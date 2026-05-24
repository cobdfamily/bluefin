import { getAttributesForElement } from './getAttributesForElement';

export const getAttributesForElementWithFilter = ( element, filter ) => {
return getAttributesForElement( element ).filter( attribute => !filter.test( attribute ) );
};
