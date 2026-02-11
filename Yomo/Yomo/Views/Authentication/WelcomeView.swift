//
//  WelcomeView.swift
//  Yomo
//
//  Welcome screen with Google and Phone authentication (Screen 1)
//

import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var animateContent = false
    @State private var logoFloat = false

    private var showInternalTools: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-YOMOInternalTools")
        #else
        return false
        #endif
    }

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                Spacer()

                // Logo + Tagline
                VStack(spacing: Spacing.lg) {
                    Image("logo-nobg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .scaleEffect(animateContent ? 1 : 0.5)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: logoFloat ? -6 : 6)
                        .animation(
                            .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                            value: logoFloat
                        )

                    VStack(spacing: Spacing.sm) {
                        Text("Your moment.")
                            .font(.custom("Noteworthy-Bold", size: 30))
                            .foregroundColor(.textPrimary)

                        Text("Don't miss it.")
                            .font(.custom("Noteworthy-Light", size: 20))
                            .foregroundColor(.textSecondary)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 16)
                }

                Spacer()
                Spacer()

                // Auth Buttons
                VStack(spacing: Spacing.md) {
                    AuthButton(
                        title: "Continue with Google",
                        action: { viewModel.signInWithGoogle() },
                        icon: { GoogleLogo() }
                    )

                    AuthButton(
                        icon: "phone.fill",
                        title: "Continue with Phone"
                    ) {
                        viewModel.showPhoneInput = true
                    }

                    #if DEBUG
                    if showInternalTools {
                        Button(action: { viewModel.devLogin() }) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 14))
                                Text("Dev Login (Skip Auth)")
                                    .font(.bodySmall)
                            }
                            .foregroundColor(.textTertiary)
                            .padding(.vertical, Spacing.xs)
                        }
                    }
                    #endif
                }
                .padding(.horizontal, Spacing.xl)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 24)

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.bodySmall)
                        .foregroundColor(.dangerRed)
                        .padding(Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(Color.dangerRed.opacity(0.1))
                        )
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.sm)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.brandBlue)
                        .padding(.top, Spacing.md)
                }

                Spacer()
                    .frame(height: Spacing.lg)

                // Legal text
                Text("By continuing, you agree to our Terms of Service & Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.bottom, Spacing.lg)
                    .opacity(animateContent ? 1 : 0)
            }
        }
        .sheet(isPresented: $viewModel.showPhoneInput) {
            PhoneAuthFlowSheet(viewModel: viewModel)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                logoFloat = true
            }
        }
    }
}

// MARK: - Country Code Data
private struct CountryCode: Identifiable {
    let id = UUID()
    let flag: String
    let name: String
    let code: String
}

private let popularCountryCodes: [CountryCode] = [
    CountryCode(flag: "🇺🇸", name: "United States", code: "+1"),
    CountryCode(flag: "🇨🇳", name: "China", code: "+86"),
    CountryCode(flag: "🇬🇧", name: "United Kingdom", code: "+44"),
    CountryCode(flag: "🇯🇵", name: "Japan", code: "+81"),
    CountryCode(flag: "🇰🇷", name: "South Korea", code: "+82"),
    CountryCode(flag: "🇩🇪", name: "Germany", code: "+49"),
    CountryCode(flag: "🇫🇷", name: "France", code: "+33"),
    CountryCode(flag: "🇮🇳", name: "India", code: "+91"),
    CountryCode(flag: "🇧🇷", name: "Brazil", code: "+55"),
    CountryCode(flag: "🇦🇺", name: "Australia", code: "+61"),
    CountryCode(flag: "🇨🇦", name: "Canada", code: "+1"),
    CountryCode(flag: "🇲🇽", name: "Mexico", code: "+52"),
    CountryCode(flag: "🇸🇬", name: "Singapore", code: "+65"),
    CountryCode(flag: "🇭🇰", name: "Hong Kong", code: "+852"),
    CountryCode(flag: "🇹🇼", name: "Taiwan", code: "+886"),
    CountryCode(flag: "🇮🇹", name: "Italy", code: "+39"),
    CountryCode(flag: "🇪🇸", name: "Spain", code: "+34"),
    CountryCode(flag: "🇳🇱", name: "Netherlands", code: "+31"),
    CountryCode(flag: "🇷🇺", name: "Russia", code: "+7"),
    CountryCode(flag: "🇹🇭", name: "Thailand", code: "+66"),
    CountryCode(flag: "🇵🇭", name: "Philippines", code: "+63"),
    CountryCode(flag: "🇮🇩", name: "Indonesia", code: "+62"),
    CountryCode(flag: "🇻🇳", name: "Vietnam", code: "+84"),
    CountryCode(flag: "🇲🇾", name: "Malaysia", code: "+60"),
    CountryCode(flag: "🇳🇿", name: "New Zealand", code: "+64"),
]

// MARK: - Country Picker Sheet
private struct CountryPickerSheet: View {
    @Binding var selectedCountry: CountryCode
    @Binding var isPresented: Bool
    @State private var searchText = ""

    private var filteredCountries: [CountryCode] {
        if searchText.isEmpty { return popularCountryCodes }
        let query = searchText.lowercased()
        return popularCountryCodes.filter {
            $0.name.lowercased().contains(query) || $0.code.contains(query)
        }
    }

    var body: some View {
        NavigationView {
            List(filteredCountries) { country in
                Button {
                    selectedCountry = country
                    isPresented = false
                } label: {
                    HStack {
                        Text(country.flag)
                            .font(.system(size: 24))
                        Text(country.name)
                            .font(.bodyRegular)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text(country.code)
                            .font(.bodyRegular)
                            .foregroundColor(.textSecondary)
                        if country.code == selectedCountry.code && country.name == selectedCountry.name {
                            Image(systemName: "checkmark")
                                .foregroundColor(.brandBlue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .searchable(text: $searchText, prompt: "Search country")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}

// MARK: - Phone Auth Flow Sheet
struct PhoneAuthFlowSheet: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: FocusedField?

    @State private var step: Step = .enterPhone
    @State private var selectedCountry = popularCountryCodes[0]
    @State private var showCountryPicker = false
    @State private var localNumber = ""

    private enum Step {
        case enterPhone
        case enterCode
    }

    private enum FocusedField {
        case phone
        case code
    }

    private var localDigits: String {
        localNumber.filter(\.isNumber)
    }

    private var fullPhoneNumber: String {
        selectedCountry.code + localDigits
    }

    private var isSendDisabled: Bool {
        localDigits.isEmpty
    }

    private var isVerifyDisabled: Bool {
        viewModel.verificationCode.count != 6
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    switch step {
                    case .enterPhone:
                        phoneStep
                    case .enterCode:
                        codeStep
                    }
                }
                .padding(.top, Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brandBlue)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    if step == .enterCode {
                        Button("Back") { backToPhone() }
                            .foregroundColor(.brandBlue)
                    }
                }
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerSheet(
                    selectedCountry: $selectedCountry,
                    isPresented: $showCountryPicker
                )
            }
        }
        .onAppear {
            resetFlow()
        }
        .onChange(of: viewModel.verificationID) { verificationID in
            guard verificationID != nil else { return }
            step = .enterCode
            focusedField = .code
        }
        .onChange(of: viewModel.isAuthenticated) { isAuthed in
            if isAuthed {
                dismiss()
            }
        }
    }

    private var phoneStep: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xs) {
                Text("Enter your phone number")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)

                Text("We'll send a 6-digit code via SMS.")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }

            HStack(spacing: Spacing.sm) {
                Button {
                    showCountryPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCountry.flag)
                            .font(.system(size: 20))
                        Text(selectedCountry.code)
                            .font(.bodyRegular)
                            .foregroundColor(.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.horizontal, Spacing.sm + 2)
                    .padding(.vertical, Spacing.sm + 2)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                            .fill(Color.brandBlueBg)
                    )
                }

                TextField("Phone number", text: $localNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .focused($focusedField, equals: .phone)
                    .font(.bodyRegular)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm + 2)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                            .fill(Color.brandBlueBg)
                    )
                    .onChange(of: localNumber) { newValue in
                        let filtered = String(newValue.filter(\.isNumber).prefix(15))
                        if filtered != newValue {
                            localNumber = filtered
                        }
                    }
            }
            .padding(.horizontal, Spacing.lg)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.bodySmall)
                    .foregroundColor(.dangerRed)
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.dangerRed.opacity(0.1))
                    )
                    .padding(.horizontal, Spacing.lg)
            }

            PrimaryButton(
                "Send Code",
                isLoading: viewModel.isLoading,
                isDisabled: isSendDisabled
            ) {
                viewModel.phoneNumber = fullPhoneNumber
                viewModel.startPhoneAuth()
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()
        }
        .onAppear {
            focusedField = .phone
        }
    }

    private var codeStep: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xs) {
                Text("Enter verification code")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)

                if !viewModel.phoneNumber.isEmpty {
                    Text("Sent to \(viewModel.phoneNumber)")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
            }

            TextField("123456", text: $viewModel.verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focusedField, equals: .code)
                .font(.bodyRegular)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm + 2)
                        .fill(Color.brandBlueBg)
                )
                .padding(.horizontal, Spacing.lg)
                .onChange(of: viewModel.verificationCode) { newValue in
                    let filtered = String(newValue.filter(\.isNumber).prefix(6))
                    if filtered != newValue {
                        viewModel.verificationCode = filtered
                    }
                }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.bodySmall)
                    .foregroundColor(.dangerRed)
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.dangerRed.opacity(0.1))
                    )
                    .padding(.horizontal, Spacing.lg)
            }

            PrimaryButton(
                "Verify",
                isLoading: viewModel.isLoading,
                isDisabled: isVerifyDisabled
            ) {
                viewModel.verifyCode()
            }
            .padding(.horizontal, Spacing.lg)

            Button {
                viewModel.errorMessage = nil
                viewModel.startPhoneAuth()
            } label: {
                Text("Resend Code")
                    .font(.bodySmall)
                    .foregroundColor(.brandBlue)
            }
            .disabled(viewModel.isLoading || viewModel.phoneNumber.isEmpty)
            .padding(.top, Spacing.xs)

            Spacer()
        }
        .onAppear {
            focusedField = .code
        }
    }

    private func resetFlow() {
        step = .enterPhone
        selectedCountry = popularCountryCodes[0]
        localNumber = ""
        viewModel.phoneNumber = ""
        viewModel.verificationCode = ""
        viewModel.verificationID = nil
        viewModel.errorMessage = nil
    }

    private func backToPhone() {
        step = .enterPhone
        viewModel.verificationCode = ""
        viewModel.verificationID = nil
        viewModel.errorMessage = nil
        focusedField = .phone
    }
}

#Preview {
    WelcomeView()
}
