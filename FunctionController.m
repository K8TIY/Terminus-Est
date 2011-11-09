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
#import "FunctionController.h"
#import "TEFunction.h"
#import "foma.h"

extern struct definedf* defines_f;
// Submitted this as a proposed patch to define.c
static int remove_defined_function(const char *string, int numargs);

@interface FunctionController (Private)
-(NSString*)_formatName:(struct definedf*)df;
-(NSString*)_formatRegex:(struct definedf*)df;
-(void)_insertFunction:(TEFunction*)f atIndex:(NSUInteger)idx withActionName:(NSString*)action;
-(struct definedf*)_functionAtIndex:(NSUInteger)idx;
-(void)_deleteFunctionAtIndex:(NSUInteger)i withActionName:(NSString*)action;
@end

@implementation FunctionController
-(NSInteger)numberOfRowsInTableView:(NSTableView*)tv
{
  #pragma unused (tv)
  NSInteger rows = 0;
  struct definedf* df;
  for (df = defines_f; df != NULL; df = df->next) rows++;
  //NSLog(@"%ld rows", rows);
  return rows;
}

-(id)tableView:(NSTableView*)tv objectValueForTableColumn:(NSTableColumn*)col row:(NSInteger)row
{
  #pragma unused (tv)
  id obj = nil;
  NSString* colid = [col identifier];
  struct definedf *df = [self _functionAtIndex:row];
  if (df)
  {
    if ([colid isEqual:@"name"]) obj = [self _formatName:df];
    else if ([colid isEqual:@"numargs"]) obj = [NSString stringWithFormat:@"%d", df->numargs];
    else if ([colid isEqual:@"regex"]) obj = [self _formatRegex:df];
  }
  return obj;
}

-(NSString*)_formatName:(struct definedf*)df
{
  NSMutableString* ms = [[NSMutableString alloc] initWithFormat:@"%s", df->name];
  int i;
  for (i = 1; i <= df->numargs; i++)
  {
    NSMutableString* ns = [[NSMutableString alloc] initWithFormat:@"%d", i];
    NSUInteger j, len = [ns length];
    for (j = 0; j < len; j++)
      [ns replaceCharactersInRange:NSMakeRange(j, 1)
          withString:[NSString stringWithFormat:@"%C", 0x2050 + [ns characterAtIndex:j]]];
    [ms appendFormat:@"%sx%@", (i>1)?",":"", ns];
    [ns release];
  }
  [ms appendString:@")"];
  NSString* ret = [NSString stringWithString:ms];
  [ms release];
  return ret;
}

-(NSString*)_formatRegex:(struct definedf*)df
{
  NSMutableString* ms = [[NSMutableString alloc] initWithFormat:@"%s", df->regex];
  int i;
  for (i = 1; i <= df->numargs; i++)
  {
    NSMutableString* ns = [[NSMutableString alloc] initWithFormat:@"%d", i];
    NSUInteger j, len = [ns length];
    for (j = 0; j < len; j++)
      [ns replaceCharactersInRange:NSMakeRange(j, 1)
          withString:[NSString stringWithFormat:@"%C", 0x2050 + [ns characterAtIndex:j]]];
    NSString* argString = [NSString stringWithFormat:@"@ARGUMENT%.02d@", i];
    [ms replaceOccurrencesOfString:argString withString:[NSString stringWithFormat:@"x%@", ns] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [ms length])];
    [ns release];
  }
  [ms deleteCharactersInRange:NSMakeRange([ms length]-1, 1)];
  NSString* ret = [NSString stringWithString:ms];
  [ms release];
  return ret;
}

-(BOOL)tableView:(NSTableView *)tv shouldEditTableColumn:(NSTableColumn*)col row:(NSInteger)row
{
  #pragma unused (tv,col,row)
  return NO;
}

-(void)insertFunction:(NSString*)regex withName:(NSString*)name withParams:(NSString*)params asAction:(BOOL)act
{
  NSString* fname = [[NSString alloc] initWithFormat:@"%@(", name];
  params = [params stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSArray* parms = [params componentsSeparatedByString:@","];
  NSMutableString* newRegex = [regex mutableCopy];
  unsigned i = 1;
  for (NSString* s in parms)
  {
    NSRange r = NSMakeRange(0, [newRegex length]);
    NSString* pname = [[NSString alloc] initWithFormat:@"@ARGUMENT%.02d@", i];
    [newRegex replaceOccurrencesOfString:s withString:pname options:NSLiteralSearch range:r];
    [pname release];
    i++;
  }
  [newRegex appendString:@";"];
  add_defined_function((char*)[fname UTF8String], (char*)[newRegex UTF8String], (int)[parms count]);
  [newRegex release];
  [fname release];
  [_ftable reloadData];
  [_ftable selectRow:[_ftable numberOfRows]-1 byExtendingSelection:NO];
  [_ftable scrollRowToVisible:i];
  if (act)
  {
    NSString* action = NSLocalizedString(@"__UNDO_ADD_F__",@"Add Function");
    [[[_doc undoManager] prepareWithInvocationTarget:self] _deleteFunctionAtIndex:0 withActionName:action];
    [[_doc undoManager] setActionName:action];
  }
}

-(void)_insertFunction:(TEFunction*)f atIndex:(NSUInteger)idx withActionName:(NSString*)action
{
  add_defined_function((char*)[[f name] UTF8String], (char*)[[f regex] UTF8String], [f numargs]);
  [_ftable reloadData];
  [_ftable selectRow:[_ftable numberOfRows]-1 byExtendingSelection:NO];
  [_ftable scrollRowToVisible:idx];
  [[[_doc undoManager] prepareWithInvocationTarget:self] _deleteFunctionAtIndex:idx withActionName:action];
  [[_doc undoManager] setActionName:action];
}

-(struct definedf*)_functionAtIndex:(NSUInteger)idx
{
  NSUInteger i = 0;
  struct definedf* f = NULL;
  struct definedf* defined;
  for (defined = defines_f; defined != NULL; defined = defined->next,i++)
  {
    if (i == idx)
    {
      f = defined;
      break;
    }
  }
  return defined;
}

-(void)delete:(id)sender
{
  #pragma unused (sender)
  //NSLog(@"delete: %d rows", [_ftable numberOfRows]);
  NSInteger i;
  for (i = [_ftable numberOfRows]; i > 0; i--)
  {
    if ([_ftable isRowSelected:i-1])
    {
      [self _deleteFunctionAtIndex:i-1 withActionName:NSLocalizedString(@"__UNDO_DELETE_F__", @"Delete Function")];
    }
  }
  if ([_ftable selectedRow] == -1)
    [_ftable selectRow:[_ftable numberOfRows]-1 byExtendingSelection:NO];
}

-(void)_deleteFunctionAtIndex:(NSUInteger)i withActionName:(NSString*)action
{
  struct definedf* df = [self _functionAtIndex:i];
  if (df)
  {
    TEFunction* f = [[TEFunction alloc] initWithFunction:df];
    //NSLog(@"undo with %@", f);
    remove_defined_function(df->name, df->numargs);
    [_ftable reloadData];
    [[[_doc undoManager] prepareWithInvocationTarget:self] _insertFunction:f atIndex:i withActionName:action];
    [[_doc undoManager] setActionName:action];
    [f release];
  }
  
}
@end

@implementation TEFunctionTableView
-(void)keyDown:(NSEvent*)event
{
	NSString* characters = [event charactersIgnoringModifiers];
	BOOL handled = NO;
	if ([characters length] == 1)
	{
		unichar	c = [characters characterAtIndex:0];
		if (c == NSDeleteFunctionKey || c == 0x7F)
		{
			handled = YES;
			[[self delegate] delete:self];
		}
	}
	if (!handled) [super keyDown:event];
}
@end

/* Removes a defined function from the list */
/* Returns 0 on success, 1 if the definition did not exist */
static int remove_defined_function(const char *string, int numargs) {
  struct definedf *defined, *defined_prev;
  int exists = 0;
  defined_prev = NULL;
  /* Undefine all */
  if (string == NULL) {
      for (defined = defines_f; defined != NULL; ) {
          xxfree(defined->name);
          xxfree(defined->regex);
          //printf("Undefining %s\n", defined->name);
          defined_prev = defined;
          defined = defined->next;
          xxfree(defined_prev);    
          defines_f = NULL;
      }
      return(0);
  }
  for (defined = defines_f; defined != NULL; defined = defined->next) {
      if (strcmp(defined->name, string) == 0 && defined->numargs == numargs) {
          exists = 1;
          break;
      }
      defined_prev = defined;
  }
  if (exists == 0) {
      return 1;
  }
  if (defined_prev != NULL) {
      defined_prev->next = defined->next;
  } else {
      defines_f = defined->next;
  }
  xxfree(defined->name);
  xxfree(defined->regex);
  xxfree(defined);
  return(0);
}
