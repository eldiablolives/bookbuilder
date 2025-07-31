import SwiftUI
import WebKit

struct ContentView: View {
//    @StateObject var fileHelper = FileHelper()
    @EnvironmentObject var fileHelper: FileHelper
    @State private var selectedTab = "eBook"   // For Export Types tab

    @State private var dividerPosition: CGFloat = 0.3  // Left divider
    @State private var dividerPositionRight: CGFloat = 0.7  // Right divider
    @State private var isHoveringOverDivider: Bool = false
    @State private var initialDividerPosition: CGFloat = 0.3
    @State private var initialDividerPositionRight: CGFloat = 0.7

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left panel
                FileBrowserView(
                    fileHelper: fileHelper,
                    dividerPosition: $dividerPosition,
                    isHoveringOverDivider: $isHoveringOverDivider,
                    initialDividerPosition: $initialDividerPosition,
                    dividerPositionRight: $dividerPositionRight,
                    geometry: geometry
                )
                .frame(width: geometry.size.width * dividerPosition)
                .background(Color.gray.opacity(0.1))

                // First Divider
                Divider()
                    .frame(width: 2)
                    .background(Color.gray)
                    .onHover { hovering in
                        isHoveringOverDivider = hovering
                        if hovering {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let totalWidth = geometry.size.width
                                let deltaX = value.translation.width / totalWidth
                                dividerPosition = min(max(initialDividerPosition + deltaX, 0.2), dividerPositionRight - 0.1)
                            }
                            .onEnded { _ in
                                initialDividerPosition = dividerPosition
                            }
                    )

                // Middle panel
                CentralPanelView(
                    fileHelper: fileHelper,
                    selectedTab: $selectedTab
                )
                .frame(width: geometry.size.width * (dividerPositionRight - dividerPosition))
                .background(Color.gray.opacity(0.1))

                // Second Divider
                Divider()
                    .frame(width: 2)
                    .background(Color.gray)
                    .onHover { hovering in
                        isHoveringOverDivider = hovering
                        if hovering {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let totalWidth = geometry.size.width
                                let deltaX = value.translation.width / totalWidth
                                dividerPositionRight = min(max(initialDividerPositionRight + deltaX, dividerPosition + 0.1), 0.8)
                            }
                            .onEnded { _ in
                                initialDividerPositionRight = dividerPositionRight
                            }
                    )

                // Right panel (now BookBuildView)
                BookBuildView(
                    fileHelper: fileHelper,
                    selectedTab: $selectedTab
                )
                .frame(width: geometry.size.width * (1 - dividerPositionRight))
                .background(Color.gray.opacity(0.1))
            }
        }
    }
}
