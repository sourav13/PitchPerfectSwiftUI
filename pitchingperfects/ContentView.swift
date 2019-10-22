//
//  ContentView.swift
//  pitchingperfects
//
//  Created by sourav sachdeva on 18/10/19.
//  Copyright © 2019 sourav sachdeva. All rights reserved.
//

import SwiftUI
import AVFoundation
import Combine

struct ContentView: View {
    @State private var recordbutton : Bool = false
    @State private var stopbutton : Bool = true
    @State private var recordbuttontext : String = "Tap to record"
    var audioRec = SoundPlayerUIView()
    @State private var presentMe = false;
    var body: some View {
        NavigationView{
            VStack{
                Button(action: {
                    self.stopbutton = !self.stopbutton
                    self.recordbutton = !self.recordbutton
                    self.recordbuttontext = "Recording in progress"
                    self.audioRec.startRecording()
                }){
                    Image("Record")
                }.disabled(recordbutton)
                Text("\(recordbuttontext)")
                NavigationLink(destination: Display(),isActive: $presentMe){EmptyView()}
                Button(action: {
                    self.recordbutton = !self.recordbutton
                    self.stopbutton = !self.stopbutton
                    self.recordbuttontext = "Tap to record"
                    self.audioRec.stopRecording()
                    self.presentMe = true
                    
                }){
                    Image("Stop")    .resizable()
                        .scaledToFit()
                        .frame(width:64,height:64)
                    
                }.disabled(stopbutton)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
class SoundPlayerUIView: UIView{
 var audioecorder : AVAudioRecorder?
    override init(frame: CGRect) {
        super.init(frame:frame)
    }
    func startRecording(){
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let recordingName = "recordedVoice.wav"
        let pathArray = [dirPath,recordingName]
        let filePath : String = pathArray.joined(separator: "/")
        let urlStr : String = filePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let convertedURL : URL = URL(string: urlStr)!
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
        try! self.audioecorder = AVAudioRecorder(url: convertedURL, settings: [:])
        self.audioecorder!.delegate = self
        self.audioecorder!.isMeteringEnabled = true
        self.audioecorder!.prepareToRecord()
        self.audioecorder!.record()
        
    }
    required init?(coder: NSCoder) {
        super.init(coder:coder)
    }
    
    func stopRecording(){
        self.audioecorder?.stop()
        let session = AVAudioSession.sharedInstance()
        try! session.setActive(false, options:AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
extension SoundPlayerUIView: AVAudioRecorderDelegate{
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if(flag){
            print("audio recorded successfully")
        }else{
            print("audio not recorded")
        }
    }
    
}

