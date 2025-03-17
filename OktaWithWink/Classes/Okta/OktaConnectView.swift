import SwiftUI

// Define the protocol to include username and password
protocol OktaConnectDelegate: AnyObject {
    func didCompleteOktaLogin(success: Bool, username: String?, password: String?)
}

struct OktaConnectView: View {
    // State variables
    @State private var emailOrUsername: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    var preFilledEmail: String?
    // Delegate to communicate back to the view controller
    weak var delegate: OktaConnectDelegate?

    var body: some View {
        VStack(spacing: 20) {
            Spacer() // Pushes content down to center vertically

            // Header
            Text("Connect with Okta")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Email/Username TextField with icon
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                TextField("Email or Username", text: $emailOrUsername)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onAppear {
                                        // Pre-fill the text field with the provided email
                                        if let email = preFilledEmail {
                                            emailOrUsername = email
                                        }
                                    }
            }
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
            .padding(.horizontal)

            // Password TextField with eye icon to toggle visibility and lock icon
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                if isPasswordVisible {
                    TextField("Password", text: $password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField("Password", text: $password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
            .padding(.horizontal)



            // Confirm Button
            Button(action: {
               // validatePasswords()
                performAPICall()
            }) {
                Text("Confirm")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }

            Spacer() // Pushes content up to center vertically
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fills the screen to center content
        .background(Color.white) // Optional: set background color
        .ignoresSafeArea(.keyboard, edges: .bottom) // Handle keyboard appearing
    }

    // Function to validate passwords and make API call
    private func validatePasswords() {
        if password != confirmPassword {
            alertMessage = "Passwords do not match!"
            showAlert = true
        } else {
            // Perform API call here
            performAPICall()
        }
    }

    // Placeholder for API call
    private func performAPICall() {
        // Simulate a successful API call after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Notify the delegate that login is complete, passing the username and password
            delegate?.didCompleteOktaLogin(success: true, username: emailOrUsername, password: password)
        }
    }
}

struct OktaConnectView_Previews: PreviewProvider {
    static var previews: some View {
        OktaConnectView()
    }
}
