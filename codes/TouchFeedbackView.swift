//
//  TouchFeedbackView.swift
//
//  Created by kaizei on 2017/5/2.
//  Copyright © 2017年 kaizei.yimi. All rights reserved.
//

import UIKit

public class TouchFeedbackView: UIView {
    
    public let contentView = UIView()
    
    public var onTap: () -> Void = {}
    public lazy var setActive: (_ isActive: Bool, _ animated: Bool) -> Void = {
        return { [weak self] isActive, animated in
            self?.setActiveUsingUITableViewCellStyle(isActive: isActive, animated: animated)
        }
    }()
    
    private var beginTouch: UITouch?
    
    private let delay = 0.025
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
        contentView.frame = CGRect(origin: .zero, size: bounds.size)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard beginTouch == nil, let touch = touches.first else { return }
        beginTouch = touch
        resetTimer()
        
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer?.setEventHandler {[weak self] in
            self?.resetTimer()
            self?.setActive(true, true)
        }
        timer?.scheduleOneshot(deadline: DispatchTime.now() + delay)
        timer?.resume()
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let beginTouch = beginTouch else {
            return
        }
        
        if beginTouch.location(in: self).y != touch.location(in: self).y {
            resetTimer()
            self.beginTouch = nil
            setActive(false, false)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard beginTouch != nil else { return }
        beginTouch = nil
        resetTimer()
        onTap()
        setActive(false, true)
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard beginTouch != nil else { return }
        resetTimer()
        beginTouch = nil
        setActive(false, false)
    }
    
    private func resetTimer() {
        timer?.cancel()
        timer = nil
    }
    
    public func setActiveUsingMaskBoard(color: UIColor = UIColor.white.withAlphaComponent(0.4),
                                        isActive: Bool,
                                        animated: Bool) {
        if isActive {
            guard self.maskBoard == nil else { return }
            let maskBoard = UIView(frame: bounds)
            maskBoard.isUserInteractionEnabled = false
            maskBoard.backgroundColor = color
            maskBoard.alpha = 0
            addSubview(maskBoard)
            UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
                maskBoard.alpha = 1
            })
            self.maskBoard = maskBoard
        } else {
            guard let maskBoard = maskBoard else { return }
            UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
                maskBoard.alpha = 0
            }, completion: { _ in
                maskBoard.removeFromSuperview()
            })
        }
    }
    
    public func setActiveUsingUITableViewCellStyle(color: UIColor = UIColor(white: CGFloat(0xd9)/255, alpha: 1),
                                                   isActive: Bool,
                                                   animated: Bool) {
        if isActive {
            guard self.colors == nil else { return }
            var colors: [UIView: UIColor] = [:]
            var views = subviews
            while !views.isEmpty {
                let current = views.removeFirst()
                views.append(contentsOf: current.subviews)
                colors[current] = current.backgroundColor
                current.backgroundColor = UIColor.clear
            }
            
            let view = UIView(frame: bounds)
            view.isUserInteractionEnabled = false
            view.backgroundColor = color
            insertSubview(view, at: 0)
            view.alpha = 0
            UIView.animate(withDuration: 0, animations: {
                view.alpha = 1
            })
            
            self.colors = colors
            self.selectedBackgroundView = view
            
        } else {
            guard let colors = self.colors else { return }
            var views = subviews
            while !views.isEmpty {
                let current = views.removeFirst()
                views.append(contentsOf: current.subviews)
                if let color = colors[current] {
                    current.backgroundColor = color
                }
            }
            
            UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
                self.selectedBackgroundView?.alpha = 0
            }, completion: { _ in
                self.colors = nil
                self.selectedBackgroundView?.removeFromSuperview()
            })
        }
    }
    
}
