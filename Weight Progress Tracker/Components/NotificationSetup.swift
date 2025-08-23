//
//  NotificationSetup.swift
//  Weight Progress Tracker
//
//  Created by Weight Progress Tracker on 2024.
//

import SwiftUI
import UserNotifications

struct NotificationSetup: View {
    @Binding var notificationsEnabled: Bool
    @Binding var notificationTime: Date
    @State private var showingTimePicker = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Título
            Text(LocalizationKeys.notifications.localized)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(LocalizationKeys.notificationsDesc.localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Configuración de notificaciones
            VStack(spacing: 16) {
                // Toggle principal
                NotificationToggleCard(
                    isEnabled: $notificationsEnabled,
                    onToggle: {
                        if !notificationsEnabled {
                            // Si se está activando, solicitar permisos
                            requestNotificationPermission()
                        } else {
                            // Si se está desactivando, simplemente cambiar el estado
                            withAnimation(.easeInOut(duration: 0.3)) {
                                notificationsEnabled = false
                            }
                        }
                    }
                )
                
                // Configuración de hora (solo si están habilitadas)
                if notificationsEnabled {
                    TimeSelectionCard(
                        selectedTime: $notificationTime,
                        showingTimePicker: $showingTimePicker
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal)
            
            // Información adicional
            NotificationInfoCard()
                .padding(.horizontal)
            
            Spacer(minLength: 20)
        }
        .padding(.top, 20)
        .animation(.easeInOut(duration: 0.3), value: notificationsEnabled)
        .alert(LocalizationManager.shared.localizedString(for: "notification_permission_title"), isPresented: $showingPermissionAlert) {
            Button(LocalizationManager.shared.localizedString(for: LocalizationKeys.ok)) { }
        } message: {
            Text(LocalizationManager.shared.localizedString(for: "notification_permission_message"))
        }
    }
    
    // MARK: - Private Methods
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        notificationsEnabled = true
                    }
                } else {
                    // Si no se conceden permisos, mostrar alerta y mantener desactivado
                    showingPermissionAlert = true
                    notificationsEnabled = false
                }
            }
        }
    }
}

struct NotificationToggleCard: View {
    @Binding var isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: isEnabled ? "bell.fill" : "bell")
                            .font(.title2)
                            .foregroundColor(isEnabled ? .white : .teal)
                        
                        Text(LocalizationKeys.enableNotifications.localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isEnabled ? .white : .primary)
                    }
                    
                    Text(LocalizationKeys.notificationDailyReminder.localized)
                        .font(.caption)
                        .foregroundColor(isEnabled ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Toggle visual
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isEnabled ? Color.white.opacity(0.3) : Color.gray.opacity(0.3))
                        .frame(width: 50, height: 30)
                    
                    Circle()
                        .fill(isEnabled ? Color.black : Color.gray)
                        .frame(width: 26, height: 26)
                        .offset(x: isEnabled ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: isEnabled)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isEnabled ?
                        LinearGradient(
                            colors: [Color.teal, Color.teal.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isEnabled ? Color.teal : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isEnabled ? 1.02 : 1.0)
            .shadow(
                color: isEnabled ? Color.teal.opacity(0.3) : Color.black.opacity(0.1),
                radius: isEnabled ? 8 : 4,
                x: 0,
                y: isEnabled ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct TimeSelectionCard: View {
    @Binding var selectedTime: Date
    @Binding var showingTimePicker: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingTimePicker.toggle()
            }) {
                HStack {
                    Image(systemName: "clock")
                        .font(.title3)
                        .foregroundColor(.teal)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizationKeys.notificationTime.localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text(timeFormatter.string(from: selectedTime))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.teal)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showingTimePicker ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: showingTimePicker)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if showingTimePicker {
                DatePicker(
                    "",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .environment(\.locale, localizationManager.currentLanguage.locale)
                .preferredColorScheme(.dark)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct NotificationInfoCard: View {
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizationKeys.notificationImportantInfo.localized)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                
                Text(LocalizationKeys.notificationHabitHelp.localized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

#Preview {
    NotificationSetup(
        notificationsEnabled: .constant(false),
        notificationTime: .constant(Date())
    )
    .padding()
    .background(Color.black)
}