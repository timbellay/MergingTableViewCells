//
//  SplittableTableViewCell.swift
//  SplitAndCombineTableViewCells
//
//  Created by Timothy Bellay on 2/6/16.
//  Copyright © 2016 Timothy Bellay. All rights reserved.
//

import UIKit

public class SplittableTableViewCell: UITableViewCell {
	
	public var originalCenter: CGPoint? // For animations back to original position in tableView upon cancel of failure to merge with another.
	@IBOutlet internal weak var outlineView: UIView!
//	let panGR = UIPanGestureRecognizer()
	let pressGR = UILongPressGestureRecognizer()
	public var indexPath: NSIndexPath!
	public weak var splitCellDelegate: SplitGestureRecognizerDelegate?
	
	// Data Labels
	@IBOutlet weak var milesTraveledLabel: UILabel!
	@IBOutlet weak var potentialMoneyReimbursement: UILabel!
	
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		
		// Setup cell layer properties.
		outlineView.layer.cornerRadius = 8
		outlineView.layer.shadowOffset = CGSizeMake(2, 2)
		outlineView.layer.shadowOpacity = 0.5
		
		// Setup gesture recgonizers.
//		panGR.addTarget(self, action: "handlePan:")
//		self.addGestureRecognizer(panGR)
		
		pressGR.addTarget(self, action: "handlePress:")
		pressGR.minimumPressDuration = 0.5
		self.addGestureRecognizer(pressGR)

	}
	
	public override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
	public override func gestureRecognizer(gr: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGR: UIGestureRecognizer) -> Bool {
		return true
	}
	
	func handlePan(panGR: UIPanGestureRecognizer) {
		
		let 𝚫X = panGR.translationInView(self).x
//		let 𝚫Y = panGR.translationInView(self).y
		let direction = 𝚫X > 0 ? 1 : -1
		
		let maxAngle = CGFloat(M_PI / 24)
		let maxTranslationX = CGFloat(300)
		var rotationAngle = 0 as CGFloat
		
		switch panGR.state {
		case .Began:
			break
		case .Changed:
			var center = self.center
			if direction == 1 {
				rotationAngle = min(CGFloat(M_PI * Double(𝚫X) / 512), maxAngle)
				center.x = min(center.x + 𝚫X/8, self.frame.width / 2 + maxTranslationX)
				self.alpha = min(self.alpha + 0.1, 1)
			} else {
				rotationAngle = max(CGFloat(M_PI * Double(𝚫X) / 512), -maxAngle)
				center.x = max(center.x + 𝚫X/8, self.frame.width / 2 - maxTranslationX)
				self.alpha = max(self.alpha - 0.1, 0)
			}
			let angleTransform = CGAffineTransformMakeRotation(rotationAngle)
			self.transform = angleTransform
			self.center = center
		case .Ended:
			break
		default:
			break
		}
	}
	
	func handlePress(pressGR: UILongPressGestureRecognizer) {
		switch pressGR.state {
		case .Began:
			if let delegate = splitCellDelegate {
				delegate.insertMergedCellAtIndexPath(indexPath, color: nil)
			}
		case .Ended:
			break
		default:
			break
		}
	}
	
}
