package dragonbones.animation;

import flash.utils.GetTimer;

/**
 * A WorldClock instance lets you conveniently update many number of Armature instances at once. You can add/remove Armature instance and set a global timescale that will apply to all registered Armature instance animations.
 * @see dragonBones.Armature
 * @see dragonBones.animation.Animation
 */
public final class WorldClock implements IAnimatable
{
/**
 * A global static WorldClock instance ready to use.
 */
public static var clock:WorldClock = new WorldClock();

private var _animatableList:Vector<IAnimatable>;

private var _time:Float;
public var time(getTime, setTime):Float;
 	private function getTime():Float
{
	return _time;
}

private var _timeScale:Float;
private var _animatable:IAnimatable;
private var _length:Int;
private var _currentIndex:Int;
/**
 * The time scale to apply to the number of second passed to the advanceTime() method.
 * @param A Number to use as a time scale.
 */
public var time(getTime, setTime):Float;
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
 * Creates a new WorldClock instance. (use the static var WorldClock.clock instead).
 */
public function WorldClock(time:Float = -1, timeScale:Float = 1)
{
	_time = time >= 0?time:getTimer() * 0.001;
	_timeScale = isNaN(timeScale)?1:timeScale;
	_animatableList = new Vector<IAnimatable>;
}

/** 
 * Returns true if the IAnimatable instance is contained by WorldClock instance.
 * @param An IAnimatable instance (Armature or custom)
 * @return true if the IAnimatable instance is contained by WorldClock instance.
 */
public function contains(animatable:IAnimatable):Bool
{
	return _animatableList.indexOf(animatable) >= 0;
}

/**
 * Add a IAnimatable instance (Armature or custom) to this WorldClock instance.
 * @param An IAnimatable instance (Armature, WorldClock or custom)
 */
public function add(animatable:IAnimatable):Void
{
	if (animatable && _animatableList.indexOf(animatable) == -1)
	{
	_animatableList.push(animatable);
	}
}

/**
 * Remove a IAnimatable instance (Armature or custom) from this WorldClock instance.
 * @param An IAnimatable instance (Armature or custom)
 */
public function remove(animatable:IAnimatable):Void
{
	var index:Int = _animatableList.indexOf(animatable);
	if (index >= 0)
	{
	_animatableList[index] = null;
	}
}

/**
 * Remove all IAnimatable instance (Armature or custom) from this WorldClock instance.
 */
public function clear():Void
{
	_animatableList.length = 0;
}

/**
 * Update all registered IAnimatable instance animations using this method typically in an ENTERFRAME Event or with a Timer.
 * @param The amount of second to move the playhead ahead.
 */
public function advanceTime(passedTime:Float):Void
{
	if(passedTime < 0)
	{
	passedTime = getTimer() * 0.001 - _time;
	}
	_time += passedTime;
	
	passedTime *= _timeScale;
	
	_length = _animatableList.length;
	if(_length == 0)
	{
	return;
	}
	_currentIndex = 0;
	
	for(var i:Int = 0;i < _length; i++)
	{
	_animatable = _animatableList[i];
	if(_animatable)
	{
		if(_currentIndex != i)
		{
		_animatableList[_currentIndex] = _animatable;
		_animatableList[i] = null;
		}
		_animatable.advanceTime(passedTime);
		_currentIndex ++;
	}
	}
	
	if (_currentIndex != i)
	{
	_length = _animatableList.length;
	while(i < _length)
	{
		_animatableList[_currentIndex ++] = _animatableList[i ++];
	}
	_animatableList.length = _currentIndex;
	}
}
}