package fxgeditor.parser.abstract 
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import fxgeditor.event.ItemEditEvent;
	import fxgeditor.parser.IEditable;
	import fxgeditor.parser.style.*;
	import fxgeditor.parser.Path;
	import fxgeditor.parser.utils.StyleUtil;
	import fxgeditor.parser.model.PersistentData;
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.path.PathManager;
	import fxgeditor.ui.CreationBox;
	import fxgeditor.Constants;

	public class AbstractEditable extends Sprite implements IEditable
	{
		protected var _parentMatrix:Matrix;
		protected var _style:Style;
		protected var _controlLayer:Sprite;
		protected var _pathLayer:Sprite;
		protected var _creationBox:CreationBox;
		protected var _outline:Boolean = false;
		protected var _isMask:Boolean = false;
		
		public function AbstractEditable() 
		{
			this.doubleClickEnabled = true;
			this.addEventListener( Event.REMOVED_FROM_STAGE , remove );
		}
		
		public function applyMatrix():void 
		{
			if (!_style ) return;
			setMatrix( this.transform.matrix.clone() );
		}
		
		public function addMatrix( m:Matrix ):void 
		{
			if (!_style ) return;
			_style.addMatrix( m );
			this.transform.matrix = _style.getMatrix();
		}
		
		public function setMatrix( m:Matrix ):void 
		{
			if (!_style ) return;
			_style.setMatrix( m );
			this.transform.matrix = _style.getMatrix();
		}
		
		public function getMatrix():Matrix 
		{
			if ( !_style ) 
				return this.transform.matrix ? this.transform.matrix.clone() : new Matrix();
			return _style.getMatrix();
		}
		
		public function getParentMatrix():Matrix 
		{
			if ( this.parent && ( this.parent is IEditable ) )
				return IEditable( this.parent ).getGlobalMatrix();
			else
				return new Matrix();
		}
		
		public function getGlobalMatrix():Matrix
		{
			var matrix:Matrix = getMatrix();
			matrix.concat( getParentMatrix() );
			return matrix;
		}
		
		public function getRegistrationPoint():Point 
		{
			return getBounds( this.parent ).topLeft;
		}
		
		public function resize( scaleX:Number , scaleY:Number , center:Point = null ):void 
		{
			if ( !center ) 
				center = getRegistrationPoint();
				
			var matrix:Matrix = style.getMatrix();
			matrix.translate( -center.x, -center.y );
			matrix.scale( scaleX , scaleY );
			matrix.translate( center.x, center.y );
			setMatrix( matrix );
		}
		
		public function rotate( angle:Number , center:Point = null):void
		{
			if ( !center ) 
			{
				var bounds:Rectangle = this.getBounds( this.parent );
				center = bounds.topLeft;
				center.offset( bounds.width / 2 , bounds.height / 2 );
			}
				
			var matrix:Matrix = style.getMatrix();
			matrix.translate( -center.x , -center.y );
			matrix.rotate( angle );
			matrix.translate( center.x , center.y );
			setMatrix( matrix );
		}
		
		public function translate( x:Number , y:Number ):void
		{
			var matrix:Matrix = style.getMatrix();
			matrix.translate( x, y );
			this.setMatrix( matrix );
		}
		
		public function redraw():void { 
			throw new Error( "AbstractEditable.redraw "); 
		}
		public function edit():void { 
			throw new Error( "AbstractEditable.edit" ); 
		}
		public function exit():void { 
			throw new Error( "AbstractEditable.exit" ); 
		}
		
		public function getFxg():XML {
			throw new Error( "AbstractEditable.getFxg" ); 
		}
		
		public function outline( f:Boolean ):void
		{
			_outline = f;
			redraw();
		}
		
		public function removeFromStage():void
		{
			if ( parent ) parent.removeChild( this );
		}
		
		public function getPathManager():PathManager { return null; }
		
		public function getChildren():Vector.<IEditable>
		{
			if ( this.numChildren > 0 ) 
			{
				var children:Array = [];
				var numChildren:int = this.numChildren;
				for ( var i:int = 0; i < numChildren ; i++ ) 
				{
					var item:IEditable = this.getChildAt( i ) as IEditable;
					if ( item  ) children.push( item );
				}
				return Vector.<IEditable>( children );
			}
			return new Vector.<IEditable>;
		}
		
		public function getNumChildren():int 
		{
			return 0;
		}
		
		public function get style():Style { return _style;  }
		public function set style( s:Style ):void 
		{
			_style = s;
		}
		
		public function convertToPath():Path
		{
			if ( !convertible ) return null;
			var path:Path =  new Path();
			var d:String = getPathString();
			path.convertFrom( d, style );
			return path;
		}
		
		public function get convertible():Boolean { return false ; };
		
		public function get asContainer():DisplayObjectContainer{ return this as DisplayObjectContainer; }
		public function get asObject():DisplayObject { return this as DisplayObject; }
		
		public function get isMask():Boolean { return _isMask; }
		public function set isMask(value:Boolean):void {_isMask = value;}
		
		public function newPrimitive():void 
		{ 
			createControl();
			style = new Style();
			style.fill = PersistentData.getInstance().currentStyle.fill;
			style.stroke = PersistentData.getInstance().currentStyle.stroke;
			if ( !style.fill ) {
				style.fill = new SolidColor();
				IColor( style.fill ).color = StyleUtil.getRandomColor();
			}
			if ( !style.stroke ) {
				style.stroke =  new SolidColorStroke();
				IColor( style.stroke ).color = StyleUtil.getRandomColor();
				IStroke( style.stroke ).weight = Constants.DEFAULT_LINE_WIDTH;
			}
			
			_creationBox = new CreationBox( _controlLayer , _pathLayer );
			_creationBox.addEventListener( Event.CHANGE , onCreationUpdate );
			_creationBox.addEventListener( Event.COMPLETE , onCreationComplete );
		};
		
		public function cancelCreation():void
		{
			_creationBox.removeEventListener( Event.CHANGE , onCreationUpdate );
			_creationBox.removeEventListener( Event.COMPLETE , onCreationComplete );
			_creationBox.exit();
			removeControl();
			dispatchEvent( new ItemEditEvent( ItemEditEvent.CREATION_CANCELED ) );
			removeFromStage();
		}
		
		//Item Createion
		protected function onCreationUpdate( e:Event ):void { redraw(); }
		
		protected function onCreationComplete( e:Event ):void
		{
			_creationBox.removeEventListener( Event.CHANGE , onCreationUpdate );
			_creationBox.removeEventListener( Event.COMPLETE , onCreationComplete );
			_creationBox.exit();
			removeControl();
			dispatchEvent( new ItemEditEvent( ItemEditEvent.CREATION_COMPLETE ) );
		}
		
		protected function getPathString():String { return ""; }
		
		//Create Layers for Editing
		protected function createControl():void 
		{
			if ( !_controlLayer ) 
			{
				_pathLayer = new Sprite();
				_pathLayer.transform.matrix = getGlobalMatrix();
				PersistentData.getInstance().controlCanvas.addChild( _pathLayer );
				_controlLayer = new Sprite();
				PersistentData.getInstance().controlCanvas.addChild( _controlLayer );
			}
		}
		
		protected function removeControl():void 
		{
			try{
				_pathLayer.parent.removeChild( _pathLayer );
				_controlLayer.parent.removeChild( _controlLayer );
			}catch( e:Error ){ }
			_pathLayer = null;
			_controlLayer = null;
		}
		
		protected function applyStyle():void {
			_style.applyStyle( this );
			/*
			target.mask = null;
			target.filters = [];
			if ( !style ) return;
			if( setName ) target.name = style.id;
			target.alpha = style.opacity;
			if ( style.viewBox ) target.scrollRect = style.viewBox;
			
			if ( style.hasTransform ) 
			{
				var m:Matrix = target.transform.matrix.clone();
				m.concat( style.transform.getMatrix() );
				target.transform.matrix = m;
			}
			
			target.filters = [];
			if ( style.hasFilter ) 
			{
				var fl:FilterSet = style.getFilterSet();
				if ( fl ) 
				{
					fl.setSourceGraphic( target );
					target.filters = fl.getAllFilters();
				}
			}
			
			if ( style.hasClipPath ) {
				var maskobj:DisplayObject = PersistentData.getInstance().getClipPathById( style.clipPath_id );
				if ( maskobj ) 
				{
					var mtx:Matrix = maskobj.transform.matrix.clone();
					mtx.concat( getMatrix() );
					maskobj.transform.matrix = mtx;
					this.parent.addChild( maskobj );
					target.mask = maskobj;
				}
			}*/
		}
		
		protected function reset ( ):void 
		{
			if ( getNumChildren() ) 
			{
				var children:Vector.<IEditable> = getChildren();
				for each( var c:IEditable in children )
					c.removeFromStage();
			}
		}
		
		protected function remove( e:Event ):void
		{
			this.removeEventListener( Event.REMOVED_FROM_STAGE , remove );
			try{ exit(); } catch ( e:Error ){ }
		}
		
	}

}