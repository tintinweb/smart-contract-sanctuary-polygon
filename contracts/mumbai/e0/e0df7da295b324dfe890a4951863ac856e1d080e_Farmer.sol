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
    address admin;
    address payable admin1;
    constructor(){
        admin=payable(msg.sender);
        admin1=payable(msg.sender);
    }
    mapping(address=>farmerDetails) public _farmer;
    function enroll(string memory name_,string memory district_) external {
          _farmer[admin].name=name_;
          _farmer[admin].district=district_;
          _farmer[admin].premium=0;
    }
    function payPremium() external payable{
        _farmer[admin].premium += msg.value;
        totalPremium += _farmer[admin].premium;
    }

    function getFarmerDetails(address) external view returns(farmerDetails memory){
        return _farmer[admin];
    }

    function sendEther(uint a) public{
        admin1.transfer(a);
    }
    function details() public view returns(uint){
        return totalPremium;
    }
}