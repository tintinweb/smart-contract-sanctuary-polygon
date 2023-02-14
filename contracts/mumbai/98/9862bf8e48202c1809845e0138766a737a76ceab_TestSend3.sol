/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


abstract contract InterfaceCT{
    function balanceOf(address account) external view virtual returns (uint256);
    function transfer(address to, uint256 amount) external virtual returns (bool);
}


contract TestSend3{

    function sendNecesToken (address payable account) public returns (string memory){
        if(checkBalMatic(account) && checkBalCT(account)){
            sendMatic(account);
            sendCT(account);
            return "send Matic and CT";

        } else if (checkBalMatic(account)){
            sendMatic(account);
            return "send Matic";

        } else if (checkBalCT(account)){
            sendCT(account);
            return "send CT";

        } else {
            return "you have all the necessary tokens";
        }
    }

    function checkBalMatic (address account) public view returns(bool){
        uint minMatic = 0.02e18;

        uint balanceMatic = address(account).balance;

        if(balanceMatic < minMatic){
            return true;
        } else {
            return false;
        }
    }

    function checkBalCT (address account) public view returns(bool){
        address addressCT = 0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5;
        InterfaceCT ctContract = InterfaceCT(addressCT);

        uint minCT = 10000e18;
        uint balanceCT = ctContract.balanceOf(account);

        if(balanceCT < minCT){
            return true;
        } else {
            return false;
        }
    }

    function sendMatic(address payable account) public{
        account.transfer(0.3e18);
    }

    function sendCT(address payable account) public{
        address addressCT = 0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5;
        InterfaceCT ctContract = InterfaceCT(addressCT);

        ctContract.transfer(account, 10000e18);
    }

    //function pay() payable public{}
    receive() external payable{}
}