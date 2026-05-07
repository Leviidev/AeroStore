//
//  FluxLogoView.swift
//  AltStore
//

import UIKit

final class FluxLogoView: UIView {
    private let gradient = CAGradientLayer()
    private let glyphLayer = CAShapeLayer()
    private let glowLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        self.layer.cornerCurve = .continuous
        self.layer.cornerRadius = 24
        self.layer.masksToBounds = true
        self.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)
                : UIColor(red: 0.12, green: 0.13, blue: 0.16, alpha: 1.0)
        }

        gradient.colors = [
            UIColor(red: 0.98, green: 0.43, blue: 0.25, alpha: 1.0).cgColor,
            UIColor(red: 0.98, green: 0.67, blue: 0.28, alpha: 1.0).cgColor,
            UIColor(red: 0.32, green: 0.80, blue: 0.94, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.25)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.9)
        self.layer.addSublayer(gradient)

        glowLayer.fillColor = UIColor.clear.cgColor
        glowLayer.strokeColor = UIColor.white.withAlphaComponent(0.30).cgColor
        glowLayer.lineWidth = 14
        glowLayer.lineCap = .round
        glowLayer.lineJoin = .round
        glowLayer.shadowColor = UIColor.white.cgColor
        glowLayer.shadowOpacity = 0.30
        glowLayer.shadowRadius = 10
        glowLayer.shadowOffset = .zero
        self.layer.addSublayer(glowLayer)

        glyphLayer.fillColor = UIColor.clear.cgColor
        glyphLayer.strokeColor = UIColor.white.cgColor
        glyphLayer.lineWidth = 10
        glyphLayer.lineCap = .round
        glyphLayer.lineJoin = .round
        self.layer.addSublayer(glyphLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = self.bounds

        let inset = bounds.width * 0.22
        let left = inset
        let right = bounds.width - inset
        let top = bounds.height * 0.24
        let mid = bounds.height * 0.50
        let bottom = bounds.height * 0.76

        let path = UIBezierPath()
        path.move(to: CGPoint(x: right, y: top))
        path.addCurve(
            to: CGPoint(x: left, y: mid),
            controlPoint1: CGPoint(x: bounds.width * 0.62, y: top),
            controlPoint2: CGPoint(x: bounds.width * 0.36, y: bounds.height * 0.40)
        )
        path.addLine(to: CGPoint(x: bounds.width * 0.62, y: mid))
        path.move(to: CGPoint(x: bounds.width * 0.62, y: mid))
        path.addCurve(
            to: CGPoint(x: left, y: bottom),
            controlPoint1: CGPoint(x: bounds.width * 0.47, y: bounds.height * 0.60),
            controlPoint2: CGPoint(x: bounds.width * 0.32, y: bottom)
        )

        glyphLayer.path = path.cgPath
        glowLayer.path = path.cgPath
    }
}
