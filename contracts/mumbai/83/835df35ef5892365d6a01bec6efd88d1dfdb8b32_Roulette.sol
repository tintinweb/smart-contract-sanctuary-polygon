// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
//import "hardhat/console.sol";
//import "./pumpk.sol";

contract Roulette is Ownable {
  
  address[] public players;
  address public manager;
  IERC20 public cedToken;

   constructor( IERC20 _cedToken)  {
    manager = msg.sender;
    cedToken = _cedToken;
  }


 function gamble(uint256 amount, uint256 _guess) public {
        require(
            amount > 0 &&
            cedToken.balanceOf(msg.sender) >= amount &&  cedToken.balanceOf(address(this)) >= amount*2,
            "You cannot gamble zero tokens");
            require(
        cedToken.balanceOf(address(this)) >= amount*2,
            "There are not enough tokens in the bank");
        require(_guess < 3);
             cedToken.approve(msg.sender,cedToken.balanceOf(address(this)));
             cedToken.transferFrom(msg.sender, address(this), amount);
      uint256 myrandom = getRand();
      bool result;
      // console.log("yolo");
      // console.log(_guess);
      // console.log(myrandom);
      emit Guess(myrandom);
    if(_guess == myrandom){
        result = true;
        cedToken.approve(address(this),amount*2);
        cedToken.transferFrom(address(this),msg.sender, amount*2);
        emit GotPaid(true);
        // console.log("I got paid");
        // console.log('got paid');
    }
    else{
        result = false;
        // console.log("I did not get paid");
        emit GotPaid(true);
    }  
           

 }
   

  function enter() public payable {
    require(msg.value > .01 ether);

    players.push(msg.sender);
  }

 event GotPaid(bool value);
 event Guess(uint256 guess);

  function guessMe(uint256 _guess) public payable returns (bool) {
    
   
    require(msg.value > .01 ether);
    require(_guess < 3);
    bool result;
    uint256 myrandom = getRand();

    if(_guess == myrandom){
        result = true;
        emit GotPaid(true);
    }
    else{
        result = false;
        emit GotPaid(true);
    }  

    return result;
  }

  function random() public view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
  }

  function getRand() public view returns (uint256)  { 
    uint index = random() % 2; //will always be 1 below the number for reference
    return index;
  }

  function withdrawFunds() public onlyOwner {

        cedToken.approve(address(this),cedToken.balanceOf(address(this)));
        cedToken.transferFrom(address(this),msg.sender, cedToken.balanceOf(address(this)));

  }


    modifier restricted() {
    require(msg.sender == manager);
    _;
  }

}