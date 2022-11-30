// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./utils/TransferHelper.sol";

contract StakingReward {

    struct UserInfo {
        uint256 amount; // Amount of staked tokens provided by user
        uint256 rewardDebt; // Reward debt
        uint256 lastRewardBlock;
    }

    struct OrderInfo {
        uint256 index;
        uint256 addedBlock;
        uint256 amount;
    }

    address public owner;
    address public operator;
    address private privatePlacementAddress;

    // Precision factor for calculating rewards
    uint256 public constant PRECISION_FACTOR = 10**12;

    uint256 public constant BLOCK_FOR_30DAYS = 10**12;

    mapping(address => UserInfo) public userInfo;

    constructor() {
        owner = msg.sender;
        operator = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "Ownable: caller is not the operator");
        _;
    }

    modifier onlyPP() {
        require(msg.sender == privatePlacementAddress, "not PrivatePlacement");
        _;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setPrivatePlacementAddress(address _privatePlacementAddress) external onlyOwner{
        privatePlacementAddress = _privatePlacementAddress;
    }

    function deposit(address staker, uint256 amount) external onlyPP {
        

    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }                                

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}