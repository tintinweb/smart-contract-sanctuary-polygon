/**
 *Submitted for verification at polygonscan.com on 2022-06-27
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
// https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

contract InterestProxy{

//// This contract is an attachment that allows you to use interestprotocol.io with a special feature that lets you place a bounty for MEVers
//// that repay the loan in exchange for a bounty

    // How to setup this contract

    // Step 1: Configure the contstructor to the values you want, make sure to double and triple check!
    // Step 2: Deploy the contract.
    // Step 3: Approve USDi for use on this contract.
    // Step 4: Send some ETH to this contract for the bounty


//// Commissioned by Fishy#0007 on 6/17/2022

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.

    address public admin;
    ERC20 USDi = ERC20(0x203c05ACb6FC02F5fA31bd7bE371E7B213e59Ff7);
    VaultController public Vault = VaultController(0x385E2C6b5777Bc5ED960508E774E4807DDe6618c);
    uint public VaultID;
    uint public bounty;
    uint public MINLTV;

    modifier onlyAdmin{

        require(admin == msg.sender, "You can't call this admin function because you are not the admin (duh)");
        _;
    }
    
    constructor(){

        admin = msg.sender;
        VaultID = 57; // <------- MAKE SURE THIS IS RIGHT!!!!!!!
        MINLTV = 60;
    }

    function ClaimBounty() public{

        require(MINLTV <= CalculateLTV(), "The bounty cannot be claimed yet");

        // Send all USDi from fishy to this contract

        USDi.transferFrom(admin, address(this), USDi.balanceOf(admin));

        // If you have enough to pay the entire thing do it, if you don't then just pay what you can

        if(Vault.vaultLiability(VaultID) < USDi.balanceOf(address(this))){Vault.repayAllUSDi(VaultID);}
        else{Vault.repayUSDi(VaultID, USDi.balanceOf(address(this)));}

        // Give the bounty to the kind MEVer who called this (thank you)

        (bool sent,) = msg.sender.call{value: bounty}("");
        require(sent, "Looks like someone claimed the bounty first, sorry!");

        // Send any remaining USDi to fishy

        USDi.transfer(admin, USDi.balanceOf(address(this)));
    
    }

    // Functions that let you change values like the trigger LTV or the bounty amount

    function EditBounty(uint HowMuch) public onlyAdmin{bounty = HowMuch;}
    function EditTriggerLTV(uint HowMuch) public onlyAdmin{MINLTV = HowMuch;}
    function EditVaultID(uint WhatID) public onlyAdmin{VaultID = WhatID;}

    // You can withdraw extra ETH held by this contract using this function

    function withdrawETH(uint HowMuch) public onlyAdmin{

        (bool sent,) = admin.call{value: HowMuch}("");
        require(sent, "Looks like someone claimed the bounty first, sorry!");
    }

    // a function that lets MEVers know if the bounty is claimable or not

    function CalculateLTV() public view returns(uint){

        uint MAXLTV = Vault.vaultLiability(VaultID) + Vault.vaultBorrowingPower(VaultID);
        uint FULLLTV = (1176470588235294 * MAXLTV)/10e15;


        return Vault.vaultLiability(VaultID)*(FULLLTV/10e16);
    }
}

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

interface ERC20{

    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
}

interface VaultController{

    function repayUSDi(uint256 id, uint256 amount) external;
    function repayAllUSDi(uint256 id) external;
    function vaultBorrowingPower(uint256 id) external view returns (uint192);
    function vaultLiability(uint256 id) external view returns (uint192);
}