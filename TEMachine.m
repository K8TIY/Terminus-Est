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
+(TEMachine*)machineWithRegex:(NSString*)regex name:(NSString*)name
             machines:(NSArray*)machines
{
  TEMachine* m = nil;
  remove_defined(NULL);
  for (TEMachine* machine in machines) 
  {
    struct fsm* fsm = [machine fsm];
    add_defined(fsm_copy(fsm), (char*)[[machine name] UTF8String]);
  }
  const char* txt = [regex UTF8String];
  struct fsm* fsm = fsm_parse_regex((char*)txt);
  if (fsm)
  {
    fsm = fsm_topsort(fsm);
    m = [[[TEMachine alloc] initWithFSM:fsm name:name defined:NO] autorelease];
    fsm_destroy(fsm);
  }
  remove_defined(NULL);
  return m;
}

-(id)initWithFSM:(struct fsm*)fsm name:(NSString*)name defined:(BOOL)def
{
  self = [super init];
  _fsm = fsm_copy(fsm);
  _name = [[NSMutableString alloc] init];
  [self setName:name];
  [self setDefined:def];
  return self;
}

-(void)dealloc
{
  fsm_destroy(_fsm);
  [_name release];
  [super dealloc];
}

-(id)copyWithZone:(NSZone*)zone
{
  return [[TEMachine allocWithZone:zone] initWithFSM:_fsm name:_name defined:_def];
}

-(void)setName:(NSString*)name
{
  if (name) [_name setString:name];
  else [_name setString:@""];
  strncpy(_fsm->name, [_name UTF8String], 39);
}

-(struct fsm*)fsm { return _fsm; }
-(NSString*)name { return _name; }
-(void)setDefined:(BOOL)flag { _def = flag; }
-(BOOL)isDefined { return _def; }
@end
