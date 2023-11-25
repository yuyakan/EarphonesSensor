//
//  ViewController.swift
//  AirpodsAccelerator
//
//  Created by 上別縄祐也 on 2021/11/14.
//

import UIKit
import CoreMotion
import SwiftUI
import AVFoundation
import GoogleMobileAds

class MeasurementViewController: UIViewController, CMHeadphoneMotionManagerDelegate, ObservableObject{
    @Published var fileName = ""
    @Published var timeCounter = "0.00"
    @Published var saveCompleteShowingAlert = false
    @Published var notNameShowingAlert = false
    @Published var isStartingMeasure = false
    @Published var status = "Waiting for measurement"
    @Published var stopSave = false
    @ObservedObject var setting = SettingInfo.shared
    
    let airpods = CMHeadphoneMotionManager()
    
    var graphValues: [Double] = []
    var time : [Double] = []
    var nowTime: Double = 0.0
    
    var X : [Double] = []
    var Y : [Double] = []
    var Z : [Double] = []
    var Total: [Double] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        airpods.delegate = self
    }

    override func viewWillAppear(_ flag: Bool){
        super.viewWillAppear(flag)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    //start
    func startCalc(){
        guard isValidFileName() else { return }
        resetMeasureStatus()
        startGettingData()
    }
    
    private func isValidFileName() -> Bool {
        if fileName == "" {
            notNameShowingAlert = true
            return false
        }
        isStartingMeasure = true
        return true
    }
    
    private func resetMeasureStatus() {
        saveCompleteShowingAlert = false
        notNameShowingAlert = false
        graphValues = []
        nowTime = 0.0
        time.removeAll()
        X.removeAll()
        Y.removeAll()
        Z.removeAll()
    }
    
    private func startGettingData() {
        status = "During measurement"
        airpods.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {[weak self] motion, error  in
            guard let motion = motion else { return }
            self?.registData(motion)
        })
    }
    
    private func registData(_ data: CMDeviceMotion){
        let x, y, z : Double
        //選択されたセンサのデータをX,Y,Zに記録
        if self.setting.checkedSensor[0] {
            x = data.userAcceleration.x
            y = data.userAcceleration.y
            z = data.userAcceleration.z
            graphValues.append(abs(x) + abs(y) + abs(z))
        }else if self.setting.checkedSensor[1] {
            x = data.gravity.x
            y = data.gravity.y
            z = data.gravity.z
            graphValues.append(z*z)
        }else if self.setting.checkedSensor[2] {
            x = data.rotationRate.x
            y = data.rotationRate.y
            z = data.rotationRate.z
            graphValues.append((abs(x) + abs(y) + abs(z)) * 0.3)
        }else {
            x = data.attitude.pitch
            y = data.attitude.roll
            z = data.attitude.yaw
            graphValues.append(y + 0.3)
        }
        X.append(x)
        Y.append(y)
        Z.append(z)
        
        //計測開始からの時間をtimeに記録
        let t = data.timestamp
        if (nowTime == 0.0){
            nowTime = t
        }
        time.append(t - nowTime)
        //画面の計測時間を更新
        timeCounter = String(format: "%0.2f",t - nowTime)
    }
 
    
    //stop
    func stopCalc(){
        //計測の停止
        airpods.stopDeviceMotionUpdates()
        if nowTime == 0.0 {
            return
        }
        saveCompleteShowingAlert = false
    }
    
    
    //save
    func saveFile(){
        do {
            // csvファイルに計測データを書き込む
            var csv = ""
            csv = self.createCsv(X: X, Y: Y, Z: Z)
            let path = NSHomeDirectory() + "/Documents/" + fileName + ".csv"
            try csv.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            
            status = "End of measurement"
            saveCompleteShowingAlert = true
            fileName = ""
        }
        catch {
            print("Failed to save: \(error)")
            saveCompleteShowingAlert = false
        }
    }
    
    private func createCsv(X: [Double], Y: [Double], Z: [Double]) -> String {
        //計測データを一つにまとめる
        var csv: String
        
        //Attitude以外の時はTotalを追加
        var Title: String
        if setting.checkedSensor[3] {
            csv = zip(zip(zip(time, X)
                            .map { nums in "\(nums.0), \(nums.1)" }
                          , Y)
                        .map { nums in "\(nums.0), \(nums.1)" }
                      , Z)
                    .map { nums in "\(nums.0), \(nums.1)" }
                    .joined(separator: "\n")
            Title = "time, pitch, roll, yaw\n"
        } else {
            Title = "time, x, y, z, T\n"
            Total = X.map{$0 * $0} + Y.map{$0 * $0} + Z.map{$0 * $0}
            Total = Total.map{sqrt($0)}
            
            csv = zip(zip(zip(zip(time, X)
                                .map { nums in "\(nums.0), \(nums.1)" }
                              , Y)
                            .map { nums in "\(nums.0), \(nums.1)" }
                          , Z)
                        .map { nums in "\(nums.0), \(nums.1)" }
                        , Total)
            .map{ nums in "\(nums.0), \(nums.1)"}
            .joined(separator: "\n")
        }
        
        csv = Title + csv
        return csv
    }
}


