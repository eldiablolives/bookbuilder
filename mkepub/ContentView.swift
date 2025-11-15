import SwiftUI
import AppKit               // needed for NSCursor

struct ContentView: View {
    @EnvironmentObject var fileHelper: FileHelper
    @State private var selectedTab = "eBook"

    @State private var dividerPosition: CGFloat = 0.3
    @State private var dividerPositionRight: CGFloat = 0.7

    // your original capture states – keep them exactly as you had them
    @State private var initialDividerPosition: CGFloat = 0.3
    @State private var initialDividerPositionRight: CGFloat = 0.7
    @State private var dragStartLeft: CGFloat? = nil
    @State private var dragStartRight: CGFloat? = nil

    // optional – only needed if FileBrowserView actually reads the binding
    @State private var isHoveringOverDivider = false

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                // ---------- LEFT PANEL ----------
                FileBrowserView(
                    fileHelper: fileHelper,
                    dividerPosition: $dividerPosition,
                    isHoveringOverDivider: $isHoveringOverDivider,
                    initialDividerPosition: $initialDividerPosition,
                    dividerPositionRight: $dividerPositionRight,
                    geometry: geometry
                )
                .frame(width: geometry.size.width * dividerPosition)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(Color.gray.opacity(0.1))

                // ---------- LEFT DIVIDER ----------
                dividerView { value in
                    let total = geometry.size.width
                    if dragStartLeft == nil { dragStartLeft = dividerPosition }
                    let base = dragStartLeft ?? dividerPosition
                    let delta = value.translation.width / total
                    dividerPosition = min(
                        max(base + delta, 0.2),
                        dividerPositionRight - 0.1
                    )
                } onEnded: {
                    initialDividerPosition = dividerPosition
                    dragStartLeft = nil
                }

                // ---------- MIDDLE PANEL ----------
                CentralPanelView(fileHelper: fileHelper, selectedTab: $selectedTab)
                    .frame(width: geometry.size.width * (dividerPositionRight - dividerPosition))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .background(Color.gray.opacity(0.1))

                // ---------- RIGHT DIVIDER ----------
                dividerView { value in
                    let total = geometry.size.width
                    if dragStartRight == nil { dragStartRight = dividerPositionRight }
                    let base = dragStartRight ?? dividerPositionRight
                    let delta = value.translation.width / total
                    dividerPositionRight = min(
                        max(base + delta, dividerPosition + 0.1),
                        0.8
                    )
                } onEnded: {
                    initialDividerPositionRight = dividerPositionRight
                    dragStartRight = nil
                }

                // ---------- RIGHT PANEL ----------
                BookBuildView(fileHelper: fileHelper, selectedTab: $selectedTab)
                    .frame(width: geometry.size.width * (1 - dividerPositionRight))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .background(Color.gray.opacity(0.1))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .coordinateSpace(name: "Container")
        }
        // If you have a top bar, wrap ContentView like this:
        // VStack(spacing: 0) { TopBar(); ContentView().frame(maxHeight: .infinity) }
    }

    // MARK: - Reusable divider (the only place where the error was)
    @ViewBuilder
    private func dividerView(
        onChanged: @escaping (DragGesture.Value) -> Void,
        onEnded:   @escaping () -> Void
    ) -> some View {
        ZStack {
            // 1-pixel gray line, full height
            Rectangle()
                .fill(Color.gray)
                .frame(width: 1)
                .frame(maxHeight: .infinity)

            // invisible hit-area
            Color.clear
                .contentShape(Rectangle())
        }
        .frame(width: 11)                     // grab area (11 px works great)
        .frame(maxHeight: .infinity)          // fill the whole height
        .onHover { hovering in
            if hovering { NSCursor.resizeLeftRight.push() }
            else { NSCursor.pop() }
        }
        .gesture(
            DragGesture(coordinateSpace: .named("Container"))
                .onChanged(onChanged)
                .onEnded { _ in onEnded() }
        )
    }
}
