import { readFile } from 'fs/promises';
import swift from '../swift';

export const getSnapshot = async () => {
  try {
    let pathFinder = swift.runAppleScript( `
tell application "VoiceOver"
	tell vo cursor
		set pathFinder to grab screenshot
		set posixPathFinder to POSIX path of pathFinder
		return posixPathFinder
	end tell
end tell
` );
    const image = await readFile( pathFinder, 'base64' );
    return `data:image/png;base64,${image}`;
  } catch( error ) {
    throw( `Failed to take snapshot: ${error}` );
  }
};
