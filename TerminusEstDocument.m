/*
Terminus Est: a Mac GUI for the foma finite-state toolkit and library.
Copyright © 2009-2011 Brian "Moses" Hall
Portions © 2008-2010 Mans Hulden

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
#import "Onizuka.h"
#import "TerminusEstDocument.h"

#import <zlib.h>
#import "StringsPanel.h"
#import "foma.h"

extern struct io_buf_handle *io_init();
extern size_t io_gz_file_to_mem(struct io_buf_handle *iobh, char *filename);
extern struct fsm *io_net_read(struct io_buf_handle *iobh, char **net_name);
extern void io_free(struct io_buf_handle *iobh);
// FIXME: print_dot is static so we reproduce it here.
static int TE_print_dot(struct fsm *net, char *filename);
static char *TE_sigptr(struct sigma *sigma, int number);

static NSString* const TEMachineListRows = @"TEMachineListRows";
extern int foma_net_print(struct fsm *net, gzFile *outfile);
extern struct definedf  *defines_f;

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
typedef NSUInteger NSPropertyListWriteOptions;
@interface NSPropertyListSerialization (SnowLeopardAdditions)
+(NSData*)dataWithPropertyList:(id)plist format:(NSPropertyListFormat)format
          options:(NSPropertyListWriteOptions)opt error:(NSError**)error;
@end
#endif

@interface TerminusEstDocument (TerminusEstPrivate)
+(NSArray*)columnIDs;
-(NSString*)createAndOpenTempFile:(int*)oFile;
-(NSString*)_retrieveStdout;
-(void)_compile:(NSString*)regex defined:(NSString*)name asAction:(BOOL)act;
-(void)_insertMachine:(TEMachine*)m atIndex:(NSUInteger)i withActionName:(NSString*)action defining:(BOOL)def;
-(void)_replaceMachineAtIndex:(NSUInteger)i withMachine:(TEMachine*)m withActionName:(NSString*)action;
-(void)_deleteMachineAtIndex:(NSUInteger)i withActionName:(NSString*)action;
-(void)_renameMachineAtIndex:(NSUInteger)i toName:(NSString*)name withActionName:(NSString*)action defining:(BOOL)def;
-(void)_undefineDuplicatesOfMachine:(TEMachine*)m;
-(void)_readLexc:(NSString*)file;
-(void)_sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)code contextInfo:(void*)contextInfo;
-(void)_exportPanelDidEnd:(NSSavePanel*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)ctx;
-(void)_importPanelDidEnd:(NSSavePanel*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)ctx;
-(void)_alertDidEnd:(NSAlert*)alert returnCode:(int)code contextInfo:(void*)ctx;
-(NSMutableAttributedString*)_check;
-(NSMutableAttributedString*)_question;
-(NSString*)_infinity;
-(NSUInteger)_moveRows:(NSArray*)array to:(NSUInteger)destination copying:(BOOL)copy;
@end

@implementation TerminusEstDocument
static NSDictionary* gViewTagToColumnID = nil;
static NSDictionary* gColumnIDToViewTag = nil;
+(void)initialize
{
  /*
  #define kUGMargin (10.0)
  #define kUGHeight (256.0)
  NSString* path = [[NSBundle mainBundle] pathForResource:@"syms" ofType:@"plist"];
  NSArray* data = [[NSArray alloc] initWithContentsOfFile:path];
  //NSLog(@"%@", data);
  double width = 0.7*kUGHeight;
  CGRect imgRect = CGRectMake(0, 0, width+(2.0*kUGMargin), kUGHeight+(2.0*kUGMargin));
  NSURL* url = [NSURL fileURLWithPath:@"/Symbols.pdf"];
  CGContextRef ctx = CGPDFContextCreateWithURL((CFURLRef)url, &imgRect, nil);
  PDFImageMapCreator* creator = [[PDFImageMapCreator alloc] initWithContext:ctx rect:imgRect data:data];
  [creator setPreferredFont:@"Times New Roman"];
  [creator makeImageMapWithTitle:@"user"];
  NSLog(@"%@", [creator xml]);
  [creator release];
  CGContextRelease(ctx);*/
  gViewTagToColumnID = [[NSDictionary alloc] initWithObjectsAndKeys:@"name", [NSNumber numberWithInteger:teViewNameTag],
                                             @"states", [NSNumber numberWithInteger:teViewStatesTag],
                                             @"finals", [NSNumber numberWithInteger:teViewFinalsTag],
                                             @"edges", [NSNumber numberWithInteger:teViewEdgesTag],
                                             @"paths", [NSNumber numberWithInteger:teViewPathsTag],
                                             @"deterministic", [NSNumber numberWithInteger:teViewDetTag],
                                             @"efree", [NSNumber numberWithInteger:teViewEfreeTag],
                                             @"empty", [NSNumber numberWithInteger:teViewEmptyTag],
                                             @"functional", [NSNumber numberWithInteger:teViewFunctionalTag],
                                             @"unambiguous", [NSNumber numberWithInteger:teViewUnambiguousTag],
                                             @"identity", [NSNumber numberWithInteger:teViewIdentityTag],
                                             @"universal", [NSNumber numberWithInteger:teViewUniversalTag],
                                             @"starfree", [NSNumber numberWithInteger:teViewStarfreeTag],
                                             NULL];
  gColumnIDToViewTag = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:teViewNameTag], @"name",
                                             [NSNumber numberWithInteger:teViewStatesTag], @"states",
                                             [NSNumber numberWithInteger:teViewFinalsTag], @"finals",
                                             [NSNumber numberWithInteger:teViewEdgesTag], @"edges",
                                             [NSNumber numberWithInteger:teViewPathsTag], @"paths",
                                             [NSNumber numberWithInteger:teViewDetTag], @"deterministic", 
                                             [NSNumber numberWithInteger:teViewEfreeTag], @"efree",
                                             [NSNumber numberWithInteger:teViewEmptyTag], @"empty",
                                             [NSNumber numberWithInteger:teViewFunctionalTag], @"functional",
                                             [NSNumber numberWithInteger:teViewUnambiguousTag], @"unambiguous",
                                             [NSNumber numberWithInteger:teViewIdentityTag], @"identity",
                                             [NSNumber numberWithInteger:teViewUniversalTag], @"universal",
                                             [NSNumber numberWithInteger:teViewStarfreeTag], @"starfree",
                                             NULL];
  //NSColor* red = [NSColor colorWithCalibratedRed:0.67f green:0.0f blue:0.0f alpha:1.0f];
  //NSData* dat = [NSArchiver archivedDataWithRootObject:red];
  //NSLog(@"%@", dat);
}


+(id)columnIDFromViewTag:(NSUInteger)tag
{
  return [gViewTagToColumnID objectForKey:[NSNumber numberWithInteger:tag]];
}

+(NSUInteger)viewTagFromColumnID:(id)cid
{
  return [[gColumnIDToViewTag objectForKey:cid] intValue];
}

+(NSArray*)columnIDs
{
  static NSArray* ids = nil;
  if (!ids) ids = [[NSArray alloc] initWithObjects:@"name", @"states", @"finals", @"edges", @"paths", @"deterministic", @"efree", @"empty",
                                                   @"functional", @"unambiguous", @"identity", @"universal", @"starfree", NULL];
  return ids;
}


-(NSString*)windowNibName { return @"TerminusEstDocument"; }

-(void)dealloc
{
  if (_machines) [_machines release];
  if (_stdout) [_stdout release];
  [super dealloc];
}

-(void)windowControllerDidLoadNib:(NSWindowController*)controller
{
  [super windowControllerDidLoadNib:controller];
  [_table registerForDraggedTypes:[NSArray arrayWithObjects:TEMachineListRows, nil]];
  // Can't seem to set the height < 200 in IB (IB bug?), so do it here.
  [_errorDrawer setContentSize:NSMakeSize(200.0f,60.0f)];
  [self handleStderr:nil length:0];
  if (!_machines) _machines = [[NSMutableArray alloc] init];
  if (!_stdout) _stdout = [[NSMutableData alloc] init];
  [[Onizuka sharedOnizuka] localizeWindow:_docWindow];
  [[Onizuka sharedOnizuka] localizeWindow:_defineSheet];
  [[Onizuka sharedOnizuka] localizeWindow:_defineFSheet];
  [[_recentsButton cell] setUsesItemFromMenu:NO];
  [[_columnsButton cell] setUsesItemFromMenu:NO];
  for (NSString* cid in [TerminusEstDocument columnIDs])
  {
    BOOL vis = [[NSUserDefaults standardUserDefaults] boolForKey:cid];
    [[_table tableColumnWithIdentifier:cid] setHidden:!vis];
    NSInteger tag = [TerminusEstDocument viewTagFromColumnID:cid];
    NSInteger where = [[_columnsButton menu] indexOfItemWithTag:tag];
    NSMenuItem* item = [[_columnsButton menu] itemAtIndex:where];
    [item setState:vis];
  }
  if (_recents)
  {
    NSMenu* menu = [_recentsButton menu];
    for (NSString* regex in _recents)
    {
      (void)[menu insertItemWithTitle:regex action:@selector(insertRecent:) keyEquivalent:@"" atIndex:[menu numberOfItems]];
    }
    [_recents release];
    _recents = nil;
    [_recentsButton setEnabled:YES];
  }
}

-(void)windowDidResignMain:(NSNotification*)note
{
  #pragma unused (note)
  [_stringsPanel setSuspended:YES];
}

-(void)windowDidBecomeMain:(NSNotification*)note
{
  #pragma unused (note)
  [_stringsPanel setSuspended:NO];
}

-(BOOL)validateMenuItem:(NSMenuItem*)item
{
  SEL action = [item action];
  if (action == @selector(view:) ||
      action == @selector(exportATTAction:) ||
      action == @selector(unaryOp:) ||
      action == @selector(dupAction:))
  {
    NSInteger nSel = [_table numberOfSelectedRows];
    return ([[[_tabs selectedTabViewItem] identifier] isEqual:@"Machines"] && nSel == 1);
  }
  if (action == @selector(compile:) ||
      action == @selector(defineAction:) ||
      action == @selector(defineFAction:)) return ([[_edit stringValue] length] > 0);
  if (action == @selector(stringsAction:))
  {
    [item setTag:[_stringsPanel isVisible]];
    [[Onizuka sharedOnizuka] localizeObject:item withTitle:([item tag])? @"__HIDE_STRINGS__":@"__SHOW_STRINGS__"];
    return YES;
  }
  if (action == @selector(selectNextTab:)) return ([_tabs indexOfTabViewItem:[_tabs selectedTabViewItem]]+1 < [_tabs numberOfTabViewItems]);
  if (action == @selector(selectPreviousTab:)) return ([_tabs indexOfTabViewItem:[_tabs selectedTabViewItem]] > 0);
  return [super validateMenuItem:item];
}

-(NSFileWrapper*)fileWrapperOfType:(NSString*)type error:(NSError**)oError
{
  NSFileWrapper* wrapper = nil;
  int err = 0;
  if (oError) *oError = nil;
  if ([type isEqualToString:@"Terminus Est Document"])
  {
    wrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    int fd;
    NSString* tempfile = [self createAndOpenTempFile:&fd];
    close(fd);
    gzFile* f = gzopen([tempfile UTF8String], "ab");
    NSUInteger i, n = [_machines count];
    NSMutableArray* defs = [[NSMutableArray alloc] init];
    for (i = 0; i < n; i++)
    {
      TEMachine* m = [_machines objectAtIndex:i];
      (void)foma_net_print([m fsm], f);
      if (m.defined) [defs addObject:[NSNumber numberWithInteger:i]];
    }
    gzclose(f);
    NSData* data = [[NSData alloc] initWithContentsOfFile:tempfile];
    (void)[wrapper addRegularFileWithContents:data preferredFilename:@"stack.gz"];
    [data release];
    if ([defs count])
    {
      if ([NSPropertyListSerialization respondsToSelector:@selector(dataWithPropertyList:format:options:error:)])
        data = [NSPropertyListSerialization dataWithPropertyList:defs format:NSPropertyListXMLFormat_v1_0 options:0 error:oError];
      else
      {
        NSString* errStr = nil;
        data = [NSPropertyListSerialization dataFromPropertyList:defs format:NSPropertyListXMLFormat_v1_0 errorDescription:&errStr];
        if (errStr && oError)
        {
          NSDictionary *errUI = [NSDictionary dictionaryWithObjectsAndKeys:errStr, NSLocalizedDescriptionKey, nil];
          *oError = [NSError errorWithDomain:@"TerminusEstErrorDomain" code:-1 userInfo:errUI];
          [errStr release];
        }
      }
      (void)[wrapper addRegularFileWithContents:data preferredFilename:@"defs.plist"];
    }
    [defs release];
    if (_recents) [_recents removeAllObjects];
    else _recents = [[NSMutableArray alloc] init];
    n = [[_recentsButton menu] numberOfItems];
    for (i = 2; i < n; i++)
    {
      [_recents addObject:[[[_recentsButton menu] itemAtIndex:i] title]];
    }
    if ([_recents count])
    {
      if ([NSPropertyListSerialization respondsToSelector:@selector(dataWithPropertyList:format:options:error:)])
        data = [NSPropertyListSerialization dataWithPropertyList:_recents format:NSPropertyListXMLFormat_v1_0 options:0 error:oError];
      else
      {
        NSString* errStr = nil;
        data = [NSPropertyListSerialization dataFromPropertyList:_recents format:NSPropertyListXMLFormat_v1_0 errorDescription:&errStr];
        if (errStr && oError)
        {
          NSDictionary *errUI = [NSDictionary dictionaryWithObjectsAndKeys:errStr, NSLocalizedDescriptionKey, nil];
          *oError = [NSError errorWithDomain:@"TerminusEstErrorDomain" code:-1 userInfo:errUI];
          [errStr release];
        }
      }
      (void)[wrapper addRegularFileWithContents:data preferredFilename:@"recents.plist"];
    }
    [_recents release];
    _recents = nil;
    struct definedf *df;
    NSMutableArray* fdefs = [[NSMutableArray alloc] init];
    for (df = defines_f; NULL != df; df = df->next)
    {
      NSString* dfname = [[NSString alloc] initWithCString:df->name encoding:NSUTF8StringEncoding];
      NSString* dfregex = [[NSString alloc] initWithCString:df->regex encoding:NSUTF8StringEncoding];
      NSString* dfnargs = [[NSNumber alloc] initWithInt:df->numargs];
      [fdefs addObject:[NSDictionary dictionaryWithObjectsAndKeys:dfname, @"name", dfregex, @"regex", dfnargs, @"numargs", NULL]];
      [dfname release];
      [dfregex release];
      [dfnargs release];
    }
    if ([fdefs count])
    {
      if ([NSPropertyListSerialization respondsToSelector:@selector(dataWithPropertyList:format:options:error:)])
        data = [NSPropertyListSerialization dataWithPropertyList:fdefs format:NSPropertyListXMLFormat_v1_0 options:0 error:oError];
      else
      {
        NSString* errStr = nil;
        data = [NSPropertyListSerialization dataFromPropertyList:fdefs format:NSPropertyListXMLFormat_v1_0 errorDescription:&errStr];
        if (errStr && oError)
        {
          NSDictionary *errUI = [NSDictionary dictionaryWithObjectsAndKeys:errStr, NSLocalizedDescriptionKey, nil];
          *oError = [NSError errorWithDomain:@"TerminusEstErrorDomain" code:-1 userInfo:errUI];
          [errStr release];
        }
      }
      (void)[wrapper addRegularFileWithContents:data preferredFilename:@"fdefs.plist"];
    }
    [fdefs release];
  }
  else if ([type isEqualToString:@"foma Prolog Document"])
  {
    NSMutableString* contents = [[NSMutableString alloc] init];
    for (TEMachine* m in _machines)
    {
      write_prolog([m fsm], NULL);
      NSString* asns = [self _retrieveStdout];
      [contents appendString:asns];
    }
    if (!err)
    {
      wrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:[contents dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [contents release];
  }
  else err = -1;
  if (err && oError && !*oError)
  {
    *oError = [[[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:err userInfo:nil] autorelease];
  }
  return [wrapper autorelease];
}

-(NSString*)createAndOpenTempFile:(int*)oFile
{
  NSString* tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"terminus_est_temp.XXXXXX"];
  const char* tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
  char* tempFileNameCString = (char*)malloc(strlen(tempFileTemplateCString) + 1);
  strcpy(tempFileNameCString, tempFileTemplateCString);
  *oFile = mkstemp(tempFileNameCString);
  if (*oFile == -1) return nil;
  // This is the file name if you need to access the file by name, otherwise
  // you can remove this line.
  NSString* tempFileName = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
  free(tempFileNameCString);
  return tempFileName;
}


-(BOOL)revertToContentsOfURL:(NSURL*)url ofType:(NSString*)type error:(NSError**)oError
{
  NSArray* saved = [_machines copy];
  [_machines removeAllObjects];
  NSFileWrapper* wrapper = [[NSFileWrapper alloc] initWithPath:[url path]];
  BOOL ok = [self readFromFileWrapper:wrapper ofType:type error:oError];
  [wrapper release];
  if (!ok) [_machines setArray:saved];
  [saved release];
  [_table reloadData];
  [self updateChangeCount:NSChangeCleared];
  [self tableViewSelectionDidChange:nil]; // Well, the machine may have changed anyway.
  return ok;
}

-(BOOL)readFromFileWrapper:(NSFileWrapper*)wrapper ofType:(NSString*)type error:(NSError**)oError
{
  #pragma unused (wrapper)
  int err = 0;
  struct fsm* net;
  TEMachine* m;
  NSString* name = nil;
  if (!_machines) _machines = [[NSMutableArray alloc] init];
  if ([type isEqualToString:@"__TE_DOC__"])
  {
    NSString* path = [[self fileName] stringByAppendingPathComponent:@"stack.gz"];
    //NSLog(@"Reading %@", path);
    char* net_name = NULL;
    struct io_buf_handle* bh = io_init();
    if (io_gz_file_to_mem(bh, (char*)[path UTF8String]) > 0)
    {
      while (NULL != (net = io_net_read(bh, &net_name)))
      {
        if (NULL == net_name || NULL == net)
        {
          err = (errno)? errno:-1;
          goto Bail;
        }
        name = [[NSString alloc] initWithCString:net_name encoding:NSUTF8StringEncoding];
        m = [[TEMachine alloc] initWithFSM:net name:name defined:NO];
        [name release];
        [_machines addObject:m];
        [m release];
        fsm_destroy(net);
        if (net_name) free(net_name);
        net_name = NULL;
      }
    }
    io_free(bh);
    path = [[self fileName] stringByAppendingPathComponent:@"defs.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
      NSArray* defs = [[NSArray alloc] initWithContentsOfFile:path];
      for (NSNumber* num in defs)
        [[_machines objectAtIndex:[num integerValue]] setDefined:YES];
      [defs release];
    }
    // See if the document has a regex history associated with it.
    path = [[self fileName] stringByAppendingPathComponent:@"recents.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
      _recents = [[NSArray alloc] initWithContentsOfFile:path];
    }
    path = [[self fileName] stringByAppendingPathComponent:@"fdefs.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
      NSArray* fdefs = [[NSArray alloc] initWithContentsOfFile:path];
      for (NSDictionary* d in fdefs)
      {
        add_defined_function((char*)[[d objectForKey:@"name"] UTF8String],
                             (char*)[[d objectForKey:@"regex"] UTF8String],
                             [[d objectForKey:@"numargs"] intValue]);
      }
      [fdefs release];
    }
  }
  else if ([type isEqualToString:@"__P_DOC__"])
  {
    // FIXME: when foma supports fsm_read_prolog on a FILE*, this needs rewritten.
    /*FILE* prologFile = fopen([[self fileName] UTF8String], "r");
    if (NULL == prologFile)
    {
      err = errno;
      goto Bail;
    }
    while (NULL != (net = fsm_read_prolog(prologFile)))
    {
      m = [[TEMachine alloc] initWithFSM:net name:[NSString stringWithCString:net->name] defined:NO];
      [_machines addObject:m];
      [m release];
      fsm_destroy(net);
    }
    fclose(prologFile);*/
    net = fsm_read_prolog((char*)[[self fileName] UTF8String]);
    NSString* mname = [NSString stringWithCString:net->name encoding:NSUTF8StringEncoding];
    m = [[TEMachine alloc] initWithFSM:net name:mname defined:NO];
    [_machines addObject:m];
    [m release];
    fsm_destroy(net);
    if (0 == [_machines count]) err = -1;
  }
  else if ([type isEqualToString:@"__RE_DOC__"])
  {
    NSString* content = [[NSString alloc] initWithContentsOfFile:[self fileName] encoding:NSUTF8StringEncoding error:oError];
    if (!content) return NO;
    NSScanner* scanner = [NSScanner scannerWithString:content];
    [content release];
    NSString* line;
    while (![scanner isAtEnd])
    {
      [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&line];
      
      NSString* trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      //NSLog(@"Read '%@' trimmed '%@'\n", line, trimmed);
      NSString* cmd = nil;
      NSString* regex = nil;
      NSScanner* scanner2 = [NSScanner scannerWithString:trimmed];
      [scanner2 scanUpToCharactersFromSet:
               [NSCharacterSet whitespaceAndNewlineCharacterSet] 
               intoString:&cmd];
      if ([cmd isEqualToString:@"def"])
      {
        [scanner2 scanUpToCharactersFromSet:
                 [NSCharacterSet whitespaceAndNewlineCharacterSet] 
                 intoString:&name];
      }
      //NSLog(@"command '%@' name '%@' regex '%@'", cmd, name, regex);
      regex = [trimmed substringFromIndex:[scanner2 scanLocation]];
      [self _compile:regex defined:name asAction:NO];
      cmd = name = regex = nil;
    }
  }
  else if ([type isEqualToString:@"__L_DOC__"])
  {
    [self _readLexc:[self fileName]];
  }
  else err = -1;
Bail:
  if (err && oError)
  {
    *oError = [[[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:err userInfo:nil] autorelease];
  }
  return (err == 0);
}


#pragma mark Actions
-(IBAction)columnAction:(id)sender
{
  NSInteger tag = [sender tag];
  NSInteger state = [sender state];
  [sender setState:!state];
  id identifier = [TerminusEstDocument columnIDFromViewTag:tag];
  [[_table tableColumnWithIdentifier:(id)identifier] setHidden:state];
}

-(IBAction)compile:(id)sender
{
  // If sender is the text field, compile or define function as appropriate to the tab
  if (sender == _edit && [[[_tabs selectedTabViewItem] identifier] isEqual:@"Functions"])
    [NSApp beginSheet:_defineFSheet modalForWindow:_docWindow modalDelegate:self
           didEndSelector:@selector(_sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
  else [self _compile:[_edit stringValue] defined:nil asAction:YES];
}

-(IBAction)copyPrologAction:(id)sender
{
  #pragma unused (sender)
  NSInteger i = [_table selectedRow];
  if (i >= 0)
  {
    TEMachine* m = [_machines objectAtIndex:i];
    write_prolog([m fsm], NULL);
    NSString* prolog = [self _retrieveStdout];
    NSPasteboard* pb = [NSPasteboard generalPasteboard];
    [pb declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NULL] owner:self];
    [pb setString:prolog forType:NSStringPboardType];
  }
}

-(IBAction)defineAction:(id)sender
{
  #pragma unused (sender)
  [NSApp beginSheet:_defineSheet modalForWindow:_docWindow modalDelegate:self
         didEndSelector:@selector(_sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(IBAction)defineFAction:(id)sender
{
  #pragma unused (sender)
  [NSApp beginSheet:_defineFSheet modalForWindow:_docWindow modalDelegate:self
         didEndSelector:@selector(_sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}


-(IBAction)dupAction:(id)sender
{
  #pragma unused (sender)
  NSInteger i = [_table selectedRow];
  if (i >= 0)
  {
    TEMachine* m = [_machines objectAtIndex:i];
    if (m)
    {
      m = [m copy];
      [m setName:[NSString stringWithFormat:@"%@ copy", [m name]]];
      [self _insertMachine:m atIndex:i+1 withActionName:NSLocalizedString(@"__UNDO_DUP__", @"Duplicate") defining:NO];
      [m release];
    }
  }
}

-(IBAction)exportATTAction:(id)sender
{
  #pragma unused (sender)
  [[NSSavePanel savePanel]
    beginSheetForDirectory:NSHomeDirectory()
    file:nil
    modalForWindow:_docWindow
    modalDelegate:self
    didEndSelector:@selector(_exportPanelDidEnd:returnCode:contextInfo:)
    contextInfo:NULL];
}

-(IBAction)importLexcAction:(id)sender
{
  #pragma unused (sender)
  [[NSOpenPanel openPanel] beginSheetForDirectory:nil file:nil
                           modalForWindow:_docWindow modalDelegate:self
                           didEndSelector:@selector(_importPanelDidEnd:returnCode:contextInfo:)
                           contextInfo:@"lexc"];
}

-(IBAction)insertSymbol:(id)sender
{
  NSString* symbol = [NSString stringWithFormat:@"%C", [sender tag]];
  if (symbol)
  {
    NSEvent* evt = [NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0.0f,0.0f)
                            modifierFlags:0 timestamp:0 windowNumber:0 context:NULL
                            characters:symbol charactersIgnoringModifiers:symbol
                            isARepeat:NO keyCode:0];
    [NSApp sendEvent:evt];
  }
}

-(IBAction)view:(id)sender
{
  #pragma unused (sender)
  NSInteger i = [_table selectedRow];
  if (i >= 0)
  {
    TEMachine* m = [_machines objectAtIndex:i];
    NSString* tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"terminusdot.XXXXXX.dot"];
    char* tempFileNameCString = (char*)strdup([tempFileTemplate fileSystemRepresentation]);
    NSLog(@"%s", tempFileNameCString);
    int fd = mkstemps(tempFileNameCString, 4);
    if (fd == -1)
    {
      NSLog(@"Could not create the temp file.");
    }
    NSString* tempFileName = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
    //FILE* fh = fdopen(fd, "w");
    TE_print_dot([m fsm], tempFileNameCString);
    //fclose(fh);
    free(tempFileNameCString);
    [[NSWorkspace sharedWorkspace] openFile:tempFileName withApplication:@"GraphViz"];
  }
}

-(IBAction)clearRecents:(id)sender
{
  #pragma unused (sender)
  NSInteger items = [_recentsButton numberOfItems];
  while (items > 2)
  {
    [_recentsButton removeItemAtIndex:2];
    items--;
  }
  [_recentsButton setEnabled:NO];
}

-(IBAction)insertRecent:(id)sender
{
  NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:[sender title]];
  [_edit setAttributedStringValue:attrStr];
  [[_edit window] makeFirstResponder:_edit];
  [attrStr release];
}

-(IBAction)delete:(id)sender
{
  #pragma unused (sender)
  NSInteger i;
  for (i = [_table numberOfRows]; i > 0; i--)
    if ([_table isRowSelected:i-1])
      [self _deleteMachineAtIndex:i-1 withActionName:NSLocalizedString(@"__UNDO_DELETE__", @"Delete Machine")];
  if ([_table selectedRow] == -1)
  {
    NSIndexSet* rows = [[NSIndexSet alloc] initWithIndex:[_table numberOfRows]-1];
    [_table selectRowIndexes:rows byExtendingSelection:NO];
    [rows release];
  }
}

-(IBAction)machineOp:(id)sender
{
  NSInteger op = [sender tag];
  struct fsm* fsm = NULL;
  switch (op)
  {
    case teMachineUniversalTag:  fsm = fsm_universal();  break;
    //case teMachineAnyTag:  fsm = fsm_any();  break;
    case teMachineEmptySetTag:  fsm = fsm_empty_set();  break;
    case teMachineEmptyStringTag: fsm = fsm_empty_string();  break;
    case teMachineIdentityTag:  fsm = fsm_identity();  break;
  }
  if (fsm)
  {
    TEMachine* m = [[TEMachine alloc] initWithFSM:fsm name:[sender title] defined:NO];
    [self _insertMachine:m atIndex:[_machines count] withActionName:NSLocalizedString(@"__UNDO_ADD__", @"Add Machine") defining:NO];
    [m release];
  }
}


-(IBAction)unaryOp:(id)sender
{
  NSInteger op = [sender tag];
  NSUInteger i;
  if ([_table selectedRow] != -1)
  {
    for (i = 0; i < [_machines count]; i++)
    {
      if ([_table isRowSelected:i])
      {
        TEMachine* m = [_machines objectAtIndex:i];
        TEMachine* cpy = [m copy];
        struct fsm* fsm = [cpy fsm];
        NSString* actionName = @"__UNARY__";
        switch (op)
        {
          case teUnaryMinimizeTag:     fsm_minimize(fsm);     actionName = @"__MINIMIZE__";    break;
          case teUnaryDeterminizeTag:  fsm_determinize(fsm);  actionName = @"__DETERMINIZE__"; break;
          case teUnaryPruneTag:        fsm_coaccessible(fsm); actionName = @"__PRUNE__";       break;
          case teUnaryCompactTag:      fsm_compact(fsm);      actionName = @"__COMPACT__";     break;
          case teUnaryReverseTag:      fsm_reverse(fsm);      actionName = @"__REVERSE__";     break;
          case teUnaryInvertTag:       fsm_invert(fsm);       actionName = @"__INVERT__";      break;
          case teUnaryUpperTag:        fsm_upper(fsm);        actionName = @"__UPPER__";       break;
          case teUnaryLowerTag:        fsm_lower(fsm);        actionName = @"__LOWER__";       break;
          case teUnaryKleeneStarTag:   fsm_kleene_star(fsm);  actionName = @"__STAR__";        break;
          case teUnaryKleenePlusTag:   fsm_kleene_plus(fsm);  actionName = @"__PLUS__";        break;
          case teUnaryOptionalTag:     fsm_optionality(fsm);  actionName = @"__OPTIONAL__";    break;
        }
        fsm_topsort(fsm);
        [self _replaceMachineAtIndex:i withMachine:cpy withActionName:NSLocalizedString(actionName, @"Unary Operation")];
        [cpy release];
      }
    }
    [_table reloadData];
  }
}

-(IBAction)acceptSheet:(id)sender
{
  [NSApp endSheet:[sender window] returnCode:NSAlertDefaultReturn];
}

-(IBAction)cancelSheet:(id)sender
{
  [NSApp endSheet:[sender window] returnCode:NSAlertAlternateReturn];
}

-(IBAction)selectNextTab:(id)sender { [_tabs selectNextTabViewItem:sender]; }
-(IBAction)selectPreviousTab:(id)sender { [_tabs selectPreviousTabViewItem:sender]; }

-(IBAction)stringsAction:(id)sender
{
  [_stringsPanel setVisible:![sender tag]];
  [sender setTag:![sender tag]];
}

/*-(IBAction)copy:(id)sender
{
  if ([_docWindow firstResponder] == _table)
  {
    unsigned long i;
    if ([_table selectedRow] != -1)
    {
      NSMutableString* descs = [[NSMutableString alloc] init];
      NSPasteboard* pb = [NSPasteboard generalPasteboard];
      [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
      for (i = 0; i < [_machines count]; i++)
      {
        if ([_table isRowSelected:i])
        {
          TEMachine* m = [_machines objectAtIndex:i];
          [descs appendFormat:@"%s%@", ([descs length] > 0) ? "\n\n" : "", [m description]];
        }
      }
      [pb setString:descs forType:NSStringPboardType];
      [descs release];
    }
  }
}*/

#pragma mark Machine Table
-(NSInteger)numberOfRowsInTableView:(NSTableView*)tv
{
  #pragma unused (tv)
  return [_machines count];
}

// FIXME: when this makes it into the foma public API, remove it.
extern int fsm_isstarfree(struct fsm *net);
-(id)tableView:(NSTableView*)tv objectValueForTableColumn:(NSTableColumn*)col row:(NSInteger)row
{
  #pragma unused (tv)
  id obj = nil;
  id ident = [col identifier];
  TEMachine* m = [_machines objectAtIndex:row];
  struct fsm* fsm = [m fsm];
  if ([ident isEqual:@"defined"] && m.defined) obj = [NSImage imageNamed:@"TEDefinitionTemplate"];
  else if ([ident isEqual:@"name"])
  {
    obj = [m name];
  }
  else if ([ident isEqual:@"states"])
  {
    obj = [NSNumber numberWithInt:fsm->statecount];
  }
  else if ([ident isEqual:@"finals"])
  {
    obj = [NSNumber numberWithInt:fsm->finalcount];
  }
  else if ([ident isEqual:@"edges"])
  {
    obj = [NSNumber numberWithInt:fsm->arccount];
  }
  else if ([ident isEqual:@"paths"])
  {
    if (fsm->pathcount == -1) obj = [self _infinity];
    else if (fsm->pathcount == -2) obj = [NSString stringWithFormat:@"> %lld", LLONG_MAX];
    else if (fsm->pathcount == -3) obj = [self _question];
    else obj = [NSNumber numberWithLongLong:fsm->pathcount];
  }
  else if ([ident isEqual:@"deterministic"])
  {
    obj = (fsm->is_deterministic) ? [self _check] : nil;
  }
  else if ([ident isEqual:@"efree"])
  {
    obj = (fsm->is_epsilon_free) ? [self _check] : nil;
  }
  else if ([ident isEqual:@"empty"])
  {
    if (fsm->statecount > [[NSUserDefaults standardUserDefaults] integerForKey:@"cutoff"]) obj = [self _question];
    else obj = (fsm_isempty(fsm)) ? [self _check] : nil;
  }
  else if ([ident isEqual:@"functional"])
  {
    if (fsm->statecount > [[NSUserDefaults standardUserDefaults] integerForKey:@"cutoff"]) obj = [self _question];
    else obj = (fsm_isfunctional(fsm)) ? [self _check] : nil;
  }
  else if ([ident isEqual:@"unambiguous"])
  {
    if (fsm->statecount > [[NSUserDefaults standardUserDefaults] integerForKey:@"cutoff"]) obj = [self _question];
    else obj = (fsm_isunambiguous(fsm)) ? [self _check] : nil;
  }
  else if ([ident isEqual:@"identity"])
  {
    if (fsm->statecount > [[NSUserDefaults standardUserDefaults] integerForKey:@"cutoff"]) obj = [self _question];
    else obj = (fsm_isidentity(fsm)) ? [self _check] : nil;
  }
  else if ([ident isEqual:@"universal"])
  {
    if (fsm->statecount > [[NSUserDefaults standardUserDefaults] integerForKey:@"cutoff"]) obj = [self _question];
    else obj = (fsm_isuniversal(fsm)) ? [self _check] : nil;
  }
  else if ([ident isEqual:@"starfree"])
  {
    if (fsm->statecount > [[NSUserDefaults standardUserDefaults] integerForKey:@"sfcutoff"]) obj = [self _question];
    else
    {
      struct fsm* cpy = fsm_copy(fsm);
      obj = (fsm_isstarfree(cpy)) ? [self _check] : nil;
      fsm_destroy(cpy);
    }
  }
  return obj;
}

-(void)controlTextDidEndEditing:(NSNotification*)note
{
  id obj = [note object];
  if (obj == _table && [[note userInfo] objectForKey:@"TEReturn"])
  {
    NSInteger sel = [_table selectedRow];
    if (sel != -1)
    {
      NSDictionary* dict = [note userInfo];
      NSTextView* tv = [dict objectForKey:@"NSFieldEditor"];
      NSString* newName = [[tv textStorage] string];
      NSRange white = [newName rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if (white.location == NSNotFound || white.length == 0)
        [self _renameMachineAtIndex:sel toName:newName withActionName:NSLocalizedString(@"__UNDO_DEFINE__", @"Rename Machine") defining:YES];
      else if (NO == [[NSUserDefaults standardUserDefaults] boolForKey:@"noWhitespaceAlert"])
      {
        NSAlert* lert = [NSAlert alertWithMessageText:NSLocalizedString(@"__NO_SPACE__",@"")
                        defaultButton:NSLocalizedString(@"__OK__",@"OK")
                        alternateButton:nil
                        otherButton:nil
                        informativeTextWithFormat:NSLocalizedString(@"__NO_SPACE_EXPL__",@"")];
        [lert setShowsSuppressionButton:YES];
        [lert beginSheetModalForWindow:_docWindow modalDelegate:self didEndSelector:@selector(_alertDidEnd:returnCode:contextInfo:) contextInfo:@"noWhitespaceAlert"];
      }
    }
  }
}

-(BOOL)tableView:(NSTableView*)table writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pb
{
	if (table == _table && [table numberOfSelectedRows])
	{
		// Intra-table drag - data is the array of rows.
		[pb declareTypes:[NSArray arrayWithObject:TEMachineListRows] owner:nil];
		[pb setPropertyList:rows forType:TEMachineListRows];
		return YES;
	}
	return NO;
}

-(NSDragOperation)tableView:(NSTableView*)table validateDrop:(id <NSDraggingInfo>)info
                  proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
  #pragma unused (info)
	// Make drops at the end of the table go to the end.
	if (row == -1)
	{
		row = [table numberOfRows];
		op = NSTableViewDropAbove;
		[table setDropRow:row dropOperation:op];
	}
	// We don't ever want to drop onto a row, only between rows.
	if (op == NSTableViewDropOn)
		[table setDropRow:(row+1) dropOperation:NSTableViewDropAbove];
  NSUInteger modifiers = [[NSApp currentEvent] modifierFlags] & NSDeviceIndependentModifierFlagsMask;
  if (modifiers == NSAlternateKeyMask) return NSDragOperationCopy;
  return NSDragOperationMove;
}

-(BOOL)tableView:(NSTableView*)table acceptDrop:(id <NSDraggingInfo>)info
       row:(NSInteger)dropRow dropOperation:(NSTableViewDropOperation)op;
{
  #pragma unused (op)
  //NSLog(@"row %d op %d", dropRow, op);
	BOOL accepted = NO;
  if (table == _table)
	{
	  NSPasteboard* pb = [info draggingPasteboard];
    NSArray* array = [pb propertyListForType:TEMachineListRows];
    if (array)
    {
      NSDragOperation	srcMask = [info draggingSourceOperationMask];
      BOOL isCopy = (srcMask & NSDragOperationMove) ? NO:YES;
      dropRow = [self _moveRows:array to:dropRow copying:isCopy];
      [table deselectAll:self];
      NSMutableIndexSet* rows = [[NSMutableIndexSet alloc] init];
      for (id blah in array)
        [rows addIndex:dropRow++];
      [table selectRowIndexes:rows byExtendingSelection:YES];
      [rows release];
      accepted = YES;
    }
	}
	return accepted;
}

-(void)tableViewSelectionDidChange:(NSNotification*)note
{
  #pragma unused (note)
  TEMachine* m = nil;
  if ([_table numberOfSelectedRows] == 1)
  {
    m = [_machines objectAtIndex:[_table selectedRow]];
  }
  [_stringsPanel setMachine:m];
}

-(void)tableView:(NSTableView*)tv willDisplayContextualMenu:(NSMenu*)menu forRow:(unsigned)row
{
  if (tv == _table && row < [_machines count])
  {
    [[menu addItemWithTitle:NSLocalizedString(@"__COPY_PROLOG__", "Copy Prolog") action:@selector(copyPrologAction:) keyEquivalent:@""] setTarget:self];
  }
}

#pragma mark Internal
-(void)handleStderr:(const char*)msg length:(int)len
{
  NSString* err = nil;
  //NSLog(@"handleError:'%@' %@ %@ %@", err, _errorDrawer, _errorDrawerIcon, _errorDrawerText);
  if (msg && len)
    err = [[[NSString alloc] initWithBytes:msg length:len encoding:NSUTF8StringEncoding] autorelease];
  else if (len && !err && [_stdout length]) err = [self _retrieveStdout];
  else [_errorDrawer close];
  if (err)
  {
    NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kAlertStopIcon)];
    [_errorDrawerText setStringValue:err];
    [_errorDrawerIcon setImage:icon];
    [_errorDrawer open];
  }
}

-(void)handleStdout:(const char*)msg length:(int)len
{
  [_stdout appendBytes:msg length:len];
}

-(NSString*)_retrieveStdout
{
  NSString* s = [[NSString alloc] initWithBytes:[_stdout bytes] length:[_stdout length] encoding:NSUTF8StringEncoding];
  [_stdout setLength:0];
  return [s autorelease];
}

-(void)_compile:(NSString*)regex defined:(NSString*)name asAction:(BOOL)act
{
  [self handleStderr:nil length:0];
  TEMachine* m = [TEMachine machineWithRegex:regex name:name machines:_machines];
  if ([_stdout length]) [self handleStderr:nil length:1];
  if (m)
  {
    if (name) [m setName:name];
    else [m setName:regex];
    NSUInteger i = [_machines count];
    NSString* action = nil;
    if (act) action = [[Onizuka sharedOnizuka] bestLocalizedString:@"__UNDO_COMPILE__"];
    [self _insertMachine:m atIndex:i withActionName:action defining:(name)? YES:NO];
    if (act)
    {
      [_docWindow makeFirstResponder:_edit];
      NSUInteger items = [_recentsButton numberOfItems];
      NSMenu* menu = [_recentsButton menu];
      NSMenuItem* newItem;
      if (items >= 12) [_recentsButton removeItemAtIndex:2];
      newItem = [[NSMenuItem alloc] initWithTitle:regex
                                    action:@selector(insertRecent:)
                                    keyEquivalent:@""];
      [menu addItem:newItem];
      [newItem release];
      [_recentsButton setEnabled:YES];
    }
  }
}

-(void)_insertMachine:(TEMachine*)m atIndex:(NSUInteger)i withActionName:(NSString*)action defining:(BOOL)def
{
  //NSLog(@"_insertMachine:%@ atIndex:%d", [m name], i);
  if ([_machines count] < i) i = [_machines count];
  [_machines insertObject:m atIndex:i];
  if (def) [m setDefined:YES];
  if (action)
  {
    [_table reloadData];
    [_table selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
    [_table scrollRowToVisible:i];
    [[[self undoManager] prepareWithInvocationTarget:self] _deleteMachineAtIndex:i withActionName:action]; 
    [[self undoManager] setActionName:action];
  }
}

-(void)_replaceMachineAtIndex:(NSUInteger)i withMachine:(TEMachine*)m withActionName:(NSString*)action
{
  TEMachine* orig = [_machines objectAtIndex:i];
  if (orig.defined)
  {
    [m setName:[orig name]];
    m.defined = YES;
  }
  TEMachine* cpy = [orig copy];
  [_machines replaceObjectAtIndex:i withObject:m];
  [[[self undoManager] prepareWithInvocationTarget:self] _replaceMachineAtIndex:i withMachine:cpy withActionName:action];
  if (action) [[self undoManager] setActionName:action];
  [cpy release];
  [_table reloadData];
}

-(void)_deleteMachineAtIndex:(NSUInteger)i withActionName:(NSString*)action
{
  TEMachine* m = [_machines objectAtIndex:i];
  TEMachine* cpy = [m copy];
  [[[self undoManager] prepareWithInvocationTarget:self] _insertMachine:cpy atIndex:i withActionName:action defining:m.defined]; 
  [[self undoManager] setActionName:action];
  [cpy release];
  [_machines removeObjectAtIndex:i];
  [_table reloadData];
}

-(void)_renameMachineAtIndex:(NSUInteger)i toName:(NSString*)name withActionName:(NSString*)action defining:(BOOL)def
{
  TEMachine* m = [_machines objectAtIndex:i];
  NSString* oldName = [m name];
  if (def != m.defined || ![oldName isEqualToString:name])
  {
    oldName = [oldName copy];
    [[[self undoManager] prepareWithInvocationTarget:self] _renameMachineAtIndex:i toName:oldName withActionName:action defining:!def]; 
    [[self undoManager] setActionName:action];
    [oldName release];
    if (name) [m setName:name];
    [m setDefined:def];
    if (def) [self _undefineDuplicatesOfMachine:m];
    [_table reloadData];
  }
}

-(void)_undefineDuplicatesOfMachine:(TEMachine*)m
{
  NSUInteger i = 0;
  for (TEMachine* m2 in _machines)
  {
    if (m2 != m && m2.defined && [[m name] isEqualToString:[m2 name]])
    {
      m2.defined = NO;
      [[[self undoManager] prepareWithInvocationTarget:self] _renameMachineAtIndex:i toName:nil withActionName:nil defining:YES];
      break;
    }
    i++;
  }
}

-(NSMutableAttributedString*)_check
{
  static NSMutableAttributedString* check = nil;
  if (!check)
  {
    NSRange range = {0,1};
    check = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%C", 0x2713]];
    NSColor* green = [NSColor colorWithCalibratedRed:0.0f green:0.67f blue:0.0f alpha:1.0f];
    [check addAttribute:NSForegroundColorAttributeName value:green range:range];
  }
  return check;
}

-(NSMutableAttributedString*)_question
{
  static NSMutableAttributedString* question = nil;
  if (!question)
  {
    NSRange range = {0,1};
    question = [[NSMutableAttributedString alloc] initWithString:@"?"];
    NSColor* red = [NSColor colorWithCalibratedRed:0.67f green:0.0f blue:0.0f alpha:1.0f];
    [question addAttribute:NSForegroundColorAttributeName value:red range:range];
  }
  return question;
}

-(NSString*)_infinity
{
  static NSString* inf = nil;
  if (!inf) inf = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%C", 0x221E]];
  return inf;
}

-(NSUInteger)_moveRows:(NSArray*)array to:(NSUInteger)destination copying:(BOOL)copy
{
  NSMutableArray* movedMachines = [[NSMutableArray alloc] initWithCapacity:[array count]];
  NSInteger		result = destination;
  NSString* action = (copy)? NSLocalizedString(@"__UNDO_COPY__", @"Move") :
                             NSLocalizedString(@"__UNDO_MOVE__", @"Copy");
  //NSLog(@"moveRows:%@ to:%d copying:%s action:%@", array, destination, (copy)?"YES":"NO", action);
  // Accumulate the selected elements from the track array, accumulating
  // them in movedMachines. We iterate backwards to avoid changing the dragged numbers.
	for (id val in [array reverseObjectEnumerator])
  {
		unsigned i = [val unsignedIntValue];
		TEMachine* m = [_machines objectAtIndex:i];
		// If we're copying then duplicate the item.
		if (copy) m = [m copy];
    else [m retain];
		// Accumulate this track into the array.
		[movedMachines addObject:m];
		[m release];
    // If we're moving then remove the original item.
		//	This may change the destination index.
		if (!copy)
		{
      //NSLog(@"Removing %d", i);
			[self _deleteMachineAtIndex:i withActionName:action];
			if (i < destination) destination--;
		}
	}
  result = destination;
	for (TEMachine* m in [movedMachines reverseObjectEnumerator])
  {
    //NSLog(@"Inserting at %d", destination);
		[self _insertMachine:m atIndex:destination++ withActionName:action defining:NO];
  }
  [movedMachines release];
  return result;
}

-(void)_readLexc:(NSString*)file
{
  struct fsm* net = fsm_lexc_parse_file((char*)[file UTF8String]);
  if (!net) return;
  TEMachine* m = [[TEMachine alloc] initWithFSM:net name:[file lastPathComponent] defined:YES];
  [_machines addObject:m];
  [m release];
  fsm_destroy(net);
}

-(void)_sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)code contextInfo:(void*)ctx
{
  #pragma unused (ctx)
  if (sheet) [sheet orderOut:self];
  if (code != NSOKButton) return;
  if (sheet == _defineSheet)
  {
    [self _compile:[_edit stringValue] defined:[_defineField stringValue] asAction:YES];
  }
  else if (sheet == _defineFSheet)
  {
    [_fController insertFunction:[_edit stringValue] withName:[_defineFNameField stringValue] withParams:[_defineFParamsField stringValue] asAction:YES];
  }
}

-(void)_exportPanelDidEnd:(NSSavePanel*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)ctx
{
  #pragma unused (ctx)
  if (returnCode == NSOKButton)
  {
    NSInteger i = [_table selectedRow];
    if (i >= 0)
    {
      TEMachine* m = [_machines objectAtIndex:i];
      FILE* outfile = fopen([[sheet filename] UTF8String], "w");
      (void)net_print_att([m fsm], outfile);
      fclose(outfile);
    }
  }
}

-(void)_importPanelDidEnd:(NSSavePanel*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)ctx
{
  id ctxObj = (id)ctx;
  if (returnCode == NSOKButton)
  {
    NSString* f = [sheet filename];
    if ([ctxObj isEqual:@"regex"])
    {
      NSString* contents = [[NSString alloc] initWithContentsOfFile:f];
      if (contents)
      {
        [_edit setStringValue:contents];
        [contents release];
      }
    }
    else if ([ctxObj isEqual:@"lexc"])
    {
      [self _readLexc:f];
    }
  }
}

-(void)_alertDidEnd:(NSAlert*)alert returnCode:(int)code contextInfo:(void*)ctx
{
  #pragma unused (code)
  if ([alert showsSuppressionButton] && [[alert suppressionButton] state] == NSOnState && ctx)
  {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ctx];
  }
}
@end


@implementation TRTableView
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
    else if (c == 0x0D && [self selectedRow] != -1)
    {
      handled = YES;
      [self editColumn:[self columnWithIdentifier:@"name"] row:[self selectedRow]
            withEvent:event select:YES];
    }
    else if (c == '\t')
    {
      handled = YES;
      if ([event modifierFlags] & NSShiftKeyMask) [[self window] selectPreviousKeyView:self];
      else [[self window] selectKeyViewFollowingView:self];
    }
	}
	if (!handled) [super keyDown:event];
}

-(void)textDidEndEditing:(NSNotification*)note
{
  NSDictionary *ui = [note userInfo];
  int textMovement = [[ui valueForKey:@"NSTextMovement"] intValue];
  if (textMovement == NSReturnTextMovement
      || textMovement == NSTabTextMovement
      || textMovement == NSBacktabTextMovement)
  {
    NSMutableDictionary *newInfo;
    newInfo = [NSMutableDictionary dictionaryWithDictionary:ui];
    [newInfo setObject: [NSNumber numberWithInt: NSIllegalTextMovement]
             forKey: @"NSTextMovement"];
    [newInfo setObject:[NSNull null] forKey:@"TEReturn"];
    note = [NSNotification notificationWithName:[note name]
                           object:[note object]
                           userInfo:newInfo];
  }
  [super textDidEndEditing:note];
  [[self window] makeFirstResponder:self];
}

-(NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
  if (isLocal) return NSDragOperationMove | NSDragOperationCopy;
  return NSDragOperationCopy;
}

// Contextual menu support
-(NSMenu*)menuForEvent:(NSEvent*)event
{
  NSMenu *menu = [[NSMenu alloc] init];
  NSPoint where = [event locationInWindow];
  NSPoint here = [self convertPoint:where fromView:nil];
  NSInteger row = [self rowAtPoint:here];
  if (row != -1)
  {
    id del = [self delegate];
    if (del && [del respondsToSelector:@selector(tableView:willDisplayContextualMenu:forRow:)])
    {
      [del tableView:self willDisplayContextualMenu:menu forRow:(unsigned)row];
    }
  }
  return [menu autorelease];
}
@end

static int TE_print_dot(struct fsm *net, char *filename) {
    struct fsm_state *stateptr;
    FILE *dotfile;
    int i, j, linelen;
    short *finals, *printed;
    
    stateptr = net->states;
    fsm_count(net);
    
    finals = xxmalloc(sizeof(short)*net->statecount);
    
    for (i=0; (stateptr+i)->state_no != -1; i++) {
        if ((stateptr+i)->final_state == 1) {
            *(finals+((stateptr+i)->state_no)) = 1;
        } else {
            *(finals+((stateptr+i)->state_no)) = 0;
        }
    }
    
    if (filename != NULL) {
        dotfile = fopen(filename,"w");
    } else {
        dotfile = stdout;
    }

  fprintf(dotfile,"digraph A {\nrankdir = LR;\n");
  /* Go through states */
  for (i=0; i < net->statecount; i++) {
    if (*(finals+i)) {
      fprintf(dotfile,"node [shape=doublecircle,style=filled] %i\n",i);
    } else {
      fprintf(dotfile,"node [shape=circle,style=filled] %i\n",i);
    }
  }

  printed = xxcalloc(net->linecount,sizeof(printed));
  /* Go through arcs */  
  for (i=0; (stateptr+i)->state_no != -1; i++) {      
      if ((stateptr+i)->target == -1 || printed[i] == 1)
          continue;
      fprintf(dotfile,"%i -> %i [label=\"", (stateptr+i)->state_no, (stateptr+i)->target);
      linelen = 0;
      for (j=i; (stateptr+j)->state_no == (stateptr+i)->state_no; j++) {
          if (((stateptr+i)->target == ((stateptr+j)->target)) && printed[j] == 0) {
              printed[j] = 1;

              if (((stateptr+j)->in == ((stateptr+j)->out)) && (stateptr+j)->out != UNKNOWN ) {
                  fprintf(dotfile,"%s", escape_string(TE_sigptr(net->sigma, (stateptr+j)->in),'"'));
                  linelen += strlen((TE_sigptr(net->sigma, (stateptr+j)->in)));
              } else {
                  fprintf(dotfile,"<%s:%s>", escape_string(TE_sigptr(net->sigma, (stateptr+j)->in),'"'), escape_string(TE_sigptr(net->sigma, (stateptr+j)->out),'"'));
                  linelen += strlen((TE_sigptr(net->sigma, (stateptr+j)->in))) + strlen(TE_sigptr(net->sigma, (stateptr+j)->out)) + 3;
              }
              if (linelen > 12) {
                  fprintf(dotfile, "\\n");
                  linelen = 0;
              } else {
                  fprintf(dotfile, " ");
              }
          }
      }
      fprintf(dotfile,"\"];\n");  
  }

  
  xxfree(finals);
  xxfree(printed);
  fprintf(dotfile, "}\n");
  if (filename != NULL)
      fclose(dotfile);
  return(1);
}

static char *TE_sigptr(struct sigma *sigma, int number) {
    char *mystr;
    if (number == EPSILON)
        return "0";
    if (number == UNKNOWN)
        return "?";
    if (number == IDENTITY)
        return "@";

    for (; sigma != NULL; sigma = sigma->next) {
        if (sigma->number == number) {
            if (strcmp(sigma->symbol,"0") == 0)
                return("\"0\"");
            if (strcmp(sigma->symbol,"?") == 0)
                return("\"?\"");
            if (strcmp(sigma->symbol,"\n") == 0)
                return("\\n");
            if (strcmp(sigma->symbol,"\r") == 0)
                return("\\r");
            return (sigma->symbol);
        }
    }
    mystr = xxmalloc(sizeof(char)*40);
    snprintf(mystr, 40, "NONE(%i)",number);
    return(mystr);
}

