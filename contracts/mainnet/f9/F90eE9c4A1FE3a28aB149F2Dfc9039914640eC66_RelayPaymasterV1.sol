// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IForwarder {

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntil;
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

    function getNonce(address from)
    external view
    returns(uint256);

    /**
     * verify the transaction would execute.
     * validate the signature and the nonce of the request.
     * revert if either signature or nonce are incorrect.
     * also revert if domainSeparator or requestTypeHash are not registered.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    ) external view;

    /**
     * execute a transaction
     * @param forwardRequest - all transaction parameters
     * @param domainSeparator - domain used when signing this request
     * @param requestTypeHash - request type used when signing this request.
     * @param suffixData - the extension data used when signing this request.
     * @param signature - signature to validate.
     *
     * the transaction is verified, and then executed.
     * the success and ret of "call" are returned.
     * This method would revert only verification errors. target errors
     * are reported using the returned "success" and ret string
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    )
    external payable
    returns (bool success, bytes memory ret);

    /**
     * Register a new Request typehash.
     * @param typeName - the name of the request type.
     * @param typeSuffix - any extra data after the generic params.
     *  (must add at least one param. The generic ForwardRequest type is always registered by the constructor)
     */
    function registerRequestType(string calldata typeName, string calldata typeSuffix) external;

    /**
     * Register a new domain separator.
     * The domain separator must have the following fields: name,version,chainId, verifyingContract.
     * the chainId is the current network's chainId, and the verifyingContract is this forwarder.
     * This method is given the domain name and version to create and register the domain separator value.
     * @param name the domain's display name
     * @param version the domain/protocol version
     */
    function registerDomainSeparator(string calldata name, string calldata version) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../utils/GsnTypes.sol";

interface IPaymaster {

    /**
     * @param acceptanceBudget -
     *      Paymaster expected gas budget to accept (or reject) a request
     *      This a gas required by any calculations that might need to reject the
     *      transaction, by preRelayedCall, forwarder and recipient.
     *      See value in BasePaymaster.PAYMASTER_ACCEPTANCE_BUDGET
     *      Transaction that gets rejected above that gas usage is on the paymaster's expense.
     *      As long this value is above preRelayedCallGasLimit (see defaults in BasePaymaster), the
     *      Paymaster is guaranteed it will never pay for rejected transactions.
     *      If this value is below preRelayedCallGasLimt, it might might make Paymaster open to a "griefing" attack.
     *
     *      Specifying value too high might make the call rejected by some relayers.
     *
     *      From a Relay's point of view, this is the highest gas value a paymaster might "grief" the relay,
     *      since the paymaster will pay anything above that (regardless if the tx reverts)
     *
     * @param preRelayedCallGasLimit - the max gas usage of preRelayedCall. any revert (including OOG)
     *      of preRelayedCall is a reject by the paymaster.
     *      as long as acceptanceBudget is above preRelayedCallGasLimit, any such revert (including OOG)
     *      is not payed by the paymaster.
     * @param postRelayedCallGasLimit - the max gas usage of postRelayedCall.
     *      note that an OOG will revert the transaction, but the paymaster already committed to pay,
     *      so the relay will get compensated, at the expense of the paymaster
     */
    struct GasAndDataLimits {
        uint256 acceptanceBudget;
        uint256 preRelayedCallGasLimit;
        uint256 postRelayedCallGasLimit;
        uint256 calldataSizeLimit;
    }

    /**
     * Return the Gas Limits and msg.data max size constants used by the Paymaster.
     */
    function getGasAndDataLimits()
    external
    view
    returns (
        GasAndDataLimits memory limits
    );

    function trustedForwarder() external view returns (address);

/**
 * return the relayHub of this contract.
 */
    function getHubAddr() external view returns (address);

    /**
     * Can be used to determine if the contract can pay for incoming calls before making any.
     * @return the paymaster's deposit in the RelayHub.
     */
    function getRelayHubDeposit() external view returns (uint256);

    /**
     * Called by Relay (and RelayHub), to validate if the paymaster agrees to pay for this call.
     *
     * MUST be protected with relayHubOnly() in case it modifies state.
     *
     * The Paymaster rejects by the following "revert" operations
     *  - preRelayedCall() method reverts
     *  - the forwarder reverts because of nonce or signature error
     *  - the paymaster returned "rejectOnRecipientRevert", and the recipient contract reverted.
     * In any of the above cases, all paymaster calls (and recipient call) are reverted.
     * In any other case, the paymaster agrees to pay for the gas cost of the transaction (note
     *  that this includes also postRelayedCall revert)
     *
     * The rejectOnRecipientRevert flag means the Paymaster "delegate" the rejection to the recipient
     *  code.  It also means the Paymaster trust the recipient to reject fast: both preRelayedCall,
     *  forwarder check and receipient checks must fit into the GasLimits.acceptanceBudget,
     *  otherwise the TX is paid by the Paymaster.
     *
     *  @param relayRequest - the full relay request structure
     *  @param signature - user's EIP712-compatible signature of the {@link relayRequest}.
     *              Note that in most cases the paymaster shouldn't try use it at all. It is always checked
     *              by the forwarder immediately after preRelayedCall returns.
     *  @param approvalData - extra dapp-specific data (e.g. signature from trusted party)
     *  @param maxPossibleGas - based on values returned from {@link getGasAndDataLimits},
     *         the RelayHub will calculate the maximum possible amount of gas the user may be charged for.
     *         In order to convert this value to wei, the Paymaster has to call "relayHub.calculateCharge()"
     *  return:
     *      a context to be passed to postRelayedCall
     *      rejectOnRecipientRevert - TRUE if paymaster want to reject the TX if the recipient reverts.
     *          FALSE means that rejects by the recipient will be completed on chain, and paid by the paymaster.
     *          (note that in the latter case, the preRelayedCall and postRelayedCall are not reverted).
     */
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    returns (bytes memory context, bool rejectOnRecipientRevert);

    /**
     * This method is called after the actual relayed function call.
     * It may be used to record the transaction (e.g. charge the caller by some contract logic) for this call.
     *
     * MUST be protected with relayHubOnly() in case it modifies state.
     *
     * @param context - the call context, as returned by the preRelayedCall
     * @param success - true if the relayed call succeeded, false if it reverted
     * @param gasUseWithoutPost - the actual amount of gas used by the entire transaction, EXCEPT
     *        the gas used by the postRelayedCall itself.
     * @param relayData - the relay params of the request. can be used by relayHub.calculateCharge()
     *
     * Revert in this functions causes a revert of the client's relayed call (and preRelayedCall(), but the Paymaster
     * is still committed to pay the relay for the entire transaction.
     */
    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external;

    function versionPaymaster() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../utils/GsnTypes.sol";
import "./IStakeManager.sol";

interface IRelayHub {
    struct RelayHubConfig {
        // maximum number of worker accounts allowed per manager
        uint256 maxWorkerCount;
        // Gas set aside for all relayCall() instructions to prevent unexpected out-of-gas exceptions
        uint256 gasReserve;
        // Gas overhead to calculate gasUseWithoutPost
        uint256 postOverhead;
        // Gas cost of all relayCall() instructions after actual 'calculateCharge()'
        // Assume that relay has non-zero balance (costs 15'000 more otherwise).
        uint256 gasOverhead;
        // Maximum funds that can be deposited at once. Prevents user error by disallowing large deposits.
        uint256 maximumRecipientDeposit;
        // Minimum unstake delay blocks of a relay manager's stake on the StakeManager
        uint256 minimumUnstakeDelay;
        // Minimum stake a relay can have. An attack on the network will never cost less than half this value.
        uint256 minimumStake;
        // relayCall()'s msg.data upper bound gas cost per byte
        uint256 dataGasCostPerByte;
        // relayCalls() minimal gas overhead when calculating cost of putting tx on chain.
        uint256 externalCallDataCostOverhead;
    }

    event RelayHubConfigured(RelayHubConfig config);

    /// Emitted when a relay server registers or updates its details
    /// Looking at these events lets a client discover relay servers
    event RelayServerRegistered(
        address indexed relayManager,
        uint256 baseRelayFee,
        uint256 pctRelayFee,
        string relayUrl
    );

    /// Emitted when relays are added by a relayManager
    event RelayWorkersAdded(
        address indexed relayManager,
        address[] newRelayWorkers,
        uint256 workersCount
    );

    /// Emitted when an account withdraws funds from RelayHub.
    event Withdrawn(
        address indexed account,
        address indexed dest,
        uint256 amount
    );

    /// Emitted when depositFor is called, including the amount and account that was funded.
    event Deposited(
        address indexed paymaster,
        address indexed from,
        uint256 amount
    );

    /// Emitted when an attempt to relay a call fails and Paymaster does not accept the transaction.
    /// The actual relayed call was not executed, and the recipient not charged.
    /// @param reason contains a revert reason returned from preRelayedCall or forwarder.
    event TransactionRejectedByPaymaster(
        address indexed relayManager,
        address indexed paymaster,
        address indexed from,
        address to,
        address relayWorker,
        bytes4 selector,
        uint256 innerGasUsed,
        bytes reason
    );

    /// Emitted when a transaction is relayed. Note that the actual encoded function might be reverted: this will be
    /// indicated in the status field.
    /// Useful when monitoring a relay's operation and relayed calls to a contract.
    /// Charge is the ether value deducted from the recipient's balance, paid to the relay's manager.
    event TransactionRelayed(
        address indexed relayManager,
        address indexed relayWorker,
        address indexed from,
        address to,
        address paymaster,
        bytes4 selector,
        RelayCallStatus status,
        uint256 charge
    );

    event TransactionResult(
        RelayCallStatus status,
        bytes returnValue
    );

    event HubDeprecated(uint256 fromBlock);

    /// Reason error codes for the TransactionRelayed event
    /// @param OK - the transaction was successfully relayed and execution successful - never included in the event
    /// @param RelayedCallFailed - the transaction was relayed, but the relayed call failed
    /// @param RejectedByPreRelayed - the transaction was not relayed due to preRelatedCall reverting
    /// @param RejectedByForwarder - the transaction was not relayed due to forwarder check (signature,nonce)
    /// @param PostRelayedFailed - the transaction was relayed and reverted due to postRelatedCall reverting
    /// @param PaymasterBalanceChanged - the transaction was relayed and reverted due to the paymaster balance change
    enum RelayCallStatus {
        OK,
        RelayedCallFailed,
        RejectedByPreRelayed,
        RejectedByForwarder,
        RejectedByRecipientRevert,
        PostRelayedFailed,
        PaymasterBalanceChanged
    }

    /// Add new worker addresses controlled by sender who must be a staked Relay Manager address.
    /// Emits a RelayWorkersAdded event.
    /// This function can be called multiple times, emitting new events
    function addRelayWorkers(address[] calldata newRelayWorkers) external;

    function registerRelayServer(uint256 baseRelayFee, uint256 pctRelayFee, string calldata url) external;

    // Balance management

    /// Deposits ether for a contract, so that it can receive (and pay for) relayed transactions. Unused balance can only
    /// be withdrawn by the contract itself, by calling withdraw.
    /// Emits a Deposited event.
    function depositFor(address target) external payable;

    /// Withdraws from an account's balance, sending it back to it. Relay managers call this to retrieve their revenue, and
    /// contracts can also use it to reduce their funding.
    /// Emits a Withdrawn event.
    function withdraw(uint256 amount, address payable dest) external;

    // Relaying


    /// Relays a transaction. For this to succeed, multiple conditions must be met:
    ///  - Paymaster's "preRelayCall" method must succeed and not revert
    ///  - the sender must be a registered Relay Worker that the user signed
    ///  - the transaction's gas price must be equal or larger than the one that was signed by the sender
    ///  - the transaction must have enough gas to run all internal transactions if they use all gas available to them
    ///  - the Paymaster must have enough balance to pay the Relay Worker for the scenario when all gas is spent
    ///
    /// If all conditions are met, the call will be relayed and the recipient charged.
    ///
    /// Arguments:
    /// @param maxAcceptanceBudget - max valid value for paymaster.getGasLimits().acceptanceBudget
    /// @param relayRequest - all details of the requested relayed call
    /// @param signature - client's EIP-712 signature over the relayRequest struct
    /// @param approvalData: dapp-specific data forwarded to preRelayedCall.
    ///        This value is *not* verified by the Hub. For example, it can be used to pass a signature to the Paymaster
    /// @param externalGasLimit - the value passed as gasLimit to the transaction.
    ///
    /// Emits a TransactionRelayed event.
    function relayCall(
        uint maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint externalGasLimit
    )
    external
    returns (bool paymasterAccepted, bytes memory returnValue);

    function penalize(address relayWorker, address payable beneficiary) external;

    function setConfiguration(RelayHubConfig memory _config) external;

    // Deprecate hub (reverting relayCall()) from block number 'fromBlock'
    // Can only be called by owner
    function deprecateHub(uint256 fromBlock) external;

    /// The fee is expressed as a base fee in wei plus percentage on actual charge.
    /// E.g. a value of 40 stands for a 40% fee, so the recipient will be
    /// charged for 1.4 times the spent amount.
    function calculateCharge(uint256 gasUsed, GsnTypes.RelayData calldata relayData) external view returns (uint256);

    /* getters */

    /// Returns the whole hub configuration
    function getConfiguration() external view returns (RelayHubConfig memory config);

    function calldataGasCost(uint256 length) external view returns (uint256);

    function workerToManager(address worker) external view returns(address);

    function workerCount(address manager) external view returns(uint256);

    /// Returns an account's deposits. It can be either a deposit of a paymaster, or a revenue of a relay manager.
    function balanceOf(address target) external view returns (uint256);

    function stakeManager() external view returns (IStakeManager);

    function penalizer() external view returns (address);

    /// Uses StakeManager info to decide if the Relay Manager can be considered staked
    /// @return true if stake size and delay satisfy all requirements
    function isRelayManagerStaked(address relayManager) external view returns(bool);

    // Checks hubs' deprecation status
    function isDeprecated() external view returns (bool);

    // Returns the block number from which the hub no longer allows relaying calls.
    function deprecationBlock() external view returns (uint256);

    /// @return a SemVer-compliant version of the hub contract
    function versionHub() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../../../@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IStakeManager {

    /// Emitted when a stake or unstakeDelay are initialized or increased
    event StakeAdded(
        address indexed relayManager,
        address indexed owner,
        uint256 stake,
        uint256 unstakeDelay
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(
        address indexed relayManager,
        address indexed owner,
        uint256 withdrawBlock
    );

    /// Emitted when owner withdraws relayManager funds
    event StakeWithdrawn(
        address indexed relayManager,
        address indexed owner,
        uint256 amount
    );

    /// Emitted when an authorized Relay Hub penalizes a relayManager
    event StakePenalized(
        address indexed relayManager,
        address indexed beneficiary,
        uint256 reward
    );

    event HubAuthorized(
        address indexed relayManager,
        address indexed relayHub
    );

    event HubUnauthorized(
        address indexed relayManager,
        address indexed relayHub,
        uint256 removalBlock
    );

    event OwnerSet(
        address indexed relayManager,
        address indexed owner
    );

    /// @param stake - amount of ether staked for this relay
    /// @param unstakeDelay - number of blocks to elapse before the owner can retrieve the stake after calling 'unlock'
    /// @param withdrawBlock - first block number 'withdraw' will be callable, or zero if the unlock has not been called
    /// @param owner - address that receives revenue and manages relayManager's stake
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelay;
        uint256 withdrawBlock;
        address payable owner;
    }

    struct RelayHubInfo {
        uint256 removalBlock;
    }

    /// Set the owner of a Relay Manager. Called only by the RelayManager itself.
    /// Note that owners cannot transfer ownership - if the entry already exists, reverts.
    /// @param owner - owner of the relay (as configured off-chain)
    function setRelayManagerOwner(address payable owner) external;

    /// Only the owner can call this function. If the entry does not exist, reverts.
    /// @param relayManager - address that represents a stake entry and controls relay registrations on relay hubs
    /// @param unstakeDelay - number of blocks to elapse before the owner can retrieve the stake after calling 'unlock'
    function stakeForRelayManager(address relayManager, uint256 unstakeDelay) external payable;

    function unlockStake(address relayManager) external;

    function withdrawStake(address relayManager) external;

    function authorizeHubByOwner(address relayManager, address relayHub) external;

    function authorizeHubByManager(address relayHub) external;

    function unauthorizeHubByOwner(address relayManager, address relayHub) external;

    function unauthorizeHubByManager(address relayHub) external;

    function isRelayManagerStaked(address relayManager, address relayHub, uint256 minAmount, uint256 minUnstakeDelay)
    external
    view
    returns (bool);

    /// Slash the stake of the relay relayManager. In order to prevent stake kidnapping, burns half of stake on the way.
    /// @param relayManager - entry to penalize
    /// @param beneficiary - address that receives half of the penalty amount
    /// @param amount - amount to withdraw from stake
    function penalizeRelayManager(address relayManager, address payable beneficiary, uint256 amount) external;

    function getStakeInfo(address relayManager) external view returns (StakeInfo memory stakeInfo);

    function maxUnstakeDelay() external view returns (uint256);

    function versionSM() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../forwarder/IForwarder.sol";

interface GsnTypes {
    /// @notice gasPrice, pctRelayFee and baseRelayFee must be validated inside of the paymaster's preRelayedCall in order not to overpay
    struct RelayData {
        uint256 gasPrice;
        uint256 pctRelayFee;
        uint256 baseRelayFee;
        address relayWorker;
        address paymaster;
        address forwarder;
        bytes paymasterData;
        uint256 clientId;
    }

    //note: must start with the ForwardRequest to be an extension of the generic forwarder
    struct RelayRequest {
        IForwarder.ForwardRequest request;
        RelayData relayData;
    }
}

// SPDX-License-Identifier: MIT
// minimal bytes manipulation required by GSN
// a minimal subset from 0x/LibBytes
/* solhint-disable no-inline-assembly */
pragma solidity ^0.8.0;

library MinLibBytes {

    //truncate the given parameter (in-place) if its length is above the given maximum length
    // do nothing otherwise.
    //NOTE: solidity warns unless the method is marked "pure", but it DOES modify its parameter.
    function truncateInPlace(bytes memory data, uint256 maxlen) internal pure {
        if (data.length > maxlen) {
            assembly { mstore(data, maxlen) }
        }
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        require (b.length >= index + 20, "readAddress: data too short");

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        require(b.length >= index + 32, "readBytes32: data too short" );

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
        }
        return result;
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        require(b.length >= index + 4, "readBytes4: data too short");

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./libs/@openzeppelin/contracts/access/Ownable.sol";
import "./libs/@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./libs/@opengsn/contracts/src/interfaces/IPaymaster.sol";
import "./libs/@opengsn/contracts/src/interfaces/IRelayHub.sol";
import "./libs/@opengsn/contracts/src/utils/MinLibBytes.sol";

// accept everything.
// this paymaster accepts any request.
contract RelayPaymasterV1 is IPaymaster, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event PreRelayed();
    event PostRelayed();
    event RelayWorkerRegistered(address indexed worker);
    event RelayWorkerUnregistered(address indexed worker);

    bytes4 public constant PERMIT_METHOD_SIG = bytes4(0xd505accf);

    IRelayHub private _relayHub;
    address private _trustedForwarder;

    EnumerableSet.AddressSet private _allowedWorkers;

    //overhead of forwarder verify+signature, plus hub overhead.
    uint256 private _forwarderHubOverhead = 50000;
    uint256 private _preRelayedCallGasLimit = 100000;
    uint256 private _postRelayedCallGasLimit = 40000;
    uint256 private _paymasterAcceptanceBudget = _forwarderHubOverhead + _preRelayedCallGasLimit;
    uint256 private _calldataSizeLimit = 10500;

    constructor(address admin, address relayHub, address forwarder) Ownable() {
        setRelayHub(IRelayHub(relayHub));
        setTrustedForwarder(forwarder);
        _transferOwnership(admin);
    }

    modifier relayHubOnly() {
        require(msg.sender == getHubAddr(), "can only be called by RelayHub");
        _;
    }

    function getHubAddr() public view override returns (address) {
        return address(_relayHub);
    }

    function setRelayHub(IRelayHub hub) public onlyOwner {
        _relayHub = hub;
    }

    function trustedForwarder() external view override returns (address) {
        return _trustedForwarder;
    }

    function setTrustedForwarder(address forwarder) public onlyOwner {
        _trustedForwarder = forwarder;
    }

    function setGasAndDataLimits(
        uint256 forwarderHubOverhead,
        uint256 preRelayedCallGasLimit,
        uint256 postRelayedCallGasLimit,
        uint256 calldataSizeLimit
    ) external onlyOwner returns (IPaymaster.GasAndDataLimits memory limits) {
        _forwarderHubOverhead = forwarderHubOverhead;
        _preRelayedCallGasLimit = preRelayedCallGasLimit;
        _postRelayedCallGasLimit = postRelayedCallGasLimit;
        _calldataSizeLimit = calldataSizeLimit;
        _paymasterAcceptanceBudget = _forwarderHubOverhead + _preRelayedCallGasLimit;

        return getGasAndDataLimits();
    }

    function getGasAndDataLimits() public view override returns (IPaymaster.GasAndDataLimits memory limits) {
        return
            IPaymaster.GasAndDataLimits(
                _paymasterAcceptanceBudget,
                _preRelayedCallGasLimit,
                _postRelayedCallGasLimit,
                _calldataSizeLimit
            );
    }

    // worker whitelist management
    function registerRelayWorker(address worker) external onlyOwner {
        require(worker != address(0), "worker can not be zero address");
        require(_allowedWorkers.add(worker), "worker already registered");

        emit RelayWorkerRegistered(worker);
    }

    function unregisterRelayWorker(address worker) external onlyOwner {
        require(_allowedWorkers.remove(worker), "worker is not registered");

        emit RelayWorkerUnregistered(worker);
    }

    function isRegisteredRelayWorker(address worker) public view returns (bool) {
        return _allowedWorkers.contains(worker);
    }

    function getRegisteredRelayWorkerCount() external view returns (uint256) {
        return _allowedWorkers.length();
    }

    function getRegisteredRelayWorkerAt(uint256 index) external view returns (address) {
        return _allowedWorkers.at(index);
    }

    function getRegisteredRelayWorkers() external view returns (address[] memory) {
        return _allowedWorkers.values();
    }

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    ) external override relayHubOnly returns (bytes memory context, bool revertOnRecipientRevert) {
        (signature, approvalData, maxPossibleGas);

        require(
            isRegisteredRelayWorker(relayRequest.relayData.relayWorker),
            "preRelayedCall: relay worker is not allowed worker"
        );

        if (relayRequest.relayData.paymasterData.length > 32) {
            address token = MinLibBytes.readAddress(relayRequest.relayData.paymasterData, 12);
            require(
                PERMIT_METHOD_SIG == MinLibBytes.readBytes4(relayRequest.relayData.paymasterData, 32),
                "preRelayedCall: paymasterData has invalid permit method sig"
            );

            // execute permit method for this token
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = token.call(relayRequest.relayData.paymasterData[32:]);
            require(success, "preRelayedCall: permit call reverted");
        }

        emit PreRelayed();

        return ("", false);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external override relayHubOnly {
        (context, success, gasUseWithoutPost, relayData);

        emit PostRelayed();
    }

    function versionPaymaster() external pure override returns (string memory) {
        return "2.2.5+relay.paymaster.v1";
    }

    /// check current deposit on relay hub.
    function getRelayHubDeposit() external view override returns (uint256) {
        return _relayHub.balanceOf(address(this));
    }

    // any money moved into the paymaster is transferred as a deposit.
    // This way, we don't need to understand the RelayHub API in order to replenish
    // the paymaster.
    receive() external payable {
        require(address(_relayHub) != address(0), "relay hub address not set");
        _relayHub.depositFor{value: msg.value}(address(this));
    }

    /// withdraw deposit from relayHub
    function withdrawRelayHubDepositTo(uint256 amount, address payable target) external onlyOwner {
        _relayHub.withdraw(amount, target);
    }
}