//
//  FrameBufferProcessor.swift
//  VNC Client
//
//  Created by Alex Barron on 6/23/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import CoreFoundation
import UIKit

class FrameBufferProcessor
{
    private var inputStream: NSInputStream?
    private var outputStream: NSOutputStream?
    
    let encodingMessageType = 2
    var pixelRectangle: PixelRectangle?
    
    let frameBufferRequestMessageType = UInt8(3)
    
    var pixelsToRead = 0
    var rectsToRead = 0
    var pixelBuffer = [UInt8]()
    
    struct Point {
        var x = 0;
        var y = 0;
    }
   // var rects = [Point:(Int, Int)]()
    
    init(inputStream: NSInputStream?, outputStream: NSOutputStream?) {
        self.inputStream = inputStream
        self.outputStream = outputStream
    }
    
    //frame buffer constants
    var framebufferwidth = 0
    var framebufferheight = 0
    var bitsperpixel = 0
    var depth = 0
    var bigendianflag = 0
    var truecolourflag = 0
    var redmax = 0
    var greenmax = 0
    var bluemax = 0
    var redshift = 0
    var greenshift = 0
    var blueshift = 0
    
    func initialise() {
        var buffer = StreamReader.readAllFromServer(inputStream)
        var data = NSData(bytes: buffer, length: 4096)
        
        //extract constants
        data.getBytes(&framebufferwidth, range: NSMakeRange(0,2))
        data.getBytes(&framebufferheight, range: NSMakeRange(2,2))
        data.getBytes(&bitsperpixel, range: NSMakeRange(4,1))
        data.getBytes(&depth, range: NSMakeRange(5,1))
        data.getBytes(&bigendianflag, range: NSMakeRange(6,1))
        data.getBytes(&truecolourflag, range: NSMakeRange(7,1))
        data.getBytes(&redmax, range: NSMakeRange(8,2))
        data.getBytes(&greenmax, range: NSMakeRange(10,2))
        data.getBytes(&bluemax, range: NSMakeRange(12,2))
        data.getBytes(&redshift, range: NSMakeRange(14,1))
        data.getBytes(&greenshift, range: NSMakeRange(15,1))
        data.getBytes(&blueshift, range: NSMakeRange(16,1))
        
        //fix network byte order
        framebufferwidth = Int(CFSwapInt16(UInt16(framebufferwidth)))
        framebufferheight = Int(CFSwapInt16(UInt16(framebufferheight)))
        redmax = Int(CFSwapInt16(UInt16(redmax)))
        greenmax = Int(CFSwapInt16(UInt16(greenmax)))
        bluemax = Int(CFSwapInt16(UInt16(bluemax)))
        
        println("Frame Width: \(framebufferwidth)")
        println("Frame Height: \(framebufferheight)")
        println("Bits Per Pixel: \(bitsperpixel)")
        println("True colour: \(truecolourflag)")
        println("Depth:  \(depth)")
        println("redmax:  \(redmax)")
        println("redshift:  \(redshift)")
        
        //set encoding
        var encoding: [UInt8] = [UInt8(encodingMessageType), 0, 0, 1, 0, 0, 0, 0]
        outputStream!.write(&encoding, maxLength: encoding.count)
        
        //set size of pixel buffer according to frame size
        pixelBuffer = [UInt8](count: framebufferwidth * framebufferheight * 4, repeatedValue: 0)
        
        //send initial frame buffer request
        sendFrameBufferRequest(0, xvalue: 0, yvalue: 0, width: UInt16(framebufferwidth), height: UInt16(framebufferheight))
    }
    
    private func sendFrameBufferRequest(incremental: UInt8, xvalue: UInt16, yvalue: UInt16, width: UInt16, height: UInt16) {
        
        var firstbytex = UInt8(truncatingBitPattern: xvalue)
        var secondbytex = UInt8(truncatingBitPattern: xvalue.byteSwapped)
        var firstbytey = UInt8(truncatingBitPattern: yvalue)
        var secondbytey = UInt8(truncatingBitPattern: yvalue.byteSwapped)
        var firstbytewidth = UInt8(truncatingBitPattern: width)
        var secondbytewidth = UInt8(truncatingBitPattern: width.byteSwapped)
        var firstbyteheight = UInt8(truncatingBitPattern: height)
        var secondbyteheight = UInt8(truncatingBitPattern: height.byteSwapped)
        var info = [frameBufferRequestMessageType, incremental, secondbytex, firstbytex, secondbytey, firstbytey, secondbytewidth, firstbytewidth, secondbyteheight, firstbyteheight]
        outputStream!.write(&info, maxLength: info.count)
    }
    
    func sendRequest() {
        sendFrameBufferRequest(1, xvalue: 0, yvalue: 0, width: UInt16(framebufferwidth), height: UInt16(framebufferheight))
    }
    
    //return the number of pixels found
    private func ingestRectangle(offset: Int, data: NSData) -> PixelRectangle {
        var xvalue = 0
        var yvalue = 0
        var width = 0
        var height = 0
        var encodingtype = 0
        data.getBytes(&xvalue, range: NSMakeRange(offset, 2))
        data.getBytes(&yvalue, range: NSMakeRange(offset + 2, 2))
        data.getBytes(&width, range: NSMakeRange(offset + 4, 2))
        data.getBytes(&height, range: NSMakeRange(offset + 6, 2))
        data.getBytes(&encodingtype, range: NSMakeRange(offset + 8, 4))
        xvalue = Int(CFSwapInt16(UInt16(xvalue)))
        yvalue = Int(CFSwapInt16(UInt16(yvalue)))
        width = Int(CFSwapInt16(UInt16(width)))
        height = Int(CFSwapInt16(UInt16(height)))
        encodingtype = Int(CFSwapInt16(UInt16(encodingtype)))
        println("xvalue: \(xvalue)")
        println("yvalue: \(yvalue)")
        println("width: \(width)")
        println("height: \(height)")
        println("encodingtype: \(encodingtype)")
        return PixelRectangle(xvalue: xvalue, yvalue: yvalue, width: width, height: height, encodingtype: 0, image: nil)
    }
    
    func readHeader() {
        var buffer = StreamReader.readAllFromServer(inputStream, maxlength: 4)
        println("Message type: \(buffer[0])")
        var data = NSData(bytes: buffer, length: 4)
        data.getBytes(&rectsToRead, range: NSMakeRange(2, 2))
        println("Num rects: \(Int(CFSwapInt16(UInt16(rectsToRead))))")
        rectsToRead = (Int(CFSwapInt16(UInt16(rectsToRead))))
        print("rectsToRead: \(rectsToRead)")
    }
    
    func readRectHeader() -> Bool {
        
        if rectsToRead == 0 { return false }
        var buffer = StreamReader.readAllFromServer(inputStream, maxlength: 12)
        var data = NSData(bytes: buffer, length: 12)
        pixelRectangle = ingestRectangle(0, data: data)
        rectsToRead--
        pixelsToRead = pixelRectangle!.width * pixelRectangle!.height * 4
        return true
    }
    
    private func createImage() -> UIImage {
        
        //lets make a UIImage first
        return ImageProcessor.imageFromARGB32Bitmap(NSData(bytes: &pixelBuffer, length: pixelBuffer.count), width: framebufferwidth, height: framebufferheight)
        
    }
    //transfer pixels directly to buffer, then we'll update the image
    private func addPixelsToBuffer(buffer: [UInt8], len: Int) {
        //need to use pixelsToRead and the size and x/y position of the rectangle we're trying to draw to do this
        //every rect width need to go down a level
        //figure out coordinates in pixel rect
        //then transfer this to overall thing?
        var pixelsRead = pixelRectangle!.width * pixelRectangle!.height * 4 - pixelsToRead
        var xCoordInRect = pixelsRead % (pixelRectangle!.width * 4)
        var yCoordInRect = pixelsRead / (pixelRectangle!.width * 4)
        
        var initialIndex = ((pixelRectangle!.yvalue) + yCoordInRect) * (framebufferwidth * 4) + (pixelRectangle!.xvalue  * 4) + xCoordInRect
        //println("Initial index: \(initialIndex)")
        //outer for loop goes through every level
        for var i = 0; i < len; i++ {
            var curIndex = (initialIndex + i) + (framebufferwidth * 4 - pixelRectangle!.width * 4) * (((pixelsRead + i) / (pixelRectangle!.width * 4)) - yCoordInRect)
            pixelBuffer[curIndex] = buffer[i]
        }
    }
    
    func getPixelData() -> Int {
        if pixelsToRead > 0 {
            var buffer = [UInt8](count: pixelsToRead, repeatedValue: 0)
            var len = inputStream!.read(&buffer, maxLength: buffer.count)
            
            var tempByte = UInt8(0)
            //change from bgr to rgb
            for var index = 0; index < (len); index += 4 {
                tempByte = buffer[index]
                buffer[index] = buffer[index + 2]
                buffer[index + 2] = tempByte
            }
            addPixelsToBuffer(buffer, len: len)
            pixelsToRead -= len
            println("Len: \(len)")
            println("pixels left: \(pixelsToRead)")
        }
        if pixelsToRead == 0 {
            println("rectsToRead: \(rectsToRead)")
            var image = createImage()
            pixelRectangle!.image = image
            NSNotificationCenter.defaultCenter().postNotificationName("pixeldataavailiable", object: nil, userInfo: ["data":pixelRectangle!])
            if rectsToRead > 0 {
                println("returning 1")
                return 1
            }
            else { return 2 }
        }
        return 0 //signifies keep reading pixels
    }
}