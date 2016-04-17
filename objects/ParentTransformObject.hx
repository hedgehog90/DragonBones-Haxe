package dragonbones.objects;

 	import flash.geom.Matrix;
 	
 	/**
 * optimized by freem-trg
 	 * Intermediate class for store the results of the parent transformation
 	 */
 	import flash.Vector;

class ParentTransformObject 
 	{
 	
 	public var parentGlobalTransform:DBTransform;
 	public var parentGlobalTransformMatrix:Matrix;
 	
 	/// Object pool to reduce GC load
 	private static var _pool:Vector<ParentTransformObject> = new Vector();
 	private static var _poolSize:Int = 0;
 	
 	public function new() 
 	{
 	}
 	
 	/// Method to set properties after its creation/pooling
	@:final public function setTo(parentGlobalTransform:DBTransform, parentGlobalTransformMatrix:Matrix):ParentTransformObject
 	{
 		this.parentGlobalTransform = parentGlobalTransform;
 		this.parentGlobalTransformMatrix = parentGlobalTransformMatrix;
 		return this
 	}
 	
 	/// Cleanup object and return it to the object pool
 	@:final public inline function release():Void
 	{
 		dispose(this);
 	}
 	
 	/// Create/take new clean object from the object pool
 	public static inline function create():ParentTransformObject
 	{
 		if (_poolSize > 0)
 		{
 		_poolSize--;
 		return _pool.pop();
 		}
 		
 		return new ParentTransformObject();
 	}
 	
 	/// Cleanup object and return it to the object pool
 	public static inline function dispose(parentTransformObject:ParentTransformObject):Void
 	{
 		parentTransformObject.parentGlobalTransform = null;
 		parentTransformObject.parentGlobalTransformMatrix = null;
 		_pool[_poolSize++] = parentTransformObject;
 	}
 	
 	}