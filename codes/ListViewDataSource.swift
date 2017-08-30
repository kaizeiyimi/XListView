//
//  ListViewDataSource.swift
//
//  Created by kaizei on 2017/4/27.
//  Copyright © 2017年 kaizei. All rights reserved.
//

import UIKit

// MARK: - ListViewDataSourceItem

public protocol ListViewDataSourceItem {
    var xListViewIdentifier: String? { get }
    func makeXListManagedView() -> UIView
}

extension ListViewDataSourceItem {
    public var xListViewIdentifier: String? { return nil }
}

extension UIView: ListViewDataSourceItem {
    public func makeXListManagedView() -> UIView {
        return self
    }
}

// MARK: - XListViewDataSource

open class BaseListViewDataSource<Item> {
    
    public var listView: ListView!
    public var items: [Item] = []
    
    public init(){}
    public init(_ listView: ListView){ self.listView = listView }
}

open class ListViewDataSource<Item>: BaseListViewDataSource<Item> where Item: ListViewDataSourceItem {}

open class ListViewPlainDataSource: BaseListViewDataSource<ListViewDataSourceItem> {}


// MARK: - ListViewDataSourceUpdating

private var identifierKey = "kaize.yimi.XListView.identifierKey.key"
extension UIView {
    fileprivate var identifier: String? {
        get { return objc_getAssociatedObject(self, &identifierKey) as? String }
        set { objc_setAssociatedObject(self, &identifierKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
}


extension ListViewDataSourceItem {
    fileprivate func makeManagedView() -> UIView {
        let view = makeXListManagedView()
        view.identifier = xListViewIdentifier
        return view
    }
}

extension BaseListViewDataSource {
    public func view(by identifier: String?) -> UIView? {
        guard let identifier = identifier else { return nil }
        return listView.managedViews.first{ $0.identifier == identifier }
    }

    public func reset(items: [Item] = []) {
        self.items = items
        listView.reset(views: items.map{ ($0 as! ListViewDataSourceItem).makeManagedView() })
    }
    
    public func replace(items: [Item], in range: Range<Int>, animations: Animations.ReplaceMulti? = Animations.replaceMulti()) {
        self.items.replaceSubrange(range, with: items)
        listView.replace(views: items.map{ ($0 as! ListViewDataSourceItem).makeManagedView() }, in: range, animations: animations)
    }
    
    public func remove(indexes: [Int], animations: Animations.RemoveMulti? = Animations.removeMulti()) {
        items = items.enumerated().filter{ !indexes.contains($0.offset) }.map{ $0.element }
        listView.remove(indexes: indexes, animations: animations)
    }
    
    public func move(from: Int, to: Int, animations: Animations.MoveOne? = Animations.moveOne()) {
        items.insert(items.remove(at: from), at: to)
        listView.move(from: from, to: to, animations: animations)
    }
}

extension BaseListViewDataSource {

    public func insert(items: [Item], at index: Int, animations: Animations.InsertMulti? = Animations.insertMulti()) {
        self.items.insert(contentsOf: items, at: index)
        listView.insert(views: items.map{ ($0 as! ListViewDataSourceItem).makeManagedView() }, at: index, animations: animations)
    }
    
    public func insert(item: Item, at index: Int, animations: Animations.InsertOne? = Animations.insertOne()) {
        self.items.insert(item, at: index)
        listView.insert(view: (item as! ListViewDataSourceItem).makeManagedView(), at: index, animations: animations)
    }
    
    public func append(items: [Item], animations: Animations.InsertMulti? = Animations.insertMulti()) {
        insert(items: items, at: self.items.count, animations: animations)
    }
    
    public func append(item: Item, animations: Animations.InsertOne? = Animations.insertOne()) {
        insert(item: item, at: items.count, animations: animations)
    }
    
    public func replace(items: [Item], at index: Int, animations: Animations.ReplaceMulti? = Animations.replaceMulti()) {
        replace(items: items, in: index..<index+1, animations: animations)
    }
    
    public func replace(item: Item, at index: Int, animations: Animations.ReplaceOne? = Animations.replaceOne()) {
        items.replaceSubrange(index...index, with: [item])
        listView.replace(view: (item as! ListViewDataSourceItem).makeManagedView(), at: index, animations: animations)
    }
    
    public func remove(at: Int, animations: Animations.RemoveOne? = Animations.removeOne()) {
        items.remove(at: at)
        listView.remove(at: at, animations: animations)
    }
}
