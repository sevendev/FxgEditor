package fxgeditor.parser.style
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public interface IGradient extends IStyleParser
	{
		function newPrimitive():void ;
		function copy():IStyleParser;
		function convert():IGradient;
		
		function setSize( rect:Rectangle ):void;
		function get type():String;
		function get colors():Array;
		function get alphas():Array;
		function get ratios():Array;
		function get matrix():Matrix;
		function get method():String;
		
		function set colors(value:Array):void ;
		function set alphas(value:Array):void ;
		function set ratios(value:Array):void ;
		function set matrix(value:Matrix):void;
	}
	
}