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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IPriceConverter {
    function getConversionRate(uint256 ETHAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IRandomNumberGenerator {
    function getRandomNumber(uint256 _requestId) external view returns (uint256);

    function requestRandomWords() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPriceConverter.sol";
import "./IRandomNumberGenerator.sol";

error Lottery__NotEntranceFee();
error Lottery__RandomNumberNotExists();
error Lottery__TransferFailed();
error Lottery__NotRightTime();
error Lottery__Closed();
error Lottery__Open();
error Lottery__NotEnoughParticipant();

contract Lottery is Ownable {
    uint256 private immutable entranceFee;
    uint256 private immutable interval;
    uint256 private latestCheckpoint;
    uint256 private playerCounter;
    uint256 private requestId;
    address payable private recentWinner;
    bool private isOpen = true;

    mapping(uint256 => address payable) private players;

    IPriceConverter public priceConverter;
    IRandomNumberGenerator public randomNumberGenerator;

    event LotteryEntered(address indexed player);
    event WinnerRequested(uint256 indexed requestId);
    event WinnerPicked(address indexed recentWinner);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _randomNumberGenerator,
        address _priceConverter
    ) {
        entranceFee = _entranceFee;
        interval = _interval;
        randomNumberGenerator = IRandomNumberGenerator(_randomNumberGenerator);
        priceConverter = IPriceConverter(_priceConverter);
        latestCheckpoint = block.timestamp;
    }

    function enterLottery() public payable {
        if (!isOpen) {
            revert Lottery__Closed();
        }
        if (priceConverter.getConversionRate(msg.value) != entranceFee) {
            revert Lottery__NotEntranceFee();
        }
        players[playerCounter] = payable(msg.sender);
        playerCounter++;
        emit LotteryEntered(msg.sender);
    }

    function requestRandomWinner() public {
        if (!isOpen) {
            revert Lottery__Closed();
        }
        if (playerCounter < 2) {
            revert Lottery__NotEnoughParticipant();
        }
        if (block.timestamp - latestCheckpoint < interval * 10) {
            revert Lottery__NotRightTime();
        }
        isOpen = false;
        latestCheckpoint = block.timestamp;
        requestId = randomNumberGenerator.requestRandomWords();
        emit WinnerRequested(requestId);
    }

    function pickRandomWinner() public {
        if (isOpen) {
            revert Lottery__Open();
        }
        if (getRandomNumber() == 0) {
            revert Lottery__RandomNumberNotExists();
        }
        if (block.timestamp - latestCheckpoint < interval) {
            revert Lottery__NotRightTime();
        }
        uint256 randomNumber = getRandomNumber();
        uint256 playerId = randomNumber % (playerCounter - 1);
        recentWinner = players[playerId];
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        latestCheckpoint = block.timestamp;
        for (uint i = 0; i < playerCounter; i++) {
            delete players[playerId];
        }
        playerCounter = 0;
        isOpen = true;
        emit WinnerPicked(recentWinner);
    }

    function getRandomNumber() public view returns (uint256) {
        return randomNumberGenerator.getRandomNumber(requestId);
    }

    function getRequestId() public view returns (uint256) {
        return requestId;
    }

    function getEntranceFee() public view returns (uint256) {
        return entranceFee;
    }

    function getInterval() public view returns (uint256) {
        return interval;
    }

    function getLatestCheckpoint() public view returns (uint256) {
        return latestCheckpoint;
    }

    function getRecentWinner() public view returns (address) {
        return recentWinner;
    }

    function getPlayerCounter() public view returns (uint256) {
        return playerCounter;
    }

    function getPlayer(uint256 _id) public view returns (address) {
        return players[_id];
    }

    function getState() public view returns (bool) {
        return isOpen;
    }
}