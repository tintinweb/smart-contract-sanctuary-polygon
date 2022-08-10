//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;
import './Ownable.sol';
import './Verifiable.sol';

error SignatureNotVerified();
error AdminNotAuthorized();
error AdminNotSet();
error LengthMismatch();

contract Governance is Ownable, Verifiable {

    mapping (string => string) public pollResult;

    event PollPublished(string _pollId, string _result);
    event AdminUpdated(address _newAdmin);
    event AdminAuthorizationUpdated(address admin, bool _isAuthorized);

    constructor(address owner) Ownable(owner){}

    /**
    * @param _pollId : The poll id string corresponding to the id offchain
    * @return _pollResult :  The IPFS CID hash corresponding to the result of the rating of the poll
    * Returns the IPFS url of the poll rating containing the voting data
    */
    function getPollResult(string calldata _pollId) external view returns(string memory _pollResult) {
        return pollResult[_pollId];
    }

    /**
    * @param _pollId : The id of the poll corresponding to offchain poll id
    * @param _result : The IPFS CID hash corresponding to the voting result of the rating of the poll
    * @param _signature : The signature corresponding to the pollId and ipfs hash
    * @return success : Returns boolean value true when flow is completed successfully
    * To create a new poll entry, with some data (pollId, poll result) included for future verification with offchain data
    */
    function setPollResult(string calldata _pollId, string calldata _result, bytes calldata _signature) public returns(bool success){
        if(!verify(owner(), msg.sender, _pollId, _result, _signature)) revert SignatureNotVerified();

        pollResult[_pollId] = _result;
        emit PollPublished(_pollId, _result);
        return true;
    }

    /**
    * @param _pollIds : The array of ids of the poll corresponding to offchain poll ids
    * @param _results : The array of transaction hashes corresponding to the result of the rating of the polls
    * @param _signatures : The array of signatures corresponding to the pollId array and ipfs hash array
    * @return success : Returns boolean value true when flow is completed successfully
    * To create a new poll entry, with some data (pollId, poll result) included for future verification with offchain data
    */
    function multiSetPollResult(string[] calldata _pollIds, string[] calldata _results, bytes[] calldata _signatures) 
    external returns(bool success){
       if(_pollIds.length != _results.length || _results.length != _signatures.length) revert LengthMismatch();

        for (uint256 i = 0; i < _pollIds.length; i++) {
            setPollResult(_pollIds[i], _results[i], _signatures[i]);
        }
        return true;
    }

        /**
    * @param _pollId : The id of the poll corresponding to offchain poll id
    * @param _result : The IPFS CID hash corresponding to the voting result of the rating of the poll
    * @param _signature : The signature corresponding to the pollId and ipfs hash
    * @return success : Returns boolean value true when flow is completed successfully
    * To create a new poll entry, with some data (pollId, poll result) included for future verification with offchain data using admin signature
    */
    function setPollResultThroughAdmin(string calldata _pollId, string calldata _result, bytes calldata _signature) public returns(bool success){

        if(admin == address(0)) revert AdminNotSet();
        if(!isAdminAuthorized) revert AdminNotAuthorized();
        if(!verify(admin, msg.sender, _pollId, _result, _signature)) revert SignatureNotVerified();

        pollResult[_pollId] = _result;
        emit PollPublished(_pollId, _result);
        return true;
    }

    /**
    * @param _pollIds : The array of ids of the poll corresponding to offchain poll ids
    * @param _results : The array of transaction hashes corresponding to the result of the rating of the polls
    * @param _signatures : The array of signatures corresponding to the pollId array and ipfs hash array
    * @return success : Returns boolean value true when flow is completed successfully
    * To create a new poll entry, with some data (pollId, poll result) included for future verification with offchain data using admin signature
    */
    function multiSetPollResultThroughAdmin(string[] calldata _pollIds, string[] calldata _results, bytes[] calldata _signatures) 
    external returns(bool success){
       if(_pollIds.length != _results.length || _results.length != _signatures.length) revert LengthMismatch();

        for (uint256 i = 0; i < _pollIds.length; i++) {
            setPollResultThroughAdmin(_pollIds[i], _results[i], _signatures[i]);
        }
        return true;
    }

    /**
    * @param _pollId : The id of the poll corresponding to offchain poll id
    * @param _result : The IPFS CID hash corresponding to the voting result of the rating of the poll
    * @return success : Returns boolean value true when flow is completed successfully
    * To create a new poll entry, with some data (pollId, poll result) included for future verification with offchain data
    * Can be executed only by the owner or admin(if authorized) of the governance smart contract
    */
    function setPollResultOwnerOrAdmin(string calldata _pollId, string calldata _result) public onlyOwnerOrAdmin returns(bool success){
        pollResult[_pollId] = _result;
        emit PollPublished(_pollId, _result);
        return true;
    }

    /**
    * @param _pollIds : The array of ids of the poll corresponding to offchain poll ids
    * @param _results : The array of transaction hashes corresponding to the result of the rating of the polls
    * @return success : Returns boolean value true when flow is completed successfully
    * To create multiple new poll entries, with some data (pollId, poll result) included for future verification with offchain data
    * Can be executed only by the owner or admin(if authorized) of the governance smart contract
    */
    function multiSetPollResultOwnerOrAdmin(string[] calldata _pollIds, string[] calldata _results) 
    external onlyOwnerOrAdmin returns(bool success){
        if(_pollIds.length != _results.length) revert LengthMismatch();

        for (uint256 i = 0; i < _pollIds.length; i++) {
            setPollResultOwnerOrAdmin(_pollIds[i], _results[i]);
        }
        return true;
    }

    /**
    * @param _newAdmin : The poll id string corresponding to the id offchain
    * To set the admin address, who can set poll results without owner signature
    */
    function setAdmin(address _newAdmin) external onlyOwner{
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }

    /**
    * @param _isAuthorized : The poll id string corresponding to the id offchain
    * To authorize or revoke admin permission for setting poll results
    */
    function setAdminAuthorization(bool _isAuthorized) external onlyOwner{
        isAdminAuthorized = _isAuthorized;
        emit AdminAuthorizationUpdated(admin, _isAuthorized);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Context {
    /**
     * @return Address of the transaction message sender {msg.sender}
     * Returns the msg.sender
     */
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {

    address public _owner;

    // Admin
    address public admin;
    bool public isAdminAuthorized;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @param tokenOwner address of the token owner
     * Transfers ownership to tokenOwner
     */
    constructor(address tokenOwner) {
        _transferOwnership(tokenOwner);
    }

    /**
     * @return Address of the owner of the contract
     * Returns the owner address
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * Modifier that checks if the msg.sender is the owner or admin (if admin is authorized)
     */
    modifier onlyOwnerOrAdmin() {
        require(owner() == _msgSender() || (isAdminAuthorized && admin != address(0) && admin == _msgSender()), "Ownable: caller is not the owner nor admin, or admin is unauthorized");
        _;
    }

    /**
     * Modifier that checks if the msg.sender is the owner
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @return Boolean value true if flow was successful
     * Only owner can call the function
     * Releases ownership to address 0x0
     */
    function renounceOwnership() public onlyOwner returns(bool) {
        _transferOwnership(address(0));
        return true;
    }
    
    /**
     * @return Boolean value true if flow was successful
     * Only owner can call the function
     * Releases ownership to address newOwner
     */
    function transferOwnership(address newOwner) public onlyOwner returns(bool){
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
        return true;
    }

    /**
     * Sets newOwner as the owner and emits the OwnershipTransferred event
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.10;
import "./ECDSA.sol";

error InvalidSignature();

contract Verifiable {
    using ECDSA for bytes32;

    bytes32 private DOMAIN_SEPARATOR;
    bytes32 private constant VOTE_UPLOAD_TYPEHASH =
        keccak256("voteUpload(address to,string pollId,string pollResult)");

    constructor() {

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("MoviecoinGovernance")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function verify(address signerToBeMatched, address to, string calldata pollId, string calldata pollResult, bytes calldata signature) public view returns(bool success){

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(VOTE_UPLOAD_TYPEHASH, to, keccak256(abi.encodePacked(pollId)), keccak256(abi.encodePacked(pollResult))))
            )
        );

        address signer = digest.recover(signature);
        if(signer == address(0) || signer != signerToBeMatched) revert InvalidSignature();

        return true;
    }    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}