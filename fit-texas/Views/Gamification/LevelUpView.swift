//
//  LevelUpView.swift
//  fit-texas
//
//  Created by GymMate
//

import SwiftUI

struct LevelUpView: View {
    let newLevel: Int
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    
    private var levelTitle: String {
        LevelSystem.levelTitle(for: newLevel)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // Confetti
            if showConfetti {
                ConfettiView()
            }
            
            // Content
            VStack(spacing: 24) {
                Spacer()
                
                // Level Badge
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.utOrange.opacity(0.5), Color.clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    // Badge
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.utOrange, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: Color.utOrange.opacity(0.6), radius: 30, x: 0, y: 10)
                    
                    // Level Number
                    Text("\(newLevel)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0.0)
                
                // Text
                VStack(spacing: 8) {
                    Text("LEVEL UP!")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("You reached Level \(newLevel)")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(levelTitle)
                        .font(.headline)
                        .foregroundColor(.utOrange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                        .padding(.top, 8)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
                // Dismiss Button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.utOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                .opacity(showContent ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    private func createConfetti() {
        let colors: [Color] = [.utOrange, .orange, .yellow, .white, .red]
        
        for _ in 0..<50 {
            let piece = ConfettiPiece(
                id: UUID(),
                color: colors.randomElement()!,
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: -50,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.0)
            )
            confettiPieces.append(piece)
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    let color: Color
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var scale: CGFloat
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 10 * piece.scale, height: 10 * piece.scale)
            .position(x: piece.x, y: piece.y + yOffset)
            .rotationEffect(.degrees(piece.rotation + rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: Double.random(in: 2...4))) {
                    yOffset = UIScreen.main.bounds.height + 100
                    rotation = Double.random(in: 180...720)
                }
                
                withAnimation(.linear(duration: 3).delay(1)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Level Up Overlay Modifier

struct LevelUpOverlayModifier: ViewModifier {
    @Binding var isPresented: Bool
    let level: Int
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                LevelUpView(newLevel: level) {
                    withAnimation {
                        isPresented = false
                    }
                }
                .transition(.opacity)
                .zIndex(1000)
            }
        }
    }
}

extension View {
    func levelUpOverlay(isPresented: Binding<Bool>, level: Int) -> some View {
        modifier(LevelUpOverlayModifier(isPresented: isPresented, level: level))
    }
}

#Preview {
    LevelUpView(newLevel: 5, onDismiss: {})
}
