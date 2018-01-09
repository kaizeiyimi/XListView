//
//  PaddingView.swift
//
//  Created by kaizei on 2017/8/31.
//  Copyright © 2017年 kaizei. All rights reserved.
//

import UIKit


open class PaddingView<T: UIView>: UIView {
    
    public var wrapped: T? {
        didSet {
            guard oldValue != wrapped else { return }
            oldValue?.removeFromSuperview()
            update(reset: true)
        }
    }
    public var padding: UIEdgeInsets = .zero {
        didSet {
            guard oldValue != padding else { return }
            update(reset: false)
        }
    }
    
    open override var intrinsicContentSize: CGSize {
        let size = wrapped?.intrinsicContentSize ?? .zero
        return CGSize(
            width: size.width == UIViewNoIntrinsicMetric ? UIViewNoIntrinsicMetric : size.width + padding.left + padding.right,
            height: size.height == UIViewNoIntrinsicMetric ? UIViewNoIntrinsicMetric : size.height + padding.top + padding.bottom
        )
    }
    
    open override var forLastBaselineLayout: UIView { return wrapped ?? self }
    open override var forFirstBaselineLayout: UIView { return wrapped ?? self }
    
    private weak var topConstraint: NSLayoutConstraint?
    private weak var leftConstraint: NSLayoutConstraint?
    private weak var bottomConstraint: NSLayoutConstraint?
    private weak var rightConstraint: NSLayoutConstraint?
    
    public convenience init(_ wrapped: T, padding: UIEdgeInsets = .zero) {
        self.init()
        self.wrapped = wrapped
        self.padding = padding
        update(reset: true)
    }
    
    private func update(reset: Bool) {
        invalidateIntrinsicContentSize()
        guard let view = wrapped else { return }
        
        if reset {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            topConstraint = view.topAnchor.constraint(equalTo: topAnchor, constant: padding.top)
            leftConstraint = view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left)
            bottomConstraint = bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: padding.bottom)
            rightConstraint = trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: padding.right)
            [topConstraint, leftConstraint, bottomConstraint, rightConstraint].forEach { $0?.isActive = true }
        } else {
            topConstraint?.constant = padding.top
            leftConstraint?.constant = padding.left
            bottomConstraint?.constant = padding.bottom
            rightConstraint?.constant = padding.right
        }
    }
}
