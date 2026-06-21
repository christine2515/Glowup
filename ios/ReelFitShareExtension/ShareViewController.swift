import UIKit
import UniformTypeIdentifiers

/// Receives an Instagram reel shared from the Instagram app, saves the URL to
/// the App Group queue, and shows a brief confirmation. The main app drains the
/// queue on next launch/foreground.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.0)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleShare()
    }

    private func handleShare() {
        guard let item = (extensionContext?.inputItems.first as? NSExtensionItem),
              let attachments = item.attachments else {
            return complete(success: false)
        }

        let urlType = UTType.url.identifier
        let textType = UTType.plainText.identifier

        // Prefer a URL attachment; fall back to any text that contains a link.
        if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(urlType) }) {
            provider.loadItem(forTypeIdentifier: urlType, options: nil) { [weak self] data, _ in
                let url = (data as? URL)?.absoluteString
                self?.finish(url: url, text: nil)
            }
        } else if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(textType) }) {
            provider.loadItem(forTypeIdentifier: textType, options: nil) { [weak self] data, _ in
                let text = data as? String
                self?.finish(url: Self.firstURL(in: text), text: text)
            }
        } else {
            complete(success: false)
        }
    }

    private func finish(url: String?, text: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let url, !url.isEmpty else {
                self?.showToast("No link found") { self?.complete(success: false) }
                return
            }
            ShareInbox.enqueue(SharedReel(url: url, sharedText: text))
            self?.showToast("Saved to Glowup ✓") { self?.complete(success: true) }
        }
    }

    private static func firstURL(in text: String?) -> String? {
        guard let text,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        return detector.firstMatch(in: text, range: range)?.url?.absoluteString
    }

    private func showToast(_ message: String, then: @escaping () -> Void) {
        let label = UILabel()
        label.text = message
        label.textColor = .label
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: then)
    }

    private func complete(success: Bool) {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
