/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Insurance{
    
    DisasterData dd;
    uint premiumAmount;
    address public owner;

    struct FarmerInfo{
        bool exists;
        address payable addr;
        uint premiumPaid;
    }

    struct localInfo{
        uint count;
        uint contribution;
    }

    mapping (string => FarmerInfo) private _farmers;
    mapping (string => localInfo) public _districts;

    constructor (address addr){
        dd = DisasterData(addr);
        owner = msg.sender;
    }

    function register(string memory name_, string memory district_) public {
        _farmers[name_].exists = true;
        _farmers[name_].addr = payable(msg.sender);
        _districts[district_].count ++;
    }

    function payPremium(string memory name_, string memory district_) external payable {
        require(_farmers[name_].exists == true, "You are not registered");
        _farmers[name_].premiumPaid += msg.value;
        premiumAmount += msg.value;
        _districts[district_].contribution += msg.value;
    }

    uint factor;
    function triggerClaim (string memory district_) public {
        require(msg.sender==owner, "You can't trigger claim");
        uint day_ = block.timestamp / 5 minutes;
        require (dd.getSeverityData(district_, day_) >= 25, "Condition not severe");
        factor = (7 * premiumAmount) / (10* _districts[district_].contribution);
    }

    function claimInsurance(string memory name_) public {
        require(_farmers[name_].exists == true, "You are not registered");
        _farmers[name_].addr.transfer(_farmers[name_].premiumPaid * factor);
        _farmers[name_].premiumPaid = 0;
    }
    
}

contract DisasterData{
    function setSeverity(string memory district, uint newSeverity) public {}
    function getSeverityData(string memory district, uint day) public view returns (uint){}
    function getDistricts() public pure returns (string memory) {}
    function getAccumulatedSeverity(string memory district) public view returns (uint) {}
}