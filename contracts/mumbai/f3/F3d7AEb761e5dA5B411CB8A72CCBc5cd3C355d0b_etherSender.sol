/**
 *Submitted for verification at polygonscan.com on 2022-10-04
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract etherSender {

    function sendToEOA() external returns(bool) {
        address payable to =payable (msg.sender); //Add "the casting" 'payable' to allow the address to receive money. 
        uint256 amount= 0.01 ether;
        bool result = to.send(amount);
        return result;
    }

    function sendHalf() external returns(bool) {
        address payable to =payable (msg.sender); 
        uint256 amount= getBalance()/2;
        bool result = to.send(amount);
        return result;

    }

    function sendAllToOwner() external returns (bool) {
        address payable owner = payable (0x17F6AD8Ef982297579C203069C1DbfFE4348c372); // Looking for your address to bribe you (so i can get the best student title hehehe)
        uint256 amount =getBalance(); // Seriously, i guess this address payable variable could be a state variable too, right?
        bool result =owner.send(amount);
        return result;
    }
    
    function inject() external payable{
        //Injecting some money without any kind of security. Lets rugpull!

    }
    
    function getBalance() private view returns(uint256) {
        uint256 balance =address(this).balance;        //Get the SC address balance
        return balance;
    }


}