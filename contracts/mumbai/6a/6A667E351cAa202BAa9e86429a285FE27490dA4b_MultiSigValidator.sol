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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
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
pragma solidity ^0.8.19;

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
pragma solidity ^0.8.19;

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
pragma solidity ^0.8.19;

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
            IHooks(addr).beforeTransaction(to, value, data, operation);
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
            IHooks(addr).afterTransaction(to, value, data, operation);
            addr = afterTxHooks[addr];
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

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
pragma solidity ^0.8.19;

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
pragma solidity ^0.8.19;

import "./IModule.sol";
import "../common/Enum.sol";

interface IHooks is IModule {
    function hasHooks() external view returns (uint256);

    function beforeTransaction(address to, uint256 value, bytes memory data, Enum.Operation operation) external;

    function afterTransaction(address to, uint256 value, bytes memory data, Enum.Operation operation) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IModule is IERC165 {
    function initWalletConfig(bytes memory data) external;

    function clearWalletConfig() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

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
pragma solidity ^0.8.19;

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
pragma solidity ^0.8.19;

import "@aa-template/contracts/interfaces/UserOperation.sol";

library SignatureHandler {
    uint8 constant INSTANT_TRANSACTION = 0x00;
    uint8 constant SCHEDULE_TRANSACTION = 0x01;

    uint8 constant SIG_TYPE_OFFSET = 20;
    uint8 constant SIG_TYPE_LENGTH = 1;

    uint8 constant TIME_LENGTH = 6;
    uint8 constant VALID_UNTIL_OFFSET = 21;
    uint8 constant VALID_AFTER_OFFSET = VALID_UNTIL_OFFSET + TIME_LENGTH;

    uint8 constant FEE_LENGTH = 32;
    uint8 constant MAX_FEE_OFFSET = 33;
    uint8 constant MAX_PRIORITY_FEE_OFFSET = MAX_FEE_OFFSET + FEE_LENGTH;

    uint8 constant INSTANT_SIG_OFFSET = 21;
    uint8 constant SCHEDULE_SIG_OFFSET = MAX_PRIORITY_FEE_OFFSET + FEE_LENGTH;

    // Memory struct for decoded userOp signature
    struct SplitedSignature {
        uint256 signatureType;
        bytes32 hash;
        bytes signature;
        uint256 validUntil;
        uint256 validAfter;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
    }

    /*
        User operation's signature field(for ECDSA and Multisig validator):
        +-----------------------------+-------------------------------------------------------------------------+
        |       siganture type        |                        signature layout                                 |
        +---------------------------------------------+---------------+-----------------------------------------+
        | instant transaction (0x00)  | validatorAddr | signatureType |             signatureField              |
        |                             |    20 bytes   |    1 byte     |                 n bytes                 |
        +-------------------------------------------------------------------------+----------+------------------+
        | scheduled transaction(0x01) | validatorAddr | signatureType | timeRange |  feeData |   signatureField |
        |                             |    20 bytes   |    1 byte     | 12 bytes  | 64 bytes |     n bytes      |
        +-----------------------------+---------------+---------------+-----------+----------+------------------+
        
        timeRange: validUntil(6 bytes) and validAfter(6 bytes)
        feeData:   maxFeePerGas(32 bytes) and maxPriorityFeePerGas(32 bytes)
    */

    /**
     * @notice Decode the user operation signature and extract relevant information.
     * @param userOp The UserOperation struct containing the signature.
     * @param userOpHash The hash of the user operation.
     * @return splitedSig The SplitedSignature struct with decoded signature information.
     */
    function splitUserOpSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal pure returns (SplitedSignature memory splitedSig) {
        splitedSig.signatureType = uint8(bytes1(userOp.signature[SIG_TYPE_OFFSET:SIG_TYPE_OFFSET + SIG_TYPE_LENGTH]));
        // For instant transactions, the signature start from the 22th bytes of the userOp.signature.
        if (splitedSig.signatureType == INSTANT_TRANSACTION) {
            splitedSig.signature = userOp.signature[INSTANT_SIG_OFFSET:];
            splitedSig.hash = userOpHash;
        } else if (splitedSig.signatureType == SCHEDULE_TRANSACTION) {
            // For scheduled transactions, decode the individual fields from the signature.
            splitedSig.validUntil = uint48(
                bytes6(userOp.signature[VALID_UNTIL_OFFSET:VALID_UNTIL_OFFSET + TIME_LENGTH])
            );
            splitedSig.validAfter = uint48(
                bytes6(userOp.signature[VALID_AFTER_OFFSET:VALID_AFTER_OFFSET + TIME_LENGTH])
            );
            splitedSig.maxFeePerGas = uint256(bytes32(userOp.signature[MAX_FEE_OFFSET:MAX_FEE_OFFSET + FEE_LENGTH]));
            splitedSig.maxPriorityFeePerGas = uint256(
                bytes32(userOp.signature[MAX_PRIORITY_FEE_OFFSET:MAX_PRIORITY_FEE_OFFSET + FEE_LENGTH])
            );
            splitedSig.signature = userOp.signature[SCHEDULE_SIG_OFFSET:];
            // Calculate the hash of the scheduled transaction using the extra data fields.
            bytes memory extraData = abi.encode(
                splitedSig.validUntil,
                splitedSig.validAfter,
                splitedSig.maxFeePerGas,
                splitedSig.maxPriorityFeePerGas
            );
            splitedSig.hash = keccak256(abi.encode(userOpHash, extraData));
        }
    }

    /**
     * @dev divides bytes ecdsa signatures into `uint8 v, bytes32 r, bytes32 s` from `pos`.
     * @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
     * @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
     * @param signatures concatenated rsv signatures
     */
    function multiSignatureSplit(
        bytes memory signatures,
        uint256 pos
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // The signature format is a compact form of:
        // {bytes32 r} {bytes32 s} {uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            // signatures data start from signaturesOffset + 0x20(signature length)
            r := mload(add(signaturePos, add(signatures, 0x20)))
            s := mload(add(signaturePos, add(signatures, 0x40)))
            v := byte(0, mload(add(signaturePos, add(signatures, 0x60))))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "../../interface/IValidator.sol";
import "../../VersaWallet.sol";

/**
 * @title BaseValidator
 * @dev Base contract for validator implementation.
 */
abstract contract BaseValidator is IValidator {
    event WalletInited(address indexed wallet);
    event WalletCleared(address indexed wallet);

    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    /**
     * @dev Modifier to check if the validator is enabled for the caller wallet.
     */
    modifier onlyEnabledValidator() {
        require(VersaWallet(payable(msg.sender)).isValidatorEnabled(address(this)), "Validator is not enabled");
        _;
    }

    /**
     * @dev Initializes the wallet configuration.
     * @param data The initialization data.
     */
    function initWalletConfig(bytes memory data) external onlyEnabledValidator {
        if (!_isWalletInited(msg.sender)) {
            _init(data);
            emit WalletInited(msg.sender);
        }
    }

    /**
     * @dev Clears the wallet configuration. Triggered when disabled by a wallet.
     *  It's optional to implement the clear logic.
     */
    function clearWalletConfig() external onlyEnabledValidator {
        if (_isWalletInited(msg.sender)) {
            _clear();
            emit WalletCleared(msg.sender);
        }
    }

    /**
     * @dev Checks if the specified wallet has been initialized.
     * @param wallet The wallet address to check.
     * @return A boolean indicating if the wallet is initialized.
     */
    function isWalletInited(address wallet) external view returns (bool) {
        return _isWalletInited(wallet);
    }

    /**
     * @dev Internal function to handle wallet initialization.
     * Subclass must implement this function
     * @param data The initialization data.
     */
    function _init(bytes memory data) internal virtual {}

    /**
     * @dev Internal function to handle wallet configuration clearing.
     * Subclass must implement this function
     */
    function _clear() internal virtual {}

    /**
     * @dev Checks if the specified wallet has been initialized.
     * @param wallet The wallet address to check.
     * @return A boolean indicating if the wallet is initialized.
     */
    function _isWalletInited(address wallet) internal view virtual returns (bool) {}

    /**
     * @dev Inherits from ERC165.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IValidator).interfaceId;
    }

    /**
     * @dev Check the decoded signature type and fee.
     * @param sigType The signature type.
     * @param maxFeePerGas The maximum fee per gas.
     * @param maxPriorityFeePerGas The maximum priority fee per gas.
     * @param actualMaxFeePerGas The actual maximum fee per gas from the user operation.
     * @param actualMaxPriorityFeePerGas The actual maximum priority fee per gas from the user operation.
     * @return A boolean indicating whether the decoded signature is valid or not.
     */
    function _checkTransactionTypeAndFee(
        uint256 sigType,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 actualMaxFeePerGas,
        uint256 actualMaxPriorityFeePerGas
    ) internal pure returns (bool) {
        if (sigType != 0x00 && sigType != 0x01) {
            return false;
        }
        if (
            sigType == 0x01 && (actualMaxFeePerGas > maxFeePerGas || actualMaxPriorityFeePerGas > maxPriorityFeePerGas)
        ) {
            return false;
        }
        return true;
    }

    /**
     * @dev Pack the validation data.
     * @param sigFailed The signature validation result.
     * @param validUntil The valid until timestamp.
     * @param validAfter The valid after timestamp.
     * @return The packed validation data.
     */
    function _packValidationData(
        uint256 sigFailed,
        uint256 validUntil,
        uint256 validAfter
    ) internal pure returns (uint256) {
        return sigFailed | (validUntil << 160) | (validAfter << (160 + 48));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./BaseValidator.sol";
import "../../library/AddressLinkedList.sol";
import "../../library/SignatureHandler.sol";

/**
 * @title MultiSigValidator.
 * A multi-ECDSA validator contract.
 */
contract MultiSigValidator is BaseValidator {
    using ECDSA for bytes32;

    event AddGuardian(address indexed wallet, address indexed guardian);
    event RevokeGuardian(address indexed wallet, address indexed guardian);
    event ChangeThreshold(address indexed wallet, uint256 indexed threshold);

    event ApproveHash(bytes32 indexed hash);
    event RevokeHash(bytes32 indexed hash);

    struct WalletInfo {
        // guardians count of a wallet
        uint128 guardianCount;
        // verification threshold
        uint128 threshold;
    }

    /// @dev Record guardians of a wallet
    mapping(address => mapping(address => bool)) internal _guardians;

    /// @dev Record signer's count and verification threshold of a wallet
    mapping(address => WalletInfo) internal _walletInfo;

    /// @dev Record approved signed message hashes of a wallet
    mapping(bytes32 => mapping(address => bool)) internal _approvedHashes;

    /**
     * @dev Internal function to handle wallet initialization.
     * @param data The initialization data.
     */
    function _init(bytes memory data) internal override {
        (address[] memory guardians, uint256 newThreshold) = abi.decode(data, (address[], uint256));
        require(guardians.length > 0 && newThreshold <= guardians.length, "Invalid initdata");
        for (uint256 i = 0; i < guardians.length; i++) {
            _addGuardian(msg.sender, guardians[i]);
        }
        _changeThreshold(msg.sender, newThreshold);
    }

    /**
     * @dev Internal function to handle wallet configuration clearing.
     * We don't delete guardian config in this validator
     */
    function _clear() internal override {}

    /**
     * @dev Checks if the specified wallet has been initialized.
     * @param wallet The wallet address to check.
     * @return A boolean indicating if the wallet is initialized.
     */
    function _isWalletInited(address wallet) internal view override returns (bool) {
        return _guardiansCount(wallet) != 0;
    }

    /**
     * @notice Let the sudo validator add a guardian for its wallet.
     * @param guardian The guardian to add.
     * @param newThreshold The new threshold that will be set after addition.
     */
    function addGuardian(address guardian, uint256 newThreshold) external onlyEnabledValidator {
        _addGuardian(msg.sender, guardian);
        _changeThreshold(msg.sender, newThreshold);
    }

    /**
     * @notice Let the sudo validator add guardians for its wallet.
     * @param guardians The guardian list to add.
     * @param newThreshold The new threshold that will be set after addition.
     */
    function addGuardians(address[] calldata guardians, uint256 newThreshold) external onlyEnabledValidator {
        uint guardiansLength = guardians.length;
        for (uint i = 0; i < guardiansLength; i++) {
            _addGuardian(msg.sender, guardians[i]);
        }
        _changeThreshold(msg.sender, newThreshold);
    }

    /**
     * @notice Let the sudo validator revoke a guardian from its wallet.
     * @param guardian The guardian to revoke.
     * @param newThreshold The new threshold that will be set after execution of revokation.
     */
    function revokeGuardian(address guardian, uint256 newThreshold) external onlyEnabledValidator {
        require(_guardiansCount(msg.sender) >= 2, "Must have at least one guardian");
        _revokeGuardian(msg.sender, guardian);
        _changeThreshold(msg.sender, newThreshold);
    }

    /**
     * @notice Let the sudo validator change the guardian threshold required.
     * @param newThreshold The new threshold that will be set after execution of revokation.
     */
    function changeThreshold(uint256 newThreshold) external onlyEnabledValidator {
        _changeThreshold(msg.sender, newThreshold);
    }

    /**
     * @notice Clear previous guardians and set new guardians and threshold.
     * @param newThreshold The new threshold that will be set after execution of revokation.
     * @param newGuardians The array of new guardians, must be ordered for duplication check.
     */
    function resetGuardians(
        uint256 newThreshold,
        address[] calldata oldGuardians,
        address[] calldata newGuardians
    ) external onlyEnabledValidator {
        // Make sure the wallet has at least one guardian
        require(
            _guardiansCount(msg.sender) + newGuardians.length > oldGuardians.length,
            "Must have at least one guardian"
        );
        for (uint256 i = 0; i < oldGuardians.length; i++) {
            _revokeGuardian(msg.sender, oldGuardians[i]);
        }
        for (uint256 i = 0; i < newGuardians.length; i++) {
            _addGuardian(msg.sender, newGuardians[i]);
        }
        _changeThreshold(msg.sender, newThreshold);
    }

    /**
     * @dev Function to approve a message hash for EIP-1271 validation.
     * @param hash The hash to be approved.
     */
    function approveHash(bytes32 hash) external onlyEnabledValidator {
        require(!_isHashApproved(msg.sender, hash), "Hash already approved");
        _approvedHashes[hash][msg.sender] = true;
        emit ApproveHash(hash);
    }

    /**
     * @dev Function to revoke an previously approved message hash.
     * @param hash The hash to be revoked.
     */
    function revokeHash(bytes32 hash) external onlyEnabledValidator {
        require(_isHashApproved(msg.sender, hash), "Hash is not approved");
        _approvedHashes[hash][msg.sender] = false;
        emit RevokeHash(hash);
    }

    /**
     * @dev Internal function to add a guardian for a wallet.
     * @param wallet The target wallet.
     * @param guardian The guardian to add.
     */
    function _addGuardian(address wallet, address guardian) internal {
        require(!_isGuardian(wallet, guardian), "Guardian is already added");
        require(guardian != wallet && guardian != address(0), "Invalid guardian address");
        WalletInfo storage info = _walletInfo[wallet];
        info.guardianCount++;
        _guardians[guardian][msg.sender] = true;
        emit AddGuardian(wallet, guardian);
    }

    /**
     * @dev Lets an authorised module revoke a guardian from a wallet.
     * @param wallet The target wallet.
     * @param guardian The guardian to revoke.
     */
    function _revokeGuardian(address wallet, address guardian) internal {
        require(_isGuardian(wallet, guardian), "Not a valid guardian");
        WalletInfo storage info = _walletInfo[wallet];
        _guardians[guardian][msg.sender] = false;
        info.guardianCount--;
        emit RevokeGuardian(wallet, guardian);
    }

    /**
     * @dev Allows to update the number of required confirmations by guardians.
     * @param wallet The target wallet.
     * @param newThreshold New threshold.
     */
    function _changeThreshold(address wallet, uint256 newThreshold) internal {
        WalletInfo storage info = _walletInfo[wallet];
        // Validate that threshold is smaller than or equal to number of guardians.
        if (info.guardianCount == 0) {
            require(newThreshold == 0, "Threshold must be 0");
        } else {
            require(newThreshold > 0, "Threshold cannot be 0");
        }
        require(newThreshold <= info.guardianCount, "Threshold must be lower or equal to guardians count");
        info.threshold = uint128(newThreshold);
        emit ChangeThreshold(wallet, newThreshold);
    }

    /**
     * @dev Inherits from IValidator.
     * @param userOp The userOp to validate.
     * @param userOpHash The hash of the userOp.
     */
    function validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external view returns (uint256 validationData) {
        uint256 currentThreshold = _threshold(userOp.sender);
        // Check that the provided signature data is not too short
        // 20 bytes validator address + 1 byte sig type + required signatures(no less than threshold * 65)
        if (currentThreshold == 0 || userOp.signature.length < 20 + 1 + currentThreshold * 65) {
            return SIG_VALIDATION_FAILED;
        }
        SignatureHandler.SplitedSignature memory splitedSig = SignatureHandler.splitUserOpSignature(userOp, userOpHash);
        if (
            !_checkTransactionTypeAndFee(
                splitedSig.signatureType,
                splitedSig.maxFeePerGas,
                splitedSig.maxPriorityFeePerGas,
                userOp.maxFeePerGas,
                userOp.maxPriorityFeePerGas
            )
        ) {
            return SIG_VALIDATION_FAILED;
        }

        bytes32 ethSignedMessageHash = splitedSig.hash.toEthSignedMessageHash();
        // Check if signatures are valid, return `SIG_VALIDATION_FAILED` if error occurs
        try this.checkNSignatures(userOp.sender, ethSignedMessageHash, splitedSig.signature, currentThreshold) {
            return _packValidationData(0, splitedSig.validUntil, splitedSig.validAfter);
        } catch {
            return SIG_VALIDATION_FAILED;
        }
    }

    /**
     * @notice Legacy EIP-1271 signature validation method.
     * @param hash Hash of data signed.
     * @param signature Signature byte array associated with _data.
     * @return True if signature valid.
     */
    function isValidSignature(bytes32 hash, bytes calldata signature, address wallet) external view returns (bool) {
        // If signature is empty, the hash must be previously approved
        if (signature.length == 0) {
            require(_isHashApproved(wallet, hash), "Hash not approved");
            // If check if enough valid guardians's signature collected
        } else {
            bytes32 ethSignedMessageHash = hash.toEthSignedMessageHash();
            checkNSignatures(wallet, ethSignedMessageHash, signature, _threshold(wallet));
        }
        return true;
    }

    /**
     * @dev Checks if an account is a guardian for a wallet.
     * @param wallet The target wallet.
     * @param guardian The account.
     * @return true if the account is a guardian for a wallet.
     */
    function isGuardian(address wallet, address guardian) public view returns (bool) {
        return _isGuardian(wallet, guardian);
    }

    /**
     * @dev Returns the number of guardians for a wallet.
     * @param wallet The target wallet.
     * @return the number of guardians.
     */
    function guardiansCount(address wallet) public view returns (uint256) {
        return _guardiansCount(wallet);
    }

    /**
     * @dev Retrieves the wallet threshold count.
     * @param wallet The target wallet.
     * @return uint256 Threshold count.
     */
    function threshold(address wallet) public view returns (uint256) {
        return _threshold(wallet);
    }

    /**
     * @dev Function that check if a hash is approved by given wallet.
     * @param wallet The target wallet.
     * @return bool True if the hash is approves.
     */
    function isHashApproved(address wallet, bytes32 hash) public view returns (bool) {
        return _isHashApproved(wallet, hash);
    }

    /**
     * @notice Checks whether the signature provided is valid for the provided data and hash. Reverts otherwise.
     * @dev Since the EIP-1271 does an external call, be mindful of reentrancy attacks.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param signatures Signature data that should be verified.
     *                   Can be packed ECDSA signature ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     * @param requiredSignatures Amount of required valid signatures.
     */
    function checkNSignatures(
        address wallet,
        bytes32 dataHash,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures * 65, "Signatures data too short");
        // There cannot be an guardian with address 0.
        address lastGuardian = address(0);
        address currentGuardian;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;

        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = SignatureHandler.multiSignatureSplit(signatures, i);
            if (v == 0) {
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentGuardian = address(uint160(uint256(r)));

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= requiredSignatures * 65, "Inside static part");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s) + (32) <= signatures.length, "Contract signatures out of bounds");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s) + 32 + contractSignatureLen <= signatures.length, "Contract signature wrong offset");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(
                    SignatureChecker.isValidERC1271SignatureNow(currentGuardian, dataHash, contractSignature),
                    "Contract signature invalid"
                );
            } else {
                // eip712 recovery
                currentGuardian = ECDSA.recover(dataHash, v, r, s);
            }
            require(currentGuardian > lastGuardian && isGuardian(wallet, currentGuardian), "Invalid guardian");
            lastGuardian = currentGuardian;
        }
    }

    /**
     * @dev Internal function that checks if an account is a guardian for a wallet.
     * @param wallet The target wallet.
     * @param guardian The account.
     * @return true if the account is a guardian for a wallet.
     */
    function _isGuardian(address wallet, address guardian) internal view returns (bool) {
        return _guardians[guardian][wallet];
    }

    /**
     * @dev Internal function that returns the number of guardians for a wallet.
     * @param wallet The target wallet.
     * @return the number of guardians.
     */
    function _guardiansCount(address wallet) internal view returns (uint256) {
        return _walletInfo[wallet].guardianCount;
    }

    /**
     * @dev Internal function that retrieves the wallet threshold count.
     * @param wallet The target wallet.
     * @return uint256 Threshold count.
     */
    function _threshold(address wallet) internal view returns (uint256) {
        return _walletInfo[wallet].threshold;
    }

    /**
     * @dev Internal function that check if a hash is approved by given wallet.
     * @param wallet The target wallet.
     * @return bool True if the hash is approves.
     */
    function _isHashApproved(address wallet, bytes32 hash) internal view returns (bool) {
        return _approvedHashes[hash][wallet];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

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
    bytes4 internal constant SUDO_EXECUTE = this.sudoExecute.selector;
    // `batchSudoExecute` function selector
    bytes4 internal constant BATCH_SUDO_EXECUTE = this.batchSudoExecute.selector;

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