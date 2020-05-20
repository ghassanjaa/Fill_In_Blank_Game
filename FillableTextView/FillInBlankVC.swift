//
//  FillInBlankVC.swift
//  FillableTextView_Example
//
//  Created by Ghassan Jaam on 5/20/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import FillableTextView

class FillInBlankVC: UIViewController, FillableTextViewDelegate, UITextViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var phraseTextView: FillableTextView!
    
    public var items_CollectionView: UICollectionView!
    public var destinationTextView: FillableTextView!
    private lazy var customLabel = UILabel()
    private lazy var startFrame = CGRect()
    private lazy var isReachedDest = Bool()
    private lazy var isPanRunning = Bool()
    private lazy var isPanAllowed = Bool()
    private var indexPathForItem:IndexPath?
    let textLabelTag: Int = 998
    var cellTextLabel: UILabel?
    var selectedVariable: String?


    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureTextView()
        self.items_CollectionView = collectionView
        self.destinationTextView = phraseTextView
        self.addGesturesForCollectionView()

    }
    
    //MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
         print(#function)
         print("ℹ️ \(String(describing: textView.text))")
     }
     
     func textViewDidChangeSelection(_ textView: UITextView) {
         print(textView.selectedRange)
     }
    
    
    //MARK: - Configure FillableTextView
    
    func configureTextView() {
        phraseTextView.text = "test test test [] test test test [] test test test [] test test test [] "
        phraseTextView.placeHolderLength = 3
        phraseTextView.blankType = .line
        print(phraseTextView.filledText)
        phraseTextView.delegate = self
        phraseTextView.fillableTextViewDelegate = self

    }//END
    
    func optionsForIndex(_ textView: FillableTextView, index: Int) -> [FillableOptionItem]? {
        return nil
    }//END
    
    func didSelectOptionForIndex(_ textView: FillableTextView, index: Int, text: String, userData: FillableOptionItem) {
        print("didSelectOption \(text) with userData \(String(describing: userData))")
    }//END
    
    func textViewDidChangeText(_ textView: FillableTextView, index: Int, text: String, textSpace: TextSpace) {
        print("index = \(index) text = \"\(text)\"")
    }//END
    
    func addGesturesForCollectionView() {
        let longPressGest = UILongPressGestureRecognizer.init(target: self, action: #selector(longPressGestureAction))
        longPressGest.delegate = self
        longPressGest.minimumPressDuration = 0.2
        items_CollectionView.addGestureRecognizer(longPressGest)
        
        let panGesture = UIPanGestureRecognizer()
        panGesture.addTarget(self, action: #selector(panGestureAction))
        panGesture.delaysTouchesBegan = true
        panGesture.delegate = self
        items_CollectionView.addGestureRecognizer(panGesture)

    }//END
}//END Class

extension FillInBlankVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self

    }//END
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataClassArray.count
    }//END
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fillCell", for: indexPath) as! fillCell
        cell.titleLabel.text = dataClassArray[indexPath.row]
        cell.titleLabel?.tag = textLabelTag
        return cell
    }//END

}//END Extension

extension FillInBlankVC: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
}//END

@objc fileprivate func panGestureAction (_ gestureRecognizer : UIPanGestureRecognizer) {
    if !isPanAllowed || !customLabel.isDescendant(of: self.view) {
        items_CollectionView.isScrollEnabled = true
        return
    }//END
    
    let translation = gestureRecognizer.translation(in: self.view)
    items_CollectionView.isScrollEnabled = false
    if gestureRecognizer.state == .began  {
        startFrame = customLabel.frame
    }
    else if gestureRecognizer.state == .changed {
        
        checkWhetherProductMovedDestination()
        customLabel.center = CGPoint(x: customLabel.center.x + translation.x, y: customLabel.center.y + translation.y)
        gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
        
    }
    else if gestureRecognizer.state == .ended {
        caseMethodForPanCompletionWith(gestureRecognizer)
    }
}//END
    
        private func caseMethodForPanCompletionWith(_ gestureRecognizer:UIPanGestureRecognizer) {
            
            if indexPathForItem == nil || !customLabel.isDescendant(of: self.view) {
                return
            }
            let velocity = gestureRecognizer.velocity(in: self.view)
            
            let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
            let slideMultiplier = magnitude / 200
    //        print("magnitude: \(magnitude), slideMultiplier: \(slideMultiplier)")
            
            let slideFactor = 0.1 * slideMultiplier     //Increase for more of a slide
            
            var finalPoint = CGPoint(x:customLabel.center.x + (velocity.x * slideFactor),
                                     y:customLabel.center.y + (velocity.y * slideFactor))
            finalPoint.x = min(max(finalPoint.x, 0), self.view.bounds.size.width)
            finalPoint.y = min(max(finalPoint.y, 0), self.view.bounds.size.height)
            
            print("This is the final Point x:\(finalPoint.x) and Y: \(finalPoint.y)")
            
            
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           options: UIViewAnimationOptions.curveEaseOut,
                           animations: { [weak self] in
                            self?.customLabel.center = finalPoint
                            self?.checkWhetherProductMovedDestination()
                },
                           completion: { [weak self] _ in
                            
                            self?.panCompletionMethod()
            })
            items_CollectionView.isScrollEnabled = true
        }//END

        fileprivate func panCompletionMethod() {
            if self.isReachedDest {
                UIView.animate(withDuration: 0.2, animations: { [weak weakSelf = self] in
                    let destionViewCenterWithRespectMain = weakSelf?.getTheMainViewBasedCenterForDestination()
                    weakSelf?.customLabel.frame = CGRect(x: (destionViewCenterWithRespectMain?.x)! - 5, y: (destionViewCenterWithRespectMain?.y)! - 5, width: 10.0, height: 10.0)
                    }, completion:{  [weak weakSelf = self] _ in
                        
                        weakSelf?.doSomeThingsAfterPanCompletion()})
            }
            else {
                UIView.animate(withDuration: 0.2, animations: { [weak weakSelf = self] in
                    weakSelf?.customLabel.frame = (weakSelf?.constructFrameForIndex(indexPath: (weakSelf?.indexPathForItem)!))!
                    }, completion:{  [weak weakSelf = self] _ in
                        weakSelf?.doSomeThingsAfterPanCompletion()})
            }

        }//END
        
        
        fileprivate func checkWhetherProductMovedDestination() {
            isPanRunning = true
            
            let draggingViewX = customLabel.frame.origin.x + customLabel.frame.size.width
            let draggingViewY = customLabel.frame.origin.y
            
            let destionViewCenterWithRespectMain = getTheMainViewBasedCenterForDestination()
            
            let requiredDestFrame = CGRect(x: destionViewCenterWithRespectMain.x - destinationTextView.frame.width/2, y: destionViewCenterWithRespectMain.y - destinationTextView.frame.height/2, width: destinationTextView.frame.size.width, height: destinationTextView.frame.size.height)
            
            isReachedDest = false
            if (draggingViewY <= requiredDestFrame.origin.y + destinationTextView.frame.size.height && draggingViewX >= requiredDestFrame.origin.x)  {
                isReachedDest = true
            }

        }//END
        
        
        fileprivate func getTheMainViewBasedCenterForDestination() -> CGPoint {
            var destionViewCenterWithRespectMain = destinationTextView.center
            
            if var destinationSuperView = destinationTextView.superview {
                destionViewCenterWithRespectMain = CGPoint(x: destionViewCenterWithRespectMain.x + destinationSuperView.frame.origin.x, y: destionViewCenterWithRespectMain.y + destinationSuperView.frame.origin.y)
                while let anotherSuperView = destinationSuperView.superview {
                    destionViewCenterWithRespectMain = CGPoint(x: destionViewCenterWithRespectMain.x + anotherSuperView.frame.origin.x, y: destionViewCenterWithRespectMain.y + anotherSuperView.frame.origin.y)
                    destinationSuperView = anotherSuperView
                }
            }
            return destionViewCenterWithRespectMain
        }//END
        
        @objc fileprivate func longPressGestureAction(_ gestureRecognizer : UILongPressGestureRecognizer) {
            if isPanRunning {
                return
            }
            
            if gestureRecognizer.state == .began {
                
                let point = gestureRecognizer.location(in: items_CollectionView)
                
                guard items_CollectionView.indexPathForItem(at: point) != nil else {
                    return
                }
//                print(indexPathForItem?.item)
                if customLabel.isDescendant(of: self.view) {
                    customLabel.removeFromSuperview()
                }
                isPanAllowed = true
                
                addCustomViewAt(point)
                cellTextLabel = gestureRecognizer.view?.viewWithTag(textLabelTag) as? UILabel
            }
            else if gestureRecognizer.state == .ended {
                
                isPanAllowed = false
                if customLabel.isDescendant(of: view) {
                    customLabel.removeFromSuperview()
                }
                items_CollectionView.isScrollEnabled = true
            }

            
        }//END
        
        fileprivate func addCustomViewAt(_ point:CGPoint) {
            guard let indexPath = items_CollectionView.indexPathForItem(at: point) else {return}
            
            if customLabel.isDescendant(of: self.view) {
                print("Nil Indexpath or already view available>>>>>>> Returned")
                return
            }
            
            indexPathForItem = indexPath as IndexPath
            customLabel = UILabel.init(frame:constructFrameForIndex(indexPath: indexPath))
            customLabel.contentMode = .scaleAspectFit
            let itemAtIndexPath = dataClassArray[indexPath.row]
            customLabel.text = itemAtIndexPath
            customLabel.backgroundColor = #colorLiteral(red: 0.9640098214, green: 0.5248013139, blue: 0.1971936822, alpha: 1)
            customLabel.textAlignment = .center
            startFrame = customLabel.frame
            self.selectedVariable = itemAtIndexPath
            print("The value that has selected is \(selectedVariable ?? "")")
            self.view.addSubview(customLabel)

        }//END
        
        fileprivate func doSomeThingsAfterPanCompletion() {
            if customLabel.isDescendant(of: view) {
                print("DONE")
                customLabel.removeFromSuperview()
            }
            isReachedDest = false
            isPanRunning = false
            isPanAllowed = false
            
        }//END
        
        fileprivate func constructFrameForIndex(indexPath:IndexPath)->CGRect {
            let attributes = items_CollectionView.layoutAttributesForItem(at: indexPath as IndexPath)
                   let sizeRect = attributes?.frame
                   
                   let tempView = UIView.init(frame: CGRect(x: 0, y: 0, width: (sizeRect?.size.width)! + 20.0, height: (sizeRect?.size.height)! + 20.0))
                   tempView.center = CGPoint(x: (attributes?.center.x)! + items_CollectionView.frame.origin.x - items_CollectionView.contentOffset.x , y: (attributes?.center.y)! + items_CollectionView.frame.origin.y - items_CollectionView.contentOffset.y)
                   
                   if var theSuperView = items_CollectionView.superview {
                       tempView.center = CGPoint(x: tempView.center.x + theSuperView.frame.origin.x, y: tempView.center.y + theSuperView.frame.origin.y)
                       while let anotherSuperView = theSuperView.superview {
                           tempView.center = CGPoint(x: tempView.center.x + anotherSuperView.frame.origin.x, y: tempView.center.y + anotherSuperView.frame.origin.y)
                           theSuperView = anotherSuperView
                       }
                   }
                   
                   return tempView.frame
        }//END
}//END Extension


