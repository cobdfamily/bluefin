import { getBatteryPercentage } from './getBatteryPercentage';
import { getIsCharging } from './getIsCharging';

export const getBatteryStatus = () => {
return {
percentage: getBatteryPercentage(),
isCharging: getIsCharging(),
};


};
