//
//  SignupView.swift
//  fit-texas
//
//  Created by Austin Tran on 11/18/25.
//

import SwiftUI
import FirebaseAuth

struct SignupView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var agreeToTerms: Bool = false
    @State private var showLogin: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    
    enum Field {
        case fullName, email, password, confirmPassword
    }
    
    var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo/Icon placeholder
                    Image(systemName: "figure.strengthtraining.traditional")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.utOrange)
                        .padding(.top, 40)
                    
                    // Title Section
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Start your fitness journey today")
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
                        // Full Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                TextField("Enter your full name", text: $fullName)
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .focused($focusedField, equals: .fullName)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .email
                                    }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
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
                                
                                // Email validation indicator
                                if !email.isEmpty {
                                    Image(systemName: isValidEmail ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isValidEmail ? .green : .red)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            
                            if !email.isEmpty && !isValidEmail {
                                Text("Please enter a valid email address")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
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
                                    TextField("Create a password", text: $password)
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .confirmPassword
                                        }
                                } else {
                                    SecureField("Create a password", text: $password)
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .confirmPassword
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
                            
                            // Password strength indicators
                            if !password.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    PasswordRequirement(
                                        text: "At least 8 characters",
                                        isMet: password.count >= 8
                                    )
                                    PasswordRequirement(
                                        text: "Contains a number",
                                        isMet: password.range(of: #"\d"#, options: .regularExpression) != nil
                                    )
                                    PasswordRequirement(
                                        text: "Contains an uppercase letter",
                                        isMet: password.range(of: #"[A-Z]"#, options: .regularExpression) != nil
                                    )
                                }
                                .font(.caption)
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                if isConfirmPasswordVisible {
                                    TextField("Re-enter your password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            handleSignup()
                                        }
                                } else {
                                    SecureField("Re-enter your password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            handleSignup()
                                        }
                                }
                                
                                // Password match indicator
                                if !confirmPassword.isEmpty {
                                    Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(passwordsMatch ? .green : .red)
                                }
                                
                                Button(action: {
                                    isConfirmPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            
                            if !confirmPassword.isEmpty && !passwordsMatch {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Terms and Conditions Toggle
                    HStack(spacing: 8) {
                        Button(action: {
                            agreeToTerms.toggle()
                        }) {
                            Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(agreeToTerms ? .utOrange : .gray)
                        }
                        
                        Text("I agree to the Terms and Conditions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    
                    // Sign Up Button
                    Button(action: handleSignup) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
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
                    
                    // Login Link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Log In")
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
    
    // MARK: - Computed Properties
    
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    var isValidPassword: Bool {
        password.count >= 8 &&
        password.range(of: #"\d"#, options: .regularExpression) != nil &&
        password.range(of: #"[A-Z]"#, options: .regularExpression) != nil
    }
    
    var passwordsMatch: Bool {
        !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }
    
    var isFormValid: Bool {
        !fullName.isEmpty &&
        isValidEmail &&
        isValidPassword &&
        passwordsMatch &&
        agreeToTerms
    }
    
    // MARK: - Methods
    
    private func handleSignup() {
        guard isFormValid else { return }
        
        isLoading = true
        showError = false
        focusedField = nil
        
        // Create user with Firebase Auth
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                handleAuthError(error)
                isLoading = false
                return
            }
            
            // Update user's display name
            guard let user = authResult?.user else {
                isLoading = false
                return
            }
            
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            changeRequest.commitChanges { error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Account created but failed to set name: \(error.localizedDescription)"
                    showError = true
                } else {
                    // Successfully created account with display name
                    // AuthManager will automatically detect and show TabView
                    dismiss()
                }
            }
        }
    }
    
    private func handleAuthError(_ error: Error) {
        let nsError = error as NSError
        
        if let errorCode = AuthErrorCode(rawValue: nsError.code) {
            switch errorCode {
            case .emailAlreadyInUse:
                errorMessage = "This email is already registered. Please log in."
            case .invalidEmail:
                errorMessage = "Invalid email address format."
            case .weakPassword:
                errorMessage = "Password is too weak. Please choose a stronger password."
            case .networkError:
                errorMessage = "Network error. Check your connection."
            case .operationNotAllowed:
                errorMessage = "Email/password sign up is not enabled."
            default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        showError = true
    }
}

// MARK: - Supporting Views

struct PasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
                .font(.caption)
            
            Text(text)
                .foregroundColor(isMet ? .green : .secondary)
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthManager())
}
