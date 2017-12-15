//
//  SIMManagers.m
//  SIMDEMO
//
//  Created by 辜东明 on 2017/11/6.
//  Copyright © 2017年 Louis. All rights reserved.
//

#import "SIMManagers.h"
#import <Foundation/Foundation.h>
#import <termios.h>
#import <time.h>
#import <sys/ioctl.h>


//UCS2编码支持
@implementation NSString(UCS2Encoding)

- (NSString*)ucs2EncodingString{
    NSMutableString *result = [NSMutableString string];
    for (int i = 0; i < [self length]; i++) {
        unichar unic = [self characterAtIndex:i];
        [result appendFormat:@"%04hX",unic];
    }
    return [NSString stringWithString:result];
}

- (NSString*)ucs2DecodingString{
    NSUInteger length = [self length]/4;
    unichar *buf = malloc(sizeof(unichar)*length);
    const char *scanString = [self UTF8String];
    for (int i = 0; i < length; i++) {
        sscanf(scanString+i*4, "%04hX", buf+i);
    }
    return [[NSString alloc] initWithCharacters:buf length:length];
}

@end


@implementation SIMManagers

NSString *sendATCommand(NSFileHandle *baseBand, NSString *atCommand){
    NSLog(@"SEND AT: %@", atCommand);
    [baseBand writeData:[atCommand dataUsingEncoding:NSASCIIStringEncoding]];
    NSMutableString *result = [NSMutableString string];
    NSData *resultData = [baseBand availableData];
    while ([resultData length]) {
        [result appendString:[[NSString alloc] initWithData:resultData encoding:NSASCIIStringEncoding]];
        if ([result hasSuffix:@"OK\r\n"]||[result hasSuffix:@"ERROR\r\n"]) {
            NSLog(@"RESULT: %@", result);
            return [NSString stringWithString:result];
        }
        else{
            resultData = [baseBand availableData];
        }
    }
    return nil;
}

//添加SIM卡联系人
BOOL addNewSIMContact(NSFileHandle *baseband, NSString *name, NSString *phone){
    NSString *result = sendATCommand(baseband, [NSString stringWithFormat:@"AT+CPBW=,\"%@\",,\"%@\"\r", phone, [name ucs2EncodingString]]);
    if ([result hasSuffix:@"OK\r\n"]) {
        return YES;
    }
    else{
        return NO;
    }
}

//读取所有SIM卡联系人
NSArray *readAllSIMContacts(NSFileHandle *baseband){
    NSString *result = sendATCommand(baseband, @"AT+CPBR=?\r");
    if (![result hasSuffix:@"OK\r\n"]) {
        return nil;
    }
    int max = 0;
    sscanf([result UTF8String], "%*[^+]+CPBR: (%*d-%d)", &max);
    result = sendATCommand(baseband, [NSString stringWithFormat:@"AT+CPBR=1,%d\r",max]);
    NSMutableArray *records = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:result];
    [scanner scanUpToString:@"+CPBR:" intoString:NULL];
    while ([scanner scanString:@"+CPBR:" intoString:NULL]) {
        NSString *phone = nil;
        NSString *name = nil;
        [scanner scanInt:NULL];
        [scanner scanString:@",\"" intoString:NULL];
        [scanner scanUpToString:@"\"" intoString:&phone];
        [scanner scanString:@"\"," intoString:NULL];
        [scanner scanInt:NULL];
        [scanner scanString:@",\"" intoString:NULL];
        [scanner scanUpToString:@"\"" intoString:&name];
        [scanner scanUpToString:@"+CPBR:" intoString:NULL];
        if ([phone length] > 0 && [name length] > 0) {
            [records addObject:@{@"name":[name ucs2DecodingString], @"phone":phone}];
        }
    }
    return [NSArray arrayWithArray:records];
}

- (void)demo{
    NSString *cc = @"简体中文";
    
    NSLog(@"%@",[cc ucs2EncodingString]);
    NSLog(@"%@",[[cc ucs2EncodingString] ucs2DecodingString]);
    
    
    NSFileHandle *baseband = [NSFileHandle fileHandleForUpdatingAtPath:@"/dev/dlci.spi-baseband.extra_0"];
    if (baseband == nil) {
        NSLog(@"Can't open baseband1.");
    }
    baseband =[NSFileHandle fileHandleForUpdatingAtPath:@"/dev/tty.debug"];
    if (baseband == nil) {
        NSLog(@"Can't open baseband2.");
    }
    baseband =[NSFileHandle fileHandleForUpdatingAtPath:@"/dev/tty.debug"];
    if (baseband == nil) {
        NSLog(@"Can't open baseband3.");
    }
    
    
    int fd = [baseband fileDescriptor];
    
    ioctl(fd, TIOCEXCL);
    fcntl(fd, F_SETFL, 0);
    
    static struct termios term;
    
    tcgetattr(fd, &term);
    
    cfmakeraw(&term);
    cfsetspeed(&term, 115200);
    term.c_cflag = CS8 | CLOCAL | CREAD;
    term.c_iflag = 0;
    term.c_oflag = 0;
    term.c_lflag = 0;
    term.c_cc[VMIN] = 0;
    term.c_cc[VTIME] = 0;
    tcsetattr(fd, TCSANOW, &term);
    
    //设置环境
    NSString *result = sendATCommand(baseband, @"AT+CPBS=\"SM\"\r");
    result = sendATCommand(baseband, @"AT+CSCS=\"UCS2\"\r");
    result = sendATCommand(baseband, @"ATE0\r");
    
    //添加数个联系人
    addNewSIMContact(baseband, @"测试一", @"13111111111");
    addNewSIMContact(baseband, @"测试二", @"13122222222");
    addNewSIMContact(baseband, @"测试三", @"13111113333");
    addNewSIMContact(baseband, @"测试四", @"13111114444");
    
    //获取所有联系人
    NSArray *allContacts = readAllSIMContacts(baseband);
    NSLog(@"%@", allContacts);
}
//
//int main(int argc, const char * argv[])
//{
//    
//    @autoreleasepool {
//        
//        NSString *cc = @"简体中文";
//        
//        NSLog(@"%@",[cc ucs2EncodingString]);
//        NSLog(@"%@",[[cc ucs2EncodingString] ucs2DecodingString]);
//        
//        
//        NSFileHandle *baseband = [NSFileHandle fileHandleForUpdatingAtPath:@"/dev/dlci.spi-baseband.extra_0"];
//        if (baseband == nil) {
//            NSLog(@"Can't open baseband.");
//        }
//        
//        int fd = [baseband fileDescriptor];
//        
//        ioctl(fd, TIOCEXCL);
//        fcntl(fd, F_SETFL, 0);
//        
//        static struct termios term;
//        
//        tcgetattr(fd, &term);
//        
//        cfmakeraw(&term);
//        cfsetspeed(&term, 115200);
//        term.c_cflag = CS8 | CLOCAL | CREAD;
//        term.c_iflag = 0;
//        term.c_oflag = 0;
//        term.c_lflag = 0;
//        term.c_cc[VMIN] = 0;
//        term.c_cc[VTIME] = 0;
//        tcsetattr(fd, TCSANOW, &term);
//        
//        //设置环境
//        NSString *result = sendATCommand(baseband, @"AT+CPBS=\"SM\"\r");
//        result = sendATCommand(baseband, @"AT+CSCS=\"UCS2\"\r");
//        result = sendATCommand(baseband, @"ATE0\r");
//        
//        //添加数个联系人
//        addNewSIMContact(baseband, @"测试一", @"13111111111");
//        addNewSIMContact(baseband, @"测试二", @"13122222222");
//        addNewSIMContact(baseband, @"测试三", @"13111113333");
//        addNewSIMContact(baseband, @"测试四", @"13111114444");
//        
//        //获取所有联系人
//        NSArray *allContacts = readAllSIMContacts(baseband);
//        NSLog(@"%@", allContacts);
//        
//    }
//    return 0;
//}

@end
