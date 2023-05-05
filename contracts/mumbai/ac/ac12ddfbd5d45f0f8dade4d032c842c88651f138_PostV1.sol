// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MessageEditable.sol";
import "./AllowRepliesStatus.sol";
import "./IAllowReplies.sol";

contract PostV1 is MessageEditable, AllowRepliesStatus {
  constructor(string memory _message, address _owner)
    MessageEditable(_message, _owner) {}

  function supportsInterface(bytes4 interfaceId) public view virtual
      override (AllowRepliesStatus, MessageEditable) returns (bool) {
    return interfaceId == type(IMessageEditable).interfaceId
        || interfaceId == type(IMessage).interfaceId
        || interfaceId == type(IAllowRepliesStatus).interfaceId
        || interfaceId == type(IAllowReplies).interfaceId
        || super.supportsInterface(interfaceId);
  }

  function setReplyStatus(ReplyStatus[] memory newStatus) external onlyOwner {
    _setReplyStatus(newStatus);
  }
}

contract PostV1Factory {
  event NewPost(address indexed post, address indexed parent);

  function createNew(string memory message, IAllowReplies parent) external returns(PostV1 created) {
    created = new PostV1(message, msg.sender);
    emit NewPost(address(created), address(parent));

    if(address(parent) != address(0)) {
      parent.addReply(address(created));
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Message.sol";
import "./IMessageEditable.sol";

contract MessageEditable is Ownable, Message {
  uint256 public lastEdited;

  event MessageChanged(string oldValue, string newValue);
  
  constructor(string memory _message, address _owner) Message(_message) {
    _transferOwnership(_owner);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IMessageEditable).interfaceId || super.supportsInterface(interfaceId);
  }

  function editMessage(string memory newValue) external onlyOwner {
    emit MessageChanged(message, newValue);
    message = newValue;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AllowReplies.sol";
import "./IAllowRepliesStatus.sol";

contract AllowRepliesStatus is AllowReplies {
  mapping(address => int32) public replyStatus;
  uint256 public replyCountLTZero;

  event ReplyStatusUpdated(address indexed item, int32 oldStatus, int32 newStatus);

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAllowRepliesStatus).interfaceId || super.supportsInterface(interfaceId);
  }

  function replyCountGTEZero() external view returns(uint256) {
    return replies.length - replyCountLTZero;
  }

  struct ReplyStatus {
    address item;
    int32 status;
  }

  function _setReplyStatus(ReplyStatus[] memory newStatus) internal {
    if(newStatus.length > 0) {
      for(uint256 i = 0; i < newStatus.length; i++) {
        int32 oldVal = replyStatus[newStatus[i].item];
        int32 newVal = newStatus[i].status;
        if(oldVal == newVal) continue;
        require(newVal != 0);
        emit ReplyStatusUpdated(newStatus[i].item, oldVal, newVal);
        replyStatus[newStatus[i].item] = newVal;

        bool changedSign = (oldVal > 0 && newVal < 0) || (oldVal < 0 && newVal > 0);
        if(changedSign) {
          if(newVal > 0) replyCountLTZero--;
          else replyCountLTZero++;
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IAllowReplies is IERC165 {
  function addReply(address reply) external;
  function replyCount() external view returns(uint256);
  function replies(uint256 index) external view returns(address);
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
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IMessage.sol";

contract Message is ERC165 {
  string public message;
  uint256 public created;

  constructor(string memory _message) {
    message = _message;
    created = block.timestamp;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IMessage).interfaceId || super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IMessage.sol";
import "./IOwnable.sol";

interface IMessageEditable is IMessage, IOwnable {
  event MessageChanged(string oldValue, string newValue);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function lastEdited() external view returns(uint256);
  function editMessage(string memory newValue) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IAllowReplies.sol";

contract AllowReplies is ERC165 {
  address[] public replies;

  event ReplyAdded(address indexed item, uint256 indexed replyIndex);

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAllowReplies).interfaceId || super.supportsInterface(interfaceId);
  }

  function addReply(address reply) external {
    emit ReplyAdded(reply, replies.length);
    replies.push(reply);
  }

  function replyCount() external view returns(uint256) {
    return replies.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IAllowReplies.sol";

interface IAllowRepliesStatus is IAllowReplies {
  function replyStatus(address item) external view returns(int32);
  function replyCountLTZero() external view returns(uint256);
  function replyCountGTEZero() external view returns(uint256);
  
  struct ReplyStatus {
    address item;
    int32 status;
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

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMessage is IERC165 {
  function message() external view returns(string memory);
  function created() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IOwnable {
  function owner() external view returns(address);
  function transferOwnership(address newOwner) external;
  function renounceOwnership() external;
}