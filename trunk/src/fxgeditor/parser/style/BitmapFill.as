package fxgeditor.parser.style 
{
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.EventDispatcher;
	import fxgeditor.parser.utils.GeomUtil;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.Constants;

	public class BitmapFill extends EventDispatcher implements IStyleParser
	{
		public static var LOCALNAME:String = "BitmapFill";
		
		private static const DEFAULT_FILL_MODE:String = "scale";
		
		protected var loader:Loader;
		
		protected var _x:Number=0;
		protected var _y:Number=0;
		protected var _scaleX:Number = 1;
		protected var _scaleY:Number = 1;
		protected var _rotation:Number = 0;
		protected var _fillMode:String = DEFAULT_FILL_MODE;
		protected var _href:String;
		
		protected var _matrix:Matrix = new Matrix();
		protected var _bitmapdata:BitmapData;
		protected var _loading:Boolean;
		
		public function BitmapFill() { }
		
		public function parse( item:XML ):void 
		{
			_x = StyleUtil.validateAttr( item.@x, _x );
			_y = StyleUtil.validateAttr( item.@y, _y );
			_scaleX = StyleUtil.validateAttr( item.@scaleX, _scaleX );
			_scaleY = StyleUtil.validateAttr( item.@scaleY, _scaleY );
			_rotation = StyleUtil.validateAttr( item.@rotation, _rotation );
			_fillMode = StyleUtil.validateAttr( item.@fillMode, _fillMode );
	
			_matrix.scale( _scaleX, _scaleY );
			_matrix.rotate( GeomUtil.degree2radian( _rotation ) );	
			_matrix.translate( _x , _y );	
			
			var fxg:Namespace = Constants.fxg;
			if ( item..fxg::Matrix.length() )
			{
				var m:XML = item..fxg::Matrix[0];
				_matrix = new Matrix();
				StyleUtil.validateMatrix( m, _matrix );
			}

			_href = StyleUtil.toURL( item.@source );
			if ( _href ) loadBitmap( _href );
		}
		
		public function getXML( localName:String = null ):XML
		{
			localName = localName ? localName : LOCALNAME;
			var node:XML = <{localName} />;
			if ( _fillMode != DEFAULT_FILL_MODE ) node.@fillMode = _fillMode;
			if ( _href ) node.@source = StyleUtil.fromURL( _href );
			
			if ( _rotation == 0 && _matrix.b == 0 && _matrix.c == 0 )
			{
				if ( _matrix.tx != 0 ) node.@x = _matrix.tx;
				if ( _matrix.ty != 0 ) node.@y = _matrix.ty;
				if ( _matrix.a != 1 ) node.@scaleX = _matrix.a;
				if ( _matrix.d != 1 ) node.@scaleY = _matrix.d;
				//if ( _rotation != 0 ) node.@rotation = _rotation;
			}else {
				node.appendChild( <matrix><Matrix /></matrix> );
				StyleUtil.setMatrixAttr( node.matrix[0].Matrix[0] , _matrix );
				for each( var d:XML in node.descendants() )
					d.setNamespace( Constants.fxg.uri );
			}
			return node;
		}
		
		public function setSize( rect:Rectangle ):void
		{
			if ( fillMode == "scale" )
			{
				_matrix = new Matrix();
				_matrix.scale( rect.width / _bitmapdata.width  , rect.height / _bitmapdata.height  );
				_matrix.translate( _x , _y );	
			}
		}
		
		public function toStroke( stroke:IStroke = null ):IStroke
		{
			var st:SolidColorStroke = new SolidColorStroke();
			if( stroke.caps ) st.caps = stroke.caps;
			if( stroke.joints ) st.joints = stroke.joints;
			if( stroke.miterLimit ) st.miterLimit = stroke.miterLimit;
			if ( stroke.weight ) st.weight = stroke.weight;
			return st;
		}
		
		protected function loadBitmap( url:String ):void
		{
			_loading = true;
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener( Event.COMPLETE, loadComplete );
			loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, loadError );
			loader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, loadError );
			loader.load( new URLRequest( _href ) );
		}
		
		protected function loadComplete( e:Event ):void 
		{
			_loading = false;
			if ( loader.contentLoaderInfo.childAllowsParent ) 
			{
				_bitmapdata = new BitmapData( loader.content.width, loader.content.height );
				_bitmapdata.draw( loader.content );
			}
			
			dispatchEvent( new Event( Event.COMPLETE ) );

			loader.unload();
			removeListeners();
		}
		
		protected function loadError( e:Event ):void
		{
			_loading = false;
			dispatchEvent( new Event( Event.CANCEL ) );
			dispatchEvent( new Event( Event.COMPLETE ) );
			removeListeners();
		}
		
		protected function removeListeners():void
		{
			loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, loadComplete );
			loader.contentLoaderInfo.removeEventListener( IOErrorEvent.IO_ERROR, loadError );
			loader.contentLoaderInfo.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, loadError );
		}
		
		public function get colorType():int { return ColorType.BITMAP; }
		public function get loading():Boolean { return _loading; }
		
		public function get repeat():Boolean { return _fillMode == "repeat"; }
		
		public function get bitmapdata():BitmapData { return _bitmapdata; }
		
		public function get fillMode():String { return _fillMode; }
		public function set fillMode(value:String):void {_fillMode = value;}
		
		public function get href():String { return _href; }
		public function set href(value:String):void 
		{
			if ( _href == value ) return;
			_href = value;
			loadBitmap( _href );
		}
		
		public function get matrix():Matrix { return _matrix.clone(); }
		public function set matrix(value:Matrix):void {_matrix = value;}

	}

}