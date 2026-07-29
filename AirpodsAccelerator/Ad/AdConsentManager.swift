//
//  AdConsentManager.swift
//  Earphones Acceleration Sensor
//
//  広告の同意管理（UMP）とATT（App Tracking Transparency）を扱う。
//

import AppTrackingTransparency
import GoogleMobileAds
import UserMessagingPlatform

final class AdConsentManager {
    static let shared = AdConsentManager()

    private init() {}

    /// 同意フロー（UMP）とATTリクエストを実行し、完了後に completion を呼ぶ。
    /// - Parameter completion: 同意フロー完了後に必ずメインスレッドで呼ばれる。広告SDKの初期化はこの後に行う。
    func gatherConsent(completion: @escaping () -> Void) {
        let parameters = RequestParameters()
        // デバッグ設定が必要な場合はここで parameters.debugSettings を設定する。

        // UMPの同意情報を最新化する
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard let self else { return }

            if let error {
                print("😭: 同意情報の更新に失敗しました: \(error.localizedDescription)")
                // 同意情報が取得できなくても、ATTだけは要求して広告読み込みへ進む
                self.requestTrackingAuthorization(completion: completion)
                return
            }

            // 必要であれば同意フォームを表示する（EU圏など）。表示不要な地域では即クロージャが返る。
            ConsentForm.loadAndPresentIfRequired(from: nil) { [weak self] formError in
                guard let self else { return }
                if let formError {
                    print("😭: 同意フォームの表示に失敗しました: \(formError.localizedDescription)")
                }
                // UMPの同意処理が済んでからATTを要求する
                self.requestTrackingAuthorization(completion: completion)
            }
        }
    }

    /// ATTの許可をリクエストする。結果に関わらず completion をメインスレッドで呼ぶ。
    private func requestTrackingAuthorization(completion: @escaping () -> Void) {
        // ATTのダイアログはアプリがアクティブになってから表示する必要がある
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                print("😍: トラッキングが許可されました（パーソナライズ広告可）")
            case .denied, .restricted:
                print("🙅: トラッキングが許可されませんでした（非パーソナライズ広告）")
            case .notDetermined:
                print("❓: トラッキングの状態が未確定です")
            @unknown default:
                break
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    /// 広告をリクエストできる状態か（UMPの判定）。
    var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }
}
