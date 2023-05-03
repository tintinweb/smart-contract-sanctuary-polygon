// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;


/**
*  Pool's functionality required by DAOOperations and DAOFarm
*/

interface ISwapsRouter {

    function getAmountOutMin(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 feeV3
    ) external returns (uint amountOut);

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient,
        uint24 feeV3
    ) external returns (uint amountOut);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;


//// V3 Quoter interfaces  ////

interface IQuoter_Uniswap {

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}


interface IQuoter_Quickswap {

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint160 limitSqrtPrice
    ) external returns (uint256 amountOut, uint16 fee);
}



//// V3 Router Intervaces ////

interface ISwapRouter_Uniswap {

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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}



interface ISwapRouter_Quickswap {

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

interface IUniswapV2Router {

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn, //amount of tokens we are sending in
        uint amountOutMin, //the minimum amount of tokens we want out of the trade
        address[] calldata path,  //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address to,  //this is the address we are going to send the output tokens to
        uint deadline //the last time that the trade is valid for
    ) external returns (uint[] memory amounts);

    function WETH() external returns (address addr);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../TokenMaths.sol";

import "./IUniswapV2Router.sol";
import "./ISwapsRouter.sol";
import "./ISwapsV3.sol";


/**
 * Owner of this contract should be DAOOperations
 */
contract SwapsRouter is ISwapsRouter, ReentrancyGuard, Ownable {

    enum RouterVersion { V2, V3 }
    enum RouterType { Uniswap, QuickSwap }

    struct RouterInfo {
        address routerAddress;
        RouterVersion routerVersion;
        RouterType routerType;
    }

    IQuoter_Uniswap quoterUniswap;
    IQuoter_Quickswap quoterQuickswap;

    uint public activeRouterIdx = 0;
    RouterInfo[] public routers;


    constructor(address quoterUniswapAddress, address quoterQuickswapAddress) {
        quoterUniswap = IQuoter_Uniswap(quoterUniswapAddress);
        quoterQuickswap = IQuoter_Quickswap(quoterQuickswapAddress);
    }


    function getRouters() public view returns (RouterInfo[] memory) {
        return routers;
    }


    function activeRouter() public view returns (RouterInfo memory) {
        require (activeRouterIdx < routers.length, "SwapsRouter: Invalid router index");

        return routers[activeRouterIdx];
    }


    /**
     * Entry point for Pool swaps.
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient,
        uint24 feeV3
    ) external returns (uint amountOut) {

        // transfer the tokens to this contract and aprove spend from the AMM
        RouterInfo memory routerInfo = activeRouter();

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(routerInfo.routerAddress), amountIn);

        if (routerInfo.routerVersion == RouterVersion.V3 && routerInfo.routerType == RouterType.Uniswap ) {
            ISwapRouter_Uniswap.ExactInputSingleParams memory params = ISwapRouter_Uniswap
                .ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    fee: feeV3,
                    recipient: recipient,
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin,
                    sqrtPriceLimitX96: 0
                });

            ISwapRouter_Uniswap router = ISwapRouter_Uniswap(routerInfo.routerAddress);

            amountOut = router.exactInputSingle(params);

        } else if (routerInfo.routerVersion == RouterVersion.V3 && routerInfo.routerType == RouterType.QuickSwap ) {
            ISwapRouter_Quickswap.ExactInputSingleParams memory params = ISwapRouter_Quickswap
                .ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    recipient: recipient,
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin,
                    limitSqrtPrice: 0
                });

            ISwapRouter_Quickswap router = ISwapRouter_Quickswap(routerInfo.routerAddress);
            amountOut = router.exactInputSingle(params);

        } else if (routerInfo.routerVersion == RouterVersion.V2) {
            // path is an array of addresses and we assume there is a direct pair btween the in and out tokens
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;

            // the deadline is the latest time the trade is valid for
            // for the deadline we will pass in block.timestamp
            IUniswapV2Router router = IUniswapV2Router(routerInfo.routerAddress);
            uint256[] memory amounstOut = router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                recipient,
                block.timestamp
            );

            amountOut = amounstOut[amounstOut.length - 1];
        }

    }



    /**
    * @return amountOut the minimum amount of tokens expected from the V2 or v3 swap
    */
    function getAmountOutMin(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 feeV3
    ) external returns (uint amountOut) {

        RouterInfo memory routerInfo = activeRouter();

        if (routerInfo.routerVersion == RouterVersion.V3 && routerInfo.routerType == RouterType.Uniswap ) {
            amountOut = quoterUniswap.quoteExactInputSingle(tokenIn, tokenOut, feeV3, amountIn, 0);

        } else if (routerInfo.routerVersion == RouterVersion.V3 && routerInfo.routerType == RouterType.QuickSwap ) {
            (amountOut, ) = quoterQuickswap.quoteExactInputSingle(tokenIn, tokenOut, amountIn, 0);

        } else if (routerInfo.routerVersion == RouterVersion.V2) {
            IUniswapV2Router router = IUniswapV2Router(routerInfo.routerAddress);
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;

            uint256[] memory amountOutMins = router.getAmountsOut(amountIn, path);
            amountOut = amountOutMins[path.length - 1];
        }
    }


    //// ONLY OWNER ////

    function addRouter(address routerAddress,  RouterVersion routerVersion, RouterType routerType) public onlyOwner {
        RouterInfo memory info = RouterInfo({
            routerAddress: routerAddress,
            routerVersion: routerVersion,
            routerType: routerType
        });
        routers.push(info);
    }

    function setActiveRouter(uint routerIndex) public onlyOwner {
        activeRouterIdx = routerIndex;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;


/**
 * @title TokenMaths
 * @dev Library for simple arithmetics operations between tokens of different decimals, up to 18 decimals.
 */
library TokenMaths {

    /**
     * @notice division between 2 token amounts with different decimals. Assumes decimals1 <= 18 and decimals2 <= 18.
     * The returns value is provided with decimalsOut decimals.
     */
    function div(uint amount1, uint amount2, uint8 decimals1, uint8 decimals2, uint8 decimalsOut) internal pure returns (uint) {
        return (10 ** decimalsOut * toWei(amount1, decimals1) / toWei(amount2, decimals2));
    }


    /**
     * @notice multiplication between 2 token amounts with different decimals. Assumes decimals1 <= 18 and decimals2 <= 18.
     * The returns value is provided with decimalsOut decimals.
     */
    function mul(uint amount1, uint amount2, uint8 decimals1, uint8 decimals2, uint8 decimalsOut) internal pure returns (uint) {
       return 10 ** decimalsOut * amount1 * amount2 / 10 ** (decimals1 + decimals2);
    }


    /**
     * @notice converts an amount, having less than 18 decimals, to to a value with 18 decimals.
     * Otherwise returns the provided amount unchanged.
     */
    function toWei(uint amount, uint8 decimals) internal pure returns (uint) {

        if (decimals >= 18) return amount;

        return amount * 10 ** (18 - decimals);
    }


    /**
     * @notice converts an amount, having 18 decimals, to to a value with less than 18 decimals.
     * Otherwise returns the provided amount unchanged.
     */
    function fromWei(uint amount, uint8 decimals) internal pure returns (uint) {

        if (decimals >= 18) return amount;

        return amount / 10 ** (18 - decimals);
    }

}