// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


contract TicketNumberGovernor {
    uint16[6] minNumbers = [0, 0, 0, 0, 0, 1];
    uint16[6] maxNumbers = [49, 49, 49, 49, 49, 5];
    uint16[6] currentNumbers = [0, 0, 0, 0, 0, 0];
    mapping(address => bool) public iswhiteListed;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function getTicket() public returns (uint16, uint16, uint16, uint16, uint16, uint16) {
        require(iswhiteListed[msg.sender], "You are not whitelisted");
        bool flag = false;
        for(uint i=5; i>=0; i--){
            if(currentNumbers[i] < maxNumbers[i]){
                flag = true;
                currentNumbers[i]++;
                for(uint j=i+1; j<6;j++){
                    currentNumbers[j] = minNumbers[j];
                }
                return (currentNumbers[0], currentNumbers[1], currentNumbers[2], currentNumbers[3], currentNumbers[4], currentNumbers[5]);
            }
        }
        if(!flag){
            for(uint i=0; i<6; i++){
                currentNumbers[i] = minNumbers[i];
            }
        }
        return (currentNumbers[0], currentNumbers[1], currentNumbers[2], currentNumbers[3], currentNumbers[4], currentNumbers[5]);
    }

    function addWhiteListed(address[] calldata _address) external {
        require(msg.sender == owner, "Only owner can add whitelisted");
        for(uint i=0; i<_address.length; i++){
            iswhiteListed[_address[i]] = true;
        }
    }
}