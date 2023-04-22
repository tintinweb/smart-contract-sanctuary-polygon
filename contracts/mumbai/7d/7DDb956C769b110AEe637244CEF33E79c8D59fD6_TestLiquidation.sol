// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
contract TestLiquidation {
    address private owner;

    event MortgageLiquidated(address user, uint256 mortgageID);

    error NotOwner();
    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        if(msg.sender != owner){
            revert NotOwner();
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