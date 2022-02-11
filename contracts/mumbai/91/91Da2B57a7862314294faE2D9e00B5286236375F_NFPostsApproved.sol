/**
 *Submitted for verification at polygonscan.com on 2022-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFPostsApproved {
    
    event NewApprovedAddress(address indexed approverAddress, address approveAddress);
    
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");
    bytes32 private constant APPROVE_ACCOUNT_TYPEHASH = keccak256("ApproveAccount(uint256 nonce,address approveAddress)");
    
    // Approved address can do interactions on behalf of user to improve UI.
    mapping(address => address) public approvedAddress;
    
    mapping(address => uint256) public sigTransactionNonce;
        
    constructor() {}

    function setApprovedAddress(address _approveAddress, uint256 _nonce, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) {
            address signer = ecrecover(hashApproveAccountTransaction(address(this), _nonce, _approveAddress), v, r, s);
            sigTransactionNonce[signer] = _nonce;
            approvedAddress[signer] = _approveAddress;
            emit NewApprovedAddress(signer, _approveAddress);
        }
        else {
            approvedAddress[msg.sender] = _approveAddress;
            emit NewApprovedAddress(msg.sender, _approveAddress);
        }
    }
    
    function getDomainSeperator(address verifyingContract) public pure returns (bytes32) {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes("NFPosts Approved Domain")),  // name
            keccak256(bytes("1")),                        // version
            verifyingContract
        ));
        return DOMAIN_SEPARATOR;
    }
    
    function hashApproveAccountTransaction(address verifyingContract, uint256 _nonce, address _approveAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(APPROVE_ACCOUNT_TYPEHASH, _nonce, _approveAddress))));
    }
}