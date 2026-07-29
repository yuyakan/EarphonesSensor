//
//  InterstitialAd.swift
//  Earphones Acceleration Sensor
//
//  Created by 上別縄祐也 on 2023/11/25.
//

import Foundation
import GoogleMobileAds

class Interstitial: NSObject, FullScreenContentDelegate, ObservableObject {
    @Published var interstitialAdLoaded: Bool = false

    var interstitialAd: InterstitialAd?

    // 前回広告を表示した時刻。この時刻から一定時間内は再表示しない
    private var lastPresentedDate: Date?
    // 広告の再表示までの最小間隔（秒）
    private let presentInterval: TimeInterval = 60

    // 読み込み失敗時のリトライ回数
    private var retryCount = 0
    // リトライの最大回数
    private let maxRetryCount = 5
    // 指数バックオフの基準遅延（秒）
    private let baseRetryDelay: TimeInterval = 2

    override init() {
        super.init()
    }

    // インタースティシャル広告の読み込みを新規に開始する（リトライ回数をリセット）
    func loadInterstitial() {
        retryCount = 0
        load()
    }

    // 実際の読み込み処理。リトライ時はリセットせずにこちらを呼ぶ
    private func load() {
        let id = AdUnitID.interstitial
        let request = Request()
        InterstitialAd.load(with: id, request: request) { [weak self] (ad, error) in
            guard let self else { return }
            if let _ = error {
                print("😭: 読み込みに失敗しました")
                self.interstitialAdLoaded = false
                self.scheduleRetry()
                return
            }
            print("😍: 読み込みに成功しました")
            self.retryCount = 0
            self.interstitialAdLoaded = true
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
        }
    }

    // 指数バックオフで読み込みを再試行する
    private func scheduleRetry() {
        guard retryCount < maxRetryCount else {
            print("😭: 読み込みのリトライ上限（\(maxRetryCount)回）に達しました")
            return
        }
        let delay = baseRetryDelay * pow(2, Double(retryCount))
        retryCount += 1
        print("🔄: \(delay)秒後にリトライします（\(retryCount)/\(maxRetryCount)回目）")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.load()
        }
    }

    // インタースティシャル広告の表示
    // 戻り値: クールダウン中で広告を表示せずスキップした場合は true
    @discardableResult
    func presentInterstitial() -> Bool {
        // 前回の表示から一定時間空いていない場合はスキップする（広告は消費せず次回に持ち越す）
        if let lastPresentedDate, Date().timeIntervalSince(lastPresentedDate) < presentInterval {
            print("⏳: 前回の表示から\(Int(presentInterval))秒経過していないためスキップしました")
            return true
        }

        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let root = windowScenes?.keyWindow?.rootViewController
        if let ad = interstitialAd, let root {
            ad.present(from: root)
            self.lastPresentedDate = Date()
            self.interstitialAdLoaded = false
        } else {
            print("😭: 広告の準備ができていませんでした")
            self.interstitialAdLoaded = false
            self.loadInterstitial()
        }
        return false
    }

    // 失敗通知
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("インタースティシャル広告の表示に失敗しました")
        self.interstitialAdLoaded = false
        self.loadInterstitial()
    }

    // 表示通知
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("インタースティシャル広告を表示しました")
        self.interstitialAdLoaded = false
    }

    // クローズ通知
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("インタースティシャル広告を閉じました")
        self.interstitialAdLoaded = false
    }
}
