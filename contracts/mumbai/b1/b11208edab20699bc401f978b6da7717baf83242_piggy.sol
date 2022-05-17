/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.0;

contract piggy {
    uint public goal ;           /*存款目標*/
    constructor(uint _goal){    /*建構子 給初始值*/
    goal= _goal;
    }
    receive() external payable{}    
    
    function getMyBalance() public view returns(uint){
        return address(this).balance;   /*現在多少錢*/
    }
    function withdraw() public{
        if(getMyBalance()>= goal){
         
          selfdestruct(payable(msg.sender));   /*payable收件人  只能將資金轉入address payable*/
        }

    }
}