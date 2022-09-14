/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Relayer {
  /**
   * @notice Trusted forwarders mapping
   */
  mapping(address => bool) public isTrustedForwarder;

  /**
   * @notice Nonce of addresses
   */
  mapping(address => uint) public nonce;

  /**
   * @notice [JIRA: BERU-230]
   */
  modifier onlyTrustedForwarder() {
    require(isTrustedForwarder[msg.sender], 'Error: {msg.sender} has to be a trusted forwarder');
    _;
  }

  /**
   * @notice Builder
   */
  constructor() {
    isTrustedForwarder[msg.sender] = true;
  }

  /**
   * @notice execute a meta transaction
   */
  function executeMetaTX(address from, address to, bytes memory data, bytes memory signature) public onlyTrustedForwarder returns (bytes memory response) {
    // Calculate hash
    bytes32 hash = _calculateHash(from, to, data);
    require(from == _recover(hash, signature), 'Error: {from} address must be {msg.sender}');
    
    // Actually call and execute data
    bool success;
    (success, response) = to.call(abi.encodePacked(data, from));
    require(success, 'Error: call failed');

    nonce[from]++;
  }

  /**
   * @notice Internal function to get the ECDSA values of {signature}
   * @param signature The signature
   * @return r first 32 bytes of signature
   * @return s second 32 bytes of signature
   * @return v final byte of signature
   */
  function _unwrapSignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }
  }

  /**
   * @notice Function to recover the address from a signature
   */
  function _recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = _unwrapSignature(signature);
    // Return the address
    return ecrecover(hash, v, r, s);
  }

  /**
   * @notice Function to calculate keccak256 hash
   */
  function _calculateHash(address from, address to, bytes memory data) internal pure returns (bytes32) {
    // Ethereum signed message prefix
    string memory prefix = "\x19Ethereum Signed Message:\n32";
    return keccak256(abi.encodePacked(prefix, keccak256(abi.encodePacked('from:', from, ', to:', to, ', data:', data))));
  }

  /**
   * @notice Add or remove a trusted forwarder
   */
  function validateForwarder(address forwarder, bool valid) public onlyTrustedForwarder {
    isTrustedForwarder[forwarder] = valid;
  }

}