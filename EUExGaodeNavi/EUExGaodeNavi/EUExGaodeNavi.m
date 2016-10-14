/**
 *
 *	@file   	: EUExGaodeNavi.m  in EUExGaodeNavi
 *
 *	@author 	: CeriNo 
 * 
 *	@date   	: Created on 15/12/21.
 *
 *	@copyright 	: 2015 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "EUExGaodeNavi.h"
#import "uexGaodeNaviManager.h"
#import <AppCanKit/ACEXTScope.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
@interface EUExGaodeNavi()<AMapNaviDriveManagerDelegate, AMapNaviDriveViewDelegate,AMapNaviWalkManagerDelegate,AMapNaviWalkViewDelegate,MAMapViewDelegate>

@property (nonatomic,weak) AMapNaviDriveManager *driveManager;
@property (nonatomic, weak) AMapNaviWalkManager *walkManager;
@property (nonatomic, strong) AMapNaviDriveView *driveView;
@property (nonatomic, strong) AMapNaviWalkView *walkView;
@property (nonatomic,assign)BOOL useGPSNavi;
@property (nonatomic,assign)BOOL isWalk;
@end


@implementation EUExGaodeNavi




#pragma mark - Life Cycle

- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine{
    self = [super initWithWebViewEngine:engine];
    if (self) {
        
    }
    return self;
}



- (void)cleanDriveManager{
    self.driveManager.delegate = nil;
    self.driveView.delegate = nil;
    self.driveView = nil;
    
}
- (void)cleanWalkManager{
    self.walkManager.delegate = nil;
    self.walkView.delegate = nil;
    self.walkView = nil;
}


-(AMapNaviDriveView *)driveView{
    if (!_driveView){
        _driveView = [[AMapNaviDriveView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _driveView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _driveView.delegate = self;
    }
    return _driveView;
}
-(AMapNaviWalkView *)walkView{
    if (!_walkView){
        _walkView = [[AMapNaviWalkView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _walkView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _walkView.delegate = self;
    }
    return _walkView;
}


#pragma mark - API

- (void)init:(NSMutableArray *)inArguments{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    ACArgsUnpack(NSDictionary *info) = inArguments;
    ACJSFunctionRef *cb = ac_JSFunctionArg(inArguments.lastObject);
    NSString *appKey = stringArg(info[@"appKey"]);

    if(!appKey || ![appKey isKindOfClass:[NSString class]] || appKey.length == 0){
        appKey=[[NSBundle mainBundle]infoDictionary][@"uexGaodeNaviAppKey"];
    }
    [AMapServices sharedServices].apiKey = appKey;
    NSDictionary *result = @{@"result":@(YES)};
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.cbInit" arguments:ACArgsPack(result.ac_JSONFragment)];
    [cb executeWithArguments:ACArgsPack(kUexNoError)];
}
- (void)statusBarOrientationChange:(NSNotification *)notification
{
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        if (_isWalk) {
            [self.walkView setIsLandscape:NO];
        } else {
            [self.driveView setIsLandscape:NO];
        }
        
       
    }
    else if (UIInterfaceOrientationIsLandscape(orientation))
    {
        if (_isWalk) {
             [self.walkView setIsLandscape:YES];
        } else {
            [self.driveView setIsLandscape:YES];
        }
        
       
    }
}

- (void)calculateWalkRoute:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    self.walkManager = [uexGaodeNaviManager defaultManager].walkManager;
    self.walkManager.delegate = self;
    _isWalk = YES;
    __block BOOL isSuccess = NO;
    @onExit{
        NSDictionary *result = @{@"result":@(isSuccess)};
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.cbCalculateRoute" arguments:ACArgsPack(result.ac_JSONFragment)];
        [cb executeWithArguments:ACArgsPack(isSuccess ? kUexNoError : uexErrorMake(1,@"路径规划失败"))];

    };
    AMapNaviPoint *endPoint = [self pointFromArray:info[@"endPoint"]];
    if(!endPoint){
        return;
    }
    AMapNaviPoint *startPoint = [self pointFromArray:info[@"startPoint"]];
    if(!startPoint){
        isSuccess = [self.walkManager calculateWalkRouteWithEndPoints:@[endPoint]];
    }else{
        isSuccess = [self.walkManager calculateWalkRouteWithStartPoints:@[startPoint] endPoints:@[endPoint]];
    }
    
}

- (void)calculateDriveRoute:(NSMutableArray *)inArguments{
    _isWalk = NO;
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    self.driveManager = [uexGaodeNaviManager defaultManager].driveManager;
    self.driveManager.delegate = self;
    __block BOOL isSuccess = NO;
    @onExit{
        NSDictionary *result = @{@"result":@(isSuccess)};
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.cbCalculateRoute" arguments:ACArgsPack(result.ac_JSONFragment)];
        [cb executeWithArguments:ACArgsPack(isSuccess ? kUexNoError : uexErrorMake(1,@"路径规划失败"))];
    };
    //endPoints
    NSArray *endPoints = [self pointsFromArray:info[@"endPoints"]];
    if(!endPoints){
        AMapNaviPoint *endPoint = [self pointFromArray:info[@"endPoint"]];
        if(!endPoint){
            return;
        }
        endPoints = @[endPoint];
    }
    //startPoints
    NSArray *startPoints = [self pointsFromArray:info[@"startPoints"]];
    if(!startPoints){
        AMapNaviPoint *startPoint = [self pointFromArray:info[@"startPoint"]];
        if(startPoint){
            startPoints = @[startPoint];
        }
        
    }
    //wayPoints
    NSArray *wayPoints = [self pointsFromArray:info[@"wayPoints"]];
    
    //driveMode
    NSInteger driveMode=[info[@"driveMode"] integerValue]?:0;
    AMapNaviDrivingStrategy strategy;
    switch (driveMode) {
        case 1:{
            strategy = AMapNaviDrivingStrategySingleAvoidCost;
            break;
        }
        case 2:{
            strategy = AMapNaviDrivingStrategySinglePrioritiseDistance;
            break;
        }
        case 3:{
            strategy = AMapNaviDrivingStrategySingleAvoidExpressway;
            break;
        }
        case 4:{
            strategy = AMapNaviDrivingStrategySingleAvoidCongestion;
            break;
        }
        case 5:{
            strategy = AMapNaviDrivingStrategySingleAvoidCostAndCongestion;
            break;
        }
        default:{
            strategy = AMapNaviDrivingStrategySingleDefault;
            break;
        }
    }
   
    if(!startPoints){
        isSuccess = [self.driveManager calculateDriveRouteWithEndPoints:endPoints wayPoints:wayPoints drivingStrategy:strategy];
    }else{
        isSuccess = [self.driveManager calculateDriveRouteWithStartPoints:startPoints endPoints:endPoints wayPoints:wayPoints drivingStrategy:strategy];
    }
    
}

- (void)startNavi:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    self.useGPSNavi = !([info[@"type"] integerValue] == 1);
    if (_isWalk) {
        [self.walkManager addDataRepresentative:self.walkView];
        [[self.webViewEngine webView] addSubview:self.walkView];
    } else {
        [self.driveManager addDataRepresentative:self.driveView];
        [[self.webViewEngine webView] addSubview:self.driveView];

    }
    
    
}


- (void)stopNavi:(NSMutableArray *)inArguments{
    if(_isWalk){
        [self.walkManager stopNavi];
        [self.walkManager removeDataRepresentative:self.walkView];
        [self.walkView removeFromSuperview];
        [self cleanWalkManager];
        
    }else{
        [self.driveManager stopNavi];
        [self.driveManager removeDataRepresentative:self.driveView];
        [self.driveView removeFromSuperview];
        [self cleanDriveManager];
    }


    
    
}

#pragma mark - AMapNaviDriveManagerDelegate

- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onCalculateRouteSuccess");
    
    //算路成功后开始GPS导航
    if(self.useGPSNavi){
        [self.driveManager startGPSNavi];
    }else{
        [self.driveManager startEmulatorNavi];
    }
    BOOL iOS9= (ACSystemVersion() >= 9.0);
    NSArray *backgroundModes=[[NSBundle mainBundle]infoDictionary][@"UIBackgroundModes"];
    BOOL requireBackgroundLocationUpdate = backgroundModes && [backgroundModes isKindOfClass:[NSArray class]] && [backgroundModes containsObject:@"location"];
    if (iOS9 && requireBackgroundLocationUpdate) {
        self.driveManager.allowsBackgroundLocationUpdates = YES;
    }

}

- (void)driveManager:(AMapNaviDriveManager *)driveManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    [dict setValue:soundString forKey:@"text"];
    [dict setValue:@(soundStringType) forKey:@"type"];
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onGetNavigationText" arguments:ACArgsPack(dict.ac_JSONFragment)];
}

- (void)driveManagerNeedRecalculateRouteForYaw:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"needRecalculateRouteForYaw");
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onReCalculateRouteForYaw" arguments:nil];
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager didStartNavi:(AMapNaviMode)naviMode
{
    NSLog(@"didStartNavi");
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onStartNavi" arguments:nil];
}

- (void)driveManagerDidEndEmulatorNavi:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"didEndEmulatorNavi");
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onArriveDestination" arguments:nil];
}


- (void)driveManagerOnArrivedDestination:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onArrivedDestination");
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onArriveDestination" arguments:nil];
}
#pragma mark - AMapNaviDriveViewDelegate
- (void)driveViewCloseButtonClicked:(AMapNaviDriveView *)driveView
{
    //停止导航
    [self.driveManager stopNavi];
    [self.driveManager removeDataRepresentative:self.driveView];
    [self.driveView removeFromSuperview];
    [self cleanDriveManager];
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onNaviCancel" arguments:nil];
}
- (void)driveViewMoreButtonClicked:(AMapNaviDriveView *)driveView{
}


#pragma mark - AMapNaviWalkManagerDelegate

- (void)walkManager:(AMapNaviWalkManager *)walkManager error:(NSError *)error
{
    NSLog(@"error:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)walkManagerOnCalculateRouteSuccess:(AMapNaviWalkManager *)walkManager
{
    NSLog(@"onCalculateRouteSuccess");
    //算路成功后开始导航
    if(self.useGPSNavi){
        [self.self.walkManager startGPSNavi];
    }else{
        [self.self.walkManager startEmulatorNavi];
    }
    BOOL iOS9= (ACSystemVersion() >= 9.0);
    NSArray *backgroundModes=[[NSBundle mainBundle]infoDictionary][@"UIBackgroundModes"];
    BOOL requireBackgroundLocationUpdate = backgroundModes && [backgroundModes isKindOfClass:[NSArray class]] && [backgroundModes containsObject:@"location"];
    if (iOS9 && requireBackgroundLocationUpdate) {
        self.walkManager.allowsBackgroundLocationUpdates = YES;
    }
   
    
}

- (void)walkManager:(AMapNaviWalkManager *)walkManager onCalculateRouteFailure:(NSError *)error
{
    NSLog(@"onCalculateRouteFailure:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)walkManager:(AMapNaviWalkManager *)walkManager didStartNavi:(AMapNaviMode)naviMode
{
    NSLog(@"didStartNavi");
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onStartNavi" arguments:nil];
}

- (void)walkManagerNeedRecalculateRouteForYaw:(AMapNaviWalkManager *)walkManager
{
    NSLog(@"needRecalculateRouteForYaw");
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onReCalculateRouteForYaw" arguments:nil];
}

- (void)walkManager:(AMapNaviWalkManager *)walkManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    [dict setValue:soundString forKey:@"text"];
    [dict setValue:@(soundStringType) forKey:@"type"];
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onGetNavigationText" arguments:ACArgsPack(dict.ac_JSONFragment)];
}

- (void)walkManagerDidEndEmulatorNavi:(AMapNaviWalkManager *)walkManager
{
    NSLog(@"didEndEmulatorNavi");
     [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onArriveDestination" arguments:nil];
}

- (void)walkManagerOnArrivedDestination:(AMapNaviWalkManager *)walkManager
{
    NSLog(@"onArrivedDestination");
     [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onArriveDestination" arguments:nil];
}
#pragma mark - AMapNaviWalkViewDelegate
- (void)walkViewCloseButtonClicked:(AMapNaviWalkView *)walkView{
    //停止导航
    [self.walkManager stopNavi];
    [self.walkManager removeDataRepresentative:self.walkView];
    [self.walkView removeFromSuperview];
    [self cleanWalkManager];
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onNaviCancel" arguments:nil];
}

/**
 *  导航界面更多按钮点击时的回调函数
 */
- (void)walkViewMoreButtonClicked:(AMapNaviWalkView *)walkView{
    
}

#pragma mark - Private



- (AMapNaviPoint *)pointFromArray:(NSArray *)array{
    if(!array || ![array isKindOfClass:[NSArray class]]){
        return nil;
    }
    if(array.count < 2){
        return nil;
    }
    return [AMapNaviPoint locationWithLatitude:[array[0] floatValue] longitude:[array[1] floatValue]];
}

- (NSArray<AMapNaviPoint *> *)pointsFromArray:(NSArray *)array{
    if(!array || ![array isKindOfClass:[NSArray class]]){
        return nil;
    }
    NSMutableArray *result = [NSMutableArray array];
    for(NSArray *aPointArray in array){
        AMapNaviPoint *point = [self pointFromArray:aPointArray];
        if(point){
            [result addObject:point];
        }
    }
    return result;
}


@end
