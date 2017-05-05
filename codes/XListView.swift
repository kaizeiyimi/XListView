//
//  XListView.swift
//
//  Created by kaizei on 2017/4/26.
//  Copyright © 2017年 kaizei. All rights reserved.
//

import UIKit

public class XListView: UIScrollView {
    
    public struct ManagedItem {
        let view: UIView
        let margins: UIEdgeInsets
        public init(view: UIView, margins: UIEdgeInsets = .zero) {
            self.view = view
            self.margins = margins
        }
    }
    
    public private(set) var managedContainers: [ContainerView] = []
    
    private lazy var top: ContainerView = self.makeAnchorContainer()
    private lazy var bottom: ContainerView = self.makeAnchorContainer()
    
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
        [top, bottom].forEach {
            $0.isUserInteractionEnabled = false
            $0.backgroundColor = .purple
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        let views: [String: Any] = ["top": top, "bottom": bottom, "list": self]
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[top(==list)]|",
                                           options: [], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[top(0)]",
                                           options: [], metrics: nil, views: views)
        )
        
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:[bottom(==top)]",
                                           options: [], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:[bottom(0)]|",
                                           options: [], metrics: nil, views: views)
        )
        
        let space = NSLayoutConstraint(item: top, attribute: .bottom, relatedBy: .equal, toItem: bottom, attribute: .top, multiplier: 1, constant: 0)
        space.isActive = true
        
        top.bottomConstraint = space
        bottom.topConstraint = space
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    private func makeAnchorContainer() -> ContainerView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        return ContainerView(ManagedItem(view: view))
    }
    
    @objc private func keyboardWillShow(_ notify: Notification) {
        guard let keyboardFrame = notify.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect else { return }
        DispatchQueue.main.async {
            guard let container = self.managedContainers.first(where: { $0.containsFirstResponder() }) else { return }
            self.contentInset.bottom += keyboardFrame.height - self.adjustingInsetsBottom
            self.scrollIndicatorInsets.bottom += keyboardFrame.height - self.adjustingInsetsBottom
            self.adjustingInsetsBottom = keyboardFrame.height
            
            // act like UITableView
            let converted = self.convert(keyboardFrame, from: nil)
            let bottomDiff = container.frame.maxY - converted.minY
            let topDiff = self.contentOffset.y + self.contentInset.top - container.frame.minY
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
    
    //
    public func reset(_ views: [UIView]) {
        reset(views.map{ ManagedItem(view: $0) })
    }
    
    public func reset(_ items: [ManagedItem]) {
        removeManagedViews(managedContainers.flatMap{ $0.view }, animations: nil)
        items.forEach { item in
            appendManagedItem(item, animations: nil)
        }
    }
    
    // append 
    
    public func appendManagedView(_ view: UIView,
                                  animations: ((XListView, UIView) -> Void)? = Animations.addOne()) {
        addManagedItem(ManagedItem(view: view), at: managedContainers.count, animations: animations)
    }
    
    public func appendManagedItem(_ item: ManagedItem,
                                  animations: ((XListView, UIView) -> Void)? = Animations.addOne()) {
        addManagedItem(item, at: managedContainers.count, animations: animations)
    }
    
    public func appendManagedViews(_ views: [UIView],
                                   animations: ((XListView, [UIView]) -> Void)? = Animations.addMulti()) {
        addManagedItems(views.map{ ManagedItem(view: $0) }, at: managedContainers.count, animations: animations)
    }
    
    public func appendManagedItems(_ items: [ManagedItem],
                                   animations: ((XListView, [UIView]) -> Void)? = Animations.addMulti()) {
        addManagedItems(items, at: managedContainers.count, animations: animations)
    }
    
    // insert
    
    public func insertManagedView(_ view: UIView, at index: Int,
                                  animations: ((XListView, UIView) -> Void)? = Animations.addOne()) {
        addManagedItem(ManagedItem(view: view), at: index, animations: animations)
    }
    
    public func insertManagedItem(_ item: ManagedItem, at index: Int,
                                  animations: ((XListView, UIView) -> Void)? = Animations.addOne()) {
        addManagedItem(item, at: index, animations: animations)
    }
    
    public func insertManagedViews(_ views: [UIView], at index: Int,
                                   animations: ((XListView, [UIView]) -> Void)? = Animations.addMulti()) {
        addManagedItems(views.map{ ManagedItem(view: $0) }, at: index, animations: animations)
    }
    
    public func insertManagedItems(_ items: [ManagedItem], at index: Int,
                                  animations: ((XListView, [UIView]) -> Void)? = Animations.addMulti()) {
        addManagedItems(items, at: index, animations: animations)
    }
    
    // replace
    
    public func replaceManagedView(_ view: UIView, at index: Int,
                                   animations: ((XListView, UIView, UIView, @escaping () -> Void) -> Void)? = Animations.replaceOne()) {
        replaceManagedItem(ManagedItem(view: view), at: index, animations: animations)
    }
    
    public func replaceManagedItem(_ item: ManagedItem, at index: Int,
                                   animations: ((XListView, UIView, UIView, @escaping () -> Void) -> Void)? = Animations.replaceOne()) {
        if let animations = animations {
            replaceManagedItems([item], at: index) { (listView, old, containers, completion) in
                animations(listView, old, containers[0], completion)
            }
        } else {
            replaceManagedItems([item], at: index, animations: nil)
        }
    }
    
    public func replaceManagedViews(_ views: [UIView], at index: Int,
                                    animations: ((XListView, UIView, [UIView], @escaping () -> Void) -> Void)? = Animations.replaceMulti()) {
        replaceManagedItems(views.map{ ManagedItem(view: $0) }, at: index, animations: animations)
    }
    
    public func replaceManagedItems(_ items: [ManagedItem], at index: Int,
                                   animations: ((XListView, UIView, [UIView], @escaping () -> Void) -> Void)? = Animations.replaceMulti()) {
        let old = managedContainers[index]
        
        let list = [top] + managedContainers + [bottom]
        let up = list[index], down = list[index + 2]
        old.topConstraint?.isActive = false
        old.bottomConstraint?.isActive = false
        managedContainers.remove(at: index)
        
        let containers = items.map { item -> ContainerView in
            let container = ContainerView(item)
            container.translatesAutoresizingMaskIntoConstraints = false
            addSubview(container)
            
            NSLayoutConstraint(item: container, attribute: .leading, relatedBy: .equal, toItem: top, attribute: .leading, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: container, attribute: .trailing, relatedBy: .equal, toItem: top, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
            
            return container
        }
        managedContainers.insert(contentsOf: containers, at: index)
        
        var toSticks = managedContainers[index..<(index+items.count)]
        toSticks = [up] + toSticks + [down]
        for i in 0..<toSticks.count - 1 {
            stick(toSticks[i], toSticks[i + 1])
        }
        
        if let animations = animations {
            old.translatesAutoresizingMaskIntoConstraints = true
            let containers = toSticks[1..<toSticks.count - 1].map{$0}
            containers.forEach{ container in
                container.layoutIfNeeded()
                container.frame = CGRect(x: top.frame.minX,
                                         y: up.frame.maxY,
                                         width: container.frame.width,
                                         height: container.frame.height)
            }
            
            animations(self, old, containers) {
                old.removeFromSuperview()
            }
        }
    }
    
    // remove
    
    public func removeManagedView(_ view: UIView,
                                  animations: ((XListView, UIView, @escaping () -> Void) -> Void)? = Animations.removeOne()) {
        if let animations = animations {
            removeManagedViews([view]) { listView, containers, completion in animations(listView, containers[0], completion) }
        } else {
            removeManagedViews([view], animations: nil)
        }
    }
    
    public func removeManagedViews(_ views: [UIView],
                                   animations: ((XListView, [UIView], @escaping () -> Void) -> Void)? = Animations.removeMulti()) {
        let indexes = Array(Set(views.flatMap{ self.index(ofManagedView: $0) })).sorted(by: <)
        guard indexes.count > 0 else { return }
        
        let removedContainers = indexes.map{ managedContainers[$0] }
        
        removedContainers.forEach {
            $0.topConstraint?.isActive = false
            $0.bottomConstraint?.isActive = false
        }
        
        let list = [top] + managedContainers + [bottom]
        var prevIndex = indexes[0], nextIndex = prevIndex + 2
        while nextIndex < list.count {
            if indexes.contains(nextIndex - 1) {
                nextIndex += 1
                continue
            }
            let prev = list[prevIndex], next = list[nextIndex]
            stick(prev, next)
            prevIndex = nextIndex
            while prevIndex < managedContainers.count, !indexes.contains(prevIndex) {
                prevIndex += 1
            }
            nextIndex = prevIndex + 2
        }
        
        managedContainers = managedContainers.enumerated().filter{ !indexes.contains($0.offset) }.map{ $0.element }
        
        if let animations = animations {
            removedContainers.forEach {
                $0.translatesAutoresizingMaskIntoConstraints = true
            }
            animations(self, removedContainers) {
                removedContainers.forEach {
                    $0.removeFromSuperview()
                }
            }
        } else {
            removedContainers.forEach {
                $0.removeFromSuperview()
            }
        }
    }
    
    // move
    
    public func moveManagedView(_ view: UIView, to index: Int,
                                animations: ((XListView, UIView, _ from: CGRect, _ to: CGRect) -> Void)? = Animations.move()) {
        guard let current = self.index(ofManagedView: view), current != index else { return }
        let container = managedContainers[current]
        let target = managedContainers[index]
        
        do {
            let list = [top] + managedContainers + [bottom]
            let up = list[current], down = list[current + 2]
            container.topConstraint?.isActive = false
            container.bottomConstraint?.isActive = false
            managedContainers.remove(at: current)
            stick(up, down)
        }
        
        do {
            managedContainers.insert(container, at: index)
            let list = [top] + managedContainers + [bottom]
            let up = list[index], down = list[index + 2]
            up.bottomConstraint?.isActive = false
            stick(up, container)
            stick(container, down)
        }
        
        if let animations = animations {
            let from = container.frame
            let diff = target.frame.minY <= from.minY ? 0 : from.height - target.frame.height
            let to = from.offsetBy(dx: 0, dy: target.frame.minY - from.minY - diff)
            animations(self, container, from, to)
        }
    }
    
    public func index(ofManagedView view: UIView) -> Int? {
        return managedContainers.index(where: { $0.view == view })
    }
    
    private func addManagedItem(_ item: ManagedItem, at index: Int,
                                animations: ((XListView, UIView) -> Void)? = Animations.addOne()) {
        if let animations = animations {
            addManagedItems([item], at: index) { listView, containers in animations(listView, containers[0]) }
        } else {
            addManagedItems([item], at: index, animations: nil)
        }
    }
    
    private func addManagedItems(_ items: [ManagedItem], at index: Int,
                                animations: ((XListView, [UIView]) -> Void)? = Animations.addMulti()) {
        guard items.count > 0 else { return }
        
        let list = [top] + managedContainers + [bottom]
        let up = list[index], down = list[index + 1]
        up.bottomConstraint?.isActive = false
        down.topConstraint?.isActive = false
        
        let containers = items.map { item -> ContainerView in
            let container = ContainerView(item)
            container.translatesAutoresizingMaskIntoConstraints = false
            addSubview(container)
            
            NSLayoutConstraint(item: container, attribute: .leading, relatedBy: .equal, toItem: top, attribute: .leading, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: container, attribute: .trailing, relatedBy: .equal, toItem: top, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
            
            return container
        }
        managedContainers.insert(contentsOf: containers, at: index)
        
        var toSticks = managedContainers[index..<(index+items.count)]
        toSticks = [up] + toSticks + [down]
        for i in 0..<toSticks.count - 1 {
            stick(toSticks[i], toSticks[i + 1])
        }
        
        if let animations = animations {
            let containers = toSticks[1..<toSticks.count - 1].map{$0}
            containers.forEach{ container in
                container.layoutIfNeeded()
                container.frame = CGRect(x: top.frame.minX,
                                         y: up.frame.maxY,
                                         width: container.frame.width,
                                         height: container.frame.height)
            }
            
            animations(self, containers)
        }
    }
    
    private func stick(_ up: ContainerView, _ down: ContainerView) {
        let space = NSLayoutConstraint(item: up, attribute: .bottom, relatedBy: .equal, toItem: down, attribute: .top, multiplier: 1, constant: 0)
        space.isActive = true
        up.bottomConstraint = space
        down.topConstraint = space
    }
}

extension XListView {
    public final class ContainerView: UIView {
        
        weak var topConstraint: NSLayoutConstraint?
        weak var bottomConstraint: NSLayoutConstraint?
        
        public let view: UIView
        
        init(_ item: ManagedItem) {
            self.view = item.view
            super.init(frame: .zero)
            addSubview(item.view)
            item.view.translatesAutoresizingMaskIntoConstraints = false
            let metrics = ["top": item.margins.top,
                           "left": item.margins.left,
                           "bottom": item.margins.bottom,
                           "right": item.margins.right]
            let views = ["view": item.view]
            
            let h = NSLayoutConstraint.constraints(withVisualFormat: "H:|-left-[view]-right-|",
                                                   options: [],
                                                   metrics: metrics,
                                                   views: views)
            let v = NSLayoutConstraint.constraints(withVisualFormat: "V:|-top-[view]-bottom-|",
                                                   options: [],
                                                   metrics: metrics,
                                                   views: views)
            NSLayoutConstraint.activate(h)
            NSLayoutConstraint.activate(v)
        }
        
        public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func containsFirstResponder() -> Bool {
            return findFirstResponder(root: self) != nil
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
