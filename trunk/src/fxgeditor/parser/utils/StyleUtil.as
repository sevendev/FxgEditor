package fxgeditor.parser.utils 
{
	import flash.geom.Matrix;
	public class StyleUtil
	{
		
		public static function toNumber( val:String ):Number {
			if ( val.indexOf("%") != -1 ) return Number( val.replace( /%/, "") ) / 100;
			return Number( val.replace(/%|mm|px/, ""));
		}
		
		public static function toColor( val:String ):uint 
		{
			if ( val.lastIndexOf( "rgb" ) != -1 ) {
				var vals:Array = val.replace(/rgb\((.+)\)/, "$1" ).split(",");
				var result:String = "";
				for each( var item:String in vals ) {
					var v:String = int( item  ).toString(16);
					result += ( val.length > 1 ) ? v : "0" + v;
				}
				return uint( "0x" + result );
			}
			return uint( val.replace( /#/, "0x" ) );
		}
		
		public static function toURL( val:String ):String 
		{
			return val.replace(/\@Embed\(\'(.+)\'\)/ , "$1" );
		}
		
		public static function removeNameSpace( val:String ):String 
		{
			return val.replace(/http(.+)::(.+)/, "$2");
		}
		
		public static function validateAttr( attr:XMLList , val:* ):*
		{
			return attr.length() ? attr.toString() : val;
		}
		
		public static function validateMatrix( xml:XML , m:Matrix ):void
		{
			m.a = validateAttr( xml.@a , m.a );
			m.b = validateAttr( xml.@b , m.b );
			m.c = validateAttr( xml.@c , m.c );
			m.d = validateAttr( xml.@d , m.d );
			m.tx = validateAttr( xml.@tx , m.tx );
			m.ty = validateAttr( xml.@ty , m.ty );
		}
		
		//export
		public static function fromURL( val:String ):String {
			return "@Embed('" + val +"')";
		}
		
		public static function fromColor(value:uint):String {
			var str:String = value.toString(16).toUpperCase();
			return "#" + String("000000" + str ).substr(-6);
		}
		
		public static function fromNumber( value:Number , unit:String = "" ):String 
		{
			return value + unit;
		}
		
		public static function setMatrixAttr( node:XML , m:Matrix ):void
		{
			node.@a = m.a;
			node.@b = m.b;
			node.@c = m.c;
			node.@d = m.d;
			node.@tx = m.tx;
			node.@ty = m.ty;
		}
		
		
		public static function getRandomColor():uint 
		{
			return Math.round( Math.random() * 0xFFFFFF );
		}
		
	}

}