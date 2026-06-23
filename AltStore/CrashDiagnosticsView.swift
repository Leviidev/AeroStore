import SwiftUI

struct CrashDiagnosticsView: View {
    let report: CrashReport
    let onContinue: () -> Void

    @State private var isCopied = false

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f.string(from: report.timestamp)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.orange)
                            .padding(.top, 8)

                        Text("Previous Launch Crashed")
                            .font(.title2.bold())

                        Text("AeroStore detected that it crashed on the previous launch without generating a system crash log. The details below can help diagnose the issue.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)

                    // Crash details card
                    CardSection(title: "Crash Details", icon: "ant.fill") {
                        DiagRow(label: "Crashed in", value: report.crashedComponent)
                        DiagRow(label: "Detected",   value: formattedDate)
                        DiagRow(label: "Device",     value: report.deviceModel)
                        DiagRow(label: "OS",         value: report.iOSVersion)
                    }

                    // Explanation
                    CardSection(title: "Why no crash log?", icon: "questionmark.circle") {
                        Text("""
When the Rust idevice library encounters an unrecoverable error — \
for example, a restricted kernel API on iOS 26, a missing pairing file, \
or a sandboxing violation — it calls process::abort() directly.

abort() terminates the process immediately, bypassing the iOS crash \
reporter, CocoaCrashKit, and all Swift error handlers. This is why \
no crash log appears in Xcode Organizer or the device console.
""")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }

                    // What to try
                    CardSection(title: "Suggested steps", icon: "list.bullet.rectangle") {
                        VStack(alignment: .leading, spacing: 6) {
                            StepRow(n: 1, text: "Tap \"Continue Anyway\" — the crash guard has been cleared and will not repeat until a new Rust call is attempted.")
                            StepRow(n: 2, text: "If it crashes again, note which component appears next time (tunnel vs mount check vs launch setup).")
                            StepRow(n: 3, text: "Copy the debug info below and share it in the issue tracker.")
                        }
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        SwiftUI.Button {
                            UIPasteboard.general.string = CrashReportStore.debugText(for: report)
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                isCopied = false
                            }
                        } label: {
                            Label(
                                isCopied ? "Copied to clipboard!" : "Copy Debug Info",
                                systemImage: isCopied ? "checkmark.circle.fill" : "doc.on.doc"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(isCopied ? .green : .accentColor)
                        .animation(.default, value: isCopied)

                        SwiftUI.Button {
                            onContinue()
                        } label: {
                            Text("Continue Anyway")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
            .navigationTitle("Crash Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Sub-views

private struct CardSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
            Divider()
            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

private struct DiagRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.caption.monospaced())
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

private struct StepRow: View {
    let n: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.accentColor)
                .clipShape(Circle())
            Text(text)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
