package fxgeditor.parser.filters 
{
	import flash.filters.BitmapFilter;
	import fxgeditor.Constants;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.FilterParameters;
	
	public class BevelFilter implements IFilter
	{
		
		public static var LOCALNAME:String = "BevelFilter";
		
		private var _blurX:Number = 4;
		private var _blurY:Number = 4;
		private var _highlightAlpha:Number = 1;
		private var _highlightColor:uint = Constants.FILL_COLOR;
		private var _shadowAlpha:Number = 1;
		private var _shadowColor:uint = Constants.FILL_COLOR;
		private var _distance:Number = 4;
		private var _angle:Number = 45;
		private var _strength:Number = 1;
		private var _quality :Number = 1;
		private var _type :String = "inner";
		private var _knockout:Boolean = false;
		
		public function BevelFilter() { }
		
		public function parse( xml:XML ):void
		{
			if ( xml.@blurX.length() ) _blurX = xml.@blurX;
			if ( xml.@blurY.length() ) _blurY = xml.@blurY;
			if ( xml.@highlightAlpha.length() ) _highlightAlpha = xml.@highlightAlpha;
			if ( xml.@highlightColor.length() ) _highlightColor = StyleUtil.toColor( xml.@highlightColor );
			if ( xml.@shadowColor.length() ) _shadowColor = StyleUtil.toColor( xml.@shadowColor );
			if ( xml.@shadowAlpha.length() ) _shadowAlpha = xml.@shadowAlpha;
			if ( xml.@distance.length() ) _distance = xml.@distance;
			if ( xml.@angle.length() ) _angle = xml.@angle;
			if ( xml.@strength.length() ) _strength = xml.@strength;
			if ( xml.@quality.length() ) _quality = xml.@quality;
			if ( xml.@type.length() ) _type = xml.@type.toString();
			if ( xml.@knockout.length() ) _knockout = xml.@knockout.toString() == "true";
		}
		
		public function getFlashFilter():BitmapFilter 
		{
			return new flash.filters.BevelFilter(	 _distance, _angle, _highlightColor, _highlightAlpha, _shadowColor, _shadowAlpha, 
													_blurX, _blurY , _strength, _quality, _type, _knockout );
		}
		
		public function getXML():XML
		{
			var node:XML = <{LOCALNAME} />;
			node.@blurX = _blurX;
			node.@blurY = _blurY;
			node.@highlightColor = StyleUtil.fromColor( _highlightColor );
			node.@shadowColor = StyleUtil.fromColor( _shadowColor );
			node.@highlightAlpha = _highlightAlpha;
			node.@shadowAlpha = _shadowAlpha;
			node.@distance = _distance;
			node.@angle = _angle;
			node.@strength = _strength;
			node.@type = _type;
			node.@quality = _quality;
			node.@knockout = _knockout ? "true" : "false";
			return node;
		}
		
		public function parsePrameters( o:FilterParameters ):void 
		{
			_blurX = o.blurX;
			_blurY = o.blurY;
			_highlightAlpha = o.highlightAlpha;
			_highlightColor = o.highlightColor;
			_shadowAlpha = o.shadowAlpha;
			_shadowColor = o.shadowColor;
			_distance = o.distance;
			_angle = o.angle;
			_strength = o.strength;
			_quality = o.quality;
			_type = o.type;
			_knockout = o.knockout;
		}
		
		public function getPrameters():FilterParameters 
		{
			var o:FilterParameters = new FilterParameters();
			o.blurX = _blurX;
			o.blurY = _blurY;
			o.highlightAlpha = _highlightAlpha;
			o.highlightColor = _highlightColor;
			o.shadowAlpha = _shadowAlpha;
			o.shadowColor = _shadowColor;
			o.distance = _distance;
			o.angle = _angle;
			o.strength = _strength;
			o.quality = _quality;
			o.type = _type;
			o.knockout = _knockout;
			return o;
		}
	}

}