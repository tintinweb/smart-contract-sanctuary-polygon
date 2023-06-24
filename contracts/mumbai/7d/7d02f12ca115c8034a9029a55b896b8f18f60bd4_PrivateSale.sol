/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PrivateSale {
    // Token details
    string public constant tokenName = "ESQ Token";
    string public constant tokenSymbol = "ESQ";
    uint256 public constant tokenDecimals = 18;
    uint256 public constant tokenTotalSupply = 100000000 * (10**tokenDecimals);
    
    // Token price: 1 MATIC = 20000 ESQ
    uint256 public constant tokenPrice = 20000;

    // Wallet address of the contract creator
    address public creatorWallet;

    // Address of the ESQ token contract
    address public esqTokenAddress;

    // Mapping to track token balances
    mapping(address => uint256) public balances;

    // Event triggered on token purchase
    event TokensPurchased(address indexed buyer, uint256 amountMATIC, uint256 amountESQ);

    constructor(address _esqTokenAddress) {
        creatorWallet = msg.sender;
        esqTokenAddress = _esqTokenAddress;
        balances[msg.sender] = tokenTotalSupply;
    }

    // Function to buy tokens during private sale
    function buyTokens() external payable {
        require(msg.value > 0, "No MATIC sent");
        
        uint256 amountMATIC = msg.value;
        uint256 amountESQ = amountMATIC * tokenPrice;
        
        require(amountESQ > 0, "Insufficient MATIC sent");

        // Check if the contract has enough tokens to sell
        require(amountESQ <= balances[creatorWallet], "Insufficient tokens available for sale");

        // Transfer tokens to the buyer
        balances[creatorWallet] -= amountESQ;
        (bool success, ) = esqTokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amountESQ));
        require(success, "Token transfer failed");

        // Emit event
        emit TokensPurchased(msg.sender, amountMATIC, amountESQ);
    }

    // Function to withdraw unsold tokens by the contract creator
    function withdrawUnsoldTokens() external {
        require(msg.sender == creatorWallet, "Only contract creator can withdraw unsold tokens");

        uint256 unsoldTokens = balances[creatorWallet];
        require(unsoldTokens > 0, "No unsold tokens to withdraw");

        balances[creatorWallet] = 0;
        (bool success, ) = esqTokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", creatorWallet, unsoldTokens));
        require(success, "Token transfer failed");

        // You can emit an event here to track the withdrawal if needed
    }
}