import swift from '@cobd/taylor';

export const setOutput = ( message ) => {
  let script = `tell application "VoiceOver" to output "${message.replace( /"/g, '\"' )}"`;
  swift.runAppleScript( script );
};
