// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Signal is Ownable {

    AggregatorV3Interface internal priceFeedEth;
    AggregatorV3Interface internal priceFeedMatic;
    AggregatorV3Interface internal priceFeedSol;
    AggregatorV3Interface internal priceFeedLuna;

    uint private p1 = 11;
    uint private p2 = 12;
    uint private pPrecision = 10;
    uint constant private maxPeriod = 21;
    uint private numberOfSamplingSinceLaunch = 0;

    uint8 private bullish = 1;
    uint8 private bearish = 0;

    uint public priceSampling = 5 minutes;
    uint public genesisSampling;

    enum CoinList {
        ETH,
        MATIC,
        SOL,
        LUNA
    }

    CoinList numberOfCoins = CoinList.LUNA;
    uint8 constant N_MAX = uint8(CoinList.LUNA);

    struct CoinPrice {
        uint timeStamp;
        uint priceUsd;
        uint signal;
    }

    mapping(CoinList => CoinPrice[maxPeriod + 1]) public coinHistory;
    mapping(CoinList => CoinPrice) public currentPrices;

    event NewPrice(uint ethPrice, uint maticPrice, uint solPrice, uint lunaPrice);

    constructor() {
        priceFeedEth = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);
        priceFeedMatic = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
        priceFeedSol = AggregatorV3Interface(0x10C8264C0935b3B9870013e057f330Ff3e9C56dC);
        priceFeedLuna = AggregatorV3Interface(0x1248573D9B62AC86a3ca02aBC6Abe6d403Cd1034);

        //take a week of margin before launching
        genesisSampling = block.timestamp + 1 weeks;
    }

    /**
     * Returns the latest price
     */
    function recordAndCompute() external {
        require(block.timestamp >= numberOfSamplingSinceLaunch * priceSampling + genesisSampling, "Too soon");

        _updateCurrentPrices();

        for (uint coin = 0; coin <= uint(numberOfCoins); coin++) {
            for (uint day = maxPeriod; day > 0; day--) {
                coinHistory[CoinList(coin)][day].priceUsd = coinHistory[CoinList(coin)][day - 1].priceUsd;
            }
            coinHistory[CoinList(coin)][0].priceUsd = currentPrices[CoinList(coin)].priceUsd;
        }

        emit NewPrice(currentPrices[CoinList.ETH].priceUsd
        , currentPrices[CoinList.MATIC].priceUsd
        , currentPrices[CoinList.SOL].priceUsd
        , currentPrices[CoinList.LUNA].priceUsd);

        numberOfSamplingSinceLaunch += 1;
    }

    function getExpos() external view returns (uint256, uint256, uint256, uint256) {
        uint256 sumOfSignals;
        uint256 expo = 0;
        uint8[] memory coinSignal = new uint8[](4);

        for (uint coin = 0; coin <= uint(numberOfCoins); coin++) {
            if (currentPrices[CoinList(coin)].priceUsd > (coinHistory[CoinList(coin)][14].priceUsd * p2 / pPrecision)
                && currentPrices[CoinList(coin)].priceUsd > (coinHistory[CoinList(coin)][maxPeriod].priceUsd * p1 / pPrecision))
            {
                coinSignal[uint8(CoinList(coin))] = bullish;
            } else {
                coinSignal[uint8(CoinList(coin))] = bearish;
            }
            sumOfSignals = sumOfSignals + coinSignal[uint8(CoinList(coin))];
        }

        if (sumOfSignals > N_MAX) {
            expo = 100 / sumOfSignals;
        } else if (sumOfSignals > 0) {
            expo = 100 / N_MAX;
        } else {
            expo = 0;
        }

        return (expo * coinSignal[uint8(CoinList.ETH)]
        , expo * coinSignal[uint8(CoinList.MATIC)]
        , expo * coinSignal[uint8(CoinList.SOL)]
        , expo * coinSignal[uint8(CoinList.LUNA)]);
    }

    function _updateCurrentPrices() private {
        (uint priceEth, uint priceMatic, uint priceSol, uint priceLuna) = _getCurrentPrices();
        currentPrices[CoinList.ETH].priceUsd = priceEth;
        currentPrices[CoinList.SOL].priceUsd = priceSol;
        currentPrices[CoinList.MATIC].priceUsd = priceMatic;
        currentPrices[CoinList.LUNA].priceUsd = priceLuna;
    }

    function _getCurrentPrices() private view returns (uint priceEth, uint priceMatic, uint priceSol, uint priceLuna) {
        (int ethusd,) = getPriceFromChainlink(priceFeedEth);
        (int maticusd,) = getPriceFromChainlink(priceFeedMatic);
        (int solusd,) = getPriceFromChainlink(priceFeedSol);
        (int lunausd,) = getPriceFromChainlink(priceFeedLuna);

        return (uint(ethusd), uint(maticusd), uint(solusd), uint(lunausd));
    }

    function getPriceFromChainlink(AggregatorV3Interface aggregator) private view returns (int, uint) {
        (
        /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        uint timeStamp,
        /*uint80 answeredInRound*/
        ) = aggregator.latestRoundData();

        return (price, timeStamp);
    }

    function getPriceAtDayOfWeek(CoinList coin, uint day) external view returns (uint) {
        return coinHistory[coin][day].priceUsd;
    }

    function setGenesisSampling(uint256 _newGenesisSampling) external {
        genesisSampling = _newGenesisSampling;
    }

    function setSampling(uint _newSampling) external {
        priceSampling = _newSampling;
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