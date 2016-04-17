package openfl.geom;


class DBPoint {
	
	public var length (get, null):Float;
	public var x:Float;
	public var y:Float;
	
	
	public function new (x:Float = 0, y:Float = 0) {
		
		this.x = x;
		this.y = y;
		
	}
	
	public function add (v:DBPoint):DBPoint {
		
		return new DBPoint (v.x + x, v.y + y);
		
	}
	
	public function clone ():DBPoint {
		
		return new DBPoint (x, y);
		
	}
	
	public function copyFrom (sourcePoint:DBPoint):Void {
		
		x = sourcePoint.x;
		y = sourcePoint.y;
		
	}
	
	public static function distance (pt1:DBPoint, pt2:DBPoint):Float {
		
		var dx = pt1.x - pt2.x;
		var dy = pt1.y - pt2.y;
		return Math.sqrt (dx * dx + dy * dy);
		
	}
	
	public function equals (toCompare:DBPoint):Bool {
		
		return toCompare != null && toCompare.x == x && toCompare.y == y;
		
	}
	
	public static function interpolate (pt1:DBPoint, pt2:DBPoint, f:Float):DBPoint {
		
		return new DBPoint (pt2.x + f * (pt1.x - pt2.x), pt2.y + f * (pt1.y - pt2.y));
		
	}
	
	public function normalize (thickness:Float):Void {
		
		if (x == 0 && y == 0) {
			
			return;
			
		} else {
			
			var norm = thickness / Math.sqrt (x * x + y * y);
			x *= norm;
			y *= norm;
			
		}
		
	}
	
	public function offset (dx:Float, dy:Float):Void {
		
		x += dx;
		y += dy;
		
	}
	
	public static function polar (len:Float, angle:Float):DBPoint {
		
		return new DBPoint (len * Math.cos (angle), len * Math.sin (angle));
		
	}
	
	public function setTo (xa:Float, ya:Float):Void {
		
		x = xa;
		y = ya;
	}
	
	public function subtract (v:DBPoint):DBPoint {
		
		return new DBPoint (x - v.x, y - v.y);
		
	}
	
	public function toString ():String {
		
		return '(x=$x, y=$y)';
		
	}
	
	// Getters & Setters
	private function get_length ():Float {
		
		return Math.sqrt (x * x + y * y);
		
	}
	
}