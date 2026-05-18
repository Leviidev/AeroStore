//
//  ScriptEditorView.swift
//  StikDebug
//
//  Created by s s on 2025/7/4.
//

import SwiftUI

struct ScriptEditorView: View {
    let scriptURL: URL

    @State private var scriptContent: String = ""
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TextEditor(text: $scriptContent)
                    .font(.system(.footnote, design: .monospaced))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollContentBackground(.hidden)
                    .background(Color(UIColor.systemBackground))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationTitle(scriptURL.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadScript)
        .toolbar(content: {
            SwiftUI.ToolbarItem(placement: .confirmationAction) {
                SwiftUI.Button(action: saveAndDismiss) {
                    SwiftUI.Text("Save")
                }
            }
        })
        .tint(colorScheme == .dark ? .white : .black)
        .toolbar(.hidden, for: .tabBar)
    }

    private func loadScript() {
        scriptContent = (try? String(contentsOf: scriptURL)) ?? ""
    }

    private func saveScript() {
        try? scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
    }

    private func saveAndDismiss() {
        saveScript()
        dismiss()
    }
}
