package dragonbones.fast.animation;

import dragonBones.cache.AnimationCacheManager;
import dragonBones.core.IArmature;
import dragonBones.core.dragonBones_internal;
import dragonBones.fast.FastArmature;
import dragonBones.fast.FastSlot;
import dragonBones.objects.AnimationData;

/**
 * 不支持动画融合，在开启缓存的情况下，不支持无极的平滑补间
 */
import flash.Vector;

class FastAnimation
{
public var animationList:Vector<String>;
public var animationState:FastAnimationState = new FastAnimationState();
public var animationCacheManager:AnimationCacheManager;

private var _armature:FastArmature;
private var _animationDataList:Vector<AnimationData>;
private var _animationDataObj:Object;
private var _isPlaying:Bool;
private var _timeScale:Float;

public function new(armature:FastArmature)
{
	_armature = armature;
	animationState._armature = armature;
	animationList = new Vector<String>;
	_animationDataObj = {};

	_isPlaying = false;
	_timeScale = 1;
}

/**
 * Qualifies all resources used by this Animation instance for garbage collection.
 */
public function dispose():Void
{
	if(!_armature)
	{
	return;
	}
	
	_armature = null;
	_animationDataList = null;
	animationList = null;
	animationState = null;
}

public function gotoAndPlay( animationName:String, fadeInTime:Float = -1, duration:Float = -1, playTimes:Float = NaN):FastAnimationState
{
	if (!_animationDataList)
	{
	return null;
	}
	var animationData:AnimationData = _animationDataObj[animationName];
	if (!animationData)
	{
	return null;
	}
	_isPlaying = true;
	fadeInTime = fadeInTime < 0?(animationData.fadeTime < 0?0.3:animationData.fadeTime):fadeInTime;
	var durationScale:Float;
	if(duration < 0)
	{
	durationScale = animationData.scale < 0?1:animationData.scale;
	}
	else
	{
	durationScale = duration * 1000 / animationData.duration;
	}
	playTimes = isNaN(playTimes)?animationData.playTimes:playTimes;
	
	//播放新动画
	
	animationState.fadeIn(animationData, playTimes, 1 / durationScale, fadeInTime);
	
	if(_armature.enableCache && animationCacheManager)
	{
	animationState.animationCache = animationCacheManager.getAnimationCache(animationName);
	}
	
	var i:Int = _armature.slotHasChildArmatureList.length;
	while(i--)
	{
	var slot:FastSlot = _armature.slotHasChildArmatureList[i];
	var childArmature:IArmature = slot.childArmature as IArmature;
	if(childArmature)
	{
		childArmature.getAnimation().gotoAndPlay(animationName);
	}
	}
	return animationState;
}

/**
 * Control the animation to stop with a specified time. If related animationState haven't been created, then create a new animationState.
 * @param animationName The name of the animationState.
 * @param time 
 * @param normalizedTime 
 * @param fadeInTime A fade time to apply (>= 0), -1 means use xml data's fadeInTime. 
 * @param duration The duration of that Animation. -1 means use xml data's duration.
 * @param layer The layer of the animation.
 * @param group The group of the animation.
 * @param fadeOutMode Fade out mode (none, sameLayer, sameGroup, sameLayerAndGroup, all).
 * @return AnimationState.
 * @see dragonBones.objects.AnimationData.
 * @see dragonBones.animation.AnimationState.
 */
public function gotoAndStop(
	animationName:String, 
	time:Float, 
	normalizedTime:Float = -1,
	fadeInTime:Float = 0, 
	duration:Float = -1
):FastAnimationState
{
	if(!animationState.name != animationName)
	{
	gotoAndPlay(animationName, fadeInTime, duration);
	}
	
	if(normalizedTime >= 0)
	{
	animationState.setCurrentTime(animationState.totalTime * normalizedTime);
	}
	else
	{
	animationState.setCurrentTime(time);
	}
	
	animationState.stop();
	return animationState;
}

/**
 * Play the animation from the current position.
 */
public function play():Void
{
	if(!_animationDataList)
	{
	return;
	}
	if(!animationState.name)
	{
	gotoAndPlay(_animationDataList[0].name);
	}
	else if (!_isPlaying)
	{
	_isPlaying = true;
	}
	else
	{
	gotoAndPlay(animationState.name);
	}
}

public function stop():Void
{
	_isPlaying = false;
}

/** @private */
private function advanceTime(passedTime:Float):Void
{
	if(!_isPlaying)
	{
	return;
	}
	
	animationState.advanceTime(passedTime * _timeScale);
}

/**
 * check if contains a AnimationData by name.
 * @return Boolean.
 * @see dragonBones.animation.AnimationData.
 */
public function hasAnimation(animationName:String):Bool
{
	return _animationDataObj[animationName] != null;
}

/**
 * The amount by which passed time should be scaled. Used to slow down or speed up animations. Defaults to 1.
 */
public var timeScale(getTimeScale, setTimeScale):Float;
 	private function getTimeScale():Float
{
	return _timeScale;
}
private function setTimeScale(value:Float):Void
{
	if(isNaN(value) || value < 0)
	{
	value = 1;
	}
	_timeScale = value;
}

/**
 * The AnimationData list associated with this Animation instance.
 * @see dragonBones.objects.AnimationData.
 */
public var animationDataList(getAnimationDataList, setAnimationDataList):Vector;
 	private function getAnimationDataList():Vector<AnimationData>
{
	return _animationDataList;
}
private function setAnimationDataList(value:Vector<AnimationData>):Void
{
	_animationDataList = value;
	animationList.length = 0;
	for each(var animationData:AnimationData in _animationDataList)
	{
	animationList.push(animationData.name);
	_animationDataObj[animationData.name] = animationData;
	}
}

/**
 * Unrecommended API. Recommend use animationList.
 */
public var movementList(getMovementList, null):Vector;
 	private function getMovementList():Vector<String>
{
	return animationList;
}

/**
 * Unrecommended API. Recommend use lastAnimationName.
 */
public var movementID(getMovementID, null):String;
 	private function getMovementID():String
{
	return lastAnimationName;
}

/**
 * Is the animation playing.
 * @see dragonBones.animation.AnimationState.
 */
public var isPlaying(getIsPlaying, null):Bool;
 	private function getIsPlaying():Bool
{
	return _isPlaying && !isComplete;
}

/**
 * Is animation complete.
 * @see dragonBones.animation.AnimationState.
 */
public var isComplete(getIsComplete, null):Bool;
 	private function getIsComplete():Bool
{
	return animationState.isComplete;
}

/**
 * The last AnimationState this Animation played.
 * @see dragonBones.objects.AnimationData.
 */
public var lastAnimationState(getLastAnimationState, null):FastAnimationState;
 	private function getLastAnimationState():FastAnimationState
{
	return animationState;
}
/**
 * The name of the last AnimationData played.
 * @see dragonBones.objects.AnimationData.
 */
public var lastAnimationName(getLastAnimationName, null):String;
 	private function getLastAnimationName():String
{
	return animationState?animationState.name:null;
}
}