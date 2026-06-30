import SwiftUI

@main
struct CrisisEngineApp: App {
    var body: some Scene {
        WindowGroup {
            CrisisEngineView()
        }
    }
}

struct CrisisEngineView: View {
    @State private var selectedMode = GameMode.collapse
    @State private var activeScenario: Scenario?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.black, Color(red: 0.08, green: 0.09, blue: 0.14), Color(red: 0.24, green: 0.08, blue: 0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        modeCarousel
                        featuredScenario
                        designNotes
                    }
                    .padding(20)
                }
            }
            .navigationDestination(item: $activeScenario) { scenario in
                ScenarioSimulationView(scenario: scenario)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CRISIS ENGINE")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("A strategy sandbox about systems that spread, mutate, and spiral out of control.")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))

            Text("Launch mode: Collapse Engine")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.18), in: Capsule())
                .foregroundStyle(.orange)
        }
    }

    private var modeCarousel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Modes")
                .font(.title2.bold())
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(GameMode.allCases) { mode in
                        ModeCard(mode: mode, isSelected: selectedMode == mode) {
                            selectedMode = mode
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var featuredScenario: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedMode.isPlayable ? "Playable Prototype" : "Future Expansion")
                .font(.title2.bold())
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedMode.title)
                            .font(.title.bold())
                            .foregroundStyle(.white)

                        Text(selectedMode.pitch)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    Spacer()

                    Text(selectedMode.isPlayable ? "PLAY" : "LOCKED")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedMode.isPlayable ? .green.opacity(0.18) : .white.opacity(0.10), in: Capsule())
                        .foregroundStyle(selectedMode.isPlayable ? .green : .white.opacity(0.7))
                }

                Divider().overlay(.white.opacity(0.15))

                ForEach(selectedMode.hooks, id: \.self) { hook in
                    Label(hook, systemImage: "sparkle")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Button {
                    if selectedMode.isPlayable {
                        activeScenario = Scenario.collapsePrototype
                    }
                } label: {
                    Text(selectedMode.isPlayable ? "Start Collapse Engine" : "Coming After Launch")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedMode.isPlayable ? .orange : .gray.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .disabled(!selectedMode.isPlayable)
            }
            .padding(18)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private var designNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why start here?")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Collapse Engine is the best first mode because it gives players immediate Plague Inc.-style cause-and-effect: push one global system, watch another crack, then exploit the chain reaction. If it works, Alien Parasite, Dream Invader, Invasive Species, and Shadow Market can reuse the same simulation foundation with new skins, maps, stats, and upgrade trees.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.76))
                .padding(16)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

struct ModeCard: View {
    let mode: GameMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundStyle(mode.accent)

                Text(mode.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                Text(mode.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Spacer()
            }
            .frame(width: 172, height: 178, alignment: .topLeading)
            .padding(16)
            .background(isSelected ? mode.accent.opacity(0.20) : .white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(isSelected ? mode.accent : .white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ScenarioSimulationView: View {
    let scenario: Scenario
    @State private var day = 1
    @State private var selectedAction: CrisisAction?
    @State private var stability = 82.0
    @State private var panic = 12.0
    @State private var resources = 68.0
    @State private var awareness = 8.0
    @State private var log = ["Day 1: Small pressure points appear across the world."]

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(red: 0.11, green: 0.07, blue: 0.05)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(scenario.title)
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text("Day \(day) · Create cascading failure without triggering a coordinated recovery too early.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    worldStatus
                    actionGrid
                    eventLog
                }
                .padding(20)
            }
        }
        .navigationTitle("Simulation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var worldStatus: some View {
        VStack(spacing: 14) {
            MetricRow(title: "Global Stability", value: stability, color: .green, icon: "shield.lefthalf.filled")
            MetricRow(title: "Public Panic", value: panic, color: .red, icon: "exclamationmark.triangle.fill")
            MetricRow(title: "Resource Pressure", value: resources, color: .orange, icon: "shippingbox.fill")
            MetricRow(title: "Crisis Awareness", value: awareness, color: .blue, icon: "eye.fill")
        }
        .padding(16)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    private var actionGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pressure Points")
                .font(.title2.bold())
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(CrisisAction.allCases) { action in
                    Button {
                        apply(action)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.title3)
                                .foregroundStyle(action.color)

                            Text(action.title)
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text(action.effect)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.67))
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
                        .padding(14)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var eventLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chain Reaction Log")
                .font(.title2.bold())
                .foregroundStyle(.white)

            ForEach(log.indices.reversed(), id: \.self) { index in
                Text(log[index])
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func apply(_ action: CrisisAction) {
        day += 1
        selectedAction = action
        stability = clamp(stability + action.stabilityDelta)
        panic = clamp(panic + action.panicDelta)
        resources = clamp(resources + action.resourceDelta)
        awareness = clamp(awareness + action.awarenessDelta)

        let outcome: String
        if stability < 20 {
            outcome = "Governments begin emergency coordination as stability nears collapse."
        } else if panic > 75 {
            outcome = "Public panic creates a feedback loop across markets and media."
        } else if resources > 85 {
            outcome = "Resource bottlenecks spread into food, fuel, and medical supply chains."
        } else if awareness > 70 {
            outcome = "Analysts connect the pattern, increasing the chance of organized recovery."
        } else {
            outcome = action.logLine
        }

        log.append("Day \(day): \(outcome)")
    }

    private func clamp(_ value: Double) -> Double {
        min(100, max(0, value))
    }
}

struct MetricRow: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(Int(value))%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(color)
            }

            ProgressView(value: value, total: 100)
                .tint(color)
        }
    }
}

enum GameMode: String, CaseIterable, Identifiable {
    case collapse
    case alienParasite
    case dreamInvader
    case invasiveSpecies
    case shadowMarket

    var id: String { rawValue }

    var title: String {
        switch self {
        case .collapse: "Collapse Engine"
        case .alienParasite: "Alien Parasite"
        case .dreamInvader: "Dream Invader"
        case .invasiveSpecies: "Invasive Species"
        case .shadowMarket: "Shadow Market"
        }
    }

    var shortDescription: String {
        switch self {
        case .collapse: "Trigger cascading global failure."
        case .alienParasite: "Evolve, hide, and overtake Earth."
        case .dreamInvader: "Spread through dreams and break reality."
        case .invasiveSpecies: "Dominate ecosystems through mutation."
        case .shadowMarket: "Grow an underground economy."
        }
    }

    var pitch: String {
        switch self {
        case .collapse:
            "Push climate, markets, health, energy, and trust until one crack becomes a worldwide chain reaction."
        case .alienParasite:
            "Begin as a tiny alien organism and choose whether to hide in hosts, bloom across nature, or merge with technology."
        case .dreamInvader:
            "Start as one recurring nightmare, spread from mind to mind, and make waking life feel unsafe."
        case .invasiveSpecies:
            "Adapt an organism to predators, climates, and humans while deciding whether to balance or devour the ecosystem."
        case .shadowMarket:
            "Build a fictional underground network where risk, demand, rival factions, and law enforcement pressure collide."
        }
    }

    var hooks: [String] {
        switch self {
        case .collapse:
            ["Cascading cause-and-effect across connected systems", "Multiple endings: recovery, collapse, or unstable survival", "Designed as the shared simulation base for every future mode"]
        case .alienParasite:
            ["Stealth vs monster outbreak evolution paths", "Military detection creates constant pressure", "Hosts, habitats, and technology become upgrade routes"]
        case .dreamInvader:
            ["Fear, obsession, and sleep science become resources", "Lucid dreamers and therapists fight back", "Reality-bleed upgrades change the map rules"]
        case .invasiveSpecies:
            ["Ecosystem balance creates strategic tradeoffs", "Predators and humans force adaptation", "Beautiful maps can become hostile living puzzles"]
        case .shadowMarket:
            ["A stylized fictional economy, not a real crime guide", "Supply, demand, heat, and rival pressure drive strategy", "Can become a tense city-control management mode"]
        }
    }

    var icon: String {
        switch self {
        case .collapse: "globe.americas.fill"
        case .alienParasite: "ant.fill"
        case .dreamInvader: "moon.stars.fill"
        case .invasiveSpecies: "leaf.fill"
        case .shadowMarket: "building.2.crop.circle.fill"
        }
    }

    var accent: Color {
        switch self {
        case .collapse: .orange
        case .alienParasite: .mint
        case .dreamInvader: .purple
        case .invasiveSpecies: .green
        case .shadowMarket: .gray
        }
    }

    var isPlayable: Bool { self == .collapse }
}

struct Scenario: Identifiable, Hashable {
    let id = UUID()
    let title: String

    static let collapsePrototype = Scenario(title: "Collapse Engine Prototype")
}

enum CrisisAction: String, CaseIterable, Identifiable {
    case climateShock
    case marketPanic
    case gridFailure
    case trustErosion

    var id: String { rawValue }

    var title: String {
        switch self {
        case .climateShock: "Climate Shock"
        case .marketPanic: "Market Panic"
        case .gridFailure: "Grid Failure"
        case .trustErosion: "Trust Erosion"
        }
    }

    var effect: String {
        switch self {
        case .climateShock: "+resources, +panic"
        case .marketPanic: "-stability, +panic"
        case .gridFailure: "+resources, -stability"
        case .trustErosion: "-stability, +awareness"
        }
    }

    var icon: String {
        switch self {
        case .climateShock: "cloud.sun.bolt.fill"
        case .marketPanic: "chart.line.downtrend.xyaxis"
        case .gridFailure: "bolt.slash.fill"
        case .trustErosion: "person.2.slash.fill"
        }
    }

    var color: Color {
        switch self {
        case .climateShock: .yellow
        case .marketPanic: .red
        case .gridFailure: .orange
        case .trustErosion: .blue
        }
    }

    var stabilityDelta: Double {
        switch self {
        case .climateShock: -8
        case .marketPanic: -14
        case .gridFailure: -12
        case .trustErosion: -10
        }
    }

    var panicDelta: Double {
        switch self {
        case .climateShock: 12
        case .marketPanic: 18
        case .gridFailure: 10
        case .trustErosion: 7
        }
    }

    var resourceDelta: Double {
        switch self {
        case .climateShock: 14
        case .marketPanic: 6
        case .gridFailure: 18
        case .trustErosion: 4
        }
    }

    var awarenessDelta: Double {
        switch self {
        case .climateShock: 8
        case .marketPanic: 10
        case .gridFailure: 9
        case .trustErosion: 16
        }
    }

    var logLine: String {
        switch self {
        case .climateShock:
            "Extreme weather damages crops and ports, raising food prices across connected regions."
        case .marketPanic:
            "A selloff spreads from finance feeds into jobs, housing, and public confidence."
        case .gridFailure:
            "Power interruptions ripple into hospitals, data centers, fuel pumps, and emergency response."
        case .trustErosion:
            "Conflicting narratives make communities slower to coordinate and faster to blame each other."
        }
    }
}
