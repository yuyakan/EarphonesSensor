//
//  ContentView.swift
//  Airpods accelerator
//
//  Created by 上別縄祐也 on 2021/11/03.
//

import SwiftUI
import Charts
import GoogleMobileAds

struct MeasurementView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var measuremetViewController = MeasurementViewController()
    @State var showIntersitialAd: Bool = false
    
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass
    
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
                        LineChartStyle(.quadCurve, lineColor: .blue, lineWidth: 3)
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
                Text("Setting")
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private extension MeasurementView {
    var buttonsOnPortrait: some View {
        VStack{
            HStack{
                TextField("File name to save", text: $measuremetViewController.fileName, onCommit: {
                    measuremetViewController.status = "Waiting for measurement"
                })
                    .frame(width: 200.0)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text(".csv")
                    .frame(width: 35.0, height: 35.0)
            }
            
            HStack{
                Button(action: {
                    measuremetViewController.stopSave = false
                    measuremetViewController.startCalc()
                }) {
                    Text("start")
                        .padding(.horizontal)
                        .font(.title)
                        .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                        .frame(width: 160.0, height: 120.0)
                        .background(Color("startColor"))
                        .clipShape(Circle())
                }.alert(isPresented: $measuremetViewController.notNameShowingAlert) {
                    Alert(title: Text("The file name to save has not been entered"), message: Text("Please enter the file name to save"))
                }
                if(measuremetViewController.stopSave){
                    Button(action: {
                        measuremetViewController.saveFile()
                        measuremetViewController.isStartingMeasure = false
                        measuremetViewController.stopSave = false
                    }) {
                        Text("save")
                            .padding(.horizontal)
                            .font(.title)
                            .foregroundColor(Color.white)
                            .frame(width: 160.0, height: 120.0)
                            .background(Color("saveColor"))
                            .clipShape(Circle())
                    }
                }else{
                    Button(action: {
                        measuremetViewController.stopCalc()
                        measuremetViewController.stopSave = true
                    }) {
                        Text("stop")
                            .padding(.horizontal)
                            .font(.title)
                            .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                            .frame(width: 160.0, height: 120.0)
                            .background(Color("startColor"))
                            .clipShape(Circle())
                    }.disabled(!measuremetViewController.isStartingMeasure)
                    .alert("Save completed", isPresented: $measuremetViewController.saveCompleteShowingAlert) {
                        Button("OK") {
                            showIntersitialAd.toggle()
                            Thread.sleep(forTimeInterval: 0.5)
                            measuremetViewController.timeCounter = "0.00"
                            measuremetViewController.graphValues = []
                        }
                    } message: {
                        Text("Saved in　Files->On My iPhone->AirpodsAccelerator")
                    }
                }
            }.padding()
        }
    }
    
    var buttonsOnLandscape: some View {
        HStack{
            Button(action: {
                measuremetViewController.stopSave = false
                measuremetViewController.startCalc()
            }) {
                Text("start")
                    .padding()
                    .font(.title)
                    .foregroundColor(Color.white)
                    .frame(width: 160.0, height: 120.0)
                    .background(Color("startColor"))
                    .clipShape(Circle())
            }.alert(isPresented: $measuremetViewController.notNameShowingAlert) {
                Alert(title: Text("The file name to save has not been entered"), message: Text("Please enter the file name to save"))
            }
            TextField("File name to save", text: $measuremetViewController.fileName, onCommit: {
                measuremetViewController.status = "Waiting for measurement"
            })
                .frame(width: 200.0)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text(".csv")
                .frame(width: 35.0, height: 35.0)
            
            
            if(measuremetViewController.stopSave){
                Button(action: {
                    measuremetViewController.saveFile()
                    measuremetViewController.isStartingMeasure = false
                    measuremetViewController.stopSave = false
                }) {
                    Text("save")
                        .padding(.horizontal)
                        .font(.title)
                        .foregroundColor(Color.white)
                        .frame(width: 160.0, height: 120.0)
                        .background(Color("saveColor"))
                        .clipShape(Circle())
                }
            }else{
                Button(action: {
                    measuremetViewController.stopCalc()
                    measuremetViewController.stopSave = true
                    
                }) {
                    Text("stop")
                        .padding(.horizontal)
                        .font(.title)
                        .foregroundColor(Color.white)
                        .frame(width: 160.0, height: 120.0)
                        .background(Color("startColor"))
                        .clipShape(Circle())
                }.disabled(!measuremetViewController.isStartingMeasure)
                .alert("Save completed", isPresented: $measuremetViewController.saveCompleteShowingAlert) {
                    Button("OK") {
                        showIntersitialAd.toggle()
                        Thread.sleep(forTimeInterval: 0.5)
                        measuremetViewController.timeCounter = "0.00"
                        measuremetViewController.graphValues = []
                    }
                } message: {
                    Text("Saved in　Files->On My iPhone->AirpodsAccelerator")
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
