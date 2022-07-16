/**
 *Submitted for verification at polygonscan.com on 2022-07-15
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
contract PurposeHandler {

  string public purpose = "Building Unstoppable Apps!!!";
  address public owner ;     //这里填写自己的地址
  constructor() {
    owner = msg.sender ;
    // what should we do on deploy?
  }
  function setPurpose(string memory newPurpose) public {
  //   emit SetPurpose(msg.sender, purpose);
   require( msg.sender == owner,"NOT THE OWNER!");  //条件判断owner是否合约发起人
   
   purpose = newPurpose;
   // console.log(msg.sender,"set purpose to",purpose);
  }
  // to support receiving ETH by default
  //receive() external payable {}
  //fallback() external payable {}
}