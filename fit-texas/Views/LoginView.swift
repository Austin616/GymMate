//
//  LoginView.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var showSignup: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @FocusState private var focusedField: Field?
  
    enum Field {
        case email, password
    }
  
    var body: some View {
        ZStack {
            // Background gradient
            ScrollView {
                VStack(spacing: 24) {
                    // Logo/Icon placeholder
                    Image(systemName: "figure.strengthtraining.traditional")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.utOrange)
                        .padding(.top, 60)
                
                    // Title Section
                    VStack(spacing: 8) {
                        Text("Welcome to LiftUT")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    
                        Text("Track your fitness journey")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                
                    // Error Message
                    if showError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                    }
                
                    // Input Fields
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                            
                                TextField("Enter your email", text: $email)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .password
                                    }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                            
                                if isPasswordVisible {
                                    TextField("Enter your password", text: $password)
                                        .textContentType(.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            handleLogin()
                                        }
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .textContentType(.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            handleLogin()
                                        }
                                }
                            
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)
                
                    // Forgot Password
                    HStack {
                        Spacer()
                        Button(action: {
                            handleForgotPassword()
                        }) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.utOrange)
                        }
                    }
                    .padding(.horizontal, 24)
                
                    // Login Button
                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Log In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isFormValid ? Color.utOrange : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: isFormValid ? .utOrange.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                
                    // Sign Up Link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                    
                        Button(action: {
                            showSignup = true
                        }) {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.utOrange)
                        }
                    }
                    .font(.subheadline)
                    .padding(.top, 16)
                
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showSignup) {
            SignupView()
        }
    }
  
    // MARK: - Computed Properties
  
    var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }
  
    // MARK: - Methods
  
    private func handleLogin() {
        guard isFormValid else { return }
    
        isLoading = true
        showError = false
        focusedField = nil
    
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            isLoading = false
            
            if let error = error {
                handleAuthError(error)
                return
            }
            
            // AuthManager will automatically update and show TabView
        }
    }
    
    private func handleForgotPassword() {
        guard !email.isEmpty, email.contains("@") else {
            errorMessage = "Please enter a valid email address first"
            showError = true
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            } else {
                errorMessage = "Password reset email sent! Check your inbox."
                showError = true
            }
        }
    }
    
    private func handleAuthError(_ error: Error) {
        let nsError = error as NSError
        
        if let errorCode = AuthErrorCode(rawValue: nsError.code) {
            switch errorCode {
            case .wrongPassword:
                errorMessage = "Incorrect password. Please try again."
            case .invalidEmail:
                errorMessage = "Invalid email address format."
            case .userNotFound:
                errorMessage = "No account found with this email."
            case .userDisabled:
                errorMessage = "This account has been disabled."
            case .networkError:
                errorMessage = "Network error. Check your connection."
            case .tooManyRequests:
                errorMessage = "Too many attempts. Try again later."
            default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        showError = true
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
