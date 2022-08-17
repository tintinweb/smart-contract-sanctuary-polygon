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

  function _hashMessage(address _oldSignet, address _signet, uint256 _nonce) private view returns (bytes32) {
    bytes32 messageHash = _oldSignet == address(0) ?
     keccak256(abi.encode(
       keccak256("Message(address signet,uint256 nonce)"),
       _signet,
       _nonce
     )):
     keccak256(abi.encode(
       keccak256("Message(address oldSignet,address signet,uint256 nonce)"),
       _oldSignet,
       _signet,
       _nonce
     ));
    return keccak256(abi.encodePacked(
        "\x19\x01",
        keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId)"
                ),
                keccak256(bytes("Signet")),
                keccak256(bytes("1")),
                block.chainid
          )
        ),
      messageHash
    ));
  }

  function _recoverAddress(uint8 _v, bytes32 _r, bytes32 _s, address _oldSignet, address _signet, uint256 _nonce) internal view returns (address) {
    bytes32 digest = _hashMessage(_oldSignet, _signet, _nonce);
    return ecrecover(digest, _v, _r, _s);
  }

  function _verifySignature(address _oldSignet, address _signet, address _owner, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) internal returns(address) {
    require(nonces[_owner] == _nonce, 'Invalid nonce');
    nonces[_owner]++;
    return _recoverAddress(_v, _r, _s, _oldSignet, _signet, _nonce);
  }

  function registerSignet(address _signet) external {
    _registerSignet(_signet, msg.sender);
  }

  function registerSignetFromSignature(address _signet, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) external {
    require(_verifySignature(address(0), _signet, _owner, _nonce, _v, _r, _s) == _owner, 'Invalid signature');
    _registerSignet(_signet, _owner);
  }

  function revokeSignet(address _signet) external {
    _revokeSignet(_signet, msg.sender);
  }

  function revokeSignetFromSignature(address _signet, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) external {
    require(_verifySignature(address(0), _signet, _owner, _nonce, _v, _r, _s) == _owner, 'Invalid signature');
    _revokeSignet(_signet, _owner);
  }

  function changeSignet(address _oldSignet, address _newSignet) external {
    _changeSignet(_oldSignet, _newSignet, msg.sender);
  }

  function changeSignetFromSignature(address _oldSignet, address _newSignet, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) external {
    require(_verifySignature(_oldSignet, _newSignet, _owner, _nonce, _v, _r, _s) == _owner, 'Invalid signature');
    _changeSignet(_oldSignet, _newSignet, _owner);
  }
}