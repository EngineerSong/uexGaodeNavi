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
#import "EUtility.h"
#import "JSON.h"
#import "uexGaodeNaviManager.h"


@interface EUExGaodeNavi()<AMapNaviManagerDelegate,AMapNaviViewControllerDelegate>

@property (nonatomic,weak)AMapNaviManager *manager;
@property (nonatomic,strong)MAMapView *mapView;
@property (nonatomic,strong)AMapNaviViewController *naviController;
@property (nonatomic,assign)BOOL useGPSNavi;
@end


@implementation EUExGaodeNavi




#pragma mark - Life Cycle

- (instancetype)initWithBrwView:(EBrowserView *)eInBrwView{
    self=[super initWithBrwView:eInBrwView];
    if(self){
        
    }
    return self;
}

- (void)clean{
    _mapView=nil;
    _naviController=nil;
}

- (void)dealloc{
    [self clean];
}

- (MAMapView *)mapView{
    if(!_mapView){
        _mapView=[[MAMapView alloc]init];
    }
    return _mapView;
}

- (AMapNaviViewController *)naviController{
    if(!_naviController){
        _naviController=[[AMapNaviViewController alloc]initWithMapView:self.mapView delegate:self];
    }
    return _naviController;
}

#pragma mark - API

- (void)init:(NSMutableArray *)inArguments{
    NSString *appKey = [self appKeyFromInit:inArguments];
    if(!appKey || ![appKey isKindOfClass:[NSString class]] || appKey.length == 0){
        appKey=[[NSBundle mainBundle]infoDictionary][@"uexGaodeNaviAppKey"];
    }
    [AMapNaviServices sharedServices].apiKey=appKey;
    [MAMapServices sharedServices].apiKey=appKey;
    self.manager=[uexGaodeNaviManager defaultManager].naviManager;
    self.manager.delegate=self;
    [self callbackJSONWithFunction:@"cbInit" object:@{@"result":@(YES)}];
}


- (void)calculateWalkRoute:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        [self cbCalculateRouteWithResult:NO];
        return;
    }
    id info = [inArguments[0] JSONValue];
    if(!info || ![info isKindOfClass:[NSDictionary class]]){
        [self cbCalculateRouteWithResult:NO];
        return;
    }
    
    AMapNaviPoint *endPoint = [self pointFromArray:info[@"endPoint"]];
    if(!endPoint){
        [self cbCalculateRouteWithResult:NO];
        return;
    }
    AMapNaviPoint *startPoint = [self pointFromArray:info[@"startPoint"]];
    BOOL isSuccess;
    if(!startPoint){
        isSuccess = [self.manager calculateWalkRouteWithEndPoints:@[endPoint]];
    }else{
        isSuccess = [self.manager calculateWalkRouteWithStartPoints:@[startPoint] endPoints:@[endPoint]];
    }
    [self cbCalculateRouteWithResult:isSuccess];
}

- (void)calculateDriveRoute:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        return;
    }
    id info = [inArguments[0] JSONValue];
    if(!info || ![info isKindOfClass:[NSDictionary class]]){
        return;
    }
    //endPoints
    NSArray *endPoints=[info[@"endPoints"] isKindOfClass:[NSArray class]]?[self pointsFromArray:info[@"endPoints"]]:nil;
    if(!endPoints){
        AMapNaviPoint *endPoint = [self pointFromArray:info[@"endPoint"]];
        if(!endPoint){
            [self cbCalculateRouteWithResult:NO];
            return;
        }
        endPoints=@[endPoint];
    }
    //startPoints
    NSArray *startPoints=[info[@"startPoints"] isKindOfClass:[NSArray class]]?[self pointsFromArray:info[@"startPoints"]]:nil;
    if(!startPoints){
        AMapNaviPoint *startPoint = [self pointFromArray:info[@"startPoint"]];
        if(startPoint){
            startPoints=@[startPoint];
        }
        
    }
    //wayPoints
    NSArray *wayPoints=[info[@"wayPoints"] isKindOfClass:[NSArray class]]?[self pointsFromArray:info[@"wayPoints"]]:nil;
    
    //driveMode
    NSInteger driveMode=[info[@"driveMode"] integerValue]?:0;
    AMapNaviDrivingStrategy strategy;
    switch (driveMode) {
        case 1:{
            strategy=AMapNaviDrivingStrategySaveMoney;
            break;
        }
        case 2:{
            strategy=AMapNaviDrivingStrategyShortDistance;
            break;
        }
        case 3:{
            strategy=AMapNaviDrivingStrategyNoExpressways;
            break;
        }
        case 4:{
            strategy=AMapNaviDrivingStrategyFastestTime;
            break;
        }
        case 5:{
            strategy=AMapNaviDrivingStrategyAvoidCongestion;
            break;
        }
        default:{
            strategy=AMapNaviDrivingStrategyDefault;
            break;
        }
    }
    
    
    BOOL isSuccess;
    if(!startPoints){
        isSuccess = [self.manager calculateDriveRouteWithEndPoints:endPoints wayPoints:wayPoints drivingStrategy:strategy];
    }else{
        isSuccess = [self.manager calculateDriveRouteWithStartPoints:startPoints endPoints:endPoints wayPoints:wayPoints drivingStrategy:strategy];
    }
    [self cbCalculateRouteWithResult:isSuccess];

}

- (void)startNavi:(NSMutableArray *)inArguments{
    self.useGPSNavi=YES;
    if(inArguments.count>0){
        id info=[inArguments[0] JSONValue];
        if (info && [info isKindOfClass:[NSDictionary class]] && info[@"type"]){
            self.useGPSNavi=!([info[@"type"] integerValue] == 1);
        }
    }
    //[EUtility brwView:self.meBrwView presentModalViewController:self.naviController animated:YES];
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
    BOOL iOS9=[[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0;
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
    [self callbackJSONWithFunction:@"onNaviCancel" object:nil];
}

- (void)naviManager:(AMapNaviManager *)naviManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSMutableDictionary *dict=[NSMutableDictionary dictionary];
    [dict setValue:soundString forKey:@"text"];
    [dict setValue:@(soundStringType) forKey:@"type"];
    [self callbackJSONWithFunction:@"onGetNavigationText" object:dict];

}

- (void)naviManagerNeedRecalculateRouteForYaw:(AMapNaviManager *)naviManager{
    [self callbackJSONWithFunction:@"onReCalculateRouteForYaw" object:nil];
}

- (void)naviManager:(AMapNaviManager *)naviManager didStartNavi:(AMapNaviMode)naviMode{
    [self callbackJSONWithFunction:@"onStartNavi" object:nil];
}
- (void)naviManagerDidEndEmulatorNavi:(AMapNaviManager *)naviManager{
    [self callbackJSONWithFunction:@"onArriveDestination" object:nil];
}

- (void)naviManagerOnArrivedDestination:(AMapNaviManager *)naviManager{
    [self callbackJSONWithFunction:@"onArriveDestination" object:nil];
}
#pragma mark - Private




- (void)cbCalculateRouteWithResult:(BOOL)isSuccess{
    [self callbackJSONWithFunction:@"cbCalculateRoute" object:@{@"result":@(isSuccess)}];
}


- (NSString *)appKeyFromInit:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        return nil;
    }
    id info = [inArguments[0] JSONValue];
    if(!info || ![info isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    return info[@"appKey"];
}



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
    NSMutableArray *result=[NSMutableArray array];
    for(NSArray *aPointArray in array){
        AMapNaviPoint *point=[self pointFromArray:aPointArray];
        if(point){
            [result addObject:point];
        }
    }
    return result;
}

#pragma mark - JSON Callback

- (void)callbackJSONWithFunction:(NSString *)functionName object:(id)object{
    [EUtility uexPlugin:@"uexGaodeNavi"
         callbackByName:functionName
             withObject:object
                andType:uexPluginCallbackWithJsonString
               inTarget:self.meBrwView];
}

@end
