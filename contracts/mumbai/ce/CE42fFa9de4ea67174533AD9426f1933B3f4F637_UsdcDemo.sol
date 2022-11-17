/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Abstract
interface USDC {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// Contract
contract UsdcDemo{

    USDC public USDc;

    // Contract Owner
    address payable public owner; 

    constructor(address usdcContractAddress) {

        USDc = USDC(usdcContractAddress);

        // User who is calling this function address
        owner = payable(msg.sender);
    }


    function Fund(uint $USDC) public payable {

        // Transfer USDC to this contract from the sender account
        USDc.transferFrom(msg.sender, address(this), $USDC * 10 ** 6);  

        // Transfer to the owner
        //USDc.transfer(owner, $USDC * 10 ** 6);  
    }
    
    modifier onlyManger(){
        require(msg.sender==owner,"Only owner can calll this function");
        _;
    }

    function makePayment(address _recipient, uint256 _amount) public onlyManger{
        USDc.transfer(_recipient, _amount);
    }

    // Alternatively 
    // receive() payable external {

        // Send the fund to the owner of the contract.
       // owner.transfer(address(this).balance);
    // }      
}