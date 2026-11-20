import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var auth

    private enum Step { case email, code }
    @State private var step: Step = .email
    @State private var email = ""
    @State private var code = ""
    @State private var isLoading = false
    @State private var errorText: String?

    private var emailValid: Bool { email.contains("@") && email.contains(".") }

    var body: some View {
        VStack(spacing: 24) {
            if step == .code {
                HStack {
                    Button { step = .email; code = "" } label: { Image(systemName: "arrow.left") }
                    Spacer()
                }
            }
            Spacer()
            Image(systemName: "car.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white)
                .frame(width: 110, height: 110)
                .background(RoundedRectangle(cornerRadius: 28).fill(Color.brand))

            if step == .email { emailStep } else { codeStep }
            Spacer()
        }
        .padding(24)
    }

    private var emailStep: some View {
        VStack(spacing: 20) {
            Text("Welcome to Auto Care Tracker")
                .font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text("Know your car’s wear before it fails.")
                .foregroundStyle(.secondary)
            TextField("Email address", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .fieldStyle()
            Button {
                isLoading = true
                Task {
                    await auth.sendCode(to: email)
                    isLoading = false
                    step = .code
                }
            } label: {
                Text(isLoading ? L.text("Sending…") : L.text("Send code"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!emailValid || isLoading)
            Text("No passwords. Just a code sent to your email.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var codeStep: some View {
        VStack(spacing: 20) {
            Text("Check your email").font(.largeTitle.bold())
            Text("We sent an 8-digit code to \(email)")
                .multilineTextAlignment(.center)
            TextField("Enter code", text: $code)
                .keyboardType(.numberPad)
                .fieldStyle()
            if let errorText {
                Text(errorText).font(.footnote).foregroundStyle(.red)
            }
            Button {
                isLoading = true
                Task {
                    let ok = await auth.verify(code: code, email: email)
                    isLoading = false
                    errorText = ok ? nil : L.text("Enter the 8-digit code.")
                }
            } label: {
                Text(isLoading ? L.text("Checking…") : L.text("Confirm and sign in"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(code.count != 8 || isLoading)
            Button("Resend code") { Task { await auth.sendCode(to: email) } }
        }
    }
}
