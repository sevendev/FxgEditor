package component 
{
	import mx.core.IFlexDisplayObject;
	import fxgeditor.StyleObject;
	//import fxgeditor.parser.style.Style;
	
	public interface StylePanel extends IFlexDisplayObject
	//public interface StylePanel
	{
		function setItemStyle( s:StyleObject ):void ;
		//function setItemStyle( s:Style ):void ;
		function set type( t:String ):void;
		function get type():String;
	}
	
}