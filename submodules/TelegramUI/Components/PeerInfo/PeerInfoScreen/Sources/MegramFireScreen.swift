import Foundation
import UIKit
import Display
import AsyncDisplayKit
import AccountContext
import TelegramCore
import TelegramPresentationData
import SwiftSignalKit

// A small local store keeps the screen useful before a Megram backend is connected.
// It is deliberately isolated so it can be replaced by an API-backed implementation.
private struct MegramFireState {
    let days: Int
    let messages: Int
    let lastActivityDay: String?
}

private enum MegramFireStore {
    private static func prefix(_ peerId: EnginePeer.Id) -> String {
        return "megram.fire.\(peerId.id._internalGetInt64Value())"
    }

    static func state(peerId: EnginePeer.Id, isStarter: Bool) -> MegramFireState {
        let defaults = UserDefaults.standard
        let prefix = self.prefix(peerId)
        let savedDays = defaults.integer(forKey: "\(prefix).days")
        return MegramFireState(
            days: isStarter ? max(4, savedDays) : savedDays,
            messages: defaults.integer(forKey: "\(prefix).messages"),
            lastActivityDay: defaults.string(forKey: "\(prefix).lastActivityDay")
        )
    }

    static func recordActivity(peerId: EnginePeer.Id, isStarter: Bool) -> MegramFireState {
        let defaults = UserDefaults.standard
        let prefix = self.prefix(peerId)
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        var state = self.state(peerId: peerId, isStarter: isStarter)
        var days = state.days
        if state.lastActivityDay != today {
            if let previous = state.lastActivityDay, let previousDate = formatter.date(from: previous), Calendar.current.dateComponents([.day], from: previousDate, to: Date()).day ?? 0 > 1 {
                days = 1
            } else {
                days = max(1, days + 1)
            }
            defaults.set(today, forKey: "\(prefix).lastActivityDay")
        }
        defaults.set(days, forKey: "\(prefix).days")
        defaults.set(state.messages + 1, forKey: "\(prefix).messages")
        state = MegramFireState(days: days, messages: state.messages + 1, lastActivityDay: today)
        return state
    }
}

private final class MegramFireScreenNode: ASDisplayNode {
    private let backgroundView = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let flameCard = UIView()
    private let flameLabel = UILabel()
    private let dayLabel = UILabel()
    private let flameCaptionLabel = UILabel()
    private let activityCard = UIView()
    private let activityTitleLabel = UILabel()
    private let activityTextLabel = UILabel()
    private let activityButton = UIButton(type: .system)
    private let messageCard = UIView()
    private let messageValueLabel = UILabel()
    private let messageTitleLabel = UILabel()
    private let goalCard = UIView()
    private let goalTitleLabel = UILabel()
    private let goalTextLabel = UILabel()
    private let avatarView = UIView()
    private let avatarLabel = UILabel()
    private let friendAvatarView = UIView()
    private let friendAvatarLabel = UILabel()

    private var presentationData: PresentationData
    private var state: MegramFireState
    private let peerId: EnginePeer.Id
    private let peerName: String
    private let isStarter: Bool
    var close: () -> Void = {}

    init(presentationData: PresentationData, peerId: EnginePeer.Id, peerName: String, isStarter: Bool) {
        self.presentationData = presentationData
        self.peerId = peerId
        self.peerName = peerName
        self.isStarter = isStarter
        self.state = MegramFireStore.state(peerId: peerId, isStarter: isStarter)
        super.init()
        self.setViewBlock({ UIView() })
    }

    override func didLoad() {
        super.didLoad()
        let view = self.view
        view.addSubview(self.backgroundView)
        view.addSubview(self.scrollView)
        view.addSubview(self.closeButton)
        self.scrollView.addSubview(self.contentView)

        [self.titleLabel, self.subtitleLabel, self.flameCard, self.activityCard, self.messageCard, self.goalCard].forEach(self.contentView.addSubview)
        [self.flameLabel, self.dayLabel, self.flameCaptionLabel, self.avatarView, self.friendAvatarView].forEach(self.flameCard.addSubview)
        self.avatarView.addSubview(self.avatarLabel)
        self.friendAvatarView.addSubview(self.friendAvatarLabel)
        [self.activityTitleLabel, self.activityTextLabel, self.activityButton].forEach(self.activityCard.addSubview)
        [self.messageValueLabel, self.messageTitleLabel].forEach(self.messageCard.addSubview)
        [self.goalTitleLabel, self.goalTextLabel].forEach(self.goalCard.addSubview)

        self.closeButton.setTitle("Закрыть", for: .normal)
        self.closeButton.titleLabel?.font = Font.medium(16.0)
        self.closeButton.addTarget(self, action: #selector(self.closePressed), for: .touchUpInside)
        self.activityButton.titleLabel?.font = Font.semibold(16.0)
        self.activityButton.setTitle("Отметить сообщение", for: .normal)
        self.activityButton.addTarget(self, action: #selector(self.activityPressed), for: .touchUpInside)

        self.titleLabel.font = Font.bold(30.0)
        self.subtitleLabel.font = Font.regular(16.0)
        self.subtitleLabel.numberOfLines = 0
        self.flameLabel.font = Font.regular(72.0)
        self.flameLabel.text = "🔥"
        self.dayLabel.font = Font.bold(42.0)
        self.flameCaptionLabel.font = Font.medium(15.0)
        self.activityTitleLabel.font = Font.semibold(18.0)
        self.activityTextLabel.font = Font.regular(15.0)
        self.activityTextLabel.numberOfLines = 0
        self.messageValueLabel.font = Font.bold(30.0)
        self.messageTitleLabel.font = Font.regular(14.0)
        self.goalTitleLabel.font = Font.semibold(18.0)
        self.goalTextLabel.font = Font.regular(15.0)
        self.goalTextLabel.numberOfLines = 0
        self.avatarLabel.font = Font.bold(16.0)
        self.friendAvatarLabel.font = Font.bold(16.0)
        self.avatarLabel.textAlignment = .center
        self.friendAvatarLabel.textAlignment = .center

        self.flameCard.layer.cornerRadius = 28.0
        self.activityCard.layer.cornerRadius = 22.0
        self.messageCard.layer.cornerRadius = 22.0
        self.goalCard.layer.cornerRadius = 22.0
        self.activityButton.layer.cornerRadius = 14.0
        self.avatarView.layer.cornerRadius = 22.0
        self.friendAvatarView.layer.cornerRadius = 22.0
        self.friendAvatarView.layer.borderWidth = 3.0
        self.updatePresentationData(presentationData)
    }

    func updatePresentationData(_ presentationData: PresentationData) {
        self.presentationData = presentationData
        let theme = presentationData.theme
        self.backgroundView.backgroundColor = theme.list.plainBackgroundColor
        self.closeButton.setTitleColor(theme.list.itemAccentColor, for: .normal)
        self.titleLabel.textColor = theme.list.itemPrimaryTextColor
        self.subtitleLabel.textColor = theme.list.itemSecondaryTextColor
        self.dayLabel.textColor = UIColor(rgb: 0xffb119)
        self.flameCaptionLabel.textColor = UIColor(rgb: 0xa96a00)
        self.flameCard.backgroundColor = UIColor(rgb: 0xfff3d7)
        self.activityCard.backgroundColor = theme.list.itemBlocksBackgroundColor
        self.messageCard.backgroundColor = UIColor(rgb: 0xe8f4ff)
        self.goalCard.backgroundColor = UIColor(rgb: 0xf1edff)
        self.activityTitleLabel.textColor = theme.list.itemPrimaryTextColor
        self.activityTextLabel.textColor = theme.list.itemSecondaryTextColor
        self.messageValueLabel.textColor = UIColor(rgb: 0x1877c9)
        self.messageTitleLabel.textColor = UIColor(rgb: 0x397bb4)
        self.goalTitleLabel.textColor = UIColor(rgb: 0x5f4ab5)
        self.goalTextLabel.textColor = theme.list.itemSecondaryTextColor
        self.activityButton.backgroundColor = UIColor(rgb: 0xffa700)
        self.activityButton.setTitleColor(.white, for: .normal)
        self.avatarView.backgroundColor = UIColor(rgb: 0x3c8ff0)
        self.friendAvatarView.backgroundColor = UIColor(rgb: 0xffa34d)
        self.friendAvatarView.layer.borderColor = UIColor.white.cgColor
        self.avatarLabel.textColor = .white
        self.friendAvatarLabel.textColor = .white
        self.updateTexts()
    }

    private func updateTexts() {
        self.titleLabel.text = "Огонек"
        self.subtitleLabel.text = state.days > 0 ? "Ваша серия с \(peerName) уже горит. Одно настоящее сообщение сегодня сохранит ее." : "Начните общаться каждый день. После первого дня появится ваш огонек."
        self.dayLabel.text = "\(state.days)"
        self.flameCaptionLabel.text = state.days == 1 ? "день вместе" : "дней вместе"
        self.activityTitleLabel.text = state.lastActivityDay == nil ? "Зажги первый день" : "Сегодня в серии"
        self.activityTextLabel.text = "Отправьте хотя бы одно сообщение друг другу. Серия сбросится, если пропустить два дня."
        self.messageValueLabel.text = "\(state.messages)"
        self.messageTitleLabel.text = "сообщений в этой серии"
        self.goalTitleLabel.text = "Мини-задание дня"
        self.goalTextLabel.text = "Расскажите друг другу одну вещь, которая сегодня вас удивила. За 7 дней откроется следующий уровень огонька."
        self.avatarLabel.text = "Я"
        self.friendAvatarLabel.text = String(peerName.prefix(1)).uppercased()
        self.setNeedsLayout()
    }

    @objc private func closePressed() {
        self.close()
    }

    @objc private func activityPressed() {
        self.state = MegramFireStore.recordActivity(peerId: self.peerId, isStarter: self.isStarter)
        self.updateTexts()
        self.flameCard.layer.animateScale(from: 0.92, to: 1.0, duration: 0.35)
    }

    func containerLayoutUpdated(_ layout: ContainerViewLayout) {
        guard self.isNodeLoaded else { return }
        let size = layout.size
        let topInset = layout.statusBarHeight ?? 0.0
        self.backgroundView.frame = CGRect(origin: .zero, size: size)
        self.closeButton.frame = CGRect(x: size.width - 88.0, y: topInset + 8.0, width: 76.0, height: 44.0)
        self.scrollView.frame = CGRect(x: 0.0, y: topInset + 52.0, width: size.width, height: size.height - topInset - 52.0)
        let side: CGFloat = 16.0
        let width = size.width - side * 2.0
        self.contentView.frame = CGRect(x: 0.0, y: 0.0, width: size.width, height: 670.0 + layout.safeInsets.bottom)
        self.titleLabel.frame = CGRect(x: side, y: 14.0, width: width, height: 38.0)
        self.subtitleLabel.frame = CGRect(x: side, y: 56.0, width: width, height: 48.0)
        self.flameCard.frame = CGRect(x: side, y: 122.0, width: width, height: 212.0)
        self.flameLabel.frame = CGRect(x: 28.0, y: 50.0, width: 88.0, height: 88.0)
        self.dayLabel.frame = CGRect(x: 122.0, y: 64.0, width: 100.0, height: 52.0)
        self.flameCaptionLabel.frame = CGRect(x: 124.0, y: 116.0, width: 150.0, height: 24.0)
        self.avatarView.frame = CGRect(x: width - 112.0, y: 24.0, width: 44.0, height: 44.0)
        self.friendAvatarView.frame = CGRect(x: width - 76.0, y: 24.0, width: 44.0, height: 44.0)
        self.avatarLabel.frame = self.avatarView.bounds
        self.friendAvatarLabel.frame = self.friendAvatarView.bounds
        self.activityCard.frame = CGRect(x: side, y: 350.0, width: width, height: 154.0)
        self.activityTitleLabel.frame = CGRect(x: 18.0, y: 18.0, width: width - 36.0, height: 24.0)
        self.activityTextLabel.frame = CGRect(x: 18.0, y: 48.0, width: width - 36.0, height: 42.0)
        self.activityButton.frame = CGRect(x: 18.0, y: 102.0, width: width - 36.0, height: 38.0)
        self.messageCard.frame = CGRect(x: side, y: 520.0, width: (width - 10.0) * 0.45, height: 118.0)
        self.goalCard.frame = CGRect(x: side + (width - 10.0) * 0.45 + 10.0, y: 520.0, width: (width - 10.0) * 0.55, height: 118.0)
        self.messageValueLabel.frame = CGRect(x: 16.0, y: 20.0, width: self.messageCard.bounds.width - 32.0, height: 38.0)
        self.messageTitleLabel.frame = CGRect(x: 16.0, y: 64.0, width: self.messageCard.bounds.width - 32.0, height: 34.0)
        self.goalTitleLabel.frame = CGRect(x: 16.0, y: 16.0, width: self.goalCard.bounds.width - 32.0, height: 24.0)
        self.goalTextLabel.frame = CGRect(x: 16.0, y: 44.0, width: self.goalCard.bounds.width - 32.0, height: 60.0)
        self.scrollView.contentSize = self.contentView.bounds.size
    }
}

final class MegramFireScreen: ViewController {
    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    private let peerId: EnginePeer.Id
    private let peerName: String
    private let isStarter: Bool

    private var controllerNode: MegramFireScreenNode {
        return self.displayNode as! MegramFireScreenNode
    }

    init(context: AccountContext, peer: EnginePeer) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.peerId = peer.id
        self.peerName = peer.displayTitle
        if case let .user(user) = peer {
            self.isStarter = user.addressName == "weholy" || user.addressName == "entwilsupport"
        } else {
            self.isStarter = false
        }
        super.init(navigationBarPresentationData: nil)
        self.statusBar.statusBarStyle = .Ignore
        self.presentationDataDisposable = (context.sharedContext.presentationData |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            guard let self else {
                return
            }
            self.presentationData = presentationData
            if self.isNodeLoaded {
                self.controllerNode.updatePresentationData(presentationData)
            }
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.presentationDataDisposable?.dispose()
    }

    override func loadDisplayNode() {
        self.displayNode = MegramFireScreenNode(presentationData: self.presentationData, peerId: self.peerId, peerName: self.peerName, isStarter: self.isStarter)
        self.controllerNode.close = { [weak self] in
            self?.dismiss()
        }
    }

    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.controllerNode.containerLayoutUpdated(layout)
    }
}
