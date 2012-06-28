package fxgeditor.parser.filters 
{
	import flash.filters.BitmapFilter;
	import fxgeditor.Constants;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.FilterParameters;
	
	public class DropShadowFilter implements IFilter
	{
		
		public static var LOCALNAME:String = "DropShadowFilter";
		
		private var _blurX:Number = 4;
		private var _blurY:Number = 4;
		private var _alpha:Number = 1;
		private var _color:uint = Constants.FILL_COLOR;
		private var _distance:Number = 4;
		private var _angle:Number = 45;
		private var _strength:Number = 1;
		private var _quality :Number = 1;
		private var _inner:Boolean = false;
		private var _knockout:Boolean = false;
		private var _hideObject :Boolean = false;
		
		public function DropShadowFilter() { }
		
		public function parse( xml:XML ):void
		{
			_blurX = StyleUtil.validateAttr( xml.@blurX , _blurX );
			_blurY = StyleUtil.validateAttr( xml.@blurY , _blurY );
			_alpha = StyleUtil.validateAttr( xml.@alpha , _alpha );
			_distance = StyleUtil.validateAttr( xml.@distance , _distance );
			_angle = StyleUtil.validateAttr( xml.@angle , _angle );
			_strength = StyleUtil.validateAttr( xml.@strength , _strength );
			_quality = StyleUtil.validateAttr( xml.@quality , _quality );
			
			if ( xml.@inner.length() ) _inner = xml.@inner.toString() == "true";
			if ( xml.@knockout.length() ) _knockout = xml.@knockout.toString() == "true";
			if ( xml.@hideObject.length() ) _hideObject = xml.@hideObject.toString() == "true";
			if ( xml.@color.length() ) _color = StyleUtil.toColor( xml.@color );
			
		}
		
		public function getFlashFilter():BitmapFilter 
		{
			return new flash.filters.DropShadowFilter( _distance , _angle, _color, _alpha, _blurX, _blurY , _strength, _quality, _inner, _knockout, _hideObject );
		}
		
		public function getXML():XML
		{
			var node:XML = <{LOCALNAME} />;
			node.@blurX = _blurX;
			node.@blurY = _blurY;
			node.@color = StyleUtil.fromColor( _color );
			node.@alpha = _alpha;
			node.@distance = _distance;
			node.@angle = _angle;
			node.@strength = _strength;
			node.@quality = _quality;
			node.@inner = _inner ? "true" : "false";
			node.@knockout = _knockout ? "true" : "false";
			node.@hideObject = _hideObject ? "true" : "false";
			return node;
		}
		
		public function parsePrameters( o:FilterParameters ):void 
		{
			_blurX = o.blurX;
			_blurY = o.blurY;
			_alpha = o.alpha;
			_color = o.color;
			_distance = o.distance;
			_angle = o.angle;
			_strength = o.strength;
			_quality = o.quality;
			_inner = o.inner;
			_knockout = o.knockout;
			_hideObject = o.hideObject;
		}
		
		public function getPrameters():FilterParameters 
		{
			var o:FilterParameters = new FilterParameters();
			o.blurX = _blurX;
			o.blurY = _blurY;
			o.alpha = _alpha;
			o.color = _color;
			o.distance = _distance;
			o.angle = _angle;
			o.strength = _strength;
			o.quality = _quality;
			o.knockout = _knockout;
			o.inner = _inner;
			o.hideObject = _hideObject ;
			return o;
		}
		
	}

}