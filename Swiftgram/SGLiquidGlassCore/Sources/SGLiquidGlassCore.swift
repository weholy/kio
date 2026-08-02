import Foundation
import UIKit
import SGSimpleSettings

// MARK: - Zones

/// All distinct Liquid Glass surfaces in nameless.
/// When master `liquidGlassEnabled` is ON — every zone is ON (glass absolutely everywhere).
public enum SGLiquidGlassZone: Int, CaseIterable {
    case messages
    case outgoingMessages
    case settings
    case profile
    case profileGifts
    case inlineButtons
    case tabBar
    case navigationBar
    case inputPanel
    case search
    case buttons
    case popup
    case contextMenu
    case reactions
    case stickers
    case calls
    case media
    case chatList

    /// MARK: Megram — glass is always on.
    ///
    /// The per-zone flags have no rows in the rebuilt settings tabs, so a
    /// single stale value from an older build would silently drop whole
    /// screens back to flat grey with no way to reach the switch and undo it.
    public var isEnabled: Bool {
        return true
    }

    public var isTinted: Bool {
        SGSimpleSettings.shared.namelessLiquidGlassTinting
    }

    public var intensity: CGFloat {
        CGFloat(SGSimpleSettings.shared.namelessLiquidGlassIntensity)
    }

    public var fadeAnimationEnabled: Bool {
        SGSimpleSettings.shared.namelessLiquidGlassFadeAnimation
    }
}

// MARK: - Glass Radii

public struct GlassRadii: Equatable {
    public let topLeft: CGFloat
    public let topRight: CGFloat
    public let bottomLeft: CGFloat
    public let bottomRight: CGFloat

    public init(radius: CGFloat) {
        self.topLeft = radius; self.topRight = radius
        self.bottomLeft = radius; self.bottomRight = radius
    }

    public init(topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat) {
        self.topLeft = topLeft; self.topRight = topRight
        self.bottomLeft = bottomLeft; self.bottomRight = bottomRight
    }

    public var roundedCorners: UIRectCorner {
        var c: UIRectCorner = []
        if topLeft > 0 { c.insert(.topLeft) }
        if topRight > 0 { c.insert(.topRight) }
        if bottomLeft > 0 { c.insert(.bottomLeft) }
        if bottomRight > 0 { c.insert(.bottomRight) }
        return c
    }
}

// MARK: - Container protocols

public protocol SGLiquidGlassContainer: AnyObject {
    func refreshGlass(zone: SGLiquidGlassZone)
}

public protocol SGLiquidGlassViewContainer: AnyObject {
    func refreshGlass(zone: SGLiquidGlassZone)
}

public protocol SGLiquidGlassViewProtocol: AnyObject {
    var tintColorGlass: UIColor { get set }
    var cornerRadii: GlassRadii { get set }
    var isVisible: Bool { get set }
    func refreshGlass(zone: SGLiquidGlassZone)
}

public extension SGLiquidGlassViewProtocol where Self: UIView {
    func setFrame(_ frame: CGRect) { self.frame = frame }
}

public final class SGLiquidGlassFactory {
    public static let shared = SGLiquidGlassFactory()
    private init() {}
    public var create: (() -> SGLiquidGlassViewProtocol?)?
}

// MARK: - Coordinator

public final class SGLiquidGlassCoordinator {
    public static let shared = SGLiquidGlassCoordinator()

    private struct Observer {
        weak var node: AnyObject?
        let zone: SGLiquidGlassZone
    }

    private var observers: [ObjectIdentifier: Observer] = [:]
    private var notificationObserver: NSObjectProtocol?
    /// Registration happens from node initialisers, which ASDisplayKit may run off the main
    /// thread, so the table still needs guarding — but with a lock rather than a serial queue.
    /// `DispatchQueue.sync` costs a thread hop on every register/unregister, and surfaces come and
    /// go constantly while a chat scrolls; an uncontended `NSLock` is orders of magnitude cheaper.
    private let lock = NSLock()

    private init() {
        self.notificationObserver = NotificationCenter.default.addObserver(
            forName: .luxgramLiquidGlassDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.refreshAll() }
    }

    deinit {
        if let o = notificationObserver { NotificationCenter.default.removeObserver(o) }
    }

    public func register(node: AnyObject, zone: SGLiquidGlassZone) {
        let id = ObjectIdentifier(node)
        self.lock.lock()
        self.observers[id] = Observer(node: node, zone: zone)
        self.lock.unlock()
    }

    public func unregister(node: AnyObject) {
        let id = ObjectIdentifier(node)
        self.lock.lock()
        self.observers.removeValue(forKey: id)
        self.lock.unlock()
    }

    public func refreshAll() {
        self.lock.lock()
        // Deregistered surfaces leave nil entries behind; drop them here rather than growing the
        // table forever, since nothing else ever walks it.
        self.observers = self.observers.filter { $0.value.node != nil }
        let snapshot = Array(self.observers.values)
        self.lock.unlock()
        for obs in snapshot {
            if let n = obs.node as? SGLiquidGlassContainer {
                n.refreshGlass(zone: obs.zone)
            } else if let v = obs.node as? SGLiquidGlassViewContainer {
                v.refreshGlass(zone: obs.zone)
            }
        }
    }
}
