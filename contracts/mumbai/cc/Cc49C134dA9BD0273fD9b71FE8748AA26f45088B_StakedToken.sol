pragma solidity ^0.8.0;

import '@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol';

contract StakedToken is FxBaseChildTunnel {
    mapping(uint256 => address) private _owners;
    
    event Stake(
        address indexed sender,
        uint256 indexed tokenId
    );
    event Unstake(
        address indexed sender,
        uint256 indexed tokenId
    );

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

    function unstake(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender);
        delete _owners[tokenId];
        bytes memory data = abi.encodePacked(tokenId);
        _sendMessageToRoot(data);
        emit Stake(msg.sender, tokenId);        
    }

    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) internal override {
        (uint256 tokenId) = abi.decode(message, (uint256));
        _owners[tokenId] = sender;
        emit Stake(sender, tokenId);
    }
    
    function ownerOf(uint256 tokenId) public view returns(address) {
        return _owners[tokenId];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
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
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
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
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}