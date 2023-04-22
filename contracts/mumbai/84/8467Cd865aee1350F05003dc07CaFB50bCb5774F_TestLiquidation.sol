// SPDX-License-Identifier: MIT

// **** Test Liquidation Contract deployed to: 0x48D53b58218b3742eDa53D7a9eADe012766e3539 ****

pragma solidity 0.8.16;

contract TestLiquidation {
    address private owner;

    event MortgageLiquidated(address user, uint256 mortgageID);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        if(msg.sender != owner){
            revert("Not the owner");
        }
        _;
    }

    function simulateLiquidation(address[] memory _user, uint256[] memory _mortgageID) external onlyOwner{
        if(_user.length != _mortgageID.length){
            revert("Arrays Mismatch");
        }
        for(uint8 i = 0; i < _user.length; i++){
            emit MortgageLiquidated(_user[i], _mortgageID[i]);
        }
    }

}