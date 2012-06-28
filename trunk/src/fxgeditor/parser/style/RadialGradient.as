package fxgeditor.parser.style
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.style.Style;
	import flash.display.GradientType;
	import flash.display.SpreadMethod;
	import fxgeditor.parser.utils.GeomUtil;
	
	public class RadialGradient extends LinearGradient implements IStyleParser , IGradient
	{
		public static var LOCALNAME:String = "RadialGradient";
		
		public var p3:Point;

		public function RadialGradient() {
			_type = GradientType.RADIAL;
		}
		
		override public function editGradient():void 
		{
			_x = p1.x;
			_y = p1.y;
			_scaleX = GeomUtil.getDistance( p1 , p2 ) * 2;
			_scaleY = GeomUtil.getDistance( p1 , p3 ) * 2;
			_rotation = GeomUtil.radian2degree( GeomUtil.getAngle( p1 , p2 ) );
			createMatrix();
		}
		
		override public function getXML( localName:String = null ):XML
		{
			localName = localName ? localName : LOCALNAME;
			var node:XML = super.getXML(  localName );
			if ( _scaleY != 1 ) node.@scaleY = _scaleY;
			return node;
		}
		
		override protected function createMatrix():void
		{
			_matrix.createGradientBox( _scaleX  , _scaleY );
			_matrix.translate( -_scaleX/2, -_scaleY/2 );
			_matrix.rotate( GeomUtil.degree2radian( _rotation ) );
			_matrix.translate( _x, _y );
			
			if ( !p1 || !p2 || !p3 )
				createEditPoints();
		}
		
		override protected function createEditPoints():void
		{
			p1 = new Point( _x,  _y );
			var m:Matrix = new Matrix()
			m.createGradientBox( _scaleX , 1 );
			m.rotate( GeomUtil.degree2radian( _rotation ) );
			m.translate( _x , _y );
			p2 = m.transformPoint( new Point() );
			var m2:Matrix = new Matrix()
			m2.createGradientBox( 1 , _scaleY);
			m2.rotate( GeomUtil.degree2radian( _rotation ) );
			m2.translate( _x , _y );
			p3 = m2.transformPoint( new Point() );
		}
		
	}

}