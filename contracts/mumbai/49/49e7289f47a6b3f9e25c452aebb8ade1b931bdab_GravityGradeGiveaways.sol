pragma solidity ^0.8.0;

import "./IGravityGrade.sol";
import "./IGravityGradeGiveaways.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract GravityGradeGiveaways is IGravityGradeGiveaways, OwnableUpgradeable, EIP712Upgradeable {
    uint256 public s_totalGiveaways;
    mapping(uint256 => GiveawayInfo) private s_idToGiveaway;
    mapping(address => mapping(uint256 => bool)) private s_hasClaimed;
    mapping(address => mapping(uint256 => uint256)) public nonces;

    address private s_signer;
    IGravityGrade s_gravityGrade;

    bytes32 private constant AIRDROP_MESSAGE =
        keccak256("AirdropMessage(uint256 id,address sender,uint256 nonce)");

    modifier giveawayValid(uint256 _id) {
        if (s_idToGiveaway[_id].id == 0 || s_idToGiveaway[_id].id > s_totalGiveaways)
            revert GG_Giveaway_InvalidId(_id);
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        __EIP712_init("GG__Giveaway", "1");
    }

    function claim(
        uint256 _id,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external giveawayValid(_id) {
        GiveawayInfo memory giveawayInfo = s_idToGiveaway[_id];
        if (giveawayInfo.claimed >= giveawayInfo.cap) revert GG_Giveaway_MaxAmountExceeded(_id);
        if (s_hasClaimed[msg.sender][_id]) revert GG_Giveaway_AlreadyClaimed(msg.sender);

        uint256 nonce = nonces[msg.sender][_id]++;

        bytes32 structHash = keccak256(abi.encode(AIRDROP_MESSAGE, _id, msg.sender, nonce));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        if (signer != s_signer) revert GG_Giveaway_InvalidSignature();

        address[] memory sender = new address[](1);
        uint256[] memory tokenId = new uint256[](1);
        uint256[] memory amount = new uint256[](1);

        sender[0] = msg.sender;
        tokenId[0] = giveawayInfo.tokenId;
        amount[0] = giveawayInfo.amount;

        IGravityGrade(s_gravityGrade).airdrop(sender, tokenId, amount);

        unchecked {
            ++giveawayInfo.claimed;
        }

        s_idToGiveaway[_id] = giveawayInfo;
        s_hasClaimed[msg.sender][_id] = true;

        emit GiveawayClaimed(msg.sender, _id);
    }

    function createGiveaway(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _totalAmount
    ) external onlyOwner {
        unchecked {
            ++s_totalGiveaways;
        }

        s_idToGiveaway[s_totalGiveaways] = GiveawayInfo({
            id: s_totalGiveaways,
            tokenId: _tokenId,
            amount: _amount,
            claimed: 0,
            cap: _totalAmount
        });

        emit GiveawayCreated(s_totalGiveaways, _tokenId, _amount, _totalAmount);
    }

    function deleteGiveaway(uint256 _id) external onlyOwner giveawayValid(_id) {
        delete s_idToGiveaway[_id];
        emit GiveawayDeleted(_id);
    }

    function setGravityGrade(address _gravityGrade) external onlyOwner {
        s_gravityGrade = IGravityGrade(_gravityGrade);
        emit GravityGradeSet(_gravityGrade);
    }

    function setSigner(address _signer) external onlyOwner {
        s_signer = _signer;
        emit SignerSet(_signer);
    }

    function getGiveawayInfo(uint256 _id)
        external
        view
        giveawayValid(_id)
        returns (GiveawayInfo memory _info)
    {
        _info = s_idToGiveaway[_id];
    }

    function canClaim(address _user, uint256 _id)
        external
        view
        giveawayValid(_id)
        returns (bool _canClaim)
    {
        _canClaim = !s_hasClaimed[_user][_id];
    }
}

pragma solidity ^0.8.0;

/// @dev Implementation should extend EIP712Upgradeable
interface IGravityGradeGiveaways {
    error GG_Giveaway_InvalidId(uint256 _id);
    error GG_Giveaway_InvalidSignature();
    error GG_Giveaway_MaxAmountExceeded(uint256 _id);
    error GG_Giveaway_AlreadyClaimed(address sender);

    /**
    * @notice Event emitted when a giveaway is claimed
    * @param _user The users address
    * @param _id The id of the giveaway
    */
    event GiveawayClaimed(address _user, uint256 _id);
    /**
    * @notice Event emitted when a giveaway is created
    * @param _id The id of the giveaway
    * @param _tokenId The tokenId being given away
    * @param _amount The amount of token id being given away
    * @param _totalAmount The total number of addresses that can claim this giveaway
    */
    event GiveawayCreated(uint256 _id, uint256 _tokenId, uint256 _amount, uint256 _totalAmount);
    /**
    * @notice Event emitted when a giveaway is deleted
    * @param _id The giveaways' id
    */
    event GiveawayDeleted(uint256 _id);
    /**
    * @notice Event emitted when the gravity grade address is set
    * @dev No check is made that the address is indeed to a contract implementing IGravityGrade
    * @param _gravityGrade The address to the gravity grade contract
    */
    event GravityGradeSet(address _gravityGrade);
    /**
    * @notice Event emitted when the signer wallet is updated
    * @param _signer The address of the signer wallet
    */
    event SignerSet(address _signer);

    /**
     * @notice Struct for containing giveaway info
     * @param id Giveaway id
     * @param tokenId Token Id to be given away
     * @param amount Amount given when claimed
     * @param claimed Total number claimed so far
     * @param cap Cap on total number of claims
     */
    struct GiveawayInfo {
        uint256 id;
        uint256 tokenId;
        uint256 amount;
        uint256 claimed;
        uint256 cap;
    }

    /**
     * @notice Claims a giveaway.
     * @dev Use EIP712 to handle the signature stuff.
     * @param _id The giveaway id
     * @param v Signature
     * @param r Signature
     * @param s Signature
     *
     * Throws GG_Giveaway_InvalidId on invalid id
     * Throws GG_Giveaway_InvalidSignature on invalid signature
     *
     * Emits GiveawayClaimed on successful claim
     */
    function claim(
        uint256 _id,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Creates a giveaway
     * @param _tokenId The tokenId to give away
     * @param _amount The amount to give away when the giveaway is claiemd
     * @param _totalClaims The total amount of claims to give away
     *
     * Reverts on non owner call
     *
     * Emits GiveawayCreated on successful creation
     */
    function createGiveaway(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _totalClaims
    ) external;

    /**
     * @notice Deletes a giveaway
     * @param _id The id of the giveaway to delete
     *
     * Reverts on non owner call
     * Throws GG_Giveaway_InvalidId on invalid id
     * Emits GiveawayDeleted on deletion
     */
    function deleteGiveaway(uint256 _id) external;

    /**
     * @notice Used to retrieve info regarding a giveaway
     * @param _id The id of the giveaway
     * @return _info Info struct regarding the giveaway
     *
     * Throws GG_Giveaway_InvalidId on invalid id
     */
    function getGiveawayInfo(uint256 _id) external view returns (GiveawayInfo memory _info);

    /**
     * @notice Used to check whether a user has already claimed a giveaway
     * @param _user The address of the user
     * @param _id The giveaway id
     *
     * Throws GG_Giveaway_InvalidId on invalid id
     */
    function canClaim(address _user, uint256 _id) external view returns (bool _canClaim);

    /**
     * @notice Used to set the address to Gravity Grade
     * @dev This contract has to be trusted by GravityGrade, see {IGravityGrade}
     * @param _gravityGrade The address to Gravity Grade
     *
     * Reverts on non owner call
     */
    function setGravityGrade(address _gravityGrade) external;

    /**
     * @notice Sets the signer for the claims
     * @param _signer The address of the signer
     *
     * Reverts on non owner call
     */
    function setSigner(address _signer) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/// @title Interface defining Gravity Grade
interface IGravityGrade is IERC1155Upgradeable {
    enum GravityGradeDrops {
        UNUSED,
        CargoDrop3,
        AnniversaryPackMystery,
        AnniversaryPackOutlier,
        AnniversaryPackCommon,
        AnniversaryPackUncommon,
        AnniversaryPackRare,
        AnniversaryPackLegendary,
        StarterPack
    }

    /**
    * @notice Event emitted when a sales state is mutated
    * @param saleId The id of the sale
    * @param isPaused Whether the sale is paused or not
    */
    event SaleState(uint256 saleId, bool isPaused);
    /**
    * @notice Event emitted when a sale is deleted
    * @param saleId The sale id
    */
    event SaleDeleted(uint256 saleId);
    /**
    * @notice Event emitted when a sales parameters are updated
    * @param saleId The sale id
    * @param tokenId The token id that is being sold
    * @param salePrice The price, denoted in the default currency
    * @param totalSupply The cap on the total amount of units to be sold
    * @param userCap The cap per user on units that can be purchased
    * @param defaultCurrency The default currency for the sale.
    */
    event SaleInfoUpdated(
        uint256 saleId,
        uint256 tokenId,
        uint256 salePrice,
        uint256 totalSupply,
        uint256 userCap,
        address defaultCurrency
    );
    /**
    * @notice Event emitted when the beneficiaries are updated
    * @param beneficiaries Array of beneficiary addresses
    * @param basisPoints Array of basis points for each beneficiary (by index)
    */
    event BeneficiariesUpdated(address[] beneficiaries, uint256[] basisPoints);
    /**
    * @notice Event emitted when payment currencies are added
    * @param saleId The sale id
    * @param currencyAddresses The addresses of the currencies that have been added
    */
    event PaymentCurrenciesSet(uint256 saleId, address[] currencyAddresses);
    /**
    * @notice Event emitted when payment currencies are removed
    * @param saleId The sale id
    * @param currencyAddresses The addresses of the currencies that have been removed
    */
    event PaymentCurrenciesRevoked(uint256 saleId, address[] currencyAddresses);

    // Used to classify token types in the ownership rebate struct
    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     * @notice Used to provide specifics for ownership based discounts
     * @param tokenType The type of token
     * @param tokenAddress The address of the token contract
     * @param tokenId The token id, ignored if ERC721 is provided for the token type
     * @param basisPoints The discount in basis points
     */
    struct OwnershipRebate {
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId; // ignored if ERC721
        uint256 basisPoints;
    }

    /**
     * @notice Used to output pack discount info
     * @param originalPrice The original pack price from calculating the salePrice * purchaseQuantity
     * @param discountedPrice The discounted pack price from calculating bulk purchases and rebates
     * @param purchaseQuantity The number of packs to purchase
     * @param tokenAddress The address of the token contract
     */
    struct Discounts {
        uint256 originalPrice;
        uint256 discountedPrice;
        uint256 purchaseQuantity;
        address tokenAddress;
    }

    /**
     * @notice Calculates the discount pack price
     * @param _saleId The sale ID to query the price against
     * @param _numPurchases The number of packs to query against
     * @param _currency Address of currency to use, address(0) for matic
     * @param _tokenAddress The token address for the token claimed to be held
     * @return Discounts The discount details for the pack
     */
    function calculateDiscountedPackPrice(
        uint256 _saleId,
        uint256 _numPurchases,
        address _currency,
        address _tokenAddress
    ) external returns (Discounts memory);

    /**
     * @notice Sets the TokenURI
     * @param _tokenId The tokenId to set for the URI
     * @param _uri The URI to set for the token
     */
    function setTokenUri(uint256 _tokenId, string memory _uri) external;

    /**
     * @notice Create new emissions/sales
     * @param _tokenId The ERC1155 tokenId to sell
     * @param _salePrice Price in US dollars
     * @param _totalSupplyAmountToSell Cap on total amount to be sold
     * @param _userCap A per-user cap
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     */
    function createNewSale(
        uint256 _tokenId,
        uint256 _salePrice,
        uint256 _totalSupplyAmountToSell,
        uint256 _userCap,
        address _defaultCurrency,
        bool _profitState
    ) external returns (uint256 saleId);

    /**
     * @notice Start and pause sales
     * @param _saleId The sale ID to set the status for
     * @param _paused The sale status
     */
    function setSaleState(uint256 _saleId, bool _paused) external;

    /**
     * @notice Modify sale
     * @param _saleId The sale ID to modify
     * @param _salePrice Price in US dollars
     * @param _totalSupplyAmountToSell Cap on total amount to be sold
     * @param _userCap A per-user cap
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     */
    function modifySale(
        uint256 _saleId,
        uint256 _salePrice,
        uint256 _totalSupplyAmountToSell,
        uint256 _userCap,
        address _defaultCurrency,
        bool _profitState
    ) external;

    /**
     * @notice Adds a bulk discount to a sale
     * @param _saleId The sale id
     * @param _breakpoint At what quantity the discount should be applied
     * @param _basisPoints The non cumulative discount in basis point
     */
    function addBulkDiscount(
        uint256 _saleId,
        uint256 _breakpoint,
        uint256 _basisPoints
    ) external;

    /**
     * @notice Adds a token ownership based discount to a sale
     * @param _saleId The sale id
     * @param _info Struct containing specifics regarding the discount
     */
    function addOwnershipDiscount(uint256 _saleId, OwnershipRebate calldata _info) external;

    /**
     * @notice Delete a sale
     * @param _saleId The sale ID to delete
     */
    function deleteSale(uint256 _saleId) external;

    /**
     * @notice Set the whitelist for allowed payment currencies on a per saleId basis
     * @param _saleId The sale ID to set
     * @param _currencyAddresses The addresses of permissible payment currencies
     */
    function setAllowedPaymentCurrencies(uint256 _saleId, address[] calldata _currencyAddresses)
    external;

    /**
     * @notice Set a swap manager to manage the means through which tokens are exchanged
     * @param _swapManager SwapManager address
     */
    function setSwapManager(address _swapManager) external;

    /**
     * @notice Set a oracle manager to manage the means through which token prices are fetched
     * @param _oracleManager OracleManager address
     */
    function setOracleManager(address _oracleManager) external;

    /**
     * @notice Set administrator
     * @param _moderatorAddress The addresse of an allowed admin
     */
    function setModerator(address _moderatorAddress) external;

    /**
     * @notice Adds a trusted party, which is allowed to mint tokens through the airdrop function
     * @param _trusted The address of the trusted party
     * @param _isTrusted Whether the party is trusted or not
     */
    function setTrusted(address _trusted, bool _isTrusted) external;

    /**
     * @notice Empty the treasury into the owners or an arbitrary wallet
     * @param _walletAddress The withdrawal EOA address
     * @param _currency ERC20 currency to withdraw, ZERO address implies MATIC
     */
    function withdraw(address _walletAddress, address _currency) external payable;

    /**
     * @notice  Set Fee Wallets and fee percentages from sales
     * @param _walletAddresses The withdrawal EOA addresses
     * @param _feeBps Represented as basis points e.g. 500 == 5 pct
     */
    function setFeeWalletsAndPercentages(
        address[] calldata _walletAddresses,
        uint256[] calldata _feeBps
    ) external;

    /**
     * @notice Purchase any active sale in any whitelisted currency
     * @param _saleId The sale ID of the pack to purchase
     * @param _numPurchases The number of packs to purchase
     * @param _tokenId The tokenId claimed to be owned (for rebates)
     * @param _tokenAddress The token address for the tokenId claimed to be owned (for rebates)
     * @param _currency Address of currency to use, address(0) for matic
     */
    function buyPacks(
        uint256 _saleId,
        uint256 _numPurchases,
        uint256 _tokenId,
        address _tokenAddress,
        address _currency
    ) external payable;

    /**
     * @notice Airdrop tokens to arbitrary wallets
     * @param _recipients The recipient addresses
     * @param _tokenIds The tokenIds to mint
     * @param _amounts The amount of tokens to mint
     */
    function airdrop(
        address[] calldata _recipients,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice used to burn tokens by trusted contracts
     * @param _from address to burn tokens from
     * @param _tokenId id of to-be-burnt tokens
     * @param _amount number of tokens to burn
     */
    function burn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
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
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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