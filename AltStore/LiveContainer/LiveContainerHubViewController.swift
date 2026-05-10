//
//  LiveContainerHubViewController.swift
//  AltStore
//

import UIKit

/// Bridges FluxStore with the standalone **LiveContainer** app (`livecontainer://`). Guest-app execution stays in LiveContainer;
/// FluxStore acts as launcher and pointer to installs/docs.
final class LiveContainerHubViewController: UIViewController
{
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let statusLabel = UILabel()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.navigationItem.largeTitleDisplayMode = .always
        self.title = NSLocalizedString("Live Container", comment: "")
        self.view.backgroundColor = .systemGroupedBackground

        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.contentStack.translatesAutoresizingMaskIntoConstraints = false
        self.contentStack.axis = .vertical
        self.contentStack.spacing = 16

        self.scrollView.addSubview(self.contentStack)
        self.view.addSubview(self.scrollView)

        let margin: CGFloat = 16
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),

            self.contentStack.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor, constant: margin),
            self.contentStack.leadingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.leadingAnchor, constant: margin),
            self.contentStack.trailingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.trailingAnchor, constant: -margin),
            self.contentStack.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor, constant: -margin),
            self.contentStack.widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor, constant: -margin * 2),
        ])

        self.statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        self.statusLabel.numberOfLines = 0

        let intro = self.makeBodyLabel(text: NSLocalizedString(
            "LiveContainer runs other apps inside one host install so sideload slots stay free for FluxStore. Install the LiveContainer IPA, add IPAs inside it, then use Open to jump over. Data and guests are managed entirely in LiveContainer.",
            comment: "Live Container hub explanatory text"
        ))

        self.contentStack.addArrangedSubview(self.makeCard(wrapping: self.statusLabel))
        self.contentStack.addArrangedSubview(intro)

        var openConfiguration = UIButton.Configuration.filled()
        openConfiguration.title = NSLocalizedString("Open LiveContainer", comment: "")
        openConfiguration.image = UIImage(systemName: "arrow.up.forward.app")
        openConfiguration.imagePlacement = .leading
        openConfiguration.imagePadding = 8
        openConfiguration.baseBackgroundColor = .altPrimary
        openConfiguration.cornerStyle = .large
        let openButton = UIButton(configuration: openConfiguration)
        openButton.addAction(UIAction { [weak self] _ in self?.openLiveContainer() }, for: .primaryActionTriggered)
        self.contentStack.addArrangedSubview(openButton)

        let secondary = UIStackView()
        secondary.axis = .vertical
        secondary.spacing = 10
        secondary.addArrangedSubview(self.makeOutlineLinkButton(
            title: NSLocalizedString("Latest LiveContainer IPA", comment: ""),
            symbol: "arrow.down.circle",
            urlString: "https://github.com/LiveContainer/LiveContainer/releases/latest"
        ))
        secondary.addArrangedSubview(self.makeOutlineLinkButton(
            title: NSLocalizedString("Documentation", comment: ""),
            symbol: "book",
            urlString: "https://livecontainer.github.io/docs/intro"
        ))
        self.contentStack.addArrangedSubview(secondary)
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.refreshInstallStatus()
    }

    private func refreshInstallStatus()
    {
        let primary = LiveContainerURLs.primaryLaunch
        guard let primaryURL = URL(string: primary) else { return }

        let hasExtraSlots = LiveContainerURLs.extraLaunchSchemes.contains { scheme in
            guard let u = URL(string: scheme) else { return false }
            return UIApplication.shared.canOpenURL(u)
        }

        if UIApplication.shared.canOpenURL(primaryURL)
        {
            self.statusLabel.text = hasExtraSlots
                ? NSLocalizedString("LiveContainer is installed. Extra instances were detected.", comment: "")
                : NSLocalizedString("LiveContainer is installed. Tap Open to switch to it.", comment: "")
            self.statusLabel.textColor = .fluxSecondaryText
        }
        else
        {
            self.statusLabel.text = NSLocalizedString(
                "LiveContainer is not detected. Install its IPA first, then return to this tab.",
                comment: ""
            )
            self.statusLabel.textColor = .systemOrange
        }
    }

    private func openLiveContainer()
    {
        guard let url = URL(string: LiveContainerURLs.primaryLaunch) else { return }
        guard UIApplication.shared.canOpenURL(url) else
        {
            let alert = UIAlertController(
                title: NSLocalizedString("Cannot Open LiveContainer", comment: ""),
                message: NSLocalizedString("Install LiveContainer from the latest GitHub release, then try again.", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel))
            self.present(alert, animated: true)
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func makeBodyLabel(text: String) -> UILabel
    {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }

    private func makeCard(wrapping subview: UIView) -> UIView
    {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        subview.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(subview)
        wrapper.backgroundColor = .fluxCardBackground
        wrapper.layer.cornerRadius = 18
        wrapper.layer.cornerCurve = .continuous
        wrapper.layer.borderWidth = 1
        wrapper.layer.borderColor = UIColor.fluxCardBorder.cgColor

        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 14),
            subview.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 14),
            subview.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -14),
            subview.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -14),
        ])
        return wrapper
    }

    private func makeOutlineLinkButton(title: String, symbol: String, urlString: String) -> UIButton
    {
        var configuration = UIButton.Configuration.borderedTinted()
        configuration.title = title
        configuration.image = UIImage(systemName: symbol)
        configuration.imagePlacement = .leading
        configuration.imagePadding = 8
        configuration.cornerStyle = .large

        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { _ in
            guard let url = URL(string: urlString) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }, for: .primaryActionTriggered)

        return button
    }
}

private enum LiveContainerURLs
{
    static let primaryLaunch = "livecontainer://"
    static let extraLaunchSchemes = ["livecontainer2://", "livecontainer3://"]
}
