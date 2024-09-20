//
//  LogView.swift
//  mkepub
//
//  Created by Rumpel Stiltskin on 16.09.2024.
//
//import SwiftUI
import Combine
import SwiftUI
import AppKit

class LogWindowController: NSWindowController {
    // Singleton instance to manage the log window
    static let shared = LogWindowController()

    private override init(window: NSWindow?) {
        let logView = LogView()
        let hostingController = NSHostingController(rootView: logView)

        // Create a window for the log
        let window = NSWindow(
            contentViewController: hostingController
        )
        window.title = "Log Window"
        window.setContentSize(NSSize(width: 400, height: 300))
        window.styleMask = [.titled, .closable, .resizable]
        window.center()

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Function to open the log window
    func openLogWindow() {
        showWindow(nil)
    }

    // Function to close the log window
    func closeLogWindow() {
        close()
    }
}


class LogManager: ObservableObject {
    // Published property that the view will observe
    @Published var logMessages: String = ""

    // Append a new log message
    func log(_ message: String) {
        DispatchQueue.main.async {
            // Append the new message, followed by a new line
            self.logMessages += "\(message)\n"
        }
    }
}

// Create a global instance of the LogManager to use throughout the app
let logger = LogManager()

struct LogView: View {
    @ObservedObject var logManager = logger

    var body: some View {
        VStack {
            ScrollView {
                Text(logManager.logMessages)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .border(Color.gray, width: 1)
            .frame(height: 200) // Adjust the height of the log area
            .padding()

            // Close button
            Button("Close") {
                LogWindowController.shared.closeLogWindow() // Close the window
            }
            .padding()
        }
    }
}
