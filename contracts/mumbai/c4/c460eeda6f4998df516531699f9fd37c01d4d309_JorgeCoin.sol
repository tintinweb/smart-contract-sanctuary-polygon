/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//Create a Smart Contract called “TuNombreCoin”
contract JorgeCoin {
    //Save the "maxTotalSupply" initialized to a number
    uint maxTotalSupply = 55555;
    //A function called "setMaxTotalSupply" to modify that variable
    //A function called "getMaxTotalSupply" that returns the maxTotalSupply
    function getmaxTotalSupply() public view returns (uint){
        return maxTotalSupply;
    }

    function setmaxTotalSupply(uint newMaxTotalSupply) public {
        maxTotalSupply = newMaxTotalSupply;
    }
    //Keep "owner" initialized to an address
    //A function called "getOwner" that returns the address of the owner
     function getowner() public pure returns (address){
        address owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        return owner;
    }
    //Save token name
    function getTokenName() public pure returns (string memory){
        string memory TokenName= "JorgeCoin";
        return TokenName;
    }
    //Save token symbol
    function getTokenSymbol() public pure returns (string memory){
        string memory TokenSymbol = "JRG";
        return TokenSymbol;
    }
}