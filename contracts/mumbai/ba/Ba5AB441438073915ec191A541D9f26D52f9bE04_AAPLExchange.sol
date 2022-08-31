// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstract/Pausable.sol";
import "./abstract/AccessControl.sol";
import "./abstract/Initializer.sol";
import "./interfaces/IUniswapPool.sol";
import "./interfaces/IAAPLTokenizer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error SameAAPLPrice();
error InvalidAAPLAmount();
error InvalidETHAmount();

contract AAPLExchange is AccessControl, Pausable, ReentrancyGuard, Initializer {
    /// @dev AAPLT Token contract
    address public AAPL_TOKEN;

    /// @dev Uniswap V3 Pool contract
    address public UNISWAP_POOL;

    /// @dev Latest AAPL PRICE
    uint256 public latestPrice;

    /// @dev Latest AAPL PRICE timestamp
    uint256 public updatedAt;

    /// @dev Contract initializer
    function initialize() external {
        addOperator(_msgSender());
        pause();
    }

    /// @dev Set AAPLTokenizer contract address
    function setAAPL(address _aapl) external onlyOwner {
        AAPL_TOKEN = _aapl;
    }

    /// @dev Withdraw ETH
    function withdrawETH(address _who, uint256 _amount) external onlyOwner {
        payable(_who).transfer(_amount);
    }

    /// @dev Withdraw AAPL
    function withdrawAAPL(address _who, uint256 _amount) external onlyOwner {
        getAAPL().transfer(_who, _amount);
    }

    /// @dev Set AAPLToken price
    function setLatestPrice(uint256 _price) external onlyOperator {
        latestPrice = _price;
        updatedAt = block.timestamp;
        emit NewPrice(latestPrice, updatedAt);
    }

    /// @dev Buy AAPLT with ETH
    function buy(uint256 _amount) external payable nonReentrant {
        if (_amount == 0) revert InvalidAAPLAmount();

        uint256 amount = _amount;
        uint256 ethAmount = (latestPrice * amount) / 10**18;
        if (msg.value != ethAmount) revert InvalidETHAmount();

        getAAPL().mint(_msgSender(), amount);

        emit Buy(_msgSender(), ethAmount, amount);
    }

    /// @dev Sell AAPLT
    function sell(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert InvalidAAPLAmount();

        uint256 amount = _amount;
        getAAPL().transferFrom(_msgSender(), address(this), amount);

        uint256 ethAmount = (latestPrice * amount) / 10**18;
        payable(_msgSender()).transfer(ethAmount);

        emit Sell(_msgSender(), ethAmount, amount);
    }

    /// @dev Get Latest Price Changes
    function getLatestPrice() public view returns (uint256, uint256) {
        return (latestPrice, updatedAt);
    }

    /// @dev Get AAPLTokenizer contract address
    function getAAPL() public view returns (IAAPLTokenizer) {
        return IAAPLTokenizer(AAPL_TOKEN);
    }

    event NewPrice(uint256 timestamp, uint256 price);
    event Buy(address buyer, uint256 ethAmount, uint256 btcAmount);
    event Sell(address seller, uint256 ethAmount, uint256 btcAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Pausable {
    bool private _paused;

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
    function pause() public virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

error AlreadyAdded();
error NotAdded();
error OnlyOperator();
error InvalidAddress();

abstract contract AccessControl is Ownable {
    mapping(address => bool) public operators;

    function addOperator(address _operator) public onlyOwner {
        if (_operator == address(0)) revert InvalidAddress();
        if (operators[_operator]) revert AlreadyAdded();

        operators[_operator] = true;
    }

    function addOperators(address[] calldata _operators) external onlyOwner {
        uint256 length = _operators.length;
        for (uint256 i = 0; i < length; i++) {
            addOperator(_operators[i]);
        }
    }

    function revokeOperator(address _operator) public onlyOwner {
        if (_operator == address(0)) revert InvalidAddress();
        if (operators[_operator]) revert NotAdded();

        operators[_operator] = false;
    }

    function revokeOperators(address[] calldata _operators) external onlyOwner {
        uint256 length = _operators.length;
        for (uint256 i = 0; i < length; i++) {
            revokeOperator(_operators[i]);
        }
    }

    modifier onlyOperator() {
        if (!operators[_msgSender()]) revert OnlyOperator();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error AlreadyInitialized();

abstract contract Initializer {
  bool private _isInitialized;

  modifier initializer() {
    if (_isInitialized) revert AlreadyInitialized();
    _;
    _isInitialized = true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniswapPool {
  /// @notice Swap token0 for token1, or token1 for token0
  /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
  /// @param recipient The address to receive the output of the swap
  /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
  /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
  /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
  /// @param data Any data to be passed through to the callback
  /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
  /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
  function swap(
      address recipient,
      bool zeroForOne,
      int256 amountSpecified,
      uint160 sqrtPriceLimitX96,
      bytes calldata data
  ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAAPLTokenizer is IERC20 {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
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