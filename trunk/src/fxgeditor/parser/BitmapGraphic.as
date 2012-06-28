package fxgeditor.parser
{
	import flash.display.DisplayObjectContainer ;
	import flash.display.DisplayObject;
	import flash.display.LineScaleMode;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import fxgeditor.parser.abstract.AbstractEditable;
	import fxgeditor.parser.IParser;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.style.Style;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.event.PathEditEvent;
	import fxgeditor.parser.path.EditPoint;
	import fxgeditor.Constants;
	
	public class BitmapGraphic extends AbstractEditable implements IParser
	{
		public static var LOCALNAME:String = "BitmapGraphic";
		
		protected var loader:Loader;
		private var sizePt:EditPoint;

		public function BitmapGraphic() { }
		
		/* IEditable methods*/
		override public function redraw():void 
		{ 
			if ( style.href == null ) return;
			if ( !loader || loader.contentLoaderInfo.url != style.href )
			{
				if ( loader ) loader.unload();
				loadImage();
			}else if( loader.contentLoaderInfo.childAllowsParent )
				applyStyle();
		}
		
		override public function edit():void 
		{ 
			createControl();
			sizePt = new EditPoint( _controlLayer, _pathLayer , 1 , style.width, style.height );
			sizePt.addEventListener( PathEditEvent.PATH_EDIT , onPathEdit );
		}
		
		override public function exit():void 
		{ 
			this.graphics.clear();
			sizePt.exit();
			removeControl();
			if ( !loader ) this.parent.removeChild( this );
		}
		
		override public function getFxg():XML 
		{
			if ( !style.href || _isMask ) return new XML;
			var node:XML = <{LOCALNAME} />;
			if( !isNaN(style.width) )node.@width = style.width;
			if( !isNaN(style.height) )node.@height = style.height;
			node.@source = StyleUtil.fromURL( style.href );
			style.setFxgAttr( node );
			return node;
		}
		
		override public function outline( f:Boolean ):void
		{
			_outline = f;
			loader.visible = !_outline;
			if ( _outline )
				drawOutLine();
			else
				this.graphics.clear();
		}
		
		/* IParser methods*/
		public function parse( data:Data ):void 
		{
			style = new Style( data.currentXml );
			
			style.width = style.width;
			style.height = style.height;

			style.href  = StyleUtil.toURL( data.currentXml.@source );
			
			data.currentCanvas.addChild( this );
			
			if ( style.href != null ) loadImage();
		}
		
		protected function loadImage():void 
		{
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener( Event.COMPLETE, loadComplete );
			loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, loadError );
			loader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, loadError );
			loader.load( new URLRequest( style.href ) );
			addChild( loader );
			loader.doubleClickEnabled = true;
		}
		
		protected function loadComplete( e:Event ):void 
		{
			if ( !loader.contentLoaderInfo.childAllowsParent ) return;
			
			applyStyle();
			if ( !isNaN( style.width) ) 
				loader.content.width = style.width;
			else
				style.width = loader.content.width;
				
			if ( !isNaN( style.height) ) 
				loader.content.height = style.height;
			else
				style.height = loader.content.height;
			
			removeListeners();
		}
		
		protected function loadError( e:Event ):void { removeListeners(); }
		
		protected function removeListeners():void
		{
			loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, loadComplete );
			loader.contentLoaderInfo.removeEventListener( IOErrorEvent.IO_ERROR, loadError );
			loader.contentLoaderInfo.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, loadError );
		}
		
		override protected function onCreationUpdate( e:Event ):void
		{
			if ( !style.hasMatrix ) 
			{
				style.x = _creationBox.rect.x;
				style.y = _creationBox.rect.y;
			}
			style.width = _creationBox.rect.width;
			style.height = _creationBox.rect.height;
			drawEditLine();
		}
		
		protected function drawEditLine():void 
		{
			this.graphics.clear();
			this.graphics.lineStyle( 1, Constants.EDIT_LINE_COLOR, 1 );
			this.graphics.beginFill( 0x666666 , .2 );
			this.graphics.drawRect( 0 , 0 , style.width, style.height );
			this.graphics.endFill();
			applyStyle();
		}
		
		protected function drawOutLine():void 
		{
			this.graphics.clear();
			this.graphics.lineStyle( 1, Constants.OUTLINE_COLOR, 1 , false, LineScaleMode.NONE );
			this.graphics.drawRect( 0 , 0 , style.width, style.height );
		}
		
		private function onPathEdit( e:PathEditEvent ):void 
		{
			style.width = sizePt.ax;
			style.height = sizePt.ay;
			if ( loader )
			{
				loader.content.width = style.width;
				loader.content.height = style.height;
			}
			drawEditLine();
		}

	}

}