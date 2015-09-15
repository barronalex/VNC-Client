//
//  DESEncryptor.h
//  VNC Client
//
//  Created by Alex Barron on 6/22/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

#ifndef VNC_Client_DESEncryptor_h
#define VNC_Client_DESEncryptor_h

#import <CommonCrypto/CommonCryptor.h>
#import <Foundation/Foundation.h>

@interface DESEncryptor : NSObject

+ (NSData*)encryptData:(NSData*)data key:(NSData*)key;

@end

#endif
