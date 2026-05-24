import { UIApp } from '../Elements/UIApp';
import { UIManager } from './UIManager';

export const load = () => {

if( global )
{
if( !global.uiManager )
{
global.uiManager = new UIManager();
global.uiManager.app = new UIApp( 'active' );
}
return global.uiManager;
}

};

