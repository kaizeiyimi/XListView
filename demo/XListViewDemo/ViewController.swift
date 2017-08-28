//
//  ViewController.swift
//  XListViewDemo
//
//  Created by kaizei on 2017/5/5.
//  Copyright © 2017年 yingmi. All rights reserved.
//

import UIKit
import XListView
import RxCocoa

class ViewController: UIViewController {
    class MarginView: UIView {
        func setup(_ view: UIView, margins: UIEdgeInsets = .zero) -> MarginView {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            let views = ["view": view]
            
            NSLayoutConstraint.activate(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(margins.left)-[view]-\(margins.right)-|", options: [], metrics: nil, views: views)
            )
            NSLayoutConstraint.activate(
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(margins.top)-[view]-\(margins.bottom)-|", options: [], metrics: nil, views: views)
            )
            return self
        }
    }
    
    enum PageItem: XListViewDataSourceItem {
        case box(String?, UIColor, () -> Void)
        case template(UIView, UIEdgeInsets)
        case scrollView(UIScrollView)
        
        func makeXListManagedView() -> UIView {
            switch self {
            case let .scrollView(scrollView):
                return scrollView
                
            case let .template(view, margins):
                return MarginView().setup(view, margins: margins)
                
            case let .box(_, color, action):
                let box = TouchFeedbackView()
                
                box.backgroundColor = color
                box.translatesAutoresizingMaskIntoConstraints = false
                let height = CGFloat(arc4random() % 50) + 50
                let constraint = NSLayoutConstraint(item: box, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)
                constraint.isActive = true
                
                let inner: UIView
                if Int(height) % 2 == 0 {
                    let feedbackView = TouchFeedbackView(frame: CGRect(x: 5, y: 5, width: 120, height: 40))
                    feedbackView.onStateChange = {[weak feedbackView] in
                        feedbackView?.setStateUsingMaskBoard()($0)
                    }
                    let label = UILabel()
                    label.translatesAutoresizingMaskIntoConstraints = false
                    feedbackView.contentView.addSubview(label)
                    label.text = "inner feedback"
                    label.textAlignment = .center

                    feedbackView.onTap = {[weak constraint, weak box] in
                        if let constraint = constraint {
                            constraint.constant = constraint.constant > 75 ? constraint.constant - 25 : constraint.constant + 25
                            UIView.animate(withDuration: 0.25, animations: {
                                box?.superview?.superview?.layoutIfNeeded()
                            })
                        }
                    }
                    
                    inner = feedbackView
                    
                    NSLayoutConstraint.activate(
                        NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]|",
                                                       options: [],
                                                       metrics: nil,
                                                       views: ["label": label])
                    )
                    NSLayoutConstraint.activate(
                        NSLayoutConstraint.constraints(withVisualFormat: "V:|[label]|",
                                                       options: [],
                                                       metrics: nil,
                                                       views: ["label": label])
                    )
                } else {
                    inner = UIView(frame: CGRect(x: 5, y: 5, width: 120, height: 40))
                }
                inner.layer.borderWidth = 1
                inner.backgroundColor = .orange
                box.contentView.addSubview(inner)
                
                if Int(height) % 3 == 0 {
                    box.onStateChange = {[weak box] in box?.setStateUsingMaskBoard()($0) }
                    let input = UITextField()
                    input.translatesAutoresizingMaskIntoConstraints = false
                    box.contentView.addSubview(input)
                    input.text = "mask style"
                    
                    let input2 = UITextField()
                    input2.translatesAutoresizingMaskIntoConstraints = false
                    box.contentView.addSubview(input2)
                    input2.text = "input2"
                    
                    NSLayoutConstraint.activate(
                        NSLayoutConstraint.constraints(withVisualFormat: "H:[input]-|",
                                                       options: [],
                                                       metrics: nil,
                                                       views: ["input": input])
                    )
                    NSLayoutConstraint.activate(
                        NSLayoutConstraint.constraints(withVisualFormat: "V:[input2]-[input]-|",
                                                       options: [.alignAllTrailing],
                                                       metrics: nil,
                                                       views: ["input": input, "input2": input2])
                    )
                    
                } else {
                    box.onTap = action
                }
                
                return MarginView().setup(box, margins: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
            }
        }
        
    }

    @IBOutlet weak var listView: XListView!
    
    let dataSource = XListViewDataSource<PageItem>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource.listView = listView
        setup()
    }
    
    func setup() {
        let view1 = UIView()
        view1.translatesAutoresizingMaskIntoConstraints = false
        view1.backgroundColor = .purple
        
        let button = UIButton(type: .infoDark)
        button.translatesAutoresizingMaskIntoConstraints = false
        view1.addSubview(button)
        
        let constraint = NSLayoutConstraint(item: view1, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60)
        constraint.isActive = true
        
        NSLayoutConstraint(item: button, attribute: .centerX, relatedBy: .equal, toItem: view1, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: button, attribute: .centerY, relatedBy: .equal, toItem: view1, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        
        _ = button.rx.tap.subscribe(onNext: {[weak self] in
            constraint.constant = CGFloat(arc4random() % 41) + 40
            UIView.animate(withDuration: 0.4, animations: {
                self?.listView.layoutIfNeeded()
            })
        })
        
        dataSource.reset(items: [.template(view1, UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))])
    }
    
    func makeBoxItem() -> PageItem {
        let rgb = (0..<3).map{_ in CGFloat(arc4random() % 255) / 255 }
        let color = UIColor(red: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1)
        
        let id = UUID().uuidString
        
        return .box(id, color, {[weak self] in
            guard let `self` = self else { return }
            let vc = UIViewController()
            vc.view.backgroundColor = .white
            self.navigationController?.pushViewController(vc, animated: true)
        })
    }
    
    func makeScrollViewItem() -> PageItem {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .lightGray
        let width = UIScreen.main.bounds.width
        
        let view1 = UIView()
        view1.backgroundColor = .purple
        view1.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(view1)
        
        let view2 = UIView()
        view2.backgroundColor = .orange
        view2.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(view2)
        
        let views = ["v1": view1, "v2": view2]
        
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[v1(\(width))]|", options: [], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[v2(\(width))]|", options: [], metrics: nil, views: views)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[v1(\(500))]-10-[v2(\(500))]-10-|", options: [], metrics: nil, views: views)
        )
        
        return .scrollView(scrollView)
    }
    
    func makeTableViewItem() -> PageItem {
        class Cell: UITableViewCell {
            override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
                super.init(style: style, reuseIdentifier: reuseIdentifier)
                
                let label = UILabel()
                label.text = "test"
                label.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(label)
                let views = ["v": label]
                NSLayoutConstraint.activate(
                    NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[v]", options: [], metrics: nil, views: views)
                )
                NSLayoutConstraint.activate(
                    NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[v]-16-|", options: [], metrics: nil, views: views)
                )
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }
        
        class DataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
            func numberOfSections(in tableView: UITableView) -> Int {
                return 3
            }
            
            func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return 6
            }
            
            func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            }
            
            func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
                return "hehe"
            }
        }
        
        let tableView = UITableView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(Cell.self, forCellReuseIdentifier: "cell")
        
        // in this embed mode, headerView or footerView is not encouraged.
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        headerView.backgroundColor = .orange
        tableView.tableHeaderView = headerView
        
        
        let dataSource = DataSource()
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        objc_setAssociatedObject(tableView, "", dataSource, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return .scrollView(tableView)
    }

    @IBAction func addBox(_ sender: Any) {
        if dataSource.items.count >= 4 {
            replace()
            return
        }
        
        let index = Int(arc4random() % UInt32(dataSource.items.count + 1))
        
//        if index == 3 {
            dataSource.insert(item: makeTableViewItem(), at: index, animations: Animations.insertOneFromLeft())
//        } else {
//            dataSource.insert(item: makeBoxItem(), at: index, animations: Animations.insertOneFromLeft())
//        }
    }
    
    func replace() {
        let index = Int(arc4random() % UInt32(dataSource.items.count))
        if dataSource.items.count >= 7 {
            dataSource.replace(item: makeBoxItem(), at: index)
        } else {
            dataSource.replace(items: [makeBoxItem(), makeBoxItem()], at: index)
        }
    }
    
    @IBAction func removeBox(_ sender: Any) {
        if dataSource.items.count >= 5 {
            remove2()
            return
        }
        
        guard dataSource.items.count > 0 else { return }
        let index = Int(arc4random() % UInt32(dataSource.items.count))
        
        dataSource.remove(at: index)
    }
    
    @IBAction func move(_ sender: Any) {
        guard dataSource.items.count > 1 else { return }
        let from = Int(arc4random() % UInt32(dataSource.items.count))
        var to = Int(arc4random() % UInt32(dataSource.items.count))
        if to == from {
            to = (from + 1) % dataSource.items.count
        }
        
        dataSource.move(from: from, to: to)
    }
    
    @IBAction func endEditing() {
        view.window?.endEditing(true)
    }
    
    func remove2() {
        guard dataSource.items.count >= 2 else { return }
        let first = Int(arc4random() % UInt32(dataSource.items.count))
        var second = Int(arc4random() % UInt32(dataSource.items.count))
        if second == first {
            second = (first + 1) % dataSource.items.count
        }
        
        dataSource.remove(indexes: [first, second])
    }
}

