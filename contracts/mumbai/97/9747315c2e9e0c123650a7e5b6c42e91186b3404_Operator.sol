// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Client.sol";
import "openzeppelin/access/Ownable.sol";

/// @title Operator
/// @author Clique
/// @custom:coauthor ollie (eillo.eth)
/// @notice This contract is an instance of a Clique Client.
contract Operator is Client, Ownable {
  event ResponseData(bytes[] data);

  /// @notice Function calls internal function to get the Oracle contract address.
  function getOracle() external view returns (address) {
    return _getOracle();
  }

  /// @notice Function calls internal function to set the Oracle contract address.
  function setOracle(IOracle oracle) external onlyOwner {
    _setOracle(oracle);
  }

  /// @notice Function calls internal function to send an Oracle request.
  /// @notice taskId is the ID of the task to be performed by the node.
  /// @notice data is the data to be sent to the node.
  function sendOracleRequest(uint256 taskId, bytes memory data) external {
    // callback address is set to this contract
    // callback function selector is set to the fulfill function of this contract.
    Request memory request = Request(taskId, address(this), this.fulfill.selector, data);
    _sendRequest(request);
  }

  /// @notice Function is called by the Oracle contract to fulfill a request.
  function fulfill(uint256 requestId, bytes[] memory data) external recordFulfillment(requestId) {
    emit ResponseData(data);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./interfaces/IClient.sol";

error OracleNotSet();
error CannotBeZeroAddress();
error InvalidSource(address expectedSource, address source);

/// @title Client abstract contract
/// @author Clique
/// @custom:coauthor ollie (eillo.eth)
/// @notice This contract is to be inherited by Clique clients.
abstract contract Client is IClient {
  IOracle private _oracle;

  event Requested(uint256 indexed requestId);
  event Fulfilled(uint256 indexed requestId);

  mapping(uint256 => address) private _pendingRequests; // requestId => pending-status, checks if request is pending.

  /// @notice Struct to store request data.
  /// @param taskId The ID of the task to be performed by the node.
  /// @param callbackAddress The address the Oracle contract should call back to after fulfilling a request.
  /// @param callbackFunctionId The function selector used in the callback.
  /// @param data The data to be sent by the node.
  struct Request {
    uint256 taskId;
    address callbackAddress;
    bytes4 callbackFunctionId;
    bytes data;
  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits CliqueFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordFulfillment(uint256 requestId) {
    if (msg.sender != _pendingRequests[requestId]) revert InvalidSource(_pendingRequests[requestId], msg.sender);
    delete _pendingRequests[requestId];
    emit Fulfilled(requestId);
    _;
  }

  /// @notice Internal function to set the Oracle contract address.
  /// @param oracle The address of the Oracle contract.
  function _setOracle(IOracle oracle) internal {
    if (address(oracle) == address(0)) revert CannotBeZeroAddress();
    _oracle = oracle;
  }

  /// @notice Internal function to get the Oracle contract address.
  function _getOracle() internal view returns (address) {
    if (address(_oracle) == address(0)) revert OracleNotSet();
    return address(_oracle);
  }

  /// @notice Internal function to send an Oracle request.
  /// @param request The request data to be sent to the Oracle contract.
  function _sendRequest(Request memory request) internal {
    if (address(_oracle) == address(0)) revert OracleNotSet();
    uint256 requestId = _oracle.requestCount();
    _pendingRequests[requestId] = address(_oracle);

    emit Requested(requestId);
    IOracle(_oracle).oracleRequest(
      requestId,
      msg.sender,
      request.taskId,
      request.callbackAddress,
      request.callbackFunctionId,
      request.data
    );
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
pragma solidity ^0.8.17;

import "./IOracle.sol";

interface IClient {
  function getOracle() external view returns (address);

  function setOracle(IOracle oracle) external;

  function sendOracleRequest(uint256 taskId, bytes memory data) external;

  function fulfill(uint256 requestId, bytes[] memory data) external;
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
pragma solidity ^0.8.17;

interface IOracle {
  /// @notice OracleRequest is emitted when a request has been made.
  /// @param taskId The ID of the task to be performed by the node.
  /// @param requester The address of the account making the request.
  /// @param requestId The ID of the request.
  /// @param callbackAddress The address the contract should call back to after fulfilling a request.
  /// @param callbackFunctionId The function selector used in the callback.
  /// @param data The data to be send to the node.
  event OracleRequest(
    uint256 indexed taskId,
    address requester,
    uint256 requestId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    bytes data
  );

  function requestCount() external view returns (uint256);

  /// @notice Function called by Clique clients to create an oracle request.
  /// @param requestId The ID of the request.
  /// @param requester The address of the account making the request.
  /// @param taskId The ID of the task to be performed by the node.
  /// @param callbackAddress The address the contract should call back to after fulfilling a request.
  /// @param callbackFunctionId The function selector used in the callback.
  /// @param data The data to be send to the node.
  function oracleRequest(
    uint256 requestId,
    address requester,
    uint256 taskId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    bytes calldata data
  ) external;

  /// @notice notice Function called by Clique nodes to fulfill an oracle request.
  /// @param requestId The ID of the request.
  /// @param callbackAddress The address the contract should call back to after fulfilling a request.
  /// @param callbackFunctionId The function selector used in the callback.
  /// @param data The data returned by the node.
  function fulfillOracleRequest(
    uint256 requestId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    bytes[] calldata data
  ) external returns (bool);

  /// @notice Function checks if the sender is an authorized node.
  /// @param node The address of the node.
  /// @return True if the sender is an authorized node.
  function isAuthorizedNodeAddress(address node) external view returns (bool);
}