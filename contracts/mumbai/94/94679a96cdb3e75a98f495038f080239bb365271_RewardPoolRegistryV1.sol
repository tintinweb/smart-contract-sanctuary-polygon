// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/VRFV2WrapperInterface.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./utils/GsnTypes.sol";
import "./interfaces/IPaymaster.sol";
import "./interfaces/IRelayHub.sol";
import "./utils/GsnEip712Library.sol";
import "./forwarder/IForwarder.sol";

/**
 * @notice An abstract base class to be inherited by a concrete Paymaster.
 * A subclass must implement:
 *  - preRelayedCall
 *  - postRelayedCall
 */
abstract contract BasePaymaster is IPaymaster, Ownable, ERC165 {
    using ERC165Checker for address;

    IRelayHub internal relayHub;
    address private _trustedForwarder;

    /// @inheritdoc IPaymaster
    function getRelayHub() public override view returns (address) {
        return address(relayHub);
    }

    //overhead of forwarder verify+signature, plus hub overhead.
    uint256 constant public FORWARDER_HUB_OVERHEAD = 50000;

    //These parameters are documented in IPaymaster.GasAndDataLimits
    uint256 constant public PRE_RELAYED_CALL_GAS_LIMIT = 100000;
    uint256 constant public POST_RELAYED_CALL_GAS_LIMIT = 110000;
    uint256 constant public PAYMASTER_ACCEPTANCE_BUDGET = PRE_RELAYED_CALL_GAS_LIMIT + FORWARDER_HUB_OVERHEAD;
    uint256 constant public CALLDATA_SIZE_LIMIT = 10500;

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IPaymaster).interfaceId ||
            interfaceId == type(Ownable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IPaymaster
    function getGasAndDataLimits()
    public
    override
    virtual
    view
    returns (
        IPaymaster.GasAndDataLimits memory limits
    ) {
        return IPaymaster.GasAndDataLimits(
            PAYMASTER_ACCEPTANCE_BUDGET,
            PRE_RELAYED_CALL_GAS_LIMIT,
            POST_RELAYED_CALL_GAS_LIMIT,
            CALLDATA_SIZE_LIMIT
        );
    }

    /**
     * @notice this method must be called from preRelayedCall to validate that the forwarder
     * is approved by the paymaster as well as by the recipient contract.
     */
    function _verifyForwarder(GsnTypes.RelayRequest calldata relayRequest)
    internal
    virtual
    view
    {
        require(getTrustedForwarder() == relayRequest.relayData.forwarder, "Forwarder is not trusted");
        GsnEip712Library.verifyForwarderTrusted(relayRequest);
    }

    function _verifyRelayHubOnly() internal virtual view {
        require(msg.sender == getRelayHub(), "can only be called by RelayHub");
    }

    function _verifyValue(GsnTypes.RelayRequest calldata relayRequest) internal virtual view{
        require(relayRequest.request.value == 0, "value transfer not supported");
    }

    function _verifyPaymasterData(GsnTypes.RelayRequest calldata relayRequest) internal virtual view {
        require(relayRequest.relayData.paymasterData.length == 0, "should have no paymasterData");
    }

    function _verifyApprovalData(bytes calldata approvalData) internal virtual view{
        require(approvalData.length == 0, "should have no approvalData");
    }

    /**
     * @notice The owner of the Paymaster can change the instance of the RelayHub this Paymaster works with.
     * :warning: **Warning** :warning: The deposit on the previous RelayHub must be withdrawn first.
     */
    function setRelayHub(IRelayHub hub) public onlyOwner {
        require(address(hub).supportsInterface(type(IRelayHub).interfaceId), "target is not a valid IRelayHub");
        relayHub = hub;
    }

    /**
     * @notice The owner of the Paymaster can change the instance of the Forwarder this Paymaster works with.
     * @notice the Recipients must trust this Forwarder as well in order for the configuration to remain functional.
     */
    function setTrustedForwarder(address forwarder) public virtual onlyOwner {
        require(forwarder.supportsInterface(type(IForwarder).interfaceId), "target is not a valid IForwarder");
        _trustedForwarder = forwarder;
    }

    function getTrustedForwarder() public virtual view override returns (address){
        return _trustedForwarder;
    }

    /**
     * @notice Any native Ether transferred into the paymaster is transferred as a deposit to the RelayHub.
     * This way, we don't need to understand the RelayHub API in order to replenish the paymaster.
     */
    receive() external virtual payable {
        require(address(relayHub) != address(0), "relay hub address not set");
        relayHub.depositFor{value:msg.value}(address(this));
    }

    /**
     * @notice Withdraw deposit from the RelayHub.
     * @param amount The amount to be subtracted from the sender.
     * @param target The target to which the amount will be transferred.
     */
    function withdrawRelayHubDepositTo(uint256 amount, address payable target) public onlyOwner {
        relayHub.withdraw(target, amount);
    }

    /// @inheritdoc IPaymaster
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    returns (bytes memory, bool) {
        _verifyRelayHubOnly();
        _verifyForwarder(relayRequest);
        _verifyValue(relayRequest);
        _verifyPaymasterData(relayRequest);
        _verifyApprovalData(approvalData);
        return _preRelayedCall(relayRequest, signature, approvalData, maxPossibleGas);
    }


    /**
     * @notice internal logic the paymasters need to provide to select which transactions they are willing to pay for
     * @notice see the documentation for `IPaymaster::preRelayedCall` for details
     */
    function _preRelayedCall(
        GsnTypes.RelayRequest calldata,
        bytes calldata,
        bytes calldata,
        uint256
    )
    internal
    virtual
    returns (bytes memory, bool);

    /// @inheritdoc IPaymaster
    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    external
    override
    {
        _verifyRelayHubOnly();
        _postRelayedCall(context, success, gasUseWithoutPost, relayData);
    }

    /**
     * @notice internal logic the paymasters need to provide if they need to take some action after the transaction
     * @notice see the documentation for `IPaymaster::postRelayedCall` for details
     */
    function _postRelayedCall(
        bytes calldata,
        bool,
        uint256,
        GsnTypes.RelayData calldata
    )
    internal
    virtual;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @title The Forwarder Interface
 * @notice The contracts implementing this interface take a role of authorization, authentication and replay protection
 * for contracts that choose to trust a `Forwarder`, instead of relying on a mechanism built into the Ethereum protocol.
 *
 * @notice if the `Forwarder` contract decides that an incoming `ForwardRequest` is valid, it must append 20 bytes that
 * represent the caller to the `data` field of the request and send this new data to the target address (the `to` field)
 *
 * :warning: **Warning** :warning: The Forwarder can have a full control over a `Recipient` contract.
 * Any vulnerability in a `Forwarder` implementation can make all of its `Recipient` contracts susceptible!
 * Recipient contracts should only trust forwarders that passed through security audit,
 * otherwise they are susceptible to identity theft.
 */
interface IForwarder is IERC165 {

    /**
     * @notice A representation of a request for a `Forwarder` to send `data` on behalf of a `from` to a target (`to`).
     */
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntilTime;
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

    /**
     * @param from The address of a sender.
     * @return The nonce for this address.
     */
    function getNonce(address from)
    external view
    returns(uint256);

    /**
     * @notice Verify the transaction is valid and can be executed.
     * Implementations must validate the signature and the nonce of the request are correct.
     * Does not revert and returns successfully if the input is valid.
     * Reverts if any validation has failed. For instance, if either signature or nonce are incorrect.
     * Reverts if `domainSeparator` or `requestTypeHash` are not registered as well.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    ) external view;

    /**
     * @notice Executes a transaction specified by the `ForwardRequest`.
     * The transaction is first verified and then executed.
     * The success flag and returned bytes array of the `CALL` are returned as-is.
     *
     * This method would revert only in case of a verification error.
     *
     * All the target errors are reported using the returned success flag and returned bytes array.
     *
     * @param forwardRequest All requested transaction parameters.
     * @param domainSeparator The domain used when signing this request.
     * @param requestTypeHash The request type used when signing this request.
     * @param suffixData The ABI-encoded extension data for the current `RequestType` used when signing this request.
     * @param signature The client signature to be validated.
     *
     * @return success The success flag of the underlying `CALL` to the target address.
     * @return ret The byte array returned by the underlying `CALL` to the target address.
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
     * @notice Register a new Request typehash.
     *
     * @notice This is necessary for the Forwarder to be able to verify the signatures conforming to the ERC-712.
     *
     * @param typeName The name of the request type.
     * @param typeSuffix Any extra data after the generic params. Must contain add at least one param.
     * The generic ForwardRequest type is always registered by the constructor.
     */
    function registerRequestType(string calldata typeName, string calldata typeSuffix) external;

    /**
     * @notice Register a new domain separator.
     *
     * @notice This is necessary for the Forwarder to be able to verify the signatures conforming to the ERC-712.
     *
     * @notice The domain separator must have the following fields: `name`, `version`, `chainId`, `verifyingContract`.
     * The `chainId` is the current network's `chainId`, and the `verifyingContract` is this Forwarder's address.
     * This method accepts the domain name and version to create and register the domain separator value.
     * @param name The domain's display name.
     * @param version The domain/protocol version.
     */
    function registerDomainSeparator(string calldata name, string calldata version) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "../utils/GsnTypes.sol";

/**
 * @title The Paymaster Interface
 * @notice Contracts implementing this interface exist to make decision about paying the transaction fee to the relay.
 *
 * @notice There are two callbacks here that are executed by the RelayHub: `preRelayedCall` and `postRelayedCall`.
 *
 * @notice It is recommended that your implementation inherits from the abstract BasePaymaster contract.
*/
interface IPaymaster is IERC165 {
    /**
     * @notice The limits this Paymaster wants to be imposed by the RelayHub on user input. See `getGasAndDataLimits`.
     */
    struct GasAndDataLimits {
        uint256 acceptanceBudget;
        uint256 preRelayedCallGasLimit;
        uint256 postRelayedCallGasLimit;
        uint256 calldataSizeLimit;
    }

    /**
     * @notice Return the Gas Limits for Paymaster's functions and maximum msg.data length values for this Paymaster.
     * This function allows different paymasters to have different properties without changes to the RelayHub.
     * @return limits An instance of the `GasAndDataLimits` struct
     *
     * ##### `acceptanceBudget`
     * If the transactions consumes more than `acceptanceBudget` this Paymaster will be charged for gas no matter what.
     * Transaction that gets rejected after consuming more than `acceptanceBudget` gas is on this Paymaster's expense.
     *
     * Should be set to an amount gas this Paymaster expects to spend deciding whether to accept or reject a request.
     * This includes gas consumed by calculations in the `preRelayedCall`, `Forwarder` and the recipient contract.
     *
     * :warning: **Warning** :warning: As long this value is above `preRelayedCallGasLimit`
     * (see defaults in `BasePaymaster`), the Paymaster is guaranteed it will never pay for rejected transactions.
     * If this value is below `preRelayedCallGasLimit`, it might might make Paymaster open to a "griefing" attack.
     *
     * The relayers should prefer lower `acceptanceBudget`, as it improves their chances of being compensated.
     * From a Relay's point of view, this is the highest gas value a bad Paymaster may cost the relay,
     * since the paymaster will pay anything above that value regardless of whether the transaction succeeds or reverts.
     * Specifying value too high might make the call rejected by relayers (see `maxAcceptanceBudget` in server config).
     *
     * ##### `preRelayedCallGasLimit`
     * The max gas usage of preRelayedCall. Any revert of the `preRelayedCall` is a request rejection by the paymaster.
     * As long as `acceptanceBudget` is above `preRelayedCallGasLimit`, any such revert is not payed by the paymaster.
     *
     * ##### `postRelayedCallGasLimit`
     * The max gas usage of postRelayedCall. The Paymaster is not charged for the maximum, only for actually used gas.
     * Note that an OOG will revert the inner transaction, but the paymaster will be charged for it anyway.
     */
    function getGasAndDataLimits()
    external
    view
    returns (
        GasAndDataLimits memory limits
    );

    /**
     * @notice :warning: **Warning** :warning: using incorrect Forwarder may cause the Paymaster to agreeing to pay for invalid transactions.
     * @return trustedForwarder The address of the `Forwarder` that is trusted by this Paymaster to execute the requests.
     */
    function getTrustedForwarder() external view returns (address trustedForwarder);

    /**
     * @return relayHub The address of the `RelayHub` that is trusted by this Paymaster to execute the requests.
     */
    function getRelayHub() external view returns (address relayHub);

    /**
     * @notice Called by the Relay in view mode and later by the `RelayHub` on-chain to validate that
     * the Paymaster agrees to pay for this call.
     *
     * The request is considered to be rejected by the Paymaster in one of the following conditions:
     *  - `preRelayedCall()` method reverts
     *  - the `Forwarder` reverts because of nonce or signature error
     *  - the `Paymaster` returned `rejectOnRecipientRevert: true` and the recipient contract reverted
     *    (and all that did not consume more than `acceptanceBudget` gas).
     *
     * In any of the above cases, all Paymaster calls and the recipient call are reverted.
     * In any other case the Paymaster will pay for the gas cost of the transaction.
     * Note that even if `postRelayedCall` is reverted the Paymaster will be charged.
     *

     * @param relayRequest - the full relay request structure
     * @param signature - user's EIP712-compatible signature of the `relayRequest`.
     * Note that in most cases the paymaster shouldn't try use it at all. It is always checked
     * by the forwarder immediately after preRelayedCall returns.
     * @param approvalData - extra dapp-specific data (e.g. signature from trusted party)
     * @param maxPossibleGas - based on values returned from `getGasAndDataLimits`
     * the RelayHub will calculate the maximum possible amount of gas the user may be charged for.
     * In order to convert this value to wei, the Paymaster has to call "relayHub.calculateCharge()"
     *
     * @return context
     * A byte array to be passed to postRelayedCall.
     * Can contain any data needed by this Paymaster in any form or be empty if no extra data is needed.
     * @return rejectOnRecipientRevert
     * The flag that allows a Paymaster to "delegate" the rejection to the recipient code.
     * It also means the Paymaster trust the recipient to reject fast: both preRelayedCall,
     * forwarder check and recipient checks must fit into the GasLimits.acceptanceBudget,
     * otherwise the TX is paid by the Paymaster.
     * `true` if the Paymaster wants to reject the TX if the recipient reverts.
     * `false` if the Paymaster wants rejects by the recipient to be completed on chain and paid by the Paymaster.
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
     * @notice This method is called after the actual relayed function call.
     * It may be used to record the transaction (e.g. charge the caller by some contract logic) for this call.
     *
     * Revert in this functions causes a revert of the client's relayed call (and preRelayedCall(), but the Paymaster
     * is still committed to pay the relay for the entire transaction.
     *
     * @param context The call context, as returned by the preRelayedCall
     * @param success `true` if the relayed call succeeded, false if it reverted
     * @param gasUseWithoutPost The actual amount of gas used by the entire transaction, EXCEPT
     *        the gas used by the postRelayedCall itself.
     * @param relayData The relay params of the request. can be used by relayHub.calculateCharge()
     *
     */
    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external;

    /**
     * @return version The SemVer string of this Paymaster's version.
     */
    function versionPaymaster() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "../utils/GsnTypes.sol";
import "./IStakeManager.sol";

/**
 * @title The RelayHub interface
 * @notice The implementation of this interface provides all the information the GSN client needs to
 * create a valid `RelayRequest` and also serves as an entry point for such requests.
 *
 * @notice The RelayHub also handles all the related financial records and hold the balances of participants.
 * The Paymasters keep their Ether deposited in the `RelayHub` in order to pay for the `RelayRequest`s that thay choose
 * to pay for, and Relay Servers keep their earned Ether in the `RelayHub` until they choose to `withdraw()`
 *
 * @notice The RelayHub on each supported network only needs a single instance and there is usually no need for dApp
 * developers or Relay Server operators to redeploy, reimplement, modify or override the `RelayHub`.
 */
interface IRelayHub is IERC165 {
    /**
     * @notice A struct that contains all the parameters of the `RelayHub` that can be modified after the deployment.
     */
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
        // Minimum unstake delay seconds of a relay manager's stake on the StakeManager
        uint256 minimumUnstakeDelay;
        // Developers address
        address devAddress;
        // 0 < fee < 100, as percentage of total charge from paymaster to relayer
        uint8 devFee;
        // baseRelayFee The base fee the Relay Server charges for a single transaction in Ether, in wei.
        uint80 baseRelayFee;
        // pctRelayFee The percent of the total charge to add as a Relay Server fee to the total charge.
        uint16 pctRelayFee;
    }

    /// @notice Emitted when a configuration of the `RelayHub` is changed
    event RelayHubConfigured(RelayHubConfig config);

    /// @notice Emitted when relays are added by a relayManager
    event RelayWorkersAdded(
        address indexed relayManager,
        address[] newRelayWorkers,
        uint256 workersCount
    );

    /// @notice Emitted when an account withdraws funds from the `RelayHub`.
    event Withdrawn(
        address indexed account,
        address indexed dest,
        uint256 amount
    );

    /// @notice Emitted when `depositFor` is called, including the amount and account that was funded.
    event Deposited(
        address indexed paymaster,
        address indexed from,
        uint256 amount
    );

    /// @notice Emitted for each token configured for staking in setMinimumStakes
    event StakingTokenDataChanged(
        address token,
        uint256 minimumStake
    );

    /**
     * @notice Emitted when an attempt to relay a call fails and the `Paymaster` does not accept the transaction.
     * The actual relayed call was not executed, and the recipient not charged.
     * @param reason contains a revert reason returned from preRelayedCall or forwarder.
     */
    event TransactionRejectedByPaymaster(
        address indexed relayManager,
        address indexed paymaster,
        bytes32 indexed relayRequestID,
        address from,
        address to,
        address relayWorker,
        bytes4 selector,
        uint256 innerGasUsed,
        bytes reason
    );

    /**
     * @notice Emitted when a transaction is relayed. Note that the actual internal function call might be reverted.
     * The reason for a revert will be indicated in the `status` field of a corresponding `RelayCallStatus` value.
     * @notice `charge` is the Ether value deducted from the `Paymaster` balance.
     * The amount added to the `relayManager` balance will be lower if there is an activated `devFee` in the `config`.
     */
    event TransactionRelayed(
        address indexed relayManager,
        address indexed relayWorker,
        bytes32 indexed relayRequestID,
        address from,
        address to,
        address paymaster,
        bytes4 selector,
        RelayCallStatus status,
        uint256 charge
    );

    /// @notice This event is emitted in case the internal function returns a value or reverts with a revert string.
    event TransactionResult(
        RelayCallStatus status,
        bytes returnValue
    );

    /// @notice This event is emitted in case this `RelayHub` is deprecated and will stop serving transactions soon.
    event HubDeprecated(uint256 deprecationTime);

    /**
     * @notice This event is emitted in case a `relayManager` has been deemed "abandoned" for being
     * unresponsive for a prolonged period of time.
     * @notice This event means the entire balance of the relay has been transferred to the `devAddress`.
     */
    event AbandonedRelayManagerBalanceEscheated(
        address indexed relayManager,
        uint256 balance
    );

    /**
     * Error codes that describe all possible failure reasons reported in the `TransactionRelayed` event `status` field.
     *  @param OK The transaction was successfully relayed and execution successful - never included in the event.
     *  @param RelayedCallFailed The transaction was relayed, but the relayed call failed.
     *  @param RejectedByPreRelayed The transaction was not relayed due to preRelatedCall reverting.
     *  @param RejectedByForwarder The transaction was not relayed due to forwarder check (signature,nonce).
     *  @param PostRelayedFailed The transaction was relayed and reverted due to postRelatedCall reverting.
     *  @param PaymasterBalanceChanged The transaction was relayed and reverted due to the paymaster balance change.
     */
    enum RelayCallStatus {
        OK,
        RelayedCallFailed,
        RejectedByPreRelayed,
        RejectedByForwarder,
        RejectedByRecipientRevert,
        PostRelayedFailed,
        PaymasterBalanceChanged
    }

    /**
     * @notice Add new worker addresses controlled by the sender who must be a staked Relay Manager address.
     * Emits a `RelayWorkersAdded` event.
     * This function can be called multiple times, emitting new events.
     */
    function addRelayWorkers(address[] calldata newRelayWorkers) external;

    /**
     * @notice The `RelayRegistrar` callback to notify the `RelayHub` that this `relayManager` has updated registration.
     */
    function onRelayServerRegistered(address relayManager) external;

    // Balance management

    /**
     * @notice Deposits ether for a `Paymaster`, so that it can and pay for relayed transactions.
     * :warning: **Warning** :warning: Unused balance can only be withdrawn by the holder itself, by calling `withdraw`.
     * Emits a `Deposited` event.
     */
    function depositFor(address target) external payable;

    /**
     * @notice Withdraws from an account's balance, sending it back to the caller.
     * Relay Managers call this to retrieve their revenue, and `Paymasters` can also use it to reduce their funding.
     * Emits a `Withdrawn` event.
     */
    function withdraw(address payable dest, uint256 amount) external;

    /**
     * @notice Withdraws from an account's balance, sending funds to multiple provided addresses.
     * Relay Managers call this to retrieve their revenue, and `Paymasters` can also use it to reduce their funding.
     * Emits a `Withdrawn` event for each destination.
     */
    function withdrawMultiple(address payable[] memory dest, uint256[] memory amount) external;

    // Relaying


    /**
     * @notice Relays a transaction. For this to succeed, multiple conditions must be met:
     *  - `Paymaster`'s `preRelayCall` method must succeed and not revert.
     *  - the `msg.sender` must be a registered Relay Worker that the user signed to use.
     *  - the transaction's gas fees must be equal or larger than the ones that were signed by the sender.
     *  - the transaction must have enough gas to run all internal transactions if they use all gas available to them.
     *  - the `Paymaster` must have enough balance to pay the Relay Worker if all gas is spent.
     *
     * @notice If all conditions are met, the call will be relayed and the `Paymaster` charged.
     *
     * @param domainSeparatorName The name of the Domain Separator used to verify the EIP-712 signature
     * @param maxAcceptanceBudget The maximum valid value for `paymaster.getGasLimits().acceptanceBudget` to return.
     * @param relayRequest All details of the requested relayed call.
     * @param signature The client's EIP-712 signature over the `relayRequest` struct.
     * @param approvalData The dapp-specific data forwarded to the `Paymaster`'s `preRelayedCall` method.
     * This value is **not** verified by the `RelayHub` in any way.
     * As an example, it can be used to pass some kind of a third-party signature to the `Paymaster` for verification.
     *
     * Emits a `TransactionRelayed` event regardless of whether the transaction succeeded or failed.
     */
    function relayCall(
        string calldata domainSeparatorName,
        uint256 maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData
    )
    external
    returns (
        bool paymasterAccepted,
        uint256 charge,
        IRelayHub.RelayCallStatus status,
        bytes memory returnValue
    );

    /**
     * @notice In case the Relay Worker has been found to be in violation of some rules by the `Penalizer` contract,
     * the `Penalizer` will call this method to execute a penalization.
     * The `RelayHub` will look up the Relay Manager of the given Relay Worker and will forward the call to
     * the `StakeManager` contract. The `RelayHub` does not perform the actual penalization either.
     * @param relayWorker The address of the Relay Worker that committed a penalizable offense.
     * @param beneficiary The address that called the `Penalizer` and will receive a reward for it.
     */
    function penalize(address relayWorker, address payable beneficiary) external;

    /**
     * @notice Sets or changes the configuration of this `RelayHub`.
     * @param _config The new configuration.
     */
    function setConfiguration(RelayHubConfig memory _config) external;

    /**
     * @notice Sets or changes the minimum amount of a given `token` that needs to be staked so that the Relay Manager
     * is considered to be 'staked' by this `RelayHub`. Zero value means this token is not allowed for staking.
     * @param token An array of addresses of ERC-20 compatible tokens.
     * @param minimumStake An array of minimal amounts necessary for a corresponding token, in wei.
     */
    function setMinimumStakes(IERC20[] memory token, uint256[] memory minimumStake) external;

    /**
     * @notice Deprecate hub by reverting all incoming `relayCall()` calls starting from a given timestamp
     * @param _deprecationTime The timestamp in seconds after which the `RelayHub` stops serving transactions.
     */
    function deprecateHub(uint256 _deprecationTime) external;

    /**
     * @notice
     * @param relayManager
     */
    function escheatAbandonedRelayBalance(address relayManager) external;

    /**
     * @notice The fee is expressed as a base fee in wei plus percentage of the actual charge.
     * For example, a value '40' stands for a 40% fee, so the recipient will be charged for 1.4 times the spent amount.
     * @param gasUsed An amount of gas used by the transaction.
     * @param relayData The details of a transaction signed by the sender.
     * @return The calculated charge, in wei.
     */
    function calculateCharge(uint256 gasUsed, GsnTypes.RelayData calldata relayData) external view returns (uint256);

    /**
     * @notice The fee is expressed as a  percentage of the actual charge.
     * For example, a value '40' stands for a 40% fee, so the Relay Manager will only get 60% of the `charge`.
     * @param charge The amount of Ether in wei the Paymaster will be charged for this transaction.
     * @return The calculated devFee, in wei.
     */
    function calculateDevCharge(uint256 charge) external view returns (uint256);
    /* getters */

    /// @return config The configuration of the `RelayHub`.
    function getConfiguration() external view returns (RelayHubConfig memory config);

    /**
     * @param token An address of an ERC-20 compatible tokens.
     * @return The minimum amount of a given `token` that needs to be staked so that the Relay Manager
     * is considered to be 'staked' by this `RelayHub`. Zero value means this token is not allowed for staking.
     */
    function getMinimumStakePerToken(IERC20 token) external view returns (uint256);

    /**
     * @param worker An address of the Relay Worker.
     * @return The address of its Relay Manager.
     */
    function getWorkerManager(address worker) external view returns (address);

    /**
     * @param manager An address of the Relay Manager.
     * @return The count of Relay Workers associated with this Relay Manager.
     */
    function getWorkerCount(address manager) external view returns (uint256);

    /// @return An account's balance. It can be either a deposit of a `Paymaster`, or a revenue of a Relay Manager.
    function balanceOf(address target) external view returns (uint256);

    /// @return The `StakeManager` address for this `RelayHub`.
    function getStakeManager() external view returns (IStakeManager);

    /// @return The `Penalizer` address for this `RelayHub`.
    function getPenalizer() external view returns (address);

    /// @return The `RelayRegistrar` address for this `RelayHub`.
    function getRelayRegistrar() external view returns (address);

    /// @return The `BatchGateway` address for this `RelayHub`.
    function getBatchGateway() external view returns (address);

    /**
     * @notice Uses `StakeManager` to decide if the Relay Manager can be considered staked or not.
     * Returns if the stake's token, amount and delay satisfy all requirements, reverts otherwise.
     */
    function verifyRelayManagerStaked(address relayManager) external view;

    /**
     * @notice Uses `StakeManager` to check if the Relay Manager can be considered abandoned or not.
     * Returns true if the stake's abandonment time is in the past including the escheatment delay, false otherwise.
     */
    function isRelayEscheatable(address relayManager) external view returns (bool);

    /// @return `true` if the `RelayHub` is deprecated, `false` it it is not deprecated and can serve transactions.
    function isDeprecated() external view returns (bool);

    /// @return The timestamp from which the hub no longer allows relaying calls.
    function getDeprecationTime() external view returns (uint256);

    /// @return The block number in which the contract has been deployed.
    function getCreationBlock() external view returns (uint256);

    /// @return a SemVer-compliant version of the `RelayHub` contract.
    function versionHub() external view returns (string memory);

    /// @return A total measurable amount of gas left to current execution. Same as 'gasleft()' for pure EVMs.
    function aggregateGasleft() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title The StakeManager Interface
 * @notice In order to prevent an attacker from registering a large number of unresponsive relays, the GSN requires
 * the Relay Server to maintain a permanently locked stake in the system before being able to register.
 *
 * @notice Also, in some cases the behavior of a Relay Server may be found to be illegal by a `Penalizer` contract.
 * In such case, the stake will never be returned to the Relay Server operator and will be slashed.
 *
 * @notice An implementation of this interface is tasked with keeping Relay Servers' stakes, made in any ERC-20 token.
 * Note that the `RelayHub` chooses which ERC-20 tokens to support and how much stake is needed.
 */
interface IStakeManager is IERC165 {

    /// @notice Emitted when a `stake` or `unstakeDelay` are initialized or increased.
    event StakeAdded(
        address indexed relayManager,
        address indexed owner,
        IERC20 token,
        uint256 stake,
        uint256 unstakeDelay
    );

    /// @notice Emitted once a stake is scheduled for withdrawal.
    event StakeUnlocked(
        address indexed relayManager,
        address indexed owner,
        uint256 withdrawTime
    );

    /// @notice Emitted when owner withdraws `relayManager` funds.
    event StakeWithdrawn(
        address indexed relayManager,
        address indexed owner,
        IERC20 token,
        uint256 amount
    );

    /// @notice Emitted when an authorized `RelayHub` penalizes a `relayManager`.
    event StakePenalized(
        address indexed relayManager,
        address indexed beneficiary,
        IERC20 token,
        uint256 reward
    );

    /// @notice Emitted when a `relayManager` adds a new `RelayHub` to a list of authorized.
    event HubAuthorized(
        address indexed relayManager,
        address indexed relayHub
    );

    /// @notice Emitted when a `relayManager` removes a `RelayHub` from a list of authorized.
    event HubUnauthorized(
        address indexed relayManager,
        address indexed relayHub,
        uint256 removalTime
    );

    /// @notice Emitted when a `relayManager` sets its `owner`. This is necessary to prevent stake hijacking.
    event OwnerSet(
        address indexed relayManager,
        address indexed owner
    );

    /// @notice Emitted when a `burnAddress` is changed.
    event BurnAddressSet(
        address indexed burnAddress
    );

    /// @notice Emitted when a `devAddress` is changed.
    event DevAddressSet(
        address indexed devAddress
    );

    /// @notice Emitted if Relay Server is inactive for an `abandonmentDelay` and contract owner initiates its removal.
    event RelayServerAbandoned(
        address indexed relayManager,
        uint256 abandonedTime
    );

    /// @notice Emitted to indicate an action performed by a relay server to prevent it from being marked as abandoned.
    event RelayServerKeepalive(
        address indexed relayManager,
        uint256 keepaliveTime
    );

    /// @notice Emitted when the stake of an abandoned relayer has been confiscated and transferred to the `devAddress`.
    event AbandonedRelayManagerStakeEscheated(
        address indexed relayManager,
        address indexed owner,
        IERC20 token,
        uint256 amount
    );

    /**
     * @param stake - amount of ether staked for this relay
     * @param unstakeDelay - number of seconds to elapse before the owner can retrieve the stake after calling 'unlock'
     * @param withdrawTime - timestamp in seconds when 'withdraw' will be callable, or zero if the unlock has not been called
     * @param owner - address that receives revenue and manages relayManager's stake
     */
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelay;
        uint256 withdrawTime;
        uint256 abandonedTime;
        uint256 keepaliveTime;
        IERC20 token;
        address owner;
    }

    struct RelayHubInfo {
        uint256 removalTime;
    }

    /**
     * @param devAddress - the address that will receive the 'abandoned' stake
     * @param abandonmentDelay - the amount of time after which the relay can be marked as 'abandoned'
     * @param escheatmentDelay - the amount of time after which the abandoned relay's stake and balance may be withdrawn to the `devAddress`
     */
    struct AbandonedRelayServerConfig {
        address devAddress;
        uint256 abandonmentDelay;
        uint256 escheatmentDelay;
    }

    /**
     * @notice Set the owner of a Relay Manager. Called only by the RelayManager itself.
     * Note that owners cannot transfer ownership - if the entry already exists, reverts.
     * @param owner - owner of the relay (as configured off-chain)
     */
    function setRelayManagerOwner(address owner) external;

    /**
     * @notice Put a stake for a relayManager and set its unstake delay.
     * Only the owner can call this function. If the entry does not exist, reverts.
     * The owner must give allowance of the ERC-20 token to the StakeManager before calling this method.
     * It is the RelayHub who has a configurable list of minimum stakes per token. StakeManager accepts all tokens.
     * @param token The address of an ERC-20 token that is used by the relayManager as a stake
     * @param relayManager The address that represents a stake entry and controls relay registrations on relay hubs
     * @param unstakeDelay The number of seconds to elapse before an owner can retrieve the stake after calling `unlock`
     * @param amount The amount of tokens to be taken from the relayOwner and locked in the StakeManager as a stake
     */
    function stakeForRelayManager(IERC20 token, address relayManager, uint256 unstakeDelay, uint256 amount) external;

    /**
     * @notice Schedule the unlocking of the stake. The `unstakeDelay` must pass before owner can call `withdrawStake`.
     * @param relayManager The address of a Relay Manager whose stake is to be unlocked.
     */
    function unlockStake(address relayManager) external;
    /**
     * @notice Withdraw the unlocked stake.
     * @param relayManager The address of a Relay Manager whose stake is to be withdrawn.
     */
    function withdrawStake(address relayManager) external;

    /**
     * @notice Add the `RelayHub` to a list of authorized by this Relay Manager.
     * This allows the RelayHub to penalize this Relay Manager. The `RelayHub` cannot trust a Relay it cannot penalize.
     * @param relayManager The address of a Relay Manager whose stake is to be authorized for the new `RelayHub`.
     * @param relayHub The address of a `RelayHub` to be authorized.
     */
    function authorizeHubByOwner(address relayManager, address relayHub) external;

    /**
     * @notice Same as `authorizeHubByOwner` but can be called by the RelayManager itself.
     */
    function authorizeHubByManager(address relayHub) external;

    /**
     * @notice Remove the `RelayHub` from a list of authorized by this Relay Manager.
     * @param relayManager The address of a Relay Manager.
     * @param relayHub The address of a `RelayHub` to be unauthorized.
     */
    function unauthorizeHubByOwner(address relayManager, address relayHub) external;

    /**
     * @notice Same as `unauthorizeHubByOwner` but can be called by the RelayManager itself.
     */
    function unauthorizeHubByManager(address relayHub) external;

    /**
     * Slash the stake of the relay relayManager. In order to prevent stake kidnapping, burns part of stake on the way.
     * @param relayManager The address of a Relay Manager to be penalized.
     * @param beneficiary The address that receives part of the penalty amount.
     * @param amount A total amount of penalty to be withdrawn from stake.
     */
    function penalizeRelayManager(address relayManager, address beneficiary, uint256 amount) external;

    /**
     * @notice Allows the contract owner to set the given `relayManager` as abandoned after a configurable delay.
     * Its entire stake and balance will be taken from a relay if it does not respond to being marked as abandoned.
     */
    function markRelayAbandoned(address relayManager) external;

    /**
     * @notice If more than `abandonmentDelay` has passed since the last Keepalive transaction, and relay manager
     * has been marked as abandoned, and after that more that `escheatmentDelay` have passed, entire stake and
     * balance will be taken from this relay.
     */
    function escheatAbandonedRelayStake(address relayManager) external;

    /**
     * @notice Sets a new `keepaliveTime` for the given `relayManager`, preventing it from being marked as abandoned.
     * Can be called by an authorized `RelayHub` or by the `relayOwner` address.
     */
    function updateRelayKeepaliveTime(address relayManager) external;

    /**
     * @notice Check if the Relay Manager can be considered abandoned or not.
     * Returns true if the stake's abandonment time is in the past including the escheatment delay, false otherwise.
     */
    function isRelayEscheatable(address relayManager) external view returns(bool);

    /**
     * @notice Get the stake details information for the given Relay Manager.
     * @param relayManager The address of a Relay Manager.
     * @return stakeInfo The `StakeInfo` structure.
     * @return isSenderAuthorizedHub `true` if the `msg.sender` for this call was a `RelayHub` that is authorized now.
     * `false` if the `msg.sender` for this call is not authorized.
     */
    function getStakeInfo(address relayManager) external view returns (StakeInfo memory stakeInfo, bool isSenderAuthorizedHub);

    /**
     * @return The maximum unstake delay this `StakeManger` allows. This is to prevent locking money forever by mistake.
     */
    function getMaxUnstakeDelay() external view returns (uint256);

    /**
     * @notice Change the address that will receive the 'burned' part of the penalized stake.
     * This is done to prevent malicious Relay Server from penalizing itself and breaking even.
     */
    function setBurnAddress(address _burnAddress) external;

    /**
     * @return The address that will receive the 'burned' part of the penalized stake.
     */
    function getBurnAddress() external view returns (address);

    /**
     * @notice Change the address that will receive the 'abandoned' stake.
     * This is done to prevent Relay Servers that lost their keys from losing access to funds.
     */
    function setDevAddress(address _burnAddress) external;

    /**
     * @return The structure that contains all configuration values for the 'abandoned' stake.
     */
    function getAbandonedRelayServerConfig() external view returns (AbandonedRelayServerConfig memory);

    /**
     * @return the block number in which the contract has been deployed.
     */
    function getCreationBlock() external view returns (uint256);

    /**
     * @return a SemVer-compliant version of the `StakeManager` contract.
     */
    function versionSM() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/GsnTypes.sol";
import "../interfaces/IERC2771Recipient.sol";
import "../forwarder/IForwarder.sol";

import "./GsnUtils.sol";

/**
 * @title The ERC-712 Library for GSN
 * @notice Bridge Library to convert a GSN RelayRequest into a valid `ForwardRequest` for a `Forwarder`.
 */
library GsnEip712Library {
    // maximum length of return value/revert reason for 'execute' method. Will truncate result if exceeded.
    uint256 private constant MAX_RETURN_SIZE = 1024;

    //copied from Forwarder (can't reference string constants even from another library)
    string public constant GENERIC_PARAMS = "address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntilTime";

    bytes public constant RELAYDATA_TYPE = "RelayData(uint256 maxFeePerGas,uint256 maxPriorityFeePerGas,uint256 transactionCalldataGasUsed,address relayWorker,address paymaster,address forwarder,bytes paymasterData,uint256 clientId)";

    string public constant RELAY_REQUEST_NAME = "RelayRequest";
    string public constant RELAY_REQUEST_SUFFIX = string(abi.encodePacked("RelayData relayData)", RELAYDATA_TYPE));

    bytes public constant RELAY_REQUEST_TYPE = abi.encodePacked(
        RELAY_REQUEST_NAME,"(",GENERIC_PARAMS,",", RELAY_REQUEST_SUFFIX);

    bytes32 public constant RELAYDATA_TYPEHASH = keccak256(RELAYDATA_TYPE);
    bytes32 public constant RELAY_REQUEST_TYPEHASH = keccak256(RELAY_REQUEST_TYPE);


    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    function splitRequest(
        GsnTypes.RelayRequest calldata req
    )
    internal
    pure
    returns (
        bytes memory suffixData
    ) {
        suffixData = abi.encode(
            hashRelayData(req.relayData));
    }

    //verify that the recipient trusts the given forwarder
    // MUST be called by paymaster
    function verifyForwarderTrusted(GsnTypes.RelayRequest calldata relayRequest) internal view {
        (bool success, bytes memory ret) = relayRequest.request.to.staticcall(
            abi.encodeWithSelector(
                IERC2771Recipient.isTrustedForwarder.selector, relayRequest.relayData.forwarder
            )
        );
        require(success, "isTrustedForwarder: reverted");
        require(ret.length == 32, "isTrustedForwarder: bad response");
        require(abi.decode(ret, (bool)), "invalid forwarder for recipient");
    }

    function verifySignature(
        string memory domainSeparatorName,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature
    ) internal view {
        (bytes memory suffixData) = splitRequest(relayRequest);
        bytes32 _domainSeparator = domainSeparator(domainSeparatorName, relayRequest.relayData.forwarder);
        IForwarder forwarder = IForwarder(payable(relayRequest.relayData.forwarder));
        forwarder.verify(relayRequest.request, _domainSeparator, RELAY_REQUEST_TYPEHASH, suffixData, signature);
    }

    function verify(
        string memory domainSeparatorName,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature
    ) internal view {
        verifyForwarderTrusted(relayRequest);
        verifySignature(domainSeparatorName, relayRequest, signature);
    }

    function execute(
        string memory domainSeparatorName,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature
    ) internal returns (
        bool forwarderSuccess,
        bool callSuccess,
        bytes memory ret
    ) {
        (bytes memory suffixData) = splitRequest(relayRequest);
        bytes32 _domainSeparator = domainSeparator(domainSeparatorName, relayRequest.relayData.forwarder);
        /* solhint-disable-next-line avoid-low-level-calls */
        (forwarderSuccess, ret) = relayRequest.relayData.forwarder.call(
            abi.encodeWithSelector(IForwarder.execute.selector,
            relayRequest.request, _domainSeparator, RELAY_REQUEST_TYPEHASH, suffixData, signature
        ));
        if ( forwarderSuccess ) {

          //decode return value of execute:
          (callSuccess, ret) = abi.decode(ret, (bool, bytes));
        }
        truncateInPlace(ret);
    }

    //truncate the given parameter (in-place) if its length is above the given maximum length
    // do nothing otherwise.
    //NOTE: solidity warns unless the method is marked "pure", but it DOES modify its parameter.
    function truncateInPlace(bytes memory data) internal pure {
        MinLibBytes.truncateInPlace(data, MAX_RETURN_SIZE);
    }

    function domainSeparator(string memory name, address forwarder) internal view returns (bytes32) {
        return hashDomain(EIP712Domain({
            name : name,
            version : "3",
            chainId : getChainID(),
            verifyingContract : forwarder
            }));
    }

    function getChainID() internal view returns (uint256 id) {
        /* solhint-disable no-inline-assembly */
        assembly {
            id := chainid()
        }
    }

    function hashDomain(EIP712Domain memory req) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(req.name)),
                keccak256(bytes(req.version)),
                req.chainId,
                req.verifyingContract));
    }

    function hashRelayData(GsnTypes.RelayData calldata req) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                RELAYDATA_TYPEHASH,
                req.maxFeePerGas,
                req.maxPriorityFeePerGas,
                req.transactionCalldataGasUsed,
                req.relayWorker,
                req.paymaster,
                req.forwarder,
                keccak256(req.paymasterData),
                req.clientId
            ));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../forwarder/IForwarder.sol";

interface GsnTypes {
    /// @notice maxFeePerGas, maxPriorityFeePerGas, pctRelayFee and baseRelayFee must be validated inside of the paymaster's preRelayedCall in order not to overpay
    struct RelayData {
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 transactionCalldataGasUsed;
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

/* solhint-disable no-inline-assembly */
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../utils/MinLibBytes.sol";
import "./GsnTypes.sol";

/**
 * @title The GSN Solidity Utils Library
 * @notice Some library functions used throughout the GSN Solidity codebase.
 */
library GsnUtils {

    bytes32 constant private RELAY_REQUEST_ID_MASK = 0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * @notice Calculate an identifier for the meta-transaction in a format similar to a transaction hash.
     * Note that uniqueness relies on signature and may not be enforced if meta-transactions are verified
     * with a different algorithm, e.g. when batching.
     * @param relayRequest The `RelayRequest` for which an ID is being calculated.
     * @param signature The signature for the `RelayRequest`. It is not validated here and may even remain empty.
     */
    function getRelayRequestID(GsnTypes.RelayRequest calldata relayRequest, bytes calldata signature)
    internal
    pure
    returns (bytes32) {
        return keccak256(abi.encode(relayRequest.request.from, relayRequest.request.nonce, signature)) & RELAY_REQUEST_ID_MASK;
    }

    /**
     * @notice Extract the method identifier signature from the encoded function call.
     */
    function getMethodSig(bytes memory msgData) internal pure returns (bytes4) {
        return MinLibBytes.readBytes4(msgData, 0);
    }

    /**
     * @notice Extract a parameter from encoded-function block.
     * see: https://solidity.readthedocs.io/en/develop/abi-spec.html#formal-specification-of-the-encoding
     * The return value should be casted to the right type (`uintXXX`/`bytesXXX`/`address`/`bool`/`enum`).
     * @param msgData Byte array containing a uint256 value.
     * @param index Index in byte array of uint256 value.
     * @return result uint256 value from byte array.
     */
    function getParam(bytes memory msgData, uint256 index) internal pure returns (uint256 result) {
        return MinLibBytes.readUint256(msgData, 4 + index * 32);
    }

    /// @notice Re-throw revert with the same revert data.
    function revertWithData(bytes memory data) internal pure {
        assembly {
            revert(add(data,32), mload(data))
        }
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
        if (_initialized < type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155URIStorage.sol)

pragma solidity ^0.8.0;

import "../../../utils/Strings.sol";
import "../ERC1155.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 * Inspired by the ERC721URIStorage extension
 *
 * _Available since v4.6._
 */
abstract contract ERC1155URIStorage is ERC1155 {
    using Strings for uint256;

    // Optional base URI
    string private _baseURI = "";

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the concatenation of the `_baseURI`
     * and the token-specific uri if the latter is set
     *
     * This enables the following behaviors:
     *
     * - if `_tokenURIs[tokenId]` is set, then the result is the concatenation
     *   of `_baseURI` and `_tokenURIs[tokenId]` (keep in mind that `_baseURI`
     *   is empty per default);
     *
     * - if `_tokenURIs[tokenId]` is NOT set then we fallback to `super.uri()`
     *   which in most cases will contain `ERC1155._uri`;
     *
     * - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
     *   uri value set, then the result is empty.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenURI)) : super.uri(tokenId);
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    /**
     * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@redeem/interfaces/IRewardPoolRegistryV1.sol";
import "@redeem/interfaces/factory/IRewardPoolFactoryV1.sol";

import "@redeem/contracts/RewardPoolV1.sol";
import "@redeem/contracts/RewardVRFConsumerV1.sol";
import "@redeem/contracts/gsn/RedeemAssetPaymaster.sol";

contract RewardPoolRegistryV1 is IRewardPoolRegistryV1 {
    address public immutable rewardPoolFactory;
    address public immutable vrfWrapper;
    address public immutable link;
    address public immutable trustedForwarder;

    mapping(address => address) private _ownerToVRFConsumer;

    mapping(address => address) private _ownerToPaymaster;

    mapping(address => address[]) private _ownerToRewardPools;
    mapping(address => address) private _rewardPoolToOwner;

    constructor(
        address _rewardPoolFactory,
        address _forwarder,
        address _vrfWrapper,
        address _link
    ) {
        rewardPoolFactory = _rewardPoolFactory;
        vrfWrapper = _vrfWrapper;
        link = _link;
        trustedForwarder = _forwarder;
    }

    /// @inheritdoc IRewardPoolRegistryV1
    function getVRFConsumer(address owner) external view returns (address) {
        return _ownerToVRFConsumer[owner];
    }

    /// @inheritdoc IRewardPoolRegistryV1
    function getPaymaster(address owner) external view returns (address) {
        return _ownerToPaymaster[owner];
    }

    /// @inheritdoc IRewardPoolRegistryV1
    function getRewardPoolsByAddress(address owner) external view returns (address[] memory) {
        return _ownerToRewardPools[owner];
    }

    /// @inheritdoc IRewardPoolRegistryV1
    function getRewardPoolOwner(address pool) external view returns (address) {
        return _rewardPoolToOwner[pool];
    }

    /// @inheritdoc IRewardPoolRegistryV1
    function createRewardPool(
        string memory name,
        address withdrawAddress,
        IRewardPoolV1.RedeemMethod redeemMethod,
        address redeemTokenContractAddress,
        uint256 redeemTokenAmount,
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseUri
    ) external returns (address rewardPool) {
        address owner = msg.sender;
        address self = address(this);

        address vrfConsumer = _ownerToVRFConsumer[owner];

        if (vrfConsumer == address(0)) {
            vrfConsumer = _createAndSetVRFConsumer(
                self,
                owner,
                vrfWrapper,
                link
            );

            emit VRFConsumerCreated(owner, vrfConsumer);
        }

        rewardPool = IRewardPoolFactoryV1(rewardPoolFactory).create(
            self,
            owner,
            withdrawAddress,
            name,
            redeemMethod,
            redeemTokenContractAddress,
            redeemTokenAmount,
            tokenName,
            tokenSymbol,
            baseUri,
            trustedForwarder
        );

        _ownerToRewardPools[owner].push(rewardPool);

        _rewardPoolToOwner[rewardPool] = owner;

        emit RewardPoolCreated(owner, rewardPool, name, redeemMethod, redeemTokenContractAddress);
    }

    function createPaymaster() public {
        address owner = msg.sender;

        if (_ownerToPaymaster[owner] == address(0)) {
            address paymaster = _createAndSetPaymaster(owner);

            emit PaymasterCreated(owner, paymaster);
        }
    }

    function _createAndSetPaymaster(address owner) private returns (address paymaster) {
        paymaster = address(
            new RedeemAssetPaymaster(address(this))
        );

        _ownerToPaymaster[owner] = paymaster;

        return paymaster;
    }

    function _createAndSetVRFConsumer(
        address self,
        address owner,
        address _vrfWrapper,
        address _link
    ) private returns (address vrfConsumer) {
        vrfConsumer = address(
            new RewardVRFConsumerV1(
                self,
                owner,
                _vrfWrapper,
                _link
            )
        );

        _ownerToVRFConsumer[owner] = vrfConsumer;

        return vrfConsumer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@redeem/interfaces/IRewardPoolRegistryV1.sol";
import "@redeem/interfaces/IRewardVRFConsumerV1.sol";
import "@redeem/interfaces/factory/IAssetPoolFactoryV1.sol";

import "@redeem/contracts/token/ERC1155RedeemTokenV1.sol";
import "@redeem/contracts/token/ERC20RedeemTokenV1.sol";

contract RewardPoolV1 is IRewardPoolV1, Initializable, ERC165 {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;

    uint256 public constant MAX_NUMBER_OF_REWARDS_PER_TX = 10;
    uint256 public constant MAX_NUMBER_OF_ASSET_POOL = 10;
    uint256 public constant MAX_ADMINS = 10;
    uint256 public constant MAX_TRANSFERRERS = 3;

    address public rewardPoolRegistry;
    address public assetPoolFactory;

    string private _name;
    address private _owner;
    address private _withdrawAddress;
    address private _redeemTokenContractAddress;
    address private _forwarder;
    bool private _active;

    IRewardPoolV1.RedeemMethod private _redeemMethod;

    Counters.Counter private _assetPoolId;
    /*
         TODO
         Bits Layout:
       - // - [0..159]   `assetPoolAddress`
       - // - [160..256] `assetPoolId`
         EnumerableSet.UintSet private _assetPoolsPacked;
    */
    mapping(uint256 => address) private _assetPoolIdToAssetPool;

    EnumerableSet.AddressSet private _admins;
    EnumerableSet.AddressSet private _transferrers;
    EnumerableSet.AddressSet private _assetPools;
    EnumerableSet.UintSet private _assetPoolIds;

    modifier onlyAdmin() {
        address sender = msg.sender;
        require(_admins.contains(sender) || sender == _owner, "RewardPoolV1: only admin allowed");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "RewardPoolV1: only owner allowed");
        _;
    }

    modifier onlyAssetPool() {
        require(_assetPools.contains(msg.sender), "RewardPoolV1: only asset pool allowed");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _rewardPoolRegistry,

        address _assetPoolFactory,

        address owner_,
        address withdrawAddress_,
        string memory name_,

        IRewardPoolV1.RedeemMethod redeemMethod_,

        address redeemTokenContractAddress_,
        uint256 _redeemTokenAmount,

        string memory _tokenName,
        string memory _tokenSymbol,

        string memory _baseUri,

        address forwarder_
    ) public payable initializer {
        rewardPoolRegistry = _rewardPoolRegistry;

        assetPoolFactory = _assetPoolFactory;

        _name = name_;

        if (withdrawAddress_ == address(0)) {
            _withdrawAddress = owner_;
        } else {
            _withdrawAddress = withdrawAddress_;
        }

        _owner = owner_;
        _redeemMethod = redeemMethod_;
        _forwarder = forwarder_;
        _active = true;

        _setOrCreateRedeemToken(
            redeemMethod_,
            redeemTokenContractAddress_,
            _tokenName,
            _tokenSymbol,
            _baseUri
        );

        // start from 1
        _assetPoolId.increment();

        _createAssetPool(_redeemTokenAmount);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IRewardPoolV1).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IRewardPoolV1
    function name() external view returns (string memory) {
        return _name;
    }

    /// @inheritdoc IRewardPoolV1
    function isActive() external view returns (bool) {
        return _active;
    }

    /// @inheritdoc IRewardPoolV1
    function getOwner() external view returns (address) {
        return _owner;
    }

    /// @inheritdoc IRewardPoolV1
    function getWithdrawAddress() external view returns (address) {
        return _withdrawAddress;
    }

    /// @inheritdoc IRewardPoolV1
    function getAdmins() external view returns (address [] memory) {
        return _admins.values();
    }

    /// @inheritdoc IRewardPoolV1
    function getTransferrers() external view returns (address [] memory) {
        return _transferrers.values();
    }

    /// @inheritdoc IRewardPoolV1
    function getAssetPools() external view returns (address [] memory) {
        return _assetPools.values();
    }

    /// @inheritdoc IRewardPoolV1
    function getAssetPoolById(uint256 id) external view returns (address) {
        return _assetPoolIdToAssetPool[id];
    }

    /// @inheritdoc IRewardPoolV1
    function getAssetPoolIds() external view returns (uint256 [] memory) {
        return _assetPoolIds.values();
    }

    /// @inheritdoc IRewardPoolV1
    function containsAssetPool(address assetPool) external view returns (bool) {
        return _assetPools.contains(assetPool);
    }

    /// @inheritdoc IRewardPoolV1
    function getTotalNumberOfRewards() external view returns (uint256) {
        uint256 total = 0;
        // should be okay since the number of asset pools won't be that high
        address[] memory pools = _assetPools.values();
        uint256 len = pools.length;

        for (uint i = 0; i < len; ++i) {
            total += IAssetPoolV1(pools[i]).getTotalNumberOfAssets();
        }

        return total;
    }

    /// @inheritdoc IRewardPoolV1
    function isAdmin(address addr) external view returns (bool) {
        return _admins.contains(addr) || addr == _owner;
    }

    /// @inheritdoc IRewardPoolV1
    function isTransferrer(address addr) external view returns (bool) {
        return _transferrers.contains(addr) || addr == _owner;
    }

    /// @inheritdoc IRewardPoolV1
    function getRedeemMethod() external view returns (RedeemMethod) {
        return _redeemMethod;
    }

    /// @inheritdoc IRewardPoolV1
    function getRedeemTokenContractAddress() external view returns (address) {
        return _redeemTokenContractAddress;
    }

    /// @inheritdoc IRewardPoolV1
    function getRedeemTokenBalanceOf(address addr, address assetPool) external view returns (uint256 balance) {
        if (
            _redeemMethod == RedeemMethod.ExistingERC20 ||
            _redeemMethod == RedeemMethod.CustomERC20
        ) {
            balance = IERC20(_redeemTokenContractAddress).balanceOf(addr);
        } else if (_redeemMethod == RedeemMethod.CustomERC1155) {
            balance = IERC1155(_redeemTokenContractAddress).balanceOf(addr, IAssetPoolV1(assetPool).id());
        }

        return balance;
    }

    /// @inheritdoc IRewardPoolV1
    function getMaxNumberOfRewardsPerTx() external pure returns (uint256) {
        return MAX_NUMBER_OF_REWARDS_PER_TX;
    }

    /// @inheritdoc IRewardPoolV1
    function getVRFConsumer() external view returns (address) {
        return IRewardPoolRegistryV1(rewardPoolRegistry).getVRFConsumer(_owner);
    }

    /// @inheritdoc IRewardPoolV1
    function getTrustedForwarder() external view returns (address) {
        return _forwarder;
    }

    /// @inheritdoc IRewardPoolV1
    function createAssetPool(
        uint256 _redeemTokenAmount
    ) external onlyAdmin returns (address) {
        return _createAssetPool(_redeemTokenAmount);
    }

    /// @inheritdoc IRewardPoolV1
    function setActive(bool active_) external onlyOwner {
        _active = active_;

        emit ActiveChanged(active_);
    }

    /// @inheritdoc IRewardPoolV1
    function setName(string memory name_) external onlyAdmin {
        _name = name_;

        emit NameChanged(msg.sender, name_);
    }

    /// @inheritdoc IRewardPoolV1
    function addTransferrers(address [] memory transferrers) external onlyOwner {
        require(transferrers.length + _transferrers.length() <= MAX_TRANSFERRERS, "RewardPoolV1: cant add that many transferrers");

        for (uint i = 0; i < transferrers.length; i++) {
            _transferrers.add(transferrers[i]);
        }

        emit TransferrersAdded(transferrers);
    }

    /// @inheritdoc IRewardPoolV1
    function removeTransferrers(address [] memory transferrers) external onlyOwner {
        for (uint i = 0; i < transferrers.length; i++) {
            _transferrers.remove(transferrers[i]);
        }

        emit TransferrersRemoved(transferrers);
    }

    /// @inheritdoc IRewardPoolV1
    function addAdmins(address [] memory admins) external onlyOwner {
        require(admins.length + _admins.length() <= MAX_ADMINS, "RewardPoolV1: cant add that many admins");

        for (uint i = 0; i < admins.length; i++) {
            _admins.add(admins[i]);
        }

        emit AdminsAdded(admins);
    }

    /// @inheritdoc IRewardPoolV1
    function removeAdmins(address [] memory admins) external onlyOwner {
        for (uint i = 0; i < admins.length; i++) {
            _admins.remove(admins[i]);
        }

        emit AdminsRemoved(admins);
    }

    /// @inheritdoc IRewardPoolV1
    function requestRandomWords(address receiver) external onlyAssetPool {
        address vrfConsumer = IRewardPoolRegistryV1(rewardPoolRegistry).getVRFConsumer(_owner);

        IRewardVRFConsumerV1(vrfConsumer).requestRandomWords(msg.sender, receiver);
    }

    function _setOrCreateRedeemToken(
        RedeemMethod redeemMethod,
        address redeemTokenContractAddress,
        string memory name_,
        string memory symbol_,
        string memory baseUri
    ) private {
        if (redeemMethod == RedeemMethod.ExistingERC20) {
            require(redeemTokenContractAddress != address(0), "RewardPoolV1: address cannot be zero");

            _redeemTokenContractAddress = redeemTokenContractAddress;
        } else if (redeemMethod == RedeemMethod.CustomERC20) {
            _redeemTokenContractAddress = address(
                new ERC20RedeemTokenV1(
                    address(this),
                    name_,
                    symbol_
                )
            );

            emit RedeemTokenCreated(redeemMethod, _redeemTokenContractAddress);
        } else if (redeemMethod == RedeemMethod.CustomERC1155) {
            _redeemTokenContractAddress = address(
                new ERC1155RedeemTokenV1(
                    address(this),
                    baseUri
                )
            );

            emit RedeemTokenCreated(redeemMethod, _redeemTokenContractAddress);
        } else {
            revert("RewardPoolV1: unknown redeem method");
        }
    }

    function _createAssetPool(
        uint256 _redeemTokenAmount
    ) private returns (address assetPool) {
        uint256 id = _assetPoolId.current();

        assetPool = IAssetPoolFactoryV1(assetPoolFactory).create(
            address(this),
            id,
            _redeemTokenAmount
        );

        _addAssetPool(assetPool, id);

        _assetPoolId.increment();

        emit AssetPoolCreated(msg.sender, assetPool, _redeemTokenAmount);
    }

    // TODO optimize
    function _addAssetPool(address assetPool, uint256 id) private {
        _assetPools.add(assetPool);
        _assetPoolIds.add(id);
        _assetPoolIdToAssetPool[id] = assetPool;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/v0.8/VRFV2WrapperConsumerBase.sol";

import "@redeem/interfaces/IRewardVRFConsumerV1.sol";
import "@redeem/interfaces/IAssetPoolV1.sol";
import "@redeem/interfaces/IRewardPoolRegistryV1.sol";

contract RewardVRFConsumerV1 is IRewardVRFConsumerV1, VRFV2WrapperConsumerBase {
    struct Request {
        address assetPool;
        address receiver;
    }

    uint32 callbackGasLimit = 1000000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 10;

    address public immutable linkAddress;

    address public immutable wrapperAddress;

    address public immutable rewardPoolRegistry;

    address public immutable owner;

    mapping(uint256 => Request) public requestIds;

    modifier onlyRewardPool() {
        require(IRewardPoolRegistryV1(rewardPoolRegistry).getRewardPoolOwner(msg.sender) == owner, "RedeemVRFConsumerV1: only reward pool allowed");
        _;
    }

    constructor(
        address _rewardPoolRegistry,
        address _owner,
        address _wrapper,
        address _link
    )
    VRFV2WrapperConsumerBase(_link, _wrapper)
    {
        linkAddress = _link;
        wrapperAddress = _wrapper;
        rewardPoolRegistry = _rewardPoolRegistry;
        owner = _owner;
    }

    function requestRandomWords(address assetPool, address receiver)
    external
    onlyRewardPool
    returns (uint256 requestId)
    {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        requestIds[requestId] = Request({
        assetPool : assetPool,
        receiver : receiver
        });

        return requestId;
    }

    function depositLink(uint256 amount) public {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transferFrom(msg.sender, address(this), amount),
            "Failed to transfer"
        );
    }

    function withdrawLink() public {
        require(msg.sender == owner, "RedeemVRFConsumerV1: only owner can withdraw link");

        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        Request storage req = requestIds[requestId];

        IAssetPoolV1(req.assetPool).fulfillRedeemAsset(requestId, req.receiver, randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (Request memory)
    {
        return requestIds[_requestId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@opengsn/contracts/src/BasePaymaster.sol";
import "@opengsn/contracts/src/forwarder/IForwarder.sol";

import "../../interfaces/IRewardPoolRegistryV1.sol";

contract RedeemAssetPaymaster is BasePaymaster {
    IRewardPoolRegistryV1 REWARD_POOL_REGISTRY;

    constructor(address _rewardPoolRegistry) {
        REWARD_POOL_REGISTRY = IRewardPoolRegistryV1(_rewardPoolRegistry);
    }

    function _preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata,
        uint256 maxPossibleGas
    )
    internal
    override
    virtual
    returns (bytes memory context, bool revertOnRecipientRevert) {
        (signature, maxPossibleGas);
        IForwarder.ForwardRequest calldata req = relayRequest.request;

        IAssetPoolV1 assetPool = IAssetPoolV1(req.to);

        IRewardPoolV1 rewardPool = IRewardPoolV1(assetPool.getRewardPool());

        require(REWARD_POOL_REGISTRY.getRewardPoolOwner(address(rewardPool)) != address(0));

        bytes4 method = GsnUtils.getMethodSig(req.data);

        require(method == IAssetPoolV1.redeemAsset.selector);

        uint256 amountOfAssetsToRedeem = abi.decode(req.data, (uint256));

        require(rewardPool.getRedeemTokenBalanceOf(req.from, req.to) >= amountOfAssetsToRedeem * assetPool.getRedeemTokenAmount());
        require(assetPool.getTotalNumberOfAssets() >= amountOfAssetsToRedeem);

        return ("", false);
    }

    function _postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    internal
    override
    virtual {
        (context, success, gasUseWithoutPost, relayData);
    }

    function versionPaymaster() external view override virtual returns (string memory){
        return "3.0.0-beta.3+opengsn.vpm.ipaymaster";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

import "@redeem/interfaces/IRewardPoolV1.sol";
import "@redeem/interfaces/token/IERC1155RedeemTokenV1.sol";

import "./RedeemTokenV1.sol";

contract ERC1155RedeemTokenV1 is IERC1155RedeemTokenV1, RedeemTokenV1, ERC1155URIStorage {
    modifier onlyValidAssetPool(address assetPool, uint256 id) {
        require(IRewardPoolV1(rewardPool).getAssetPoolById(id) == assetPool, "RedeemTokenV1: only asset pool allowed with correct asset pool id");
        _;
    }

    constructor(address _rewardPool, string memory uri_)
    RedeemTokenV1(_rewardPool)
    ERC1155(uri_)
    {}

    function setBaseUri(string memory _uri) external onlyAdmin {
        _setBaseURI(_uri);
    }

    function setUri(uint256 _id, string memory _uri) external onlyAdmin {
        _setURI(_id, _uri);
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data)
    external
    onlyValidAssetPool(msg.sender, id)
    {
        _mint(to, id, amount, data);
    }

    function burn(address from, uint256 id, uint256 amount)
    external
    onlyValidAssetPool(msg.sender, id)
    {
        _burn(from, id, amount);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
        require(!_blacklisted[from], "RedeemTokenV1: address is blacklisted");

        for (uint i = 0; i < ids.length; ++i) {
            require(IRewardPoolV1(rewardPool).getAssetPoolById(ids[i]) != address(0), "RedeemTokenV1: invalid id");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@redeem/interfaces/IRewardPoolV1.sol";
import "@redeem/interfaces/token/IERC20RedeemTokenV1.sol";

import "./RedeemTokenV1.sol";

contract ERC20RedeemTokenV1 is IERC20RedeemTokenV1, RedeemTokenV1, ERC20 {
    constructor(
        address _rewardPool, string memory _name, string memory _symbol
    )
    RedeemTokenV1(_rewardPool)
    ERC20(_name, _symbol)
    {
    }

    function mint(address to, uint256 amount)
    external
    onlyAssetPool
    {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external onlyAssetPool {
        _burn(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        require(!_blacklisted[from], "ERC20RedeemTokenV1: blacklisted");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@redeem/interfaces/IRewardPoolV1.sol";

contract RedeemTokenV1 {
    IRewardPoolV1 REWARD_POOL;

    address public immutable rewardPool;

    mapping(address => bool) _blacklisted;

    modifier onlyOwner() {
        require(msg.sender == REWARD_POOL.getOwner(), "RedeemTokenV1: only owner allowed");
        _;
    }

    modifier onlyAdmin() {
        require(REWARD_POOL.isAdmin(msg.sender), "RedeemTokenV1: only admin allowed");
        _;
    }

    modifier onlyAssetPool() {
        require(REWARD_POOL.containsAssetPool(msg.sender), "RedeemTokenV1: only asset pool allowed");
        _;
    }

    constructor(address _rewardPool) {
        rewardPool = _rewardPool;

        REWARD_POOL = IRewardPoolV1(rewardPool);
    }

    function getBlacklisted(address _user) external view returns (bool) {
        return _blacklisted[_user];
    }

    function setBlacklisted(address _user, bool blacklisted_) external onlyOwner {
        _blacklisted[_user] = blacklisted_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IAssetPoolV1 is IERC721Receiver, IERC1155Receiver {
    // =============================================================
    //                            ERRORS
    // =============================================================

    /*
     * Pool owner/admin should deposit at least one asset in the asset pool
     */
    error DepositAtLeastOneAsset();

    /*
     * The caller should redeem at least one asset in the asset pool
     */
    error RedeemAtLeastOneAsset();

    /*
     * Got invalid redeem method
     */
    error InvalidRedeemMethod();

    /*
     * Should deposit at least one asset in the asset pool
     */
    error RedeemMoreThanMaxAmount();

    /*
     * The caller is trying to redeem more assets than there is in the pool
     */
    error NotEnoughAssetsInThePool();

    /*
     * Insufficient token balance
     */
    error InsufficientBalance();

    /*
     * Insufficient approval balance
     */
    error InsufficientApproval();

    /*
     * Token transfer failed
     */
    error TransferFailed();

    // =============================================================
    //                            ENUMS
    // =============================================================

    enum AssetType {
        ERC721,
        ERC20,
        NativeToken
    }

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct AssetBox {
        AssetType assetType;
        // Number of cards in the box
        uint256 numberOfCards;
        // ERC721 tokenId or ERC20 amount
        uint256 amountOrTokenId;
    }

    // =============================================================
    //                            EVENTS
    // =============================================================

    /* @dev Emitted when `admin` or one of the admins deposits `amount` of assets in the pool */
    event AssetsDeposited(address indexed admin, uint256 amount);

    /* @dev Emitted when `admin` withdraws assets from the pool */
    event AssetsWithdrawn(address admin);

    /* @dev Emitted when `receiver` redeems an asset using pool's redeem method */
    event AssetRedeemed(uint256 requestId, address indexed receiver, AssetType, address indexed assetContract, uint256 amountOrTokenId);

    /* @dev Emitted when a new redeem token amount is changed to `newAmount` by `admin`  */
    event RedeemTokenAmountChanged(address indexed admin, uint256 newAmount);

    // =============================================================
    //                            IAssetPoolV1
    // =============================================================

    /* @dev Returns the id of the asset pool */
    function id() external view returns (uint256);

    /* @dev Returns the reward pool address this pool belongs to */
    function getRewardPool() external view returns (address);

    /*
     * @dev Returns the amount of units required to transfer/burn when calling redeemAsset()
     */
    function getRedeemTokenAmount() external view returns (uint256);

    /*
     * @dev Returns all the contracts by `assetType`
     */
    function getContractsByAssetType(AssetType assetType) external view returns (address [] memory);

    /*
     * @dev Returns all the ERC721 assets present in this asset pool for `contractAddress`
     */
    function getERC721Assets(address contractAddress) external view returns (AssetBox[] memory);

    /*
     * @dev Returns all the ERC20 assets present in this asset pool for `contractAddress`
     */
    function getERC20Assets(address contractAddress) external view returns (AssetBox[] memory);

    /*
     * @dev Returns all the native token assets present in this asset pool
     */
    function getNativeTokenAssets() external view returns (AssetBox[] memory);

    /*
     * @dev Returns all the deposited asset types in the pool
     */
    function getDepositedAssetTypes() external view returns (AssetType [] memory);

    /*
     * @dev Returns the amount of assets deposited in the pool
     */
    function getTotalNumberOfAssets() external view returns (uint256);

    /* @dev Deposits assets in the asset pool */
    function depositAssets(
        address [] calldata erc20ContractAddresses,
        uint256 [] calldata erc20Amounts,
        AssetBox [][] memory erc20Boxes,

        address [] calldata erc721ContractAddresses,
        uint256 [][] calldata erc721TokenIds,

        AssetBox [] memory nativeTokenBoxes
    ) payable external;

    /* @dev Withdraw assets in the asset pool */
    function withdrawAssets(
        address [] calldata erc20ContractAddresses,
        AssetBox [][] memory erc20Boxes,

        address [] calldata erc721ContractAddresses,
        uint256 [][] calldata erc721TokenIds,

        AssetBox [] memory nativeTokenBoxes
    ) external;

    /* @dev Transfers `number` of redeem tokens to `to` */
    function transferRedeemTokenNumber(address to, uint256 number) external;

    /* @dev Transfers `amount` of redeem token to `to` */
    function transferRedeemTokenAmount(address to, uint256 amount) external;

    /*
     * @dev Redeems asset for the caller and depending on the redeemMethod
     * burns/takes redeem token and sends a request to chainlink for randomization
     */
    function redeemAsset(uint256 amount) external;

    /*
     * @notice Randomizes asset for the `receiver`
     * @dev Called by ChainLink VRF consumer
     */
    function fulfillRedeemAsset(
        uint256 requestId,
        address receiver,
        uint256[] memory
    ) external returns (AssetType, address, uint256);

    /*
     * @dev Sets the new redeem token amount
     */
    function setRedeemTokenAmount(uint256 redeemAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IRewardPoolV1.sol";

interface IRewardPoolRegistryV1 {
    /* @dev Emitted when new `rewardPool` is created by the `owner` */
    event RewardPoolCreated(address indexed owner, address rewardPool, string name, IRewardPoolV1.RedeemMethod redeemMethod, address redeemToken);

    /* @dev Emitted when `vrfConsumer` is created by the `owner` */
    event VRFConsumerCreated(address indexed owner, address vrfConsumer);

    /* @dev Emitted when new `paymaster` is created by the `owner` */
    event PaymasterCreated(address indexed owner, address paymaster);

    /* @dev Returns the vrf consumer deployed by `owner` */
    function getVRFConsumer(address owner) external view returns (address);

    /* @dev Returns the paymaster deployed by `owner` */
    function getPaymaster(address owner) external view returns (address);

    /* @dev Returns all the reward pools created by the `owner` */
    function getRewardPoolsByAddress(address owner) external view returns (address [] memory);

    /* @dev Returns owner of the `pool` */
    function getRewardPoolOwner(address pool) external view returns (address);

    /* @dev Creates a new reward pool */
    function createRewardPool(
        string memory name,
        address withdrawAddress,
        IRewardPoolV1.RedeemMethod redeemMethod,
        address redeemTokenContractAddress,
        uint256 redeemTokenAmount,
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseUri
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAssetPoolV1.sol";

interface IRewardPoolV1 {
    // =============================================================
    //                            ENUMS
    // =============================================================

    enum RedeemMethod {
        ExistingERC20,
        CustomERC20,

        //        ExistingERC721,
        //        CustomERC721,
        //        ExistingERC1155,

        CustomERC1155
    }

    // =============================================================
    //                            EVENTS
    // =============================================================

    /* @dev Emitted when a new `assetPool` is created by the `creator` */
    event AssetPoolCreated(address indexed creator, address assetPool, uint256 redeemTokenAmount);

    /* @dev Emitted when a new redeem token (`redeemContractAddress`) is created */
    event RedeemTokenCreated(RedeemMethod redeemMethod, address redeemContractAddress);

    /* @dev Emitted when new `admins` are added to the reward pool */
    event AdminsAdded(address[] admins);

    /* @dev Emitted when `admins` are removed from the reward pool */
    event AdminsRemoved(address[] admins);

    /* @dev Emitted when new `transferrers` are added to the reward pool */
    event TransferrersAdded(address[] transferrers);

    /* @dev Emitted when `transferrers` are removed from the reward pool */
    event TransferrersRemoved(address[] transferrers);

    /* @dev Emitted when the name is changed */
    event ActiveChanged(bool active);

    /* @dev Emitted when the name is changed */
    event NameChanged(address ownerOrAdmin, string newName);

    // =============================================================
    //                            IRewardPoolV1
    // =============================================================

    /* @dev Returns the name of the reward pool */
    function name() external view returns (string memory);

    /* @dev Returns whether the reward pool is active */
    function isActive() external view returns (bool);

    /* @dev Returns the owner of the pool */
    function getOwner() external view returns (address);

    /* @dev Returns the withdraw address */
    function getWithdrawAddress() external view returns (address);

    /* @dev Returns all the admins of the reward pool */
    function getAdmins() external view returns (address [] memory);

    /* @dev Returns whether `addr` is admin or not */
    function isAdmin(address addr) external view returns (bool);

    /* @dev Returns all the transferrers of the reward pool */
    function getTransferrers() external view returns (address [] memory);

    /* @dev Returns whether `addr` is allowed to transfer redeem token from the pool */
    function isTransferrer(address addr) external view returns (bool);

    /* @dev Returns all the asset pools created in the reward pool */
    function getAssetPools() external view returns (address [] memory);

    /* @dev Returns all the asset pool ids  */
    function getAssetPoolIds() external view returns (uint256 [] memory);

    /* @dev Returns asset pool by `id`  */
    function getAssetPoolById(uint256 id) external view returns (address);

    /* @dev Returns true if this reward pool has `assetPool`; false otherwise */
    function containsAssetPool(address assetPool) external view returns (bool);

    /* @dev Returns the total amount of rewards across all the asset pools */
    function getTotalNumberOfRewards() external view returns (uint256);

    /* @dev Returns the redeem method set by the asset pool creator */
    function getRedeemMethod() external view returns (RedeemMethod);

    /* @dev Returns the contract address of the redeem token */
    function getRedeemTokenContractAddress() external view returns (address);

    /* @dev Returns redeem token balance for `addr` in `assetPool`(if needed) */
    function getRedeemTokenBalanceOf(address addr, address assetPool) external view returns (uint256);

    /* @dev Returns the VRF consumer address */
    function getVRFConsumer() external view returns (address);

    /* @dev Returns trusted forwarder for GSN redeemAsset() */
    function getTrustedForwarder() external view returns (address);

    /* @dev Returns maximum number of rewards allowed per tx */
    function getMaxNumberOfRewardsPerTx() external view returns (uint256);

    /* @dev Creates a new asset pool */
    function createAssetPool(
        uint256 redeemTokenAmount
    ) external returns (address);

    /* @dev Sets reward pool's `active` status */
    function setActive(bool active) external;

    /* @dev Sets a new `name` for the reward pool */
    function setName(string memory name) external;

    /* @dev Adds `admins` to the reward pool */
    function addAdmins(address [] memory admins) external;

    /* @dev Removes `admins` from the reward pool */
    function removeAdmins(address [] memory admins) external;

    /* @dev Adds `transferrers` to the reward pool */
    function addTransferrers(address [] memory transferrers) external;

    /* @dev Removes `transferrers` from the reward pool */
    function removeTransferrers(address [] memory transferrers) external;

    /* @dev Request random words from ChainLinkVRFConsumer on behalf of `assetPool` for the `receiver` */
    function requestRandomWords(address receiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRewardVRFConsumerV1
{
    function requestRandomWords(address, address) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAssetPoolFactoryV1 {
    function create(
        address rewardPool,
        uint256 id,
        uint256 redeemTokenAmount
    ) payable external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../IRewardPoolV1.sol";

interface IRewardPoolFactoryV1 {
    //    struct RedeemOptions {
    //        IRewardPoolV1.RedeemMethod method;
    //        address contractAddress;
    //        uint256 amount;
    //    }

    /* @dev Creates a new instance of the RewardPool */
    function create(
        address rewardPoolRegistry,

        address owner,
        address withdrawAddress,

        string memory name,

        IRewardPoolV1.RedeemMethod redeemMethod,

        address redeemTokenContractAddress,
        uint256 redeemTokenAmount,

    /* only if redeemMethod is Custom* and `owner` wants to create a new token */
        string memory tokenName,
        string memory tokenSymbol,
    /**/
        string memory baseUri,

        address forwarder
    ) payable external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155RedeemTokenV1 is IERC1155 {
    function mint(address addr, uint256 id, uint256 amount, bytes memory) external;

    function burn(address, uint256, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20RedeemTokenV1 is IERC20 {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}