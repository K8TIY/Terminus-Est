/*
Terminus Est: a Mac GUI for the foma finite-state toolkit and library.
Copyright © 2009-2011 Brian "Moses" Hall

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
#import "StringsPanel.h"
#import "Onizuka.h"

@interface StringsPanel (Private)
-(void)_recalc;
@end


@implementation StringsPanel
-(id)init
{
  self = [super init];
  _strings = [[NSMutableArray alloc] init];
  return self;
}

-(void)awakeFromNib
{
  [[Onizuka sharedOnizuka] localizeWindow:_stringsPanel];
}

-(void)dealloc
{
  [_strings release];
  [super dealloc];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView*)tv
{
  #pragma unused (tv)
  return [_strings count];
}

-(BOOL)validateMenuItem:(NSMenuItem*)item
{
  SEL action = [item action];
  if (action == @selector(copy:))
    return [_strings count];
  return YES;
  //return [super validateMenuItem:item];
}

-(id)tableView:(NSTableView*)tv objectValueForTableColumn:(NSTableColumn*)col row:(NSInteger)row
{
  #pragma unused (tv,col)
  return [_strings objectAtIndex:row];
}

-(BOOL)tableView:(NSTableView*)tv writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
  #pragma unused (tv)
  [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NULL] owner:nil];
  BOOL wrote = NO;
  for (NSString* s in [_strings objectsAtIndexes:rowIndexes])
  {
    [pboard setString:s forType:NSStringPboardType];
    wrote = YES;
  }
  return wrote;
}

-(void)setMachine:(TEMachine*)machine
{
  [machine retain];
  if (_machine) [_machine release];
  _machine = machine;
  [self _recalc];
}

-(IBAction)opAction:(id)sender
{
  #pragma unused (sender)
  [self _recalc];
}

-(void)_recalc
{
  NSInteger op = [[_stringsMenu selectedItem] tag];
  BOOL wasEnabled = [_stringsInput isEnabled];
  BOOL enable = (_machine && (teApplyUpTag == op || teApplyDownTag == op || teApplyMedTag == op));
  [_stringsInput setEnabled:enable];
  if (enable && !wasEnabled) [_stringsPanel makeFirstResponder:_stringsInput];
  [_strings removeAllObjects];
  if (_machine && [self isVisible])
  {
    struct fsm* fsm = [_machine fsm];
    struct apply_handle* ah = NULL;
    struct apply_med_handle* amh = NULL;
    if (op == teApplyMedTag) amh = apply_med_init(fsm);
    else ah = apply_init(fsm);
    char* input = (char*)[[_stringsInput stringValue] UTF8String];
    //NSLog(@"_recalc: op %d input %s", op, input);
    unsigned limit = (op == teApplyMedTag)? 1:[_stringsLimit intValue];
    if (0 == limit) limit = 10;
    unsigned i;
    for (i = 0; i < limit; i++)
    {
      char* result = NULL;
      switch (op)
      {
        case teApplyUpTag:          result = apply_up(ah, (i==0)? input:NULL);  break;
        case teApplyDownTag:        result = apply_down(ah, (i==0)? input:NULL);  break;
        case teApplyUpperWordsTag:  result = apply_upper_words(ah);  break;
        case teApplyLowerWordsTag:  result = apply_lower_words(ah);  break;
        case teApplyWordsTag:       result = apply_words(ah);  break;
        case teApplyRandomUpperTag: result = apply_random_upper(ah);  break;
        case teApplyRandomLowerTag: result = apply_random_lower(ah);  break;
        case teApplyRandomWordsTag: result = apply_random_words(ah);  break;
        case teApplyMedTag:         result = apply_med(amh, input);  break;
      }
      if (!result)
      {
        if (i > 0) break;
        result = "<no result>";
      }
      if (result)
      {
        NSString* nsstr = [NSString stringWithUTF8String:result];
        if (nsstr) [_strings addObject:nsstr];
      }
    }
    if (ah) apply_clear(ah);
    if (amh) apply_med_clear(amh);
  }
  [_stringsTable reloadData];
}

-(BOOL)isVisible { return [_stringsPanel isVisible]; }

-(void)setVisible:(BOOL)flag
{
  if (flag)
  {
    [_stringsPanel makeKeyAndOrderFront:self];
    [self _recalc];
    _suspended = NO;
  }
  else [_stringsPanel orderOut:self];
}

-(void)setSuspended:(BOOL)flag
{
  if (flag)
  {
    if ([_stringsPanel isVisible])
    {
      _suspended = YES;
      [_stringsPanel orderOut:self];
    }
  }
  else
  {
    if (_suspended)
    {
      _suspended = NO;
      [_stringsPanel makeKeyAndOrderFront:self];
      [self _recalc];
      [[_stringsInput window] makeFirstResponder:_stringsInput];
    }
  }
}

-(void)controlTextDidEndEditing:(NSNotification*)note
{
  #pragma unused (note)
  //NSLog(@"controlTextDidEndEditing: %@", note);
  [self _recalc];
}

-(void)controlTextDidChange:(NSNotification*)note
{
  #pragma unused (note)
  //NSLog(@"controlTextDidChange: %@", note);
  [self _recalc];
}
@end
