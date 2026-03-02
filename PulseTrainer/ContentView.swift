//
//  ContentView.swift
//  PulseTrainer
//
//  Created by Kenichi Takahama on 2026/02/26.
//

import SwiftUI
import UIKit
import CoreHaptics
import MessageUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

private enum AdMobConfig {
    // Replace these with your own production unit IDs.
    static let homeBottomUnitID = "ca-app-pub-5009939459633318/5498042405"
    static let setDataUnitID = "ca-app-pub-5009939459633318/5498042405"
    static let measurementBottomUnitID = "ca-app-pub-5009939459633318/5498042405"
}

private enum ArrhythmiaMode: String, Hashable {
    case none
    case premature
    case atrialFibrillation
}

private final class PulseHaptics {
    static let shared = PulseHaptics()

    private var engine: CHHapticEngine?
    private let fallback = UIImpactFeedbackGenerator(style: .heavy)

    private init() {}

    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            fallback.prepare()
            return
        }
        if engine == nil {
            buildEngine()
        }
        startEngineIfNeeded()
        fallback.prepare()
    }

    func playBeat(intensityScale: Float) {
        prepare()

        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, let engine else {
            playFallback(intensityScale: intensityScale)
            return
        }

        do {
            let pulseIntensity = min(1.0, 0.22 + (intensityScale * 1.0))
            let events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: pulseIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.75)
                    ],
                    relativeTime: 0.0
                )
            ]
            let pattern = try CHHapticPattern(events: events, parameterCurves: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            playFallback(intensityScale: intensityScale)
        }
    }

    private func buildEngine() {
        do {
            let newEngine = try CHHapticEngine()
            newEngine.isAutoShutdownEnabled = false
            newEngine.playsHapticsOnly = true
            newEngine.stoppedHandler = { [weak self] _ in
                self?.startEngineIfNeeded()
            }
            newEngine.resetHandler = { [weak self] in
                self?.startEngineIfNeeded()
            }
            engine = newEngine
        } catch {
            engine = nil
        }
    }

    private func startEngineIfNeeded() {
        guard let engine else { return }
        do {
            try engine.start()
        } catch {
            self.engine = nil
        }
    }

    private func playFallback(intensityScale: Float) {
        fallback.prepare()
        let fallbackIntensity = min(1.0, CGFloat(0.28 + (intensityScale * 1.0)))
        fallback.impactOccurred(intensity: fallbackIntensity)
    }
}

private struct PulseSet: Identifiable, Equatable, Hashable {
    let id = UUID()
    var name: String
    var pulseValue: Double
    var isWeakPulse: Bool
    var arrhythmiaMode: ArrhythmiaMode
    var prematureBeatsPerMinute: Double
    var afMeanRate: Double
    var afIrregularity: Double
}

struct ContentView: View {
    @State private var pulseSets: [PulseSet] = [
        PulseSet(
            name: "Set.1",
            pulseValue: 105,
            isWeakPulse: false,
            arrhythmiaMode: .none,
            prematureBeatsPerMinute: 8,
            afMeanRate: 95,
            afIrregularity: 35
        ),
        PulseSet(
            name: "Set.2",
            pulseValue: 79,
            isWeakPulse: true,
            arrhythmiaMode: .none,
            prematureBeatsPerMinute: 8,
            afMeanRate: 95,
            afIrregularity: 35
        )
    ]

    var body: some View {
        NavigationStack {
            HomeView(pulseSets: $pulseSets)
        }
    }
}

private struct HomeView: View {
    @Binding var pulseSets: [PulseSet]
    @State private var showMeasurementView = false
    @State private var showSetDataSheet = false
    @State private var showHowToView = false
    @State private var showAppSettings = false

    var body: some View {
        ZStack {
            Color(red: 0.72, green: 0.82, blue: 0.92)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                VStack(spacing: 18) {
                    Text("Let's Measure Your Pulse")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.65))
                        .padding(.bottom,20)
                    Button {
                        showMeasurementView = true
                    } label: {
                        startButton
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                AdBannerSlot(unitID: AdMobConfig.homeBottomUnitID)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                bottomBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showMeasurementView) {
            MeasurementView()
                .navigationBarBackButtonHidden(true)
        }
        .sheet(isPresented: $showSetDataSheet) {
            NavigationStack {
                PulseSetListView(pulseSets: $pulseSets)
            }
        }
        .sheet(isPresented: $showHowToView) {
            HowToUseView()
        }
        .sheet(isPresented: $showAppSettings) {
            HomeSettingsView()
        }
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                Text("PulseTrainer")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.55))

                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 64)

            Rectangle()
                .fill(Color.black.opacity(0.12))
                .frame(height: 1)
        }
    }

    private var startButton: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.26))
                .frame(width: 138, height: 138)

            Circle()
                .fill(Color.blue.opacity(0.28))
                .frame(width: 124, height: 124)

            Circle()
                .fill(Color.blue.opacity(0.35))
                .frame(width: 110, height: 110)

            Circle()
                .fill(Color(red: 0.09, green: 0.49, blue: 0.96))
                .frame(width: 96, height: 96)

            Text("START")
                .font(.system(size: 20, weight: .black, design: .serif))
                .foregroundStyle(.white)
        }
        .frame(width: 138, height: 138)
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.black.opacity(0.12))
                .frame(height: 1)

            HStack(spacing: 10) {
                navPill(icon: "square.and.arrow.down", title: "Set Data") {
                    showSetDataSheet = true
                }
                navPill(icon: "sunburst", title: "How to Use") {
                    showHowToView = true
                }
                navPill(icon: "gearshape", title: "Settings") {
                    showAppSettings = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .background(Color(red: 0.72, green: 0.82, blue: 0.92))
        }
    }

    private func navPill(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.72))

                Text(LocalizedStringKey(title))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
    }
}

private struct MeasurementView: View {
    private enum BeatProfile {
        case normal
        case weak
    }

    @Environment(\.dismiss) private var dismiss
    @State private var pulseValue: Double = 105
    @State private var pulseNormal = false
    @State private var prematureBeatOn = false
    @State private var atrialFibrillationOn = false
    @State private var prematureBeatsPerMinute: Double = 8
    @State private var afMeanRate: Double = 95
    @State private var afIrregularity: Double = 35
    @State private var showSettings = false
    @State private var isPulsing = false
    @State private var pulseTask: Task<Void, Never>?
    @State private var beatIndex = 0
    @State private var pendingPrematureBeat = false
    @State private var rngState: UInt64 = 0

    var body: some View {
        ZStack {
            Color(red: 0.72, green: 0.82, blue: 0.92)
                .ignoresSafeArea()

            GeometryReader { proxy in
                let isCompactHeight = proxy.size.height < 760

                VStack(spacing: 0) {
                    topBar
                        .padding(.top, isCompactHeight ? 2 : 8)

                    Spacer(minLength: isCompactHeight ? 18 : 30)

                    Text("\(Int(atrialFibrillationOn ? afMeanRate : pulseValue))")
                        .font(.system(size: isCompactHeight ? 88 : 104, weight: .bold))
                        .foregroundStyle(.black)

                    Slider(value: $pulseValue, in: 40...180, step: 1)
                        .tint(Color(red: 0.09, green: 0.49, blue: 0.96))
                        .disabled(atrialFibrillationOn)
                        .opacity(atrialFibrillationOn ? 0.35 : 1.0)
                        .padding(.horizontal, isCompactHeight ? 44 : 52)
                        .padding(.top, isCompactHeight ? 30 : 42)

                    VStack(spacing: isCompactHeight ? 14 : 18) {
                        settingRow(title: pulseNormal ? "Pulse (Weak)" : "Pulse (Normal)", isOn: $pulseNormal)
                        settingRow(
                            title: "Arrhythmia (PVC)",
                            isOn: $prematureBeatOn,
                            isDisabled: atrialFibrillationOn
                        )
                        settingRow(
                            title: "Arrhythmia (AF)",
                            isOn: $atrialFibrillationOn,
                            isDisabled: prematureBeatOn
                        )
                    }
                    .padding(.horizontal, isCompactHeight ? 40 : 52)
                    .padding(.top, isCompactHeight ? 26 : 34)

                    Button(isPulsing ? "STOP" : "START") {
                        if isPulsing {
                            stopPulseMode()
                        } else {
                            startPulseMode()
                        }
                    }
                    .font(.system(size: isCompactHeight ? 32 : 34, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: isCompactHeight ? 66 : 68)
                    .background(Color(red: 0.09, green: 0.49, blue: 0.96))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, isCompactHeight ? 40 : 52)
                    .padding(.top, isCompactHeight ? 46 : 46)

                    Spacer(minLength: isCompactHeight ? 24 : 24)

                    AdBannerSlot(unitID: AdMobConfig.measurementBottomUnitID)
                        .padding(.horizontal, 12)
                        .padding(.bottom, isCompactHeight ? 8 : 14)
                }
            }

            if isPulsing {
                Color.black
                    .ignoresSafeArea()
                    .onTapGesture(count: 2) {
                        stopPulseMode()
                    }
            }
        }
        .onDisappear {
            stopPulseMode()
        }
        .onAppear {
            resetMeasurementDefaults()
        }
        .onChange(of: prematureBeatOn) { _, newValue in
            if newValue {
                atrialFibrillationOn = false
                showSettings = true
            }
        }
        .onChange(of: atrialFibrillationOn) { _, newValue in
            if newValue {
                prematureBeatOn = false
                showSettings = true
            }
        }
        .sheet(isPresented: $showSettings) {
            PulseSettingsView(
                prematureBeatsPerMinute: $prematureBeatsPerMinute,
                afMeanRate: $afMeanRate,
                afIrregularity: $afIrregularity,
                prematureBeatOn: $prematureBeatOn,
                atrialFibrillationOn: $atrialFibrillationOn
            )
            .presentationDetents([.medium])
        }
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .regular))
                        Text("Back")
                            .font(.system(size: 22, weight: .regular))
                    }
                    .foregroundStyle(Color.black.opacity(0.55))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 64)

            Rectangle()
                .fill(Color.black.opacity(0.12))
                .frame(height: 1)
        }
    }

    private func settingRow(title: String, isOn: Binding<Bool>, isDisabled: Bool = false) -> some View {
        HStack {
            Text(LocalizedStringKey(title))
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(isDisabled ? .black.opacity(0.35) : .black)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(red: 0.66, green: 0.75, blue: 0.84))
                .scaleEffect(0.95)
                .disabled(isDisabled)
        }
    }

    private func startPulseMode() {
        isPulsing = true
        beatIndex = 0
        pendingPrematureBeat = false
        rngState = measurementSeed()
        PulseHaptics.shared.prepare()
        pulseTask?.cancel()

        pulseTask = Task {
            while !Task.isCancelled {
                let plan = await MainActor.run { nextBeatPlan() }
                await MainActor.run {
                    playSingleBeat(profile: plan.profile)
                }

                let interval = plan.nextInterval
                let ns = UInt64(interval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: ns)
            }
        }
    }

    private func stopPulseMode() {
        isPulsing = false
        pulseTask?.cancel()
        pulseTask = nil
    }

    private func nextBeatPlan() -> (profile: BeatProfile, nextInterval: Double) {
        let baseInterval = 60.0 / max(pulseValue, 1)
        beatIndex += 1

        if atrialFibrillationOn {
            let afBaseInterval = 60.0 / max(afMeanRate, 1)
            let irregularity = afIrregularity / 100.0
            let maxJitter = 0.08 + irregularity * 0.75
            let jitter = seededRandom(in: -maxJitter...maxJitter)
            let next = max(0.28, afBaseInterval * (1.0 + jitter))
            let weakBeatChance = 0.12 + irregularity * 0.35
            let isWeak = seededRandomUnit() < weakBeatChance
            return (isWeak ? .weak : .normal, next)
        }

        if prematureBeatOn {
            if pendingPrematureBeat {
                pendingPrematureBeat = false
                return (.weak, max(0.25, baseInterval * 1.55))
            }

            let eventRate = min(0.9, prematureBeatsPerMinute / max(pulseValue, 1))
            if seededRandomUnit() < eventRate {
                pendingPrematureBeat = true
                return (.normal, max(0.22, baseInterval * 0.55))
            }

            return (.normal, baseInterval)
        }

        return (.normal, baseInterval)
    }

    private func playSingleBeat(profile: BeatProfile) {
        var intensityScale: Float = pulseNormal ? 0.68 : 1.0
        if profile == .weak {
            intensityScale *= 0.64
        }
        PulseHaptics.shared.playBeat(intensityScale: intensityScale)
    }

    private func measurementSeed() -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        hash ^= UInt64(pulseValue.rounded()); hash &*= 1099511628211
        hash ^= UInt64(pulseNormal ? 1 : 0); hash &*= 1099511628211
        hash ^= UInt64(prematureBeatOn ? 1 : 0); hash &*= 1099511628211
        hash ^= UInt64(atrialFibrillationOn ? 1 : 0); hash &*= 1099511628211
        hash ^= UInt64(prematureBeatsPerMinute.rounded()); hash &*= 1099511628211
        hash ^= UInt64(afMeanRate.rounded()); hash &*= 1099511628211
        hash ^= UInt64(afIrregularity.rounded()); hash &*= 1099511628211
        return hash == 0 ? 1 : hash
    }

    private func seededRandomUnit() -> Double {
        // Deterministic LCG for reproducible arrhythmia pattern
        rngState = rngState &* 6364136223846793005 &+ 1
        let value = (rngState >> 11) & ((1 << 53) - 1)
        return Double(value) / Double(1 << 53)
    }

    private func seededRandom(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + (range.upperBound - range.lowerBound) * seededRandomUnit()
    }

    private func resetMeasurementDefaults() {
        // Keep Home START measurement consistent every time.
        pulseValue = 105
        pulseNormal = false
        prematureBeatOn = false
        atrialFibrillationOn = false
        prematureBeatsPerMinute = 8
        afMeanRate = 95
        afIrregularity = 35
        pendingPrematureBeat = false
        beatIndex = 0
        rngState = measurementSeed()
    }
}

private struct PulseSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var prematureBeatsPerMinute: Double
    @Binding var afMeanRate: Double
    @Binding var afIrregularity: Double
    @Binding var prematureBeatOn: Bool
    @Binding var atrialFibrillationOn: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("PVC Settings") {
                    sliderRow(
                        title: "PVC (/min)",
                        value: $prematureBeatsPerMinute,
                        range: 0...40
                    )
                }
                .disabled(atrialFibrillationOn)

                Section("AF Settings") {
                    sliderRow(
                        title: "Mean Rate (bpm)",
                        value: $afMeanRate,
                        range: 40...180
                    )
                    sliderRow(
                        title: "Irregularity (%)",
                        value: $afIrregularity,
                        range: 0...100
                    )
                }
                .disabled(prematureBeatOn)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LocalizedStringKey(title))
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .fontWeight(.semibold)
            }
            Slider(value: value, in: range, step: 1)
        }
        .padding(.vertical, 4)
    }
}

private struct PulseSetListView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var pulseSets: [PulseSet]
    @State private var showSetEditor = false
    @State private var selectedSet: PulseSet?

    var body: some View {
        ZStack {
            Color(white: 0.95).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                List {
                    ForEach(pulseSets) { set in
                        Button {
                            selectedSet = set
                        } label: {
                            setRow(set)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.white)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteSet(set)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                AdBannerSlot(unitID: AdMobConfig.setDataUnitID)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(item: $selectedSet) { set in
            PulsePlaybackView(pulseSet: set)
        }
        .sheet(isPresented: $showSetEditor) {
            PulseSetEditorView(setName: "Set.\(pulseSets.count + 1)") { newSet in
                pulseSets.append(newSet)
            }
        }
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .regular))
                        Text("Back")
                            .font(.system(size: 22, weight: .regular))
                    }
                    .foregroundStyle(Color.black.opacity(0.55))
                }

                Spacer()

                Button {
                    showSetEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Color.black.opacity(0.55))
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 64)

            Rectangle()
                .fill(Color.black.opacity(0.12))
                .frame(height: 1)
        }
        .background(Color(red: 0.72, green: 0.82, blue: 0.92))
    }

    private func setRow(_ set: PulseSet) -> some View {
        HStack(spacing: 18) {
            Text(set.name)
                .font(.system(size: 22))
                .foregroundStyle(.black)
                .frame(width: 88, alignment: .leading)

            Text("\(Int(set.pulseValue))")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 92, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text(set.isWeakPulse ? "Pulse\n(Weak)" : "Pulse\n(Normal)")
                    .font(.system(size: 19))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(.black)
                Text(LocalizedStringKey(arrhythmiaLabel(set.arrhythmiaMode)))
                    .font(.system(size: 19))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(.black)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.gray.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func arrhythmiaLabel(_ mode: ArrhythmiaMode) -> String {
        switch mode {
        case .none: return "Arrhythmia (None)"
        case .premature: return "Arrhythmia\n(PVC)"
        case .atrialFibrillation: return "Arrhythmia\n(AF)"
        }
    }

    private func deleteSet(_ set: PulseSet) {
        pulseSets.removeAll { $0.id == set.id }
    }
}

private struct PulseSetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let setName: String
    let onSave: (PulseSet) -> Void

    @State private var pulseValue: Double = 105
    @State private var weakPulse = false
    @State private var prematureBeatOn = false
    @State private var atrialFibrillationOn = false
    @State private var prematureBeatsPerMinute: Double = 8
    @State private var afMeanRate: Double = 95
    @State private var afIrregularity: Double = 35
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.72, green: 0.82, blue: 0.92).ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 24))
                                    Text("Back").font(.system(size: 22))
                                }
                                .foregroundStyle(Color.black.opacity(0.55))
                            }
                            Spacer()
                            Text(setName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.65))
                            Spacer()
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundStyle(Color.black.opacity(0.55))
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 64)

                        Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                    }

                    Spacer(minLength: 30)

                    Text("\(Int(atrialFibrillationOn ? afMeanRate : pulseValue))")
                        .font(.system(size: 92, weight: .bold))

                    Slider(value: $pulseValue, in: 40...180, step: 1)
                        .tint(Color(red: 0.09, green: 0.49, blue: 0.96))
                        .disabled(atrialFibrillationOn)
                        .opacity(atrialFibrillationOn ? 0.35 : 1)
                        .padding(.horizontal, 48)
                        .padding(.top, 30)

                    VStack(spacing: 16) {
                        settingRow(title: weakPulse ? "Pulse (Weak)" : "Pulse (Normal)", isOn: $weakPulse)
                        settingRow(title: "Arrhythmia (PVC)", isOn: $prematureBeatOn, isDisabled: atrialFibrillationOn)
                        settingRow(title: "Arrhythmia (AF)", isOn: $atrialFibrillationOn, isDisabled: prematureBeatOn)
                    }
                    .padding(.horizontal, 48)
                    .padding(.top, 26)

                    Button("SET") {
                        onSave(
                            PulseSet(
                                name: setName,
                                pulseValue: pulseValue,
                                isWeakPulse: weakPulse,
                                arrhythmiaMode: atrialFibrillationOn ? .atrialFibrillation : (prematureBeatOn ? .premature : .none),
                                prematureBeatsPerMinute: prematureBeatsPerMinute,
                                afMeanRate: afMeanRate,
                                afIrregularity: afIrregularity
                            )
                        )
                        dismiss()
                    }
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color(red: 0.09, green: 0.49, blue: 0.96))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 38)
                    .padding(.top, 56)

                    Spacer(minLength: 20)
                }
            }
            .onChange(of: prematureBeatOn) { _, newValue in
                if newValue {
                    atrialFibrillationOn = false
                    showSettings = true
                }
            }
            .onChange(of: atrialFibrillationOn) { _, newValue in
                if newValue {
                    prematureBeatOn = false
                    showSettings = true
                }
            }
            .sheet(isPresented: $showSettings) {
                PulseSettingsView(
                    prematureBeatsPerMinute: $prematureBeatsPerMinute,
                    afMeanRate: $afMeanRate,
                    afIrregularity: $afIrregularity,
                    prematureBeatOn: $prematureBeatOn,
                    atrialFibrillationOn: $atrialFibrillationOn
                )
                .presentationDetents([.medium])
            }
        }
    }

    private func settingRow(title: String, isOn: Binding<Bool>, isDisabled: Bool = false) -> some View {
        HStack {
            Text(LocalizedStringKey(title)).font(.system(size: 22)).foregroundStyle(isDisabled ? .black.opacity(0.35) : .black)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().scaleEffect(0.95).disabled(isDisabled)
        }
    }
}

private struct PulsePlaybackView: View {
    private enum BeatProfile {
        case normal
        case weak
    }

    @Environment(\.dismiss) private var dismiss
    let pulseSet: PulseSet

    @State private var pulseTask: Task<Void, Never>?
    @State private var pendingPrematureBeat = false
    @State private var rngState: UInt64 = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
        }
        .statusBarHidden()
        .onAppear {
            startPulseMode()
        }
        .onDisappear {
            stopPulseMode()
        }
    }

    private func startPulseMode() {
        pendingPrematureBeat = false
        rngState = playbackSeed()
        PulseHaptics.shared.prepare()
        pulseTask?.cancel()

        pulseTask = Task {
            while !Task.isCancelled {
                let plan = await MainActor.run { nextBeatPlan() }
                await MainActor.run {
                    playSingleBeat(profile: plan.profile)
                }
                let ns = UInt64(plan.nextInterval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: ns)
            }
        }
    }

    private func stopPulseMode() {
        pulseTask?.cancel()
        pulseTask = nil
    }

    private func nextBeatPlan() -> (profile: BeatProfile, nextInterval: Double) {
        let baseInterval = 60.0 / max(pulseSet.pulseValue, 1)

        switch pulseSet.arrhythmiaMode {
        case .none:
            return (.normal, baseInterval)
        case .premature:
            if pendingPrematureBeat {
                pendingPrematureBeat = false
                return (.weak, max(0.25, baseInterval * 1.55))
            }
            let eventRate = min(0.9, pulseSet.prematureBeatsPerMinute / max(pulseSet.pulseValue, 1))
            if seededRandomUnit() < eventRate {
                pendingPrematureBeat = true
                return (.normal, max(0.22, baseInterval * 0.55))
            }
            return (.normal, baseInterval)
        case .atrialFibrillation:
            let afBaseInterval = 60.0 / max(pulseSet.afMeanRate, 1)
            let irregularity = pulseSet.afIrregularity / 100.0
            let maxJitter = 0.08 + irregularity * 0.75
            let jitter = seededRandom(in: -maxJitter...maxJitter)
            let next = max(0.28, afBaseInterval * (1.0 + jitter))
            let weakBeatChance = 0.12 + irregularity * 0.35
            let isWeak = seededRandomUnit() < weakBeatChance
            return (isWeak ? .weak : .normal, next)
        }
    }

    private func playbackSeed() -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        hash ^= UInt64(pulseSet.pulseValue.rounded()); hash &*= 1099511628211
        hash ^= UInt64(pulseSet.isWeakPulse ? 1 : 0); hash &*= 1099511628211
        hash ^= UInt64(pulseSet.prematureBeatsPerMinute.rounded()); hash &*= 1099511628211
        hash ^= UInt64(pulseSet.afMeanRate.rounded()); hash &*= 1099511628211
        hash ^= UInt64(pulseSet.afIrregularity.rounded()); hash &*= 1099511628211
        return hash == 0 ? 1 : hash
    }

    private func seededRandomUnit() -> Double {
        rngState = rngState &* 6364136223846793005 &+ 1
        let value = (rngState >> 11) & ((1 << 53) - 1)
        return Double(value) / Double(1 << 53)
    }

    private func seededRandom(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + (range.upperBound - range.lowerBound) * seededRandomUnit()
    }

    private func playSingleBeat(profile: BeatProfile) {
        var intensityScale: Float = pulseSet.isWeakPulse ? 0.68 : 1.0
        if profile == .weak {
            intensityScale *= 0.64
        }
        PulseHaptics.shared.playBeat(intensityScale: intensityScale)
    }
}

private struct HowToUseView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("How to Use")
                        .font(.system(size: 28, weight: .bold))

                    Group {
                        Text("1. Basic Pulse Playback")
                            .font(.system(size: 19, weight: .semibold))
                        Text("- Tap START on the Home screen to open the pulse screen.")
                        Text("- Tap START again to begin black-screen pulse playback.")
                        Text("- Double tap the black screen to stop playback.")
                        Text("- Double tap when leaving pulse measurement playback.")
                    }

                    Group {
                        Text("2. Pulse Controls")
                            .font(.system(size: 19, weight: .semibold))
                        Text("- Pulse slider: sets regular pulse rate in bpm.")
                        Text("- Pulse (Weak): lowers haptic intensity to simulate weaker palpation.")
                    }

                    Group {
                        Text("3. Arrhythmia Modes")
                            .font(.system(size: 19, weight: .semibold))
                        Text("- Arrhythmia (PVC): simulates premature beats with compensatory pause.")
                        Text("- Arrhythmia (AF): simulates irregularly irregular rhythm.")
                        Text("- Only one arrhythmia mode can be ON at a time.")
                    }

                    Group {
                        Text("4. AF Sliders (Settings Sheet)")
                            .font(.system(size: 19, weight: .semibold))
                        Text("- Mean Rate (bpm): average ventricular rate target during AF.")
                        Text("- Irregularity (%): variability of beat-to-beat interval.")
                        Text("  - Lower value: rhythm feels closer to regular.")
                        Text("  - Higher value: rhythm feels more chaotic.")
                    }

                    Group {
                        Text("5. Set Data Workflow")
                            .font(.system(size: 19, weight: .semibold))
                        Text("- Open Set Data from Home bottom navigation.")
                        Text("- Tap + to build a new SET profile.")
                        Text("- Tap SET to save.")
                        Text("- Tap a row to play that saved pattern on black screen.")
                        Text("- Swipe left on a row to delete it.")
                    }
                }
                .font(.system(size: 16))
                .foregroundStyle(Color.black.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct HomeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showMailComposer = false
    @State private var showMailUnavailableAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Support") {
                    Button("Send Feedback") {
                        if MFMailComposeViewController.canSendMail() {
                            showMailComposer = true
                        } else {
                            showMailUnavailableAlert = true
                        }
                    }

                    ShareLink(
                        item: URL(string: "https://apps.apple.com/jp/app/id1228463311")!,
                        subject: Text("PulseTrainer"),
                        message: Text("Try PulseTrainer")
                    ) {
                        Label("Share App", systemImage: "square.and.arrow.up")
                    }

                    Button("Write a Review") {
                        if let url = URL(string: "https://apps.apple.com/jp/app/id1228463311?action=write-review") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersionText)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Mail is unavailable", isPresented: $showMailUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please set up a mail account in the Mail app first.")
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeView(
                    recipients: ["hammer528@msn.com"],
                    subject: "PulseTrainer Feedback",
                    messageBody: ""
                )
            }
        }
    }

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }
}

private struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let messageBody: String

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(recipients)
        controller.setSubject(subject)
        controller.setMessageBody(messageBody, isHTML: false)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            dismiss()
        }
    }
}

private struct AdBannerSlot: View {
    let unitID: String

    var body: some View {
        #if canImport(GoogleMobileAds)
        AdMobBannerView(unitID: unitID)
            .frame(height: 50)
        #else
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.35))
            .frame(height: 50)
            .overlay(
                Text("Ad Banner")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.45))
            )
        #endif
    }
}

#if canImport(GoogleMobileAds)
private struct AdMobBannerView: UIViewRepresentable {
    let unitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = unitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
#endif

#Preview {
    ContentView()
}
