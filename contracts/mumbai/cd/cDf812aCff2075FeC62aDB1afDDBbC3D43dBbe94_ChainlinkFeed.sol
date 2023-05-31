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
pragma solidity 0.8.10;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAggregatorFeed {
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

    function getRoundData(
        uint256 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function pairName() external view returns (string memory);

    function getAnswer(uint256 _roundId) external view returns (int192);
}

contract AggregatorFeed is Ownable, IAggregatorFeed {
    using Counters for Counters.Counter;
    int256 public fakeAnswer = 100_000 * 1e10;
    Counters.Counter public latestAggregatorRoundId;
    mapping(address => bool) public verifiers;
    mapping(address => bool) public whitelistCallers;
    string public pairName;

    struct Transmission {
        int192 answer; // 192 bits ought to be enough for anyone
        uint256 timestamp;
    }

    //RoundId -> Transmission
    mapping(uint256 => Transmission) internal transmissions;

    constructor(string memory _pairName) {
        if (bytes(_pairName).length > 0) {
            pairName = _pairName;
        }
    }

    modifier onlyVerifier() {
        require(verifiers[msg.sender], "PERMISSION_DENIED");
        _;
    }

    modifier onlyWhitelist() {
        require(whitelistCallers[msg.sender], "NOT_WHITELIST");
        _;
    }

    function latestRoundData()
        public
        view
        override
        onlyWhitelist
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            uint80(latestAggregatorRoundId.current()),
            transmissions[latestAggregatorRoundId.current()].answer,
            transmissions[latestAggregatorRoundId.current()].timestamp,
            transmissions[latestAggregatorRoundId.current()].timestamp,
            uint80(latestAggregatorRoundId.current())
        );
    }

    function getAnswer(uint256 _roundId) external view returns (int192) {
        return transmissions[_roundId].answer;
    }

    function getRoundData(
        uint256 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        Transmission memory transmission = transmissions[_roundId];
        return (
            uint80(_roundId),
            transmission.answer,
            transmission.timestamp,
            transmission.timestamp,
            uint80(_roundId)
        );
    }

    function updateAnswer(int192 _answer) external onlyVerifier {
        latestAggregatorRoundId.increment();
        transmissions[latestAggregatorRoundId.current()].answer = _answer;
        transmissions[latestAggregatorRoundId.current()].timestamp = block
            .timestamp;
    }

    function addVerifier(address verifier, bool status) external onlyOwner {
        verifiers[verifier] = status;
    }

    function addWhitelist(address whitelist, bool status) external onlyOwner {
        whitelistCallers[whitelist] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AggregatorFeed.sol";

contract ChainlinkFeed is Ownable {
    IAggregatorFeed private _aggFeed;
    int256 public _fakeAnswer;

    constructor() {}

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        if (address(_aggFeed) == address(0)) {
            return (0, _fakeAnswer, 0, 0, 0);
        }
        (roundId, answer, startedAt, updatedAt, answeredInRound) = _aggFeed
            .latestRoundData();
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    function setAggregator(IAggregatorFeed aggFeed) external onlyOwner {
        _aggFeed = aggFeed;
    }

    function pairName() external view returns (string memory) {
        return _aggFeed.pairName();
    }

    function getAggregator() external view onlyOwner returns (address) {
        return address(_aggFeed);
    }

    function setAnswer(int256 answer) external onlyOwner {
        _fakeAnswer = answer;
    }
}