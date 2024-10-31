import swift from '../swift';
import { getCamelCase } from './getCamelCase';
import { getUpperCamelCase } from './getUpperCamelCase';

export const getAttributeForElementByName = ( element, name ) => {
let value = swift.AXUIElementCopyAttributeValue( element, getUpperCamelCase( name ) );
if( name == "role" ) return getCamelCase( value.valueOf() );
if( !value )
{
return null;
}
else
{
return value.valueOf();
}

};
