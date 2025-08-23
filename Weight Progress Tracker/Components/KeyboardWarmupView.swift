//
//  KeyboardWarmupView.swift
//  Weight Progress Tracker
//
//  Created by Weight Progress Tracker on 2024.
//

import SwiftUI
// import UIKit // Comentado temporalmente para depuración

/// Vista para pre-calentar el teclado y eliminar el hang del primer toque
/*
struct KeyboardWarmupView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> KeyboardWarmupTextField {
        return KeyboardWarmupTextField()
    }
    
    func updateUIView(_ uiView: KeyboardWarmupTextField, context: Context) {
        // No necesita actualizaciones
    }
}

/// TextField oculto que pre-calienta el teclado al aparecer
final class KeyboardWarmupTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextField()
    }
    
    private func setupTextField() {
        // Configurar como invisible pero funcional
        isHidden = true
        alpha = 0
        frame = CGRect(x: -1000, y: -1000, width: 1, height: 1)
        
        // Configurar tipo de teclado para pre-calentar el decimal pad
        keyboardType = .decimalPad
        autocorrectionType = .no
        autocapitalizationType = .none
        
        // Evitar que interfiera con la UI
        isUserInteractionEnabled = false
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        guard window != nil else { return }
        
        // Pre-calentar el teclado de forma asíncrona
        DispatchQueue.main.async { [weak self] in
            self?.becomeFirstResponder()
            
            // Resignar inmediatamente para no mostrar el teclado
            DispatchQueue.main.async {
                self?.resignFirstResponder()
            }
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        // Solo permitir si la ventana está disponible
        guard window != nil else { return false }
        return super.becomeFirstResponder()
    }
}
*/

// Placeholder para evitar errores de compilación
struct KeyboardWarmupView: View {
    var body: some View {
        EmptyView()
    }
}

/*
#Preview {
    VStack {
        Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.keyboardWarmupHidden))
            .padding()
        
        KeyboardWarmupView()
    }
}
*/