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
        address farmerAdd;
        address payable farmerAdd1;
    }

    
    uint public totalPremium;
    
    // address[43] admin;
    // address payable[43] admin1;

    uint public i;

    // constructor(){
    //     admin[i]=payable(msg.sender);
    //     admin1[i]=payable(msg.sender);
    //     i+=1;
    // }
   
    mapping(uint=>farmerDetails) private _farmer;

    function enroll(string memory name_,string memory district_,address farmerAdd_,address payable payAdd) external {
          _farmer[i].name=name_;
          _farmer[i].district=district_;
          _farmer[i].farmerAdd = farmerAdd_;
          _farmer[i].farmerAdd1 =payAdd;
          _farmer[i].premium=0;
    }

    function payPremium() external payable{
        _farmer[i].premium += msg.value;
        totalPremium += _farmer[i].premium;
    }

    function getFarmerDetails(uint u) external view returns(farmerDetails memory){
        return _farmer[u];
    }

    function sendEther(uint p,uint a) public{
        _farmer[p].farmerAdd1.transfer(a);
    }
    
    function details() public view returns(uint){
        return totalPremium;
    }
    
}