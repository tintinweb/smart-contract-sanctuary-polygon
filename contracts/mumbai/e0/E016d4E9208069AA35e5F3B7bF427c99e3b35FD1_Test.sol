/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// SPDX-License-Identifier: MIT

// File: contracts/test.sol



pragma solidity >=0.7.0 <0.9.0;

contract Test {

    uint256[] public result;

    uint256 [] public mintedPlayersIds;


    function random(uint256 maxValue) public{
        uint256 randomizer = 1;

        for(uint256 i = 0; i < mintedPlayersIds.length; i++){
            if(randomizer * mintedPlayersIds[i] >= (2**(128))-1){
                randomizer = 1;
            }else{
                randomizer *= mintedPlayersIds[i];
            }
        }

        result.push(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number, randomizer))) % maxValue);
    }

    function mostra() public view returns(uint256[] memory){
        return result;
    }

    function carica() public {
        for (uint256 i = 1; i < 501; i++){
            mintedPlayersIds.push(i);
        }
    }

    function mostra2() public view returns(uint256[] memory){
        return mintedPlayersIds;
    }
}