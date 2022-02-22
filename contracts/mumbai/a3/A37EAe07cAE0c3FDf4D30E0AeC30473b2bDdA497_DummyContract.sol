// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";

contract DummyContract { //0x666ff195DC7e81a71cc73E1458E1B2bdA2654382

    ILayerZeroEndpoint public endpoint;

    constructor(address _layerZeroEndpoint) {
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
    }

    function sendTokens(
        uint16 _chainId,                            // send tokens to this chainId
        bytes calldata _dstMultiChainTokenAddr,     // destination address of MultiChainToken
        uint _qty                                   // how many tokens to send
    )
        public
        payable
    {
        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, _qty);

        // send LayerZero message
        endpoint.send{value:msg.value}(
            _chainId,                       // destination chainId
            _dstMultiChainTokenAddr,        // destination address of MultiChainToken
            payload,                        // abi.encode()'ed bytes
            payable(msg.sender),            // refund address (LayerZero will refund any superflous gas back to caller of send()
            address(0x0),                   // 'zroPaymentAddress' unused for this mock/example
            bytes("")                       // 'txParameters' unused for this mock/example
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.4;

interface ILayerZeroReceiver {
    // LayerZero will invoke this function to deliver the message on the destination
    function lzReceive(
        uint16 _srcChainId, // the source endpoint identifier
        bytes calldata _srcAddress, // the source sending contract address from the source chain
        uint64 _nonce, // the ordered message nonce
        bytes calldata _payload // the signed payload is the UA bytes has encoded to be sent
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.4;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified endpoint.
    // @param _chainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. ie: pay for a specified destination gasAmount, or receive airdropped native gas from the relayer on destination (oh yea!)
    function send(uint16 _chainId, bytes calldata _destination, bytes calldata _payload, address payable refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    function getInboundNonce(uint16 _chainID, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    function getOutboundNonce(uint16 _chainID, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _chainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _chainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getEndpointId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    // @param _libraryAddress - the address of the layerzero library
    function isValidSendLibrary(address _userApplication, address _libraryAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    // @param _libraryAddress - the address of the layerzero library
    function isValidReceiveLibrary(address _userApplication, address _libraryAddress) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.4;

interface ILayerZeroUserApplicationConfig {
    // @notice generic config getter/setter for user app
    function setConfig(uint16 _version, uint _configType, bytes calldata _config) external;

    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice LayerZero versions. Send/Receive can be different versions during migration
    function setSendVersion(uint16 version) external;

    function setReceiveVersion(uint16 version) external;

    function getSendVersion() external view returns (uint16);

    function getReceiveVersion() external view returns (uint16);

    // @notice Only in extreme cases where the UA needs to resume the message flow
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}