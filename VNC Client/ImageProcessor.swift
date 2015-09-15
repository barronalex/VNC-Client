//
//  ImageProcessor.swift
//  VNC Client
//
//  Created by Alex Barron on 6/26/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class ImageProcessor
{
    static func imageFromARGB32Bitmap(data: NSData, width:Int, height:Int) -> UIImage {
        let bitsPerComponent:Int = 8
        let bitsPerPixel:Int = 32
        
        let providerRef = CGDataProviderCreateWithCFData(data)
        let rgb = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.ByteOrder32Big | CGBitmapInfo(CGImageAlphaInfo.None.rawValue)
        let cgim = CGImageCreate(
            width,
            height,
            bitsPerComponent,
            bitsPerPixel,
            width * 4,
            rgb,
            bitmapInfo,
            providerRef,
            nil,
            true,
            kCGRenderingIntentDefault
        )
        return UIImage(CGImage: cgim)!
    }

}