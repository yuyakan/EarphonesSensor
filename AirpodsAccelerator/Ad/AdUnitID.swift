//
//  AdUnitID.swift
//  Earphones Acceleration Sensor
//
//  広告ユニットID。Debugビルドではテスト広告、Releaseビルドでは本番広告を使う。
//

import Foundation

enum AdUnitID {
    // バナー広告
    static var banner: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716" // テスト
        #else
        return "ca-app-pub-3155724310732667/9728563089" // 本番
        #endif
    }

    // インタースティシャル広告
    static var interstitial: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/4411468910" // テスト
        #else
        return "ca-app-pub-3155724310732667/9696228900" // 本番
        #endif
    }
}
