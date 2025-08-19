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
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
            )
            .navigationTitle("Términos de Uso")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Cerrar") {
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
                
                Text("Términos y condiciones")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .primaryGradientText()
            }
            
            Text("Última actualización: Agosto 2025")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            TermsSection(
                title: "Aceptación de términos",
                icon: "checkmark.seal.fill",
                content: "Al usar Weight Progress Tracker, aceptas estos términos de uso. Si no estás de acuerdo con alguno de estos términos, no uses la aplicación."
            )
            
            TermsSection(
                title: "Uso de la aplicación",
                icon: "iphone",
                content: "Weight Progress Tracker está diseñada para el seguimiento personal del peso corporal. La aplicación es solo para uso informativo y no debe considerarse como consejo médico profesional."
            )
            
            TermsSection(
                title: "Responsabilidad del usuario",
                icon: "person.fill.checkmark",
                content: "Eres responsable de la precisión de los datos que ingresas. La aplicación no verifica la exactitud de la información proporcionada y no se hace responsable por decisiones tomadas basándose en estos datos."
            )
            
            TermsSection(
                title: "Limitaciones de responsabilidad",
                icon: "exclamationmark.triangle.fill",
                content: "Weight Progress Tracker se proporciona 'tal como está'. No garantizamos que la aplicación esté libre de errores o que funcione sin interrupciones. No somos responsables por pérdida de datos o daños derivados del uso de la aplicación."
            )
            
            TermsSection(
                title: "Consejo médico",
                icon: "cross.case.fill",
                content: "Esta aplicación no proporciona consejo médico. Siempre consulta con un profesional de la salud antes de tomar decisiones importantes sobre tu peso o salud. No uses esta aplicación como sustituto de atención médica profesional."
            )
            
            TermsSection(
                title: "Propiedad intelectual",
                icon: "c.circle.fill",
                content: "Todos los derechos de la aplicación Weight Progress Tracker están reservados. No puedes copiar, modificar, distribuir o crear trabajos derivados de la aplicación sin autorización expresa."
            )
            
            TermsSection(
                title: "Modificaciones",
                icon: "arrow.triangle.2.circlepath",
                content: "Nos reservamos el derecho de modificar estos términos en cualquier momento. Las actualizaciones se reflejarán en la fecha de 'última actualización'. El uso continuado de la aplicación constituye aceptación de los términos modificados."
            )
            
            TermsSection(
                title: "Terminación",
                icon: "xmark.circle.fill",
                content: "Puedes dejar de usar la aplicación en cualquier momento eliminándola de tu dispositivo. Nos reservamos el derecho de discontinuar la aplicación o sus servicios en cualquier momento."
            )
            
            TermsSection(
                title: "Contacto",
                icon: "envelope.fill",
                content: "Si tienes preguntas sobre estos términos de uso, puedes contactarnos a través de la App Store o los canales de soporte disponibles."
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

#if DEBUG
#Preview("Terms of Use • Dark") {
    TermsOfUseView()
        .preferredColorScheme(.dark)
}

#Preview("Terms of Use • Light") {
    TermsOfUseView()
        .preferredColorScheme(.light)
}
#endif