/**
 *Submitted for verification at polygonscan.com on 2022-09-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract lottery {

    event newNumber(uint num);

    mapping(address => uint256) numbers;
    mapping(address => uint256) internal numbersCount;
    mapping(address => bool) isWinner;

    uint randNonce = 0;

    function _setNum() internal {
        numbersCount[msg.sender]++;
        randNonce++;
        uint256 randNum = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 100;
        numbers[msg.sender] = randNum;
        emit newNumber(randNum);

        if (numbers[msg.sender] > 90) {
            isWinner[msg.sender] = true;
        }
  }

    function generateRandomNumber() public {
        require(numbersCount[msg.sender] == 0);
        _setNum();
    }

    function getNumByAddress(address _address) public view returns (uint256) {
        return numbers[_address];
    }

    function getIsWinner(address _address) public view returns (bool) {
        return isWinner[_address];
    }
 
    function claimRewards(address payable _to) public payable {
        require(isWinner[msg.sender] == true);
        _to.transfer(5*10**16);
    }

}