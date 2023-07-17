/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

// SPDX-License-Identifier: GPL-3.0

// File: contracts/IERC20.sol



pragma solidity >=0.8.2 <0.9.0;

interface Token {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

}
// File: contracts/TransferHelper.sol



pragma solidity >=0.8.4;

// helper methods for intrcting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address, uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data,(bool))),"TransferHelper: safeApprove: approve failed");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address, uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data,(bool))),"TransferHelper: safeTransfer: transfer failed");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address, address, uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data,(bool))),"TransferHelper: safeTransferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: safeTransferETH: ETH transfer failed");
    }
}
// File: contracts/Ownable.sol



pragma solidity >=0.8.4;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /** 
    * @dev The Ownable constructor sets the orignal 'owner' of the contract to the sender *account
    */
    constructor() {
        _setOwner(msg.sender);
    }

    /**@dev Throws if called by any account other than the owner */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /** 
    * @dev Allows the current owner to transfer control of the contract to a newOwner
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Not transferred to zero address");
        emit OwnershipTransferred(owner, newOwner);
    }
    function _setOwner(address newOwner) internal {
        owner = newOwner;
    }
}
// File: contracts/StakeToken.sol



pragma solidity >=0.8.5;




contract Staking is Ownable {
    address rewardTokenAddress;
    address stakingTokenAddress;

    uint256 durationOfStaking = 60 seconds;
    uint256 penaltyPercentage = 10; // 10% penalty for early unstaking

    struct userStakeDetails {
        uint256 stakeAmount;
        uint256 stakeTimestamp;
        uint256 rewards;
        bool isStaked;
        bool isUnstaked;
    }

    mapping(address => userStakeDetails) public userMapping;

    constructor(
        address _rewardTokenAddress,
        address _stakingTokenAddress
    ) {
        rewardTokenAddress = _rewardTokenAddress;
        stakingTokenAddress = _stakingTokenAddress;
    }

    // Staking function 
    function stakeTokens(uint256 _stakeAmount) public returns(bool success) {
        require(_stakeAmount > 0, "Stake amount should be greater than zero");
        require(Token(stakingTokenAddress).balanceOf(msg.sender) >= _stakeAmount);
        require(Token(stakingTokenAddress).allowance(msg.sender, address(this)) >= _stakeAmount);

        userStakeDetails storage udetails = userMapping[msg.sender];
        require(!udetails.isStaked, "Already staked");

        TransferHelper.safeTransferFrom(
            stakingTokenAddress,
            msg.sender, 
            address(this), 
            _stakeAmount
        );
        
        udetails.stakeAmount = _stakeAmount;
        udetails.stakeTimestamp = block.timestamp;
        udetails.isStaked = true;

        return true;
    }

    // Calculate reward tokens
    function calculateRewards(address userAddress) internal view returns (uint256) {
        userStakeDetails storage udetails = userMapping[userAddress];
        if (udetails.isStaked && !udetails.isUnstaked) {
            uint256 stakingDuration = block.timestamp - udetails.stakeTimestamp;
            uint256 rewards = (udetails.stakeAmount * stakingDuration) / durationOfStaking;
            return rewards;
        }
        return 0;
    }

    // Claim reward tokens
    function claimRewards() public returns (bool success) {
        userStakeDetails storage udetails = userMapping[msg.sender];
        require(udetails.isStaked, "User has not staked yet!");

        uint256 rewards = calculateRewards(msg.sender);
        require(rewards > 0, "No rewards available for claiming");

        TransferHelper.safeTransfer(rewardTokenAddress, msg.sender, rewards);
        udetails.rewards += rewards;

        return true;
    }

    // Unstake function with penalty
    function unstakeTokens() public returns (bool success) {
        userStakeDetails storage udetails = userMapping[msg.sender];
        require(udetails.isStaked, "User has not staked yet!");
        require(!udetails.isUnstaked, "User has already unstaked");

        if (block.timestamp >= udetails.stakeTimestamp + durationOfStaking) {
            // No penalty if unstaking after the staking duration
            TransferHelper.safeTransfer(
                stakingTokenAddress, 
                msg.sender, 
                udetails.stakeAmount
            );
        } else {
            // Apply penalty if unstaking before the staking duration
            uint256 penaltyAmount = (udetails.stakeAmount * penaltyPercentage) / 100;
            uint256 remainingAmount = udetails.stakeAmount - penaltyAmount;

            TransferHelper.safeTransfer(
                stakingTokenAddress, 
                msg.sender, 
                remainingAmount
            );
            // TransferHelper.safeTransfer(
            //     stakingTokenAddress, 
            //     owner(), 
            //     penaltyAmount
            // );
        }

        udetails.isUnstaked = true;
        return true;
    }
}