import Foundation
import UIKit
import SwiftSignalKit
import TelegramCore
import AccountContext
import AvatarNode

/// MARK: Megram — the profile's blurred backdrop.
///
/// The screen shows the peer's photo full width at the top; everything below it
/// sits on a heavily blurred copy of that same photo rather than on the theme's
/// flat panel colour.
///
/// It is pinned to the screen, not to the scroll content: the reference keeps
/// the backdrop still while the list moves over it, and scrolling it away would
/// leave the bottom of a long settings list on bare grey.
final class MegramAvatarBackdrop: UIView {
    private let imageView: UIImageView
    /// Sits over the photo so light avatars do not wash out the text above them.
    private let scrimView: UIView

    private var disposable: Disposable?
    /// The photo the current image was rendered from. Profile data updates land
    /// several times a second while a screen settles, and re-rendering a blurred
    /// photo on each of them is visible as a stutter.
    private var appliedRepresentation: TelegramMediaImageRepresentation?

    override init(frame: CGRect) {
        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true

        self.scrimView = UIView()

        super.init(frame: frame)

        self.isUserInteractionEnabled = false
        // Empty until a photo arrives, and `isHidden` is what the screen reads
        // to decide whether it still owes the theme's opaque fill.
        self.isHidden = true
        self.addSubview(self.imageView)
        self.addSubview(self.scrimView)
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    deinit {
        self.disposable?.dispose()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.frame = self.bounds
        self.scrimView.frame = self.bounds
    }

    func update(context: AccountContext, peer: EnginePeer?, isDark: Bool) {
        self.scrimView.backgroundColor = UIColor(white: isDark ? 0.0 : 1.0, alpha: isDark ? 0.45 : 0.3)

        guard let peer, let representation = peer.smallProfileImage else {
            self.appliedRepresentation = nil
            self.disposable?.dispose()
            self.disposable = nil
            self.imageView.image = nil
            self.isHidden = true
            return
        }
        self.isHidden = false

        if self.appliedRepresentation == representation {
            return
        }
        self.appliedRepresentation = representation

        // The small representation is deliberate. The result is blurred past
        // recognition anyway, so fetching the full-size photo would spend
        // bandwidth and decode time on detail that is destroyed on arrival.
        self.disposable?.dispose()
        self.disposable = (peerAvatarCompleteImage(
            account: context.account,
            peer: peer,
            size: CGSize(width: 180.0, height: 180.0),
            round: false,
            drawLetters: false,
            blurred: true
        )
        |> deliverOnMainQueue).startStrict(next: { [weak self] image in
            guard let self else {
                return
            }
            self.imageView.image = image
        })
    }
}
