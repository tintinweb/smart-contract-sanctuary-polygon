//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../signatures/EIP712.sol";

// based on openzeppelin's `MinimalForwarder` reference implementation:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/MinimalForwarder.sol
contract FiboMetatxForwarder is FiboEIP712 {
    /// @notice emitted after any metatx is executed, regardless of whether it succeeded or failed
    /// @param sender the address of the account that signed the metatx (not the one who actually submitted it on-chain)
    /// @param nonce the metatx nonce used for this transaction
    /// @param success true if the internal transaction succeeded, and false otherwise
    /// @param reason if the transaction failed with a revert string (using the standard `Error(string)` selector and abi)
    /// then this field will contain that revert string.  if the transaction succeeded or we were unable to extract
    /// a revert reason string, then this field will contain the empty string
    event FiboMetatxResult(
        address indexed sender,
        uint256 indexed nonce,
        bool success,
        string reason
    );

    struct ForwardRequest {
        address from;
        address to;
        // `value` field removed from openzeppelin reference because we don't support transactions that transfer the native token
        // uint256 value

        // `gas` field removed from openzeppelin reference because we are fine with covering gas costs for these transactions
        // (and only to our own contracts, so we'll determine our own gas)
        // uint256 gas

        uint256 nonce;
        bytes data;
    }

    bytes32 private constant REQUEST_TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 nonce,bytes data)");

    mapping(address => uint256) public nonces;

    constructor() {
        _updateDomain("FiboMetatxForwarder", "0.0.1");
    }

    // this function effectively returns a pointer into the input data
    // thus it relies on the assumption that the input memory will not be modified during the lifetime of the return value
    // because we are using this in a single tightly-scoped scenario below, this is safe
    // however, this approach may not be safe to use elsewhere if the actual string contents need to be copied
    function _extractRevertReason(bool success, bytes memory returndata)
        private
        pure
        returns (string memory)
    {
        string memory reason = "";

        if (success) {
            return reason;
        }

        if (returndata.length < 0x44) {
            return reason;
        }

        uint256 selector;
        uint256 stringOffset;
        uint256 stringLength;

        assembly {
            selector := shr(0xe0, mload(add(returndata, 0x20)))
            stringOffset := mload(add(returndata, 0x24))
            stringLength := mload(add(returndata, 0x44))
        }

        // 0x08c379a0 is the function selector for `Error(string)`, which is the default solidity format for simple revert strings
        // if we don't encounter this exact format, then don't attempt to parse out a string
        if (selector != 0x08c379a0 || stringOffset != 0x20 || stringLength == 0) {
            return reason;
        }

        // according to the solidity abi spec (https://docs.soliditylang.org/en/v0.8.17/abi-spec.html#formal-specification-of-the-encoding)
        // while strings are assumed to use utf-8 encoding, the abi represents them as byte arrays, where the leading length value
        // represents the number of *bytes* in the string, rather than the number of utf-8 characters
        // therefore we can use this value to check the number of bytes to "copy", and return a pointer to that same location
        // in the return data, which uses the same abi that we want for providing this string to the event
        if (returndata.length < (stringLength + 0x44)) {
            return reason;
        }

        assembly {
            reason := add(returndata, 0x44)
        }

        return reason;
    }

    function execute(ForwardRequest calldata req, EOASignature calldata signature)
        public
        returns (bool, bytes memory)
    {
        bytes memory requestData = abi.encode(req.from, req.to, req.nonce, keccak256(req.data));
        bytes32 requestHash = _generateObjectHash(REQUEST_TYPEHASH, requestData);
        require(_verifyEOASignature(requestHash, signature, req.from), "invalid signature");

        require(req.nonce == nonces[req.from], "nonce mismatch");
        nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call(abi.encodePacked(req.data, req.from));

        emit FiboMetatxResult(
            req.from,
            req.nonce,
            success,
            _extractRevertReason(success, returndata)
        );

        return (success, returndata);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol";

import "./signatureTypes.sol";

abstract contract FiboEIP712 {
    string public EIP712_name;
    string public EIP712_version;
    bytes32 internal _domainHash;

    function _updateDomain(string memory contractName, string memory version) internal {
        EIP712_name = contractName;
        EIP712_version = version;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        _domainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(EIP712_name)),
                keccak256(bytes(EIP712_version)),
                chainId,
                address(this)
            )
        );
    }

    function _generateObjectHash(bytes32 typeHash, bytes memory data)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", _domainHash, keccak256(bytes.concat(typeHash, data)))
            );
    }

    function _verifySignature(
        bytes32 typeHash,
        bytes memory data,
        address signer,
        Signature memory signature
    ) internal view returns (bool) {
        bytes32 objectHash = _generateObjectHash(typeHash, data);
        if (signature.sigType == SignatureType.SignatureEOA) {
            EOASignature memory eoaSig = abi.decode(signature.signatureData, (EOASignature));
            return _verifyEOASignature(objectHash, eoaSig, signer);
        } else if (signature.sigType == SignatureType.SignatureContract) {
            return _verifyContractSignature(objectHash, signer);
        } else {
            revert("unknown signature type");
        }
    }

    function _verifyEOASignature(
        bytes32 objectHash,
        EOASignature memory signature,
        address signer
    ) internal pure returns (bool) {
        return signer == ecrecover(objectHash, signature.v, signature.r, signature.s);
    }

    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant EIP1271_MAGICVALUE = 0x1626ba7e;

    // based on eip-1271: https://eips.ethereum.org/EIPS/eip-1271
    function _verifyContractSignature(bytes32 objectHash, address signer)
        internal
        view
        returns (bool)
    {
        bytes memory emptyBytes;
        bytes4 magicValue = IERC1271Upgradeable(signer).isValidSignature(objectHash, emptyBytes);
        return magicValue == EIP1271_MAGICVALUE;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

enum SignatureType {
    SignatureEOA,
    SignatureContract
}

struct EOASignature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

struct Signature {
    SignatureType sigType;
    bytes signatureData;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}