/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

abstract contract HandlerContext {
    /**
     * @notice Allows fetching the original caller address.
     * @dev This is only reliable in combination with a FallbackManager that supports this (e.g. Safe contract >=1.3.0).
     *      When using this functionality make sure that the linked _manager (aka msg.sender) supports this.
     *      This function does not rely on a trusted forwarder. Use the returned value only to
     *      check information against the calling manager.
     * @return sender Original caller address.
     */
    function _msgSender() internal pure returns (address sender) {
        // The assembly code is more direct than the Solidity version using `abi.decode`.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    /**
     * @notice Returns the FallbackManager address
     * @return Fallback manager address
     */
    function _manager() internal view returns (address) {
        return msg.sender;
    }
}


contract SafeStorage {
    // From /common/Singleton.sol
    address internal singleton;
    // From /common/ModuleManager.sol
    mapping(address => address) internal modules;
    // From /common/OwnerManager.sol
    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    // From /Safe.sol
    uint256 internal nonce;
    bytes32 internal _deprecatedDomainSeparator;
    mapping(bytes32 => uint256) internal signedMessages;
    mapping(address => mapping(bytes32 => uint256)) internal approvedHashes;
}


/**
 * User Operation struct
 * @param sender the sender account of this request.
 * @param nonce unique value the sender uses to verify it is not a replay.
 * @param initCode if set, the account contract will be created by this constructor/
 * @param callData the method call to execute on this account.
 * @param callGasLimit the gas limit passed to the callData method call.
 * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp.
 * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
 * @param maxFeePerGas same as EIP-1559 gas parameter.
 * @param maxPriorityFeePerGas same as EIP-1559 gas parameter.
 * @param paymasterAndData if set, this field holds the paymaster address and paymaster-specific data. the paymaster will pay for the transaction instead of the sender.
 * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
 */
struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {
    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {
            data := calldataload(userOp)
        }
        return address(uint160(data));
    }

    // Solidity 0.7.6 doesn't support the BASEFEE opcode, so we hardcode it here.
    function getBaseFee() public pure returns (uint256) {
        return 20 gwei;
    }

    // relayer/block builder might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal pure returns (uint256) {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + getBaseFee());
    }

    function calldataKeccak(bytes calldata data) public pure returns (bytes32 ret) {
        assembly {
            let mem := mload(0x40)
            let len := data.length
            calldatacopy(mem, data.offset, len)
            ret := keccak256(mem, len)
        }
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        address sender = getSender(userOp);
        uint256 nonce = userOp.nonce;
        bytes32 hashInitCode = calldataKeccak(userOp.initCode);
        bytes32 hashCallData = calldataKeccak(userOp.callData);
        uint256 callGasLimit = userOp.callGasLimit;
        uint256 verificationGasLimit = userOp.verificationGasLimit;
        uint256 preVerificationGas = userOp.preVerificationGas;
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        bytes32 hashPaymasterAndData = calldataKeccak(userOp.paymasterAndData);

        return
            abi.encode(
                sender,
                nonce,
                hashInitCode,
                hashCallData,
                callGasLimit,
                verificationGasLimit,
                preVerificationGas,
                maxFeePerGas,
                maxPriorityFeePerGas,
                hashPaymasterAndData
            );
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface ISafe {
    function isOwner(address owner) external view returns (bool);

    function execTransactionFromModule(address to, uint256 value, bytes memory data, uint8 operation) external returns (bool success);
}

/// @title SafeEIP4337Diatomic
/// @author Mikhail Mikheev - @mikhailxyz
/// @notice Diatomic implementation of EIP-4337 for the Gnosis Safe, consisting of a module and a fallback handler
contract Test4337ModuleAndHandler is HandlerContext, SafeStorage {
    using UserOperationLib for UserOperation;

    address public immutable myAddress;
    address public immutable entryPoint;

    address internal constant SENTINEL_MODULES = address(0x1);

    constructor(address entryPointAddress) {
        entryPoint = entryPointAddress;
        myAddress = address(this);
    }

    // return value in case of signature failure, with no time-range.
    // equivalent to _packValidationData(true,0,0);
    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    /// @dev Validates user operation provided by the entry point
    /// @param userOp User operation struct
    /// @param userOpHash Hash of the user operation
    /// @param missingAccountFunds Required prefund to execute the operation
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData) {
        address msgSender = _msgSender();
        require(msgSender == entryPoint, "account: not from entrypoint");

        address payable safeAddress = payable(userOp.sender);
        ISafe senderSafe = ISafe(safeAddress);
        address signer = address(0);
        bytes memory signature = userOp.signature;
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash)), v, r, s);
        }
        if (signer == address(0) || !senderSafe.isOwner(signer)) {
            // signature is invalid
            return SIG_VALIDATION_FAILED;
        }

        if (missingAccountFunds != 0) {
            ISafe(senderSafe).execTransactionFromModule(entryPoint, missingAccountFunds, "", 0);
        }
    }

    /// @dev Executes the operation if it was marked as ready to execute during `validateUserOp`
    /// @param to Destination address of transaction
    /// @param value Native token value of transaction
    /// @param data Data payload of transaction.
    function execTransaction(address to, uint256 value, bytes calldata data) external payable {
        // we need to strip out msg.sender address appended by HandlerContext contract from the calldata
        bytes memory callData;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory location
            let pointer := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value - 32 bytes for stripped msg.sender
            mstore(0x40, add(pointer, calldatasize()))
            // Store the size
            mstore(pointer, sub(calldatasize(), 20))
            // Store the data
            calldatacopy(add(pointer, 0x20), 0, sub(calldatasize(), 20))
            // Point the callData to the correct memory location
            callData := pointer
        }

        address msgSender = _msgSender();
        require(msgSender == entryPoint, "account: not from entrypoint");

        address payable safeAddress = payable(msg.sender);
        ISafe safe = ISafe(safeAddress);
        require(safe.execTransactionFromModule(to, value, data, 0), "tx failed");
    }

    function enableMyself() public {
        require(myAddress != address(this), "You need to DELEGATECALL, sir");

        // Module cannot be added twice.
        require(modules[myAddress] == address(0), "GS102");
        modules[myAddress] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = myAddress;
    }
}