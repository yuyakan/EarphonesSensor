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
    @Published var checkAirpodsShowingAlert = false
    @Published var saveNameAlert = false
    @Published var isStartingMeasure = false
    @Published var status = String(localized: "Waiting for measurement")
    @Published var stopSave = false
    @ObservedObject var setting = SettingInfo.shared
    var graphValues: [Double] = []

    let airpods = CMHeadphoneMotionManager()
    var rawTime: [Double] = []
    var elapsedTime : [Double] = []
    var nowTime: Double = 0.0
    
    var accel = SensorData()
    var rotate = SensorData()
    var gravity = SensorData()
    var attitude = SensorData()

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
        isStartingMeasure = true
        resetMeasureStatus()
        startGettingData()
    }
    
    private func resetMeasureStatus() {
        saveCompleteShowingAlert = false
        checkAirpodsShowingAlert = false
        graphValues = []
        nowTime = 0.0
        elapsedTime.removeAll()
        accel = SensorData()
        rotate = SensorData()
        attitude = SensorData()
        gravity = SensorData()
    }
    
    private func startGettingData() {
        status = String(localized: "During measurement")
        airpods.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {[weak self] motion, error  in
            guard let motion = motion else { return }
            self?.registData(motion)
        })
    }
    
    private func registData(_ data: CMDeviceMotion){
        updateSensorData(data: data)
        updateGraphValue(data: data)
        updateTime(t: data.timestamp)
    }
    
    private func updateSensorData(data: CMDeviceMotion) {
        if self.setting.checkedSensor[0] {
            accel.x.append(data.userAcceleration.x)
            accel.y.append(data.userAcceleration.y)
            accel.z.append(data.userAcceleration.z)
        }
        if self.setting.checkedSensor[1] {
            gravity.x.append(data.gravity.x)
            gravity.y.append(data.gravity.y)
            gravity.z.append(data.gravity.z)
        }
        if self.setting.checkedSensor[2] {
            rotate.x.append(data.rotationRate.x)
            rotate.y.append(data.rotationRate.y)
            rotate.z.append(data.rotationRate.z)
        }
        if self.setting.checkedSensor[3] {
            attitude.x.append(data.attitude.pitch)
            attitude.y.append(data.attitude.roll)
            attitude.z.append(data.attitude.yaw)
        }
    }
    
    private func updateGraphValue(data: CMDeviceMotion) {
        if self.setting.checkedSensor[0] {
            graphValues.append(abs(data.userAcceleration.x) + abs(data.userAcceleration.y) + abs(data.userAcceleration.z))
        } else if self.setting.checkedSensor[2] {
            graphValues.append((abs(data.rotationRate.x) + abs(data.rotationRate.y) + abs(data.rotationRate.z)) * 0.3)
        } else if self.setting.checkedSensor[1] {
            graphValues.append(data.gravity.z*data.gravity.z)
        } else {
            graphValues.append(data.attitude.roll + 0.3)
        }
    }
    
    private func updateTime(t: Double) {
        if (nowTime == 0.0){
            nowTime = t
        }
        rawTime.append(t)
        elapsedTime.append(t - nowTime)
        //画面の計測時間を更新
        timeCounter = String(format: "%0.2f",t - nowTime)
    }
 
    
    //stop
    func stopCalc(){
        //計測の停止
        airpods.stopDeviceMotionUpdates()
        isStartingMeasure = false
        if nowTime == 0.0 {
            checkAirpodsShowingAlert = true
            return
        }
        stopSave = true
        saveCompleteShowingAlert = false
    }
    
    
    //save
    let formatter = DateFormatter()
    func save() {
        let now = Date()
        formatter.dateFormat = "y-MM-dd_HH-mm-ss"
        formatter.locale = .current
        fileName = formatter.string(from: now)
        saveNameAlert = true
    }
    
    func saveFile(){
        saveNameAlert = false
        isStartingMeasure = false
        stopSave = false
        do {
            let csv = self.createCsv()
            let path = NSHomeDirectory() + "/Documents/" + fileName + ".csv"
            try csv.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            
            status = String(localized: "End of measurement")
            saveCompleteShowingAlert = true
            fileName = ""
        }
        catch {
            print("Failed to save: \(error)")
            saveCompleteShowingAlert = false
        }
    }
    
    private func createCsv() -> String {
        var Title: String = "time, elapsedTime"
        var dataRows: [String] = zip2Array(array1: rawTime, array2: elapsedTime)
        
        if self.setting.checkedSensor[0] {
            Title = Title + ", Acceleration_x, Acceleration_y, Acceleration_z"
            dataRows = zip2Array(array1: dataRows, array2: zipSensorData(sensorData: accel))
        }
        if self.setting.checkedSensor[1] {
            Title = Title + ", Gravity_x, Gravity_y, Gravity_z"
            dataRows = zip2Array(array1: dataRows, array2: zipSensorData(sensorData: gravity))
        }
        if self.setting.checkedSensor[2] {
            Title = Title + ", Rotation_x, Rotation_y, Rotation_z"
            dataRows = zip2Array(array1: dataRows, array2: zipSensorData(sensorData: rotate))
        }
        if self.setting.checkedSensor[3] {
            Title = Title + ", pitch, roll, yaw"
            dataRows = zip2Array(array1: dataRows, array2: zipSensorData(sensorData: attitude))
        }
        
        return Title + "\n" + dataRows.joined(separator: "\n")
    }
    
    private func zipSensorData(sensorData: SensorData) -> [String] {
        let zip2Data = zip2Array(array1: sensorData.x, array2: sensorData.y)
        let zip3Data = zip2Array(array1: zip2Data, array2: sensorData.z)
        return zip3Data
    }
    
    private func zip2Array(array1: Array<Any>, array2: Array<Any>) -> [String] {
        zip(array1, array2)
            .map { nums in "\(nums.0), \(nums.1)" }
    }
}
