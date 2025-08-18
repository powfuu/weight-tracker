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
                Color(.systemBackground)
                    .ignoresSafeArea()
            )
            .navigationTitle("Política de Privacidad")
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
                Image(systemName: "shield.checkered")
                    .font(.title)
                    .foregroundColor(.teal)
                
                Text("Tu privacidad es importante")
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
    
    private var policyContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            PolicySection(
                title: "Información que recopilamos",
                icon: "doc.text.fill",
                content: "Weight Progress Tracker solo almacena los datos de peso que tú ingresas voluntariamente. Toda la información se guarda localmente en tu dispositivo y no se envía a servidores externos."
            )
            
            PolicySection(
                title: "Cómo usamos tu información",
                icon: "chart.line.uptrend.xyaxis",
                content: "Tus datos de peso se utilizan únicamente para generar gráficos, estadísticas y seguimiento de progreso dentro de la aplicación. No compartimos, vendemos ni transferimos tu información a terceros."
            )
            
            PolicySection(
                title: "Almacenamiento de datos",
                icon: "internaldrive.fill",
                content: "Todos tus datos se almacenan localmente en tu dispositivo usando Core Data de Apple. No utilizamos servicios en la nube ni bases de datos externas para almacenar tu información personal."
            )
            
            PolicySection(
                title: "Notificaciones",
                icon: "bell.fill",
                content: "Si habilitas las notificaciones, solo se enviarán recordatorios locales para ayudarte a mantener tu rutina de seguimiento. No recopilamos información sobre tus hábitos de notificación."
            )
            
            PolicySection(
                title: "Exportación de datos",
                icon: "square.and.arrow.up",
                content: "Puedes exportar tus datos en cualquier momento en formato CSV o JSON. Esta función te permite mantener el control total sobre tu información y crear respaldos cuando lo desees."
            )
            
            PolicySection(
                title: "Eliminación de datos",
                icon: "trash.fill",
                content: "Puedes eliminar todos tus datos en cualquier momento desde la configuración de la aplicación. Esta acción es irreversible y eliminará permanentemente toda tu información."
            )
            
            PolicySection(
                title: "Contacto",
                icon: "envelope.fill",
                content: "Si tienes preguntas sobre esta política de privacidad o sobre cómo manejamos tus datos, puedes contactarnos a través de la App Store."
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
                .fill(Color(.systemGray6))
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