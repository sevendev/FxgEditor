package fxgeditor.parser.style 
{
	import flash.display.DisplayObject;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import fxgeditor.parser.utils.GeomUtil;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.Constants;
	
	public class Transform
	{
		
		public var type:String;
		private var vals:Array;
		private var _matrix:Matrix;
		private var _colorTransform:ColorTransform;
		
		public function Transform( xml:XML = null ) 
		{
			if( xml != null ) parse( xml );
		}
		
		public function parse( xml:XML ):void 
		{
			var fxg:Namespace = Constants.fxg;
			if ( xml..fxg::Matrix.length() )
			{
				var m:XML = xml..fxg::Matrix[0];
				_matrix = new Matrix();
				StyleUtil.validateMatrix( m, _matrix );
			}
			
			if ( xml..fxg::ColorTransform.length() )
			{
				var ct:XML = xml..fxg::ColorTransform[0];
				_colorTransform = new ColorTransform();
				_colorTransform.redMultiplier = StyleUtil.validateAttr( ct.@redMultiplier, _colorTransform.redMultiplier);
				_colorTransform.greenMultiplier = StyleUtil.validateAttr(ct.@greenMultiplier,_colorTransform.greenMultiplier);
				_colorTransform.blueMultiplier = StyleUtil.validateAttr(ct.@blueMultiplier,_colorTransform.blueMultiplier);
				_colorTransform.alphaMultiplier = StyleUtil.validateAttr(ct.@alphaMultiplier, _colorTransform.alphaMultiplier);
				_colorTransform.redOffset = StyleUtil.validateAttr(ct.@redOffset,_colorTransform.redOffset);
				_colorTransform.greenOffset = StyleUtil.validateAttr(ct.@greenOffset,_colorTransform.greenOffset);
				_colorTransform.blueOffset = StyleUtil.validateAttr(ct.@blueOffset,_colorTransform.blueOffset);
				_colorTransform.alphaOffset = StyleUtil.validateAttr(ct.@alphaOffset, _colorTransform.alphaOffset);
			}
		}
		
		public function setFxgAttr( node:XML ):void 
		{
			if ( hasMatrix ) {
				if ( _matrix.b == 0 && _matrix.c == 0 ) {
					if( _matrix.tx != 0 ) node.@x = _matrix.tx;
					if( _matrix.ty != 0 ) node.@y = _matrix.ty;
					if( _matrix.a != 1 ) node.@scaleX = _matrix.a;
					if( _matrix.d != 1 ) node.@scaleY = _matrix.d;
				}else {
					node.appendChild( <transform><Transform/></transform> );
					node.transform.Transform.appendChild( <matrix><Matrix/></matrix> );
					node.transform.Transform.matrix.Matrix.@a = _matrix.a;
					node.transform.Transform.matrix.Matrix.@b = _matrix.b;
					node.transform.Transform.matrix.Matrix.@c = _matrix.c;
					node.transform.Transform.matrix.Matrix.@d = _matrix.d;
					node.transform.Transform.matrix.Matrix.@tx = _matrix.tx;
					node.transform.Transform.matrix.Matrix.@ty = _matrix.ty;
				}
			}
			if ( hasColorTransform ) {
				if( !node..Transform.length() ) node.appendChild( <transform><Transform/></transform> );
				node.transform.Transform.appendChild( <colorTransform><ColorTransform/></colorTransform> );
				node.transform.Transform.colorTransform.ColorTransform.@redMultiplier = _colorTransform.redMultiplier;
				node.transform.Transform.colorTransform.ColorTransform.@greenMultiplier = _colorTransform.greenMultiplier;
				node.transform.Transform.colorTransform.ColorTransform.@blueMultiplier = _colorTransform.blueMultiplier;
				node.transform.Transform.colorTransform.ColorTransform.@alphaMultiplier = _colorTransform.alphaMultiplier;
				node.transform.Transform.colorTransform.ColorTransform.@redOffset = _colorTransform.redOffset;
				node.transform.Transform.colorTransform.ColorTransform.@greenOffset = _colorTransform.greenOffset;
				node.transform.Transform.colorTransform.ColorTransform.@blueOffset = _colorTransform.blueOffset;
				node.transform.Transform.colorTransform.ColorTransform.@alphaOffset = _colorTransform.alphaOffset;
			}
			
			for each ( var d:XML in node.descendants() )
				d.setNamespace( Constants.fxg.uri );
		}
		public function get hasMatrix():Boolean { return _matrix != null; }
		public function get hasColorTransform():Boolean { return _colorTransform != null; }
		
		public function get matrix():Matrix { return _matrix ? _matrix.clone() : new Matrix(); }
		public function get colorTransform():ColorTransform { return _colorTransform; }
		
		public function set matrix(value:Matrix):void { _matrix = value; }
		public function set colorTransform(value:ColorTransform):void { _colorTransform = value; }
	}

}