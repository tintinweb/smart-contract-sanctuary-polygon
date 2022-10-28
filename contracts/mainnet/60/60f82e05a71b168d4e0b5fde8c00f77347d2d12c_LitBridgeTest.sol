/**
 *Submitted for verification at polygonscan.com on 2022-10-28
*/

/*
Created, deployed, run, managed and maintained by CodeCraftrs
https://codecraftrs.com
*/

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None

pragma solidity 0.8.17;

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract LitBridgeTest {
    address private constant SERVER = 0x78051f622c502801fdECc56d544cDa87065Acb76;
    address private constant CEO = 0x7c4ad2B72bA1bDB68387E0AE3496F49561b45625;
    address public constant LIT = 0x01015DdbeaF37A522666c4B1A0186DA878c30101;
    mapping (string => bool) public bridgingCompleted;
    uint256 public feeInNative;
    uint256 public myChain;

    modifier onlyBridge() {
        if(msg.sender != SERVER) return;
         _;
    }
    
    modifier onlyOwner() {
        if(msg.sender != CEO) return;
         _;
    }

    event BridgingInitiated(
        address from,
        address to,
        uint256 myChain,
        uint256 toChain,
        uint256 amount
    );

    event BridgingCompleted(string txID);

    constructor(uint256 chainID) {
        myChain = chainID;
    }

    function setFee(uint256 feeAmount) external onlyOwner {
        feeInNative = feeAmount;
    }

    function bridgeTokens(address to, uint256 toChain, uint256 amount) external payable {
        require(msg.value >= feeInNative, "Pay the price for bridging please");
        IBEP20(LIT).transferFrom(msg.sender, address(this), amount);
        emit BridgingInitiated(msg.sender, to, myChain, toChain, amount);
    }

    function sendTokens(address to, uint256 chainTo, uint256 amount, string calldata txID) external onlyBridge {
        if(chainTo != myChain) return;
        if(bridgingCompleted[txID]) return;
        bridgingCompleted[txID] = true;
        IBEP20(LIT).transfer(to, amount);
        emit BridgingCompleted(txID);
    }
}