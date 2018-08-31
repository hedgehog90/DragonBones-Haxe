package dragonbones;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.utils.Dictionary;

import dragonBones.animation.Animation;
import dragonBones.animation.AnimationState;
import dragonBones.animation.TimelineState;
import dragonBones.core.IArmature;
import dragonBones.core.dragonBones_internal;
import dragonBones.events.ArmatureEvent;
import dragonBones.events.FrameEvent;
import dragonBones.events.SoundEvent;
import dragonBones.events.SoundEventManager;
import dragonBones.objects.ArmatureData;
import dragonBones.objects.DragonBonesData;
import dragonBones.objects.Frame;
import dragonBones.objects.IKData;
import dragonBones.objects.SkinData;
import dragonBones.objects.SlotData;

/**
 * Dispatched when slot's zOrder changed
 */
//[Event(name="zOrderUpdated", type="dragonBones.events.ArmatureEvent")]

/**
 * Dispatched when an animation state begins fade in (Even if fade in time is 0)
 */
//[Event(name="fadeIn", type="dragonBones.events.AnimationEvent")]

/**
 * Dispatched when an animation state begins fade out (Even if fade out time is 0)
 */
//[Event(name="fadeOut", type="dragonBones.events.AnimationEvent")]

/**
 * Dispatched when an animation state start to play(AnimationState may play when fade in start or end. It is controllable).
 */
//[Event(name="start", type="dragonBones.events.AnimationEvent")]

/**
 * Dispatched when an animation state play complete (if playtimes equals to 0 means loop forever. Then this Event will not be triggered)
 */
//[Event(name="complete", type="dragonBones.events.AnimationEvent")]

/**
 * Dispatched when an animation state complete a loop.
 */
//[Event(name="loopComplete", type="dragonBones.events.AnimationEvent")]

/**
 * Dispatched when an animation state fade in complete.
 */
//[Event(name="fadeInComplete", type="dragonBones.events.AnimationEvent")]

/**
 * Dispatched when an animation state fade out complete.
 */
//[Event(name="fadeOutComplete", type="dragonBones.events.AnimationEvent")]

/**
 * Dispatched when an animation state enter a frame with animation frame event.
 */
//[Event(name="animationFrameEvent", type="dragonBones.events.FrameEvent")]

/**
 * Dispatched when an bone enter a frame with animation frame event.
 */
//[Event(name="boneFrameEvent", type="dragonBones.events.FrameEvent")]

class Armature extends EventDispatcher implements IArmature
{
	private var __dragonBonesData:DragonBonesData;


	/**
	 * The instance dispatch sound event.
	 */
	private static inline var _soundManager:SoundEventManager = SoundEventManager.getInstance();

	/**
	 * The name should be same with ArmatureData's name
	 */
	public var name:String;

	/**
	 * An object that can contain any user extra data.
	 */
	public var userData:Object;

	/** @private Set it to true when slot's zorder changed*/
	private var _slotsZOrderChanged:Bool;

	/** @private Store event needed to dispatch in current frame. When advanceTime execute complete, dispath them.*/
	private var _eventList:Array<Event>;
	private var _skewEnable:Bool;


	/** @private Store slots based on slots' zOrder*/
	private var _slotList:Array<Slot>;

	/** @private Store bones based on bones' hierarchy (From root to leaf)*/
	private var _boneList:Array<Bone>;
	/**计算IK约束**/
	private var _boneIKList:Array<Array<Bone>> = new Array<Array<Bone>>();
	private var _ikList:Array<IKConstraint>;

	private var _delayDispose:Bool;
	private var _lockDispose:Bool;

	// optimized by arhcy
	private var _isFading:Bool;
		private var _i:Int;
		private var _tmpBone:Bone;
		private var _childArmature:Armature;
		private var _tmpSlot:Slot;
	 
	/** @private */
	private var _armatureData:ArmatureData;
	/**
	 * ArmatureData.
	 * @see dragonBones.objects.ArmatureData.
	 */
	public var armatureData(getArmatureData, null):ArmatureData;
		private function getArmatureData():ArmatureData
	{
		return _armatureData;
	}

	/** @private */
	private var _display:Object;
	/**
	 * Armature's display object. It's instance type depends on render engine. For example "flash.display.DisplayObject" or "startling.display.DisplayObject"
	 */
	public var display(getDisplay, null):Object;
		private function getDisplay():Object
	{
		return _display;
	}

	/** @private */
	private var _animation:Animation;
	/**
	 * An Animation instance
	 * @see dragonBones.animation.Animation
	 */
	public var animation(getAnimation, null):Animation;
		private function getAnimation():Animation
	{
		return _animation;
	}

	/**
	 * save more skinLists
	 */
	private var _skinLists:Object;
	/**
	 * Creates a Armature blank instance.
	 * @param Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
	 * @see #display
	 */
	public function new(display:Object)
	{
		super(this);
		_display = display;
		
		_animation = new Animation(this);
		
		_slotsZOrderChanged = false;
		
		_slotList = new Array<Slot>;
		_slotList.fixed = true;
		_boneList = new Array<Bone>;
		_boneList.fixed = true;
		_ikList = new Array();
		_ikList.fixed = true;
		_eventList = new Array<Event>;
		_skinLists = { };
		_delayDispose = false;
		_lockDispose = false;
		
		_armatureData = null;
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
		var i:Int = _slotList.length;
		while(i --)
		{
		_slotList[i].dispose();
		}
		i = _boneList.length;
		while(i --)
		{
		_boneList[i].dispose();
		}
		i = _ikList.length;
		while(i --)
		{
		_ikList[i].dispose();
		}
		
		_slotList.fixed = false;
		_slotList.length = 0;
		_boneList.fixed = false;
		_boneList.length = 0;
		_ikList.fixed = false;
		_ikList.length = 0;
		_eventList.length = 0;
		
		_armatureData = null;
		_animation = null;
		_slotList = null;
		_boneList = null;
		_ikList = null;
		_eventList = null;
		
		//_display = null;
	}

	/**
	 * Force update bones and slots. (When bone's animation play complete, it will not update) 
	 */
	public function invalidUpdate(boneName:String = null):Void
	{
		if(boneName)
		{
			var bone:Bone = getBone(boneName);
			if(bone)
			{
				bone.invalidUpdate();
			}
		}
		else
		{
		var i:Int = _boneList.length;
			while(i --)
			{
				_boneList[i].invalidUpdate();
			}
		}
	}

	/**
	 * Update the animation using this method typically in an ENTERFRAME Event or with a Timer.
	 * @param The amount of second to move the playhead ahead.
	 */
	public function advanceTime(passedTime:Float):Void
	{
		_lockDispose = true;
		
		_animation.advanceTime(passedTime);
		
		passedTime *= _animation.timeScale;	//_animation's time scale will impact childArmature
		
		var isFading:Bool = _animation._isFading;
		var i:Int = 0;
		var len:Int = _boneIKList.length;
		var bone:Bone;
		var j:Int;
		var jLen:Int;
		
		for (i = 0; i < len; i++) 
		{
			for (j = 0, jLen = _boneIKList[i].length; j < jLen; j++)
			{
				bone = _boneIKList[i][j];
				bone.update(isFading);
				bone.rotationIK = bone.global.rotation;
				if(i != 0 && bone.isIKConstraint)
				{
				_ikList[i-1].compute();
				bone.adjustGlobalTransformMatrixByIK();
				}
			}
		}
		
		//IK
		
		i = _slotList.length;
		while(i --)
		{
			var slot:Slot = _slotList[i];
			slot.update();
			if(slot._isShowDisplay)
			{
				var childArmature:Armature = slot.childArmature;
				if(childArmature)
				{
				childArmature.advanceTime(passedTime);
				}
			}
		}
		
		if(_slotsZOrderChanged)
		{
			updateSlotsZOrder();
			
			if(this.hasEventListener(ArmatureEvent.Z_ORDER_UPDATED))
			{
				this.dispatchEvent(new ArmatureEvent(ArmatureEvent.Z_ORDER_UPDATED));
			}
		}
		
		if(_eventList.length)
		{
			for each(var event:Event in _eventList)
			{
				this.dispatchEvent(event);
			}
			_eventList.length = 0;
		}
			
		_lockDispose = false;
		if(_delayDispose)
		{
			dispose();
		}
	}

	public function resetAnimation():Void
	{
		animation.stop();
		animation.resetAnimationStateList();
		
		for each(var boneItem:Bone in _boneList)
		{
			boneItem.removeAllStates();
		}
	}

	/**
	 * Get all Slot instance associated with this armature.
	 * @param if return Array copy
	 * @return A Array.&lt;Slot&gt; instance.
	 * @see dragonBones.Slot
	 */
	public function getSlots(returnCopy:Bool = true):Array<Slot>
	{
		return returnCopy?_slotList.concat():_slotList;
	}

	/**
	 * Retrieves a Slot by name
	 * @param The name of the Bone to retrieve.
	 * @return A Slot instance or null if no Slot with that name exist.
	 * @see dragonBones.Slot
	 */
	public function getSlot(slotName:String):Slot
	{
		for each(var slot:Slot in _slotList)
		{
			if(slot.name == slotName)
			{
				return slot;
			}
		}
		return null;
	}

	/**
	 * Gets the Slot associated with this DisplayObject.
	 * @param Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
	 * @return A Slot instance or null if no Slot with that DisplayObject exist.
	 * @see dragonBones.Slot
	 */
	public function getSlotByDisplay(displayObj:Object):Slot
	{
		if(displayObj)
		{
			for each(var slot:Slot in _slotList)
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
	 * Add a slot to a bone as child.
	 * @param slot A Slot instance
	 * @param boneName bone name
	 * @see dragonBones.core.DBObject
	 */
	public function addSlot(slot:Slot, boneName:String):Void
	{
		var bone:Bone = getBone(boneName);
		if (bone)
		{
			bone.addSlot(slot);
		}
		else
		{
			throw new ArgumentError();
		}
	}

	/**
	 * Remove a Slot instance from this Armature instance.
	 * @param The Slot instance to remove.
	 * @see dragonBones.Slot
	 */
	public function removeSlot(slot:Slot):Void
	{
		if(!slot || slot.armature != this)
		{
			throw new ArgumentError();
		}
		
		slot.parent.removeSlot(slot);
	}

	/**
	 * Remove a Slot instance from this Armature instance.
	 * @param The name of the Slot instance to remove.
	 * @see dragonBones.Slot
	 */
	public function removeSlotByName(slotName:String):Slot
	{
		var slot:Slot = getSlot(slotName);
		if(slot)
		{
			removeSlot(slot);
		}
		return slot;
	}

	/**
	 * Get all Bone instance associated with this armature.
	 * @param if return Array copy
	 * @return A Array.&lt;Bone&gt; instance.
	 * @see dragonBones.Bone
	 */
	public function getBones(returnCopy:Bool = true):Array<Bone>
	{
		return returnCopy?_boneList.concat():_boneList;
	}

	/**
	 * Retrieves a Bone by name
	 * @param The name of the Bone to retrieve.
	 * @return A Bone instance or null if no Bone with that name exist.
	 * @see dragonBones.Bone
	 */
	public function getBone(boneName:String):Bone
	{
		for each(var bone:Bone in _boneList)
		{
			if(bone.name == boneName)
			{
				return bone;
			}
		}
		return null;
	}

	/**
	 * Gets the Bone associated with this DisplayObject.
	 * @param Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
	 * @return A Bone instance or null if no Bone with that DisplayObject exist..
	 * @see dragonBones.Bone
	 */
	public function getBoneByDisplay(display:Object):Bone
	{
		var slot:Slot = getSlotByDisplay(display);
		return slot?slot.parent:null;
	}

	/**
	 * Add a Bone instance to this Armature instance.
	 * @param A Bone instance.
	 * @param (optional) The parent's name of this Bone instance.
	 * @see dragonBones.Bone
	 */
	public function addBone(bone:Bone, parentName:String = null, updateLater:Bool = false):Void
	{
		var parentBone:Bone;
		if(parentName)
		{
			parentBone = getBone(parentName);
			if (!parentBone)
			{
				throw new ArgumentError();
			}
		}
		
		if(parentBone)
		{
			parentBone.addChildBone(bone, updateLater);
		}
		else
		{
			if(bone.parent)
			{
				bone.parent.removeChildBone(bone, updateLater);
			}
			bone.setArmature(this);
			if(!updateLater)
			{
				updateAnimationAfterBoneListChanged();
			}
		}
	}

	/**
	 * Remove a Bone instance from this Armature instance.
	 * @param The Bone instance to remove.
	 * @see	dragonBones.Bone
	 */
	public function removeBone(bone:Bone, updateLater:Bool = false):Void
	{
		if(!bone || bone.armature != this)
		{
			throw new ArgumentError();
		}
		
		if(bone.parent)
		{
			bone.parent.removeChildBone(bone, updateLater);
		}
		else
		{
			bone.setArmature(null);
			if(!updateLater)
			{
				updateAnimationAfterBoneListChanged(false);
			}
		}
	}

	/**
	 * Remove a Bone instance from this Armature instance.
	 * @param The name of the Bone instance to remove.
	 * @see dragonBones.Bone
	 */
	public function removeBoneByName(boneName:String):Bone
	{
		var bone:Bone = getBone(boneName);
		if(bone)
		{
			removeBone(bone);
		}
		return bone;
	}

	/** @private */
	private function addBoneToBoneList(bone:Bone):Void
	{
		if(_boneList.indexOf(bone) < 0)
		{
			_boneList.fixed = false;
			_boneList[_boneList.length] = bone;
			_boneList.fixed = true;
		}
	}

	/** @private */
	private function removeBoneFromBoneList(bone:Bone):Void
	{
		var index:Int = _boneList.indexOf(bone);
		if(index >= 0)
		{
			_boneList.fixed = false;
			_boneList.splice(index, 1);
			_boneList.fixed = true;
		}
	}

	/** @private */
	private function addSlotToSlotList(slot:Slot):Void
	{
		if(_slotList.indexOf(slot) < 0)
		{
			_slotList.fixed = false;
			_slotList[_slotList.length] = slot;
			_slotList.fixed = true;
		}
	}

	/** @private */
	private function removeSlotFromSlotList(slot:Slot):Void
	{
		var index:Int = _slotList.indexOf(slot);
		if(index >= 0)
		{
			_slotList.fixed = false;
			_slotList.splice(index, 1);
			_slotList.fixed = true;
		}
	}

	/**
	 * Sort all slots based on zOrder
	 */
	public function updateSlotsZOrder():Void
	{
		_slotList.fixed = false;
		_slotList.sort(sortSlot);
		_slotList.fixed = true;
		var i:Int = _slotList.length;
		while(i --)
		{
			var slot:Slot = _slotList[i];
			if(slot._isShowDisplay)
			{
				//_display 实际上是container, 这个方法就是把原来的显示对象放到container中的第一个
				slot.addDisplayToContainer(_display);
			}
		}
		
		_slotsZOrderChanged = false;
	}

	private function updateAnimationAfterBoneListChanged(ifNeedSortBoneList:Bool = true):Void
	{
		if(ifNeedSortBoneList)
		{
			sortBoneList();
		}
		_animation.updateAnimationStates();
	}

	private function sortBoneList():Void
	{
		var i:Int = _boneList.length;
		if(i == 0)
		{
			return;
		}
		var helpArray:Array = [];
		while(i --)
		{
			var level:Int = 0;
			var bone:Bone = _boneList[i];
			var boneParent:Bone = bone;
			while(boneParent)
			{
				level ++;
				boneParent = boneParent.parent;
			}
			helpArray[i] = [level, bone];
		}
		
		helpArray.sortOn("0", Array.NUMERIC|Array.DESCENDING);
		
		i = helpArray.length;
		
		_boneList.fixed = false;
		while(i --)
		{
			_boneList[i] = helpArray[i][1];
		}
		_boneList.fixed = true;
		
		helpArray.length = 0;
	}

	/** @private When AnimationState enter a key frame, call this func*/
	private function arriveAtFrame(frame:Frame, timelineState:TimelineState, animationState:AnimationState, isCross:Bool):Void
	{
		if(frame.event && this.hasEventListener(FrameEvent.ANIMATION_FRAME_EVENT))
		{
			var frameEvent:FrameEvent = new FrameEvent(FrameEvent.ANIMATION_FRAME_EVENT);
			frameEvent.animationState = animationState;
			frameEvent.frameLabel = frame.event;
			_eventList.push(frameEvent);
		}
		
		if(frame.sound && _soundManager.hasEventListener(SoundEvent.SOUND))
		{
			var soundEvent:SoundEvent = new SoundEvent(SoundEvent.SOUND);
			soundEvent.armature = this;
			soundEvent.animationState = animationState;
			soundEvent.sound = frame.sound;
			_soundManager.dispatchEvent(soundEvent);
		}
		
		//[TODO]currently there is only gotoAndPlay belongs to frame action. In future, there will be more.  
		//后续会扩展更多的action，目前只有gotoAndPlay的含义
		if(frame.action)
		{
			if(animationState.displayControl)
			{
				animation.gotoAndPlay(frame.action);
			}
		}
	}

	private function sortSlot(slot1:Slot, slot2:Slot):Int
	{
		return slot1.zOrder < slot2.zOrder?1: -1;
	}

	public function addSkinList(skinName:String, list:Object):Void
	{
		if (!skinName)
		{
			skinName = "default";
		}
		if (!_skinLists[skinName])
		{
			_skinLists[skinName] = list;
		}
	}

	public function changeSkin(skinName:String):Void
	{
		var skinData:SkinData = armatureData.getSkinData(skinName);
		if(!skinData || !_skinLists[skinName])
		{
			return;
		}
		armatureData.setSkinData(skinName);
		var displayList:Array = [];
		var slotDataList:Array<SlotData> = armatureData.slotDataList;
		var slotData:SlotData;
		var slot:Slot;
		var bone:Bone;
		for(var i:Int = 0; i < slotDataList.length; i++)
		{
		
			slotData = slotDataList[i];
			displayList = _skinLists[skinName][slotData.name];
			bone = getBone(slotData.parent);
			if(!bone || !displayList)
			{
				continue;
			}
			
			slot = getSlot(slotData.name);
			slot.initWithSlotData(slotData);
			
			slot.displayList = displayList;
			slot.changeDisplay(0);
		}
	}

	public function getIKs(returnCopy:Bool = true):Array<IKConstraint>
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
			_ikList.push(new IKConstraint(ikConstraintData, this));
		}
		_ikList.fixed = true;
	}

	public function updateBoneCache():Void
	{
		_boneList.reverse();
		var temp:Object = { };
		var ikConstraintsCount:Int = _ikList.length;
		var arrayCount:Int = ikConstraintsCount + 1;
		var i:Int;
		var len:Int;
		var j:Int;
		var jLen:Int;
		var bone:Bone;
		var currentBone:Bone;
		
		_boneIKList = new Array<Array<Bone>>();
		while (_boneIKList.length < arrayCount)
		{
			_boneIKList[_boneIKList.length] = new Array();
		}
		
		temp[_boneList[0].name] = 0;
		for (i = 0, len = _ikList.length; i < len; i++) 
		{
			temp[_ikList[i].bones[0].name] = i+1;
		}
		next:
		for (i = 0, len = _boneList.length; i < len; i++)
		{
		
			bone = _boneList[i];
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

	public function getIKTargetData(bone:Bone):Array
	{
		var target:Array = [];
		var ik:IKConstraint; 
		for (var i:Int = 0, len:Int = _ikList.length; i < len; i++)
		{
			ik = _ikList[i];
			if(bone.name == ik.target.name){
				target.push(ik);
			}
		}
		return target;
	}

	public function getAnimation():Object
	{
		return _animation;
	}
}