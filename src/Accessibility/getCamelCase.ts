import swift from '../swift';

export const getCamelCase = (word)=> {
    // Check if the string starts with "AX"
    if (word.startsWith("AX")) {
        // Remove "AX", then make the first letter lowercase and concatenate it with the rest of the string
        return word.slice(2, 3).toLowerCase() + word.slice(3);
    }
    // Return the original string if it doesn't start with "AX"
    return word;
};