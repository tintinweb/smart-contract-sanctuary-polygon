// SPDX-License-Identifier: None
pragma solidity ^0.8.0;
pragma abicoder v2;
import "./Ownable.sol";
import "./IERC20_Escrow.sol";
import "./ECDSA.sol";

contract Escrow is Ownable{
    using ECDSA for bytes32;

    event JobCreated(uint256 jobId, address contractor, address freelancer, uint256 payment, uint256 fees);
    event JobCancelled(uint256 jobId);
    event JobComplete(uint256 jobId);
    event PaymentReleased(uint256 jobId, uint256 paymentToRelease);

    struct Job{
        address freelancer;
        uint96 payment;
    }

    struct JobCreate{
        uint256 jobId;
        address freelancer;
        uint96 payment;
        uint256 fees;
        uint256 startTime;
        uint256 endTime;
    }

    struct JobInteract{
        uint256 jobId;
        uint256 fees;
        uint256 startTime;
        uint256 endTime;
    }

    address public USDT;
    address public SPAY;
    address public feesRegistry;

    bytes32 private constant JOB_CREATION_TYPEHASH =
        keccak256("jobCreation(uint256 jobId,address freelancer,uint256 payment,uint256 fees,uint256 startTime,uint256 endTime)");

    bytes32 private constant JOB_CANCELLATION_TYPEHASH =
        keccak256("jobCancellation(uint256 jobId,uint256 fees,uint256 startTime,uint256 endTime)");

    bytes32 private constant JOB_CLAIM_TYPEHASH =    
        keccak256("jobClaim(uint256 jobId,uint256 fees,uint256 startTime,uint256 endTime)");
        

    bytes32 private DOMAIN_SEPARATOR;
    address platformSigner;


    mapping (uint256 => Job) public job;
    mapping (uint256 => bool) public cancellation;
    mapping (uint256 => bool) public completion;
    mapping (uint256 => uint256) public releasedPayment;
    mapping (uint256 => uint256) public claimedPayment;


    constructor( address _platformSigner, address _USDT, address _SPAY, address _feesRegistry){
    
        platformSigner = _platformSigner;
        USDT = _USDT;
        SPAY= _SPAY;
        feesRegistry = _feesRegistry;

        uint256 chainId;
        assembly {
        chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                //TODO CHANGE
                keccak256(bytes("ProjectName")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    modifier checkJobCreator(uint256 jobId){
        address sender = address(uint160(jobId>>96));
        if(sender != msg.sender) revert("Caller is not owner of job Id");
        _;
    }

    function initializeJob(JobCreate memory jobCreation, bytes memory signature) external checkJobCreator(jobCreation.jobId){
        Job memory _job = Job(jobCreation.freelancer, uint96(jobCreation.payment));
        if(job[jobCreation.jobId].freelancer != address(0)) revert("job id exists");
        require(jobCreation.startTime <= block.timestamp && jobCreation.endTime > block.timestamp, "Invalid Job Creation time");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(JOB_CREATION_TYPEHASH, jobCreation.jobId, jobCreation.freelancer,
                 jobCreation.payment, jobCreation.fees, jobCreation.startTime, jobCreation.endTime))
            )
        );

        address signer = digest.recover(signature);
        require(signer != address(0) && signer == platformSigner, "Invalid signature");

        job[jobCreation.jobId] = _job;

        // Pay USDT
        IERC20(USDT).transferFrom(msg.sender, address(this), jobCreation.payment);

        // Pay SPay
        IERC20(SPAY).transferFrom(msg.sender, feesRegistry, jobCreation.fees);

        emit JobCreated(jobCreation.jobId, msg.sender, jobCreation.freelancer, jobCreation.payment, jobCreation.fees);
    }


    function cancelJob(JobInteract memory jobCancel, bytes memory signature) external checkJobCreator(jobCancel.jobId){
        if(!cancellation[jobCancel.jobId]) revert("Not cancelled by admin");
        if(completion[jobCancel.jobId]) revert("Job already complete");
        require(jobCancel.startTime <= block.timestamp && jobCancel.endTime > block.timestamp, "Invalid Job Cancellation time");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(JOB_CANCELLATION_TYPEHASH, jobCancel.jobId, jobCancel.fees, jobCancel.startTime, jobCancel.endTime))
            )
        );

        address signer = digest.recover(signature);
        require(signer != address(0) && signer == platformSigner,"Invalid signature");

        completion[jobCancel.jobId] = true;

        // Transfer USDT to contractor
        IERC20(USDT).transfer(msg.sender, job[jobCancel.jobId].payment - releasedPayment[jobCancel.jobId]); // remaining amount

        // Pay platform fees
        IERC20(SPAY).transferFrom(msg.sender, feesRegistry, jobCancel.fees);

        emit JobCancelled(jobCancel.jobId);
    }

    function releasePayment(uint256 jobId, uint256 paymentToRelease) external checkJobCreator(jobId){
        if(completion[jobId]) revert ("Job already complete");
        Job memory _job = job[jobId];
        require(releasedPayment[jobId] + paymentToRelease <= _job.payment, "Payment release exceeds job payment");
        if(releasedPayment[jobId] + paymentToRelease == _job.payment) completion[jobId] = true;
        releasedPayment[jobId] += paymentToRelease;
        emit PaymentReleased(jobId,paymentToRelease);
    }

    function claimPayment(JobInteract memory jobClaim, bytes memory signature) external {
        require(claimedPayment[jobClaim.jobId] < releasedPayment[jobClaim.jobId] , "Nothing left to claim");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(JOB_CLAIM_TYPEHASH, jobClaim.jobId, jobClaim.fees, jobClaim.startTime, jobClaim.endTime))
            )
        );

        address signer = digest.recover(signature);
        require(signer != address(0) && signer == platformSigner, "Invalid signature");

        Job memory _job = job[jobClaim.jobId];
        uint256 paymentToClaim = releasedPayment[jobClaim.jobId] - claimedPayment[jobClaim.jobId];
        claimedPayment[jobClaim.jobId] = releasedPayment[jobClaim.jobId];

        // Get paid
        IERC20(USDT).transfer(_job.freelancer, paymentToClaim);

        // Pay fees in SPay
        IERC20(SPAY).transferFrom(_job.freelancer, address(this), jobClaim.fees);
    }

    function cancelJobAdmin(uint256 jobId) external onlyOwner{
        cancellation[jobId] = true;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20{
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    function transfer(address _to, uint _value) external;
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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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