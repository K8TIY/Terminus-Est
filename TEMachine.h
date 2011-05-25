/*
Terminus Est: a Mac GUI for the foma finite-state toolkit and library.
Copyright © 2009-2011 Brian "Moses" Hall

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/
#import <Cocoa/Cocoa.h>
#import "fomalib.h"
#import "foma.h"

@interface TEMachine : NSObject <NSCopying>
{
  struct fsm*       _fsm;
  NSMutableString*  _name;
}
-(id)initWithFSM:(struct fsm*)fsm name:(NSString*)name defined:(BOOL)def;
-(void)setName:(NSString*)name;
-(struct fsm*)fsm;
-(NSString*)name;
-(void)setDefined:(BOOL)flag;
-(BOOL)isDefined;
@end
