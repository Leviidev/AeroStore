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
        image = UIImage(named: "AeroStoreMark")
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
