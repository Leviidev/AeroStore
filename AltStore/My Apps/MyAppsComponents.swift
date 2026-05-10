//
//  MyAppsComponents.swift
//  AltStore
//
//  Created by Riley Testut on 7/17/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit
import Roxas
import AltStoreCore

final class InstalledAppCollectionViewCell: UICollectionViewCell
{
    private(set) var deactivateBadge: UIView?
    
    @IBOutlet var bannerView: AppBannerView!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.preservesSuperviewLayoutMargins = true
        self.contentView.backgroundColor = UIColor.fluxCardBackground
        self.contentView.layer.cornerRadius = 20
        self.contentView.layer.cornerCurve = .continuous
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor.fluxCardBorder.cgColor
        self.contentView.layer.masksToBounds = true

        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.07
        self.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.layer.shadowRadius = 10
        
        let deactivateBadge = UIView()
        deactivateBadge.translatesAutoresizingMaskIntoConstraints = false
        deactivateBadge.isHidden = true
        self.addSubview(deactivateBadge)
        
        // Solid background to make the X opaque white.
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .white
        deactivateBadge.addSubview(backgroundView)
                    
        let badgeView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
        badgeView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(scale: .large)
        badgeView.tintColor = .systemRed
        deactivateBadge.addSubview(badgeView, pinningEdgesWith: .zero)
        
        NSLayoutConstraint.activate([
            deactivateBadge.centerXAnchor.constraint(equalTo: self.bannerView.iconImageView.trailingAnchor),
            deactivateBadge.centerYAnchor.constraint(equalTo: self.bannerView.iconImageView.topAnchor),
            
            backgroundView.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            backgroundView.widthAnchor.constraint(equalTo: badgeView.widthAnchor, multiplier: 0.5),
            backgroundView.heightAnchor.constraint(equalTo: badgeView.heightAnchor, multiplier: 0.5)
        ])
        
        self.deactivateBadge = deactivateBadge
    }

    override func layoutSubviews()
    {
        super.layoutSubviews()
        self.layer.shadowPath = UIBezierPath(roundedRect: self.contentView.frame, cornerRadius: self.contentView.layer.cornerRadius).cgPath
    }
}

final class InstalledAppsCollectionFooterView: UICollectionReusableView
{
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var button: UIButton!
}

final class NoUpdatesCollectionViewCell: UICollectionViewCell
{
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var button: UIButton!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.contentView.preservesSuperviewLayoutMargins = true
        self.contentView.layer.cornerRadius = 20
        self.contentView.layer.cornerCurve = .continuous
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor.fluxCardBorder.cgColor
        self.blurView.layer.cornerRadius = 20
        self.blurView.clipsToBounds = true
        
        let font = self.textLabel.font ?? UIFont.systemFont(ofSize: 17)
        let configuration = UIImage.SymbolConfiguration(font: font)
        let image = UIImage(systemName: "ellipsis.circle", withConfiguration: configuration)
        
        self.button.setTitle("", for: .normal)
        self.button.setImage(image, for: .normal)
    }
}

final class FluxStoreSelfUpdateCell: UICollectionViewCell
{
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let iconView = UIImageView()

    override init(frame: CGRect)
    {
        super.init(frame: frame)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .fluxCardBackground
        cardView.layer.cornerRadius = 20
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.fluxCardBorder.cgColor

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "arrow.down.circle.fill")
        iconView.tintColor = .altPrimary
        iconView.contentMode = .scaleAspectFit

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .fluxSecondaryText
        subtitleLabel.numberOfLines = 2

        contentView.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
        ])

        contentView.preservesSuperviewLayoutMargins = true
    }

    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with info: FluxStoreGitHubRelease.UpdateInfo)
    {
        titleLabel.text = String(format: NSLocalizedString("FluxStore %@ is available", comment: ""), info.versionString)
        subtitleLabel.text = NSLocalizedString("Tap to download the latest IPA from GitHub", comment: "")
    }
}

final class UpdatesCollectionHeaderView: UICollectionReusableView
{
    let button = PillButton(type: .system)
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.setTitle(">", for: .normal)
        self.addSubview(self.button)
        
        NSLayoutConstraint.activate([self.button.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
                                     self.button.topAnchor.constraint(equalTo: self.topAnchor),
                                     self.button.widthAnchor.constraint(equalToConstant: 50),
                                     self.button.heightAnchor.constraint(equalToConstant: 26)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
