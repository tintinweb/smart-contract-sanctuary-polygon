// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

import './interfaces/IUserProxyFactory.sol';
import './UserProxy.sol';

contract UserProxyFactory is IUserProxyFactory {
    mapping(address => address) public override getProxy;

    // // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    // bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    
    // keccak256("EIP712Domain(string name,string version,address verifyingContract)");
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x91ab3d17e3a50a9d89e63fd30b92be7f5336b03b287bb946787a83a9d62a2766;

    bytes32 public DOMAIN_SEPARATOR;
    string public constant name = 'User Proxy Factory V1';
    string public constant VERSION = "1";

    constructor() {
        // uint chainId;
        // assembly {
        //     chainId := chainid()
        // }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(VERSION)),
                address(this)
            )
        );
    }

    function createProxy(address owner) external override returns (address proxy) {
        require(owner != address(0), 'ZERO_ADDRESS');
        require(getProxy[owner] == address(0), 'PROXY_EXISTS');
        bytes memory bytecode = proxyCreationCode();
        bytes32 salt = keccak256(abi.encodePacked(address(this), owner));
        assembly {
            proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUserProxy(proxy).initialize(owner, DOMAIN_SEPARATOR);
        getProxy[owner] = proxy;
        emit ProxyCreated(owner, proxy);
    }

    function proxyRuntimeCode() public pure returns (bytes memory) {
        return type(UserProxy).runtimeCode;
    }

    function proxyCreationCode() public pure returns (bytes memory) {
        return type(UserProxy).creationCode;
    }

    function proxyCreationCodeHash() public pure returns (bytes32) {
        return keccak256(proxyCreationCode());
    }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

import './interfaces/IUserProxy.sol';
import './libraries/ECDSA.sol';
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract UserProxy is IUserProxy {
    mapping(uint256 => bool) public nonces;

    // keccak256("ExecTransaction(address to,uint256 value,bytes data,uint8 operation,uint256 nonce)");
    bytes32 internal constant EXEC_TX_TYPEHASH = 0xa609e999e2804ed92314c0c662cfdb3c1d8107df2fb6f2e4039093f20d5e6250;
    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    // bytes32(uint256(keccak256('eip1967.proxy.domain')) - 1)
    bytes32 internal constant DOMAIN_SLOT = 0x5d29634e15c15fa29be556decae8ee5a34c9fee5f209623aed08a64bf865b694;

    function initialize(address _owner, bytes32 _DOMAIN_SEPARATOR) external override {
        require(owner() == address(0), 'initialize error');
        require(_owner != address(0), "ERC1967: new owner is the zero address");
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = _owner;
        StorageSlot.getBytes32Slot(DOMAIN_SLOT).value = _DOMAIN_SEPARATOR;
    }

    function owner() public override view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    function domain() public view returns (bytes32) {
        return StorageSlot.getBytes32Slot(DOMAIN_SLOT).value;
    }

    function execTransaction(address to, uint256 value, bytes calldata data, Operation operation, uint256 nonce, bytes memory signature) external override {
        require(!nonces[nonce],"nonce had used");
        nonces[nonce] = true;
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                domain(),
                keccak256(abi.encode(EXEC_TX_TYPEHASH, to, value, keccak256(data), operation, nonce))
            )
        );
        address recoveredAddress = ECDSA.recover(digest, signature);
        require(recoveredAddress != address(0) && recoveredAddress == owner(), "ECDSA: invalid signature");
        execute(to, value, data, operation);
    }

    function execTransaction(address to, uint256 value, bytes calldata data, Operation operation) external override  {
        require(msg.sender == owner(), "ECDSA: invalid signature");
        execute(to, value, data, operation);
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) internal {
        if (operation == Operation.DelegateCall) {
            assembly {
                let result := delegatecall(gas(), to, add(data, 0x20), mload(data), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        } else {
            assembly {
                let result := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        }
    }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IUserProxyFactory {
    event ProxyCreated(address indexed owner, address proxy);
    function getProxy(address owner) external view returns (address proxy);
    function createProxy(address owner) external returns (address proxy);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IUserProxy {
    enum Operation {Call, DelegateCall}
    function owner() external view returns (address);
    function initialize(address,bytes32) external;
    function execTransaction(address,uint256,bytes calldata,Operation, uint256 nonce,bytes memory) external;
    function execTransaction(address,uint256,bytes calldata,Operation) external;
}