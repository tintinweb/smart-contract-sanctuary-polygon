//  SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import './interfaces/IUserProxy.sol';
import './libraries/ECDSA.sol';

contract UserProxy is IUserProxy {
    address public override factory;
    address public override owner;
    mapping(uint256 => bool) public nonces;

    string public constant name = 'User Proxy V1';
    string public constant VERSION = "1";

    // keccak256("ExecTransaction(address to,uint256 value,bytes data,uint8 operation,uint256 nonce)");
    bytes32 public constant EXEC_TX_TYPEHASH = 0xa609e999e2804ed92314c0c662cfdb3c1d8107df2fb6f2e4039093f20d5e6250;
    bytes32 public DOMAIN_SEPARATOR;

    constructor() public {
        factory = msg.sender;
    }

    function initialize(address _owner, bytes32 _DOMAIN_SEPARATOR) external override {
        require(msg.sender == factory, 'FORBIDDEN');
        owner = _owner;
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    function execTransaction(address to, uint256 value, bytes calldata data, Operation operation, uint256 nonce,bytes memory signature) external override {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(EXEC_TX_TYPEHASH, to, value, keccak256(data), operation, nonce))
            )
        );
        require(!nonces[nonce],"nonce had used");
        nonces[nonce] = true;
        address recoveredAddress = ECDSA.recover(digest, signature);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "ECDSA: invalid signature");
        require(execute(to, value, data, operation), "call error");
    }

    function execTransaction(address to, uint256 value, bytes calldata data, Operation operation) external override  {
        require(msg.sender == owner, "ECDSA: invalid signature");
        require(execute(to, value, data, operation), "call error");
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) internal returns (bool success) {
        if (operation == Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(gas(), to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }

}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * NOTE: This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

//  SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUserProxy {
    enum Operation {Call, DelegateCall}
    function factory() external view returns (address);
    function owner() external view returns (address);
    function initialize(address,bytes32) external;
    function execTransaction(address,uint256,bytes calldata,Operation, uint256 nonce,bytes memory) external;
    function execTransaction(address,uint256,bytes calldata,Operation) external;
}