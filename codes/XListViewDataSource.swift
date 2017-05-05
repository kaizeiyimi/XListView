//
//  XListViewDataSource.swift
//
//  Created by kaizei on 2017/4/27.
//  Copyright © 2017年 kaizei. All rights reserved.
//

import UIKit


public protocol XListViewDataSourceItem {
    var xListViewManagedItemIdentifier: String? { get }
    func makeXListViewManagedItem() -> XListView.ManagedItem
}

extension XListViewDataSourceItem {
    public var xListViewManagedItemIdentifier: String? { return nil }
}

extension UIView: XListViewDataSourceItem {
    public func makeXListViewManagedItem() -> XListView.ManagedItem {
        return XListView.ManagedItem(view: self)
    }
}

extension XListView.ManagedItem: XListViewDataSourceItem {
    public func makeXListViewManagedItem() -> XListView.ManagedItem {
        return self
    }
}


public protocol XListViewDataSourceUpdating: class {
    associatedtype Item
    
    var listView: XListView! { get }
    var items: [Item] { get set }
}

public class XListViewDataSource<Item>: XListViewDataSourceUpdating where Item: XListViewDataSourceItem {
    
    public var listView: XListView!
    public var items: [Item] = []
    
    public init(){}
}

public class XListViewPlainDataSource: XListViewDataSourceUpdating {
    
    public typealias Item = XListViewDataSourceItem
    
    public var listView: XListView!
    public var items: [Item] = []
    
    public init(){}
}

private var identifierKey = "kaize.yimi.XXListView.identifier.key"
extension XListView.ContainerView {
    var identifier: String? {
        get { return objc_getAssociatedObject(self, &identifierKey) as? String }
        set { objc_setAssociatedObject(self, &identifierKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

extension XListViewDataSourceUpdating where Item: XListViewDataSourceItem {
    
    public func getViewBy(identifier: String?) -> UIView? {
        guard let identifier = identifier else { return nil }
        return listView.managedContainers.filter{ $0.identifier == identifier }.first?.view
    }
    
    public func reset(_ items: [Item] = []) {
        self.items = items
        listView.reset(items.map{ $0.makeXListViewManagedItem() })
    }
    
    public func insert(_ items: [Item], at index: Int,
                       animations: ((XListView, [UIView]) -> Void)? = Animations.addMulti()) {
        guard items.flatMap({ getViewBy(identifier: $0.xListViewManagedItemIdentifier) }).count == 0 else {
            assertionFailure("every item must has unique identifier!")
            return
        }
        self.items.insert(contentsOf: items, at: index)
        listView.insertManagedItems(items.map{ $0.makeXListViewManagedItem() }, at: index, animations: animations)
        items.enumerated().forEach { ( offset, item) in
            listView.managedContainers[index + offset].identifier = item.xListViewManagedItemIdentifier
        }
    }
    
    public func insert(_ item: Item, at index: Int,
                       animations: ((XListView, UIView) -> Void)? = Animations.addOne()) {
        guard getViewBy(identifier: item.xListViewManagedItemIdentifier) == nil else {
            assertionFailure("every item must has unique identifier!")
            return
        }
        items.insert(item, at: index)
        listView.insertManagedItem(item.makeXListViewManagedItem(), at: index, animations: animations)
        listView.managedContainers[index].identifier = item.xListViewManagedItemIdentifier
    }
    
    public func remove(at index: Int,
                       animations: ((XListView, UIView, @escaping () -> Void) -> Void)? = Animations.removeOne()) {
        let view = listView.managedContainers[index].view
        items.remove(at: index)
        listView.removeManagedView(view, animations: animations)
    }
    
    public func remove(_ indexes: [Int],
                       animations: ((XListView, [UIView], @escaping () -> Void) -> Void)? = Animations.removeMulti()) {
        let views = indexes.flatMap{ listView.managedContainers[$0].view }
        Array(Set(indexes)).sorted(by: >).forEach{ items.remove(at: $0) }
        listView.removeManagedViews(views, animations: animations)
    }
    
    public func move(fromIndex from: Int, to: Int,
                     animations: ((XListView, UIView, CGRect, CGRect) -> Void)? = Animations.move()) {
        let view = listView.managedContainers[from].view
        let item = items.remove(at: from)
        items.insert(item, at: to)
        listView.moveManagedView(view, to: to, animations: animations)
    }
    
    public func replace(_ item: Item, at index: Int,
                        animations: ((XListView, UIView, UIView, @escaping () -> Void) -> Void)? = Animations.replaceOne()) {
        items[index] = item
        listView.replaceManagedItem(item.makeXListViewManagedItem(), at: index, animations: animations)
        listView.managedContainers[index].identifier = item.xListViewManagedItemIdentifier
    }
    
    public func replace(_ items: [Item], at index: Int,
                        animations: ((XListView, UIView, [UIView], @escaping () -> Void) -> Void)? = Animations.replaceMulti()) {
        self.items.replaceSubrange(index..<index+1, with: items)
        listView.replaceManagedItems(items.map({ $0.makeXListViewManagedItem() }), at: index, animations: animations)
        items.enumerated().forEach { ( offset, item) in
            listView.managedContainers[index + offset].identifier = item.xListViewManagedItemIdentifier
        }
    }
    
}

extension XListViewDataSourceUpdating where Item: XListViewDataSourceItem {
    
    public func append(_ items: [Item],
                       animations: ((XListView, [UIView]) -> Void)? = Animations.addMulti()) {
        insert(items, at: items.count, animations: animations)
    }
    
    public func append(_ item: Item,
                       animations: ((XListView, UIView) -> Void)? = Animations.addOne()) {
        insert(item, at: items.count, animations: animations)
    }
    
    public func removeFirst(where: (Item) -> Bool,
                            animations: ((XListView, UIView, @escaping () -> Void) -> Void)? = Animations.removeOne()) {
        guard let index = items.index(where: `where`) else { return }
        remove(at: index, animations: animations)
    }
    
    public func removeLast(where: (Item) -> Bool,
                           animations: ((XListView, UIView, @escaping () -> Void) -> Void)? = Animations.removeOne()) {
        guard let index = items.reversed().index(where: `where`)?.base else { return }
        remove(at: index, animations: animations)
    }
}

extension XListViewDataSourceUpdating where Item: XListViewDataSourceItem {
    
    public func remove(identifier: String?,
                       animations: ((XListView, UIView, @escaping () -> Void) -> Void)? = Animations.removeOne()) {
        guard let identifier = identifier else { return }
        guard let index = listView.managedContainers.index(where: { $0.identifier == identifier }) else { return }
        remove(at: index, animations: animations)
    }
    
    public func remove(identifiers: [String?],
                       animations: ((XListView, [UIView], @escaping () -> Void) -> Void)? = Animations.removeMulti()) {
        let indexes = identifiers.flatMap{ $0 }.flatMap{ id in listView.managedContainers.index{ $0.identifier == id } }
        remove(indexes, animations: animations)
    }
    
    public func move(identifier: String?, to: Int,
                     animations: ((XListView, UIView, CGRect, CGRect) -> Void)? = Animations.move()) {
        guard let identifier = identifier,
            let index = listView.managedContainers.index(where: {$0.identifier == identifier}) else { return }
        move(fromIndex: index, to: to, animations: animations)
    }
}
