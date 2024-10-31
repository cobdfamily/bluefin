import * as Accessibility from '../Accessibility/index';

export class UIElement {
_element;
_accessibility;

constructor( element )
{
if( !element ) throw new Error( "Missing element reference" );
this._element = element
this._accessibility = Accessibility;
}

get parentNode()
{
try {
return new UIElement( this._accessibility.getAttributeForElementByName( this._element, 'parent' ) );
} catch( error ) {
return null;
}
}

get role()
{
return this._accessibility.getAttributeForElementByName( this._element, 'roleDescription' ) || this._accessibility.getAttributeForElementByName( this._element, 'role' );
}

getAttribute( attributeName )
{
return this._accessibility.getAttributeForElementByName( this._element, attributeName );
}

};
