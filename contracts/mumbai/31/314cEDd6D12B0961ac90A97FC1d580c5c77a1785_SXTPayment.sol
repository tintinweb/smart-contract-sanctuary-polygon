// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Admin related functionalities
/// @dev This conntract is abstract. It is inherited in SXTApi and SXTValidator to set and handle admin only functions

abstract contract Admin {
    /// @dev Address of admin set by inheriting contracts
    address public admin;

    /// @notice Modifier for checking if Admin address has called the function
    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "admin only function");
        _;
    }

    /**
     * @notice Get the address of Admin wallet
     * @return adminAddress Address of Admin wallet set in the contract
     */
    function getAdmin() public view returns (address adminAddress) {
        return admin;
    }

    /**
     * @notice Set the address of Admin wallet
     * @param  adminAddress Address of Admin wallet to be set in the contract
     */
    function setAdmin(address adminAddress) public onlyAdmin {
        admin = adminAddress;
    }
}

/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|         
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title SXTApi handles request from SXTClient
/// @dev This conntract will be deployed by SXT team, used to emit event which will be listened by Oracle node

interface ISXTPayment {

    /**
     * @notice Function to add price of a token address
     * @param  tokenAddress Token address to set the price
     * @param  tokenPrice Price for the token
     */
    function setTokenPrice(
        address tokenAddress,
        uint128 tokenPrice
    ) external;

    /**
     * @notice Function to get price of a token address
     * @param  tokenAddress ID for selecting cluster on Gateway
     */
    function getTokenPrice(
        address tokenAddress
    ) external returns (uint128);

    /**
     * @notice Function to add Price of a token address
     * @param  tokenAddress ID for selecting cluster on Gateway
     */
    function hasTokenPrice(
        address tokenAddress
    ) external returns (bool);
}

/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|         
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./abstract/Admin.sol";
import "./interfaces/ISXTPayment.sol";

/// @title SXTPayment handles prices of supported Tokens and Native currency for accepting prepaid requests in SXT Oracle
/// @dev This conntract will be deployed by SXT team, used to get and set prices of different tokens for SXT prepaid requests

contract SXTPayment is Admin, ISXTPayment {

    // Zero Address
    address constant ZERO_ADDRESS = address(0);

    // Mapping for Address of token to their price
    mapping (address => uint128) public tokenToPrice;

    /// @notice constructor sets the admin address of contract
    constructor() {
        admin = msg.sender;
    }

    /**
     * @notice Function to add price of a token address
     * @notice For Native currency, use address "0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF"
     * @param  tokenAddress Token address to set the price
     * @param  tokenPrice Price for the token
     */
    function setTokenPrice(
        address tokenAddress,
        uint128 tokenPrice
    ) external override onlyAdmin {
        require(tokenAddress != ZERO_ADDRESS, "SXTPayment: Cannot set to Zero Address");
        require(tokenPrice != 0, "SXTPayment: Cannot set to Zero Price");
        tokenToPrice[tokenAddress] = tokenPrice;
    }

    /**
     * @notice Function to get price of a token address
     * @param  tokenAddress ID for selecting cluster on Gateway
     */
    function getTokenPrice(
        address tokenAddress
    ) external view override returns (uint128){
        return tokenToPrice[tokenAddress];
    }

    /**
     * @notice Function to add Price of a token address
     * @param  tokenAddress ID for selecting cluster on Gateway
     */
    function hasTokenPrice(
        address tokenAddress
    ) public view override returns (bool){
        return tokenToPrice[tokenAddress] > 0;
    }

    modifier isTokenAvailable(address tokenAddress) {
        require(hasTokenPrice(tokenAddress), "SXTPayment: Token price not available");
        _;
    }
}