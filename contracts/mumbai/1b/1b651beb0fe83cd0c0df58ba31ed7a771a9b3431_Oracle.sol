/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Oracle {
    uint256 public currentMarketPrice;
    uint256 public targetPrice;
    address public Owner;

    modifier onlyOwner{
        msg.sender == Owner;
        _;
    }
    
    function pushMarketReport(uint256 currentMarketPrice_) external onlyOwner{
        currentMarketPrice = currentMarketPrice_;
    }

    function setTargetPrice(uint256 setTargetPrice_) external onlyOwner{
        targetPrice = setTargetPrice_;
    }

    function getMarketData() external returns (uint256, bool){
        return (currentMarketPrice, true);
    }
     
    function getTargetData() external returns(uint256, bool){
        return (targetPrice, true);
    }

}