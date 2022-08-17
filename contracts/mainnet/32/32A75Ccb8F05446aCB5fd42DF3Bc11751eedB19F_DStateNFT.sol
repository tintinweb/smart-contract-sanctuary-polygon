/**
 *Submitted for verification at polygonscan.com on 2022-08-17
*/

// SPDX-License-Identifier: MIT
// Rabbit Eggs DeFi Contract
pragma solidity ^0.8.11;

contract DStateNFT
{
    Jelly private jelly;

       constructor(address _jelly) {
        jelly = Jelly(_jelly); 
    }

    modifier nonContract() {
        require(tx.origin == msg.sender, "Contract not allowed");
        _;
    }
 
    function getBalance(address _useraddress) public view nonContract returns(uint256){
      require(_useraddress != address(0), "msg sender is the zero address");
        return jelly.getBal(_useraddress);
    }

    function withdraw() external nonContract {
        require(msg.sender != address(0), "msg sender is the zero address");
        jelly.WithdrawToken(msg.sender);
    }

    function buyNFT(address _from,address _pro) external payable  {
        require(msg.sender != address(0), "msg sender is the zero address");
        require(_from != address(0), "Its zero address");
        require(_pro != address(0), "Its zero address");
        jelly.BuyCart{value: msg.value}(_from,_pro);
    }

}

contract Jelly {

 function getBal(address _usrAddress) external view returns(uint256){}
 function WithdrawToken(address _to) external payable {}
 function BuyCart(address _from,address _pro) external payable {}

}