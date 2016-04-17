package dragonbones.utils;

import flash.utils.ByteArray;

/** @private */
class BytesType
{
public static inline var SWF:String = "swf";
public static inline var PNG:String = "png";
public static inline var JPG:String = "jpg";
public static inline var ATF:String = "atf";
public static inline var ZIP:String = "zip";

public static function getType(bytes:ByteArray):String
{
	var outputType:String;
	var b1:UInt = bytes[0];
	var b2:UInt = bytes[1];
	var b3:UInt = bytes[2];
	var b4:UInt = bytes[3];
	if ((b1 == 0x46 || b1 == 0x43 || b1 == 0x5A) && b2 == 0x57 && b3 == 0x53)
	{
	//CWS FWS ZWS
	outputType = SWF;
	}
	else if (b1 == 0x89 && b2 == 0x50 && b3 == 0x4E && b4 == 0x47)
	{
	//89 50 4e 47 0d 0a 1a 0a
	outputType = PNG;
	}
	else if (b1 == 0xFF)
	{
	outputType = JPG;
	}
	else if (b1 == 0x41 && b2 == 0x54 && b3 == 0x46)
	{
	outputType = ATF;
	}
	else if (b1 == 0x50 && b2 == 0x4B)
	{
	outputType = ZIP;
	}
	return outputType;
}
}