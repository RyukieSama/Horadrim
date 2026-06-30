//
//  HomeView.swift
//  Horadrim
//
//  Minimal home page that only keeps the four-card component grid.
//
//  Created by RyukieSama Zhong on 14/2/26.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: String
    @Binding var scrollTarget: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                moduleGrid
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.vertical, 24)
            }
            .scrollIndicators(.never)
            .navigationTitle("tab.home")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }

    // MARK: - Module Grid

    private var moduleGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ModuleCard(
                icon: "puzzlepiece.extension.fill",
                color: .blue,
                title: "Module",
                subtitle: "Frameworks",
                description: "Auth, Camera, Face Camera, Paywall"
            ) { selectedTab = "component"; scrollTarget = "module" }

            ModuleCard(
                icon: "sparkles.tv.fill",
                color: .orange,
                title: "Animation",
                subtitle: "Components",
                description: "Shimmer, TypewriterText, OrbitingLogos, and more"
            ) { selectedTab = "component"; scrollTarget = "animation" }

            ModuleCard(
                icon: "chart.bar.fill",
                color: .green,
                title: "Chart",
                subtitle: "Components",
                description: "Line, Bar, Area, Donut, Radar, Scatter, and more"
            ) { selectedTab = "component"; scrollTarget = "chart" }

            ModuleCard(
                icon: "square.grid.2x2.fill",
                color: .purple,
                title: "Component",
                subtitle: "Components",
                description: "Display, Feedback, Input — ready to use"
            ) { selectedTab = "component"; scrollTarget = "display" }
        }
    }
}

// MARK: - Module Card

private struct ModuleCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let description: String
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    #if canImport(UIKit)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    #else
                    .fill(Color(NSColor.controlBackgroundColor))
                    #endif
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HomeView(selectedTab: .constant("home"), scrollTarget: .constant(nil))
        .environment(SWStoreManager.shared)
        .environment(SWUserManager(skipAuthCheck: true))
        .swAlert()
}
