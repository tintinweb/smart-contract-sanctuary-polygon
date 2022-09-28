/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

pragma solidity ^0.8.13;

contract Balance {

    mapping(address => uint256) numbers;
    uint randNonce = 0;

    function RandNum() public returns (uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 100;
    }

    function SetBalance() internal {
        numbers[msg.sender] = RandNum();
  }

    function GetBalance(address _myaddress) public view returns (uint) {
        return numbers[_myaddress];
    }
}