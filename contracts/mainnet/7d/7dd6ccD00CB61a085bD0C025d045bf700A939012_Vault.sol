/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IParent{

    function GetContractAddress(string calldata name) external view returns(address);
}

contract Vault{

//-----------------------------------------------------------------------// v EVENTS

    event VaultWithdraw(uint256 amount);
    event Deposit(address indexed from, uint256 amount);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x163342FAe2bBe3303e5A9ADCe4BC9fb44d0FF062;

//-----------------------------------------------------------------------// v NUMBERS

    uint256 private totalMATIC = 0;

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Corporation.Vault";

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

//-----------------------------------------------------------------------// v MODIFIERS

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function GetTotalMATIC() public view returns(uint256){

        return(totalMATIC);
    }

    function GetCurrentMATIC() public view returns(uint256){

        return(address(this).balance);
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function ClerkWithdraw(uint256 _amount) public returns(bool){

        if(reentrantLocked == true)
            revert("Reentrance failed");

        reentrantLocked = true;

        address clerkAddress = pt.GetContractAddress(".Corporation.Clerk");

        if(clerkAddress != msg.sender)
            revert("Clerk only");

        (bool sent,) = payable(address(clerkAddress)).call{value : _amount}("");

        if(sent != true)
           revert("ClerkWithdraw failed");

        reentrantLocked = false;

        emit VaultWithdraw(_amount);
        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        totalMATIC += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external{

        revert("Vault fallback reverted");
    }
}