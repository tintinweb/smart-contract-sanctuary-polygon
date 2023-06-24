/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ThereIsNothingHere {
    string private looking_for_that;
    uint[] private sequence;
    mapping(address => uint[]) private addresses_with_sequence;

    constructor(string memory text, uint[] memory _sequence) {
        looking_for_that = text; 
        sequence = _sequence;
    }

    function reset_sequence() public{
        delete addresses_with_sequence[msg.sender];
    }

    function verify_sequence(address _player) internal view returns(bool){
        
        if(addresses_with_sequence[_player].length != sequence.length){
            return false;
        }
        
        for(uint i=0; i < sequence.length; i++){
            if(addresses_with_sequence[_player][i] != sequence[i]){
                return false;
            }
        }
        
        return true;
    }

    function show_me_the_answer() public view returns(string memory){
        if(verify_sequence(msg.sender)){
            return looking_for_that;
        }
        
        return "Invalid Sequence. Reset or continue to find the correct sequence";
    }

    function add_zero() public{
        addresses_with_sequence[msg.sender].push(0);
    }

    function add_one() public{
        addresses_with_sequence[msg.sender].push(1);
    }
}