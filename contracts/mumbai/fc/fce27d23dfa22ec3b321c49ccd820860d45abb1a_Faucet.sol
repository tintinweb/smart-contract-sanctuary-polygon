/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

// SPDX-License-Identifier: BUSL - 1.1
pragma solidity =0.8.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Faucet {
    uint256 public constant AMOUNT = 1000000000000000000000;

    address public admin;
    IERC20 public subgraphToken;
    mapping(address => bool) public isReceived;

    constructor(address _admin, IERC20 _subgraphToken) {
        admin = _admin;
        subgraphToken = _subgraphToken;
    }

    function receiveSToken() external {
        require(!isReceived[msg.sender], "Faucet: already transferred");
        bool success = subgraphToken.transferFrom(admin, msg.sender, AMOUNT);
        require(success, "Faucet: transfer failed");
    }
}