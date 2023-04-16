/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}

interface IPriceOracle {
    function getTokenPrice(address tokenAddress) external view returns (uint256);
}

contract GasFeeCalculator {
    
    uint256 constant private BASE_GAS = 21000; // Base gas cost for a transaction
    
    address private _nativeTokenAddress; // Address of the native token
    address private _priceOracleAddress; // Address of the external price oracle
    
    constructor(address nativeTokenAddress, address priceOracleAddress) {
        _nativeTokenAddress = nativeTokenAddress;
        _priceOracleAddress = priceOracleAddress;
    }
    
    function calculateGasFee(uint256 gasUsed) public view returns (uint256) {
        uint8 nativeTokenDecimals = IERC20(_nativeTokenAddress).decimals(); // Get the decimals of the native token
        uint256 nativeTokenBalance = IERC20(_nativeTokenAddress).balanceOf(address(this)); // Get the balance of the contract in native token
        uint256 nativeTokenPrice = IPriceOracle(_priceOracleAddress).getTokenPrice(_nativeTokenAddress); // Get the current price of the native token
        
        uint256 gasPrice = tx.gasprice;
        uint256 gasCostInWei = gasPrice * gasUsed;
        uint256 nativeTokenCost = gasCostInWei / nativeTokenPrice;
        
        uint256 nativeTokenDecimalFactor = 10 ** uint256(nativeTokenDecimals);
        uint256 nativeTokenCostInWei = nativeTokenCost * nativeTokenDecimalFactor;
        
        require(nativeTokenBalance >= nativeTokenCostInWei, "GasFeeCalculator: insufficient balance"); // Ensure the contract has enough balance to pay for the gas fees
        
        return nativeTokenCostInWei;
    }
    
    function setPriceOracleAddress(address priceOracleAddress) public {
        _priceOracleAddress = priceOracleAddress;
    }
    
    function withdrawNativeToken() public {
        uint256 nativeTokenBalance = IERC20(_nativeTokenAddress).balanceOf(address(this)); // Get the balance of the contract in native token
        require(nativeTokenBalance > 0, "GasFeeCalculator: no balance to withdraw"); // Ensure the contract has balance to withdraw
        
        // bool success = IERC20(_nativeTokenAddress).transfer(msg.sender, nativeTokenBalance); // Transfer the native token balance to the caller
        bool success = payable(msg.sender).send(nativeTokenBalance);
        require(success, "GasFeeCalculator: transfer failed");
    }
}