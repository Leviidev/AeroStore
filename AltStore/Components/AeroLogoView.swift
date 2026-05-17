//
//  AeroLogoView.swift
//  AltStore
//

import UIKit

/// Vector AeroStore mark: sky gradient tile with a bold “A” wing glyph.
final class AeroLogoView: UIView {
    private let gradient = CAGradientLayer()
    private let glyphLayer = CAShapeLayer()
    private let highlightLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isAccessibilityElement = true
        accessibilityLabel = "AeroStore"

        layer.cornerCurve = .continuous
        layer.cornerRadius = 24
        layer.masksToBounds = true

        gradient.colors = [
            UIColor(red: 0.04, green: 0.52, blue: 0.98, alpha: 1.0).cgColor,
            UIColor(red: 0.20, green: 0.72, blue: 1.00, alpha: 1.0).cgColor,
            UIColor(red: 0.45, green: 0.88, blue: 0.98, alpha: 1.0).cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0.1, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.addSublayer(gradient)

        highlightLayer.fillColor = UIColor.white.withAlphaComponent(0.12).cgColor
        layer.addSublayer(highlightLayer)

        glyphLayer.fillColor = UIColor.white.cgColor
        glyphLayer.strokeColor = UIColor.clear.cgColor
        layer.addSublayer(glyphLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds

        let highlight = UIBezierPath(
            roundedRect: bounds.insetBy(dx: bounds.width * 0.08, dy: bounds.height * 0.55),
            cornerRadius: bounds.width * 0.2
        )
        highlightLayer.path = highlight.cgPath

        let w = bounds.width
        let h = bounds.height
        let path = UIBezierPath()
        path.move(to: CGPoint(x: w * 0.50, y: h * 0.20))
        path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.80))
        path.addLine(to: CGPoint(x: w * 0.64, y: h * 0.80))
        path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.54))
        path.addLine(to: CGPoint(x: w * 0.36, y: h * 0.80))
        path.addLine(to: CGPoint(x: w * 0.22, y: h * 0.80))
        path.close()

        let bar = UIBezierPath(rect: CGRect(x: w * 0.31, y: h * 0.58, width: w * 0.38, height: h * 0.09))
        path.append(bar)

        let wing = UIBezierPath()
        wing.move(to: CGPoint(x: w * 0.54, y: h * 0.34))
        wing.addQuadCurve(to: CGPoint(x: w * 0.86, y: h * 0.46), controlPoint: CGPoint(x: w * 0.78, y: h * 0.28))
        wing.addLine(to: CGPoint(x: w * 0.80, y: h * 0.54))
        wing.addQuadCurve(to: CGPoint(x: w * 0.54, y: h * 0.44), controlPoint: CGPoint(x: w * 0.70, y: h * 0.50))
        wing.close()
        path.append(wing)

        glyphLayer.path = path.cgPath
    }
}

/// Legacy name used in a few call sites during the Flux → Aero rebrand.
typealias FluxLogoView = AeroLogoView
