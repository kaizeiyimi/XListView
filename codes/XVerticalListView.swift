//
//  XVerticalListView.swift
//
//  Created by kaizei on 2017/4/26.
//  Copyright © 2017年 kaizei. All rights reserved.
//

import UIKit


open class XVerticalListView: XListView {
    
    private var adjustingInsetsBottom: CGFloat = 0
    
    override func commonInit() {
        [head, tail].forEach {
            $0.isUserInteractionEnabled = false
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        let views: [String: Any] = ["head": head, "tail": tail, "list": self]
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[head(==list)]|",
                                           options: [], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:[tail(==head)]",
                                           options: [.alignAllCenterX], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[head(0)]",
                                           options: [], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:[tail(0)]|",
                                           options: [], metrics: nil, views: views)
        )
        
        spaces[head] = (nil, nil)
        spaces[tail] = (nil, nil)
        stick(head, tail)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    @discardableResult
    override func attachManagedView(_ view: UIView) -> UIView {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: head, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: head, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        spaces[view] = (nil, nil)
        
        // scrollview
        if let scrollView = view as? UIScrollView {
            let height = NSLayoutConstraint(item: scrollView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
            height.isActive = true
            
            observeForScrollView(scrollView, onChange: {[weak height] (container, scrollView) in
                let maxHeight = scrollView.contentInset.top + scrollView.contentSize.height + scrollView.contentInset.bottom
                let containerHeight = container.bounds.height
                if maxHeight <= containerHeight {
                    if height?.constant != maxHeight {
                        height?.constant = maxHeight
                    }
                    if container.spaces[scrollView]?.next?.constant != 0 {
                        container.spaces[scrollView]?.next?.constant = 0
                    }
                } else {
                    if height?.constant != containerHeight {
                        height?.constant = containerHeight
                    }
                    if container.spaces[scrollView]?.next?.constant != containerHeight - maxHeight {
                        container.spaces[scrollView]?.next?.constant = containerHeight - maxHeight
                    }
                    let top = scrollView.frame.minY  - scrollView.transform.ty
                    let offsetY = container.contentOffset.y
                    if offsetY <= top {
                        scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.contentInset.top), animated: false)
                        scrollView.transform = .identity
                    } else {
                        let metric = min(offsetY - top, maxHeight - containerHeight)
                        if metric != scrollView.transform.ty {
                            scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.contentInset.top + metric), animated: false)
                            scrollView.transform = CGAffineTransform(translationX: 0, y: metric)
                        }
                    }
                }
            })
            
            scrollView.isScrollEnabled = false
            scrollView.layoutIfNeeded()
        }
        
        return view
    }
    
    override func stick(_ a: UIView, _ b: UIView, inner: [UIView] = []) {
        spaces[a]?.next?.isActive = false
        spaces[b]?.prev?.isActive = false
        
        let list = [a] + inner + [b]
        for i in 0..<list.count - 1 {
            let space = NSLayoutConstraint(item: list[i], attribute: .bottom,
                                           relatedBy: .equal,
                                           toItem: list[i+1], attribute: .top,
                                           multiplier: 1, constant: 0)
            space.isActive = true
            spaces[list[i]]?.next = space
            spaces[list[i+1]]?.prev = space
        }
    }
    
    @objc private func keyboardWillShow(_ notify: Notification) {
        guard let keyboardFrame = notify.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect else { return }
        DispatchQueue.main.async {
            
            // swift compile bug
            // guard let view = self.managedViews.first({ findFirstResponder(root: $0) != nil }) else { return }
            guard let index = self.managedViews.index(where: { findFirstResponder(root: $0) != nil }) else { return }
            let view = self.managedViews[index]
            
            self.contentInset.bottom += keyboardFrame.height - self.adjustingInsetsBottom
            self.scrollIndicatorInsets.bottom += keyboardFrame.height - self.adjustingInsetsBottom
            self.adjustingInsetsBottom = keyboardFrame.height
            
            // act like UITableView
            let converted = self.convert(keyboardFrame, from: nil)
            let bottomDiff = view.frame.maxY - converted.minY
            let topDiff = self.contentOffset.y + self.contentInset.top - view.frame.minY
            var offset = self.contentOffset
            if bottomDiff > 0 {
                offset.y += bottomDiff
                self.setContentOffset(offset, animated: true)
            } else if topDiff > 0 {
                offset.y -= topDiff
                self.setContentOffset(offset, animated: true)
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notify: Notification) {
        guard adjustingInsetsBottom != 0 else { return }
        let interval = notify.userInfo?[UIKeyboardAnimationDurationUserInfoKey] == nil ? 0 : 0.25
        DispatchQueue.main.async {
            UIView.animate(withDuration: interval, animations: {
                self.contentInset.bottom -= self.adjustingInsetsBottom
                self.scrollIndicatorInsets.bottom -= self.adjustingInsetsBottom
            })
            self.adjustingInsetsBottom = 0
        }
    }
    
    
}


private func findFirstResponder(root: UIView) -> UIView? {
    if root.isFirstResponder {
        return root
    }
    for view in root.subviews {
        if let v = findFirstResponder(root: view) {
            return v
        }
    }
    return nil
}
