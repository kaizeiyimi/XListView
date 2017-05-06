//
//  XListView.swift
//
//  Created by kaizei on 2017/4/26.
//  Copyright © 2017年 kaizei. All rights reserved.
//

import UIKit

public class XListView: UIScrollView {
    
    public private(set) var managedViews: [UIView] = []
    private var spaces: [UIView: (prev: NSLayoutConstraint?, next: NSLayoutConstraint?)] = [:]
    
    private lazy var head = UIView()
    private lazy var tail = UIView()
    
    private var adjustingInsetsBottom: CGFloat = 0
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
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
                                           options: [], metrics: nil, views: views)
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
    
    @discardableResult
    private func attachManagedView(_ view: UIView) -> UIView {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: head, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: head, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        spaces[view] = (nil, nil)
        return view
    }

    private func stick(_ a: UIView, _ b: UIView, inner: [UIView] = []) {
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
    
    //
    public func replace(views: [UIView], in range: Range<Int>, animations: Animations.ReplaceMulti? = Animations.replaceMulti()) {
        let inserted = views.map{ attachManagedView($0) }
        let removed = Array(managedViews[range])
        managedViews.replaceSubrange(range, with: inserted)
        guard inserted.count > 0 || removed.count > 0 else {
            animations?(self, removed, inserted, {})
            return
        }
        
        let list = [head] + managedViews + [tail]
        let up = list[range.lowerBound], down = list[range.lowerBound + inserted.count + 1]
        stick(up, down, inner: inserted)
        
        if let animations = animations {
            removed.forEach{ $0.translatesAutoresizingMaskIntoConstraints = true }
            
            var prev = up
            inserted.forEach { view in
                view.layoutIfNeeded()
                view.frame = CGRect(origin: CGPoint(x: 0, y: prev.frame.maxY), size: view.frame.size)
                prev = view
            }
            
            animations(self, removed, inserted) {
                removed.forEach { $0.removeFromSuperview() }
            }
        }
    }
    
    public func remove(views: [UIView], animations: Animations.RemoveMulti? = Animations.removeMulti()) {
        let indexes = Array(Set(views.flatMap{ managedViews.index(of: $0) })).sorted(by: <)
        guard indexes.count > 0 else { return }
        
        let removed = indexes.map{ managedViews[$0] }
        
        removed.forEach {
            spaces[$0]?.next?.isActive = false
            spaces[$0]?.prev?.isActive = false
        }
        
        let list = [head] + managedViews + [tail]
        var prevIndex = indexes[0], nextIndex = prevIndex + 2
        while nextIndex < list.count {
            if indexes.contains(nextIndex - 1) {
                nextIndex += 1
                continue
            }
            let prev = list[prevIndex], next = list[nextIndex]
            stick(prev, next)
            prevIndex = nextIndex
            while prevIndex < managedViews.count, !indexes.contains(prevIndex) {
                prevIndex += 1
            }
            nextIndex = prevIndex + 2
        }
        
        managedViews = managedViews.filter{ !removed.contains($0) }
        
        if let animations = animations {
            removed.forEach { $0.translatesAutoresizingMaskIntoConstraints = true }
            animations(self, removed) {
                removed.forEach { $0.removeFromSuperview() }
            }
        } else {
            removed.forEach { $0.removeFromSuperview() }
        }
    }
    
    public func move(from: Int, to: Int, animations: Animations.MoveOne? = Animations.moveOne()) {
        let view = managedViews[from]
        let target = managedViews[to]
        guard view != target else { return }
        
        do {
            let list = [head] + managedViews + [tail]
            let up = list[from], down = list[from + 2]
            spaces[view]?.prev?.isActive = false
            spaces[view]?.next?.isActive = false
            managedViews.remove(at: from)
            stick(up, down)
        }
        
        do {
            managedViews.insert(view, at: to)
            let list = [head] + managedViews + [tail]
            let up = list[to], down = list[to + 2]
            stick(up, down, inner: [view])
        }
        
        if let animations = animations {
            let fromFrame = view.frame
            let diff = target.frame.minY <= fromFrame.minY ? 0 : fromFrame.height - target.frame.height
            let toFrame = fromFrame.offsetBy(dx: 0, dy: target.frame.minY - fromFrame.minY - diff)
            animations(self, view, fromFrame, toFrame)
        }
    }
}

extension XListView {
    
    // reset
    
    public func reset(views: [UIView]) {
        replace(views: views, in: 0..<managedViews.count, animations: nil)
    }

    // insert
    
    public func insert(views: [UIView], at index: Int, animations: Animations.InsertMulti? = Animations.insertMulti()) {
        if let animations = animations {
            replace(views: views, in: index..<index) { listView, _, inserted, completion in
                animations(listView, inserted)
                completion()
            }
        } else {
            replace(views: views, in: index..<index, animations: nil)
        }
    }
    
    public func insert(view: UIView, at index: Int, animations: Animations.InsertOne? = Animations.insertOne()) {
        if let animations = animations {
            insert(views: [view], at: index) { listView, inserted in animations(listView, inserted[0]) }
        } else {
            insert(views: [view], at: index, animations: nil)
        }
    }
    
    public func append(views: [UIView], animations: Animations.InsertMulti? = Animations.insertMulti()) {
        insert(views: views, at: managedViews.count, animations: animations)
    }
    
    public func append(view: UIView, animations: Animations.InsertOne? = Animations.insertOne()) {
        insert(view: view, at: managedViews.count, animations: animations)
    }
    
    // replace 
    
    public func replace(view: UIView, at index: Int, animations: Animations.ReplaceOne? = Animations.replaceOne()) {
        if let animations = animations {
            replace(views: [view], in: index..<index+1) { (listView, removed, inserted, completion) in
                animations(listView, removed[0], inserted[0], completion)
            }
        } else {
            replace(views: [view], in: index..<index, animations: nil)
        }
    }
    
    // remove
    
    public func remove(view: UIView, animations: Animations.RemoveOne? = Animations.removeOne()) {
        if let animations = animations {
            remove(views: [view]) { listView, removed, completion in animations(listView, removed[0], completion) }
        } else {
            remove(views: [view], animations: nil)
        }
    }
    
    public func remove(indexes: [Int], animations: Animations.RemoveMulti? = Animations.removeMulti()) {
        remove(views: indexes.map{ managedViews[$0] }, animations: animations)
    }
    
    public func remove(at: Int, animations: Animations.RemoveOne? = Animations.removeOne()) {
        remove(view: managedViews[at], animations: animations)
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
