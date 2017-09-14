//
//  EnvironConfig.c
//  PAPersonalDoctor
//
//  Created by Perry on 15/2/25.
//  Copyright (c) 2015年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#include <stdio.h>


NSString *pathComponentOfResourceType(TFSResourceType resourceType)
{
    NSString *pathComponent = nil;
    switch (resourceType) {
        case TFSResourceTypeImage:
            pathComponent = @"img";
            break;
        case TFSResourceTypeThumnail:
            pathComponent = @"smg";
            break;
        case TFSResourceTypeVoice:
            pathComponent = @"voc";
            break;
        case TFSResourceTypeFile:
            pathComponent = @"file";
            break;
        default:
            pathComponent = @"file";
            break;
    }
    
    return pathComponent;
}

NSURL *resourceUrlWithTfsKey(NSString *tfskey)
{
    if ([tfskey length] > 0)
    {
        if ([tfskey hasPrefix:@"http://"]) {
            return [NSURL URLWithString:tfskey];
        }
        
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", PAAPI_TFSUrl, tfskey]];
    }
    
    return nil;
}

NSURL *resourceUrlWithTfsKeyAndSize(NSString *tfskey, CGSize size)
{
    if ([tfskey length] > 0)
    {
        if ([tfskey hasPrefix:@"http://"]) {
            return [NSURL URLWithString:tfskey];
        }
        
        CGFloat scale = [UIScreen mainScreen].scale;
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@_%ldx%ld.png", PAAPI_TFSUrl, tfskey, (long)(size.width * scale), (NSInteger)(size.height * scale)]];
    }
    
    return nil;
}

NSString *resourcePathWithTfsKey(NSString *tfskey)
{
    if ([tfskey length] > 0)
    {
        if ([tfskey hasPrefix:@"http://"]) {
            return tfskey;
        }
        
        return [NSString stringWithFormat:@"%@%@", PAAPI_TFSUrl, tfskey];
    }
    
    return nil;
}


NSURL *privateResourceUrlWithTfsKey(NSString *tfskey, TFSResourceType resourceType)
{
    if ([tfskey length] > 0)
    {
        if ([tfskey hasPrefix:@"http://"]) {
            return [NSURL URLWithString:tfskey];
        }
        
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@", PAAPI_IM_IMAGE_TFS_ADDRESS, pathComponentOfResourceType(resourceType), tfskey]];
    }
    
    return nil;
}

NSString *privateResourcePathWithTfsKey(NSString *tfskey, TFSResourceType resourceType)
{
    if ([tfskey length] > 0)
    {
        if ([tfskey hasPrefix:@"http://"]) {
            return tfskey;
        }
        
        return [NSString stringWithFormat:@"%@%@/%@", PAAPI_IM_IMAGE_TFS_ADDRESS, pathComponentOfResourceType(resourceType), tfskey];
    }
    
    return nil;
}

NSURL *privateThumnailUrlWithTfsKey(NSString *tfskey, NSString *sizeSting)
{
    if ([tfskey length] > 0)
    {
        if ([tfskey hasPrefix:@"http://"]) {
            return [NSURL URLWithString:tfskey];
        }
        
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@%@", PAAPI_IM_IMAGE_TFS_ADDRESS, @"smg", tfskey, sizeSting]];
    }
    
    return nil;
}

NSString *privateThumnailPathWithTfsKey(NSString *tfskey, NSString *sizeSting)
{
    if ([tfskey length] > 0)
    {
        if ([tfskey hasPrefix:@"http://"]) {
            return tfskey;
        }
        
        return [NSString stringWithFormat:@"%@%@/%@%@", PAAPI_IM_IMAGE_TFS_ADDRESS, @"smg", tfskey, sizeSting];
    }
    
    return nil;
}
