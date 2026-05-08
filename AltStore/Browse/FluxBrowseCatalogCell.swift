//
//  FluxBrowseCatalogCell.swift
//

import UIKit
import Nuke

enum FluxBrowseCatalogCellMode {
    case ownedChevron
    case addCatalog
}

final class FluxBrowseCatalogCell: UITableViewCell {
    static let reuseID = "FluxBrowseCatalogCell"

    private let cardView = UIView()
    private let iconContainer = UIView()
    let iconView = UIImageView()
    private var iconImageTask: ImageTask?
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    private let metaLabel = UILabel()
    private let accessoryImg = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureHierarchy()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureHierarchy()
    }

    private func configureHierarchy() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = 22
        cardView.layer.cornerCurve = .continuous
        cardView.backgroundColor = UIColor.fluxCardBackground
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.fluxCardBorder.cgColor

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 14
        iconContainer.layer.cornerCurve = .continuous
        iconContainer.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.12)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 10
        iconView.layer.cornerCurve = .continuous
        iconView.tintColor = .altPrimary
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = UIColor.fluxSecondaryText
        subtitleLabel.numberOfLines = 2

        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        metaLabel.font = .preferredFont(forTextStyle: .caption1)
        metaLabel.textColor = UIColor.fluxSecondaryText.withAlphaComponent(0.85)
        metaLabel.numberOfLines = 1

        accessoryImg.translatesAutoresizingMaskIntoConstraints = false
        accessoryImg.contentMode = .scaleAspectFit

        contentView.addSubview(cardView)
        cardView.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(metaLabel)
        cardView.addSubview(accessoryImg)

        let pad: CGFloat = 16
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            iconContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: pad),
            iconContainer.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 56),
            iconContainer.heightAnchor.constraint(equalToConstant: 56),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: pad),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: accessoryImg.leadingAnchor, constant: -10),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            metaLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 6),
            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            metaLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -pad),

            accessoryImg.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            accessoryImg.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -pad),
            accessoryImg.widthAnchor.constraint(equalToConstant: 22),
            accessoryImg.heightAnchor.constraint(equalToConstant: 22),
        ])
    }

    func configure(title: String, subtitle: String, meta: String?, mode: FluxBrowseCatalogCellMode) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        metaLabel.text = meta
        metaLabel.isHidden = (meta == nil || meta?.isEmpty == true)

        switch mode {
        case .ownedChevron:
            accessoryImg.image = UIImage(systemName: "chevron.right")?.withTintColor(UIColor.fluxSecondaryText, renderingMode: .alwaysOriginal)
        case .addCatalog:
            accessoryImg.image = UIImage(systemName: "plus.circle.fill")?.withTintColor(.altPrimary, renderingMode: .alwaysOriginal)
        }
    }

    /// Loads remote artwork for owned catalogs; picks use a Flux-forward glyph tile.
    func applyVisuals(mode: FluxBrowseCatalogCellMode, artworkURL: URL?, pickGlyph: String = "sparkles.rectangle.stack") {
        iconImageTask?.cancel()
        iconImageTask = nil

        switch mode {
        case .ownedChevron:
            if let artworkURL {
                iconContainer.backgroundColor = .white
                iconView.image = nil
                iconView.tintColor = nil
                iconImageTask = Nuke.loadImage(with: artworkURL, into: iconView) { [weak self] result in
                    guard let self else { return }
                    if case .failure = result {
                        self.applyOwnedFallbackGlyph()
                    }
                }
            } else {
                applyOwnedFallbackGlyph()
            }

        case .addCatalog:
            iconContainer.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.95)
            iconView.image = UIImage(systemName: pickGlyph)
            iconView.tintColor = .white
        }
    }

    private func applyOwnedFallbackGlyph() {
        iconContainer.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.12)
        iconView.image = UIImage(systemName: "square.stack.3d.up.fill")
        iconView.tintColor = .altPrimary
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageTask?.cancel()
        iconImageTask = nil
        iconView.image = nil
        iconView.tintColor = .altPrimary
        iconContainer.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.12)
        metaLabel.isHidden = false
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.15) {
            self.cardView.transform = highlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            self.cardView.alpha = highlighted ? 0.92 : 1
        }
    }
}
