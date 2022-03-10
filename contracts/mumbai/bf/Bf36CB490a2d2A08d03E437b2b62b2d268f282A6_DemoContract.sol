/**
 *Submitted for verification at polygonscan.com on 2022-03-09
*/

// File: Demo.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract DemoContract {
    struct Transcation {
        string contract_address;
        uint token_id;
        uint co2;
    }

    Transcation[] public transcations;
    
    function fetchTransaction(string memory contract_address, uint token_id, uint co2) public{
        transcations.push(Transcation(contract_address, token_id, co2));
    }  

    function getAll() view public returns(Transcation[] memory) {
    return transcations;
    }

    function getToken(uint position) view public returns(uint) {
    return transcations[position].co2/10;
    }

    function destroy(uint position) public {
        delete transcations[position];
    }
}