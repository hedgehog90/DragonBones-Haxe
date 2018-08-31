package dragonbones.fast.animation;

import dragonBones.cache.AnimationCache;
import dragonBones.core.IAnimationState;
import dragonBones.core.dragonBones_internal;
import dragonBones.events.AnimationEvent;
import dragonBones.fast.FastArmature;
import dragonBones.fast.FastBone;
import dragonBones.fast.FastSlot;
import dragonBones.objects.AnimationData;
import dragonBones.objects.Frame;
import dragonBones.objects.SlotTimeline;
import dragonBones.objects.TransformTimeline;

class FastAnimationState implements IAnimationState
{

	public var animationCache:AnimationCache;
	/**
	 * If auto genterate tween between keyframes.
	 */
	public var autoTween:Bool;
	private var _progress:Float;

	private var _armature:FastArmature;

	private var _boneTimelineStateList:Array<FastBoneTimelineState> = [];
	private var _slotTimelineStateList:Array<FastSlotTimelineState> = [];
	public var animationData:AnimationData;

	public var name:String;
	private var _time:Float;//秒
	private var _currentFrameIndex:Int;
	private var _currentFramePosition:Int;
	private var _currentFrameDuration:Int;

	private var _currentPlayTimes:Int;
	private var _totalTime:Int;//毫秒
	private var _currentTime:Int;
	private var _lastTime:Int;

	private var _isComplete:Bool;
	private var _isPlaying:Bool;
	private var _timeScale:Float;
	private var _playTimes:Int;

	private var _fading:Bool = false;
	private var _listenCompleteEvent:Bool;
	private var _listenLoopCompleteEvent:Bool;

	private var _fadeTotalTime:Float;


	public function new()
	{
	}

	public function dispose():Void
	{
		resetTimelineStateList();
		_armature = null;
	}

	/**
	 * Play the current animation. 如果动画已经播放完毕, 将不会继续播放.
	 */
	public function play():FastAnimationState
	{
		_isPlaying = true;
		return this;
	}

	/**
	 * Stop playing current animation.
	 */
	public function stop():FastAnimationState
	{
		_isPlaying = false;
		return this;
	}

	public function setCurrentTime(value:Float):FastAnimationState
	{
		if(value < 0 || isNaN(value))
		{
		value = 0;
		}
		_time = value;
		_currentTime = _time * 1000;
		return this;
	}

	private function resetTimelineStateList():Void
	{
		var i:Int = _boneTimelineStateList.length;
		while(i --)
		{
			FastBoneTimelineState.returnObject(_boneTimelineStateList[i]);
		}
		_boneTimelineStateList.length = 0;
		
		i = _slotTimelineStateList.length;
		while(i --)
		{
			FastSlotTimelineState.returnObject(_slotTimelineStateList[i]);
		}
		_slotTimelineStateList.length = 0;
		name = null;
	}

	/** @private */
	private function fadeIn(aniData:AnimationData, playTimes:Float, timeScale:Float, fadeTotalTime:Float):Void
	{
		animationData = aniData;
		
		name = animationData.name;
		_totalTime = animationData.duration;
		autoTween = aniData.autoTween;
		setTimeScale(timeScale);
		setPlayTimes(playTimes);
		
		//reset
		_isComplete = false;
		_currentFrameIndex = -1;
		_currentPlayTimes = -1;
		if(Math.round(_totalTime * animationData.frameRate * 0.001) < 2)
		{
			_currentTime = _totalTime;
		}
		else
		{
			_currentTime = -1;
		}

		_fadeTotalTime = fadeTotalTime * _timeScale;
		_fading = _fadeTotalTime>0;
		//default
		_isPlaying = true;
		
		_listenCompleteEvent = _armature.hasEventListener(AnimationEvent.COMPLETE);
		
		if(this._armature.enableCache && animationCache && _fading && _boneTimelineStateList)
		{
			updateTransformTimeline(progress);
		}
		
		_time = 0;
		_progress = 0;
		
		updateTimelineStateList();
		hideBones();
		return;
	}

	/**
	 * @private
	 * Update timeline state based on mixing transforms and clip.
	 */
	private function updateTimelineStateList():Void
	{	
		resetTimelineStateList();
		var timelineName:String;
		for each(var boneTimeline:TransformTimeline in animationData.timelineList)
		{
			timelineName = boneTimeline.name;
			var bone:FastBone = _armature.getBone(timelineName);
			if(bone)
			{
				var boneTimelineState:FastBoneTimelineState = FastBoneTimelineState.borrowObject();
				boneTimelineState.fadeIn(bone, this, boneTimeline);
				_boneTimelineStateList.push(boneTimelineState);
			}
		}
			
		for each(var slotTimeline:SlotTimeline in animationData.slotTimelineList)
		{
			timelineName = slotTimeline.name;
			var slot:FastSlot = _armature.getSlot(timelineName);
			if(slot && slot.displayList.length > 0)
			{
				var slotTimelineState:FastSlotTimelineState = FastSlotTimelineState.borrowObject();
				slotTimelineState.fadeIn(slot, this, slotTimeline);
				_slotTimelineStateList.push(slotTimelineState);
			}
		}
	}

	/** @private */
	private function advanceTime(passedTime:Float):Void
	{
		passedTime *= _timeScale;
		if(_fading)
		{
		//计算progress
		_time += passedTime;
		_progress = _time / _fadeTotalTime;
		if(progress >= 1)
		{
			_progress = 0;
			_time = 0;
			_fading = false;
		}
		}
		
		if(_fading)
		{
		//update boneTimelie
		for each(var timeline:FastBoneTimelineState in _boneTimelineStateList)
		{
			timeline.updateFade(progress);
		}
		//update slotTimelie
		for each(var slotTimeline:FastSlotTimelineState in _slotTimelineStateList)
		{
			slotTimeline.updateFade(progress);
		}
		}
		else
		{
		advanceTimelinesTime(passedTime);
		}
	}

	private function advanceTimelinesTime(passedTime:Float):Void
	{
		if(_isPlaying)
		{
		_time += passedTime;
		}
		
		//计算是否已经播放完成isThisComplete

		var startFlg:Bool = false;
		var loopCompleteFlg:Bool = false;
		var completeFlg:Bool = false;
		var isThisComplete:Bool = false;
		var currentPlayTimes:Int = 0;
		var currentTime:Int = _time * 1000;
		if( _playTimes == 0 || //无限循环
		currentTime < _playTimes * _totalTime) //没有播放完毕
		{
		isThisComplete = false;
		
		_progress = currentTime / _totalTime;
		currentPlayTimes = Math.ceil(progress) || 1;
		_progress -= Math.floor(progress);
		currentTime %= _totalTime;
		}
		else
		{
		currentPlayTimes = _playTimes;
		currentTime = _totalTime;
		isThisComplete = true;
		_progress = 1;
		}
		
		_isComplete = isThisComplete;

		if(this.isUseCache())
		{
		animationCache.update(progress);
		}
		else
		{
		updateTransformTimeline(progress);
		}
		
		//update main timeline
		if(_currentTime != currentTime)
		{
		if(_currentPlayTimes != currentPlayTimes)	//check loop complete
		{
			if(_currentPlayTimes > 0 && currentPlayTimes > 1)
			{
			loopCompleteFlg = true;
			}
			_currentPlayTimes = currentPlayTimes;
		}
		if(_currentTime < 0)	//check start
		{
			startFlg = true;
		}
		if (_isComplete)
		{
			completeFlg = true;
		}
		_lastTime = _currentTime;
		_currentTime = currentTime;
		updateMainTimeline(isThisComplete);
		}
		
		//抛事件
		var event:AnimationEvent;
		if(startFlg)
		{
		if(_armature.hasEventListener(AnimationEvent.START))
		{
			event = new AnimationEvent(AnimationEvent.START);
			event.animationState = this;
			_armature.addEvent(event);
		}
		}
		if(completeFlg)
		{
		if (_armature.hasEventListener(AnimationEvent.COMPLETE))
		{
			event = new AnimationEvent(AnimationEvent.COMPLETE);
			event.animationState = this;
			_armature.addEvent(event);
		}
		}
		else if(loopCompleteFlg)
		{
		if (_armature.hasEventListener(AnimationEvent.LOOP_COMPLETE))
		{
			event = new AnimationEvent(AnimationEvent.LOOP_COMPLETE);
			event.animationState = this;
			_armature.addEvent(event);
		}
		
		}
	}

	private function updateTransformTimeline(progress:Float):Void
	{
		var i:Int = _boneTimelineStateList.length;
		var boneTimeline:FastBoneTimelineState;
		var slotTimeline:FastSlotTimelineState;
		
		if(_isComplete) // 性能优化
		{
		//update boneTimelie
		while(i--)
		{
			boneTimeline = _boneTimelineStateList[i];
			boneTimeline.update(progress);
			_isComplete = boneTimeline._isComplete && _isComplete;
		}
		
		i = _slotTimelineStateList.length;
		
		//update slotTimelie
		while(i--)
		{
			slotTimeline = _slotTimelineStateList[i];
			slotTimeline.update(progress);
			_isComplete = slotTimeline._isComplete && _isComplete;
		}
		}
		else
		{
		//update boneTimelie
		while(i--)
		{
			boneTimeline = _boneTimelineStateList[i];
			boneTimeline.update(progress);
		}
		
		i = _slotTimelineStateList.length;
		
		//update slotTimelie
		while(i--)
		{
			slotTimeline = _slotTimelineStateList[i];
			slotTimeline.update(progress);
		}
		}
	}

	private function updateMainTimeline(isThisComplete:Bool):Void
	{
		var frameList:Array<Frame> = animationData.frameList;
		if(frameList.length > 0)
		{
		var prevFrame:Frame;
		var currentFrame:Frame;
		for (var i:Int = 0, l:Int = animationData.frameList.length; i < l; ++i)
		{
			if(_currentFrameIndex < 0)
			{
			_currentFrameIndex = 0;
			}
			else if(_currentTime < _currentFramePosition || _currentTime >= _currentFramePosition + _currentFrameDuration || _currentTime < _lastTime)
			{
			_lastTime = _currentTime;
			_currentFrameIndex ++;
			if(_currentFrameIndex >= frameList.length)
			{
				if(isThisComplete)
				{
				_currentFrameIndex --;
				break;
				}
				else
				{
				_currentFrameIndex = 0;
				}
			}
			}
			else
			{
			break;
			}
			currentFrame = frameList[_currentFrameIndex];
			
			if(prevFrame)
			{
			_armature.arriveAtFrame(prevFrame, this);
			}
			
			_currentFrameDuration = currentFrame.duration;
			_currentFramePosition = currentFrame.position;
			prevFrame = currentFrame;
		}
		
		if(currentFrame)
		{
			_armature.arriveAtFrame(currentFrame, this);
		}
		}
	}

	private function hideBones():Void
	{
		for each(var timelineName:String in animationData.hideTimelineNameMap)
		{
		var bone:FastBone = _armature.getBone(timelineName);
		if(bone)
		{
			bone.hideSlots();
		}
		}
		for each(var slotTimelineName:String in animationData.hideSlotTimelineNameMap)
		{
		var slot:FastSlot = _armature.getSlot(slotTimelineName);
		if (slot)
		{
			slot.resetToOrigin();
		}
		}
	}

	public function setTimeScale(value:Float):FastAnimationState
	{
		if(isNaN(value) || value == Infinity)
		{
		value = 1;
		}
		_timeScale = value;
		return this;
	}

	public function setPlayTimes(value:Int):FastAnimationState
	{
		//如果动画只有一帧  播放一次就可以
		if(Math.round(_totalTime * 0.001 * animationData.frameRate) < 2)
		{
		_playTimes = 1;
		}
		else
		{
		_playTimes = value;
		}
		return this;
	}

	/**
	 * playTimes Play times(0:loop forever, 1~+∞:play times, -1~-∞:will fade animation after play complete).
	 */
	public var playTimes(getPlayTimes, null):Int;
		private function getPlayTimes():Int
	{
		return _playTimes;
	}

	/**
	 * Current animation played times
	 */
	public var currentPlayTimes(getCurrentPlayTimes, null):Int;
		private function getCurrentPlayTimes():Int
	{
		return _currentPlayTimes < 0 ? 0 : _currentPlayTimes;
	}

	/**
	 * Is animation complete.
	 */
	public var isComplete(getIsComplete, null):Bool;
		private function getIsComplete():Bool
	{
		return _isComplete; 
	}

	/**
	 * Is animation playing.
	 */
	public var isPlaying(getIsPlaying, null):Bool;
		private function getIsPlaying():Bool
	{
		return (_isPlaying && !_isComplete);
	}

	/**
	 * The length of the animation clip in seconds.
	 */
	public var totalTime(getTotalTime, null):Float;
		private function getTotalTime():Float
	{
		return _totalTime * 0.001;
	}

	/**
	 * The current time of the animation.
	 */
	public var currentTime(getCurrentTime, null):Float;
		private function getCurrentTime():Float
	{
		return _currentTime < 0 ? 0 : _currentTime * 0.001;
	}


	public function isUseCache():Bool
	{
		return _armature.enableCache && animationCache && !_fading;
	}

	public var progress(getProgress, null):Float;
		private function getProgress():Float
	{
		return _progress;
	}
}