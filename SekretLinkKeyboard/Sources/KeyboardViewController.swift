import UIKit
import SwiftUI

final class KeyboardViewController: UIInputViewController {

    private var hostingController: UIHostingController<KeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewModel = KeyboardViewModel { [weak self] url in
            self?.insertURL(url)
        }

        let keyboardView = KeyboardView(
            viewModel: viewModel,
            onNextKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            }
        )

        let hosting = UIHostingController(rootView: keyboardView)
        hostingController = hosting

        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)

        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func insertURL(_ url: String) {
        textDocumentProxy.insertText(url)
    }
}
