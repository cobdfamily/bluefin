// @cobd/bluetide node side -- launches the bluetide
// Swift binary (../bin/bluetide) as a child process
// and re-emits its stdout messages as a typed
// EventEmitter. Consumers don't care that there's a
// Swift process behind the scenes; they subscribe to
// the bluefin event surface like any JS object.
//
// .start()  spawns + connects to stdio
// .end()    SIGTERMs the child, emits 'end'
// 'event'   one fires per child-side notification
//
// Why spawn + pipe rather than a node-swift binding:
// the Swift process needs to retain its own runloop
// to receive macOS accessibility callbacks; bridging
// that into Node's runloop via a native module is
// fiddly. Child-process + JSON-line stdout is the
// boring shape that just works.

import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { EventEmitter } from 'events';

// Define event types for better type safety
export interface TidalEvents {
start: () => void;
    event: (data: any) => void;
end: () => void;
}

// Custom EventEmitter class with typed events
export class BlueTide extends EventEmitter {

private binary;

constructor() {
super();
};

public end() {
if( !this.binary ) return;
// Kill the process
this.binary.kill('SIGTERM');  // This sends a termination signal to the process
this.binary = undefined;
this.emit( 'end' );
};

public start() {

if( !this.binary )
{
// Resolve the path to the Swift executable
const swiftAppPath = fileURLToPath( new URL( '../bin/bluetide', import.meta.url ) );

// Spawn the Swift application as a child process
this.binary = spawn(swiftAppPath, {
    stdio: ['pipe', 'pipe', 'pipe']  // Capture stdin, stdout, and stderr as streams
});

// Handle errors in spawning the process
this.binary.on('error', (error) => {});

// Listen for any output from the Swift process (both stdout and stderr)
this.binary.stdout.on('data', (data) => {
try {
let json = JSON.parse( data.toString() );
this.emit( 'event', json );
} catch( error ) {} // Discard silently

});

this.binary.stderr.on('data', (data) => {
    console.error(`Swift app error: ${data.toString()}`);
});

// Listen for when the Swift process exits
this.binary.on('close', (code) => {
    console.log(`Swift app exited with code ${code}`);
this.emit( 'end' );
});

this.emit( 'start' );
}
};

    // Emit an event with the specified event type
    emit<T extends keyof TidalEvents>(event: T, ...args: Parameters<TidalEvents[T]>): boolean {
        return super.emit(event, ...args);
    }

    // Add a listener for the specified event type
    on<T extends keyof TidalEvents>(event: T, listener: TidalEvents[T]): this {
        return super.on(event, listener);
    }

// Function to send a PID to the Swift process
public sendPID(pid) {
    if (this.binary.stdin.writable) {
        this.binary.stdin.write(`${pid}\n`);
        console.log(`Sent PID ${pid} to Swift app`);
    } else {
        console.error('Unable to send PID, stdin is not writable');
    }
}

};

