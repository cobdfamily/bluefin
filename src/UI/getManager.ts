import { load } from './load';

export const getManager = () => {

if( global && global.uiManager ) return global.uiManager;
return load();

};
