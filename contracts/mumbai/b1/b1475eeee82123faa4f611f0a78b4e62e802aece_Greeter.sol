//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import { ICrossDomainMessenger } from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

import "../src/ExecutorAware.sol";

contract Greeter is ExecutorAware {
  string public greeting;

  event SetGreeting(
    string greeting,
    address l1Sender, // _msgSender() is the address who called `relayCalls` on the origin chain
    address l2Sender // CrossChainExecutor contract
  );

  constructor(address _executor, string memory _greeting) ExecutorAware(_executor) {
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    require(isTrustedForwarder(msg.sender), "Greeter/caller-not-executor");

    greeting = _greeting;
    emit SetGreeting(_greeting, _msgSender(), msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

/**
 * @title ExecutorAware contract
 * @notice The ExecutorAware contract allows contracts on a receiving chain to execute calls from an origin chain.
 *         These calls are sent by the `CrossChainRelayer` contract which live on the origin chain.
 *         The `CrossChainExecutor` contract on the receiving chain executes these calls
 *         and then forward them to a ExecutorAware contract on the receiving chain.
 * @dev This contract implements EIP 2771 (https://eips.ethereum.org/EIPS/eip-2771)
 *      to ensure that calls are sent by a trusted `CrossChainExecutor` contract.
 */
abstract contract ExecutorAware {
  /* ============ Variables ============ */

  /**
   * @notice Address of the trusted forwarder contract as specified in EIP 2771.
   *         In our case, it is the `CrossChainExecutor` contract on the receiving chain.
   */
  address public immutable trustedForwarder;

  /* ============ Constructor ============ */

  /**
   * @notice ExecutorAware constructor.
   * @param _executor Address of the `CrossChainRelayer` contract
   */
  constructor(address _executor) {
    require(_executor != address(0), "executor-not-zero-address");
    trustedForwarder = _executor;
  }

  /* ============ External Functions ============ */

  /**
   * @notice Check which forwarder this contract trust as specified in EIP 2771.
   * @param _forwarder Address to check
   */
  function isTrustedForwarder(address _forwarder) public view returns (bool) {
    return _forwarder == trustedForwarder;
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Retrieve signer address as specified in EIP 2771.
   * @return _signer Address of the signer
   */
  function _msgSender() internal view returns (address payable _signer) {
    _signer = payable(msg.sender);

    if (msg.data.length >= 20 && isTrustedForwarder(_signer)) {
      assembly {
        _signer := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    }
  }
}