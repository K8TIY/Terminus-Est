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
#import "TEMachine.h"

@implementation TEMachine
-(id)initWithFSM:(struct fsm*)fsm name:(NSString*)name defined:(BOOL)def
{
  self = [super init];
  _fsm = fsm_copy(fsm);
  _name = [[NSMutableString alloc] init];
  [self setName:name];
  if (def) add_defined(_fsm, [_name UTF8String]);
  return self;
}

-(void)dealloc
{
  if ([self isDefined]) remove_defined([_name UTF8String]);
  else fsm_destroy(_fsm);
  [_name release];
  [super dealloc];
}

-(id)copyWithZone:(NSZone*)zone
{
  return [[TEMachine allocWithZone:zone] initWithFSM:_fsm name:_name defined:NO];
}

-(void)setName:(NSString*)name
{
  if (name) [_name setString:name];
  else [_name setString:@""];
  strncpy(_fsm->name, [_name UTF8String], 39);
}

-(struct fsm*)fsm { return _fsm; }
-(NSString*)name { return _name; }
-(void)setDefined:(BOOL)flag
{
  if (flag) add_defined(_fsm, [_name UTF8String]);
  else
  {
    struct fsm* cpy = fsm_copy(_fsm);
    remove_defined([_name UTF8String]);
    _fsm = cpy;
  }
}

-(BOOL)isDefined
{
  struct fsm* fsm = find_defined([_name UTF8String]);
  return (fsm && fsm==_fsm);
}
@end
