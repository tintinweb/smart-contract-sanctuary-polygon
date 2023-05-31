//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../interfaces/swaps/uniswap/v3/IQuoter.sol";
import "../interfaces/swaps/uniswap/v3/ISwapRouter.sol";
import "../libraries/SwapAdapterBase.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/Path.sol";

contract UniswapV3SwapAdapter is SwapAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;
    using Path for address[];

    IQuoter private immutable _quoter;
    ISwapRouter private immutable _router;
    uint24[] private _feeRates;

    constructor(address quoter, address router, uint24[] memory feeRates) {
        _quoter = IQuoter(quoter);
        _router = ISwapRouter(router);
        _feeRates = feeRates;
        _setWrappedNativeAsset(_router.WETH9());
    }

    function getAmountIn(
        address[] memory path,
        uint256 amountOut
    ) external override returns (uint256 amountIn, bytes memory swapData) {
        _convertPath(path);
        uint24[] memory bestFees = new uint24[](path.length - 1);
        address tokenOut = path[path.length - 1];
        for (uint256 i = path.length - 2; i >= 0; i--) {
            uint24 bestFee = 0;
            address tokenIn = path[i];
            amountIn = 0;
            for (uint256 j = 0; j < _feeRates.length; j++) {
                try _quoter.quoteExactOutputSingle(tokenIn, tokenOut, _feeRates[j], amountOut, 0) returns (
                    uint256 amount
                ) {
                    if (amount > 0 && (amountIn == 0 || amount < amountIn)) {
                        amountIn = amount;
                        bestFee = _feeRates[j];
                    }
                } catch {}
            }
            if (amountIn == 0) {
                return (amountIn, swapData);
            }
            bestFees[i] = bestFee;
            tokenOut = tokenIn;
            amountOut = amountIn;
        }
        swapData = abi.encode(bestFees);
    }

    function getAmountOut(
        address[] memory path,
        uint256 amountIn
    ) external override returns (uint256 amountOut, bytes memory swapData) {
        _convertPath(path);
        uint24[] memory bestFees = new uint24[](path.length - 1);
        address tokenIn = path[0];
        for (uint256 i = 1; i < path.length; i++) {
            uint24 bestFee = 0;
            address tokenOut = path[i];
            amountOut = 0;
            for (uint256 j = 0; j < _feeRates.length; j++) {
                try _quoter.quoteExactInputSingle(tokenIn, tokenOut, _feeRates[j], amountIn, 0) returns (
                    uint256 amount
                ) {
                    if (amount > amountOut) {
                        amountOut = amount;
                        bestFee = _feeRates[j];
                    }
                } catch {}
            }
            if (amountOut == 0) {
                return (amountOut, swapData);
            }
            bestFees[i - 1] = bestFee;
            tokenIn = tokenOut;
            amountIn = amountOut;
        }
        swapData = abi.encode(bestFees);
    }

    function swap(
        SwapParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall handleWrap(params) returns (uint256 amountOut) {
        uint24[] memory poolFee = abi.decode(params.data, (uint24[]));
        require(params.path.length == poolFee.length + 1, "UniswapV3SwapAdapter: fee does not match path");
        address tokenIn = params.path[0];
        address tokenOut = params.path[params.path.length - 1];

        uint256 value = 0;
        if (tokenIn.isNativeAsset()) {
            value = params.amountIn;
        } else {
            IERC20(tokenIn).safeApproveToMax(address(_router), params.amountIn);
        }
        address[] memory swapPath = _convertPath(params.path);
        address recipient = params.recipient;
        if (tokenOut.isNativeAsset()) {
            recipient = address(this);
        }

        if (swapPath.length == 2) {
            amountOut = _router.exactInputSingle{value: value}(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: swapPath[0],
                    tokenOut: swapPath[1],
                    fee: poolFee[0],
                    recipient: recipient,
                    deadline: type(uint256).max,
                    amountIn: params.amountIn,
                    amountOutMinimum: params.minAmountOut,
                    sqrtPriceLimitX96: 0
                })
            );
        } else {
            amountOut = _router.exactInput{value: value}(
                ISwapRouter.ExactInputParams({
                    path: swapPath.buildPath(poolFee),
                    recipient: recipient,
                    deadline: type(uint256).max,
                    amountIn: params.amountIn,
                    amountOutMinimum: params.minAmountOut
                })
            );
        }

        if (tokenOut.isNativeAsset()) {
            _unwrapNativeAsset(amountOut, params.recipient);
        }
    }
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./AdapterBase.sol";
import "../interfaces/ISwapAdapter.sol";
import "../interfaces/tokens/IWrappedNativeAsset.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

abstract contract SwapAdapterBase is ISwapAdapter, AdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    // wrapped native asset address for swap in current chain
    address internal _wrappedNativeAsset;

    // @dev handle swap between native asset and wrapped native asset
    // @notice if swapped between native asset and wrapped native asset, the modified function will return default value
    modifier handleWrap(SwapParams calldata params) {
        address tokenIn = params.path[0];
        address tokenOut = params.path[params.path.length - 1];
        if (tokenIn.isNativeAsset() && tokenOut == WrappedNativeAsset()) {
            _wrapNativeAsset(params.amountIn, params.recipient);
            return;
        } else if (tokenIn == WrappedNativeAsset() && tokenOut.isNativeAsset()) {
            _unwrapNativeAsset(params.amountIn, params.recipient);
            return;
        }
        _;
    }

    function getAmountIn(
        address[] memory path,
        uint256 amountOut
    ) external virtual override returns (uint256, bytes memory) {
        return getAmountInView(path, amountOut);
    }

    function getAmountOut(
        address[] memory path,
        uint256 amountIn
    ) external virtual override returns (uint256, bytes memory) {
        return getAmountOutView(path, amountIn);
    }

    function getAmountInView(address[] memory, uint256) public view virtual returns (uint256, bytes memory) {
        revert("SwapAdapterBase: not supported");
    }

    function getAmountOutView(address[] memory, uint256) public view virtual returns (uint256, bytes memory) {
        revert("SwapAdapterBase: not supported");
    }

    // @dev get wrapped native asset address for swap in current chain
    function WrappedNativeAsset() public view virtual returns (address) {
        return _wrappedNativeAsset;
    }

    // @dev transfer native asset to recipient in wrapped token
    function _wrapNativeAsset(uint256 amount, address recipient) internal {
        require(address(this).balance >= amount, "SwapAdapterBase: not enough native asset in transaction");
        if (amount > 0) {
            IWrappedNativeAsset wna = IWrappedNativeAsset(WrappedNativeAsset());
            wna.deposit{value: amount}();
            IERC20(wna).safeTransfer(recipient, amount);
        }
    }

    // @dev transfer wrapped token to recipient in native asset
    function _unwrapNativeAsset(uint256 amount, address recipient) internal {
        IWrappedNativeAsset wna = IWrappedNativeAsset(WrappedNativeAsset());
        uint256 balance = wna.balanceOf(address(this));
        require(balance >= amount, "SwapAdapterBase: not enough native asset in transaction");
        if (amount > 0) {
            wna.withdraw(amount);
            recipient.safeTransfer(amount);
        }
    }

    // @dev set wrapped native asset address for swap in current chain
    function _setWrappedNativeAsset(address addr) internal {
        _wrappedNativeAsset = addr;
    }

    // @dev replace native asset address to wrapped token address
    function _convertPath(address[] memory path) internal view returns (address[] memory) {
        for (uint256 i = 0; i < path.length; i++) {
            if (path[i].isNativeAsset()) {
                path[i] = WrappedNativeAsset();
            }
        }
        return path;
    }
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

library SafeNativeAsset {
    // native asset address
    address internal constant NATIVE_ASSET = address(0);

    function nativeAsset() internal pure returns (address) {
        return NATIVE_ASSET;
    }

    function isNativeAsset(address addr) internal pure returns (bool) {
        return addr == NATIVE_ASSET;
    }

    function safeTransfer(address recipient, uint256 amount) internal {
        require(recipient != address(0), "SafeNativeAsset: transfer to the zero address");
        (bool success, ) = recipient.call{value: amount}(new bytes(0));
        require(success, "SafeNativeAsset: safe transfer native assets failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)
// Modified by UXUY

pragma solidity ^0.8.0;

import "../interfaces/tokens/IERC20.sol";
import "./Address.sol";

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

    address internal constant TRON_USDT_ADDRESS = address(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(to != address(0), "SafeERC20: transfer to the zero address");
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferTron(IERC20 token, address to, uint256 value) internal {
        require(to != address(0), "SafeERC20: transfer to the zero address");
        if (address(token) == TRON_USDT_ADDRESS) {
            // For USDT on Tron, transfer method always returns false, so _callOptionalReturn can not be used.
            token.transfer(to, value);
        } else {
            _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(to != address(0), "SafeERC20: transfer to the zero address");
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeApproveToMax(IERC20 token, address spender, uint256 value) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance >= value) {
            return;
        }
        // For ERC-20 that has safe approve check, set approval to 0 before approve to max
        if (allowance > 0) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        }
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, type(uint256).max));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

library Path {
    function buildPath(address[] memory path, uint24[] memory fee) internal pure returns (bytes memory) {
        require(path.length >= 2 && path.length <= 5, "Path: path length should between 2 and 5");
        require(path.length == fee.length + 1, "Path: path length should match fee length");
        if (path.length == 2) {
            return abi.encodePacked(path[0], fee[0], path[1]);
        } else if (path.length == 3) {
            return abi.encodePacked(path[0], fee[0], path[1], fee[1], path[2]);
        } else if (path.length == 4) {
            return abi.encodePacked(path[0], fee[0], path[1], fee[1], path[2], fee[2], path[3]);
        } else {
            return abi.encodePacked(path[0], fee[0], path[1], fee[1], path[2], fee[2], path[3], fee[3], path[4]);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Pausable.sol";
import "./CallerControl.sol";
import "./SafeNativeAsset.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract CommonBase is Ownable, Pausable, CallerControl, ReentrancyGuard {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    uint256 internal constant TRON_CHAIN_ID = 0x1ebf88508a03865c71d452e25f4d51194196a1d22b6653dc;

    // The original address of this contract
    address private immutable _original;

    // ERC20 safeTransfer function pointer
    function(IERC20, address, uint256) internal _safeTransferERC20;

    // @dev Emitted when native assets (token=address(0)) or tokens are withdrawn by owner.
    event Withdrawn(address indexed token, address indexed to, uint256 amount);

    constructor() {
        _original = address(this);
        if (block.chainid == TRON_CHAIN_ID) {
            _safeTransferERC20 = SafeERC20.safeTransferTron;
        } else {
            _safeTransferERC20 = SafeERC20.safeTransfer;
        }
    }

    // @dev prevents delegatecall into the modified method
    modifier noDelegateCall() {
        _checkNotDelegateCall();
        _;
    }

    // @dev check whether deadline is reached
    modifier checkDeadline(uint256 deadline) {
        require(deadline == 0 || block.timestamp <= deadline, "CommonBase: transaction too old");
        _;
    }

    // @dev fallback function to receive native assets
    receive() external payable {}

    // @dev pause stops contract from doing any swap
    function pause() external onlyOwner {
        _pause();
    }

    // @dev resumes contract to do swap
    function unpause() external onlyOwner {
        _unpause();
    }

    // @dev withdraw eth to recipient
    function withdrawNativeAsset(uint256 amount, address recipient) external onlyOwner {
        recipient.safeTransfer(amount);
        emit Withdrawn(address(0), recipient, amount);
    }

    // @dev withdraw token to owner account
    function withdrawToken(address token, uint256 amount, address recipient) external onlyOwner {
        _safeTransferERC20(IERC20(token), recipient, amount);
        emit Withdrawn(token, recipient, amount);
    }

    // @dev update caller allowed status
    function updateAllowedCaller(address caller, bool allowed) external onlyOwner {
        _updateAllowedCaller(caller, allowed);
    }

    // @dev ensure not a delegatecall
    function _checkNotDelegateCall() private view {
        require(address(this) == _original, "CommonBase: delegate call not allowed");
    }
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./Context.sol";

abstract contract CallerControl is Context {
    mapping(address => bool) private _allowedCallers;

    // @dev Emitted when allowed caller is changed.
    event AllowedCallerChanged(address indexed caller, bool allowed);

    // @dev modifier to check if message sender is allowed caller
    modifier onlyAllowedCaller() {
        require(_allowedCallers[_msgSender()], "CallerControl: msgSender is not allowed to call");
        _;
    }

    function _updateAllowedCaller(address caller, bool allowed) internal {
        if (allowed) {
            _allowedCallers[caller] = true;
        } else {
            delete _allowedCallers[caller];
        }
        emit AllowedCallerChanged(caller, allowed);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./CommonBase.sol";
import "../interfaces/IBridgeAdapter.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

abstract contract AdapterBase is CommonBase {}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;
import "./IERC20.sol";

interface IWrappedNativeAsset is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 recipient) external;
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.11;

interface ISwapRouter {
    function WETH9() external view returns (address);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.11;

interface IQuoter {
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface ISwapAdapter {
    struct SwapParams {
        address[] path;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient;
        bytes data;
    }

    function getAmountIn(
        address[] memory path,
        uint256 amountOut
    ) external returns (uint256 amountIn, bytes memory swapData);

    function getAmountOut(
        address[] memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut, bytes memory swapData);

    // @dev view only version of getAmountIn
    function getAmountInView(
        address[] memory path,
        uint256 amountOut
    ) external view returns (uint256 amountIn, bytes memory swapData);

    // @dev view only version of getAmountOut
    function getAmountOutView(
        address[] memory path,
        uint256 amountIn
    ) external view returns (uint256 amountOut, bytes memory swapData);

    // @dev calls swap router to fulfill the exchange
    // @return amountOut the amount of tokens transferred out, may be 0 if this can not be fetched
    function swap(SwapParams calldata params) external payable returns (uint256 amountOut);
}

//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface IBridgeAdapter {
    struct BridgeParams {
        address tokenIn;
        uint256 chainIDOut;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient;
        bytes data;
    }

    function supportSwap() external pure returns (bool);

    // @dev calls bridge router to fulfill the exchange
    // @return amountOut the amount of tokens transferred out, may be 0 if can not be fetched
    // @return txnID the transaction id of the bridge, may be 0 if not exist
    function bridge(BridgeParams calldata params) external payable returns (uint256 amountOut, uint256 txnID);
}