//
//  CircleView.swift
//  Network Quality Monitor
//
//  Created by Kichibekov Ramiz on 08.05.17.
//  Copyright © 2017 Kichibekov Ramiz. All rights reserved.
//

import Foundation
import UIKit

public protocol CircularViewDelegate: NSObjectProtocol {
    func circularSlider(_ circularSlider: KRCircleView, valueForValue value: Float) -> Float
}

@IBDesignable
open class KRCircleView: UIView {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconCenterY: NSLayoutConstraint!
    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var separatorLabel: UILabel!
    @IBOutlet weak var bottomLineView: UIView!
    
    weak var delegate: CircularViewDelegate?
    
    fileprivate var containerView: UIView!
    fileprivate var backgroundCircleLayer = CAShapeLayer()
    fileprivate var progressCircleLayer = CAShapeLayer()
    fileprivate var knobLayer = CAShapeLayer()
    fileprivate var backingValue: Float = 0
    fileprivate var backingKnobAngle: CGFloat = 0
    fileprivate var rotationGesture: RotationGesture?
    fileprivate var backingFractionDigits: Int = 2
    fileprivate let maxFractionDigits: Int = 4
    
    fileprivate var startAngle: CGFloat {
        return -.pi / 2 + radiansOffset
    }
    fileprivate var endAngle: CGFloat {
        return 3 * .pi / 2 - radiansOffset
    }
    fileprivate var angleRange: CGFloat {
        return endAngle - startAngle
    }
    fileprivate var valueRange: Float {
        return maximumValue - minimumValue
    }
    fileprivate var arcCenter: CGPoint {
        return CGPoint(x: frame.width / 2, y: frame.height / 2)
    }
    fileprivate var arcRadius: CGFloat {
        return min(frame.width,frame.height) / 2 - lineWidth / 2
    }
    fileprivate var normalizedValue: Float {
        return (value - minimumValue) / (maximumValue - minimumValue)
    }
    fileprivate var knobAngle: CGFloat {
        return CGFloat(normalizedValue) * angleRange + startAngle
    }
    fileprivate var knobMidAngle: CGFloat {
        return (2 * .pi + startAngle - endAngle) / 2 + endAngle
    }
    fileprivate var knobRotationTransform: CATransform3D {
        return CATransform3DMakeRotation(knobAngle, 0.0, 0.0, 1)
    }
    
    @IBInspectable
    var title: String = "Title" {
        didSet {
            titleLabel.text = title
        }
    }
    @IBInspectable
    var titleColor: UIColor = UIColor.white {
        didSet {
            appearenceTitleColor()
        }
    }
    @IBInspectable
    var radiansOffset: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable
    var icon: UIImage? = UIImage() {
        didSet {
            configureIcon()
        }
    }
    @IBInspectable
    var separator: String = "" {
        didSet {
            appearanceSeparator()
        }
    }
    @IBInspectable
    var value: Float {
        set {
            backingValue = min(maximumValue, max(minimumValue, newValue))
        } get {
            return backingValue
        }
    }
    @IBInspectable
    var valueColor: UIColor = UIColor.black {
        didSet {
            appearenceValueColor()
        }
    }
    @IBInspectable
    var bottomLineColor: UIColor = UIColor.white {
        didSet {
            appearanceBottomLine()
        }
    }
    
    @IBInspectable
    var minimumValue: Float = 100
    @IBInspectable
    var maximumValue: Float = 300
    @IBInspectable
    var lineWidth: CGFloat = 5 {
        didSet {
            appearanceBackgroundLayer()
            appearanceProgressLayer()
        }
    }
    @IBInspectable
    var lineColor: UIColor = UIColor.white {
        didSet {
            appearanceBackgroundLayer()
        }
    }
    @IBInspectable
    var lineDisableColor: UIColor = UIColor.lightGray {
        didSet {
            appearanceProgressLayer()
        }
    }
    @IBInspectable
    var lineHighlightedColor: UIColor = UIColor.green {
        didSet {
            appearanceProgressLayer()
        }
    }
    @IBInspectable
    var knobRadius: CGFloat = 20 {
        didSet {
            appearanceKnobLayer()
        }
    }
    @IBInspectable
    var highlighted: Bool = true {
        didSet {
            appearanceProgressLayer()
            appearanceKnobLayer()
        }
    }
    @IBInspectable
    var changeValueForTouch: Bool = true {
        didSet {
            setChangeValueForTouch(self.changeValueForTouch)
        }
    }
    
    @IBInspectable
    var hideLabels: Bool = false {
        didSet {
            setLabelsHidden(self.hideLabels)
        }
    }
    @IBInspectable
    var fractionDigits: NSInteger {
        set {
            backingFractionDigits = min(maxFractionDigits, max(0, newValue))
        } get {
            return backingFractionDigits
        }
    }
    @IBInspectable
    var customDecimalSeparator: String? = nil {
        didSet {
            if let customSeparator = self.customDecimalSeparator, customSeparator.characters.count > 1 {
                self.customDecimalSeparator = nil
            }
        }
    }
    
    //MARK: init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        fromNib()
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fromNib()
        configure()
    }
    
    override open func draw(_ rect: CGRect) {
        backgroundCircleLayer.bounds = bounds
        progressCircleLayer.bounds = bounds
        knobLayer.bounds = bounds
        
        backgroundCircleLayer.position = arcCenter
        progressCircleLayer.position = arcCenter
        knobLayer.position = arcCenter
        
        rotationGesture?.arcRadius = arcRadius
        
        backgroundCircleLayer.path = getCirclePath()
        progressCircleLayer.path = getCirclePath()
        knobLayer.path = getKnobPath()
        
        appearanceIconImageView()
        setValue(value, animated: false)
    }
    
    fileprivate func getCirclePath() -> CGPath {
        return UIBezierPath(arcCenter: arcCenter,
                            radius: arcRadius,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: true).cgPath
    }
    
    fileprivate func getKnobPath() -> CGPath {
        return UIBezierPath(roundedRect:
            CGRect(x: arcCenter.x + arcRadius - knobRadius / 2, y: arcCenter.y - knobRadius / 2,
                   width: knobRadius, height: knobRadius),
                            cornerRadius: knobRadius / 2).cgPath
    }
    
    //MARK: Configure
    fileprivate func configure() {
        clipsToBounds = false
        configureBackgroundLayer()
        configureProgressLayer()
        configureKnobLayer()
        configureGesture()
    }
    
    fileprivate func configureIcon() {
        iconImageView.image = icon
        appearanceIconImageView()
    }
    
    fileprivate func configureBackgroundLayer() {
        backgroundCircleLayer.frame = bounds
        layer.addSublayer(backgroundCircleLayer)
        appearanceBackgroundLayer()
    }
    
    fileprivate func configureProgressLayer() {
        progressCircleLayer.frame = bounds
        progressCircleLayer.strokeEnd = 0
        layer.addSublayer(progressCircleLayer)
        appearanceProgressLayer()
    }
    
    fileprivate func configureKnobLayer() {
        knobLayer.frame = bounds
        knobLayer.position = arcCenter
        layer.addSublayer(knobLayer)
        appearanceKnobLayer()
    }
    
    fileprivate func configureGesture() {
        rotationGesture = RotationGesture.init(target: self,
                                               action: #selector(handleRotationGesture(_:)),
                                               arcRadius: arcRadius,
                                               knobRadius: knobRadius)
        addGestureRecognizer(rotationGesture!)
    }
    
    //MARK: Appearance
    fileprivate func appearanceIconImageView() {
        iconCenterY.constant = arcRadius
    }
    
    fileprivate func appearenceTitleColor() {
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 30)
        titleLabel.textColor = titleColor
    }
    
    fileprivate func appearenceValueColor() {
        textField.text = String(value)
        textField.font = UIFont.systemFont(ofSize: 40)
        textField.textColor = valueColor
    }
    
    fileprivate func appearanceBackgroundLayer() {
        backgroundCircleLayer.lineWidth = lineWidth
        backgroundCircleLayer.fillColor = UIColor.clear.cgColor
        backgroundCircleLayer.strokeColor = lineColor.cgColor
        backgroundCircleLayer.lineCap = kCALineCapRound
    }
    
    fileprivate func appearanceProgressLayer() {
        progressCircleLayer.lineWidth = lineWidth
        progressCircleLayer.fillColor = UIColor.clear.cgColor
        progressCircleLayer.strokeColor = highlighted ? lineHighlightedColor.cgColor : lineDisableColor.cgColor
        progressCircleLayer.lineCap = kCALineCapRound
    }
    
    fileprivate func appearanceKnobLayer() {
        knobLayer.lineWidth = 2
        knobLayer.fillColor = highlighted ? lineHighlightedColor.cgColor : lineDisableColor.cgColor
        knobLayer.strokeColor = UIColor.white.cgColor
    }
    
    fileprivate func appearanceSeparator() {
        separatorLabel.text = separator
        separatorLabel.font = UIFont.systemFont(ofSize: 26)
        separatorLabel.textColor = valueColor
    }
    
    fileprivate func appearanceBottomLine() {
        bottomLineView.backgroundColor = bottomLineColor
    }
    
    //MARK: Update
    open func setValue(_ value: Float, animated: Bool) {
        self.value = delegate?.circularSlider(self, valueForValue: value) ?? value
        
        updateLabels()
        
        setStrokeEnd(animated: animated)
        setKnobRotation(animated: animated)
    }
    
    fileprivate func setStrokeEnd(animated: Bool) {
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.duration = animated ? 0.66 : 0
        strokeAnimation.repeatCount = 1
        strokeAnimation.fromValue = progressCircleLayer.strokeEnd
        strokeAnimation.toValue = CGFloat(normalizedValue)
        strokeAnimation.isRemovedOnCompletion = false
        strokeAnimation.fillMode = kCAFillModeRemoved
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        progressCircleLayer.add(strokeAnimation, forKey: "strokeAnimation")
        progressCircleLayer.strokeEnd = CGFloat(normalizedValue)
        CATransaction.commit()
    }
    
    fileprivate func setKnobRotation(animated: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.duration = animated ? 0.66 : 0
        animation.values = [backingKnobAngle, knobAngle]
        knobLayer.add(animation, forKey: "knobRotationAnimation")
        knobLayer.transform = knobRotationTransform
        
        CATransaction.commit()
        
        backingKnobAngle = knobAngle
    }
    
    fileprivate func setChangeValueForTouch(_ isEnable: Bool) {
        isEnable ? configureGesture() : removeGestureRecognizer(rotationGesture!)
    }
    
    fileprivate func setLabelsHidden(_ isHidden: Bool) {
        centerView.isHidden = isHidden
    }
    
    fileprivate func updateLabels() {
        updateValueLabel()
    }
    
    fileprivate func updateValueLabel() {
        textField.attributedText = value.formatWithFractionDigits(fractionDigits, customDecimalSeparator: customDecimalSeparator).sliderAttributeString(customDecimalSeparator: customDecimalSeparator )
    }
    
    //MARK: Gesture handler
    @objc fileprivate func handleRotationGesture(_ sender: AnyObject) {
        guard let gesture = sender as? RotationGesture else { return }
        
        if gesture.state == UIGestureRecognizerState.began {
            cancelAnimation()
        }
        
        var rotationAngle = gesture.rotation
        if rotationAngle > knobMidAngle {
            rotationAngle -= 2 * .pi
        } else if rotationAngle < (knobMidAngle - 2 * .pi) {
            rotationAngle += 2 * .pi
        }
        rotationAngle = min(endAngle, max(startAngle, rotationAngle))
        
        guard abs(Double(rotationAngle - knobAngle)) < .pi / 2 else { return }
        
        let valueForAngle = Float(rotationAngle - startAngle) / Float(angleRange) * valueRange + minimumValue
        setValue(valueForAngle, animated: false)
    }
    
    func cancelAnimation() {
        progressCircleLayer.removeAllAnimations()
        knobLayer.removeAllAnimations()
    }
}
