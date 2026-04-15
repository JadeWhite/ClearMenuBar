//
//  PreferencesView.swift
//  Clear Menu Bar
//
//  Created by zorth64 on 11/03/26.
//

import SwiftUI
import Swinject
import Schwifty

struct PreferencesView: View {
    var body: some View {
        VStack(spacing: 30) {
            AllowReduceTransparencyDisabledSection()
        }
        .padding(50)
    }
}

private struct AllowReduceTransparencyDisabledSection: View {
    @StateObject private var appState: AppState = Container.main.resolve(AppState.self)!
    
    var body: some View {
        FormField(
            title: "Allows Reduce Transparency to be Disabled (Experimental)",
            hint: "This option will try to create a modified version of the current wallpaper to allow this application to work with the Reduce Transparency accessibility option disabled. If the application has any problems, disable this option and enable the Reduce Transparency option in the Accessibility section of the System Settings application.") {
                Toggle(isOn: $appState.allowReduceTransparencyToBeDisabled, label: { EmptyView() })
                    .toggleStyle(.switch)
                    .positioned(.trailing)
            }
    }
}

private struct FormField<Content: View>: View {
    let title: String
    var titleWidth: CGFloat = 350
    var contentWidth: CGFloat = 100
    var hint: String?
    let content: () -> Content
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 16) {
                Text(title)
                    .textAlign(.leading)
                    .frame(width: titleWidth)
                content()
                    .frame(width: contentWidth)
            }
            if let hint {
                Text(hint)
                    .font(.caption)
                    .textAlign(.leading)
            }
        }
        .frame(width: titleWidth + 16 + contentWidth)
    }
}
