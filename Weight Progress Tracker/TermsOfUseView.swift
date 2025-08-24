//
//  TermsOfUseView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI

struct TermsOfUseView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    termsContent
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(
                Color.black
                    .ignoresSafeArea()
            )
            .navigationTitle(LocalizationManager.shared.localizedString(for: LocalizationKeys.termsOfUse))
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
                Image(systemName: "doc.text.below.ecg")
                    .font(.title)
                    .foregroundColor(.teal)
                
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.termsAndConditions))
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
    
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            TermsSection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.acceptanceOfTerms),
                icon: "checkmark.seal.fill",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.acceptanceOfTermsDesc)
            )
            
            TermsSection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.appUsage),
                icon: "iphone",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.appUsageDesc)
            )
            
            TermsSection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.userResponsibility),
                icon: "person.fill.checkmark",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.userResponsibilityDesc)
            )
            
            TermsSection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.limitationsOfLiability),
                icon: "exclamationmark.triangle.fill",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.limitationsOfLiabilityDesc)
            )
            
            TermsSection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.medicalAdvice),
                icon: "cross.case.fill",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.medicalAdviceDesc)
            )
            
            TermsSection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.intellectualProperty),
                icon: "c.circle.fill",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.intellectualPropertyDesc)
            )
            
            TermsSection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.modifications),
                icon: "arrow.triangle.2.circlepath",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.modificationsDesc)
            )
            
            TermsSection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.termination),
                icon: "xmark.circle.fill",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.terminationDesc)
            )
            
            TermsSection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.contact),
                icon: "envelope.fill",
                content: LocalizationManager.shared.localizedString(for: LocalizationKeys.contactDesc)
            )
        }
    }
}

struct TermsSection: View {
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