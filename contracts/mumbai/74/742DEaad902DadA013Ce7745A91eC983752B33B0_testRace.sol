/**
 *Submitted for verification at polygonscan.com on 2022-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IGreyhound {
    struct Greyhound {
        uint father;
        uint mother;
        string name;
        uint rarity;
        uint[] stats;//[Spe,Str,Agi,Rea,End]
        uint[] exp;//[Spe,Str,Agi,Rea,End]
        uint bornDate;
        string skin;
        uint numRaces;
        uint maxRaces;
        bool male;
        string color;
        uint numPregnant;
        uint pregnantDate;
        bool isPregnant;
        uint endRace;
        uint endTrainingDate;
        uint injuredDate;
        uint horasEntrenadas;
        uint entrenamientosConsecutivos;
        uint resetDate;
    }
}
contract testRace {
    struct Record{
        uint millimeters;
        uint milliseconds;
        bool collision;
    }
    struct GreyhoundRecord{
        IGreyhound.Greyhound greyhound;
        Record[] records;
    }
    struct Race{
        string wheater;
        bool withObstacles;
        uint millimeters;
        uint start;
        uint end;
        uint registration_price;
        uint category; 
        GreyhoundRecord[] greyhoundWithRecords;
    }
    
    uint public lastRace;
    mapping(uint => Race) public races;
    constructor () {}
    function insertRace(Race calldata race) public {
        uint last=lastRace;
        last++;
        races[last]=race;
        lastRace=last;
    }
}