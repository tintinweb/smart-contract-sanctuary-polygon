/**
 *Submitted for verification at polygonscan.com on 2022-08-16
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Noob2 {
    string name = "Noobieplus";
    
    function getName() external view returns (string memory) {
        return name;
    }

    function setName(string memory newName) external {
        name = newName;
    }

    address myAddress = 0x423621013e46F834dE9C01710e2eC278574BBF61;

    function getAddress() external view returns (address) {
        return myAddress;
    } 

    function setAddress(address newAddress) external {
        myAddress = newAddress;
    }

    bool iamNoobie = true;

    function getBool() external view returns (bool) {
        return iamNoobie;
    }

    function setBool(bool newBool) external {
        iamNoobie = newBool; 
    }

    uint howMuch = 1000;

    function getUint() external view returns (uint) {
        return howMuch;
    }

    function setUint(uint newUint) external {
        howMuch = newUint;
    }
}