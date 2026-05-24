import * as Accessibility from '../Accessibility/index';
import { UIApp } from './UIApp';

export class UIElement {
_element;

constructor( element )
{
if( !element ) throw new Error( "Missing element reference" );
this._element = element
}

get children()
{
let children = [];
const rawChildren = this.getAttributeForSelf( 'childrenInNavigationOrder' );
if( !rawChildren ) return [];
for( const child of rawChildren )
{
if( child ) children.push( new UIElement( child ) );
}
return children.filter( child => !child.getAttribute( 'hidden' ) || ( child.getAttribute( 'hidden' ) != true ) );
};

get firstChild()
{
return this.children[0] || null;
};

get memoryAddress()
{
return this._element;
};

get nextSibling()
{
return this.getSibling( 1 );
};

get parentNode()
{
try {
let memoryAddress = Accessibility.getAttributeForElementByName( this._element, 'parent' );
let uiObject = new UIElement( memoryAddress );
if( uiObject.getAttribute( 'role' ) == "application" ) return this.getApp();
return uiObject;
} catch( error ) {
return undefined;
}
}

get previousSibling()
{
return this.getSibling( -1 );
};

get role()
{
return this.getAttributeForSelf( 'role' ).toLowerCase();
}

get window()
{
let memoryAddress = this.getAttributeForSelf( 'window' );
if( memoryAddress ) return new UIElement( memoryAddress );
return null;
};

public focus()
{
if( this.role == "application" && global && global.uiManager )
{
global.uiManager.app = this;
}
else if( global && global.uiManager && global.uiManager.app )
{
global.uiManager.app.activeElement = this;
}

};

public getAttribute( attributeName )
{
return this.getAttributeForSelf( attributeName );
}

public getAttributeNames()
{
return Accessibility.getAttributesForElement( this._element );
};

protected matchElements( e1, e2 )
{
let e1Position = e1.getAttribute( 'position' );
let e2Position = e2.getAttribute( 'position' );

let e1Size = e1.getAttribute( 'size' );
let e2Size = e2.getAttribute( 'size' );

let e1Role = e1.getAttribute( 'role' );
let e2Role = e2.getAttribute( 'role' );

if( e1Role && e2Role && ( e1Role == e2Role ) && e1Position && e2Position && ( e1Position.x == e2Position.x ) && ( e1Position.y == e2Position.y ) && e1Size && e2Size && ( ( e1Size.height == e2Size.height ) || ( e1Size.width == e2Size.width ) ) )
{
return true;
};
return false;
}

protected getAttributeForSelf( attributeName: string ): any {
if( !this.getAttributeNames().includes( attributeName ) ) return null;
let result = Accessibility.getAttributeForElementByName( this._element, attributeName );
if( !result ) return undefined;
return result;
};

private getSibling( offset: number ) {
if( !this.parentNode ) return null;

let siblingIndex;
let siblings = this.parentNode.children || [];
for( let index=0;index<siblings.length;index++ )
{
if( this.matchElements( this, siblings[index] ) )
{
siblingIndex = index+offset;
break;
}

}
if( ( siblingIndex >= 0 ) && ( siblingIndex < siblings.length ) )
{
return  siblings[(siblingIndex)];
}
return null;
};

public getChildrenWithPlatformRole( roleName ) {
roleName = Accessibility.getCamelCase( roleName );
return this.children.filter( child => child.getAttribute( "role" ) == roleName );
};

public hasSiblings() {
if( this.parentNode && this.parentNode.children.length > 1 ) return true;
return false;
};

public performAction( actionName )
{
return Accessibility.performActionForElement( this._element, actionName );
};

private getApp() {
if( global && global.uiManager && global.uiManager.app ) return global.uiManager.app;
return undefined;
};

public compute_aria_label()
{
let label = this.getAttributeForSelf( 'title' ) || this.getAttributeForSelf( 'description' );
if( label ) return label;
if( this.getAttributeForSelf( 'value' ) != undefined ) return String( this.getAttributeForSelf( 'value' ) );
let description = this.getAttributeForSelf( 'roleDescription' );
if( description ) return description.replace( ` ${this.getAttributeForSelf( 'role' )}`, "" );
return "";
};

public compute_role()
{
return this.getAttributeForSelf( 'role' ) || "";
};

};
