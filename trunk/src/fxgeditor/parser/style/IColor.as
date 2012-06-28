package fxgeditor.parser.style
{
	
	public interface IColor extends IStyleParser
	{
		function get color():uint;
		function get opacity():Number;
		function set color(value:uint):void;
		function set opacity(value:Number):void ;
		
	}
	
}