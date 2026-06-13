import SwiftUI

struct AuthView: View {
    @EnvironmentObject var session: SessionStore
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(isLoginMode ? "Login" : "Sign Up")
                    .font(.system(size: 36, weight: .bold))
                    .transition(.opacity)
                    .padding(.top, 60)
                
                VStack(spacing: 16) {
                    if !isLoginMode {
                        TextField("Username", text: $username)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                    }
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                
                Button(action: {
                    withAnimation {
                        if isLoginMode {
                            session.signIn(email: email, password: password)
                        } else {
                            session.signUp(email: email, password: password, username: username)
                        }
                    }
                }) {
                    Text(isLoginMode ? "Login" : "Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(
                            gradient: Gradient(colors: [Color("ButtonGradientStart"), Color("ButtonGradientEnd")]),
                            startPoint: .leading,
                            endPoint: .trailing))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                
                Button(action: {
                    withAnimation {
                        isLoginMode.toggle()
                    }
                }) {
                    Text(isLoginMode ? "Create an account" : "Already have an account?")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .appBackground()
        }
    }
}
