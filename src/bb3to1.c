/*
 * Author: Darin Franklin
 * Date: 21 Jan 2006
 */
/*
    Copyright 2006 Darin Franklin

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License,
    version 2, as published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/
/*
 * Converts Alpha Sign 3-byte protocol to 1-byte format.  Unescapes a
 * string, converting the 3-char sequence, "_cc", to a single char,
 * where "cc" denotes a hex value.  Returns with a non-zero exit code
 * if the input is invalid, or 0 on success.
 */
#include <stdio.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char **argv)
{
  while (1)
  {
    int c;
    switch (c = getchar())
    {
    case EOF:
      return 0;
    case '_':
    {
      char hex[3];
      int i;
      i = scanf("%1[0-9A-Fa-f]%1[0-9A-Fa-f]", &hex[0], &hex[1]);
      if (i != 2)
      {
	return 1;
      }
      i = sscanf(hex, "%2x", &c);
      if (i == EOF || i == 0) 
      {
	return 2;
      }
    }
    /* fall through */
    default:
      putchar(c);
      break;
    }
  }
}
