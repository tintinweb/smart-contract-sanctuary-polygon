// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./Ownable.sol";

contract ChallengeFee is Ownable {
    /**
    * This struct represents various settings related to fees.
    * The BASE_FEE field represents the base fee, expressed as a percentage and divided by 100.
    * The TOKEN_FEE field represents the fee charged in the token being traded, measured in ETH.
    */
    struct Settings {
        uint256 BASE_FEE; // base fee divided by 100
        uint256 TOKEN_FEE; // token fee divided by 100
    }
    
    // The SETTINGS variable holds the current settings for the contract.
    Settings public SETTINGS;
    
    /**
    *This is the constructor for the contract.
    *It initializes the SETTINGS variable with default values.
    */
    constructor(uint256 amountBaseFee, uint256 amountTokenFee){
        require(amountBaseFee >= 0 && amountTokenFee <= 100, "Amount base fee is not invalid");
        require(amountTokenFee >= 0 && amountTokenFee <= 100, "Amount token fee is not invalid");
        SETTINGS.BASE_FEE = amountBaseFee; 
        SETTINGS.TOKEN_FEE = amountTokenFee;
    }
    
    /**
    *This function returns the current base fee.
    *It is an external view function, which means it can be called from outside the contract and does not modify the contract state.
    *@return The current base fee, expressed as a uint256.
    */
    function getBaseFee() external view returns (uint256) {
        return SETTINGS.BASE_FEE;
    }
    
    /**
    *This function returns the current token fee.
    *It is an external view function, which means it can be called from outside the contract and does not modify the contract state.
    *@return The current token fee, expressed as a uint256.
    */
    function getTokenFee() external view returns (uint256) {
        return SETTINGS.TOKEN_FEE;
    }
    
    /**
    *This function sets the base and token fees.
    *It is an external function that can only be called by the contract owner, as specified by the onlyOwner modifier.
    *@param _baseFee The new base fee, expressed as a uint256 divided by 100.
    *@param _tokenFee The new token fee, expressed as a uint256.
    */
    function setFees(
        uint256 _baseFee,
        uint256 _tokenFee
    ) external onlyOwner {
        SETTINGS.BASE_FEE = _baseFee;
        SETTINGS.TOKEN_FEE = _tokenFee;
    }
}