/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Clase_2_Tarea {
    
    string web_3_name = "CryptoGBA";
    address eth_address = 0x20097E8444e6b241bbc93a92e342fF5e476DeAa3;
    uint balance = 10000;
    bool isBalance_real = false;
    

    function getWeb_3_name() external view returns (string memory){
        return web_3_name;
    }
    function setWeb_3_name(string memory betterWeb_3_name) external {
        web_3_name = betterWeb_3_name;
    }

    function getEth_address() external view returns (address) {
        return eth_address;
    }
    function setEth_address (address newEth_address) external {
        eth_address = newEth_address;
    }

    function getBalance() external view returns (uint) {
        return balance;
    }
    function setBalance (uint wishedBalance) external {
        balance = wishedBalance;
    }

    function getIsBalance_real() external view returns (bool) {
        return isBalance_real;
    }
    function setIsBalance_real(bool newIsBalance_real) external {
        isBalance_real = newIsBalance_real;
    }
    
}