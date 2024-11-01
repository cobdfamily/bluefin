import swift from '@cobd/taylor';

export const getUpperCamelCase = ( word ) => {
return `AX${word.slice(0,1).toUpperCase()}${word.substring(1)}`;
};
