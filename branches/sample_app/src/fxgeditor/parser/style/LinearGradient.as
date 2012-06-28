package fxgeditor.parser.style
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.display.GradientType;
	import flash.display.SpreadMethod;
	import fxgeditor.parser.style.IGradient;
	import fxgeditor.parser.style.ColorType;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.parser.utils.GeomUtil;
	import fxgeditor.parser.style.ColorType;
	import fxgeditor.Constants;
	
	public class LinearGradient implements IStyleParser , IGradient
	{
		public static var LOCALNAME:String = "LinearGradient";
		
		public var id:String;
		
		public var p1:Point;
		public var p2:Point;
		
		protected var _type:String = GradientType.LINEAR;
		protected var _colors:Array = [];
		protected var _alphas:Array = [];
		protected var _ratios:Array = [];
		protected var _matrix:Matrix = new Matrix();
		protected var _method:String = SpreadMethod.PAD;
		
		protected var _x:Number;
		protected var _y:Number;
		protected var _scaleX:Number;
		protected var _scaleY:Number;
		protected var _rotation:Number;
				
		public function LinearGradient() { }
		
		public function parse( item:XML ):void 
		{
			_x = StyleUtil.toNumber( item.@x );
			_y = StyleUtil.toNumber( item.@y );
			_scaleX = StyleUtil.toNumber( item.@scaleX );
			_scaleY = item.@scaleY.length() ? StyleUtil.toNumber( item.@scaleY ) : 1;
			_rotation = StyleUtil.toNumber( item.@rotation );
			
			var fxg:Namespace = Constants.fxg;
			
			createMatrix();
			if ( item..fxg::Matrix.length() )
			{
				var m:XML = item..fxg::Matrix[0];
				_matrix = new Matrix();
				StyleUtil.validateMatrix( m, _matrix );
			}
			
			var stops:XMLList = item.fxg::GradientEntry;
			for each( var stop:XML in stops ) 
				parseStop( stop );
		}
		
		public function getXML( localName:String = null ):XML
		{
			localName = localName ? localName : LOCALNAME;
			var fxg:Namespace = Constants.fxg;
			var node:XML = <{localName} />;
			node.setNamespace( fxg.uri );
			node.@x = _x;
			node.@y = _y;
			node.@scaleX = _scaleX;
			if ( _rotation != 0 ) node.@rotation = _rotation;
			//if ( _scaleY != 1 ) node.@scaleY = _scaleY;
				
			var length:int = _colors.length;
			for (var i:int = 0; i < length ; i++ ) {
				var entry:XML = <GradientEntry />; 
				entry.setNamespace( fxg.uri );
				entry.@color = StyleUtil.fromColor( _colors[i] );
				entry.@ratio = StyleUtil.fromNumber( _ratios[i] / 255 ) ;
				if ( _alphas[i] != 1 )
					entry.@alpha = StyleUtil.fromNumber( _alphas[i] );
				node.appendChild( entry );
			}
			return node;
		}
		
		public function setSize( rect:Rectangle ):void
		{
			if ( _scaleX == 0 || isNaN( _scaleX ) || _scaleY == 0 || isNaN( _scaleY ) )
			{
				_x = rect.x;
				_y = rect.y;
				_scaleX = rect.width;
				_scaleY = rect.height;
				_rotation = 0;
				createMatrix();
			}
		}
		
		public function editGradient():void 
		{
			_x = p1.x;
			_y = p1.y;
			_scaleX = _scaleY = GeomUtil.getDistance( p1 , p2 );
			_rotation = GeomUtil.radian2degree( GeomUtil.getAngle( p1 , p2 ) );
			createMatrix();
		}
		
		public function newPrimitive():void  
		{ 
			_colors = [0x000000, 0xffffff ];
			_alphas = [ 1 , 1 ];
			_ratios = [ 0 , 255 ];
		}
		public function copy():IStyleParser
		{
			var g:IGradient = ( type == GradientType.LINEAR ) ? new LinearGradient() :  new RadialGradient();
			return duplicateGradient( g ) as IStyleParser;
		}
		
		public function convert():IGradient 
		{
			var g:IGradient = ( type == GradientType.LINEAR )  ? new RadialGradient() : new LinearGradient();
			return duplicateGradient( g );
		}
		
		public function toStroke( stroke:IStroke  = null ):IStroke
		{
			var g:IGradient = ( type == GradientType.LINEAR ) ? new LinearGradientStroke() :  new RadialGradientStroke();
			g = duplicateGradient( g );
			var st:IStroke = g as IStroke;
			st.setStroke( stroke );
			return st;
		}
		
		protected function createMatrix():void
		{
			_matrix.createGradientBox( _scaleX , _scaleY );
			_matrix.rotate( GeomUtil.degree2radian( _rotation ) );
			_matrix.translate( _x , _y );
			
			if( !p1 || !p2 )
				createEditPoints();
		}
		
		protected function createEditPoints():void
		{
			p1 = new Point( _x,  _y );
			var m:Matrix = new Matrix()
			m.createGradientBox( _scaleX * 2 , _scaleY );
			m.rotate( GeomUtil.degree2radian( _rotation ) );
			m.translate( _x , _y );
			p2 = m.transformPoint( new Point() );
		}
		
		protected function parseStop( stop:XML ):void 
		{
			_colors.push( StyleUtil.toColor( stop.@color ));
			_alphas.push( stop.@alpha.length() ? StyleUtil.toNumber( stop.@alpha ) : 1.0 );
			_ratios.push( StyleUtil.toNumber( stop.@ratio ) * 255 );
		}
		
		protected function duplicateGradient( g:IGradient ):IGradient
		{
			g.newPrimitive();
			g.colors = colors;
			g.alphas = alphas;
			g.ratios = ratios;
			g.matrix = matrix;
			return g;
		}
		
		public function get colorType():int { return ColorType.GRADIENT; }
		public function get type():String { return _type; }
		public function get method():String { return _method; }
		
		public function get colors():Array { return _colors.concat(); }
		public function get alphas():Array { return _alphas.concat(); }
		public function get ratios():Array { return _ratios.concat(); }
		public function get matrix():Matrix { return _matrix.clone(); }
		
		public function set colors(value:Array):void { _colors = value.concat(); }
		public function set alphas(value:Array):void { _alphas = value.concat(); }
		public function set ratios(value:Array):void { _ratios = value.concat(); }
		public function set matrix(value:Matrix):void { _matrix = value.clone(); }
		
	}
}