//
//  HorizontalConfigurator.swift
//
//  Created by kaizei on 2017/4/26.
//  Copyright © 2017年 kaizei. All rights reserved.
//

import UIKit


final class HorizontalConfigurator: Configurator {
    
    private unowned let listView: ListView
    
    private var head: UIView { return listView.head }
    private var tail: UIView { return listView.tail }
    
    init(_ listView: ListView) {
        self.listView = listView
        listView.alwaysBounceHorizontal = true
        
        let views: [String: Any] = ["head": head, "tail": tail, "list": listView]
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[head(==list)]|",
                                           options: [], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:[tail(==head)]",
                                           options: [], metrics: nil, views: views)
        )
        head.centerYAnchor.constraint(equalTo: tail.centerYAnchor).isActive = true
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[head(0)]",
                                           options: [], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:[tail(0)]|",
                                           options: [], metrics: nil, views: views)
        )
        
        listView.spaces[head] = (nil, nil)
        listView.spaces[tail] = (nil, nil)
        stick(head, tail)
    }
    
    @discardableResult
    func attachManagedView(_ view: UIView) -> UIView {
        view.translatesAutoresizingMaskIntoConstraints = false
        listView.addSubview(view)
        NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: head, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: head, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        listView.spaces[view] = (nil, nil)
        return view
    }
    
    func stick(_ a: UIView, _ b: UIView, inner: [UIView] = []) {
        listView.spaces[a]?.next?.isActive = false
        listView.spaces[b]?.prev?.isActive = false
        
        let list = [a] + inner + [b]
        for i in 0..<list.count - 1 {
            let space = NSLayoutConstraint(item: list[i], attribute: .right,
                                           relatedBy: .equal,
                                           toItem: list[i+1], attribute: .left,
                                           multiplier: 1, constant: 0)
            space.isActive = true
            listView.spaces[list[i]]?.next = space
            listView.spaces[list[i+1]]?.prev = space
        }
    }

}
