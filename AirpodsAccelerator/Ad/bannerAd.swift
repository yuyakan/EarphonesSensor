//
//  bannerAd.swift
//  Earphones Acceleration Sensor
//
//  Created by 上別縄祐也 on 2023/11/25.
//

import GoogleMobileAds
import SwiftUI

struct BannerView: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> UIViewController {
        let viewController = BannerAdViewController()
        return viewController
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

class BannerAdViewController: UIViewController, BannerViewDelegate {
    var bannerView: GoogleMobileAds.BannerView!
    let adUnitID = AdUnitID.banner

    // 読み込み失敗時のリトライ回数
    private var retryCount = 0
    // リトライの最大回数
    private let maxRetryCount = 5
    // 指数バックオフの基準遅延（秒）
    private let baseRetryDelay: TimeInterval = 2

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        retryCount = 0
        loadBanner()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.retryCount = 0
            self.loadBanner()
        }
    }

    private func loadBanner() {
        bannerView = GoogleMobileAds.BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID

        bannerView.delegate = self
        bannerView.rootViewController = self

        let bannerWidth = view.frame.size.width
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: bannerWidth)

        let request = Request()
        request.scene = view.window?.windowScene
        bannerView.load(request)

        setAdView(bannerView)
    }

    func setAdView(_ view: GoogleMobileAds.BannerView) {
        bannerView = view
        self.view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        let viewDictionary = ["_bannerView": bannerView!]
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[_bannerView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary
            )
        )
        self.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[_bannerView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary
            )
        )
    }

    // 読み込み成功
    func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
        print("😍: バナー広告の読み込みに成功しました")
        retryCount = 0
    }

    // 読み込み失敗
    func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
        print("😭: バナー広告の読み込みに失敗しました")
        scheduleRetry()
    }

    // 指数バックオフで読み込みを再試行する
    private func scheduleRetry() {
        guard retryCount < maxRetryCount else {
            print("😭: バナー広告の読み込みリトライ上限（\(maxRetryCount)回）に達しました")
            return
        }
        let delay = baseRetryDelay * pow(2, Double(retryCount))
        retryCount += 1
        print("🔄: \(delay)秒後にバナー広告をリトライします（\(retryCount)/\(maxRetryCount)回目）")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.loadBanner()
        }
    }
}
