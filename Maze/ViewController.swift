//
//  ViewController.swift
//  Maze
//
//  Created by Kusunose Hosho on 2020/05/15.
//  Copyright © 2020 Kusunose Hosho. All rights reserved.
//

import UIKit
import CoreMotion //加速度センサー(CMMotionManager)を使うため設定

class ViewController: UIViewController {
    
    // playerViwewを表すUIVinew
    // playerMotionManager:iPhoneの動きを感知するCMMotionManager
    //speedX,apeedY: プレイヤーが動くはやさ
    var playerView: UIView!
    var playerMotionManager: CMMotionManager!
    var speedX: Double = 0.0
    var speedY: Double = 0.0

    //画面サイズの取得
    let screenSize = UIScreen.main.bounds.size
    
    //迷路マップを表した配列
    let maze = [
        [1, 0, 0, 0, 1, 0],
        [1, 0, 1, 0, 1, 0],
        [3, 0, 1, 0, 1, 0],
        [1, 1, 1, 0, 0, 0],
        [1, 0, 0, 1, 1, 0],
        [0, 0, 1, 0, 0, 0],
        [0, 1, 1, 0, 1, 0],
        [0, 0, 0, 0, 1, 1],
        [0, 1, 1, 0, 0, 0],
        [0, 0, 1, 1, 1, 2],
    ]
    
    //スタートとゴールを表すUIView
    var startView: UIView!
    var goalView: UIView!
    
    //wallViewのフレームワークの情報を入れておく配列
    var wallRectArray = [CGRect]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let cellWidth = screenSize.width / CGFloat(maze[0].count)
        let cellHeight = screenSize.height / CGFloat(maze.count)
        
        let cellOffsetX = cellWidth / 2
        let cellOffsetY = cellWidth / 2
        
        //for文とsswitch文を使って画面にオブジェクトを配置していく
        for y in 0 ..< maze.count {
            for x in 0 ..< maze[y].count {
                switch maze[y][x] {
                case 1: //当たるとゲームオーバーになるマス
                    let wallView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offsetX: cellOffsetX, offsetY: cellOffsetY)
                    wallView.backgroundColor = UIColor.black
                    view.addSubview(wallView)
                    wallRectArray.append(wallView.frame)
                
                case 2: //スタート地点
                    startView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offsetX: cellOffsetX, offsetY: cellOffsetY)
                    startView.backgroundColor = UIColor.green
                    view.addSubview(startView)
                    
                case 3: //ゴール地点
                    goalView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offsetX: cellOffsetX, offsetY: cellOffsetY)
                    goalView.backgroundColor = UIColor.red
                    view.addSubview(goalView)
                    
                default:
                    break
                }
            }
        }
        
        // playerViewの生成
        playerView = UIView(frame: CGRect(x: 0, y: 0, width: cellWidth / 6, height: cellHeight / 6))
        playerView.center = startView.center
        playerView.backgroundColor = UIColor.gray
        view.addSubview(playerView)
        
        //MotionManagerを生成
        playerMotionManager = CMMotionManager()
        playerMotionManager.accelerometerUpdateInterval = 0.02  //playerMotionManagerを生成し、加速度の値を0.02秒ごとに取得する
        
        startAccelerometer()
    }

    //迷路の１マスとなるUIViewを作るメソッド
    func createView(x: Int, y: Int, width: CGFloat, height: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> UIView {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let view = UIView(frame: rect)
        
        let center = CGPoint(x: offsetX + width * CGFloat(x), y: offsetY + height * CGFloat(y))
        
        view.center = center
        
        return view
    }
    
    func startAccelerometer() {
        
        //加速度の取得
        let handler: CMAccelerometerHandler = {(CMAccelerometerData: CMAccelerometerData?, error: Error?) -> Void in self.speedX += CMAccelerometerData!.acceleration.x
            self.speedY += CMAccelerometerData!.acceleration.y
            
            //プレイヤーの中心位置を設定
            var posX = self.playerView.center.x + (CGFloat(self.speedX) / 3)
            var posY = self.playerView.center.y - (CGFloat(self.speedY) / 3)
            
            //画面上からプレーヤーがはみ出しそうになったら、posX/posYを修正
            if posX <= self.playerView.frame.width / 2 {
                self.speedX = 0
                posX = self.playerView.frame.width / 2
            }
            if posY <= self.playerView.frame.height / 2 {
                self.speedY = 0
                posY = self.playerView.frame.height / 2
            }
            if posX >= self.screenSize.width - (self.playerView.frame.width / 2) {
                self.speedX = 0
                posX = self.screenSize.width - (self.playerView.frame.width / 2)
            }
            if posY >= self.screenSize.height - (self.playerView.frame.height / 2) {
                self.speedY = 0
                posY = self.screenSize.height - (self.playerView.frame.height / 2)
            }
            
            //playerViewとwallViewが当たっているかどうかの判定
            for wallRect in self.wallRectArray {
                if wallRect.intersects(self.playerView.frame) {
                    self.gameCheck(result: "GameOver", message: "壁に当たりました")
                    return
                }
                
                //playerViewとgoalViewが当たっているかの判定
                if self.goalView.frame.intersects(self.playerView.frame) {
                    self.gameCheck(result: "Clear", message: "クリアしました！")
                    return
                }
            }
            self.playerView.center = CGPoint(x: posX, y: posY)
        }
        
        //加速度の開始
        playerMotionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: handler)
    }
    
    func gameCheck(result: String, message: String){
        //加速度をとめる
        if playerMotionManager.isAccelerometerActive {
            playerMotionManager.stopAccelerometerUpdates()
        }
        
        let gameCheckAlert: UIAlertController = UIAlertController(title: result, message: message, preferredStyle: .alert)
        
        let retryAction = UIAlertAction(title: "もう一度", style: .default, handler: {
            (action: UIAlertAction!) -> Void in
            self.retry()
        })
        
        gameCheckAlert.addAction(retryAction)
        
        self.present(gameCheckAlert, animated: true, completion: nil)
    }
    
    func retry() {
        //プレイヤーを初期化
        playerView.center = startView.center
        //加速度センサーを始める
        if !playerMotionManager.isAccelerometerActive {
            self.startAccelerometer()
        }
        //スピードの初期化
        speedX = 0.0
        speedY = 0.0
    }

}

