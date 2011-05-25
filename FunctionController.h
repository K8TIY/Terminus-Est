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
@class TerminusEstDocument;

@interface TEFunctionTableView : NSTableView
{};
@end

@interface FunctionController : NSObject
{
  IBOutlet TEFunctionTableView* _ftable;
  IBOutlet TerminusEstDocument* _doc;
}
-(void)insertFunction:(NSString*)regex withName:(NSString*)name withParams:(NSString*)params asAction:(BOOL)act;
-(void)delete:(id)sender;
@end
