package fxgeditor.parser.style
{
	public interface IStroke extends IStyleParser
	{
		function setStroke( s:IStroke ):void;
		
		function get weight():Number;
		function get miterLimit():Number;
		function get caps():String;
		function get joints():String;
		
		function set weight(value:Number):void;
		function set miterLimit(value:Number):void;
		function set caps(value:String):void;
		function set joints(value:String):void;
	}
	
}