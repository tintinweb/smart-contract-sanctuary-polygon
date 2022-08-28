/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Farmer{

    struct farmerDetails{
        
        string name;
        string district;
        uint premium;
        uint claim;
    }

    uint public totalPremium;
    
    address[43] admin;
    address payable[43] admin1;

    uint public i;

    constructor(){
        admin[i]=payable(msg.sender);
        admin1[i]=payable(msg.sender);
        i+=1;
    }
   
    mapping(address=>farmerDetails) private _farmer;

    function enroll(string memory name_,string memory district_) external {
          _farmer[admin[i]].name=name_;
          _farmer[admin[i]].district=district_;
          _farmer[admin[i]].premium=0;
    }

    function payPremium() external payable{
        _farmer[admin[i]].premium += msg.value;
        totalPremium += _farmer[admin[i]].premium;
    }

    function getFarmerDetails() external view returns(farmerDetails memory){
        return _farmer[admin[i]];
    }

    function sendEther(uint a) public{
        admin1[i].transfer(a);
    }
    function details() public view returns(uint){
        return totalPremium;
    }
    
}