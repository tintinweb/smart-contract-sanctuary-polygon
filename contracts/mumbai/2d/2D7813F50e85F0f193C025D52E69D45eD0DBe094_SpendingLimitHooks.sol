// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

/**
 * returned data from validateUserOp.
 * validateUserOp returns a uint256, with is created by `_packedValidationData` and parsed by `_parseValidationData`
 * @param aggregator - address(0) - the account validated the signature by itself.
 *              address(1) - the account failed to validate the signature.
 *              otherwise - this is an address of a signature aggregator that must be used to validate the signature.
 * @param validAfter - this UserOp is valid only after this timestamp.
 * @param validaUntil - this UserOp is valid only up to this timestamp.
 */
    struct ValidationData {
        address aggregator;
        uint48 validAfter;
        uint48 validUntil;
    }

//extract sigFailed, validAfter, validUntil.
// also convert zero validUntil to type(uint48).max
    function _parseValidationData(uint validationData) pure returns (ValidationData memory data) {
        address aggregator = address(uint160(validationData));
        uint48 validUntil = uint48(validationData >> 160);
        if (validUntil == 0) {
            validUntil = type(uint48).max;
        }
        uint48 validAfter = uint48(validationData >> (48 + 160));
        return ValidationData(aggregator, validAfter, validUntil);
    }

// intersect account and paymaster ranges.
    function _intersectTimeRange(uint256 validationData, uint256 paymasterValidationData) pure returns (ValidationData memory) {
        ValidationData memory accountValidationData = _parseValidationData(validationData);
        ValidationData memory pmValidationData = _parseValidationData(paymasterValidationData);
        address aggregator = accountValidationData.aggregator;
        if (aggregator == address(0)) {
            aggregator = pmValidationData.aggregator;
        }
        uint48 validAfter = accountValidationData.validAfter;
        uint48 validUntil = accountValidationData.validUntil;
        uint48 pmValidAfter = pmValidationData.validAfter;
        uint48 pmValidUntil = pmValidationData.validUntil;

        if (validAfter < pmValidAfter) validAfter = pmValidAfter;
        if (validUntil > pmValidUntil) validUntil = pmValidUntil;
        return ValidationData(aggregator, validAfter, validUntil);
    }

/**
 * helper to pack the return value for validateUserOp
 * @param data - the ValidationData to pack
 */
    function _packValidationData(ValidationData memory data) pure returns (uint256) {
        return uint160(data.aggregator) | (uint256(data.validUntil) << 160) | (uint256(data.validAfter) << (160 + 48));
    }

/**
 * helper to pack the return value for validateUserOp, when not using an aggregator
 * @param sigFailed - true for signature failure, false for success
 * @param validUntil last timestamp this UserOperation is valid (or zero for infinite)
 * @param validAfter first timestamp this UserOperation is valid
 */
    function _packValidationData(bool sigFailed, uint48 validUntil, uint48 validAfter) pure returns (uint256) {
        return (sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48));
    }

/**
 * keccak function over calldata.
 * @dev copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.
 */
    function calldataKeccak(bytes calldata data) pure returns (bytes32 ret) {
        assembly {
            let mem := mload(0x40)
            let len := data.length
            calldatacopy(mem, data.offset, len)
            ret := keccak256(mem, len)
        }
    }

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

interface IAccount {

    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     * signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
     * This allows making a "simulation call" without a valid signature
     * Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param userOpHash hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     * @return validationData packaged ValidationData structure. use `_packValidationData` and `_unpackValidationData` to encode and decode
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If an account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external returns (uint256 validationData);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

/**
 * Aggregated Signatures validator.
 */
interface IAggregator {

    /**
     * validate aggregated signature.
     * revert if the aggregated signature does not match the given list of operations.
     */
    function validateSignatures(UserOperation[] calldata userOps, bytes calldata signature) external view;

    /**
     * validate signature of a single userOp
     * This method is should be called by bundler after EntryPoint.simulateValidation() returns (reverts) with ValidationResultWithAggregation
     * First it validates the signature over the userOp. Then it returns data to be used when creating the handleOps.
     * @param userOp the userOperation received from the user.
     * @return sigForUserOp the value to put into the signature field of the userOp when calling handleOps.
     *    (usually empty, unless account and aggregator support some kind of "multisig"
     */
    function validateUserOpSignature(UserOperation calldata userOp)
    external view returns (bytes memory sigForUserOp);

    /**
     * aggregate multiple signatures into a single value.
     * This method is called off-chain to calculate the signature to pass with handleOps()
     * bundler MAY use optimized custom code perform this aggregation
     * @param userOps array of UserOperations to collect the signatures from.
     * @return aggregatedSignature the aggregated signature
     */
    function aggregateSignatures(UserOperation[] calldata userOps) external view returns (bytes memory aggregatedSignature);
}

/**
 ** Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 ** Only one instance required on each chain.
 **/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./UserOperation.sol";
import "./IStakeManager.sol";
import "./IAggregator.sol";
import "./INonceManager.sol";

interface IEntryPoint is IStakeManager, INonceManager {

    /***
     * An event emitted after each successful request
     * @param userOpHash - unique identifier for the request (hash its entire content, except signature).
     * @param sender - the account that generates this request.
     * @param paymaster - if non-null, the paymaster that pays for this request.
     * @param nonce - the nonce value from the request.
     * @param success - true if the sender transaction succeeded, false if reverted.
     * @param actualGasCost - actual amount paid (by account or paymaster) for this UserOperation.
     * @param actualGasUsed - total gas used by this UserOperation (including preVerification, creation, validation and execution).
     */
    event UserOperationEvent(bytes32 indexed userOpHash, address indexed sender, address indexed paymaster, uint256 nonce, bool success, uint256 actualGasCost, uint256 actualGasUsed);

    /**
     * account "sender" was deployed.
     * @param userOpHash the userOp that deployed this account. UserOperationEvent will follow.
     * @param sender the account that is deployed
     * @param factory the factory used to deploy this account (in the initCode)
     * @param paymaster the paymaster used by this UserOp
     */
    event AccountDeployed(bytes32 indexed userOpHash, address indexed sender, address factory, address paymaster);

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length
     * @param userOpHash the request unique identifier.
     * @param sender the sender of this request
     * @param nonce the nonce used in the request
     * @param revertReason - the return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

    /**
     * an event emitted by handleOps(), before starting the execution loop.
     * any event emitted before this event, is part of the validation.
     */
    event BeforeExecution();

    /**
     * signature aggregator used by the following UserOperationEvents within this bundle.
     */
    event SignatureAggregatorChanged(address indexed aggregator);

    /**
     * a custom revert error of handleOps, to identify the offending op.
     *  NOTE: if simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
     *  @param opIndex - index into the array of ops to the failed one (in simulateValidation, this is always zero)
     *  @param reason - revert reason
     *      The string starts with a unique code "AAmn", where "m" is "1" for factory, "2" for account and "3" for paymaster issues,
     *      so a failure can be attributed to the correct entity.
     *   Should be caught in off-chain handleOps simulation and not happen on-chain.
     *   Useful for mitigating DoS attempts against batchers or for troubleshooting of factory/account/paymaster reverts.
     */
    error FailedOp(uint256 opIndex, string reason);

    /**
     * error case when a signature aggregator fails to verify the aggregated signature it had created.
     */
    error SignatureValidationFailed(address aggregator);

    /**
     * Successful result from simulateValidation.
     * @param returnInfo gas and time-range returned values
     * @param senderInfo stake information about the sender
     * @param factoryInfo stake information about the factory (if any)
     * @param paymasterInfo stake information about the paymaster (if any)
     */
    error ValidationResult(ReturnInfo returnInfo,
        StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo);

    /**
     * Successful result from simulateValidation, if the account returns a signature aggregator
     * @param returnInfo gas and time-range returned values
     * @param senderInfo stake information about the sender
     * @param factoryInfo stake information about the factory (if any)
     * @param paymasterInfo stake information about the paymaster (if any)
     * @param aggregatorInfo signature aggregation info (if the account requires signature aggregator)
     *      bundler MUST use it to verify the signature, or reject the UserOperation
     */
    error ValidationResultWithAggregation(ReturnInfo returnInfo,
        StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo,
        AggregatorStakeInfo aggregatorInfo);

    /**
     * return value of getSenderAddress
     */
    error SenderAddressResult(address sender);

    /**
     * return value of simulateHandleOp
     */
    error ExecutionResult(uint256 preOpGas, uint256 paid, uint48 validAfter, uint48 validUntil, bool targetSuccess, bytes targetResult);

    //UserOps handled, per aggregator
    struct UserOpsPerAggregator {
        UserOperation[] userOps;

        // aggregator address
        IAggregator aggregator;
        // aggregated signature
        bytes signature;
    }

    /**
     * Execute a batch of UserOperation.
     * no signature aggregator is used.
     * if any account requires an aggregator (that is, it returned an aggregator when
     * performing simulateValidation), then handleAggregatedOps() must be used instead.
     * @param ops the operations to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;

    /**
     * Execute a batch of UserOperation with Aggregators
     * @param opsPerAggregator the operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts)
     * @param beneficiary the address to receive the fees
     */
    function handleAggregatedOps(
        UserOpsPerAggregator[] calldata opsPerAggregator,
        address payable beneficiary
    ) external;

    /**
     * generate a request Id - unique identifier for this request.
     * the request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     */
    function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32);

    /**
     * Simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.
     * @dev this method always revert. Successful result is ValidationResult error. other errors are failures.
     * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the account's data.
     * @param userOp the user operation to validate.
     */
    function simulateValidation(UserOperation calldata userOp) external;

    /**
     * gas and return values during simulation
     * @param preOpGas the gas used for validation (including preValidationGas)
     * @param prefund the required prefund for this operation
     * @param sigFailed validateUserOp's (or paymaster's) signature check failed
     * @param validAfter - first timestamp this UserOp is valid (merging account and paymaster time-range)
     * @param validUntil - last timestamp this UserOp is valid (merging account and paymaster time-range)
     * @param paymasterContext returned by validatePaymasterUserOp (to be passed into postOp)
     */
    struct ReturnInfo {
        uint256 preOpGas;
        uint256 prefund;
        bool sigFailed;
        uint48 validAfter;
        uint48 validUntil;
        bytes paymasterContext;
    }

    /**
     * returned aggregated signature info.
     * the aggregator returned by the account, and its current stake.
     */
    struct AggregatorStakeInfo {
        address aggregator;
        StakeInfo stakeInfo;
    }

    /**
     * Get counterfactual sender address.
     *  Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
     * this method always revert, and returns the address in SenderAddressResult error
     * @param initCode the constructor code to be passed into the UserOperation.
     */
    function getSenderAddress(bytes memory initCode) external;


    /**
     * simulate full execution of a UserOperation (including both validation and target execution)
     * this method will always revert with "ExecutionResult".
     * it performs full validation of the UserOperation, but ignores signature error.
     * an optional target address is called after the userop succeeds, and its value is returned
     * (before the entire call is reverted)
     * Note that in order to collect the the success/failure of the target call, it must be executed
     * with trace enabled to track the emitted events.
     * @param op the UserOperation to simulate
     * @param target if nonzero, a target address to call after userop simulation. If called, the targetSuccess and targetResult
     *        are set to the return from that call.
     * @param targetCallData callData to pass to target address
     */
    function simulateHandleOp(UserOperation calldata op, address target, bytes calldata targetCallData) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface INonceManager {

    /**
     * Return the next nonce for this sender.
     * Within a given key, the nonce values are sequenced (starting with zero, and incremented by one on each userop)
     * But UserOp with different keys can come with arbitrary order.
     *
     * @param sender the account address
     * @param key the high 192 bit of the nonce
     * @return nonce a full nonce to pass for next UserOp with this sender.
     */
    function getNonce(address sender, uint192 key)
    external view returns (uint256 nonce);

    /**
     * Manually increment the nonce of the sender.
     * This method is exposed just for completeness..
     * Account does NOT need to call it, neither during validation, nor elsewhere,
     * as the EntryPoint will update the nonce regardless.
     * Possible use-case is call it with various keys to "initialize" their nonces to one, so that future
     * UserOperations will not pay extra for the first transaction with a given key.
     */
    function incrementNonce(uint192 key) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a paymaster or an account)
 * stake is value locked for at least "unstakeDelay" by the staked entity.
 */
interface IStakeManager {

    event Deposited(
        address indexed account,
        uint256 totalDeposit
    );

    event Withdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /// Emitted when stake or unstake delay are modified
    event StakeLocked(
        address indexed account,
        uint256 totalStaked,
        uint256 unstakeDelaySec
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(
        address indexed account,
        uint256 withdrawTime
    );

    event StakeWithdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /**
     * @param deposit the entity's deposit
     * @param staked true if this entity is staked.
     * @param stake actual amount of ether staked for this entity.
     * @param unstakeDelaySec minimum delay to withdraw the stake.
     * @param withdrawTime - first block timestamp where 'withdrawStake' will be callable, or zero if already locked
     * @dev sizes were chosen so that (deposit,staked, stake) fit into one cell (used during handleOps)
     *    and the rest fit into a 2nd cell.
     *    112 bit allows for 10^15 eth
     *    48 bit for full timestamp
     *    32 bit allows 150 years for unstake delay
     */
    struct DepositInfo {
        uint112 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint48 withdrawTime;
    }

    //API struct used by getStakeInfo and simulateValidation
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelaySec;
    }

    /// @return info - full deposit information of given account
    function getDepositInfo(address account) external view returns (DepositInfo memory info);

    /// @return the deposit (for gas payment) of the account
    function balanceOf(address account) external view returns (uint256);

    /**
     * add to the deposit of the given account
     */
    function depositTo(address account) external payable;

    /**
     * add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param _unstakeDelaySec the new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 _unstakeDelaySec) external payable;

    /**
     * attempt to unlock the stake.
     * the value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external;

    /**
     * withdraw from the (unlocked) stake.
     * must first call unlockStake and wait for the unstakeDelay to pass
     * @param withdrawAddress the address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external;

    /**
     * withdraw from the deposit.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

import {calldataKeccak} from "../core/Helpers.sol";

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
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/block builder might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
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

        return abi.encode(
            sender, nonce,
            hashInitCode, hashCallData,
            callGasLimit, verificationGasLimit, preVerificationGas,
            maxFeePerGas, maxPriorityFeePerGas,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        InvalidSignatureV // Deprecated in v4.8
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
            return tryRecover(hash, v, r, s);
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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@aa-template/contracts/interfaces/IEntryPoint.sol";
import "../common/SelfAuthorized.sol";

abstract contract EntryPointManager is SelfAuthorized {
    /**
     * @dev The ERC-4337 entrypoint address, it's hardcoded in implementation
     * contract for gas efficiency. Upgrading to a new version of entrypoint
     * requires replacing the implementation contract
     */
    address private immutable _entryPoint;

    modifier onlyFromEntryPoint() {
        _requireFromEntryPoint();
        _;
    }

    constructor(address newEntryPoint) {
        _entryPoint = newEntryPoint;
    }

    /**
     * ensure the request comes from the known entrypoint.
     */
    function _requireFromEntryPoint() internal view virtual {
        require(msg.sender == _entryPoint, "account: not from EntryPoint");
    }

    /**
     * Helper for wallet to get the next nonce.
     */
    function getNonce(uint192 key) public view returns (uint256) {
        return IEntryPoint(_entryPoint).getNonce(address(this), key);
    }

    /**
     * Get the entrypoint address
     */
    function entryPoint() public view returns (address) {
        return _entryPoint;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import "../common/SelfAuthorized.sol";
import "../common/NativeCurrencyPaymentFallback.sol";

/**
 * @title Fallback Manager - A contract managing fallback calls made to this contract
 * @author Richard Meissner - @rmeissner
 */
abstract contract FallbackManager is NativeCurrencyPaymentFallback, SelfAuthorized {
    event ChangedFallbackHandler(address indexed handler);

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT =
        0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    /**
     *  @notice Internal function to set the fallback handler.
     *  @param handler contract to handle fallback calls.
     */
    function internalSetFallbackHandler(address handler) internal {
        /*
            If a fallback handler is set to self, then the following attack vector is opened:
            Imagine we have a function like this:
            function withdraw() internal authorized {
                withdrawalAddress.call.value(address(this).balance)("");
            }

            If the fallback method is triggered, the fallback handler appends the msg.sender address to the calldata and calls the fallback handler.
            A potential attacker could call a Safe with the 3 bytes signature of a withdraw function. Since 3 bytes do not create a valid signature,
            the call would end in a fallback handler. Since it appends the msg.sender address to the calldata, the attacker could craft an address 
            where the first 3 bytes of the previous calldata + the first byte of the address make up a valid function signature. The subsequent call would result in unsanctioned access to Safe's internal protected methods.
            For some reason, solidity matches the first 4 bytes of the calldata to a function signature, regardless if more data follow these 4 bytes.
        */
        require(handler != address(this), "GS400");

        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler)
        }
    }

    /**
     * @notice Set Fallback Handler to `handler` for the Safe.
     * @dev Only fallback calls without value and with data will be forwarded.
     *      This can only be done via a Safe transaction.
     *      Cannot be set to the Safe itself.
     * @param handler contract to handle fallback calls.
     */
    function setFallbackHandler(address handler) public authorized {
        internalSetFallbackHandler(handler);
        emit ChangedFallbackHandler(handler);
    }

    // @notice Forwards all calls to the fallback handler if set. Returns 0 if no handler is set.
    // @dev Appends the non-padded caller address to the calldata to be optionally used in the handler
    //      The handler can make us of `HandlerContext.sol` to extract the address.
    //      This is done because in the next call frame the `msg.sender` will be FallbackManager's address
    //      and having the original caller address may enable additional verification scenarios.
    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../common/SelfAuthorized.sol";
import "../common/Enum.sol";
import "../library/AddressLinkedList.sol";
import "../interface/IHooks.sol";

/**
 * @title HooksManager
 * @dev A contract managing hooks for transaction execution in a Versa wallet.
 * @notice Hooks are wallet extensions that can be executed before and after each transaction in a Versa wallet.
 * Hooks provide additional functionality and customization options for transaction processing.
 * It is important to only enable trusted and audited hooks to prevent potential security risks.
 */
abstract contract HooksManager is SelfAuthorized {
    using AddressLinkedList for mapping(address => address);

    event EnabledHooks(address indexed hooks);
    event DisabledHooks(address indexed hooks);
    event DisabledHooksWithError(address indexed hooks);

    mapping(address => address) internal beforeTxHooks;
    mapping(address => address) internal afterTxHooks;

    /**
     * @dev Enable hooks for a versa wallet.
     * @param hooks The address of the `hooks` contract.
     * @param initData Initialization data for the `hooks` contract.
     */
    function enableHooks(address hooks, bytes memory initData) public authorized {
        _enableHooks(hooks, initData);
    }

    /**
     * @dev Disable `hooks` for a versa wallet.
     * @param prevBeforeTxHooks The address of the previous preTxHook in the linked list, will
     * be unused if the `hooks` contract doesn't have a preTxHook.
     * @param prevAfterTxHooks The address of the previous afterTxHook in the linked list.will
     * be unused if the `hooks` contract doesn't have a afterTxHook.
     * @param hooks The address of the `hooks` contract to be disabled.
     */
    function disableHooks(address prevBeforeTxHooks, address prevAfterTxHooks, address hooks) public authorized {
        _disableHooks(prevBeforeTxHooks, prevAfterTxHooks, hooks);
    }

    /**
     * @dev Check if hooks are enabled for a versa wallet.
     * @param hooks The address of the hooks contract.
     * @return enabled True if hooks are enabled for the contract.
     */
    function isHooksEnabled(address hooks) public view returns (bool enabled) {
        bool isBeforeHookExist = beforeTxHooks.isExist(hooks);
        bool isAfterHookExist = afterTxHooks.isExist(hooks);

        if (isBeforeHookExist || isAfterHookExist) {
            uint256 hasHooks = IHooks(hooks).hasHooks();
            if ((uint128(hasHooks) == 1 && !isAfterHookExist) || ((hasHooks >> 128) == 1 && !isBeforeHookExist)) {
                return false;
            }
            return true;
        }
    }

    /**
     * @dev Get a paginated array of before transaction hooks.
     * @param start The start of the page. Must be a hooks or start pointer (0x1 address).
     * @param pageSize The maximum number of hooks to be returned. Must be > 0.
     * @return array An array of hooks.
     */
    function getPreHooksPaginated(address start, uint256 pageSize) external view returns (address[] memory array) {
        return beforeTxHooks.list(start, pageSize);
    }

    /**
     * @dev Get a paginated array of after transaction hooks.
     * @param start The start of the page. Must be a hooks or start pointer (0x1 address).
     * @param pageSize The maximum number of hooks to be returned. Must be > 0.
     * @return array An array of hooks.
     */
    function getPostHooksPaginated(address start, uint256 pageSize) external view returns (address[] memory array) {
        return afterTxHooks.list(start, pageSize);
    }

    function hooksSize() external view returns (uint256 beforeTxHooksSize, uint256 afterTxHooksSize) {
        beforeTxHooksSize = beforeTxHooks.size();
        afterTxHooksSize = afterTxHooks.size();
    }

    /**
     * @dev Internal function to enable hooks for a versa wallet.
     * @param hooks The address of the hooks contract.
     * @param initData Initialization data for the hooks contract.
     */
    function _enableHooks(address hooks, bytes memory initData) internal {
        // Add hooks to linked list
        require(IHooks(hooks).supportsInterface(type(IHooks).interfaceId), "Not a valid hooks contract");
        uint256 hasHooks = IHooks(hooks).hasHooks();
        if (hasHooks >> 128 == 1) {
            beforeTxHooks.add(hooks);
        }
        if (uint128(hasHooks) == 1) {
            afterTxHooks.add(hooks);
        }
        // Initialize wallet configurations
        IHooks(hooks).initWalletConfig(initData);
        emit EnabledHooks(hooks);
    }

    /**
     * @dev Internal function to disable hooks for a specific contract.
     * @param prevBeforeTxHook The previous before transaction hooks contract address in the linked list.
     * @param prevAfterTxHooks The previous after transaction hooks contract address in the linked list.
     * @param hooks The address of the hooks contract to be disabled.
     */
    function _disableHooks(address prevBeforeTxHook, address prevAfterTxHooks, address hooks) internal {
        // Try to clear wallet configurations
        try IHooks(hooks).clearWalletConfig() {
            emit DisabledHooks(hooks);
        } catch {
            emit DisabledHooksWithError(hooks);
        }
        // Remove hooks from exsiting linked list
        uint256 hasHooks = IHooks(hooks).hasHooks();
        if (hasHooks >> 128 == 1) {
            beforeTxHooks.remove(prevBeforeTxHook, hooks);
        }
        if (uint128(hasHooks) == 1) {
            afterTxHooks.remove(prevAfterTxHooks, hooks);
        }
    }

    /**
     * @dev Loop through the beforeTransactionHooks list and execute all before transaction hooks.
     * @param to The address of the transaction recipient.
     * @param value The value of the transaction.
     * @param data The data of the transaction.
     * @param operation The type of operation being performed.
     */
    function _beforeTransaction(address to, uint256 value, bytes memory data, Enum.Operation operation) internal {
        address addr = beforeTxHooks[AddressLinkedList.SENTINEL_ADDRESS];
        while (uint160(addr) > AddressLinkedList.SENTINEL_UINT) {
            {
                address hooks = addr;
                IHooks(hooks).beforeTransaction(to, value, data, operation);
            }
            addr = beforeTxHooks[addr];
        }
    }

    /**
     * @dev Loop through the afterTransactionHooks list and execute all after transaction hooks.
     * @param to The address of the transaction recipient.
     * @param value The value of the transaction.
     * @param data The data of the transaction.
     * @param operation The type of operation being performed.
     */
    function _afterTransaction(address to, uint256 value, bytes memory data, Enum.Operation operation) internal {
        address addr = afterTxHooks[AddressLinkedList.SENTINEL_ADDRESS];
        while (uint160(addr) > AddressLinkedList.SENTINEL_UINT) {
            {
                address hooks = addr;
                IHooks(hooks).afterTransaction(to, value, data, operation);
            }
            addr = afterTxHooks[addr];
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "../common/Executor.sol";
import "../interface/IModule.sol";
import "../library/AddressLinkedList.sol";

/**
 * @title Module Manager
 * @dev A contract managing Versa modules.
 * @notice Modules are extensions with unlimited access to a Wallet that can be added to a Wallet by its super users.
 * ⚠️ WARNING: Modules are a security risk since they can execute arbitrary transactions, so only trusted and audited
 *   modules should be added to a Versa wallet. A malicious module can completely take over a Versa wallet.
 */
abstract contract ModuleManager is Executor, SelfAuthorized {
    using AddressLinkedList for mapping(address => address);

    event EnabledModule(address indexed module);
    event DisabledModule(address indexed module);
    event DisabledModuleWithError(address indexed module);

    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    mapping(address => address) internal modules;

    /**
     * @notice Enables the module `module` for the Versa Wallet.
     * @dev This can only be done via a Versa Wallet transaction.
     * @param module The module to be enabled.
     * @param initData Initialization data for the module.
     */
    function enableModule(address module, bytes memory initData) public authorized {
        _enableModule(module, initData);
    }

    /**
     * @notice Disables the module `module` for the Versa Wallet.
     * @dev This can only be done via a Versa Wallet transaction.
     * @param prevModule The address of the previous module in the modules linked list.
     * @param module The module to be disabled.
     */
    function disableModule(address prevModule, address module) public authorized {
        _disableModule(prevModule, module);
    }

    /**
     * @notice Execute `operation` (0: Call, 1: DelegateCall) to `to` with `value` (Native Token).
     * @dev This function is marked as virtual to allow overriding for L2 singleton to emit an event for indexing.
     * @notice Subclasses must override `_isPluginEnabled` to ensure the plugin is enabled.
     * @param to Destination address of the module transaction.
     * @param value Ether value of the module transaction.
     * @param data Data payload of the module transaction.
     * @param operation Operation type of the module transaction.
     * @return success Boolean flag indicating if the call succeeded.
     */
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public virtual returns (bool success) {
        require(_isModuleEnabled(msg.sender), "Only enabled module");
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, type(uint256).max);
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /**
     * @notice Execute `operation` (0: Call, 1: DelegateCall) to `to` with `value` (Native Token) and return data.
     * @param to Destination address of the module transaction.
     * @param value Ether value of the module transaction.
     * @param data Data payload of the module transaction.
     * @param operation Operation type of the module transaction.
     * @return success Boolean flag indicating if the call succeeded.
     * @return returnData Data returned by the call.
     */
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation);
        returnData = getReturnData(type(uint256).max);
    }

    /**
     * @notice Checks if a module is enabled for the Versa Wallet.
     * @return True if the module is enabled, false otherwise.
     */
    function isModuleEnabled(address module) public view returns (bool) {
        return _isModuleEnabled(module);
    }

    /**
     * @notice Returns an array of modules.
     * @param start The start of the page. Must be a module or start pointer (0x1 address).
     * @param pageSize The maximum number of modules to be returned. Must be > 0.
     * @return array An array of modules.
     */
    function getModulesPaginated(address start, uint256 pageSize) external view returns (address[] memory array) {
        return modules.list(start, pageSize);
    }

    function moduleSize() external view returns (uint256) {
        return modules.size();
    }

    /**
     * @dev Internal function to enable a module for the Versa Wallet.
     * @param module The module to be enabled.
     * @param initData Initialization data for the module.
     */
    function _enableModule(address module, bytes memory initData) internal {
        require(IModule(module).supportsInterface(type(IModule).interfaceId), "Not a module");
        modules.add(module);
        IModule(module).initWalletConfig(initData);
        emit EnabledModule(module);
    }

    /**
     * @dev Internal function to disable a module for the Versa Wallet.
     * @param prevModule The address of the previous module in the modules linked list.
     * @param module The module to be disabled.
     */
    function _disableModule(address prevModule, address module) internal {
        try IModule(module).clearWalletConfig() {
            emit DisabledModule(module);
        } catch {
            emit DisabledModuleWithError(module);
        }
        modules.remove(prevModule, module);
    }

    /**
     * @dev Internal function to check if a module is enabled for the Versa Wallet.
     * @return True if the module is enabled, false otherwise.
     */
    function _isModuleEnabled(address module) internal view returns (bool) {
        return modules.isExist(module);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../common/SelfAuthorized.sol";
import "../library/AddressLinkedList.sol";
import "../interface/IValidator.sol";

/**
 * @title ValidatorManager
 * @notice The validator is an extension of a `module` which implements `IValidator` interface
 * The validators are classified as "sudo" or "normal" based on their security level. If a
 * signature passes the authentication of a sudo validator, then the operation being signed
 * will have full permissions of the wallet. Otherwise it will only have limited access.
 * ⚠️ WARNING: A wallet MUST always have at least one sudo validator.
 */
abstract contract ValidatorManager is SelfAuthorized {
    using AddressLinkedList for mapping(address => address);

    event EnabledValidator(address indexed validator);
    event DisabledValidator(address indexed validator);
    event DisabledValidatorWithError(address indexed validator);

    enum ValidatorType {
        Disabled,
        Sudo,
        Normal
    }

    mapping(address => address) internal sudoValidators;
    mapping(address => address) internal normalValidators;

    /**
     * @notice Enables the validator `validator` for the Versa Wallet with the specified `validatorType`.
     * @dev This can only be done via a Versa Wallet transaction.
     * @param validator The validator to be enabled.
     * @param validatorType The type of the validator (Sudo or Normal).
     * @param initData Initialization data for the validator contract.
     */
    function enableValidator(address validator, ValidatorType validatorType, bytes memory initData) public authorized {
        _enableValidator(validator, validatorType, initData);
    }

    /**
     * @notice Disables the validator `validator` for the Versa Wallet.
     * @dev This can only be done via a Versa Wallet transaction.
     * @param prevValidator The previous validator in the validators linked list.
     * @param validator The validator to be removed.
     */
    function disableValidator(address prevValidator, address validator) public authorized {
        _disableValidator(prevValidator, validator);
    }

    /**
     * @notice Toggles the type of the validator `validator` between Sudo and Normal.
     * @dev This can only be done via a Versa Wallet transaction.
     * @param prevValidator The previous validator in the validators linked list.
     * @param validator The validator to toggle the type.
     */
    function toggleValidatorType(address prevValidator, address validator) public authorized {
        _toggleValidatorType(prevValidator, validator);
    }

    function validatorSize() external view returns (uint256 sudoSize, uint256 normalSize) {
        sudoSize = sudoValidators.size();
        normalSize = normalValidators.size();
    }

    /**
     * @notice Returns the type of the validator `validator`.
     * @param validator The validator to check.
     * @return The type of the validator (Disabled, Sudo, or Normal).
     */
    function getValidatorType(address validator) public view returns (ValidatorType) {
        if (normalValidators.isExist(validator)) {
            return ValidatorType.Normal;
        } else if (sudoValidators.isExist(validator)) {
            return ValidatorType.Sudo;
        } else {
            return ValidatorType.Disabled;
        }
    }

    /**
     * @notice Checks if the validator `validator` is enabled.
     * @param validator The validator to check.
     * @return True if the validator is enabled, false otherwise.
     */
    function isValidatorEnabled(address validator) public view returns (bool) {
        if (getValidatorType(validator) != ValidatorType.Disabled) {
            return true;
        }
        return false;
    }

    /**
     * @notice Returns an array of validators based on the specified `validatorType`.
     * @param start Start of the page. Has to be a validator or start pointer (0x1 address).
     * @param pageSize Maximum number of validators that should be returned. Must be greater than 0.
     * @param validatorType The type of validators to retrieve (Sudo or Normal).
     * @return array An array of validators.
     */
    function getValidatorsPaginated(
        address start,
        uint256 pageSize,
        ValidatorType validatorType
    ) external view returns (address[] memory array) {
        require(validatorType != ValidatorType.Disabled, "Only valid validators");

        if (validatorType == ValidatorType.Sudo) {
            return sudoValidators.list(start, pageSize);
        } else if (validatorType == ValidatorType.Normal) {
            return normalValidators.list(start, pageSize);
        }
    }

    /**
     * @notice Internal function to enable a validator with the specified type and initialization data.
     * @param validator The validator to be enabled.
     * @param validatorType The type of the validator (Sudo or Normal).
     * @param initData Initialization data for the validator contract.
     */
    function _enableValidator(address validator, ValidatorType validatorType, bytes memory initData) internal {
        require(
            validatorType != ValidatorType.Disabled &&
                IValidator(validator).supportsInterface(type(IValidator).interfaceId),
            "Only valid validator allowed"
        );
        require(
            !sudoValidators.isExist(validator) && !normalValidators.isExist(validator),
            "Validator has already been added"
        );

        if (validatorType == ValidatorType.Sudo) {
            sudoValidators.add(validator);
        } else {
            normalValidators.add(validator);
        }

        IValidator(validator).initWalletConfig(initData);
        emit EnabledValidator(validator);
    }

    /**
     * @notice Internal function to disable a validator from the Versa Wallet.
     * @param prevValidator The previous validator in the validators linked list.
     * @param validator The validator to be disabled.
     */
    function _disableValidator(address prevValidator, address validator) internal {
        try IValidator(validator).clearWalletConfig() {
            emit DisabledValidator(validator);
        } catch {
            emit DisabledValidatorWithError(validator);
        }
        if (sudoValidators.isExist(validator)) {
            sudoValidators.remove(prevValidator, validator);
            _checkRemovingSudoValidator();
        } else if (normalValidators.isExist(validator)) {
            normalValidators.remove(prevValidator, validator);
        } else {
            revert("Validator doesn't exist");
        }
    }

    /**
     * @notice Internal function to toggle the type of a validator between Sudo and Normal.
     * @param prevValidator The previous validator in the validators linked list.
     * @param validator The validator to toggle the type.
     */
    function _toggleValidatorType(address prevValidator, address validator) internal {
        if (normalValidators.isExist(validator)) {
            normalValidators.remove(prevValidator, validator);
            sudoValidators.add(validator);
        } else if (sudoValidators.isExist(validator)) {
            sudoValidators.remove(prevValidator, validator);
            _checkRemovingSudoValidator();
            normalValidators.add(validator);
        } else {
            revert("Validator doesn't exist");
        }
    }

    /**
     * @notice Internal function to check if there is at least one sudo validator remaining.
     * @dev Throws an error if there are no remaining sudo validators.
     */
    function _checkRemovingSudoValidator() internal view {
        require(!sudoValidators.isEmpty(), "Cannot remove the last remaining sudoValidator");
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Enum - Collection of enums used in Safe contracts.
 * @author Richard Meissner - @rmeissner
 */
abstract contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";

/**
 * @title Executor - A contract that can execute transactions
 * @author Richard Meissner - @rmeissner
 */
abstract contract Executor {
    /**
     * @notice Executes either a delegatecall or a call with provided parameters.
     * @dev This method doesn't perform any sanity check of the transaction, such as:
     *      - if the contract at `to` address has code or not
     *      It is the responsibility of the caller to perform such checks.
     * @param to Destination address.
     * @param value Ether value.
     * @param data Data payload.
     * @param operation Operation type.
     * @return success boolean flag indicating if the call succeeded.
     */
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }

    /**
     * Execute a call but also revert if the execution fails.
     * The default behavior of the Safe is to not revert if the call fails,
     * which is challenging for integrating with ERC4337 because then the
     * EntryPoint wouldn't know to emit the UserOperationRevertReason event,
     * which the frontend/client uses to capture the reason for the failure.
     */
    function executeAndRevert(address to, uint256 value, bytes memory data, Enum.Operation operation) internal {
        bool success = execute(to, value, data, operation, type(uint256).max);

        bytes memory returnData = getReturnData(type(uint256).max);
        // Revert with the actual reason string
        // Adopted from: https://github.com/Uniswap/v3-periphery/blob/464a8a49611272f7349c970e0fadb7ec1d3c1086/contracts/base/Multicall.sol#L16-L23
        if (!success) {
            if (returnData.length < 68) revert();
            assembly {
                returnData := add(returnData, 0x04)
            }
            revert(abi.decode(returnData, (string)));
        }
    }

    // get returned data from last call or calldelegate
    function getReturnData(uint256 maxLen) internal pure returns (bytes memory returnData) {
        assembly {
            let len := returndatasize()
            if gt(len, maxLen) {
                len := maxLen
            }
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, add(len, 0x20)))
            mstore(ptr, len)
            returndatacopy(add(ptr, 0x20), 0, len)
            returnData := ptr
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title NativeCurrencyPaymentFallback - A contract that has a fallback to accept native currency payments.
 */
abstract contract NativeCurrencyPaymentFallback {
    event WalletReceived(address indexed sender, uint256 value);

    /**
     * @notice Receive function accepts native currency transactions.
     * @dev Emits an event with sender and received value.
     */
    receive() external payable {
        emit WalletReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SelfAuthorized - Authorizes current contract to perform actions to itself.
 * @author Richard Meissner - @rmeissner
 */
abstract contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // Modifiers are copied around during compilation. This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Singleton - Base for singleton contracts (should always be the first super contract)
 *        This contract is tightly coupled to our proxy contract (see `proxies/SafeProxy.sol`)
 * @author Richard Meissner - @rmeissner
 */
abstract contract Singleton {
    // singleton always has to be the first declared variable to ensure the same location as in the Proxy contract.
    // It should also always be ensured the address is stored alone (uses a full word)
    address private singleton;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IModule.sol";
import "../common/Enum.sol";

interface IHooks is IModule {
    function hasHooks() external view returns (uint256);

    function beforeTransaction(address to, uint256 value, bytes memory data, Enum.Operation operation) external;

    function afterTransaction(address to, uint256 value, bytes memory data, Enum.Operation operation) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IModule is IERC165 {
    function initWalletConfig(bytes memory data) external;

    function clearWalletConfig() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@aa-template/contracts/interfaces/UserOperation.sol";
import "./IModule.sol";

interface IValidator is IModule {
    function validateSignature(
        UserOperation calldata _userOp,
        bytes32 _userOpHash
    ) external view returns (uint256 validationData);

    function isValidSignature(bytes32 hash, bytes calldata signature, address wallet) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

library AddressLinkedList {
    address internal constant SENTINEL_ADDRESS = address(1);
    uint160 internal constant SENTINEL_UINT = 1;

    modifier onlyAddress(address addr) {
        require(uint160(addr) > SENTINEL_UINT, "invalid address");
        _;
    }

    function add(mapping(address => address) storage self, address addr) internal onlyAddress(addr) {
        require(self[addr] == address(0), "address already exists");
        address _prev = self[SENTINEL_ADDRESS];
        if (_prev == address(0)) {
            self[SENTINEL_ADDRESS] = addr;
            self[addr] = SENTINEL_ADDRESS;
        } else {
            self[SENTINEL_ADDRESS] = addr;
            self[addr] = _prev;
        }
    }

    function replace(mapping(address => address) storage self, address oldAddr, address newAddr) internal {
        require(isExist(self, oldAddr), "address not exists");
        require(!isExist(self, newAddr), "new address already exists");

        address cursor = SENTINEL_ADDRESS;
        while (true) {
            address _addr = self[cursor];
            if (_addr == oldAddr) {
                address next = self[_addr];
                self[newAddr] = next;
                self[cursor] = newAddr;
                self[_addr] = address(0);
                return;
            }
            cursor = _addr;
        }
    }

    function remove(mapping(address => address) storage self, address prevAddr, address addr) internal {
        require(isExist(self, addr), "Adddress not exists");
        require(self[prevAddr] == addr, "Invalid prev address");
        self[prevAddr] = self[addr];
        self[addr] = address(0);
    }

    function clear(mapping(address => address) storage self) internal {
        for (address addr = self[SENTINEL_ADDRESS]; uint160(addr) > SENTINEL_UINT; addr = self[addr]) {
            self[addr] = address(0);
        }
        self[SENTINEL_ADDRESS] = address(0);
    }

    function isExist(mapping(address => address) storage self, address addr) internal view returns (bool) {
        return self[addr] != address(0) && uint160(addr) > SENTINEL_UINT;
    }

    function size(mapping(address => address) storage self) internal view returns (uint256) {
        uint256 result = 0;
        address addr = self[SENTINEL_ADDRESS];
        while (uint160(addr) > SENTINEL_UINT) {
            addr = self[addr];
            unchecked {
                result++;
            }
        }
        return result;
    }

    function isEmpty(mapping(address => address) storage self) internal view returns (bool) {
        return self[SENTINEL_ADDRESS] == address(0) || self[SENTINEL_ADDRESS] == SENTINEL_ADDRESS;
    }

    /**
     * @dev This function is just an example, please copy this code directly when you need it, you should not call this function
     */
    function list(
        mapping(address => address) storage self,
        address from,
        uint256 limit
    ) internal view returns (address[] memory) {
        address[] memory result = new address[](limit);
        uint256 i = 0;
        address addr = self[from];
        while (uint160(addr) > SENTINEL_UINT && i < limit) {
            result[i] = addr;
            addr = self[addr];
            unchecked {
                i++;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "../../interface/IHooks.sol";
import "../../VersaWallet.sol";

/**
 * @title BaseHooks
 * @dev Base contract for hooks implementation.
 */
abstract contract BaseHooks is IHooks {
    event InitWalletConfig(address indexed _wallet);
    event ClearWalletConfig(address indexed _wallet);

    mapping(address => bool) private _walletInitStatus;

    uint256 internal constant BEFORE_TXHOOKS_FLAG = 1 << 128;
    uint256 internal constant AFTER_TXHOOKS_FLAG = 1;

    /**
     * @dev Modifier to check if the hooks is enabled for the caller wallet.
     */
    modifier onlyEnabledHooks() {
        require(VersaWallet(payable(msg.sender)).isHooksEnabled(address(this)), "Hooks: this hooks is not enabled");
        _;
    }

    /**
     * @dev Initializes the wallet configuration.
     * @param _data The initialization data.
     */
    function initWalletConfig(bytes memory _data) external {
        require(VersaWallet(payable(msg.sender)).isHooksEnabled(address(this)), "Hooks: this hooks is not enabled 0");
        if (!_walletInitStatus[msg.sender]) {
            _walletInitStatus[msg.sender] = true;
            _init(_data);
            emit InitWalletConfig(msg.sender);
        }
    }

    /**
     * @dev Clears the wallet configuration. Triggered when disabled by a wallet
     */
    function clearWalletConfig() external {
        require(VersaWallet(payable(msg.sender)).isHooksEnabled(address(this)), "Hooks: this hooks is not enabled 1");
        if (_walletInitStatus[msg.sender]) {
            _walletInitStatus[msg.sender] = false;
            _clear();
            emit ClearWalletConfig(msg.sender);
        }
    }

    /**
     * @dev Internal function to handle wallet initialization.
     * Subclass must implement this function
     * @param _data The initialization data.
     */
    function _init(bytes memory _data) internal virtual {}

    /**
     * @dev Internal function to handle wallet configuration clearing.
     * Subclass must implement this function
     */
    function _clear() internal virtual {}

    /**
     * @dev Returns the supported hooks of this contract.
     * @return The supported hooks (represented as a bitwise flag).
     */
    function hasHooks() external pure virtual returns (uint256) {}

    /**
     * @dev Perform before transaction actions.
     * @param _to The address to which the transaction is sent.
     * @param _value The value of the transaction.
     * @param _data Additional data of the transaction.
     * @param _operation The type of the transaction operation.
     */
    function beforeTransaction(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) external virtual onlyEnabledHooks {}

    /**
     * @dev Perform after transaction actions.
     * @param _to The address to which the transaction is sent.
     * @param _value The value of the transaction.
     * @param _data Additional data of the transaction.
     * @param _operation The type of the transaction operation.
     */
    function afterTransaction(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) external virtual onlyEnabledHooks {}

    /**
     * @dev Checks if the contract supports a specific interface.
     * @param _interfaceId The interface ID to check.
     * @return True if the contract supports the interface, false otherwise.
     */
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == type(IHooks).interfaceId;
    }

    /**
     * @dev Checks if the specified wallet has been initialized.
     * @param _wallet The wallet address to check.
     * @return A boolean indicating if the wallet is initialized.
     */
    function isWalletInited(address _wallet) external view returns (bool) {
        return _walletInitStatus[_wallet];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BaseHooks.sol";

/**
 * @title SpendingLimitHooks
 */
contract SpendingLimitHooks is BaseHooks {
    struct SpendingLimitSetConfig {
        address tokenAddress; // The address of the token that needs spending limit
        uint256 allowanceAmount; // The maximum amount of the token allowed to be spent within resetTimeIntervalMinutes
        uint32 resetBaseTimeMinutes; // Base time reference value for calculation (timestamp to minutes)
        uint16 resetTimeIntervalMinutes; // Reset time interval (minutes)
    }

    struct SpendingLimitInfo {
        uint256 allowanceAmount; // The maximum amount of the token allowed to be spent within resetTimeIntervalMinutes
        uint256 spentAmount; // The amount of the token has been spent within resetTimeIntervalMinutes
        uint32 lastResetTimeMinutes; // Last reset time (timestamp to minutes)
        uint16 resetTimeIntervalMinutes; // Reset time interval (minutes)
    }

    event SetSpendingLimit(
        address indexed _wallet,
        address indexed _token,
        uint256 _allowanceAmount,
        uint32 _resetBaseTimeMinutes,
        uint16 _resetTimeIntervalMinutes
    );
    event ResetSpendingLimit(address indexed _wallet, address indexed _token);
    event DeleteSpendingLimit(address indexed _wallet, address indexed _token);

    error SpendingLimitSimulate();

    // Wallet -> Token -> SpendingLimitInfo
    mapping(address => mapping(address => SpendingLimitInfo)) internal _tokenSpendingLimitInfo;

    // ERC20 Token Method Selector
    bytes4 internal constant TRANSFER = ERC20.transfer.selector;
    bytes4 internal constant TRANSFER_FROM = ERC20.transferFrom.selector;
    bytes4 internal constant APPROVE = ERC20.approve.selector;
    bytes4 internal constant INCREASE_ALLOWANCE = ERC20.increaseAllowance.selector;

    /**
     * @dev Internal function to handle wallet initialization.
     * @param _data The initialization data.
     */
    function _init(bytes memory _data) internal override {
        if (_data.length > 0) {
            SpendingLimitSetConfig[] memory initialSetConfigs = _parseSpendingLimitSetConfigData(_data);
            _batchSetSpendingLimit(initialSetConfigs);
        }
    }

    /**
     * @dev Internal function to handle wallet configuration clearing.
     */
    function _clear() internal override {}

    /**
     * @dev Internal function to update the spending limit information for a specific token and wallet.
     * @param _token The address of the token.
     * @param _spendingLimitInfo The updated spending limit information to be stored.
     */
    function _updateSpendingLimitInfo(address _token, SpendingLimitInfo memory _spendingLimitInfo) internal {
        _tokenSpendingLimitInfo[msg.sender][_token] = _spendingLimitInfo;
    }

    /**
     * @dev Internal function to check spent amount and update the spending limit information.
     * @param _token The address of the token.
     * @param _spendingLimitInfo The updated spending limit information to be stored.
     */
    function _checkAmountAndUpdate(address _token, SpendingLimitInfo memory _spendingLimitInfo) internal {
        // Ensure that the spent amount does not exceed the allowance amount
        require(
            _spendingLimitInfo.spentAmount <= _spendingLimitInfo.allowanceAmount,
            "SpendingLimitHooks: token overspending"
        );
        _updateSpendingLimitInfo(_token, _spendingLimitInfo);
    }

    /**
     * @dev Internal function to check the spending limit before a transaction.
     * @param _wallet The address of the wallet initiating the transaction.
     * @param _to The address of the recipient of the transaction.
     * @param _value The value of the transaction.
     * @param _data The data associated with the transaction.
     * @param _operation The type of operation being performed.
     */
    function _checkSpendingLimit(
        address _wallet,
        address _to,
        uint256 _value,
        bytes calldata _data,
        Enum.Operation _operation
    ) internal {
        require(_operation != Enum.Operation.DelegateCall, "SpendingLimitHooks: not allow delegatecall");

        // Check spending limit for native token
        if (_value > 0) {
            _checkNativeTokenSpendingLimit(_wallet, _value);
        }

        // Check spending limit for ERC20 token
        uint256 dataLength = _data.length;
        if (dataLength > 0) {
            _checkERC20TokenSpendingLimit(_wallet, _to, _data);
        }
    }

    /**
     * @dev Internal function to check the spending limit for native token.
     * @param _wallet The address of the wallet.
     * @param _value The value of the transaction.
     */
    function _checkNativeTokenSpendingLimit(address _wallet, uint256 _value) internal {
        SpendingLimitInfo memory spendingLimitInfo = getSpendingLimitInfo(_wallet, address(0));

        // Check if there is a spending limit set for this wallet
        if (spendingLimitInfo.allowanceAmount > 0) {
            // Update the spent amount with the transaction value
            spendingLimitInfo.spentAmount += _value;
            _checkAmountAndUpdate(address(0), spendingLimitInfo);
        }
    }

    /**
     * @dev Internal function to check the spending limit for an ERC20 token.
     * @param _wallet The address of the wallet.
     * @param _token The address of the ERC20 token.
     * @param _data The transaction data.
     */
    function _checkERC20TokenSpendingLimit(address _wallet, address _token, bytes calldata _data) internal {
        SpendingLimitInfo memory spendingLimitInfo = getSpendingLimitInfo(_wallet, _token);

        // Check if there is a spending limit set for this token
        if (spendingLimitInfo.allowanceAmount > 0) {
            bytes4 methodSelector = bytes4(_data[:4]);
            if (methodSelector == TRANSFER || methodSelector == INCREASE_ALLOWANCE) {
                (address target, uint256 value) = abi.decode(_data[4:], (address, uint256));
                if (target != msg.sender) {
                    spendingLimitInfo.spentAmount += value;
                    _checkAmountAndUpdate(_token, spendingLimitInfo);
                }
            } else if (methodSelector == TRANSFER_FROM) {
                (address target, , uint256 value) = abi.decode(_data[4:], (address, address, uint256));
                if (target == msg.sender) {
                    spendingLimitInfo.spentAmount += value;
                    _checkAmountAndUpdate(_token, spendingLimitInfo);
                }
            } else if (methodSelector == APPROVE) {
                (address target, uint256 value) = abi.decode(_data[4:], (address, uint256));
                if (target != msg.sender) {
                    uint256 preAllowanceAmount = ERC20(_token).allowance(_wallet, target);
                    if (value > preAllowanceAmount) {
                        spendingLimitInfo.spentAmount = spendingLimitInfo.spentAmount + value - preAllowanceAmount;
                        _checkAmountAndUpdate(_token, spendingLimitInfo);
                    }
                }
            }
        }
    }

    /**
     * @dev Parses the provided data to extract SpendingLimitSetConfig configurations.
     * @param _data The data containing SpendingLimitSetConfig configurations.
     * @return An array of SpendingLimitSetConfig objects.
     */
    function _parseSpendingLimitSetConfigData(
        bytes memory _data
    ) internal pure returns (SpendingLimitSetConfig[] memory) {
        SpendingLimitSetConfig[] memory spendingLimitSetConfigs = abi.decode(_data, (SpendingLimitSetConfig[]));
        require(spendingLimitSetConfigs.length > 0, "SpendingLimitHooks: parse error");
        return spendingLimitSetConfigs;
    }

    /**
     * @dev Sets the spending limit for the caller based on the provided SpendingLimitSetConfig.
     * @param _config The SpendingLimitSetConfig to set the spending limit.
     */
    function _setSpendingLimit(SpendingLimitSetConfig memory _config) internal {
        if (_config.tokenAddress != address(0)) {
            try ERC20(_config.tokenAddress).totalSupply() returns (uint256 totalSupply) {
                require(totalSupply != 0, "SpendingLimitHooks: illegal token address");
            } catch {
                revert("SpendingLimitHooks: illegal token address");
            }
        }
        SpendingLimitInfo memory spendingLimitInfo = getSpendingLimitInfo(msg.sender, _config.tokenAddress);
        uint32 currentTimeMinutes = uint32(block.timestamp / 60);
        if (_config.resetBaseTimeMinutes > 0) {
            require(
                _config.resetBaseTimeMinutes <= currentTimeMinutes,
                "SpendingLimitHooks: resetBaseTimeMinutes can not greater than currentTimeMinutes"
            );
            spendingLimitInfo.lastResetTimeMinutes =
                currentTimeMinutes -
                ((currentTimeMinutes - _config.resetBaseTimeMinutes) % _config.resetTimeIntervalMinutes);
        } else if (spendingLimitInfo.lastResetTimeMinutes == 0) {
            spendingLimitInfo.lastResetTimeMinutes = currentTimeMinutes;
        }
        spendingLimitInfo.resetTimeIntervalMinutes = _config.resetTimeIntervalMinutes;
        spendingLimitInfo.allowanceAmount = _config.allowanceAmount;
        _updateSpendingLimitInfo(_config.tokenAddress, spendingLimitInfo);
        emit SetSpendingLimit(
            msg.sender,
            _config.tokenAddress,
            _config.allowanceAmount,
            _config.resetBaseTimeMinutes,
            _config.resetTimeIntervalMinutes
        );
    }

    /**
     * @dev Sets spending limits for multiple tokens based on the provided SpendingLimitSetConfig array.
     * @param _configs An array of SpendingLimitSetConfig objects.
     */
    function _batchSetSpendingLimit(SpendingLimitSetConfig[] memory _configs) internal {
        uint dataLength = _configs.length;
        require(dataLength > 0, "SpendingLimitHooks: dataLength should greater than zero");
        for (uint i = 0; i < dataLength; i++) {
            _setSpendingLimit(_configs[i]);
        }
    }

    /**
     * @dev Sets the spending limit for the caller based on the provided SpendingLimitSetConfig.
     * @param _config The SpendingLimitSetConfig to set the spending limit.
     */
    function setSpendingLimit(SpendingLimitSetConfig memory _config) external  {
        require(VersaWallet(payable(msg.sender)).isHooksEnabled(address(this)), "Hooks: this hooks is not enabled 2");
        _setSpendingLimit(_config);
    }

    /**
     * @dev Sets spending limits for multiple tokens based on the provided SpendingLimitSetConfig array.
     * @param _configs An array of SpendingLimitSetConfig objects.
     */
    function batchSetSpendingLimit(SpendingLimitSetConfig[] memory _configs) external {
        require(VersaWallet(payable(msg.sender)).isHooksEnabled(address(this)), "Hooks: this hooks is not enabled 3");
        _batchSetSpendingLimit(_configs);
    }

    /**
     * @dev Resets the spending limit for the caller and the specified token.
     * @param _token The token address for which to reset the spending limit.
     */
    function _resetSpendingLimit(address _token) internal {
        SpendingLimitInfo memory spendingLimitInfo = getSpendingLimitInfo(msg.sender, _token);
        spendingLimitInfo.spentAmount = 0;
        _updateSpendingLimitInfo(_token, spendingLimitInfo);
        emit ResetSpendingLimit(msg.sender, _token);
    }

    /**
     * @dev Resets the spending limit for the caller and the specified token.
     * @param _token The token address for which to reset the spending limit.
     */
    function resetSpendingLimit(address _token) external {
        require(VersaWallet(payable(msg.sender)).isHooksEnabled(address(this)), "Hooks: this hooks is not enabled 4");
        _resetSpendingLimit(_token);
    }

    /**
     * @dev Batch reset spending limit for specified tokens.
     * @param _tokens An array containing the addresses of tokens for which spending limit is to be reset.
     *                Each element in the array represents the address of a token for which the limit will be reset.
     * @notice Only enabled hooks can call this function.
     */
    function batchResetSpendingLimit(address[] memory _tokens) external {
        require(VersaWallet(payable(msg.sender)).isHooksEnabled(address(this)), "Hooks: this hooks is not enabled 5");
        uint dataLength = _tokens.length;
        require(dataLength > 0, "SpendingLimitHooks: dataLength should greater than zero");
        for (uint i = 0; i < dataLength; i++) {
            _resetSpendingLimit(_tokens[i]);
        }
    }

    /**
     * @dev Deletes the spending limit for the caller and the specified token.
     * @param _token The token address for which to delete the spending limit.
     */
    function _deleteSpendingLimit(address _token) internal {
        delete _tokenSpendingLimitInfo[msg.sender][_token];
        emit DeleteSpendingLimit(msg.sender, _token);
    }

    /**
     * @dev Deletes the spending limit for the caller and the specified token.
     * @param _token The token address for which to delete the spending limit.
     */
    function deleteSpendingLimit(address _token) external {
        require(VersaWallet(payable(msg.sender)).isHooksEnabled(address(this)), "Hooks: this hooks is not enabled 6");
        _deleteSpendingLimit(_token);
    }

    /**
     * @dev Batch delete spending limit for specified tokens.
     * @param _tokens An array containing the addresses of tokens for which spending limit is to be deleted.
     *                Each element in the array represents the address of a token for which the limit will be deleted.
     * @notice Only enabled hooks can call this function.
     */
    function batchDeleteSpendingLimit(address[] memory _tokens) external {
        require(VersaWallet(payable(msg.sender)).isHooksEnabled(address(this)), "Hooks: this hooks is not enabled 7");
        uint dataLength = _tokens.length;
        require(dataLength > 0, "SpendingLimitHooks: dataLength should greater than zero");
        for (uint i = 0; i < dataLength; i++) {
            _deleteSpendingLimit(_tokens[i]);
        }
    }

    /**
     * @dev Retrieves the spending limit information for the specified wallet and token.
     * @param _wallet The wallet address for which to retrieve the spending limit information.
     * @param _token The token address for which to retrieve the spending limit information.
     * @return SpendingLimitInfo The spending limit information for the specified wallet and token.
     */
    function getSpendingLimitInfo(address _wallet, address _token) public view returns (SpendingLimitInfo memory) {
        SpendingLimitInfo memory spendingLimitInfo = _tokenSpendingLimitInfo[_wallet][_token];
        uint32 currentTimeMinutes = uint32(block.timestamp / 60);
        if (
            spendingLimitInfo.resetTimeIntervalMinutes > 0 &&
            spendingLimitInfo.lastResetTimeMinutes + spendingLimitInfo.resetTimeIntervalMinutes <= currentTimeMinutes
        ) {
            spendingLimitInfo.spentAmount = 0;
            spendingLimitInfo.lastResetTimeMinutes =
                currentTimeMinutes -
                ((currentTimeMinutes - spendingLimitInfo.lastResetTimeMinutes) %
                    spendingLimitInfo.resetTimeIntervalMinutes);
        }
        return spendingLimitInfo;
    }

    /**
     * @dev Retrieves the spending limit information for multiple tokens for the specified wallet.
     * @param _wallet The wallet address for which to retrieve the spending limit information.
     * @param _tokens An array of token addresses for which to retrieve the spending limit information.
     * @return SpendingLimitInfo[] An array of spending limit information for the specified wallet and tokens.
     */
    function batchGetSpendingLimitInfo(
        address _wallet,
        address[] memory _tokens
    ) public view returns (SpendingLimitInfo[] memory) {
        uint dataLength = _tokens.length;
        require(dataLength > 0, "SpendingLimitHooks: dataLength should greater than zero");
        SpendingLimitInfo[] memory batchSpendingLimitInfo = new SpendingLimitInfo[](dataLength);
        for (uint i = 0; i < dataLength; i++) {
            batchSpendingLimitInfo[i] = getSpendingLimitInfo(_wallet, _tokens[i]);
        }
        return batchSpendingLimitInfo;
    }

    /**
     * @dev Returns the supported hooks of this contract.
     * @return The supported hooks (represented as a bitwise flag).
     */
    function hasHooks() external pure override returns (uint256) {
        return BEFORE_TXHOOKS_FLAG;
    }

    /**
     * @dev Perform before transaction actions.
     * @param _to The address to which the transaction is sent.
     * @param _value The value of the transaction.
     * @param _data Additional data of the transaction.
     * @param _operation The type of the transaction operation.
     */
    function beforeTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data,
        Enum.Operation _operation
    ) external override {
        require(VersaWallet(payable(msg.sender)).isHooksEnabled(address(this)), "Hooks: this hooks is not enabled 8");
        _checkSpendingLimit(msg.sender, _to, _value, _data, _operation);
    }

    /**
     * @dev Perform after transaction actions.
     * @param _to The address to which the transaction is sent.
     * @param _value The value of the transaction.
     * @param _data Additional data of the transaction.
     * @param _operation The type of the transaction operation.
     */
    function afterTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data,
        Enum.Operation _operation
    ) external view override {
        require(VersaWallet(payable(msg.sender)).isHooksEnabled(address(this)), "Hooks: this hooks is not enabled 9");
        (_to, _value, _data, _operation);
        revert("SpendingLimitHooks: afterTransaction hook is not allowed");
    }

    /**
     * @dev Simulates a limited transaction by checking the spending limit for the specified wallet.
     * @param _wallet The wallet address to simulate the transaction for.
     * @param _to The destination address of the transaction.
     * @param _value The value (amount) of the transaction.
     * @param _data The additional data for the transaction.
     * @param _operation The operation type of the transaction.
     */
    function simulateSpendingLimitTransaction(
        address _wallet,
        address _to,
        uint256 _value,
        bytes calldata _data,
        Enum.Operation _operation
    ) external {
        require(
            VersaWallet(payable(_wallet)).isHooksEnabled(address(this)),
            "SpendingLimitHooks: this hooks is not enabled"
        );
        _checkSpendingLimit(_wallet, _to, _value, _data, _operation);
        revert SpendingLimitSimulate();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@aa-template/contracts/interfaces/IAccount.sol";
import "@aa-template/contracts/interfaces/IEntryPoint.sol";
import "./common/Singleton.sol";
import "./common/Enum.sol";
import "./base/FallbackManager.sol";
import "./base/EntryPointManager.sol";
import "./base/ValidatorManager.sol";
import "./base/HooksManager.sol";
import "./base/ModuleManager.sol";
import "./interface/IValidator.sol";

/**
 * @title VersaWallet - A Smart contract wallet that supports EIP4337
 */
contract VersaWallet is
    Singleton,
    Initializable,
    EntryPointManager,
    ValidatorManager,
    HooksManager,
    ModuleManager,
    FallbackManager,
    IAccount
{
    /**
     * @dev The execution type of a transaction.
     * - Sudo: Transaction executed with full permissions.
     * - Normal: Regular transaction executed limited access.
     */
    enum ExecutionType {
        Sudo,
        Normal
    }

    string public constant VERSA_VERSION = "0.0.1";

    // `sudoExecute` function selector
    bytes4 internal constant SUDO_EXECUTE = 0x7df9bf29;
    // `batchSudoExecute` function selector
    bytes4 internal constant BATCH_SUDO_EXECUTE = 0x7e5f1c3f;

    /**
     * @dev Disable initializers to prevent the implementation contract
     * from being used
     */
    constructor(address entryPoint) EntryPointManager(entryPoint) {
        _disableInitializers();
    }

    /**
     * @dev Initializes the VersaWallet contract.
     * @param fallbackHandler The address of the fallback handler contract.
     * @param validators The addresses of the validators.
     * @param validatorInitData The initialization data for each validator.
     * @param validatorType The types of the validators.
     * @param hooks The addresses of the hooks.
     * @param hooksInitData The initialization data for each hook.
     * @param modules The addresses of the modules.
     * @param moduleInitData The initialization data for each module.
     */
    function initialize(
        address fallbackHandler,
        address[] memory validators,
        bytes[] memory validatorInitData,
        ValidatorType[] memory validatorType,
        address[] memory hooks,
        bytes[] memory hooksInitData,
        address[] memory modules,
        bytes[] memory moduleInitData
    ) external initializer {
        _checkInitializationDataLength(
            validators.length,
            validatorInitData.length,
            validatorType.length,
            hooks.length,
            hooksInitData.length,
            modules.length,
            moduleInitData.length
        );
        internalSetFallbackHandler(fallbackHandler);

        uint256 i;
        bool hasSudoValidator;
        for (i = 0; i < validators.length; ++i) {
            _enableValidator(validators[i], validatorType[i], validatorInitData[i]);
            if (validatorType[i] == ValidatorType.Sudo) {
                hasSudoValidator = true;
            }
        }
        require(hasSudoValidator, "Must set up the initial sudo validator");
        for (i = 0; i < hooks.length; ++i) {
            _enableHooks(hooks[i], hooksInitData[i]);
        }
        for (i = 0; i < modules.length; ++i) {
            _enableModule(modules[i], moduleInitData[i]);
        }
    }

    /**
     * @dev Validates an user operation before execution.
     * @param userOp The user operation data.
     * @param userOpHash The hash of the user operation.
     * @param missingAccountFunds The amount of missing account funds to be paid.
     * @return validationData The validation data returned by the validator.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override onlyFromEntryPoint returns (uint256 validationData) {
        address validator = _getValidator(userOp.signature);
        _validateValidatorAndSelector(validator, bytes4(userOp.callData[0:4]));
        validationData = IValidator(validator).validateSignature(userOp, userOpHash);
        _payPrefund(missingAccountFunds);
    }

    /**
     * @dev Executes a sudo transaction.
     * @param to The address to which the transaction is directed.
     * @param value The value of the transaction.
     * @param data The data of the transaction.
     * @param operation The operation type of the transaction.
     */
    function sudoExecute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external onlyFromEntryPoint {
        _internalExecute(to, value, data, operation, ExecutionType.Sudo);
    }

    /**
     * @dev Executes a normal transaction.
     * @param to The address to which the transaction is directed.
     * @param value The value of the transaction.
     * @param data The data of the transaction.
     * @param operation The operation type of the transaction.
     */
    function normalExecute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external onlyFromEntryPoint {
        _internalExecute(to, value, data, operation, ExecutionType.Normal);
    }

    /**
     * @dev Executes a batch transaction with sudo privileges.
     * @param to The addresses to which the transactions are directed.
     * @param value The values of the transactions.
     * @param data The data of the transactions.
     * @param operation The operation types of the transactions.
     */
    function batchSudoExecute(
        address[] memory to,
        uint256[] memory value,
        bytes[] memory data,
        Enum.Operation[] memory operation
    ) external onlyFromEntryPoint {
        _checkBatchDataLength(to.length, value.length, data.length, operation.length);
        for (uint256 i = 0; i < to.length; ++i) {
            _internalExecute(to[i], value[i], data[i], operation[i], ExecutionType.Sudo);
        }
    }

    /**
     * @dev Executes a batch normal transaction.
     * @param to The addresses to which the transactions are directed.
     * @param value The values of the transactions.
     * @param data The data of the transactions.
     * @param operation The operation types of the transactions.
     */
    function batchNormalExecute(
        address[] memory to,
        uint256[] memory value,
        bytes[] memory data,
        Enum.Operation[] memory operation
    ) external onlyFromEntryPoint {
        _checkBatchDataLength(to.length, value.length, data.length, operation.length);
        for (uint256 i = 0; i < to.length; ++i) {
            _internalExecute(to[i], value[i], data[i], operation[i], ExecutionType.Normal);
        }
    }

    /**
     * @dev Internal function to execute a transaction.
     * @param to The address to which the transaction is directed.
     * @param value The value of the transaction.
     * @param data The data of the transaction.
     * @param operation The operation type of the transaction.
     * @param execution The execution type of the transaction.
     */
    function _internalExecute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        ExecutionType execution
    ) internal {
        if (execution == ExecutionType.Sudo) {
            executeAndRevert(to, value, data, operation);
        } else {
            _checkNormalExecute(to, operation);
            _beforeTransaction(to, value, data, operation);
            executeAndRevert(to, value, data, operation);
            _afterTransaction(to, value, data, operation);
        }
    }

    /**
     * @dev Sends the missing funds for this transaction to the entry point (msg.sender).
     * Subclasses may override this method for better funds management
     * (e.g., send more than the minimum required to the entry point so that in future transactions
     * it will not be required to send again).
     * @param missingAccountFunds The minimum value this method should send to the entry point.
     * This value may be zero in case there is enough deposit or the userOp has a paymaster.
     */
    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds > 0) {
            // Note: May pay more than the minimum to deposit for future transactions
            (bool success, ) = payable(entryPoint()).call{ value: missingAccountFunds, gas: type(uint256).max }("");
            (success);
            // Ignore failure (it's EntryPoint's job to verify, not the account)
        }
    }

    /**
     * @dev Extracts the validator address from the first 20 bytes of the signature.
     * @param signature The signature from which to extract the validator address.
     * @return The extracted validator address.
     */
    function _getValidator(bytes calldata signature) internal pure returns (address) {
        return address(bytes20(signature[0:20]));
    }

    /**
     * @dev Validates the validator and selector for a user operation.
     * @param _validator The address of the validator to validate.
     * @param _selector The selector of the user operation.
     */
    function _validateValidatorAndSelector(address _validator, bytes4 _selector) internal view {
        ValidatorType validatorType = getValidatorType(_validator);
        require(validatorType != ValidatorType.Disabled, "Versa: invalid validator");
        if (_selector == SUDO_EXECUTE || _selector == BATCH_SUDO_EXECUTE) {
            require(validatorType == ValidatorType.Sudo, "Versa: selector doesn't match validator");
        }
    }

    /**
     * @dev A normal execution has following restrictions:
     * 1. Cannot selfcall, i.e., change wallet's config
     * 2. Cannot call to an enabled plugin, i.e, change plugin's config or call wallet from plugin
     * 3. Cannot perform a delegatecall
     * @param to The address to which the transaction is directed.
     * @param _operation The operation type of the transaction.
     */
    function _checkNormalExecute(address to, Enum.Operation _operation) internal view {
        require(
            to != address(this) &&
                !isValidatorEnabled(to) &&
                !isHooksEnabled(to) &&
                !isModuleEnabled(to) &&
                _operation != Enum.Operation.DelegateCall,
            "Versa: operation is not allowed"
        );
    }

    /**
     * @dev Checks the lengths of the batch transaction data arrays.
     */
    function _checkBatchDataLength(
        uint256 toLen,
        uint256 valueLen,
        uint256 dataLen,
        uint256 operationLen
    ) internal pure {
        require(toLen == valueLen && dataLen == operationLen && toLen == dataLen, "Versa: invalid batch data");
    }

    /**
     * @dev Check the length of the initialization data arrays
     */
    function _checkInitializationDataLength(
        uint256 validatorsLen,
        uint256 validatorInitLen,
        uint256 validatorTypeLen,
        uint256 hooksLen,
        uint256 hooksInitDataLen,
        uint256 modulesLen,
        uint256 moduleInitLen
    ) internal pure {
        require(
            validatorsLen == validatorInitLen &&
                validatorInitLen == validatorTypeLen &&
                hooksLen == hooksInitDataLen &&
                modulesLen == moduleInitLen,
            "Data length doesn't match"
        );
    }
}