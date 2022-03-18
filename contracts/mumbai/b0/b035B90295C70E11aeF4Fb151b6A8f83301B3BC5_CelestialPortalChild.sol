// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Celestial Portal Child
 * @notice Edited from fx-portal/contracts and EtherOrcsOfficial/etherOrcs-contracts.
 */
contract CelestialPortalChild is Ownable {
  /// @notice MessageTunnel on L1 will get data from this event.
  event MessageSent(bytes message);
  /// @notice Emited when we replay a call.
  event CallMade(address target, bool success, bytes data);

  /// @notice Fx Child contract address.
  address public fxChild;

  /// @notice Mainland Portal contract address.
  address public mainlandPortal;

  /// @notice Authorized callers mapping.
  mapping(address => bool) public auth;

  /// @notice Require the sender to be the owner or authorized.
  modifier onlyAuth() {
    require(auth[msg.sender], "CelestialPortalChild: Unauthorized to use the portal");
    _;
  }

  /// @notice Initialize the contract.
  function initialize(address newFxChild, address newMainlandPortal) external onlyOwner {
    fxChild = newFxChild;
    mainlandPortal = newMainlandPortal;
  }

  /// @notice Give authentication to `adds_`.
  function setAuth(address[] calldata addresses, bool authorized) external onlyOwner {
    for (uint256 index = 0; index < addresses.length; index++) {
      auth[addresses[index]] = authorized;
    }
  }

  /// @notice Send a message to the portal via FxChild.
  function sendMessage(bytes calldata message) external onlyAuth {
    emit MessageSent(message);
  }

  /// @notice Clone reflection calls by the owner.
  function replayCall(
    address target,
    bytes calldata data,
    bool required
  ) external onlyOwner {
    (bool succ, ) = target.call(data);
    if (required) require(succ, "CelestialPortalChild: Replay call failed");
  }

  /// @notice Executed when we receive a message from Mainland.
  function processMessageFromRoot(
    uint256,
    address rootSender,
    bytes calldata data
  ) external {
    require(msg.sender == fxChild, "CelestialPortalChild: INVALID_SENDER");
    require(rootSender == mainlandPortal, "CelestialPortalChild: INVALID_PORTAL");

    (address target, bytes[] memory calls) = abi.decode(data, (address, bytes[]));
    for (uint256 i = 0; i < calls.length; i++) {
      (bool success, ) = target.call(calls[i]);
      emit CallMade(target, success, calls[i]);
    }
  }
}

interface IFxMessageProcessor {
  function processMessageFromRoot(
    uint256 stateId,
    address rootMessageSender,
    bytes calldata data
  ) external;
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