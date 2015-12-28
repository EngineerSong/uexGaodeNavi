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


@implementation EUExGaodeNavi

#pragma mark - Life Cycle

- (instancetype)initWithBrwView:(EBrowserView *)eInBrwView{
    self=[super initWithBrwView:eInBrwView];
    if(self){
        
    }
    return self;
}

- (void)clean{
    
}

- (void)dealloc{
    [self clean];
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
