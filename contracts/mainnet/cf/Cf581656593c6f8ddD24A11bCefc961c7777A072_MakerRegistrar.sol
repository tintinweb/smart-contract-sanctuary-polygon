//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../Permissions/IRoleManager.sol";
import "./IMakerRegistrar.sol";
import "./MakerRegistrarStorage.sol";
import "./NftOwnership.sol";
import "../Royalties/Royalties.sol";

/// @title MakerRegistrar
/// @dev This contract tracks registered NFTs.  Owners of an NFT can register
/// and deregister any NFTs owned in their wallet.
/// Also, for the mappings, it is assumed the protocol will always look up the current owner of
/// an NFT when running logic (which is why the owner address is not stored).  If desired, an
/// off-chain indexer like The Graph can index registration addresses to NFTs.
contract MakerRegistrar is Initializable, MakerRegistrarStorageV1 {
    /// @dev Event triggered when an NFT is registered in the system
    event Registered(
        uint256 nftChainId,
        address indexed nftContractAddress,
        uint256 indexed nftId,
        address indexed nftOwnerAddress,
        address[] nftCreatorAddresses,
        uint256[] creatorSaleBasisPoints,
        uint256 optionBits,
        uint256 sourceId,
        uint256 transformId,
        string ipfsMetadataHash
    );

    /// @dev Event triggered when an NFT is deregistered from the system
    event Deregistered(
        uint256 nftChainId,
        address indexed nftContractAddress,
        uint256 indexed nftId,
        address indexed nftOwnerAddress,
        uint256 sourceId
    );

    /// @dev initializer to call after deployment, can only be called once
    function initialize(IAddressManager _addressManager) public initializer {
        addressManager = _addressManager;
    }

    function deriveSourceId(
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId
    ) external pure returns (uint256) {
        return _deriveSourceId(chainId, nftContractAddress, nftId);
    }

    function _deriveSourceId(
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId
    ) internal pure returns (uint256) {
        return
            uint256(keccak256(abi.encode(chainId, nftContractAddress, nftId)));
    }

    /// @dev For the specified NFT, verify it is owned by the potential owner
    function verifyOwnership(
        address nftContractAddress,
        uint256 nftId,
        address potentialOwner
    ) public view returns (bool) {
        return
            NftOwnership._verifyOwnership(
                nftContractAddress,
                nftId,
                potentialOwner
            );
    }

    /// @dev Allows a NFT owner to register the NFT in the protocol so that reactions can be sold.
    /// Owner registering must own the NFT in the wallet calling function.
    function registerNft(
        address nftContractAddress,
        uint256 nftId,
        address creatorAddress,
        uint256 creatorSaleBasisPoints,
        uint256 optionBits,
        string calldata ipfsMetadataHash
    ) external {
        // Verify ownership
        require(
            verifyOwnership(nftContractAddress, nftId, msg.sender),
            "NFT not owned"
        );

        // Get the royalties for the creator addresses - use fallback if none set on chain
        (
            address[] memory addressesArray,
            uint256[] memory creatorBasisPointsArray
        ) = Royalties._getRoyaltyOverride(
                addressManager.royaltyRegistry(),
                nftContractAddress,
                nftId,
                creatorAddress,
                creatorSaleBasisPoints
            );

        _registerForOwner(
            msg.sender,
            block.chainid, // Use current chain ID
            nftContractAddress,
            nftId,
            addressesArray,
            creatorBasisPointsArray,
            optionBits,
            ipfsMetadataHash
        );
    }

    function registerNftFromBridge(
        address owner,
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId,
        address[] memory creatorAddresses,
        uint256[] memory creatorSaleBasisPoints,
        uint256 optionBits,
        string calldata ipfsMetadataHash
    ) external {
        // Verify caller is Child Registrar from the bridge
        require(msg.sender == addressManager.childRegistrar(), "Not Bridge");

        _registerForOwner(
            owner,
            chainId,
            nftContractAddress,
            nftId,
            creatorAddresses,
            creatorSaleBasisPoints,
            optionBits,
            ipfsMetadataHash
        );
    }

    /// @dev Register an NFT from an owner
    /// @param owner - The current owner of the NFT - should be verified before calling
    /// @param chainId - Chain where NFT lives
    /// @param nftContractAddress - Address of NFT to be registered
    /// @param nftId - ID of NFT to be registered
    /// @param creatorAddresses - (optional) Address of the creator to give creatorSaleBasisPoints cut of Maker rewards
    /// @param creatorSaleBasisPoints (optional) Basis points for the creator during a reaction sale
    ///        This is the percentage of the Maker rewards to give to the Creator
    ///        Basis points are percentage divided by 100 (e.g. 100 Basis Points is 1%)
    /// @param optionBits - (optional) Params to allow owner to specify options or transformations
    ///        performed during registration
    function _registerForOwner(
        address owner,
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId,
        address[] memory creatorAddresses,
        uint256[] memory creatorSaleBasisPoints,
        uint256 optionBits,
        string calldata ipfsMetadataHash
    ) internal {
        //
        // "Source" - external NFT's
        // sourceId is derived from [chainId, nftContractAddress, nftId]`
        // Uses:
        // - ReactionVault.buyReaction():
        //    - check that sourceId is registered == true
        //    - calc creator rewards for makerNFTs
        // - ReactionVault.withdrawTakerRewards():
        //    - check that sourceId is registered == true
        //    - check msg.sender is registered as owner
        //    - calc creator rewards for takerNFTs
        //
        // Generate source ID
        uint256 sourceId = _deriveSourceId(chainId, nftContractAddress, nftId);

        // add to mapping
        sourceToDetails[sourceId] = NftDetails(
            true,
            owner,
            creatorAddresses,
            creatorSaleBasisPoints
        );

        //
        // "Transform": source NFTs that have been "transformed" into fan art via optionBits param
        // ID: derived from [MAKER_META_PREFIX, registrationSourceId, optionBits]
        // Uses:
        // ReactionVault._buyReaction()
        //  - look up source to make sure its registered
        //  - used to derive reactionMetaId

        // Generate reaction ID
        uint256 transformId = uint256(
            keccak256(abi.encode(MAKER_META_PREFIX, sourceId, optionBits))
        );
        // add to mapping
        transformToSourceLookup[transformId] = sourceId;

        // Emit event
        emit Registered(
            chainId,
            nftContractAddress,
            nftId,
            owner,
            creatorAddresses,
            creatorSaleBasisPoints,
            optionBits,
            sourceId,
            transformId,
            ipfsMetadataHash
        );
    }

    /// @dev Allow an NFT owner to deregister and remove capability for reactions to be sold.
    /// Caller must currently own the NFT being deregistered
    function deregisterNft(address nftContractAddress, uint256 nftId) external {
        // Verify ownership
        require(
            verifyOwnership(nftContractAddress, nftId, msg.sender),
            "NFT not owned"
        );

        _deregisterNftForOwner(
            msg.sender,
            block.chainid,
            nftContractAddress,
            nftId
        );
    }

    function deRegisterNftFromBridge(
        address owner,
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId
    ) external {
        // Verify caller is Child Registrar from the bridge
        require(msg.sender == addressManager.childRegistrar(), "Not Bridge");

        _deregisterNftForOwner(owner, chainId, nftContractAddress, nftId);
    }

    function _deregisterNftForOwner(
        address owner,
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId
    ) internal {
        // generate source ID
        uint256 sourceId = _deriveSourceId(chainId, nftContractAddress, nftId);

        // Verify it is registered
        NftDetails storage details = sourceToDetails[sourceId];
        require(details.registered, "NFT not registered");

        // Update the param
        details.registered = false;

        emit Deregistered(chainId, nftContractAddress, nftId, owner, sourceId);
    }

    function sourceToDetailsLookup(uint256 index)
        external
        view
        returns (NftDetails memory)
    {
        return sourceToDetails[index];
    }
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

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IRoleManager {
    /// @dev Determines if the specified address has capability to mint and burn reaction NFTs
    /// @param potentialAddress Address to check
    function isAdmin(address potentialAddress) external view returns (bool);

    /// @dev Determines if the specified address has permission to udpate addresses in the protocol
    /// @param potentialAddress Address to check
    function isAddressManagerAdmin(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to update parameters in the protocol
    /// @param potentialAddress Address to check
    function isParameterManagerAdmin(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to to mint and burn reaction NFTs
    /// @param potentialAddress Address to check
    function isReactionNftAdmin(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to purchase curator vault tokens
    /// @param potentialAddress Address to check
    function isCuratorVaultPurchaser(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to mint and burn curator tokens
    /// @param potentialAddress Address to check
    function isCuratorTokenAdmin(address potentialAddress)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @dev Interface for the maker registrar that supports registering and de-registering NFTs
interface IMakerRegistrar {
    /// @dev struct for storing details about a registered NFT
    struct NftDetails {
        bool registered;
        address owner;
        address[] creators;
        uint256[] creatorSaleBasisPoints;
    }

    function transformToSourceLookup(uint256 metaId) external returns (uint256);

    function deriveSourceId(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId
    ) external returns (uint256);

    /// @dev lookup for NftDetails from source ID
    function sourceToDetailsLookup(uint256)
        external
        returns (NftDetails memory);

    function verifyOwnership(
        address nftContractAddress,
        uint256 nftId,
        address potentialOwner
    ) external returns (bool);

    function registerNftFromBridge(
        address owner,
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId,
        address[] memory nftCreatorAddresses,
        uint256[] memory creatorSaleBasisPoints,
        uint256 optionBits,
        string memory ipfsMetadataHash
    ) external;

    function deRegisterNftFromBridge(
        address owner,
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId
    ) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../Config/IAddressManager.sol";
import "./IMakerRegistrar.sol";

/// @title MakerRegistrarStorage
/// @dev This contract will hold all local variables for the MakerRegistrar Contract
/// When upgrading the protocol, inherit from this contract on the V2 version and change the
/// MakerRegistrar to inherit from the later version.  This ensures there are no storage layout
/// corruptions when upgrading.
abstract contract MakerRegistrarStorageV1 is IMakerRegistrar {
    /// @dev local reference to the address manager contract
    IAddressManager public addressManager;

    /// @dev prefix used in meta ID generation
    string public constant MAKER_META_PREFIX = "MAKER";

    /// @dev Mapping to look up source ID from meta ID key
    mapping(uint256 => uint256) public override transformToSourceLookup;

    /// @dev Mapping to look up nft details from source ID
    mapping(uint256 => IMakerRegistrar.NftDetails) public sourceToDetails;
}

/// On the next version of the protocol, if new variables are added, put them in the below
/// contract and use this as the inheritance chain.
/**
contract MakerRegistrarStorageV2 is MakerRegistrarStorageV1 {
  address newVariable;
}
 */

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IPunk {
    function punkIndexToAddress(uint256 index) external view returns (address);
}

/// @dev This is a library for other contracts to use that need to verify ownership of an NFT on the current chain.
/// Since this only has internal functions, it will be inlined into the calling contract at
/// compile time and does not need to be separately deployed on chain.
library NftOwnership {
    /// @dev For the specified NFT, verify it is owned by the potential owner
    function _verifyOwnership(
        address nftContractAddress,
        uint256 nftId,
        address potentialOwner
    ) internal view returns (bool) {
        // Try ERC1155
        try
            IERC1155Upgradeable(nftContractAddress).balanceOf(
                potentialOwner,
                nftId
            )
        returns (uint256 balance) {
            return balance > 0;
        } catch {
            // Ignore error
        }

        // Try ERC721
        try IERC721Upgradeable(nftContractAddress).ownerOf(nftId) returns (
            address foundOwner
        ) {
            return foundOwner == potentialOwner;
        } catch {
            // Ignore error
        }

        // Try CryptoPunk
        try IPunk(nftContractAddress).punkIndexToAddress(nftId) returns (
            address foundOwner
        ) {
            return foundOwner == potentialOwner;
        } catch {
            // Ignore error
        }

        return false;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyEngineV1.sol";

/// @dev This library uses the Royalty Registry to see if royalties are configured for a specified NFT.
/// The Royalty Registry looks at a number of sources to see if the original creator set a royalty
/// configurationon the contract, such as EIP-2981, Manifold, Rarible, etc.
/// See https://royaltyregistry.xyz/ for more details and deployed addresses.
/// The output will be a list of addresses and a value that each should receive.
library Royalties {
    /// @dev Validate royalties addresses and amounts arrays
    function _validateRoyalties(
        address payable[] memory recipients,
        uint256[] memory amounts
    ) internal pure returns (bool) {
        // Verify royalties were found
        if (recipients.length == 0) {
            return false;
        }

        // Verify array lengths match
        if (recipients.length != amounts.length) {
            return false;
        }

        // Calculate the total rewards BP
        uint256 totalRewardsBp = 0;

        // Verify valid addresses and amounts
        for (uint8 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0x0)) {
                return false;
            }

            if (amounts[i] == 0 || amounts[i] > 10_000) {
                return false;
            }

            totalRewardsBp += amounts[i];
        }

        // Total rewards across all addresses should not be above 100%
        if (totalRewardsBp > 10_000) {
            return false;
        }

        // No issues found, use them
        return true;
    }

    /// @dev Gets the royalties for a specified NFT and uses the fallback values if none are found
    /// A sale price of 10,000 will be used as the value to query since the protocol uses basis points
    /// to track a percentage of value to send to the creators.  (10k basis points = 100%)
    function _getRoyaltyOverride(
        address royaltyRegistry,
        address nftContractAddress,
        uint256 nftId,
        address fallbackCreator,
        uint256 fallbackCreatorBasisPoints
    )
        internal
        view
        returns (
            address[] memory creators,
            uint256[] memory creatorSaleBasisPoints
        )
    {
        // Query the royalty registry
        if (royaltyRegistry != address(0x0)) {
            // Use 10k to get back basis points
            try
                IRoyaltyEngineV1(royaltyRegistry).getRoyaltyView(
                    nftContractAddress,
                    nftId,
                    10_000
                )
            returns (
                address payable[] memory recipients,
                uint256[] memory amounts
            ) {
                // Check to see if valid results were found
                if (_validateRoyalties(recipients, amounts)) {
                    // Convert to non-payable
                    // https://github.com/ethereum/solidity/issues/5462
                    address[] memory convertedAddresses = new address[](
                        recipients.length
                    );
                    for (uint8 i = 0; i < recipients.length; i++) {
                        convertedAddresses[i] = recipients[i];
                    }

                    // Use the valid royalties
                    return (convertedAddresses, amounts);
                }
            } catch {
                // Ignore an errors
            }
        }
        // None found, use fallback address... address 0x0 means no creator rewards
        address[] memory addressesArray = new address[](1);
        addressesArray[0] = fallbackCreator;

        // Use fallback value, and ensure it is not above 100%
        require(fallbackCreatorBasisPoints <= 10_000, "Invalid bp");
        uint256[] memory creatorBasisPointsArray = new uint256[](1);
        creatorBasisPointsArray[0] = fallbackCreatorBasisPoints;

        return (addressesArray, creatorBasisPointsArray);
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

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../Permissions/IRoleManager.sol";
import "../Parameters/IParameterManager.sol";
import "../Maker/IMakerRegistrar.sol";
import "../Token/IStandard1155.sol";
import "../Reactions/IReactionVault.sol";
import "../CuratorVault/ICuratorVault.sol";

interface IAddressManager {
    /// @dev Getter for the role manager address
    function roleManager() external returns (IRoleManager);

    /// @dev Setter for the role manager address
    function setRoleManager(IRoleManager _roleManager) external;

    /// @dev Getter for the role manager address
    function parameterManager() external returns (IParameterManager);

    /// @dev Setter for the role manager address
    function setParameterManager(IParameterManager _parameterManager) external;

    /// @dev Getter for the maker registrar address
    function makerRegistrar() external returns (IMakerRegistrar);

    /// @dev Setter for the maker registrar address
    function setMakerRegistrar(IMakerRegistrar _makerRegistrar) external;

    /// @dev Getter for the reaction NFT contract address
    function reactionNftContract() external returns (IStandard1155);

    /// @dev Setter for the reaction NFT contract address
    function setReactionNftContract(IStandard1155 _reactionNftContract)
        external;

    /// @dev Getter for the default Curator Vault contract address
    function defaultCuratorVault() external returns (ICuratorVault);

    /// @dev Setter for the default Curator Vault contract address
    function setDefaultCuratorVault(ICuratorVault _defaultCuratorVault)
        external;

    /// @dev Getter for the L2 bridge registrar
    function childRegistrar() external returns (address);

    /// @dev Setter for the L2 bridge registrar
    function setChildRegistrar(address _childRegistrar) external;

    /// @dev Getter for the address of the royalty registry
    function royaltyRegistry() external returns (address);

    /// @dev Setter for the address of the royalty registry
    function setRoyaltyRegistry(address _royaltyRegistry) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../Permissions/IRoleManager.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IParameterManager {
    /// @dev Getter for the payment token
    function paymentToken() external returns (IERC20Upgradeable);

    /// @dev Setter for the payment token
    function setPaymentToken(IERC20Upgradeable _paymentToken) external;

    /// @dev Getter for the reaction price
    function reactionPrice() external returns (uint256);

    /// @dev Setter for the reaction price
    function setReactionPrice(uint256 _reactionPrice) external;

    /// @dev Getter for the cut of purchase price going to the curator liability
    function saleCuratorLiabilityBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of purchase price going to the curator liability
    function setSaleCuratorLiabilityBasisPoints(
        uint256 _saleCuratorLiabilityBasisPoints
    ) external;

    /// @dev Getter for the cut of purchase price going to the referrer
    function saleReferrerBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of purchase price going to the referrer
    function setSaleReferrerBasisPoints(uint256 _saleReferrerBasisPoints)
        external;

    /// @dev Getter for the cut of spend curator liability going to the taker
    function spendTakerBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of spend curator liability going to the taker
    function setSpendTakerBasisPoints(uint256 _spendTakerBasisPoints) external;

    /// @dev Getter for the cut of spend curator liability going to the taker
    function spendReferrerBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of spend curator liability going to the referrer
    function setSpendReferrerBasisPoints(uint256 _spendReferrerBasisPoints)
        external;

    /// @dev Getter for the check to see if a curator vault is allowed to be used
    function approvedCuratorVaults(address potentialVault)
        external
        returns (bool);

    /// @dev Setter for the list of curator vaults allowed to be used
    function setApprovedCuratorVaults(address vault, bool approved) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @dev Interface for the Standard1155 toke contract.
interface IStandard1155 {
    /// @dev Allows a priviledged account to mint tokens to the specified address
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @dev Interface for the ReactionVault that supports buying and spending reactions
interface IReactionVault {
    struct ReactionPriceDetails {
        IERC20Upgradeable paymentToken;
        uint256 reactionPrice;
        uint256 saleCuratorLiabilityBasisPoints;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../Token/IStandard1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @dev Interface for the curator vault
interface ICuratorVault {
    function getTokenId(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IERC20Upgradeable paymentToken
    ) external returns (uint256);

    function buyCuratorTokens(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IERC20Upgradeable paymentToken,
        uint256 paymentAmount,
        address mintToAddress,
        bool isTakerPosition
    ) external returns (uint256);

    function sellCuratorTokens(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IERC20Upgradeable paymentToken,
        uint256 tokensToBurn,
        address refundToAddress
    ) external returns (uint256);

    function curatorTokens() external returns (IStandard1155);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external returns(address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) external view returns(address payable[] memory recipients, uint256[] memory amounts);
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