//
//  Utils.swift
//
//  Created by kaizei on 2017/4/28.
//  Copyright © 2017年 kaizei. All rights reserved.
//

import UIKit


public enum Animations {
    
    public typealias ReplaceOne = (XListView, _ removed: UIView, _ inserted: UIView, _ completion: @escaping () -> Void) -> Void
    public typealias ReplaceMulti = (XListView, _ removed: [UIView], _ inserted: [UIView], _ completion: @escaping () -> Void) -> Void
    
    public typealias RemoveOne = (XListView, UIView, _ completion: @escaping () -> Void) -> Void
    public typealias RemoveMulti = (XListView, [UIView], _ completion: @escaping () -> Void) -> Void
    
    public typealias MoveOne = (XListView, UIView, _ from: CGRect, _ to: CGRect) -> Void
    
    public typealias InsertOne = (XListView, UIView) -> Void
    public typealias InsertMulti = (XListView, [UIView]) -> Void
    
    
    public static func replaceOne(duration: TimeInterval = 0.3) -> ReplaceOne {
        return { (listView, removed, inserted, completion) in
            replaceMulti(duration: duration)(listView, [removed], [inserted], completion)
        }
    }
    
    public static func replaceMulti(duration: TimeInterval = 0.3) -> ReplaceMulti {
        return { (listView, removed, inserted, completion) in
            inserted.forEach{ $0.alpha = 0 }
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                removed.forEach{ $0.alpha = 0 }
                inserted.forEach{ $0.alpha = 1 }
            }, completion: { _ in completion() })
        }
    }
    
    public static func removeOne(duration: TimeInterval = 0.3) -> RemoveOne {
        return { listView, removed, completion in
            removeMulti(duration: duration)(listView, [removed], completion)
        }
    }
    
    public static func removeMulti(duration: TimeInterval = 0.3) -> RemoveMulti {
        return { (listView, removed, completion) in
            removed.forEach{ listView.sendSubview(toBack: $0) }
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                removed.forEach({ view in
                    view.transform = CGAffineTransform(translationX: 0, y: -view.frame.height/2).scaledBy(x: 1, y: 0.01)
                    view.alpha = 0
                })
            }, completion: { _ in completion() })
        }
    }
    
    public static func moveOne(duration: TimeInterval = 0.6) -> MoveOne {
        return { listView, view, from, to in
            listView.bringSubview(toFront: view)
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
            })
        }
    }
    
    public static func insertOne(duration: TimeInterval = 0.3) -> InsertOne {
        return { listView, inserted in
            inserted.alpha = 0
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                inserted.alpha = 1
            })
        }
    }
    
    public static func insertMulti(duration: TimeInterval = 0.3) -> InsertMulti {
        return { listView, inserted in
            inserted.forEach { $0.alpha = 0 }
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                inserted.forEach { $0.alpha = 1 }
            })
        }
    }
}

extension Animations {
    public static func insertOneFromLeft(duration: TimeInterval = 0.3) -> InsertOne {
        return { listView, inserted in
            inserted.transform = CGAffineTransform(translationX: -inserted.frame.width, y: 0)
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                inserted.transform = .identity
            })
        }
    }
    
    public static func replaceOneFromLeft(duration: TimeInterval = 0.3) -> ReplaceOne {
        return { (listView, removed, inserted, completion) in
            inserted.transform = CGAffineTransform(translationX: -inserted.frame.width, y: 0)
            UIView.animate(withDuration: duration, animations: {
                listView.layoutIfNeeded()
                removed.transform = CGAffineTransform(translationX: removed.frame.width, y: 0)
                inserted.transform = .identity
            }, completion: { _ in completion() })
        }
    }
    
    public static func moveOneOutInFromLeft(duration: TimeInterval = 0.6) -> MoveOne {
        return { listView, view, from, to in
            UIView.animateKeyframes(withDuration: duration, delay: 0, options: [.beginFromCurrentState], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                    listView.layoutIfNeeded()
                    view.frame = from
                })
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                    view.frame = from.offsetBy(dx: -from.width, dy: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0, animations: {
                    view.frame = to.offsetBy(dx: -to.width, dy: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations: {
                    view.frame = to
                })
            }, completion: nil)
        }
    }
}

