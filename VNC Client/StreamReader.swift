//
//  StreamReader.swift
//  VNC Client
//
//  Created by Alex Barron on 6/23/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

class StreamReader
{
    static func readAllFromServer(inputStream: NSInputStream?) -> [UInt8] {
        var buffer = [UInt8](count: 4096, repeatedValue: 0)
        //while (inputStream!.hasBytesAvailable){
            var len = inputStream!.read(&buffer, maxLength: buffer.count)
        //}
        return buffer
    }
    
    static func readAllFromServer(inputStream: NSInputStream?, maxlength: Int) -> [UInt8] {
        var buffer = [UInt8](count: maxlength, repeatedValue: 0)
       // while (inputStream!.hasBytesAvailable){
            var len = inputStream!.read(&buffer, maxLength: buffer.count)
        //}
        
        return buffer
    }
}