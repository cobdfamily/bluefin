import { UIElement } from './UIElement';
import * as Accessibility  from '../Accessibility/index';

export class UIApp extends UIElement {

constructor( element )
{
if( element == "active" ) {
element = Accessibility.getFrontmostApp();
} else if( element == "system" ) {
element = Accessibility.getSystemApp();
}

super( element );
}

};
