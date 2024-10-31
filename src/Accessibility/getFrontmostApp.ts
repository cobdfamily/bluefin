import swift from '../swift';

export const getFrontmostApp = () => {
return ( swift.AXUIElementCreateApplication( swift.getIdOfFrontmostApp() ) );
};