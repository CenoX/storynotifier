//
//  Crypto.m
//  StoryNotifier
//
//  Created by CenoX on 2016. 12. 29..
//  Copyright © 2016년 Team Vanilla. All rights reserved.
//

#import "Crypto.h"


@implementation Crypto

+ (NSData *)AES256EncryptWithKey:(NSString *)key data: (NSData *)data {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr [kCCKeySizeAES256 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    size_t buffersize                        = dataLength + kCCBlockSizeAES128;
    size_t numBytesencrypted    = 0;
    void *buffer = malloc(buffersize);
    if (!buffer) {
        return nil;
    }
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, keyPtr, kCCKeySizeAES256, NULL, [data bytes], dataLength, buffer, buffersize, &numBytesencrypted);
    
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesencrypted];
    }
    
    free(buffer);
    return nil;
}

+ (NSData *)AES256DecryptWithKey:(NSString *)key data: (NSData *)data {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr [kCCKeySizeAES256 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    size_t bufferSize                        = dataLength + kCCBlockSizeAES128;
    size_t numBytesDecrypted    = 0;
    
    void *buffer = malloc(bufferSize);
    if (!buffer) {
        return nil;
    }
    
    CCCryptorStatus cryptSatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, keyPtr, kCCKeySizeAES256, NULL, [data bytes], dataLength, buffer, bufferSize, &numBytesDecrypted);
    
    if (cryptSatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer);
    return  nil;
}

@end
