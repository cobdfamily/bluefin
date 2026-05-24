// @cobd/taylor -- Node.js bridge to a Swift-built
// native module that exposes macOS accessibility APIs
// to the Tuna screen reader. The .node binary is built
// from Sources/ via `node-swift build`; this file just
// loads it.
//
// Why a manual path.join: __dirname/lib/Module.node
// path is fixed by node-swift's output layout. Using
// `require('./lib/Module.node')` works too but the
// absolute path keeps behavior predictable when this
// file is consumed via npm-link or symlinked into
// another project's node_modules.

const path = require( 'path' );
module.exports = require( path.join( __dirname, 'lib', 'Module.node' ) );
