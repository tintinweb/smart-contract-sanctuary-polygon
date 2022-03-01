// SPDX-License-Identifier: Unlicensed

pragma solidity >= 0.8.0;

import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroEndpoint.sol";

contract TWAPReceiver is ILayerZeroReceiver {
  ILayerZeroEndpoint public endpoint;
  mapping(uint16 => int56) public receivedTWAPs;

  event TWAPReceived(uint16 _sourceChainId, int56 _twap);

  error InvalidSender(address _sender);

  constructor(address _layerZeroEndpoint){
    endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
  }

  function lzReceive(uint16 _sourceChainId, bytes memory _fromAddress, uint64 _nonce, bytes memory _payload) override external {
    if(msg.sender != address(endpoint)) revert InvalidSender(msg.sender);
    (int56 _twap) = abi.decode(_payload, (int56));
    receivedTWAPs[_sourceChainId] = _twap;
    emit TWAPReceived(_sourceChainId, _twap);
  }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

// this interfaace should be implemented by any User Application contract
// to receive a LayerZero message.
interface ILayerZeroReceiver {
  function lzReceive(
      uint16 _srcChainId,
      bytes calldata _srcAddress,
      uint64 nonce,
      bytes calldata _payload
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
  // the starting point of LayerZero message protocol
  function send(uint16 _chainId, bytes calldata _destination, bytes calldata _payload, address payable refundAddress, address _zroPaymentAddress,  bytes calldata txParameters ) external payable;

  // estimate the fee requirement for message passing
  function estimateNativeFees(uint16 _chainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _txParameters)  view external returns(uint totalFee);

  // LayerZero uses nonce to enforce message ordering.
  function getInboundNonce(uint16 _chainID, bytes calldata _srcAddress) external view returns (uint64);

  function getOutboundNonce(uint16 _chainID, address _srcAddress) external view returns (uint64);

  // endpoint has a unique ID that never change. User application may need this to identity the blockchain they are on
  function getEndpointId() view external returns(uint16);

  // LayerZero catch all error/exception from the receiver contract and store them for retry.
  function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint _gasLimit) external returns(bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

// a contract that implements this interface must have access
// to a LayerZero endpoint
interface ILayerZeroUserApplicationConfig {
    // generic config for user Application
    function setConfig(uint16 _version, uint _configType, bytes calldata _config) external;
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) view external returns(bytes memory);

    // LayerZero versions. Send/Receive can be different versions during migration
    function setSendVersion(uint16 version) external;
    function setReceiveVersion(uint16 version) external;
    function getSendVersion() external view returns (uint16);
    function getReceiveVersion() external view returns (uint16);

    //---------------------------------------------------------------------------
    // Only in extreme cases where the UA needs to resume the message flow
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}