import { UIElement } from './UIElement';
import * as Accessibility  from '../Accessibility/index';

export class UIApp extends UIElement {
private _activeElement;

constructor( element )
{
if( element == "active" ) {
element = Accessibility.getFrontmostApp();
} else if( element == "system" ) {
element = Accessibility.getSystemApp();
}
else if( typeof element != 'number' ) throw new Error( "Invalid pid" );

super( element );
}

get activeElement()
{
if( this._activeElement ) return this._activeElement;
return new UIElement( this.getAttributeForSelf( 'focusedUIElement' ) );
};

set activeElement( element )
{
if( !element ) return;
let result = false;

if( element.role == "window" )
{
result = element.performAction( 'AXRaise' );
}
else
{
element.window.performAction( 'AXRaise' );
result = Accessibility.setFocusedUIElement( this._element, element.memoryAddress );
}
this._activeElement = element;
};

get parentNode() { return undefined };


public resolveElementAtPath( path: [string] ): UIElement|undefined {
let pathFinder = this;

for( const stone of path )
{

if( pathFinder )
{
const [ roleName, index ] = stone.split( "#" );

pathFinder = pathFinder.getChildrenWithPlatformRole( roleName )[index];
}

}

if( pathFinder ) return pathFinder;
return undefined;
};

};
