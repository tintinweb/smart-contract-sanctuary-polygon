/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// File: contracts/HealthBlock.sol


pragma solidity >=0.7.0 <0.9.0;


contract HealthBlock{
    uint256 public totalBlocks = 0;

    string public name;

    mapping(uint256 => Insurance) public insurances;


    constructor(){
        name = "HealthBlock";
    }

    struct Insurance{
        uint256 id;
        address owner;
        uint256 age;
        string[] disease;
        bool initialised;
    }
    

    event InsuranceDataAdded(address owner, uint256 age);

    function InsuranceAdd(
        uint256 _age,
        string[] memory _disease
    ) public {
       
        require(_age > 0);
        totalBlocks++;

        Insurance storage newInsurance = insurances[totalBlocks];

        newInsurance.id = totalBlocks;
        newInsurance.owner = msg.sender;
        newInsurance.age = _age;
        newInsurance.disease =_disease;
        newInsurance.initialised =  true;
    
        emit InsuranceDataAdded(
            newInsurance.owner, 
            newInsurance.age
        );
    }
    function getCaseById(uint256 id)
        external
        view
        returns (
            address,
            uint256,
            string[] memory

        )
    {
        require(insurances[id].initialised, "No such insurance exists!");
        Insurance storage reqinsurance = insurances[id];
         
        return (
            reqinsurance.owner,
            reqinsurance.age,
            reqinsurance.disease
        );
    }

}