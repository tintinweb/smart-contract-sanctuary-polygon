/**
 *Submitted for verification at polygonscan.com on 2022-09-26
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
    
    struct Instructor {
        uint id;
        uint age;
        string first_name;
        string last_name;
        string hash_value;
    }

    event instructorEvent(uint indexed _instructorId);

    event stationEvent(uint indexed _stationIndex);

    uint stationCount;

    uint instructorCount;

    constructor() {
        instructorCount = 0;
        stationCount = 0;
    }
    
    Station[] station_enrolled;
    
    Instructor[] instructor_enrolled;

    mapping(uint => Instructor) instructors;
    
    mapping(uint => Station) stations;
    
    function compareStrings(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function getStationInfo(string memory _cod_station) public view returns(Station[] memory) {
        Station[] memory index = new Station[](stationCount);
        for (uint i = 0; i<instructorCount; i++){
            Station storage station = stations[i];
            if (compareStrings(station.cod_station, _cod_station) == true) {
                index[i] = station; 
            }    
        }
        return index;
    }

    /*function get(uint _instructorId) public view returns(Instructor memory) {
        return instructors[_instructorId];
    }*/

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
        stationCount++;
    }

/*
uint index;
        string cod_station;
        bool is_online;
        string address_details;
        string address_active_contract;
        bool is_deprecated;
        uint lastUpdate;
*/

 /*   function addInstructor(uint _age, string memory _first_name, string memory _last_name, string memory _hash_value) public {
        instructors[instructorCount] = Instructor(instructorCount,_age, _first_name,_last_name, _hash_value);
        instructorCount++;
    }

    function addInstructorOld(uint _age, string memory _first_name, string memory _last_name, string memory _hash_value) private {
        Instructor memory new_instructor = Instructor(instructorCount,_age, _first_name, _last_name, _hash_value);
        instructor_enrolled.push(new_instructor);
        instructorCount++;
    }

    function getNumInstructors() public view returns (uint) {
        return instructorCount;
    }
*/

    function getNumStations() public view returns (uint) {
        return stationCount;
    }

 /*   function getContracts() public view returns (Instructor[] memory) {
        Instructor[] memory id = new Instructor[](instructorCount);
        for (uint i = 0; i<instructorCount; i++){
            Instructor storage instructor = instructors[i];
            id[i] = instructor;     
        }
        return id;
    }
    */
}