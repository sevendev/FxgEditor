package fxgeditor.parser 
{
	import component.custom.preloader.WhitePreLoader;
	import flash.display.*;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldType;
	import flash.text.engine.*;
	import flashx.textLayout.edit.IEditManager;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.events.StatusChangeEvent;
	import flashx.textLayout.edit.EditManager;
	import flashx.textLayout.conversion.ConversionType;
	import flashx.undo.UndoManager;
	import flashx.textLayout.elements.InlineGraphicElementStatus;
	import fxgeditor.parser.abstract.AbstractEditable;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.style.Style;
	import flash.text.engine.FontLookup;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.parser.utils.GeomUtil;
	import fxgeditor.event.ItemEditEvent;
	import fxgeditor.Constants;

	public class TextGraphic extends AbstractEditable implements IParser
	{
		public static var LOCALNAME:String = "TextGraphic";
		
		private var _textFlow:TextFlow;
		private var _container:ContainerController;
		private var creationTimer:Timer;
		
		public function TextGraphic() { }
		
		/* IEditable methods*/
		override public function redraw():void 
		{
			if ( _textFlow ) {
				if (  _textFlow.interactionManager  )
					EditManager( _textFlow.interactionManager ).applyLeafFormat( style.text );
				else
					_textFlow.format = style.text;
				
				_textFlow.flowComposer.updateAllControllers();
			}
			this.transform.matrix = new Matrix();
			applyStyle();
		}
		
		override public function edit():void 
		{
			_textFlow.interactionManager = new EditManager();
			_textFlow.flowComposer.updateAllControllers();
			_textFlow.interactionManager.selectRange(0,0);
			_textFlow.interactionManager.refreshSelection();
			_textFlow.interactionManager.setFocus();	
			style.text =  _textFlow.interactionManager.getCommonCharacterFormat() as TextLayoutFormat;
		}
		
		override public function exit():void
		{
			_textFlow.interactionManager.selectRange(0,0);
			_textFlow.interactionManager.refreshSelection();
			_textFlow.interactionManager = null;
			_textFlow.flowComposer.updateAllControllers();
		}
		
		override public function getFxg():XML 
		{
			if ( _isMask || !_textFlow ) return new XML;
			var node:XML = <{RichText.LOCALNAME} />;
			node.appendChild( <content/> );
			var flowxml:XML = TextConverter.export( _textFlow , TextConverter.TEXT_LAYOUT_FORMAT, ConversionType.XML_TYPE ) as XML;
			var format:ITextLayoutFormat = _textFlow.format;
			if ( format.fontFamily ) node.@fontFamily =  format.fontFamily;
			if ( format.fontSize )node.@fontSize = format.fontSize;
			if ( format.color )node.@color = StyleUtil.fromColor( format.color );
			if ( format.whiteSpaceCollapse )node.@whiteSpaceCollapse = format.whiteSpaceCollapse;
			if ( format.lineHeight )node.@lineHeight = format.lineHeight;
			if ( format.kerning ) node.@kerning = format.kerning;
			if ( format.fontWeight ) node.@fontWeight = format.fontWeight;
			if ( format.fontStyle ) node.@fontStyle = format.fontStyle;
			if ( !isNaN( style.width ) && style.width != 0  ) node.@width = style.width;

			for each( var item:XML in flowxml.descendants() )
				item.setNamespace( Constants.fxg );
			node.content[0].appendChild( flowxml.children() );
			node.content.setNamespace( Constants.fxg.uri );
			
			style.setFxgAttr( node );
			return node;
		}
		
		override public function newPrimitive():void 
		{ 
			this.stage.addEventListener( MouseEvent.MOUSE_DOWN, createText );
		};
		
		override public function cancelCreation():void
		{
			creationTimer.stop();
			reset ( );
			dispatchEvent( new ItemEditEvent( ItemEditEvent.CREATION_CANCELED ) );
			this.removeFromStage();
		}
		
		override public function outline( f:Boolean ):void { }
		
		/* IParser methods*/
		public function parse( data:Data ):void 
		{
			name = data.currentXml.@id.toString();
			
			style = new Style( data.currentXml );
			
			var format:TextLayoutFormat = new TextLayoutFormat();
			
			format.fontFamily = StyleUtil.validateAttr( data.currentXml.@fontFamily , Constants.FONT_FAMILY );
			format.fontSize = StyleUtil.validateAttr( data.currentXml.@fontSize,Constants.FONT_SIZE );
			format.lineHeight = StyleUtil.validateAttr( data.currentXml.@lineHeight, format.lineHeight );
			format.color = StyleUtil.validateAttr( data.currentXml.@color, format.color );
			format.kerning = StyleUtil.validateAttr( data.currentXml.@kerning, format.kerning );
			format.whiteSpaceCollapse = StyleUtil.validateAttr( data.currentXml.@whiteSpaceCollapse, format.whiteSpaceCollapse );
			format.fontWeight = StyleUtil.validateAttr( data.currentXml.@fontWeight , format.fontWeight );
			format.fontStyle = StyleUtil.validateAttr( data.currentXml.@fontStyle, format.fontStyle );
			format.textDecoration = StyleUtil.validateAttr( data.currentXml.@textDecoration, format.textDecoration );
			format.lineThrough = StyleUtil.validateAttr( data.currentXml.@lineThrough, format.lineThrough );
			format.textAlpha = StyleUtil.validateAttr( data.currentXml.@textAlpha, format.textAlpha );
			format.backgroundAlpha = StyleUtil.validateAttr( data.currentXml.@backgroundAlpha, format.backgroundAlpha );
			format.baselineShift = StyleUtil.validateAttr( data.currentXml.@baselineShift, format.baselineShift );
			format.breakOpportunity = StyleUtil.validateAttr( data.currentXml.@breakOpportunity, format.breakOpportunity );
			format.digitCase = StyleUtil.validateAttr( data.currentXml.@digitCase, format.digitCase );
			format.digitWidth = StyleUtil.validateAttr( data.currentXml.@digitWidth, format.digitWidth );
			format.dominantBaseline = StyleUtil.validateAttr( data.currentXml.@dominantBaseline, format.dominantBaseline );
			format.ligatureLevel = StyleUtil.validateAttr( data.currentXml.@ligatureLevel, format.ligatureLevel );
			format.locale = StyleUtil.validateAttr( data.currentXml.@locale, format.locale );
			format.typographicCase = StyleUtil.validateAttr( data.currentXml.@typographicCase, format.typographicCase );
			format.textRotation = StyleUtil.validateAttr( data.currentXml.@textRotation, format.textRotation );
			format.trackingLeft  = StyleUtil.validateAttr( data.currentXml.@trackingLeft , format.trackingLeft );
			format.trackingRight  = StyleUtil.validateAttr( data.currentXml.@trackingRight , format.trackingRight );
			
			style.width = StyleUtil.validateAttr(  data.currentXml.@width , NaN );
			style.height = StyleUtil.validateAttr( data.currentXml.@height , NaN );

			var fxg:Namespace = Constants.fxg;
			var flowxml:XML = <TextFlow xmlns="http://ns.adobe.com/textLayout/2008" /> ;
			var content:XML = data.currentXml..fxg::content[0].copy();
			if ( !content ) return;
			for each( var item:XML in content.descendants() )
				item.setNamespace( flowxml.namespace() );
			flowxml.appendChild( content.children() );
			
			createTextFlow( flowxml , format );
			
			data.currentCanvas.addChild( this );
			applyStyle( );
		}
		
		/* IEditable private methods*/
		private function createTextFlow( xml:XML , format:ITextLayoutFormat ):void
		{
			reset();
			_textFlow = TextConverter.importToFlow(  xml , TextConverter.TEXT_LAYOUT_FORMAT );
			_container = new ContainerController( this , style.width , style.height );
			_textFlow.hostFormat = _textFlow.format = format;
			_textFlow.flowComposer.addController( _container );
			_textFlow.addEventListener(StatusChangeEvent.INLINE_GRAPHIC_STATUS_CHANGE , onImageLoaded );
			_textFlow.flowComposer.updateAllControllers();
			style.text = new TextLayoutFormat( format );
		}
		
		private function createText( e:MouseEvent ):void 
		{
			this.stage.removeEventListener( MouseEvent.MOUSE_DOWN, createText );
			creationTimer = new Timer( Constants.AUTO_CREATION_DELAY , 1);
			creationTimer.addEventListener( TimerEvent.TIMER_COMPLETE, function( e:TimerEvent ):void
			{
				creationTimer.removeEventListener(  TimerEvent.TIMER_COMPLETE, arguments.callee );
				doCreateText();
			} );
			creationTimer.start();
		}
		
		private function doCreateText():void 
		{
			
			style = new Style();
			style.x = this.mouseX;
			style.y = this.mouseY;

			var flowxml:XML = < TextFlow xmlns = "http://ns.adobe.com/textLayout/2008" ><div>Text</div></TextFlow>;
			var format:TextLayoutFormat = new TextLayoutFormat();
			format.fontFamily = Constants.FONT_FAMILY;
			format.fontSize = Constants.FONT_SIZE;
			createTextFlow( flowxml , format );
			applyStyle();
			
			dispatchEvent( new ItemEditEvent( ItemEditEvent.CREATION_COMPLETE ) );
		}

		/* IParser private methods*/
		private function onImageLoaded( e:StatusChangeEvent ):void
		{
			if (e.status == InlineGraphicElementStatus.READY || e.status == InlineGraphicElementStatus.SIZE_PENDING)
				_textFlow.flowComposer.updateAllControllers();
		}
		
		override protected function reset ( ):void 
		{
			if ( _textFlow ) _textFlow.flowComposer.removeAllControllers();
		}
		
		
	}

}