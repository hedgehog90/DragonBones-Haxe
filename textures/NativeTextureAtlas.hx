package dragonbones.textures;

/**
* Copyright 2012-2013. DragonBones. All Rights Reserved.
* @playerversion Flash 10.0, Flash 10
* @langversion 3.0
* @version 2.0
*/
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.geom.Rectangle;

import dragonBones.core.dragonBones_internal;
import dragonBones.objects.DataParser;

/**
 * The NativeTextureAtlas creates and manipulates TextureAtlas from traditional flash.display.DisplayObject.
 */
class NativeTextureAtlas implements ITextureAtlas
{
/**
 * @private
 */
private var _subTextureDataDic:Object;
/**
 * @private
 */
private var _isDifferentConfig:Bool;
/**
 * @private
 */
private var _name:String;
/**
 * The name of this NativeTextureAtlas instance.
 */
public var name(getName, null):String;
 	private function getName():String
{
	return _name;
}

private var _movieClip:MovieClip;
/**
 * The MovieClip created by this NativeTextureAtlas instance.
 */
public var movieClip(getMovieClip, null):MovieClip;
 	private function getMovieClip():MovieClip
{
	return _movieClip;
}

private var _bitmapData:BitmapData;
/**
 * The BitmapData created by this NativeTextureAtlas instance.
 */
public var bitmapData(getBitmapData, null):BitmapData;
 	private function getBitmapData():BitmapData
{
	return _bitmapData;
}

private var _scale:Float;
/** 
 * @private
 */
public var scale(getScale, null):Float;
 	private function getScale():Float
{
	return _scale;
}
/**
 * Creates a new NativeTextureAtlas instance. 
 * @param texture A MovieClip or Bitmap.
 * @param textureAtlasRawData The textureAtlas config data.
 * @param textureScale A scale value (x and y axis)
 * @param isDifferentConfig 
 */
public function new(texture:Object, textureAtlasRawData:Object, textureScale:Float = 1, isDifferentConfig:Bool = false)
{
	_scale = textureScale;
	_isDifferentConfig = isDifferentConfig;
	if (texture is BitmapData)
	{
	_bitmapData = texture as BitmapData;
	}
	else if (texture is MovieClip)
	{
	_movieClip = texture as MovieClip;
	_movieClip.stop();
	}
	parseData(textureAtlasRawData);
}
/**
 * Clean up all resources used by this NativeTextureAtlas instance.
 */
public function dispose():Void
{
	_movieClip = null;
	if (_bitmapData)
	{
	_bitmapData.dispose();
	}
	_bitmapData = null;
}
/**
 * The area occupied by all assets related to that name.
 * @param name The name of these assets.
 * @return Rectangle The area occupied by all assets related to that name.
 */
public function getRegion(name:String):Rectangle
{
	var textureData:TextureData = _subTextureDataDic[name] as TextureData;
	if(textureData)
	{
	return textureData.region;
	}
	
	return null;
}

public function getFrame(name:String):Rectangle
{
	var textureData:TextureData = _subTextureDataDic[name] as TextureData;
	if(textureData)
	{
	return textureData.frame;
	}
	
	return null;
}

private function parseData(textureAtlasRawData:Object):Void
{
	_subTextureDataDic = DataParser.parseTextureAtlasData(textureAtlasRawData, _isDifferentConfig ? _scale : 1);
	_name = _subTextureDataDic.__name;
	
	delete _subTextureDataDic.__name;
}

private function movieClipToBitmapData():Void
{
	if (!_bitmapData && _movieClip)
	{
	_movieClip.gotoAndStop(1);
	_bitmapData = new BitmapData(getNearest2N(_movieClip.width), getNearest2N(_movieClip.height), true, 0xFF00FF);
	_bitmapData.draw(_movieClip);
	_movieClip.gotoAndStop(_movieClip.totalFrames);
	}
}

private function getNearest2N(_n:UInt):UInt
{
	return _n & _n - 1?1 << _n.toString(2).length:_n;
}
}