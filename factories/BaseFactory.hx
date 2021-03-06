package dragonbones.factories;

import dragonBones.Armature;
import dragonBones.Bone;
import dragonBones.core.dragonBones_internal;
import dragonBones.fast.FastArmature;
import dragonBones.fast.FastBone;
import dragonBones.fast.FastSlot;
import dragonBones.objects.ArmatureData;
import dragonBones.objects.BoneData;
import dragonBones.objects.DataParser;
import dragonBones.objects.DataSerializer;
import dragonBones.objects.DecompressedData;
import dragonBones.objects.DisplayData;
import dragonBones.objects.DragonBonesData;
import dragonBones.objects.MeshData;
import dragonBones.objects.SkinData;
import dragonBones.objects.SlotData;
import dragonBones.Slot;
import dragonBones.textures.ITextureAtlas;
import flash.errors.IllegalOperationError;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Matrix;
import flash.utils.ByteArray;
import flash.utils.Dictionary;


import flash.Vector;

class BaseFactory  extends EventDispatcher
{
protected static const _helpMatrix:Matrix = new Matrix();

/** @private */
private var dragonBonesDataDic:Dictionary = new Dictionary();

/** @private */
private var textureAtlasDic:Dictionary = new Dictionary();
public function new(self:BaseFactory)
{
	super(this);
	
	if(self != this)
	{ 
	throw new IllegalOperationError("Abstract class can not be instantiated!");
	}
}

/**
 * Cleans up resources used by this BaseFactory instance.
 * @param (optional) Destroy all internal references.
 */
public function dispose(disposeData:Bool = true):Void
{
	if(disposeData)
	{
	for(var skeletonName:String in dragonBonesDataDic)
	{ 
		(dragonBonesDataDic[skeletonName] as DragonBonesData).dispose();
		delete dragonBonesDataDic[skeletonName];
	}
	
	for(var textureAtlasName:String in textureAtlasDic)
	{
		var textureAtlasArr:Array = textureAtlasDic[textureAtlasName] as Array<Dynamic>;
		if (textureAtlasArr)
		{
		for (var i:Int = 0, len:Int = textureAtlasArr.length; i < len; i++ )
		{
			textureAtlasArr[i].dispose();
		}
		}
		delete textureAtlasDic[textureAtlasName];
	}
	}
	
	dragonBonesDataDic = null;
	textureAtlasDic = null;
	//_currentDataName = null;
	//_currentTextureAtlasName = null;
}

/**
 * Returns a SkeletonData instance.
 * @param The name of an existing SkeletonData instance.
 * @return A SkeletonData instance with given name (if exist).
 */
public function getSkeletonData(name:String):DragonBonesData
{
	return dragonBonesDataDic[name];
}

/**
 * Add a SkeletonData instance to this BaseFactory instance.
 * @param A SkeletonData instance.
 * @param (optional) A name for this SkeletonData instance.
 */
public function addSkeletonData(data:DragonBonesData, name:String = null):Void
{
	if(!data)
	{
	throw new ArgumentError();
	}
	name = name || data.name;
	if(!name)
	{
	throw new ArgumentError("Unnamed data!");
	}
	if(dragonBonesDataDic[name])
	{
	throw new ArgumentError();
	}
	dragonBonesDataDic[name] = data;
}

/**
 * Remove a SkeletonData instance from this BaseFactory instance.
 * @param The name for the SkeletonData instance to remove.
 */
public function removeSkeletonData(name:String):Void
{
	delete dragonBonesDataDic[name];
}

/**
 * Return the TextureAtlas by name.
 * @param The name of the TextureAtlas to return.
 * @return A textureAtlas.
 */
public function getTextureAtlas(name:String):Object
{
	return textureAtlasDic[name];
}

/**
 * Add a textureAtlas to this BaseFactory instance.
 * @param A textureAtlas to add to this BaseFactory instance.
 * @param (optional) A name for this TextureAtlas.
 */
public function addTextureAtlas(textureAtlas:Object, name:String = null):Void
{
	if(!textureAtlas)
	{
	throw new ArgumentError();
	}
	if(!name && textureAtlas is ITextureAtlas)
	{
	name = textureAtlas.name;
	}
	if(!name)
	{
	throw new ArgumentError("Unnamed data!");
	}
	var textureAtlasArr:Array = textureAtlasDic[name] as Array<Dynamic>;
	if (textureAtlasArr == null)
	{
	textureAtlasArr = [];
	textureAtlasDic[name] = textureAtlasArr;
	}
	if(textureAtlasArr.indexOf(textureAtlas) != -1)
	{
	throw new ArgumentError();
	}
	textureAtlasArr.push(textureAtlas);
}

/**
 * Remove a textureAtlas from this baseFactory instance.
 * @param The name of the TextureAtlas to remove.
 */
public function removeTextureAtlas(name:String):Void
{
	delete textureAtlasDic[name];
}

/**
 * Return the TextureDisplay.
 * @param The name of this Texture.
 * @param The name of the TextureAtlas.
 * @param The registration pivotX position.
 * @param The registration pivotY position.
 * @return An Object.
 */
public function getTextureDisplay(textureName:String, textureAtlasName:String = null, pivotX:Float = NaN, pivotY:Float = NaN):Object
{
	var targetTextureAtlas:Object;
	var textureAtlasArr:Array;
	var i:Int;
	var len:Int;
	
	if(textureAtlasName)
	{
	textureAtlasArr = textureAtlasDic[textureAtlasName] as Array<Dynamic>;
	if (textureAtlasArr)
	{
		for (i = 0, len = textureAtlasArr.length; i < len; i++)
		{
		targetTextureAtlas = textureAtlasArr[i];
		if (targetTextureAtlas.getRegion(textureName))
		{
			break;
		}
		targetTextureAtlas = null;
		}
	}
	}
	else
	{
	for (textureAtlasName in textureAtlasDic)
	{
		textureAtlasArr = textureAtlasDic[textureAtlasName] as Array<Dynamic>;
		if (textureAtlasArr)
		{
		for (i = 0, len = textureAtlasArr.length; i < len; i++)
		{
			targetTextureAtlas = textureAtlasArr[i];
			if (targetTextureAtlas.getRegion(textureName))
			{
			break;
			}
			targetTextureAtlas = null;
		}
		if (targetTextureAtlas != null)
		{
			break;
		}
		}
	}
	}
	
	if(!targetTextureAtlas)
	{
	return null;
	}
	
	if(isNaN(pivotX) || isNaN(pivotY))
	{
	//默认dragonBonesData的名字和和纹理集的名字是一致的
	var data:DragonBonesData = dragonBonesDataDic[textureAtlasName];
	data = data ? data : findFirstDragonBonesData();
	if(data)
	{
		var displayData:DisplayData = data.getDisplayDataByName(textureName);
		if(displayData)
		{
		pivotX = displayData.pivot.x;
		pivotY = displayData.pivot.y;
		}
	}
	}
	
	return generateDisplay(targetTextureAtlas, textureName, pivotX, pivotY);
}

/**
 * Return the MeshDisplay.
 * @param The name of this Texture.
 * @param The name of the TextureAtlas.
 * @param The registration pivotX position.
 * @param The registration pivotY position.
 * @return An Object.
 */
public function getMeshDisplay(meshData:MeshData, textureAtlasName:String = null):Object
{
	var targetTextureAtlas:Object;
	var textureAtlasArr:Array;
	var i:Int;
	var len:Int;
	var textureName:String = meshData.name;
	if(textureAtlasName)
	{
	textureAtlasArr = textureAtlasDic[textureAtlasName] as Array<Dynamic>;
	if (textureAtlasArr)
	{
		for (i = 0, len = textureAtlasArr.length; i < len; i++)
		{
		targetTextureAtlas = textureAtlasArr[i];
		if (targetTextureAtlas.getRegion(textureName))
		{
			break;
		}
		targetTextureAtlas = null;
		}
	}
	}
	else
	{
	for (textureAtlasName in textureAtlasDic)
	{
		textureAtlasArr = textureAtlasDic[textureAtlasName] as Array<Dynamic>;
		if (textureAtlasArr)
		{
		for (i = 0, len = textureAtlasArr.length; i < len; i++)
		{
			targetTextureAtlas = textureAtlasArr[i];
			if (targetTextureAtlas.getRegion(textureName))
			{
			break;
			}
			targetTextureAtlas = null;
		}
		if (targetTextureAtlas != null)
		{
			break;
		}
		}
	}
	}
	
	if(!targetTextureAtlas)
	{
	return null;
	}
	
	return generateMesh(targetTextureAtlas, textureName, meshData);
}

//一般情况下dragonBonesData和textureAtlas是一对一的，通过相同的key对应。
public function buildArmature(armatureName:String, fromDragonBonesDataName:String = null, fromTextureAtlasName:String = null, skinName:String = null):Armature
{
	var buildArmatureDataPackage:BuildArmatureDataPackage = new BuildArmatureDataPackage();
	fillBuildArmatureDataPackageArmatureInfo(armatureName, fromDragonBonesDataName, buildArmatureDataPackage);
	if (fromTextureAtlasName == null)
	{
	fromTextureAtlasName = buildArmatureDataPackage.dragonBonesDataName;
	}
	
	var dragonBonesData:DragonBonesData = buildArmatureDataPackage.dragonBonesData;
	var armatureData:ArmatureData = buildArmatureDataPackage.armatureData;
	
	if(!armatureData)
	{
	return null;
	}
	
	return buildArmatureUsingArmatureDataFromTextureAtlas(dragonBonesData, armatureData, fromTextureAtlasName, skinName);
}

public function buildFastArmature(armatureName:String, fromDragonBonesDataName:String = null, fromTextureAtlasName:String = null, skinName:String = null):FastArmature
{
	var buildArmatureDataPackage:BuildArmatureDataPackage = new BuildArmatureDataPackage();
	fillBuildArmatureDataPackageArmatureInfo(armatureName, fromDragonBonesDataName, buildArmatureDataPackage);
	if (fromTextureAtlasName == null)
	{
	fromTextureAtlasName = buildArmatureDataPackage.dragonBonesDataName;
	}
	var dragonBonesData:DragonBonesData = buildArmatureDataPackage.dragonBonesData;
	var armatureData:ArmatureData = buildArmatureDataPackage.armatureData;
	
	if(!armatureData)
	{
	return null;
	}
	
	return buildFastArmatureUsingArmatureDataFromTextureAtlas(dragonBonesData, armatureData, fromTextureAtlasName, skinName);
}

private function buildArmatureUsingArmatureDataFromTextureAtlas(dragonBonesData:DragonBonesData, armatureData:ArmatureData, textureAtlasName:String, skinName:String = null):Armature
{
	var outputArmature:Armature = generateArmature();
	outputArmature.name = armatureData.name;
	outputArmature.__dragonBonesData = dragonBonesData;
	outputArmature._armatureData = armatureData;
	outputArmature._skewEnable = dragonBonesData.version >= 4.5;
	outputArmature.animation.animationDataList = armatureData.animationDataList;
	
	buildBones(outputArmature);
	outputArmature.buildIK();
	outputArmature.updateBoneCache();
	buildSlots(outputArmature, skinName, textureAtlasName);
	
	outputArmature.advanceTime(0);
	return outputArmature;
}

private function buildFastArmatureUsingArmatureDataFromTextureAtlas(dragonBonesData:DragonBonesData, armatureData:ArmatureData, textureAtlasName:String, skinName:String = null):FastArmature
{
	var outputArmature:FastArmature = generateFastArmature();
	outputArmature.name = armatureData.name;
	outputArmature.__dragonBonesData = dragonBonesData;
	outputArmature._armatureData = armatureData;
	outputArmature._skewEnable = dragonBonesData.version >= 4.5;
	outputArmature.animation.animationDataList = armatureData.animationDataList;
	
	buildFastBones(outputArmature);
	outputArmature.buildIK();
	outputArmature.updateBoneCache();
	buildFastSlots(outputArmature, skinName, textureAtlasName);
	
	outputArmature.advanceTime(0);
	
	return outputArmature;
}

//暂时不支持ifRemoveOriginalAnimationList为false的情况
public function copyAnimationsToArmature(toArmature:Armature, fromArmatreName:String, fromDragonBonesDataName:String = null, ifRemoveOriginalAnimationList:Bool = true):Bool
{
	var buildArmatureDataPackage:BuildArmatureDataPackage = new BuildArmatureDataPackage();
	if(!fillBuildArmatureDataPackageArmatureInfo(fromArmatreName, fromDragonBonesDataName, buildArmatureDataPackage))
	{
	return false;
	}
	
	var fromArmatureData:ArmatureData = buildArmatureDataPackage.armatureData;
	toArmature.animation.animationDataList = fromArmatureData.animationDataList;
	
//处理子骨架的复制
	var fromSkinData:SkinData = fromArmatureData.getSkinData("");
	var fromSlotData:SlotData;
	var fromDisplayData:DisplayData;
	
	var toSlotList:Vector<Slot> = toArmature.getSlots(false); 
	var toSlot:Slot;
	var toSlotDisplayList:Array;
	var toSlotDisplayListLength:UInt;
	var toDisplayObject:Object;
	var toChildArmature:Armature;
	
	for each(toSlot in toSlotList)
	{
	toSlotDisplayList = toSlot.displayList;
	toSlotDisplayListLength = toSlotDisplayList.length
	for(var i:Int = 0; i < toSlotDisplayListLength; i++)
	{
		toDisplayObject = toSlotDisplayList[i];
		
		if(toDisplayObject is Armature)
		{
		toChildArmature = toDisplayObject as Armature;
		
		fromSlotData = fromSkinData.getSlotData(toSlot.name);
		fromDisplayData = fromSlotData.displayDataList[i];
		if(fromDisplayData.type == DisplayData.ARMATURE)
		{
			copyAnimationsToArmature(toChildArmature, fromDisplayData.name, buildArmatureDataPackage.dragonBonesDataName, ifRemoveOriginalAnimationList);
		}
		}
	}
	}
	
	return true;
}

private function fillBuildArmatureDataPackageArmatureInfo(armatureName:String, dragonBonesDataName:String, outputBuildArmatureDataPackage:BuildArmatureDataPackage):Bool
{
	if(dragonBonesDataName)
	{
	outputBuildArmatureDataPackage.dragonBonesDataName = dragonBonesDataName;
	outputBuildArmatureDataPackage.dragonBonesData = dragonBonesDataDic[dragonBonesDataName];
	outputBuildArmatureDataPackage.armatureData = outputBuildArmatureDataPackage.dragonBonesData.getArmatureDataByName(armatureName);
	return true;
	}
	else
	{
	for(dragonBonesDataName in dragonBonesDataDic)
	{
		outputBuildArmatureDataPackage.dragonBonesData = dragonBonesDataDic[dragonBonesDataName];
		outputBuildArmatureDataPackage.armatureData = outputBuildArmatureDataPackage.dragonBonesData.getArmatureDataByName(armatureName);
		if(outputBuildArmatureDataPackage.armatureData)
		{
		outputBuildArmatureDataPackage.dragonBonesDataName = dragonBonesDataName;
		return true;
		}
	}
	}
	return false;
}

private function fillBuildArmatureDataPackageTextureInfo(fromTextureAtlasName:String, outputBuildArmatureDataPackage:BuildArmatureDataPackage):Void
{
	outputBuildArmatureDataPackage.textureAtlasName = fromTextureAtlasName;
}

private function findFirstDragonBonesData():DragonBonesData
{
	for each(var outputDragonBonesData:DragonBonesData in dragonBonesDataDic)
	{
	if(outputDragonBonesData)
	{
		return outputDragonBonesData;
	}
	}
	return null;
}

private function findFirstTextureAtlas():Object
{
	for each(var outputTextureAtlas:Object in textureAtlasDic)
	{
	if(outputTextureAtlas)
	{
		return outputTextureAtlas;
	}
	}
	return null;
}

private function buildBones(armature:Armature):Void
{
	//按照从属关系的顺序建立
	var boneDataList:Vector<BoneData> = armature.armatureData.boneDataList;
	
	var boneData:BoneData;
	var bone:Bone;
	var parent:String;
	for(var i:Int = 0;i < boneDataList.length;i ++)
	{
	boneData = boneDataList[i];
	bone = Bone.initWithBoneData(boneData);
	parent = boneData.parent;
	if(	parent && armature.armatureData.getBoneData(parent) == null)
	{
		parent = null;
	}
	armature.addBone(bone, parent, true);
	}
	armature.updateAnimationAfterBoneListChanged();
}

private function buildFastBones(armature:FastArmature):Void
{
	//按照从属关系的顺序建立
	var boneDataList:Vector<BoneData> = armature.armatureData.boneDataList;
	
	var boneData:BoneData;
	var bone:FastBone;
	for(var i:Int = 0;i < boneDataList.length;i ++)
	{
	boneData = boneDataList[i];
	bone = FastBone.initWithBoneData(boneData);
	armature.addBone(bone, boneData.parent);
	}
}

private function buildFastSlots(armature:FastArmature, skinName:String, textureAtlasName:String):Void
{
//根据皮肤初始化SlotData的DisplayDataList
	var skinData:SkinData = armature.armatureData.getSkinData(skinName);
	if(!skinData)
	{
	return;
	}
	armature.armatureData.setSkinData(skinName);
	
	var displayList:Array = [];
	var slotDataList:Vector<SlotData> = armature.armatureData.slotDataList;
	var slotData:SlotData;
	var slot:FastSlot;
	for(var i:Int = 0; i < slotDataList.length; i++)
	{
	displayList.length = 0;
	slotData = slotDataList[i];
	slot = generateFastSlot();
	slot.initWithSlotData(slotData);
	
	var l:Int = slotData.displayDataList.length;
	while(l--)
	{
		var displayData:DisplayData = slotData.displayDataList[l];
		
		switch(displayData.type)
		{
		case DisplayData.ARMATURE:
			var childArmature:FastArmature = buildFastArmatureUsingArmatureDataFromTextureAtlas(armature.__dragonBonesData, armature.__dragonBonesData.getArmatureDataByName(displayData.name), textureAtlasName, skinName);
			displayList[l] = childArmature;
			slot.hasChildArmature = true;
			break;
		case DisplayData.MESH:
			displayList[l] = getMeshDisplay(displayData as MeshData, textureAtlasName);
			break;
		case DisplayData.IMAGE:
		default:
			displayList[l] = getTextureDisplay(displayData.name, textureAtlasName, displayData.pivot.x, displayData.pivot.y);
			break;
		
		}
	}
	//==================================================
	//如果显示对象有name属性并且name属性可以设置的话，将name设置为与slot同名，dragonBones并不依赖这些属性，只是方便开发者
	for each(var displayObject:Object in displayList)
	{
		if(!displayObject)
		{
		continue;
		}
		if(displayObject is FastArmature)
		{
		displayObject = (displayObject as FastArmature).display;
		}
		
		if(displayObject.hasOwnProperty("name"))
		{
		try
		{
			displayObject["name"] = slot.name;
		}
		catch(err:Error)
		{
		}
		}
	}
	//==================================================
	slot.initDisplayList(displayList.concat());
	armature.addSlot(slot, slotData.parent);
	slot.changeDisplayIndex(slotData.displayIndex);
	}
}

private function buildSlots(armature:Armature, skinName:String, textureAtlasName:String):Void
{
	var skinData:SkinData = armature.armatureData.getSkinData(skinName);
	if(!skinData)
	{
	return;
	}
	armature.armatureData.setSkinData(skinName);
	var displayList:Array = [];
	var slotDataList:Vector<SlotData> = armature.armatureData.slotDataList;
	var slotData:SlotData;
	var slot:Slot;
	var bone:Bone;
	var skinListObject:Object = { };
	for(var i:Int = 0; i < slotDataList.length; i++)
	{
	displayList.length = 0;
	slotData = slotDataList[i];
	bone = armature.getBone(slotData.parent);
	if(!bone)
	{
		continue;
	}
	
	slot = generateSlot();
	slot.initWithSlotData(slotData);
	bone.addSlot(slot);
	
	var l:Int = slotData.displayDataList.length;
	while(l--)
	{
		var displayData:DisplayData = slotData.displayDataList[l];
		
		switch(displayData.type)
		{
		case DisplayData.ARMATURE:
			var childArmature:Armature = buildArmatureUsingArmatureDataFromTextureAtlas(armature.__dragonBonesData, armature.__dragonBonesData.getArmatureDataByName(displayData.name), textureAtlasName, skinName);
			displayList[l] = childArmature;
			break;
		case DisplayData.MESH:
			displayList[l] = getMeshDisplay(displayData as MeshData, textureAtlasName);
			break;
		case DisplayData.IMAGE:
		default:
			displayList[l] = getTextureDisplay(displayData.name, textureAtlasName, displayData.pivot.x, displayData.pivot.y);
			break;
		
		}
	}
	//==================================================
	//如果显示对象有name属性并且name属性可以设置的话，将name设置为与slot同名，dragonBones并不依赖这些属性，只是方便开发者
	for each(var displayObject:Object in displayList)
	{
		if(!displayObject)
		{
		continue;
		}
		if(displayObject is Armature)
		{
		displayObject = (displayObject as Armature).display;
		}
		
		if(displayObject.hasOwnProperty("name"))
		{
		try
		{
			displayObject["name"] = slot.name;
		}
		catch(err:Error)
		{
		}
		}
	}
	//==================================================
	skinListObject[slotData.name] = displayList.concat();
	slot.displayList = displayList;
	slot.changeDisplay(slotData.displayIndex);
	}
	armature.addSkinList(skinName, skinListObject);
}


public function addSkinToArmature(armature:Armature, skinName:String, textureAtlasName:String):Void
{
	var skinData:SkinData = armature.armatureData.getSkinData(skinName);
	if(!skinData || !textureAtlasName)
	{
	return;
	}
	var displayList:Array = [];
	var slotDataList:Vector<SlotData> = armature.armatureData.slotDataList;
	var slotData:SlotData;
	var slot:Slot;
	var bone:Bone;
	var skinListData:Object = { };
	var displayDataList:Vector<DisplayData>
	
	for(var i:Int = 0; i < slotDataList.length; i++)
	{
	displayList.length = 0;
	slotData = slotDataList[i];
	bone = armature.getBone(slotData.parent);
	if(!bone)
	{
		continue;
	}
	
	var l:Int = 0;
	if (i >= skinData.slotDataList.length)
	{
		l = 0;
	}
	else
	{
		displayDataList = skinData.slotDataList[i].displayDataList;
		l = displayDataList.length;
	}
	while(l--)
	{
		var displayData:DisplayData = displayDataList[l];
		
		switch(displayData.type)
		{
		case DisplayData.ARMATURE:
			var childArmature:Armature = buildArmatureUsingArmatureDataFromTextureAtlas(armature.__dragonBonesData, armature.__dragonBonesData.getArmatureDataByName(displayData.name), textureAtlasName, skinName);
			displayList[l] = childArmature;
			break;
		
		case DisplayData.IMAGE:
		default:
			displayList[l] = (displayData.name, textureAtlasName, displayData.pivot.x, displayData.pivot.y);
			break;
		
		}
	}
	//==================================================
	//如果显示对象有name属性并且name属性可以设置的话，将name设置为与slot同名，dragonBones并不依赖这些属性，只是方便开发者
	for each(var displayObject:Object in displayList)
	{
		if(displayObject is Armature)
		{
		displayObject = (displayObject as Armature).display;
		}
		
		if(displayObject.hasOwnProperty("name"))
		{
		try
		{
			displayObject["name"] = slot.name;
		}
		catch(err:Error)
		{
		}
		}
	}
	//==================================================
	skinListData[slotData.name] = displayList.concat();
	}
	armature.addSkinList(skinName, skinListData);
}

/**
 * Parses the raw data and returns a SkeletonData instance.	
 * @example 
 * <listing>
 * import flash.events.Event; 
 * import dragonBones.factorys.NativeFactory;
 * 
 * [Embed(source = "../assets/Dragon1.swf", mimeType = "application/octet-stream")]
 *	private static inline var ResourcesData:Class;
 * var factory:NativeFactory = new NativeFactory(); 
 * factory.addEventListener(Event.COMPLETE, textureCompleteHandler);
 * factory.parseData(new ResourcesData());
 * </listing>
 * @param ByteArray. Represents the raw data for the whole DragonBones system.
 * @param String. (optional) The SkeletonData instance name.
 * @param Boolean. (optional) flag if delay animation data parsing. Delay animation data parsing can reduce the data paring time to improve loading performance.
 * @param Dictionary. (optional) output parameter. If it is not null, and ifSkipAnimationData is true, it will be fulfilled animationData, so that developers can parse it later.
 * @return A SkeletonData instance.
 */
public function parseData(bytes:ByteArray, dataName:String = null):Void
{
	if(!bytes)
	{
	throw new ArgumentError();
	}
	
	var decompressedData:DecompressedData = DataSerializer.decompressData(bytes);
	
	var dragonBonesData:DragonBonesData = DataParser.parseData(decompressedData.dragonBonesData);
	decompressedData.name = dataName || dragonBonesData.name;
	decompressedData.addEventListener(Event.COMPLETE, parseCompleteHandler);
	decompressedData.parseTextureAtlasBytes();
	
	addSkeletonData(dragonBonesData, dataName);
}

/** @private */
private function parseCompleteHandler(event:Event):Void
{
	var decompressedData:DecompressedData = event.target as DecompressedData;
	decompressedData.removeEventListener(Event.COMPLETE, parseCompleteHandler);
	
	var textureAtlas:Object = generateTextureAtlas(decompressedData.textureAtlas, decompressedData.textureAtlasData);
	addTextureAtlas(textureAtlas, decompressedData.name);
	
	decompressedData.dispose();
	this.dispatchEvent(new Event(Event.COMPLETE));
}


/** @private */
private function generateTextureAtlas(content:Object, textureAtlasRawData:Object):ITextureAtlas
{
	return null;
}

/**
 * @private
 * Generates an Armature instance.
 * @return Armature An Armature instance.
 */
private function generateArmature():Armature
{
	return null;
}

/**
 * @private
 * Generates an Armature instance.
 * @return Armature An Armature instance.
 */
private function generateFastArmature():FastArmature
{
	return null;
}

/**
 * @private
 * Generates an Slot instance.
 * @return Slot An Slot instance.
 */
private function generateSlot():Slot
{
	return null;
}

/**
 * @private
 * Generates an Slot instance.
 * @return Slot An Slot instance.
 */
private function generateFastSlot():FastSlot
{
	return null;
}

/**
 * @private
 * Generates a DisplayObject
 * @param textureAtlas The TextureAtlas.
 * @param fullName A qualified name.
 * @param pivotX A pivot x based value.
 * @param pivotY A pivot y based value.
 * @return
 */
private function generateDisplay(textureAtlas:Object, fullName:String, pivotX:Float, pivotY:Float):Object
{
	return null;
}

private function generateMesh(textureAtlas:Object, fullName:String, meshData:MeshData):Object
{
	return null;
}

}
}
import dragonBones.objects.ArmatureData;
import dragonBones.objects.DragonBonesData;

class BuildArmatureDataPackage
{
public var dragonBonesDataName:String;
public var dragonBonesData:DragonBonesData;
public var armatureData:ArmatureData;
public var textureAtlasName:String;
}