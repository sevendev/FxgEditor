package fxgeditor.parser.style 
{
	import flash.display.DisplayObject;
	import flash.display.CapsStyle;
	import flash.display.DisplayObjectContainer;
	import flash.display.JointStyle;
	import flash.display.Sprite;
	import flash.display.BlendMode;
	import flash.filters.BitmapFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flashx.textLayout.formats.TextLayoutFormat;
	import fxgeditor.parser.FxgFactory;
	import fxgeditor.parser.IEditable;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.model.PersistentData;
	import fxgeditor.parser.Rect;
	import fxgeditor.parser.style.Transform;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.parser.utils.GeomUtil;
	import fxgeditor.Constants;
	import fxgeditor.parser.style.*;
	import fxgeditor.parser.filters.*;
	import fxgeditor.StyleObject;
	
	public class Style
	{
		public var id:String = "";
		
		public var display:Boolean = true;
		public var visible:Boolean = true;
		public var viewBox:Rectangle;
		
		public var x:Number = 0;
		public var y:Number = 0;
		public var width:Number;
		public var height:Number;
		public var scaleX:Number = 1.0;
		public var scaleY:Number = 1.0;
		public var rotation:Number = 0;
		public var alpha:Number = 1.0;
		public var blendMode:String = BlendMode.NORMAL;
		
		public var fill:IStyleParser;
		public var stroke:IStyleParser;
		public var text:TextLayoutFormat;
		
		public var maskType:*;
		public var scaleGridLeft:*;
		public var scaleGridRight:*;
		public var scaleGridTop:*;
		public var scaleGridBottom:*;
		
		public var transform:Transform;
		public var filters:Array = [];
		public var mask:XML;
		public var href:String;

		private var maskobj:IEditable;
		private var _bounds:Rectangle;
		private var _xmls:XMLList = new XMLList();
		
		public function Style( xml:XML = null ) {
			if ( xml ) parse( xml );
		}
		
		public function parse( xml:XML ):void 
		{
			_xmls += xml;
			setAttr( xml );
			var attr:XMLList = xml.children();
			for each( var item:XML in attr )
				setStyle( item.localName() , item );
		}
		
		public function copy():Style {
			var style:Style = new Style();
			for each ( var xml:XML in _xmls ) style.addStyle( xml );
			return style;
		}
		
		public function addStyle( xml:XML ):void 
		{
			parse( xml );
		}
		
		public function applyStyle( d:DisplayObject ):void {
			try { d.name = id; }catch( e:Error ) {}
			
			var mat:Matrix = new Matrix();
			mat.scale( scaleX, scaleY );
			mat.rotate( GeomUtil.degree2radian( rotation ) );
			mat.translate( x , y );
			addMatrix( mat );
			d.transform.matrix = transform.matrix;
			
			x = y = rotation = 0;
			scaleX = scaleY = 1;
			
			if ( viewBox ) d.scrollRect = viewBox;
			if ( hasColorTransform ) d.transform.colorTransform = transform.colorTransform;
			if ( hasMask ) {
				if ( !maskobj ) {
					//var parent:DisplayObjectContainer = d.parent ? d.parent : d as DisplayObjectContainer;
					var parent:DisplayObjectContainer = d as DisplayObjectContainer;
					FxgFactory.parseData( new Data( mask, parent ) );
					maskobj =  parent.getChildAt( parent.numChildren -1 ) as IEditable;
					//maskobj.setMatrix( d.transform.matrix.clone() );
					if ( maskobj ) maskobj.isMask = true;
				}
				d.mask = maskobj.asObject;
			}else
				d.mask = null;
			
			d.alpha = alpha;
			d.blendMode = blendMode;
			d.visible = visible;
			d.filters = flashFilters;
			
		}
		
		public function convertColorType( prop:String , type:String  ):void
		{
			if ( type == "none" ) {
				this[prop] = null;
				return;
			}
			for each( var Cl:Class in COLORS ) 
				if ( type == Cl["LOCALNAME"] ) {
					this[prop] = new Cl();
					break;
				}
		}
		
		public function setFxgAttr( node:XML ):void
		{
			if( alpha != 1 ) node.@alpha = alpha;
			if ( transform ) transform.setFxgAttr( node );
			if ( fill ) 
			{
				node.appendChild( <fill /> );
				node.fill[0].appendChild( fill.getXML() );
			}
			if ( stroke ) 
			{
				node.appendChild( <stroke /> );
				node.stroke[0].appendChild( stroke.getXML() );
			}
			
			if ( hasMask ) {
				mask = mask.localName() == "mask" ? mask.copy() : <mask>{mask.copy()}</mask>;
				node.appendChild( mask );
			}
			
			if ( blendMode != BlendMode.NORMAL )
				node.@blendMode = blendMode;
				
			if ( hasFilter )
			{
				node.appendChild( <filters /> );
				for each( var filter:IFilter in filters )
					node.filters[0].appendChild( filter.getXML() );
			}

			if ( viewBox ) {
				node.@viewHeight = viewBox.height;
				node.@viewWidth = viewBox.width;
			}
		}

		public function getStyleObj():StyleObject
		{
			var o:StyleObject = new StyleObject();
			o.parseStyle( this );
			return o;
		}
		
		public function parseStyleObj( o:StyleObject ):void
		{
			id = o.id;
			o.setStyle( this );
		}
		
		public function addMatrix( m:Matrix ):void 
		{
			if ( !transform ) transform = new Transform();
			var mat:Matrix = transform.matrix;
			mat.concat( m.clone() );
			transform.matrix =  mat;
		}
		
		public function setMatrix( m:Matrix ):void 
		{
			if ( !transform ) transform = new Transform();
			transform.matrix = m.clone();
		}
		
		public function getMatrix():Matrix 
		{	
			if ( hasMatrix ) return transform.matrix;
			return new Matrix();
		}
		
		public function getColorTransform():ColorTransform 
		{	
			if ( hasColorTransform ) return transform.colorTransform;
			return new ColorTransform();
		}
		
		public function get flashFilters():Array
		{
			if ( !hasFilter ) return [];
			var fs:Array = [];
			for each( var f:IFilter in filters )
				fs.push( f.getFlashFilter() );
			return fs;
		}
		
		public function setMask( xml:XML ):void
		{
			mask = xml.copy();
		}
		
		public function removeMask():IEditable
		{
			var item:IEditable = maskobj;
			maskobj.isMask = false;
			mask = null;
			maskobj = null;
			return item;
		}
		
		public function get hasStroke():Boolean { 
			return stroke != null && IStroke( stroke ).weight != 0 ; 
		}
		public function get hasGradientStroke():Boolean { 
			return hasStroke && stroke.colorType == ColorType.GRADIENT; 
		}
		public function get hasFill():Boolean { 
			return fill != null && fill.colorType == ColorType.FLAT; 
		}
		public function get hasGradientFill():Boolean { 
			return fill != null && fill.colorType == ColorType.GRADIENT;
		}
		public function get hasBitmapFill():Boolean { 
			return fill != null && fill.colorType == ColorType.BITMAP;
		}
		public function get hasFilter():Boolean { 
			return  filters.length > 0 ; 
		}
		public function get hasMatrix():Boolean { 
			return ( transform != null && transform.hasMatrix ); 
		}
		public function get hasColorTransform():Boolean { 
			return ( transform != null && transform.hasColorTransform ); 
		}
		public function get hasMask():Boolean { 
			return mask != null; 
		}
		
		public function get bounds():Rectangle 
		{ 
			if ( !_bounds ) _bounds = new Rectangle( x, y, width, height );
			return _bounds; 
		}
		public function set bounds(value:Rectangle):void { _bounds = value; }
		
		private function setAttr( item:XML ):void
		{
			x = StyleUtil.validateAttr( item.@x , x );
			y = StyleUtil.validateAttr( item.@y , y );
			width = StyleUtil.validateAttr( item.@width , width );
			height = StyleUtil.validateAttr( item.@height , height );
			alpha = StyleUtil.validateAttr( item.@alpha , alpha );
			scaleX = StyleUtil.validateAttr( item.@scaleX , scaleX);
			scaleY= StyleUtil.validateAttr( item.@scaleY , scaleY );
			rotation = StyleUtil.validateAttr( item.@rotation ,rotation );
			blendMode = StyleUtil.validateAttr(item.@blendMode , blendMode );
			if ( item.@viewWidth.length() || item.@viewHeight.length() )
				viewBox = new Rectangle( 0, 0, item.@viewWidth , item.@viewHeight );
		}
		
		private function setStyle( key:String , item:XML ):void 
		{
			if ( key == null ) return;
			if ( key == "stroke" ) 
				stroke = getStyleFactory( item );
			else if ( key == "fill" ) 
				fill = getStyleFactory( item );
			else if ( key == "filters" )
				filters =  getFilterFactory( item );
			else if ( key == "transform" )
				transform = new Transform( item );
			else if ( key == "mask" ) 
				mask = item.copy();
		}
			
		//Color Style
		private static const COLORS:Array = [ 	SolidColor, SolidColorStroke, LinearGradient, BitmapFill, 
												RadialGradient, LinearGradientStroke , RadialGradientStroke ];
		
		private static function getStyleFactory( xml:XML ):IStyleParser 
		{
			var children:XMLList  = xml.children();
			for each( var child:XML in children )
			{
				var color:IStyleParser = getStyleParser( child );
				if ( !color ) continue;
				color.parse( child );
				return color;
			}
			return null;
		}
		
		private static function getStyleParser( xml:XML  ):IStyleParser 
		{
			for each( var Cl:Class in COLORS ) 
				if ( xml.localName() == Cl["LOCALNAME"] ) return new Cl();
			return null;
		}
		
		//Filter
		private static const FILTERS:Array = [ 	BlurFilter , DropShadowFilter, GlowFilter, BevelFilter , 
												ColorMatrixFilter , GradientBevelFilter , GradientGlowFilter ];
		
		private static function getFilterFactory( xml:XML ):Array 
		{
			var fs:Array = [];
			var children:XMLList  = xml.children();
			for each( var child:XML in children )
			{
				var filter:IFilter = getFilterParser( child );
				if ( !filter ) continue;
				filter.parse( child );
				fs.push(  filter );
			}
			return fs;
		}
		
		private static function getFilterParser( xml:XML  ):IFilter 
		{
			for each( var Cl:Class in FILTERS ) 
				if ( xml.localName() == Cl["LOCALNAME"] ) return new Cl();
			return null;
		}
		
		public static function getFilterByName( name:String ):IFilter
		{
			for each( var Cl:Class in FILTERS ) 
				if ( name == Cl["LOCALNAME"] ) return new Cl();
			return null;
		}
	}

}