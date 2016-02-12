//
//  SplittableTableViewController.swift
//  SplitAndCombineTableViewCells
//
//  Created by Timothy Bellay on 2/6/16.
//  Copyright © 2016 Timothy Bellay. All rights reserved.
//

import UIKit

public protocol SplitGestureRecognizerDelegate: class {
	func insertMergedCellAtIndexPath(indexPath: NSIndexPath, color: UIColor?)
}

public func + (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

public func += (inout left: CGPoint, right: CGPoint) {
	left = left + right
}

class SplittableTableViewController: UITableViewController, UIGestureRecognizerDelegate, SplitGestureRecognizerDelegate {
	
	// TODO: [Cleanup] Pull out all constants into a constants.swift file. Remove magic numbers and replace with constants or computed values. Rename SplittableTableViewCell to "Mergable", etc.
	
	
	var colorList: [UIColor] = [.redColor(), .orangeColor(), .yellowColor(), .greenColor(), .blueColor(), .purpleColor()]
	var miles: [Float] = [1.2, 2.4, 23, 4.5, 1.1, 7.6]
	var payouts: [Float]!
	var pinchGR = UIPinchGestureRecognizer()
	var mergingCells: [SplittableTableViewCell]?
	var formingCell: SplittableTableViewCell?
	var mergingCellsIndexPaths: [NSIndexPath]?
	
	// MARK: TableView setup
	func setUpTableView() {
		tableView.separatorStyle = .None
		let splittableCellNib = UINib(nibName: "SplittableTableViewCell", bundle: NSBundle.mainBundle())
		tableView.registerNib(splittableCellNib, forCellReuseIdentifier: "SplittableCellReuseID")
		
		pinchGR.addTarget(self, action: "handlePinch:")
		tableView.addGestureRecognizer(pinchGR)
		pinchGR.delegate = self
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		payouts = miles.map({$0 * 0.5})
		setUpTableView()
	}
	
	// MARK: - Table view gesture handling
	
	func handlePinch(pinchGR: UIPinchGestureRecognizer) {
		
		switch pinchGR.state {
		case .Began:
		
			if pinchGR.numberOfTouches() != 2 {
				return
			}
			let touch1: CGPoint? = pinchGR.locationOfTouch(0, inView: tableView)
			let touch2: CGPoint? = pinchGR.locationOfTouch(1, inView: tableView)
			var topTouch: CGPoint?
			var bottomTouch: CGPoint?
			
			// Determine which touch is top cell vs. bottom cell.
			if touch2?.y > touch1?.y {
				topTouch = touch1!
				bottomTouch = touch2!
			}
			if touch2?.y < touch1?.y {
				topTouch = touch2!
				bottomTouch = touch1!
			}
			
			let topCellIndexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(topTouch!)
			let bottomCellIndexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(bottomTouch!)
			
			// Test unwraping of mergingCellsIndexPaths and that they are different.
			guard let topIndexPathUnwrapped = topCellIndexPath
				else { break }
			let topCell = tableView.cellForRowAtIndexPath(topCellIndexPath!)! as! SplittableTableViewCell
			guard let bottomIndexPathUnwrapped = bottomCellIndexPath
				else { break }
			let bottomCell = tableView.cellForRowAtIndexPath(bottomCellIndexPath!)! as! SplittableTableViewCell
			
			// Two cells should not be the same and the cells should be adjacent.
			if topIndexPathUnwrapped.compare(bottomIndexPathUnwrapped) != .OrderedSame && abs(topIndexPathUnwrapped.row - bottomIndexPathUnwrapped.row) == 1 {
					mergingCellsIndexPaths = [topIndexPathUnwrapped, bottomIndexPathUnwrapped]
					topCell.originalCenter = topCell.center
					bottomCell.originalCenter = bottomCell.center
					mergingCells = [topCell, bottomCell]
			} else {
				mergingCells = nil
			}
			
		case .Ended:
			if let cells = mergingCells {
				for cell in cells  {
					UIView.animateWithDuration(0.2, animations: { () -> Void in
						cell.center = cell.originalCenter!
						cell.alpha = 1
						}, completion: { (finished) -> Void in
							if cell == self.mergingCells?.last {
								self.mergingCells = nil
							}
					})
				}
			}
			formingCell?.removeFromSuperview()
			formingCell = nil

		default:
			if pinchGR.numberOfTouches() < 2 || mergingCells == nil {
				return
			}
		
			let intersectionRect = CGRectIntersection(mergingCells![0].frame, mergingCells![1].frame)
			let formingCellRect = CGRectMake(intersectionRect.origin.x, intersectionRect.origin.y-2, intersectionRect.width, intersectionRect.height + 4)
			
//			print("Merged cell Height: \(formingCellRect.height / (mergingCells?[0].frame.height)!  * 100 ) %") // Debug.
			if (formingCellRect.height) > 0.95 * (mergingCells?[0].frame.height)! {
				if let mergeIPs = mergingCellsIndexPaths {
					mergeCells(mergeIPs)
					// TODO: [BUG] Fix NSLayoutConstraint conflict for tableView.bottomMargin.
					mergingCellsIndexPaths = nil
					mergingCells = nil
				}
				formingCell?.removeFromSuperview()
				
			} else {
				
				if formingCell == nil {
					// Create newCell from merge of two neighbor cells.
					loadFormingCell(averageColor((mergingCells?[0].outlineView.backgroundColor)!, c2: (mergingCells?[1].outlineView.backgroundColor)!))
					tableView.addSubview(formingCell!)
				
				}
				let mergedData = mergeData()
				
				formingCell?.milesTraveledLabel.text = mergedData.0
				formingCell?.potentialMoneyReimbursement.text = mergedData.1
				
				formingCell!.frame = formingCellRect
				
				if (pinchGR.velocity < 0) {
					mergingCells?[0].center.y += 2
					mergingCells?[1].center.y -= 2
					mergingCells?[0].alpha -= 0.012
					mergingCells?[1].alpha -= 0.012
				} else {
					// TODO: Stop movement of cells with distance get to far apart.
					mergingCells?[0].center.y -= 2
					mergingCells?[1].center.y += 2
					mergingCells?[0].alpha += 0.012
					mergingCells?[1].alpha += 0.012
				}
				
			}
			
		} // End switch
		
	}
	
	// MARK: - Table view helpers
	
	func loadFormingCell(color: UIColor) {
		formingCell = NSBundle.mainBundle().loadNibNamed("SplittableTableViewCell", owner: nil, options: nil)[0] as? SplittableTableViewCell
		formingCell?.outlineView.backgroundColor = color
		formingCell?.backgroundColor = .clearColor()
//		formingCell?.outlineView.layer.shadowOffset = CGSizeMake(4, 4)
//		formingCell?.outlineView.layer.shadowOpacity = 0.5
	}
	
	func insertMergedCellAtIndexPath(indexPath: NSIndexPath, color: UIColor?) {
		if indexPath.row > 0 && color == nil {
			colorList.insert(averageColor(colorList[indexPath.row], c2: colorList[indexPath.row - 1]), atIndex: indexPath.row)
		} else if color != nil {
			colorList.insert(color!, atIndex: indexPath.row)
		} else {
			colorList.insert(averageColor(.whiteColor(), c2: colorList[indexPath.row]), atIndex: indexPath.row)
		}
		
		if formingCell == nil {
			loadFormingCell(averageColor(.whiteColor(), c2: colorList[indexPath.row]))
		}
		let milesText = formingCell?.milesTraveledLabel.text!
		var payoutText = formingCell?.potentialMoneyReimbursement.text!
		payoutText = payoutText?.stringByReplacingOccurrencesOfString("$", withString: "", options: .LiteralSearch, range: nil)
		miles.insert(Float(milesText!)!, atIndex: indexPath.row)
		payouts.insert(Float(payoutText!)!, atIndex: indexPath.row)
		
		tableView.beginUpdates()
		tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
		tableView.endUpdates()
	}
	
	func mergeCells(indexPaths: [NSIndexPath]) {
		
		if mergingCells == nil {
			return
		}
		
		let sortedIPs = indexPaths.sort({$0.row < $1.row})
		
		colorList.removeAtIndex(sortedIPs[1].row) // Remove bottom cell first
		colorList.removeAtIndex(sortedIPs[0].row) // Remove top cell next
		miles.removeAtIndex(sortedIPs[1].row)
		miles.removeAtIndex(sortedIPs[0].row)
		payouts.removeAtIndex(sortedIPs[1].row)
		payouts.removeAtIndex(sortedIPs[0].row)
		
		if let cells = mergingCells {
			for cell in cells {
				// TODO: Fade these merging cells out.
				cell.hidden = true
			}
			
		}
		tableView.beginUpdates()
		tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
		tableView.endUpdates()
		let avgColor = averageColor((mergingCells?[0].outlineView.backgroundColor)!, c2: (mergingCells?[1].outlineView.backgroundColor)!)
		insertMergedCellAtIndexPath(sortedIPs[0], color: avgColor)
		mergingCells = nil
	}
	
	func mergeData()-> (String?, String?) {
		// This would normally access the model for each Drive.
		if let cells = mergingCells {
			let firstMiles = Float(cells[0].milesTraveledLabel.text!)
			let secondMiles = Float(cells[1].milesTraveledLabel.text!)
			let totalMiles = firstMiles! + secondMiles!
			
			let firstPayoutText = cells[0].potentialMoneyReimbursement.text!.stringByReplacingOccurrencesOfString("$", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
			let secondPayoutText = cells[1].potentialMoneyReimbursement.text!.stringByReplacingOccurrencesOfString("$", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
			let firstPayout = Float(firstPayoutText)
			let secondPayout = Float(secondPayoutText)
			let totalPayout = firstPayout! + secondPayout!
			
			return (String(totalMiles), "$" + String(totalPayout))
		}
		return (nil, nil)
	}
	
	func averageColor(c1: UIColor, c2: UIColor) -> UIColor {
		var c1red: CGFloat = 0
		var c1green: CGFloat = 0
		var c1blue: CGFloat = 0
		var c1alpha: CGFloat = 0
		c1.getRed(&c1red, green: &c1green, blue: &c1blue, alpha: &c1alpha)
		
		var c2red: CGFloat = 0
		var c2green: CGFloat = 0
		var c2blue: CGFloat = 0
		var c2alpha: CGFloat = 0
		c2.getRed(&c2red, green: &c2green, blue: &c2blue, alpha: &c2alpha)
		
		let avgColor = UIColor(red: (c1red + c2red) / 2, green: (c1green + c2green) / 2, blue: (c1blue + c2blue) / 2, alpha: (c1alpha + c2alpha) / 2)
		return avgColor
	}
	
	// MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return colorList.count
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 256
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("SplittableCellReuseID", forIndexPath: indexPath) as! SplittableTableViewCell
		cell.backgroundColor = .clearColor() // Needs to be here to ensure background is transparent.
		cell.outlineView.backgroundColor = colorList[indexPath.row]
		cell.selectionStyle = .None
		cell.showsReorderControl = true
		cell.splitCellDelegate = self
		cell.indexPath = indexPath
		cell.milesTraveledLabel.text = String(miles[indexPath.row])
		cell.potentialMoneyReimbursement.text = "$" + String(payouts[indexPath.row])
		
		return cell
	}
	
}
