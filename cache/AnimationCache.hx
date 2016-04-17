package dragonbones.cache;

import dragonBones.objects.AnimationData;
import dragonBones.objects.ArmatureData;
import dragonBones.objects.BoneData;
import dragonBones.objects.SlotData;
import dragonBones.objects.SlotTimeline;
import dragonBones.objects.TransformTimeline;

import flash.Vector;

class AnimationCache
{
public var name:String;
//	public var boneTimelineCacheList:Vector<BoneTimelineCache> = new Vector();
public var slotTimelineCacheList:Vector<SlotTimelineCache> = new Vector();
//	public var boneTimelineCacheDic:Object = {};
public var slotTimelineCacheDic:Object = {};
public var frameNum:Int = 0;
public function new()
{
}

public static function initWithAnimationData(animationData:AnimationData,armatureData:ArmatureData):AnimationCache
{
	var output:AnimationCache = new AnimationCache();
	output.name = animationData.name;
	
	var boneTimelineList:Vector<TransformTimeline> = animationData.timelineList;
	var boneName:String;
	var boneData:BoneData;
	var slotData:SlotData;
	var slotTimelineCache:SlotTimelineCache;
	var slotName:String;
	
	for(var i:Int = 0, length:Int = boneTimelineList.length; i < length; i++)
	{
	boneName = boneTimelineList[i].name;
	for (var j:Int = 0, jlen:Int = armatureData.slotDataList.length; j < jlen; j++)
	{
		slotData = armatureData.slotDataList[j];
		slotName = slotData.name;
		if (slotData.parent == boneName)
		{
		if (output.slotTimelineCacheDic[slotName] == null)
		{
			slotTimelineCache = new SlotTimelineCache();
			slotTimelineCache.name = slotName;
			output.slotTimelineCacheList.push(slotTimelineCache);
			output.slotTimelineCacheDic[slotName] = slotTimelineCache;
		}
		
		}
	}
	}
	return output;
}

//	public function initBoneTimelineCacheDic(boneCacheGeneratorDic:Object, boneFrameCacheDic:Object):Void
//	{
//		var name:String;
//		for each(var boneTimelineCache:BoneTimelineCache in boneTimelineCacheDic)
//		{
//		name = boneTimelineCache.name;
//		boneTimelineCache.cacheGenerator = boneCacheGeneratorDic[name];
//		boneTimelineCache.currentFrameCache = boneFrameCacheDic[name];
//		}
//	}

public function initSlotTimelineCacheDic(slotCacheGeneratorDic:Object, slotFrameCacheDic:Object):Void
{
	var name:String;
	for each(var slotTimelineCache:SlotTimelineCache in slotTimelineCacheDic)
	{
	name = slotTimelineCache.name;
	slotTimelineCache.cacheGenerator = slotCacheGeneratorDic[name];
	slotTimelineCache.currentFrameCache = slotFrameCacheDic[name];
	}
}

//	public function bindCacheUserBoneDic(boneDic:Object):Void
//	{
//		for(var name:String in boneDic)
//		{
//		(boneTimelineCacheDic[name] as BoneTimelineCache).bindCacheUser(boneDic[name]);
//		}
//	}

public function bindCacheUserSlotDic(slotDic:Object):Void
{
	for(var name:String in slotDic)
	{
	(slotTimelineCacheDic[name] as SlotTimelineCache).bindCacheUser(slotDic[name]);
	}
}

public function addFrame():Void
{
	frameNum++;
//		var boneTimelineCache:BoneTimelineCache;
//		for(var i:Int = 0, length:Int = boneTimelineCacheList.length; i < length; i++)
//		{
//		boneTimelineCache = boneTimelineCacheList[i];
//		boneTimelineCache.addFrame();
//		}
	
	var slotTimelineCache:SlotTimelineCache;
	for(var i:Int = 0, length:Int = slotTimelineCacheList.length; i < length; i++)
	{
	slotTimelineCache = slotTimelineCacheList[i];
	slotTimelineCache.addFrame();
	}
}
	

public function update(progress:Float):Void
{
	var frameIndex:Int = progress * (frameNum-1);
	
//		var boneTimelineCache:BoneTimelineCache;
//		for(var i:Int = 0, length:Int = boneTimelineCacheList.length; i < length; i++)
//		{
//		boneTimelineCache = boneTimelineCacheList[i];
//		boneTimelineCache.update(frameIndex);
//		}
	
	var slotTimelineCache:SlotTimelineCache;
	for(var i:Int = 0, length:Int = slotTimelineCacheList.length; i < length; i++)
	{
	slotTimelineCache = slotTimelineCacheList[i];
	slotTimelineCache.update(frameIndex);
	}
}
}