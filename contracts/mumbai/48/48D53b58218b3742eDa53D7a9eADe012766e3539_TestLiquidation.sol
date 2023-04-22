// SPDX-License-Identifier: MIT

// **** Test Liquidation Contract deployed to: 0x7DDb956C769b110AEe637244CEF33E79c8D59fD6 ****

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
        for(uint8 i = 1; i <= _user.length; i++){
            emit MortgageLiquidated(_user[i], _mortgageID[i]);
        }
    }

}