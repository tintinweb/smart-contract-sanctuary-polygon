// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

contract Storage {
    uint public storeAmount = 0.5 ether;

    struct Hash { 
        string hash;
        uint timestamp;
    }

    Hash[] private hashs;

    function validate(string memory hash) public view returns (bool){
        for(uint i = 0; i< hashs.length ; i++) {
            if (keccak256(abi.encodePacked(hashs[i].hash)) == keccak256(abi.encodePacked(hash))) {
                
                return true;
            }
        }

        return false;
    }

    function store(string memory hash) public payable {
        require(msg.value == storeAmount, "Invalid amount");

        require(!validate(hash), "Already exists");

        hashs.push(Hash({ hash: hash, timestamp: block.timestamp }));
    }
}