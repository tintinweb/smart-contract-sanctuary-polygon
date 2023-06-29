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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGeckoFinance {
    function transferFrom(address _from, address _to, uint256 _amount) external;

    function balanceOf(address _user) external returns (uint256);
}

contract GeckoRewards {
    address geckoTokenAddress;
    IGeckoFinance GeckoERC20;

    // Map for tracking rewards per each user
    mapping(address => uint256) private rewards;
    mapping(address => uint256) public balances;
    mapping(address => mapping(uint256 => uint256)) public userBalances;
    mapping(address => uint256) public lastUpdate;

    constructor(address _geckoAddress) {
        geckoTokenAddress = _geckoAddress;
        GeckoERC20 = IGeckoFinance(_geckoAddress);
    }

    function getRewards(address _user) public returns (uint256) {
        // get user's balance and holding period
        uint256 tokenBalance = GeckoERC20.balanceOf(_user);
        uint256 lastUpdatedTime = lastUpdateTime(_user);
        uint256 holdingPeriod = block.timestamp - lastUpdatedTime;

        // calculate average daily holdings
        uint256 startingBalance = userBalances[_user][lastUpdatedTime];
        uint256 endingBalance = tokenBalance;
        uint256 averageDailyHoldings = (startingBalance + endingBalance) /
            ((2 * holdingPeriod) / (1 days));

        // calculate rewards based on holding balance
        if (tokenBalance >= 2000 ether) {
            rewards[_user] = 50 ether;
        } else if (tokenBalance >= 1000 ether) {
            rewards[_user] = 50 ether * (tokenBalance / 1000 ether);
        } else if (tokenBalance >= 200 ether) {
            rewards[_user] = 5 ether * (tokenBalance / 200 ether);
        } else if (tokenBalance >= 50 ether) {
            rewards[_user] = 2 ether * (tokenBalance / 50 ether);
        }

        // calculate additional rewards based on average daily holdings
        if (averageDailyHoldings > 0) {
            if (tokenBalance >= 2000 ether) {
                rewards[_user] += 50 ether * (averageDailyHoldings / 1000);
            } else if (tokenBalance >= 1000 ether) {
                rewards[_user] += 5 ether * (averageDailyHoldings / 200);
            } else if (tokenBalance >= 200 ether) {
                rewards[_user] += 2 ether * (averageDailyHoldings / 50);
            }
        }

        // update user's balance and last update time
        balances[_user] = tokenBalance;
        lastUpdate[_user] = block.timestamp;
        userBalances[_user][block.timestamp] = tokenBalance;

        return rewards[_user];
    }

    function lastUpdateTime(address _user) public view returns (uint256) {
        return lastUpdate[_user];
    }

    function updateBalance(address _user, uint256 _balance) public {
        GeckoERC20.transferFrom(msg.sender, address(this), _balance);
        uint256 prevBalance = balances[_user];
        uint256 newBalance = prevBalance + _balance;
        balances[_user] = newBalance;
        lastUpdate[_user] = block.timestamp;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balances[_user];
    }

    function balanceOf(
        address _user,
        uint256 _time
    ) public view returns (uint256) {
        if (_time >= lastUpdate[_user]) {
            return balances[_user];
        } else {
            return userBalances[_user][_time];
        }
    }


    function claimRewards(address _user) public {
        // get rewards
        uint256 rewardsToClaim = getRewards(_user);

        // claim
        GeckoERC20.transferFrom(address(this), _user, rewardsToClaim);
    }
}