// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./FxCommonTypes.sol";
import "./FxBaseChildTunnel.sol";

import "../token/IFxERC721.sol";

contract FxERC721ChildTunnel is
  FxBaseChildTunnel,
  FxCommonTypes,
  IERC721Receiver
{
  ////////////////////////////////////////////////////////////////////////////////
  // EVENTS
  ////////////////////////////////////////////////////////////////////////////////
  event Withdraw(address indexed childToken, address indexed user, uint256[] tokenIds);
  event Deposit(address indexed childToken, address indexed user, uint256[] tokenIds);

  ////////////////////////////////////////////////////////////////////////////////
  // GENERAL
  ////////////////////////////////////////////////////////////////////////////////
  mapping(address => address) public childToRootToken;

  // solhint-disable-next-line
  constructor(address fxChild_) FxBaseChildTunnel(fxChild_) {}

  function mapToken(address rootToken_, address childToken_) external onlyOwner {
    childToRootToken[childToken_] = rootToken_;
  }

  function setFxRootTunnel(address rootTunnel_) external virtual override onlyOwner {
    fxRootTunnel = rootTunnel_;
  }

  ////////////////////////////////////////////////////////////////////////////////
  // TO ROOT
  ////////////////////////////////////////////////////////////////////////////////
  function withdraw(address childToken_, uint256[] calldata tokenIds_)
    external
    isMapped(childToken_)
  {
    require(tokenIds_.length <= BATCH_LIMIT, "ChildTunnel: batch limit");

    IFxERC721 childToken = IFxERC721(childToken_);
    childToken.burn(msg.sender, tokenIds_);

    address rootToken = childToRootToken[childToken_];
    bytes memory message = abi.encode(rootToken, msg.sender, tokenIds_);
    message = abi.encode(WITHDRAW, message);
    _sendMessageToRoot(message);

    emit Withdraw(childToken_, msg.sender, tokenIds_);
  }

  ////////////////////////////////////////////////////////////////////////////////
  // FROM ROOT
  ////////////////////////////////////////////////////////////////////////////////
  function _deposit(bytes memory data_) internal {
    (address childToken_, address user, uint256[] memory tokenIds) = abi.decode(
      data_,
      (address, address, uint256[])
    );

    IFxERC721 childToken = IFxERC721(childToken_);
    childToken.mint(user, tokenIds);

    emit Deposit(childToken_, user, tokenIds);
  }

  function _processMessageFromRoot(
    uint256,
    address sender_,
    bytes memory data_
  ) internal override onlyRootTunnel(sender_) {
    (bytes32 syncType, bytes memory syncData) = abi.decode(data_, (bytes32, bytes));

    if (syncType == DEPOSIT) {
      _deposit(syncData);
    } else {
      revert("ChildTunnel: invalid sync");
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  // MISC
  ////////////////////////////////////////////////////////////////////////////////
  modifier isMapped(address childToken_) {
    require(
      childToRootToken[childToken_] != address(0x0),
      "ChildTunnel: token not mapped"
    );
    _;
  }

  function onERC721Received(
    address, /* operator */
    address, /* from */
    uint256, /* tokenId */
    bytes calldata /* data */
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract FxCommonTypes {
  bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
  bytes32 public constant WITHDRAW = keccak256("WITHDRAW");

  uint256 public constant BATCH_LIMIT = 15;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFxMessageProcessor {
  function processMessageFromRoot(
    uint256 stateId,
    address rootMessageSender,
    bytes calldata data
  ) external;
}

abstract contract FxBaseChildTunnel is IFxMessageProcessor, Ownable {
  event MessageSent(bytes message);

  address public fxChild;
  address public fxRootTunnel;

  constructor(address _fxChild) {
    fxChild = _fxChild;
  }

  ////////////////////////////////////////////////////////////////////////////////
  // FROM ROOT
  ////////////////////////////////////////////////////////////////////////////////
  function processMessageFromRoot(
    uint256 stateId,
    address rootMessageSender,
    bytes calldata data
  ) external override {
    require(msg.sender == fxChild, "FxCT: INVALID_SENDER");
    _processMessageFromRoot(stateId, rootMessageSender, data);
  }

  function _processMessageFromRoot(
    uint256 stateId,
    address sender,
    bytes memory message
  ) internal virtual;

  ////////////////////////////////////////////////////////////////////////////////
  // TO ROOT
  ////////////////////////////////////////////////////////////////////////////////
  function _sendMessageToRoot(bytes memory message) internal {
    emit MessageSent(message);
  }

  ////////////////////////////////////////////////////////////////////////////////
  // MISC
  ////////////////////////////////////////////////////////////////////////////////
  function setFxRootTunnel(address _fxRootTunnel) external virtual onlyOwner {
    fxRootTunnel = _fxRootTunnel;
  }

  modifier onlyRootTunnel(address sender) {
    require(sender == fxRootTunnel, "FxCT: INVALID_SENDER_FROM_ROOT");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFxERC721 {
  function mint(
    address user_,
    uint256[] calldata tokenIds_
  ) external;

  function burn(address user_, uint256[] calldata tokenIds_) external;
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