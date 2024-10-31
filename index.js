import * as system from './dist/index.js';
import swift from './dist/swift.js';

let app = system.getSystemApp();

console.log( new system.UIElement( app ).getAttribute( 'role' ) );

let atts = system.getAttributesForElementWithFilter( app, /action|children|window/i );

for( let att of atts )
{

// console.log( att, system.getAttributeForElementByName( app, att ) );
}

console.log( `Battery: ${system.getBatteryPercentage()}% - ${(system.getIsCharging() ? "Charging":"Not Charging")}` );


setInterval( () => {
let title = "me";

}, 2000 );

