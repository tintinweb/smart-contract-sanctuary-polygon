// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IEntryPoint.sol";
import "./StakeManager.sol";
import "../factory/ISingletonFactory.sol";
import "../wallet/IAggregatedWallet.sol";
import "../paymaster/IPaymaster.sol";
import "../util/Utils.sol";

contract EntryPoint is IEntryPoint, StakeManager {
    using UserOperationLib for UserOperation;

    //a memory copy of UserOp fields (except that dynamic byte arrays: callData, initCode and signature
    struct MemoryUserOp {
        address sender;
        uint256 nonce;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        address paymaster;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
    }

    struct UserOpInfo {
        MemoryUserOp mUserOp;
        bytes32 requestId;
        uint256 prefund;
        uint256 contextOffset;
        uint256 preOpGas;
    }

    address private constant SIMULATE_NO_AGGREGATOR = address(1);

    // Singleton factory used by the entry point to instantiate wallets
    ISingletonFactory public immutable create2Factory;

    /* solhint-disable */
    error InvalidUnstakeDelay();
    error InvalidPaymasterStake();
    error InvalidPaymasterAndData();
    error GasValueOverflow();
    error OnlyEntryPoint();
    error InvalidReceiver();
    error TransferFailed();
    error OnlyZeroAddressCaller();
    error SimulateResult(uint256 callGas);
    /* solhint-enable */

    modifier onlySelf() {
        if (msg.sender != address(this)) revert OnlyEntryPoint();
        _;
    }

    modifier validReceiver(address receiver) {
        if (receiver == address(0)) revert InvalidReceiver();
        _;
    }

    modifier onlySimulateCall() {
        if (msg.sender != address(0)) revert OnlyZeroAddressCaller();
        _;
    }

    constructor(
        ISingletonFactory create2Factory_,
        uint256 paymasterStake,
        uint32 unstakeDelaySec
    ) StakeManager(paymasterStake, unstakeDelaySec) {
        create2Factory = create2Factory_;
        if (unstakeDelaySec == 0) revert InvalidUnstakeDelay();
        if (paymasterStake == 0) revert InvalidPaymasterStake();
    }

    /*------------------------------------------external functions---------------------------------*/

    /**
     * @dev Execute a batch of UserOperation.
     * no signature aggregator is used.
     * if any wallet requires an aggregator (that is, it returned an "actualAggregator" when
     * performing simulateValidation), then handleAggregatedOps() must be used instead.
     * @param ops the operations to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) public {
        uint256 opslen = ops.length;
        UserOpInfo[] memory opInfos = new UserOpInfo[](opslen);

        unchecked {
            for (uint256 i = 0; i < opslen; i++) {
                validatePrepayment(i, ops[i], opInfos[i], address(0));
            }

            uint256 collected = 0;

            for (uint256 i = 0; i < opslen; i++) {
                collected += executeUserOp(i, ops[i], opInfos[i]);
            }

            compensate(beneficiary, collected);
        } //unchecked
    }

    /**
     * @dev Simulate a call to wallet.validateUserOp and paymaster.validatePaymasterUserOp.
     * Validation succeeds if the call doesn't revert.
     * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the wallet's data.
     *      In order to split the running opcodes of the wallet (validateUserOp) from the paymaster's validatePaymasterUserOp,
     *      it should look for the NUMBER opcode at depth=1 (which itself is a banned opcode)
     * @param userOp the user operation to validate.
     * @param offChainSigCheck if the wallet has an aggregator, skip on-chain aggregation check. In thus case, the bundler must
     *          perform the equivalent check using an off-chain library code
     * @return preOpGas total gas used by validation (including contract creation)
     * @return prefund the amount the wallet had to prefund (zero in case a paymaster pays)
     * @return actualAggregator the aggregator used by this userOp. if a non-zero aggregator is returned, the bundler must get its params using
     *      aggregator.
     * @return sigForUserOp - only if has actualAggregator: this value is returned from IAggregator.validateUserOpSignature, and should be placed in the userOp.signature when creating a bundle.
     * @return sigForAggregation  - only if has actualAggregator:  this value is returned from IAggregator.validateUserOpSignature, and should be passed to aggregator.aggregateSignatures
     * @return offChainSigInfo - if has actualAggregator, and offChainSigCheck is true, this value should be used by the off-chain signature code (e.g. it contains the sender's publickey)
     */
    function simulateValidation(UserOperation calldata userOp, bool offChainSigCheck)
        external
        onlySimulateCall
        returns (
            uint256 preOpGas,
            uint256 prefund,
            address actualAggregator,
            bytes memory sigForUserOp,
            bytes memory sigForAggregation,
            bytes memory offChainSigInfo
        )
    {
        uint256 preGas = gasleft();

        UserOpInfo memory outOpInfo;

        actualAggregator = validatePrepayment(0, userOp, outOpInfo, SIMULATE_NO_AGGREGATOR);
        prefund = outOpInfo.prefund;
        preOpGas = preGas - gasleft() + userOp.preVerificationGas;

        (offChainSigCheck, sigForUserOp, sigForAggregation, offChainSigInfo);

        // TODO: validate with Aggregator
        // numberMarker();
        // if (actualAggregator != address(0)) {
        //     (sigForUserOp, sigForAggregation, offChainSigInfo) = IAggregator(actualAggregator).validateUserOpSignature(
        //         userOp,
        //         offChainSigCheck
        //     );
        // }
    }

    /**
     * @dev Simulate a call to wallet to get the gas used.
     * Revert SimulateResult if succeed to call and other errors if failed.
     * @param userOp the user operation to validate.
     */
    function simulateExecute(UserOperation calldata userOp) external onlySimulateCall {
        MemoryUserOp memory mUserOp;
        copyUserOpToMemory(userOp, mUserOp);
        createWalletIfNeeded(0, mUserOp, userOp.initCode);
        if (userOp.callData.length == 0) revert FailedOp(0, address(0), "no call data");
        uint256 preGas = gasleft();
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(mUserOp.sender).call(userOp.callData);
        uint256 gasUsed = preGas - gasleft();
        if (!success) revert FailedOp(0, address(0), "call failed");
        revert SimulateResult(gasUsed);
    }

    /**
     * inner function to handle a UserOperation.
     * Must be declared "external" to open a call context, but it can only be called by handleOps.
     */
    function innerHandleOp(
        bytes calldata callData,
        bytes calldata paymasterAndData,
        UserOpInfo memory opInfo,
        bytes calldata context
    ) external onlySelf returns (uint256 actualGasCost) {
        uint256 preGas = gasleft();
        MemoryUserOp memory mUserOp = opInfo.mUserOp;
        IPaymaster.PostOpMode mode = IPaymaster.PostOpMode.opSucceeded;
        bool success = true;
        bytes memory result;
        //call wallet to deposit to paymaster
        if (paymasterAndData.length > 40) {
            // solhint-disable-next-line avoid-low-level-calls
            (success, result) = address(mUserOp.sender).call(
                abi.encodeWithSignature("handlePaymasterAndData(bytes)", paymasterAndData)
            );
            if (!success) {
                if (result.length > 0) {
                    emit UserOperationRevertReason(opInfo.requestId, mUserOp.sender, mUserOp.nonce, result);
                }
                mode = IPaymaster.PostOpMode.opReverted;
            }
        }
        if (callData.length > 0 && success) {
            // solhint-disable-next-line avoid-low-level-calls
            (success, result) = address(mUserOp.sender).call{gas: mUserOp.callGasLimit}(callData);
            if (!success) {
                if (result.length > 0) {
                    emit UserOperationRevertReason(opInfo.requestId, mUserOp.sender, mUserOp.nonce, result);
                }
                mode = IPaymaster.PostOpMode.opReverted;
            }
        }

        unchecked {
            uint256 actualGas = preGas - gasleft() + opInfo.preOpGas;
            //note: opIndex is ignored (relevant only if mode==postOpReverted, which is only possible outside of innerHandleOp)
            return handlePostOp(0, mode, opInfo, context, actualGas);
        }
    }

    /*------------------------------------------public functions---------------------------------*/

    /**
     * @dev Generate a request Id - unique identifier for this request.
     * the request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     * @param userOp user opreation
     * @return requestId of the user operation
     */
    function getRequestId(UserOperation calldata userOp) public view returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), address(this), block.chainid));
    }

    /*------------------------------------------internal functions---------------------------------*/

    /**
     * @dev Compensate the caller's beneficiary address with the collected fees of all UserOperations.
     * @param beneficiary the address to receive the fees
     * @param amount amount to transfer.
     */
    function compensate(address payable beneficiary, uint256 amount) internal validReceiver(beneficiary) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = beneficiary.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Internal function that will trigger a wallet creation in case it was requested in the op
     * @param opIndex Index of operation in batch using for emit
     * @param mUserOp memory user operation
     * @param initCode init code of user operation
     */
    function createWalletIfNeeded(
        uint256 opIndex,
        MemoryUserOp memory mUserOp,
        bytes calldata initCode
    ) internal {
        if (initCode.length == 0) return;
        if (mUserOp.sender.code.length != 0) return;
        address createdWallet = create2Factory.deploy(initCode);
        if (createdWallet == address(0)) revert FailedOp(opIndex, address(0), "initCode failed");
        if (createdWallet != mUserOp.sender)
            revert FailedOp(opIndex, address(0), "sender doesn't match initCode address");
        if (createdWallet.code.length == 0) revert FailedOp(opIndex, address(0), "initCode failed to create sender");
    }

    /**
     * copy general fields from userOp into the memory opInfo structure.
     */
    function copyUserOpToMemory(UserOperation calldata userOp, MemoryUserOp memory mUserOp) internal pure {
        mUserOp.sender = userOp.sender;
        mUserOp.nonce = userOp.nonce;
        mUserOp.callGasLimit = userOp.callGasLimit;
        mUserOp.verificationGasLimit = userOp.verificationGasLimit;
        mUserOp.preVerificationGas = userOp.preVerificationGas;
        mUserOp.maxFeePerGas = userOp.maxFeePerGas;
        mUserOp.maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        bytes calldata paymasterAndData = userOp.paymasterAndData;
        if (paymasterAndData.length > 0) {
            if (paymasterAndData.length < 20) revert InvalidPaymasterAndData();
            mUserOp.paymaster = address(bytes20(paymasterAndData[:20]));
        } else {
            mUserOp.paymaster = address(0);
        }
    }

    function getUserOpGasPrice(MemoryUserOp memory mUserOp) internal view returns (uint256) {
        unchecked {
            uint256 maxFeePerGas = mUserOp.maxFeePerGas;
            uint256 maxPriorityFeePerGas = mUserOp.maxPriorityFeePerGas;
            if (maxFeePerGas == maxPriorityFeePerGas) {
                //legacy mode (for networks that don't support basefee opcode)
                return maxFeePerGas;
            }
            return Utils.min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
        }
    }

    function getRequiredPrefund(MemoryUserOp memory mUserOp) internal view returns (uint256 requiredPrefund) {
        unchecked {
            //when using a Paymaster, the verificationGasLimit is used also to as a limit for the postOp call.
            // our security model might call postOp eventually twice
            uint256 mul = mUserOp.paymaster != address(0) ? 3 : 1;
            uint256 requiredGas = mUserOp.callGasLimit +
                mUserOp.verificationGasLimit *
                mul +
                mUserOp.preVerificationGas;

            // TODO: copy logic of gasPrice?
            requiredPrefund = requiredGas * getUserOpGasPrice(mUserOp);
        }
    }

    //place the NUMBER opcode in the code.
    // this is used as a marker during simulation, as this OP is completely banned from the simulated code of the
    // wallet and paymaster.
    function numberMarker() internal view {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(0, number())
        }
    }

    /*------------------------------------------private functions---------------------------------*/

    /**
     * call wallet.validateUserOp.
     * revert (with FailedOp) in case validateUserOp reverts, or wallet didn't send required prefund.
     * decrement wallet's deposit if needed
     */
    function validateWalletPrepayment(
        uint256 opIndex,
        UserOperation calldata op,
        UserOpInfo memory opInfo,
        address aggregator,
        uint256 requiredPrefund
    ) internal returns (uint256 gasUsedByValidateWalletPrepayment, address actualAggregator) {
        unchecked {
            uint256 preGas = gasleft();
            MemoryUserOp memory mUserOp = opInfo.mUserOp;
            createWalletIfNeeded(opIndex, mUserOp, op.initCode);
            if (aggregator == SIMULATE_NO_AGGREGATOR) {
                try IAggregatedWallet(mUserOp.sender).getAggregator() returns (address userOpAggregator) {
                    aggregator = actualAggregator = userOpAggregator;
                } catch {
                    aggregator = actualAggregator = address(0);
                }
            }
            uint256 missingWalletFunds = 0;
            address sender = mUserOp.sender;
            address paymaster = mUserOp.paymaster;
            if (paymaster == address(0)) {
                uint256 bal = getBalanceOf(sender);
                missingWalletFunds = bal > requiredPrefund ? 0 : requiredPrefund - bal;
            }
            try
                IEIP4337Wallet(sender).validateUserOp{gas: mUserOp.verificationGasLimit}(
                    op,
                    opInfo.requestId,
                    aggregator,
                    missingWalletFunds
                )
            {
                //
            } catch Error(string memory reason) {
                revert FailedOp(opIndex, address(0), reason);
            } catch {
                revert FailedOp(opIndex, address(0), "");
            }
            if (paymaster == address(0)) {
                DepositInfo storage senderInfo = deposits[sender];
                uint256 deposit = senderInfo.deposit;
                if (requiredPrefund > deposit) revert FailedOp(opIndex, address(0), "wallet didn't pay prefund");

                senderInfo.deposit = uint112(deposit - requiredPrefund);
            }
            gasUsedByValidateWalletPrepayment = preGas - gasleft();
        }
    }

    /**
     * in case the request has a paymaster:
     * validate paymaster is staked and has enough deposit.
     * call paymaster.validatePaymasterUserOp.
     * revert with proper FailedOp in case paymaster reverts.
     * decrement paymaster's deposit
     */
    function validatePaymasterPrepayment(
        uint256 opIndex,
        UserOperation calldata op,
        UserOpInfo memory opInfo,
        uint256 requiredPreFund,
        uint256 gasUsedByValidateWalletPrepayment
    ) internal returns (bytes memory context) {
        unchecked {
            MemoryUserOp memory mUserOp = opInfo.mUserOp;
            address paymaster = mUserOp.paymaster;
            DepositInfo storage paymasterInfo = deposits[paymaster];
            uint256 deposit = paymasterInfo.deposit;
            bool staked = paymasterInfo.staked;
            if (!staked) {
                revert FailedOp(opIndex, paymaster, "not staked");
            }
            if (deposit < requiredPreFund) {
                revert FailedOp(opIndex, paymaster, "paymaster deposit too low");
            }
            paymasterInfo.deposit = uint112(deposit - requiredPreFund);
            uint256 gas = mUserOp.verificationGasLimit - gasUsedByValidateWalletPrepayment;
            try IPaymaster(paymaster).validatePaymasterUserOp{gas: gas}(op, opInfo.requestId, requiredPreFund) returns (
                bytes memory context_
            ) {
                context = context_;
            } catch Error(string memory revertReason) {
                revert FailedOp(opIndex, paymaster, revertReason);
            } catch {
                revert FailedOp(opIndex, paymaster, "");
            }
        }
    }

    /**
     * @dev Validate wallet and paymaster (if defined).
     * also make sure total validation doesn't exceed verificationGasLimit
     * this method is called off-chain (simulateValidation()) and on-chain (from handleOps)
     * @param opIndex the index of this userOp into the "opInfos" array
     * @param userOp the userOp to validate
     */
    function validatePrepayment(
        uint256 opIndex,
        UserOperation calldata userOp,
        UserOpInfo memory outOpInfo,
        address aggregator
    ) private returns (address actualAggregator) {
        uint256 preGas = gasleft();
        MemoryUserOp memory mUserOp = outOpInfo.mUserOp;
        copyUserOpToMemory(userOp, mUserOp);
        outOpInfo.requestId = getRequestId(userOp);

        // validate all numeric values in userOp are well below 128 bit, so they can safely be added
        // and multiplied without causing overflow
        uint256 maxGasValues = mUserOp.preVerificationGas |
            mUserOp.verificationGasLimit |
            mUserOp.callGasLimit |
            userOp.maxFeePerGas |
            userOp.maxPriorityFeePerGas;
        if (maxGasValues > type(uint120).max) revert GasValueOverflow();

        uint256 gasUsedByValidateWalletPrepayment;
        uint256 requiredPreFund = getRequiredPrefund(mUserOp);
        (gasUsedByValidateWalletPrepayment, actualAggregator) = validateWalletPrepayment(
            opIndex,
            userOp,
            outOpInfo,
            aggregator,
            requiredPreFund
        );
        //a "marker" where wallet opcode validation is done and paymaster opcode validation is about to start
        // (used only by off-chain simulateValidation)
        numberMarker();

        bytes memory context;
        if (mUserOp.paymaster != address(0)) {
            context = validatePaymasterPrepayment(
                opIndex,
                userOp,
                outOpInfo,
                requiredPreFund,
                gasUsedByValidateWalletPrepayment
            );
        } else {
            context = "";
        }
        unchecked {
            uint256 gasUsed = preGas - gasleft();

            if (userOp.verificationGasLimit < gasUsed)
                revert FailedOp(opIndex, mUserOp.paymaster, "Used more than verificationGasLimit");
            outOpInfo.prefund = requiredPreFund;
            outOpInfo.contextOffset = Utils.getOffsetOfMemoryBytes(context);
            outOpInfo.preOpGas = preGas - gasleft() + userOp.preVerificationGas;
        }
    }

    /**
     * @dev Process post-operation.
     * called just after the callData is executed.
     * if a paymaster is defined and its validation returned a non-empty context, its postOp is called.
     * the excess amount is refunded to the wallet (or paymaster - if it is was used in the request)
     * @param opIndex index in the batch
     * @param mode - whether is called from innerHandleOp, or outside (postOpReverted)
     * @param opInfo userOp fields and info collected during validation
     * @param context the context returned in validatePaymasterUserOp
     * @param actualGas the gas used so far by this user operation
     */
    function handlePostOp(
        uint256 opIndex,
        IPaymaster.PostOpMode mode,
        UserOpInfo memory opInfo,
        bytes memory context,
        uint256 actualGas
    ) private returns (uint256 actualGasCost) {
        uint256 preGas = gasleft();
        unchecked {
            address refundAddress;
            MemoryUserOp memory mUserOp = opInfo.mUserOp;
            uint256 gasPrice = getUserOpGasPrice(mUserOp);

            address paymaster = mUserOp.paymaster;
            if (paymaster == address(0)) {
                refundAddress = mUserOp.sender;
            } else {
                refundAddress = paymaster;
                if (context.length > 0) {
                    actualGasCost = actualGas * gasPrice;
                    if (mode != IPaymaster.PostOpMode.postOpReverted) {
                        IPaymaster(paymaster).postOp{gas: mUserOp.verificationGasLimit}(mode, context, actualGasCost);
                    } else {
                        // solhint-disable-next-line no-empty-blocks
                        try
                            IPaymaster(paymaster).postOp{gas: mUserOp.verificationGasLimit}(
                                mode,
                                context,
                                actualGasCost
                            )
                        {} catch Error(string memory reason) {
                            revert FailedOp(opIndex, paymaster, reason);
                        } catch {
                            revert FailedOp(opIndex, paymaster, "postOp revert");
                        }
                    }
                }
            }
            actualGas += preGas - gasleft();
            actualGasCost = actualGas * gasPrice;
            if (opInfo.prefund < actualGasCost) {
                revert FailedOp(opIndex, paymaster, "prefund below actualGasCost");
            }
            uint256 refund = opInfo.prefund - actualGasCost;
            internalIncrementDeposit(refundAddress, refund);
            bool success = mode == IPaymaster.PostOpMode.opSucceeded;
            emit UserOperationEvent(
                opInfo.requestId,
                mUserOp.sender,
                mUserOp.paymaster,
                mUserOp.nonce,
                actualGasCost,
                gasPrice,
                success
            );
        } // unchecked
    }

    /**
     * @dev Execute a user op.
     * @param opIndex into into the opInfo array
     * @param userOp the userOp to execute
     * @param opInfo the opInfo filled by validatePrepayment for this userOp.
     * @return collected the total amount this userOp paid.
     */
    function executeUserOp(
        uint256 opIndex,
        UserOperation calldata userOp,
        UserOpInfo memory opInfo
    ) private returns (uint256 collected) {
        uint256 preGas = gasleft();
        bytes memory context = Utils.getMemoryBytesFromOffset(opInfo.contextOffset);

        try this.innerHandleOp(userOp.callData, userOp.paymasterAndData, opInfo, context) returns (
            uint256 actualGasCost
        ) {
            collected = actualGasCost;
        } catch {
            uint256 actualGas = preGas - gasleft() + opInfo.preOpGas;
            collected = handlePostOp(opIndex, IPaymaster.PostOpMode.postOpReverted, opInfo, context, actualGas);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../UserOperation.sol";
import "./IStakeManager.sol";

/**
 * @dev EntryPoint interface specified in https://eips.ethereum.org/EIPS/eip-4337
 */
interface IEntryPoint is IStakeManager {
    /* solhint-disable */

    /**
     * a custom revert error of handleOps, to identify the offending op.
     *  NOTE: if simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
     *  @param opIndex - index into the array of ops to the failed one (in simulateValidation, this is always zero)
     *  @param paymaster - if paymaster.validatePaymasterUserOp fails, this will be the paymaster's address. if validateUserOp failed,
     *       this value will be zero (since it failed before accessing the paymaster)
     *  @param reason - revert reason
     *   Should be caught in off-chain handleOps simulation and not happen on-chain.
     *   Useful for mitigating DoS attempts against batchers or for troubleshooting of wallet/paymaster reverts.
     */
    error FailedOp(uint256 opIndex, address paymaster, string reason);

    /***
     * An event emitted after each successful request
     * @param requestId - unique identifier for the request (hash its entire content, except signature).
     * @param sender - the account that generates this request.
     * @param paymaster - if non-null, the paymaster that pays for this request.
     * @param nonce - the nonce value from the request
     * @param actualGasCost - the total cost (in gas) of this request.
     * @param actualGasPrice - the actual gas price the sender agreed to pay.
     * @param success - true if the sender transaction succeeded, false if reverted.
     */
    event UserOperationEvent(
        bytes32 indexed requestId,
        address indexed sender,
        address indexed paymaster,
        uint256 nonce,
        uint256 actualGasCost,
        uint256 actualGasPrice,
        bool success
    );

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length
     * @param requestId the request unique identifier.
     * @param sender the sender of this request
     * @param nonce the nonce used in the request
     * @param revertReason - the return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(bytes32 indexed requestId, address indexed sender, uint256 nonce, bytes revertReason);

    /* solhint-enable */

    /**
     * @dev Process a list of operations
     */
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;

    /**
     * @dev Allows off-chain parties to validate operations through the entry point before executing them
     */
    function simulateValidation(UserOperation calldata userOp, bool offChainSigCheck)
        external
        returns (
            uint256 preOpGas,
            uint256 prefund,
            address actualAggregator,
            bytes memory sigForUserOp,
            bytes memory sigForAggregation,
            bytes memory offChainSigInfo
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IStakeManager {
    /**
     * @param deposit the account's deposit
     * @param staked true if this account is staked as a paymaster
     * @param stake actual amount of ether staked for this paymaster. must be above paymasterStake
     * @param unstakeDelaySec minimum delay to withdraw the stake. must be above the global unstakeDelaySec
     * @param withdrawTime - first block timestamp where 'withdrawStake' will be callable, or zero if already locked
     * @dev sizes were chosen so that (deposit,staked) fit into one cell (used during handleOps)
     *    and the rest fit into a 2nd cell.
     *    112 bit allows for 2^15 eth
     *    64 bit for full timestamp
     *    32 bit allow 150 years for unstake delay
     */
    struct DepositInfo {
        uint112 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint64 withdrawTime;
    }

    event Deposited(address indexed account, uint256 totalDeposit);

    event Withdrawn(address indexed account, address withdrawAddress, uint256 amount);

    event StakeLocked(address indexed account, uint256 totalStaked, uint256 withdrawTime);

    event StakeUnlocked(address indexed account, uint256 withdrawTime);

    event StakeWithdrawn(address indexed account, address withdrawAddress, uint256 amount);

    // minimum time (in seconds) required to lock a paymaster stake before it can be withdraw.
    function unstakeDelaySec() external returns (uint32);

    // minimum value required to stake for a paymaster
    function paymasterStake() external returns (uint256);

    // return the deposit (for gas payment) of the account
    function getBalanceOf(address account) external view returns (uint256);

    // add to the deposit of the given account
    function depositTo(address account) external payable;

    /**
     * add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param unstakeDelaySec the new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 unstakeDelaySec) external payable;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IStakeManager.sol";

/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a paymaster or a wallet)
 * stake is value locked for at least "unstakeDelay" by a paymaster.
 */
abstract contract StakeManager is IStakeManager {
    // minimum time (in seconds) required to lock a paymaster stake before it can be withdraw.
    uint32 public immutable unstakeDelaySec;

    // minimum value required to stake for a paymaster
    uint256 public immutable paymasterStake;

    // maps paymaster to their deposits and stakes
    mapping(address => DepositInfo) public deposits;

    /* solhint-disable */
    error DepositOverflow();
    error UnstakeDelayTooLow();
    error CannotDecreaseUnstakeTime();
    error StakeValueTooLow();
    error StakeOverflow();
    error NotStaked();
    error AlreadyUnstaking();
    error NoStakeToWithdraw();
    error NoUnlockStakeCallYet();
    error StakeWithdrawalIsNotDue();
    error FailedToWithdrawStake();
    error WithdrawAmountIsTooLarge();
    error FailedToWithdraw();
    error InsufficientStake();

    /* solhint-enable */
    constructor(uint256 paymasterStake_, uint32 unstakeDelaySec_) {
        paymasterStake = paymasterStake_;
        unstakeDelaySec = unstakeDelaySec_;
    }

    receive() external payable {
        depositTo(msg.sender);
    }

    function getBalanceOf(address account) public view returns (uint256) {
        return deposits[account].deposit;
    }

    /**
     * @dev Deposits value to an account. It will deposit the entire msg.value sent to the function.
     * @param account willing to deposit the value to
     */
    function depositTo(address account) public payable {
        internalIncrementDeposit(account, msg.value);
        DepositInfo storage info = deposits[account];
        emit Deposited(account, info.deposit);
    }

    /**
     * @dev Stakes the sender's deposits. It will deposit the entire msg.value sent to the function and mark it as staked.
     * @param unstakeDelaySec_ the new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 unstakeDelaySec_) public payable {
        DepositInfo storage info = deposits[msg.sender];
        if (unstakeDelaySec_ < unstakeDelaySec) revert UnstakeDelayTooLow();
        if (unstakeDelaySec_ < info.unstakeDelaySec) revert CannotDecreaseUnstakeTime();
        uint256 stake = info.stake + msg.value;
        if (stake < paymasterStake) revert StakeValueTooLow();
        if (stake > type(uint112).max) revert StakeOverflow();
        deposits[msg.sender] = DepositInfo(info.deposit, true, uint112(stake), unstakeDelaySec_, 0);
        emit StakeLocked(msg.sender, stake, unstakeDelaySec_);
    }

    /**
     * @dev Starts the unlocking process for the sender,
     * the value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external {
        DepositInfo storage info = deposits[msg.sender];
        if (info.unstakeDelaySec == 0) revert NotStaked();
        if (!info.staked) revert AlreadyUnstaking();
        // solhint-disable-next-line not-rely-on-time
        uint64 withdrawTime = uint64(block.timestamp) + info.unstakeDelaySec;
        info.withdrawTime = withdrawTime;
        info.staked = false;
        emit StakeUnlocked(msg.sender, withdrawTime);
    }

    /**
     * @dev withdraw from the (unlocked) stake.
     * must first call unlockStake and wait for the unstakeDelay to pass
     * @param withdrawAddress the address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external {
        DepositInfo storage info = deposits[msg.sender];
        uint256 stake = info.stake;
        if (stake == 0) revert NoStakeToWithdraw();
        if (info.withdrawTime == 0) revert NoUnlockStakeCallYet();
        // solhint-disable-next-line not-rely-on-time
        if (info.withdrawTime > block.timestamp) revert StakeWithdrawalIsNotDue();
        info.unstakeDelaySec = 0;
        info.withdrawTime = 0;
        info.stake = 0;
        emit StakeWithdrawn(msg.sender, withdrawAddress, stake);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = withdrawAddress.call{value: stake}("");
        if (!success) revert FailedToWithdrawStake();
    }

    /**
     * @dev withdraw from the deposit.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external {
        DepositInfo storage info = deposits[msg.sender];
        if (withdrawAmount > info.deposit) revert WithdrawAmountIsTooLarge();
        info.deposit = uint112(info.deposit - withdrawAmount);
        emit Withdrawn(msg.sender, withdrawAddress, withdrawAmount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = withdrawAddress.call{value: withdrawAmount}("");
        if (!success) revert FailedToWithdraw();
    }

    /**
     * @dev Internal function to increase an account's deposited balance
     */
    function internalIncrementDeposit(address account, uint256 amount) internal {
        DepositInfo storage info = deposits[account];
        uint256 newAmount = info.deposit + amount;
        if (newAmount > type(uint112).max) revert DepositOverflow();
        info.deposit = uint112(newAmount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title Singleton Factory (EIP-2470)
 * @notice Exposes CREATE2 (EIP-1014) to deploy bytecode on deterministic addresses based on initialization code and salt.
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
interface ISingletonFactory {
    /**
     * @notice Deploys `_initCode` using `_salt` for defining the deterministic address.
     * @param initCode Initialization code.
     * @return createdContract Created contract address.
     */
    function deploy(bytes memory initCode) external returns (address payable createdContract);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../UserOperation.sol";

interface IPaymaster {
    enum PostOpMode {
        opSucceeded, // UserOp succeeded.
        opReverted, // UserOp reverted. still has to pay for gas.
        postOpReverted // UserOp succeeded, but caused postOp (in mode=opSucceeded) to revert. Now its a 2nd call, after user's op was deliberately reverted.
    }

    /**
     * @dev payment validation: check if paymaster agree to pay.
     * Must verify sender is the entryPoint.
     * Revert to reject this request.
     * Note that bundlers will reject this method if it changes the state, unless the paymaster is trusted (whitelisted)
     * The paymaster pre-pays using its deposit, and receive back a refund after the postOp method returns.
     * @param userOp the user operation
     * @param requestId hash of the user's request data.
     * @param maxCost the maximum cost of this transaction (based on maximum gas and gas price from userOp)
     * @return context value to send to a postOp
     *  zero length to signify postOp is not required.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 requestId,
        uint256 maxCost
    ) external returns (bytes memory context);

    /**
     * @dev post-operation handler.
     * Must verify sender is the entryPoint
     * @param mode enum with the following options:
     *      opSucceeded - user operation succeeded.
     *      opReverted  - user op reverted. still has to pay for gas.
     *      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.
     *                       Now this is the 2nd call, after user's op was deliberately reverted.
     * @param context - the context value returned by validatePaymasterUserOp
     * @param actualGasCost - actual gas used so far (without this postOp call).
     */
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Operation object specified in https://eips.ethereum.org/EIPS/eip-4337
 */
/**
 * User Operation struct
 * @param sender the sender account of this request
 * @param nonce unique value the sender uses to verify it is not a replay.
 * @param initCode if set, the account contract will be created by this constructor
 * @param callData the method call to execute on this account.
 * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp
 * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
 * @param maxFeePerGas same as EIP-1559 gas parameter
 * @param maxPriorityFeePerGas same as EIP-1559 gas parameter
 * @param paymasterAndData if set, this field hold the paymaster address and "paymaster-specific-data". the paymaster will pay for the transaction instead of the sender
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

library UserOperationLib {
    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := calldataload(userOp)
        }
        return address(uint160(data));
    }

    //relayer/miner might submit the TX with higher priorityFee, but the user should not
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
        //lighter signature scheme. must match UserOp.ts#packUserOp
        bytes calldata sig = userOp.signature;
        // copy directly the userOp from calldata up to (but not including) the signature.
        // this encoding depends on the ABI encoding of calldata, but is much lighter to copy
        // than referencing each field separately.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ofs := userOp
            let len := sub(sub(sig.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Utils {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function getOffsetOfMemoryBytes(bytes memory data) internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := data
        }
    }

    function getMemoryBytesFromOffset(uint256 offset) internal pure returns (bytes memory data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := offset
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../UserOperation.sol";

/**
 * @dev Wallet interface specified in https://eips.ethereum.org/EIPS/eip-4337.
 */
interface IEIP4337Wallet {
    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param requestId hash of the user's request data. can be used as the basis for signature.
     * @param aggregator the aggregator used to validate the signature. NULL for non-aggregated signature wallets.
     * @param missingWalletFunds missing funds on the wallet's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 requestId,
        address aggregator,
        uint256 missingWalletFunds
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./EIP4337Wallet/IEIP4337Wallet.sol";

/**
 * Aggregated wallet, that support IAggregator.
 * - the validateUserOp will be called only after the aggregator validated this wallet (with all other wallets of this aggregator).
 * - the validateUserOp MUST valiate the aggregator parameter, and MAY ignore the userOp.signature field.
 */
interface IAggregatedWallet is IEIP4337Wallet {
    /**
     * @return address of the signature aggregator the wallet supports.
     */
    function getAggregator() external view returns (address);
}