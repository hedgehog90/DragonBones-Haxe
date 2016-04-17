package dragonbones.fast;

import dragonBones.objects.IKData;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.utils.Dictionary;

import dragonBones.cache.AnimationCacheManager;
import dragonBones.cache.SlotFrameCache;
import dragonBones.core.IArmature;
import dragonBones.core.ICacheableArmature;
import dragonBones.core.dragonBones_internal;
import dragonBones.events.AnimationEvent;
import dragonBones.events.FrameEvent;
import dragonBones.fast.animation.FastAnimation;
import dragonBones.fast.animation.FastAnimationState;
import dragonBones.objects.ArmatureData;
import dragonBones.objects.DragonBonesData;
import dragonBones.objects.Frame;

use namespace dragonBones_internal;

/**
 * Dispatched when an animation state play complete (if playtimes equals to 0 means loop forever. Then this Event will not be triggered)
 */
//[Event(name="complete", type="dragonBones.events.AnimationEvent")]

/**
 * Dispatched when an animation state complete a loop.
 */
//[Event(name="loopComplete", type="dragonBones.events.AnimationEvent")]

/**
 * Dispatched when an animation state enter a frame with animation frame event.
 */
//[Event(name="animationFrameEvent", type="dragonBones.events.FrameEvent")]

/**
 * Dispatched when an bone enter a frame with animation frame event.
 */
//[Event(name="boneFrameEvent", type="dragonBones.events.FrameEvent")]

/**
 * 不支持动态添加Bone和Slot，换装请通过更换Slot的dispaly或子骨架childArmature来实现
 */
import flash.Vector;

class FastArmature extends EventDispatcher implements ICacheableArmature
{
/**
 * The name should be same with ArmatureData's name
 */
public var name:String;
/**
 * An object that can contain any user extra data.
 */
public var userData:Object;


private var _enableCache:Bool;

/**
 * 保证CacheManager是独占的前提下可以开启，开启后有助于性能提高
 */
public var isCacheManagerExclusive:Bool = false;

/** @private */
private var _animation:FastAnimation;

/** @private */
private var _display:Object;

/** @private Store bones based on bones' hierarchy (From root to leaf)*/
public var boneList:Vector<FastBone>;
dragonBones_private var _boneDic:Object;

/** @private Store slots based on slots' zOrder*/
public var slotList:Vector<FastSlot>;
dragonBones_private var _slotDic:Object;

private var _boneIKList:Vector<Vector.<FastBone>> = new Vector<Vector.<FastBone>>();
private var _ikList:Vector<FastIKConstraint>;

public var slotHasChildArmatureList:Vector<FastSlot>;

private var _enableEventDispatch:Bool = true;

dragonBones_private var __dragonBonesData:DragonBonesData;
dragonBones_private var _armatureData:ArmatureData;
dragonBones_private var _slotsZOrderChanged:Bool;
dragonBones_private var _skewEnable:Bool;

private var _eventList:Array;
private var _delayDispose:Bool;
private var _lockDispose:Bool;
private var useCache:Bool = true;
public function new(display:Object)
{
	super(this);
	_display = display;
	_animation = new FastAnimation(this);
	_slotsZOrderChanged = false;
	_armatureData = null;
	
	boneList = new Vector<FastBone>;
	_boneDic = {};
	slotList = new Vector<FastSlot>;
	_slotDic = {};
	slotHasChildArmatureList = new Vector<FastSlot>;
	_ikList = new Vector();
	_ikList.fixed = true;
	_eventList = [];
	
	_delayDispose = false;
	_lockDispose = false;
	
}

/**
 * Cleans up any resources used by this instance.
 */
public function dispose():Void
{
	_delayDispose = true;
	if(!_animation || _lockDispose)
	{
	return;
	}
	
	userData = null;
	
	_animation.dispose();
	var i:Int = slotList.length;
	while(i --)
	{
	slotList[i].dispose();
	}
	i = boneList.length;
	while(i --)
	{
	boneList[i].dispose();
	}
	i = _ikList.length;
	while(i --)
	{
	_ikList[i].dispose();
	}
	slotList.fixed = false;
	slotList.length = 0;
	boneList.fixed = false;
	boneList.length = 0;
	_ikList.fixed = false;
	_ikList.length = 0;
	
	_armatureData = null;
	_animation = null;
	slotList = null;
	boneList = null;
	_eventList = null;
	_ikList = null;
	
}

/**
 * Update the animation using this method typically in an ENTERFRAME Event or with a Timer.
 * @param The amount of second to move the playhead ahead.
 */

public function advanceTime(passedTime:Float):Void
{
	_lockDispose = true;
	_animation.advanceTime(passedTime);
	
	var bone:FastBone;
	var slot:FastSlot;
	var i:Int;
	var len:Int = _boneIKList.length;
	var j:Int;
	var jLen:Int;
	
	if(_animation.animationState.isUseCache())
	{
	if(!useCache)
	{
		useCache = true;
	}
	i = slotList.length;
	while(i --)
	{
		slot = slotList[i];
		slot.updateByCache();
	}
	}
	else
	{
	if(useCache)
	{
		useCache = false;
		i = slotList.length;
		while(i --)
		{
		slot = slotList[i];
		slot.switchTransformToBackup();
		}
	}
	
	//i = boneList.length;
	//while(i --)
	//{
		//bone = boneList[i];
		//bone.update();
	//}
	for (i = 0; i < len; i++) 
	{
		for (j = 0, jLen = _boneIKList[i].length; j < jLen; j++)
		{
		bone = _boneIKList[i][j];
		bone.update();
		bone.rotationIK = bone.global.rotation;
		if(i != 0 && bone.isIKConstraint)
		{
			_ikList[i-1].compute();
			bone.adjustGlobalTransformMatrixByIK();
		}
		}
	}
	
	i = slotList.length;
	while(i --)
	{
		slot = slotList[i];
		slot.update();
	}
	}
	
	i = slotHasChildArmatureList.length;
	while(i--)
	{
	slot = slotHasChildArmatureList[i];
	var childArmature:IArmature = slot.childArmature as IArmature;
	if(childArmature)
	{
		childArmature.advanceTime(passedTime);
	}
	}
	
	if(_slotsZOrderChanged)
	{
	updateSlotsZOrder();
	}
	
	while(_eventList.length > 0)
	{
	this.dispatchEvent(_eventList.shift());
	}
	
	_lockDispose = false;
	if(_delayDispose)
	{
	dispose();
	}
}

public function enableAnimationCache(frameRate:Int, animationList:Array = null, loop:Bool = true):AnimationCacheManager
{
	var animationCacheManager:AnimationCacheManager = AnimationCacheManager.initWithArmatureData(armatureData,frameRate);
	if(animationList)
	{
	for each(var animationName:String in animationList)
	{
		animationCacheManager.initAnimationCache(animationName);
	}
	}
	else
	{
	animationCacheManager.initAllAnimationCache();
	}
	animationCacheManager.setCacheGeneratorArmature(this);
	animationCacheManager.generateAllAnimationCache(loop);
	
	animationCacheManager.bindCacheUserArmature(this);
	enableCache = true;
	return animationCacheManager;
}

public function getBone(boneName:String):FastBone
{
	return _boneDic[boneName];
}
public function getSlot(slotName:String):FastSlot
{
	return _slotDic[slotName];
}

/**
 * Gets the Bone associated with this DisplayObject.
 * @param Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
 * @return A Bone instance or null if no Bone with that DisplayObject exist..
 * @see dragonBones.Bone
 */
public function getBoneByDisplay(display:Object):FastBone
{
	var slot:FastSlot = getSlotByDisplay(display);
	return slot?slot.parent:null;
}

/**
 * Gets the Slot associated with this DisplayObject.
 * @param Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
 * @return A Slot instance or null if no Slot with that DisplayObject exist.
 * @see dragonBones.Slot
 */
public function getSlotByDisplay(displayObj:Object):FastSlot
{
	if(displayObj)
	{
	for each(var slot:FastSlot in slotList)
	{
		if(slot.display == displayObj)
		{
		return slot;
		}
	}
	}
	return null;
}

/**
 * Get all Slot instance associated with this armature.
 * @param if return Vector copy
 * @return A Vector.&lt;Slot&gt; instance.
 * @see dragonBones.Slot
 */
public function getSlots(returnCopy:Bool = true):Vector<FastSlot>
{
	return returnCopy?slotList.concat():slotList;
}

dragonBones_private function _updateBonesByCache():Void
{
	var i:Int = boneList.length;
	var bone:FastBone;
	while(i --)
	{
	bone = boneList[i];
	bone.update();
	}
}


/**
 * Add a Bone instance to this Armature instance.
 * @param A Bone instance.
 * @param (optional) The parent's name of this Bone instance.
 * @see dragonBones.Bone
 */
dragonBones_private function addBone(bone:FastBone, parentName:String = null):Void
{
	var parentBone:FastBone;
	if(parentName)
	{
	parentBone = getBone(parentName);
	parentBone.boneList.push(bone);
	}
	bone.armature = this;
	bone.parentBoneData = parentBone;
	boneList.unshift(bone);
	_boneDic[bone.name] = bone;
}

/**
 * Add a slot to a bone as child.
 * @param slot A Slot instance
 * @param boneName bone name
 * @see dragonBones.core.DBObject
 */
dragonBones_private function addSlot(slot:FastSlot, parentBoneName:String):Void
{
	var bone:FastBone = getBone(parentBoneName);
	if(bone)
	{
	slot.armature = this;
	slot.setParent(bone);
	bone.slotList.push(slot);
	slot.addDisplayToContainer(display);
	slotList.push(slot);
	_slotDic[slot.name] = slot;
	if(slot.hasChildArmature)
	{
		slotHasChildArmatureList.push(slot);
	}
	
	}
	else
	{
	throw new ArgumentError();
	}
}

/**
 * Sort all slots based on zOrder
 */
dragonBones_private function updateSlotsZOrder():Void
{
	slotList.fixed = false;
	slotList.sort(sortSlot);
	slotList.fixed = true;
	var i:Int = slotList.length;
	while(i --)
	{
	var slot:FastSlot = slotList[i];
	if ((slot._frameCache && (slot._frameCache as SlotFrameCache).displayIndex >= 0) 
		|| (!slot._frameCache && slot.displayIndex >= 0))
	{
		slot.addDisplayToContainer(_display);
	}
	}
	
	_slotsZOrderChanged = false;
}

private function sortBoneList():Void
{
	var i:Int = boneList.length;
	if(i == 0)
	{
	return;
	}
	var helpArray:Array = [];
	while(i --)
	{
	var level:Int = 0;
	var bone:FastBone = boneList[i];
	var boneParent:FastBone = bone;
	while(boneParent)
	{
		level ++;
		boneParent = boneParent.parent;
	}
	helpArray[i] = [level, bone];
	}
	
	helpArray.sortOn("0", Array.NUMERIC|Array.DESCENDING);
	
	i = helpArray.length;
	
	boneList.fixed = false;
	while(i --)
	{
	boneList[i] = helpArray[i][1];
	}
	boneList.fixed = true;
	
	helpArray.length = 0;
}





/** @private When AnimationState enter a key frame, call this func*/
dragonBones_private function arriveAtFrame(frame:Frame, animationState:FastAnimationState):Void
{
	if(frame.event && this.hasEventListener(FrameEvent.ANIMATION_FRAME_EVENT))
	{
	var frameEvent:FrameEvent = new FrameEvent(FrameEvent.ANIMATION_FRAME_EVENT);
	frameEvent.animationState = animationState;
	frameEvent.frameLabel = frame.event;
	addEvent(frameEvent);
	}

	if(frame.action)
	{
	animation.gotoAndPlay(frame.action);
	}
}

/**
 * Force update bones and slots. (When bone's animation play complete, it will not update) 
 */
public function invalidUpdate(boneName:String = null):Void
{
	if(boneName)
	{
	var bone:FastBone = getBone(boneName);
	if(bone)
	{
		bone.invalidUpdate();
	}
	}
	else
	{
	var i:Int = boneList.length;
	while(i --)
	{
		boneList[i].invalidUpdate();
	}
	}
}

public function resetAnimation():Void
{
	animation.animationState.resetTimelineStateList();
	for each(var boneItem:FastBone in boneList)
	{
	boneItem._timelineState = null;
	}
	animation.stop();
}

private function sortSlot(slot1:FastSlot, slot2:FastSlot):Int
{
	return slot1.zOrder < slot2.zOrder?1: -1;
}

public function getAnimation():Object
{
	return _animation;
}

/**
 * ArmatureData.
 * @see dragonBones.objects.ArmatureData.
 */
public var armatureData(getArmatureData, setArmatureData):ArmatureData;
 	private function getArmatureData():ArmatureData
{
	return _armatureData;
}

/**
 * An Animation instance
 * @see dragonBones.animation.Animation
 */
public var animation(getAnimation, setAnimation):FastAnimation;
 	private function getAnimation():FastAnimation
{
	return _animation;
}

/**
 * Armature's display object. It's instance type depends on render engine. For example "flash.display.DisplayObject" or "startling.display.DisplayObject"
 */
public var display(getDisplay, setDisplay):Object;
 	private function getDisplay():Object
{
	return _display;
}

public var enableCache(getEnableCache, setEnableCache):Bool;
 	private function getEnableCache():Bool
{
	return _enableCache;
}
private function setEnableCache(value:Bool):Void
{
	_enableCache = value;
}

public var enableEventDispatch(getEnableEventDispatch, setEnableEventDispatch):Bool;
 	private function getEnableEventDispatch():Bool
{
	return _enableEventDispatch;
}
private function setEnableEventDispatch(value:Bool):Void
{
	_enableEventDispatch = value;
}

public function getSlotDic():Object
{
	return _slotDic;
}

dragonBones_private function addEvent(event:Event):Void
{
	if (_enableEventDispatch)
	{
	_eventList.push(event);
	}		
}

public function getIKs(returnCopy:Bool = true):Vector<FastIKConstraint>
{
	return returnCopy?_ikList.concat():_ikList;
}

public function buildIK():Void
{
	var ikConstraintData:IKData;
	_ikList.fixed = false;
	_ikList.length = 0;
	for (var i:Int = 0, len:Int = _armatureData.ikDataList.length; i < len; i++)
	{
	ikConstraintData = _armatureData.ikDataList[i];
	_ikList.push(new FastIKConstraint(ikConstraintData, this));
	}
	_ikList.fixed = true;
}

public function updateBoneCache():Void
{
	boneList.reverse();
	var temp:Object = {};
	var ikConstraintsCount:Int = _ikList.length;
	var arrayCount:Int = ikConstraintsCount + 1;
	var i:Int;
	var len:Int;
	var j:Int;
	var jLen:Int;
	var bone:FastBone;
	var currentBone:FastBone;
	
	_boneIKList = new Vector<Vector.<FastBone>>();
	while (_boneIKList.length < arrayCount)
	{
	_boneIKList[_boneIKList.length] = new Vector();
	}
	
	temp[boneList[0].name] = 0;
	for (i = 0, len = _ikList.length; i < len; i++) 
	{
	temp[_ikList[i].bones[0].name] = i+1;
	}
	next:
	for (i = 0, len = boneList.length; i < len; i++)
	{
	bone = boneList[i];
	currentBone = bone;
	while (currentBone)
	{
		if (currentBone.parent == null) 
		{
		temp[currentBone.name] = 0;
		}
		if (temp.hasOwnProperty(currentBone.name))
		{
		_boneIKList[temp[currentBone.name]].push(bone);
		continue next;
		}
		currentBone = currentBone.parent;
	}
	}
}

public function getIKTargetData(bone:FastBone):Array
{
	var target:Array = [];
	var ik:FastIKConstraint; 
	for (var i:Int = 0, len:Int = _ikList.length; i < len; i++)
	{
	ik = _ikList[i];
	if(bone.name == ik.target.name){
		target.push(ik);
	}
	}
	return target;
}
}