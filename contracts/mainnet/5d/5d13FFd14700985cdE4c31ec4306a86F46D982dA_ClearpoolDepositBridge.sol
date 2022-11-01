// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/IClearpoolPoolV1.sol";
import "./interfaces/IClearpoolFactoryV1.sol";
import "../interfaces/IClearpoolDeposit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ClearpoolDepositBridge
 * @author Picnic (formerly DeFi Basket)
 *
 * @notice Deposits and withdraws from Clearpool pools in Polygon.
 *
 * @dev This contract has 2 main functions:
 *
 * 1. Deposit in Clearpool pool
 * 2. Withdraw from Clearpool pool
 *
 */

contract ClearpoolDepositBridge is IClearpoolDeposit {
    /**
     * @notice Deposits into a Clearpool pool
     *
     * @dev Wraps Clearpool's pool provide function and generates an event to communicate with Picnic's UI and back-end.
     *
     * @param poolAddress The address of the Clearpool's pool.
     * @param percentageIn Percentage of the balance of the asset that will be deposited
     */
    function deposit(address poolAddress, uint256 percentageIn)
        external
        override
    {
        IClearpoolPoolV1 pool = IClearpoolPoolV1(poolAddress);
        IERC20 poolToken = IERC20(poolAddress);

        address assetIn = pool.currency();
        IERC20 assetInContract = IERC20(assetIn);
        uint256 amountIn = (assetInContract.balanceOf(address(this)) *
            percentageIn) / 100000;

        // Approve 0 first as a few ERC20 tokens are requiring this pattern.
        assetInContract.approve(poolAddress, 0);
        assetInContract.approve(poolAddress, amountIn);

        // Compute balance of mooToken before deposit
        uint256 poolTokenBalanceBefore = poolToken.balanceOf(address(this));

        pool.provide(amountIn);
        uint256 poolTokenReceived = poolToken.balanceOf(address(this)) -
            poolTokenBalanceBefore;

        emit DEFIBASKET_CLEARPOOL_DEPOSIT(assetIn, amountIn, poolTokenReceived);
    }

    /**
     * @notice Claim rewards from a pool without unstaking principal
     *
     * @dev Wraps Clearpool's withdrawReward and generate the necessary events to communicate with Picnic's UI and back-end.
     *
     * @param poolAddress The address of the Clearpool pool.
     *
     */
    function _claimRewards(address poolAddress) private {
        address rewardTokenAddress = 0xb08b3603C5F2629eF83510E6049eDEeFdc3A2D91;

        IClearpoolPoolV1 pool = IClearpoolPoolV1(poolAddress);
        IClearpoolFactoryV1 factory = IClearpoolFactoryV1(pool.factory());

        address[] memory poolAddresses = new address[](1);
        poolAddresses[0] = poolAddress;

        uint256 rewardTokenBalance = IERC20(rewardTokenAddress).balanceOf(
            address(this)
        );

        factory.withdrawReward(poolAddresses);

        uint256 rewardTokenBalanceOut = IERC20(rewardTokenAddress).balanceOf(
            address(this)
        ) - rewardTokenBalance;

        emit DEFIBASKET_CLEARPOOL_CLAIM(
            rewardTokenAddress,
            rewardTokenBalanceOut
        );
    }

    /**
     * @notice Withdraws from the Clearpool pool
     *
     * @dev Wraps the Clearpool's pool redeem function and generates an event to communicate with Picnic's UI and back-end.
     *
     * @param poolAddress The address of the Clearpool pool.
     * @param percentageOut Percentage of poolToken that will be burned
     *
     */
    function withdraw(address poolAddress, uint256 percentageOut)
        external
        override
    {
        IClearpoolPoolV1 pool = IClearpoolPoolV1(poolAddress);
        IERC20 poolToken = IERC20(poolAddress);

        uint256 burnAmount = (poolToken.balanceOf(address(this)) *
            percentageOut) / 100000;

        // Compute balance of underlying asset before withdraw
        address assetReceived = pool.currency();
        uint256 assetBalanceBefore = IERC20(assetReceived).balanceOf(
            address(this)
        );
        pool.redeem(burnAmount);

        // Claim rewards from the pool
        _claimRewards(poolAddress);

        // Compute balance of underlying asset after withdraw
        uint256 amountReceived = IERC20(assetReceived).balanceOf(
            address(this)
        ) - assetBalanceBefore;

        emit DEFIBASKET_CLEARPOOL_WITHDRAW(
            burnAmount,
            assetReceived,
            amountReceived
        );
    }

    /**
     * @notice Claim rewards from a pool without unstaking principal
     *
     * @dev Wraps Clearpool's withdrawReward and generate the necessary events to communicate with Picnic's UI and back-end.
     *
     * @param poolAddress The address of the Clearpool pool.
     *
     */
    function claimRewards(address poolAddress) external override {
        return _claimRewards(poolAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IClearpoolPoolV1 {

    function provide(
        uint256 currencyAmount    
    ) external;

    function redeem(
        uint256 tokens
    ) external;

    function withdrawReward(
        address account
    ) external;

    function withdrawableRewardOf(
        address account
    ) external view returns (uint256);

    function currency() external view returns (address);

    function factory() external view returns (address);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IClearpoolFactoryV1 {

    function withdrawReward(
        address[] memory poolsList
    ) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IClearpoolDeposit {
    event DEFIBASKET_CLEARPOOL_DEPOSIT(
        address assetIn,
        uint256 amountIn,
        uint256 poolTokenReceived
    );

    event DEFIBASKET_CLEARPOOL_WITHDRAW(
        uint256 burnAmount,
        address assetReceived,
        uint256 amountReceived
    );

    event DEFIBASKET_CLEARPOOL_CLAIM(
        address rewardTokenAddress,
        uint256 rewardTokenBalanceOut
    );

    function deposit(address poolAddress, uint256 percentageIn) external;
    function withdraw(address poolAddress, uint256 percentageOut) external;
    function claimRewards(address poolAddress) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
}