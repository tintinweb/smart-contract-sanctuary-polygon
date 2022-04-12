/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/AnyCallSrc.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CallProxy{
  function anyCall(
      address _to,
      bytes calldata _data,
      address _fallback,
      uint256 _toChainID
  ) external;
}

contract AnyCallSrc {
  // real: 0x37414a8662bC1D25be3ee51Fb27C2686e2490A89;
  address private _anyCallProxy;
  address private _owner;
  address private _anyCallDst;
  uint private _chainIdDst;
  address private _fallback; // maybe 0

  event NewMsg(string msg);

  function getOwner() view external returns(address) {
    return _owner;
  }

  function getAnyCallProxy() view external returns(address) {
    return _anyCallProxy;
  }

  function getChainIdDst() view external returns(uint) {
    return _chainIdDst;
  }

  constructor(
    address anyCallProxy,
    address anyCallDst, 
    uint chainIdDst, 
    address fallback_
  ) {
    _owner = msg.sender;
    _anyCallProxy = anyCallProxy;
    _anyCallDst = anyCallDst;
    _chainIdDst = chainIdDst;
    _fallback  = fallback_;
  }

  function step1_initiateAnyCallSimple(string calldata message) external {
    emit NewMsg(message);
    if (msg.sender == _owner){
      CallProxy(_anyCallProxy).anyCall(
        _anyCallDst,
        abi.encodeWithSignature("step2_createMsg(string)", message),
        address(_fallback),
        _chainIdDst
      );        
    }
  }
}