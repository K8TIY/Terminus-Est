/*
Terminus Est: a Mac GUI for the foma finite-state toolkit and library.
Copyright © 2009 Brian "Moses" Hall

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

static int stderrwrite(void* inFD, const char* buffer, int size);
static int stdoutwrite(void* inFD, const char* buffer, int size);

int quiet_mode = 0;

int main(int argc, char* argv[])
{
  stderr->_write = stderrwrite;
  stdout->_write = stdoutwrite;
  return NSApplicationMain(argc, (const char**)argv);
}

static int stderrwrite(void* inFD, const char* buffer, int size)
{
  #pragma unused (inFD)
  NSWindow* mainWindow = [[NSApplication sharedApplication] mainWindow];
  if (mainWindow)
  {
    [[mainWindow delegate] handleStderr:buffer length:size];
  }
  return size;
}

static int stdoutwrite(void* inFD, const char* buffer, int size)
{
  #pragma unused (inFD)
  NSWindow* mainWindow = [[NSApplication sharedApplication] mainWindow];
  if (mainWindow)
  {
    [[mainWindow delegate] handleStdout:buffer length:size];
  }
  return size;
}

