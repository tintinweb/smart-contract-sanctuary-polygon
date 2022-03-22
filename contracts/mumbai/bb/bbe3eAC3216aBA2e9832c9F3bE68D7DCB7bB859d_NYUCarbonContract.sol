/**
 *Submitted for verification at polygonscan.com on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract NYUCarbonContract {
    struct Transcation {
        string contract_address;
        uint token_id;
        uint co2;
    }

    uint BCT= 1000;

    Transcation[] public transcations;
    address[] public arr;
    
    function fetchTransaction(string memory contract_address, uint token_id, uint co2) public{
        transcations.push(Transcation(contract_address, token_id, co2));
    }  

    function getLatest() view public returns(string memory, uint, uint) {
        uint id = transcations.length-1;
        return (transcations[id].contract_address, transcations[id].token_id, transcations[id].co2);
    }

    function getBalance() view public returns(uint) {
        return BCT;
    }

    function withdraw() public  {
        uint position = transcations.length-1;
        uint offset = transcations[position].co2/10;
        BCT = BCT - offset;
    }

}