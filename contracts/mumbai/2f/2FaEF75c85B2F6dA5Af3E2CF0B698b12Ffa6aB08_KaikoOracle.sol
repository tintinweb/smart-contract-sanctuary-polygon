// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error NoDataPresent();

contract KaikoOracle is Ownable, AggregatorV3Interface {
    uint256 constant public override version = 0;

    event NewRound(uint256 indexed roundId, uint256 updatedAt);

    // list of addresses that are whitelisted
    mapping(address => bool) whitelistedAddresses;

    uint8 public override decimals;
   
    uint80 private _currentRoundId;
    
    struct Entry {
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    mapping(uint80 => Entry) private _entries;

    constructor(uint8 _decimals) Ownable() {
        decimals = _decimals;
        toggleWhitelist(msg.sender);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        address oldOwner = owner();
        super.transferOwnership(newOwner);
        // need to do it manually since the newOwner is not the msg sender anymore
        whitelistedAddresses[newOwner] = true;
        whitelistedAddresses[oldOwner] = false;
    }

    // allow the addition of a user to the whitelist
    function toggleWhitelist(address _addressToWhitelist) public onlyOwner {
       whitelistedAddresses[_addressToWhitelist] =! whitelistedAddresses[_addressToWhitelist];
    } 

    function isWhitelisted(address _addressToCheck) public view returns (bool) {
        return whitelistedAddresses[_addressToCheck];
    }

    // modifier that will only allow whitelisted address
    modifier onlyWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "The address should be whitelisted");
        _;
    }

    function getRoundId() external view onlyWhitelisted(msg.sender) returns (uint256) {
        return _currentRoundId;
    }

    // to change for the blocktimestamp
    function addNewAnswer(int256 answer) public onlyOwner {
        unchecked {++_currentRoundId;}
        _entries[_currentRoundId] = Entry({
            answer: answer,
            startedAt: block.timestamp,
            updatedAt: block.timestamp,
            answeredInRound: _currentRoundId
        });
        
        emit NewRound(_currentRoundId, block.timestamp);
    }

    function getRoundData(uint80 _roundId) public view onlyWhitelisted(msg.sender) override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        Entry memory entry = _entries[_roundId];
        if(entry.updatedAt == 0) revert NoDataPresent();
        return (_roundId, entry.answer, entry.startedAt, entry.updatedAt, entry.answeredInRound);
    }

    function latestRoundData() public view onlyWhitelisted(msg.sender) override
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return getRoundData(_currentRoundId);
    }

    function description() external pure returns (string memory) {
        return "v0/KaikoOracle.sol";
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