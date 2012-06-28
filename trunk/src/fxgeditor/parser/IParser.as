package fxgeditor.parser 
{
	import fxgeditor.parser.model.Data;
	
	public interface IParser 
	{
		function parse(  data:Data ):void;
	}
	
}