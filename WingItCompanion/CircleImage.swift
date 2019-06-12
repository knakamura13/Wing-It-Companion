//
//  CircleImage.swift
//  WingItCompanion
//
//  Created by Kyle Nakamura on 1/5/17.
//  Copyright © 2017 Kyle Nakamura. All rights reserved.
//

import UIKit

class CircleImage: UIImageView {
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.customInit();
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.customInit();
    }
    
    func customInit() {
        let layerWidth = layer.frame.size.width
        if layerWidth.remainder(dividingBy: 2) == 0 {
            self.layer.cornerRadius = layerWidth/2
        } else {
            self.layer.cornerRadius = (layerWidth-1)/2
        }
    }
}
