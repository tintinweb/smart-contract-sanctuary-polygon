//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

contract Test {
    address private owner;
    string private secret;

    modifier onlyOwner() {
        require(msg.sender==owner,"onlyOwner");
        _;
    }

    constructor() {
        owner = msg.sender;
        secret="Abracadabra";
    }

    function setSecret(string memory newSecret) public onlyOwner {
        secret = newSecret;
    }
    function getSecret() public view onlyOwner returns(string memory) {
        return secret;
    }
    
}