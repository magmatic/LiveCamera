/*
     File: AVCamUtilities.h
 Abstract: A utility class containing a method to find an AVCaptureConnection of a particular media type from an array of AVCaptureConnections.
  Version: 1.2
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>

@class AVCaptureConnection;

@interface AVCamUtilities : NSObject {

}

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;

@end
