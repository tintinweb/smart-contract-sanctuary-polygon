/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IChainlink{

	function latestAnswer() external view returns(int256);
    function decimals() external view returns(uint8);
}

contract Oracle{

//-----------------------------------------------------------------------// v EVENTS

//-----------------------------------------------------------------------// v INTERFACES

    IChainlink constant private mu = IChainlink(maticusdAddress);

//-----------------------------------------------------------------------// v BOOLEANS

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private maticusdAddress = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Corporation.Oracle";

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

//-----------------------------------------------------------------------// v MODIFIERS

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function GetMATICPrice() public view returns(uint256){

        try mu.latestAnswer() returns(int256 answer){

            if(answer <=0)
                return(0);

            return(uint256(answer));
        }
        catch{ return(0); }
    }

    function GetMATICDecimals() public view returns(uint8, bool){

        try mu.decimals() returns(uint8 decimals){

            return(decimals, true);
        }
        catch{ return(0, false); }
    }
//-----------------------------------------------------------------------// v SET FUNTIONS

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        revert("Oracle receive reverted");
    }
    fallback() external{
        
        revert("Oracle fallback reverted");
    }
}