// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IIronSwap.sol";
import "./IronSwapRouter.sol";

contract FeeDistributor is Initializable, Ownable {
    using SafeERC20 for IERC20;

    enum SwapPoolType {
        plain,
        meta
    }

    struct SwapConfig {
        SwapPoolType poolType;
        address pool;
        address basePool;
    }

    /// @dev convert all fee to this token
    address public target;

    /// @dev fromToken => routerAddress
    mapping(address => SwapConfig) public getSwapConfig;
    mapping(address => bool) public operators;

    IronSwapRouter public swapRouter;
    address[] public whiteListedTokens;
    uint256 constant swapTimeout = 3600;

    /* ========== PUBLIC FUNCTIONS ========== */

    function transfer(IERC20 token, address to, uint256 amount) external {
        if (operators[msg.sender] == true) {
            uint256 _before = token.balanceOf(address(this));
            if (_before >= amount) {
                token.safeTransfer(to, amount);
                uint256 _after = token.balanceOf(address(this));
                require(_before - _after == amount, 'transfer-fail');
                emit TransferFee(msg.sender, to, token, amount);
            }
        }
    }

    function swap() external {
        if (operators[msg.sender] == true) {
            for (uint256 i = 0; i < whiteListedTokens.length; i++) {
                address fromToken = whiteListedTokens[i];
                SwapConfig storage swapConfig = getSwapConfig[fromToken];

                if (swapConfig.poolType == SwapPoolType.plain) {
                    swapPlainPool(swapConfig, fromToken);
                } else if (swapConfig.poolType == SwapPoolType.meta) {
                    swapMetaPool(swapConfig, fromToken);
                }
            }
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function swapPlainPool(SwapConfig storage config, address fromTokenAddress) internal {
        IERC20 fromToken = IERC20(fromTokenAddress);
        uint256 inAmount = fromToken.balanceOf(address(this));
        if (inAmount > 0) {
            IIronSwap pool = IIronSwap(config.pool);
            uint8 fromIndex = pool.getTokenIndex(fromTokenAddress);
            uint8 toIndex = pool.getTokenIndex(target);
            fromToken.safeIncreaseAllowance(config.pool, inAmount);
            pool.swap(fromIndex, toIndex, inAmount, 0, block.timestamp + swapTimeout);
        }
    }

    function swapMetaPool(SwapConfig storage config, address fromTokenAddress) internal {
        IERC20 fromToken = IERC20(fromTokenAddress);
        uint256 inAmount = fromToken.balanceOf(address(this));

        if (inAmount > 0) {
            IIronSwap pool = IIronSwap(config.pool);
            IIronSwap basePool = IIronSwap(config.basePool);
            uint8 tokenIndexFrom = pool.getTokenIndex(fromTokenAddress);
            uint8 tokenIndexTo = basePool.getTokenIndex(target);
            fromToken.safeIncreaseAllowance(address(swapRouter), inAmount);
            swapRouter.swapToBase(
                pool,
                basePool,
                tokenIndexFrom,
                tokenIndexTo,
                inAmount,
                0,
                block.timestamp + swapTimeout
            );
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function initialize(address _target, address _swapRouter) external onlyOwner initializer {
        target = _target;
        swapRouter = IronSwapRouter(_swapRouter);
    }

    function toggleOperator(address _operator) external onlyOwner {
        operators[_operator] = !operators[_operator];
    }

    function setSwapConfig(
        address _fromToken,
        SwapPoolType poolType,
        address pool,
        address basePool
    ) external onlyOwner {
        require(_fromToken != address(0), "zeroFromTokenAddress");
        require(pool != address(0), "zeroPoolAddress");

        if (poolType == SwapPoolType.meta) {
            require(basePool != address(0), "zeroBasePoolAddress");
        }

        if (getSwapConfig[_fromToken].pool == address(0)) {
            whiteListedTokens.push(_fromToken);
        }

        getSwapConfig[_fromToken] = SwapConfig({poolType: poolType, pool: pool, basePool: basePool});
    }


    /* =============== EVENTS ==================== */

    event TransferFee(address caller, address to, IERC20 token, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IIronSwap {
    /// EVENTS
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 tokenSupply
    );

    event TokenExchange(
        address indexed buyer,
        uint256 soldId,
        uint256 tokensSold,
        uint256 boughtId,
        uint256 tokensBought
    );

    event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256[] fees, uint256 tokenSupply);

    event RemoveLiquidityOne(address indexed provider, uint256 tokenIndex, uint256 tokenAmount, uint256 coinAmount);

    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 tokenSupply
    );

    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);

    event StopRampA(uint256 A, uint256 timestamp);

    event NewFee(uint256 fee, uint256 adminFee, uint256 withdrawFee);

    event CollectProtocolFee(address token, uint256 amount);

    event FeeControllerChanged(address newController);

    event FeeDistributorChanged(address newController);

    // pool data view functions
    function getLpToken() external view returns (IERC20 lpToken);

    function getA() external view returns (uint256);

    function getAPrecise() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokens() external view returns (IERC20[] memory);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getTokenBalances() external view returns (uint256[] memory);

    function getNumberOfTokens() external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);

    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateRemoveLiquidity(address account, uint256 amount) external view returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    function getAdminBalances() external view returns (uint256[] memory adminBalances);

    function getAdminBalance(uint8 index) external view returns (uint256);

    function calculateCurrentWithdrawFee(address account) external view returns (uint256);

    // state modifying functions
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    function updateUserWithdrawFee(address recipient, uint256 transferAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/IIronSwap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract IronSwapRouter {
    using SafeERC20 for IERC20;

    function calculateConvert(
        IIronSwap fromPool,
        IIronSwap toPool,
        uint256 amount
    ) external view returns (uint256) {
        uint256 fromPoolLength = fromPool.getNumberOfTokens();
        uint256[] memory amounts = fromPool.calculateRemoveLiquidity(address(this), amount);
        uint256[] memory meta_amounts = new uint256[](fromPoolLength);
        for (uint8 i = 0; i < fromPoolLength; i++) {
            IERC20 fromCoin = fromPool.getToken(i);
            uint256 toCoinIndex = toPool.getTokenIndex(address(fromCoin));
            meta_amounts[toCoinIndex] = amounts[i];
        }
        return toPool.calculateTokenAmount(meta_amounts, true);
    }

    function convert(
        IIronSwap fromPool,
        IIronSwap toPool,
        uint256 amount,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256) {
        uint256 fromPoolLength = fromPool.getNumberOfTokens();
        uint256 toPoolLength = toPool.getNumberOfTokens();
        require(address(fromPool) != address(toPool), "fromPool = toPool");
        require(fromPoolLength == toPoolLength, "poolTokensLengthMissmatch");
        IERC20 fromToken = fromPool.getLpToken();
        IERC20 toToken = toPool.getLpToken();
        uint256[] memory min_amounts = new uint256[](fromPoolLength);
        // validate token
        for (uint8 i = 0; i < fromPoolLength; i++) {
            IERC20 coin = fromPool.getToken(i);
            toPool.getTokenIndex(address(coin));
        }
        fromToken.transferFrom(msg.sender, address(this), amount);
        fromToken.safeIncreaseAllowance(address(fromPool), amount);
        fromPool.removeLiquidity(amount, min_amounts, deadline);

        uint256[] memory meta_amounts = new uint256[](toPoolLength);

        for (uint8 i = 0; i < toPoolLength; i++) {
            IERC20 coin = toPool.getToken(i);
            uint256 addBalance = coin.balanceOf(address(this));
            coin.safeIncreaseAllowance(address(toPool), addBalance);
            meta_amounts[i] = addBalance;
        }
        toPool.addLiquidity(meta_amounts, minToMint, deadline);

        uint256 lpAmount = toToken.balanceOf(address(this));
        toToken.transfer(msg.sender, lpAmount);
        return lpAmount;
    }

    function addLiquidity(
        IIronSwap pool,
        IIronSwap basePool,
        uint256[] memory meta_amounts,
        uint256[] memory base_amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256) {
        IERC20 token = IERC20(pool.getLpToken());
        require(base_amounts.length == basePool.getNumberOfTokens(), "invalidBaseAmountsLength");
        require(meta_amounts.length == pool.getNumberOfTokens(), "invalidMetaAmountsLength");
        bool deposit_base = false;
        for (uint8 i = 0; i < base_amounts.length; i++) {
            uint256 amount = base_amounts[i];
            if (amount > 0) {
                deposit_base = true;
                IERC20 coin = basePool.getToken(i);
                coin.safeTransferFrom(msg.sender, address(this), amount);
                uint256 transferred = coin.balanceOf(address(this));
                coin.safeIncreaseAllowance(address(basePool), transferred);
                base_amounts[i] = transferred;
            }
        }
        if (deposit_base) {
            basePool.addLiquidity(base_amounts, 0, deadline);
        }

        for (uint8 i = 0; i < meta_amounts.length; i++) {
            IERC20 coin = pool.getToken(i);
            if (meta_amounts[i] > 0) {
                coin.safeTransferFrom(msg.sender, address(this), meta_amounts[i]);
            }
            uint256 transferred = coin.balanceOf(address(this));
            coin.safeIncreaseAllowance(address(pool), transferred);
            meta_amounts[i] = transferred;
        }
        pool.addLiquidity(meta_amounts, minToMint, deadline);
        uint256 lpAmount = token.balanceOf(address(this));
        token.transfer(msg.sender, lpAmount);
        return lpAmount;
    }

    function removeLiquidity(
        IIronSwap pool,
        IIronSwap basePool,
        uint256 _amount,
        uint256[] calldata min_amounts_meta,
        uint256[] calldata min_amounts_base,
        uint256 deadline
    ) external returns (uint256[] memory amounts, uint256[] memory base_amounts) {
        IERC20 token = pool.getLpToken();
        IERC20 baseToken = basePool.getLpToken();
        token.transferFrom(msg.sender, address(this), _amount);
        token.safeIncreaseAllowance(address(pool), _amount);
        pool.removeLiquidity(_amount, min_amounts_meta, deadline);
        uint256 _base_amount = baseToken.balanceOf(address(this));
        baseToken.safeIncreaseAllowance(address(basePool), _base_amount);

        basePool.removeLiquidity(_base_amount, min_amounts_base, deadline);
        // Transfer all coins out
        amounts = new uint256[](pool.getNumberOfTokens());
        for (uint8 i = 0; i < pool.getNumberOfTokens(); i++) {
            IERC20 coin = pool.getToken(i);
            amounts[i] = coin.balanceOf(address(this));
            if (amounts[i] > 0) {
                coin.safeTransfer(msg.sender, amounts[i]);
            }
        }

        base_amounts = new uint256[](basePool.getNumberOfTokens());
        for (uint8 i = 0; i < basePool.getNumberOfTokens(); i++) {
            IERC20 coin = basePool.getToken(i);
            base_amounts[i] = coin.balanceOf(address(this));
            if (base_amounts[i] > 0) {
                coin.safeTransfer(msg.sender, base_amounts[i]);
            }
        }
    }

    function calculateTokenAmount(
        IIronSwap pool,
        IIronSwap basePool,
        uint256[] memory meta_amounts,
        uint256[] memory base_amounts,
        bool is_deposit
    ) external view returns (uint256) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        uint256 _base_tokens = basePool.calculateTokenAmount(base_amounts, is_deposit);
        meta_amounts[baseTokenIndex] = meta_amounts[baseTokenIndex] + _base_tokens;
        return pool.calculateTokenAmount(meta_amounts, is_deposit);
    }

    function calculateRemoveLiquidity(
        IIronSwap pool,
        IIronSwap basePool,
        uint256 amount
    ) external view returns (uint256[] memory meta_amounts, uint256[] memory base_amounts) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        meta_amounts = pool.calculateRemoveLiquidity(address(this), amount);
        uint256 lpAmount = meta_amounts[baseTokenIndex];
        meta_amounts[baseTokenIndex] = 0;
        base_amounts = basePool.calculateRemoveLiquidity(address(this), lpAmount);
    }

    function swapFromBase(
        IIronSwap pool,
        IIronSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        uint256[] memory base_amounts = new uint256[](basePool.getNumberOfTokens());
        base_amounts[tokenIndexFrom] = dx;
        IERC20 coin = basePool.getToken(tokenIndexFrom);
        coin.safeTransferFrom(msg.sender, address(this), dx);
        coin.safeIncreaseAllowance(address(basePool), dx);
        uint256 baseLpAmount = basePool.addLiquidity(base_amounts, 0, deadline);
        if (baseTokenIndex != tokenIndexTo) {
            baseToken.safeIncreaseAllowance(address(pool), baseLpAmount);
            pool.swap(baseTokenIndex, tokenIndexTo, baseLpAmount, minDy, deadline);
        }
        IERC20 coinTo = pool.getToken(tokenIndexTo);
        uint256 amountOut = coinTo.balanceOf(address(this));
        coinTo.safeTransfer(msg.sender, amountOut);
        return amountOut;
    }

    function calculateSwapFromBase(
        IIronSwap pool,
        IIronSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        uint256[] memory base_amounts = new uint256[](basePool.getNumberOfTokens());
        base_amounts[tokenIndexFrom] = dx;
        uint256 baseLpAmount = basePool.calculateTokenAmount(base_amounts, true);
        if (baseTokenIndex == tokenIndexTo) {
            return baseLpAmount;
        }
        return pool.calculateSwap(baseTokenIndex, tokenIndexTo, baseLpAmount);
    }

    function swapToBase(
        IIronSwap pool,
        IIronSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        IERC20 coin = pool.getToken(tokenIndexFrom);
        coin.safeTransferFrom(msg.sender, address(this), dx);
        uint256 tokenLPAmount = dx;
        if (baseTokenIndex != tokenIndexFrom) {
            coin.safeIncreaseAllowance(address(pool), dx);
            tokenLPAmount = pool.swap(tokenIndexFrom, baseTokenIndex, dx, 0, deadline);
        }
        baseToken.safeIncreaseAllowance(address(basePool), tokenLPAmount);
        basePool.removeLiquidityOneToken(tokenLPAmount, tokenIndexTo, minDy, deadline);
        IERC20 coinTo = basePool.getToken(tokenIndexTo);
        uint256 amountOut = coinTo.balanceOf(address(this));
        coinTo.safeTransfer(msg.sender, amountOut);
        return amountOut;
    }

    function calculateSwapToBase(
        IIronSwap pool,
        IIronSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256) {
        IERC20 baseToken = basePool.getLpToken();
        uint8 baseTokenIndex = pool.getTokenIndex(address(baseToken));
        uint256 tokenLPAmount = dx;
        if (baseTokenIndex != tokenIndexFrom) {
            tokenLPAmount = pool.calculateSwap(tokenIndexFrom, baseTokenIndex, dx);
        }
        return basePool.calculateRemoveLiquidityOneToken(address(this), tokenLPAmount, tokenIndexTo);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}