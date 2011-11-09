/*
Copyright © 2009-2011 Brian S. Hall

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


// Same fields as an NSRect, but a SubRect has all fields as
// percentages (<= 1.0) so this describes a portion of some
// other 2D object. In this case, the subrects are the hot
// spots in the image map. If the image is scaled, the new
// hot spots' areas can be recalculated easily.
typedef NSRect SubRect;

@interface PDFImageMap : NSImageView
{
  CFMachPortRef          _tap;  // Quartz event tap for tracking rects
  NSMutableDictionary*   _data; // key -> stringified SubRect
  NSMutableDictionary*   _hots; // stringified SubRect -> key
  // an optional image used for generating drag images in case
  // the regular image has extra "stuff" (like the lines in the vowel chart)
  NSImage*               _dragImage;
  NSMutableString*       _lastHot;
  NSUInteger             _modifiers;
  id                     delegate;
  NSPoint                _lastMouse;
  NSTrackingRectTag      _trackingRect; // for the whole view
  BOOL                   _dragging;
}
-(NSString*)stringValue;
-(void)startTracking;
-(void)stopTracking;
-(void)removeAllTrackingRects;
-(void)setTrackingRect:(SubRect)r forKey:(NSString*)key;
-(NSUInteger)modifiers;
-(id)delegate;
-(void)setDragImage:(NSImage*)img;
@end
