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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);

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

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

contract BackedOracle is AggregatorV2V3Interface, Ownable {
  struct RoundData {
    int192 answer;
    uint32 timestamp;
  }

  uint8 private _decimals;
  string private _description;

  mapping(uint256 => RoundData) private _roundData;
  uint80 private _latestRoundNumber;

  constructor(uint8 decimals, string memory description) {
    _decimals = decimals;
    _description = description;
  }

  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  function description() external view override returns (string memory) {
    return _description;
  }

  function latestAnswer() external view override returns (int256) {
    return _roundData[_latestRoundNumber].answer;
  }

  function latestTimestamp() external view override returns (uint256) {
    return _roundData[_latestRoundNumber].timestamp;
  }

  function latestRound() external view override returns (uint256) {
    return _latestRoundNumber;
  }

  function getAnswer(uint256 roundId) external view override returns (int256) {
    return _roundData[roundId].answer;
  }

  function getTimestamp(uint256 roundId) external view override returns (uint256) {
    return _roundData[roundId].timestamp;
  }

  function updateAnswer(int192 newAnswer, uint32 newTimestamp, uint32 newRound) public onlyOwner {
    _roundData[newRound] = RoundData(newAnswer, newTimestamp);
    _latestRoundNumber = newRound;

    emit AnswerUpdated(newAnswer, newRound, newTimestamp);
    emit NewRound(newRound, msg.sender, newTimestamp);
  }

  function getRoundData(uint80 roundId) external view override returns (
    uint80,
    int256,
    uint256,
    uint256,
    uint80
  ) {
    require(_roundData[roundId].answer != 0, "No data present");

    return (roundId, _roundData[roundId].answer, _roundData[roundId].timestamp, _roundData[roundId].timestamp, roundId);
  }

  function latestRoundData() external view override returns (
    uint80,
    int256,
    uint256,
    uint256,
    uint80
  ) {
    require(_latestRoundNumber != 0, "No data present");

    return (uint80(_latestRoundNumber), _roundData[_latestRoundNumber].answer, _roundData[_latestRoundNumber].timestamp, _roundData[_latestRoundNumber].timestamp, uint80(_latestRoundNumber));
  }
}