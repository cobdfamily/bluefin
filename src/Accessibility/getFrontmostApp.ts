import swift from '@cobd/taylor';

export const getFrontmostApp = () => {
return ( swift.AXUIElementCreateApplication( swift.getIdOfFrontmostApp() ) );
};