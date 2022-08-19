// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./interfaces/IUniswapPool.sol";
import "./interfaces/IAAPLTokenizer.sol";

error SameAAPLPrice();

contract AAPLDataFeed is AccessControl  {
  /// @dev AAPLT Token contract
  address public AAPL_TOKEN;

  /// @dev Uniswap V3 Pool contract
  address public UNISWAP_POOL;

  /// @dev Latest AAPL PRICE
  uint256 public latestPrice;

  /// @dev Latest AAPL PRICE timestamp
  uint256 public updatedAt;

  function _mint() private {
    IAAPLTokenizer token = getAAPL();
    (uint256 price, ) = getLatestPrice();
    token.mint(address(this), 100 * 10**18);
  }

  function _burn() private {
    IAAPLTokenizer token = getAAPL();
    token.burn(address(this), 100 * 10**18);
  }

  function setAAPL(address _aapl) external onlyOwner {
    AAPL_TOKEN = _aapl;
  }

  function setLatestPrice(uint256 _price) external {
    if (latestPrice == _price) {
      revert SameAAPLPrice();
    }

    if (latestPrice > _price) {
      _burn();
    } else {
      _mint();
    }

    latestPrice = _price;
    updatedAt = block.timestamp;
    emit NewPrice(latestPrice, updatedAt);
  }

  function getLatestPrice() public view returns (uint256, uint256) {
    return (latestPrice, updatedAt);
  }

  function getAAPL() public view returns (IAAPLTokenizer) {
    return IAAPLTokenizer(AAPL_TOKEN);
  }

  event NewPrice(uint256 timestamp, uint256 price);
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

interface IAAPLTokenizer {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
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