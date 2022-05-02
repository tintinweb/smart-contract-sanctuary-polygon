// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "../VirtualFloorMetadataValidator.sol";

/**
 * @title Graph helper contract
 * @author 🎲🎲 <[email protected]>
 * @dev The purpose of this contract is to assist the Graph indexer in abi-decoding an abi-encoded VirtualFloorMetadataV1 structure.
 * In theory the Graph should be able to abi-decode such a structure via the AssemblyScript function
 * [ethereum.decode](https://thegraph.com/docs/en/developer/assemblyscript-api/#encoding-decoding-abi).
 * However this function doesn't seem to handle tuple-arrays correctly,
 * so as the Graph indexer has the ability to call a deployed contract,
 * the limitation is worked around by deploying this helper contract which
 * is then used by the Graph to decode metadata.
 */
contract GraphHelper {

    /**
     * @dev This function never needs to be called on the contract, and its sole purpose is to coerce TypeChain
     * into generating a corresponding encodeFunctionData, which can be used to abi-encode a VirtualFloorMetadataV1
     * without ever communicating with the deployed contract.
     * Nevertheless:
     * 1. Rather than on a separate interface, for simplicity it is included on this contract (and unnecessarily deployed)
     * 2. Although it would have sufficed to have an empty implementation, it is included for completeness.
     */
    function encodeVirtualFloorMetadataV1(VirtualFloorMetadataV1 calldata decoded) external pure returns (bytes memory encoded) {
        encoded = abi.encode(decoded);
    }

    function decodeVirtualFloorMetadataV1(bytes calldata encoded) external pure returns (VirtualFloorMetadataV1 memory decoded) {
        (decoded) = abi.decode(encoded, (VirtualFloorMetadataV1));
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "./BaseDoubleDice.sol";
import "./library/Utils.sol";

/**
 * @notice In v1 the metadata is a direct ABI-encoding of this structure.
 */
struct VirtualFloorMetadataV1 {
    string category;
    string subcategory;
    string title;
    string description;
    bool isListed;
    VirtualFloorMetadataOpponent[] opponents;
    VirtualFloorMetadataOutcome[] outcomes;
    VirtualFloorMetadataResultSource[] resultSources;
    string discordChannelId;
    bytes extraData;
}

struct VirtualFloorMetadataOpponent {
    string title;
    string image;
}

struct VirtualFloorMetadataOutcome {
    string title;
}

struct VirtualFloorMetadataResultSource {
    string title;
    string url;
}


error InvalidMetadataVersion();

error MetadataOpponentArrayLengthMismatch();

error ResultSourcesArrayLengthMismatch();

error InvalidOutcomesArrayLength();

error TooFewOpponents();

error TooFewResultSources();

error EmptyCategory();

error EmptySubcategory();

error EmptyTitle();

error EmptyDescription();

error EmptyDiscordChannelId();


/**
 * @title VirtualFloorMetadataValidator extension of BaseDoubleDice contract
 * @author 🎲🎲 <[email protected]>
 * @notice This contract extends the BaseDoubleDice contract to restrict VF-creation to VFs with valid metadata only.
 */
contract VirtualFloorMetadataValidator is BaseDoubleDice {

    using Utils for string;

    function __VirtualFloorMetadataValidator_init(BaseDoubleDiceInitParams calldata params) internal onlyInitializing {
        __BaseDoubleDice_init(params);
    }

    function _onVirtualFloorCreation(VirtualFloorCreationParams calldata params) internal virtual override {
        uint256 version = uint256(params.metadata.version);
        if (!(version == 1)) revert InvalidMetadataVersion();

        (VirtualFloorMetadataV1 memory metadata) = abi.decode(params.metadata.data, (VirtualFloorMetadataV1));

        // `nOutcomes` could simply be taken to be `metadata.outcomes.length` and this `require` could then be dropped.
        // But it is accepted as separate parameter to distinguish parameters that required on-chain from those that are not,
        // and then consistency between the two in enforced with this check.
        if (!(metadata.outcomes.length == params.nOutcomes)) revert InvalidOutcomesArrayLength();

        if (!(metadata.opponents.length >= 1)) revert TooFewOpponents();

        if (!(metadata.resultSources.length >= 1)) revert TooFewResultSources();

        if (!(!metadata.category.isEmpty())) revert EmptyCategory();

        if (!(!metadata.subcategory.isEmpty())) revert EmptySubcategory();

        if (!(!metadata.title.isEmpty())) revert EmptyTitle();

        if (!(!metadata.description.isEmpty())) revert EmptyDescription();

        if (!(!metadata.discordChannelId.isEmpty())) revert EmptyDiscordChannelId();
    }

    /**
     * @dev See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED 
 
pragma solidity 0.8.12;
 
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./ForkedERC1155UpgradeableV4_5_2.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
 
import "./library/ERC1155TokenIds.sol";
import "./library/FixedPointTypes.sol";
import "./library/Utils.sol"; 
import "./library/VirtualFloorCreationParamsUtils.sol"; 
import "./library/VirtualFloors.sol"; 
import "./ExtraStorageGap.sol"; 
import "./MultipleInheritanceOptimization.sol";
 
 
/**
 *                            ________ 
 *                 ________  / o   o /\
 *                /     o /\/   o   /o \ 
 *               /   o   /  \o___o_/o   \ 
 *              /_o_____/o   \     \   o/
 *              \ o   o \   o/  o   \ o/ 
 *  ______     __\ o   o \  /\_______\/       _____     ____    ____    ____   _______ 
 * |  __  \   /   \_o___o_\/ |  _ \  | |     |  ___|   |  _ \  |_  _|  / ___| |   ____|
 * | |  \  | | / \ | | | | | | |_| | | |     | |_      | | \ |   ||   | /     |  | 
 * | |   | | | | | | | | | | |  _ <  | |     |  _|     | | | |   I|   | |     |  |__
 * |D|   |D| |O\_/O| |U|_|U| |B|_|B| |L|___  |E|___    |D|_/D|  _I|_  |C\___  |EEEEE| 
 * |D|__/DD|  \OOO/   \UUU/  |BBBB/  |LLLLL| |EEEEE|   |DDDD/  |IIII|  \CCCC| |EE|____ 
 * |DDDDDD/  ================================================================ |EEEEEEE|
 *
 * @title Base DoubleDice protocol contract
 * @author 🎲🎲 <[email protected]>
 * @notice Enables accounts to commit an amount of ERC-20 tokens to a prediction that a specific future event,
 * or VirtualFloor (VF), resolves to a specific outcome from a predefined list of 2 or more mutually-exclusive
 * possible outcomes.
 * Users committing funds to a specific VF outcome at a specific timepoint are issued with a commitment receipt
 * in the form of a ERC-1155 commitment-balance. 
 * If a VF is resolved to a winning outcome and winner profits are available, the commitment-balance may be redeemed
 * by its holder for the corresponding share of the profit. 
 */ 
abstract contract BaseDoubleDice is 
    ForkedERC1155UpgradeableV4_5_2, 
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ExtraStorageGap, 
    MultipleInheritanceOptimization 
{ 
    using FixedPointTypes for UFixed16x4; 
    using FixedPointTypes for UFixed256x18;
    using FixedPointTypes for UFixed32x6; 
    using FixedPointTypes for uint256;
    using SafeCastUpgradeable for uint256; 
    using SafeERC20Upgradeable for IERC20Upgradeable; 
    using Utils for uint256; 
    using VirtualFloorCreationParamsUtils for VirtualFloorCreationParams; 
    using ERC1155TokenIds for uint256;
    using VirtualFloors for VirtualFloor; 


    // ----------🎲🎲 STORAGE 🎲🎲----------
 
    mapping(uint256 => VirtualFloor) private _vfs;
 
    address private _protocolFeeBeneficiary; 

    UFixed16x4 private _protocolFeeRate; 
 
    string private _contractURI;

    mapping(IERC20Upgradeable => bool) private _paymentTokenWhitelist; 
 

    // ----------🎲🎲 GENERIC ERRORS & CONSTANTS 🎲🎲---------- 
 
    /** 
     * @notice Caller is not authorized to execute this action.
     */ 
    error UnauthorizedMsgSender(); 
 
    /** 
     * @notice VF is in state `actualState`, but it must be in a different state to execute this action. 
     */ 
    error WrongVirtualFloorState(VirtualFloorState actualState);
 
    /**
     * @notice The action being attempted can only be executed from a specific timepoint onwards, 
     * and that timepoint has not yet arrived. 
     */
    error TooEarly();
 
    /** 
     * @notice The action you are trying to execute can only be executed until a specific timepoint,
     * and that timepoint has passed. 
     */ 
    error TooLate(); 
 
    /**
     * @notice The specified outcome index is too large for this VF. 
     */
    error OutcomeIndexOutOfRange();

 
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE"); 
 
 
    // ----------🎲🎲 SETUP & CONFIG 🎲🎲----------


    // ----------🎲 Initial config 🎲----------
 
    struct BaseDoubleDiceInitParams {
        string tokenMetadataUriTemplate;
        address protocolFeeBeneficiary;
        UFixed256x18 protocolFeeRate_e18;
        string contractURI;
    } 

    function __BaseDoubleDice_init(BaseDoubleDiceInitParams calldata params) 
        internal
        onlyInitializing
        multipleInheritanceRootInitializer
    {
        __ERC1155_init(params.tokenMetadataUriTemplate); 
        __AccessControl_init(); 
        __Pausable_init();
        __ReentrancyGuard_init(); 
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setProtocolFeeBeneficiary(params.protocolFeeBeneficiary); 
        _setProtocolFeeRate(params.protocolFeeRate_e18);
        _setContractURI(params.contractURI); 
    }
 
 
    // ----------🎲 Config: tokenMetadataUriTemplate 🎲---------- 

    /**
     * @notice Admin: Set tokenMetadataUriTemplate
     * @dev See https://eips.ethereum.org/EIPS/eip-1155#metadata 
     */ 
    function setTokenMetadataUriTemplate(string calldata template) external onlyRole(DEFAULT_ADMIN_ROLE) { 
        _setURI(template);
    }


    // ----------🎲 Config: protocolFeeBeneficiary 🎲----------

    /**
     * @notice Account to which protocol-fee is transferred
     */ 
    function platformFeeBeneficiary() public view returns (address) { 
        return _protocolFeeBeneficiary;
    } 
 
    /**
     * @notice Admin: Set protocolFeeBeneficiary
     */
    function setPlatformFeeBeneficiary(address protocolFeeBeneficiary_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setProtocolFeeBeneficiary(protocolFeeBeneficiary_); 
    } 
 
    event PlatformFeeBeneficiaryUpdate(address protocolFeeBeneficiary);

    function _setProtocolFeeBeneficiary(address protocolFeeBeneficiary_) internal { 
        emit OwnershipTransferred(_protocolFeeBeneficiary, protocolFeeBeneficiary_);
        _protocolFeeBeneficiary = protocolFeeBeneficiary_; 
        emit PlatformFeeBeneficiaryUpdate(protocolFeeBeneficiary_);
    }
 
 
    // ----------🎲 Config: protocolFeeRate 🎲---------- 
 
    /** 
     * @notice Protocol-fee rate that will apply to newly-created VFs. 
     * E.g. 1.25% would be returned as 0.0125e18 
     */
    function platformFeeRate_e18() external view returns (UFixed256x18) { 
        return _protocolFeeRate.toUFixed256x18(); 
    }
 
    /**
     * @notice Admin: Set protocol-fee rate.
     * @param protocolFeeRate_e18_ The rate as a proportion, scaled by 1e18. 
     * E.g. 1.25% or 0.0125 should be entered as 0_012500_000000_000000 
     */ 
    function setPlatformFeeRate_e18(UFixed256x18 protocolFeeRate_e18_) external onlyRole(DEFAULT_ADMIN_ROLE) { 
        _setProtocolFeeRate(protocolFeeRate_e18_); 
    } 

    /**
     * @notice protocolFeeRate <= 1.0 not satisfied
     */
    error PlatformFeeRateTooLarge();
 
    event PlatformFeeRateUpdate(UFixed256x18 protocolFeeRate_e18);

    function _setProtocolFeeRate(UFixed256x18 protocolFeeRate) internal {
        if (!protocolFeeRate.lte(UFIXED256X18_ONE)) revert PlatformFeeRateTooLarge();
        _protocolFeeRate = protocolFeeRate.toUFixed16x4();
        emit PlatformFeeRateUpdate(protocolFeeRate); 
    }


    // ----------🎲 Config: contractURI 🎲----------
 
    /** 
     * @notice URL for the OpenSea storefront-level metadata for this contract
     * @dev See https://docs.opensea.io/docs/contract-level-metadata 
     */
    function contractURI() external view returns (string memory) { 
        return _contractURI; 
    }

    /** 
     * @notice Admin: Set contractURI
     */
    function setContractURI(string memory contractURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setContractURI(contractURI_);
    } 
 
    event ContractURIUpdate(string contractURI);

    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
        emit ContractURIUpdate(contractURI_); 
    }
 

    // ----------🎲 Config: paymentTokenWhitelist 🎲----------
 
    /**
     * @notice Check whether a specific ERC-20 token can be set as a VF's payment-token during createVirtualFloor. 
     */
    function isPaymentTokenWhitelisted(IERC20Upgradeable token) public view returns (bool) {
        return _paymentTokenWhitelist[token]; 
    }
 
    /**
     * @notice Admin: Update payment-token whitelist status. Has no effect on VFs already created with this token. 
     */
    function updatePaymentTokenWhitelist(IERC20Upgradeable token, bool isWhitelisted) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updatePaymentTokenWhitelist(token, isWhitelisted); 
    }

    event PaymentTokenWhitelistUpdate(IERC20Upgradeable indexed token, bool whitelisted);

    function _updatePaymentTokenWhitelist(IERC20Upgradeable token, bool isWhitelisted) internal { 
        _paymentTokenWhitelist[token] = isWhitelisted;
        emit PaymentTokenWhitelistUpdate(token, isWhitelisted); 
    }
 
 
    // ----------🎲🎲 PUBLIC VIRTUAL-FLOOR GETTERS 🎲🎲----------
 
    /**
     * @notice Get state of VF with id `vfId`.
     */
    function getVirtualFloorState(uint256 vfId) public view returns (VirtualFloorState) {
        return _vfs[vfId].state();
    }

    /**
     * @notice Get account that created VF with id `vfId`.
     */ 
    function getVirtualFloorCreator(uint256 vfId) public view returns (address) {
        return _vfs[vfId].creator;
    } 
 
    struct CreatedVirtualFloorParams {
        UFixed256x18 betaOpen_e18; 
        UFixed256x18 totalFeeRate_e18;
        UFixed256x18 protocolFeeRate_e18;
        uint32 tOpen; 
        uint32 tClose; 
        uint32 tResolve; 
        uint8 nOutcomes; 
        IERC20Upgradeable paymentToken;
        uint256 bonusAmount; 
        uint256 minCommitmentAmount; 
        uint256 maxCommitmentAmount; 
        address creator;
    }

    /** 
     * @notice Get parameters of VF with id `vfId`. 
     */ 
    function getVirtualFloorParams(uint256 vfId) public view returns (CreatedVirtualFloorParams memory) { 
        VirtualFloor storage vf = _vfs[vfId]; 
        (uint256 minCommitmentAmount, uint256 maxCommitmentAmount) = vf.minMaxCommitmentAmounts(); 
        return CreatedVirtualFloorParams({
            betaOpen_e18: vf.betaOpenMinusBetaClose.toUFixed256x18().add(_BETA_CLOSE),
            totalFeeRate_e18: vf.totalFeeRate.toUFixed256x18(), 
            protocolFeeRate_e18: vf.protocolFeeRate.toUFixed256x18(), 
            tOpen: vf.tOpen, 
            tClose: vf.tClose, 
            tResolve: vf.tResolve, 
            nOutcomes: vf.nOutcomes,
            paymentToken: vf.paymentToken, 
            bonusAmount: vf.bonusAmount, 
            minCommitmentAmount: minCommitmentAmount,
            maxCommitmentAmount: maxCommitmentAmount, 
            creator: vf.creator
        });
    } 

    /**
     * @notice Get total ERC-20 payment-token amount, as well as total weighted amount,
     * committed to outcome with 0-based index `outcomeIndex` of VF with id `vfId`.
     */ 
    function getVirtualFloorOutcomeTotals(uint256 vfId, uint8 outcomeIndex) public view returns (OutcomeTotals memory) {
        return _vfs[vfId].outcomeTotals[outcomeIndex];
    }

 
    // ----------🎲🎲 VIRTUAL-FLOOR LIFECYCLE 🎲🎲---------- 


    // ----------🎲 Lifecycle: Creating a VF 🎲---------- 

    /** 
     * @notice A VF with the same id already exists.
     */ 
    error DuplicateVirtualFloorId(); 

    /** 
     * @notice Trying to create a VF with a non-whitelisted ERC-20 payment-token. 
     */
    error PaymentTokenNotWhitelisted();
 
    /** 
     * @notice Condition `0 < minCommitmentAmount <= maxCommitmentAmount` not satisfied. 
     */ 
    error InvalidMinMaxCommitmentAmounts(); 

    event VirtualFloorCreation(
        uint256 indexed vfId,
        address indexed creator, 
        UFixed256x18 betaOpen_e18, 
        UFixed256x18 totalFeeRate_e18, 
        UFixed256x18 protocolFeeRate_e18, 
        uint32 tOpen, 
        uint32 tClose,
        uint32 tResolve, 
        uint8 nOutcomes,
        IERC20Upgradeable paymentToken, 
        uint256 bonusAmount,
        uint256 minCommitmentAmount, 
        uint256 maxCommitmentAmount,
        EncodedVirtualFloorMetadata metadata
    ); 

    /**
     * @notice Create a VF with params `params`. 
     */
    function createVirtualFloor(VirtualFloorCreationParams calldata params) 
        public 
        whenNotPaused 
    { 
 
        // Pure value validation 
        params.validatePure();

        // Validation against block 

        // solhint-disable-next-line not-rely-on-time 
        if (!(block.timestamp <= params.tCreateMax())) revert TooLate(); 
 
        VirtualFloor storage vf = _vfs[params.vfId];

        // Validation against storage 
        if (!(vf._internalState == VirtualFloorInternalState.None)) revert DuplicateVirtualFloorId(); 
        if (!isPaymentTokenWhitelisted(params.paymentToken)) revert PaymentTokenNotWhitelisted(); 

        vf._internalState = VirtualFloorInternalState.Active;
        vf.creator = _msgSender(); 
        vf.betaOpenMinusBetaClose = params.betaOpen_e18.sub(_BETA_CLOSE).toUFixed32x6(); 
        vf.totalFeeRate = params.totalFeeRate_e18.toUFixed16x4();
        vf.protocolFeeRate = _protocolFeeRate; // freeze current global protocolFeeRate 
        vf.tOpen = params.tOpen; 
        vf.tClose = params.tClose;
        vf.tResolve = params.tResolve; 
        vf.nOutcomes = params.nOutcomes; 
        vf.paymentToken = params.paymentToken; 
 
        if (params.bonusAmount > 0) { 
            vf.bonusAmount = params.bonusAmount;

            // For the purpose of knowing whether a VF is unresolvable, 
            // the bonus amount is equivalent to a commitment to a "virtual" outcome 
            // that never wins, but only serves the purpose of increasing the total
            // amount committed to the VF
            vf.nonzeroOutcomeCount += 1;
 
            // nonReentrant 
            // Since createVirtualFloor is guarded by require(_internalState == None)
            // and _internalState has now been moved to Active,
            // the following external safeTransferFrom call cannot re-enter createVirtualFloor.
            params.paymentToken.safeTransferFrom(_msgSender(), address(this), params.bonusAmount); 
        } 
 
        uint256 min; 
        uint256 max; 
        {
            // First store raw values ... 
            vf._optionalMinCommitmentAmount = params.optionalMinCommitmentAmount.toUint128();
            vf._optionalMaxCommitmentAmount = params.optionalMaxCommitmentAmount.toUint128(); 
            // ... then validate values returned through the library getter. 
            (min, max) = vf.minMaxCommitmentAmounts(); 
            if (!(_MIN_POSSIBLE_COMMITMENT_AMOUNT <= min && min <= max && max <= _MAX_POSSIBLE_COMMITMENT_AMOUNT)) revert InvalidMinMaxCommitmentAmounts(); 
        }

        // Extracting this value to a local variable 
        // averts a "Stack too deep" CompilerError in the 
        // subsequent `emit`
        EncodedVirtualFloorMetadata calldata metadata = params.metadata;

        emit VirtualFloorCreation({
            vfId: params.vfId,
            creator: vf.creator, 
            betaOpen_e18: params.betaOpen_e18, 
            totalFeeRate_e18: params.totalFeeRate_e18,
            protocolFeeRate_e18: _protocolFeeRate.toUFixed256x18(), 
            tOpen: params.tOpen, 
            tClose: params.tClose,
            tResolve: params.tResolve, 
            nOutcomes: params.nOutcomes, 
            paymentToken: params.paymentToken,
            bonusAmount: params.bonusAmount,
            minCommitmentAmount: min, 
            maxCommitmentAmount: max,
            metadata: metadata
        });
 
        // nonReentrant 
        // Since createVirtualFloor is guarded by require(_internalState == None) 
        // and _internalState has now been moved to Active,
        // any external calls made by _onVirtualFloorCreation cannot re-enter createVirtualFloor. 
        // 
        // Hooks might want to read VF values from storage, so hook-call must happen last. 
        _onVirtualFloorCreation(params); 
    }
 

    // ----------🎲 Lifecycle: Committing ERC-20 tokens to an Active VF's outcome and receiving ERC-1155 token balance in return 🎲---------- 

    /**
     * @notice Commitment transaction not mined within the specified deadline.
     */ 
    error CommitmentDeadlineExpired(); 

    /** 
     * @notice minCommitmentAmount <= amount <= maxCommitmentAmount not satisfied.
     */
    error CommitmentAmountOutOfRange(); 
 
    event UserCommitment(
        uint256 indexed vfId,
        address indexed committer, 
        uint8 outcomeIndex, 
        uint256 timeslot, 
        uint256 amount, 
        UFixed256x18 beta_e18,
        uint256 tokenId 
    );

    /** 
     * @notice Commit a non-zero amount of payment-token to one of the VF's outcomes. 
     * Calling account must have pre-approved the amount as spending allowance to this contract. 
     * @param vfId Id of VF to which to commit. 
     * @param outcomeIndex 0-based index of VF outcome to which to commit. Must be < nOutcomes. 
     * @param amount Amount of ERC-20 payment-token vf.paymentToken to commit.
     * @param optionalDeadline Latest timestamp at which transaction can be mined. Pass 0 to not enforce a deadline.
     */ 
    function commitToVirtualFloor(uint256 vfId, uint8 outcomeIndex, uint256 amount, uint256 optionalDeadline) 
        public 
        whenNotPaused 
        nonReentrant
    {
        // Note: if-condition is a minor gas optimization; it costs ~20 gas more to test the if-condition,
        // but if it deadline is left unspecified, it saves ~400 gas. 
        if (optionalDeadline != 0) { 
            // solhint-disable-next-line not-rely-on-time 
            if (!(block.timestamp <= optionalDeadline)) revert CommitmentDeadlineExpired(); 
        } 
 
        VirtualFloor storage vf = _vfs[vfId]; 
 
        if (!vf.isOpen()) revert WrongVirtualFloorState(vf.state());

        if (!(outcomeIndex < vf.nOutcomes)) revert OutcomeIndexOutOfRange(); 
 
        (uint256 minAmount, uint256 maxAmount) = vf.minMaxCommitmentAmounts(); 
        if (!(minAmount <= amount && amount <= maxAmount)) revert CommitmentAmountOutOfRange(); 

        vf.paymentToken.safeTransferFrom(_msgSender(), address(this), amount); 
 
        // Commitments made at t < tOpen will all be accumulated into the same timeslot == tOpen, 
        // and will therefore be assigned the same beta == betaOpen.
        // This means that all commitments to a specific outcome that happen at t <= tOpen
        // will be minted as balances on the the same ERC-1155 tokenId, which means that
        // these balances will be exchangeable/tradeable/fungible between themselves,
        // but they will not be fungible with commitments to the same outcome that arrive later. 
        // solhint-disable-next-line not-rely-on-time 
        uint256 timeslot = MathUpgradeable.max(vf.tOpen, block.timestamp);

        UFixed256x18 beta_e18 = vf.betaOf(timeslot);
        OutcomeTotals storage outcomeTotals = vf.outcomeTotals[outcomeIndex];
 
        // Only increment this counter the first time an outcome is committed to.
        // In this way, this counter will be updated maximum nOutcome times over the entire commitment period. 
        // Some gas could be saved here by marking as unchecked, and by not counting beyond 2,
        // but these micro-optimizations are forfeited to retain simplicity. 
        if (outcomeTotals.amount == 0) {
            vf.nonzeroOutcomeCount += 1;
        }
 
        outcomeTotals.amount += amount; 
        outcomeTotals.amountTimesBeta_e18 = outcomeTotals.amountTimesBeta_e18.add(beta_e18.mul0(amount)); 

        uint256 tokenId = ERC1155TokenIds.vfOutcomeTimeslotIdOf(vfId, outcomeIndex, timeslot);

        // It is useful to the Graph indexer for the commitment-parameters to have been bound to a particular tokenId
        // before that same tokenId is referenced in a transfer. 
        // For this reason, the UserCommitment event is emitted before _mint emits TransferSingle.
        emit UserCommitment({ 
            vfId: vfId, 
            committer: _msgSender(), 
            outcomeIndex: outcomeIndex,
            timeslot: timeslot, 
            amount: amount,
            beta_e18: beta_e18, 
            tokenId: tokenId 
        }); 
        _mint({ 
            to: _msgSender(),
            id: tokenId,
            amount: amount,
            data: hex"" 
        }); 
    }
 

    // ----------🎲 Lifecycle: Transferring commitment-balances held on an Active VF 🎲---------- 
 
    error CommitmentBalanceTransferWhilePaused();

    error CommitmentBalanceTransferRejection(uint256 id, VirtualFloorState state);
 
    /**
     * @dev Hook into ERC-1155 transfer process to allow commitment-balances to be transferred only if VF
     * in states `Active_Open_ResolvableLater` and `Active_Closed_ResolvableLater`.
     */
    function _beforeTokenTransfer( 
        address /*operator*/,
        address from,
        address to, 
        uint256[] memory ids, 
        uint256[] memory /*amounts*/, 
        bytes memory /*data*/
    ) 
        internal
        override
        virtual
    {
        // No restrictions on mint/burn
        if (from == address(0) || to == address(0)) { 
            return;
        }
 
        if (paused()) revert CommitmentBalanceTransferWhilePaused(); 

        for (uint256 i = 0; i < ids.length; i++) { 
            uint256 id = ids[i]; 
            VirtualFloorState state = _vfs[id.extractVirtualFloorId()].state(); 
            if (!(state == VirtualFloorState.Active_Open_ResolvableLater || state == VirtualFloorState.Active_Closed_ResolvableLater)) { 
                revert CommitmentBalanceTransferRejection(id, state); 
            }
        }
    } 

 
    // ----------🎲 Lifecycle: Cancelling an Active VF that could never possibly be resolved 🎲----------

    event VirtualFloorCancellationUnresolvable( 
        uint256 indexed vfId 
    ); 
 
    /**
     * @notice A VF's commitment period closes at `tClose`. If at this point there are 0 commitments to 0 outcomes, 
     * or there are > 0 commitments, but all to a single outcome, then this VF is considered *unresolvable*. 
     * For such a VF:
     * 1. ERC-1155 commitment-balances on outcomes of this VF can no longer transferred.
     * 2. The only possible action for this VF is for *anyone* to invoke this function to cancel the VF. 
     */
    function cancelVirtualFloorUnresolvable(uint256 vfId)
        public
        whenNotPaused 
    {
        VirtualFloor storage vf = _vfs[vfId]; 
        VirtualFloorState state = vf.state(); 
        if (!(state == VirtualFloorState.Active_Closed_ResolvableNever)) revert WrongVirtualFloorState(state);
        vf._internalState = VirtualFloorInternalState.Claimable_Refunds_ResolvableNever;
        emit VirtualFloorCancellationUnresolvable(vfId);

        // nonReentrant 
        // Since cancelVirtualFloorUnresolvable is guarded by require(_internalState == Active)
        // and _internalState has now been moved to Claimable_Refunds_ResolvableNever, 
        // any external calls made from this point onwards cannot re-enter cancelVirtualFloorUnresolvable.
 
        vf.refundBonusAmount(); 

        _onVirtualFloorConclusion(vfId); 
    } 

 
    // ----------🎲 Lifecycle: Cancelling an Active VF that was flagged 🎲---------- 
 
    event VirtualFloorCancellationFlagged( 
        uint256 indexed vfId, 
        string reason
    ); 
 
    function cancelVirtualFloorFlagged(uint256 vfId, string calldata reason) 
        public
        onlyRole(OPERATOR_ROLE)
    {
        VirtualFloor storage vf = _vfs[vfId];
        if (!(vf._internalState == VirtualFloorInternalState.Active)) revert WrongVirtualFloorState(vf.state()); 
        vf._internalState = VirtualFloorInternalState.Claimable_Refunds_Flagged; 
        emit VirtualFloorCancellationFlagged(vfId, reason); 

        // nonReentrant 
        // Since cancelVirtualFloorFlagged is guarded by require(_internalState == Active) 
        // and _internalState has now been moved to Claimable_Refunds_Flagged, 
        // any external calls made from this point onwards cannot re-enter cancelVirtualFloorFlagged. 

        vf.refundBonusAmount();
 
        _onVirtualFloorConclusion(vfId); 
    }
 

    // ----------🎲 Lifecycle: Resolving a VF to the winning outcome 🎲---------- 

    error ResolveWhilePaused();

    enum VirtualFloorResolutionType { 
        /**
         * @notice VF resolved to an outcome to which there were 0 commitments,
         * so the VF will be cancelled. 
         */ 
        NoWinners, 

        /** 
         * @notice VF resolved to an outcome to which there were commitments,
         * so all commitments to that outcome will be able to claim payouts. 
         */ 
        Winners
    } 

    event VirtualFloorResolution(
        uint256 indexed vfId, 
        uint8 winningOutcomeIndex, 
        VirtualFloorResolutionType resolutionType, 
        uint256 winnerProfits,
        uint256 protocolFeeAmount,
        uint256 creatorFeeAmount
    );

    /** 
     * @dev This base function only requires that the VF is in the correct state to be resolved,
     * but it is up to the extending contract to decide how to restrict further the conditions under which VF is resolved, 
     * e.g. through a consensus mechanism, or via integration with an external oracle. 
     */
    function _resolve(uint256 vfId, uint8 winningOutcomeIndex, address creatorFeeBeneficiary) internal { 
        if (paused()) revert ResolveWhilePaused(); 
 
        VirtualFloor storage vf = _vfs[vfId]; 
 
        VirtualFloorState state = vf.state(); 
        if (!(state == VirtualFloorState.Active_Closed_ResolvableNow)) revert WrongVirtualFloorState(state);
 
        if (!(winningOutcomeIndex < vf.nOutcomes)) revert OutcomeIndexOutOfRange(); 

        vf.winningOutcomeIndex = winningOutcomeIndex; 
 
        uint256 totalCommitmentsToAllOutcomesPlusBonus = vf.totalCommitmentsToAllOutcomesPlusBonus(); 
        uint256 totalCommitmentsToWinningOutcome = vf.outcomeTotals[winningOutcomeIndex].amount;

        // If all funds under this VF were to be under a single outcome, 
        // then nonzeroOutcomeCount would be == 1 and 
        // the VF would not be in state Active_Closed_ResolvableNow.
        // Therefore the following assertion should never fail. 
        assert(totalCommitmentsToWinningOutcome != totalCommitmentsToAllOutcomesPlusBonus); 
 
        VirtualFloorResolutionType resolutionType;
        uint256 protocolFeeAmount;
        uint256 creatorFeeAmount; 
        uint256 totalWinnerProfits;

        if (totalCommitmentsToWinningOutcome == 0) {
            // This could happen if e.g. there are commitments to outcome #0 and outcome #1, 
            // but not to outcome #2, and #2 is the winner.
            // In this case, the current ERC-1155 commitment-balance owner becomes eligible
            // to reclaim the equivalent original ERC-20 token amount, 
            // i.e. to withdraw the current ERC-1155 balance amount as ERC-20 tokens. 
            // Neither the creator nor the protocol apply any fees in this circumstance. 
            vf._internalState = VirtualFloorInternalState.Claimable_Refunds_ResolvedNoWinners;
            resolutionType = VirtualFloorResolutionType.NoWinners; 
            protocolFeeAmount = 0; 
            creatorFeeAmount = 0;
            totalWinnerProfits = 0;
 
            vf.refundBonusAmount();
        } else {
            vf._internalState = VirtualFloorInternalState.Claimable_Payouts;
            resolutionType = VirtualFloorResolutionType.Winners;

            // Winner commitments refunded, fee applied, then remainder split between winners proportionally by `commitment * beta`. 
            uint256 maxTotalFeeAmount = vf.totalFeeRate.toUFixed256x18().mul0(totalCommitmentsToAllOutcomesPlusBonus).floorToUint256();

            // If needs be, limit the fee to ensure that there enough funds to be able to refund winner commitments in full.
            uint256 totalFeePlusTotalWinnerProfits = totalCommitmentsToAllOutcomesPlusBonus - totalCommitmentsToWinningOutcome; 

            uint256 totalFeeAmount = MathUpgradeable.min(maxTotalFeeAmount, totalFeePlusTotalWinnerProfits); 
 
            unchecked { // because b - min(a, b) >= 0
                totalWinnerProfits = totalFeePlusTotalWinnerProfits - totalFeeAmount;
            }
            vf.winnerProfits = totalWinnerProfits.toUint192();

            // Since protocolFeeRate <= 1.0, protocolFeeAmount will always be <= totalFeeAmount...
            protocolFeeAmount = vf.protocolFeeRate.toUFixed256x18().mul0(totalFeeAmount).floorToUint256();
            vf.paymentToken.safeTransfer(_protocolFeeBeneficiary, protocolFeeAmount); 
 
            unchecked { // ... so this subtraction will never underflow.
                creatorFeeAmount = totalFeeAmount - protocolFeeAmount;
            }

            vf.paymentToken.safeTransfer(creatorFeeBeneficiary, creatorFeeAmount);
        }

        emit VirtualFloorResolution({
            vfId: vfId, 
            winningOutcomeIndex: winningOutcomeIndex, 
            resolutionType: resolutionType,
            winnerProfits: totalWinnerProfits,
            protocolFeeAmount: protocolFeeAmount,
            creatorFeeAmount: creatorFeeAmount 
        }); 
 
        _onVirtualFloorConclusion(vfId);
    } 


    // ----------🎲 Lifecycle: Claiming ERC-20 payouts/refunds for commitment-balance held on a Claimable VF 🎲---------- 

    /**
     * @notice Token id `tokenId` does not match the specified VF id 
     */ 
    error MismatchedVirtualFloorId(uint256 tokenId);
 
    /** 
     * @notice For a VF that has been cancelled, 
     * claim the original ERC-20 commitments corresponding to the ERC-1155 balances
     * held by the calling account on the specified `tokenIds`.
     * @param vfId The VF id. This VF must be in one of the Claimable_Refunds states. 
     * @param tokenIds The ERC-1155 token-ids for which to claim refunds.
     * If a tokenId is included multiple times, it will count only once. 
     */
    function claimRefunds(uint256 vfId, uint256[] calldata tokenIds) 
        public 
        whenNotPaused 
    {
        VirtualFloor storage vf = _vfs[vfId]; 
        if (!vf.isClaimableRefunds()) revert WrongVirtualFloorState(vf.state());
        address msgSender = _msgSender(); 
        uint256 totalPayout = 0;
        uint256[] memory amounts = new uint256[](tokenIds.length); 
        for (uint256 i = 0; i < tokenIds.length; i++) { 
            uint256 tokenId = tokenIds[i];
            (uint256 extractedVfId, /*outcomeIndex*/, /*timeslot*/) = tokenId.destructure();
            if (!(extractedVfId == vfId)) revert MismatchedVirtualFloorId(tokenId);
            uint256 amount = _balances[tokenId][msgSender];
            amounts[i] = amount; 
            if (amount > 0) { 
                _balances[tokenId][msgSender] = 0;
                totalPayout += amount;
            }
        } 
        emit TransferBatch(msgSender, msgSender, address(0), tokenIds, amounts); 

        // nonReentrant 
        // Since at this point in claimRefunds the ERC-1155 balances have already been burned,
        // the following external safeTransfer call cannot re-enter claimRefunds and re-claim.
        vf.paymentToken.safeTransfer(msgSender, totalPayout);
    }
 
    /** 
     * @notice For a VF that has been resolved with winners and winner-profits,
     * claim the share of the total ERC-20 winner-profits corresponding to the ERC-1155 balances 
     * held by the calling account on the specified `tokenIds`.
     * If a tokenId is included multiple times, it will count only once.
     * @param vfId The VF id. This VF must be in the Claimable_Payouts state.
     * @param tokenIds The ERC-1155 token-ids for which to claim payouts. 
     * If a tokenId is included multiple times, it will count only once. 
     */
    function claimPayouts(uint256 vfId, uint256[] calldata tokenIds) 
        public
        whenNotPaused 
    {
        VirtualFloor storage vf = _vfs[vfId];
        { 
            VirtualFloorState state = vf.state(); 
            if (!(state == VirtualFloorState.Claimable_Payouts)) revert WrongVirtualFloorState(state); 
        } 
        address msgSender = _msgSender();
        uint256 totalPayout = 0;
        uint256[] memory amounts = new uint256[](tokenIds.length);
        uint8 winningOutcomeIndex = vf.winningOutcomeIndex; 
        UFixed256x18 winningOutcomeTotalAmountTimesBeta = vf.outcomeTotals[winningOutcomeIndex].amountTimesBeta_e18;
        uint256 totalWinnerProfits = vf.winnerProfits; 
        for (uint256 i = 0; i < tokenIds.length; i++) { 
            uint256 tokenId = tokenIds[i];
            (uint256 extractedVfId, uint8 outcomeIndex, uint32 timeslot) = tokenId.destructure(); 
            if (!(extractedVfId == vfId)) revert MismatchedVirtualFloorId(tokenId); 
            uint256 amount = _balances[tokenId][msgSender]; 
            amounts[i] = amount; 
            _balances[tokenId][msgSender] = 0;
            if (outcomeIndex == winningOutcomeIndex) { 
                UFixed256x18 beta = vf.betaOf(timeslot); 
                UFixed256x18 amountTimesBeta = beta.mul0(amount);
                uint256 profit = amountTimesBeta.mul0(totalWinnerProfits).divToUint256(winningOutcomeTotalAmountTimesBeta);
                totalPayout += amount + profit;
            }
        }
        emit TransferBatch(msgSender, msgSender, address(0), tokenIds, amounts); 
 
        // nonReentrant
        // Since at this point in claimPayouts the ERC-1155 balances have already been burned, 
        // the following external safeTransfer call cannot re-enter claimPayouts and re-claim. 
        vf.paymentToken.safeTransfer(msgSender, totalPayout); 
    } 
 

    // ----------🎲 Lifecycle: Overrideable VF lifecycle hooks 🎲---------- 
 
    // solhint-disable-next-line no-empty-blocks 
    function _onVirtualFloorCreation(VirtualFloorCreationParams calldata params) internal virtual {
    }

    // solhint-disable-next-line no-empty-blocks 
    function _onVirtualFloorConclusion(uint256 vfId) internal virtual { 
    }
 

    // ----------🎲🎲 FURTHER INTEROPERABILITY 🎲🎲----------
 

    // ----------🎲 Pausable 🎲----------

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) { 
        _pause();
    } 

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { 
        _unpause();
    } 


    // ----------🎲 Ownable 🎲---------- 
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); 
 
    /**
     * @notice Does not control anything on the contract, but simply exposes the protocolFeeBeneficiary as the `Ownable.owner()`
     * to enable this contract to interface with 3rd-party tools.
     */
    function owner() external view returns (address) { 
        return _protocolFeeBeneficiary; 
    } 
 

    // ----------🎲 ERC-165 🎲----------

    function supportsInterface(bytes4 interfaceId)
        public 
        view 
        override(ForkedERC1155UpgradeableV4_5_2, AccessControlUpgradeable)
        virtual
        returns (bool) 
    { 
        return ForkedERC1155UpgradeableV4_5_2.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    } 
 
 
    /**
     * @dev See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap; 

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;


/**
 * @title Generic utility functions
 * @author 🎲🎲 <[email protected]>
 */
library Utils {

    /**
     * @notice `value` doesn't fit in 192 bits
     */
    error TooLargeForUint192(uint256 value);

    function toUint192(uint256 value) internal pure returns (uint192) {
        if (!(value <= type(uint192).max)) revert TooLargeForUint192(value);
        return uint192(value);
    }


    function isEmpty(string memory value) internal pure returns (bool) {
        return bytes(value).length == 0;
    }


    /**
     * @dev Addition of a signed int256 to an unsigned uint256, returning a unsigned uint256,
     * (implicitly) checked for over/underflow.
     */
    function add(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return a + uint256(b);
        } else {
            return a - uint256(-b);
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";



// ----------------------------------------🎲🎲 ABOUT THIS FORK 🎲🎲----------------------------------------
// THIS FORK IS IDENTICAL TO ORIGINAL IMPLEMENTATION IN openzeppelin/[email protected],
// BUT WITH VISIBILITY OF `_balances` ALTERED FROM `private` TO `internal`,
// AND WITH `pragma solidity ^0.8.0` RESTRICTED TO `pragma solidity 0.8.12`



/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ForkedERC1155UpgradeableV4_5_2 is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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
        require(account != address(0), "ERC1155: balance query for the zero address");
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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
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

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
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

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
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
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
    function _beforeTokenTransfer(
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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

/**
 * @title VF ids and ERC-1155 commitment-balance ids
 * @author 🎲🎲 <[email protected]>
 * @notice Logic for VirtualFloor (VF) ids, and for ERC-1155 token-ids
 * representing commitments on specific VF-outcome-timeslot combinations.
 * @dev Both VF ids and VF-outcome-timeslot ids are uint256.
 * The lower 5 bytes of a VF id are always 5 zero-bytes, so the 32 bytes of a VF id
 * always have the shape `VVVVVVVVVVVVVVVVVVVVVVVVVVV00000`.
 * An account that at (4-byte) timeslot `TTTT` commits a `n` ERC-20 token units
 * to a specific (1-byte) outcome index `I` of a VF with id `VVVVVVVVVVVVVVVVVVVVVVVVVVV00000`,
 * will in return be minted a balance of `n` units on the ERC-1155 token-id `VVVVVVVVVVVVVVVVVVVVVVVVVVVITTTT`.
 */
library ERC1155TokenIds {

    using SafeCastUpgradeable for uint256;

    /**
     * @dev The lower 5 bytes of a VF id must always be 0.
     */
    function isValidVirtualFloorId(uint256 value) internal pure returns (bool) {
        return value & 0xff_ff_ff_ff_ff == 0;
    }

    function extractVirtualFloorId(uint256 erc1155TokenId) internal pure returns (uint256) {
        return erc1155TokenId & ~uint256(0xff_ff_ff_ff_ff);
    }

    /**
     * @dev Destructure an ERC-1155 token-id `VVVVVVVVVVVVVVVVVVVVVVVVVVVITTTT` into its
     * `VVVVVVVVVVVVVVVVVVVVVVVVVVV00000`, `I` and `TTTT` components.
     */
    function destructure(
        uint256 erc1155TokenId
    ) internal pure returns (
        uint256 vfId,
        uint8 outcomeIndex,
        uint32 timeslot
    ) {
        vfId = erc1155TokenId & ~uint256(0xff_ff_ff_ff_ff);
        outcomeIndex = uint8((erc1155TokenId >> 32) & 0xff);
        timeslot = uint32(erc1155TokenId & 0xff_ff_ff_ff);
    }

    /**
     * @dev Assemble `VVVVVVVVVVVVVVVVVVVVVVVVVVV00000`, `I` and `TTTT` components
     * into an ERC-1155 token-id `VVVVVVVVVVVVVVVVVVVVVVVVVVVITTTT`.
     * This function should only be called with a valid VF-id.
     */
    function vfOutcomeTimeslotIdOf(
        uint256 validVirtualFloorId,
        uint8 outcomeIndex,
        uint256 timeslot
    )
        internal
        pure
        returns (uint256 tokenId)
    {
        // Since this function should always be called after the VF
        // has already been required to be in one of the non-None states,
        // and a VF can only be in a non-None state if it has a valid id,
        // then this assertion should never fail.
        assert(isValidVirtualFloorId(validVirtualFloorId));

        tokenId = uint256(bytes32(abi.encodePacked(
            bytes27(bytes32(validVirtualFloorId)), //   27 bytes
            outcomeIndex,                          // +  1 byte
            timeslot.toUint32()                    // +  4 bytes
        )));                                       // = 32 bytes
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";


/**
 * @dev Holds range [0.000000, 4294.967295]
 */
type UFixed32x6 is uint32;

/**
 * @dev Holds range [0.0000, 6.5535]
 */
type UFixed16x4 is uint16;

/**
 * @dev Holds range
 * [000000000000000000000000000000000000000000000000000000000000.000000000000000000,
 * 115792089237316195423570985008687907853269984665640564039457.584007913129639935]
 */
type UFixed256x18 is uint256;


/**
 * @dev The value 1.000000000000000000
 */
UFixed256x18 constant UFIXED256X18_ONE = UFixed256x18.wrap(1e18);


/**
 * @title Generic fixed-point type arithmetic and safe-casting functions
 * @author 🎲🎲 <[email protected]>
 * @dev The primary fixed-point type in this library is UFixed256x18,
 * but some conversions to/from UFixed32x6 and UFixed16x4 are also provided,
 * as these are used in the main contract.
 */
library FixedPointTypes {

    using SafeCastUpgradeable for uint256;
    using FixedPointTypes for UFixed16x4;
    using FixedPointTypes for UFixed32x6;
    using FixedPointTypes for UFixed256x18;

    function add(UFixed256x18 a, UFixed256x18 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) + UFixed256x18.unwrap(b));
    }

    function sub(UFixed256x18 a, UFixed256x18 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) - UFixed256x18.unwrap(b));
    }

    /**
     * @dev e.g. 1.230000_000000_000000 * 3 = 3.690000_000000_000000
     * Named `mul0` because unlike `add` and `sub`, `b` is `UFixed256x0`, not `UFixed256x18`
     */
    function mul0(UFixed256x18 a, uint256 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) * b);
    }

    function div0(UFixed256x18 a, uint256 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) / b);
    }

    /**
     * @dev More efficient implementation of (hypothetical) `value.div(b).toUint256()`
     * e.g. 200.000000_000000_000000 / 3.000000_000000_000000 = 33
     */
    function divToUint256(UFixed256x18 a, UFixed256x18 b) internal pure returns (uint256) {
        return UFixed256x18.unwrap(a) / UFixed256x18.unwrap(b);
    }

    /**
     * @dev More efficient implementation of (hypothetical) `value.floor().toUint256()`
     * e.g. 987.654321_000000_000000 => 987
     */
    function floorToUint256(UFixed256x18 value) internal pure returns (uint256) {
        return UFixed256x18.unwrap(value) / 1e18;
    }

    function eq(UFixed256x18 a, UFixed256x18 b) internal pure returns (bool) {
        return UFixed256x18.unwrap(a) == UFixed256x18.unwrap(b);
    }

    function gte(UFixed256x18 a, UFixed256x18 b) internal pure returns (bool) {
        return UFixed256x18.unwrap(a) >= UFixed256x18.unwrap(b);
    }

    function lte(UFixed256x18 a, UFixed256x18 b) internal pure returns (bool) {
        return UFixed256x18.unwrap(a) <= UFixed256x18.unwrap(b);
    }


     /**
      * @notice Cannot convert UFixed256x18 `value` to UFixed16x4 without losing precision
      */
    error UFixed16x4LossOfPrecision(UFixed256x18 value);

    /**
     * @notice e.g. 1.234500_000000_000000 => 1.2345
     * Reverts if input is too large to fit in output-type,
     * or if conversion would lose precision, e.g. 1.234560_000000_000000 will revert.
     */
    function toUFixed16x4(UFixed256x18 value) internal pure returns (UFixed16x4 converted) {
        converted = UFixed16x4.wrap((UFixed256x18.unwrap(value) / 1e14).toUint16());
        if (!(converted.toUFixed256x18().eq(value))) revert UFixed16x4LossOfPrecision(value);
    }


    /**
     * @notice Cannot convert UFixed256x18 `value` to UFixed32x6 without losing precision
     */
    error UFixed32x6LossOfPrecision(UFixed256x18 value);

    /**
     * @notice e.g. 123.456789_000000_000000 => 123.456789
     * Reverts if input is too large to fit in output-type,
     * or if conversion would lose precision, e.g. 123.456789_100000_000000 will revert.
     */
    function toUFixed32x6(UFixed256x18 value) internal pure returns (UFixed32x6 converted) {
        converted = UFixed32x6.wrap((UFixed256x18.unwrap(value) / 1e12).toUint32());
        if (!(converted.toUFixed256x18().eq(value))) revert UFixed32x6LossOfPrecision(value);
    }


    /**
     * @notice e.g. 123 => 123.000000_000000_000000
     * Reverts if input is too large to fit in output-type.
     */
    function toUFixed256x18(uint256 value) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(value * 1e18);
    }

    /**
     * @notice e.g. 1.2345 => 1.234500_000000_000000
     * Input always fits in output-type.
     */
    function toUFixed256x18(UFixed16x4 value) internal pure returns (UFixed256x18 converted) {
        unchecked { // because type(uint16).max * 1e14 <= type(uint256).max
            return UFixed256x18.wrap(uint256(UFixed16x4.unwrap(value)) * 1e14);
        }
    }

    /**
     * @notice e.g. 123.456789 => 123.456789_000000_000000
     * Input always fits in output-type.
     */
    function toUFixed256x18(UFixed32x6 value) internal pure returns (UFixed256x18 converted) {
        unchecked { // because type(uint32).max * 1e12 <= type(uint256).max
            return UFixed256x18.wrap(uint256(UFixed32x6.unwrap(value)) * 1e12);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../BaseDoubleDice.sol";
import "./FixedPointTypes.sol";
import "./ERC1155TokenIds.sol";
import "./VirtualFloors.sol";


/**
 * @notice Versioned & abi-encoded VF metadata
 * @dev BaseDoubleDice.createVirtualFloor treats VF metadata as opaque bytes.
 * In this way, contract can be upgraded to new metadata formats without altering createVirtualFloor signature.
 */
struct EncodedVirtualFloorMetadata {
    /**
     * @notice Version that determines how the encoded metadata bytes are decoded.
     */
    bytes32 version;

    /**
     * @notice Encoded metadata.
     */
    bytes data;
}

struct VirtualFloorCreationParams {

    /**
     * @notice The VF id.
     * Lower 5 bytes must be 0x00_00_00_00_00. Upper 27 bytes must be unique.
     * Since all VF-related functions accept this id as an argument,
     * it pays to choose an id with more zero-bytes, as these waste less intrinsic gas,
     * and the savings will add up in the long run.
     * Suggestion: This id could be of the form 0xVV_VV_VV_VV_00_00_00_00_00
     */
    uint256 vfId;

    /**
     * @notice Opening beta-multiplier value.
     * This is the beta value at tOpen. The value of beta is fixed at betaOpen up until tOpen, then decreases linearly with time to 1.0 at tClose.
     * Should be >= 1.0.
     * E.g. 23.4 is specified as 23_400000_000000_000000
     */
    UFixed256x18 betaOpen_e18;

    /**
     * @notice Fee-rate to be applied to a winning VF's total committed funds.
     * Should be <= 1.0.
     * E.g. 2.5%, or 0.025, is specified as the value 0_025000_000000_000000
     */
    UFixed256x18 totalFeeRate_e18;

    /**
     * @notice Commitment-period begins as soon as a VF is created, but up until tOpen, beta is fixed at betaOpen.
     * tOpen is the timestamp at which beta starts decreasing.
     */
    uint32 tOpen;

    /**
     * @notice Commitment-period closes at tClose.
     */
    uint32 tClose;

    /**
     * @notice The official timestamp at which the result is known. VF can be resolved from tResolve onwards.
     */
    uint32 tResolve;

    /**
     * @notice Number of mutually-exclusive outcomes for this VF.
     */
    uint8 nOutcomes;

    /**
     * @notice Address of ERC-20 token used for commitments and payouts/refunds in this VF.
     */
    IERC20Upgradeable paymentToken;

    /**
     * @notice An optional amount of payment-token to deposit into the VF as a incentive.
     * bonusAmount will contribute toward winnings if VF is concluded with winners,
     * and will be refunded to creator if VF is cancelled.
     * Creator account must have pre-approved the bonusAmount as spending allowance to this contract.
     */
    uint256 bonusAmount;

    /**
     * @notice The minimum amount of payment-token that should be committed to this VF per-commitment.
     * If left unspecified (by passing 0), will default to the minimum non-zero possible ERC-20 amount.
     */
    uint256 optionalMinCommitmentAmount;

    /**
     * @notice The maximum amount of payment-token that can be committed to this VF per-commitment.
     * If left unspecified (by passing 0), will default to no-maximum.
     */
    uint256 optionalMaxCommitmentAmount;

    /**
     * @notice Encoded VF metadata.
     */
    EncodedVirtualFloorMetadata metadata;
}


/**
 * @title VirtualFloorCreationParams object methods
 * @author 🎲🎲 <[email protected]>
 */
library VirtualFloorCreationParamsUtils {

    using ERC1155TokenIds for uint256;
    using FixedPointTypes for UFixed256x18;


    /**
     * @dev Estimate of max(world timestamp - block.timestamp)
     */
    uint256 constant internal _MAX_POSSIBLE_BLOCK_TIMESTAMP_DISCREPANCY = 60 seconds;

    uint256 constant internal _MIN_POSSIBLE_T_RESOLVE_MINUS_T_CLOSE = 10 * _MAX_POSSIBLE_BLOCK_TIMESTAMP_DISCREPANCY;


    /**
     * @notice A VF id's lower 5 bytes must be 0x00_00_00_00_00
     */
    error InvalidVirtualFloorId();

    /**
     * @notice betaOpen >= 1.0 not satisfied
     */
    error BetaOpenTooSmall();

    /**
     * @notice totalFeeRate <= 1.0 not satisfied
     * @dev To be renamed to `TotalFeeRateTooLarge`.
     */
    error CreationFeeRateTooLarge();

    /**
     * @notice VF timeline does not satisfy relation tOpen < tClose <= tResolve
     */
    error InvalidTimeline();

    /**
     * @notice nOutcomes >= 2 not satisfied
     */
    error NotEnoughOutcomes();


    function validatePure(VirtualFloorCreationParams calldata params) internal pure {
        if (!params.vfId.isValidVirtualFloorId()) revert InvalidVirtualFloorId();
        if (!(params.betaOpen_e18.gte(_BETA_CLOSE))) revert BetaOpenTooSmall();
        if (!(params.totalFeeRate_e18.lte(UFIXED256X18_ONE))) revert CreationFeeRateTooLarge();
        if (!(params.tOpen < params.tClose && params.tClose + _MIN_POSSIBLE_T_RESOLVE_MINUS_T_CLOSE <= params.tResolve)) revert InvalidTimeline();
        if (!(params.nOutcomes >= 2)) revert NotEnoughOutcomes();
    }


    /**
     * @dev Allow creation to happen up to 10% into the period tOpen ≤ t ≤ tClose, to tolerate mining delays.
     */
    function tCreateMax(VirtualFloorCreationParams calldata params) internal pure returns (uint256) {
        return params.tOpen + (params.tClose - params.tOpen) / 10;
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./FixedPointTypes.sol";

/**
 * @dev beta = 1.0 at the VF's close-time.
 */
UFixed256x18 constant _BETA_CLOSE = UFIXED256X18_ONE;

uint256 constant _MIN_POSSIBLE_COMMITMENT_AMOUNT = 1;

uint256 constant _MAX_POSSIBLE_COMMITMENT_AMOUNT = type(uint256).max;

/**
 * @dev 255 not 256, because nOutcomes is stored in in a uint8
 */
uint256 constant _MAX_OUTCOMES_PER_VIRTUAL_FLOOR = 255;

/**
 * @notice Totals over all commitments to a specific VF outcome
 */
struct OutcomeTotals {
    /**
     * @notice Total ERC-20 payment-token amount committed to this outcome.
     */
    uint256 amount;

    /**
     * @notice Total (ERC-20 payment-token amount × beta × 1e18) committed to this outcome.
     */
    UFixed256x18 amountTimesBeta_e18;
}

/**
 * @dev Component of the VF state that is stored on-chain.
 * This is combined with block.timestamp and vf.nonzeroOutcomeCount to calculate the exact state.
 */
enum VirtualFloorInternalState {
    None,
    Active,
    Claimable_Payouts,
    Claimable_Refunds_ResolvedNoWinners,
    Claimable_Refunds_ResolvableNever,
    Claimable_Refunds_Flagged
}

/**
 * @dev Main VF data structure.
 */
struct VirtualFloor {
    // Storage slot 0
    address creator; //   20 bytes
    uint32 tOpen;    // +  4 bytes
    uint32 tClose;   // +  4 bytes
    uint32 tResolve; // +  4 bytes
                     // = 32 bytes => packed into 1 32-byte slot

    // Storage slot 1
    UFixed32x6 betaOpenMinusBetaClose;        // +  4 bytes ; fits with 6-decimal-place precision entire range [0.000000, 4294.967295]
    UFixed16x4 totalFeeRate;                  // +  2 bytes ; fits with 4-decimal-place precision entire range [0.0000, 1.0000]
    UFixed16x4 protocolFeeRate;               // +  2 bytes ; fits with 4-decimal-place precision entire range [0.0000, 1.0000]
    uint8 nOutcomes;                          // +  1 byte
    VirtualFloorInternalState _internalState; // +  1 byte
    uint8 nonzeroOutcomeCount;                // +  1 byte  ; number of outcomes having aggregate commitments > 0
    IERC20Upgradeable paymentToken;           // + 20 bytes
                                              // = 31 bytes => packed into 1 32-byte slot

    // Storage slot 2: Not written to, but used in calculation of outcome-specific slots
    // A fixed-length array is used so as not to store an entire 32-byte slot to write array-length,
    // and instead the length is stored in 1 byte in `nOutcomes`
    OutcomeTotals[_MAX_OUTCOMES_PER_VIRTUAL_FLOOR] outcomeTotals;

    // Storage slot 3
    uint8 winningOutcomeIndex; // +  1 byte
    uint192 winnerProfits;     // + 24 bytes ; fits with 18-decimal-place precision all values up to ~1.5e30 (and with less decimals, more)
                               // = 25 bytes => packed into 1 32-byte slot

    // Storage slot 4
    uint256 bonusAmount;

    // Storage slot 5
    // _prefixed as they are not meant to be read directly, but through .minMaxCommitmentAmounts()
    uint128 _optionalMinCommitmentAmount;
    uint128 _optionalMaxCommitmentAmount;
}


/**
 * @notice Exact state of a VF.
 */
enum VirtualFloorState {
    /**
     * @notice VF does not exist.
     */
    None,

    /**
     * @notice VF accepting commitments to outcomes.
     * For a VF to be resolvable, there must be (i) one or more winners, and (ii) funds to share between those winners.
     * If a VF is in the `Active_Open_MaybeResolvableNever` state, it means that not enough commitments have been yet
     * made to enough different outcomes to ensure that it will be possible to meet these conditions when commitments close.
     * In this state commitment-balances on this VF cannot be transferred.
     */
    Active_Open_MaybeResolvableNever,

    /**
     * @notice VF open for commitments.
     * Enough commitments have been made to enough different outcomes to allow this VF to not be classified as *Unresolvable* at t == tClose.
     * In this VF state, commitment-balances on this VF may be transferred.
     */
    Active_Open_ResolvableLater,

    /**
     * @notice VF closed for commitments.
     * For a VF to be resolvable, there must be (i) one or more winners, and (ii) funds to share between those winners.
     * Commitment-period is now closed with either of these conditions left unsatisfied, so VF is classified as unresolvable.
     * Only possible action is to call cancelVirtualFloorUnresolvable.
     * In this state commitment-balances on this VF cannot be transferred.
     */
    Active_Closed_ResolvableNever,

    /**
     * @notice VF closed for commitments.
     * Only possible action is to wait for result to be published at tResolve.
     * In this VF state, commitment-balances on this VF may be transferred.
     */
    Active_Closed_ResolvableLater,

    /**
     * @notice The VF is active but is closed for commitments.
     * The only course of action is for the extending contract to call _resolve.
     */
    Active_Closed_ResolvableNow,

    /**
     * @notice The VF was resolved with a winning outcome,
     * and accounts having commitments on that winning outcome may call claimPayouts.
     */
    Claimable_Payouts,

    /**
     * @notice The VF was cancelled because there were no commitments to the winning outcome,
     * and accounts having commitments on any of this VF's outcomes may claim back a refund of the original commitment.
     */
    Claimable_Refunds_ResolvedNoWinners,

    /**
     * @notice The VF was cancelled because at close-time the VF was unresolvable,
     * and accounts having commitments on any of this VF's outcomes may claim back a refund of the original commitment.
     */
    Claimable_Refunds_ResolvableNever,

    /**
     * @notice The VF was cancelled because it was flagged,
     * and accounts having commitments on any of this VF's outcomes may claim back a refund of the original commitment.
     */
    Claimable_Refunds_Flagged
}



/**
 * @title VirtualFloor object methods
 * @author 🎲🎲 <[email protected]>
 */
library VirtualFloors {

    using FixedPointTypes for UFixed256x18;
    using FixedPointTypes for UFixed32x6;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using VirtualFloors for VirtualFloor;

    /**
     * @dev Combines the entire state of a VF into this single state value,
     * so that BaseDoubleDice can determine the next possible action for a VF based on
     * this combined state alone.
     */
    function state(VirtualFloor storage vf) internal view returns (VirtualFloorState) {
        VirtualFloorInternalState _internalState = vf._internalState;
        if (_internalState == VirtualFloorInternalState.None) {
            return VirtualFloorState.None;
        } else if (_internalState == VirtualFloorInternalState.Active) {
            // solhint-disable-next-line not-rely-on-time
            if (block.timestamp < vf.tClose) {
                if (vf.nonzeroOutcomeCount >= 2) {
                    return VirtualFloorState.Active_Open_ResolvableLater;
                } else {
                    return VirtualFloorState.Active_Open_MaybeResolvableNever;
                }
            } else {
                if (vf.nonzeroOutcomeCount >= 2) {
                    // solhint-disable-next-line not-rely-on-time
                    if (block.timestamp < vf.tResolve) {
                        return VirtualFloorState.Active_Closed_ResolvableLater;
                    } else {
                        return VirtualFloorState.Active_Closed_ResolvableNow;
                    }
                } else {
                    return VirtualFloorState.Active_Closed_ResolvableNever;
                }
            }
        } else if (_internalState == VirtualFloorInternalState.Claimable_Payouts) {
            return VirtualFloorState.Claimable_Payouts;
        } else if (_internalState == VirtualFloorInternalState.Claimable_Refunds_ResolvedNoWinners) {
            return VirtualFloorState.Claimable_Refunds_ResolvedNoWinners;
        } else if (_internalState == VirtualFloorInternalState.Claimable_Refunds_ResolvableNever) {
            return VirtualFloorState.Claimable_Refunds_ResolvableNever;
        } else /*if (_internalState == VirtualFloorInternalState.Claimable_Refunds_Flagged)*/ {
            assert(_internalState == VirtualFloorInternalState.Claimable_Refunds_Flagged); // Ensure all enum values have been handled.
            return VirtualFloorState.Claimable_Refunds_Flagged;
        }
    }

    /**
     * @dev Compare:
     * 1. (((tClose - t) * (betaOpen - 1)) / (tClose - tOpen)) * amount
     * 2. (((tClose - t) * (betaOpen - 1) * amount) / (tClose - tOpen))
     * (2) has less rounding error than (1), but then the *precise* effective beta used in the computation might not
     * have a uint256 representation.
     * Therefore some (miniscule) rounding precision is sacrificed to gain computation reproducibility.
     */
    function betaOf(VirtualFloor storage vf, uint256 t) internal view returns (UFixed256x18) {
        UFixed256x18 betaOpenMinusBetaClose = vf.betaOpenMinusBetaClose.toUFixed256x18();
        return _BETA_CLOSE.add(betaOpenMinusBetaClose.mul0(vf.tClose - t).div0(vf.tClose - vf.tOpen));
    }

    function totalCommitmentsToAllOutcomesPlusBonus(VirtualFloor storage vf) internal view returns (uint256 total) {
        total = vf.bonusAmount;
        for (uint256 i = 0; i < vf.nOutcomes; i++) {
            total += vf.outcomeTotals[i].amount;
        }
    }

    function minMaxCommitmentAmounts(VirtualFloor storage vf) internal view returns (uint256 min, uint256 max) {
        min = vf._optionalMinCommitmentAmount;
        max = vf._optionalMaxCommitmentAmount;
        if (min == 0) {
            min = _MIN_POSSIBLE_COMMITMENT_AMOUNT;
        }
        if (max == 0) {
            max = _MAX_POSSIBLE_COMMITMENT_AMOUNT;
        }
    }

    /**
     * @dev Equivalent to state == Active_Open_ResolvableLater || state == Active_Open_MaybeResolvableNever,
     * but ~300 gas cheaper.
     */
    function isOpen(VirtualFloor storage vf) internal view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return vf._internalState == VirtualFloorInternalState.Active && block.timestamp < vf.tClose;
    }

    function isClaimableRefunds(VirtualFloor storage vf) internal view returns (bool) {
        return vf._internalState == VirtualFloorInternalState.Claimable_Refunds_ResolvedNoWinners
            || vf._internalState == VirtualFloorInternalState.Claimable_Refunds_ResolvableNever
            || vf._internalState == VirtualFloorInternalState.Claimable_Refunds_Flagged;
    }

    function refundBonusAmount(VirtualFloor storage vf) internal {
        if (vf.bonusAmount > 0) {
            vf.paymentToken.safeTransfer(vf.creator, vf.bonusAmount);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;


/**
 * @title Reserved storage slots
 * @author 🎲🎲 <[email protected]>
 */
contract ExtraStorageGap {

    /**
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[200] private __gap;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

/**
 * @title Mechanism to call diamond-inheritance root initializer just once.
 * @author 🎲🎲 <[email protected]>
 */
contract MultipleInheritanceOptimization {

    bool private _rootInitialized;

    /**
     * @dev Should be diamond-root's last declared modifier.
     * Ensures that diamond-root initializer is run only once.
     */
    modifier multipleInheritanceRootInitializer() {
        if (!_rootInitialized) {
            _rootInitialized = true;
            _;
        }
    }

    /**
     * @dev Should be diamond-leaf's last declared modifier.
     * Clears up the storage variable once it has served its purpose.
     */
    modifier multipleInheritanceLeafInitializer() {
        _;
        _rootInitialized = false;
    }

    /**
     * @dev See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}