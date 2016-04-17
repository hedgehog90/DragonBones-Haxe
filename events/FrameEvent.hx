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
 * The FrameEvent class provides and defines all events dispatched by an Animation or Bone instance entering a new frame.
 *
 * 
 * @see dragonBones.animation.Animation
 */
class FrameEvent extends Event
{
public static var MOVEMENT_FRAME_EVENT(getMOVEMENT_FRAME_EVENT, null):String;
 	private function getMOVEMENT_FRAME_EVENT():String
{
	return  ANIMATION_FRAME_EVENT;
}

/**
 * Dispatched when the animation of the armatrue enter a frame.
 */
public static inline var ANIMATION_FRAME_EVENT:String = "animationFrameEvent";

/**
 * 
 */
public static inline var BONE_FRAME_EVENT:String ="boneFrameEvent";

/**
 * The entered frame label.
 */
public var frameLabel:String;

public var bone:Object;

/**
 * The armature that is the target of this event.
 */
public var armature(getArmature, null):Armature;
 	private function getArmature():Armature
{
	return target as Armature;
}

/**
 * The animationState instance.
 */
public var animationState:Object;

/**
 * Creates a new FrameEvent instance.
 * @param type
 * @param cancelable
 */
public function new(type:String, cancelable:Bool = false)
{
	super(type, false, cancelable);
}

/**
 * @private
 *
 * @return An exact duplicate of the current object.
 */
override public function clone():Event
{
	var event:FrameEvent = new FrameEvent(type, cancelable);
	event.animationState = animationState;
	event.bone = bone;
	event.animationState = animationState;
	event.frameLabel = frameLabel;
	return event;
}
}