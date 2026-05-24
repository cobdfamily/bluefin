// Events -- a single shared SeaBus instance used as
// the framework-wide event channel. Subscribers can
// listen on a named channel or on 'all' to observe
// every emit (handy for the cli.js demo and for
// tracing accessibility-event flow during development).

import { SeaBus } from './SeaBus';

export const bus = new SeaBus();
