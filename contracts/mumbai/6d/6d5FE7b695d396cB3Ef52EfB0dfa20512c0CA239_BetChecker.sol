// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/BetCheckerInterface.sol";

contract BetChecker is BetCheckerInterface, Ownable {
    uint80 constant SECONDS_PER_DAY = 3600 * 24;

    mapping(string => address) internal _feedAddresses;

    constructor(string[] memory feedSymbols, address[] memory feedAddresses) {
        require(
            feedSymbols.length == feedAddresses.length,
            "lenghs of input arrays must be the same"
        );
        for (uint i = 0; i < feedSymbols.length; i++) {
            _feedAddresses[feedSymbols[i]] = feedAddresses[i];
        }
    }

    function setFeedAddress(string memory feedSymbol, address feedAddress)
        public
        onlyOwner
    {
        _feedAddresses[feedSymbol] = feedAddress;
    }

    function getFeedAddress(string memory feedSymbol)
        external
        view
        returns (address)
    {
        return _feedAddresses[feedSymbol];
    }

    function getPhaseForTimestamp(
        AggregatorV2V3Interface feed,
        uint256 targetTime
    )
        public
        view
        returns (
            uint80,
            uint256,
            uint80
        )
    {
        uint16 currentPhase = uint16(feed.latestRound() >> 64);
        uint80 firstRoundOfCurrentPhase = (uint80(currentPhase) << 64) + 1;

        for (uint16 phase = currentPhase; phase >= 1; phase--) {
            uint80 firstRoundOfPhase = (uint80(phase) << 64) + 1;
            uint256 firstTimeOfPhase = feed.getTimestamp(firstRoundOfPhase);

            if (targetTime > firstTimeOfPhase) {
                return (
                    firstRoundOfPhase,
                    firstTimeOfPhase,
                    firstRoundOfCurrentPhase
                );
            }
        }
        return (0, 0, firstRoundOfCurrentPhase);
    }

    function guessSearchRoundsForTimestamp(
        AggregatorV2V3Interface feed,
        uint256 fromTime,
        uint80 daysToFetch
    )
        public
        view
        returns (uint80 firstRoundToSearch, uint80 numRoundsToSearch)
    {
        uint256 toTime = fromTime + SECONDS_PER_DAY * daysToFetch;

        (
            uint80 lhRound,
            uint256 lhTime,
            uint80 firstRoundOfCurrentPhase
        ) = getPhaseForTimestamp(feed, fromTime);

        uint80 rhRound;
        uint256 rhTime;
        if (lhRound == 0) {
            // Date is too far in the past, no data available
            return (0, 0);
        } else if (lhRound == firstRoundOfCurrentPhase) {
            (rhRound, , rhTime, , ) = feed.latestRoundData();
        } else {
            // No good way to get last round of phase from Chainlink feed, so our binary search function will have to use trial & error.
            // Use 2**16 == 65536 as a upper bound on the number of rounds to search in a single Chainlink phase.

            rhRound = lhRound + 2**16;
            rhTime = 0;
        }

        uint80 fromRound = binarySearchForTimestamp(
            feed,
            fromTime,
            lhRound,
            lhTime,
            rhRound,
            rhTime
        );
        uint80 toRound = binarySearchForTimestamp(
            feed,
            toTime,
            fromRound,
            fromTime,
            rhRound,
            rhTime
        );
        return (fromRound, toRound - fromRound);
    }

    function binarySearchForTimestamp(
        AggregatorV2V3Interface feed,
        uint256 targetTime,
        uint80 lhRound,
        uint256 lhTime,
        uint80 rhRound,
        uint256 rhTime
    ) public view returns (uint80 targetRound) {
        if (lhTime > targetTime) return 0;

        uint80 guessRound = rhRound;
        while (rhRound - lhRound > 1) {
            guessRound = uint80(int80(lhRound) + int80(rhRound - lhRound) / 2);
            uint256 guessTime = feed.getTimestamp(uint256(guessRound));
            if (guessTime == 0 || guessTime > targetTime) {
                (rhRound, rhTime) = (guessRound, guessTime);
            } else if (guessTime < targetTime) {
                (lhRound, lhTime) = (guessRound, guessTime);
            }
        }
        return guessRound;
    }

    function roundIdsToSearch(
        AggregatorV2V3Interface feed,
        uint256 fromTimestamp,
        uint80 daysToFetch,
        uint dataPointsToFetchPerDay
    ) public view returns (uint80[] memory) {
        (
            uint80 startingId,
            uint80 numRoundsToSearch
        ) = guessSearchRoundsForTimestamp(feed, fromTimestamp, daysToFetch);

        uint80 fetchFilter = uint80(
            numRoundsToSearch / (daysToFetch * dataPointsToFetchPerDay)
        );
        if (fetchFilter < 1) {
            fetchFilter = 1;
        }
        uint80[] memory roundIds = new uint80[](
            numRoundsToSearch / fetchFilter
        );

        // Snap startingId to a round that is a multiple of fetchFilter. This prevents the perpetual jam from changing more often than
        // necessary, and keeps it aligned with the daily prints.
        startingId -= startingId % fetchFilter;

        for (uint80 i = 0; i < roundIds.length; i++) {
            roundIds[i] = startingId + i * fetchFilter;
        }
        return roundIds;
    }

    function fetchPriceData(
        AggregatorV2V3Interface feed,
        uint256 fromTimestamp,
        uint80 daysToFetch,
        uint dataPointsToFetchPerDay
    ) public view returns (int[] memory) {
        uint80[] memory roundIds = roundIdsToSearch(
            feed,
            fromTimestamp,
            daysToFetch,
            dataPointsToFetchPerDay
        );
        uint dataPointsToReturn;
        if (roundIds.length == 0) {
            dataPointsToReturn = 0;
        } else {
            dataPointsToReturn = dataPointsToFetchPerDay * daysToFetch; // Number of data points to return
        }
        uint secondsBetweenDataPoints = SECONDS_PER_DAY /
            dataPointsToFetchPerDay;

        int[] memory prices = new int[](dataPointsToReturn);

        uint80 latestRoundId = uint80(feed.latestRound());
        for (uint80 i = 0; i < roundIds.length; i++) {
            if (roundIds[i] != 0 && roundIds[i] < latestRoundId) {
                (, int price, uint timestamp, , ) = feed.getRoundData(
                    roundIds[i]
                );

                if (timestamp >= fromTimestamp) {
                    uint segmentsSinceStart = (timestamp - fromTimestamp) /
                        secondsBetweenDataPoints;
                    if (segmentsSinceStart < prices.length) {
                        prices[segmentsSinceStart] = price;
                    }
                }
            }
        }

        return prices;
    }

    function fetchPriceDataForFeed(
        address feedAddress,
        uint fromTimestamp,
        uint80 daysToFetch,
        uint dataPointsToFetchPerDay
    ) public view returns (int[] memory) {
        AggregatorV2V3Interface feed = AggregatorV2V3Interface(feedAddress);

        require(fromTimestamp > 0);

        int256[] memory prices = fetchPriceData(
            feed,
            fromTimestamp,
            daysToFetch,
            dataPointsToFetchPerDay
        );
        return prices;
    }

    function getMinMaxPrices(address feedAddress, uint dayStartTimestamp)
        public
        view
        returns (int, int)
    {
        // Init params
        uint80 daysToFetch = 1;
        uint dataPointsToFetchPerDay = 256;
        // Load day prices
        int[] memory prices = fetchPriceDataForFeed(
            feedAddress,
            dayStartTimestamp,
            daysToFetch,
            dataPointsToFetchPerDay
        );
        // Fin min and max prices
        int minPrice = 2**255 - 1;
        int maxPrice = 0;
        for (uint80 i = 0; i < prices.length; i++) {
            int price = prices[i];
            if (price != 0 && price < minPrice) {
                minPrice = price;
            }
            if (price != 0 && price > maxPrice) {
                maxPrice = price;
            }
        }
        // Return
        return (minPrice, maxPrice);
    }

    // TODO: Check that day has passed
    function isPriceExist(
        string memory symbol,
        uint dayStartTimestamp,
        int minPrice,
        int maxPrice
    )
        external
        view
        returns (
            bool,
            int,
            int
        )
    {
        // Check input data
        require(minPrice <= maxPrice, "min price is higher than max price");
        require(
            _feedAddresses[symbol] != address(0),
            "feed for symbol is not found"
        );
        // Get day min and max prices
        (int dayMinPrice, int dayMaxPrice) = getMinMaxPrices(
            _feedAddresses[symbol],
            dayStartTimestamp
        );
        // Compare input prices with day prices
        bool result = false;
        int fixedMinPrice = minPrice * 10**8;
        int fixedMaxPrice = maxPrice * 10**8;
        if (fixedMinPrice <= dayMinPrice && fixedMaxPrice >= dayMinPrice) {
            result = true;
        }
        if (fixedMinPrice >= dayMinPrice && fixedMaxPrice <= dayMaxPrice) {
            result = true;
        }
        if (fixedMinPrice <= dayMaxPrice && fixedMaxPrice >= dayMaxPrice) {
            result = true;
        }
        // Return
        return (result, dayMinPrice, dayMaxPrice);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface BetCheckerInterface {
    function isPriceExist(
        string memory symbol,
        uint dayStartTimestamp,
        int minPrice,
        int maxPrice
    )
        external
        view
        returns (
            bool,
            int,
            int
        );

    function getFeedAddress(string memory feedSymbol)
        external
        view
        returns (address);
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
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

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
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

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