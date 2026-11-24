import AppKit
import Combine
import SwiftUI

@main
@MainActor
final class BozoBarApp: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private lazy var vm = HeadphoneViewModel()
    private var item: NSStatusItem!
    private let popover = NSPopover()
    private lazy var host = NSHostingController(
        rootView: MenuPopoverLayout(content: MenuContent(vm: vm), onResize: { [weak self] size in
            self?.fitPopover(to: size)
        })
    )
    private var stateSubscription: AnyCancellable?
    private var defaultsSubscription: AnyCancellable?
    private var keyMonitor: Any?
    private var modeTimer: Timer?

    static func main() {
        let app = NSApplication.shared
        let delegate = BozoBarApp()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installQuitMenu()
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.target = self
            button.action = #selector(togglePopover)
            button.imagePosition = .imageLeading
            button.toolTip = "BozoBar — Bose noise control"
            let image = NSImage(systemSymbolName: "headphones", accessibilityDescription: "Headphones")
            image?.isTemplate = true
            button.image = image
            button.setAccessibilityLabel("BozoBar")
        }
        popover.behavior = .transient
        popover.delegate = self
        stateSubscription = vm.$state.sink { [weak self] state in self?.updateTitle(state) }
        defaultsSubscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateTitle(self.vm.state)
            }
    }

    private func updateTitle(_ state: HeadphoneState) {
        let defaults = UserDefaults.standard
        let showBattery = defaults.object(forKey: "showBatteryInMenuBar") == nil || defaults.bool(forKey: "showBatteryInMenuBar")
        let title = state.connected && showBattery ? state.battery.first.map { " \($0.percentage)%" } ?? "" : ""
        if item.button?.title != title { item.button?.title = title }
    }

    private func installQuitMenu() {
        let menu = NSMenu()
        let root = NSMenuItem()
        let appMenu = NSMenu()
        let quit = NSMenuItem(title: "Quit BozoBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.keyEquivalentModifierMask = .command
        quit.target = NSApp
        appMenu.addItem(quit)
        root.submenu = appMenu
        menu.addItem(root)
        NSApp.mainMenu = menu
    }

    private func fitPopover(to size: CGSize) {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else { return }
        let fitted = CGSize(width: ceil(size.width), height: ceil(size.height))
        if popover.contentSize != fitted { popover.contentSize = fitted }
    }

    @objc private func togglePopover() {
        if popover.isShown { popover.performClose(nil); return }
        guard let button = item.button, button.window != nil else { return }
        if popover.contentViewController == nil {
            // MenuPopoverLayout reports the natural size of whichever page is active.
            host.sizingOptions = []
            popover.contentViewController = host
        }
        fitPopover(to: host.sizeThatFits(in: NSSize(width: 300, height: CGFloat.greatestFiniteMagnitude)))
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        guard popover.isShown else { return }
        // A status-bar popover only dismisses itself on outside clicks once the app is
        // active and the popover window is key; showing it is not enough.
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        popover.contentViewController?.view.window?.makeKey()
        // Nothing in the panel should start out holding keyboard focus.
        popover.contentViewController?.view.window?.makeFirstResponder(nil)
        refreshVisibleMode()
        let timer = Timer(timeInterval: 2, target: self, selector: #selector(refreshVisibleMode), userInfo: nil, repeats: true)
        modeTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.popover.isShown else { return event }
            if event.keyCode == 53 { self.popover.performClose(nil); return nil }
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
               event.charactersIgnoringModifiers?.lowercased() == "q" {
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }

    func popoverWillClose(_ notification: Notification) {
        modeTimer?.invalidate()
        modeTimer = nil
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor); self.keyMonitor = nil }
    }

    @objc private func refreshVisibleMode() {
        guard popover.isShown else { return }
        vm.ble.refreshAudioMode()
    }
}
