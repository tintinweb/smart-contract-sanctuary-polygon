/**
 *Submitted for verification at polygonscan.com on 2022-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract WaterSamples {
    address public owner;
    string[] public samplesArray;

    constructor() {
        owner = msg.sender;
    }

    struct sample {
        bool exists;
        string sampleAddress;
        string lead;
        string latitude;
        string longitude;
        uint date;
        mapping(address => bool) Samplers;
    }

    event sampleCreated (
        address sampler,
        string sampleAddress,
        string lead,
        string latitude,
        string longitude,
        uint date
    );

    mapping(string => sample) private Samples;

    function addSample(string memory _sampleAddress, string memory _lead, string memory _latitude, string memory _longitude) public {
        require(!Samples[_sampleAddress].Samplers[msg.sender], "You already sampled this location");
        sample storage newSample = Samples[_sampleAddress];
        newSample.exists = true;
        samplesArray.push(_sampleAddress);
        newSample.sampleAddress = _sampleAddress; 
        newSample.lead = _lead; 
        newSample.latitude = _latitude;
        newSample.longitude = _longitude;
        newSample.date = block.timestamp;
        newSample.Samplers[msg.sender] = true;
 
        emit sampleCreated(msg.sender, _sampleAddress, _lead, _latitude, _longitude, block.timestamp);
    }

    function getSample(string memory _sampleAddress) public view returns (string memory sampleAddress, string memory lead, string memory latitude, string memory longitude, uint date) {
        require(Samples[_sampleAddress].exists, "Sample does not exist");
        sample storage s = Samples[_sampleAddress];
        return(s.sampleAddress, s.lead, s.latitude, s.longitude, s.date);
    }

    function getArray() public view returns(string[] memory sArray) {
        return(samplesArray);
    }
}