/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Transfer{

    address public owner;
    uint public contractPrice;

    modifier onlyOwner(){
        require(msg.sender==owner, "not owner");
        _;
    }

    constructor(){
        owner = msg.sender;
        contractPrice = 10 wei;
    }

    function buyContract()public payable returns(bool){

        if (msg.value > contractPrice){
           
            address payable _to = payable (owner);
            address _thisContract = address(this);
            _to.transfer(_thisContract.balance);

            owner = msg.sender;

            return true;
        } else { 

            return false;
        }
            
    }

    function changePrice (uint _newPrice) public onlyOwner{

        contractPrice = _newPrice / 10**18;
    }

    function changeOwner( address _newOwner) public onlyOwner{

        owner = _newOwner;
    }
}