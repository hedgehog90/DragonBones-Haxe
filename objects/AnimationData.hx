package dragonbones.objects;

class AnimationData extends Timeline
{
	
	public var name:String;
	public var frameRate:UInt;
	public var fadeTime:Float;
	public var playTimes:Int;
	//use frame tweenEase, NaN
	//overwrite frame tweenEase, [-1, 0):ease in, 0:line easing, (0, 1]:ease out, (1, 2]:ease in out
	public var tweenEasing:Float;
	public var autoTween:Bool;
	public var lastFrameDuration:Int;

	public var hideTimelineNameMap:Array<String>;
	public var hideSlotTimelineNameMap:Array<String>;

	private var _timelineList:Array<TransformTimeline>;
	public var timelineList(getTimelineList, null):Array;
	private function getTimelineList():Array<TransformTimeline>
	{
		return _timelineList;
	}

	private var _slotTimelineList:Array<SlotTimeline>;
	public var slotTimelineList(getSlotTimelineList, null):Array;
	private function getSlotTimelineList():Array<SlotTimeline>
	{
		return _slotTimelineList;
	}

	private var _ffdTimelineList:Array<FFDTimeline>;
	public var ffdTimelineList(getFfdTimelineList, null):Array;
	private function getFfdTimelineList():Array<FFDTimeline>
	{
		return _ffdTimelineList;
	}

	public function new()
	{
		super();
		fadeTime = 0;
		playTimes = 0;
		autoTween = true;
		tweenEasing = NaN;
		hideTimelineNameMap = new Array<String>;
		hideTimelineNameMap.fixed = true;
		hideSlotTimelineNameMap = new Array<String>;
		hideSlotTimelineNameMap.fixed = true;
		
		_timelineList = new Array<TransformTimeline>;
		_timelineList.fixed = true;
		_slotTimelineList = new Array<SlotTimeline>;
		_slotTimelineList.fixed = true;
		_ffdTimelineList = new Array();
		_ffdTimelineList.fixed = true;
	}

	override public function dispose():Void
	{
		super.dispose();
		
		hideTimelineNameMap.fixed = false;
		hideTimelineNameMap.length = 0;
		hideTimelineNameMap = null;
		
		_timelineList.fixed = false;
		for each(var timeline:TransformTimeline in _timelineList)
		{
			timeline.dispose();
		}
		_timelineList.fixed = false;
		_timelineList.length = 0;
		_timelineList = null;
		
		_slotTimelineList.fixed = false;
		for each(var slotTimeline:SlotTimeline in _slotTimelineList)
		{
			slotTimeline.dispose();
		}
		_slotTimelineList.fixed = false;
		_slotTimelineList.length = 0;
		_slotTimelineList = null;
	}

	public function getTimeline(timelineName:String):TransformTimeline
	{
		var i:Int = _timelineList.length;
		while(i --)
		{
			if(_timelineList[i].name == timelineName)
			{
				return _timelineList[i];
			}
		}
		return null;
	}

	public function addTimeline(timeline:TransformTimeline):Void
	{
		if(!timeline)
		{
			throw new ArgumentError();
		}
		
		if(_timelineList.indexOf(timeline) < 0)
		{
			_timelineList.fixed = false;
			_timelineList[_timelineList.length] = timeline;
			_timelineList.fixed = true;
		}
	}

	public function getSlotTimeline(timelineName:String):SlotTimeline
	{
		var i:Int = _slotTimelineList.length;
		while(i --)
		{
			if(_slotTimelineList[i].name == timelineName)
			{
				return _slotTimelineList[i];
			}
		}
		return null;
	}

	public function addSlotTimeline(timeline:SlotTimeline):Void
	{
		if(!timeline)
		{
			throw new ArgumentError();
		}
		
		if(_slotTimelineList.indexOf(timeline) < 0)
		{
			_slotTimelineList.fixed = false;
			_slotTimelineList[_slotTimelineList.length] = timeline;
			_slotTimelineList.fixed = true;
		}
	}

	public function getFFDTimeline(timelineName:String):FFDTimeline
	{
		var i:Int = _ffdTimelineList.length;
		while(i --)
		{
			if(_ffdTimelineList[i].name == timelineName)
		{
			return _ffdTimelineList[i];
		}
		}
		return null;
	}

	public function addFFDTimeline(timeline:FFDTimeline):Void
	{
		if(!timeline)
		{
			throw new ArgumentError();
		}
		
		if(_ffdTimelineList.indexOf(timeline) < 0)
		{
		_ffdTimelineList.fixed = false;
		_ffdTimelineList[_ffdTimelineList.length] = timeline;
		_ffdTimelineList.fixed = true;
		}
	}
	
}