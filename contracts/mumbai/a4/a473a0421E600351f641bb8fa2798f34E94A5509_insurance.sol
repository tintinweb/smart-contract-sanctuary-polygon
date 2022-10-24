/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract insurance {

    address public admin;
    uint public startDay;

    struct SeverityData {
        uint lastUpdatedDay;
        uint[] values;        // 0-100 indicating intensity assuming that 0 to 20 is normal intensity and it increases by 1 every 20 interval
    }

    mapping(string => SeverityData) public severity;

    constructor() {
        admin = msg.sender;
        startDay = block.timestamp / 5 minutes;
    }

    function setSeverity(string memory district, uint newSeverity) public {
        require(msg.sender == admin, "Only admin can set data");
        require(newSeverity<=100, "Severity exceeds max value of 100");
        uint currentDay = block.timestamp / 5 minutes;
        
        uint currentValue;
        if(severity[district].lastUpdatedDay != 0) {
            currentValue = severity[district].values[severity[district].values.length-1];
        }
        else {
            SeverityData memory data;
            data.lastUpdatedDay = startDay-1;
            severity[district] = data;
            currentValue = 0;
        }
        for(uint i=severity[district].lastUpdatedDay+1; i<currentDay; i++) {
            severity[district].values.push(currentValue);
        }
        severity[district].values.push(newSeverity);
        severity[district].lastUpdatedDay = currentDay;
    }

    function getSeverityData(string memory district, uint day) public view returns (uint){
        require(severity[district].lastUpdatedDay != 0, "Data not present for location");
        require(startDay <= day, "Day should be greater than startDay");
        if(severity[district].lastUpdatedDay > day) return severity[district].values[day-startDay];
        else return severity[district].values[severity[district].values.length-1];
    }

    function getDistricts() public pure returns (string memory) {
        return "Ahmednagar, Akola, Amravati, Aurangabad, Beed, Bhandara, Buldhana, Chandrapur, Dhule, Gadchiroli, Gondia, Hingoli, Jalgaon, Jalna, Kolhapur, Latur, Mumbai City, Mumbai Suburban, Nagpur, Nanded, Nandurbar, Nashik, Osmanabad, Palghar, Parbhani, Pune, Raigad, Ratnagiri, Sangli, Satara, Sindhudurg, Solapur, Thane, Wardha, Washim, Yavatmal";
    }

    function getAverageSeverity(string memory district) public view returns (uint) {
        require(severity[district].lastUpdatedDay != 0, "Data not present for location");

        if(severity[district].values.length == 0) return 0;
        uint sumSeverity = 0;
        uint totalDays = severity[district].values.length < 10 ? severity[district].values.length : 10;
        for(uint i=severity[district].values.length-totalDays; i<severity[district].values.length; i++) {
            sumSeverity += severity[district].values[i];
        }
        return sumSeverity/totalDays;
    }

    function CurrentDay() public view returns (uint){
        uint currentDay = block.timestamp / 5 minutes;
        return currentDay;
    }

    // Until here is the oracle contract below begins the insurance smart contract
    // modified getAccumaltedSeverity to getAvergaeSeverity  
    // making the basic struct for each individual farmer
    struct farmer
    {
        string name;
        address hash;
        uint[] premium;
        uint[] dayPaid;
        string district;
        uint code;
    }
    // creating an array of farmer called farmers
    mapping(uint => farmer) farmers;
    uint public totalFarmers=0; //counter for total number of farmers
    // function to register a farmer to farmers mapping. Assumed that district is on of the available ones
    function Register(string memory name_ , string memory district_ ) payable public returns(uint){
        farmers[totalFarmers].name=name_;
        farmers[totalFarmers].district=district_;
        farmers[totalFarmers].premium.push(msg.value);
        farmers[totalFarmers].hash=msg.sender;
        farmers[totalFarmers].dayPaid.push(block.timestamp / 5 minutes);
        farmers[totalFarmers].code=totalFarmers;
        totalFarmers++; // increment total number of farmers
        return totalFarmers-1; // returning each farmer thier code
    }

    //function for a farmer to add premium to their registered account
    function addPremium(uint  code_) payable public{
        require(farmers[code_].hash==msg.sender, "Create account if not currently registered or enter correct code for account");
        uint currentDay=block.timestamp / 5 minutes;
        farmers[code_].dayPaid.push(currentDay);
        farmers[code_].premium.push(msg.value);
    }

    /*function getCode() public view returns(uint){
        uint i;
        for(i=0;i<totalFarmers;i++)
        {
            if(msg.sender==farmers[i].hash)
            break;
        }
        if(totalFarmers==i)
        require(false,"No code exists for this address");
        else
        return i;
        
    }*/ 

    function triggerClaim(uint  code_ ) public{
        require(farmers[code_].hash==msg.sender, "Create account if not currently registered or enter correct code for account");
        require(severity[farmers[code_].district].lastUpdatedDay != 0, "Data not present for location");
        require(getAverageSeverity(farmers[code_].district)>=20, "No reason to trigger claim"); 
        uint currentDay=block.timestamp / 5 minutes;
        uint  payout=0;
        uint  noOfDays;
        
        for(uint i= 0;i<farmers[code_].premium.length;i++)
        {
            noOfDays=currentDay - farmers[code_].dayPaid[i];
            if(noOfDays >= 365 || noOfDays <50) // assuming that each premium payment lasts for a year
            continue;                           // and the premium wont activate for the first 50 days
            uint averageSeverity=getAverageSeverity(farmers[code_].district); 
// formula for calculating payout which can be upto 36x the premium no of days since premium has
// a maximum of 4x return and average severity has a maximum of 9x return
            payout+=farmers[code_].premium[i]*(1+noOfDays*4/365)*(averageSeverity/10);
            farmers[code_].premium[i]=0;
        }      
        require(payout!=0,"No Claim available");
        payable(msg.sender).transfer(payout);// payout transfered to the person who triggered claim
    }
}