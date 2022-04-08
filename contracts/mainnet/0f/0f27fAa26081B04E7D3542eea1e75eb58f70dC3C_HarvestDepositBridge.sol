// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IHarvestVault.sol";
import "./interfaces/IHarvestPool.sol";
import "../interfaces/IHarvestDeposit.sol";

/**
 * @title HarvestDepositBridge
 * @author DeFi Basket
 *
 * @notice Deposits, withdraws and harvest rewards from harvest vaults in Polygon.
 *
 * @dev This contract has 2 main functions:
 *
 * 1. Deposit in Harvest vault and stake fASSET in corresponding pool
 * 2. Withdraw from Harvest vault and claim rewards
 *
 */

contract HarvestDepositBridge is IHarvestDeposit {

    /**
      * @notice Deposits into a Harvest vault and automatically stakes in the corresponding pool
      *
      * @dev Wraps the Harvest vault deposit and pool stake. Also generates the necessary events to communicate with DeFi Basket's UI and back-end.
      *
      * @param poolAddress The address of the Harvest pool.
      * @param percentageIn Percentage of the balance of the asset that will be deposited
      */
    function deposit(address poolAddress, uint256 percentageIn) external override {

        address vaultAddress = IHarvestPool(poolAddress).lpToken();
        /* lpToken returns the proxy (and not the implementation address) */
        IHarvestVault vault = IHarvestVault(vaultAddress);

        IERC20 assetIn = IERC20(vault.underlying());
        uint256 amountIn = assetIn.balanceOf(address(this)) * percentageIn / 100000;

        // Approve 0 first as a few ERC20 tokens are requiring this pattern.
        assetIn.approve(vaultAddress, 0);
        assetIn.approve(vaultAddress, amountIn);

        vault.deposit(amountIn);

        // Stake token in reward pool
        IERC20 vaultToken = IERC20(vaultAddress);
        uint256 vaultTokenBalance = vaultToken.balanceOf(address(this));
        vaultToken.approve(poolAddress, vaultTokenBalance);
        IHarvestPool(poolAddress).stake(vaultTokenBalance);

        emit DEFIBASKET_HARVEST_DEPOSIT(address(assetIn), amountIn, vaultTokenBalance);
    }

    /**
      * @notice Withdraws from the Harvest vault.
      *
      * @dev Wraps the Harvest vault withdraw and the pool exit. Also generates the necessary events to communicate with DeFi Basket's UI and back-end.
      *
      * @param poolAddress The address of the Harvest pool.
      * @param percentageOut Percentage of fAsset that will be withdrawn
      *
      */
    function withdraw(address poolAddress, uint256 percentageOut) external override {

        address[] memory rewardTokens;
        uint256[] memory rewardBalancesOut;
        address assetOut;
        uint256 amountIn;
        uint256 amountOut;

        try IHarvestPool(poolAddress).lpToken() returns (address vaultAddress){
            (rewardTokens, rewardBalancesOut) = _withdrawPool(poolAddress, percentageOut);
            (amountIn, assetOut, amountOut) = _withdrawVault(vaultAddress, 100_000);
        }
        catch{
            // Burn fASSET and withdraw corresponding asset from Vault
            (amountIn, assetOut, amountOut) = _withdrawVault(poolAddress, percentageOut);
        }

        emit DEFIBASKET_HARVEST_WITHDRAW(assetOut, amountOut, amountIn, rewardTokens, rewardBalancesOut);
    }

    function _withdrawPool(address poolAddress, uint256 percentageOut) internal returns (address[] memory, uint256[] memory) {
        IHarvestPool pool = IHarvestPool(poolAddress);

        // Compute balance of reward tokens before exit is called
        uint256 rewardTokensLength = pool.rewardTokensLength();
        address[] memory rewardTokens = new address[](rewardTokensLength);
        uint256[] memory rewardBalances = new uint256[](rewardTokensLength);
        uint256[] memory rewardBalancesOut = new uint256[](rewardTokensLength);

        for (uint256 i = 0; i < rewardTokensLength; i = unchecked_inc(i)) {
            rewardTokens[i] = pool.rewardTokens(i);
            rewardBalances[i] = IERC20(rewardTokens[i]).balanceOf(address(this));
        }

        // Returns the staked fASSET to the Wallet in addition to any accumulated FARM rewards
        uint256 poolWithdrawalAmount = pool.balanceOf(address(this)) * percentageOut / 100000;

        pool.withdraw(Math.min(poolWithdrawalAmount, pool.stakedBalanceOf(address(this))));
        pool.getAllRewards();

        // Compute total rewards for each reward token
        for (uint256 i = 0; i < rewardTokensLength; i = unchecked_inc(i)) {
            rewardBalancesOut[i] = IERC20(rewardTokens[i]).balanceOf(address(this)) - rewardBalances[i];
        }

        return (rewardTokens, rewardBalancesOut);
    }

    function _withdrawVault(address vaultAddress, uint256 percentageOut) internal returns (uint256, address, uint256) {
        IHarvestVault vault = IHarvestVault(vaultAddress);
        IERC20 assetOut = IERC20(vault.underlying());

        // Burn fASSET and withdraw corresponding asset from Vault
        uint256 assetBalanceBefore = assetOut.balanceOf(address(this));
        uint256 assetAmountIn = IERC20(vaultAddress).balanceOf(address(this)) * percentageOut / 100000;
        vault.withdraw(assetAmountIn);
        uint256 assetAmountOut = assetOut.balanceOf(address(this)) - assetBalanceBefore;

        return (assetAmountIn, address(assetOut), assetAmountOut);
    }

    /**
      * @notice Claim rewards from a pool without unstaking the fASSET
      *
      * @dev Wraps the Harvest getAllRewards and generate the necessary events to communicate with DeFi Basket's UI and
      * back-end. 
      *
      * @param poolAddress The address of the Harvest pool.
      *
      */
    function claimRewards(address poolAddress) external override {

        IHarvestPool pool = IHarvestPool(poolAddress);

        // Compute balance of reward tokens before exit is called 
        uint256 rewardTokensLength = pool.rewardTokensLength();
        address[] memory rewardTokens = new address[](rewardTokensLength);
        uint256[] memory rewardBalances = new uint256[](rewardTokensLength);
        uint256[] memory rewardBalancesOut = new uint256[](rewardTokensLength);

        for (uint256 i = 0; i < rewardTokensLength; i = unchecked_inc(i)) {
            rewardTokens[i] = pool.rewardTokens(i);
            rewardBalances[i] = IERC20(rewardTokens[i]).balanceOf(address(this));
        }

        pool.getAllRewards();

        // Compute total rewards for each reward token
        for (uint256 i = 0; i < rewardTokensLength; i = unchecked_inc(i)) {
            rewardBalancesOut[i] = IERC20(rewardTokens[i]).balanceOf(address(this)) - rewardBalances[i];
        }

        emit DEFIBASKET_HARVEST_CLAIM(rewardTokens, rewardBalancesOut);
    }

    /**
      * @notice Increment integer without checking for overflow - only use in loops where you know the value won't overflow
      *
      * @param i Integer to be incremented
    */
    function unchecked_inc(uint256 i) internal pure returns (uint256) {
    unchecked {
        return i + 1;
    }
    }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IHarvestVault {

    function deposit(uint256 amount) external;
    function withdraw(uint256 numberOfShares) external; 
    function underlying() external view returns(address);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IHarvestPool {
    
    function lpToken() external returns (address);
    function rewardTokens(uint i) external returns (address);
    function rewardTokensLength() external returns(uint256);    
    function getAllRewards() external; 
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function balanceOf(address) external returns (uint256);
    function stakedBalanceOf(address) external returns (uint256);
    function exit() external;

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IHarvestDeposit {
    event DEFIBASKET_HARVEST_DEPOSIT(
        address assetIn,
        uint256 amountIn,
        uint256 amountOut
    );

    event DEFIBASKET_HARVEST_WITHDRAW(
        address assetOut,
        uint256 assetAmountOut,
        uint256 assetAmountIn,
        address[] rewardTokens,
        uint256[] rewardBalancesOut
    );

    event DEFIBASKET_HARVEST_CLAIM(
        address[] rewardTokens,
        uint256[] rewardBalancesOut
    );

    function deposit(address poolAddress, uint256 percentageIn) external;
    function withdraw(address poolAddress, uint256 percentageOut) external;
    function claimRewards(address poolAddress) external;
}