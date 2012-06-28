package  fxgeditor
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.display.BlendMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ContextMenuEvent;
	import flash.filters.DisplacementMapFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.*;
	import fxgeditor.memento.Caretaker;
	import fxgeditor.memento.Memento;
	import fxgeditor.parser.filters.IFilter;
	import fxgeditor.parser.style.ColorType;
	import fxgeditor.parser.style.IGradient;
	import fxgeditor.ui.SelectionBox;
	
	import fxgeditor.parser.model.Data;
	import fxgeditor.parser.path.PathManager;
	import fxgeditor.parser.style.Style;
	import fxgeditor.ui.GradientBox;

	import fxgeditor.event.SelectionChangeEvent;
	import fxgeditor.event.ItemEditEvent;
	import fxgeditor.event.PathEditEvent;
	import fxgeditor.parser.*;
	import fxgeditor.parser.model.PersistentData;
	import fxgeditor.ui.DragItem;
	import fxgeditor.ui.BoundingBox;
	import fxgeditor.Constants;
	
	[Event(name = "selectionChange", type = "fxgeditor.event.SelectionChangeEvent")]
	[Event(name = "creationComplete", type = "fxgeditor.event.ItemEditEvent")]
	[Event(name = "creationCanceled", type = "fxgeditor.event.ItemEditEvent")]
	[Event(name = "pathEdit", type = "fxgeditor.event.PathEditEvent")]
	[Event(name = "pathEditFinish", type = "fxgeditor.event.PathEditEvent")]
	
	public class FxgEditor extends Sprite{
		
		private var _appStage:DisplayObject;
		private var _infoLayer:Sprite;
		
		private var _currentSelection:IEditable;
		private var _selectables:Vector.<IEditable>;
		private var _selections:Vector.<IEditable>
		private var _currentEditable:IEditable;
		private var _currentLayer:IEditable;
		private var _currentPrimitive:IEditable;
		
		private var _bounds:Vector.<BoundingBox>
		private var _gradientBox:GradientBox;
		private var _selectionBox:SelectionBox;
		private var _isEditMode:Boolean = false;
		private var _isSelectMode:Boolean = true;
		private var _multiSelMode:Boolean = false;
		private var _isOutline:Boolean = false;
		private var _dragStage:DragItem;
		private var _clipboard:XML;
		private var _styleClipboard:StyleObject;
		private var _histories:Caretaker;
		
		public function FxgEditor( xml:XML = null) 
		{ 
			if ( xml ) parse( xml );
			this.addEventListener( Event.ADDED_TO_STAGE, init );
		}
		
		public function newDocument( width:Number , height:Number ):void
		{
			var fxg:XML = <Graphic />;
			fxg.@viewHeight = height;
			fxg.@viewWidth = width;
			parse( fxg );
		}
		
		public function parse( fxg:XML ):void 
		{
			reset();
			
			var parser:FxgFactory = new FxgFactory();
			parser.addEventListener( Event.COMPLETE, onParseFinish );
			parser.parse( fxg , this );
		
			_infoLayer = new Sprite();
			addChild( _infoLayer );
			PersistentData.getInstance().controlCanvas = _infoLayer;
			
			_selectables = new Vector.<IEditable>();
			_bounds = new Vector.<BoundingBox>();
			editRoot();
		}
		
		public function reset():void
		{
			PersistentData.getInstance().reset();
			_histories = null;
			_infoLayer = null;
			_clipboard = null;
			_selectables = null;
			_selections = null;
			_currentEditable = null;
			_currentLayer = null;
			_bounds = null;
			_gradientBox = null;
			_selectionBox = null;
		}
		
		public function export():XML 
		{
			if( this.numChildren > 0 )
				return new FxgFactory().export( this.getChildAt( 0 ) as Graphic );
			return <Graphic />;
		}
		
		public function get appStage():DisplayObject 
		{ 
			if ( !_appStage ) _appStage = this;
			return _appStage; 
		}
		
		public function set appStage(value:DisplayObject):void 
		{
			_appStage = value;
		}
		
		public function zoom( scale:Number ):void 
		{
			if( scale > 0 )
				PersistentData.getInstance().currentZoom = this.scaleX = this.scaleY = scale;
		}
		
		public function zoomByMouse( scale:Number , center:Point = null  ):void 
		{
			scale += 1 - this.scaleX;
			if ( scale > 0 )
			{
				if ( !center ) center = new Point();
				var mat:Matrix = this.transform.matrix.clone() ;
				mat.translate( -center.x, -center.y );
				mat.scale( scale , scale );
				mat.translate( center.x, center.y );
				this.transform.matrix = mat;
				PersistentData.getInstance().currentZoom = this.scaleX;
			}
		}
		
		public function move( _x:Number, _y:Number ):void 
		{
			this.x = _x;
			this.y = _y;
		}
		
		public function stageDraggable():void 
		{
			if ( _dragStage ) return;
			_isSelectMode = false;
			appStage.addEventListener( MouseEvent.MOUSE_DOWN, dragStage );
			this.stage.addEventListener( MouseEvent.MOUSE_UP, endDragStage );
		}
		
		public function stageUndraggable( ):void 
		{
			_isSelectMode = true;
			appStage.removeEventListener( MouseEvent.MOUSE_DOWN, dragStage );
			this.stage.removeEventListener( MouseEvent.MOUSE_UP, endDragStage );
		}
		
		public function get currentSelectionName():String 
		{ 
			return 	_currentSelection ? _currentSelection.asObject.name : ""; 
		}
		
		public function get currentSelectionType():String 
		{ 
			return _currentSelection ? getQualifiedClassName( _currentSelection ).replace(/.+::(.+)/, "$1")  : "" ; 
		}
		
		public function get currentSelection():IEditable { return _currentSelection; }
		public function set currentSelection(value:IEditable):void 
		{
			if ( _currentSelection == value ) return;
			_currentSelection = value;
			_isEditMode = false;
			dispatchEvent( new SelectionChangeEvent );
			
			if ( !value ) return;
			var parent:IEditable = value.asContainer.parent as IEditable;
			if ( parent ) _currentLayer = parent;
			//setHistory();
		}
		
		public function get currentMode():int 
		{
			if ( _currentEditable ) return Constants.EDIT_MODE;
			if ( _currentSelection && _selections.length > 0 ) return Constants.SELECT_MODE;
			return Constants.IDLE_MODE;
		}

		//history
		public function undo():void
		{
			if ( !_histories || !_histories.hasItems ) return;
			var state:Memento =  _histories.getMemento( _histories.prevIndex );
			parseHistory( state );
		}
		
		public function redo():void
		{
			if (  !_histories || !_histories.hasItems ) return;
			var state:Memento =  _histories.getMemento( _histories.nextIndex );
			parseHistory( state );
		}
		
		//depth
		public function sendToBack():void 
		{
			if ( !_currentSelection ) return;
			_currentSelection.asContainer.parent.setChildIndex( _currentSelection.asObject , 0 );
			if ( _multiSelMode )
			{
				for each ( var item:IEditable in _selections )
					item.asContainer.parent.setChildIndex( item.asObject , 0 );
			}
		}
		
		public function bringToFront():void 
		{
			if ( !_currentSelection ) return;
			var parent:DisplayObjectContainer = _currentSelection.asContainer.parent;
			parent.setChildIndex( _currentSelection.asObject , parent.numChildren -1 );
			if ( _multiSelMode )
			{
				for each ( var item:IEditable in _selections )
					parent.setChildIndex( item.asObject , parent.numChildren -1  );
			}
		}
		
		public function unselectAll():void 
		{
			exitEditMode();
			removeCurrentSelectables();
			clearSelections();
			hideBound();
			editRoot();
		}
		
		public function deleteSelection():void 
		{
			if ( !_currentSelection ) return;
			addSelection( _currentSelection );
			hideBound();
			while ( _selections.length ) {
				var item:IEditable = _selections.pop();
				if ( !item ) continue;
				item.removeFromStage();
			}
		}
		
		public function deletePathPoint():void
		{
			_currentEditable.getPathManager().deleteCurrentPoint();
		}
		
		public function deletePathControlPoint( id:int ):void
		{
			_currentEditable.getPathManager().deleteCurrentControl( id );
		}
		
		public function toggleOutline():void
		{
			var fxg:Graphic = this.getChildAt( 0 ) as Graphic;
			fxg.outline( _isOutline = ! _isOutline );
		}
		
		public function copy():void 
		{
			if ( !_currentSelection  ) return;
			_clipboard = _currentSelection.getFxg();
			for each ( var item:XML in _clipboard.descendants() )
				item.setNamespace( Constants.fxg.uri );
		}
		
		public function paste():void
		{
			if ( !_clipboard  ) return;
			var data:Data = new Data( _clipboard , _currentLayer.asContainer );
			FxgFactory.parseData( data );
			setCurrentSelectables( _currentLayer );
		}
		
		public function getStyle():StyleObject 
		{
			if ( !_currentSelection ) return new StyleObject();
			return _currentSelection.style.getStyleObj();
		}
		
		public function setStyle( o:StyleObject ):void 
		{
			if ( !_currentSelection ) return;
			_currentSelection.style.parseStyleObj( o );
			_currentSelection.redraw();
			
			var gs:Style = PersistentData.getInstance().currentStyle;
			var ls:Style = _currentSelection.style;
			if ( ( !gs.fill || !ls.fill || gs.fill.colorType != ls.fill.colorType ) || 
				 ( !gs.stroke || !ls.stroke || gs.stroke.colorType != ls.stroke.colorType ) )
			{
				if ( _gradientBox && !( ls.fill is IGradient ) ) 
					_gradientBox.exit();
			}
			gs.parseStyleObj( o );
		}
		
		public function copyStyle():void
		{
			if ( !_currentSelection  ) return;
			_styleClipboard = _currentSelection.style.getStyleObj();
		}
		
		public function pasteStyle():void
		{
			if ( !_currentSelection || !_styleClipboard ) return;
			_currentSelection.style.parseStyleObj( _styleClipboard );
			_currentSelection.redraw();
			if ( _multiSelMode )
			{
				for each( var item:IEditable in _selections )
				{
					item.style.parseStyleObj( _styleClipboard );
					item.redraw();	
				}
			}
		}
		
		public function group():void
		{
			if ( ( _selections && !_selections.length ) && !_currentSelection ) return;
			var g:Group = new Group();
			g.newPrimitive();
			_currentLayer.asContainer.addChild( g.asObject );
			if ( !_selections ) clearSelections();
			if ( !_selections.length && _currentSelection ) _selections.push( _currentSelection );
			_selections.sort( function( a:IEditable, b:IEditable ):Number {
				return _currentLayer.asContainer.getChildIndex( a.asObject ) - _currentLayer.asContainer.getChildIndex( b.asObject );
			});
			g.setChildren( _selections );
			_multiSelMode = false;
			setCurrentSelectables( _currentLayer );
			hideBound();
			showBound( g , false );
			currentSelection = g;
		}
		
		public function ungroup():void
		{
			if ( ! ( _currentSelection is Group ) ) return;
			var g:DisplayObjectContainer = _currentSelection.asContainer;
			var mat:Matrix = _currentSelection.getMatrix();
			var children:Vector.<IEditable> = _currentSelection.getChildren();
			for each ( var item:IEditable in children )
			{
				g.removeChild( item.asObject );
				g.parent.addChild( item.asObject );
				item.addMatrix( mat );
			}
			setCurrentSelectables( g.parent as IEditable );
			g.parent.removeChild( g );
			hideBound();
		}
		
		public function setClippingPath():void
		{
			if ( !_currentSelection || !_selections.length ) return;
			var index:int = _selections.indexOf( _currentSelection ); //remove currentSelection
			_selections.splice( index , 1 );

			var mask:IEditable = _currentSelection;
			var item:IEditable = _selections[0];
			clearSelections();
			_selections.push( mask );
			group();
			mask = _currentSelection;
			var mat:Matrix = item.getMatrix();
			mat.invert();
			mask.addMatrix( mat );
			
			item.style.setMask( mask.getFxg() );
			item.redraw();
			mask.removeFromStage();
		}
		
		public function removeClippingPath():void
		{
			if ( !_currentSelection || !_currentSelection.style.hasMask ) return;
			
			var item:IEditable = _currentSelection;
			var mask:IEditable = _currentSelection.style.removeMask();
			if ( mask ) {
				mask.removeFromStage();
				item.asContainer.parent.addChild( mask.asObject );
				mask.addMatrix( item.getMatrix() );
				_currentSelection = mask;
				ungroup();
			}
			item.redraw();
		}
		
		//create new item
		public function addPrimitive( className:String ):void	//Class name for IEditable
		{
			if ( !_isSelectMode ) return;
			if ( _currentPrimitive ) cancelCreation();
			var Item:Class = getDefinitionByName( "fxgeditor.parser::" + className ) as Class;
			var item:IEditable = new Item();
			_currentLayer.asContainer.addChild( item.asObject );
			item.newPrimitive();
			item.addEventListener( ItemEditEvent.CREATION_COMPLETE, onItemCreated );
			item.addEventListener( ItemEditEvent.CREATION_CANCELED, onCreationCanceled );
			_isSelectMode = false;
			_currentPrimitive = item;
		}
		
		public function drawPath():void
		{
			var item:Path = new Path();
			_currentLayer.asContainer.addChild( item.asObject );
			item.newDrawing();
			item.addEventListener( ItemEditEvent.CREATION_COMPLETE, onItemCreated );
			item.addEventListener( ItemEditEvent.CREATION_CANCELED, onCreationCanceled );
			_isSelectMode = false;
			_currentPrimitive = item;
		}
		
		public function mixPath():void
		{
			if ( !_currentSelection || !( _currentSelection is Path ) ) return;
			var path1:Path = _currentSelection as Path;
			var path2:Path;
			for each( var item:IEditable in _selections )
			{
				if ( item is Path && item != _currentSelection )
				{
					path2 = item as Path;
					break;
				}
			}
			if ( !path2 ) return;
			path1.mixPath( path2 );
			path2.asContainer.parent.removeChild( path2.asObject );
			setCurrentSelectables( _currentLayer );
		}
		
		public function convertToPath():void
		{
			if ( !_currentSelection || !_currentSelection.convertible ) return;
			var path:IEditable = _currentSelection.convertToPath();
			_currentLayer.asContainer.addChild( path.asObject );
			_currentLayer.asContainer.swapChildren( path.asObject , _currentSelection.asObject );
			_currentSelection.removeFromStage();
			setCurrentSelectables( _currentLayer );
			currentSelection = path;
			clearSelections();
		}
		
		public function editGradientMatrix( editStroke:Boolean = false ):void 
		{
			if ( !_currentSelection ) return;
			if ( _gradientBox ) _gradientBox.exit();
			if ( _currentSelection.style.hasGradientFill || _currentSelection.style.hasGradientStroke ) 
				_gradientBox = new GradientBox( _infoLayer , _currentSelection.asObject , editStroke );
		}
		
		public function cancelCreation():void 
		{
			if (_currentPrimitive )
				_currentPrimitive.cancelCreation();
		}

		//Private
		private function init( e:Event = null ):void
		{
			this.removeEventListener( Event.ADDED_TO_STAGE, init );
			this.addEventListener( Event.REMOVED_FROM_STAGE, exit );
			this.stage.addEventListener( MouseEvent.MOUSE_DOWN, onEmptySpaceClicked );
			this.stage.addEventListener( MouseEvent.MOUSE_UP, setHistory );
			editRoot();
		}
		
		private function exit( e:Event ):void 
		{
			this.removeEventListener( Event.REMOVED_FROM_STAGE, exit );
			this.stage.removeEventListener( MouseEvent.MOUSE_DOWN, onEmptySpaceClicked );
			stageUndraggable();
		}
		
		private function dragStage( e:MouseEvent ):void 
		{
			_dragStage = new DragItem( this as DisplayObject );
		}
		
		private function endDragStage( e:MouseEvent ):void 
		{
			if ( _dragStage ) _dragStage.exit();
			_dragStage = null;
		}
		
		private function editRoot():void 
		{
			if ( !this.numChildren ) return;
			var svgRoot:IEditable = this.getChildAt(0) as IEditable;
			setCurrentSelectables( svgRoot );
			_currentLayer = svgRoot;
			_multiSelMode = false;
		}

		private function setCurrentSelectables( s:IEditable ):void 
		{
			if ( s.getNumChildren() <= 0 ) 	//EDIT MODE
			{
				_currentEditable = s;
				if ( _currentEditable ) {
					_currentEditable.removeEventListener( MouseEvent.MOUSE_DOWN, onItemClick );
					_currentEditable.edit();
					currentSelection = _currentEditable;
				}
				return;
			}
			
			removeCurrentSelectables();
			if ( s.getNumChildren() <= 0 ) return;
			var children:Vector.<IEditable> = s.getChildren();
			for each( var item:IEditable in children ) 	//MAKE ITEMS SELECTABLE
			{
				_selectables.push( item );
				item.addEventListener( MouseEvent.MOUSE_DOWN, onItemClick );
				item.addEventListener( MouseEvent.DOUBLE_CLICK, enterEditMode );
			}
			_currentLayer = s;
			_currentLayer.edit();
		}
		
		private function removeCurrentSelectables():void 
		{
			for each ( var item:IEditable in _selectables ) 
			{
				item.removeEventListener( MouseEvent.MOUSE_DOWN, onItemClick );
				item.removeEventListener( MouseEvent.DOUBLE_CLICK, enterEditMode );
			}
			_selectables = new Vector.<IEditable>();
			if( _currentLayer ) _currentLayer.exit();
		}
		
		private function onItemClick( e:MouseEvent ):void 
		{
			_multiSelMode = e.shiftKey;
			if ( !_multiSelMode ) clearSelections();
			selectItem( e.currentTarget as IEditable );
		}
		
		private function selectItem( item:IEditable , draggable:Boolean = true ):void 
		{	
			if ( !_isSelectMode || (item is Graphic) ) return;
			if ( !_multiSelMode || !_selections ) clearSelections();
			if ( currentSelection  ) addSelection( _currentSelection );
			hideBound();
			currentSelection =  item;
			if ( _multiSelMode )
			{
				toggleSelection( item );
				for each( var sel:IEditable  in _selections )
					showBound( sel , false );
				
				if ( draggable ) 
					draggableSelections();
			}
			else
			{
				showBound( item , draggable );
				clearSelections();
			}
			
			if ( _currentEditable != item ) 
				exitEditMode();
		}
		
		private function enterEditMode( e:MouseEvent ):void 
		{
			if ( _currentEditable == e.currentTarget ) return;
			var localItem:IEditable = e.currentTarget as IEditable;
			if ( !localItem ) {	//empty space clicked
				editRoot();
				return;
			}
			hideBound();
			setCurrentSelectables( localItem );
		}
		
		private function exitEditMode():void 
		{
			if ( !_currentEditable ) return;
			_currentEditable.exit();
			_currentEditable.addEventListener( MouseEvent.MOUSE_DOWN, onItemClick );
			_currentEditable = null;
			setHistory();
		}
		
		private function onItemCreated( e:ItemEditEvent ):void 
		{
			e.currentTarget.removeEventListener( ItemEditEvent.CREATION_COMPLETE, onItemCreated );
			e.currentTarget.removeEventListener( ItemEditEvent.CREATION_CANCELED, onCreationCanceled );
			setCurrentSelectables( _currentLayer );
			_isSelectMode = true;
			_currentPrimitive = null;
			selectItem( e.currentTarget as IEditable , false );
			dispatchEvent( e );
		}
		
		private function onCreationCanceled( e:ItemEditEvent ):void 
		{
			e.currentTarget.removeEventListener( ItemEditEvent.CREATION_COMPLETE, onItemCreated );
			e.currentTarget.removeEventListener( ItemEditEvent.CREATION_CANCELED, onCreationCanceled );
			setCurrentSelectables( _currentLayer );
			_isSelectMode = true;
			_currentPrimitive = null;
			dispatchEvent( e );
		}
		
		private function onEmptySpaceClicked( e:MouseEvent ):void 
		{
			if ( ( e.target is Graphic ) || e.target == appStage )
			//	 ( _currentLayer is Group && _selectables.indexOf( e.target ) == -1 ) ) 
			{
				unselectAll();

				if ( !_isSelectMode ) return;
				_selectionBox = new SelectionBox( _infoLayer );
				_selectionBox.addEventListener( Event.COMPLETE , dragSelectComplete );
			}
		}
		
		private function dragSelectComplete( e:Event ):void
		{
			_multiSelMode = true;
			currentSelection = null;
			var items:Vector.<IEditable> = _currentLayer.getChildren();
			for each( var item:IEditable in items )
			{
				if ( item.asObject.hitTestObject( _selectionBox ) )
					selectItem( item , false );
			}
			_selectionBox.exit();
		}
		
		private function toggleSelection( item:IEditable ):void
		{
			if ( _selections.indexOf( item ) == -1 )
				addSelection( item );
			else 
				removeSelection( item );
		}
		
		private function addSelection( item:IEditable ):void
		{
			if ( _selections.indexOf( item ) == -1 )
				_selections.push( item );
		}
		
		private function removeSelection( item:IEditable ):void
		{
			if ( _selections.indexOf( item ) == -1 ) return;
			_selections.splice( _selections.indexOf( item ) , 1 );
			currentSelection = _selections.length ? _selections[0] : null;
		}
		
		private function clearSelections():void
		{
			_selections = new Vector.<IEditable>();
			_multiSelMode = false;
		}
		
		private function draggableSelections():void
		{
			for each( var box:BoundingBox in _bounds )
				box.draggable();
		}
		
		//history
		private function setHistory( e:MouseEvent=null ):void
		{
			if ( !_currentSelection ) return;
			if ( !_histories ) _histories = new Caretaker();
			_histories.addMemento( new Memento( _currentSelection , _currentSelection.getFxg() ));
		}
		
		
		private function parseHistory( state:Memento ):void
		{
			if ( !state ) return;
			var instance:IEditable = state.instance;
			var parent:DisplayObjectContainer = instance.asContainer.parent;
			if ( instance is Graphic || !parent ) return;
			var data:Data = new Data( state.xml, instance.asContainer.parent );
			IParser( instance ).parse( data );
			
			hideBound();
		}

		//Bounds
		private function showBound( o:IEditable , draggable:Boolean = true ):void 
		{
			for each( var box:BoundingBox in _bounds )
				if ( box.editItem == o ) return;
			
			_bounds.push( new BoundingBox( _infoLayer, o , draggable ) );
		}
		
		private function hideBound( e:Event = null ):void 
		{
			while ( _bounds.length ) 
			{
				var b:BoundingBox = _bounds.pop();
				b.exit();
			}
			if ( _gradientBox ) _gradientBox.exit();
			_gradientBox = null;
		}
		
		private function getRootMatrix():Matrix 
		{
			var mat:Matrix = this.transform.matrix.clone();
			if ( this.parent ) 
				mat.concat( this.parent.transform.matrix.clone() );
			return mat;
		}
		
		private function onParseFinish( e:Event ):void
		{
			dispatchEvent( e );
		}
		
	}
	
}