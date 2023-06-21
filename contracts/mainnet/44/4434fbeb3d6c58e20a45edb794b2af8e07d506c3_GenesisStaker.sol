// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GenesisStaker {
    address public constant CRE = 0xe81432473290F4ffCFc5E823F8069Db83e8A677B;
    address public constant CREPE = 0x5516d551Af482B4eef4B909138d5e48e05a7f50a;

    struct StakeConfig {
        uint32 start;
        uint32 end;
        uint128 exchangeRate;
        uint256 totalStaked;
        uint256 totalStaker;
    }

    mapping(uint8 => StakeConfig) public stakeConfigs;
    mapping(uint8 => mapping(address => uint256)) public userStakedAmount;

    event Stake(address indexed staker, uint8 stakeId, uint256 indexed unstakedAmount, uint256 indexed stakedAmount);
    event Unstake(address indexed staker, uint8 stakeId, uint256 indexed unstakedAmount);

    constructor(uint32[3] memory start_, uint32[3] memory end_) {
        stakeConfigs[0] =
            StakeConfig({start: start_[0], end: end_[0], exchangeRate: 104 * 1e16, totalStaked: 0, totalStaker: 0});

        stakeConfigs[1] =
            StakeConfig({start: start_[1], end: end_[1], exchangeRate: 112 * 1e16, totalStaked: 0, totalStaker: 0});

        stakeConfigs[2] =
            StakeConfig({start: start_[2], end: end_[2], exchangeRate: 136 * 1e16, totalStaked: 0, totalStaker: 0});
    }

    /// @notice burn CREPE tokens and record the balance for paying rewards in CRE tokens
    /// @param stakeId ID to identify lockup period(3, 6, 12 month)
    /// @param amount amount of CREPE token
    function stake(uint8 stakeId, uint256 amount) external {
        require(amount > 0, "GenesisStaker: invalid amount");
        require(stakeConfigs[stakeId].start > block.timestamp, "GenesisStaker: already started");

        unchecked {
            if (userStakedAmount[stakeId][msg.sender] == 0) {
                stakeConfigs[stakeId].totalStaker++;
            }

            // Since the total amount of CREPE tokens issued does not exceed the overflow range of uint256 type
            // there is no need to check overflow.
            userStakedAmount[stakeId][msg.sender] += amount;
            stakeConfigs[stakeId].totalStaked += amount;
        }

        IERC20(CREPE).transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, amount);

        emit Stake(msg.sender, stakeId, lockedCreToken(stakeId), amount);
    }

    function lockedCreToken(uint8 stakeId) public view returns (uint256) {
        unchecked {
            return userStakedAmount[stakeId][msg.sender] * stakeConfigs[stakeId].exchangeRate / 1e18;
        }
    }

    /// @notice claim staking rewards after lockup period
    /// @param stakeId ID to identify lock-up period(3, 6, 12 month)
    function unstake(uint8 stakeId) external {
        require(stakeConfigs[stakeId].end <= block.timestamp, "GenesisStaker: not ended");

        uint256 lockedCreAmount = lockedCreToken(stakeId);

        uint256 stakedAmount = userStakedAmount[stakeId][msg.sender];
        require(stakedAmount > 0, "GenesisStaker: not enough stake amount");

        unchecked {
            userStakedAmount[stakeId][msg.sender] = 0;
            stakeConfigs[stakeId].totalStaked -= stakedAmount;
            stakeConfigs[stakeId].totalStaker -= 1;
        }

        IERC20(CRE).transfer(msg.sender, lockedCreAmount);

        emit Unstake(msg.sender, stakeId, lockedCreAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}