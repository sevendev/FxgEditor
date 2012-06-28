package fxgeditor.parser.filters 
{
	import flash.display.DisplayObject;
	import flash.filters.BitmapFilter;
	import fxgeditor.FilterParameters;
	public interface IFilter 
	{
		function parse( xml:XML ):void;
		function getFlashFilter():BitmapFilter;
		function getXML():XML;
		
		function parsePrameters( o:FilterParameters ):void;
		function getPrameters():FilterParameters;
	}
	
}