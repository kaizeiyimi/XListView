//
//  TouchFeedbackView.swift
//
//  Created by kaizei on 2017/5/2.
//  Copyright © 2017年 kaizei.yimi. All rights reserved.
//

import UIKit

open class TouchFeedbackView: UIView {
    
    public enum State {
        case active
        case recognized
        case cancelled
    }
    public var isFeedbackEnabled = true
    
    public var onTap: () -> Void = {}
    public lazy var onStateChange: (_ state: State) -> Void = {
        return {[weak self] in self?.setStateUsingUITableViewCellStyle()($0) }
    }()
    
    private var beginTouch: UITouch?
    
    private let delay = 0.02
    private var timer: DispatchSourceTimer?
    
    private weak var maskBoard: UIView?
    
    private var colors: [UIView: UIColor]?
    private weak var selectedBackgroundView: UIView?
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard beginTouch == nil, let touch = touches.first else { return }
        beginTouch = touch
        resetTimer()
        
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer?.setEventHandler {[weak self] in
            self?.resetTimer()
            self?.setState(.active)
        }
        timer?.scheduleOneshot(deadline: DispatchTime.now() + delay)
        timer?.resume()
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let beginTouch = beginTouch else {
            return
        }
        
        if beginTouch.location(in: self).y != touch.location(in: self).y {
            resetTimer()
            self.beginTouch = nil
            setState(.cancelled)
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard beginTouch != nil else { return }
        beginTouch = nil
        resetTimer()
        onTap()
        setState(.recognized)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard beginTouch != nil else { return }
        resetTimer()
        beginTouch = nil
        setState(.cancelled)
    }
    
    private func resetTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func setState(_ state: State) {
        onStateChange(isFeedbackEnabled ? state : .cancelled)
    }
    
    public func setStateUsingMaskBoard(color: UIColor = UIColor.white.withAlphaComponent(0.4)) -> (State) -> Void {
        return {[weak self] state in
            guard let `self` = self else { return }
            
            func attachMaskBoard() -> UIView {
                let maskBoard = UIView(frame: self.bounds)
                maskBoard.isUserInteractionEnabled = false
                maskBoard.backgroundColor = color
                self.addSubview(maskBoard)
                return maskBoard
            }
            
            switch state {
            case .active:
                guard self.maskBoard == nil else { return }
                self.maskBoard = attachMaskBoard()
                self.maskBoard?.alpha = 0
                UIView.animate(withDuration: 0.25, animations: {
                    self.maskBoard?.alpha = 1
                })
            
            case .recognized:
                if self.maskBoard == nil {
                    self.maskBoard = attachMaskBoard()
                }
                self.maskBoard?.alpha = 1
                UIView.animate(withDuration: 0.25, animations: {
                    self.maskBoard?.alpha = 0
                }, completion: {_ in
                    self.maskBoard?.removeFromSuperview()
                })
                
            case .cancelled:
                self.maskBoard?.removeFromSuperview()
            }
        }
    }
    
    public func setStateUsingUITableViewCellStyle(color: UIColor = UIColor(white: CGFloat(0xd9)/255, alpha: 1)) -> (State) -> Void {
        return {[weak self] state in
            guard let `self` = self else { return }
            guard self.isFeedbackEnabled else {
                
                return
            }
            
            func attachSelectedBackgroundView() -> UIView {
                let view = UIView(frame: self.bounds)
                view.isUserInteractionEnabled = false
                view.backgroundColor = color
                self.insertSubview(view, at: 0)
                return view
            }
            
            func saveColors() -> [UIView: UIColor] {
                var colors: [UIView: UIColor] = [:]
                var views = self.subviews
                while !views.isEmpty {
                    let current = views.removeFirst()
                    views.append(contentsOf: current.subviews)
                    colors[current] = current.backgroundColor
                    current.backgroundColor = .clear
                }
                return colors
            }
            
            func restoreColors(_ colors: [UIView: UIColor]?) {
                guard let colors = colors, !colors.isEmpty else { return }
                var views = self.subviews
                while !views.isEmpty {
                    let current = views.removeFirst()
                    views.append(contentsOf: current.subviews)
                    if let color = colors[current] {
                        current.backgroundColor = color
                    }
                }
            }
            
            switch state {
            case .active:
                guard self.colors == nil else { return }
                self.colors = saveColors()
                self.selectedBackgroundView = attachSelectedBackgroundView()
                
            case .recognized:
                restoreColors(self.colors)
                if self.selectedBackgroundView == nil {
                    self.selectedBackgroundView = attachSelectedBackgroundView()
                }
                
                UIView.animate(withDuration: 0.35, animations: {
                    self.selectedBackgroundView?.alpha = 0
                }, completion: { _ in
                    self.colors = nil
                    self.selectedBackgroundView?.removeFromSuperview()
                })
                
            case .cancelled:
                restoreColors(self.colors)
                self.colors = nil
                self.selectedBackgroundView?.removeFromSuperview()
            }
            
        }
    }
    
}
