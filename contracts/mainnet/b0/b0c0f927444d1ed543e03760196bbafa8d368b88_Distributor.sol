/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IToken {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external;
}

/// @title Token Distributor
/// @author @fbslo (@fbsloXBT)
/// @notice Contract to distribute PolyCub aurdrop.

contract Distributor {
    /// @notice Token to be distributed
    address public token;
    /// @notice Owner address who can change settings
    address public owner;
    /// @notice Signer address, used to sign messages off-chain
    address public signer;
    /// @notice true if contracts are allowed to interact, otherwise only EOAs can call it
    bool public allowContracts;

    /// @notice Nonces for each user, used to prevent replay attacks
    mapping(address => uint256) public nonces;
    /// @notice Total amount claimed by user
    mapping (address => uint256) public claimed;
    /// @notice Mapping of admin addresses
    mapping (address => bool) public isAdmin;

    /// @notice An event thats emitted when user claims rewards
    event Claim(address indexed user, uint256 amount);

    /**
     * @notice Construct a new Distributor contract
     * @param newSigner The address with signers rights
     * @param newToken The token to be distributed
     */
    constructor(address newSigner, address newToken){
        token = newToken;
        owner = msg.sender;
        signer = newSigner;
        allowContracts = false;
    }

    /**
     * @notice Claim PolyCub airdrop using signature generate off-chain
     * @param user Address of the user
     * @param amount PolyCUb amount that user wants to claim
     * @param nonce Number only used once
     * @param signature Signature signed by signer
     */
    function claim(address payable user, uint256 amount, uint256 nonce, bytes memory signature) external {
        bytes32 hash = getEthereumMessageHash(getMessageHash(user, amount, nonce));
        address signedBy = recoverSigner(hash, signature);

        require(signedBy == signer, 'Not signed by signer');
        require(nonces[user] == nonce, 'Nonce does not match');
        if (!allowContracts) require(msg.sender == tx.origin, 'No smart contracts allowed');

        nonces[user] += 1;
        claimed[user] += amount;

        IToken(token).transfer(user, amount);

        emit Claim(user, amount);
    }

    /**
     * @notice Call external contract
     * @param target Address of the contract we want to call
     * @param value ETH amount we want to send
     * @param signature Function signature
     * @param data Encoded call data
     */
    function call(address target, uint value, string memory signature, bytes memory data) external {
        require(msg.sender == owner, '!owner');
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success,) = target.call{value:value}(callData);
        require(success, "Transaction execution reverted.");
    }

    /**
     * @notice Change settings
     * @param newOwner Address of the new owner
     * @param newSigner Address of the new signer
     * @param newAllowContracts Boolean, true if contracts are allowed
     */
    function settings(address newOwner, address newSigner, bool newAllowContracts) external {
        require(msg.sender == owner, '!owner');
        require(newOwner != address(0), "Owner != 0x0");
        require(newSigner != address(0), "Signer != 0x0");

        owner = newOwner;
        allowContracts = newAllowContracts;
        signer = newSigner;
    }

    /**
     * @notice Get users nonce
     * @param user Address of the user
     */
    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    /**
     * @notice Get total amount user claimed
     * @param user Address of the user
     */
    function getClaimed(address user) external view returns (uint256) {
        return claimed[user];
    }

    /**
     * @notice Get hash of the input data
     * @param user Address of the user
     */
    function getMessageHash(address user, uint256 amount, uint256 nonce) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(user, amount, nonce));
    }

    /**
     * @notice Get hash of the input hash and ethereum message prefix
     * @param hash Hash of some data
     */
    function getEthereumMessageHash(bytes32 hash) public pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @notice Recover signer address from signature
     * @param hash Hash of some data
     * @param signature Signature of this hash
     */
    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return (address(0));
        }

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}