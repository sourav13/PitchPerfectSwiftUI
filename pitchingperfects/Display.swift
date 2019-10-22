//
//  Display.swift
//  pitchingperfects
//
//  Created by sourav sachdeva on 18/10/19.
//  Copyright © 2019 sourav sachdeva. All rights reserved.
//

import SwiftUI
import AVFoundation
struct Display: View {
    @State private var stopButton: Bool = true
    @State private var voiceButtons: Bool = false

  var audioRec = PlayerControllerUIView()
  enum ButtonType: String {
    case Slow,Fast,LowPitch,HighPitch,Echo,Reverb
    }
    var imageNames = [["Slow","Fast"],["Reverb","Echo"],["LowPitch","HighPitch"]]
    func returnValue(imageName: String)-> some View{
        var button: some View {  Button(action: {
            switch(ButtonType(rawValue: imageName)) {
              case .Slow:
                   self.audioRec.playSound(rate: 0.5)
              case .Fast:
                   self.audioRec.playSound(rate: 1.5)
              case .LowPitch:
                   self.audioRec.playSound(pitch: -1000)
              case .HighPitch:
                   self.audioRec.playSound(pitch: 1000)
              case .Echo:
                   self.audioRec.playSound(echo: true)
              case .Reverb:
                   self.audioRec.playSound(reverb: true)
            case .none:
               self.audioRec.playSound()
            }
            self.voiceButtons = true
            self.stopButton = false
        }){
            Image(imageName)
            }.disabled(voiceButtons)
            
        }
        return button
    }
    var body: some View {
        VStack{
            GridStack(rows:3, columns: 2) { row, col in
                self.returnValue(imageName: self.imageNames[row][col])
            }
            Button(action: {
                self.audioRec.stopAudio()
                self.voiceButtons = false
                self.stopButton = true
            }){
                Image("Stop").resizable()
                    .scaledToFit()
                    .frame(width:64,height:64)
            }.padding(.leading).padding(.bottom).disabled(stopButton)
        }.padding(.top)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}
struct Display_Previews: PreviewProvider {
    static var previews: some View {
        Display()
    }
}
struct GridStack<Content: View>: View {
    var rows: Int
    var columns: Int
    let content: (Int, Int) -> Content
    var body: some View {
        VStack {
            ForEach(0 ..< rows) { row in
                HStack {
                    Spacer()
                    ForEach(0 ..< self.columns) { column in
                        self.content(row, column)
                        Spacer()
                    }
                }
                Spacer()
            }
        }
    }
}

class PlayerControllerUIView: UIView{
    var recordedAudioURL:URL!
    var audioFile:AVAudioFile!
    var audioEngine:AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    var stopTimer: Timer!
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }
    override init(frame: CGRect) {
        super.init(frame:frame)
        setupAudio()
    }
    required init?(coder: NSCoder) {
        super.init(coder:coder)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
extension PlayerControllerUIView:AVAudioPlayerDelegate {
    enum PlayingState { case playing, notPlaying }
    func setupAudio() {
       let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
           let recordingName = "recordedVoice.wav"
           let pathArray = [dirPath,recordingName]
           let filePath : String = pathArray.joined(separator: "/")
           let urlStr : String = filePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
           let convertedURL : URL = URL(string: urlStr)!
        do {
            audioFile = try AVAudioFile(forReading: convertedURL as URL)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }
    
    func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attach(changeRatePitchNode)
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
        }
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {
            
            var delayInSeconds: Double = 0
            
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
                
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(PlayerControllerUIView.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: RunLoop.Mode.default)
        }
        do {
            try audioEngine.start()
        } catch {
            showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return
        }
        audioPlayerNode.play()
    }
    
    @objc func stopAudio() {
        
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
      //  configureUI(.notPlaying)
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    // MARK: Connect List of Audio Nodes
    
    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
    
    // MARK: UI Functions
    
    func configureUI(_ playState: PlayingState) {
        switch(playState) {
        case .playing:
            setPlayButtonsEnabled(false)
        //  stopButton.isEnabled = true
        case .notPlaying:
            setPlayButtonsEnabled(true)
            //   stopButton.isEnabled = false
        }
    }
    
    func setPlayButtonsEnabled(_ enabled: Bool) {
        //        snailButton.isEnabled = enabled
        //        chipmunkButton.isEnabled = enabled
        //        rabbitButton.isEnabled = enabled
        //        vaderButton.isEnabled = enabled
        //        echoButton.isEnabled = enabled
        //        reverbButton.isEnabled = enabled
    }
    
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        //  self.present(alert, animated: true, completion: nil)
    }
    
}
















//   func containedView(x:Int) -> some View {
//       switch x {
//       case  let  x where x % 2 == 0 :  return self.returnValue(imageName: self.imageNames[x+1])
//         case  let  x where  x % 2 != 0 : return self.returnValue(imageName: self.imageNames[x-1])
//       default : break
//    }
//        return self.returnValue(imageName: self.imageNames[x])
//    }
