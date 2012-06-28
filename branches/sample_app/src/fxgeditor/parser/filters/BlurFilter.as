package fxgeditor.parser.filters 
{
	import flash.filters.BitmapFilter;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.FilterParameters;
	
	public class BlurFilter implements IFilter
	{
		
		public static var LOCALNAME:String = "BlurFilter";
		
		private var _blurX:Number = 4;
		private var _blurY:Number = 4;
		private var _quality :Number = 1;
		
		public function BlurFilter() { }
		
		public function parse( xml:XML ):void
		{
			_blurX = StyleUtil.validateAttr( xml.@blurX , _blurX );
			_blurY = StyleUtil.validateAttr( xml.@blurY , _blurY );
			_quality = StyleUtil.validateAttr( xml.@quality , _quality );

		}
		
		public function getFlashFilter():BitmapFilter 
		{
			return new flash.filters.BlurFilter( _blurX, _blurY, _quality );
		}
		
		public function getXML():XML
		{
			var node:XML = <{LOCALNAME} />;
			node.@blurX = _blurX;
			node.@blurY = _blurY;
			node.@quality = _quality;
			return node;
		}
		
		public function parsePrameters( o:FilterParameters ):void 
		{
			_blurX = o.blurX;
			_blurY = o.blurY;
			_quality = o.quality;
		}
		
		public function getPrameters():FilterParameters 
		{
			var o:FilterParameters = new FilterParameters();
			o.blurX = _blurX;
			o.blurY = _blurY;
			o.quality = _quality;
			return o;
		}
		
	}

}