/*
Terminus Est: a Mac GUI for the foma finite-state toolkit and library.
Copyright © 2009-2011 Brian "Moses" Hall
Portions may be copyright © 2008-2009 Mans Hulden

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 or later as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/
#import <Cocoa/Cocoa.h>
#import "StringsPanel.h"
#import "FunctionController.h"

// Menu item tags for machine creation
enum
{
  teMachineUniversalTag,
  teMachineAnyTag,
  teMachineEmptySetTag,
  teMachineEmptyStringTag,
  teMachineIdentityTag
};

// Menu item tags for unary operations
enum
{
  teUnaryMinimizeTag,
  teUnaryDeterminizeTag,
  teUnaryPruneTag,
  teUnaryCompactTag,
  teUnaryReverseTag,
  teUnaryInvertTag,
  teUnaryUpperTag,
  teUnaryLowerTag,
  teUnaryKleeneStarTag,
  teUnaryKleenePlusTag,
  teUnaryOptionalTag
};

// Menu item tags for binary (or n-ary) operations
/*enum
{
  teBinaryAppendTag = 1,
  teBinaryPrependTag,
  teBinaryComposeTag,
  teBinaryCrossTag,
  teBinaryIntersectTag,
  teBinaryUnionTag,
  teBinaryIgnoreTag,
  teBinaryIgnoreInsideTag
};*/

// Menu item tags for view options
enum
{
  teViewNameTag,
  teViewStatesTag,
  teViewFinalsTag,
  teViewEdgesTag,
  teViewPathsTag,
  teViewDetTag,
  teViewEfreeTag,
  teViewEmptyTag,
  teViewFunctionalTag,
  teViewUnambiguousTag,
  teViewIdentityTag,
  teViewUniversalTag,
  teViewStarfreeTag
};

@interface TRTableView : NSTableView
{};
@end


@interface TerminusEstDocument : NSDocument
{
  IBOutlet FunctionController* _fController;
  // Main window
  IBOutlet NSWindow* _docWindow;
  IBOutlet NSTextField* _edit;
  IBOutlet NSTabView* _tabs;
  IBOutlet TRTableView* _table;
  IBOutlet NSPopUpButton* _recentsButton;
  IBOutlet NSPopUpButton* _columnsButton;
  // Define... sheet
  IBOutlet NSPanel* _defineSheet;
  IBOutlet NSFormCell* _defineField;
  // Define Function... sheet
  IBOutlet NSPanel* _defineFSheet;
  IBOutlet NSFormCell* _defineFNameField;
  IBOutlet NSFormCell* _defineFParamsField;
  // Error drawer
  IBOutlet NSDrawer* _errorDrawer;
  IBOutlet NSTextField* _errorDrawerText;
  IBOutlet NSImageView* _errorDrawerIcon;
  // Strings Panel Controller
  IBOutlet StringsPanel* _stringsPanel;
  // Other ivars
  NSMutableArray* _machines;
  NSMutableArray* _recents;
  NSMutableData* _stdout;
}
+(id)columnIDFromViewTag:(NSUInteger)tag;
+(NSUInteger)viewTagFromColumnID:(id)cid;
-(void)handleStdout:(const char*)msg length:(int)len;
-(void)handleStderr:(const char*)msg length:(int)len;
-(IBAction)view:(id)sender;
-(IBAction)columnAction:(id)sender;
-(IBAction)compile:(id)sender;
-(IBAction)clearRecents:(id)sender;
-(IBAction)defineAction:(id)sender;
-(IBAction)defineFAction:(id)sender;
-(IBAction)dupAction:(id)sender;
-(IBAction)exportATTAction:(id)sender;
-(IBAction)importLexcAction:(id)sender;
-(IBAction)insertRecent:(id)sender;
-(IBAction)machineOp:(id)sender;
-(IBAction)selectNextTab:(id)sender;
-(IBAction)selectPreviousTab:(id)sender;
-(IBAction)stringsAction:(id)sender;
-(IBAction)unaryOp:(id)sender;
// Sheets
-(IBAction)acceptSheet:(id)sender;
-(IBAction)cancelSheet:(id)sender;
@end

