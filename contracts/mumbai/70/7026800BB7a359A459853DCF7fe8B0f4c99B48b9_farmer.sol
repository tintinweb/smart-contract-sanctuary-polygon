/**
 *Submitted for verification at polygonscan.com on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import "./DisasterData.sol";

interface DisasterInterface  {
     function setSeverity(string memory district, uint newSeverity) external;
     function getSeverityData(string memory district, uint day) external view returns (uint);
     function getDistricts() external pure returns (string memory);
     function getAccumulatedSeverity(string memory district) external view returns (uint);
}

contract farmer{

    DisasterInterface d = DisasterInterface(0xaD736Bb2D21e38e9978592904ea746Af489476e6);

    enum triggerStatus{on,off}
    triggerStatus public currentStatus;

    constructor (){
        currentStatus = triggerStatus.off;
    }

    mapping(uint => Farmer) public myInfo;
    mapping(string => uint) public districtSeverity;
    struct Farmer{
        string name;
        string district;
        uint depositedMoney;
        uint timeofdeposit;
    }

    uint public totalMoney;
    uint public viewBalance = totalMoney;
    uint public timeofwithdraw;
    bool public trigerred = false;
    uint totalSeverity = 0;
    string[36] dist = ["Ahmednagar", "Akola", "Amravati", "Aurangabad", "Beed", "Bhandara", "Buldhana", "Chandrapur", "Dhule", "Gadchiroli", "Gondia", "Hingoli", "Jalgaon", "Jalna", "Kolhapur", "Latur", "Mumbai City", "Mumbai Suburban"," Nagpur"," Nanded", "Nandurbar"," Nashik", "Osmanabad", "Palghar", "Parbhani"," Pune", "Raigad", "Ratnagiri", "Sangli", "Satara", "Sindhudurg", "Solapur", "Thane", "Wardha", "Washim", "Yavatmal"];
    uint[36] severity;
    uint[] payTime;
    uint[] ids;
    uint totalTimeDif;
    uint totalPercentage;
   


   function addFarmerInfo(uint _id,string memory _name,string memory _district) public {
        myInfo[_id] = Farmer(_name,_district,0,0);
        ids.push(_id);

    }

    modifier ifNotTrigger{
        require(currentStatus == triggerStatus.off);
        _;
    }
    function payInsurance(uint _id) external payable ifNotTrigger {
        myInfo[_id].depositedMoney += msg.value;
        totalMoney += msg.value;
        myInfo[_id].timeofdeposit = block.timestamp;
        payTime.push(myInfo[_id].timeofdeposit);
        
    }
    function getFarmerDetails(uint _id) external view returns (Farmer memory) {
        return myInfo[_id];
    }

    function claimInsurance(uint _id) payable external {
        
        if(currentStatus == triggerStatus.off){
            timeofwithdraw = block.timestamp;
            for(uint i=0;i<36;i++){
                totalSeverity += d.getAccumulatedSeverity(dist[i]);
                districtSeverity[dist[i]] = d.getAccumulatedSeverity(dist[i]);
            }

            for(uint i=0;i< payTime.length;i++){               
                totalTimeDif += (timeofwithdraw - payTime[i]);
            }
            for(uint i=0;i< ids.length;i++){
                uint ownSeverity1 = (districtSeverity[myInfo[ids[i]].district] *100)/totalSeverity; // severity factor
                uint ownDeposit1 = (myInfo[ids[i]].depositedMoney*100)/totalMoney; // deposit factor
                uint timeFactor1 = ((timeofwithdraw -myInfo[ids[i]].timeofdeposit)*100)/ totalTimeDif; // timeFactor
                uint averagePercentage1 = ownSeverity1 +ownDeposit1 + timeFactor1;
                
                totalPercentage += averagePercentage1;
            }
        }

        uint ownSeverity = (districtSeverity[myInfo[_id].district] *100)/totalSeverity; // severity factor
        uint ownDeposit = (myInfo[_id].depositedMoney*100)/totalMoney; // deposit factor
        uint timeFactor = ((timeofwithdraw -myInfo[_id].timeofdeposit)*100)/ totalTimeDif; // timeFactor
        uint averagePercentage =  ownSeverity + ownDeposit + timeFactor;
        
        uint finalPercentge = averagePercentage / totalPercentage;
        uint finalInsurance = (totalMoney*finalPercentge) / 100;
          
        payable(msg.sender).transfer(finalInsurance);
    }
    function foo() external pure returns(string memory){
        DisasterInterface di = DisasterInterface(0xaD736Bb2D21e38e9978592904ea746Af489476e6);
        return di.getDistricts();
    }  

}