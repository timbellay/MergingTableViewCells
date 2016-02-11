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
	
	var colorList: [UIColor] = [.redColor(), .orangeColor(), .yellowColor(), .greenColor(), .blueColor(), .purpleColor()]
	var pinchGR = UIPinchGestureRecognizer()
	var mergingCells: [SplittableTableViewCell]?
	var formingCell: SplittableTableViewCell?
	var mergingCellsIndexPaths: [NSIndexPath]?
	
	// MARK: Table view setup and memory
	func setUpTableView() {
		tableView.separatorStyle = .None
		let splittableCellNib = UINib(nibName: "SplittableTableViewCell", bundle: NSBundle.mainBundle())
		tableView.registerNib(splittableCellNib, forCellReuseIdentifier: "SplittableCellReuseID")
		
		pinchGR.addTarget(self, action: "handlePinch:")
		tableView.addGestureRecognizer(pinchGR)
		pinchGR.delegate = self
		
		//		self.navigationItem.rightBarButtonItem = self.editButtonItem()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setUpTableView()
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	// MARK: - Table view helpers
	
	func handlePinch(pinchGR: UIPinchGestureRecognizer) {
	
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
		
		switch pinchGR.state {
		case .Began:
		
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
					})
				}
			}
			formingCell?.removeFromSuperview()
			formingCell = nil
			mergingCells = nil

		default:
			if pinchGR.numberOfTouches() < 2 {
				formingCell = nil
				mergingCells = nil
				return
			}
			
			if mergingCells == nil {
				return
			}
			
			// TODO: Fix for sometimes pinch fingers will hit before window centers get close enough to trigger merge for cells.
			//				if abs(mergingCells![0].center.y - mergingCells![1].center.y) < 5 || (bottomTouch!.y - topTouch!.y) < 150 {
			let topCellYpos = (mergingCells?[0].center.y)!
			let bottomCellYPos = (mergingCells?[1].center.y)!
			let intersectionRect = CGRectIntersection(mergingCells![0].frame, mergingCells![1].frame)
			print("DIFF: \(bottomCellYPos - topCellYpos)")
			if (intersectionRect.height) > 0.96 * (mergingCells?[0].frame.height)! {
				if let mergeIPs = mergingCellsIndexPaths {
					mergeCells(mergeIPs)
					mergingCellsIndexPaths = nil
					mergingCells = nil
				}
				formingCell?.removeFromSuperview()
				formingCell = nil
			} else {
				
				if formingCell == nil {
					loadFormingCell(averageColor((mergingCells?[0].outlineView.backgroundColor)!, c2: (mergingCells?[1].outlineView.backgroundColor)!))
				}
				formingCell!.frame = intersectionRect
				
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
				
			} // end case default
		} // end switch
		
	}
	
	func loadFormingCell(color: UIColor) {
		formingCell = NSBundle.mainBundle().loadNibNamed("SplittableTableViewCell", owner: nil, options: nil)[0] as? SplittableTableViewCell
		formingCell?.outlineView.backgroundColor = color
		formingCell?.backgroundColor = .clearColor()
		tableView.addSubview(formingCell!)
	}
	
	func insertMergedCellAtIndexPath(indexPath: NSIndexPath, color: UIColor?) {
		if indexPath.row > 0 && color == nil {
			colorList.insert(averageColor(colorList[indexPath.row], c2: colorList[indexPath.row - 1]), atIndex: indexPath.row)
		} else if color != nil {
			colorList.insert(color!, atIndex: indexPath.row)
		} else {
			colorList.insert(averageColor(.whiteColor(), c2: colorList[indexPath.row]), atIndex: indexPath.row)
		}
		tableView.beginUpdates()
		tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
		tableView.endUpdates()
	}
	
	func mergeCells(indexPaths: [NSIndexPath]) {
		
		if mergingCells == nil {
			return
		}
		
		let sortedIPs = indexPaths.sort({$0.row < $1.row})
		
		colorList.removeAtIndex(sortedIPs[1].row) // Remove bottom cell first
		colorList.removeAtIndex(sortedIPs[0].row) // Remove top cell next
		
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
		return cell
	}
	
	//    // Override to support conditional editing of the table view.
	//    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	//        return true
	//    }
	//
	//	// Override to support editing the table view.
	//    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
	//        if editingStyle == .Delete {
	//            // Delete the row from the data source
	//            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
	//        } else if editingStyle == .Insert {
	//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	//        }
	//    }
	//
	//    // Override to support rearranging the table view.
	//    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
	//		print("delegate moveRowAtIndexPath called")
	//		let itemToMove = colorList[fromIndexPath.row]
	//		colorList.removeAtIndex(fromIndexPath.row)
	//		colorList.insert(itemToMove, atIndex: toIndexPath.row)
	//	}
	//
	//    // Override to support conditional rearranging of the table view.
	//    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	//        // Return false if you do not want the item to be re-orderable.
	//        return true
	//    }
	
	/*
	// MARK: - Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	// Get the new view controller using segue.destinationViewController.
	// Pass the selected object to the new view controller.
	}
	*/
	
}
