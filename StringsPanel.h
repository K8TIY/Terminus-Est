/*
Terminus Est: a Mac GUI for the foma finite-state toolkit and library.
Copyright © 2009-2010 Brian "Moses" Hall

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
#import "TEMachine.h"

// Menu item tags for application
enum
{
  teApplyUpTag,
  teApplyDownTag,
  teApplyUpperWordsTag,
  teApplyLowerWordsTag,
  teApplyWordsTag,
  teApplyRandomUpperTag,
  teApplyRandomLowerTag,
  teApplyRandomWordsTag,
  teApplyMedTag
};

@interface StringsPanel : NSObject
{
  NSMutableArray* _strings;
  IBOutlet NSTableView* _stringsTable;
  IBOutlet NSPanel* _stringsPanel;
  IBOutlet NSTextField* _stringsInput;
  IBOutlet NSFormCell* _stringsLimit;
  IBOutlet NSPopUpButton* _stringsMenu;
  TEMachine* _machine;
  BOOL _suspended;
}
-(IBAction)opAction:(id)sender;
-(void)setMachine:(TEMachine*)machine;
-(BOOL)isVisible;
-(void)setVisible:(BOOL)flag;
-(void)setSuspended:(BOOL)flag;
@end
