package dragonbones.objects;

import flash.geom.Point;
import flash.utils.Dictionary;

import flash.Vector;

class DragonBonesData
{
public var name:String;
public var isGlobalData:Bool;
public var version:Float = 0;

private var _armatureDataList:Vector<ArmatureData> = new Vector<ArmatureData>(0, true);
private var _displayDataDictionary:Dictionary = new Dictionary();

public function new()
{
}

public function dispose():Void
{
	for each(var armatureData:ArmatureData in _armatureDataList)
	{
	armatureData.dispose();
	}
	_armatureDataList.fixed = false;
	_armatureDataList.length = 0;
	_armatureDataList = null;
	
	removeAllDisplayData();
	_displayDataDictionary = null;
}

public var armatureDataList(getArmatureDataList, null):Vector;
 	private function getArmatureDataList():Vector<ArmatureData>
{
	return _armatureDataList;
}

public function getArmatureDataByName(armatureName:String):ArmatureData
{
	var i:Int = _armatureDataList.length;
	while(i --)
	{
	if(_armatureDataList[i].name == armatureName)
	{
		return _armatureDataList[i];
	}
	}
	
	return null;
}

public function addArmatureData(armatureData:ArmatureData):Void
{
	if(!armatureData)
	{
	throw new ArgumentError();
	}
	
	if(_armatureDataList.indexOf(armatureData) < 0)
	{
	_armatureDataList.fixed = false;
	_armatureDataList[_armatureDataList.length] = armatureData;
	_armatureDataList.fixed = true;
	}
	else
	{
	throw new ArgumentError();
	}
}

public function removeArmatureData(armatureData:ArmatureData):Void
{
	var index:Int = _armatureDataList.indexOf(armatureData);
	if(index >= 0)
	{
	_armatureDataList.fixed = false;
	_armatureDataList.splice(index, 1);
	_armatureDataList.fixed = true;
	}
}

public function removeArmatureDataByName(armatureName:String):Void
{
	var i:Int = _armatureDataList.length;
	while(i --)
	{
	if(_armatureDataList[i].name == armatureName)
	{
		_armatureDataList.fixed = false;
		_armatureDataList.splice(i, 1);
		_armatureDataList.fixed = true;
	}
	}
}

public function getDisplayDataByName(name:String):DisplayData
{
	return _displayDataDictionary[name];
}

public function addDisplayData(displayData:DisplayData):Void
{
	_displayDataDictionary[displayData.name] = displayData;
}

public function removeDisplayDataByName(name:String):Void
{
	delete _displayDataDictionary[name]
}

public function removeAllDisplayData():Void
{
	for(var name:String in _displayDataDictionary)
	{
	delete _displayDataDictionary[name];
	}
}
}