package fxgeditor.parser 
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.LineScaleMode;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import fxgeditor.parser.abstract.AbstractEditable;
	import fxgeditor.parser.IParser;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.style.Style;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.Constants;
	
	public class Group extends AbstractEditable implements IParser
	{
		
		public static var LOCALNAME:String = "Group";
		
		private var _width:Number;
		private var _height:Number;
		
		public function Group() { }
		
		override public function redraw():void 
		{
			this.transform.matrix = new Matrix();
			applyStyle();
		}

		public function parse( data:Data ):void 
		{
			reset();
			style = new Style( data.currentXml );
			if ( !style.display ) return;
			name = style.id;
			
			width = _width = style.width;
			height = _height = style.height;

			data.currentCanvas.addChild( this );
			var groupXML:XML = data.currentXml.copy();
			
			var fxg:Namespace = Constants.fxg;
			groupXML.setLocalName(  "_Group" );
			if ( groupXML.fxg::mask.length() ) // remove MASK
				delete groupXML.fxg::mask;
			FxgFactory.parseData( data.copy( groupXML, this ) );
			
			applyStyle();
		}
		
		override public function getFxg():XML 
		{
			if ( !getNumChildren() || _isMask ) return new XML;
			var node:XML = <{LOCALNAME} />;
			style.setFxgAttr( node );
			
			var children:Vector.<IEditable> = getChildren();
			for each ( var item:IEditable in children ) 
				node.appendChild( item.getFxg() );
			return node;
		}
		
		override public function getNumChildren():int 
		{
			return numChildren;
		}
		
		override public function outline( f:Boolean ):void
		{
			var children:Vector.<IEditable> = this.getChildren();
			for each ( var item:IEditable in children ) 
				item.outline( f );
			
			if ( f ) 
			{
				this.filters = [];
				this.mask = null;
			}
			else
				redraw();
		}
		
		override public function newPrimitive():void 
		{
			style = new Style();
		}
		
		public function setChildren( children:Vector.<IEditable> ):void
		{
			for each( var child:IEditable in children )
				this.addChild( child as DisplayObject );
		}
		
		override public function edit():void 
		{ 
			var rect:Rectangle = this.getBounds( this );
			this.graphics.lineStyle( 1, Constants.EDIT_LINE_COLOR , .5 , false, LineScaleMode.NONE );
			this.graphics.drawRect( rect.x, rect.y , rect.width , rect.height );
		}
		
		override public function exit():void 
		{ 
			this.graphics.clear();
		}
	}

}