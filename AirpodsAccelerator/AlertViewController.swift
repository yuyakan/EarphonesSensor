//
//  AlertViewController.swift
//  Earphones Acceleration Sensor
//
//  Created by 上別縄祐也 on 2023/11/29.
//

import UIKit
import SwiftUI

struct AlertControllerWithTextFieldContainer: UIViewControllerRepresentable {

    @Binding var isPresented: Bool

    let title: String?
    let message: String?
    let interstitial: Interstitial
    let measuremetViewController: MeasurementViewController

    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let imageView = UIImageView(frame: CGRect(x: 10, y: 105, width: 250, height: 140))
        let height = NSLayoutConstraint(item: alert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 320)
        alert.view.addConstraint(height)
        imageView.image = UIImage(named: "file")
        alert.view.addSubview(imageView)
        
        let doneAction = UIAlertAction(title: "OK", style: .default) { _ in
            measuremetViewController.timeCounter = "0.00"
            measuremetViewController.graphValues = []
            interstitial.presentInterstitial()
        }
        alert.addAction(doneAction)

        DispatchQueue.main.async {
            uiViewController.present(alert, animated: true) {
                isPresented = false
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
                AlertControllerWithTextFieldContainer(
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
