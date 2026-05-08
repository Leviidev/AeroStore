//
//  FluxAddCatalogViewController.swift
//

import UIKit
import AltStoreCore
import Nuke

/// Flux-branded add-catalog flow (replaces presenting SideStore’s legacy Add Source UI from Browse).
final class FluxAddCatalogViewController: UIViewController {

    var prefilledURL: URL?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let urlField = UITextField()
    private let pasteButton = UIButton(type: .system)
    private let previewButton = UIButton(type: .system)

    private let previewContainer = UIStackView()
    private let previewIconWrap = UIView()
    private let previewIcon = UIImageView()

    private let previewTitle = UILabel()
    private let previewSubtitle = UILabel()
    private let addButton = UIButton(type: .system)

    private let activity = UIActivityIndicatorView(style: .medium)

    private var fetchedSource: Source?
    private var didAutoPreview = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .altBackground
        title = NSLocalizedString("Add catalog", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive

        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        let intro = UILabel()
        intro.translatesAutoresizingMaskIntoConstraints = false
        intro.text = NSLocalizedString("Paste an AltStore-compatible catalog URL. FluxStore shows a live preview—nothing is saved until you confirm.", comment: "")
        intro.font = .preferredFont(forTextStyle: .body)
        intro.textColor = UIColor.fluxSecondaryText
        intro.numberOfLines = 0

        urlField.translatesAutoresizingMaskIntoConstraints = false
        urlField.borderStyle = .roundedRect
        urlField.placeholder = "https://"
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = .no
        urlField.keyboardType = .URL
        urlField.backgroundColor = UIColor.fluxCardBackground
        urlField.textColor = .label

        pasteButton.setTitle(NSLocalizedString("Paste", comment: ""), for: .normal)
        pasteButton.addTarget(self, action: #selector(pasteTapped), for: .touchUpInside)

        previewButton.translatesAutoresizingMaskIntoConstraints = false
        previewButton.setTitle(NSLocalizedString("Preview catalog", comment: ""), for: .normal)
        previewButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        previewButton.backgroundColor = .altPrimary
        previewButton.setTitleColor(.white, for: .normal)
        previewButton.layer.cornerRadius = 14
        previewButton.layer.cornerCurve = .continuous
        previewButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        previewButton.addTarget(self, action: #selector(previewTapped), for: .touchUpInside)

        previewContainer.axis = .vertical
        previewContainer.spacing = 12
        previewContainer.isHidden = true
        previewContainer.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        previewContainer.isLayoutMarginsRelativeArrangement = true
        previewContainer.backgroundColor = UIColor.fluxCardBackground
        previewContainer.layer.cornerRadius = 18
        previewContainer.layer.cornerCurve = .continuous
        previewContainer.layer.borderWidth = 1
        previewContainer.layer.borderColor = UIColor.fluxCardBorder.cgColor

        previewIconWrap.translatesAutoresizingMaskIntoConstraints = false
        previewIcon.translatesAutoresizingMaskIntoConstraints = false
        previewIcon.layer.cornerRadius = 16
        previewIcon.layer.cornerCurve = .continuous
        previewIcon.clipsToBounds = true
        previewIcon.contentMode = .scaleAspectFill
        previewIcon.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.12)

        previewIconWrap.addSubview(previewIcon)
        NSLayoutConstraint.activate([
            previewIconWrap.heightAnchor.constraint(equalToConstant: 72),
            previewIcon.leadingAnchor.constraint(equalTo: previewIconWrap.leadingAnchor),
            previewIcon.centerYAnchor.constraint(equalTo: previewIconWrap.centerYAnchor),
            previewIcon.widthAnchor.constraint(equalToConstant: 64),
            previewIcon.heightAnchor.constraint(equalToConstant: 64),
        ])

        previewTitle.font = .systemFont(ofSize: 20, weight: .bold)
        previewTitle.textColor = .label
        previewTitle.numberOfLines = 0

        previewSubtitle.font = .preferredFont(forTextStyle: .subheadline)
        previewSubtitle.textColor = UIColor.fluxSecondaryText
        previewSubtitle.numberOfLines = 0

        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle(NSLocalizedString("Add to FluxStore", comment: ""), for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        addButton.backgroundColor = UIColor.refreshGreen
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 14
        addButton.layer.cornerCurve = .continuous
        addButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        addButton.isHidden = true
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.hidesWhenStopped = true

        let fieldRow = UIStackView(arrangedSubviews: [urlField, pasteButton])
        fieldRow.axis = .horizontal
        fieldRow.spacing = 10
        fieldRow.alignment = .center

        previewContainer.addArrangedSubview(previewIconWrap)
        previewContainer.addArrangedSubview(previewTitle)
        previewContainer.addArrangedSubview(previewSubtitle)

        stack.addArrangedSubview(intro)
        stack.addArrangedSubview(fieldRow)
        stack.addArrangedSubview(previewButton)
        stack.addArrangedSubview(activity)
        stack.addArrangedSubview(previewContainer)
        stack.addArrangedSubview(addButton)

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),

            urlField.heightAnchor.constraint(equalToConstant: 44),
        ])

        if let prefilledURL {
            urlField.text = prefilledURL.absoluteString
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didAutoPreview, prefilledURL != nil else { return }
        didAutoPreview = true
        DispatchQueue.main.async { [weak self] in self?.previewTapped() }
    }

    @objc private func pasteTapped() {
        if let s = UIPasteboard.general.string {
            urlField.text = s
        }
    }

    @objc private func previewTapped() {
        view.endEditing(true)

        guard let raw = urlField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            presentSimpleAlert(title: NSLocalizedString("URL needed", comment: ""), message: NSLocalizedString("Enter a catalog URL to continue.", comment: ""))
            return
        }

        var urlToTry = URL(string: raw)
        if urlToTry?.scheme == nil {
            urlToTry = URL(string: "https://" + raw)
        }

        guard let url = urlToTry else {
            presentSimpleAlert(title: NSLocalizedString("Invalid URL", comment: ""), message: NSLocalizedString("FluxStore couldn’t parse that address.", comment: ""))
            return
        }

        previewButton.isEnabled = false
        activity.startAnimating()
        fetchedSource = nil
        previewContainer.isHidden = true
        addButton.isHidden = true
        previewIcon.image = nil

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let source = try await AppManager.shared.fetchSource(sourceURL: url)
                // `fetchSource` uses a background MOC by default; Core Data attributes must be read on that queue.
                guard let moc = source.managedObjectContext else {
                    await MainActor.run {
                        self.activity.stopAnimating()
                        self.previewButton.isEnabled = true
                        self.presentSimpleAlert(
                            title: NSLocalizedString("Can’t load catalog", comment: ""),
                            message: NSLocalizedString("The preview could not be prepared. Try again.", comment: "")
                        )
                    }
                    return
                }
                let preview = await moc.performAsync {
                    (
                        name: source.name,
                        subtitleLine: source.subtitle ?? source.sourceURL.absoluteString,
                        iconURL: source.effectiveIconURL
                    )
                }
                await MainActor.run {
                    self.fetchedSource = source
                    self.previewTitle.text = preview.name
                    self.previewSubtitle.text = preview.subtitleLine
                    self.previewContainer.isHidden = false
                    self.addButton.isHidden = false
                    self.activity.stopAnimating()
                    self.previewButton.isEnabled = true

                    if let iconURL = preview.iconURL {
                        self.previewIcon.backgroundColor = .white
                        self.previewIcon.tintColor = nil
                        Nuke.loadImage(with: iconURL, into: self.previewIcon)
                    } else {
                        self.previewIcon.image = UIImage(systemName: "square.stack.3d.up.fill")
                        self.previewIcon.tintColor = .altPrimary
                        self.previewIcon.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.12)
                    }
                }
            } catch {
                await MainActor.run {
                    self.activity.stopAnimating()
                    self.previewButton.isEnabled = true
                    self.presentSimpleAlert(title: NSLocalizedString("Can’t load catalog", comment: ""), message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func addTapped() {
        guard let source = fetchedSource else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await AppManager.shared.add(
                    source,
                    message: NSLocalizedString("FluxStore only refreshes apps from catalogs you trust. If you don’t recognize this publisher, tap Cancel and verify the URL.", comment: ""),
                    presentingViewController: self
                )

                self.dismiss(animated: true)
            } catch is CancellationError {
            } catch {
                self.presentSimpleAlert(title: NSLocalizedString("Unable to add catalog", comment: ""), message: error.localizedDescription)
            }
        }
    }

    /// Sync alert only — avoids colliding with `UIViewController.presentAlert` (async) in AltStoreCore.
    private func presentSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
    }
}
