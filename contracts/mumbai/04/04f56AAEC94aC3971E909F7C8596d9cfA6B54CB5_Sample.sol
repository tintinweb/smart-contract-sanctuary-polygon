// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;



contract Sample {


    string data;    

    function setData(string memory _data) public returns (string memory testdata) {
        data = _data;
         
        return "TestData"; 
    }


}