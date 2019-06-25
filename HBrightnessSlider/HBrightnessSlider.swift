//
//  HBrightnessSlider.swift
//
//  Copyright (c) 2019 Himal Madhushan (http://himalmadhushan.weebly.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import AudioToolbox.AudioServices

public protocol HorizontalSliderDelegate {
    func valueChangedContinuesly(value: Float)
}

public class HBrightnessSlider: UIControl {
    
    /// Slider minimum value. Default 0
    @IBInspectable open var minimumValue: Float = 0
    
    /// Slider maximum value. Default 1
    @IBInspectable open var maximumValue: Float = 1
    
    /// Slider current value.
    private(set) open var value: Float = 0
    
    /// Slider animating duration.  Default 0.5
    @IBInspectable open var animationDuration: Double = 0.5
    
    /// Slider will scale if set to `true`. Default is set to `false`.
    @IBInspectable open var shouldScale: Bool = false {
        didSet { addLognPressGesture() }
    }
    
    /// Shows the current value in the slider. Default is set to `false`.
    @IBInspectable open var showText: Bool = false {
        didSet { addTextLayer() }
    }
    
    /// Sliding color. Default `UIColor.lightGray`
    @IBInspectable open var fillingColor: UIColor = .lightGray {
        didSet { renderer.highlightColor = fillingColor }
    }
    
    /// Slider value text color. Default `UIColor.black`
    @IBInspectable open var textColor: UIColor = .black {
        didSet { renderer.textColor = textColor }
    }
    
    /// Long press gesture delay for scaling.
    open var scaleDelay: Double = 0
    
    open var delegate: HorizontalSliderDelegate?
    
    private let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
    
    private var longRecognizer: LongGesture?
    //    {
    //        return LongGesture(target: self, action: #selector(HBrightnessSlider.handleLongGesture(_:)))
    //    }
    
    private var didVibrate = false
    
    private var startValue: CGFloat {
        get { return renderer.startValue }
        set { renderer.startValue = newValue }
    }
    
    private var endValue: CGFloat {
        get { return renderer.endValue }
        set { renderer.endValue = newValue }
    }
    
    var isContinuous = true
    
    private let renderer = HorizontalSliderRenderer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        layoutIfNeeded()
        renderer.updateBounds(bounds)
        renderer.sliderWidth = bounds.width
    }
    
    private func commonInit() {
        renderer.updateBounds(bounds)
        
        renderer.backgroundColor = backgroundColor ?? .white
        renderer.highlightColor = fillingColor
        renderer.sliderWidth = frame.width
        renderer.animationDuration = animationDuration
        renderer.setPointerAngle(0, 5, animated: false)
        
        layer.addSublayer(renderer.trackLayer)
        layer.addSublayer(renderer.fillingLayer)
        addTextLayer()
        
        addLognPressGesture()
        
        let gestureRecognizer = PanGestureRecognizer(target: self, action: #selector(HBrightnessSlider.handleGesture(_:)))
        gestureRecognizer.delegate = self
        addGestureRecognizer(gestureRecognizer)
        
    }
    
    /// Adds the value text layer.
    fileprivate func addTextLayer() {
        if showText {
            
            renderer.textColor = textColor
            layer.addSublayer(renderer.textLayer)
        } else {
            renderer.textLayer.removeFromSuperlayer()
        }
    }
    
    /// Adds/Remove long press gesture.
    fileprivate func addLognPressGesture() {
        if shouldScale {
            longRecognizer = LongGesture(target: self, action: #selector(HBrightnessSlider.handleLongGesture(_:)))
            longRecognizer?.delegate = self
            longRecognizer?.minimumPressDuration = scaleDelay
            addGestureRecognizer(longRecognizer!)
        } else {
            if let g = longRecognizer {
                removeGestureRecognizer(g)
            }
        }
    }
    
    @objc private func handleGesture(_ gesture: PanGestureRecognizer) {
        if gesture.touchValue <= 1.0 && gesture.touchValue >= 0.0 {
            let v = floor(value+1)
            let t = floor((((maximumValue - minimumValue) * Float(gesture.touchValue)) + minimumValue))
            
            if v == t {
                if !didVibrate {
                    impactFeedbackgenerator.prepare()
                    impactFeedbackgenerator.impactOccurred()
                    didVibrate = !didVibrate
                }
            } else {
                didVibrate = false
            }
            setValue(Float(gesture.touchValue), animated: true)
            
        } else if gesture.touchValue > 1.0 {
            setValue(1.0, animated: true)
            if !didVibrate {
                impactFeedbackgenerator.prepare()
                impactFeedbackgenerator.impactOccurred()
                didVibrate = !didVibrate
            }
        } else if gesture.touchValue <= 0.0 {
            setValue(0.0, animated: true)
            if !didVibrate {
                impactFeedbackgenerator.prepare()
                impactFeedbackgenerator.impactOccurred()
                didVibrate = !didVibrate
            }
        }
        
        if isContinuous {
            sendActions(for: .valueChanged)
        } else {
            if gesture.state == .ended || gesture.state == .cancelled {
                sendActions(for: .valueChanged)
            }
        }
    }
    
    @objc private func handleLongGesture(_ gesture: LongGesture) {
        switch gesture.state {
        case .began:
            scaleInView()
        case .cancelled, .ended, .failed:
            scaleOutView()
        default:
            break
        }
    }
    
    /// Sets value for slider.
    ///
    /// - Parameters:
    ///   - newValue: Value in Float
    ///   - animated: State whether to animate or not. Default `false`.
    public func setValue(_ newValue: Float, animated: Bool = false) {
        value = ((maximumValue - minimumValue) * newValue) + minimumValue
        delegate?.valueChangedContinuesly(value: value)
        let angleValue = endValue * CGFloat(newValue)
        renderer.setPointerAngle(CGFloat(newValue), CGFloat(angleValue), animated: animated)
    }
    
    /// The value to show in the slider. Pass any value that can be converted in to String.
    ///
    /// - Parameter value: Value in strings
    public func showValue(_ value: String?) {
        renderer.updateTextValue(value)
    }
    
    private func scaleInView() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let animation = CASpringAnimation(keyPath: "transform.scale")
        animation.duration = 0.3
        animation.fromValue = 1
        animation.toValue = 1.05
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: nil)
        CATransaction.commit()
    }
    
    private func scaleOutView() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let animation = CASpringAnimation(keyPath: "transform.scale")
        animation.duration = 0.3
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: nil)
        CATransaction.commit()
    }
}

extension HBrightnessSlider: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


////////////** HorizontalSliderRenderer **/////////////////

private class HorizontalSliderRenderer {
    var backgroundColor: UIColor = .white {
        didSet {
            trackLayer.strokeColor = backgroundColor.cgColor
        }
    }
    
    var highlightColor: UIColor = .lightGray {
        didSet {
            fillingLayer.strokeColor = highlightColor.cgColor
        }
    }
    
    var textColor: UIColor = .black {
        didSet {
            textLayer.foregroundColor = textColor.cgColor
        }
    }
    
    var sliderWidth: CGFloat = 20 {
        didSet {
            trackLayer.lineWidth = sliderWidth
            fillingLayer.lineWidth = sliderWidth
            updateTrackLayerPath()
            updateFillingLayerPath()
        }
    }
    
    var startValue: CGFloat {
        get { return self.trackLayer.bounds.minY }
        set { updateTrackLayerPath() }
    }
    
    var endValue: CGFloat {
        get { return self.trackLayer.bounds.maxY }
        set { updateTrackLayerPath() }
    }
    
    var animationDuration: Double = 0.5
    
    let trackLayer = CAShapeLayer()
    let fillingLayer = CAShapeLayer()
    var textLayer = CATextLayer()
    
    init() {
        trackLayer.fillColor = backgroundColor.cgColor
        fillingLayer.fillColor = highlightColor.cgColor
    }
    
    func initTextLayer() {
        textLayer.font = UIFont.systemFont(ofSize: 12)
        textLayer.fontSize = 12
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.frame = CGRect(x: trackLayer.bounds.origin.x,
                                 y: trackLayer.bounds.maxY-30,
                                 width: trackLayer.bounds.width,
                                 height: 22)
        textLayer.alignmentMode = .center
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.foregroundColor = textColor.cgColor
        
    }
    
    func setPointerAngle(_ percentage: CGFloat = 0, _ newPointerAngle: CGFloat, animated: Bool = false) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let start = CGPoint(x: fillingLayer.bounds.midX, y: fillingLayer.bounds.maxY)
        let end = CGPoint(x: fillingLayer.bounds.midX, y: fillingLayer.bounds.height - abs(newPointerAngle))
        
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        path.lineWidth = sliderWidth
        path.lineCapStyle = .butt
        
        if animated {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = animationDuration
            animation.toValue = path.cgPath
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            fillingLayer.add(animation, forKey: nil)
        } else {
            fillingLayer.path = path.cgPath
        }
        
        CATransaction.commit()
    }
    
    func updateTextValue(_ value: String?) {
        textLayer.string = value
    }
    
    private func updateTrackLayerPath() {
        let bounds = trackLayer.bounds
        let start = CGPoint(x: bounds.midX, y: bounds.maxY)
        let end = CGPoint(x: bounds.midX, y: bounds.minY)
        
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        path.lineWidth = sliderWidth
        path.lineCapStyle = .butt
        
        trackLayer.path = path.cgPath
    }
    
    private func updateFillingLayerPath() {
        let bounds = trackLayer.bounds
        let start = CGPoint(x: bounds.midX, y: bounds.maxY)
        let end = CGPoint(x: bounds.midX, y: bounds.maxY-5)
        
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        path.lineWidth = sliderWidth
        path.lineCapStyle = .butt
        
        fillingLayer.path = path.cgPath
    }
    
    func updateBounds(_ bounds: CGRect) {
        trackLayer.bounds = bounds
        trackLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        updateTrackLayerPath()
        
        fillingLayer.bounds = trackLayer.bounds
        fillingLayer.position = trackLayer.position
        updateFillingLayerPath()
        
        initTextLayer()
    }
    
}


////////////** Gestures **/////////////////

import UIKit.UIGestureRecognizerSubclass

private class PanGestureRecognizer: UIPanGestureRecognizer {
    private(set) var touchValue: CGFloat = 0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        updateAngle(with: touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        updateAngle(with: touches)
    }
    
    private func updateAngle(with touches: Set<UITouch>) {
        guard
            let touch = touches.first,
            let view = view
            else {
                return
        }
        let touchPoint = touch.location(in: view)
        touchValue = angle(for: touchPoint, in: view)
    }
    
    private func angle(for point: CGPoint, in view: UIView) -> CGFloat {
        return 1-(point.y/view.frame.height)
    }
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        maximumNumberOfTouches = 1
        minimumNumberOfTouches = 1
    }
}

private class LongGesture: UILongPressGestureRecognizer {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        minimumPressDuration = 0
    }
}
