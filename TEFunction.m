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
#import "TEFunction.h"


@implementation TEFunction
@synthesize name = _name;
@synthesize regex = _regex;
@synthesize numargs = _numargs;
-(id)init
{
  self = [super init];
  _name = [[NSString alloc] init];
  _regex = [[NSString alloc] init];
  return self;
}

-(id)initWithFunction:(struct definedf*)f
{
  self = [super init];
  _name = [[NSString alloc] initWithCString:f->name encoding:NSUTF8StringEncoding];
  _regex = [[NSString alloc] initWithCString:f->regex encoding:NSUTF8StringEncoding];
  _numargs = f->numargs;
  return self;
}

/*-(id)copyWithZone:(NSZone*)z

{
  TEFunction* f = [[TEFunction allocWithZone:z] init];
  [f setName:_name];
  [f setRegex:_regex];
  [f setNumargs:_numargs];
  return f;
}*/

-(void)dealloc
{
  [_name release];
  [_regex release];
  [super dealloc];
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"<%@ %@%@ (%d args)>", [self class], _name, _regex, _numargs];
}

-(void)encodeWithCoder:(NSCoder*)coder
{
  [coder encodeObject:_name forKey:@"name"];
  [coder encodeObject:_regex forKey:@"regex"];
  [coder encodeInt:_numargs forKey:@"numargs"];
}

-(id)initWithCoder:(NSCoder*)coder
{
  _name = [coder decodeObjectForKey:@"name"];
  _regex = [coder decodeObjectForKey:@"regex"];
  _numargs = [coder decodeIntForKey:@"numargs"];
  return self;
}
@end
