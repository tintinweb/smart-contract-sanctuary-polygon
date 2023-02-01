// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LibertiPriceFeed is Ownable {
    error AssetNotSupportedError();
    error FeedAlreadyExistsError();
    error NegativePriceError();
    error StalePriceError();

    mapping(address => address) public feeds;

    constructor() {
        // Ethereum
        if (1 == block.chainid) {
            feeds[
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
            ] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETHUSD
            feeds[
                0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
            ] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c; // BTCUSD
            feeds[
                0xdAC17F958D2ee523a2206206994597C13D831ec7
            ] = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D; // USDTUSD
        }

        // Binance Smart Chain
        if (56 == block.chainid) {
            feeds[
                0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c // Wrapped BNB
            ] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; // BNBUSD
            feeds[
                0x55d398326f99059fF775485246999027B3197955 // Tether USD, Binance-Peg BSC-USD
            ] = 0xB97Ad0E74fa7d920791E90258A6E2085088b4320; // BUSDUSD
        }

        // Polygon
        if (137 == block.chainid) {
            feeds[
                0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
            ] = 0xF9680D99D6C9589e2a93a78A04A279e509205945; // ETHUSD
            feeds[
                0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6
            ] = 0xc907E116054Ad103354f2D350FD2514433D57F6f; // BTCUSD
            feeds[
                0xc2132D05D31c914a87C6611C10748AEb04B58e8F
            ] = 0x0A6513e40db6EB1b165753AD52E80663aeA50545; // USDTUSD
            feeds[
                0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
            ] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0; // MATICUSD
            feeds[
                0xA1c57f48F0Deb89f569dFbE6E2B7f46D33606fD4
            ] = 0xA1CbF3Fe43BC3501e3Fc4b573e822c70e76A7512; // MANAUSD
        }
    }

    function addPriceFeed(address tokenAddr, address feedAddr) external onlyOwner {
        if (address(0) != feeds[tokenAddr]) {
            revert FeedAlreadyExistsError();
        }
        feeds[tokenAddr] = feedAddr;
    }

    function getPrice(address token) external view returns (uint256) {
        address feed = feeds[token];
        if (address(0) == feed) {
            revert AssetNotSupportedError();
        }
        (
            uint80 roundID,
            int256 answer,
            ,
            uint256 updatedAt, // updatedAt data feed property is the timestamp of an answered round
            uint80 answeredInRound // answeredInRound is the round it was updated in
        ) = AggregatorV3Interface(feed).latestRoundData();
        if (0 >= updatedAt) {
            // A timestamp with zero value means the round is not complete and should not be used.
            revert StalePriceError();
        }
        if (0 >= answer) {
            revert NegativePriceError();
        }
        if (answeredInRound < roundID) {
            // If answeredInRound is less than roundId, the answer is being carried over. If
            // answeredInRound is equal to roundId, then the answer is fresh.
            revert StalePriceError();
        }
        return uint256(answer);
    }
}