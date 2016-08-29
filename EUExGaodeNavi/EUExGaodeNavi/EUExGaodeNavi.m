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

@interface EUExGaodeNavi()<AMapNaviManagerDelegate,AMapNaviViewControllerDelegate>

@property (nonatomic,weak)AMapNaviManager *manager;
@property (nonatomic,strong)MAMapView *mapView;
@property (nonatomic,strong)AMapNaviViewController *naviController;
@property (nonatomic,assign)BOOL useGPSNavi;
@end


@implementation EUExGaodeNavi




#pragma mark - Life Cycle

- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine{
    self = [super initWithWebViewEngine:engine];
    if (self) {
        
    }
    return self;
}



- (void)clean{
    _mapView = nil;
    _naviController = nil;
    self.manager.delegate = nil;
}

- (void)dealloc{
    [self clean];
    
}

- (MAMapView *)mapView{
    if(!_mapView){
        _mapView = [[MAMapView alloc]init];
    }
    return _mapView;
}

- (AMapNaviViewController *)naviController{
    if(!_naviController){
        _naviController = [[AMapNaviViewController alloc]initWithMapView:self.mapView delegate:self];
    }
    return _naviController;
}

#pragma mark - API

- (void)init:(NSMutableArray *)inArguments{
    
    
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    NSString *appKey = stringArg(info[@"appKey"]);

    if(!appKey || ![appKey isKindOfClass:[NSString class]] || appKey.length == 0){
        appKey=[[NSBundle mainBundle]infoDictionary][@"uexGaodeNaviAppKey"];
    }
    [AMapNaviServices sharedServices].apiKey = appKey;
    [MAMapServices sharedServices].apiKey = appKey;
    
    self.manager = [uexGaodeNaviManager defaultManager].naviManager;
    
    
    NSDictionary *result = @{@"result":@(YES)};
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.cbInit" arguments:ACArgsPack(result.ac_JSONFragment)];
    [cb executeWithArguments:ACArgsPack(result)];
}


- (void)calculateWalkRoute:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    __block BOOL isSuccess = NO;
    @onExit{
        NSDictionary *result = @{@"result":@(isSuccess)};
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.cbCalculateRoute" arguments:ACArgsPack(result.ac_JSONFragment)];
        [cb executeWithArguments:ACArgsPack(result)];

    };
    AMapNaviPoint *endPoint = [self pointFromArray:info[@"endPoint"]];
    if(!endPoint){
        return;
    }
    AMapNaviPoint *startPoint = [self pointFromArray:info[@"startPoint"]];
    if(!startPoint){
        isSuccess = [self.manager calculateWalkRouteWithEndPoints:@[endPoint]];
    }else{
        isSuccess = [self.manager calculateWalkRouteWithStartPoints:@[startPoint] endPoints:@[endPoint]];
    }
}

- (void)calculateDriveRoute:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *cb) = inArguments;
    __block BOOL isSuccess = NO;
    @onExit{
        NSDictionary *result = @{@"result":@(isSuccess)};
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.cbCalculateRoute" arguments:ACArgsPack(result.ac_JSONFragment)];
        [cb executeWithArguments:ACArgsPack(result)];
        
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
            strategy = AMapNaviDrivingStrategySaveMoney;
            break;
        }
        case 2:{
            strategy = AMapNaviDrivingStrategyShortDistance;
            break;
        }
        case 3:{
            strategy = AMapNaviDrivingStrategyNoExpressways;
            break;
        }
        case 4:{
            strategy = AMapNaviDrivingStrategyFastestTime;
            break;
        }
        case 5:{
            strategy = AMapNaviDrivingStrategyAvoidCongestion;
            break;
        }
        default:{
            strategy = AMapNaviDrivingStrategyDefault;
            break;
        }
    }
    if(!startPoints){
        isSuccess = [self.manager calculateDriveRouteWithEndPoints:endPoints wayPoints:wayPoints drivingStrategy:strategy];
    }else{
        isSuccess = [self.manager calculateDriveRouteWithStartPoints:startPoints endPoints:endPoints wayPoints:wayPoints drivingStrategy:strategy];
    }
}

- (void)startNavi:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    self.useGPSNavi = !([info[@"type"] integerValue] == 1);
    self.manager.delegate = self;
    [self.manager presentNaviViewController:self.naviController animated:YES];
}


- (void)stopNavi:(NSMutableArray *)inArguments{
    if(!_naviController){
        return;
    }
    [self.manager stopNavi];
    [self.manager dismissNaviViewControllerAnimated:YES];
}

#pragma mark - Delegate



- (void)naviManager:(AMapNaviManager *)naviManager didPresentNaviViewController:(UIViewController *)naviViewController{
    if(self.useGPSNavi){
        [self.manager startGPSNavi];
    }else{
        [self.manager startEmulatorNavi];
    }
    BOOL iOS9= (ACSystemVersion() >= 9.0);
    NSArray *backgroundModes=[[NSBundle mainBundle]infoDictionary][@"UIBackgroundModes"];
    BOOL requireBackgroundLocationUpdate = backgroundModes && [backgroundModes isKindOfClass:[NSArray class]] && [backgroundModes containsObject:@"location"];
    if (iOS9 && requireBackgroundLocationUpdate) {
        self.manager.allowsBackgroundLocationUpdates = YES;
    }
}
- (void)naviManager:(AMapNaviManager *)naviManager didDismissNaviViewController:(UIViewController *)naviViewController{
    [self clean];
}
- (void)naviViewControllerCloseButtonClicked:(AMapNaviViewController *)naviViewController
{
    
    [self.manager stopNavi];
    [self.manager dismissNaviViewControllerAnimated:YES];
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onNaviCancel" arguments:nil];
}

- (void)naviManager:(AMapNaviManager *)naviManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    [dict setValue:soundString forKey:@"text"];
    [dict setValue:@(soundStringType) forKey:@"type"];
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onGetNavigationText" arguments:ACArgsPack(dict.ac_JSONFragment)];
}

- (void)naviManagerNeedRecalculateRouteForYaw:(AMapNaviManager *)naviManager{
    
    
    
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onReCalculateRouteForYaw" arguments:nil];
}

- (void)naviManager:(AMapNaviManager *)naviManager didStartNavi:(AMapNaviMode)naviMode{
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onStartNavi" arguments:nil];
}
- (void)naviManagerDidEndEmulatorNavi:(AMapNaviManager *)naviManager{
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onArriveDestination" arguments:nil];
}

- (void)naviManagerOnArrivedDestination:(AMapNaviManager *)naviManager{
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexGaodeNavi.onArriveDestination" arguments:nil];
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
