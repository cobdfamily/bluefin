import swift from '../swift';

export const getUpperCamelCase = ( word ) => {
return `AX${word.slice(0,1).toUpperCase()}${word.substring(1)}`;
};
