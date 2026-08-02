import Foundation
import UIKit
import Display
import AsyncDisplayKit
import AccountContext
import TelegramCore
import TelegramPresentationData
import SwiftSignalKit
import AvatarNode
import LocalizedPeerData
import SGMegramFire

// MARK: - Building blocks

private final class MegramCardView: UIView {
    init(cornerRadius: CGFloat) {
        super.init(frame: CGRect())
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = 1.0
        if #available(iOS 13.0, *) {
            self.layer.cornerCurve = .continuous
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func apply(palette: MegramFirePalette) {
        self.backgroundColor = palette.cardFill
        self.layer.borderColor = palette.cardStroke.cgColor
    }
}

private final class MegramProgressBar: UIView {
    private let track = UIView()
    private let fill = UIView()

    private var progress: CGFloat = 0.0

    init() {
        super.init(frame: CGRect())
        self.track.layer.cornerRadius = 5.0
        self.fill.layer.cornerRadius = 5.0
        self.addSubview(self.track)
        self.addSubview(self.fill)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func update(progress: CGFloat, palette: MegramFirePalette) {
        self.progress = max(0.0, min(1.0, progress))
        self.track.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        self.fill.backgroundColor = palette.accent
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.track.frame = self.bounds
        self.fill.frame = CGRect(x: 0.0, y: 0.0, width: floor(self.bounds.width * self.progress), height: self.bounds.height)
    }
}

/// Seven-day message chart. The last bar is today and is highlighted.
private final class MegramWeekChartView: UIView {
    private var bars: [UIView] = []
    private var labels: [UILabel] = []
    private var counts: [Int] = Array(repeating: 0, count: 7)
    /// Smooth curve traced through the bar tops, as in the reference design.
    private let curveLayer = CAShapeLayer()

    private static let dayTitles = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"]

    init() {
        super.init(frame: CGRect())
        self.curveLayer.fillColor = nil
        self.curveLayer.lineWidth = 2.0
        self.curveLayer.lineJoin = .round
        self.curveLayer.lineCap = .round
        self.layer.addSublayer(self.curveLayer)
        for _ in 0 ..< 7 {
            let bar = UIView()
            bar.layer.cornerRadius = 5.0
            self.addSubview(bar)
            self.bars.append(bar)

            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 9.0, weight: .semibold)
            label.textAlignment = .center
            self.addSubview(label)
            self.labels.append(label)
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func update(counts: [Int], palette: MegramFirePalette) {
        self.counts = counts.count == 7 ? counts : Array(repeating: 0, count: 7)

        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        self.curveLayer.strokeColor = palette.accent.withAlphaComponent(0.75).cgColor
        for index in 0 ..< 7 {
            let isToday = index == 6
            self.bars[index].backgroundColor = isToday ? palette.accent.withAlphaComponent(0.85) : UIColor.white.withAlphaComponent(0.22)
            self.bars[index].layer.borderWidth = isToday ? 1.5 : 0.0
            self.bars[index].layer.borderColor = palette.accent.cgColor
            self.labels[index].textColor = isToday ? palette.accent : UIColor.white.withAlphaComponent(0.4)
            if let date = calendar.date(byAdding: .day, value: index - 6, to: now) {
                // Calendar weekday is 1...7 starting on Sunday.
                let weekday = calendar.component(.weekday, from: date)
                self.labels[index].text = MegramWeekChartView.dayTitles[(weekday + 5) % 7]
            }
        }
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = self.bounds
        guard bounds.width > 0.0 else {
            return
        }
        let labelHeight: CGFloat = 12.0
        let chartHeight = max(0.0, bounds.height - labelHeight - 4.0)
        let spacing: CGFloat = 8.0
        let barWidth = max(4.0, (bounds.width - spacing * 6.0) / 7.0)
        let peak = max(1, self.counts.max() ?? 1)

        var tops: [CGPoint] = []
        for index in 0 ..< 7 {
            let ratio = CGFloat(self.counts[index]) / CGFloat(peak)
            let height = max(6.0, chartHeight * ratio)
            let x = CGFloat(index) * (barWidth + spacing)
            self.bars[index].frame = CGRect(x: x, y: chartHeight - height, width: barWidth, height: height)
            self.labels[index].frame = CGRect(x: x - 4.0, y: chartHeight + 4.0, width: barWidth + 8.0, height: labelHeight)
            tops.append(CGPoint(x: x + barWidth / 2.0, y: chartHeight - height))
        }

        // Catmull-Rom style smoothing: pull each segment towards the midpoint
        // of its neighbours so the line reads as a curve, not a polyline.
        let path = UIBezierPath()
        if let first = tops.first {
            path.move(to: first)
            for index in 1 ..< tops.count {
                let previous = tops[index - 1]
                let current = tops[index]
                let controlX = (previous.x + current.x) / 2.0
                path.addCurve(
                    to: current,
                    controlPoint1: CGPoint(x: controlX, y: previous.y),
                    controlPoint2: CGPoint(x: controlX, y: current.y)
                )
            }
        }
        self.curveLayer.frame = self.bounds
        self.curveLayer.path = path.cgPath
    }
}

/// Who carries the conversation — a two-tone bar plus percentages.
private final class MegramBalanceBar: UIView {
    private let mine = UIView()
    private let theirs = UIView()
    private var share: CGFloat = 0.5

    init() {
        super.init(frame: CGRect())
        self.mine.layer.cornerRadius = 4.0
        self.theirs.layer.cornerRadius = 4.0
        self.addSubview(self.theirs)
        self.addSubview(self.mine)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func update(share: CGFloat, palette: MegramFirePalette) {
        self.share = max(0.0, min(1.0, share))
        self.mine.backgroundColor = palette.accent
        self.theirs.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.theirs.frame = self.bounds
        self.mine.frame = CGRect(x: 0.0, y: 0.0, width: floor(self.bounds.width * self.share), height: self.bounds.height)
    }
}

// MARK: - Screen node

private final class MegramFireScreenNode: ASDisplayNode {
    private let context: AccountContext
    private let peer: EnginePeer
    private var presentationData: PresentationData

    private let backgroundLayer = CAGradientLayer()
    /// Large radial wash behind the flame. It lives on the screen rather than
    /// inside the flame view so it can spill across the whole width.
    private let glowLayer = CAGradientLayer()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var validLayout: ContainerViewLayout?

    private let closeButton = UIButton(type: .system)
    private var avatarNodes: [AvatarNode] = []

    private let flameView: MegramFlameView
    private let daysLabel = UILabel()
    private let daysCaptionLabel = UILabel()
    private let levelLabel = UILabel()

    private let milestoneCard = MegramCardView(cornerRadius: 20.0)
    private let milestoneBar = MegramProgressBar()
    private let milestoneTitleLabel = UILabel()
    private let milestoneDetailLabel = UILabel()
    private let milestoneCounterLabel = UILabel()
    private let previousLevelButton = UIButton(type: .system)
    private let nextLevelButton = UIButton(type: .system)

    private let goalCard = MegramCardView(cornerRadius: 20.0)
    private let goalLabel = UILabel()
    private let goalCheckView = UIView()
    private let goalCheckLabel = UILabel()

    private let statsCard = MegramCardView(cornerRadius: 20.0)
    private let statsTitleLabel = UILabel()
    private let statsTotalCaptionLabel = UILabel()
    private let statsTotalLabel = UILabel()
    private let statsTodayLabel = UILabel()
    private let chartView = MegramWeekChartView()

    private let extrasCard = MegramCardView(cornerRadius: 20.0)
    private let bestStreakTitleLabel = UILabel()
    private let bestStreakValueLabel = UILabel()
    private let balanceTitleLabel = UILabel()
    private let balanceBar = MegramBalanceBar()
    private let balanceDetailLabel = UILabel()

    private let footerLabel = UILabel()

    private var state: MegramFireState
    private var partners: [EnginePeer] = []
    /// Level the user is browsing with the arrows; nil means "follow the streak".
    private var previewLevel: MegramFireLevel?

    var close: () -> Void = {}

    private var displayedLevel: MegramFireLevel {
        return self.previewLevel ?? self.state.level
    }

    init(context: AccountContext, peer: EnginePeer, presentationData: PresentationData, state: MegramFireState) {
        self.context = context
        self.peer = peer
        self.presentationData = presentationData
        self.state = state
        self.flameView = MegramFlameView(level: state.level)

        super.init()

        self.setViewBlock({ UIView() })
    }

    override func didLoad() {
        super.didLoad()

        let view = self.view
        view.layer.addSublayer(self.backgroundLayer)
        self.glowLayer.type = .radial
        self.glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        self.glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.addSublayer(self.glowLayer)
        view.addSubview(self.scrollView)
        view.addSubview(self.closeButton)
        self.scrollView.addSubview(self.contentView)
        self.scrollView.showsVerticalScrollIndicator = false

        self.closeButton.setTitle("✕", for: .normal)
        self.closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
        self.closeButton.setTitleColor(UIColor.white.withAlphaComponent(0.85), for: .normal)
        self.closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        self.closeButton.layer.cornerRadius = 17.0
        self.closeButton.addTarget(self, action: #selector(self.closePressed), for: .touchUpInside)

        for subview in [self.flameView, self.milestoneCard, self.goalCard, self.statsCard, self.extrasCard] as [UIView] {
            self.contentView.addSubview(subview)
        }
        for label in [self.daysLabel, self.daysCaptionLabel, self.levelLabel, self.footerLabel] {
            self.contentView.addSubview(label)
        }

        self.daysLabel.font = UIFont.systemFont(ofSize: 110.0, weight: .heavy)
        self.daysLabel.textAlignment = .center
        self.daysLabel.textColor = .white
        self.daysCaptionLabel.font = UIFont.systemFont(ofSize: 19.0, weight: .semibold)
        self.daysCaptionLabel.textAlignment = .center
        self.levelLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)
        self.levelLabel.textAlignment = .center
        self.footerLabel.font = UIFont.systemFont(ofSize: 11.0, weight: .semibold)
        self.footerLabel.textAlignment = .center
        self.footerLabel.textColor = UIColor.white.withAlphaComponent(0.3)
        self.footerLabel.text = "MEGRAM · ОГОНЁК"

        // Milestone
        for subview in [self.milestoneBar, self.milestoneTitleLabel, self.milestoneDetailLabel, self.milestoneCounterLabel, self.previousLevelButton, self.nextLevelButton] as [UIView] {
            self.milestoneCard.addSubview(subview)
        }
        self.milestoneCard.clipsToBounds = false
        self.milestoneTitleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        self.milestoneTitleLabel.textColor = .white
        self.milestoneDetailLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        self.milestoneDetailLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        self.milestoneCounterLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .bold)
        self.milestoneCounterLabel.textAlignment = .right
        self.milestoneCounterLabel.textColor = .white
        self.previousLevelButton.setTitle("‹", for: .normal)
        self.nextLevelButton.setTitle("›", for: .normal)
        for button in [self.previousLevelButton, self.nextLevelButton] {
            button.titleLabel?.font = UIFont.systemFont(ofSize: 26.0, weight: .medium)
            button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
        }
        self.previousLevelButton.addTarget(self, action: #selector(self.previousLevelPressed), for: .touchUpInside)
        self.nextLevelButton.addTarget(self, action: #selector(self.nextLevelPressed), for: .touchUpInside)

        // Goal
        self.goalCard.addSubview(self.goalLabel)
        self.goalCard.addSubview(self.goalCheckView)
        self.goalCheckView.addSubview(self.goalCheckLabel)
        self.goalLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        self.goalLabel.textColor = .white
        self.goalLabel.numberOfLines = 2
        self.goalCheckView.layer.cornerRadius = 14.0
        self.goalCheckLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .bold)
        self.goalCheckLabel.textAlignment = .center
        self.goalCheckLabel.textColor = .white

        // Stats
        for subview in [self.statsTitleLabel, self.statsTotalCaptionLabel, self.statsTotalLabel, self.statsTodayLabel, self.chartView] as [UIView] {
            self.statsCard.addSubview(subview)
        }
        self.statsTitleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .bold)
        self.statsTitleLabel.textColor = .white
        self.statsTitleLabel.text = "Статистика сообщений"
        self.statsTotalCaptionLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        self.statsTotalCaptionLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        self.statsTotalCaptionLabel.text = "Сообщений всего:"
        self.statsTotalLabel.font = UIFont.systemFont(ofSize: 38.0, weight: .heavy)
        self.statsTotalLabel.textColor = .white
        self.statsTodayLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        self.statsTodayLabel.textColor = UIColor.white.withAlphaComponent(0.55)

        // Extras
        for subview in [self.bestStreakTitleLabel, self.bestStreakValueLabel, self.balanceTitleLabel, self.balanceBar, self.balanceDetailLabel] as [UIView] {
            self.extrasCard.addSubview(subview)
        }
        self.bestStreakTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        self.bestStreakTitleLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        self.bestStreakTitleLabel.text = "Лучшая серия"
        self.bestStreakValueLabel.font = UIFont.systemFont(ofSize: 22.0, weight: .bold)
        self.bestStreakValueLabel.textColor = .white
        self.bestStreakValueLabel.textAlignment = .right
        self.balanceTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        self.balanceTitleLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        self.balanceTitleLabel.text = "Баланс диалога"
        self.balanceDetailLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        self.balanceDetailLabel.textColor = UIColor.white.withAlphaComponent(0.45)

        self.rebuildAvatars()
        self.applyState()
        self.flameView.startAnimating()
    }

    func update(state: MegramFireState, partners: [EnginePeer]) {
        let leveledUp = state.level != self.state.level
        self.state = state
        self.partners = partners
        self.previewLevel = nil
        guard self.isNodeLoaded else {
            return
        }
        self.rebuildAvatars()
        self.applyState()
        // Freshly created avatar views sit at the origin until a layout pass
        // places them, and data can arrive after the last one.
        if let layout = self.validLayout {
            self.containerLayoutUpdated(layout)
        }
        if leveledUp {
            self.flameView.playIgnition()
        }
    }

    private func rebuildAvatars() {
        for node in self.avatarNodes {
            node.view.removeFromSuperview()
        }
        self.avatarNodes.removeAll()

        // Current partner first, then the other chats that have a fire.
        var peers: [EnginePeer] = [self.peer]
        for partner in self.partners where partner.id != self.peer.id {
            peers.append(partner)
        }

        for peer in peers.prefix(4) {
            let node = AvatarNode(font: avatarPlaceholderFont(size: 15.0))
            node.setPeer(
                accountPeerId: self.context.account.peerId,
                postbox: self.context.account.postbox,
                network: self.context.account.network,
                contentSettings: self.context.currentContentSettings.with { $0 },
                theme: self.presentationData.theme,
                peer: peer,
                displayDimensions: CGSize(width: 36.0, height: 36.0)
            )
            node.frame = CGRect(origin: CGPoint(), size: CGSize(width: 36.0, height: 36.0))
            node.view.layer.borderWidth = 2.0
            node.view.layer.cornerRadius = 18.0
            node.view.layer.masksToBounds = true
            self.view.addSubview(node.view)
            self.avatarNodes.append(node)
        }
        self.setNeedsLayout()
    }

    private func applyState() {
        let level = self.displayedLevel
        let palette = level.palette
        let isPreview = self.previewLevel != nil && self.previewLevel != self.state.level

        self.backgroundLayer.colors = [palette.backgroundTop.cgColor, palette.backgroundBottom.cgColor]
        self.backgroundLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.backgroundLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

        let glowStrength: CGFloat = isPreview ? 0.22 : 1.0
        self.glowLayer.colors = [
            palette.glow.withAlphaComponent(0.95 * glowStrength).cgColor,
            palette.glow.withAlphaComponent(0.55 * glowStrength).cgColor,
            palette.glow.withAlphaComponent(0.18 * glowStrength).cgColor,
            palette.glow.withAlphaComponent(0.0).cgColor
        ]
        self.glowLayer.locations = [0.0, 0.28, 0.55, 1.0]

        self.flameView.update(level: level)
        self.flameView.isDimmed = isPreview || !self.state.isActive

        self.daysLabel.text = "\(self.state.days)"
        self.daysCaptionLabel.text = self.pluralDays(self.state.days)
        self.daysCaptionLabel.textColor = .white
        self.levelLabel.text = "\(level.titleRu) · серия с \(self.peer.compactDisplayTitle)"
        self.levelLabel.textColor = UIColor.white.withAlphaComponent(0.4)

        for card in [self.milestoneCard, self.goalCard, self.statsCard, self.extrasCard] {
            card.apply(palette: palette)
        }

        // Milestone / level browser
        if isPreview, let preview = self.previewLevel {
            self.milestoneTitleLabel.text = preview.titleRu
            let remaining = max(0, preview.startDay - self.state.days)
            self.milestoneDetailLabel.text = remaining > 0 ? "Откроется через \(remaining) \(self.pluralDays(remaining))" : "Уровень уже открыт"
            self.milestoneCounterLabel.text = "\(min(self.state.days, preview.startDay))/\(preview.startDay)"
            let progress = preview.startDay > 0 ? CGFloat(self.state.days) / CGFloat(preview.startDay) : 1.0
            self.milestoneBar.update(progress: progress, palette: palette)
        } else if let milestone = self.state.milestone {
            let remaining = max(0, milestone.target - milestone.current)
            self.milestoneTitleLabel.text = "Веха \(milestone.target) \(self.pluralDays(milestone.target))"
            self.milestoneDetailLabel.text = "Ещё \(remaining) \(self.pluralDays(remaining))"
            self.milestoneCounterLabel.text = "\(milestone.current)/\(milestone.target)"
            self.milestoneBar.update(progress: CGFloat(milestone.current) / CGFloat(max(1, milestone.target)), palette: palette)
        } else {
            self.milestoneTitleLabel.text = "Максимальный уровень"
            self.milestoneDetailLabel.text = "Дальше только серия"
            self.milestoneCounterLabel.text = "\(self.state.days)"
            self.milestoneBar.update(progress: 1.0, palette: palette)
        }
        self.previousLevelButton.isEnabled = level.rawValue > 0
        self.nextLevelButton.isEnabled = level.rawValue < MegramFireLevel.allCases.count - 1
        self.previousLevelButton.alpha = self.previousLevelButton.isEnabled ? 1.0 : 0.25
        self.nextLevelButton.alpha = self.nextLevelButton.isEnabled ? 1.0 : 0.25

        // Goal
        self.goalLabel.text = self.state.mutualToday ? MegramFireGoal.goal(for: Date()) : "Ответьте друг другу сегодня"
        self.goalCheckView.backgroundColor = self.state.mutualToday ? UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0) : UIColor.white.withAlphaComponent(0.12)
        self.goalCheckLabel.text = self.state.mutualToday ? "✓" : ""

        // Stats
        self.statsTotalLabel.text = "\(self.state.totalMessages)"
        self.statsTodayLabel.text = "Сообщений за сутки: \(self.state.todayMessages)"
        self.chartView.update(counts: self.state.weekCounts, palette: palette)

        // Extras
        self.bestStreakValueLabel.text = "\(self.state.bestStreak) \(self.pluralDays(self.state.bestStreak))"
        self.balanceBar.update(share: CGFloat(self.state.outgoingShare), palette: palette)
        let minePercent = Int((self.state.outgoingShare * 100.0).rounded())
        self.balanceDetailLabel.text = "Вы \(minePercent)% · собеседник \(100 - minePercent)%"

        self.setNeedsLayout()
    }

    private func pluralDays(_ value: Int) -> String {
        let remainder100 = abs(value) % 100
        if remainder100 >= 11 && remainder100 <= 14 {
            return "дней"
        }
        switch abs(value) % 10 {
        case 1: return "день"
        case 2, 3, 4: return "дня"
        default: return "дней"
        }
    }

    @objc private func closePressed() {
        self.close()
    }

    @objc private func previousLevelPressed() {
        let current = self.displayedLevel
        guard let target = MegramFireLevel(rawValue: current.rawValue - 1) else {
            return
        }
        self.previewLevel = target == self.state.level ? nil : target
        self.applyState()
    }

    @objc private func nextLevelPressed() {
        let current = self.displayedLevel
        guard let target = MegramFireLevel(rawValue: current.rawValue + 1) else {
            return
        }
        self.previewLevel = target == self.state.level ? nil : target
        self.applyState()
    }

    func containerLayoutUpdated(_ layout: ContainerViewLayout) {
        guard self.isNodeLoaded else {
            return
        }
        self.validLayout = layout
        let size = layout.size
        let topInset = (layout.statusBarHeight ?? 20.0) + 6.0
        let side: CGFloat = 16.0
        let width = size.width - side * 2.0

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.backgroundLayer.frame = CGRect(origin: CGPoint(), size: size)
        // Centred on the flame and wide enough to wash across the whole screen.
        let glowSide = size.width * 2.2
        self.glowLayer.frame = CGRect(
            x: size.width / 2.0 - glowSide / 2.0,
            y: topInset + 150.0 - glowSide / 2.0,
            width: glowSide,
            height: glowSide
        )
        CATransaction.commit()

        self.closeButton.frame = CGRect(x: side, y: topInset, width: 34.0, height: 34.0)

        // Avatars sit in the top-right corner, overlapping right to left.
        let avatarSize: CGFloat = 36.0
        let avatarOverlap: CGFloat = 12.0
        for (index, node) in self.avatarNodes.enumerated() {
            let x = size.width - side - avatarSize - CGFloat(index) * (avatarSize - avatarOverlap)
            node.view.frame = CGRect(x: x, y: topInset - 1.0, width: avatarSize, height: avatarSize)
            node.view.layer.borderColor = self.displayedLevel.palette.backgroundTop.cgColor
            node.view.layer.zPosition = CGFloat(self.avatarNodes.count - index)
        }

        let scrollTop = topInset + 44.0
        self.scrollView.frame = CGRect(x: 0.0, y: scrollTop, width: size.width, height: max(0.0, size.height - scrollTop))

        var y: CGFloat = 8.0

        // Small flame, oversized day count — the number is the hero here.
        let flameSide: CGFloat = 74.0
        self.flameView.frame = CGRect(x: (size.width - flameSide) / 2.0, y: y + 10.0, width: flameSide, height: flameSide * 1.24)
        y += flameSide * 1.24 + 6.0

        self.daysLabel.frame = CGRect(x: side, y: y, width: width, height: 118.0)
        y += 112.0
        self.daysCaptionLabel.frame = CGRect(x: side, y: y, width: width, height: 24.0)
        y += 26.0
        self.levelLabel.frame = CGRect(x: side, y: y, width: width, height: 16.0)
        y += 32.0

        // Milestone card with the level arrows on either side.
        let arrowWidth: CGFloat = 30.0
        let milestoneCardWidth = width - arrowWidth * 2.0
        let milestoneHeight: CGFloat = 78.0
        self.milestoneCard.frame = CGRect(x: side + arrowWidth, y: y, width: milestoneCardWidth, height: milestoneHeight)
        self.previousLevelButton.frame = CGRect(x: -arrowWidth, y: 0.0, width: arrowWidth, height: milestoneHeight)
        self.nextLevelButton.frame = CGRect(x: milestoneCardWidth, y: 0.0, width: arrowWidth, height: milestoneHeight)
        self.milestoneBar.frame = CGRect(x: 16.0, y: 14.0, width: milestoneCardWidth - 32.0, height: 10.0)
        self.milestoneCounterLabel.frame = CGRect(x: milestoneCardWidth - 90.0, y: 34.0, width: 74.0, height: 34.0)
        self.milestoneTitleLabel.frame = CGRect(x: 16.0, y: 32.0, width: milestoneCardWidth - 110.0, height: 20.0)
        self.milestoneDetailLabel.frame = CGRect(x: 16.0, y: 51.0, width: milestoneCardWidth - 110.0, height: 18.0)
        y += milestoneHeight + 12.0

        let goalHeight: CGFloat = 60.0
        self.goalCard.frame = CGRect(x: side, y: y, width: width, height: goalHeight)
        self.goalLabel.frame = CGRect(x: 16.0, y: 10.0, width: width - 74.0, height: 40.0)
        self.goalCheckView.frame = CGRect(x: width - 44.0, y: (goalHeight - 28.0) / 2.0, width: 28.0, height: 28.0)
        self.goalCheckLabel.frame = self.goalCheckView.bounds
        y += goalHeight + 12.0

        let statsHeight: CGFloat = 210.0
        self.statsCard.frame = CGRect(x: side, y: y, width: width, height: statsHeight)
        self.statsTitleLabel.frame = CGRect(x: 16.0, y: 16.0, width: width - 32.0, height: 22.0)
        self.statsTotalCaptionLabel.frame = CGRect(x: 16.0, y: 44.0, width: width - 32.0, height: 18.0)
        self.statsTotalLabel.frame = CGRect(x: 16.0, y: 62.0, width: width - 32.0, height: 44.0)
        self.statsTodayLabel.frame = CGRect(x: 16.0, y: 106.0, width: width - 32.0, height: 20.0)
        self.chartView.frame = CGRect(x: 16.0, y: 134.0, width: width - 32.0, height: 60.0)
        y += statsHeight + 12.0

        let extrasHeight: CGFloat = 132.0
        self.extrasCard.frame = CGRect(x: side, y: y, width: width, height: extrasHeight)
        self.bestStreakTitleLabel.frame = CGRect(x: 16.0, y: 18.0, width: width - 150.0, height: 20.0)
        self.bestStreakValueLabel.frame = CGRect(x: width - 150.0, y: 14.0, width: 134.0, height: 28.0)
        self.balanceTitleLabel.frame = CGRect(x: 16.0, y: 58.0, width: width - 32.0, height: 18.0)
        self.balanceBar.frame = CGRect(x: 16.0, y: 82.0, width: width - 32.0, height: 8.0)
        self.balanceDetailLabel.frame = CGRect(x: 16.0, y: 96.0, width: width - 32.0, height: 20.0)
        y += extrasHeight + 20.0

        self.footerLabel.frame = CGRect(x: side, y: y, width: width, height: 16.0)
        y += 16.0 + layout.intrinsicInsets.bottom + 24.0

        self.contentView.frame = CGRect(x: 0.0, y: 0.0, width: size.width, height: y)
        self.scrollView.contentSize = CGSize(width: size.width, height: y)
    }
}

// MARK: - Controller

final class MegramFireScreen: ViewController {
    private let context: AccountContext
    private let peer: EnginePeer
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private let stateDisposable = MetaDisposable()
    private var state: MegramFireState

    private var controllerNode: MegramFireScreenNode {
        return self.displayNode as! MegramFireScreenNode
    }

    init(context: AccountContext, peer: EnginePeer) {
        self.context = context
        self.peer = peer
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.state = MegramFireStore.state(peerId: peer.id.toInt64())

        super.init(navigationBarPresentationData: nil)

        self.statusBar.statusBarStyle = .White

        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            guard let self else {
                return
            }
            self.presentationData = presentationData
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.presentationDataDisposable?.dispose()
        self.stateDisposable.dispose()
    }

    override func loadDisplayNode() {
        self.displayNode = MegramFireScreenNode(context: self.context, peer: self.peer, presentationData: self.presentationData, state: self.state)
        self.controllerNode.close = { [weak self] in
            self?.dismiss()
        }
        self.displayNodeDidLoad()
        self.reloadState()
    }

    private func reloadState() {
        self.stateDisposable.set((MegramFireRefresh.refresh(postbox: self.context.account.postbox, peerId: self.peer.id)
        |> deliverOnMainQueue).start(next: { [weak self] snapshot in
            guard let self else {
                return
            }
            self.state = snapshot.state
            self.controllerNode.update(state: snapshot.state, partners: snapshot.partners)
        }))
    }

    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.controllerNode.containerLayoutUpdated(layout)
    }
}
