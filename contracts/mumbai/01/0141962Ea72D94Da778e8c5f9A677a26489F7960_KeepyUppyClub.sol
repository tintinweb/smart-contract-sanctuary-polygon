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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/IREDDIES.sol";
import "../interfaces/IBootcampPlayer.sol";

struct GameTime {
  uint128 start;
  uint128 end;
}

// @notice abstract scaffolding for bootcamp challenges
abstract contract Game is Ownable, Pausable {

  // @dev track the other important contracts
  IREDDIES public reddies;
  IBootcampPlayer public bootcampPlayer;

  // @notice the start and end times of the game
  GameTime public gameTime;

  // @notice emitted when the game time is set
  event Scheduled(uint256 start, uint256 end);

  // @notice mapping of "helper" contracts who can bypass the contract check
  mapping(address => bool) public helpers;
  
  constructor(address _bootcampPlayer, address _reddies) {
      reddies = IREDDIES(_reddies);
      bootcampPlayer = IBootcampPlayer(_bootcampPlayer);
      _pause();
  }

  /**
  * @dev identifies whether a token has participated in the RiskyGame
  * @param tokenId the tokenId to check
  */
  function played(uint256 tokenId) public view virtual returns(bool);

  /**
  * @dev enables owner to pause / unpause minting
  * @param _bPaused the flag to pause or unpause
  */
  function setPaused(bool _bPaused) external onlyOwner {
      if (_bPaused) _pause();
      else _unpause();
  }

  // @notice set the start and end time of the game
  function setGameTime(GameTime calldata _gameTime) public onlyOwner {
    gameTime = _gameTime;
    emit Scheduled(_gameTime.start, _gameTime.end);
  }

  // @notice set the start and end time of the game
  function setHelper(address _helper, bool status) public onlyOwner {
    helpers[_helper] = status;
  }

  // @notice ensure an action is mid-game
  modifier duringGame() {
    require(block.timestamp >= gameTime.start && block.timestamp <= gameTime.end, "Game: inactive");
    _;
  }

  // @notice ensure an action is not from a smart contract, outside a 
  modifier originCheck() {
    require(msg.sender == tx.origin || helpers[msg.sender], "Game: cannot play from contract");
    _;
  }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./RiskyGame.sol";

contract KeepyUppyClub is RiskyGame {

  using Queue for Queue.PlayQueue;

  uint256 public rounds = 3;

  struct TokenStatus {
    uint8 rounds;
    bool pending;
    bool disqualified;
  }

  mapping(uint256 => TokenStatus) public tokenStatuses;
  
  constructor(address _bootcampPlayer, address _reddies, address _oracle)
    RiskyGame(_bootcampPlayer, _reddies, _oracle) {
    setConfiguration(Configuration(
    {
        baseRate: 29491,
        riskyReward: 50 ether,
        safeReward: 30 ether
    }
    ));
  }

  function traitBoost(uint256 tokenId) public view override returns (uint32 boost) {
      Metadata memory metadata = bootcampPlayer.getPlayerMetadata(tokenId);
      boost += block.timestamp % 3600 < 1800 ? 4916 : 0;
      boost += (metadata.skillLevel == 2 || metadata.quirks == 24 || metadata.quirks == 21 || metadata.quirks == 22) ? 40000 : 0;
  }

  function attributeBoost(uint256 tokenId) public view override returns (uint32) {
      Stats memory stats = bootcampPlayer.getPlayerStats(tokenId);
      return uint32(uint256(stats.creativity) * 1639);
  }

  // @notice play a given token - checks ownership & customisation, and marks as played
  function _play(uint256 tokenId, bool risky) internal override {
    require(bootcampPlayer.ownerOf(tokenId) == msg.sender, "Not your token");
    require(bootcampPlayer.hasStats(tokenId), "Not game-ready");

    TokenStatus storage tokenStatus = tokenStatuses[tokenId];
    require(tokenStatus.rounds < rounds, "Already played");
    require(tokenStatus.disqualified == false, "Dropped the ball!");
    require(tokenStatus.pending == false, "Result pending");
    tokenStatus.rounds += 1;

    if(risky) {
      tokenStatus.pending = true;
    }
  }

  function played(uint256 tokenId) public view override returns(bool) {
    TokenStatus storage tokenStatus = tokenStatuses[tokenId];
    return tokenStatus.rounds > 0;
  }

  // @notice reveal a given risky play
  function _reveal(Queue.Play memory play) internal override {

    TokenStatus storage tokenStatus = tokenStatuses[play.tokenId];
    tokenStatus.pending = false;
    (uint256 reward, uint16 roll) = _getReward(play);
    if (reward > 0) {
      reddies.mint(play.holder, reward);
    } else {
      tokenStatus.disqualified = true;
    }
    queue.removeFront();
    emit Revealed(play.tokenId, roll, reward);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev forked from the OpenZeppelin Deque, this is a FIFO for Risky Game plays
 */
library Queue {
    
    struct Play {
        address holder;
        uint32 blockNumber;
        uint16 tokenId;
        uint32 odds;
        }

    struct PlayQueue {
        int128 _begin;
        int128 _end;
        mapping(int128 => Play) _data;
        }

    function pushBack(PlayQueue storage deque, Play memory value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    function front(PlayQueue storage deque) internal view returns (Play memory value) {
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    function removeFront(PlayQueue storage deque) internal {
        int128 frontIndex = deque._begin;
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./PlayQueue.sol";
import "./Game.sol";

interface IOracle {
  function getSeed() external returns (uint256);
}

// @notice abstract scaffolding for Simple Risky Games
abstract contract RiskyGame is Game {

  using BitMaps for BitMaps.BitMap;
  using Queue for Queue.PlayQueue;

  // @notice bitmap tracking whether players have participated in the challenge
  BitMaps.BitMap internal _played;

  // @notice events tracking game events
  event PlayedItSafe(address indexed holder, uint16[] tokenIds, uint256 reward);
  event TookARisk(address indexed holder, uint16[] tokenIds);
  event Revealed(uint16 tokenId, uint16 roll, uint256 reward);
  event Configured(Configuration config);

  // @notice configuration for the risky game
  struct Configuration {
    uint32 baseRate;
    uint256 riskyReward;
    uint256 safeReward;
  }

  Queue.PlayQueue public queue;

  Configuration public config;
  IOracle public offchainOracle;

  // @notice how long the keeper has to wait to reveal
  uint256 public keeperDelay;
  // @notice number of altruistic reveals by follow-on players
  uint256 public revealAmount = 1;
  
  constructor(address _bootcampPlayer, address _reddies, address _offchainOracle)
    Game(_bootcampPlayer, _reddies) {
    setOffchainOracle(_offchainOracle);
  }

  // @notice owner only function to update the config
  function setConfiguration(Configuration memory _config) public virtual onlyOwner {
    config = _config;
    emit Configured(config);
  }

  // @notice owner only function to update the offchain oracle
  function setOffchainOracle(address _offchainOracle) public virtual onlyOwner {
    offchainOracle = IOracle(_offchainOracle);
  }

  // @notice owner only function to update keeper delay
  function setKeeperDelay(uint256 _keeperDelay) public virtual onlyOwner {
    keeperDelay = _keeperDelay;
  }

  // @notice owner only function to update reveal amount
  function setRevealAmount(uint256 _revealAmount) public virtual onlyOwner {
    revealAmount = _revealAmount;
  }

  // @notice function to allow sending funds to the contract
  function topUp() external payable {
  }

  // @notice owner only function to withdraw the contract balance
  function withdraw() public onlyOwner {
    (bool sent, ) = owner().call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  // @notice virtual functions to get trait and attribute boosts for a given token
  function traitBoost(uint256 tokenId) public view virtual returns (uint32);
  function attributeBoost(uint256 tokenId) public view virtual returns (uint32);

  // Get reward for `tokenId` with random seed `seed`. Returns reward in wei.
  function _getReward(Queue.Play memory play) internal virtual returns (uint256 reward, uint16 roll) {
    uint256 seed = _seed(play.blockNumber);
    roll = uint16(uint256(keccak256(abi.encode(seed, play.tokenId))));
    reward = play.odds >= roll ? config.riskyReward : 0; 
  }

  // @notice gets a random seed based on a blok number and an offchain oracle
  function _seed(uint256 commitBlock) internal virtual returns (uint256) {
    uint256 offset = (block.number - commitBlock) % 256;
    if (offset == 0) {
      offset++;
    }
    return uint256(blockhash(block.number - offset)) ^ offchainOracle.getSeed();
  }

  // @notice view function to get the odds for a given token
  function tokenOdds(uint256 tokenId) public view virtual returns (uint32 odds) {
    odds = config.baseRate;
    odds += traitBoost(tokenId);
    odds += attributeBoost(tokenId);
  }

  // @notice play a given token - checks ownership & customisation, and marks as played
  function _play(uint256 tokenId, bool risky) internal virtual {
  }

  function played(uint256 tokenId) public view override virtual returns(bool) {
    return _played.get(tokenId);
  }
  
  // @notice playSafe with an array of tokens for a set reward
  function playSafe(uint16[] calldata tokenIds) public virtual duringGame whenNotPaused{
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _play(tokenIds[i], false);
    }
    uint256 payoff = config.safeReward * uint256(tokenIds.length);
    reddies.mint(msg.sender, payoff);

    emit PlayedItSafe(msg.sender, tokenIds, payoff);
  }

  // @notice helper max function
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  // @notice reveal a given risky play
  function _reveal(Queue.Play memory play) internal virtual {
    (uint256 reward, uint16 roll) = _getReward(play);
    if (reward > 0) {
      reddies.mint(play.holder, reward);
    }
    queue.removeFront();
    emit Revealed(play.tokenId, roll, reward);
  }

  // @notice reveal as many as possible up to an amount
  function _revealMany(uint256 amount) internal virtual {

    Queue.Play memory play = queue.front();
    uint256 i = 0;
    
    while (i < amount && block.number > play.blockNumber && play.blockNumber > 0) {
      _reveal(play);
      play = queue.front();
      i++;
    }
  }

  // @notice keeper function to reveal as many as possible up to a specified amount, after a given delay
  function keeperReveal(uint amount) public virtual originCheck whenNotPaused {
    Queue.Play memory play = queue.front();
    require(play.blockNumber > 0 && block.number - uint256(play.blockNumber) >= keeperDelay, "Not ready");
    
    _revealMany(amount);
  }

  // @notice riskyPlay with an array of tokens, then reveal any that are left in the queue
  function playRisky(uint16[] calldata tokenIds) public virtual duringGame originCheck whenNotPaused {

    uint256 i;
    for (i = 0; i < tokenIds.length; i++) {
      uint16 tokenId = tokenIds[i];
      _play(tokenId, true);
      queue.pushBack(Queue.Play(msg.sender, uint32(block.number), tokenId, tokenOdds(tokenId)));
    }

    _revealMany(max(revealAmount, tokenIds.length));
    
    emit TookARisk(msg.sender, tokenIds);
  }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../types/BootcampTypes.sol";

interface IBootcampPlayer is IERC721 {

    /**
     * @dev returns the player stats
     */
    function getPlayerStats(uint256 tokenId)
        external
        view
        returns (Stats memory);

    /**
     * @dev returns the player stats
     */
    function getBatchPlayerStats(uint32[] calldata tokenIds)
        external
        view
        returns (Stats[] memory stats);

    /**
     * @dev returns the player stats
     */
    function getPlayerMetadata(uint256 tokenId)
        external
        view
        returns (Metadata memory);

    /**
     * @dev returns the player stats
     */
    function getBatchPlayerMetadata(uint32[] calldata tokenIds)
        external
        view
        returns (Metadata[] memory stats);

    /**
     * @dev returns the player stats
     */
    function hasStats(uint256 tokenId)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IREDDIES {
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
     * mints $REDDIES to a recipient
     * @param to the recipient of the $REDDIES
     * @param amount the amount of $REDDIES to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * burns $REDDIES from a holder
     * @param from the holder of the $REDDIES
     * @param amount the amount of $REDDIES to burn
     */
    function burn(address from, uint256 amount) external;
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

struct Metadata {
    uint16 playerType;
    uint16 skillLevel;
    uint16 quirks;
    bool pet;
}

struct Stats {
    uint8 passing;
    uint8 finishing;
    uint8 tackling;
    uint8 teamwork;
    uint8 creativity;
    uint8 pace;
    uint8 strength;
    uint8 kit;
    uint8 boots;
}