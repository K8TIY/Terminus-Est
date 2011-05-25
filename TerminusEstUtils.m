/*
The MIT License

Copyright © 2009 Brian S. Hall
All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
#import <Cocoa/Cocoa.h>
#import "TerminusEstUtils.h"

@implementation TerminusEstUtils
+(OSStatus)runGraphvizOnString:(NSString*)dot atPath:(NSString*)path
{
  CFDataRef dat = CFStringCreateExternalRepresentation(kCFAllocatorDefault,
                                                       (CFStringRef)dot,
                                                       kCFStringEncodingUTF8,
                                                       '?');
  if (nil == path)
  {
    int fh = -1;
    static char* const template = "/var/tmp/Transductor_XXXXXX.dot";
    char* buff = malloc(strlen(template)+1);
    memcpy(buff, template, strlen(template)+1);
    fh = mkstemps(buff, 4);
    path = [NSString stringWithCString:buff];
    CFIndex len = CFDataGetLength(dat);
    unsigned char* databuff = malloc(len);
    CFDataGetBytes(dat, CFRangeMake(0,len), databuff);
    write(fh, databuff, len);
    free(databuff);
    close(fh);
  }
  else [(NSData*)dat writeToFile:path atomically:YES];
  CFRelease(dat);
  CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                              (CFStringRef)path,
                                               kCFURLPOSIXPathStyle, false);
  LSLaunchURLSpec urlSpec = {NULL, NULL, NULL, 0, NULL};
  urlSpec.itemURLs = CFArrayCreate(kCFAllocatorDefault, (const void**)&url, 1, NULL);
  urlSpec.launchFlags = kLSLaunchDefaults | kLSLaunchDontAddToRecents |
                        kLSLaunchDontSwitch;
  OSStatus status = LSOpenFromURLSpec(&urlSpec, NULL);
  CFRelease(urlSpec.itemURLs);
  CFRelease(url);
  return status;
}

+(id)propertyListFromRunningScript:(NSString*)script onData:(NSData*)data
{
  NSString* path = [[NSBundle mainBundle] pathForResource:script ofType:nil];
  NSTask* task = [[NSTask alloc] init];
  [task setLaunchPath:path];
  NSPipe* readPipe = [NSPipe pipe];
  NSFileHandle* readHandle = [readPipe fileHandleForReading];
  NSPipe* writePipe = [NSPipe pipe];
  NSFileHandle* writeHandle = [writePipe fileHandleForWriting];
  [task setStandardInput:writePipe];
  [task setStandardOutput:readPipe];
  [task launch];
  [writeHandle writeData:data];
  [writeHandle closeFile];
  NSMutableData* pldata = [[NSMutableData alloc] init];
  NSData* readatad;
  while ((readatad = [readHandle availableData]) && [readatad length])
    [pldata appendData:readatad];
  NSString* err = nil;
  NSString* asstr = [[NSString alloc] initWithData:pldata encoding:NSUTF8StringEncoding];
  [asstr release];
  id plist = [NSPropertyListSerialization propertyListFromData:pldata
                                          mutabilityOption:kCFPropertyListImmutable
                                          format:NULL errorDescription:&err];
  // FIXME: what to do with error string?
  if (err)
  {
    NSLog(@"%@", err);
    [err release];
  }
  [task release];
  [pldata release];
  return plist;
}

+(NSString*)localized:(NSString*)key
{
  return [[NSBundle mainBundle] localizedStringForKey:key value:@"" table:@"Transductor"];
}

// Taken from Unicode Consortium data.
// We don't use 0xFEFF ZERO WIDTH NO-BREAK SPACE because it is a control
// character and is invisible.
// 0x200C ZERO WIDTH NON-JOINER is counted as a space, but
// 0x200D ZERO WIDTH JOINER is counted as a nonspace.
+(BOOL)unicodeIsSpace:(unichar)ch
{
  return ((ch >= 0x0009 && ch <= 0x000D) || // Spacey control characters
          ch == 0x0020 || // SPACE
          ch == 0x0085 || // NEXT LINE (NEL)
          ch == 0x00A0 || // NO-BREAK SPACE
          ch == 0x1680 || // OGHAM SPACE MARK
          ch == 0x180E || // MONGOLIAN VOWEL SEPARATOR
          (ch >= 0x2000 && ch <= 0x200C) || // Spacey part of gen punctuation
          ch == 0x2028 || // LINE SEPARATOR
          ch == 0x2029 || // PARAGRAPH SEPARATOR
          ch == 0x202F || // NARROW NO-BREAK SPACE
          ch == 0x205F || // MEDIUM MATHEMATICAL SPACE
          ch == 0x3000);
}

// Is this character a nonspacing diacritic?
// FIXME: should this apply to all Unicode characters with Mn class?
// FIXME: how to handle char values in higher planes? (unichar is 16 bits on PowerPC 32 anyway)
+(BOOL)unicodeIsNonspacing:(unichar)ch
{
  return ((ch >= 0x0300 && ch <= 0x036F) || // Combining diacritical marks
          (ch >= 0x20D0 && ch <= 0x20FF) || // Combining Marks for Symbols
          (ch >= 0xFE20 && ch <= 0xFE2F) // Combining Half Marks
  );
}
@end
