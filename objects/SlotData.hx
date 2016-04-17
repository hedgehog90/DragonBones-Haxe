package dragonbones.objects;

/** @private */
public final class SlotData
{
public var name:String;
public var parent:String;
public var zOrder:Float;
public var blendMode:String;
public var displayIndex:Int;
public var gotoAndPlay:String;

private var _displayDataList:Vector<DisplayData>;

public function SlotData()
{
	_displayDataList = new Vector<DisplayData>(0, true);
	zOrder = 0;
}

public function dispose():Void
{
	_displayDataList.fixed = false;
	_displayDataList.length = 0;
}

public function addDisplayData(displayData:DisplayData):Void
{
	if(!displayData)
	{
	throw new ArgumentError();
	}
	if (_displayDataList.indexOf(displayData) < 0)
	{
	_displayDataList.fixed = false;
	_displayDataList[_displayDataList.length] = displayData;
	_displayDataList.fixed = true;
	}
	else
	{
	throw new ArgumentError();
	}
}

public function getDisplayData(displayName:String):DisplayData
{
	var i:Int = _displayDataList.length;
	while(i --)
	{
	if(_displayDataList[i].name == displayName)
	{
		return _displayDataList[i];
	}
	}
	
	return null;
}

public var displayDataList(getDisplayDataList, null):Vector;
 	private function getDisplayDataList():Vector<DisplayData>
{
	return _displayDataList;
}
}