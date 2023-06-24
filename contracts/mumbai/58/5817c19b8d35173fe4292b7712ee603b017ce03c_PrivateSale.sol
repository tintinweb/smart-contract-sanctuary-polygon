/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract PrivateSale {
    // Token details
    string public constant tokenName = "ESQ Token";
    string public constant tokenSymbol = "ESQ";
    uint256 public constant tokenDecimals = 18;
    uint256 public constant tokenTotalSupply = 100000000 * (10**tokenDecimals);

    // Token price: 1 MATIC = 20000 ESQ
    uint256 public constant tokenPrice = 20000;

    // Wallet address of the contract creator
    address public owner;

    // Address of the ESQ token contract
    address public esqTokenAddress;

    // Mapping to track token balances
    mapping(address => uint256) public balances;

    // Event triggered on token purchase
    event TokensPurchased(address indexed buyer, uint256 amountMATIC, uint256 amountESQ);

    constructor(address _esqTokenAddress) {
        owner = msg.sender;
        esqTokenAddress = _esqTokenAddress;
        balances[_esqTokenAddress] = tokenTotalSupply;
    }

    // Modifier to restrict access to the owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Function to buy tokens during private sale
    function buyTokens() external payable {
        require(msg.value > 0, "No MATIC sent");

        uint256 amountMATIC = msg.value;
        uint256 amountESQ = amountMATIC * tokenPrice;

        require(amountESQ > 0, "Insufficient MATIC sent");

        // Check if the contract has enough tokens to sell
        require(amountESQ <= balances[esqTokenAddress], "Insufficient tokens available for sale");

        // Transfer tokens to the buyer
        balances[esqTokenAddress] -= amountESQ;
        (bool success, ) = esqTokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amountESQ));
        require(success, "Token transfer failed");

        // Emit event
        emit TokensPurchased(msg.sender, amountMATIC, amountESQ);
    }

    // Function to withdraw unsold tokens by the owner
    function withdrawUnsoldTokens() external onlyOwner {
        uint256 unsoldTokens = balances[esqTokenAddress];
        require(unsoldTokens > 0, "No unsold tokens to withdraw");

        balances[esqTokenAddress] = 0;
        (bool success, ) = esqTokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", owner, unsoldTokens));
        require(success, "Token transfer failed");

        // You can emit an event here to track the withdrawal if needed
    }

    // Function to withdraw MATIC from the contract
    function withdrawMATIC() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No MATIC to withdraw");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "MATIC withdrawal failed");

        // You can emit an event here to track the withdrawal if needed
    }

    // Function to add the ESQ token contract address
    function addESQToken(address _esqTokenAddress) external onlyOwner {
        require(_esqTokenAddress != address(0), "Invalid token address");
        esqTokenAddress = _esqTokenAddress;
    }
}