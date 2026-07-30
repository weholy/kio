import Foundation
import UIKit
import SGLiquidGlassCore
import SGSimpleSettings

// MARK: - Glass Tab Bar Background

/// Sits behind the native UITabBar icons and makes them float on liquid glass.
/// Add as a subview *below* the tab bar's icon layer.
public final class SGLiquidGlassTabBarBackground: UIView, SGLiquidGlassViewContainer {
    private let glassView: SGLiquidGlassView

    public init(cornerRadius: CGFloat = 22) {
        self.glassView = SGLiquidGlassView()
        self.glassView.cornerRadii = GlassRadii(radius: cornerRadius)
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(glassView)
        SGLiquidGlassCoordinator.shared.register(node: self, zone: .tabBar)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { SGLiquidGlassCoordinator.shared.unregister(node: self) }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glassView.frame = bounds
        glassView.cornerRadii = GlassRadii(radius: layer.cornerRadius)
    }

    public func refreshGlass(zone: SGLiquidGlassZone) {
        glassView.refreshGlass(zone: zone)
        isHidden = !zone.isEnabled
    }
}

// MARK: - Glass Navigation Bar Background

/// Blur/glass overlay for navigation bars.
public final class SGLiquidGlassNavBarBackground: UIView, SGLiquidGlassViewContainer {
    private let glassView: SGLiquidGlassView

    public init() {
        self.glassView = SGLiquidGlassView()
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(glassView)
        SGLiquidGlassCoordinator.shared.register(node: self, zone: .navigationBar)
    }

    required init?(coder: NSCoder) { fatalError() }
    deinit { SGLiquidGlassCoordinator.shared.unregister(node: self) }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glassView.frame = bounds
    }

    public func refreshGlass(zone: SGLiquidGlassZone) {
        glassView.refreshGlass(zone: zone)
        isHidden = !zone.isEnabled
    }
}

// MARK: - Glass Reactions Panel Background

/// Transparent glass overlay for the emoji reaction picker.
public final class SGLiquidGlassReactionsPanelBackground: UIView, SGLiquidGlassViewContainer {
    private let glassView: SGLiquidGlassView

    public init(cornerRadius: CGFloat = 20) {
        self.glassView = SGLiquidGlassView()
        self.glassView.cornerRadii = GlassRadii(radius: cornerRadius)
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(glassView)
        SGLiquidGlassCoordinator.shared.register(node: self, zone: .reactions)
    }

    required init?(coder: NSCoder) { fatalError() }
    deinit { SGLiquidGlassCoordinator.shared.unregister(node: self) }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glassView.frame = bounds
    }

    public func refreshGlass(zone: SGLiquidGlassZone) {
        glassView.refreshGlass(zone: zone)
        isHidden = !zone.isEnabled
    }
}

// MARK: - Glass Voice Record Button Background

/// Circle glass background for the voice recording button.
public final class SGLiquidGlassVoiceButtonBackground: UIView, SGLiquidGlassViewContainer {
    private let glassView: SGLiquidGlassView

    public init() {
        self.glassView = SGLiquidGlassView()
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(glassView)
        SGLiquidGlassCoordinator.shared.register(node: self, zone: .inputPanel)
    }

    required init?(coder: NSCoder) { fatalError() }
    deinit { SGLiquidGlassCoordinator.shared.unregister(node: self) }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glassView.frame = bounds
        glassView.cornerRadii = GlassRadii(radius: bounds.width / 2)
    }

    public func refreshGlass(zone: SGLiquidGlassZone) {
        glassView.refreshGlass(zone: zone)
        isHidden = !zone.isEnabled
    }
}

// MARK: - Glass Chat List Search Bar

/// Drop-in glass background for the search bar in the chat list.
public final class SGLiquidGlassChatSearchBackground: UIView, SGLiquidGlassViewContainer {
    private let glassView: SGLiquidGlassView

    public init(cornerRadius: CGFloat = 10) {
        self.glassView = SGLiquidGlassView()
        self.glassView.cornerRadii = GlassRadii(radius: cornerRadius)
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(glassView)
        SGLiquidGlassCoordinator.shared.register(node: self, zone: .search)
    }

    required init?(coder: NSCoder) { fatalError() }
    deinit { SGLiquidGlassCoordinator.shared.unregister(node: self) }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glassView.frame = bounds
    }

    public func refreshGlass(zone: SGLiquidGlassZone) {
        glassView.refreshGlass(zone: zone)
        isHidden = !zone.isEnabled
    }
}
