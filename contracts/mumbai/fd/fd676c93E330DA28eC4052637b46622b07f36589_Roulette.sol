// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";


contract Roulette is Ownable {
  
  IERC20 public cedToken;

event GotPaid(bool value);
 event Lost(bool value);
 event Guess(uint256 guess);

   constructor( IERC20 _cedToken)  {
    cedToken = _cedToken;
  }


 //make the gameble by guessing between 0 and 1
 function gamble(uint256 amount, uint256 _guess) payable public {
      require(
            amount > 0 &&
             cedToken.balanceOf(msg.sender) >= amount &&  cedToken.balanceOf(address(this)) >= amount*2,
            "You cannot gamble zero tokens");
      require(
            cedToken.balanceOf(address(this)) >= amount*2,
            "There are not enough tokens in the bank");
      require(_guess < 3);    
      cedToken.transferFrom(msg.sender, address(this), amount);
      uint256 myrandom = getRand();
      bool result;
      emit Guess(myrandom);
    if(_guess == myrandom){
        result = true;
        cedToken.approve(address(this),amount*2);
        cedToken.transferFrom(address(this),msg.sender, amount*2);
        emit GotPaid(true);
        emit Lost(true);
    }
    else{
        result = false;
        emit GotPaid(false);
    }  
           

 }
   
   //get random number replace with chainlink VRF
  function random() public view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
  }

  //get modulus of random number to return a number between 0 and 1
  function getRand() public view returns (uint256)  { 
    uint index = random() % 2; //will always be 1 below the number for reference
    return index;
  }

  //withdraw funds if needed...
  function withdrawFunds() public onlyOwner {

        cedToken.approve(address(this), cedToken.balanceOf(address(this)));
        cedToken.transferFrom(address(this), msg.sender, cedToken.balanceOf(address(this)));

  }


   

}