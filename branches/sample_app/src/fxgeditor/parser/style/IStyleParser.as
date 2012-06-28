package fxgeditor.parser.style
{
	
	public interface IStyleParser 
	{
		function parse( item:XML ):void;
		function get colorType():int;
		function toStroke( stroke:IStroke = null ):IStroke;
		function getXML( localName:String = null ):XML;
	}
	
}