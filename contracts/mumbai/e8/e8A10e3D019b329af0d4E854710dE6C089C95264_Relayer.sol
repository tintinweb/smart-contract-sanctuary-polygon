/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Relayer {
  /**
   * @notice Trusted forwarders mapping
   */
  mapping(address => bool) public isTrustedForwarder;

  /**
   * @notice Only addresses we trust can use this contract
   */
  modifier onlyTrustedForwarder() {
    require(isTrustedForwarder[msg.sender], 'R600');
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
  function executeMetaTX(address from, address to, bytes memory data, bytes memory signature) public onlyTrustedForwarder {
    // Calculate hash
    bytes32 hash = _calculateHash(from, to, data);
    require(from == _recover(hash, signature), 'R604');
    
    // Actually call and execute data
    (bool success, ) = to.call(abi.encodePacked(data, from));
    require(success, 'R605');
  }

  /**
   * @notice execute two meta transactions
   */
  function executeMetaTXBatch(address[] memory from, address[] memory to, bytes[] memory data, bytes memory signature) public onlyTrustedForwarder {
    require((from.length == 2) && (from[0] == from[1]), 'R601');
    require((data.length == to.length) && (to.length == from.length), 'R602');
    
    // As we execute two transactions, finalHash should be
    // the result of hashing the hash of each one of the tx
    bytes32 finalHash = _calculateHash(from, to, data);
    require(from[0] == _recover(finalHash, signature), 'R603');

    // Actually call and execute data
    // This function is intended to be called
    // while doing two-steps operations
    (bool firstCall, ) = to[0].call(abi.encodePacked(data[0], from[0]));
    (bool secondCall, ) = to[1].call(abi.encodePacked(data[1], from[1]));
    require((firstCall) && (secondCall), 'R604');
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
  function _calculateHash(address[] memory from, address[] memory to, bytes[] memory data) internal pure returns (bytes32) {
    // Ethereum signed message prefix
    string memory prefix = "\x19Ethereum Signed Message:\n32";

    return keccak256(abi.encodePacked(prefix, keccak256(abi.encodePacked('from:', from[0], ', to:', to, ', data[0]:', data[0], ', data[1]:', data[1]))));
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

  /**
   * @notice Add or remove a trusted forwarder [Batch]
   */
  function validateForwarderBatch(address[] memory forwarders, bool valid) public onlyTrustedForwarder {
    for (uint i = 0; i < forwarders.length; i++) {
      isTrustedForwarder[forwarders[i]] = valid;
    }
  }
}