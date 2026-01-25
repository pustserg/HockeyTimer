//
//  ContentView.swift
//
//  Created by Sergey Pustovalov on 24/01/2026.
//

import SwiftUI
import AVFoundation
import AudioToolbox

struct ContentView: View {
    @AppStorage("totalTime") private var totalTime: Int = 15 * 60
    @AppStorage("interval") private var interval: Int = 60
    @AppStorage("beepVolume") private var beepVolume: Double = 1.0
    @AppStorage("selectedSound") private var selectedSound: String = "hockey whistle"
    @AppStorage("backgroundColorKey") private var backgroundColorKey: String = "white"

    @State private var remainingTime: Int = 0
    @State private var isRunning: Bool = false
    @State private var timer: Timer? = nil
    @State private var intervalsCompleted: Int = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showSettings: Bool = false

    private var backgroundColor: Color {
        ColorOption.color(for: backgroundColorKey)
    }
    
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
                backgroundColorKey: $backgroundColorKey,
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
            audioPlayer?.volume = Float(beepVolume)
            print("✅ \(selectedSound).wav загружен!")
        } catch {
            print("❌ Ошибка аудио: \(error)")
        }
    }
    
    func playBeep() {
        audioPlayer?.volume = Float(beepVolume)
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

struct SettingsView: View {
    @Binding var interval: Int
    @Binding var totalTime: Int
    @Binding var backgroundColorKey: String
    @Binding var beepVolume: Double
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
                    Picker("Background", selection: $backgroundColorKey) {
                        ForEach(ColorOption.allCases) { option in
                            Text(option.label).tag(option.key)
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
            testAudioPlayer?.volume = Float(beepVolume)
            testAudioPlayer?.play()
        } catch {
            print("Error playing test sound: \(error)")
        }
    }
}

enum ColorOption: String, CaseIterable, Identifiable {
    case black
    case darkBlue
    case navy
    case darkGreen
    case white
    case ivory
    case lightGrey
    case offWhite
    case cream

    var id: String { rawValue }
    var key: String { rawValue }

    var label: String {
        switch self {
        case .black: return "🖤 Black"
        case .darkBlue: return "🔵 Dark Blue"
        case .navy: return "🔷 Navy"
        case .darkGreen: return "🟢 Dark Green"
        case .white: return "⚪ White"
        case .ivory: return "📜 Ivory"
        case .lightGrey: return "⬜ Light Grey"
        case .offWhite: return "📰 Off-White"
        case .cream: return "🥛 Cream"
        }
    }

    var color: Color {
        switch self {
        case .black: return .black
        case .darkBlue: return Color.blue.opacity(0.9)
        case .navy: return Color(red: 0.1, green: 0.1, blue: 0.2)
        case .darkGreen: return Color.green.opacity(0.9)
        case .white: return .white
        case .ivory: return Color(red: 1.0, green: 1.0, blue: 0.98)
        case .lightGrey: return Color.gray.opacity(0.9)
        case .offWhite: return Color(red: 0.98, green: 0.98, blue: 1.0)
        case .cream: return Color(red: 1.0, green: 0.98, blue: 0.92)
        }
    }

    static func color(for key: String) -> Color {
        ColorOption(rawValue: key)?.color ?? .white
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

