import { BlueTide, TidalEvents } from '@cobd/bluetide';
import { EventEmitter } from 'events';

import { UIElement } from '../Elements/UIElement';

export class SeaBus extends EventEmitter {
private vessel;

constructor() {
super();
this.vessel = new BlueTide();
this.vessel.on( 'end', this.start );
this.vessel.on( 'event', (data) => {
this.sendData(data);
} );
};

public start() {
if( this.vessel ) this.vessel.start();
};

private sendData( data: any ) {
if( data.name ) data.name = data.name.replace( "AX", "UI" );
if( data.targetPath )
{
data.target = this.resolveElementAtPath( data.targetPath );
if( !data.target ) return;
}
this.emit( ( data.name || 'system' ), data );
this.emit( 'all', data );
};

private resolveElementAtPath( path: [number] ): UIElement|undefined {
if( global && global.uiManager && global.uiManager.app )
{
return global.uiManager.app.resolveElementAtPath( path );
}
return undefined;
};

};
