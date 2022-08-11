// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IVwapOracle.sol";


contract VwapOracle is Ownable, IVwapOracle {
    
    address[] public tokenToWatchPrices;
    mapping(address => uint256) public storedTokenPrices;

    mapping(address => address) proxyAddresses;

    constructor() {}

    function _getTokenIndex(address token) internal view returns (bool, uint256) {
        for (uint256 i = 0; i < tokenToWatchPrices.length;) {
            if (token == tokenToWatchPrices[i]) {
                return (true, i);
            }
            unchecked {
                ++i;
            }
        }
        return (false, 0);
    }

    function isToken(address token) public view returns (bool) {
        (bool found, ) = _getTokenIndex(token);
        return found;
    }

    function addToken(address _token) external {
        require(!isToken(_token), "VWAPcomponent: token already exists");
        tokenToWatchPrices.push(_token);
    }

    function removeToken(address _token) external onlyOwner {
        (bool found, uint256 index) = _getTokenIndex(_token);
        require(found, "No such token");
        for (uint256 i = index; i < tokenToWatchPrices.length;) {
            tokenToWatchPrices[i-1] = tokenToWatchPrices[i];
        }
        tokenToWatchPrices.pop();
    }

    function addTokenProxy(address _tokenAddr, address _proxyAddr) external {
        require(_tokenAddr != address(0), "Invalid token address");
        require(_proxyAddr != address(0), "Invalid proxy address");

        proxyAddresses[_tokenAddr] = _proxyAddr;
    }

    function _getLatestTokenPrice(AggregatorV3Interface tokenPriceFeed)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = tokenPriceFeed.latestRoundData();
        return uint256(price);
    }

    function getStoredTokenPrices(address token) external view override returns (uint256) {
        return storedTokenPrices[token];
    }

    function fetchTokenPrices() external override {
        for (uint256 i = 0; i < tokenToWatchPrices.length;) {
            address token = tokenToWatchPrices[i];
            if(proxyAddresses[token] == address(0)) continue;
    
            address proxy = proxyAddresses[token];
            AggregatorV3Interface tokenPriceFeed = AggregatorV3Interface(proxy);
            storedTokenPrices[token] = _getLatestTokenPrice(tokenPriceFeed);
            unchecked {
                ++i;
            }
        }
    }
}

// 0xcB1e72786A6eb3b44C2a2429e317c8a2462CFeb1 Dai
// 0x0000000000000000000000000000000000001010 Matic

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVwapOracle {
    function fetchTokenPrices() external;

    function getStoredTokenPrices(address token) external view returns (uint256);
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