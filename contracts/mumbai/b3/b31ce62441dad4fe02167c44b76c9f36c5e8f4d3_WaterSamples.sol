/**
 *Submitted for verification at polygonscan.com on 2022-07-24
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
        uint256 lead;
        string message;
        mapping(address => bool) Samplers;
    }

    event sampleCreated (
        address sampler,
        string sampleAddress,
        uint256 lead,
        string message
    );

    mapping(string => sample) private Samples;

    function addSample(string memory _sampleAddress, uint256 _lead, string memory _message) public {
        require(!Samples[_sampleAddress].Samplers[msg.sender], "You already sampled this location");
        sample storage newSample = Samples[_sampleAddress];
        newSample.exists = true;
        samplesArray.push(_sampleAddress);

        newSample.sampleAddress = _sampleAddress; 
        newSample.lead = _lead; 
        newSample.message = _message;
        newSample.Samplers[msg.sender] = true;
 
        emit sampleCreated(msg.sender, _sampleAddress, _lead, _message);

    }

    function getSample(string memory _sampleAddress) public view returns (string memory sampleAddress, uint256 leadPercentage, string memory message) {
        require(Samples[_sampleAddress].exists, "Sample does not exist");
        sample storage s = Samples[_sampleAddress];
        return(s.sampleAddress, s.lead, s.message);
    }

    function getArray() public view returns(string[] memory sArray) {
        return(samplesArray);
    }
}