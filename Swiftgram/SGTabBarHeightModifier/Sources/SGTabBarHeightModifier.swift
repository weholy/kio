import Foundation
import Display
import SGSimpleSettings

public func sgTabBarHeightModifier(tabBarHeight: CGFloat, layout: ContainerViewLayout, defaultBarSmaller: Bool) -> CGFloat {
    var tabBarHeight = tabBarHeight

    // Round tabs mode — only icons, no text — needs more compact height
    if SGSimpleSettings.shared.roundTabs {
        // Round tabs are bigger circle icons, keep standard height
        return tabBarHeight
    }

    guard !SGSimpleSettings.shared.showTabNames else {
        return tabBarHeight
    }
    
    if defaultBarSmaller {
        tabBarHeight -= 6.0
    } else {
        tabBarHeight -= 12.0
    }
    
    if layout.intrinsicInsets.bottom.isZero {
        // Devices with home button need a bit more space
        if defaultBarSmaller {
            tabBarHeight += 3.0
        } else {
            tabBarHeight += 6.0
        }
    }
    
    return tabBarHeight
}

/// Whether round tabs mode is active — used by tab bar rendering code
public func sgIsRoundTabsEnabled() -> Bool {
    return SGSimpleSettings.shared.roundTabs
}
