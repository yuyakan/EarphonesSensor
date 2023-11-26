//
//  SettingView.swift
//  AirpodsAccelerator
//
//  Created by 上別縄祐也 on 2021/11/14.
//

import SwiftUI

struct SettingView: View {
    @ObservedObject var setting = SettingInfo.shared
    
    let sensorKind: [String] = [
        String(localized: "acceleration"),
        String(localized: "gravity"),
        String(localized: "rotationRate"),
        String(localized: "attitude")
    ]

    var body: some View {
        List {
            ForEach(0..<sensorKind.count, id: \.self) { index in
                HStack {
                    Image(systemName: setting.checkedSensor[index] ? "checkmark.circle.fill" : "circle")
                    Text("\(sensorKind[index])")
                    Spacer()
                }

                .contentShape(Rectangle())
                .onTapGesture {
                    setting.checkedSensor[index].toggle()
                }
            }
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
