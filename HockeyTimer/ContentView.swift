//
//  ContentView.swift
//  HockeyTimer
//
//  Created by Sergey Pustovalov on 24/01/2026.
//

import SwiftUI
import AVFoundation
import AudioToolbox

struct ContentView: View {
    @State private var totalTime: Int = 15 * 60
    @State private var interval: Int = 60
    @State private var remainingTime: Int = 0
    @State private var isRunning: Bool = false
    @State private var timer: Timer? = nil
    @State private var intervalsCompleted: Int = 0
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        VStack(spacing: 30) {
            Text("🏒 Hockey timer")
                .font(.largeTitle)
                .padding()
            
            VStack {
                Text("\(remainingTime / 60):\(String(format: "%02d", remainingTime % 60))")
                    .font(.system(size: 80))
                    .monospacedDigit()
                
                Text("Shifts: \(intervalsCompleted)/\(totalTime / interval)")
                    .font(.title2)
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("Interval")
                    Stepper("\(interval) sec", value: $interval, in: 30...300, step: 30)
                }
                VStack {
                    Text("Total")
                    Stepper("\(totalTime / 60) min", value: $totalTime, in: 5*60...60*60, step: 60)
                }
            }
            
            HStack(spacing: 20) {
                Button(isRunning ? "⏸️ Pause" : "▶️ Start") {
                    toggleTimer()
                }
                .font(.title2)
                .padding()
                .background(isRunning ? .orange : .green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button("🔄 Reset") {
                    resetTimer()
                }
                .font(.title2)
                .padding()
                .background(.gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .onAppear {
            setupCustomAudio()
        }
    }
    
    func toggleTimer() {
        isRunning.toggle()
        if isRunning {
            if remainingTime == 0 {
                remainingTime = totalTime
                intervalsCompleted = 0
            }
            startTimer()
        } else {
            timer?.invalidate()
        }
    }
    
    func startTimer() {
        playBeep()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            remainingTime -= 1
            
            if remainingTime % interval == 0 {
                playBeep()
                if remainingTime != totalTime {  // Первый интервал не считать
                    intervalsCompleted += 1
                }
            }
            
            if remainingTime <= 0 {
                resetTimer()
                playBeep()
            }
        }
    }
    
    func resetTimer() {
        timer?.invalidate()
        isRunning = false
        remainingTime = 0
        intervalsCompleted = 0
    }
    
    func setupCustomAudio() {
        guard let path = Bundle.main.path(forResource: "beep", ofType: "wav") else {  // ← wav вместо mp3
            print("beep.wav не найден!")
            return
        }
        
        let url = URL(fileURLWithPath: path)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                audioPlayer?.volume = 1.0
                print("✅ beep.wav загружен!")
            } catch {
                print("❌ Ошибка аудио: \(error)")
            }
    }
    
    func playBeep() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

