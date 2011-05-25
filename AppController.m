/*
Terminus Est: a Mac GUI for the foma finite-state toolkit and library.
Copyright © 2009-2010 Brian "Moses" Hall

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
#import "AppController.h"
#import "Onizuka.h"
extern int g_compose_tristate;

@implementation TLPSymbolPanel
-(BOOL)canBecomeKeyWindow {return NO;}
-(BOOL)canBecomeMainWindow {return NO;}
@end


@implementation AppController
-(void)awakeFromNib
{
  [[Onizuka sharedOnizuka] localizeMenu:[[NSApplication sharedApplication] mainMenu]];
  NSDictionary* d = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
  [[NSUserDefaults standardUserDefaults] registerDefaults:d];
  [d release];
  [[Onizuka sharedOnizuka] localizeWindow:_symbolPanel];
  // Get the hot rect locations from the main image map data file
  NSString* path = [[NSBundle mainBundle] pathForResource:@"Symbols" ofType:@"plist"];
  NSArray* dat = [[NSArray alloc] initWithContentsOfFile:path];
  NSDictionary* entry;
  NSEnumerator* enumerator = [dat objectEnumerator];
  while ((entry = [enumerator nextObject]))
  {
    NSString* key = [entry objectForKey:@"char"];
    SubRect r = NSRectFromString([entry objectForKey:@"rect"]);
    [_symbolMap setTrackingRect:r forKey:key];
  }
  [dat release];
  [[Onizuka sharedOnizuka] localizeWindow:_prefsWindow];
  [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"tristate"
                                         options:NSKeyValueObservingOptionNew context:NULL];
}

-(void)observeValueForKeyPath:(NSString*)path ofObject:(id)object change:(NSDictionary*)change context:(void*)ctx
{
  #pragma unused (object,ctx)
  if ([path isEqual:@"tristate"])
  {
    id newval = [change objectForKey:NSKeyValueChangeNewKey];
    g_compose_tristate = [newval boolValue];
  }
}

-(BOOL)applicationShouldOpenUntitledFile:(NSApplication*)sender
{
  #pragma unused (sender)
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"untitled"];
}

-(BOOL)validateMenuItem:(NSMenuItem*)item
{
  SEL action = [item action];
  if (action == @selector(showSymbolPanel:))
  {
    [item setTag:[_symbolPanel isVisible]];
    [[Onizuka sharedOnizuka] localizeObject:item withTitle:([item tag])? @"__HIDE_SYMBOLS__":@"__SHOW_SYMBOLS__"];
    return YES;
  }
  return [super validateMenuItem:item];
}

-(IBAction)symbolAction:(id)sender
{
  NSString* str = [sender stringValue];
  NSEvent* evt = [NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0,0)
					                modifierFlags:0 timestamp:0 windowNumber:0
						              context:[NSGraphicsContext currentContext]
						              characters:str charactersIgnoringModifiers:str
					                isARepeat:NO keyCode:0];
  [[NSApplication sharedApplication] postEvent:evt atStart:YES];
}

-(void)PDFImageMapDidChange:(PDFImageMap*)map
{
  NSString* str = [map stringValue];
  [_symbolCaption setStringValue:NSLocalizedString(str, @"")];
}

-(IBAction)showSymbolPanel:(id)sender
{
  #pragma unused (sender)
  if ([sender tag])
  {
    [_symbolMap stopTracking];
    [_symbolPanel orderOut:self];
  }
  else
  {
    [_symbolMap startTracking];
    [_symbolPanel orderFront:self];
  }
  [sender setTag:![sender tag]];
}

-(void)windowWillClose:(NSNotification*)note
{
  if ([note object] == _symbolPanel)
  {
    [_symbolMap stopTracking];
  }
}
@end
