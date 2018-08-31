package dragonbones.factories;

/**
* Copyright 2012-2013. DragonBones. All Rights Reserved.
* @playerversion Flash 10.0, Flash 10
* @langversion 3.0
* @version 2.0
*/
import dragonBones.Armature;
import dragonBones.core.dragonBones_internal;
import dragonBones.display.mesh.MeshArmature;
import dragonBones.display.mesh.MeshImage;
import dragonBones.display.mesh.MeshQuadImage;
import dragonBones.display.StarlingFastSlot;
import dragonBones.display.StarlingSlot;
import dragonBones.fast.FastArmature;
import dragonBones.fast.FastSlot;
import dragonBones.objects.ArmatureData;
import dragonBones.objects.DragonBonesData;
import dragonBones.objects.MeshData;
import dragonBones.Slot;
import dragonBones.textures.ITextureAtlas;
import dragonBones.textures.StarlingTextureAtlas;

import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.geom.Rectangle;

import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.SubTexture;
import starling.textures.Texture;
import starling.textures.TextureAtlas;



/**
 * A object managing the set of armature resources for Starling engine. It parses the raw data, stores the armature resources and creates armature instances.
 * @see dragonBones.Armature
 */

/**
 * A StarlingFactory instance manages the set of armature resources for the starling DisplayList. It parses the raw data (ByteArray), stores the armature resources and creates armature instances.
 * <p>Create an instance of the StarlingFactory class that way:</p>
 * <listing>
 * import flash.events.Event; 
 * import dragonBones.factorys.BaseFactory;
 * 
 * [Embed(source = "../assets/Dragon2.png", mimeType = "application/octet-stream")]  
 *	private static inline var ResourcesData:Class;
 * var factory:StarlingFactory = new StarlingFactory(); 
 * factory.addEventListener(Event.COMPLETE, textureCompleteHandler);
 * factory.parseData(new ResourcesData());
 * </listing>
 * @see dragonBones.Armature
 */
import flash.Vector;

import flash.Error;

class StarlingFactory extends BaseFactory
{
/**
 * whether to use mesh
 */
public var useMesh:Bool;
/**
 * Whether to generate mapmaps (true) or not (false).
 */
public var generateMipMaps:Bool;
/**
 * Whether to optimize for rendering (true) or not (false).
 */
public var optimizeForRenderToTexture:Bool;
/**
 * Apply a scale for SWF specific texture. Use 1 for no scale.
 */
public var scaleForTexture:Float;

/**
 * Creates a new StarlingFactory instance.
 */
public function new()
{
	super(this);
	scaleForTexture = 1;
}

/** @private */
override private function generateTextureAtlas(content:Object, textureAtlasRawData:Object):ITextureAtlas
{
	var texture:Texture;
	var bitmapData:BitmapData;
	if (content is BitmapData)
	{
	bitmapData = content as BitmapData;
	texture = Texture.fromBitmapData(bitmapData, generateMipMaps, optimizeForRenderToTexture);
	}
	else if (content is MovieClip)
	{
	var width:Int = getNearest2N(content.width) * scaleForTexture;
	var height:Int = getNearest2N(content.height) * scaleForTexture;
	
//		_helpMatrix.a = 1;
//		_helpMatrix.b = 0;
//		_helpMatrix.c = 0;
//		_helpMatrix.d = 1;
	_helpMatrix.scale(scaleForTexture, scaleForTexture);
	_helpMatrix.tx = 0;
	_helpMatrix.ty = 0;		
	var movieClip:MovieClip = content as MovieClip;
	movieClip.gotoAndStop(1);
	bitmapData = new BitmapData(width, height, true, 0xFF00FF);
	bitmapData.draw(movieClip, _helpMatrix);
	movieClip.gotoAndStop(movieClip.totalFrames);
	texture = Texture.fromBitmapData(bitmapData, generateMipMaps, optimizeForRenderToTexture, scaleForTexture);
	}
	else
	{
	throw new Error();
	}		
	var textureAtlas:StarlingTextureAtlas = new StarlingTextureAtlas(texture, textureAtlasRawData, false);		
	if (Starling.handleLostContext)
	{
	textureAtlas._bitmapData = bitmapData;
	}
	else
	{
	bitmapData.dispose();
	}
	return textureAtlas;
}

/** @private */
override private function generateArmature():Armature
{
	var armature:Armature
	if (useMesh)
	{
	armature = new Armature(new MeshArmature());
	}
	else
	{
	armature = new Armature(new Sprite());
	}
	
	return armature;
}

/** @private */
override private function generateFastArmature():FastArmature
{
	var armature:FastArmature;
	if (useMesh)
	{
	armature = new FastArmature(new MeshArmature());
	}
	else
	{
	armature = new FastArmature(new Sprite());
	}
	return armature;
}

/** @private */
override private function generateSlot():Slot
{
	var slot:Slot = new StarlingSlot();
	return slot;
}

/**
 * @private
 * Generates an Slot instance.
 * @return Slot An Slot instance.
 */
override private function generateFastSlot():FastSlot
{
	var slot:FastSlot = new StarlingFastSlot();
	return slot;
}

/** @private */
override private function generateDisplay(textureAtlas:Object, fullName:String, pivotX:Float, pivotY:Float):Object
{		
	var subTexture:SubTexture = (textureAtlas as TextureAtlas).getTexture(fullName) as SubTexture;
	if (subTexture)
	{
	var image:DisplayObject;
	if (useMesh)
	{
		image = new MeshQuadImage(subTexture);
	}
	else
	{
		image = new Image(subTexture);
	}
	
	if (isNaN(pivotX) || isNaN(pivotY))
	{
		var subTextureFrame:Rectangle = (textureAtlas as TextureAtlas).getFrame(fullName);
		if(subTextureFrame)
		{
		pivotX = subTextureFrame.width / 2;//pivotX;
		pivotY = subTextureFrame.height / 2;// pivotY;
		}
		else
		{
		pivotX = subTexture.width / 2;//pivotX;
		pivotY = subTexture.height / 2;// pivotY;
		}
		
	}
	image.pivotX = pivotX;
	image.pivotY = pivotY;
	
	return image;
	}
	return null;
}

private function getNearest2N(_n:UInt):UInt
{
	return _n & _n - 1?1 << _n.toString(2).length:_n;
}

override private function generateMesh(textureAtlas:Object, fullName:String, meshData:MeshData):Object 
{
	var subTexture:SubTexture = (textureAtlas as TextureAtlas).getTexture(fullName) as SubTexture;
	if (subTexture)
	{
	var image:MeshImage = new MeshImage(subTexture,meshData);
	return image;
	}
	return null;
}

override private function buildArmatureUsingArmatureDataFromTextureAtlas(dragonBonesData:DragonBonesData, armatureData:ArmatureData, textureAtlasName:String, skinName:String = null):Armature
{
	var outputArmature:Armature = super.buildArmatureUsingArmatureDataFromTextureAtlas(dragonBonesData, armatureData, textureAtlasName, skinName);
	
	//计算mesh相对于其控制骨骼的相对matrix；此时是骨架状态
	var slots:Vector<Slot> = outputArmature.getSlots(false);
	var meshes:Vector<MeshData>;
	
	for (var i:Int = 0, len:Int = slots.length; i < len; i++)
	{
	meshes = slots[i].getSkinnedMeshData();
	if (meshes && meshes.length > 0)
	{
		for (var j:Int = 0, jLen:Int = meshes.length; j < jLen; j++)
		{
		meshes[j].rig(outputArmature, slots[i]);
		}
	}
	}
	return outputArmature;
}
}