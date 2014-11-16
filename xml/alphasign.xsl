<?xml version="1.0" encoding="UTF-8"?>
<!--
    Transforms alphasign XML document into Alpha Sign Protocol.
    Author: Darin Franklin <dfranklin@pobox.com>
    Version: 1.3

    Copyright 2005 Darin Franklin

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
  -->
<xsl:stylesheet
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:a="urn:dfranklin:bbxml:lookup"
   version="1.1"
   >
  <xsl:param name="typeCode">Z</xsl:param>
  <xsl:param name="signAddress">00</xsl:param>

  <xsl:output method="text"/>
  <xsl:output indent="no"/>
  <xsl:strip-space elements="*"/>
  <xsl:preserve-space elements="msg"/>

  <xsl:template match="@*"/>

  <xsl:variable name="hexDigits" select="'0123456789ABCDEF'"/>

  <!-- functions -->

  <!-- pad $str on left with $chr to size $len -->
  <xsl:template name="lpad">
    <xsl:param name="str"/>
    <xsl:param name="len"/>
    <xsl:param name="chr"/>
    <xsl:choose>
      <xsl:when test="string-length($str) &lt; $len">
	<xsl:call-template name="lpad">
	  <xsl:with-param name="str" select="concat($chr, $str)"/>
	  <xsl:with-param name="len" select="$len"/>
	  <xsl:with-param name="chr" select="$chr"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$str"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="toPaddedHex">
    <xsl:param name="dec"/>
    <xsl:param name="len"/>
    <xsl:call-template name="lpad">
      <xsl:with-param name="str">
	<xsl:call-template name="toHex">
	  <xsl:with-param name="dec" select="$dec"/>
	</xsl:call-template>
      </xsl:with-param>
      <xsl:with-param name="len" select="$len"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="toHex">
    <xsl:param name="dec"/>
    <xsl:if test="$dec &gt;= 16">
      <xsl:call-template name="toHex">
	<xsl:with-param name="dec" select="floor($dec div 16)"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:value-of select="substring($hexDigits, ($dec mod 16) + 1, 1)"/>
  </xsl:template>

  <xsl:template name="escapeText">
    <xsl:param name="str"/>
    <xsl:variable name="chr" select="substring($str, 1, 1)"/>
    <xsl:choose>
      <xsl:when test="$chr = '_'">
	<xsl:text>_5F</xsl:text>
      </xsl:when>
      <xsl:when test="$chr = ']'">
	<xsl:text>_5D</xsl:text>
      </xsl:when>
      <xsl:when test="$chr = '&#x0A;'">
	<xsl:text> </xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$chr"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="string-length($str) &gt; 1">
      <xsl:call-template name="escapeText">
	<xsl:with-param name="str" select="substring($str, 2)"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>


  <xsl:template name="bitMask">
    <xsl:param name="b7" select="false()"/>
    <xsl:param name="b6" select="false()"/>
    <xsl:param name="b5" select="false()"/>
    <xsl:param name="b4" select="false()"/>
    <xsl:param name="b3" select="false()"/>
    <xsl:param name="b2" select="false()"/>
    <xsl:param name="b1" select="false()"/>
    <xsl:param name="b0" select="false()"/>

    <xsl:variable name="d7">
      <xsl:choose>
	<xsl:when test="$b7">128</xsl:when>
	<xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="d6">
      <xsl:choose>
	<xsl:when test="$b6">64</xsl:when>
	<xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="d5">
      <xsl:choose>
	<xsl:when test="$b5">32</xsl:when>
	<xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="d4">
      <xsl:choose>
	<xsl:when test="$b4">16</xsl:when>
	<xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="d3">
      <xsl:choose>
	<xsl:when test="$b3">8</xsl:when>
	<xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="d2">
      <xsl:choose>
	<xsl:when test="$b2">4</xsl:when>
	<xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="d1">
      <xsl:choose>
	<xsl:when test="$b1">2</xsl:when>
	<xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="d0">
      <xsl:choose>
	<xsl:when test="$b0">1</xsl:when>
	<xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:value-of select="$d7 + $d6 + $d5 + $d4 + $d3 + $d2 + $d1 + $d0"/>
  </xsl:template>


  <!-- sign commands -->

  <xsl:template match="text()">
    <xsl:call-template name="escapeText">
      <xsl:with-param name="str">
	<xsl:value-of disable-output-escaping="yes" select="."/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="/alphasign">
    <xsl:text>_01</xsl:text>
    <xsl:choose>
      <xsl:when test="@typeCode">
	<xsl:value-of select="@typeCode"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$typeCode"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="@signAddress">
	<xsl:value-of select="@signAddress"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$signAddress"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:variable name="count" select="count(*)"/>
    <!-- nested commands -->
    <xsl:for-each select="*">
      <xsl:text>_02</xsl:text>
      <xsl:apply-templates select="."/>
      <xsl:if test="position() &lt; $count">
	<xsl:text>_03</xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:text>_04</xsl:text>
  </xsl:template>

  <xsl:template match="memoryConfig">
    <xsl:text>E$</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="memoryConfig/textConfig">
    <xsl:value-of select="@label"/>
    <xsl:text>A</xsl:text>
    <xsl:choose>
      <xsl:when test="@locked = 'true'">
	<xsl:text>L</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>U</xsl:text>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:call-template name="toPaddedHex">
      <xsl:with-param name="dec" select="@size"/>
      <xsl:with-param name="len" select="4"/>
    </xsl:call-template>

    <xsl:choose>
      <xsl:when test="@start">
	<xsl:value-of select="document('')//a:timeLookup/a:time[@name=current()/@start]/@value"/>
      </xsl:when>
      <!-- default value for start is 'always' -->
      <xsl:otherwise>
	<xsl:value-of select="document('')//a:timeLookup/a:time[@name='always']/@value"/>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:choose>
      <xsl:when test="@stop">
	<xsl:value-of select="document('')//a:timeLookup/a:time[@name=current()/@stop]/@value"/>
      </xsl:when>
      <!-- default value for stop is 'never' -->
      <xsl:otherwise>
	<xsl:value-of select="document('')//a:timeLookup/a:time[@name='never']/@value"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="memoryConfig/stringConfig">
    <xsl:value-of select="@label"/>
    <!-- STRING memory is always locked -->
    <xsl:text>BL</xsl:text>
    <xsl:call-template name="toPaddedHex">
      <xsl:with-param name="dec" select="@size"/>
      <xsl:with-param name="len" select="4"/>
    </xsl:call-template>
    <xsl:text>0000</xsl:text>
  </xsl:template>
  
  <xsl:template match="memoryConfig/dotsConfig">
    <xsl:value-of select="@label"/>
    <xsl:text>D</xsl:text>
    <xsl:choose>
      <xsl:when test="@locked = 'true'">
	<xsl:text>L</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>U</xsl:text>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:call-template name="toPaddedHex">
      <xsl:with-param name="dec" select="@height"/>
      <xsl:with-param name="len" select="2"/>
    </xsl:call-template>

    <xsl:call-template name="toPaddedHex">
      <xsl:with-param name="dec" select="@width"/>
      <xsl:with-param name="len" select="2"/>
    </xsl:call-template>

    <xsl:choose>
      <xsl:when test="@colors = '1'">
	<xsl:text>1000</xsl:text>
      </xsl:when>
      <xsl:when test="@colors = '3'">
	<xsl:text>2000</xsl:text>
      </xsl:when>
      <xsl:when test="@colors = '8'">
	<xsl:text>4000</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>4000</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="sequence">
    <xsl:text>E.</xsl:text>
    <xsl:choose>
      <xsl:when test="@mode = 'useTimeSchedule'">
	<xsl:text>T</xsl:text>
      </xsl:when>
      <xsl:when test="@mode = 'ignoreTimeSchedule'">
	<xsl:text>S</xsl:text>
      </xsl:when>
      <xsl:when test="@mode = 'deleteAtStopTime'">
	<xsl:text>D</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>T</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="@locked = 'true'">
	<xsl:text>L</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>U</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="@labels"/>
  </xsl:template>

  <xsl:template match="dayScheduleTable">
    <xsl:text>E2</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="dayScheduleTable/daySchedule">
    <xsl:value-of select="@label"/>
    <xsl:value-of select="document('')//a:dayLookup/a:schedule[@name=current()/@start]/@value"/>
    <xsl:choose>
      <xsl:when test="@stop">
	<xsl:value-of select="document('')//a:dayLookup/a:schedule[@name=current()/@stop]/@value"/>
      </xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="timeScheduleTable">
    <xsl:text>E)</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="timeScheduleTable/timeSchedule">
    <xsl:value-of select="@label"/>
    <xsl:value-of select="document('')//a:timeLookup/a:time[@name=current()/@start]/@value"/>
    <xsl:choose>
      <xsl:when test="@stop">
	<xsl:value-of select="document('')//a:timeLookup/a:time[@name=current()/@stop]/@value"/>
      </xsl:when>
      <xsl:otherwise>00</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="speakerMode">
    <xsl:text>E!</xsl:text>
    <xsl:choose>
      <xsl:when test="@enabled = 'true'">
	<xsl:text>00</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>FF</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="timeFormat">
    <xsl:text>E'</xsl:text>
    <xsl:choose>
      <xsl:when test="@format = 'am-pm'">
	<xsl:text>S</xsl:text>
      </xsl:when>
      <xsl:when test="@format = '24-hour'">
	<xsl:text>M</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="timeOfDay">
    <xsl:text>E </xsl:text>
    <xsl:call-template name="lpad">
      <xsl:with-param name="str" select="@hour"/>
      <xsl:with-param name="len" select="2"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>
    <xsl:call-template name="lpad">
      <xsl:with-param name="str" select="@minute"/>
      <xsl:with-param name="len" select="2"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="dayOfWeek">
    <xsl:text>E&amp;</xsl:text>
    <xsl:value-of select="document('')//a:dayLookup/a:schedule[@name=current()/@day]/@value"/>
  </xsl:template>

  <xsl:template match="calendarDate">
    <xsl:text>E;</xsl:text>
    <xsl:call-template name="lpad">
      <xsl:with-param name="str" select="@month"/>
      <xsl:with-param name="len" select="2"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>
    <xsl:call-template name="lpad">
      <xsl:with-param name="str" select="@day"/>
      <xsl:with-param name="len" select="2"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>
    <xsl:call-template name="lpad">
      <xsl:with-param name="str" select="@year"/>
      <xsl:with-param name="len" select="2"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="beep">
    <xsl:text>E(</xsl:text>
    <xsl:choose>
      <xsl:when test="@type">
	<xsl:choose>
	  <xsl:when test="@type='on'">
	    <xsl:text>A</xsl:text>
	  </xsl:when>
	  <xsl:when test="@type='off'">
	    <xsl:text>B</xsl:text>
	  </xsl:when>
	  <xsl:when test="@type='long'">
	    <xsl:text>0</xsl:text>
	  </xsl:when>
	  <xsl:when test="@type='short'">
	    <xsl:text>1</xsl:text>
	  </xsl:when>
	</xsl:choose>
      </xsl:when>
      <xsl:when test="@frequency and @duration and @repeat">
	<xsl:text>2</xsl:text>
	<xsl:call-template name="toPaddedHex">
	  <xsl:with-param name="dec" select="@frequency"/>
	  <xsl:with-param name="len" select="2"/>
	</xsl:call-template>
	<xsl:call-template name="toPaddedHex">
	  <xsl:with-param name="dec" select="@duration"/>
	  <xsl:with-param name="len" select="1"/>
	</xsl:call-template>
	<xsl:call-template name="toPaddedHex">
	  <xsl:with-param name="dec" select="@repeat"/>
	  <xsl:with-param name="len" select="1"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>0</xsl:text>
      </xsl:otherwise>	
      <!-- not supported: store a programmable sound -->
      <!-- not supported: trigger a programmable sound -->
    </xsl:choose>
  </xsl:template>

  <xsl:template match="softReset">
    <xsl:text>E,</xsl:text>
  </xsl:template>

  <xsl:template match="dimmingMode">
    <xsl:text>E/</xsl:text>
    <xsl:choose>
      <xsl:when test="@threshold">
	<xsl:call-template name="lpad">
	  <xsl:with-param name="str" select="@threshold"/>
	  <xsl:with-param name="len" select="2"/>
	  <xsl:with-param name="chr" select="0"/>
	</xsl:call-template>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="@level">
	<xsl:call-template name="lpad">
	  <xsl:with-param name="str" select="@level"/>
	  <xsl:with-param name="len" select="2"/>
	  <xsl:with-param name="chr" select="0"/>
	</xsl:call-template>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="@start">
	<xsl:value-of select="document('')//a:timeLookup/a:time[@name=current()/@start]/@value"/>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="@stop">
	<xsl:value-of select="document('')//a:timeLookup/a:time[@name=current()/@stop]/@value"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="clearSerialErrorStatusRegister">
    <xsl:text>E4</xsl:text>
  </xsl:template>

  <xsl:template match="counterConfig">
    <xsl:text>E5</xsl:text>
    <xsl:call-template name="counter">
      <xsl:with-param name="counter" select="counter[@id = '1']"/>
      <xsl:with-param name="id" select="'1'"/>
    </xsl:call-template>
    <xsl:call-template name="counter">
      <xsl:with-param name="counter" select="counter[@id = '2']"/>
      <xsl:with-param name="id" select="'2'"/>
    </xsl:call-template>
    <xsl:call-template name="counter">
      <xsl:with-param name="counter" select="counter[@id = '3']"/>
      <xsl:with-param name="id" select="'3'"/>
    </xsl:call-template>
    <xsl:call-template name="counter">
      <xsl:with-param name="counter" select="counter[@id = '4']"/>
      <xsl:with-param name="id" select="'4'"/>
    </xsl:call-template>
    <xsl:call-template name="counter">
      <xsl:with-param name="counter" select="counter[@id = '5']"/>
      <xsl:with-param name="id" select="'5'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="counter">
    <xsl:param name="counter"/>
    <xsl:param name="id"/>
    <xsl:choose>
      <xsl:when test="$counter">
	<xsl:apply-templates select="$counter"/>
      </xsl:when> 
      <xsl:otherwise>
	<xsl:value-of select="$id"/>
	<xsl:value-of select="'64FF0000000000000000010000000000000000000000'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="counterConfig/counter">
    <xsl:value-of select="@id"/>
    <xsl:call-template name="toPaddedHex">
      <xsl:with-param name="dec">
	<xsl:call-template name="bitMask">
	  <xsl:with-param name="b7"
			  select="not(counterOptions/@enabled)
				  or counterOptions/@enabled = 'true'"/>
	  <xsl:with-param name="b6"
			  select="not(counterValues/@increment)
				  or counterValues/@increment &gt;= 0"/>
	  <xsl:with-param name="b5"
			  select="contains(counterOptions/@eventToCount, 'minutes')"/>
	  <xsl:with-param name="b4"
			  select="contains(counterOptions/@eventToCount, 'hours')"/>
	  <xsl:with-param name="b3"
			  select="contains(counterOptions/@eventToCount, 'days')"/>
	  <xsl:with-param name="b2"
			  select="not(counterSchedule/@weekends)
				  or counterSchedule/@weekends = 'true'"/>
	  <xsl:with-param name="b1"
			  select="counterOptions/@autoReset = 'true'"/>
	  <xsl:with-param name="b0"
			  select="false()"/>
	</xsl:call-template>
      </xsl:with-param>
      <xsl:with-param name="len" select="2"/>
    </xsl:call-template>

    <xsl:choose>
      <xsl:when test="counterSchedule/@start">
	<xsl:value-of
	   select="document('')
		   //a:timeLookup/a:time[@name=current()/counterSchedule/@start]
		   /@value"/>
      </xsl:when>
      <xsl:otherwise>FF</xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="counterSchedule/@stop">
	<xsl:value-of
	   select="document('')
		   //a:timeLookup/a:time[@name=current()/counterSchedule/@stop]
		   /@value"/>
      </xsl:when>
      <xsl:otherwise>00</xsl:otherwise>
    </xsl:choose>

    <xsl:call-template name="lpad">
      <xsl:with-param name="str" select="counterValues/@start"/>
      <xsl:with-param name="len" select="8"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>

    <xsl:call-template name="lpad">
      <xsl:with-param name="str">
	<xsl:choose>
	  <xsl:when test="not(counterValues/@increment)">
	    <xsl:value-of select="'1'"/>
	  </xsl:when>
	  <xsl:when test="counterValues/@increment &lt; 0">
	    <xsl:value-of select="-1 * counterValues/@increment"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="counterValues/@increment"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="len" select="8"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>

    <xsl:call-template name="lpad">
      <xsl:with-param name="str" select="counterValues/@current"/>
      <xsl:with-param name="len" select="8"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>

    <xsl:call-template name="lpad">
      <xsl:with-param name="str" select="counterValues/@target"/>
      <xsl:with-param name="len" select="8"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>

    <xsl:call-template name="toPaddedHex">
      <xsl:with-param name="dec">
	<xsl:call-template name="bitMask">
	  <xsl:with-param name="b7" select="false()"/>
	  <xsl:with-param name="b6" select="false()"/>
	  <xsl:with-param name="b5" select="false()"/>
	  <xsl:with-param name="b4" select="contains(targetFile/@labels,'1')"/>
	  <xsl:with-param name="b3" select="contains(targetFile/@labels,'2')"/>
	  <xsl:with-param name="b2" select="contains(targetFile/@labels,'3')"/>
	  <xsl:with-param name="b1" select="contains(targetFile/@labels,'4')"/>
	  <xsl:with-param name="b0" select="contains(targetFile/@labels,'5')"/>
	</xsl:call-template>
      </xsl:with-param>
      <xsl:with-param name="len" select="2"/>
    </xsl:call-template>

    <xsl:call-template name="toPaddedHex">
      <xsl:with-param name="dec" select="eventTime/@minute"/>
      <xsl:with-param name="len" select="2"/>
    </xsl:call-template>

    <xsl:call-template name="toPaddedHex">
      <xsl:with-param name="dec" select="eventTime/@hour"/>
      <xsl:with-param name="len" select="2"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="counterValue">
    <xsl:text>_08</xsl:text>
    <xsl:choose>
      <xsl:when test="@id = '1'">z</xsl:when>
      <xsl:when test="@id = '2'">{</xsl:when>
      <xsl:when test="@id = '3'">|</xsl:when>
      <xsl:when test="@id = '4'">}</xsl:when>
      <xsl:when test="@id = '5'">~</xsl:when>
      <xsl:otherwise>z</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="temperatureDisplay">
    <xsl:text>_08</xsl:text>
    <xsl:choose>
      <xsl:when test="@units = 'C'">_1C</xsl:when>
      <xsl:when test="@units = 'F'">_1D</xsl:when>
      <xsl:otherwise>_1D</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="temperatureOffset">
    <xsl:text>ET</xsl:text>
    <xsl:choose>
      <xsl:when test="@offset">
	<xsl:choose>
	  <xsl:when test="@offset &lt; 0">-</xsl:when>
	  <xsl:otherwise>+</xsl:otherwise>
	</xsl:choose>
	<xsl:choose>
	  <xsl:when test="@offset &lt; 0">
	    <xsl:value-of select="-1 * @offset"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="@offset"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:when test="@temperature">
	<xsl:choose>
	  <xsl:when test="@temperature &lt; 0">-</xsl:when>
	  <xsl:otherwise>+</xsl:otherwise>
	</xsl:choose>
	<xsl:choose>
	  <xsl:when test="@temperature &lt; 0">
	    <xsl:call-template name="toPaddedHex">
	      <xsl:with-param name="dec" select="-1 * @temperature"/>
	      <xsl:with-param name="len" select="3"/>
	    </xsl:call-template>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:call-template name="toPaddedHex">
	      <xsl:with-param name="dec" select="@temperature"/>
	      <xsl:with-param name="len" select="3"/>
	    </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="signAddress">
    <xsl:text>E7</xsl:text>
    <xsl:value-of select="@address"/>
  </xsl:template>

  <xsl:template match="xyTextMode">
    <xsl:text>E+</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="xyTextMode[@enabled = 'false']">
    <xsl:text>E-</xsl:text>
  </xsl:template>

  <xsl:template match="xyTextMode[xyText]">
    <xsl:text>E+</xsl:text>
    <xsl:text>+</xsl:text>
    <xsl:apply-templates select="xyText"/>
  </xsl:template>

  <xsl:template match="xyTextMode/xyText">
    <xsl:if test="position() != 1">
      <xsl:text>_12</xsl:text>
    </xsl:if>
    <xsl:call-template name="lpad">
      <xsl:with-param name="str" select="@x"/>
      <xsl:with-param name="len" select="2"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>
    <xsl:call-template name="lpad">
      <xsl:with-param name="str" select="@y"/>
      <xsl:with-param name="len" select="2"/>
      <xsl:with-param name="chr" select="0"/>
    </xsl:call-template>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="string">
    <xsl:text>G</xsl:text>
    <xsl:value-of select="@label"/>
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="text">
    <xsl:text>A</xsl:text>
    <xsl:value-of select="@label"/>
    <!-- The mode, position, and trailingMode attributes are
    deprecated.  Use the "text/mode" element instead. -->
    <xsl:if test="@mode">
      <xsl:text>_1B</xsl:text>
      <xsl:choose>
	<xsl:when test="@position = 'top'">
	  <xsl:text>&quot;</xsl:text>
	</xsl:when>
	<xsl:when test="@position = 'bottom'">
	  <xsl:text>&amp;</xsl:text>
	</xsl:when>
	<xsl:when test="@position = 'fill'">
	  <xsl:text>0</xsl:text>
	</xsl:when>
	<xsl:when test="@position = 'middle'">
	  <xsl:text> </xsl:text>
	</xsl:when>
	<xsl:when test="@position = 'left'">
	  <xsl:text>1</xsl:text>
	</xsl:when>
	<xsl:when test="@position = 'right'">
	  <xsl:text>2</xsl:text>
	</xsl:when>
	<xsl:otherwise>	        <!-- middle -->
	  <xsl:text> </xsl:text>
	</xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="document('')//a:modeLookup/a:mode[@name=current()/@mode]/@value"/>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="@trailingMode">
      <xsl:text>_1B </xsl:text>
      <xsl:value-of select="document('')//a:modeLookup/a:mode[@name=current()/@trailingMode]/@value"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="mode">
    <xsl:text>_1B</xsl:text>
    <xsl:choose>
      <xsl:when test="@position = 'top'">
	<xsl:text>&quot;</xsl:text>
      </xsl:when>
      <xsl:when test="@position = 'bottom'">
	<xsl:text>&amp;</xsl:text>
      </xsl:when>
      <xsl:when test="@position = 'fill'">
	<xsl:text>0</xsl:text>
      </xsl:when>
      <xsl:when test="@position = 'middle'">
	<xsl:text> </xsl:text>
      </xsl:when>
      <xsl:when test="@position = 'left'">
	<xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="@position = 'right'">
	<xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:otherwise>	        <!-- middle -->
	<xsl:text> </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="document('')//a:modeLookup/a:mode[@name=current()/@display]/@value"/>
  </xsl:template>

  <xsl:template match="dots">
    <xsl:text>I</xsl:text>
    <xsl:value-of select="@label"/>
    <xsl:call-template name="toPaddedHex">
      <xsl:with-param name="dec" select="count(./row)"/>
      <xsl:with-param name="len" select="2"/>
    </xsl:call-template>
    <xsl:call-template name="toPaddedHex">
      <xsl:with-param name="dec" select="string-length(./row[1]/text())"/>
      <xsl:with-param name="len" select="2"/>
    </xsl:call-template>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="dots/row">
    <xsl:apply-templates/>
    <xsl:text>_0D</xsl:text>
  </xsl:template>

  <xsl:template match="dots/row/text()">
    <xsl:value-of select="."/>
  </xsl:template>


  <!-- Text formatting -->

  <xsl:template match="wideModeOff">
    <xsl:text>_11</xsl:text>
  </xsl:template>

  <xsl:template match="wideModeOn">
    <xsl:text>_12</xsl:text>
  </xsl:template>

  <xsl:template match="doubleHighModeOff">
    <xsl:text>_050</xsl:text>
  </xsl:template>

  <xsl:template match="doubleHighModeOn">
    <xsl:text>_051</xsl:text>
  </xsl:template>

  <xsl:template match="trueDescendersModeOff">
    <xsl:text>_060</xsl:text>
  </xsl:template>

  <xsl:template match="trueDescendersModeOn">
    <xsl:text>_061</xsl:text>
  </xsl:template>

  <xsl:template match="fixedWidthModeOff">
    <xsl:text>_1E0</xsl:text>
  </xsl:template>

  <xsl:template match="fixedWidthModeOn">
    <xsl:text>_1E1</xsl:text>
  </xsl:template>

  <xsl:template match="flashModeOff">
    <xsl:text>_070</xsl:text>
  </xsl:template>

  <xsl:template match="flashModeOn">
    <xsl:text>_071</xsl:text>
  </xsl:template>

  <!-- speeds -->

  <xsl:template match="noHold">
    <xsl:text>_09</xsl:text>
  </xsl:template>

  <xsl:template match="speedControl">
    <xsl:text>_0F</xsl:text>
    <xsl:choose>
      <xsl:when test="@minutes">
	<xsl:text>M</xsl:text>
	<xsl:call-template name="toPaddedHex">
	  <xsl:with-param name="dec" select="@minutes"/>
	  <xsl:with-param name="len" select="2"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:when test="@seconds">
	<xsl:call-template name="toPaddedHex">
	  <xsl:with-param name="dec" select="@seconds"/>
	  <xsl:with-param name="len" select="2"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:when test="@deciseconds">
	<xsl:text>T</xsl:text>
	<xsl:call-template name="toPaddedHex">
	  <xsl:with-param name="dec" select="@deciseconds"/>
	  <xsl:with-param name="len" select="3"/>
	</xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>00</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="speed1">
    <xsl:text>_15</xsl:text>
  </xsl:template>

  <xsl:template match="speed2">
    <xsl:text>_16</xsl:text>
  </xsl:template>

  <xsl:template match="speed3">
    <xsl:text>_17</xsl:text>
  </xsl:template>

  <xsl:template match="speed4">
    <xsl:text>_18</xsl:text>
  </xsl:template>

  <xsl:template match="speed5">
    <xsl:text>_19</xsl:text>
  </xsl:template>

  <!-- char mode -->

  <xsl:template match="standard5">
    <xsl:text>_1A1</xsl:text>
  </xsl:template>

  <xsl:template match="slim5">
    <xsl:text>_1A1</xsl:text>
  </xsl:template>

  <xsl:template match="stroke5">
    <xsl:text>_1A2</xsl:text>
  </xsl:template>

  <xsl:template match="standard7">
    <xsl:text>_1A3</xsl:text>
  </xsl:template>

  <xsl:template match="slim7">
    <xsl:text>_1A3</xsl:text>
  </xsl:template>

  <xsl:template match="stroke7">
    <xsl:text>_1A4</xsl:text>
  </xsl:template>

  <xsl:template match="fancy7">
    <xsl:text>_1A5</xsl:text>
  </xsl:template>

  <xsl:template match="slimFancy7">
    <xsl:text>_1A5</xsl:text>
  </xsl:template>

  <xsl:template match="standard10">
    <xsl:text>_1A6</xsl:text>
  </xsl:template>

  <xsl:template match="strokeFancy7">
    <xsl:text>_1A6</xsl:text>
  </xsl:template>

  <xsl:template match="shadow7">
    <xsl:text>_1A7</xsl:text>
  </xsl:template>

  <xsl:template match="fullHeightFancy">
    <xsl:text>_1A8</xsl:text>
  </xsl:template>

  <xsl:template match="wideStrokeFancy7">
    <xsl:text>_1A8</xsl:text>
  </xsl:template>

  <xsl:template match="fullHeightStandard">
    <xsl:text>_1A9</xsl:text>
  </xsl:template>

  <xsl:template match="wideStroke7">
    <xsl:text>_1A9</xsl:text>
  </xsl:template>

  <xsl:template match="shadowFancy7">
    <xsl:text>_1A:</xsl:text>
  </xsl:template>

  <xsl:template match="wide5">
    <xsl:text>_1A;</xsl:text>
  </xsl:template>

  <xsl:template match="wide7">
    <xsl:text>_1A&lt;</xsl:text>
  </xsl:template>

  <xsl:template match="wideFancy7">
    <xsl:text>_1A=</xsl:text>
  </xsl:template>

  <xsl:template match="wideStroke5">
    <xsl:text>_1A&gt;</xsl:text>
  </xsl:template>

  <xsl:template match="custom5">
    <xsl:text>_1AW</xsl:text>
  </xsl:template>

  <xsl:template match="custom7">
    <xsl:text>_1AX</xsl:text>
  </xsl:template>

  <xsl:template match="custom10">
    <xsl:text>_1AY</xsl:text>
  </xsl:template>

  <xsl:template match="custom15">
    <xsl:text>_1AZ</xsl:text>
  </xsl:template>

  <!-- colors -->

  <xsl:template match="red">
    <xsl:text>_1C1</xsl:text>
  </xsl:template>

  <xsl:template match="green">
    <xsl:text>_1C2</xsl:text>
  </xsl:template>

  <xsl:template match="amber">
    <xsl:text>_1C3</xsl:text>
  </xsl:template>

  <xsl:template match="dimred">
    <xsl:text>_1C4</xsl:text>
  </xsl:template>

  <xsl:template match="dimgreen">
    <xsl:text>_1C5</xsl:text>
  </xsl:template>

  <xsl:template match="brown">
    <xsl:text>_1C6</xsl:text>
  </xsl:template>

  <xsl:template match="orange">
    <xsl:text>_1C7</xsl:text>
  </xsl:template>

  <xsl:template match="yellow">
    <xsl:text>_1C8</xsl:text>
  </xsl:template>

  <xsl:template match="rainbow1">
    <xsl:text>_1C9</xsl:text>
  </xsl:template>

  <xsl:template match="rainbow2">
    <xsl:text>_1CA</xsl:text>
  </xsl:template>

  <xsl:template match="colormix">
    <xsl:text>_1CB</xsl:text>
  </xsl:template>

  <xsl:template match="autocolor">
    <xsl:text>_1CC</xsl:text>
  </xsl:template>

  <!-- char attribute -->

  <xsl:template match="wideOff">
    <xsl:text>_1D00</xsl:text>
  </xsl:template>

  <xsl:template match="wideOn">
    <xsl:text>_1D01</xsl:text>
  </xsl:template>

  <xsl:template match="doubleWideOff">
    <xsl:text>_1D10</xsl:text>
  </xsl:template>

  <xsl:template match="doubleWideOn">
    <xsl:text>_1D11</xsl:text>
  </xsl:template>

  <xsl:template match="doubleHighOff">
    <xsl:text>_1D20</xsl:text>
  </xsl:template>

  <xsl:template match="doubleHighOn">
    <xsl:text>_1D21</xsl:text>
  </xsl:template>

  <xsl:template match="trueDescendersOff">
    <xsl:text>_1D30</xsl:text>
  </xsl:template>

  <xsl:template match="trueDescendersOn">
    <xsl:text>_1D31</xsl:text>
  </xsl:template>

  <xsl:template match="fixedWidthOff">
    <xsl:text>_1D40</xsl:text>
  </xsl:template>

  <xsl:template match="fixedWidthOn">
    <xsl:text>_1D41</xsl:text>
  </xsl:template>

  <xsl:template match="fancyOff">
    <xsl:text>_1D50</xsl:text>
  </xsl:template>

  <xsl:template match="fancyOn">
    <xsl:text>_1D51</xsl:text>
  </xsl:template>

  <xsl:template match="auxPortOff">
    <xsl:text>_1D60</xsl:text>
  </xsl:template>

  <xsl:template match="auxPortOn">
    <xsl:text>_1D61</xsl:text>
  </xsl:template>

  <xsl:template match="shadowOff">
    <xsl:text>_1D70</xsl:text>
  </xsl:template>

  <xsl:template match="shadowOn">
    <xsl:text>_1D71</xsl:text>
  </xsl:template>


  <!-- insert special data -->

  <xsl:template match="extendedChar">
    <xsl:text>_08_</xsl:text>
    <xsl:value-of select="@offset"/>
  </xsl:template>

  <xsl:template match="date[@format = 'MM/DD/YY']">
    <xsl:text>_0B0</xsl:text>
  </xsl:template>

  <xsl:template match="date[@format = 'DD/MM/YY']">
    <xsl:text>_0B1</xsl:text>
  </xsl:template>

  <xsl:template match="date[@format = 'MM-DD-YY']">
    <xsl:text>_0B2</xsl:text>
  </xsl:template>

  <xsl:template match="date[@format = 'DD-MM-YY']">
    <xsl:text>_0B3</xsl:text>
  </xsl:template>

  <xsl:template match="date[@format = 'MM.DD.YY']">
    <xsl:text>_0B4</xsl:text>
  </xsl:template>

  <xsl:template match="date[@format = 'DD.MM.YY']">
    <xsl:text>_0B5</xsl:text>
  </xsl:template>

  <xsl:template match="date[@format = 'MM DD YY']">
    <xsl:text>_0B6</xsl:text>
  </xsl:template>

  <xsl:template match="date[@format = 'DD MM YY']">
    <xsl:text>_0B7</xsl:text>
  </xsl:template>

  <xsl:template match="date[@format = 'MMM.DD, YYYY']">
    <xsl:text>_0B8</xsl:text>
  </xsl:template>

  <xsl:template match="date[@format = 'day']">
    <xsl:text>_0B9</xsl:text>
  </xsl:template>

  <xsl:template match="time">
    <xsl:text>_13</xsl:text>
  </xsl:template>

  <xsl:template match="FF">
    <xsl:text>_0C</xsl:text>
  </xsl:template>

  <xsl:template match="CR">
    <xsl:text>_0D</xsl:text>
  </xsl:template>


  <!-- call out -->

  <xsl:template match="callString">
    <xsl:text>_10</xsl:text>
    <xsl:value-of select="@label"/>
  </xsl:template>

  <xsl:template match="callDots">
    <xsl:text>_14</xsl:text>
    <xsl:value-of select="@label"/>
  </xsl:template>

  <xsl:template match="callLargeDots">
    <xsl:text>_1F</xsl:text>
    <xsl:value-of select="@label"/>
    <!-- This feature is not yet supported. -->
  </xsl:template>


  <!-- misc -->

  <xsl:template match="msg">
    <xsl:apply-templates/>
  </xsl:template>


  <!-- read -->

  <xsl:template match="readText">
    <xsl:text>B</xsl:text>
    <xsl:value-of select="@label"/>
  </xsl:template>

  <xsl:template match="readString">
    <xsl:text>H</xsl:text>
    <xsl:value-of select="@label"/>
  </xsl:template>

  <xsl:template match="readDots">
    <xsl:text>J</xsl:text>
    <xsl:value-of select="@label"/>
  </xsl:template>

  <xsl:template match="readLargeDots">
    <xsl:text>N</xsl:text>
    <xsl:value-of select="@label"/>
  </xsl:template>

  <xsl:template match="readRGBDots">
    <xsl:text>L</xsl:text>
    <xsl:value-of select="@label"/>
  </xsl:template>

  <xsl:template match="readTimeOfDay">
    <xsl:text>F </xsl:text>
  </xsl:template>

  <xsl:template match="readSpeakerMode">
    <xsl:text>F!</xsl:text>
  </xsl:template>

  <xsl:template match="readGeneralInfo">
    <xsl:text>F&quot;</xsl:text>
  </xsl:template>

  <xsl:template match="readMemoryPoolSize">
    <xsl:text>F#</xsl:text>
  </xsl:template>

  <xsl:template match="readMemoryConfig">
    <xsl:text>F$</xsl:text>
  </xsl:template>

  <xsl:template match="readMemoryDump">
    <xsl:text>F%</xsl:text>
  </xsl:template>

  <xsl:template match="readDayOfWeek">
    <xsl:text>F&amp;</xsl:text>
  </xsl:template>

  <xsl:template match="readTimeFormat">
    <xsl:text>F'</xsl:text>
  </xsl:template>

  <xsl:template match="readTimeScheduleTable">
    <xsl:text>F)</xsl:text>
  </xsl:template>

  <xsl:template match="readSerialErrorStatusRegister">
    <xsl:text>F*</xsl:text>
  </xsl:template>

  <xsl:template match="readNetworkQuery">
    <xsl:text>F-</xsl:text>
  </xsl:template>

  <xsl:template match="readSequence">
    <xsl:text>F.</xsl:text>
  </xsl:template>

  <xsl:template match="readDayScheduleTable">
    <xsl:text>F2</xsl:text>
  </xsl:template>

  <xsl:template match="readCounters">
    <xsl:text>F5</xsl:text>
  </xsl:template>

  <xsl:template match="readAlphavisionDOTSMemoryConfig">
    <xsl:text>F8</xsl:text>
  </xsl:template>

  <xsl:template match="readRunFileTimes">
    <xsl:text>F:</xsl:text>
  </xsl:template>

  <xsl:template match="readDate">
    <xsl:text>F;</xsl:text>
  </xsl:template>

  <xsl:template match="readDaylightSavingTime">
    <xsl:text>F=</xsl:text>
  </xsl:template>

  <xsl:template match="readAutoModeTable">
    <xsl:text>F&gt;</xsl:text>
  </xsl:template>

  <xsl:template match="readTemperatureOffset">
    <xsl:text>FT</xsl:text>
  </xsl:template>

  <!-- lookup tables -->

  <a:modeLookup>
    <a:mode name="rotate" value="a"/>
    <a:mode name="hold" value="b"/>
    <a:mode name="flash" value="c"/>
    <a:mode name="rollUp" value="e"/>
    <a:mode name="rollDown" value="f"/>
    <a:mode name="rollLeft" value="g"/>
    <a:mode name="rollRight" value="h"/>
    <a:mode name="wipeUp" value="i"/>
    <a:mode name="wipeDown" value="j"/>
    <a:mode name="wipeLeft" value="k"/>
    <a:mode name="wipeRight" value="l"/>
    <a:mode name="scroll" value="m"/>
    <a:mode name="automode" value="o"/>
    <a:mode name="rollIn" value="p"/>
    <a:mode name="rollOut" value="q"/>
    <a:mode name="wipeIn" value="r"/>
    <a:mode name="wipeOut" value="s"/>
    <a:mode name="compressedRotate" value="t"/>
    <a:mode name="explode" value="u"/>
    <a:mode name="clock" value="v"/>
    <a:mode name="twinkle" value="n0"/>
    <a:mode name="sparkle" value="n1"/>
    <a:mode name="snow" value="n2"/>
    <a:mode name="interlock" value="n3"/>
    <a:mode name="switch" value="n4"/>
    <a:mode name="slide" value="n5"/>
    <a:mode name="cycleColors" value="n5"/>
    <a:mode name="spray" value="n6"/>
    <a:mode name="starburst" value="n7"/>
    <a:mode name="welcome" value="n8"/>
    <a:mode name="slotMachine" value="n9"/>
    <a:mode name="newsFlash" value="nA"/>
    <a:mode name="trumpet" value="nB"/>
    <a:mode name="thankYou" value="nS"/>
    <a:mode name="noSmoking" value="nU"/>
    <a:mode name="drinkAndDrive" value="nV"/>
    <a:mode name="runningAnimal" value="nW"/>
    <a:mode name="fish" value="nW"/>
    <a:mode name="fireworks" value="nX"/>
    <a:mode name="turboCar" value="nY"/>
    <a:mode name="balloon" value="nY"/>
    <a:mode name="cherryBomb" value="nZ"/>
  </a:modeLookup>

  <a:dayLookup>
    <a:schedule name="daily" value="0"/>
    <a:schedule name="Sunday" value="1"/>
    <a:schedule name="Monday" value="2"/>
    <a:schedule name="Tuesday" value="3"/>
    <a:schedule name="Wednesday" value="4"/>
    <a:schedule name="Thursday" value="5"/>
    <a:schedule name="Friday" value="6"/>
    <a:schedule name="Saturday" value="7"/>
    <a:schedule name="Monday-Friday" value="8"/>
    <a:schedule name="weekends" value="9"/>
    <a:schedule name="always" value="A"/>
    <a:schedule name="never" value="B"/>
  </a:dayLookup>

  <a:timeLookup>
    <a:time name="00:00" value="00"/>
    <a:time name="00:10" value="01"/>
    <a:time name="00:20" value="02"/>
    <a:time name="00:30" value="03"/>
    <a:time name="00:40" value="04"/>
    <a:time name="00:50" value="05"/>
    <a:time name="01:00" value="06"/>
    <a:time name="01:10" value="07"/>
    <a:time name="01:20" value="08"/>
    <a:time name="01:30" value="09"/>
    <a:time name="01:40" value="0A"/>
    <a:time name="01:50" value="0B"/>
    <a:time name="02:00" value="0C"/>
    <a:time name="02:10" value="0D"/>
    <a:time name="02:20" value="0E"/>
    <a:time name="02:30" value="0F"/>
    <a:time name="02:40" value="10"/>
    <a:time name="02:50" value="11"/>
    <a:time name="03:00" value="12"/>
    <a:time name="03:10" value="13"/>
    <a:time name="03:20" value="14"/>
    <a:time name="03:30" value="15"/>
    <a:time name="03:40" value="16"/>
    <a:time name="03:50" value="17"/>
    <a:time name="04:00" value="18"/>
    <a:time name="04:10" value="19"/>
    <a:time name="04:20" value="1A"/>
    <a:time name="04:30" value="1B"/>
    <a:time name="04:40" value="1C"/>
    <a:time name="04:50" value="1D"/>
    <a:time name="05:00" value="1E"/>
    <a:time name="05:10" value="1F"/>
    <a:time name="05:20" value="20"/>
    <a:time name="05:30" value="21"/>
    <a:time name="05:40" value="22"/>
    <a:time name="05:50" value="23"/>
    <a:time name="06:00" value="24"/>
    <a:time name="06:10" value="25"/>
    <a:time name="06:20" value="26"/>
    <a:time name="06:30" value="27"/>
    <a:time name="06:40" value="28"/>
    <a:time name="06:50" value="29"/>
    <a:time name="07:00" value="2A"/>
    <a:time name="07:10" value="2B"/>
    <a:time name="07:20" value="2C"/>
    <a:time name="07:30" value="2D"/>
    <a:time name="07:40" value="2E"/>
    <a:time name="07:50" value="2F"/>
    <a:time name="08:00" value="30"/>
    <a:time name="08:10" value="31"/>
    <a:time name="08:20" value="32"/>
    <a:time name="08:30" value="33"/>
    <a:time name="08:40" value="34"/>
    <a:time name="08:50" value="35"/>
    <a:time name="09:00" value="36"/>
    <a:time name="09:10" value="37"/>
    <a:time name="09:20" value="38"/>
    <a:time name="09:30" value="39"/>
    <a:time name="09:40" value="3A"/>
    <a:time name="09:50" value="3B"/>
    <a:time name="10:00" value="3C"/>
    <a:time name="10:10" value="3D"/>
    <a:time name="10:20" value="3E"/>
    <a:time name="10:30" value="3F"/>
    <a:time name="10:40" value="40"/>
    <a:time name="10:50" value="41"/>
    <a:time name="11:00" value="42"/>
    <a:time name="11:10" value="43"/>
    <a:time name="11:20" value="44"/>
    <a:time name="11:30" value="45"/>
    <a:time name="11:40" value="46"/>
    <a:time name="11:50" value="47"/>
    <a:time name="12:00" value="48"/>
    <a:time name="12:10" value="49"/>
    <a:time name="12:20" value="4A"/>
    <a:time name="12:30" value="4B"/>
    <a:time name="12:40" value="4C"/>
    <a:time name="12:50" value="4D"/>
    <a:time name="13:00" value="4E"/>
    <a:time name="13:10" value="4F"/>
    <a:time name="13:20" value="50"/>
    <a:time name="13:30" value="51"/>
    <a:time name="13:40" value="52"/>
    <a:time name="13:50" value="53"/>
    <a:time name="14:00" value="54"/>
    <a:time name="14:10" value="55"/>
    <a:time name="14:20" value="56"/>
    <a:time name="14:30" value="57"/>
    <a:time name="14:40" value="58"/>
    <a:time name="14:50" value="59"/>
    <a:time name="15:00" value="5A"/>
    <a:time name="15:10" value="5B"/>
    <a:time name="15:20" value="5C"/>
    <a:time name="15:30" value="5D"/>
    <a:time name="15:40" value="5E"/>
    <a:time name="15:50" value="5F"/>
    <a:time name="16:00" value="60"/>
    <a:time name="16:10" value="61"/>
    <a:time name="16:20" value="62"/>
    <a:time name="16:30" value="63"/>
    <a:time name="16:40" value="64"/>
    <a:time name="16:50" value="65"/>
    <a:time name="17:00" value="66"/>
    <a:time name="17:10" value="67"/>
    <a:time name="17:20" value="68"/>
    <a:time name="17:30" value="69"/>
    <a:time name="17:40" value="6A"/>
    <a:time name="17:50" value="6B"/>
    <a:time name="18:00" value="6C"/>
    <a:time name="18:10" value="6D"/>
    <a:time name="18:20" value="6E"/>
    <a:time name="18:30" value="6F"/>
    <a:time name="18:40" value="70"/>
    <a:time name="18:50" value="71"/>
    <a:time name="19:00" value="72"/>
    <a:time name="19:10" value="73"/>
    <a:time name="19:20" value="74"/>
    <a:time name="19:30" value="75"/>
    <a:time name="19:40" value="76"/>
    <a:time name="19:50" value="77"/>
    <a:time name="20:00" value="78"/>
    <a:time name="20:10" value="79"/>
    <a:time name="20:20" value="7A"/>
    <a:time name="20:30" value="7B"/>
    <a:time name="20:40" value="7C"/>
    <a:time name="20:50" value="7D"/>
    <a:time name="21:00" value="7E"/>
    <a:time name="21:10" value="7F"/>
    <a:time name="21:20" value="80"/>
    <a:time name="21:30" value="81"/>
    <a:time name="21:40" value="82"/>
    <a:time name="21:50" value="83"/>
    <a:time name="22:00" value="84"/>
    <a:time name="22:10" value="85"/>
    <a:time name="22:20" value="86"/>
    <a:time name="22:30" value="87"/>
    <a:time name="22:40" value="88"/>
    <a:time name="22:50" value="89"/>
    <a:time name="23:00" value="8A"/>
    <a:time name="23:10" value="8B"/>
    <a:time name="23:20" value="8C"/>
    <a:time name="23:30" value="8D"/>
    <a:time name="23:40" value="8E"/>
    <a:time name="23:50" value="8F"/>
    <a:time name="all day" value="FD"/>
    <a:time name="never" value="FE"/>
    <a:time name="always" value="FF"/>
  </a:timeLookup>

  <!-- the following are for unit testing -->

  <xsl:template match="/tests">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="test-hex">
    <xsl:call-template name="toHex">
      <xsl:with-param name="dec" select="."/>
    </xsl:call-template>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>

  <xsl:template match="test-bitMask">
    <xsl:variable name="bits" select="text()"/>
    <xsl:call-template name="bitMask">
      <xsl:with-param name="b7" select="substring($bits,1,1) = 1"/>
      <xsl:with-param name="b6" select="substring($bits,2,1) = 1"/>
      <xsl:with-param name="b5" select="substring($bits,3,1) = 1"/>
      <xsl:with-param name="b4" select="substring($bits,4,1) = 1"/>
      <xsl:with-param name="b3" select="substring($bits,5,1) = 1"/>
      <xsl:with-param name="b2" select="substring($bits,6,1) = 1"/>
      <xsl:with-param name="b1" select="substring($bits,7,1) = 1"/>
      <xsl:with-param name="b0" select="substring($bits,8,1) = 1"/>
    </xsl:call-template>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>

  <xsl:template match="test-escapeText">
    <xsl:call-template name="escapeText">
      <xsl:with-param name="str" select="text()"/>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
