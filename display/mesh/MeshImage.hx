package dragonbones.display.mesh;

import dragonBones.display.mesh.Mesh;
import dragonBones.display.mesh.MeshBatch;
import dragonBones.objects.MeshData;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import starling.core.RenderSupport;
import starling.textures.Texture;
import starling.textures.TextureSmoothing;
import starling.utils.VertexData;
/**
 * ...
 * @author sukui
 */
class MeshImage extends Mesh
{
public static var meshBatch:MeshBatch;

private var mTexture:Texture;
private var mSmoothing:String;

private var mVertexDataCache:VertexData;
private var mVertexDataCacheInvalid:Bool;
private var mNumVertex:Int;

public function new(texture:Texture,meshData:MeshData, color:UInt=0xffffff)
{
	if (texture)
	{
	var pma:Bool = texture.premultipliedAlpha;
	
	mTexture = texture;
	mSmoothing = TextureSmoothing.BILINEAR;
	
	super(meshData, color, pma);
	
	mNumVertex = meshData.vertices.length/ 4
	mVertexDataCache = new VertexData(mNumVertex, pma);
	mVertexDataCacheInvalid = true;
	}
	else
	{
	throw new ArgumentError("Texture cannot be null");
	}
	
	if (meshBatch == null)
	{
	meshBatch = new MeshBatch();
	}
}

override private function onVertexDataChanged():Void 
{
	mVertexDataCacheInvalid = true;
}
/** The texture that is displayed on the quad. */
public var texture(getTexture, setTexture):Texture;
 	private function getTexture():Texture { return mTexture; }
private function setTexture(value:Texture):Void 
{ 
	if (value == null)
	{
	throw new ArgumentError("Texture cannot be null");
	}
	else if (value != mTexture)
	{
	mTexture = value;
	mVertexData.setPremultipliedAlpha(mTexture.premultipliedAlpha);
	onVertexDataChanged();
	}
}

/** The smoothing filter that is used for the texture. 
*   @default bilinear
*   @see starling.textures.TextureSmoothing */ 
public var smoothing(getSmoothing, setSmoothing):String;
 	private function getSmoothing():String { return mSmoothing; }
private function setSmoothing(value:String):Void 
{
	if (TextureSmoothing.isValid(value))
	mSmoothing = value;
	else
	throw new ArgumentError("Invalid smoothing mode: " + value);
}

/** @inheritDoc */
public override function render(support:RenderSupport, parentAlpha:Float):Void
{
	super.render(support, parentAlpha);
	meshBatch.render(this, support, parentAlpha);
}

/** Copies the raw vertex data to a VertexData instance.
 *  The texture coordinates are already in the format required for rendering. */ 
public override function copyVertexDataTo(targetData:VertexData, targetVertexID:Int=0):Void
{
	copyVertexDataTransformedTo(targetData, targetVertexID, null);
}

/** Transforms the vertex positions of the raw vertex data by a certain matrix
 *  and copies the result to another VertexData instance.
 *  The texture coordinates are already in the format required for rendering. */
public override function copyVertexDataTransformedTo(targetData:VertexData,
							 targetVertexID:Int=0,
							 matrix:Matrix=null):Void
{
	if (mVertexDataCacheInvalid)
	{
	mVertexDataCacheInvalid = false;
	mVertexData.copyTo(mVertexDataCache);
	mTexture.adjustVertexData(mVertexDataCache, 0, mNumVertex);
	}
	
	mVertexDataCache.copyTransformedTo(targetData, targetVertexID, matrix, 0, mNumVertex);
}
}