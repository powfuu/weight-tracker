//
//  PrivacyPolicyView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    policyContent
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(
                Color.white
                    .ignoresSafeArea()
            )
            .navigationTitle(LocalizationManager.shared.localizedString(for: LocalizationKeys.privacyPolicy))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(LocalizationManager.shared.localizedString(for: LocalizationKeys.close)) {
                        HapticFeedback.light()
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.title)
                    .foregroundColor(.teal)
                
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.privacyImportant))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .primaryGradientText()
            }
            
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.lastUpdated))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var policyContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            PolicySection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.dataCollection),
                icon: "doc.text.fill",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.dataCollectionDesc)
            )
            
            PolicySection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.dataUsage),
                icon: "chart.line.uptrend.xyaxis",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.dataUsageDesc)
            )
            
            PolicySection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.dataStorage),
                icon: "internaldrive.fill",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.dataStorageDesc)
            )
            
            PolicySection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.notifications),
                icon: "bell.fill",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.notificationsDesc)
            )
            
            PolicySection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.dataExport),
                icon: "square.and.arrow.up",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.dataExportDesc)
            )
            
            PolicySection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.dataDeletion),
                icon: "trash.fill",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.dataDeletionDesc)
            )
            
            PolicySection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.contact),
                icon: "envelope.fill",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.contactDesc)
            )
        }
    }
}

struct PolicySection: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.teal)
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .primaryGradientText()
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

#if DEBUG
#Preview("Privacy Policy • Dark") {
    PrivacyPolicyView()
        .preferredColorScheme(.dark)
}

#Preview("Privacy Policy • Light") {
    PrivacyPolicyView()
        .preferredColorScheme(.light)
}
#endif