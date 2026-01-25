//
//  ContentView.swift
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
    @State private var showSettings: Bool = false
    @State private var backgroundColor: Color = .white
    @State private var beepVolume: Float = 1.0
    @State private var selectedSound: String = "hockey whistle"
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Text("\(remainingTime / 60):\(String(format: "%02d", remainingTime % 60))")
                        .font(.system(size: 100, weight: .bold, design: .monospaced))
                    
                    Text("Shifts: \(intervalsCompleted)/\(totalTime / interval)")
                        .font(.title2)
                }
                .padding(.top, 120)
                .foregroundColor(backgroundColor.isDark ? .white : .black)
                
                Spacer()
                
                Button(action: toggleTimer) {
                    Circle()
                        .fill(isRunning ? Color.orange : Color.green)
                        .frame(width: 180, height: 180)
                        .overlay(
                            Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .white.opacity(0.3), radius: 20)
                }
                
                Spacer()
                
                HStack {
                    Button("⚙️ \(interval)s / \(totalTime/60)m") {
                        showSettings.toggle()
                    }
                    .font(.caption)
                    
                    Spacer()
                    
                    Button("🔄 Reset") {
                        resetTimer()
                    }
                    .font(.caption)
                }
                .foregroundColor(backgroundColor.isDark ? .white.opacity(0.7) : .black.opacity(0.7))
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                interval: $interval,
                totalTime: $totalTime,
                backgroundColor: $backgroundColor,
                beepVolume: $beepVolume,
                selectedSound: $selectedSound
            )
        }
        .onAppear {
            setupCustomAudio()
        }
        .onChange(of: selectedSound) {
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
                if remainingTime != totalTime {
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
        guard let path = Bundle.main.path(forResource: selectedSound, ofType: "wav") else {
            print("\(selectedSound).wav не найден!")
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = beepVolume
            print("✅ \(selectedSound).wav загружен!")
        } catch {
            print("❌ Ошибка аудио: \(error)")
        }
    }
    
    func playBeep() {
        audioPlayer?.volume = beepVolume
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

struct SettingsView: View {
    @Binding var interval: Int
    @Binding var totalTime: Int
    @Binding var backgroundColor: Color
    @Binding var beepVolume: Float
    @Binding var selectedSound: String
    @Environment(\.dismiss) private var dismiss
    @State private var testAudioPlayer: AVAudioPlayer?

    var body: some View {
        NavigationView {
            Form {
                Section("Timer") {
                    Stepper("Interval: \(interval) sec", value: $interval, in: 30...300, step: 30)
                    Stepper("Total: \(totalTime / 60) min", value: $totalTime, in: 5*60...60*60, step: 60)
                }
                
                Section("Appearance") {
                    Picker("Background", selection: $backgroundColor) {
                        Group {
                            Text("🖤 Black").tag(Color.black)
                            Text("🔵 Dark Blue").tag(Color.blue.opacity(0.9))
                            Text("🔷 Navy").tag(Color(red: 0.1, green: 0.1, blue: 0.2))
                            Text("🟢 Dark Green").tag(Color.green.opacity(0.9))
                        }
                        
                        Divider()
                        
                        Group {
                            Text("⚪ White").tag(Color.white)
                            Text("📜 Ivory").tag(Color(red: 1.0, green: 1.0, blue: 0.98))
                            Text("⬜ Light Grey").tag(Color.gray.opacity(0.9))
                            Text("📰 Off-White").tag(Color(red: 0.98, green: 0.98, blue: 1.0))
                            Text("🥛 Cream").tag(Color(red: 1.0, green: 0.98, blue: 0.92))
                        }
                    }
                }
                
                Section("Sound") {
                    HStack {
                        Text("Volume")
                        Spacer()
                        Text("\(Int(beepVolume * 100))%")
                    }
                    Slider(value: $beepVolume, in: 0.1...1.0, step: 0.1)

                    Picker("Sound", selection: $selectedSound) {
                        Text("hockey whistle").tag("hockey whistle")
                        Text("whistle").tag("whistle")
                        Text("bell").tag("bell")
                        Text("horn").tag("horn")
                    }

                    Button("🔊 Test sound") {
                        playTestSound()
                    }
                    .buttonStyle(.borderless)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    func playTestSound() {
        guard let path = Bundle.main.path(forResource: selectedSound, ofType: "wav") else {
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            testAudioPlayer = try AVAudioPlayer(contentsOf: url)
            testAudioPlayer?.volume = beepVolume
            testAudioPlayer?.play()
        } catch {
            print("Error playing test sound: \(error)")
        }
    }
}

extension Color {
    var isDark: Bool {
        let uiColor = UIColor(self)
        var white: CGFloat = 0
        uiColor.getWhite(&white, alpha: nil)
        return white < 0.5
    }
}

#Preview {
    ContentView()
}

