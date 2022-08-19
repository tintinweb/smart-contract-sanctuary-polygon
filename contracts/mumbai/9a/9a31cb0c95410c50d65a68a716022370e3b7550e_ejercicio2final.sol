/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract ejercicio2final {
    string name = "Santiago";
    uint money = 10000;
    bool isWork = true;
    address account = 0xc05550653a751BEF6f1bD785CB4dA6e544b40E77;

    function getName() external view returns (string memory) {
        return name;
    }

    function setName(string memory newName) external {
        name = newName;
    }

    function getMoney() external view returns (uint) {
        return money;
    }

    function setMoney(uint newMoney) external {
        money = newMoney; 
    }

    function getIswork() external view returns (bool) {
        return isWork;
    }

    function setIsWork(bool newIsWork) external {
        isWork = newIsWork;
    }

    function getAccount() external view returns (address) {
        return account;
    }

    function setAccount(address newAccount) external {
        account = newAccount;
    }
}