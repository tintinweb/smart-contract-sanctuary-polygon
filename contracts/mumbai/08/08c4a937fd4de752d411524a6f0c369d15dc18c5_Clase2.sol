/**
 *Submitted for verification at polygonscan.com on 2022-09-03
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Clase2 {
    string name = "Yamaha Tenere";
    uint horsepower = 45;
    bool isMotorbike = true;
    address account = 0x5d91C94fd64a08f9b9812c22f4da940b8ceDa4ee;
    
    function getName() external view returns (string memory) {
        return name;
    }

    function setName(string memory newName) external {
        name = newName;
    }

    function getHorsepower () external view returns (uint) {
        return horsepower;
    }

    function setHorsepower (uint newHorsepower) external {
        horsepower = newHorsepower;
    }

    function getIsMotorbike () external view returns (bool) {
        return isMotorbike;
    }

    function setIsMotorbike (bool newIsMotorbike) external {
        isMotorbike = newIsMotorbike;
    }

    function getAccount () external view returns (address) {
        return account;
    }
    
    function setAccount (address newAccount) external {
        account = newAccount;
    }
    

    

    
}