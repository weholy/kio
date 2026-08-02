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
    /// The cover is a thumbnail on the left and nothing else — the card behind
    /// it is a plain dark panel.
    private let coverNode: TransformImageNode
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

        super.init(frame: frame)

        self.layer.cornerRadius = 12.0
        self.clipsToBounds = true
        if #available(iOS 13.0, *) {
            self.layer.cornerCurve = .continuous
        }

        self.coverNode.contentAnimations = [.subsequentUpdates]
        self.coverNode.view.layer.cornerRadius = 6.0
        self.coverNode.view.layer.masksToBounds = true

        // A flat dark panel, not the artwork stretched behind everything: the
        // reference keeps the cover to its thumbnail and leaves the card plain.
        self.scrimView.backgroundColor = UIColor.black.withAlphaComponent(0.55)

        self.titleLabel.font = Font.semibold(14.0)
        self.titleLabel.textColor = .white
        self.titleLabel.textAlignment = .center
        self.titleLabel.lineBreakMode = .byTruncatingTail
        self.artistLabel.font = Font.regular(12.0)
        self.artistLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        self.artistLabel.textAlignment = .center
        self.artistLabel.lineBreakMode = .byTruncatingTail

        self.addSubview(self.scrimView)
        self.addSubview(self.coverNode.view)
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
                thumbnail: true
            ))
        }

        let thumbSide = max(0.0, size.height - MegramTrackCardView.verticalInset * 2.0)
        self.coverNode.asyncLayout()(TransformImageArguments(
            corners: ImageCorners(),
            imageSize: CGSize(width: thumbSide, height: thumbSide),
            boundingSize: CGSize(width: thumbSide, height: thumbSide),
            intrinsicInsets: UIEdgeInsets()
        ))()

        self.setNeedsLayout()
    }

    private static let verticalInset: CGFloat = 6.0
    private static let horizontalInset: CGFloat = 8.0

    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = self.bounds

        self.scrimView.frame = bounds
        self.button.frame = bounds

        let verticalInset = MegramTrackCardView.verticalInset
        let horizontalInset = MegramTrackCardView.horizontalInset
        let thumbSide = max(0.0, bounds.height - verticalInset * 2.0)
        self.coverNode.view.frame = CGRect(x: horizontalInset, y: verticalInset, width: thumbSide, height: thumbSide)

        // Text is centred on the whole card rather than on the space left of
        // the thumbnail, which is what the reference does. The inset keeps a
        // long title from running under the thumbnail.
        let textInset = horizontalInset + thumbSide + 8.0
        let textWidth = max(0.0, bounds.width - textInset * 2.0)
        let textHeight: CGFloat = 34.0
        let textTop = floor((bounds.height - textHeight) / 2.0)
        self.titleLabel.frame = CGRect(x: textInset, y: textTop, width: textWidth, height: 18.0)
        self.artistLabel.frame = CGRect(x: textInset, y: textTop + 18.0, width: textWidth, height: 16.0)
    }
}
