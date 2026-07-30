// MARK: nameless — Tab Bar Settings Controller
// 4 вкладки: Внешний вид | Режим призрака | Прочие функции | Поиск
import Foundation
import UIKit
import Display
import SwiftSignalKit
import AccountContext
import TelegramPresentationData
import SGSimpleSettings
import SGLiquidGlassCore

// MARK: - Tab definitions

public enum NamelessSettingsTab: Int, CaseIterable {
    case appearance       // Внешний вид — интерфейс, чат, профиль, сообщения, медиа
    case ghostMode        // Режим призрака — скрыть онлайн, прочтение, геолокация, приватность
    case otherFunctions   // Прочие функции — контекстное меню, сторис, экспорт/импорт, доп.
    case search           // Поиск — поиск по всем настройкам с навигацией

    var title: String {
        switch self {
        case .appearance:  return "Внешний вид"
        case .ghostMode:   return "👻 Призрак"
        case .otherFunctions: return "Прочие"
        case .search:      return "Поиск"
        }
    }

    var icon: String {
        switch self {
        case .appearance:  return "paintbrush.fill"
        case .ghostMode:   return "eye.slash.fill"
        case .otherFunctions: return "ellipsis.circle.fill"
        case .search:      return "magnifyingglass"
        }
    }
}

// MARK: - Tab Bar View

/// Horizontal scrollable tab bar that sits at the top of the Nameless settings screen.
/// Uses UIGlassEffect on iOS 26+ for the bar background.
public final class NamelessSettingsTabBar: UIView {
    public var onTabSelected: ((NamelessSettingsTab) -> Void)?
    private var selectedTab: NamelessSettingsTab = .appearance
    private var buttons: [UIButton] = []
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let glassBackground: UIVisualEffectView

    // Glass indicator that slides under the selected tab
    private let indicator = UIView()

    public override init(frame: CGRect) {
        // Official Apple liquid glass (UIGlassEffect.regular) — no UIBlurEffect
        glassBackground = makeOfficialLiquidGlassEffectView(isDark: true, interactive: true)
        super.init(frame: frame)
        self.setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        self.backgroundColor = .clear
        self.clipsToBounds = true
        self.layer.cornerRadius = 16
        self.layer.cornerCurve = .continuous

        // Glass bar background
        glassBackground.frame = self.bounds
        glassBackground.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        glassBackground.backgroundColor = .clear
        addSubview(glassBackground)

        // Scrollable stack
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.frame = self.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(scrollView)

        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        // Active indicator — pill behind selected tab
        indicator.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        indicator.layer.cornerRadius = 10
        indicator.layer.cornerCurve = .continuous
        scrollView.insertSubview(indicator, at: 0)

        for tab in NamelessSettingsTab.allCases {
            let btn = self.makeTabButton(tab: tab)
            stackView.addArrangedSubview(btn)
            buttons.append(btn)
        }

        self.selectTab(.appearance, animated: false)
    }

    private func makeTabButton(tab: NamelessSettingsTab) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.tag = tab.rawValue
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = tab.title
            config.image = UIImage(systemName: tab.icon)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))
            config.imagePadding = 5
            config.imagePlacement = .leading
            config.baseForegroundColor = .white
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
                var a = attrs
                a.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
                return a
            }
            btn.configuration = config
        } else {
            btn.setTitle(tab.title, for: .normal)
            btn.setImage(UIImage(systemName: tab.icon)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)), for: .normal)
            btn.tintColor = .white
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 3)
        }
        btn.alpha = 0.55
        btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func tabTapped(_ sender: UIButton) {
        guard let tab = NamelessSettingsTab(rawValue: sender.tag) else { return }
        selectTab(tab, animated: true)
        onTabSelected?(tab)
    }

    public func selectTab(_ tab: NamelessSettingsTab, animated: Bool) {
        selectedTab = tab
        let duration = animated ? 0.28 : 0.0

        for btn in buttons {
            let isSelected = btn.tag == tab.rawValue
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                btn.alpha = isSelected ? 1.0 : 0.55
                btn.transform = isSelected ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
            }
        }

        // Move indicator
        if let btn = buttons.first(where: { $0.tag == tab.rawValue }) {
            let btnFrame = btn.convert(btn.bounds, to: scrollView)
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                self.indicator.frame = btnFrame.insetBy(dx: -2, dy: 3)
            }
            // Scroll to show selected tab
            scrollView.scrollRectToVisible(btnFrame.insetBy(dx: -20, dy: 0), animated: animated)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glassBackground.frame = bounds
        scrollView.frame = bounds
        // Re-position indicator after layout
        if let btn = buttons.first(where: { $0.tag == selectedTab.rawValue }) {
            let btnFrame = btn.convert(btn.bounds, to: scrollView)
            indicator.frame = btnFrame.insetBy(dx: -2, dy: 3)
        }
    }
}

// MARK: - Ghost Mode banner

/// Compact status banner shown at top of Ghost Mode tab
public final class NamelessGhostModeBanner: UIView {
    private let label = UILabel()
    private let statusDot = UIView()
    private let glassView: UIVisualEffectView

    public var isGhostActive: Bool = false {
        didSet { self.updateState() }
    }

    public override init(frame: CGRect) {
        // Official Apple liquid glass — no UIBlurEffect
        glassView = makeOfficialLiquidGlassEffectView(isDark: true, interactive: false)
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        clipsToBounds = true

        glassView.frame = bounds
        glassView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(glassView)

        statusDot.layer.cornerRadius = 5
        statusDot.clipsToBounds = true
        addSubview(statusDot)

        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        addSubview(label)

        updateState()
    }

    private func updateState() {
        let isOn = isGhostActive
        UIView.animate(withDuration: 0.3) {
            self.statusDot.backgroundColor = isOn
                ? UIColor.systemGreen
                : UIColor.systemGray
            self.label.text = isOn
                ? "👻 Режим призрака АКТИВЕН — ты невидим"
                : "Режим призрака выключен"
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let dotSize: CGFloat = 10
        statusDot.frame = CGRect(x: 14, y: (bounds.height - dotSize) / 2, width: dotSize, height: dotSize)
        label.frame = CGRect(x: 32, y: 0, width: bounds.width - 36, height: bounds.height)
    }
}

// MARK: - Notification names

public extension NSNotification.Name {
    static let namelessGhostModeDidChange = NSNotification.Name("nameless.ghostModeDidChange")
    static let namelessSettingsTabDidChange = NSNotification.Name("nameless.settingsTabDidChange")
}
