package dfranklin.bbxml;
/* Copyright 2006 Darin Franklin. All rights reserved. */
// See http://java.sun.com/products/javacomm/reference/api/index.html
// for gnu.io API. It is the same as javax.comm.
import gnu.io.CommPortIdentifier;
import gnu.io.NoSuchPortException;
import gnu.io.PortInUseException;
import gnu.io.SerialPort;
import gnu.io.UnsupportedCommOperationException;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Templates;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

/**
 * Command line application for controlling an Alpha LED sign.
 * 
 * See the BBXML User's Guide at http://darinfranklin.github.io/bbxml/doc/index.html for
 * for more information about creating the XML command files.
 */
public class AlphaSignXMLApp
{
   private static final int EOT = 0x04;
   private static boolean readFromPort = false;
   private static boolean useProto1 = false;
   private static String serialPortName;
   private static String xslFileName;
   private static String xmlFileName;
   private SerialPort serialPort;
   private int ioTimeoutMs = 5000;


   /**
    * Command line args: -port port_name -xsl alphasign.xsl -xml cmds.xml [
    * -read ] [ -proto1 ]
    */
   public static void main(String[] args)
      throws Exception
   {
      AlphaSignXMLApp app = new AlphaSignXMLApp();
      int i = 0;
      try
      {
         for (i = 0; i < args.length; i++)
         {
            if ("-port".equals(args[i]))
            {
               serialPortName = args[++i];
            }
            else if ("-xsl".equals(args[i]))
            {
               xslFileName = args[++i];
            }
            else if ("-xml".equals(args[i]))
            {
               xmlFileName = args[++i];
            }
            else if ("-read".equals(args[i]))
            {
               readFromPort = true;
            }
            else if ("-proto1".equals(args[i]))
            {
               useProto1 = true;
            }
         }
      }
      catch (ArrayIndexOutOfBoundsException e)
      {
         System.err.println("Arg requires an additional parameter: "
            + args[--i]);
         System.exit(1);
      }
      app.run();
   }


   public void run()
      throws Exception
   {
      openPort();
      try
      {
         configurePort();
         // create a buffer for the XSLT output
         ByteArrayOutputStream out = new ByteArrayOutputStream();
         transform(out);
         byte[] buf = out.toByteArray();
         if (useProto1) buf = convert3to1(buf);
         System.out.println("writing...");
         // write the buffer to the serial port
         writeToSerialPort(new ByteArrayInputStream(buf));
         if (readFromPort)
         {
            System.out.println("reading...");
            buf = readSerialPort();
            System.out.println("output (" + buf.length + " bytes):");
            if (useProto1) buf = convert1to3(buf);
            String reply = new String(buf);
            System.out.println(reply);
         }
      }
      finally
      {
         closePort();
      }
   }


   /**
    * Transform the XML file using the XSL file, writing result to the specified
    * OutputStream.
    */
   public void transform(OutputStream out)
      throws IOException, TransformerException
   {
      Source xslSource =
         new StreamSource(new FileInputStream(xslFileName), xslFileName);
      TransformerFactory f = TransformerFactory.newInstance();
      Templates xsl = f.newTemplates(xslSource);
      Source xmlSource =
         new StreamSource(new FileInputStream(xmlFileName), xmlFileName);
      Result result = new StreamResult(out);
      xsl.newTransformer().transform(xmlSource, result);
   }


   private void openPort()
      throws NoSuchPortException, PortInUseException,
      UnsupportedCommOperationException
   {
      CommPortIdentifier portID =
         CommPortIdentifier.getPortIdentifier(serialPortName);
      serialPort = (SerialPort) portID.open(getClass().getName(), ioTimeoutMs);
   }


   private void configurePort()
      throws UnsupportedCommOperationException
   {
      serialPort.setSerialPortParams(9600,
                                     SerialPort.DATABITS_7,
                                     SerialPort.STOPBITS_2,
                                     SerialPort.PARITY_EVEN);
      serialPort.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
   }


   private void closePort()
   {
      serialPort.close();
   }


   /**
    * Read from InputStream and write to the serial port.
    */
   public void writeToSerialPort(InputStream in)
      throws IOException
   {
      OutputStream out = serialPort.getOutputStream();
      int b;
      while (-1 != (b = in.read()))
      {
         out.write(b);
      }
   }


   public byte[] readSerialPort()
      throws IOException, UnsupportedCommOperationException
   {

      serialPort.enableReceiveTimeout(ioTimeoutMs);
      InputStream in = serialPort.getInputStream();
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      int b;
      while (-1 != (b = in.read()))
      {
         b &= 0x7F; // strip hi bit
         if (b == 0) continue; // skip the leading 0x00's
         out.write((byte) b); // (there are never 0x00's in data)
         if (b == EOT) break; // EOT. We're done.
      }
      return out.toByteArray();
   }


   /**
    * Convert 3-byte protocol message to 1-byte.
    */
   public static byte[] convert3to1(byte[] msg)
   {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      for (int i = 0; i < msg.length; i++)
      {
         if (msg[i] == '_')
         {
            out.write(Byte.parseByte(new String(msg, ++i, 2), 16));
            i++;
         }
         else
         {
            out.write(msg[i]);
         }
      }
      return out.toByteArray();
   }


   /**
    * Convert 1-byte protocol to 3-byte format.
    */
   public static byte[] convert1to3(byte[] msg)
   {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      for (int i = 0; i < msg.length; i++)
      {
         byte b = msg[i];
         if (b < 0x20)
         {
            out.write(("_" + hexString(b)).getBytes(), 0, 3);
         }
         else
         {
            out.write(b);
         }
      }
      return out.toByteArray();
   }


   private static String hexString(byte b)
   {
      String s = Integer.toHexString(b).toUpperCase();
      if (b < 0x10) s = "0" + s;
      return s;
   }
}
