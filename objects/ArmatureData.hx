package dragonbones.objects;

/** @private */
final import flash.Vector;

class ArmatureData
{
public var name:String;

private var _boneDataList:Vector<BoneData>;
private var _ikDataList:Vector<IKData>;
private var _skinDataList:Vector<SkinData>;
private var _slotDataList:Vector<SlotData>;
private var _animationDataList:Vector<AnimationData>;
public var defaultAnimation:String;
public var frameRate:UInt;

public function new()
{
	_boneDataList = new Vector<BoneData>(0, true);
	_ikDataList = new Vector<IKData>(0, true);
	_skinDataList = new Vector<SkinData>(0, true);
	_slotDataList = new Vector<SlotData>(0, true);
	_animationDataList = new Vector<AnimationData>(0, true);
	
	//_areaDataList = new Vector<IAreaData>(0, true);
}

public function setSkinData(skinName:String):Void
{
	for (var i:Int = 0, len:Int = _slotDataList.length; i < len; i++)
	{
	_slotDataList[i].dispose();
	}
	var skinData:SkinData;
	if(!skinName && _skinDataList.length > 0)
	{
	skinData = _skinDataList[0];
	}
	else
	{
	for (i = 0, len = _skinDataList.length; i < len; i++)
	{
		if (_skinDataList[i].name == skinName)
		{
		skinData = _skinDataList[i];
		break;
		}
	}
	}
	
	if (skinData)
	{
	var slotData:SlotData;
	for (i = 0, len = skinData.slotDataList.length; i < len; i++)
	{
		slotData = getSlotData(skinData.slotDataList[i].name);
		if (slotData)
		{
		for (var j:Int = 0, jLen:Int = skinData.slotDataList[i].displayDataList.length; j < jLen; j++)
		{
			slotData.addDisplayData(skinData.slotDataList[i].displayDataList[j]);
		}
		}
	}
	}
}

public function dispose():Void
{
	var i:Int = _boneDataList.length;
	while(i --)
	{
	_boneDataList[i].dispose();
	}
	i = _ikDataList.length;
	while(i --)
	{
	_ikDataList[i].dispose();
	}
	i = _skinDataList.length;
	while(i --)
	{
	_skinDataList[i].dispose();
	}
	i = _slotDataList.length;
	while(i --)
	{
	_slotDataList[i].dispose();
	}
	i = _animationDataList.length;
	while(i --)
	{
	_animationDataList[i].dispose();
	}
	
	_boneDataList.fixed = false;
	_boneDataList.length = 0;
	_ikDataList.fixed = false;
	_ikDataList.length = 0;
	_skinDataList.fixed = false;
	_skinDataList.length = 0;
	_slotDataList.fixed = false;
	_slotDataList.length = 0;
	_animationDataList.fixed = false;
	_animationDataList.length = 0;
	//_animationsCached。clear();
	_boneDataList = null;
	_ikDataList = null;
	_skinDataList = null;
	_slotDataList = null;
	_animationDataList = null;
}

public function getBoneData(boneName:String):BoneData
{
	var i:Int = _boneDataList.length;
	while(i --)
	{
	if(_boneDataList[i].name == boneName)
	{
		return _boneDataList[i];
	}
	}
	return null;
}
public function getIKData(ikName:String):IKData
{
	var i:Int = _ikDataList.length;
	while(i --)
	{
	if(_ikDataList[i].name == ikName)
	{
		return _ikDataList[i];
	}
	}
	return null;
}

public function getSlotData(slotName:String):SlotData
{
	if(!slotName && _slotDataList.length > 0)
	{
	return _slotDataList[0];
	}
	var i:Int = _slotDataList.length;
	while(i --)
	{
	if(_slotDataList[i].name == slotName)
	{
		return _slotDataList[i];
	}
	}
	
	return null;
}

public function getSkinData(skinName:String):SkinData
{
	if(!skinName && _skinDataList.length > 0)
	{
	return _skinDataList[0];
	}
	var i:Int = _skinDataList.length;
	while(i --)
	{
	if(_skinDataList[i].name == skinName)
	{
		return _skinDataList[i];
	}
	}
	
	return null;
}

public function getAnimationData(animationName:String):AnimationData
{
	var i:Int = _animationDataList.length;
	while(i --)
	{
	if(_animationDataList[i].name == animationName)
	{
		return _animationDataList[i];
	}
	}
	return null;
}

public function addBoneData(boneData:BoneData):Void
{
	if(!boneData)
	{
	throw new ArgumentError();
	}
	
	if (_boneDataList.indexOf(boneData) < 0)
	{
	_boneDataList.fixed = false;
	_boneDataList[_boneDataList.length] = boneData;
	_boneDataList.fixed = true;
	}
	else
	{
	throw new ArgumentError();
	}
}

public function addIKData(ikData:IKData):Void
{
	if(!ikData)
	{
	throw new ArgumentError();
	}
	if (_ikDataList.indexOf(ikData) < 0)
	{
	_ikDataList.fixed = false;
	_ikDataList[_ikDataList.length] = ikData;
	_ikDataList.fixed = true;
	}
	else
	{
	throw new ArgumentError();
	}
}

public function addSlotData(slotData:SlotData):Void
{
	if(!slotData)
	{
	throw new ArgumentError();
	}
	
	if(_slotDataList.indexOf(slotData) < 0)
	{
	_slotDataList.fixed = false;
	_slotDataList[_slotDataList.length] = slotData;
	_slotDataList.fixed = true;
	}
	else
	{
	throw new ArgumentError();
	}
}

public function addSkinData(skinData:SkinData):Void
{
	if(!skinData)
	{
	throw new ArgumentError();
	}
	
	if(_skinDataList.indexOf(skinData) < 0)
	{
	_skinDataList.fixed = false;
	_skinDataList[_skinDataList.length] = skinData;
	_skinDataList.fixed = true;
	}
	else
	{
	throw new ArgumentError();
	}
}

public function addAnimationData(animationData:AnimationData):Void
{
	if(!animationData)
	{
	throw new ArgumentError();
	}
	
	if(_animationDataList.indexOf(animationData) < 0)
	{
	_animationDataList.fixed = false;
	_animationDataList[_animationDataList.length] = animationData;
	_animationDataList.fixed = true;
	}
}

public function sortBoneDataList():Void
{
	var i:Int = _boneDataList.length;
	if(i == 0)
	{
	return;
	}
	
	var helpArray:Array = [];
	while(i --)
	{
	var boneData:BoneData = _boneDataList[i];
	var level:Int = 0;
	var parentData:BoneData = boneData;
	while(parentData)
	{
		level ++;
		parentData = getBoneData(parentData.parent);
	}
	helpArray[i] = [level, boneData];
	}
	
	helpArray.sortOn("0", Array.NUMERIC);
	
	i = helpArray.length;
	while(i --)
	{
	_boneDataList[i] = helpArray[i][1];
	}
}

public var boneDataList(getBoneDataList, null):Vector;
 	private function getBoneDataList():Vector<BoneData>
{
	return _boneDataList;
}
public var ikDataList(getIkDataList, null):Vector;
 	private function getIkDataList():Vector<IKData>
{
	return _ikDataList;
}
public var skinDataList(getSkinDataList, null):Vector;
 	private function getSkinDataList():Vector<SkinData>
{
	return _skinDataList;
}
public var animationDataList(getAnimationDataList, null):Vector;
 	private function getAnimationDataList():Vector<AnimationData>
{
	return _animationDataList;
}

public var slotDataList(getSlotDataList, null):Vector;
 	private function getSlotDataList():Vector<SlotData> 
{
	return _slotDataList;
}

/*
private var _areaDataList:Vector<IAreaData>;
public var areaDataList(getAreaDataList, null):Vector;
 	private function getAreaDataList():Vector<IAreaData>
{
	return _areaDataList;
}

public function getAreaData(areaName:String):IAreaData
{
	if(!areaName && _areaDataList.length > 0)
	{
	return _areaDataList[0];
	}
	var i:Int = _areaDataList.length;
	while(i --)
	{
	if(_areaDataList[i]["name"] == areaName)
	{
		return _areaDataList[i];
	}
	}
	return null;
}

public function addAreaData(areaData:IAreaData):Void
{
	if(!areaData)
	{
	throw new ArgumentError();
	}
	
	if(_areaDataList.indexOf(areaData) < 0)
	{
	_areaDataList.fixed = false;
	_areaDataList[_areaDataList.length] = areaData;
	_areaDataList.fixed = true;
	}
}
*/
}