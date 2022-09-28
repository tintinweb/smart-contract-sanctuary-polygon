/**
 *Submitted for verification at polygonscan.com on 2022-09-28
*/

// SPDX-License-Identifier: PUCRS

pragma solidity >= 0.8.9;

contract StationManager {
    struct Station{
        uint index;
        string cod_station;
        bool is_online;
        string address_details;
        string address_active_contract;
        bool is_deprecated;
        uint lastUpdate;
    }
 
    event stationEvent(uint indexed _stationIndex);

    uint stationCount;

    constructor() {
        stationCount = 0;
    }
    
    Station[] station_enrolled;
    
    mapping(uint => Station) stations;
    
    function compareStrings(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function getStationInfo(string memory _cod_station) public view returns (Station[] memory) {
        Station[] memory index = new Station[](stationCount);
        for (uint i = 0; i < stationCount; i++){
            Station storage station = stations[i];
            /*if (compareStrings(station.cod_station, _cod_station) == true) {
                index[i] = station; 
            } */ 
            index[i] = station;   
        }
        return index;
    }


    function addStation(
        string memory _cod_station, string memory _address_details
    ) public {
        stations[stationCount] = Station(
            stationCount,
            _cod_station,
            true,
            _address_details,
            "null",
            false,
            block.timestamp
        );

        /*Station memory new_station = Station(
            stationCount,
            _cod_station,
            true,
            _address_details,
            "null",
            false ,
            block.timestamp
        );

        station_enrolled.push(new_station);*/

        stationCount++;
    }

    function getNumStations() public view returns (uint) {
        return stationCount;
    }



}