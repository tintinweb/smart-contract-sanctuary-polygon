//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract AirQuality {
    
    uint256 private coGasThresholdInPM = 200;
    uint256 private smokeThresholdInPM = 300;
    uint256 private hydrogenThresholdInPM = 400;

    uint256 private avgCOgasSensorDataInPM;
    uint256 private avgSmokeSensorDataInPM;
    uint256 private avgHydrogenSensorDataInPM;
    bool private isCOgasCritical;
    bool private isSmokeCritical;
    bool private isHydrogenCritical;

    struct CriticalData {
        uint256 timeStamp;
        address sender;
        uint256 data;
    }

    CriticalData[] public criticalCOgasData;
    CriticalData[] public criticalSmokeData;
    CriticalData[] public criticalHydrogenData;

    function supplySensorData(
        uint256 _avgCOSensorData,
        uint256 _avgSmokeSensorData,
        uint256 _avgHydrogenSensorData
    ) public {
        avgCOgasSensorDataInPM = _avgCOSensorData;
        avgSmokeSensorDataInPM = _avgSmokeSensorData;
        avgHydrogenSensorDataInPM = _avgHydrogenSensorData;
    }

    function storeSensorData() public {
        require(avgCOgasSensorDataInPM >= 0);
        require(avgSmokeSensorDataInPM >= 0);
        require(avgHydrogenSensorDataInPM >= 0);
        isCOgasCritical = false;
        isSmokeCritical = false;
        isHydrogenCritical = false;

        if (avgCOgasSensorDataInPM > coGasThresholdInPM) {
            CriticalData memory coGasData = CriticalData({
                timeStamp: block.timestamp,
                data: avgCOgasSensorDataInPM,
                sender: msg.sender
            });
            criticalCOgasData.push(coGasData);
            isCOgasCritical = true;
        }

        if (avgSmokeSensorDataInPM > smokeThresholdInPM) {
            CriticalData memory smokeData = CriticalData({
                timeStamp: block.timestamp,
                data: avgSmokeSensorDataInPM,
                sender: msg.sender
            });
            criticalSmokeData.push(smokeData);
            isSmokeCritical = true;
        }

        if (avgHydrogenSensorDataInPM > hydrogenThresholdInPM) {
            CriticalData memory hydrogenData = CriticalData({
                timeStamp: block.timestamp,
                data: avgHydrogenSensorDataInPM,
                sender: msg.sender
            });
            criticalHydrogenData.push(hydrogenData);
            isHydrogenCritical = true;
        }

   
    }

    function notifyUser() public returns(string memory) {
        
        if(isCOgasCritical && isSmokeCritical && isHydrogenCritical){
           return "CO Gas, Smoke and Hydrogen gas has crossed the critical limit";
        }

        if(isCOgasCritical && isSmokeCritical){
            return "CO Gas and Smoke has crossed the limit";
        }

        if(isCOgasCritical && isHydrogenCritical){
             return "CO Gas and Hydrogen gas has crossed the limit";
        }

        if(isSmokeCritical && isHydrogenCritical){
            return "Smoke and Hydrogen gas has crossed the limit";
        }
        
        if(isCOgasCritical){
            return "CO Gas has crossed the limit";
        }
        if(isSmokeCritical){
            return "Smoke has crossed the limit";
        }if(isHydrogenCritical){
            return "Hydrogen Gas has crossed the limit";
        }

    }

    function getStoredCOData() public view returns (CriticalData[] memory) {
        return criticalCOgasData;
    }

    function getStoredSmokeData() public view returns (CriticalData[] memory) {
        return criticalSmokeData;
    }

    function getStoredHydrogenData()
        public
        view
        returns (CriticalData[] memory)
    {
        return criticalHydrogenData;
    }
}