//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SignetRegistry {
  mapping(address => address) public signets;
  mapping(address => uint) public nonces;
  event SignetChanged(address previous, address indexed signet, address indexed owner);

  function _registerSignet(address _signet, address _owner) internal {
    require(signets[_signet] == address(0), 'Signet already in use');
    signets[_signet] = _owner;
    emit SignetChanged(address(0), _signet, _owner);
  }

  function _revokeSignet(address _signet, address _owner) internal {
    require(signets[_signet] == _owner);
    delete signets[_signet];
    emit SignetChanged(_signet, address(0), _owner);
  }

  function _changeSignet(address _oldSignet, address _newSignet, address _owner) internal {
    require(signets[_oldSignet] == _owner, 'Permission denied');
    _revokeSignet(_oldSignet, _owner);
    _registerSignet(_newSignet, _owner);
  }

  function _recoverAddress(uint8 _v, bytes32 _r, bytes32 _s, bytes32 _messageHash) internal pure returns (address) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _messageHash));
    return ecrecover(prefixedHash, _v, _r, _s);
  }

  function _verifySignature(address _signet, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) internal returns(address) {
    require(nonces[_owner] == _nonce, 'Invalid nonce');
    nonces[_owner]++;
    bytes32 messageHash = keccak256(abi.encodePacked(_signet, _nonce));
    return _recoverAddress(_v, _r, _s, messageHash);
  }

  function _verifyChangeSignature(address _oldSignet, address _newSignet, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) internal returns(address) {
    require(nonces[_owner] == _nonce, 'Invalid nonce');
    nonces[_owner]++;
    bytes32 messageHash = keccak256(abi.encodePacked(_oldSignet, _newSignet, _nonce));
    return _recoverAddress(_v, _r, _s, messageHash);
  }

  function registerSignet(address _signet) external {
    _registerSignet(_signet, msg.sender);
  }

  function registerSignetFromSignature(address _signet, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) external {
    require(_verifySignature(_signet, _owner, _nonce, _v, _r, _s) == _owner, 'Invalid signature');
    _registerSignet(_signet, _owner);
  }

  function revokeSignet(address _signet) external {
    _revokeSignet(_signet, msg.sender);
  }

  function revokeSignetFromSignature(address _signet, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) external {
    require(_verifySignature(_signet, _owner, _nonce, _v, _r, _s) == _owner, 'Invalid signature');
    _revokeSignet(_signet, _owner);
  }

  function changeSignet(address _oldSignet, address _newSignet) external {
    _changeSignet(_oldSignet, _newSignet, msg.sender);
  }

  function changeSignetFromSignature(address _oldSignet, address _newSignet, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) external {
    require(_verifyChangeSignature(_oldSignet, _newSignet, _owner, _nonce, _v, _r, _s) == _owner, 'Invalid signature');
    _changeSignet(_oldSignet, _newSignet, _owner);
  }
}