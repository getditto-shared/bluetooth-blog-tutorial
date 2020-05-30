//
//  JoinTableHeaderView.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 31/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import UIKit

class JoinTableHeaderView: UIView {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var logoContainer: UIView!
    @IBOutlet weak var titleLabel: UILabel!

    class func instantiate() -> UIView {
        let views = UINib(nibName: "JoinTableHeaderView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)
        guard let view = views.first as? UIView else {
            fatalError("Was unable to locate JoinTableHeaderView XIB on disk")
        }
        return view
    }

    override func awakeFromNib() {
        // Configure the logo view
        let logoLayer = logoView.layer
        logoLayer.cornerRadius = 40.0
        logoLayer.cornerCurve = .continuous
        logoLayer.masksToBounds = true

        let logoContainerLayer = logoContainer.layer
        logoContainerLayer.shadowOpacity = 0.15
        logoContainerLayer.shadowColor = UIColor.black.cgColor
        logoContainerLayer.shadowRadius = 30.0
        logoContainerLayer.shadowPath = UIBezierPath(roundedRect: logoView.bounds, cornerRadius: 40).cgPath
    }

}
