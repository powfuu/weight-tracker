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
            .navigationTitle(LocalizationKeys.termsOfUse.localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(LocalizationKeys.close.localized) {
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
                
                Text(LocalizationKeys.termsAndConditions.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .primaryGradientText()
            }
            
            Text(LocalizationKeys.lastUpdated.localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            TermsSection(
                title: LocalizationKeys.acceptanceOfTerms.localized,
                icon: "checkmark.seal.fill",
                content: LocalizationKeys.acceptanceOfTermsDesc.localized
            )
            
            TermsSection(
                title: LocalizationKeys.appUsage.localized,
                icon: "iphone",
                content: LocalizationKeys.appUsageDesc.localized
            )
            
            TermsSection(
                title: LocalizationKeys.userResponsibility.localized,
                icon: "person.fill.checkmark",
                content: LocalizationKeys.userResponsibilityDesc.localized
            )
            
            TermsSection(
                title: LocalizationKeys.limitationsOfLiability.localized,
                icon: "exclamationmark.triangle.fill",
                content: LocalizationKeys.limitationsOfLiabilityDesc.localized
            )
            
            TermsSection(
                title: LocalizationKeys.medicalAdvice.localized,
                icon: "cross.case.fill",
                content: LocalizationKeys.medicalAdviceDesc.localized
            )
            
            TermsSection(
                title: LocalizationKeys.intellectualProperty.localized,
                icon: "c.circle.fill",
                content: LocalizationKeys.intellectualPropertyDesc.localized
            )
            
            TermsSection(
                title: LocalizationKeys.modifications.localized,
                icon: "arrow.triangle.2.circlepath",
                content: LocalizationKeys.modificationsDesc.localized
            )
            
            TermsSection(
                title: LocalizationKeys.termination.localized,
                icon: "xmark.circle.fill",
                content: LocalizationKeys.terminationDesc.localized
            )
            
            TermsSection(
                title: LocalizationKeys.contact.localized,
                icon: "envelope.fill",
                content: LocalizationKeys.contactDesc.localized
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