// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import { FxBaseChildTunnel } from "@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";

/**
 * @title CrossChainExecutor contract
 * @notice The CrossChainExecutor contract executes call from the origin chain.
 *         These calls are sent by the `CrossChainRelayer` contract which live on the origin chain.
 */
contract CrossChainExecutorPolygon is FxBaseChildTunnel {
  /* ============ Structs ============ */

  /**
   * @notice Call data structure
   * @param target Address that will be called
   * @param data Data that will be sent to the `target` address
   */
  struct Call {
    address target;
    bytes data;
  }

  /* ============ Custom Errors ============ */

  /**
   * @notice Custom error emitted if a call to a target contract fails.
   * @param call Call struct
   * @param errorData Error data returned by the failed call
   */
  error CallFailure(Call call, bytes errorData);

  /* ============ Events ============ */

  /**
   * @notice Emitted when calls have successfully been executed.
   * @param relayer Address of the contract that relayed the calls
   * @param nonce Unique identifier
   * @param caller Address of the caller on the origin chain
   * @param calls Array of calls being executed
   */
  event ExecutedCalls(
    address indexed relayer,
    uint256 indexed nonce,
    address indexed caller,
    Call[] calls
  );

  /* ============ Constructor ============ */

  /**
   * @notice CrossChainExecutor constructor.
   * @param _fxChild Address of the fx child contract on Polygon
   */
  constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

  /* ============ Internal Functions ============ */

  /// @inheritdoc FxBaseChildTunnel
  function _processMessageFromRoot(
    uint256, /* _stateId */
    address _sender,
    bytes memory _data
  ) internal override validateSender(_sender) {
    (uint256 _nonce, address _caller, Call[] memory _calls) = abi.decode(
      _data,
      (uint256, address, Call[])
    );

    uint256 _callsLength = _calls.length;

    for (uint256 _callIndex; _callIndex < _callsLength; _callIndex++) {
      Call memory _call = _calls[_callIndex];

      (bool _success, bytes memory _returnData) = _call.target.call(
        abi.encodePacked(_call.data, _caller)
      );

      if (!_success) {
        revert CallFailure(_call, _returnData);
      }
    }

    emit ExecutedCalls(_sender, _nonce, msg.sender, _calls);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}