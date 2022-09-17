/**
 *Submitted for verification at polygonscan.com on 2022-09-17
*/

// File: contracts/final.sol


// final implementation of the smart contract

pragma solidity  >=0.7.0 < 0.9.0;

contract patient_vault{

    struct data_struct {

        string patient_name1;
        string patient_name2;
    }   

    data_struct data_curr;

    function AddVals(string memory st1, string memory st2) public {
        data_curr = data_struct(st1,st2);
    }

    function GetVal1() public view returns (string memory){

        return data_curr.patient_name1; 
    
    }

    function GetVal2() public view returns (string memory){

        return data_curr.patient_name2; 
    
    }
    
    
}