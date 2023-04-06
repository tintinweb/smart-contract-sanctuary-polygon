/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

pragma solidity ^0.8.0;

contract PromoCodes {
  mapping(string => bool) private usedCodes;
  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}


  constructor(address _owner){
   owner = _owner;
   }


  function useCode(string memory code) public onlyOwner {
    usedCodes[code] = true;
  }

  function isCodeUsed(string memory code) public view returns (bool) {
    return usedCodes[code];
  }
}