//
//  PixelRectangle.swift
//  VNC Client
//
//  Created by Alex Barron on 6/25/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import UIKit

class PixelRectangle
{
    var xvalue = 0
    var yvalue = 0
    var width = 0
    var height = 0
    var encodingtype = 0
    var image: UIImage?
    
    init(xvalue: Int, yvalue: Int, width: Int, height: Int, encodingtype: Int, image: UIImage?) {
        self.xvalue = xvalue
        self.yvalue = yvalue
        self.width = width
        self.height = height
        self.encodingtype = encodingtype
        self.image = image //could just change this to image
    }
}