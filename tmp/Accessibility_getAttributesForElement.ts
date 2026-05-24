import swift from '@cobd/taylor';
import { getCamelCase } from './getCamelCase';

export const getAttributesForElement = ( element ) => {
const originalAttributes = swift.AXUIElementCopyAttributeNames( element );
let newAttributes = [];
if( originalAttributes )
{
for( const  originalAttribute of originalAttributes )
{
newAttributes.push( getCamelCase( originalAttribute ) );
}
}
return newAttributes;
};
