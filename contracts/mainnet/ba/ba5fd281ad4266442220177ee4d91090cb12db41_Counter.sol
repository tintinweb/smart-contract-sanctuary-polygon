// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ISocket} from "../interfaces/ISocket.sol";

abstract contract PlugBase {
    address public owner;
    ISocket socket;

    constructor(address socket_) {
        owner = msg.sender;
        socket = ISocket(socket_);
    }

    //
    // Modifiers
    //
    modifier onlyOwner() {
        require(msg.sender == owner, "no auth");
        _;
    }

    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external onlyOwner {
        socket.connect(
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_
        );
    }

    function inbound(
        uint256 siblingChainSlug_,
        bytes calldata payload_
    ) external payable {
        require(msg.sender == address(socket), "no auth");
        _receiveInbound(siblingChainSlug_, payload_);
    }

    function _outbound(
        uint256 chainSlug_,
        uint256 gasLimit_,
        uint256 fees_,
        bytes memory payload_
    ) internal {
        socket.outbound{value: fees_}(chainSlug_, gasLimit_, payload_);
    }

    function _receiveInbound(
        uint256 siblingChainSlug_,
        bytes memory payload_
    ) internal virtual;

    function _getChainSlug() internal view returns (uint256) {
        return socket.chainSlug();
    }

    // owner related functions

    function removeOwner() external onlyOwner {
        owner = address(0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {PlugBase} from "../base/PlugBase.sol";

contract Counter is PlugBase {
    uint256 public number;
    uint256 public constant destGasLimit = 1000000;

    constructor(address socket_) PlugBase(socket_) {
        owner = msg.sender;
    }

    function setNumber(
        uint256 newNumber_,
        uint256 toChainSlug_
    ) external payable {
        _outbound(toChainSlug_, destGasLimit, msg.value, abi.encode(newNumber_));
    }

    function setNumber(uint256 newNumber_) public {
        number = newNumber_;
    }

    function _receiveInbound(
        uint256,
        bytes memory payload_
    ) internal virtual override {
        uint256 newNumber = abi.decode(payload_, (uint256));
        setNumber(newNumber);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface ISocket {
    /**
     * @notice emits the message details when a new message arrives at outbound
     * @param localChainSlug local chain slug
     * @param localPlug local plug address
     * @param dstChainSlug sibling chain slug
     * @param dstPlug sibling plug address
     * @param msgId message id packed with siblingChainSlug and nonce
     * @param msgGasLimit gas limit needed to execute the inbound at destination
     * @param fees fees provided by msg sender
     * @param payload the data which will be used by inbound at destination
     */
    event MessageTransmitted(
        uint256 localChainSlug,
        address localPlug,
        uint256 dstChainSlug,
        address dstPlug,
        uint256 msgId,
        uint256 msgGasLimit,
        uint256 executionFee,
        uint256 fees,
        bytes payload
    );

    /**
     * @notice emits the config set by a plug for a sibling
     * @param plug address of plug on current chain
     * @param siblingChainSlug sibling chain slug
     * @param siblingPlug address of plug on sibling chain
     * @param inboundSwitchboard inbound switchboard (select from registered options)
     * @param outboundSwitchboard outbound switchboard (select from registered options)
     * @param capacitor capacitor selected based on outbound switchboard
     * @param decapacitor decapacitor selected based on inbound switchboard
     */
    event PlugConnected(
        address plug,
        uint256 siblingChainSlug,
        address siblingPlug,
        address inboundSwitchboard,
        address outboundSwitchboard,
        address capacitor,
        address decapacitor
    );

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param siblingChainSlug_ the sibling chain slug
     * @param msgGasLimit_ the gas limit needed to execute the payload on destination
     * @param payload_ the data which is needed by plug at inbound call on destination
     */
    function outbound(
        uint256 siblingChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable returns (uint256 msgId);

    /**
     * @notice sets the config specific to the plug
     * @param siblingChainSlug_ the sibling chain slug
     * @param siblingPlug_ address of plug present at sibling chain to call inbound
     * @param inboundSwitchboard_ the address of switchboard to use for receiving messages
     * @param outboundSwitchboard_ the address of switchboard to use for sending messages
     */
    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    /**
     * @notice returns chain slug
     * @return chainSlug current chain slug
     */
    function chainSlug() external view returns (uint256 chainSlug);
}