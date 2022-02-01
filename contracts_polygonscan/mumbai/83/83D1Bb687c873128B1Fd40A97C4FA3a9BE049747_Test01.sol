/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;
contract  Test01 {

    string _name; 
    uint _balance;
  
    constructor(string memory name, uint balance){   
        require(balance > 0, "more than 0");  
        _name = name;
        _balance= balance;
    }

    function getBalance() public view returns(uint balance){  
        return _balance;
    }

    function getfixvalue() public pure returns (int fixvalue) {  
        return 50000;
    } 

    function deposite(uint amount) public {  
        _balance+=amount;
        
    }

    function withdraw(uint amount) public {
        _balance-=amount;
        
    }

}