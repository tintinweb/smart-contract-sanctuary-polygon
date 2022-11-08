/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

pragma solidity ^0.8.0;

contract Kinger {

  constructor()  payable {
  }

  function getKing() public {
    payable(address(0x9B857867ab8878041A5Cb9C21c3E701AB9f6803f)).call{gas:100000,value:1200000000000000}("");
  }

}