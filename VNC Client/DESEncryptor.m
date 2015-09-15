//
//  DESEncryptor.m
//  VNC Client
//
//  Created by Alex Barron on 6/22/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//


#import "DESEncryptor.h"


@implementation DESEncryptor


+ (NSData*)encryptData:(NSData*)data key:(NSData*)key;
{
    NSData* result = nil;
    
    // setup key
    unsigned char cKey[kCCKeySizeDES];
    bzero(cKey, sizeof(cKey));
    [key getBytes:cKey length:kCCKeySizeDES];
    
    // setup output buffer
    size_t bufferSize = [data length] + kCCBlockSizeDES;
    void *buffer = malloc(bufferSize);
    
    // do encrypt
    size_t encryptedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding,
                                          cKey,
                                          kCCKeySizeDES,
                                          NULL,
                                          [data bytes],
                                          [data length],
                                          buffer,
                                          bufferSize,
                                          &encryptedSize);
    if (cryptStatus == kCCSuccess) {
        result = [NSData dataWithBytesNoCopy:buffer length:encryptedSize];
    } else {
        free(buffer);
        NSLog(@"[ERROR] failed to encrypt|CCCryptoStatus: %d", cryptStatus);
    }
    return result;
}


@end