//
//  Utils.swift
//
//  Created by kaizei on 2017/4/28.
//  Copyright © 2017年 kaizei. All rights reserved.
//

import UIKit


public enum Animations {
    public static func addOne(duration: TimeInterval = 0.3) -> (XListView, UIView) -> Void {
        return { listView, container in
            container.alpha = 0
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                container.alpha = 1
            })
        }
    }
    
    public static func addMulti(duration: TimeInterval = 0.3) -> (XListView, [UIView]) -> Void {
        return { listView, containers in
            containers.forEach { container in
                container.alpha = 0
            }
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                containers.forEach { container in
                    container.alpha = 1
                }
                
            })
        }
    }
    
    public static func removeOne(duration: TimeInterval = 0.3) -> (XListView, UIView, @escaping () -> Void) -> Void {
        return { listView, container, completion in
            listView.sendSubview(toBack: container)
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                container.transform = CGAffineTransform(translationX: 0, y: -container.frame.height/2).scaledBy(x: 1, y: 0.01)
                container.alpha = 0
            }, completion: { _ in
                completion()
            })
        }
    }
    
    public static func removeMulti(duration: TimeInterval = 0.3) -> (XListView, [UIView], @escaping () -> Void) -> Void {
        return { (listView, containers, completion) in
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                containers.forEach({ container in
                    container.transform = CGAffineTransform(translationX: 0, y: -container.frame.height/2).scaledBy(x: 1, y: 0.01)
                    container.alpha = 0
                })
            }, completion: { _ in
                completion()
            })
        }
    }
    
    public static func replaceOne(duration: TimeInterval = 0.3) -> (XListView, UIView, UIView, @escaping () -> Void) -> Void {
        return { (listView, old, current, completion) in
            current.alpha = 0
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                old.alpha = 0
                current.alpha = 1
            }, completion: { _ in completion() })
        }
    }
    
    public static func replaceMulti(duration: TimeInterval = 0.3) -> (XListView, UIView, [UIView], @escaping () -> Void) -> Void {
        return { (listView, old, current, completion) in
            current.forEach{ $0.alpha = 0 }
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                old.alpha = 0
                current.forEach{ $0.alpha = 1 }
            }, completion: { _ in completion() })
        }
    }
    
    
    public static func move(duration: TimeInterval = 0.6) -> (XListView, UIView, CGRect, CGRect) -> Void {
        return { listView, container, from, to in
            listView.bringSubview(toFront: container)
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
            })
        }
    }
}

extension Animations {
    public static func addOneFromLeft(duration: TimeInterval = 0.3) -> (XListView, UIView) -> Void {
        return { listView, container in
            container.transform = CGAffineTransform(translationX: -container.frame.width, y: 0)
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                container.transform = .identity
            })
        }
    }
    
    public static func replaceOneFromLeft(duration: TimeInterval = 0.3) -> (XListView, UIView, UIView, @escaping () -> Void) -> Void {
        return { (listView, old, current, completion) in
            current.transform = CGAffineTransform(translationX: -current.frame.width, y: 0)
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                old.transform = CGAffineTransform(translationX: old.frame.width, y: 0)
                current.transform = .identity
            }, completion: { _ in completion() })
        }
    }
    
    public static func moveOutInFromLeft(duration: TimeInterval = 0.6) -> (XListView, UIView, CGRect, CGRect) -> Void {
        return { listView, container, from, to in
            UIView.animateKeyframes(withDuration: duration, delay: 0, options: [.beginFromCurrentState], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                    listView.layoutIfNeeded()
                    container.frame = from
                })
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                    container.frame = from.offsetBy(dx: -from.width, dy: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0, animations: {
                    container.frame = to.offsetBy(dx: -to.width, dy: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations: {
                    container.frame = to
                })
            }, completion: nil)
        }
    }
}

