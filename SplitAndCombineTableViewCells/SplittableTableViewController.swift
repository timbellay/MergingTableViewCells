//
//  SplittableTableViewController.swift
//  SplitAndCombineTableViewCells
//
//  Created by Timothy Bellay on 2/6/16.
//  Copyright © 2016 Timothy Bellay. All rights reserved.
//

import UIKit

public protocol SplitGestureRecognizerDelegate: class {
	func insertRowAbove(cell: UITableViewCell, color: UIColor?)
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
	
		switch pinchGR.state {
		case .Began:
			
			// TODO: Instead of setting scale to 1, we could calculate it in points and use 0.5 * scale as threshold of when to merge cells.
			pinchGR.scale = 1
			
			let touch1: CGPoint = pinchGR.locationOfTouch(0, inView: tableView)
			let touch2: CGPoint = pinchGR.locationOfTouch(1, inView: tableView)
			let cell1IndexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(touch1)
			let cell2IndexPath: NSIndexPath? = tableView.indexPathForRowAtPoint(touch2)
			
			// Test unwraping of mergingCellsIndexPaths and that they are different.
			guard let c1IP = cell1IndexPath
				else { break }
			let cell1 = tableView.cellForRowAtIndexPath(cell1IndexPath!)! as! SplittableTableViewCell
			guard let c2IP = cell2IndexPath
				else { break }
			let cell2 = tableView.cellForRowAtIndexPath(cell2IndexPath!)! as! SplittableTableViewCell
			
			// Two cells should not be the same.
			if c1IP.compare(c2IP) == .OrderedSame {
				break
			}
			
			// Two cell should be adjacent.
			if abs(c1IP.row - c2IP.row) > 1 {
				break
			}
			
			mergingCellsIndexPaths = [cell1IndexPath!, cell2IndexPath!]
			cell1.originalCenter = cell1.center
			cell2.originalCenter = cell2.center
			mergingCells = [cell1, cell2]
			
		case .Ended:
			// TODO: Animate cells back to original positions if user did not pinch close enought to merge cells.
			if let cells = mergingCells {
				for cell in cells  {
					UIView.animateWithDuration(0.2, animations: { () -> Void in
						cell.center = cell.originalCenter!
						cell.alpha = 1
					})
				}
			}
			break
		
		default:
			if pinchGR.enabled {
				if (pinchGR.scale < 0.25) {
//					print("MERGE") // Debug.
					pinchGR.enabled = false
					if let mergeIPs = mergingCellsIndexPaths {
						mergeCells(mergeIPs)
					}
				} else {
					if (pinchGR.velocity < 0) {
						mergingCells?[0].center.y += 2
						mergingCells?[1].center.y -= 2
						mergingCells?[0].alpha -= 0.025
						mergingCells?[1].alpha -= 0.025
					} else {
						mergingCells?[0].center.y -= 2
						mergingCells?[1].center.y += 2
						mergingCells?[0].alpha += 0.025
						mergingCells?[1].alpha += 0.025
					}
				}
				
//				print("Scale: \(pinchGR.scale)")  // Debug.
//				print("Velocoty: \(pinchGR.velocity)")  // Debug.
			}
			
		}
		
	}
	
	func insertRowAbove(cell: UITableViewCell, color: UIColor?) {
		if let indexPath = tableView.indexPathForCell(cell) {
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
	}
	
	func mergeCells(indexPaths: [NSIndexPath]) {
		let indexPathToRemove = indexPaths[0]
		colorList.removeAtIndex(indexPathToRemove.row)
		colorList.removeAtIndex(indexPathToRemove.row)
		
		if let cells = mergingCells {
			for cell in cells {
				cell.hidden = true
			}
		}
		
		tableView.beginUpdates()
		tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
		tableView.endUpdates()
		if let cell = tableView.cellForRowAtIndexPath(indexPathToRemove) {
			let avgColor = averageColor((mergingCells?[0].outlineView.backgroundColor)!, c2: (mergingCells?[1].outlineView.backgroundColor)!)
			insertRowAbove(cell, color: avgColor)
		}
		pinchGR.enabled = true

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
		cell.outlineView.backgroundColor = colorList[indexPath.row]
		cell.selectionStyle = .None
		cell.showsReorderControl = true
		cell.splitCellDelegate = self
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
