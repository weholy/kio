import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import PhotoResources
import UniversalMediaPlayer

/// The saved track drawn as a card: title over artist, with the track's own
/// cover stretched behind it under a blur.
///
/// The card only exists when the track has a cover — a blurred nothing behind
/// two lines of text reads worse than the plain strip it replaces, so the
/// caller falls back to that instead.
final class MegramTrackCardView: UIView {
    private let coverNode: TransformImageNode
    private let blurView: UIVisualEffectView
    private let scrimView = UIView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let button = HighlightTrackingButton()

    private var appliedCoverKey: String?

    var pressed: (() -> Void)?

    /// True when a cover was found and the card is worth showing.
    static func hasCover(file: TelegramMediaFile) -> Bool {
        return !file.previewRepresentations.isEmpty
    }

    override init(frame: CGRect) {
        self.coverNode = TransformImageNode()
        self.blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))

        super.init(frame: frame)

        self.layer.cornerRadius = 14.0
        self.clipsToBounds = true
        if #available(iOS 13.0, *) {
            self.layer.cornerCurve = .continuous
        }

        self.coverNode.contentAnimations = [.subsequentUpdates]

        // A dark scrim under the text: a blurred cover alone does not guarantee
        // enough contrast for white text on a bright album.
        self.scrimView.backgroundColor = UIColor.black.withAlphaComponent(0.28)

        self.titleLabel.font = Font.semibold(14.0)
        self.titleLabel.textColor = .white
        self.titleLabel.lineBreakMode = .byTruncatingTail
        self.artistLabel.font = Font.regular(12.0)
        self.artistLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        self.artistLabel.lineBreakMode = .byTruncatingTail

        self.addSubview(self.coverNode.view)
        self.addSubview(self.blurView)
        self.addSubview(self.scrimView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.artistLabel)
        self.addSubview(self.button)

        self.button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
        self.button.highligthedChanged = { [weak self] highlighted in
            guard let self else {
                return
            }
            self.alpha = highlighted ? 0.8 : 1.0
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    @objc private func buttonPressed() {
        self.pressed?()
    }

    func update(context: AccountContext, file: TelegramMediaFile, title: String, artist: String, size: CGSize) {
        self.titleLabel.text = title
        self.artistLabel.text = artist

        // Reloading the same cover on every layout pass would thrash the image
        // pipeline; the resource id is stable per track.
        let coverKey = file.previewRepresentations.first?.resource.id.stringRepresentation
        if let coverKey, coverKey != self.appliedCoverKey {
            self.appliedCoverKey = coverKey
            self.coverNode.setSignal(playerAlbumArt(
                engine: context.engine,
                fileReference: .standalone(media: file),
                albumArt: nil,
                thumbnail: false
            ))
        }

        let coverSide = max(size.width, size.height)
        let arguments = TransformImageArguments(
            corners: ImageCorners(),
            imageSize: CGSize(width: coverSide, height: coverSide),
            boundingSize: CGSize(width: coverSide, height: coverSide),
            intrinsicInsets: UIEdgeInsets()
        )
        self.coverNode.asyncLayout()(arguments)()

        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = self.bounds

        // The cover is square and fills the card by its longest side, so it
        // never letterboxes behind the blur.
        let coverSide = max(bounds.width, bounds.height)
        self.coverNode.view.frame = CGRect(
            x: (bounds.width - coverSide) / 2.0,
            y: (bounds.height - coverSide) / 2.0,
            width: coverSide,
            height: coverSide
        )
        self.blurView.frame = bounds
        self.scrimView.frame = bounds
        self.button.frame = bounds

        let inset: CGFloat = 12.0
        let textWidth = max(0.0, bounds.width - inset * 2.0)
        self.titleLabel.frame = CGRect(x: inset, y: 9.0, width: textWidth, height: 18.0)
        self.artistLabel.frame = CGRect(x: inset, y: 28.0, width: textWidth, height: 16.0)
    }
}
