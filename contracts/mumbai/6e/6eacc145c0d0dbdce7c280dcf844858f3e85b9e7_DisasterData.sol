/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

pragma solidity ^0.8.16;

contract DisasterData {

    address public admin;
    uint public startDay;

    struct SeverityData {
        uint lastUpdatedDay;
        uint[] values;        // 0-100 indicating intensity
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

    function getAccumulatedSeverity(string memory district) public view returns (uint) {
        require(severity[district].lastUpdatedDay != 0, "Data not present for location");

        if(severity[district].values.length == 0) return 0;
        uint sumSeverity = 0;
        uint totalDays = severity[district].values.length < 10 ? severity[district].values.length : 10;
        for(uint i=severity[district].values.length-totalDays; i<severity[district].values.length; i++) {
            sumSeverity += severity[district].values[i];
        }
        return sumSeverity;
    }
    function trigger(string memory district) public view returns (string memory){
        require(severity[district].lastUpdatedDay != 0, "Data not present for location");

        if(severity[district].values.length == 0) return "you cannot collect the compensation now";
        uint sumSeverity = 0;
        uint totalDays = severity[district].values.length < 10 ? severity[district].values.length : 10;
        for(uint i=severity[district].values.length-totalDays; i<severity[district].values.length; i++) {
            sumSeverity += severity[district].values[i];
        }
        
        if(sumSeverity>=100) return "you can collect compensation now";
        else return "you cannot collect compensation now" ;

    }
     struct Farmerdetails{
        string name;
        string district;
        uint amountpaid;

      }



     mapping(uint => Farmerdetails) private _farmer;
     mapping(uint => SeverityData) private _district;

     uint public totalfarmers;



     function enroll(string memory name_,string memory district1_) external{

         _farmer[totalfarmers].name = name_;
         _farmer[totalfarmers].district = district1_;
         _farmer[totalfarmers].amountpaid = 0;
         totalfarmers += 1;
     }
     

     function getfarmerdetails(uint farmernumber_) external view  returns (Farmerdetails memory){

         return _farmer[farmernumber_];
     }
      struct Payment {
        uint amount;
        uint timestamp;
    }

    mapping(uint => Payment[]) public mainMap;


    function deposit(uint farmernumber_)
    external payable
    {
      
       Payment[] storage payment = mainMap[msg.value];
       payment.push(Payment({amount: msg.value, timestamp: block.timestamp}));
       mainMap[msg.value] = payment;
       _farmer[farmernumber_].amountpaid+= msg.value;

      
    }


    
    


   

   
}