package fxgeditor.parser.style
{
	import fxgeditor.parser.style.Style;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.Constants;
	
	public class SolidColor implements IStyleParser, IColor
	{
		public static var LOCALNAME:String = "SolidColor";
		
		protected var _color:uint = Constants.FILL_COLOR;
		protected var _opacity:Number = 1.0;

		public function SolidColor() {}
		
		public function parse( item:XML ) :void
		{
			_color = StyleUtil.toColor( item.@color );
			_opacity = StyleUtil.validateAttr( item.@alpha , _opacity );
		}
		
		public function toStroke( stroke:IStroke = null ):IStroke
		{
			var st:SolidColorStroke = new SolidColorStroke();
			st.color = _color;
			st.opacity = _opacity;
			st.setStroke( stroke );
			return st;
		}
		
		public function getXML( localName:String = null ):XML
		{
			localName = localName ? localName : LOCALNAME;
			var node:XML = <{localName} />;
			node.@color = StyleUtil.fromColor( _color );
			node.@alpha = StyleUtil.fromNumber( _opacity );
			return node;
		}
		
		public function get colorType():int { return ColorType.FLAT; }
		
		public function get color():uint { return _color; }
		public function get opacity():Number { return _opacity; }

		public function set color(value:uint):void { _color = value; }
		public function set opacity(value:Number):void { _opacity = value; }
		
	}

}