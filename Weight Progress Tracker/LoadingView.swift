//
//  LoadingView.swift
//  Weight Progress Tracker
//
//  Created by Weight Progress Tracker on 2024.
//

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Fondo limpio y minimalista
            Color.black
                .ignoresSafeArea()
            
            // Partículas de fondo modernas
            ParticlesView()
                .ignoresSafeArea()
                .opacity(0.6)
            
            // Loader personalizado
            CustomLoader()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleInAnimation(delay: 0.2)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    LoadingView()
}
