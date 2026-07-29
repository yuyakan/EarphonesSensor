//
//  AlertViewController.swift
//  Earphones Acceleration Sensor
//
//  Created by 上別縄祐也 on 2023/11/29.
//

import SwiftUI
import UIKit
import StoreKit

// 画像付きの保存完了ダイアログ。UIAlertController は画像を差し込むと
// 端末サイズやフォントで崩れるため、SwiftUI で素直に縦積みして表示する。
struct ImageAlertView: View {
    @Binding var isPresented: Bool

    let title: String?
    let message: String?
    let interstitial: Interstitial
    let measuremetViewController: MeasurementViewController

    var body: some View {
        ZStack {
            // 背景の暗幕。タップでは閉じない（OK を促す）
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                if let title {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }

                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Image("file")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)

                Button(action: dismiss) {
                    Text("OK")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            // 縦積みなので端末幅に対する割合で幅を決めれば崩れない
            .frame(maxWidth: 320)
            .padding(.horizontal, 32)
        }
    }

    private func dismiss() {
        isPresented = false
        measuremetViewController.timeCounter = "0.00"
        measuremetViewController.graphValues = []
        // 広告がクールダウン中で表示されなかった場合はレビューをリクエストする
        let skipped = interstitial.presentInterstitial()
        if skipped {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}

// カスタムModifierの定義
struct AlertWithImage: ViewModifier {
    @Binding var isPresented: Bool

    let title: String?
    let message: String?
    let interstitial: Interstitial
    let mesurementViewController: MeasurementViewController

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                ImageAlertView(
                    isPresented: $isPresented,
                    title: title,
                    message: message,
                    interstitial: interstitial,
                    measuremetViewController: mesurementViewController
                )
            }
        }
    }
}

extension View {
    func alertWithImage(isPresented: Binding<Bool>, title: String?, message: String?, interstitial: Interstitial, measurementViewController: MeasurementViewController) -> some View {
        self.modifier(AlertWithImage(
             isPresented: isPresented,
             title: title,
             message: message,
             interstitial: interstitial,
             mesurementViewController: measurementViewController
        ))
    }
}
