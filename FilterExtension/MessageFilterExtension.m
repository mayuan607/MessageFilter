//
//  MessageFilterExtension.m
//  FilterExtension
//
//  Created by 马远 on 2017/10/1.
//  Copyright © 2017年 马远. All rights reserved.
//

#import "MessageFilterExtension.h"
#import "RegularExpression.h"

@interface MessageFilterExtension () <ILMessageFilterQueryHandling>
@end

@implementation MessageFilterExtension

#pragma mark - ILMessageFilterQueryHandling

- (void)handleQueryRequest:(ILMessageFilterQueryRequest *)queryRequest context:(ILMessageFilterExtensionContext *)context completion:(void (^)(ILMessageFilterQueryResponse *))completion {
    // First, check whether to filter using offline data (if possible).
    ILMessageFilterAction offlineAction = [self offlineActionForQueryRequest:queryRequest];
    
    switch (offlineAction) {
        case ILMessageFilterActionAllow:
        case ILMessageFilterActionFilter: {
            // Based on offline data, we know this message should either be Allowed or Filtered. Send response immediately.
            ILMessageFilterQueryResponse *response = [[ILMessageFilterQueryResponse alloc] init];
            response.action = offlineAction;
            
            completion(response);
            break;
        }
            
        case ILMessageFilterActionNone: {
            // Based on offline data, we do not know whether this message should be Allowed or Filtered. Defer to network.
            // Note: Deferring requests to network requires the extension target's Info.plist to contain a key with a URL to use. See documentation for details.
            [context deferQueryRequestToNetworkWithCompletion:^(ILNetworkResponse *_Nullable networkResponse, NSError *_Nullable error) {
                ILMessageFilterQueryResponse *response = [[ILMessageFilterQueryResponse alloc] init];
                response.action = ILMessageFilterActionNone;
                
                if (networkResponse) {
                    // If we received a network response, parse it to determine an action to return in our response.
                    response.action = [self actionForNetworkResponse:networkResponse];
                } else {
                    NSLog(@"Error deferring query request to network: %@", error);
                }
                
                completion(response);
            }];
            break;
        }
    }
}

- (ILMessageFilterAction)offlineActionForQueryRequest:(ILMessageFilterQueryRequest *)queryRequest {
    

    __block BOOL filter = NO;
    [messageFilterData() enumerateObjectsUsingBlock:^(NSDictionary  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        switch ([[obj objectForKey:@"type"] integerValue]) {
            case 1:
            case 3:
                for (NSString *keyword in [obj objectForKey:@"rules"]) {
                    if (countOfMatchesInString(keyword, queryRequest.messageBody) >= 1 ) {
                        *stop = YES;
                        filter = YES;
                    }
                }
                break;
                
                
            case 2:
            case 4:
                for (NSString *keyword in [obj objectForKey:@"rules"]) {
                    if (countOfMatchesInString(keyword, queryRequest.sender) >= 1 ) {
                        *stop = YES;
                        filter = YES;
                    }
                }
                break;
            default:
                break;
        }
     
    }];
    
    return filter ? ILMessageFilterActionFilter : ILMessageFilterActionNone;

}

- (ILMessageFilterAction)actionForNetworkResponse:(ILNetworkResponse *)networkResponse {
    // Replace with logic to parse the HTTP response and data payload of `networkResponse` to return an action.
    return ILMessageFilterActionNone;
}


@end
