//
//  TTWebCacheURLProtocol.m
//  TianTianWang
//
//  Created by yitailong on 2016/12/1.
//  Copyright © 2016年 oyxc. All rights reserved.
//

#import "TTWebCacheURLProtocol.h"
#import "UIImage+MultiFormat.h"
#import "SDWebImageDecoder.h"
#import "NSString+hash.h"

static NSString *const TTWebCacheURLProtocolHandledKey = @"TTWebCacheURLProtocolHandledKey";
static NSDictionary *cachePlist;

@interface TTWebCacheURLProtocol ()<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *sessionTask;

@property (nonatomic, strong) NSMutableData *data;

@end

@implementation TTWebCacheURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:TTWebCacheURLProtocolHandledKey inRequest:request]) {
        return NO;
    }
    
    NSString *userAgent = [request allHTTPHeaderFields][@"User-Agent"];
    if (![[userAgent lowercaseString] containsString:@"applewebkit"]) {
        return  NO;
    }
    
    return [self shouldCacheTheURL:request.URL];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:TTWebCacheURLProtocolHandledKey inRequest:mutableReqeust];
    
    NSString *cacheKey = [[self.request.URL absoluteString] md5String];
    NSData *cacheData = [[[self class] cacheManager] objectForKey:cacheKey];
    
    if (cacheData) {
        NSURLResponse *reponse = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:[self.request.URL pathExtension] expectedContentLength:cacheData.length textEncodingName:nil];
        [self.client URLProtocol:self didReceiveResponse:reponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        
        [self.client URLProtocol:self didLoadData:cacheData];
        [self.client URLProtocolDidFinishLoading:self];
    }
    else{
        self.sessionTask = [self.session dataTaskWithRequest:self.request];
        [self.sessionTask resume];
    }
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
    self.data = [[NSMutableData alloc] init];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [self.data appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }
    
    NSData *data;
    NSString* const requestFiletype = [[task.currentRequest.URL pathExtension] lowercaseString];
    if ([requestFiletype isEqualToString:@"webp"]) {
        UIImage *webpImg = [UIImage sd_imageWithData:self.data];
        data  = UIImageJPEGRepresentation(webpImg, 1);
    }
    else{
        data = self.data;
    }
    
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
    
    NSString *cacheKey = [[task.currentRequest.URL absoluteString] md5String];
    [[[self class] cacheManager]  setObject:data forKey:cacheKey block:^(PINCache * _Nonnull cache, NSString * _Nonnull key, id  _Nullable object) {
        
    }];
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


+ (BOOL)shouldCacheTheURL:(NSURL *)url
{
    cachePlist = [[NSDictionary alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TTWebCache" withExtension:@"plist"]];
    NSArray *listOfImgType = cachePlist[@"TTImgCacheType"];
    NSString* const requestFiletype = [[url pathExtension] lowercaseString];

    for (NSString *imgType in listOfImgType) {
        if ([imgType isEqualToString:requestFiletype]) {
            return YES;
        }
    }
    
    NSArray *listOfFileType = cachePlist[@"TTFileCacheType"];
    for (NSString *fileType in listOfFileType) {
        if ([fileType isEqualToString:[url absoluteString]]) {
            return YES;
        }
    }

    return NO;
}

+ (PINCache *)cacheManager
{
    static PINCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[PINCache alloc] initWithName:@"TTWebCahces"];
        cache.memoryCache.costLimit = 4*1024*1024; // 4MB
        cache.diskCache.byteLimit = 32*1024*1024; // 32MB
        cache.diskCache.ageLimit = 60*60*24*7;
    });
    return cache;
}

@end
