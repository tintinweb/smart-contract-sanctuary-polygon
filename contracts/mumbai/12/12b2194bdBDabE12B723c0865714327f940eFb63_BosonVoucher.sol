// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import "../../../domain/BosonConstants.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC721MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import { IERC2981Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { IBosonVoucher } from "../../../interfaces/clients/IBosonVoucher.sol";
import { BeaconClientBase } from "../../bases/BeaconClientBase.sol";
import { BeaconClientLib } from "../../libs/BeaconClientLib.sol";
import { IClientExternalAddresses } from "../../../interfaces/clients/IClientExternalAddresses.sol";
import { IBosonConfigHandler } from "../../../interfaces/handlers/IBosonConfigHandler.sol";

/**
 * @title BosonVoucher
 * @notice This is the Boson Protocol ERC-721 NFT Voucher contract.
 *
 * Key features:
 * - Only PROTOCOL-roled addresses can issue vouchers, i.e., the ProtocolDiamond or an EOA for testing
 * - Minted to the buyer when the buyer commits to an offer
 * - Burned when the buyer redeems the voucher NFT
 */
contract BosonVoucher is IBosonVoucher, BeaconClientBase, OwnableUpgradeable, ERC721Upgradeable {
    string private _contractURI;
    uint256 private _royaltyPercentage;

    /**
     * @notice Initializes the voucher.
     * This function is callable only once.
     */
    function initializeVoucher(
        uint256 _sellerId,
        address _newOwner,
        VoucherInitValues calldata voucherInitValues
    ) public initializer {
        string memory sellerId = Strings.toString(_sellerId);
        string memory voucherName = string(abi.encodePacked(VOUCHER_NAME, " ", sellerId));
        string memory voucherSymbol = string(abi.encodePacked(VOUCHER_SYMBOL, "_", sellerId));

        __ERC721_init_unchained(voucherName, voucherSymbol);

        // we don't call init on ownable, but rather just set the ownership to correct owner
        _transferOwnership(_newOwner);

        _setContractURI(voucherInitValues.contractURI);

        _setRoyaltyPercentage(voucherInitValues.royaltyPercentage);

        emit VoucherInitialized(_sellerId, _royaltyPercentage, _contractURI);
    }

    /**
     * @notice Issues a voucher to a buyer.
     *
     * Minted voucher supply is sent to the buyer.
     * Caller must have PROTOCOL role.
     *
     * @param _exchangeId - the id of the exchange (corresponds to the ERC-721 token id)
     * @param _buyer - the buyer address
     */
    function issueVoucher(uint256 _exchangeId, address _buyer) external override onlyRole(PROTOCOL) {
        // Mint the voucher, sending it to the buyer address
        _mint(_buyer, _exchangeId);
    }

    /**
     * @notice Burns a voucher.
     *
     * Caller must have PROTOCOL role.
     *
     * @param _exchangeId - the id of the exchange (corresponds to the ERC-721 token id)
     */
    function burnVoucher(uint256 _exchangeId) external override onlyRole(PROTOCOL) {
        _burn(_exchangeId);
    }

    /**
     * @notice Implements the {IERC165} interface.
     *
     * N.B. This method is inherited from several parents and
     * the compiler cannot decide which to use. Thus, they must
     * be overridden here.
     *
     * If you just call super.supportsInterface, it chooses
     * 'the most derived contract'. But that's not good for this
     * particular function because you may inherit from several
     * IERC165 contracts, and all concrete ones need to be allowed
     * to respond.
     *
     * 0x2a55205a represents ERC2981 interface id
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return (interfaceId == type(IBosonVoucher).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    /**
     * @notice Gets the Voucher metadata URI.
     *
     * This method overrides the Open Zeppelin version, returning
     * a unique stored metadata URI for each token rather than a
     * replaceable baseURI template, since the latter is not compatible
     * with IPFS hashes.
     *
     * @param _exchangeId - id of the voucher's associated exchange
     * @return the uri for the associated offer's off-chain metadata (blank if not found)
     */
    function tokenURI(uint256 _exchangeId)
        public
        view
        override(ERC721Upgradeable, IERC721MetadataUpgradeable)
        returns (string memory)
    {
        (bool exists, Offer memory offer) = getBosonOffer(_exchangeId);
        return exists ? offer.metadataUri : "";
    }

    /**
     * @notice Gets the seller id.
     *
     * @return the id for the Voucher seller
     */
    function getSellerId() public view override returns (uint256) {
        (bool exists, Seller memory seller) = getBosonSellerByAddress(owner());

        return exists ? seller.id : 0;
    }

    /**
     * @notice Updates buyer on transfer.
     *
     * When an issued voucher is subsequently transferred,
     * either on the secondary market or just between wallets,
     * the protocol needs to be alerted to the change of buyer
     * address.
     *
     * The buyer account associated with the exchange will be
     * replaced. If the new voucher holder already has a
     * Boson Protocol buyer account, it will be used. Otherwise,
     * a new buyer account will be created and associated with
     * the exchange.
     *
     * @param from - the address from which the voucher is being transferred
     * @param to - the address to which the voucher is being transferred
     * @param tokenId - the tokenId of the voucher that is being transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // Only act when transferring, not minting or burning
        if (from != address(0) && to != address(0) && from != to) {
            onVoucherTransferred(tokenId, payable(to));
        }
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the protocol. Change is done by calling `updateSeller` on the protocol.
     *
     * @param newOwner - the address to which ownership of the voucher contract will be transferred
     */
    function transferOwnership(address newOwner) public override(IBosonVoucher, OwnableUpgradeable) onlyRole(PROTOCOL) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @notice Returns storefront-level metadata used by OpenSea.
     *
     * @return Contract metadata URI
     */
    function contractURI() external view override returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Sets new contract URI.
     * Can only be called by the owner or during the initialization.
     *
     * @param _newContractURI - new contract metadata URI
     */
    function setContractURI(string calldata _newContractURI) external override onlyOwner {
        _setContractURI(_newContractURI);
    }

    /**
     * @notice Sets new contract URI.
     * Can only be called by the owner or during the initialization.
     *
     * @param _newContractURI new contract metadata URI
     */
    function _setContractURI(string calldata _newContractURI) internal {
        _contractURI = _newContractURI;

        emit ContractURIChanged(_newContractURI);
    }

    /**
     * @notice Provides royalty info.
     * Called with the sale price to determine how much royalty is owed and to whom.
     *
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     *
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for the given sale price
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // get offer
        (bool offerExists, Offer memory offer) = getBosonOffer(_tokenId);

        if (offerExists) {
            (, Seller memory seller) = getBosonSeller(offer.sellerId);
            // get receiver
            receiver = seller.treasury;
            // Calculate royalty amount
            royaltyAmount = (_salePrice * _royaltyPercentage) / 10000;
        }
    }

    /**
     * @notice Sets the royalty percentage.
     * Can only be called by the owner or during the initialization
     *
     * Emits RoyaltyPercentageChanged if successful.
     *
     * Reverts if:
     * - Caller is not the owner.
     * - `_newRoyaltyPercentage` is greater than max royalty percentage defined in the protocol
     *
     * @param _newRoyaltyPercentage fee in percentage. e.g. 500 = 5%
     */
    function setRoyaltyPercentage(uint256 _newRoyaltyPercentage) external override onlyOwner {
        _setRoyaltyPercentage(_newRoyaltyPercentage);
    }

    /**
     * @notice Gets the royalty percentage.
     *
     * @return _royaltyPercentage fee in percentage. e.g. 500 = 5%
     */
    function getRoyaltyPercentage() external view returns (uint256) {
        return _royaltyPercentage;
    }

    /**
     * @notice Sets royalty percentage.
     * Can only be called by the owner or during the initialization.
     *
     * Emits RoyaltyPercentageChanged if successful.
     *
     * @param _newRoyaltyPercentage - new royalty percentage
     */
    function _setRoyaltyPercentage(uint256 _newRoyaltyPercentage) internal {
        // get max royalty percentage from the protocol
        address protocolDiamond = IClientExternalAddresses(BeaconClientLib._beacon()).getProtocolAddress();
        uint16 maxRoyaltyPecentage = IBosonConfigHandler(protocolDiamond).getMaxRoyaltyPecentage();

        // make sure that new royalty percentage does not exceed the max value set in the protocol
        require(_newRoyaltyPercentage <= maxRoyaltyPecentage, "ERC2981: royalty fee exceeds protocol limit");

        _royaltyPercentage = _newRoyaltyPercentage;

        emit RoyaltyPercentageChanged(_newRoyaltyPercentage);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

// Access Control Roles
bytes32 constant ADMIN = keccak256("ADMIN"); // Role Admin
bytes32 constant PAUSER = keccak256("PAUSER"); // Role for pausing the protocol
bytes32 constant PROTOCOL = keccak256("PROTOCOL"); // Role for facets of the ProtocolDiamond
bytes32 constant CLIENT = keccak256("CLIENT"); // Role for clients of the ProtocolDiamond
bytes32 constant UPGRADER = keccak256("UPGRADER"); // Role for performing contract and config upgrades
bytes32 constant FEE_COLLECTOR = keccak256("FEE_COLLECTOR"); // Role for collecting fees from the protocol

// Revert Reasons: Pause related
string constant NO_REGIONS_SPECIFIED = "Must specify at least one region to pause";
string constant REGION_DUPLICATED = "A region may only be specified once";
string constant ALREADY_PAUSED = "Protocol is already paused";
string constant NOT_PAUSED = "Protocol is not currently paused";
string constant REGION_PAUSED = "This region of the protocol is currently paused";

// Revert Reasons: General
string constant INVALID_ADDRESS = "Invalid address";
string constant INVALID_STATE = "Invalid state";
string constant ARRAY_LENGTH_MISMATCH = "Array length mismatch";

// Reentrancy guard
string constant REENTRANCY_GUARD = "ReentrancyGuard: reentrant call";
uint256 constant NOT_ENTERED = 1;
uint256 constant ENTERED = 2;

// Revert Reasons: Facet initializer related
string constant ALREADY_INITIALIZED = "Already initialized";

// Revert Reasons: Access related
string constant ACCESS_DENIED = "Access denied, caller doesn't have role";
string constant NOT_OPERATOR = "Not seller's operator";
string constant NOT_ADMIN = "Not admin";
string constant NOT_OPERATOR_AND_CLERK = "Not operator and clerk";
string constant NOT_ADMIN_OPERATOR_AND_CLERK = "Not admin, operator and clerk";
string constant NOT_BUYER_OR_SELLER = "Not buyer or seller";
string constant NOT_VOUCHER_HOLDER = "Not current voucher holder";
string constant NOT_BUYER_WALLET = "Not buyer's wallet address";
string constant NOT_AGENT_WALLET = "Not agent's wallet address";
string constant NOT_DISPUTE_RESOLVER_OPERATOR = "Not dispute resolver's operator address";

// Revert Reasons: Account-related
string constant NO_SUCH_SELLER = "No such seller";
string constant MUST_BE_ACTIVE = "Account must be active";
string constant SELLER_ADDRESS_MUST_BE_UNIQUE = "Seller address cannot be assigned to another seller Id";
string constant BUYER_ADDRESS_MUST_BE_UNIQUE = "Buyer address cannot be assigned to another buyer Id";
string constant DISPUTE_RESOLVER_ADDRESS_MUST_BE_UNIQUE = "Dispute resolver address cannot be assigned to another dispute resolver Id";
string constant AGENT_ADDRESS_MUST_BE_UNIQUE = "Agent address cannot be assigned to another agent Id";
string constant NO_SUCH_BUYER = "No such buyer";
string constant NO_SUCH_AGENT = "No such agent";
string constant WALLET_OWNS_VOUCHERS = "Wallet address owns vouchers";
string constant NO_SUCH_DISPUTE_RESOLVER = "No such dispute resolver";
string constant INVALID_ESCALATION_PERIOD = "Invalid escalation period";
string constant INVALID_AMOUNT_DISPUTE_RESOLVER_FEES = "Dispute resolver fees are not present or exceed maximum dispute resolver fees in a single transaction";
string constant DUPLICATE_DISPUTE_RESOLVER_FEES = "Duplicate dispute resolver fee";
string constant DISPUTE_RESOLVER_FEE_NOT_FOUND = "Dispute resolver fee not found";
string constant SELLER_ALREADY_APPROVED = "Seller id is approved already";
string constant SELLER_NOT_APPROVED = "Seller id is not approved";
string constant INVALID_AMOUNT_ALLOWED_SELLERS = "Allowed sellers are not present or exceed maximum allowed sellers in a single transaction";
string constant INVALID_AUTH_TOKEN_TYPE = "Invalid AuthTokenType";
string constant ADMIN_OR_AUTH_TOKEN = "An admin address or an auth token is required";
string constant AUTH_TOKEN_MUST_BE_UNIQUE = "Auth token cannot be assigned to another entity of the same type";
string constant INVALID_AGENT_FEE_PERCENTAGE = "Sum of agent fee percentage and protocol fee percentage should be <= max fee percentage limit";

// Revert Reasons: Offer related
string constant NO_SUCH_OFFER = "No such offer";
string constant OFFER_PERIOD_INVALID = "Offer period invalid";
string constant OFFER_PENALTY_INVALID = "Offer penalty invalid";
string constant OFFER_MUST_BE_ACTIVE = "Offer must be active";
string constant OFFER_MUST_BE_UNIQUE = "Offer must be unique to a group";
string constant OFFER_HAS_BEEN_VOIDED = "Offer has been voided";
string constant OFFER_HAS_EXPIRED = "Offer has expired";
string constant OFFER_NOT_AVAILABLE = "Offer is not yet available";
string constant OFFER_SOLD_OUT = "Offer has sold out";
string constant CANNOT_COMMIT = "Caller cannot commit";
string constant EXCHANGE_FOR_OFFER_EXISTS = "Exchange for offer exists";
string constant AMBIGUOUS_VOUCHER_EXPIRY = "Exactly one of voucherRedeemableUntil and voucherValid must be non zero";
string constant REDEMPTION_PERIOD_INVALID = "Redemption period invalid";
string constant INVALID_DISPUTE_PERIOD = "Invalid dispute period";
string constant INVALID_RESOLUTION_PERIOD = "Invalid resolution period";
string constant INVALID_DISPUTE_RESOLVER = "Invalid dispute resolver";
string constant INVALID_QUANTITY_AVAILABLE = "Invalid quantity available";
string constant DR_UNSUPPORTED_FEE = "Dispute resolver does not accept this token";
string constant AGENT_FEE_AMOUNT_TOO_HIGH = "Sum of agent fee amount and protocol fee amount should be <= offer fee limit";

// Revert Reasons: Group related
string constant NO_SUCH_GROUP = "No such group";
string constant OFFER_NOT_IN_GROUP = "Offer not part of the group";
string constant TOO_MANY_OFFERS = "Exceeded maximum offers in a single transaction";
string constant NOTHING_UPDATED = "Nothing updated";
string constant INVALID_CONDITION_PARAMETERS = "Invalid condition parameters";

// Revert Reasons: Exchange related
string constant NO_SUCH_EXCHANGE = "No such exchange";
string constant DISPUTE_PERIOD_NOT_ELAPSED = "Dispute period has not yet elapsed";
string constant VOUCHER_NOT_REDEEMABLE = "Voucher not yet valid or already expired";
string constant VOUCHER_EXTENSION_NOT_VALID = "Proposed date is not later than the current one";
string constant VOUCHER_STILL_VALID = "Voucher still valid";
string constant VOUCHER_HAS_EXPIRED = "Voucher has expired";
string constant TOO_MANY_EXCHANGES = "Exceeded maximum exchanges in a single transaction";
string constant EXCHANGE_IS_NOT_IN_A_FINAL_STATE = "Exchange is not in a final state";

// Revert Reasons: Twin related
string constant NO_SUCH_TWIN = "No such twin";
string constant NO_TRANSFER_APPROVED = "No transfer approved";
string constant TWIN_TRANSFER_FAILED = "Twin could not be transferred";
string constant UNSUPPORTED_TOKEN = "Unsupported token";
string constant BUNDLE_FOR_TWIN_EXISTS = "Bundle for twin exists";
string constant INVALID_SUPPLY_AVAILABLE = "supplyAvailable can't be zero";
string constant INVALID_AMOUNT = "Invalid twin amount";
string constant INVALID_TWIN_PROPERTY = "Invalid property for selected token type";
string constant INVALID_TWIN_TOKEN_RANGE = "Token range is already being used in another twin";
string constant INVALID_TOKEN_ADDRESS = "Token address is a contract that doesn't implement the interface for selected token type";

// Revert Reasons: Bundle related
string constant NO_SUCH_BUNDLE = "No such bundle";
string constant TWIN_NOT_IN_BUNDLE = "Twin not part of the bundle";
string constant OFFER_NOT_IN_BUNDLE = "Offer not part of the bundle";
string constant TOO_MANY_TWINS = "Exceeded maximum twins in a single transaction";
string constant BUNDLE_OFFER_MUST_BE_UNIQUE = "Offer must be unique to a bundle";
string constant BUNDLE_TWIN_MUST_BE_UNIQUE = "Twin must be unique to a bundle";
string constant EXCHANGE_FOR_BUNDLED_OFFERS_EXISTS = "Exchange for the bundled offers exists";
string constant INSUFFICIENT_TWIN_SUPPLY_TO_COVER_BUNDLE_OFFERS = "Insufficient twin supplyAvailable to cover total quantity of bundle offers";
string constant BUNDLE_REQUIRES_AT_LEAST_ONE_TWIN_AND_ONE_OFFER = "Bundle must have at least one twin and one offer";

// Revert Reasons: Funds related
string constant NATIVE_WRONG_ADDRESS = "Native token address must be 0";
string constant NATIVE_WRONG_AMOUNT = "Transferred value must match amount";
string constant TOKEN_NAME_UNSPECIFIED = "Token name unspecified";
string constant NATIVE_CURRENCY = "Native currency";
string constant TOO_MANY_TOKENS = "Too many tokens";
string constant TOKEN_AMOUNT_MISMATCH = "Number of amounts should match number of tokens";
string constant NOTHING_TO_WITHDRAW = "Nothing to withdraw";
string constant NOT_AUTHORIZED = "Not authorized to withdraw";
string constant TOKEN_TRANSFER_FAILED = "Token transfer failed";
string constant INSUFFICIENT_VALUE_RECEIVED = "Insufficient value received";
string constant INSUFFICIENT_AVAILABLE_FUNDS = "Insufficient available funds";
string constant NATIVE_NOT_ALLOWED = "Transfer of native currency not allowed";

// Revert Reasons: Meta-Transactions related
string constant NONCE_USED_ALREADY = "Nonce used already";
string constant FUNCTION_CALL_NOT_SUCCESSFUL = "Function call not successful";
string constant INVALID_FUNCTION_SIGNATURE = "functionSignature can not be of executeMetaTransaction method";
string constant SIGNER_AND_SIGNATURE_DO_NOT_MATCH = "Signer and signature do not match";
string constant INVALID_FUNCTION_NAME = "Invalid function name";
string constant INVALID_SIGNATURE = "Invalid signature";

// Revert Reasons: Dispute related
string constant DISPUTE_PERIOD_HAS_ELAPSED = "Dispute period has already elapsed";
string constant DISPUTE_HAS_EXPIRED = "Dispute has expired";
string constant INVALID_BUYER_PERCENT = "Invalid buyer percent";
string constant DISPUTE_STILL_VALID = "Dispute still valid";
string constant INVALID_DISPUTE_TIMEOUT = "Invalid dispute timeout";
string constant TOO_MANY_DISPUTES = "Exceeded maximum disputes in a single transaction";
string constant ESCALATION_NOT_ALLOWED = "Disputes without dispute resolver cannot be escalated";

// Revert Reasons: Config related
string constant FEE_PERCENTAGE_INVALID = "Percentage representation must be less than 10000";
string constant VALUE_ZERO_NOT_ALLOWED = "Value must be greater than 0";

// EIP712Lib
string constant PROTOCOL_NAME = "Boson Protocol";
string constant PROTOCOL_VERSION = "V2";
bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
    bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)")
);

// BosonVoucher
string constant VOUCHER_NAME = "Boson Voucher";
string constant VOUCHER_SYMBOL = "BOSON_VOUCHER";

// Meta Transactions - Structs
bytes32 constant META_TRANSACTION_TYPEHASH = keccak256(
    bytes(
        "MetaTransaction(uint256 nonce,address from,address contractAddress,string functionName,bytes functionSignature)"
    )
);
bytes32 constant OFFER_DETAILS_TYPEHASH = keccak256("MetaTxOfferDetails(address buyer,uint256 offerId)");
bytes32 constant META_TX_COMMIT_TO_OFFER_TYPEHASH = keccak256(
    "MetaTxCommitToOffer(uint256 nonce,address from,address contractAddress,string functionName,MetaTxOfferDetails offerDetails)MetaTxOfferDetails(address buyer,uint256 offerId)"
);
bytes32 constant EXCHANGE_DETAILS_TYPEHASH = keccak256("MetaTxExchangeDetails(uint256 exchangeId)");
bytes32 constant META_TX_EXCHANGE_TYPEHASH = keccak256(
    "MetaTxExchange(uint256 nonce,address from,address contractAddress,string functionName,MetaTxExchangeDetails exchangeDetails)MetaTxExchangeDetails(uint256 exchangeId)"
);
bytes32 constant FUND_DETAILS_TYPEHASH = keccak256(
    "MetaTxFundDetails(uint256 entityId,address[] tokenList,uint256[] tokenAmounts)"
);
bytes32 constant META_TX_FUNDS_TYPEHASH = keccak256(
    "MetaTxFund(uint256 nonce,address from,address contractAddress,string functionName,MetaTxFundDetails fundDetails)MetaTxFundDetails(uint256 entityId,address[] tokenList,uint256[] tokenAmounts)"
);
bytes32 constant DISPUTE_RESOLUTION_DETAILS_TYPEHASH = keccak256(
    "MetaTxDisputeResolutionDetails(uint256 exchangeId,uint256 buyerPercentBasisPoints,bytes32 sigR,bytes32 sigS,uint8 sigV)"
);
bytes32 constant META_TX_DISPUTE_RESOLUTIONS_TYPEHASH = keccak256(
    "MetaTxDisputeResolution(uint256 nonce,address from,address contractAddress,string functionName,MetaTxDisputeResolutionDetails disputeResolutionDetails)MetaTxDisputeResolutionDetails(uint256 exchangeId,uint256 buyerPercentBasisPoints,bytes32 sigR,bytes32 sigS,uint8 sigV)"
);

// Function names
string constant COMMIT_TO_OFFER = "commitToOffer(address,uint256)";
string constant CANCEL_VOUCHER = "cancelVoucher(uint256)";
string constant REDEEM_VOUCHER = "redeemVoucher(uint256)";
string constant COMPLETE_EXCHANGE = "completeExchange(uint256)";
string constant WITHDRAW_FUNDS = "withdrawFunds(uint256,address[],uint256[])";
string constant RETRACT_DISPUTE = "retractDispute(uint256)";
string constant RAISE_DISPUTE = "raiseDispute(uint256)";
string constant ESCALATE_DISPUTE = "escalateDispute(uint256)";
string constant RESOLVE_DISPUTE = "resolveDispute(uint256,uint256,bytes32,bytes32,uint8)";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { IERC721MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title IBosonVoucher
 *
 * @notice This is the interface for the Boson Protocol ERC-721 Voucher NFT contract.
 *
 * The ERC-165 identifier for this interface is: 0x2249ca21
 */
interface IBosonVoucher is IERC721Upgradeable, IERC721MetadataUpgradeable {
    event ContractURIChanged(string contractURI);
    event RoyaltyPercentageChanged(uint256 royaltyPercentage);
    event VoucherInitialized(uint256 indexed sellerId, uint256 indexed royaltyPercentage, string indexed contractURI);

    /**
     * @notice Issues a voucher to a buyer.
     *
     * Minted voucher supply is sent to the buyer.
     * Caller must have PROTOCOL role.
     *
     * @param _exchangeId - the id of the exchange (corresponds to the ERC-721 token id)
     * @param _buyer - the buyer address
     */
    function issueVoucher(uint256 _exchangeId, address _buyer) external;

    /**
     * @notice Burns a voucher.
     *
     * Caller must have PROTOCOL role.
     *
     * @param _exchangeId - the id of the exchange (corresponds to the ERC-721 token id)
     */
    function burnVoucher(uint256 _exchangeId) external;

    /**
     * @notice Gets the seller id.
     *
     * @return the id for the Voucher seller
     */
    function getSellerId() external view returns (uint256);

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the protocol. Change is done by calling `updateSeller` on the protocol.
     *
     * @param newOwner - the address to which ownership of the voucher contract will be transferred
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Returns storefront-level metadata used by OpenSea.
     *
     * @return Contract metadata URI
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Sets new contract URI.
     * Can only be called by the owner or during the initialization.
     *
     * @param _newContractURI - new contract metadata URI
     */
    function setContractURI(string calldata _newContractURI) external;

    /**
     * @notice Provides royalty info.
     * Called with the sale price to determine how much royalty is owed and to whom.
     *
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     *
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for the given sale price
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    /**
     * @notice Sets the royalty percentage.
     * Can only be called by the owner or during the initialization
     *
     * Emits RoyaltyPercentageChanged if successful.
     *
     * Reverts if:
     * - Caller is not the owner.
     * - `_newRoyaltyPercentage` is greater than max royalty percentage defined in the protocol
     *
     * @param _newRoyaltyPercentage fee in percentage. e.g. 500 = 5%
     */
    function setRoyaltyPercentage(uint256 _newRoyaltyPercentage) external;

    /**
     * @notice Gets the royalty percentage.
     *
     * @return royalty percentage
     */
    function getRoyaltyPercentage() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "../../domain/BosonConstants.sol";
import { IBosonOfferHandler } from "../../interfaces/handlers/IBosonOfferHandler.sol";
import { IBosonExchangeHandler } from "../../interfaces/handlers/IBosonExchangeHandler.sol";
import { IBosonAccountHandler } from "../../interfaces/handlers/IBosonAccountHandler.sol";
import { BosonTypes } from "../../domain/BosonTypes.sol";
import { BeaconClientLib } from "../libs/BeaconClientLib.sol";
import { IClientExternalAddresses } from "../../interfaces/clients/IClientExternalAddresses.sol";

/**
 * @title BeaconClientBase
 *
 * @notice Extended by Boson Protocol contracts that need to communicate with the ProtocolDiamond
 * but are NOT facets of the ProtocolDiamond. This is used where it's expected that multiple clients
 * will use the same implementation. If it's expected that only one client will use it, it's recommended to use `ClientBase` instead
 *
 * Boson client contracts include BosonVoucher
 */
abstract contract BeaconClientBase is BosonTypes {
    /**
     * @dev Modifier that checks that the caller has a specific role.
     *
     * Reverts if:
     * - Caller doesn't have role
     *
     * See: {AccessController.hasRole}
     *
     * @param role - the role to check
     */
    modifier onlyRole(bytes32 role) {
        require(BeaconClientLib.hasRole(role), ACCESS_DENIED);
        _;
    }

    /**
     * @notice Gets the info about the offer associated with a voucher's exchange
     *
     * @param _exchangeId - the id of the exchange
     * @return exists - the offer was found
     * @return offer - the offer associated with the _exchangeId
     */
    function getBosonOffer(uint256 _exchangeId) internal view returns (bool exists, Offer memory offer) {
        address protocolDiamond = IClientExternalAddresses(BeaconClientLib._beacon()).getProtocolAddress();

        (, Exchange memory exchange, ) = IBosonExchangeHandler(protocolDiamond).getExchange(_exchangeId);
        (exists, offer, , , , ) = IBosonOfferHandler(protocolDiamond).getOffer(exchange.offerId);
    }

    /**
     * @notice Informs protocol of new buyer associated with an exchange
     *
     * @param _exchangeId - the id of the exchange
     * @param _newBuyer - the address of the new buyer
     */
    function onVoucherTransferred(uint256 _exchangeId, address payable _newBuyer) internal {
        address protocolDiamond = IClientExternalAddresses(BeaconClientLib._beacon()).getProtocolAddress();
        IBosonExchangeHandler(protocolDiamond).onVoucherTransferred(_exchangeId, _newBuyer);
    }

    /**
     * @notice Gets the info about the seller associated with the sellerId.
     *
     * @param _sellerId - the id of the seller
     * @return exists - the seller was found
     * @return seller - the seller associated with the _sellerId
     */
    function getBosonSeller(uint256 _sellerId) internal view returns (bool exists, Seller memory seller) {
        address protocolDiamond = IClientExternalAddresses(BeaconClientLib._beacon()).getProtocolAddress();

        (exists, seller, ) = IBosonAccountHandler(protocolDiamond).getSeller(_sellerId);
    }

    /**
     * @notice Gets the info about the seller associated with the address.
     *
     * @param _sellerAddress - the address of the seller
     * @return exists - the seller was found
     * @return seller - the seller associated with the _sellerAddress
     */
    function getBosonSellerByAddress(address _sellerAddress) internal view returns (bool exists, Seller memory seller) {
        address protocolDiamond = IClientExternalAddresses(BeaconClientLib._beacon()).getProtocolAddress();

        (exists, seller, ) = IBosonAccountHandler(protocolDiamond).getSellerByAddress(_sellerAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { IAccessControl } from "../../interfaces/IAccessControl.sol";
import { IClientExternalAddresses } from "../../interfaces/clients/IClientExternalAddresses.sol";

/**
 * @title BeaconClientLib
 *
 * @notice
 * - Defines BeaconSlot position
 * - Provides BeaconSlot accessor
 * - Defines hasRole function
 */
library BeaconClientLib {
    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    struct BeaconSlot {
        address value;
        bool initialized;
    }

    /**
     * @notice Returns a `BeaconSlot` with member `value`.
     *
     * @return r - the BeaconSlot storage slot cast to BeaconSlot
     */
    function getBeaconSlot() internal pure returns (BeaconSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := _BEACON_SLOT
        }
    }

    /**
     * @notice Returns the address of the Beacon
     *
     * @return the Beacon address
     */
    function _beacon() internal view returns (address) {
        return getBeaconSlot().value;
    }

    /**
     * @notice Checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     *
     * @param role - the role to check
     * @return  whether caller has role
     */
    function hasRole(bytes32 role) internal view returns (bool) {
        // retrieve accessController from Beacon
        IAccessControl accessController = IClientExternalAddresses(_beacon()).getAccessController();

        // forward the check to accessController
        return accessController.hasRole(role, msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IAccessControl } from "../IAccessControl.sol";
import { IClientExternalAddressesEvents } from "../events/IClientExternalAddressesEvents.sol";

/**
 * @title IClientExternalAddresses
 *
 * @notice ClientExternalAddresses is used to set and get addresses used either by proxies or
 * by protocol clients.
 *
 *
 * The ERC-165 identifier for this interface is: 0x344552b3
 */
interface IClientExternalAddresses is IClientExternalAddressesEvents {
    /**
     * @notice Sets the implementation address.
     *
     * @param _implementation - the implementation address
     */
    function setImplementation(address _implementation) external;

    /**
     * @notice Gets the implementation address.
     *
     * @return the implementation address
     */
    function getImplementation() external view returns (address);

    /**
     * @notice Gets the address of the Boson Protocol AccessController contract.
     *
     * @return the address of the AccessController contract
     */
    function getAccessController() external view returns (IAccessControl);

    /**
     * @notice Set the ProtocolDiamond address.
     *
     * Emits a ProtocolAddressChanged event.
     *
     * @param _protocolAddress - the ProtocolDiamond address
     */
    function setProtocolAddress(address _protocolAddress) external;

    /**
     * @notice Gets the address of the ProtocolDiamond contract.
     *
     * @return the ProtocolDiamond address
     */
    function getProtocolAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";
import { IBosonConfigEvents } from "../events/IBosonConfigEvents.sol";

/**
 * @title IBosonConfigHandler
 *
 * @notice Handles management of configuration within the protocol.
 *
 * The ERC-165 identifier for this interface is: 0x2ad335b8
 */
interface IBosonConfigHandler is IBosonConfigEvents {
    /**
     * @notice Sets the Boson Token (ERC-20 contract) address.
     *
     * Emits a TokenAddressChanged event.
     *
     * Reverts if _tokenAddress is the zero address
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _tokenAddress - the Boson Token (ERC-20 contract) address
     */
    function setTokenAddress(address payable _tokenAddress) external;

    /**
     * @notice Gets the Boson Token (ERC-20 contract) address.
     *
     * @return the Boson Token (ERC-20 contract) address
     */
    function getTokenAddress() external view returns (address payable);

    /**
     * @notice Sets the Boson Protocol multi-sig wallet address.
     *
     * Emits a TreasuryAddressChanged event.
     *
     * Reverts if _treasuryAddress is the zero address
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _treasuryAddress - the the multi-sig wallet address
     */
    function setTreasuryAddress(address payable _treasuryAddress) external;

    /**
     * @notice Gets the Boson Protocol multi-sig wallet address.
     *
     * @return the Boson Protocol multi-sig wallet address
     */
    function getTreasuryAddress() external view returns (address payable);

    /**
     * @notice Sets the Boson Voucher beacon contract address.
     *
     * Emits a VoucherBeaconAddressChanged event.
     *
     * Reverts if _voucherBeaconAddress is the zero address
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _voucherBeaconAddress - the Boson Voucher beacon contract address
     */
    function setVoucherBeaconAddress(address _voucherBeaconAddress) external;

    /**
     * @notice Gets the Boson Voucher beacon contract address.
     *
     * @return the Boson Voucher beacon contract address
     */
    function getVoucherBeaconAddress() external view returns (address);

    /**
     * @notice Sets the Boson Voucher reference proxy implementation address.
     *
     * Emits a BeaconProxyAddressChanged event.
     *
     * Reverts if _beaconProxyAddress is the zero address
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _beaconProxyAddress - reference proxy implementation address
     */
    function setBeaconProxyAddress(address _beaconProxyAddress) external;

    /**
     * @notice Gets the beaconProxy address.
     *
     * @return the beaconProxy address
     */
    function getBeaconProxyAddress() external view returns (address);

    /**
     * @notice Sets the protocol fee percentage.
     *
     * Emits a ProtocolFeePercentageChanged event.
     *
     * Reverts if the _protocolFeePercentage is greater than 10000.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _protocolFeePercentage - the percentage that will be taken as a fee from the net of a Boson Protocol sale or auction (after royalties)
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setProtocolFeePercentage(uint256 _protocolFeePercentage) external;

    /**
     * @notice Gets the protocol fee percentage.
     *
     * @return the protocol fee percentage
     */
    function getProtocolFeePercentage() external view returns (uint256);

    /**
     * @notice Sets the flat protocol fee for exchanges in $BOSON.
     *
     * Emits a ProtocolFeeFlatBosonChanged event.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _protocolFeeFlatBoson - the flat fee taken for exchanges in $BOSON
     *
     */
    function setProtocolFeeFlatBoson(uint256 _protocolFeeFlatBoson) external;

    /**
     * @notice Gets the flat protocol fee for exchanges in $BOSON.
     *
     * @return the flat fee taken for exchanges in $BOSON
     */
    function getProtocolFeeFlatBoson() external view returns (uint256);

    /**
     * @notice Sets the maximum numbers of offers that can be created in a single transaction.
     *
     * Emits a MaxOffersPerBatchChanged event.
     *
     * Reverts if _maxOffersPerBatch is zero.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxOffersPerBatch - the maximum length of {BosonTypes.Offer[]}
     */
    function setMaxOffersPerBatch(uint16 _maxOffersPerBatch) external;

    /**
     * @notice Gets the maximum numbers of offers that can be created in a single transaction.
     *
     * @return the maximum numbers of offers that can be created in a single transaction
     */
    function getMaxOffersPerBatch() external view returns (uint16);

    /**
     * @notice Sets the maximum numbers of offers that can be added to a group in a single transaction.
     *
     * Emits a MaxOffersPerGroupChanged event.
     *
     * Reverts if _maxOffersPerGroup is zero.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxOffersPerGroup - the maximum length of {BosonTypes.Group.offerIds}
     */
    function setMaxOffersPerGroup(uint16 _maxOffersPerGroup) external;

    /**
     * @notice Gets the maximum numbers of offers that can be added to a group in a single transaction.
     *
     * @return the maximum numbers of offers that can be added to a group in a single transaction
     */
    function getMaxOffersPerGroup() external view returns (uint16);

    /**
     * @notice Sets the maximum numbers of twins that can be added to a bundle in a single transaction.
     *
     * Emits a MaxTwinsPerBundleChanged event.
     *
     * Reverts if _maxTwinsPerBundle is zero.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxTwinsPerBundle - the maximum length of {BosonTypes.Bundle.twinIds}
     */
    function setMaxTwinsPerBundle(uint16 _maxTwinsPerBundle) external;

    /**
     * @notice Gets the maximum numbers of twins that can be added to a bundle in a single transaction.
     *
     * @return the maximum numbers of twins that can be added to a bundle in a single transaction.
     */
    function getMaxTwinsPerBundle() external view returns (uint16);

    /**
     * @notice Sets the maximum numbers of offers that can be added to a bundle in a single transaction.
     *
     * Emits a MaxOffersPerBundleChanged event.
     *
     * Reverts if _maxOffersPerBundle is zero.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxOffersPerBundle - the maximum length of {BosonTypes.Bundle.offerIds}
     */
    function setMaxOffersPerBundle(uint16 _maxOffersPerBundle) external;

    /**
     * @notice Gets the maximum numbers of offers that can be added to a bundle in a single transaction.
     *
     * @return the maximum numbers of offers that can be added to a bundle in a single transaction
     */
    function getMaxOffersPerBundle() external view returns (uint16);

    /**
     * @notice Sets the maximum numbers of tokens that can be withdrawn in a single transaction.
     *
     * Emits a MaxTokensPerWithdrawalChanged event.
     *
     * Reverts if _maxTokensPerWithdrawal is zero.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxTokensPerWithdrawal - the maximum length of token list when calling {FundsHandlerFacet.withdraw}
     */
    function setMaxTokensPerWithdrawal(uint16 _maxTokensPerWithdrawal) external;

    /**
     * @notice Gets the maximum numbers of tokens that can be withdrawn in a single transaction.
     *
     * @return the maximum length of token list when calling {FundsHandlerFacet.withdraw}
     */
    function getMaxTokensPerWithdrawal() external view returns (uint16);

    /**
     * @notice Sets the maximum number of dispute resolver fee structs that can be processed in a single transaction.
     *
     * Emits a MaxFeesPerDisputeResolverChanged event.
     *
     * Reverts if _maxFeesPerDisputeResolver is zero.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxFeesPerDisputeResolver - the maximum length of dispute resolver fees list when calling {AccountHandlerFacet.createDisputeResolver} or {AccountHandlerFacet.updateDisputeResolver}
     */
    function setMaxFeesPerDisputeResolver(uint16 _maxFeesPerDisputeResolver) external;

    /**
     * @notice Gets the maximum number of dispute resolver fee structs that can be processed in a single transaction.
     *
     * @return the maximum number of dispute resolver fee structs that can be processed in a single transaction
     */
    function getMaxFeesPerDisputeResolver() external view returns (uint16);

    /**
     * @notice Sets the maximum escalation response period a dispute resolver can specify.
     *
     * Emits a MaxEscalationResponsePeriodChanged event.
     *
     * Reverts if _maxEscalationResponsePeriod is zero.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxEscalationResponsePeriod - the maximum escalation response period that a {BosonTypes.DisputeResolver} can specify
     */
    function setMaxEscalationResponsePeriod(uint256 _maxEscalationResponsePeriod) external;

    /**
     * @notice Gets the maximum escalation response period a dispute resolver can specify.
     *
     * @return the maximum escalation response period that a {BosonTypes.DisputeResolver} can specify
     */
    function getMaxEscalationResponsePeriod() external view returns (uint256);

    /**
     * @notice Sets the maximum number of disputes that can be expired in a single transaction.
     *
     * Emits a MaxDisputesPerBatchChanged event.
     *
     * Reverts if _maxDisputesPerBatch is zero.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxDisputesPerBatch - the maximum number of disputes that can be expired
     */
    function setMaxDisputesPerBatch(uint16 _maxDisputesPerBatch) external;

    /**
     * @notice Gets the maximum number of disputes that can be expired in a single transaction.
     *
     * @return the maximum number of disputes that can be expired
     */
    function getMaxDisputesPerBatch() external view returns (uint16);

    /**
     * @notice Sets the total offer fee percentage limit which will validate the sum of (Protocol Fee percentage + Agent Fee percentage) of an offer fee.
     *
     * Emits a MaxTotalOfferFeePercentageChanged event.
     *
     * Reverts if the _maxTotalOfferFeePercentage is greater than 10000.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxTotalOfferFeePercentage - the maximum total offer fee percentage
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setMaxTotalOfferFeePercentage(uint16 _maxTotalOfferFeePercentage) external;

    /**
     * @notice Gets the total offer fee percentage limit which will validate the sum of (Protocol Fee percentage + Agent Fee percentage) of an offer fee.
     *
     * @return the maximum total offer fee percentage
     */
    function getMaxTotalOfferFeePercentage() external view returns (uint16);

    /**
     * @notice Sets the maximum number of seller ids that can be added to or removed from dispute resolver seller allow list in a single transaction.
     *
     * Emits a MaxAllowedSellersChanged event.
     *
     * Reverts if _maxAllowedSellers is zero.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxAllowedSellers - the maximum number of seller ids that can be added or removed
     */
    function setMaxAllowedSellers(uint16 _maxAllowedSellers) external;

    /**
     * @notice Gets the maximum number of seller ids that can be added to or removed from dispute resolver seller allow list in a single transaction.
     *
     * @return the maximum number of seller ids that can be added or removed
     */
    function getMaxAllowedSellers() external view returns (uint16);

    /**
     * @notice Sets the buyer escalation fee percentage.
     *
     * Emits a BuyerEscalationFeePercentageChanged event.
     *
     * Reverts if the _buyerEscalationDepositPercentage is greater than 10000.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _buyerEscalationDepositPercentage - the percentage of the DR fee that will be charged to buyer if they want to escalate the dispute
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setBuyerEscalationDepositPercentage(uint256 _buyerEscalationDepositPercentage) external;

    /**
     * @notice Gets the buyer escalation fee percentage.
     *
     * @return the percentage of the DR fee that will be charged to buyer if they want to escalate the dispute
     */
    function getBuyerEscalationDepositPercentage() external view returns (uint256);

    /**
     * @notice Sets the contract address for the given AuthTokenType.
     *
     * Emits an AuthTokenContractChanged event.
     *
     * Reverts if _authTokenType is None
     * Reverts if _authTokenType is Custom
     * Reverts if _authTokenContract is the zero address
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _authTokenType - the auth token type, as an Enum value
     * @param _authTokenContract the address of the auth token contract (e.g. Lens or ENS contract address)
     */
    function setAuthTokenContract(BosonTypes.AuthTokenType _authTokenType, address _authTokenContract) external;

    /**
     * @notice Gets the contract address for the given AuthTokenType.
     *
     * @param _authTokenType - the auth token type, as an Enum value
     * @return the address of the auth token contract (e.g. Lens or ENS contract address) for the given AuthTokenType
     */
    function getAuthTokenContract(BosonTypes.AuthTokenType _authTokenType) external view returns (address);

    /**
     * @notice Sets the maximum number of exchanges that can be created in a single transaction.
     *
     * Emits a MaxExchangesPerBatchChanged event.
     *
     * Reverts if _maxExchangesPerBatch is zero.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxExchangesPerBatch - the maximum length of {BosonTypes.Exchange[]}
     */
    function setMaxExchangesPerBatch(uint16 _maxExchangesPerBatch) external;

    /**
     * @notice Gets the maximum number of exchanges that can be created in a single transaction.
     *
     * @return the maximum length of {BosonTypes.Exchange[]}
     */
    function getMaxExchangesPerBatch() external view returns (uint16);

    /**
     * @notice Sets the maximum royalty percentage that can be set by the seller.
     *
     * Emits a MaxRoyaltyPercentageChanged event.
     *
     * Reverts if:
     * - The _maxRoyaltyPercentage is zero.
     * - The _maxRoyaltyPecentage is greater than 10000.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxRoyaltyPecentage - the maximum royalty percentage
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setMaxRoyaltyPecentage(uint16 _maxRoyaltyPecentage) external;

    /**
     * @notice Gets the maximum royalty percentage that can be set by the seller.
     *
     * @return the maximum royalty percentage
     */
    function getMaxRoyaltyPecentage() external view returns (uint16);

    /**
     * @notice Sets the maximum resolution period a seller can specify.
     *
     * Emits a MaxResolutionPeriodChanged event.
     *
     * Reverts if _maxResolutionPeriod is zero.
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _maxResolutionPeriod - the maximum resolution period that a {BosonTypes.Seller} can specify
     */
    function setMaxResolutionPeriod(uint256 _maxResolutionPeriod) external;

    /**
     * @notice Gets the maximum resolution period a seller can specify.
     *
     * @return the maximum resolution period that a {BosonTypes.Seller} can specify
     */
    function getMaxResolutionPeriod() external view returns (uint256);

    /**
     * @notice Sets the minimum dispute period a seller can specify.
     *
     * Emits a MinDisputePeriodChanged event.
     *
     * Reverts if _minDisputePeriod is zero.
     *
     * @param _minDisputePeriod - the minimum dispute period that a {BosonTypes.Seller} can specify
     */
    function setMinDisputePeriod(uint256 _minDisputePeriod) external;

    /**
     * @notice Gets the minimum dispute period a seller can specify.
     */
    function getMinDisputePeriod() external view returns (uint256);

    /**
     * @notice Sets the access controller address.
     *
     * Emits an AccessControllerAddressChanged event.
     *
     * Reverts if _accessControllerAddress is the zero address
     *
     * @dev Caller must have ADMIN role.
     *
     * @param _accessControllerAddress - access controller address
     */
    function setAccessControllerAddress(address _accessControllerAddress) external;

    /**
     * @notice Gets the access controller address.
     *
     * @return the access controller address
     */
    function getAccessControllerAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

/**
 * @title BosonTypes
 *
 * @notice Enums and structs used by the Boson Protocol contract ecosystem.
 */

contract BosonTypes {
    enum PausableRegion {
        Offers,
        Twins,
        Bundles,
        Groups,
        Sellers,
        Buyers,
        DisputeResolvers,
        Agents,
        Exchanges,
        Disputes,
        Funds,
        Orchestration,
        MetaTransaction
    }

    enum EvaluationMethod {
        None, // None should always be at index 0. Never change this value.
        Threshold,
        SpecificToken
    }

    enum ExchangeState {
        Committed,
        Revoked,
        Canceled,
        Redeemed,
        Completed,
        Disputed
    }

    enum DisputeState {
        Resolving,
        Retracted,
        Resolved,
        Escalated,
        Decided,
        Refused
    }

    enum TokenType {
        FungibleToken,
        NonFungibleToken,
        MultiToken
    } // ERC20, ERC721, ERC1155

    enum MetaTxInputType {
        Generic,
        CommitToOffer,
        Exchange,
        Funds,
        RaiseDispute,
        ResolveDispute
    }

    enum AuthTokenType {
        None,
        Custom, // For future use
        Lens,
        ENS
    }

    struct AuthToken {
        uint256 tokenId;
        AuthTokenType tokenType;
    }

    struct Seller {
        uint256 id;
        address operator;
        address admin;
        address clerk;
        address payable treasury;
        bool active;
    }

    struct Buyer {
        uint256 id;
        address payable wallet;
        bool active;
    }

    struct DisputeResolver {
        uint256 id;
        uint256 escalationResponsePeriod;
        address operator;
        address admin;
        address clerk;
        address payable treasury;
        string metadataUri;
        bool active;
    }

    struct DisputeResolverFee {
        address tokenAddress;
        string tokenName;
        uint256 feeAmount;
    }

    struct Agent {
        uint256 id;
        uint256 feePercentage;
        address payable wallet;
        bool active;
    }

    struct DisputeResolutionTerms {
        uint256 disputeResolverId;
        uint256 escalationResponsePeriod;
        uint256 feeAmount;
        uint256 buyerEscalationDeposit;
    }

    struct Offer {
        uint256 id;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 buyerCancelPenalty;
        uint256 quantityAvailable;
        address exchangeToken;
        string metadataUri;
        string metadataHash;
        bool voided;
    }

    struct OfferDates {
        uint256 validFrom;
        uint256 validUntil;
        uint256 voucherRedeemableFrom;
        uint256 voucherRedeemableUntil;
    }

    struct OfferDurations {
        uint256 disputePeriod;
        uint256 voucherValid;
        uint256 resolutionPeriod;
    }

    struct Group {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
    }

    struct Condition {
        EvaluationMethod method;
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId;
        uint256 threshold;
        uint256 maxCommits;
    }

    struct Exchange {
        uint256 id;
        uint256 offerId;
        uint256 buyerId;
        uint256 finalizedDate;
        ExchangeState state;
    }

    struct Voucher {
        uint256 committedDate;
        uint256 validUntilDate;
        uint256 redeemedDate;
        bool expired;
    }

    struct Dispute {
        uint256 exchangeId;
        uint256 buyerPercent;
        DisputeState state;
    }

    struct DisputeDates {
        uint256 disputed;
        uint256 escalated;
        uint256 finalized;
        uint256 timeout;
    }

    struct Receipt {
        uint256 exchangeId;
        uint256 offerId;
        uint256 buyerId;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 buyerCancelPenalty;
        OfferFees offerFees;
        uint256 agentId;
        address exchangeToken;
        uint256 finalizedDate;
        Condition condition;
        uint256 committedDate;
        uint256 redeemedDate;
        bool voucherExpired;
        uint256 disputeResolverId;
        uint256 disputedDate;
        uint256 escalatedDate;
        DisputeState disputeState;
        TwinReceipt[] twinReceipts;
    }

    struct TokenRange {
        uint256 start;
        uint256 end;
    }

    struct Twin {
        uint256 id;
        uint256 sellerId;
        uint256 amount; // ERC1155 / ERC20 (amount to be transferred to each buyer on redemption)
        uint256 supplyAvailable; // all
        uint256 tokenId; // ERC1155 / ERC721 (must be initialized with the initial pointer position of the ERC721 ids available range)
        address tokenAddress; // all
        TokenType tokenType;
    }

    struct TwinReceipt {
        uint256 twinId;
        uint256 tokenId; // only for ERC721 and ERC1155
        uint256 amount; // only for ERC1155 and ERC20
        address tokenAddress;
        TokenType tokenType;
    }

    struct Bundle {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        uint256[] twinIds;
    }

    struct Funds {
        address tokenAddress;
        string tokenName;
        uint256 availableAmount;
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        bytes functionSignature;
    }

    struct HashInfo {
        bytes32 typeHash;
        function(bytes memory) internal pure returns (bytes32) hashFunction;
    }

    struct OfferFees {
        uint256 protocolFee;
        uint256 agentFee;
    }

    struct VoucherInitValues {
        string contractURI;
        uint256 royaltyPercentage;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";
import { IBosonOfferEvents } from "../events/IBosonOfferEvents.sol";

/**
 * @title IBosonOfferHandler
 *
 * @notice Handles creation, voiding, and querying of offers within the protocol.
 *
 * The ERC-165 identifier for this interface is: 0xde051f34
 */
interface IBosonOfferHandler is IBosonOfferEvents {
    /**
     * @notice Creates an offer.
     *
     * Emits an OfferCreated event if successful.
     *
     * Reverts if:
     * - The offers region of protocol is paused
     * - Caller is not an operator
     * - Valid from date is greater than valid until date
     * - Valid until date is not in the future
     * - Both voucher expiration date and voucher expiration period are defined
     * - Neither of voucher expiration date and voucher expiration period are defined
     * - Voucher redeemable period is fixed, but it ends before it starts
     * - Voucher redeemable period is fixed, but it ends before offer expires
     * - Dispute period is less than minimum dispute period
     * - Resolution period is set to zero or above the maximum resolution period
     * - Voided is set to true
     * - Available quantity is set to zero
     * - Dispute resolver wallet is not registered, except for absolute zero offers with unspecified dispute resolver
     * - Dispute resolver is not active, except for absolute zero offers with unspecified dispute resolver
     * - Seller is not on dispute resolver's seller allow list
     * - Dispute resolver does not accept fees in the exchange token
     * - Buyer cancel penalty is greater than price
     * - When agent id is non zero:
     *   - If Agent does not exist
     *   - If the sum of agent fee amount and protocol fee amount is greater than the offer fee limit
     *
     * @param _offer - the fully populated struct with offer id set to 0x0 and voided set to false
     * @param _offerDates - the fully populated offer dates struct
     * @param _offerDurations - the fully populated offer durations struct
     * @param _disputeResolverId - the id of chosen dispute resolver (can be 0)
     * @param _agentId - the id of agent
     */
    function createOffer(
        BosonTypes.Offer memory _offer,
        BosonTypes.OfferDates calldata _offerDates,
        BosonTypes.OfferDurations calldata _offerDurations,
        uint256 _disputeResolverId,
        uint256 _agentId
    ) external;

    /**
     * @notice Creates a batch of offers.
     *
     * Emits an OfferCreated event for every offer if successful.
     *
     * Reverts if:
     * - The offers region of protocol is paused
     * - Number of offers exceeds maximum allowed number per batch
     * - Number of elements in offers, offerDates and offerDurations do not match
     * - For any offer:
     *   - Caller is not an operator
     *   - Valid from date is greater than valid until date
     *   - Valid until date is not in the future
     *   - Both voucher expiration date and voucher expiration period are defined
     *   - Neither of voucher expiration date and voucher expiration period are defined
     *   - Voucher redeemable period is fixed, but it ends before it starts
     *   - Voucher redeemable period is fixed, but it ends before offer expires
     *   - Dispute period is less than minimum dispute period
     *   - Resolution period is set to zero or above the maximum resolution period
     *   - Voided is set to true
     *   - Available quantity is set to zero
     *   - Dispute resolver wallet is not registered, except for absolute zero offers with unspecified dispute resolver
     *   - Dispute resolver is not active, except for absolute zero offers with unspecified dispute resolver
     *   - Seller is not on dispute resolver's seller allow list
     *   - Dispute resolver does not accept fees in the exchange token
     *   - Buyer cancel penalty is greater than price
     * - When agent ids are non zero:
     *   - If Agent does not exist
     *   - If the sum of agent fee amount and protocol fee amount is greater than the offer fee limit
     *
     * @param _offers - the array of fully populated Offer structs with offer id set to 0x0 and voided set to false
     * @param _offerDates - the array of fully populated offer dates structs
     * @param _offerDurations - the array of fully populated offer durations structs
     * @param _disputeResolverIds - the array of ids of chosen dispute resolvers (can be 0)
     * @param _agentIds - the array of ids of agents
     */
    function createOfferBatch(
        BosonTypes.Offer[] calldata _offers,
        BosonTypes.OfferDates[] calldata _offerDates,
        BosonTypes.OfferDurations[] calldata _offerDurations,
        uint256[] calldata _disputeResolverIds,
        uint256[] calldata _agentIds
    ) external;

    /**
     * @notice Voids a given offer.
     * Existing exchanges are not affected.
     * No further vouchers can be issued against a voided offer.
     *
     * Emits an OfferVoided event if successful.
     *
     * Reverts if:
     * - The offers region of protocol is paused
     * - Offer id is invalid
     * - Caller is not the operator of the offer
     * - Offer has already been voided
     *
     * @param _offerId - the id of the offer to void
     */
    function voidOffer(uint256 _offerId) external;

    /**
     * @notice  Voids a batch of offers.
     * Existing exchanges are not affected.
     * No further vouchers can be issued against a voided offer.
     *
     * Emits an OfferVoided event for every offer if successful.
     *
     * Reverts if, for any offer:
     * - The offers region of protocol is paused
     * - Number of offers exceeds maximum allowed number per batch
     * - Offer id is invalid
     * - Caller is not the operator of the offer
     * - Offer has already been voided
     *
     * @param _offerIds - list of ids of offers to void
     */
    function voidOfferBatch(uint256[] calldata _offerIds) external;

    /**
     * @notice Sets new valid until date.
     *
     * Emits an OfferExtended event if successful.
     *
     * Reverts if:
     * - The offers region of protocol is paused
     * - Offer does not exist
     * - Caller is not the operator of the offer
     * - New valid until date is before existing valid until dates
     * - Offer has voucherRedeemableUntil set and new valid until date is greater than that
     *
     *  @param _offerId - the id of the offer to extend
     *  @param _validUntilDate - new valid until date
     */
    function extendOffer(uint256 _offerId, uint256 _validUntilDate) external;

    /**
     * @notice Sets new valid until date for a batch of offers.
     *
     * Emits an OfferExtended event for every offer if successful.
     *
     * Reverts if:
     * - The offers region of protocol is paused
     * - Number of offers exceeds maximum allowed number per batch
     * - For any of the offers:
     *   - Offer does not exist
     *   - Caller is not the operator of the offer
     *   - New valid until date is before existing valid until dates
     *   - Offer has voucherRedeemableUntil set and new valid until date is greater than that
     *
     *  @param _offerIds - list of ids of the offers to extend
     *  @param _validUntilDate - new valid until date
     */
    function extendOfferBatch(uint256[] calldata _offerIds, uint256 _validUntilDate) external;

    /**
     * @notice Gets the details about a given offer.
     *
     * @param _offerId - the id of the offer to retrieve
     * @return exists - the offer was found
     * @return offer - the offer details. See {BosonTypes.Offer}
     * @return offerDates - the offer dates details. See {BosonTypes.OfferDates}
     * @return offerDurations - the offer durations details. See {BosonTypes.OfferDurations}
     * @return disputeResolutionTerms - the details about the dispute resolution terms. See {BosonTypes.DisputeResolutionTerms}
     * @return offerFees - the offer fees details. See {BosonTypes.OfferFees}
     */
    function getOffer(uint256 _offerId)
        external
        view
        returns (
            bool exists,
            BosonTypes.Offer memory offer,
            BosonTypes.OfferDates memory offerDates,
            BosonTypes.OfferDurations memory offerDurations,
            BosonTypes.DisputeResolutionTerms memory disputeResolutionTerms,
            BosonTypes.OfferFees memory offerFees
        );

    /**
     * @notice Gets the next offer id.
     *
     * @dev Does not increment the counter.
     *
     * @return nextOfferId - the next offer id
     */
    function getNextOfferId() external view returns (uint256 nextOfferId);

    /**
     * @notice Checks if offer is voided or not.
     *
     * @param _offerId - the id of the offer to check
     * @return exists - the offer was found
     * @return offerVoided - true if voided, false otherwise
     */
    function isOfferVoided(uint256 _offerId) external view returns (bool exists, bool offerVoided);

    /**
     * @notice Gets the agent id for a given offer id.
     *
     * @param _offerId - the offer id
     * @return exists - whether the agent id exists
     * @return agentId - the agent id
     */
    function getAgentIdByOffer(uint256 _offerId) external view returns (bool exists, uint256 agentId);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";
import { IBosonExchangeEvents } from "../events/IBosonExchangeEvents.sol";
import { IBosonTwinEvents } from "../events/IBosonTwinEvents.sol";
import { IBosonFundsLibEvents } from "../events/IBosonFundsEvents.sol";

/**
 * @title IBosonExchangeHandler
 *
 * @notice Handles exchanges associated with offers within the protocol.
 *
 * The ERC-165 identifier for this interface is: 0xbc114381
 */
interface IBosonExchangeHandler is IBosonExchangeEvents, IBosonFundsLibEvents, IBosonTwinEvents {
    /**
     * @notice Commits to an offer (first step of an exchange).
     *
     * Emits a BuyerCommitted event if successful.
     * Issues a voucher to the buyer address.
     *
     * Reverts if:
     * - The exchanges region of protocol is paused
     * - The buyers region of protocol is paused
     * - OfferId is invalid
     * - Offer has been voided
     * - Offer has expired
     * - Offer is not yet available for commits
     * - Offer's quantity available is zero
     * - Buyer address is zero
     * - Buyer account is inactive
     * - Buyer is token-gated (conditional commit requirements not met or already used)
     * - Offer price is in native token and caller does not send enough
     * - Offer price is in some ERC20 token and caller also sends native currency
     * - Contract at token address does not support ERC20 function transferFrom
     * - Calling transferFrom on token fails for some reason (e.g. protocol is not approved to transfer)
     * - Received ERC20 token amount differs from the expected value
     * - Seller has less funds available than sellerDeposit
     *
     * @param _buyer - the buyer's address (caller can commit on behalf of a buyer)
     * @param _offerId - the id of the offer to commit to
     */
    function commitToOffer(address payable _buyer, uint256 _offerId) external payable;

    /**
     * @notice Completes an exchange.
     *
     * Emits an ExchangeCompleted event if successful.
     *
     * Reverts if
     * - The exchanges region of protocol is paused
     * - Exchange does not exist
     * - Exchange is not in Redeemed state
     * - Caller is not buyer and offer dispute period has not elapsed
     *
     * @param _exchangeId - the id of the exchange to complete
     */
    function completeExchange(uint256 _exchangeId) external;

    /**
     * @notice Completes a batch of exchanges.
     *
     * Emits an ExchangeCompleted event for every exchange if finalized to the Complete state.
     *
     * Reverts if:
     * - The exchanges region of protocol is paused
     * - Number of exchanges exceeds maximum allowed number per batch
     * - For any exchange:
     *   - Exchange does not exist
     *   - Exchange is not in Redeemed state
     *   - Caller is not buyer and offer dispute period has not elapsed
     *
     * @param _exchangeIds - the array of exchanges ids
     */
    function completeExchangeBatch(uint256[] calldata _exchangeIds) external;

    /**
     * @notice Revokes a voucher.
     *
     * Emits a VoucherRevoked event if successful.
     *
     * Reverts if
     * - The exchanges region of protocol is paused
     * - Exchange does not exist
     * - Exchange is not in Committed state
     * - Caller is not seller's operator
     *
     * @param _exchangeId - the id of the exchange
     */
    function revokeVoucher(uint256 _exchangeId) external;

    /**
     * @notice Cancels a voucher.
     *
     * Emits a VoucherCanceled event if successful.
     *
     * Reverts if
     * - The exchanges region of protocol is paused
     * - Exchange does not exist
     * - Exchange is not in Committed state
     * - Caller does not own voucher
     *
     * @param _exchangeId - the id of the exchange
     */
    function cancelVoucher(uint256 _exchangeId) external;

    /**
     * @notice Expires a voucher.
     *
     * Emits a VoucherExpired event if successful.
     *
     * Reverts if
     * - The exchanges region of protocol is paused
     * - Exchange does not exist
     * - Exchange is not in Committed state
     * - Redemption period has not yet elapsed
     *
     * @param _exchangeId - the id of the exchange
     */
    function expireVoucher(uint256 _exchangeId) external;

    /**
     * @notice Extends a Voucher's validity period.
     *
     * Emits a VoucherExtended event if successful.
     *
     * Reverts if
     * - The exchanges region of protocol is paused
     * - Exchange does not exist
     * - Exchange is not in Committed state
     * - Caller is not seller's operator
     * - New date is not later than the current one
     *
     * @param _exchangeId - the id of the exchange
     * @param _validUntilDate - the new voucher expiry date
     */
    function extendVoucher(uint256 _exchangeId, uint256 _validUntilDate) external;

    /**
     * @notice Redeems a voucher.
     *
     * Emits a VoucherRedeemed event if successful.
     *
     * Reverts if
     * - The exchanges region of protocol is paused
     * - Exchange does not exist
     * - Exchange is not in committed state
     * - Caller does not own voucher
     * - Current time is prior to offer.voucherRedeemableFromDate
     * - Current time is after voucher.validUntilDate
     *
     * @param _exchangeId - the id of the exchange
     */
    function redeemVoucher(uint256 _exchangeId) external;

    /**
     * @notice Informs protocol of new buyer associated with an exchange.
     *
     * Emits a VoucherTransferred event if successful.
     *
     * Reverts if
     * - The buyers region of protocol is paused
     * - Caller is not a clone address associated with the seller
     * - Exchange does not exist
     * - Exchange is not in Committed state
     * - Voucher has expired
     * - New buyer's existing account is deactivated
     *
     * @param _exchangeId - the id of the exchange
     * @param _newBuyer - the address of the new buyer
     */
    function onVoucherTransferred(uint256 _exchangeId, address payable _newBuyer) external;

    /**
     * @notice Checks if the given exchange in a finalized state.
     *
     * Returns true if
     * - Exchange state is Revoked, Canceled, or Completed
     * - Exchange is disputed and dispute state is Retracted, Resolved, Decided or Refused
     *
     * @param _exchangeId - the id of the exchange to check
     * @return exists - true if the exchange exists
     * @return isFinalized - true if the exchange is finalized
     */
    function isExchangeFinalized(uint256 _exchangeId) external view returns (bool exists, bool isFinalized);

    /**
     * @notice Gets the details about a given exchange.
     *
     * @param _exchangeId - the id of the exchange to check
     * @return exists - true if the exchange exists
     * @return exchange - the exchange details. See {BosonTypes.Exchange}
     * @return voucher - the voucher details. See {BosonTypes.Voucher}
     */
    function getExchange(uint256 _exchangeId)
        external
        view
        returns (
            bool exists,
            BosonTypes.Exchange memory exchange,
            BosonTypes.Voucher memory voucher
        );

    /**
     * @notice Gets the state of a given exchange.
     *
     * @param _exchangeId - the id of the exchange to check
     * @return exists - true if the exchange exists
     * @return state - the exchange state. See {BosonTypes.ExchangeStates}
     */
    function getExchangeState(uint256 _exchangeId) external view returns (bool exists, BosonTypes.ExchangeState state);

    /**
     * @notice Gets the id that will be assigned to the next exchange.
     *
     * @dev Does not increment the counter.
     *
     * @return nextExchangeId - the next exchange id
     */
    function getNextExchangeId() external view returns (uint256 nextExchangeId);

    /**
     * @notice Gets exchange receipt.
     *
     * Reverts if:
     * - Exchange is not in a final state
     * - Exchange id is invalid
     *
     * @param _exchangeId - the exchange id
     * @return receipt - the receipt for the exchange. See {BosonTypes.Receipt}
     */
    function getReceipt(uint256 _exchangeId) external view returns (BosonTypes.Receipt memory receipt);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";
import { IBosonAccountEvents } from "../events/IBosonAccountEvents.sol";

/**
 * @title IBosonAccountHandler
 *
 * @notice Handles creation, update, retrieval of accounts within the protocol.
 *
 * The ERC-165 identifier for this interface is: 0x6db2c812
 */
interface IBosonAccountHandler is IBosonAccountEvents {
    /**
     * @notice Creates a seller.
     *
     * Emits a SellerCreated event if successful.
     *
     * Reverts if:
     * - Caller is not the supplied admin or does not own supplied auth token
     * - Caller is not the supplied operator and clerk
     * - The sellers region of protocol is paused
     * - Address values are zero address
     * - Addresses are not unique to this seller
     * - Seller is not active (if active == false)
     * - Admin address is zero address and AuthTokenType == None
     * - AuthTokenType is not unique to this seller
     * - AuthTokenType is Custom
     *
     * @param _seller - the fully populated struct with seller id set to 0x0
     * @param _authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the seller can use to do admin functions
     * @param _voucherInitValues - the fully populated BosonTypes.VoucherInitValues struct
     */
    function createSeller(
        BosonTypes.Seller memory _seller,
        BosonTypes.AuthToken calldata _authToken,
        BosonTypes.VoucherInitValues calldata _voucherInitValues
    ) external;

    /**
     * @notice Creates a buyer.
     *
     * Emits an BuyerCreated event if successful.
     *
     * Reverts if:
     * - The buyers region of protocol is paused
     * - Wallet address is zero address
     * - Active is not true
     * - Wallet address is not unique to this buyer
     *
     * @param _buyer - the fully populated struct with buyer id set to 0x0
     */
    function createBuyer(BosonTypes.Buyer memory _buyer) external;

    /**
     * @notice Creates a dispute resolver. Dispute resolver must be activated before it can participate in the protocol.
     *
     * Emits a DisputeResolverCreated event if successful.
     *
     * Reverts if:
     * - Caller is not the supplied admin, operator and clerk
     * - The dispute resolvers region of protocol is paused
     * - Any address is zero address
     * - Any address is not unique to this dispute resolver
     * - Number of DisputeResolverFee structs in array exceeds max
     * - DisputeResolverFee array contains duplicates
     * - EscalationResponsePeriod is invalid
     * - Number of seller ids in _sellerAllowList array exceeds max
     * - Some seller does not exist
     * - Some seller id is duplicated
     *
     * @param _disputeResolver - the fully populated struct with dispute resolver id set to 0x0
     * @param _disputeResolverFees - array of fees dispute resolver charges per token type. Zero address is native currency. Can be empty.
     * @param _sellerAllowList - list of ids of sellers that can choose this dispute resolver. If empty, there are no restrictions on which seller can chose it.
     */
    function createDisputeResolver(
        BosonTypes.DisputeResolver memory _disputeResolver,
        BosonTypes.DisputeResolverFee[] calldata _disputeResolverFees,
        uint256[] calldata _sellerAllowList
    ) external;

    /**
     * @notice Creates a marketplace agent.
     *
     * Emits an AgentCreated event if successful.
     *
     * Reverts if:
     * - The agents region of protocol is paused
     * - Wallet address is zero address
     * - Active is not true
     * - Wallet address is not unique to this agent
     * - Fee percentage + protocol fee percentage is greater than the max allowable fee percentage for an offer
     *
     * @param _agent - the fully populated struct with agent id set to 0x0
     */
    function createAgent(BosonTypes.Agent memory _agent) external;

    /**
     * @notice Updates a seller, with the exception of the active flag.
     *         All other fields should be filled, even those staying the same.
     * @dev    Active flag passed in by caller will be ignored. The value from storage will be used.
     *
     * Emits a SellerUpdated event if successful.
     *
     * Reverts if:
     * - The sellers region of protocol is paused
     * - Address values are zero address
     * - Addresses are not unique to this seller
     * - Caller is not the admin address of the seller
     * - Seller does not exist
     * - Admin address is zero address and AuthTokenType == None
     * - AuthTokenType is not unique to this seller
     * - AuthTokenType is Custom
     *
     * @param _seller - the fully populated seller struct
     * @param _authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the seller can use to do admin functions
     */
    function updateSeller(BosonTypes.Seller memory _seller, BosonTypes.AuthToken calldata _authToken) external;

    /**
     * @notice Updates a buyer, with the exception of the active flag.
     *         All other fields should be filled, even those staying the same.
     * @dev    Active flag passed in by caller will be ignored. The value from storage will be used.
     *
     * Emits a BuyerUpdated event if successful.
     *
     * Reverts if:
     * - The buyers region of protocol is paused
     * - Caller is not the wallet address associated with the buyer account
     * - Wallet address is zero address
     * - Address is not unique to this buyer
     * - Buyer does not exist
     * - Current wallet address has outstanding vouchers
     *
     * @param _buyer - the fully populated buyer struct
     */
    function updateBuyer(BosonTypes.Buyer memory _buyer) external;

    /**
     * @notice Updates a dispute resolver, not including DisputeResolverFees, allowed seller list or active flag.
     *         All DisputeResolver fields should be filled, even those staying the same.
     *         Use removeFeesFromDisputeResolver and addFeesToDisputeResolver to add and remove fees.
     *         Use addSellersToAllowList and removeSellersFromAllowList to add and remove allowed sellers.
     * @dev    Active flag passed in by caller will be ignored. The value from storage will be used.
     *
     * Emits a DisputeResolverUpdated event if successful.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller is not the admin address associated with the dispute resolver account
     * - Any address is zero address
     * - Any address is not unique to this dispute resolver
     * - Dispute resolver does not exist
     *
     * @param _disputeResolver - the fully populated dispute resolver struct
     */
    function updateDisputeResolver(BosonTypes.DisputeResolver memory _disputeResolver) external;

    /**
     * @notice Updates an agent, with the exception of the active flag.
     *         All other fields should be filled, even those staying the same.
     * @dev    Active flag passed in by caller will be ignored. The value from storage will be used.
     *
     * Emits an AgentUpdated event if successful.
     *
     * Reverts if:
     * - The agents region of protocol is paused
     * - Caller is not the wallet address associated with the agent account
     * - Wallet address is zero address
     * - Wallet address is not unique to this agent
     * - Agent does not exist
     * - Fee percentage + protocol fee percentage is greater than the max allowable fee percentage for an offer
     *
     * @param _agent - the fully populated agent struct
     */
    function updateAgent(BosonTypes.Agent memory _agent) external;

    /**
     * @notice Adds DisputeResolverFees to an existing dispute resolver.
     *
     * Emits a DisputeResolverFeesAdded event if successful.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller is not the admin address associated with the dispute resolver account
     * - Dispute resolver does not exist
     * - Number of DisputeResolverFee structs in array exceeds max
     * - Number of DisputeResolverFee structs in array is zero
     * - DisputeResolverFee array contains duplicates
     *
     * @param _disputeResolverId - id of the dispute resolver
     * @param _disputeResolverFees - list of fees dispute resolver charges per token type. Zero address is native currency. See {BosonTypes.DisputeResolverFee}
     */
    function addFeesToDisputeResolver(
        uint256 _disputeResolverId,
        BosonTypes.DisputeResolverFee[] calldata _disputeResolverFees
    ) external;

    /**
     * @notice Removes DisputeResolverFees from  an existing dispute resolver.
     *
     * Emits a DisputeResolverFeesRemoved event if successful.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller is not the admin address associated with the dispute resolver account
     * - Dispute resolver does not exist
     * - Number of DisputeResolverFee structs in array exceeds max
     * - Number of DisputeResolverFee structs in array is zero
     * - DisputeResolverFee does not exist for the dispute resolver
     *
     * @param _disputeResolverId - id of the dispute resolver
     * @param _feeTokenAddresses - list of addresses of dispute resolver fee tokens to remove
     */
    function removeFeesFromDisputeResolver(uint256 _disputeResolverId, address[] calldata _feeTokenAddresses) external;

    /**
     * @notice Adds seller ids to set of ids allowed to choose the given dispute resolver for an offer.
     *
     * Emits an AllowedSellersAdded event if successful.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller is not the admin address associated with the dispute resolver account
     * - Dispute resolver does not exist
     * - Number of seller ids in array exceeds max
     * - Number of seller ids in array is zero
     * - Some seller does not exist
     * - Seller id is already approved
     *
     * @param _disputeResolverId - id of the dispute resolver
     * @param _sellerAllowList - List of seller ids to add to allowed list
     */
    function addSellersToAllowList(uint256 _disputeResolverId, uint256[] calldata _sellerAllowList) external;

    /**
     * @notice Removes seller ids from set of ids allowed to choose the given dispute resolver for an offer.
     *
     * Emits an AllowedSellersRemoved event if successful.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller is not the admin address associated with the dispute resolver account
     * - Dispute resolver does not exist
     * - Number of seller ids in array exceeds max
     * - Number of seller ids structs in array is zero
     * - Seller id is not approved
     *
     * @param _disputeResolverId - id of the dispute resolver
     * @param _sellerAllowList - list of seller ids to remove from allowed list
     */
    function removeSellersFromAllowList(uint256 _disputeResolverId, uint256[] calldata _sellerAllowList) external;

    /**
     * @notice Sets the active flag for this dispute resolver to true.
     *
     * @dev Only callable by the protocol ADMIN role.
     *
     * Emits a DisputeResolverActivated event if successful.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller does not have the ADMIN role
     * - Dispute resolver does not exist
     *
     * @param _disputeResolverId - id of the dispute resolver
     */
    function activateDisputeResolver(uint256 _disputeResolverId) external;

    /**
     * @notice Gets the details about a seller.
     *
     * @param _sellerId - the id of the seller to check
     * @return exists - the seller was found
     * @return seller - the seller details. See {BosonTypes.Seller}
     * @return authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the seller can use to do admin functions
     *                     See {BosonTypes.AuthToken}
     */
    function getSeller(uint256 _sellerId)
        external
        view
        returns (
            bool exists,
            BosonTypes.Seller memory seller,
            BosonTypes.AuthToken memory authToken
        );

    /**
     * @notice Gets the details about a seller by an address associated with that seller: operator, admin, or clerk address.
     * A seller will have either an admin address or an auth token.
     * If seller's admin uses NFT Auth the seller should call `getSellerByAuthToken` instead.
     *
     * @param _associatedAddress - the address associated with the seller. Must be an operator, admin, or clerk address.
     * @return exists - the seller was found
     * @return seller - the seller details. See {BosonTypes.Seller}
     * @return authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the seller can use to do admin functions
     *                     See {BosonTypes.AuthToken}
     */
    function getSellerByAddress(address _associatedAddress)
        external
        view
        returns (
            bool exists,
            BosonTypes.Seller memory seller,
            BosonTypes.AuthToken memory authToken
        );

    /**
     * @notice Gets the details about a seller by an auth token associated with that seller.
     * A seller will have either an admin address or an auth token.
     * If seller's admin uses an admin address, the seller should call `getSellerByAddress` instead.
     *
     *
     * @param _associatedAuthToken - the auth token that may be associated with the seller.
     * @return exists - the seller was found
     * @return seller - the seller details. See {BosonTypes.Seller}
     * @return authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the seller can use to do admin functions
     *                     See {BosonTypes.AuthToken}
     */
    function getSellerByAuthToken(BosonTypes.AuthToken calldata _associatedAuthToken)
        external
        view
        returns (
            bool exists,
            BosonTypes.Seller memory seller,
            BosonTypes.AuthToken memory authToken
        );

    /**
     * @notice Gets the details about a buyer.
     *
     * @param _buyerId - the id of the buyer to check
     * @return exists - whether the buyer was found
     * @return buyer - the buyer details. See {BosonTypes.Buyer}
     */
    function getBuyer(uint256 _buyerId) external view returns (bool exists, BosonTypes.Buyer memory buyer);

    /**
     * @notice Gets the details about a dispute resolver.
     *
     * @param _disputeResolverId - the id of the dispute resolver to check
     * @return exists - the dispute resolver was found
     * @return disputeResolver - the dispute resolver details. See {BosonTypes.DisputeResolver}
     * @return disputeResolverFees - list of fees dispute resolver charges per token type. Zero address is native currency. See {BosonTypes.DisputeResolverFee}
     * @return sellerAllowList - list of sellers that are allowed to choose this dispute resolver
     */
    function getDisputeResolver(uint256 _disputeResolverId)
        external
        view
        returns (
            bool exists,
            BosonTypes.DisputeResolver memory disputeResolver,
            BosonTypes.DisputeResolverFee[] memory disputeResolverFees,
            uint256[] memory sellerAllowList
        );

    /**
     * @notice Gets the details about a dispute resolver by an address associated with that dispute resolver: operator, admin, or clerk address.
     *
     * @param _associatedAddress - the address associated with the dispute resolver. Must be an operator, admin, or clerk address.
     * @return exists - the dispute resolver was found
     * @return disputeResolver - the dispute resolver details. See {BosonTypes.DisputeResolver}
     * @return disputeResolverFees - list of fees dispute resolver charges per token type. Zero address is native currency. See {BosonTypes.DisputeResolverFee}
     * @return sellerAllowList - list of sellers that are allowed to chose this dispute resolver
     */
    function getDisputeResolverByAddress(address _associatedAddress)
        external
        view
        returns (
            bool exists,
            BosonTypes.DisputeResolver memory disputeResolver,
            BosonTypes.DisputeResolverFee[] memory disputeResolverFees,
            uint256[] memory sellerAllowList
        );

    /**
     * @notice Gets the details about an agent.
     *
     * @param _agentId - the id of the agent to check
     * @return exists - whether the agent was found
     * @return agent - the agent details. See {BosonTypes.Agent}
     */
    function getAgent(uint256 _agentId) external view returns (bool exists, BosonTypes.Agent memory agent);

    /**
     * @notice Checks whether given sellers are allowed to choose the given dispute resolver.
     *
     * @param _disputeResolverId - id of dispute resolver to check
     * @param _sellerIds - list of seller ids to check
     * @return sellerAllowed - array with indicator (true/false) if seller is allowed to choose the dispute resolver. Index in this array corresponds to indices of the incoming _sellerIds
     */
    function areSellersAllowed(uint256 _disputeResolverId, uint256[] calldata _sellerIds)
        external
        view
        returns (bool[] memory sellerAllowed);

    /**
     * @notice Gets the next account id that can be assigned to an account.
     *
     * @dev Does not increment the counter.
     *
     * @return nextAccountId - the account id
     */
    function getNextAccountId() external view returns (uint256 nextAccountId);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title IBosonOfferEvents
 *
 * @notice Defines events related to management of offers within the protocol.
 */
interface IBosonOfferEvents {
    event OfferCreated(
        uint256 indexed offerId,
        uint256 indexed sellerId,
        BosonTypes.Offer offer,
        BosonTypes.OfferDates offerDates,
        BosonTypes.OfferDurations offerDurations,
        BosonTypes.DisputeResolutionTerms disputeResolutionTerms,
        BosonTypes.OfferFees offerFees,
        uint256 indexed agentId,
        address executedBy
    );
    event OfferExtended(
        uint256 indexed offerId,
        uint256 indexed sellerId,
        uint256 validUntilDate,
        address indexed executedBy
    );
    event OfferVoided(uint256 indexed offerId, uint256 indexed sellerId, address indexed executedBy);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title IBosonExchangeEvents
 *
 * @notice Defines events related to exchanges within the protocol.
 */
interface IBosonExchangeEvents {
    event BuyerCommitted(
        uint256 indexed offerId,
        uint256 indexed buyerId,
        uint256 indexed exchangeId,
        BosonTypes.Exchange exchange,
        BosonTypes.Voucher voucher,
        address executedBy
    );
    event ExchangeCompleted(
        uint256 indexed offerId,
        uint256 indexed buyerId,
        uint256 indexed exchangeId,
        address executedBy
    );
    event VoucherCanceled(uint256 indexed offerId, uint256 indexed exchangeId, address indexed executedBy);
    event VoucherExpired(uint256 indexed offerId, uint256 indexed exchangeId, address indexed executedBy);
    event VoucherExtended(
        uint256 indexed offerId,
        uint256 indexed exchangeId,
        uint256 validUntil,
        address indexed executedBy
    );
    event VoucherRedeemed(uint256 indexed offerId, uint256 indexed exchangeId, address indexed executedBy);
    event VoucherRevoked(uint256 indexed offerId, uint256 indexed exchangeId, address indexed executedBy);
    event VoucherTransferred(
        uint256 indexed offerId,
        uint256 indexed exchangeId,
        uint256 indexed newBuyerId,
        address executedBy
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title IBosonTwinEvents
 *
 * @notice Defines events related to management of twins within the protocol.
 */
interface IBosonTwinEvents {
    event TwinCreated(
        uint256 indexed twinId,
        uint256 indexed sellerId,
        BosonTypes.Twin twin,
        address indexed executedBy
    );
    event TwinDeleted(uint256 indexed twinId, uint256 indexed sellerId, address indexed executedBy);
    // Amount must be 0 if token type is TokenType.NonFungible
    // tokenId must be 0 if token type is TokenType.Fungible
    event TwinTransferred(
        uint256 indexed twinId,
        address indexed tokenAddress,
        uint256 indexed exchangeId,
        uint256 tokenId,
        uint256 amount,
        address executedBy
    );
    event TwinTransferFailed(
        uint256 indexed twinId,
        address indexed tokenAddress,
        uint256 indexed exchangeId,
        uint256 tokenId,
        uint256 amount,
        address executedBy
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title IBosonFundsEvents
 *
 * @notice Defines events related to management of funds within the protocol.
 */
interface IBosonFundsEvents {
    event FundsDeposited(
        uint256 indexed sellerId,
        address indexed executedBy,
        address indexed tokenAddress,
        uint256 amount
    );
}

interface IBosonFundsLibEvents {
    event FundsEncumbered(
        uint256 indexed entityId,
        address indexed exchangeToken,
        uint256 amount,
        address indexed executedBy
    );
    event FundsReleased(
        uint256 indexed exchangeId,
        uint256 indexed entityId,
        address indexed exchangeToken,
        uint256 amount,
        address executedBy
    );
    event ProtocolFeeCollected(
        uint256 indexed exchangeId,
        address indexed exchangeToken,
        uint256 amount,
        address indexed executedBy
    );
    event FundsWithdrawn(
        uint256 indexed sellerId,
        address indexed withdrawnTo,
        address indexed tokenAddress,
        uint256 amount,
        address executedBy
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title IBosonAccountEvents
 *
 * @notice Defines events related to management of accounts within the protocol.
 */
interface IBosonAccountEvents {
    event SellerCreated(
        uint256 indexed sellerId,
        BosonTypes.Seller seller,
        address voucherCloneAddress,
        BosonTypes.AuthToken authToken,
        address indexed executedBy
    );
    event SellerUpdated(
        uint256 indexed sellerId,
        BosonTypes.Seller seller,
        BosonTypes.AuthToken authToken,
        address indexed executedBy
    );
    event BuyerCreated(uint256 indexed buyerId, BosonTypes.Buyer buyer, address indexed executedBy);
    event BuyerUpdated(uint256 indexed buyerId, BosonTypes.Buyer buyer, address indexed executedBy);
    event AgentUpdated(uint256 indexed agentId, BosonTypes.Agent agent, address indexed executedBy);
    event DisputeResolverCreated(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolver disputeResolver,
        BosonTypes.DisputeResolverFee[] disputeResolverFees,
        uint256[] sellerAllowList,
        address indexed executedBy
    );
    event DisputeResolverUpdated(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolver disputeResolver,
        address indexed executedBy
    );
    event DisputeResolverFeesAdded(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolverFee[] disputeResolverFees,
        address indexed executedBy
    );
    event DisputeResolverFeesRemoved(
        uint256 indexed disputeResolverId,
        address[] feeTokensRemoved,
        address indexed executedBy
    );
    event AllowedSellersAdded(uint256 indexed disputeResolverId, uint256[] addedSellers, address indexed executedBy);
    event AllowedSellersRemoved(
        uint256 indexed disputeResolverId,
        uint256[] removedSellers,
        address indexed executedBy
    );
    event DisputeResolverActivated(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolver disputeResolver,
        address indexed executedBy
    );

    event AgentCreated(uint256 indexed agentId, BosonTypes.Agent agent, address indexed executedBy);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity 0.8.9;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

/**
 * @title IClientExternalAddressesEvents
 *
 * @notice Defines events related to management of Boson Protocol clients.
 */
interface IClientExternalAddressesEvents {
    event Upgraded(address indexed implementation, address indexed executedBy);
    event ProtocolAddressChanged(address indexed protocol, address indexed executedBy);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title IBosonConfigEvents
 *
 * @notice Defines events related to management of configuration within the protocol.
 */
interface IBosonConfigEvents {
    event TokenAddressChanged(address indexed tokenAddress, address indexed executedBy);
    event TreasuryAddressChanged(address indexed treasuryAddress, address indexed executedBy);
    event VoucherBeaconAddressChanged(address indexed voucherBeaconAddress, address indexed executedBy);
    event BeaconProxyAddressChanged(address indexed beaconProxyAddress, address indexed executedBy);
    event ProtocolFeePercentageChanged(uint256 feePercentage, address indexed executedBy);
    event ProtocolFeeFlatBosonChanged(uint256 feeFlatBoson, address indexed executedBy);
    event MaxExchangesPerBatchChanged(uint16 maxExchangesPerBatch, address indexed executedBy);
    event MaxOffersPerGroupChanged(uint16 maxOffersPerGroup, address indexed executedBy);
    event MaxOffersPerBatchChanged(uint16 maxOffersPerBatch, address indexed executedBy);
    event MaxTwinsPerBundleChanged(uint16 maxTwinsPerBundle, address indexed executedBy);
    event MaxOffersPerBundleChanged(uint16 maxOffersPerBundle, address indexed executedBy);
    event MaxTokensPerWithdrawalChanged(uint16 maxTokensPerWithdrawal, address indexed executedBy);
    event MaxFeesPerDisputeResolverChanged(uint16 maxFeesPerDisputeResolver, address indexed executedBy);
    event MaxEscalationResponsePeriodChanged(uint256 maxEscalationResponsePeriod, address indexed executedBy);
    event MaxDisputesPerBatchChanged(uint16 maxDisputesPerBatch, address indexed executedBy);
    event MaxAllowedSellersChanged(uint16 maxAllowedSellers, address indexed executedBy);
    event BuyerEscalationFeePercentageChanged(uint256 buyerEscalationFeePercentage, address indexed executedBy);
    event AuthTokenContractChanged(
        BosonTypes.AuthTokenType indexed authTokenType,
        address indexed authTokenContract,
        address indexed executedBy
    );
    event MaxTotalOfferFeePercentageChanged(uint16 maxTotalOfferFeePercentage, address indexed executedBy);
    event MaxRoyaltyPercentageChanged(uint16 maxRoyaltyPecentage, address indexed executedBy);
    event MaxResolutionPeriodChanged(uint256 maxResolutionPeriod, address indexed executedBy);
    event MinDisputePeriodChanged(uint256 minDisputePeriod, address indexed executedBy);
    event AccessControllerAddressChanged(address indexed accessControllerAddress, address indexed executedBy);
}