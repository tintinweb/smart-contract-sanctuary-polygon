/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract DisasterData {

    address public admin;
    uint public startDay;

    struct SeverityData {
        uint lastUpdatedDay;
        uint[] values;  
        uint[] firstUpdatedDay;      // 0-100 indicating intensity
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
        severity[district].firstUpdatedDay.push(currentDay);
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

    function getAccumulatedSeverity(string memory district) public view returns (uint) {
        require(severity[district].lastUpdatedDay != 0, "Data not present for location");

        if(severity[district].values.length == 0) return 0;
        uint sumSeverity = 0;
        uint totalDays = severity[district].values.length < 10 ? severity[district].values.length : 10;
        for(uint i=severity[district].values.length-totalDays; i<severity[district].values.length; i++) {
            sumSeverity += severity[district].values[i];

        }
        uint daysCount = severity[district].lastUpdatedDay - severity[district].firstUpdatedDay[0] +1;
        return sumSeverity / daysCount;
    }
    
     uint public totalPremiumSum;
     bool public isChecked = false;

    struct transactionData {
        string district;
        uint amount;
        uint farmerId;
        uint transactionId;
        uint claimDay;
        uint lastUpdatedDay;    // 0-100 indicating intensity  // values - amount
    }
         
      mapping(uint => transactionData) public _amountPaid;
      uint public transactionId; 
      
      function enrollTrans(string memory district, uint farmerId, uint amount) external payable
       {
        require(isChecked == false);
        _amountPaid[transactionId].district = district;
        _amountPaid[transactionId].farmerId = farmerId;
       // _amountPaid[transactionId].amount = amountPaid;  
        _amountPaid[transactionId].amount = msg.value;  
        _amountPaid[transactionId].lastUpdatedDay= block.timestamp / 2 minutes;
       // _amountPaid[transactionId].transactionId = transactionId;
        totalPremiumSum += amount;
        transactionId+=1; 
      }
      
    function getFarmerDetails(uint Id) external view returns(transactionData memory){
        return _amountPaid[Id];
    }

    modifier checkTrigger {
      require(isChecked == true);
      _;
   }

    uint public totalFarmer;
    uint public totalClaimAmount;
    uint public totalSeverity;
    uint public totalClaimDays;
    uint[] private amount_arr;
    uint[] private claim_def_arr;
    uint[] private severity_def_arr;
    uint[] private id_arr;

    function makeClaim(string memory district, uint farmerId, uint transactionId) public  checkTrigger returns(uint)
    {   
        totalFarmer +=1 ;
        uint get_severity = getAccumulatedSeverity(district);
        
        amount_arr.push( _amountPaid[transactionId].amount);
        id_arr.push(farmerId);
        severity_def_arr.push(get_severity);

        uint getAmount = _amountPaid[transactionId].amount;
        uint getDayOfEntry = _amountPaid[transactionId].lastUpdatedDay;
        uint claimDef = (_amountPaid[transactionId].claimDay =  block.timestamp / 2 minutes) - getDayOfEntry; 
       
        totalClaimAmount += _amountPaid[transactionId].amount;
        totalClaimDays +=claimDef;
        totalSeverity +=get_severity;
        claim_def_arr.push( claimDef);   
        return _amountPaid[transactionId].claimDay =  block.timestamp / 2 minutes;
    }
     
    function amount_def_logic() private returns(uint[] memory)
    {
        for(uint i ;i<totalFarmer;i++) 
        {
            uint ans = ((amount_arr[i])/totalClaimAmount)*totalPremiumSum;
            amount_arr[i] = ans;
        }
        return amount_arr;
    }

    function claim_def_logic() private returns(uint[] memory)
    {
        for(uint i;i<totalFarmer;i++)
        {
            uint ans = ((claim_def_arr[i])/totalClaimDays)*totalPremiumSum;
            claim_def_arr[i] = ans;
        }
        return claim_def_arr;
    }

    function severity_def_logic() private returns(uint[] memory)
    {
        for(uint i;i<totalFarmer;i++)
        {
            uint ans = ((severity_def_arr[i])/totalSeverity)*totalPremiumSum;
            severity_def_arr[i] = ans;
        }
        return severity_def_arr;
    }

    uint[] public final_arr;

    function sum_of_distribution() public returns(uint[] memory)
    {
        amount_def_logic();
        claim_def_logic();
        severity_def_logic();
        for(uint i;i<totalFarmer;i++)
        {
            uint ans = (amount_arr[i] + severity_def_arr[i] + claim_def_arr[i]) / 3;
            final_arr[i] = ans;
        }
        return final_arr;
    }

    function setTrigger() public  returns (bool)
    {
        isChecked = true; 
        return isChecked; // return boolean value true
    }

}