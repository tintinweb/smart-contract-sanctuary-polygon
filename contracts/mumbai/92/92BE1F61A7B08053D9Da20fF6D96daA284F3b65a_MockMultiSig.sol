// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract MockMultiSig {
  //keccak256(
  //    "SafeMessage(bytes message)"
  //);
  bytes32 private constant SAFE_MSG_TYPEHASH = 0x60b3cbf8b4a223d68d641b3b6ddf9a298e7f33710cf3d3a9d1146b5a6150fbca;
  //keccak256(
  //    "isValidSignature(bytes32,bytes)"
  //);
  bytes4 internal constant MAGIC_VALUE = 0x1626ba7e;
  bytes4 internal constant INVALID_SIGNATURE = 0xffffffff;

  mapping(string => uint256) private _messages;
  uint256 private _required;

  // Events definitions
  event SignMsg(bytes32 indexed msgHash);

  constructor()
    {
      _required = 2;
    }

  function signMessage(string memory msg_) external {
    _messages[msg_] += 1;
    emit SignMsg(SAFE_MSG_TYPEHASH);
  }

  function isValidSignature(string memory msg_) external view returns (bytes4) {
    require(_messages[msg_] != 0);
    if (_messages[msg_] <= _required){
      return INVALID_SIGNATURE;
    } else {
      return MAGIC_VALUE;
    }
  }

  function reset(string calldata msg_) external {
    require(_messages[msg_] != 0);
    _messages[msg_] = 0;
  }
}