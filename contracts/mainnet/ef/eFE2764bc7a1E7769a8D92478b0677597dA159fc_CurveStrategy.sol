// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../curve/ICurvePool.sol";
import "../curve/ICurveGauge.sol";
import "./IStrategy.sol";

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error INVALID_CURVE_TOKEN();
error INVALID_DEPOSIT_TOKEN();
error INVALID_GAUGE();
error INVALID_POOL();
error INVALID_REWARD_TOKEN();
error TOKEN_TRANSFER_FAILURE();

/**
  @notice
  Interacts with curve protocol to generate interest & additional rewards for the goodghosting pool it is used in, so it's responsible for deposits, staking lp tokens, withdrawals and getting rewards and sending these back to the pool.
*/
contract CurveStrategy is Ownable, ReentrancyGuard, IStrategy {
    /// @notice reward token address for eg wmatic in case of polygon deployment
    IERC20 public immutable rewardToken;

    /// @notice curve token
    IERC20 public immutable curve;

    /// @notice gauge address
    ICurveGauge public immutable gauge;

    /// @notice token index in the pool in int form
    int128 public immutable inboundTokenIndex;

    /// @notice flag to differentiate between aave and atricrypto pool
    uint64 public immutable poolType;

    /// @notice total tokens in aave pool
    uint64 public constant NUM_AAVE_TOKENS = 3;

    /// @notice total tokens in atricrypto pool
    uint64 public constant NUM_ATRI_CRYPTO_TOKENS = 5;

    /// @notice identifies the "Aave Pool" Type
    uint64 public constant AAVE_POOL = 0;

    /// @notice identifies the "Atri Crypto Pool" Type
    uint64 public constant ATRI_CRYPTO_POOL = 1;

    /// @notice pool address
    ICurvePool public pool;

    /// @notice curve lp token
    IERC20 public lpToken;

    //*********************************************************************//
    // ------------------------- external views -------------------------- //
    //*********************************************************************//
    /** 
    @notice
    Get strategy owner address.
    @return Strategy owner.
    */
    function strategyOwner() external view override returns (address) {
        return super.owner();
    }

    /** 
    @notice
    Returns the total accumulated amount i.e principal + interest stored in curve, only used in case of variable deposit pools.
    @return Total accumulated amount.
    */
    function getTotalAmount() external view override returns (uint256) {
        uint256 gaugeBalance = gauge.balanceOf(address(this));
        uint256 totalAccumalatedAmount = 0;
        if (poolType == AAVE_POOL) {
            totalAccumalatedAmount = pool.calc_withdraw_one_coin(gaugeBalance, inboundTokenIndex);
        } else {
            totalAccumalatedAmount = pool.calc_withdraw_one_coin(gaugeBalance, uint256(uint128(inboundTokenIndex)));
        }
        return totalAccumalatedAmount;
    }

    /** 
    @notice
    Get the expected net deposit amount (amount minus slippage) for a given amount. Used only for AMM strategies.
    @return net amount.
    */
    function getNetDepositAmount(uint256 _amount) external view override returns (uint256) {
          if (poolType == AAVE_POOL) {
            uint256[NUM_AAVE_TOKENS] memory amounts; // fixed-sized array is initialized w/ [0, 0, 0]
            amounts[uint256(uint128(inboundTokenIndex))] = _amount;
            uint256 poolWithdrawAmount = pool.calc_token_amount(amounts, true);
            return pool.calc_withdraw_one_coin(poolWithdrawAmount, inboundTokenIndex);
          } else {
            uint256[NUM_ATRI_CRYPTO_TOKENS] memory amounts; // fixed-sized array is initialized w/ [0, 0, 0, 0, 0]
            amounts[uint256(uint128(inboundTokenIndex))] = _amount;
            uint256 poolWithdrawAmount = pool.calc_token_amount(amounts, true);
            return pool.calc_withdraw_one_coin(poolWithdrawAmount, uint256(uint128(inboundTokenIndex)));
          }
    }

    /** 
    @notice
    Returns the underlying inbound (deposit) token address.
    @return Underlying token address.
    */
    function getUnderlyingAsset() external pure override returns (address) {
        return address(0);
    }

    /** 
    @notice
    Returns the instance of the reward tokens
    */
    function getRewardTokens() external view override returns (IERC20[] memory) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = rewardToken;
        tokens[1] = curve;
        return tokens;
    }

    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    /** 
    @param _pool Curve Pool Contract.
    @param _inboundTokenIndex Deposit token index in the pool.
    @param _poolType Pool type to diffrentiate b/w the pools.
    @param _gauge Curve Gauge Contract used to stake lp tokens.
    @param _rewardToken A contract which acts as the reward token for this strategy.
    @param _curve Curve Contract.
  */
    constructor(
        ICurvePool _pool,
        int128 _inboundTokenIndex,
        uint64 _poolType,
        ICurveGauge _gauge,
        IERC20 _rewardToken,
        IERC20 _curve
    ) {
        if (address(_pool) == address(0)) {
            revert INVALID_POOL();
        }
        if (address(_gauge) == address(0)) {
            revert INVALID_GAUGE();
        }
        if (address(_curve) == address(0)) {
            revert INVALID_CURVE_TOKEN();
        }
        if (address(_rewardToken) == address(0)) {
            revert INVALID_REWARD_TOKEN();
        }

        pool = _pool;
        gauge = _gauge;
        curve = _curve;
        poolType = _poolType;
        inboundTokenIndex = _inboundTokenIndex;
        // wmatic in case of polygon and address(0) for non-polygon deployment
        rewardToken = _rewardToken;
        if (_poolType == AAVE_POOL) {
            lpToken = IERC20(pool.lp_token());
        } else {
            lpToken = IERC20(pool.token());
        }
    }

    /**
    @notice
    Deposits funds into curve pool and then stake the lp tokens into curve gauge.
    @param _inboundCurrency Address of the inbound token.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario.
    */
    function invest(address _inboundCurrency, uint256 _minAmount) external payable override nonReentrant onlyOwner {
        if (pool.underlying_coins(uint256(uint128(inboundTokenIndex))) != _inboundCurrency) {
            revert INVALID_DEPOSIT_TOKEN();
        }
        uint256 contractBalance = IERC20(_inboundCurrency).balanceOf(address(this));
        IERC20(_inboundCurrency).approve(address(pool), contractBalance);
        /*
        Constants "NUM_AAVE_TOKENS" and "NUM_ATRI_CRYPTO_TOKENS" have to be a constant type actually,
            otherwise the signature becomes different and the external call will fail.
            If we use an "if" condition based on pool type, and dynamically set
            a value for these variables, the assignment will be to a non-constant
            which will result in failure. This is due to the structure of how
            the curve contracts are written
        */
        if (poolType == AAVE_POOL) {
            uint256[NUM_AAVE_TOKENS] memory amounts; // fixed-sized array is initialized w/ [0, 0, 0]
            amounts[uint256(uint128(inboundTokenIndex))] = contractBalance;
            pool.add_liquidity(amounts, _minAmount, true);
        } else {
            uint256[NUM_ATRI_CRYPTO_TOKENS] memory amounts; // fixed-sized array is initialized w/ [0, 0, 0, 0, 0]
            amounts[uint256(uint128(inboundTokenIndex))] = contractBalance;
            pool.add_liquidity(amounts, _minAmount);
        }

        lpToken.approve(address(gauge), lpToken.balanceOf(address(this)));
        gauge.deposit(lpToken.balanceOf(address(this)));
    }

    /**
    @notice
    Unstakes and Withdraw's funds from curve in case of an early withdrawal .
    @param _inboundCurrency Address of the inbound token.
    @param _amount Amount to withdraw.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario.
    */
    function earlyWithdraw(
        address _inboundCurrency,
        uint256 _amount,
        uint256 _minAmount
    ) external override nonReentrant onlyOwner {
        // not checking for validity of deposit token here since with pool contract as the owner of the strategy the only way to transfer pool funds is by invest method so the check there is sufficient
        uint256 gaugeBalance = gauge.balanceOf(address(this));
        if (poolType == AAVE_POOL) {
            uint256[NUM_AAVE_TOKENS] memory amounts; // fixed-sized array is initialized w/ [0, 0, 0]
            amounts[uint256(uint128(inboundTokenIndex))] = _amount;
            uint256 poolWithdrawAmount = pool.calc_token_amount(amounts, true);

            // safety check
            // the curve mock contracts are pretty complex right now and it is not possible to mock, this is a very rare scenario to occur in production.
            // if (gaugeBalance < poolWithdrawAmount) {
            //     poolWithdrawAmount = gaugeBalance;
            // }

            // passes false not to claim rewards
            gauge.withdraw(poolWithdrawAmount, false);

            pool.remove_liquidity_one_coin(
                poolWithdrawAmount,
                inboundTokenIndex,
                _minAmount,
                true // redeems underlying coin (dai, usdc, usdt), instead of aTokens
            );
        } else {
            uint256[NUM_ATRI_CRYPTO_TOKENS] memory amounts; // fixed-sized array is initialized w/ [0, 0, 0, 0, 0]
            amounts[uint256(uint128(inboundTokenIndex))] = _amount;
            uint256 poolWithdrawAmount = pool.calc_token_amount(amounts, true);

            // safety check
            // if (gaugeBalance < poolWithdrawAmount) {
            //     poolWithdrawAmount = gaugeBalance;
            // }

            // passes false not to claim rewards
            gauge.withdraw(poolWithdrawAmount, false);
            /*
                Code of curve's aave and curve's atricrypto pools are completely different.
                Curve's Aave Pool (pool type 0): in this contract, all funds "sit" in the pool's smart contract.
                Curve's Atricrypto pool (pool type 1): this contract integrates with other pools
                and funds sit in those pools. Hence, an approval transaction is required because
                it is communicating with external contracts
                */
            lpToken.approve(address(pool), poolWithdrawAmount);
            pool.remove_liquidity_one_coin(poolWithdrawAmount, uint256(uint128(inboundTokenIndex)), _minAmount);
        }
        // check for impermanent loss
        if (IERC20(_inboundCurrency).balanceOf(address(this)) < _amount) {
            _amount = IERC20(_inboundCurrency).balanceOf(address(this));
        }
        // msg.sender will always be the pool contract (new owner)
        bool success = IERC20(_inboundCurrency).transfer(msg.sender, IERC20(_inboundCurrency).balanceOf(address(this)));
        if (!success) {
            revert TOKEN_TRANSFER_FAILURE();
        }
    }

    /**
    @notice
    Redeems funds from curve after unstaking when the waiting round for the good ghosting pool is over.
    @param _inboundCurrency Address of the inbound token.
    @param _amount Amount to withdraw.
    @param variableDeposits Bool Flag which determines whether the deposit is to be made in context of a variable deposit pool or not.
    @param _minAmount Slippage based amount to cover for impermanent loss scenario.
    @param disableRewardTokenClaim Reward claim disable flag.
    */
    function redeem(
        address _inboundCurrency,
        uint256 _amount,
        bool variableDeposits,
        uint256 _minAmount,
        bool disableRewardTokenClaim
    ) external override nonReentrant onlyOwner {
        // not checking for validity of deposit token here since with pool contract as the owner of the strategy the only way to transfer pool funds is by invest method so the check there is sufficient
        bool claimRewards = true;
        if (disableRewardTokenClaim) {
            claimRewards = false;
        }
        uint256 gaugeBalance = gauge.balanceOf(address(this));
        if (variableDeposits) {
            if (poolType == AAVE_POOL) {
                uint256[NUM_AAVE_TOKENS] memory amounts; // fixed-sized array is initialized w/ [0, 0, 0]
                amounts[uint256(uint128(inboundTokenIndex))] = _amount;
                uint256 poolWithdrawAmount = pool.calc_token_amount(amounts, true);

                // safety check
                // the amm mock contracts are pretty complex right now and it is not possible to mock, this is a very rare scenario to occur in production.
                // if (gaugeBalance < poolWithdrawAmount) {
                //     poolWithdrawAmount = gaugeBalance;
                // }

                // passes false not to claim rewards
                gauge.withdraw(poolWithdrawAmount, claimRewards);

                pool.remove_liquidity_one_coin(
                    poolWithdrawAmount,
                    inboundTokenIndex,
                    _minAmount,
                    true // redeems underlying coin (dai, usdc, usdt), instead of aTokens
                );
            } else {
                uint256[NUM_ATRI_CRYPTO_TOKENS] memory amounts; // fixed-sized array is initialized w/ [0, 0, 0, 0, 0]
                amounts[uint256(uint128(inboundTokenIndex))] = _amount;
                uint256 poolWithdrawAmount = pool.calc_token_amount(amounts, true);

                // safety check
                if (gaugeBalance < poolWithdrawAmount) {
                    poolWithdrawAmount = gaugeBalance;
                }

                // passes false not to claim rewards
                gauge.withdraw(poolWithdrawAmount, claimRewards);
                /*
                    Code of curve's aave and curve's atricrypto pools are completely different.
                    Curve's Aave Pool (pool type 0): in this contract, all funds "sit" in the pool's smart contract.
                    Curve's Atricrypto pool (pool type 1): this contract integrates with other pools
                    and funds sit in those pools. Hence, an approval transaction is required because
                    it is communicating with external contracts
                    */
                lpToken.approve(address(pool), poolWithdrawAmount);
                pool.remove_liquidity_one_coin(poolWithdrawAmount, uint256(uint128(inboundTokenIndex)), _minAmount);
            }
        } else {
            // passes true to also claim rewards
            gauge.withdraw(gaugeBalance, claimRewards);

            uint256 lpTokenBalance = lpToken.balanceOf(address(this));
            if (lpTokenBalance != 0) {
                if (poolType == AAVE_POOL) {
                    pool.remove_liquidity_one_coin(
                        lpTokenBalance,
                        inboundTokenIndex,
                        _minAmount,
                        true // redeems underlying coin (dai, usdc, usdt), instead of aTokens
                    );
                } else {
                    /*
                        Code of curve's aave and curve's atricrypto pools are completely different.
                        Curve's Aave Pool (pool type 0): in this contract, all funds "sit" in the pool's smart contract.
                        Curve's Atricrypto pool (pool type 1): this contract integrates with other pools
                        and funds sit in those pools. Hence, an approval transaction is required because
                        it is communicating with external contracts
                         */
                    lpToken.approve(address(pool), lpTokenBalance);
                    pool.remove_liquidity_one_coin(lpTokenBalance, uint256(uint128(inboundTokenIndex)), _minAmount);
                }
            }
        }

        bool success = rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        if (!success) {
            revert TOKEN_TRANSFER_FAILURE();
        }

        success = curve.transfer(msg.sender, curve.balanceOf(address(this)));
        if (!success) {
            revert TOKEN_TRANSFER_FAILURE();
        }

        success = IERC20(_inboundCurrency).transfer(msg.sender, IERC20(_inboundCurrency).balanceOf(address(this)));
        if (!success) {
            revert TOKEN_TRANSFER_FAILURE();
        }
    }

    /**
    @notice
    Returns total accumulated reward token amount.
    This method is not marked as view since in the curve gauge contract "claimable_reward_write" is not marked as view.
    @param disableRewardTokenClaim Reward claim disable flag.
    */
    function getAccumulatedRewardTokenAmounts(bool disableRewardTokenClaim)
        external
        override
        returns (uint256[] memory)
    {
        uint256 amount = 0;
        uint256 additionalAmount = 0;
        if (!disableRewardTokenClaim) {
            amount = gauge.claimable_reward_write(address(this), address(rewardToken));
            additionalAmount = gauge.claimable_reward_write(address(this), address(curve));
        }
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = additionalAmount;
        return amounts;
    }
}

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
    function invest(address _inboundCurrency, uint256 _minAmount) external payable;

    function earlyWithdraw(
        address _inboundCurrency,
        uint256 _amount,
        uint256 _minAmount
    ) external;

    function redeem(
        address _inboundCurrency,
        uint256 _amount,
        bool variableDeposits,
        uint256 _minAmount,
        bool disableRewardTokenClaim
    ) external;

    function getTotalAmount() external view returns (uint256);

    function getNetDepositAmount(uint256 _amount) external view returns (uint256);

    function getAccumulatedRewardTokenAmounts(bool disableRewardTokenClaim) external returns (uint256[] memory);

    function getRewardTokens() external view returns (IERC20[] memory);

    function getUnderlyingAsset() external view returns (address);

    function strategyOwner() external view returns (address);
}

pragma solidity ^0.8.7;

interface ICurvePool {
    function add_liquidity(
        uint256[3] calldata _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external returns (uint256);

    function add_liquidity(
        uint256[5] calldata _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external returns (uint256);

    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external;

    function add_liquidity(uint256[5] calldata _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount,
        bool _use_underlying
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 _min_amount
    ) external;

    function lp_token() external view returns (address);

    function token() external view returns (address);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, uint256 i) external view returns (uint256);

    function calc_token_amount(uint256[3] calldata _amounts, bool is_deposit) external view returns (uint256);

    function calc_token_amount(uint256[5] calldata _amounts, bool is_deposit) external view returns (uint256);

    function underlying_coins(uint256 arg0) external view returns (address);
}

pragma solidity ^0.8.7;

interface ICurveGauge {
    function deposit(uint256 _value) external;

    function withdraw(uint256 _value, bool _claim_rewards) external;

    function claim_rewards() external;

    function balanceOf(address user) external view returns (uint256);

    function claimable_reward_write(address _addr, address _token) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}