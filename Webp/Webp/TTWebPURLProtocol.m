//
//  TTWebPURLProtocol.m
//  TianTianWang
//
//  Created by yitailong on 2016/11/23.
//  Copyright © 2016年 oyxc. All rights reserved.
//

#import "TTWebPURLProtocol.h"
#import "UIImage+MultiFormat.h"

static NSString *const TTWebPProtocolHandledKey = @"TTWebPProtocolHandledKey";

@interface TTWebPURLProtocol ()<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *sessionTask;

@property (nonatomic, strong) NSMutableData *imgData;

@end

@implementation TTWebPURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:TTWebPProtocolHandledKey inRequest:request]) {
        return NO;
    }
    
    NSURL *url = [request URL];
    NSString *userAgent = [request allHTTPHeaderFields][@"User-Agent"];
    if (![[userAgent lowercaseString] containsString:@"applewebkit"]) {
        return  NO;
    }
    
    NSString* const requestFiletype = [[url pathExtension] lowercaseString];
    
    return [@"webp" isEqualToString:requestFiletype];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:TTWebPProtocolHandledKey inRequest:mutableReqeust];

    self.sessionTask = [self.session dataTaskWithRequest:self.request];
    [self.sessionTask resume];
}

- (void)stopLoading
{
    [self.sessionTask cancel];
    self.sessionTask = nil;
}


#pragma mark -- NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    self.imgData = [[NSMutableData alloc] init];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [self.imgData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
    didCompleteWithError:(nullable NSError *)error
{
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }
    
    UIImage *webpImg = [UIImage sd_imageWithData:self.imgData];
    NSData *imgData  = UIImageJPEGRepresentation(webpImg, 1);
    
    [self.client URLProtocol:self didLoadData:imgData];
    [self.client URLProtocolDidFinishLoading:self];

}

#pragma mark -- Setter && Getter
- (NSURLSession *)session
{
    if (!_session) {
        
        NSURLSessionConfiguration *sessonConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:sessonConfig delegate:self delegateQueue:nil];
    }
    return _session;
}

@end
