// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IBridge.sol";
import "./interface/IDex.sol";

contract WagPayBridge is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _bridgeIds;
	address private constant NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    mapping(uint => address) bridges;

    struct DexData {
        address dex;
        uint amountIn;
        uint fees;
        uint64 chainId;
        address fromToken;
        address toToken;
        bytes extraData;
    }

    struct RouteData {
        address receiver;
        uint bridgeId;
        uint64 toChain;
        address fromToken;
        uint amount;
        bytes extraData;
        bool dexRequired;
        DexData dex;
    }

    function transfer(RouteData memory route) external payable {

        require(bridges[route.bridgeId] != address(0), "WagPay: Bridge doesn't exist");        

        IDex idex = IDex(route.dex.dex);
        IBridge bridge = IBridge(bridges[route.bridgeId]);

        if(route.dexRequired) {
            // Dex
            if(route.dex.fromToken == NATIVE_TOKEN_ADDRESS) {
                idex.swapNative{value: route.amount}(route.dex.toToken, route.dex.extraData);
            } else {
                IERC20(route.dex.fromToken).approve(route.dex.dex, route.amount);
                idex.swapERC20(route.dex.fromToken, route.dex.toToken, route.dex.amountIn,  route.dex.extraData);
            }

            // Bridge
            if(route.fromToken == NATIVE_TOKEN_ADDRESS) {
                bridge.transferNative{value: route.dex.amountIn}(route.dex.amountIn, route.receiver, route.toChain, route.extraData);
            } else {
                IERC20(route.fromToken).approve(bridges[route.bridgeId], route.dex.amountIn);
                bridge.transferERC20(route.toChain, route.fromToken, route.receiver, route.dex.amountIn, route.extraData);
            }

        } else {
            // Bridge
            if(route.fromToken == NATIVE_TOKEN_ADDRESS) {
                bridge.transferNative{value: route.amount}(route.amount, route.receiver, route.toChain, route.extraData);
            } else {
                IERC20(route.fromToken).approve(bridges[route.bridgeId], route.amount);
                bridge.transferERC20(route.toChain, route.fromToken, route.receiver, route.amount, route.extraData);
            }
        }
    }

    function addBridge(address newBridge) external onlyOwner returns (uint) {
        require(newBridge != address(0), "WagPay: Cannot be a address(0)");
        _bridgeIds.increment();
        uint bridgeId = _bridgeIds.current();
        bridges[bridgeId] = newBridge;
        return bridgeId;
    }

    function removeBridge(uint bridgeId) external onlyOwner {
        require(bridges[bridgeId] != address(0), "WagPay: Bridge doesn't exist");
        bridges[bridgeId] = address(0);
    }

    function getBridge(uint _bridgeId) external view returns (address) {
        return bridges[_bridgeId];
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBridge {

    event NativeFundsTransferred(address receiver, uint toChainId, uint amount);
	
    event ERC20FundsTransferred(address receiver, uint toChainId, uint amount, address tokenAddress);

    function transferNative(uint amount, 
        address receiver, 
        uint64 toChainId, 
        bytes memory extraData) external payable;

    function transferERC20(uint64 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        bytes memory extraData) external;

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDex {

    event NativeFundsSwapped(address tokenOut, uint amountIn, uint amountOut);
    
    event ERC20FundsSwapped(uint amountIn, address tokenIn, address tokenOut, uint amountOut);

    function swapNative(address _tokenOut,
        bytes memory extraData) external payable returns (uint amountOut);
    
    function swapERC20(address _tokenIn,
        address _tokenOut,
        uint amountIn,
        bytes memory extraData) external returns (uint amountOut);

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