package dragonbones.textures;

import flash.geom.Rectangle;

public final class TextureData
{
public var region:Rectangle;
public var frame:Rectangle;
public var rotated:Bool;

public function TextureData(region:Rectangle, frame:Rectangle, rotated:Bool)
{
	this.region = region;
	this.frame = frame;
	this.rotated = rotated;
}
}