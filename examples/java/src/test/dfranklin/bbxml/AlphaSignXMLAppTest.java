package dfranklin.bbxml;

public class AlphaSignXMLAppTest
   extends junit.framework.TestCase
{
   public void testConvert3to1(byte[] exp, String str)
   {
      assertEquals(exp, AlphaSignXMLApp.convert3to1(str.getBytes()));
   }


   public void testConvert3to1()
   {
      testConvert3to1(new byte[] { 0x01 }, "_01");
      testConvert3to1("01".getBytes(), "01");
      testConvert3to1(new byte[] { 0x00 }, "_00");
      testConvert3to1(new byte[] { 0x01, 0x03, 0x33 }, "_01_03_33");
      testConvert3to1("hello".getBytes(), "hello");
      testConvert3to1("hello\u0001kitty".getBytes(), "hello_01kitty");
   }


   public void testConvert1to3(String exp, byte[] buf)
   {
      assertEquals(exp.getBytes(), AlphaSignXMLApp.convert1to3(buf));
   }


   public void testConvertConvert1to3()
   {
      testConvert1to3("_01", new byte[] { 0x01 });
      testConvert1to3("_01_02", new byte[] { 0x01, 0x02 });
      testConvert1to3("hello_01 kitty", "hello\u0001 kitty".getBytes());
   }


   public void assertEquals(byte[] buf1, byte[] buf2)
   {
      if (buf1 == buf2) return;
      assertNotNull(buf1);
      assertNotNull(buf2);
      assertEquals(buf1.length, buf2.length);
      for (int i = 0; i < buf1.length; i++)
      {
         assertEquals(buf1[i], buf2[i]);
      }
   }


}
