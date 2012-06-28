package fxgeditor.parser 
{
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import fxgeditor.parser.IParser;
	import fxgeditor.Constants;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.style.Style;
	import fxgeditor.parser.abstract.AbstractEditable;
	import fxgeditor.parser.model.PersistentData;
	
	public class Graphic extends AbstractEditable implements IParser
	{
		
		public static var LOCALNAME:String = "Graphic";
		
		public function Graphic() { }	
		
		public function parse( data:Data ):void 
		{
			reset();
			style = new Style( data.currentXml );
			if ( !style.display ) return;
			this.name = style.id;
			applyStyle();
			drawCanvas( style.viewBox );
			data.currentCanvas.addChild( this );
			var fxgXML:XML = data.currentXml.copy();
			fxgXML.setLocalName(  "_Graphic" );	
			FxgFactory.parseData( data.copy( fxgXML , this ) );
		}
		
		override public function getFxg():XML 
		{
			var node:XML = <{LOCALNAME} xmlns={Constants.fxg.uri} />;
			node.addNamespace( Constants.fxg );
			node.addNamespace( Constants.d );
			node.@version = Constants.FXG_VERSION;
			
			style.setFxgAttr( node );
			var children:Vector.<IEditable> = this.getChildren();
			for each ( var item:IEditable in children ) 
				node.appendChild( item.getFxg() );
			return node;
		}
		
		override public function outline( f:Boolean ):void
		{
			var children:Vector.<IEditable> = this.getChildren();
			for each ( var item:IEditable in children ) 
				item.outline( f );
		}
		
		private function drawCanvas( box:Rectangle ):void 
		{
			if ( !box ) box = new Rectangle( 0 , 0, 600, 800 );
			this.graphics.lineStyle( 1, 0xcccccc, 1 );
			this.graphics.beginFill( 0xffffff, 1 );
			this.graphics.drawRect( box.x, box.y , box.width - 1, box.height - 1 );
			this.graphics.endFill();
			this.scrollRect = null;
		}
		
		override public function getNumChildren():int 
		{
			return numChildren;
		}
		override public function redraw():void {}
		override public function edit():void { }
		override public function exit():void { }
	}

}