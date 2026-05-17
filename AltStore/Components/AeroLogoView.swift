//
//  AeroLogoView.swift
//  AltStore
//

import UIKit

/// Displays the AeroStore app mark from `AeroStoreMark` in the asset catalog.
final class AeroLogoView: UIImageView {
    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        if let image = UIImage(named: "AeroStoreMark") {
            self.image = image
        } else {
            print("⚠️ AeroLogoView: AeroStoreMark image not found, using fallback")
            // Create a simple fallback view
            backgroundColor = .systemGray5
        }
        contentMode = .scaleAspectFit
        clipsToBounds = true
        layer.cornerCurve = .continuous
        isAccessibilityElement = true
        accessibilityLabel = "AeroStore"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width * 0.22
    }
}

/// Legacy name used in a few call sites during the Flux → Aero rebrand.
typealias FluxLogoView = AeroLogoView
