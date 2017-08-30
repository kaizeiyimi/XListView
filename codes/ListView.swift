//
//  ListView.swift
//
//  Created by kaizei on 2017/4/26.
//  Copyright © 2017年 kaizei. All rights reserved.
//

import UIKit


private var KVOObserverKey = "yimi.kaizei.ListView.Observer.key"

/// abstract super class. use Vertical or Horizontal listView.
open class ListView: UIScrollView {
    
    public private(set) var managedViews: [UIView] = []
    
    var spaces: [UIView: (prev: NSLayoutConstraint?, next: NSLayoutConstraint?)] = [:]
    let head = UIView()
    let tail = UIView()
    
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
    
    // MARK: - override points
    internal func commonInit() {
        fatalError("not for directly use! use Vertical or Horizontal listView!")
    }
    
    @discardableResult
    internal func attachManagedView(_ view: UIView) -> UIView {
        fatalError("not for directly use! use Vertical or Horizontal listView!")
    }
    
    internal func stick(_ a: UIView, _ b: UIView, inner: [UIView] = []) {
        fatalError("not for directly use! use Vertical or Horizontal listView!")
    }
    
    internal func removeManagedView(_ view: UIView) {
        if let scrollView = view as? UIScrollView,
            let observer = objc_getAssociatedObject(view, &KVOObserverKey) as? NSObject {
            scrollView.removeObserver(observer, forKeyPath: "contentSize")
            scrollView.removeObserver(observer, forKeyPath: "contentInset")
            self.removeObserver(observer, forKeyPath: "bounds")
        }
        view.removeFromSuperview()
    }
    
    internal func observeForScrollView(
        _ scrollView: UIScrollView,
        onChange: @escaping (_ container: ListView, _ scrollView: UIScrollView) -> Void) {
        class Observer: NSObject {
            weak var container: ListView?
            weak var scrollView: UIScrollView?
            let onChange: (ListView, UIScrollView) -> Void
            
            init(container: ListView, scrollView: UIScrollView,
                 onChange: @escaping (ListView, UIScrollView) -> Void) {
                (self.container, self.scrollView) = (container, scrollView)
                self.onChange = onChange
            }
            
            override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                guard let container = container, let scrollView = scrollView else { return }
                onChange(container, scrollView)
            }
        }
        
        let observer = Observer(container: self, scrollView: scrollView, onChange: onChange)
        scrollView.addObserver(observer, forKeyPath: "contentSize", options: [.initial, .new], context: nil)
        scrollView.addObserver(observer, forKeyPath: "contentInset", options: [.initial, .new], context: nil)
        self.addObserver(observer, forKeyPath: "bounds", options: [.initial, .new], context: nil)
        
        objc_setAssociatedObject(scrollView, &KVOObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    // MARK: - managements
    
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
                removed.forEach { self.removeManagedView($0) }
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
                removed.forEach { self.removeManagedView($0) }
            }
        } else {
            removed.forEach { self.removeManagedView($0) }
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

extension ListView {
    
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
