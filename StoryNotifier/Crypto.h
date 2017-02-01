//
//  Crypto.h
//  StoryNotifier
//
//  Created by CenoX on 2016. 12. 29..
//  Copyright © 2016년 Team Vanilla. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import <Security/Security.h>

@interface Crypto : NSObject

+ (NSData *)AES256EncryptWithKey:(NSString *)key data: (NSData *)data;
+ (NSData *)AES256DecryptWithKey:(NSString *)key data: (NSData *)data;

@end
