package fxgeditor.parser.filters 
{
	import flash.filters.BitmapFilter;
	import fxgeditor.Constants;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.FilterParameters;
	
	public class GradientGlowFilter implements IFilter
	{
		
		public static var LOCALNAME:String = "GradientGlowFilter";
		
		private var _blurX:Number = 4;
		private var _blurY:Number = 4;
		private var _distance:Number = 4;
		private var _angle:Number = 45;
		private var _strength:Number = 1;
		private var _quality :Number = 1;
		private var _type :String = "inner";
		private var _knockout:Boolean = false;
		
		protected var _colors:Array = [];
		protected var _alphas:Array = [];
		protected var _ratios:Array = [];
		
		public function GradientGlowFilter() { }
		
		public function parse( xml:XML ):void
		{
			_blurX = StyleUtil.validateAttr( xml.@blurX , _blurX );
			_blurY = StyleUtil.validateAttr( xml.@blurY , _blurY );
			_distance = StyleUtil.validateAttr( xml.@distance , _distance );
			_angle = StyleUtil.validateAttr( xml.@angle , _angle );
			_strength = StyleUtil.validateAttr( xml.@strength , _strength );
			_quality = StyleUtil.validateAttr( xml.@quality , _quality );
			_type = StyleUtil.validateAttr( xml.@type , _type );
			
			if ( xml.@knockout.length() ) _knockout = xml.@knockout.toString() == "true";
			
			var fxg:Namespace = Constants.fxg;
			var stops:XMLList = xml.fxg::GradientEntry;
			for each( var stop:XML in stops ) 
				parseStop( stop );
		}
		
		public function getFlashFilter():BitmapFilter 
		{
			return new flash.filters.GradientGlowFilter(_distance, _angle, _colors, _alphas , _ratios, _blurX, _blurY , _strength, _quality, _type, _knockout );
		}
		
		public function getXML():XML
		{
			var node:XML = <{LOCALNAME} />;
			node.@blurX = _blurX;
			node.@blurY = _blurY;
			node.@distance = _distance;
			node.@angle = _angle;
			node.@strength = _strength;
			node.@quality = _quality;
			node.@type = _type;
			node.@knockout = _knockout ? "true" : "false";
			
			var length:int = _colors.length;
			for (var i:int = 0; i < length ; i++ ) {
				node.appendChild( <GradientEntry /> );
				node.GradientEntry[i].@color = StyleUtil.fromColor( _colors[i] );
				node.GradientEntry[i].@ratio = StyleUtil.fromNumber( _ratios[i] / 255 ) ;
				if ( _alphas[i] != 1 )
					node.GradientEntry[i].@alpha = StyleUtil.fromNumber( _alphas[i] );
			}
			return node;
		}
		
		protected function parseStop( stop:XML ):void 
		{
			_colors.push( StyleUtil.toColor( stop.@color ));
			_alphas.push( stop.@alpha.length() ? StyleUtil.toNumber( stop.@alpha ) : 1.0 );
			_ratios.push( StyleUtil.toNumber( stop.@ratio ) * 255 );
		}
		
		public function parsePrameters( o:FilterParameters ):void 
		{
			_blurX = o.blurX;
			_blurY = o.blurY;
			_distance = o.distance;
			_angle = o.angle;
			_strength = o.strength;
			_quality = o.quality;
			_type = o.type;
			_knockout = o.knockout;
			_colors = o.colors;
			_alphas = o.alphas;
			_ratios = o.ratios;
		}
		
		public function getPrameters():FilterParameters 
		{
			var o:FilterParameters = new FilterParameters();
			o.blurX = _blurX;
			o.blurY = _blurY;
			o.distance = _distance;
			o.angle = _angle;
			o.strength = _strength;
			o.quality = _quality;
			o.knockout = _knockout;
			o.type = _type;
			o.colors = _colors;
			o.alphas = _alphas;
			o.ratios = _ratios;
			return o;
		}
		
	}

}