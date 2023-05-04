// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IPost.sol";

// This is an example of a type of post contract
// where the owner can decide how to moderate the replies
contract Post is Ownable, ERC165 {
  string public subject;
  string public message;

  mapping(address => int32) public replyStatus;
  address[] public replies;
  int32 public visibilityThreshold;

  event ReplyAdded(address indexed item, uint256 indexed replyIndex);
  event ReplyStatusUpdated(address indexed item, int32 oldStatus, int32 newStatus);
  event VisibilityThresholdUpdated(int32 oldThreshold, int32 newThreshold);

  constructor(string memory _subject, string memory _message, address _owner) {
    subject = _subject;
    message = _message;
    _transferOwnership(_owner);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IPost).interfaceId || super.supportsInterface(interfaceId);
  }

  // Automod -- Require coinpassport verification?
  function addReply(IPost reply) external {
    require(bytes(reply.subject()).length > 5);
    require(bytes(reply.message()).length > 5);
    emit ReplyAdded(address(reply), replies.length);
    replies.push(address(reply));
  }

  function replyCount() external view returns(uint256) {
    return replies.length;
  }

  struct ReplyStatus {
    address item;
    int32 status;
  }

  function setReplyStatus(
    ReplyStatus[] memory newStatus,
    int32 newThreshold
  ) external onlyOwner {
    if(newStatus.length > 0) {
      for(uint256 i = 0; i < newStatus.length; i++) {
        emit ReplyStatusUpdated(newStatus[i].item, replyStatus[newStatus[i].item], newStatus[i].status);
        replyStatus[newStatus[i].item] = newStatus[i].status;
      }
    }

    if(visibilityThreshold != newThreshold) {
      emit VisibilityThresholdUpdated(visibilityThreshold, newThreshold);
      visibilityThreshold = newThreshold;
    }
  }

  struct RepliesResponse {
    address[] items;
    uint totalCount;
    uint lastScanned;
  }

  // Sorting must happen on the client
  function fetchReplies(
    int32 minStatus,
    uint startIndex,
    uint fetchCount,
    bool reverseScan
  ) external view returns(RepliesResponse memory) {
    if(replies.length == 0) return RepliesResponse(new address[](0), 0, 0);
    require(startIndex < replies.length);
    if(startIndex + fetchCount >= replies.length) {
      fetchCount = replies.length - startIndex;
    }
    address[] memory selection = new address[](fetchCount);
    uint activeCount;
    uint i;
    uint replyIndex = startIndex;
    if(reverseScan && startIndex == 0) {
      replyIndex = replies.length - 1;
    }
    while(activeCount < fetchCount && replyIndex < replies.length) {
      selection[i] = replies[replyIndex];
      if(replyStatus[selection[i]] >= minStatus) activeCount++;
      if(reverseScan) {
        if(replyIndex == 0 || activeCount == fetchCount) break;
        replyIndex--;
      } else {
        replyIndex++;
      }
      i++;
    }

    address[] memory out = new address[](activeCount);
    uint j;
    for(i=0; i<fetchCount; i++) {
      if(replyStatus[selection[i]] >= minStatus) {
        out[j++] = selection[i];
      }
    }
    return RepliesResponse(out, replies.length, replyIndex);
  }
}

contract PostFactory {
  function createNew(
    string memory _subject,
    string memory _message,
    Post parent
  ) external returns(Post created) {
    created = new Post(_subject, _message, msg.sender);
    if(address(parent) != address(0)) {
      parent.addReply(IPost(address(created)));
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// EIP-XXXX: Contract Comments (Social Media: Web3 2.0)
interface IPost {
  function subject() external view returns(string memory);
  function message() external view returns(string memory);
  function addReply(address reply) external;
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