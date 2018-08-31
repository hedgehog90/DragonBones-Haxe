package dragonbones.textures;

/**
* Copyright 2012-2013. DragonBones. All Rights Reserved.
* @playerversion Flash 10.0, Flash 10
* @langversion 3.0
* @version 2.0
*/
import flash.display.BitmapData;

import dragonBones.core.dragonBones_internal;
import dragonBones.objects.DataParser;

import starling.textures.SubTexture;
import starling.textures.Texture;
import starling.textures.TextureAtlas;
/**
 * The StarlingTextureAtlas creates and manipulates TextureAtlas from starling.display.DisplayObject.
 */
class StarlingTextureAtlas extends TextureAtlas implements ITextureAtlas
{
private var _bitmapData:BitmapData;
/**
 * @private
 */
private var _subTextureDic:Object;
/**
 * @private
 */
private var _isDifferentConfig:Bool;	
/**
 * @private
 */
private var _scale:Float;
/**
 * @private
 */
private var _name:String;
/**
 * The name of this StarlingTextureAtlas instance.
 */
public var name(getName, null):String;
 	private function getName():String
{
	return _name;
}
/**
 * Creates a new StarlingTextureAtlas instance.
 * @param texture A texture instance.
 * @param textureAtlasRawData A textureAtlas config data
 * @param isDifferentXML
 */
public function new(texture:Texture, textureAtlasRawData:Object, isDifferentConfig:Bool = false)
{
	super(texture, null);
	if (texture)
	{
	_scale = texture.scale;
	_isDifferentConfig = isDifferentConfig;
	}
	_subTextureDic = {};
	parseData(textureAtlasRawData);
}
/**
 * Clean up all resources used by this StarlingTextureAtlas instance.
 */
override public function dispose():Void
{
	super.dispose();		
	for each (var subTexture:SubTexture in _subTextureDic)
	{
	subTexture.dispose();
	}		
	_subTextureDic = null;
	
	if (_bitmapData)
	{
	_bitmapData.dispose();
	}
	_bitmapData = null;
}

/**
 * Get the Texture with that name.
 * @param name The name ofthe Texture instance.
 * @return The Texture instance.
 */
override public function getTexture(name:String):Texture
{
	var texture:Texture = _subTextureDic[name];
	if (!texture)
	{
	texture = super.getTexture(name);
	if (texture)
	{
		_subTextureDic[name] = texture;
	}
	}
	return texture;
}
/**
 * @private
 */
private function parseData(textureAtlasRawData:Object):Void
{
	var textureAtlasData:Object = DataParser.parseTextureAtlasData(textureAtlasRawData, _isDifferentConfig ? _scale : 1);
	_name = textureAtlasData.__name;
	delete textureAtlasData.__name;
	for(var subTextureName:String in textureAtlasData)
	{
	var textureData:TextureData = textureAtlasData[subTextureName];
	//, textureData.rotated
	this.addRegion(subTextureName, textureData.region, textureData.frame);
	}
}
}