//
//  XHorizontalListView.swift
//
//  Created by kaizei on 2017/4/26.
//  Copyright © 2017年 kaizei. All rights reserved.
//

import UIKit


open class XHorizontalListView: XListView {
    
    override func commonInit() {
        [head, tail].forEach {
            $0.isUserInteractionEnabled = false
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        let views: [String: Any] = ["head": head, "tail": tail, "list": self]
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[head(==list)]|",
                                           options: [], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:[tail(==head)]",
                                           options: [.alignAllCenterY], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[head(0)]",
                                           options: [], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:[tail(0)]|",
                                           options: [], metrics: nil, views: views)
        )
        
        spaces[head] = (nil, nil)
        spaces[tail] = (nil, nil)
        stick(head, tail)
    }
    
    @discardableResult
    override func attachManagedView(_ view: UIView) -> UIView {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: head, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: head, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        spaces[view] = (nil, nil)
        return view
    }
    
    override func stick(_ a: UIView, _ b: UIView, inner: [UIView] = []) {
        spaces[a]?.next?.isActive = false
        spaces[b]?.prev?.isActive = false
        
        let list = [a] + inner + [b]
        for i in 0..<list.count - 1 {
            let space = NSLayoutConstraint(item: list[i], attribute: .right,
                                           relatedBy: .equal,
                                           toItem: list[i+1], attribute: .left,
                                           multiplier: 1, constant: 0)
            space.isActive = true
            spaces[list[i]]?.next = space
            spaces[list[i+1]]?.prev = space
        }
    }

}
