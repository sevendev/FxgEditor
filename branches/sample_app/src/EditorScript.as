import flash.display.*;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.text.engine.FontLookup;
import flash.net.*;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.KeyboardEvent;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;
import flash.ui.Keyboard;
import mx.core.IFlexDisplayObject;
import mx.controls.ProgressBar;
import mx.events.ItemClickEvent;
import mx.events.MenuEvent;
import mx.managers.IFocusManager;
import mx.managers.PopUpManager;
import mx.controls.Alert;
import mx.core.FlexGlobals;
import mx.resources.ResourceManager;
import fxgeditor.parser.Path;
import fxgeditor.FxgEditor;
import fxgeditor.parser.IEditable;
import fxgeditor.event.SelectionChangeEvent;
import fxgeditor.event.ItemEditEvent;
import fxgeditor.event.PathEditEvent;
import fxgeditor.Constants;
import component.*;
import component.custom.preloader.LoadingBar;
import event.PanelEvent;
import event.ServiceEvent;
import event.StyleChangeEvent;
import event.InfoPanelEvent;
import event.ToolPaletteEvent;

public var fxgurl:String;
public var approot:String;
public var imageloaderurl:String;

public var fxg:XML;
public var editor:FxgEditor;
public var popup:StylePanel;
public var loading:LoadingBar;
public var infoPanel:InfoPanel;
public var toolBox:ToolPalette;

private var _menu:ContextMenu;
private var _defaultMenuItems:Array;

private function init() :void 
{
	setLocale( getLocalLang() );

	fxgurl = FlexGlobals.topLevelApplication.parameters.url;
	approot = FlexGlobals.topLevelApplication.parameters.approot;
	imageloaderurl = FlexGlobals.topLevelApplication.parameters.imgload;
	
	if ( !approot ) approot = EditorConstants.SERVER_URL;
	if ( fxgurl ) loadData( fxgurl );
}

private function loadData( url:String ):void 
{
	showLoading();
	XML.ignoreWhitespace = false;
	svc.load( url );
}

private function onLoad( e:ServiceEvent ):void 
{
	fxg = XML( e.result );
	displayHack();
	displayData();
}

private function displayHack():void
{
	if ( !imageloaderurl ) return;
	var sources:XMLList = fxg..@source;
	for each( var src:XML in sources )
		src = src.replace( /\@Embed\(\'http:\/\/(.+)\'\)/ , imageloaderurl + "$1" );
}

private function onParseComplete( e:Event ):void 
{
	hideLoading();
}

private function initEditor():void
{
	if ( editor ) mainCanvas.removeChild( editor );
	editor = new FxgEditor();
	editor.addEventListener( Event.COMPLETE, onParseComplete );
	editor.addEventListener( SelectionChangeEvent.SELECTION_CHANGE, setCurrentName );
	editor.addEventListener( ItemEditEvent.CREATION_COMPLETE, onItemCreated );
	editor.addEventListener( ItemEditEvent.CREATION_CANCELED, onItemCreated );
	editor.addEventListener( PathEditEvent.PATH_EDIT, onPathEdit );
	editor.appStage = this.skin;
	mainCanvas.addChild( editor );
	this.stage.addEventListener( KeyboardEvent.KEY_UP, onKeyPress );
	this.stage.addEventListener( MouseEvent.MOUSE_WHEEL , onMouseWheel );
	createRightMenu();
	createToolPalette();
}

private function displayData():void 
{
	initEditor();
	editor.parse( fxg );
}

private function resize( e:Event ):void
{
	if ( !editor ) return;
	editor.zoom( e.currentTarget.value );
}

private function setCurrentName( e:SelectionChangeEvent ):void 
{
	showMenu( editor.currentSelectionType );
}

private function sendToBack():void 
{
	editor.sendToBack();
}

private function BringToFront():void 
{
	editor.bringToFront();
}

private function deleteSelection():void 
{
	editor.deleteSelection();
}

private function onMouseWheel( e:MouseEvent ):void 
{
	if ( isPanelActive() ) return;
	var value:Number =  editor.scaleX + e.delta * .05;
	editor.zoomByMouse( value , new Point( this.mouseX, this.mouseY ) );
	zoomSlider.value = value;
}

private function onKeyPress( e:KeyboardEvent ):void 
{
	if ( isPanelActive() ||
	   ( editor && editor.currentMode == Constants.EDIT_MODE ) ) return;
	
	if (  e.ctrlKey && e.keyCode == 67 ) //Control + C
		editor.copy();
		
	if (  e.ctrlKey && e.keyCode == 86 ) //Control + V
		editor.paste();
		
	if (  e.ctrlKey && e.keyCode == 90 ) //Control + Z
		editor.undo();
		
	if (  e.ctrlKey && e.keyCode == 89 ) //Control + Y
		editor.redo();
	
	if ( e.keyCode == Keyboard.BACKSPACE || e.keyCode == Keyboard.DELETE ) 
		editor.deleteSelection();
		
	if ( e.keyCode == Keyboard.SPACE ) 
		toggleDragStage();
}

private function createToolPalette():void 
{
	if ( !toolBox ) 
	{
		var gap:Number = 10;
		
		toolBox = PopUpManager.createPopUp( this, ToolPalette ) as ToolPalette;
		toolBox.addEventListener( ToolPaletteEvent.CREATE_ITEM , createItem );
		toolBox.addEventListener( ToolPaletteEvent.DRAW_PATH , drawPath );
		toolBox.addEventListener( ToolPaletteEvent.SHOW_CODE , showCodePanel );
		toolBox.addEventListener( ToolPaletteEvent.CANCEL_ALL , cancelCreation );
		toolBox.move( gap , appBox.contentToGlobal( new Point() ).y );
		
		toolBox.addEventListener( Event.RESIZE , function( e:Event ):void {
			editor.move( toolBox.width + gap * 2  , 0 );
			e.currentTarget.removeEventListener( Event.RESIZE , arguments.callee );
		});
	}
	editor.move( toolBox.width  , 0 );
}

private function showCodePanel( e:ToolPaletteEvent ):void
{
	showInfoPanel( "code" );
}

private function createItem( e:ToolPaletteEvent ):void 
{
	if ( panBtn.selected ) toggleDragStage();
	editor.addPrimitive( e.itemType );
	toolBox.releaseSelection();
}

private function drawPath( e:ToolPaletteEvent ):void 
{
	if ( panBtn.selected ) toggleDragStage();
	editor.drawPath();
}

private function cancelCreation( e:ToolPaletteEvent ):void 
{
	editor.cancelCreation();
}

private function onItemCreated( e:ItemEditEvent ) :void 
{
	toolBox.releaseSelection();
}

private function onPathEdit( e:PathEditEvent ):void
{
	if( e.editPoint.isEditablePoint() )
		addPathEditMenuItems();
}

private function toggleDragStage():void 
{
	if ( !editor ) return;
	panBtn.selected = !( panBtn.selected );
	panBtn.selected ? dragStage(): endDragStage();
}

private function dragStage():void 
{
	editor.unselectAll();
	editor.stageDraggable();
}

private function endDragStage():void 
{
	editor.stageUndraggable();
	editor.unselectAll();
}

//Right Click Menu
private function createRightMenu():void 
{
	var itemB2F:ContextMenuItem = new ContextMenuItem( resourceManager.getString( "App", "BringToFront" ), true );
	itemB2F.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.bringToFront();
	});
	var itemS2B:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "SendToBack") );
	itemS2B.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.sendToBack();
	});
	var itemGrp:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "Group")  , true );
	itemGrp.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.group();
	});
	var itemUnGrp:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "UnGroup") );
	itemUnGrp.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.ungroup();
	});
	var itemOutline:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "Outline") , true  );
	itemOutline.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.toggleOutline();
	});	
	var itemCopy:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "Copy" ), true );
	itemCopy.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.copy();
	});	
	var itemPaste:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "Paste"  ) );
	itemPaste.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.paste();
	});	
	var itemStyleCopy:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "CopyStyle" ), true );
	itemStyleCopy.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.copyStyle();
	});	
	var itemStylePaste:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "PasteStyle" ) );
	itemStylePaste.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.pasteStyle();
	});
	var itemDel:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "Delete"  ), true );
	itemDel.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.deleteSelection();
	});
	
	_defaultMenuItems = [ itemB2F, itemS2B ,itemGrp ,itemUnGrp , itemOutline , itemCopy , itemPaste , itemStyleCopy, itemStylePaste,  itemDel ];
	resetRightMenu();
}

private function addMenuItem( item:ContextMenuItem ):void {
	for each( var i:ContextMenuItem in _menu.customItems )
		if ( i.caption == item.caption ) return;
	_menu.customItems.unshift( item );
}

private function resetRightMenu():void 
{
	if ( !_menu )
	{
		_menu = new ContextMenu();
		_menu.hideBuiltInItems();
		//this.contextMenu = _menu;
		FlexGlobals.topLevelApplication.contextMenu = _menu;
	}
	_menu.customItems = [];
	for each( var item:ContextMenuItem in _defaultMenuItems )
		_menu.customItems.push( item );
}

private function addPathConvMenuItems():void 
{
	var pathItem:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "ConvertToPath" ) );
	pathItem.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.convertToPath();
		e.currentTarget.removeEventListener( ContextMenuEvent.MENU_ITEM_SELECT, arguments.callee );
		resetRightMenu();
	});
	
	addMenuItem( pathItem );
}

private function addPathMenuItems():void 
{
	var mixP:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "MixPath" ) );
	mixP.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.mixPath();
	});
	
	addMenuItem( mixP );
}

private function addPathEditMenuItems():void 
{
	var pathEditItem:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "DeleteEditPoint" ));
	pathEditItem.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.deletePathPoint();
		e.currentTarget.removeEventListener( ContextMenuEvent.MENU_ITEM_SELECT, arguments.callee );
		resetRightMenu();
	});
	var pathEditItem1:ContextMenuItem = new ContextMenuItem( resourceManager.getString("App", "DeleteControlPoint" ));
	pathEditItem1.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, function ( e:ContextMenuEvent ):void {
		editor.deletePathControlPoint( 0 );
		e.currentTarget.removeEventListener( ContextMenuEvent.MENU_ITEM_SELECT, arguments.callee );
		resetRightMenu();
	});
	
	addMenuItem( pathEditItem1 );
	addMenuItem( pathEditItem );
}

//Panel
private function showMenu( type:String ):void
{
	var lastPosition:Point;
	
	resetRightMenu();

	if ( popup ) 
	{
		lastPosition = new Point( DisplayObject( popup ).x , DisplayObject( popup ).y  );
		popup.removeEventListener( StyleChangeEvent.STYLE_CHANGE , setSelectionStyle );
		popup.removeEventListener( StyleChangeEvent.STYLE_CHANGE , setSelectionStyle );
		popup.removeEventListener( PanelEvent.EDIT_FILL_GRADIENT, editFillGradientMatrix );
		popup.removeEventListener( PanelEvent.EDIT_STROKE_GRADIENT, editStrokeGradientMatrix );
		PopUpManager.removePopUp( popup );
		popup = null;
	}
	
	switch ( type ) 
	{
		case "Ellipse" :
		case "Rect" :
		case "Line" :
			addPathConvMenuItems();
			popup = PopUpManager.createPopUp( this, PathPanel  ) as StylePanel;
		break;
		case "Path" :
			addPathMenuItems();
			popup = PopUpManager.createPopUp( this, PathPanel  ) as StylePanel;
		break;
		case "Group" :
			popup = PopUpManager.createPopUp( this, GroupPanel  ) as StylePanel;
		break;
		case "TextGraphic" :
		case "RichText" :
			popup = PopUpManager.createPopUp( this, TextPanel  ) as StylePanel;
		break;
		case "BitmapImage" :
		case "BitmapGraphic" :
			popup = PopUpManager.createPopUp( this, ImagePanel  ) as StylePanel;
		break;
	}
	
	if ( popup ) {
		popup.setItemStyle( editor.getStyle() );
		popup.type = type;
		popup.addEventListener( StyleChangeEvent.STYLE_CHANGE , setSelectionStyle  );
		popup.addEventListener( PanelEvent.EDIT_FILL_GRADIENT, editFillGradientMatrix );
		popup.addEventListener( PanelEvent.EDIT_STROKE_GRADIENT, editStrokeGradientMatrix );
		if ( lastPosition && lastPosition.x + popup.measuredWidth < this.stage.stageWidth ) 
			popup.move( lastPosition.x , lastPosition.y );
		else
			popup.move( this.stage.stageWidth - DisplayObject( popup ).width - 30 , mainCanvas.y );
	}
}

private function setSelectionStyle( e:StyleChangeEvent ):void
{
	editor.setStyle( e.styleobj );
	//editor.applyStyle();
	e.stopPropagation();
}

private function editFillGradientMatrix( e:PanelEvent ):void 
{
	editor.editGradientMatrix();
	if (popup ) popup.setItemStyle( editor.getStyle() );
}

private function editStrokeGradientMatrix( e:PanelEvent ):void 
{
	editor.editGradientMatrix(true);
	if (popup ) popup.setItemStyle( editor.getStyle() );
}

private function showInfoPanel( type:String ):void 
{
	var Panel:Class;
	switch( type ) {
		case "save" : Panel = SavePanel;
		break;
		case "help" : Panel = HelpPanel;
		break;
		case "code" : Panel = CodePanel;
		break;
		case "doc" : Panel = DocumentPanel;
		break;
	}
	infoPanel = PopUpManager.createPopUp( this, Panel, true ) as InfoPanel;
	PopUpManager.centerPopUp( infoPanel );
	infoPanel.addEventListener( InfoPanelEvent.ON_SAVE_CLICK , save );
	infoPanel.addEventListener( InfoPanelEvent.ON_CODE_CHANGE , changeCode );
	infoPanel.addEventListener( InfoPanelEvent.ON_CREATE , createNewDocument );
	infoPanel.addEventListener( InfoPanelEvent.ON_CLOSE , closeInfoPanel );
}

private function closeInfoPanel( e:InfoPanelEvent = null ):void 
{
	infoPanel.removeEventListener( InfoPanelEvent.ON_SAVE_CLICK , save );
	infoPanel.removeEventListener( InfoPanelEvent.ON_CODE_CHANGE , changeCode );
	infoPanel.removeEventListener( InfoPanelEvent.ON_CREATE , createNewDocument );
	infoPanel.removeEventListener( InfoPanelEvent.ON_CLOSE , closeInfoPanel );
	PopUpManager.removePopUp( infoPanel );
	infoPanel = null;
}

private function isPanelActive():Boolean
{
	return ( ( popup && popup.hitTestPoint( this.mouseX, this.mouseY ) ) ||
			 ( infoPanel && infoPanel.hitTestPoint( this.mouseX, this.mouseY ) ) );
}

private function changeCode( e:InfoPanelEvent ):void
{
	fxg = XML( e.code );
	displayData();
}

private function createNewDocument( e:InfoPanelEvent ):void
{
	initEditor();
	editor.newDocument( e.documentWidth , e.documentHeight );
	resetRightMenu();
	closeInfoPanel();
}

private function save( e:InfoPanelEvent ):void 
{
	closeInfoPanel();
	showLoading( EditorConstants.SAVE_LABEL_TEXT );
	var fxg:XML = editor.export();
	svc.save( e.title , fxg );
}

private function onSave( e:ServiceEvent ):void
{
	hideLoading();
	Alert.show( XML( e.result )..result.toString() , "Saved"  );
}

private function onFault( e:ServiceEvent ):void
{
	hideLoading();
	Alert.show( e.message, "Error" );
}

private function showLoading( label:String = EditorConstants.LOAD_LABEL_TEXT ):void
{
	loading = PopUpManager.createPopUp( this, LoadingBar, true ) as LoadingBar;
	loading.labelText = label;
	PopUpManager.centerPopUp( loading );
}

private function hideLoading():void
{
	PopUpManager.removePopUp( loading );
}

private function menuClicked( e:MenuEvent ):void
{
	var action:String = e.item .@action.toString();
	
	switch( action )
	{
		case "New" : showInfoPanel( 'doc' );
		break;
		case "Reset" : loadData(  fxgurl );
		break;
		case "Load" : svc.loadFile();
		break;
		case "AirLoad" :  svc.showLoadDialog();
		break;
	}
	
	if ( !editor ) return;
	
	switch( action )
	{
		case "Save" : showInfoPanel('save');
		break;
		case "AirSave" : svc.showSaveDialog( editor..export() );
		break;
		case "Undo" : editor.undo();
		break;
		case "Redo" : editor.redo();
		break;
		case "Copy" : editor.copy();
		break;
		case "Paste" : editor.paste();
		break;
		case "CopyStyle" : editor.copyStyle();
		break;
		case "PasteStyle" : editor.pasteStyle();
		break;
		
		case "Group" : editor.group();
		break;
		case "UnGroup" : editor.ungroup();
		break;
		case "BringToFront" : editor.bringToFront();
		break;
		case "SendToBack" : editor.sendToBack();
		break;
		case "SetClipping" : editor.setClippingPath();
		break;
		case "removeClipping" : editor.removeClippingPath();
		break;
		case "Outline" : editor.toggleOutline();
		break;
		case "Delete" : editor.deleteSelection();
		break;
		
		case "ConvertToPath" : editor.convertToPath();
		break;
		case "MixPath" : editor.mixPath();
		break;
		case "DeleteEditPoint" : editor.deletePathPoint();
		break;
		case "DeleteControlPoint" : editor.deletePathControlPoint( 0 );
		break;
	}
}

//Locale
private function setLocale( locale:String ):void
{
	resourceManager.localeChain = [locale];
	resourceManager.update();
}

private function getLocalLang():String {
	return ( Capabilities.language == "ja" ) ? "ja_JP" : "en_US" ;
}