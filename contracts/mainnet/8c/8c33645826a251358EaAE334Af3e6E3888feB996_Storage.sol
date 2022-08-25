// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Storage {

    address public owner;

    uint public storeAmount = 0.1 ether;

    struct Hash { 
        string hash;
        uint timestamp;
    }

    Hash[] private hashs;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

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

        require(!validate(hash), "Hash already exists");

        hashs.push(Hash({ hash: hash, timestamp: block.timestamp }));
    }

    function getHahs() public view onlyOwner returns(Hash[] memory) {
        return hashs;
    }

    function withdraw() public payable onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

}