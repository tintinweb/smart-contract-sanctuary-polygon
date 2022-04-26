/**
 *Submitted for verification at polygonscan.com on 2022-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PostPlazaApproved
 * @author PostPlaza
 *
 *   An approved address is a wallet that is generated in a user’s browser to 
 *   sign transactions on their behalf. Without an approved address, users would 
 *   have to sign a message for every interaction, including likes, posts, reposts, etc. 
 *   With an approved address, the UI feels more like a Web2 social network.
 */

contract PostPlazaApproved {

    event NewApprovedAddress(address indexed approverAddress, address approveAddress);

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");
    bytes32 private constant APPROVE_ACCOUNT_TYPEHASH = keccak256("ApproveAccount(uint256 nonce,address approveAddress)");

    // Approved address can do interactions on behalf of user to improve UI.
    mapping(address => address) public approvedAddress;

    mapping(address => uint256) public sigTransactionNonce;

    constructor() {}

    // Set an approved address for either msg.sender or the signer of an ApproveAccount signature.
    function setApprovedAddress(address _approveAddress, uint256 _nonce, bytes32 r, bytes32 s, uint8 v) public {
        if (v >= 27) {
            address signer = ecrecover(hashApproveAccountTransaction(address(this), _nonce, _approveAddress), v, r, s);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            approvedAddress[signer] = _approveAddress;
            emit NewApprovedAddress(signer, _approveAddress);
        }
        else {
            approvedAddress[msg.sender] = _approveAddress;
            emit NewApprovedAddress(msg.sender, _approveAddress);
        }
    }

    // It's important to change version every deploy even across chains. This is since there isn't a chainId.
    // chainId wasn't included since some wallets have trouble switching networks.
    function getDomainSeperator(address verifyingContract) public pure returns (bytes32) {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("PostPlaza Approved Domain")),  // name
                keccak256(bytes("1")),                          // version
                verifyingContract
            ));
        return DOMAIN_SEPARATOR;
    }

    function hashApproveAccountTransaction(address verifyingContract, uint256 _nonce, address _approveAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(APPROVE_ACCOUNT_TYPEHASH, _nonce, _approveAddress))));
    }
}