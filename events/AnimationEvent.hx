package dragonbones.events;

/**
* Copyright 2012-2013. DragonBones. All Rights Reserved.
* @playerversion Flash 10.0, Flash 10
* @langversion 3.0
* @version 2.0
*/
import flash.events.Event;

import dragonBones.Armature;

/**
 * The AnimationEvent provides and defines all events dispatched during an animation.
 *
 * @see dragonBones.Armature
 * @see dragonBones.animation.Animation
 */
class AnimationEvent extends Event
{
/**
 * 不推荐使用.
 */
public static var MOVEMENT_CHANGE(getMOVEMENT_CHANGE, null):String;
 	private function getMOVEMENT_CHANGE():String
{
	return FADE_IN;
}

/**
 * Dispatched when the playback of an animation fade in.
 */
public static inline var FADE_IN:String = "fadeIn";

/**
 * Dispatched when the playback of an animation fade out.
 */
public static inline var FADE_OUT:String = "fadeOut";

/**
 * Dispatched when the playback of an animation starts.
 */
public static inline var START:String = "start";

/**
 * Dispatched when the playback of a animation stops.
 */
public static inline var COMPLETE:String = "complete";

/**
 * Dispatched when the playback of a animation completes a loop.
 */
public static inline var LOOP_COMPLETE:String = "loopComplete";

/**
 * Dispatched when the playback of an animation fade in complete.
 */
public static inline var FADE_IN_COMPLETE:String = "fadeInComplete";

/**
 * Dispatched when the playback of an animation fade out complete.
 */
public static inline var FADE_OUT_COMPLETE:String = "fadeOutComplete";

/**
 * 不推荐的API.
 */
public var movementID(getMovementID, null):String;
 	private function getMovementID():String
{
	return animationName;
}

/**
 * The animationState instance.
 */
public var animationState:Object;

/**
 * The armature that is the taget of this event.
 */
public var armature(getArmature, null):Armature;
 	private function getArmature():Armature
{
	return target as Armature;
}

public var animationName(getAnimationName, null):String;
 	private function getAnimationName():String
{
	return animationState.name;
}

/**
 * Creates a new AnimationEvent instance.
 * @param type
 * @param cancelable
 */
public function new(type:String, cancelable:Bool = false)
{
	super(type, false, cancelable);
}

/**
 * @private
 * @return
 */
override public function clone():Event
{
	var event:AnimationEvent = new AnimationEvent(type, cancelable);
	event.animationState = animationState;
	return event;
}
}