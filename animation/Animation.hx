package dragonbones.animation;

import dragonBones.Armature;
import dragonBones.Slot;
import dragonBones.core.dragonBones_internal;
import dragonBones.fast.animation.FastBoneTimelineState;
import dragonBones.fast.animation.FastSlotTimelineState;
import dragonBones.objects.AnimationData;

/**
 * An Animation instance is used to control the animation state of an Armature.
 * @see dragonBones.Armature
 * @see dragonBones.animation.Animation
 * @see dragonBones.animation.AnimationState
 */
import flash.Vector;

class Animation
{
	public static inline var NONE:String = "none";
	public static inline var SAME_LAYER:String = "sameLayer";
	public static inline var SAME_GROUP:String = "sameGroup";
	public static inline var SAME_LAYER_AND_GROUP:String = "sameLayerAndGroup";
	public static inline var ALL:String = "all";

	/**
	 * Whether animation tweening is enabled or not.
	 */
	public var tweenEnabled:Bool;
	private var _armature:Armature;
	private var _animationStateList:Vector<AnimationState>;
	private var _animationDataList:Vector<AnimationData>;
	private var _animationList:Vector<String>;
	private var _isPlaying:Bool;
	private var _timeScale:Float;

	/** @private */
	private var _lastAnimationState:AnimationState;

	/** @private */
	private var _isFading:Bool

	/** @private */
	private var _animationStateCount:Int;


	/**
	 * Creates a new Animation instance and attaches it to the passed Armature.
	 * @param armature An Armature to attach this Animation instance to.
	 */
	public function new(armature:Armature)
	{
		_armature = armature;
		_animationList = new Vector<String>;
		_animationStateList = new Vector<AnimationState>;
		
		_timeScale = 1;
		_isPlaying = false;
		
		tweenEnabled = true;
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
		
		resetAnimationStateList();
		
		_animationList.length = 0;
		
		_armature = null;
		_animationDataList = null;
		_animationList = null;
		_animationStateList = null;
	}

	private function resetAnimationStateList():Void
	{
		var i:Int = _animationStateList.length;
		var animationState:AnimationState;
		while(i --)
		{
		animationState = _animationStateList[i];
		animationState.resetTimelineStateList();
		AnimationState.returnObject(animationState);
		}
		_animationStateList.length = 0;
	}

	/**
	 * Fades the animation with name animation in over a period of time seconds and fades other animations out.
	 * @param animationName The name of the AnimationData to play.
	 * @param fadeInTime A fade time to apply (>= 0), -1 means use xml data's fadeInTime. 
	 * @param duration The duration of that Animation. -1 means use xml data's duration.
	 * @param playTimes Play times(0:loop forever, >=1:play times, -1~-∞:will fade animation after play complete), 默认使用AnimationData.loop.
	 * @param layer The layer of the animation.
	 * @param group The group of the animation.
	 * @param fadeOutMode Fade out mode (none, sameLayer, sameGroup, sameLayerAndGroup, all).
	 * @param pauseFadeOut Pause other animation playing.
	 * @param pauseFadeIn Pause this animation playing before fade in complete.
	 * @return AnimationState.
	 * @see dragonBones.objects.AnimationData.
	 * @see dragonBones.animation.AnimationState.
	 */
	public function gotoAndPlay(
		animationName:String, 
		fadeInTime:Float = -1, 
		duration:Float = -1, 
		playTimes:Float = NaN, 
		layer:Int = 0, 
		group:String = null,
		fadeOutMode:String = SAME_LAYER_AND_GROUP,
		pauseFadeOut:Bool = true,
		pauseFadeIn:Bool = true
	):AnimationState
	{
		if (!_animationDataList)
		{
		return null;
		}
		var i:Int = _animationDataList.length;
		var animationData:AnimationData;
		while(i --)
		{
		if(_animationDataList[i].name == animationName)
		{
			animationData = _animationDataList[i];
			break;
		}
		}
		if (!animationData)
		{
		return null;
		}
		var needUpdata:Bool = !_isPlaying;
		_isPlaying = true;
		_isFading = true;
		
		//
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
		
	//根据fadeOutMode,选择正确的animationState执行fadeOut
		var animationState:AnimationState;
		switch(fadeOutMode)
		{
		case NONE:
			break;
		
		case SAME_LAYER:
			i = _animationStateList.length;
			while(i --)
			{
			animationState = _animationStateList[i];
			if(animationState.layer == layer)
			{
				animationState.fadeOut(fadeInTime, pauseFadeOut);
			}
			}
			break;
		
		case SAME_GROUP:
			i = _animationStateList.length;
			while(i --)
			{
			animationState = _animationStateList[i];
			if(animationState.group == group)
			{
				animationState.fadeOut(fadeInTime, pauseFadeOut);
			}
			}
			break;
		
		case ALL:
			i = _animationStateList.length;
			while(i --)
			{
			animationState = _animationStateList[i];
			animationState.fadeOut(fadeInTime, pauseFadeOut);
			}
			break;
		
		case SAME_LAYER_AND_GROUP:
		default:
			i = _animationStateList.length;
			while(i --)
			{
			animationState = _animationStateList[i];
			if(animationState.layer == layer && animationState.group == group )
			{
				animationState.fadeOut(fadeInTime, pauseFadeOut);
			}
			}
			break;
		}
		
		_lastAnimationState = AnimationState.borrowObject();
		_lastAnimationState._layer = layer;
		_lastAnimationState._group = group;
		_lastAnimationState.autoTween = tweenEnabled;
		_lastAnimationState.fadeIn(_armature, animationData, fadeInTime, 1 / durationScale, playTimes, pauseFadeIn);
		
		addState(_lastAnimationState);
		
	//控制子骨架播放同名动画
		var slotList:Vector<Slot> = _armature.getSlots(false);
		i = slotList.length;
		while(i --)
		{
		var slot:Slot = slotList[i];
		if(slot.childArmature)
		{
			slot.childArmature.animation.gotoAndPlay(animationName, fadeInTime);
		}
		}
		if(needUpdata)
		{
		_armature.advanceTime(0);
		}
		return _lastAnimationState;
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
		duration:Float = -1, 
		layer:Int = 0, 
		group:String = null, 
		fadeOutMode:String = ALL
	):AnimationState
	{
		var animationState:AnimationState = gotoAndPlay(animationName, fadeInTime, duration, NaN, layer, group, fadeOutMode);
		if(normalizedTime >= 0)
		{
		animationState.setCurrentTime(animationState.totalTime * normalizedTime);
		}
		else
		{
		animationState.setCurrentTime(time);
		}
		
		animationState.lastFrameAutoTween = false;
		animationState.stop();
		
		return animationState;
	}

	/**
	 * Play the animation from the current position.
	 */
	public function play():Void
	{
		if (!_animationDataList || _animationDataList.length == 0)
		{
		return;
		}
		if(!_lastAnimationState)
		{
		gotoAndPlay(_animationDataList[0].name);
		}
		else if (!_isPlaying)
		{
		_isPlaying = true;
		}
		else
		{
		gotoAndPlay(_lastAnimationState.name);
		}
	}

	public function stop():Void
	{
		_isPlaying = false;
	}

	/**
	 * Returns the AnimationState named name.
	 * @return A AnimationState instance.
	 * @see dragonBones.animation.AnimationState.
	 */
	public function getState(name:String, layer:Int = 0):AnimationState
	{
		var i:Int = _animationStateList.length;
		while(i --)
		{
		var animationState:AnimationState = _animationStateList[i];
		if(animationState.name == name && animationState.layer == layer)
		{
			return animationState;
		}
		}
		return null;
	}

	/**
	 * check if contains a AnimationData by name.
	 * @return Boolean.
	 * @see dragonBones.animation.AnimationData.
	 */
	public function hasAnimation(animationName:String):Bool
	{
		var i:Int = _animationDataList.length;
		while(i --)
		{
		if(_animationDataList[i].name == animationName)
		{
			return true;
		}
		}
		
		return false;
	}

	/** @private */
	private function advanceTime(passedTime:Float):Void
	{
		if(!_isPlaying)
		{
		return;
		}
		
		var isFading:Bool = false;
		
		passedTime *= _timeScale;
		var i:Int = _animationStateList.length;
		while(i --)
		{
		var animationState:AnimationState = _animationStateList[i];
		if(animationState.advanceTime(passedTime))
		{
			removeState(animationState);
		}
		else if(animationState.fadeState != 1)
		{
			isFading = true;
		}
		}
		
		_isFading = isFading;
	}

	/** @private */
	//当动画播放过程中Bonelist改变时触发
	private function updateAnimationStates():Void
	{
		var i:Int = _animationStateList.length;
		while(i --)
		{
		_animationStateList[i].updateTimelineStates();
		}
	}

	private function addState(animationState:AnimationState):Void
	{
		if(_animationStateList.indexOf(animationState) < 0)
		{
		_animationStateList.unshift(animationState);
		
		_animationStateCount = _animationStateList.length;
		}
	}

	private function removeState(animationState:AnimationState):Void
	{
		var index:Int = _animationStateList.indexOf(animationState);
		if(index >= 0)
		{
		_animationStateList.splice(index, 1);
		AnimationState.returnObject(animationState);
		
		if(_lastAnimationState == animationState)
		{
			if(_animationStateList.length > 0)
			{
			_lastAnimationState = _animationStateList[0];
			}
			else
			{
			_lastAnimationState = null;
			}
		}
		
		_animationStateCount = _animationStateList.length;
		}
	}



	/**
	* Unrecommended API. Recommend use animationList.
	*/
	public var movementList(getMovementList, setMovementList):Vector;
		private function getMovementList():Vector<String>
	{
		return _animationList;
	}

	/**
	* Unrecommended API. Recommend use lastAnimationName.
	*/
	public var movementID(getMovementID, setMovementID):String;
		private function getMovementID():String
	{
		return lastAnimationName;
	}



	/**
	 * The last AnimationState this Animation played.
	 * @see dragonBones.objects.AnimationData.
	 */
	public var lastAnimationState(getLastAnimationState, setLastAnimationState):AnimationState;
		private function getLastAnimationState():AnimationState
	{
		return _lastAnimationState;
	}
	/**
	 * The name of the last AnimationData played.
	 * @see dragonBones.objects.AnimationData.
	 */
	public var lastAnimationName(getLastAnimationName, setLastAnimationName):String;
		private function getLastAnimationName():String
	{
		return _lastAnimationState?_lastAnimationState.name:null;
	}


	/**
	 * An vector containing all AnimationData names the Animation can play.
	 * @see dragonBones.objects.AnimationData.
	 */
	public var animationList(getAnimationList, setAnimationList):Vector;
		private function getAnimationList():Vector<String>
	{
		return _animationList;
	}


	/**
	 * Is the animation playing.
	 * @see dragonBones.animation.AnimationState.
	 */
	public var isPlaying(getIsPlaying, setIsPlaying):Bool;
		private function getIsPlaying():Bool
	{
		return _isPlaying && !isComplete;
	}

	/**
	 * Is animation complete.
	 * @see dragonBones.animation.AnimationState.
	 */
	public var isComplete(getIsComplete, setIsComplete):Bool;
		private function getIsComplete():Bool
	{
		if(_lastAnimationState)
		{
		if(!_lastAnimationState.isComplete)
		{
			return false;
		}
		var i:Int = _animationStateList.length;
		while(i --)
		{
			if(!_animationStateList[i].isComplete)
			{
			return false;
			}
		}
		return true;
		}
		return true;
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
		_animationList.length = 0;
		for each(var animationData:AnimationData in _animationDataList)
		{
		_animationList[_animationList.length] = animationData.name;
		}
	}

}