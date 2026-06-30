//
//  SWAgreementChecker.swift
//  Horadrim
//
//  A checkbox row for agreeing to Terms of Service and Privacy Policy.
//  Displays a toggle circle icon and two tappable links. URLs are configurable
//  via termsURL and privacyURL parameters (defaults to https://horadrim.app/terms and /privacy).
//
//  Usage:
//    @State private var agreed = false
//
//    VStack {
//        // ... sign-in form ...
//
//        SWAgreementChecker(agreementChecked: $agreed)
//
//        Button("Sign In") { signIn() }
//            .disabled(!agreed)
//    }
//
//    // Custom URLs
//    SWAgreementChecker(
//        agreementChecked: $agreed,
//        termsURL: URL(string: "https://myapp.com/terms")!,
//        privacyURL: URL(string: "https://myapp.com/privacy")!
//    )
//
//  Parameters:
//    - agreementChecked: Binding<Bool> — Whether the user has checked the agreement checkbox
//    - termsURL: URL — Link destination for Terms of Service (default: https://horadrim.app/terms)
//    - privacyURL: URL — Link destination for Privacy Policy (default: https://horadrim.app/privacy)
//
//  Notes:
//    - Tap the circle icon to toggle the checked state
//    - Terms of Service and Privacy Policy are external links that open in the browser
//
//  Created by RyukieSama Zhong on 3/1/26.
//

import SwiftUI

struct SWAgreementChecker: View {
    @Binding var agreementChecked: Bool

    var termsURL: URL = URL(string: "https://horadrim.app/terms")!
    var privacyURL: URL = URL(string: "https://horadrim.app/privacy")!

    var body: some View {
        HStack(spacing: 6) {
            Button {
                agreementChecked.toggle()
            } label: {
                Image(systemName: agreementChecked ? "checkmark.circle.fill" : "circle")
                    .imageScale(.small)
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                Text("I agree to")
                    .foregroundStyle(.secondary)
                Link("Terms of Service", destination: termsURL)
                Text("and")
                    .foregroundStyle(.secondary)
                Link("Privacy Policy", destination: privacyURL)
            }
            .font(.caption2)
            .lineLimit(1)
        }
        .padding(.top, 4)
    }
}

#Preview {
    @Previewable @State var agreed = false

    SWAgreementChecker(agreementChecked: $agreed)
        .padding()
}
