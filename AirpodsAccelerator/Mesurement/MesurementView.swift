//
//  ContentView.swift
//  Airpods accelerator
//
//  Created by 上別縄祐也 on 2021/11/03.
//

import SwiftUI
import Charts
import GoogleMobileAds
import StoreKit

struct MeasurementView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var measuremetViewController = MeasurementViewController()
    @ObservedObject var interstitial = Interstitial()
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass
    
    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    var body: some View {
        let deviceTraitStatus = DeviceTraitStatus(hSizeClass: self.hSizeClass, vSizeClass: self.vSizeClass)
        NavigationView{
            VStack{
                Text(measuremetViewController.status)
                    .font(.title)
                    .frame(height: nil)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                HStack{
                    Text("\(measuremetViewController.timeCounter)")
                        .font(.largeTitle)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .frame(width:150, alignment: .leading)
                        .padding(.leading, 90.0)
                        .padding()
                    Text("s")
                        .font(.largeTitle)
                }
                Spacer()
                Chart(data: measuremetViewController.graphValues)
                    .padding(.top, 30.0)
                    .frame(width: 337, height: 121, alignment: .bottom)
                    .chartStyle(
                        LineChartStyle(.quadCurve, lineColor: .purple, lineWidth: 3)
                    )
                Spacer()
                VStack{
                    switch deviceTraitStatus {
                    case .wRhR, .wChR:
                        self.buttonsOnPortrait
                    case .wRhC, .wChC:
                        self.buttonsOnLandscape
                    }
                }
                BannerView()
                    .frame(width: 320, height: 50)
                    .padding(.bottom)
            }
            .navigationBarItems(trailing:
                NavigationLink(destination: SettingView()){
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 26))
            })
        }
        .onAppear() {
            interstitial.loadInterstitial()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private extension MeasurementView {
    var buttonsOnPortrait: some View {
        VStack{
            HStack{
                Spacer()
                Button(action: {
                    measuremetViewController.stopSave = false
                    measuremetViewController.startCalc()
                }) {
                    Image(systemName: "play.fill")
                        .padding(.horizontal)
                        .font(.title)
                        .foregroundColor(Color.white)
                        .frame(width: 160.0, height: 120.0)
                        .background(Color("startColor"))
                        .clipShape(Circle())
                }
                .disabled(measuremetViewController.isStartingMeasure)
                .opacity(measuremetViewController.isStartingMeasure ? 0.3 : 1)
                Spacer()
                if(measuremetViewController.stopSave){
                    Button(action: {
                        measuremetViewController.save()
                    }) {
                        Image(systemName: "arrow.down.to.line")
                            .padding(.horizontal)
                            .font(.title)
                            .foregroundColor(Color.white)
                            .frame(width: 160.0, height: 120.0)
                            .background(Color("saveColor"))
                            .clipShape(Circle())
                    }
                    .alert(String(localized: "sameNameMessage"), isPresented: $measuremetViewController.saveNameAlert) {
                        TextField(String(localized: "File name to save"), text: $measuremetViewController.fileName)
                        Button(String(localized: "Save")) {
                            measuremetViewController.saveFile()
                        }
                        Button(String(localized: "Cancel")) {
                            requestReview()
                        }
                    }
                }else{
                    Button(action: {
                        measuremetViewController.stopCalc()
                    }) {
                        Image(systemName: "stop.fill")
                            .padding(.horizontal)
                            .font(.title)
                            .foregroundColor(Color.white)
                            .frame(width: 160.0, height: 120.0)
                            .background(Color("stopColor"))
                            .clipShape(Circle())
                            .alert(String(localized: "checkAirpods"), isPresented: $measuremetViewController.checkAirpodsShowingAlert) {
                                Text("OK")
                            }
                    }
                    .disabled(!measuremetViewController.isStartingMeasure)
                    .opacity(measuremetViewController.isStartingMeasure ? 1 : 0.3)
                    .alert(String(localized: "Save completed"), isPresented: $measuremetViewController.saveCompleteShowingAlert) {
                        Button("OK") {
                            Thread.sleep(forTimeInterval: 0.5)
                            measuremetViewController.timeCounter = "0.00"
                            measuremetViewController.graphValues = []
                            interstitial.presentInterstitial()
                        }
                    } message: {
                        Text(LocalizedStringKey("saveFile"))
                    }
                }
                Spacer()
            }.padding()
        }
    }
    
    var buttonsOnLandscape: some View {
        HStack{
            Button(action: {
                measuremetViewController.stopSave = false
                measuremetViewController.startCalc()
            }) {
                Image(systemName: "start.fill")
                    .padding()
                    .font(.title)
                    .foregroundColor(Color.white)
                    .frame(width: 160.0, height: 120.0)
                    .background(Color("startColor"))
                    .clipShape(Circle())
            }
            
            if(measuremetViewController.stopSave){
                Button(action: {
                    measuremetViewController.save()
                }) {
                    Image(systemName: "arrow.down.to.line")
                        .padding(.horizontal)
                        .font(.title)
                        .foregroundColor(Color.white)
                        .frame(width: 160.0, height: 120.0)
                        .background(Color("saveColor"))
                        .clipShape(Circle())
                }
                .alert(String(localized: "sameNameMessage"), isPresented: $measuremetViewController.saveNameAlert) {
                    TextField(String(localized: "File name to save"), text: $measuremetViewController.fileName)
                    Button(String(localized: "Save")) {
                        measuremetViewController.saveFile()
                    }
                    Button(String(localized: "Cancel")) {
                    }
                }
            }else{
                Button(action: {
                    measuremetViewController.stopCalc()
                    measuremetViewController.stopSave = true
                    
                }) {
                    Image(systemName: "stop.fill")
                        .padding(.horizontal)
                        .font(.title)
                        .foregroundColor(Color.white)
                        .frame(width: 160.0, height: 120.0)
                        .background(Color("stopColor"))
                        .clipShape(Circle())
                }
                .disabled(!measuremetViewController.isStartingMeasure)
                .opacity(measuremetViewController.isStartingMeasure ? 1 : 0.3)
                .alert(String(localized: "Save completed"), isPresented: $measuremetViewController.saveCompleteShowingAlert) {
                    Button("OK") {
                        Thread.sleep(forTimeInterval: 0.5)
                        measuremetViewController.timeCounter = "0.00"
                        measuremetViewController.graphValues = []
                        interstitial.presentInterstitial()
                    }
                } message: {
                    Text(LocalizedStringKey("saveFile"))
                }
            }
        }
    }
}


struct MeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementView()
    }
}
