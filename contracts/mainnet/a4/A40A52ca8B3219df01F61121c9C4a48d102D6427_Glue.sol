/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
/// @title Glue
/// contract for pulling ERC20 tokens to other users on a certain intervals

contract Glue {
    uint256 public constant NO_END_TIME = 0;
    mapping(address => mapping(bytes32 => uint256)) public nextPulls;
    address public subsidy;
    address public feeToken;

    constructor(address feeToken_) {
        feeToken = feeToken_;
    }

    event NewPull(
        bytes32 indexed id,
        address indexed sender,
        address token,
        address indexed to,
        uint256 amount,
        uint48 interval,
        uint48 end
    );
    event Pull(bytes32 indexed id);
    event EndPull(bytes32 indexed id);

    /// @notice approve a new pull on a certain interval
    /// @param token the token to pull
    /// @param to the address to forward the tokens
    /// @param amount the amount to pull
    /// @param interval the interval between different pulls
    /// @param end optional end time of the pulls
    /// @param fee the fee to pay for the pull
    /// @param feeType if true, the fee is paid in the token, otherwise in ETH
    function approvePull(
        address token,
        address to,
        uint256 amount,
        uint48 interval,
        uint48 end,
        uint256 fee,
        bool feeType
    ) external {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, token, to, amount, interval, end, fee, feeType));
        require(nextPulls[msg.sender][id] == 0, "pull-already-approved");
        nextPulls[msg.sender][id] = block.timestamp;
        emit NewPull(id, msg.sender, token, to, amount, interval, end);
    }

    /// @notice pull tokens from an Ethereum address to another one
    /// @param from the address to pull from
    /// @param token the token to pull
    /// @param to the address to forward the tokens
    /// @param amount the amount to pull
    /// @param interval the interval between different pulls
    /// @param end optional end time of the pulls
    /// @param fee the fee to pay for the pull
    /// @param feeType if true, the fee is paid in the token, otherwise in WETH
    function pull(
        address from,
        address token,
        address to,
        uint256 amount,
        uint48 interval,
        uint48 end,
        uint256 fee,
        bool feeType
    ) external {
        bytes32 id = keccak256(abi.encodePacked(from, token, to, amount, interval, end, fee, feeType));
        uint256 nextPull = nextPulls[from][id];
        require(nextPull != 0, "pull-not-approved");
        require(nextPull <= end || end == NO_END_TIME, "pull-expired");
        require(block.timestamp >= nextPull, "pull-too-early");
        nextPulls[from][id] = block.timestamp + interval;
        IERC20(token).transferFrom(from, to, amount);
        if (fee > 0) {
            address feeToken_ = feeType ? token : feeToken;
            IERC20(feeToken_).transferFrom(from, msg.sender, fee);
        }
        emit Pull(id);
    }

    /// @notice end a pull
    /// @param token the token to pull
    /// @param to the address to forward the tokens
    /// @param amount the amount to pull
    /// @param interval the interval between different pulls
    /// @param end optional end time of the pulls
    /// @param fee the fee to pay for the pull
    /// @param feeType if true, the fee is paid in the token, otherwise in WETH
    function endPull(address token, address to, uint256 amount, uint48 interval, uint48 end, uint256 fee, bool feeType)
        external
    {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, token, to, amount, interval, end, fee, feeType));
        require(nextPulls[msg.sender][id] != 0, "pull-not-exists");
        nextPulls[msg.sender][id] = 0;
        emit EndPull(id);
    }
}