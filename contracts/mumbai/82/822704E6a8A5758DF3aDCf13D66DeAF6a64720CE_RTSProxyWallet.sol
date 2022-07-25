//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RTSProxyWallet {
  mapping(address => address) public proxyWallets;
  mapping(address => uint) public nonces;
  event ProxyWalletChanged(address _previous, address indexed _proxy, address indexed _subject);

  function _createProxyWallet(address _proxy, address _subject) internal {
    require(proxyWallets[_proxy] == address(0), 'Proxy already in use');
    proxyWallets[_proxy] = _subject;
    emit ProxyWalletChanged(address(0), _proxy, _subject);
  }

  function _revokeProxyWallet(address _proxy, address _subject) internal {
    require(proxyWallets[_proxy] == _subject);
    delete proxyWallets[_proxy];
    emit ProxyWalletChanged(_proxy, address(0), _subject);
  }

  function _changeProxyWallet(address _oldProxy, address _newProxy, address _subject) internal {
    require(proxyWallets[_oldProxy] == _subject, 'Permission denied');
    _revokeProxyWallet(_oldProxy, _subject);
    _createProxyWallet(_newProxy, _subject);
  }

  function _recoverAddress(uint8 _v, bytes32 _r, bytes32 _s, bytes32 _messageHash) internal pure returns (address) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _messageHash));
    return ecrecover(prefixedHash, _v, _r, _s);
  }

  function _verifySignature(address _proxy, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) internal returns(address) {
    require(nonces[_owner] == _nonce, 'Invalid nonce');
    nonces[_owner]++;
    bytes32 messageHash = keccak256(abi.encodePacked(_proxy, _nonce));
    return _recoverAddress(_v, _r, _s, messageHash);
  }

  function _verifyChangeSignature(address _oldProxy, address _newProxy, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) internal returns(address) {
    require(nonces[_owner] == _nonce, 'Invalid nonce');
    nonces[_owner]++;
    bytes32 messageHash = keccak256(abi.encodePacked(_oldProxy, _newProxy, _nonce));
    return _recoverAddress(_v, _r, _s, messageHash);
  }

  function setProxyWallet(address _proxy) external {
    _createProxyWallet(_proxy, msg.sender);
  }

  function setProxyWalletFromSignature(address _proxy, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) external {
    require(_verifySignature(_proxy, _owner, _nonce, _v, _r, _s) == _owner, 'Invalid signature');
    _createProxyWallet(_proxy, _owner);
  }

  function revokeProxyWallet(address _proxy) external {
    _revokeProxyWallet(_proxy, msg.sender);
  }

  function revokeProxyWalletFromSignature(address _proxy, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) external {
    require(_verifySignature(_proxy, _owner, _nonce, _v, _r, _s) == _owner, 'Invalid signature');
    _revokeProxyWallet(_proxy, _owner);
  }

  function changeProxyWallet(address _oldProxy, address _newProxy) external {
    _changeProxyWallet(_oldProxy, _newProxy, msg.sender);
  }

  function changeProxyWalletFromSignature(address _oldProxy, address _newProxy, address _owner, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) external {
    require(_verifyChangeSignature(_oldProxy, _newProxy, _owner, _nonce, _v, _r, _s) == _owner, 'Invalid signature');
    _changeProxyWallet(_oldProxy, _newProxy, _owner);
  }
}