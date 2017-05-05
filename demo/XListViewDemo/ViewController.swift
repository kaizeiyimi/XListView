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
    
    enum PageItem: XListViewDataSourceItem {
        case box(String?, UIColor, () -> Void)
        case template(UIView, UIEdgeInsets)
        
        var xListViewManagedItemIdentifier: String? {
            switch self {
            case let .box(info): return info.0
            default: return nil
            }
        }
        
        func makeXListViewManagedItem() -> XListView.ManagedItem {
            switch self {
            case let .template(view, margins):
                return XListView.ManagedItem(view: view, margins: margins)
                
            case let .box(_, color, action):
                let box = TouchFeedbackView()
                
                box.backgroundColor = color
                box.translatesAutoresizingMaskIntoConstraints = false
                let height = CGFloat(arc4random() % 50) + 50
                let constraint = NSLayoutConstraint(item: box, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)
                constraint.isActive = true
                
                let inner: UIView
                if Int(height) % 2 == 0 {
                    inner = TouchFeedbackView(frame: CGRect(x: 5, y: 5, width: 120, height: 40))
                    let label = UILabel()
                    label.translatesAutoresizingMaskIntoConstraints = false
                    (inner as! TouchFeedbackView).contentView.addSubview(label)
                    label.text = "inner feedback"
                    label.textAlignment = .center
                    
                    label.isUserInteractionEnabled = true
                    let tap = UITapGestureRecognizer()
                    _ = tap.rx.event.subscribe(onNext: {[weak constraint, weak box] in
                        if let constraint = constraint, $0.state == .ended {
                            constraint.constant = constraint.constant > 75 ? constraint.constant - 25 : constraint.constant + 25
                            UIView.animate(withDuration: 0.25, animations: {
                                box?.superview?.superview?.layoutIfNeeded()
                            })
                        }
                    })
                    label.addGestureRecognizer(tap)
                    
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
                    box.setActive = {[weak box] in box?.setActiveUsingMaskBoard(isActive: $0.0, animated: $0.1)}
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
                
                return XListView.ManagedItem(view: box, margins: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
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
        
        dataSource.reset([.template(view1, UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))])
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

    @IBAction func addBox(_ sender: Any) {
        if dataSource.items.count >= 4 {
            replace()
            return
        }
        
        let index = Int(arc4random() % UInt32(dataSource.items.count + 1))
        
        dataSource.insert(makeBoxItem(), at: index, animations: Animations.addOneFromLeft())
    }
    
    func replace() {
        let index = Int(arc4random() % UInt32(dataSource.items.count))
        if dataSource.items.count >= 7 {
            dataSource.replace(makeBoxItem(), at: index)
        } else {
            dataSource.replace([makeBoxItem(), makeBoxItem()], at: index)
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
        
        dataSource.move(fromIndex: from, to: to)
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
        
        dataSource.remove([first, second])
    }
}

