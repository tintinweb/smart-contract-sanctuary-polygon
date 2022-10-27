// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ERC1155NonTransferableBurnableUpgradeable.sol";

interface ICommunityRegistry {
    function doesCommunityExist(string memory uniqId) external view returns (bool);
    function communityIdToAdminOneIndexIndices(string memory uniqId, address admin) external view returns (uint256);
}

contract KudosV7 is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC1155NonTransferableBurnableUpgradeable
{
    ////////////////////////////////// CONSTANTS //////////////////////////////////
    /// @notice The name of this contract
    string public constant CONTRACT_NAME = "Kudos";

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 private constant DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the Kudos input struct used by the contract
    bytes32 public constant KUDOS_TYPE_HASH =
        keccak256(
            "Kudos(string headline,string description,uint256 startDateTimestamp,uint256 endDateTimestamp,string[] links,string communityUniqId,bool isSignatureRequired,bool isAllowlistRequired,int256 totalClaimCount,uint256 expirationTimestamp)"
        );

    /// @notice The EIP-712 typehash for the claiming flow by the contract
    bytes32 public constant CLAIM_TYPE_HASH =
        keccak256("Claim(uint256 tokenId)");
    
    /// @notice The EIP-712 typehash for adding new allowlisted addresses to an existing Kudos token
    bytes32 public constant ADD_ALLOWLISTED_ADDRESSES_TYPE_HASH = keccak256("AllowlistedAddress(uint256 tokenId)");

    /// @notice The EIP-712 typehash for burning
    bytes32 public constant BURN_TYPE_HASH =
        keccak256("Burn(uint256 tokenId)");

    /// @notice The EIP-712 typehash for the admin to trigger an airdrop
    bytes32 public constant COMMUNITY_ADMIN_AIRDROP_TYPE_HASH =
        keccak256("CommunityAdminAirdrop(uint256 tokenId)");

    /// @notice The EIP-712 typehash for receiver to consent to an admin airdropping the token
    bytes32 public constant COMMUNITY_ADMIN_AIRDROP_RECEIVER_CONSENT_TYPE_HASH =
        keccak256("CommunityAdminAirdropReceiverConsent(uint256 tokenId)");

    ////////////////////////////////// STRUCTS //////////////////////////////////
    /// @dev Struct used to contain the Kudos metadata input
    ///      Also, note that using structs in mappings should be safe:
    ///      https://forum.openzeppelin.com/t/how-to-use-a-struct-in-an-upgradable-contract/832/4
    struct KudosInputContainer {
        string headline;
        string description;
        uint256 startDateTimestamp;
        uint256 endDateTimestamp;
        string[] links;
        string communityUniqId;
        string customAttributes;

        KudosContributorsInputContainer contributorMerkleRoots;
        KudosClaimabilityAttributesInputContainer claimabilityAttributes;
    }

    /// @dev Struct used to contain the full Kudos metadata at the time of mint
    ///      Order of these variables should not be changed
    struct KudosContainer {
        string headline;
        string description;
        uint256 startDateTimestamp;
        uint256 endDateTimestamp;
        string[] links;
        string DEPRECATED_communityDiscordId;    // don't use this value anymore
        string DEPRECATED_communityName;         // don't use this value anymore
        address creator;
        uint256 registeredTimestamp;
        string communityUniqId;

        KudosClaimabilityAttributesContainer claimabilityAttributes;

        string customAttributes; // stringified JSON value that stores any other custom attributes
    }

    struct KudosClaimabilityAttributesInputContainer {
        bool isSignatureRequired;
        bool isAllowlistRequired;

        int256 totalClaimCount; // -1 indicates infinite
        uint256 expirationTimestamp; // 0 indicates no expiration
    }

    struct KudosClaimabilityAttributesContainer {
        bool isSignatureRequired;
        bool isAllowlistRequired;

        int256 totalClaimCount; // -1 indicates infinite
        uint256 remainingClaimCount; // if totalClaimCount = -1 then irrelevant
        uint256 expirationTimestamp; // 0 indicates no expiration
    }

    /// @dev Struct used to contain string and address Kudos contributors
    struct KudosContributorsInputContainer {
        bytes32 stringContributorsMerkleRoot;
        bytes32 addressContributorsMerkleRoot;
    }

    /// @dev Struct used to contain merkle tree roots of string and address contributors.
    ///      Note that the actual list of contributors is left DEPRECATED in order to not change the
    ///      existing data when upgrading.
    struct KudosContributorsContainer {
        string[] DEPRECATED_stringContributors;
        address[] DEPRECATED_addressContributors;
        bytes32 stringContributorsMerkleRoot;
        bytes32 addressContributorsMerkleRoot;
    }

    /// @dev Struct used by community admins to airdrop Kudos
    struct CommunityAdminAirdropInputContainer {
        address adminAddress;
        uint8 admin_v;
        bytes32 admin_r;
        bytes32 admin_s;
    }

    struct CommunityAdminAirdropConsentInputContainer {
        address receivingAddress;
        uint8 receiver_v;
        bytes32 receiver_r;
        bytes32 receiver_s;
    }

    /// @dev This event is solely so that we can easily track which creator registered
    ///      which Kudos tokens without having to store the mapping on-chain.
    event RegisteredKudos(address creator, uint256 tokenId);

    ////////////////////////////////// VARIABLES //////////////////////////////////
    /// @dev This has been deprecated to allow for mapping tokens to both string and address contributors.
    mapping(uint256 => address[]) public DEPRECATED_tokenIdToContributors;

    mapping(uint256 => KudosContainer) public tokenIdToKudosContainer;

    /// @notice This value signifies the largest tokenId value that has not been used yet.
    /// Whenever we register a new token, we increment this value by one, so essentially the tokenID
    /// signifies the total number of types of tokens registered through this contract.
    uint256 public latestUnusedTokenId;

    /// @notice the address pointing to the community registry
    address public communityRegistryAddress;

    /// @dev Mapping from tokens to string and address Kudos contributors
    mapping(uint256 => KudosContributorsContainer) private tokenIdToContributors;

    ////////////////////////////////// CODE //////////////////////////////////
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(uint256 _latestUnusedTokenId) public initializer {
        __ERC1155_init("https://api.mintkudos.xyz/metadata/{id}");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Supply_init();

        // We start with some passed-in latest unused token ID
        if (_latestUnusedTokenId > 0) {
            latestUnusedTokenId = _latestUnusedTokenId;
        } else {
            latestUnusedTokenId = 1;
        }

        // Start off the contract as paused
        _pause();
    }

    /// @notice Allows owner to set new URI that contains token metadata
    /// @param newuri               The Kudos creator's address
    function setURI(string memory newuri) public onlyOwner whenNotPaused {
        _setURI(newuri);
    }

    /// @notice Setting the latest unused token ID value so we can start the next token mint from a different ID.
    /// @param _latestUnusedTokenId  The latest unused token ID that should be set in the contract
    function setLatestUnusedTokenId(uint256 _latestUnusedTokenId) public onlyOwner whenPaused {
        latestUnusedTokenId = _latestUnusedTokenId;
    }

    /// @notice Setting the contract address of the community registry
    /// @param _communityRegistryAddress The community registry address
    function setCommunityRegistryAddress(address _communityRegistryAddress) public onlyOwner {
        communityRegistryAddress = _communityRegistryAddress;
    }

    /// @notice Register new Kudos token type for contributors to claim AND airdrop that token to an initial address
    /// @dev Note that because we are using signed messages, if the Kudos input data is not the same as what it was at the time of user signing, the
    ///      function call with fail. This ensures that whatever the user signs is what will get minted, and that we as the admins cannot tamper with
    ///      the content of a Kudos.
    /// @param creator              The Kudos creator's address
    /// @param receiver             The Kudos receiver's address for airdrop
    /// @param metadata             Metadata of the Kudos token
    /// @param v                    Part of the creator's signature (v)
    /// @param r                    Part of the creator's signature (r)
    /// @param s                    Part of the creator's signature (s)
    function registerBySigAndAirdrop(
        address creator,
        address receiver,
        KudosInputContainer memory metadata,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOwner whenNotPaused {
        uint256 newTokenId = latestUnusedTokenId;
        registerBySig(creator, metadata, v, r, s);
        _claim(newTokenId, receiver);
    }

    /// @notice Register new Kudos token type for contributors to claim.
    /// @dev This just allowlists the tokens that are able to claim this particular token type, but it does not necessarily mint the token until later.
    ///      Note that because we are using signed messages, if the Kudos input data is not the same as what it was at the time of user signing, the
    ///      function call with fail. This ensures that whatever the user signs is what will get minted, and that we as the admins cannot tamper with
    ///      the content of a Kudos.
    /// @param creator              The Kudos creator's address
    /// @param metadata             Metadata of the Kudos token
    /// @param v                    Part of the creator's signature (v)
    /// @param r                    Part of the creator's signature (r)
    /// @param s                    Part of the creator's signature (s)
    function registerBySig(
        address creator,
        KudosInputContainer memory metadata,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOwner whenNotPaused {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                keccak256(bytes(CONTRACT_NAME)),
                block.chainid,
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                KUDOS_TYPE_HASH,
                keccak256(bytes(metadata.headline)),
                keccak256(bytes(metadata.description)),
                metadata.startDateTimestamp,
                metadata.endDateTimestamp,
                convertStringArraytoByte32(metadata.links),
                keccak256(bytes(metadata.communityUniqId)),
                metadata.claimabilityAttributes.isSignatureRequired,
                metadata.claimabilityAttributes.isAllowlistRequired,
                metadata.claimabilityAttributes.totalClaimCount,
                metadata.claimabilityAttributes.expirationTimestamp
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == creator, "invalid signature");

        _register(signatory, metadata);
    }

    function _register(
        address creator,
        KudosInputContainer memory metadata
    ) internal {
        // Note that we currently don't have an easy way to de-duplicate Kudos tokens.
        // Because we are the only ones that can mint Kudos for now (since we're covering the cost),
        // we will gate duplicated tokens in the caller side.
        // However, once we open this up to the public (if the public wants to pay for their own Kudos at some point),
        // we may need to come up with some validation routine here to prevent the "same" Kudos from being minted.

        // Translate the Kudos input container to the actual container
        require(ICommunityRegistry(communityRegistryAddress).doesCommunityExist(metadata.communityUniqId), "uniqId does not exist in registry");

        KudosContainer memory kc;
        kc.creator = creator;
        kc.headline = metadata.headline;
        kc.description = metadata.description;
        kc.startDateTimestamp = metadata.startDateTimestamp;
        kc.endDateTimestamp = metadata.endDateTimestamp;
        kc.links = metadata.links;
        kc.communityUniqId = metadata.communityUniqId;
        kc.customAttributes = metadata.customAttributes;
        kc.registeredTimestamp = block.timestamp;

        kc.claimabilityAttributes.isSignatureRequired = metadata.claimabilityAttributes.isSignatureRequired;
        kc.claimabilityAttributes.isAllowlistRequired = metadata.claimabilityAttributes.isAllowlistRequired;

        // Register the contributor merkle roots for the allowlist
        // This is used later in the claim flow to see if an address can actually claim the token or not.
        if (kc.claimabilityAttributes.isAllowlistRequired) {
            tokenIdToContributors[latestUnusedTokenId].addressContributorsMerkleRoot = metadata.contributorMerkleRoots.addressContributorsMerkleRoot;
            tokenIdToContributors[latestUnusedTokenId].stringContributorsMerkleRoot = metadata.contributorMerkleRoots.stringContributorsMerkleRoot;

            require(metadata.claimabilityAttributes.totalClaimCount == 0, "Total claim count should not be set if allowlist is required");
        }

        kc.claimabilityAttributes.totalClaimCount = metadata.claimabilityAttributes.totalClaimCount;
        if (kc.claimabilityAttributes.totalClaimCount > 0) {
            kc.claimabilityAttributes.remainingClaimCount = uint256(kc.claimabilityAttributes.totalClaimCount);
        }
        kc.claimabilityAttributes.expirationTimestamp = metadata.claimabilityAttributes.expirationTimestamp;

        // Store the metadata into a mapping for viewing later
        tokenIdToKudosContainer[latestUnusedTokenId] = kc;

        emit RegisteredKudos(creator, latestUnusedTokenId);

        // increment the latest unused TokenId because we now have an additionally registered
        // token.
        latestUnusedTokenId++;
    }

    /// @notice Only for community admins - Mints a Kudos to any consenting address
    /// @dev    It's important to note here that this endpoint is potentially vulnerable --
    ///         because the admin signature's content is only the token ID, one can look on-chain
    ///         and obtain the admin signature for a particular token, and then call this endpoint
    ///         with their own "consenting" signature to maliciously obtain a token.
    ///         This is only the case if the function is open to anyone and not locked down by role,
    ///         so for the time being we don't need to worry about it. However, it's worth noting
    ///         as we make the contract more accessible outside of going through our API.
    /// @param id                                Token ID
    /// @param adminInput                        Container with the admin's consent info
    /// @param consentInput                      Container with the receiver's consent info
    /// @param updateContributorMerkleRoots      Flag to determine whether we should update the contributor merkle roots
    /// @param contributorMerkleRoots            New contributor merkle roots
    /// @param merkleProof                       Merkle proof for the particular claiming address
    function communityAdminAirdrop(
        uint256 id,
        CommunityAdminAirdropInputContainer memory adminInput,
        CommunityAdminAirdropConsentInputContainer memory consentInput,
        bool updateContributorMerkleRoots,
        KudosContributorsInputContainer memory contributorMerkleRoots,
        bytes32[] calldata merkleProof
    ) public onlyOwner whenNotPaused {
        _validateCommunityAdminAirdropAdminSig(
            id,
            adminInput.adminAddress,
            adminInput.admin_v,
            adminInput.admin_r,
            adminInput.admin_s
        );

        _validateCommunityAdminAirdropReceiverSig(
            id,
            consentInput.receivingAddress,
            consentInput.receiver_v,
            consentInput.receiver_r,
            consentInput.receiver_s
        );

        _claimCommunityAdminAirdrop(
            id,
            consentInput.receivingAddress,
            updateContributorMerkleRoots,
            contributorMerkleRoots,
            merkleProof
        );
    }

    /// @notice Only for community admins - Mints a Kudos to ANY address
    /// @dev    All the concerns of the above communityAdminAirdrop function apply, with
    ///         the additional issue that this function does not require a signature from
    ///         the recipient address - community admins can use this function to mint a
    ///         Kudos to ANY address. This is intended for special cases where the regular
    ///         communityAdminAirdrop function won't work - migrations, situations where
    ///         the end user can't/won't collect consent signatures for recipients, etc.
    /// @param id                                Token ID
    /// @param adminInput                        Container with the admin's consent info
    /// @param receivingAddress                  Address to mint the Kudos to
    /// @param updateContributorMerkleRoots      Flag to determine whether we should update the contributor merkle roots
    /// @param contributorMerkleRoots            New contributor merkle roots
    /// @param merkleProof                       Merkle proof for the particular claiming address
    function communityAdminAirdropWithoutConsentSig(
        uint256 id,
        CommunityAdminAirdropInputContainer memory adminInput,
        address receivingAddress,
        bool updateContributorMerkleRoots,
        KudosContributorsInputContainer memory contributorMerkleRoots,
        bytes32[] calldata merkleProof
    ) public onlyOwner whenNotPaused {
        _validateCommunityAdminAirdropAdminSig(
            id,
            adminInput.adminAddress,
            adminInput.admin_v,
            adminInput.admin_r,
            adminInput.admin_s
        );

        _claimCommunityAdminAirdrop(
            id,
            receivingAddress,
            updateContributorMerkleRoots,
            contributorMerkleRoots,
            merkleProof
        );
    }

    /// @notice Burns ALL of an assigned token for the specified address
    /// @param id                  ID of the Token
    /// @param burningAddress      Burning address
    /// @param v                   Part of the burnee's signature (v)
    /// @param r                   Part of the burnee's signature (r)
    /// @param s                   Part of the burnee's signature (s)
    function burn(
        uint256 id,
        address burningAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOwner whenNotPaused {
        uint256 balance;
        balance = balanceOf(burningAddress, id);

        require(tokenIdToKudosContainer[id].creator != address(0), "token does not exist");
        require(balance > 0, "cannot burn unowned token");

        bytes32 burnHash = keccak256(abi.encode(BURN_TYPE_HASH, id));
        _validateSignature(burnHash, burningAddress, v, r, s);

        _burn(burningAddress, id, balance);
    }

    /// @notice Mints a token for the specified address if allowlisted
    /// @param id                  ID of the Token
    /// @param claimingAddress     Claiming address
    /// @param v                   Part of the claimee's signature (v)
    /// @param r                   Part of the claimee's signature (r)
    /// @param s                   Part of the claimee's signature (s)
    /// @param merkleProof         Merkle proof for the particular claiming address
    function claim(
        uint256 id,
        address claimingAddress,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32[] calldata merkleProof
    ) public onlyOwner whenNotPaused {
        _validateClaimability(id, claimingAddress, v, r, s);

        if (tokenIdToKudosContainer[id].claimabilityAttributes.isAllowlistRequired) {
            require(
                MerkleProofUpgradeable.verify(
                    merkleProof,
                    tokenIdToContributors[id].addressContributorsMerkleRoot,
                    generateAddressMerkleLeaf(claimingAddress)
                ),
                "address not allowlisted"
            );
        }

        _claim(id, claimingAddress);
    }
    
    /// @notice Mints a token for the specified address if allowlisted without signature 
    ///         verification that the string contributor is owned by the claimee address. 
    ///         The integrity will be checked off-chain.
    /// @param id                  ID of the Token
    /// @param claimingAddress     Claiming address
    /// @param v                   Part of the claimee's signature (v)
    /// @param r                   Part of the claimee's signature (r)
    /// @param s                   Part of the claimee's signature (s)
    /// @param contributor         String ID of the contributor that should claim this token
    /// @param merkleProof         Merkle proof for the particular claiming address
    function unsafeClaim(
        uint256 id,
        address claimingAddress,
        uint8 v,
        bytes32 r,
        bytes32 s,
        string memory contributor,
        bytes32[] calldata merkleProof
    ) public onlyOwner whenNotPaused {
        _validateClaimability(id, claimingAddress, v, r, s);
    
        if (tokenIdToKudosContainer[id].claimabilityAttributes.isAllowlistRequired) {
            require(
                MerkleProofUpgradeable.verify(
                    merkleProof,
                    tokenIdToContributors[id].stringContributorsMerkleRoot,
                    generateStringMerkleLeaf(contributor)
                ),
                "contributor not allowlisted"
            );
            
        }

        _claim(id, claimingAddress);
    }

    function _claim(uint256 id, address dst) internal {
        // Address dst should not already have the token
        require(
            balanceOf(dst, id) == 0,
            "address should not own token"
        );

        // If everything is allowed, then mint the token for dst
        _mint(dst, id, 1, "");

        // Decrement counter if necessary
        bool hasFiniteCount = tokenIdToKudosContainer[id].claimabilityAttributes.totalClaimCount > 0;
        if (hasFiniteCount) {
            tokenIdToKudosContainer[id].claimabilityAttributes.remainingClaimCount--;
        }
    }

    function _validateCommunityAdminAirdropAdminSig(
        uint256 id,
        address adminAddress,
        uint8 admin_v,
        bytes32 admin_r,
        bytes32 admin_s
    ) internal view {
        _tokenClaimChecks(id);

        // verify admin address & signature
        string memory communityUniqId = tokenIdToKudosContainer[id].communityUniqId;
        uint256 adminIndex = ICommunityRegistry(communityRegistryAddress).communityIdToAdminOneIndexIndices(communityUniqId, adminAddress);
        require(adminIndex != 0, "not admin of community");

        bytes32 communityAdminAirdropHash = keccak256(
            abi.encode(
                COMMUNITY_ADMIN_AIRDROP_TYPE_HASH,
                id
            )
        );
        _validateSignature(communityAdminAirdropHash, adminAddress, admin_v, admin_r, admin_s, "invalid admin airdrop signature");
    }

    function _validateCommunityAdminAirdropReceiverSig(
        uint256 id,
        address receivingAddress,
        uint8 receiver_v,
        bytes32 receiver_r,
        bytes32 receiver_s
    ) internal view {
        bytes32 communityAdminAirdropReceiverConsentHash = keccak256(
            abi.encode(
                COMMUNITY_ADMIN_AIRDROP_RECEIVER_CONSENT_TYPE_HASH,
                id
            )
        );
        _validateSignature(communityAdminAirdropReceiverConsentHash, receivingAddress, receiver_v, receiver_r, receiver_s, "invalid admin airdrop receiver consent signature");
    }

    function _claimCommunityAdminAirdrop(
        uint256 id,
        address receivingAddress,
        bool updateContributorMerkleRoots,
        KudosContributorsInputContainer memory contributorMerkleRoots,
        bytes32[] calldata merkleProof
    ) internal {
        if (tokenIdToKudosContainer[id].claimabilityAttributes.isAllowlistRequired) {
            if (updateContributorMerkleRoots) {
                _addAllowlistedContributorRoots(id, contributorMerkleRoots);
            }

            require(
                MerkleProofUpgradeable.verify(
                    merkleProof,
                    tokenIdToContributors[id].addressContributorsMerkleRoot,
                    generateAddressMerkleLeaf(receivingAddress)
                ),
                "address not allowlisted"
            );
        }

        _claim(id, receivingAddress);
    }

    function _tokenClaimChecks(
        uint256 id
    ) internal view {
        require(tokenIdToKudosContainer[id].creator != address(0), "token does not exist");

        bool hasExpirationSet = tokenIdToKudosContainer[id].claimabilityAttributes.expirationTimestamp != 0;
        require(!hasExpirationSet || hasExpirationSet && tokenIdToKudosContainer[id].claimabilityAttributes.expirationTimestamp > block.timestamp, "token claim expired");

        // if not allowlist flow, then check to make sure there are enough tokens to claim
        bool isAllowlistRequired = tokenIdToKudosContainer[id].claimabilityAttributes.isAllowlistRequired;
        bool hasClaimCountLimit = tokenIdToKudosContainer[id].claimabilityAttributes.totalClaimCount >= 0;
        uint256 remainingCount = tokenIdToKudosContainer[id].claimabilityAttributes.remainingClaimCount;
        require(isAllowlistRequired || !isAllowlistRequired && (!hasClaimCountLimit || hasClaimCountLimit && remainingCount > 0), "no more tokens");
    }

    function _validateClaimability(
        uint256 id,
        address claimee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        _tokenClaimChecks(id);

        if (tokenIdToKudosContainer[id].claimabilityAttributes.isSignatureRequired) {
            bytes32 claimHash = keccak256(abi.encode(CLAIM_TYPE_HASH, id));
            _validateSignature(claimHash, claimee, v, r, s);
        }
    }

    /// @dev The signature validation logic is always the same - we hash together the domainSeparator
    ///      and the encodeType & encodeData, all according to EIP-712. The only thing that changes per
    ///      signature type is the encodeType & encodeData.
    ///      This function takes in the encoded & hashed encodeType & encodeData, and verifies whether the
    ///      supposed signer actually signed the content of the signature.
    /// @param signatureContentHash          Hashed value of the signature's content
    /// @param signer                        Supposed signer of the signature
    /// @param v                             Part of the provided signature (v)
    /// @param r                             Part of the provided signature (r)
    /// @param s                             Part of the provided signature (s)
    function _validateSignature(
        bytes32 signatureContentHash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        _validateSignature(signatureContentHash, signer, v, r, s, "invalid signature");
    }

    /// @dev The signature validation logic is always the same - we hash together the domainSeparator
    ///      and the encodeType & encodeData, all according to EIP-712. The only thing that changes per
    ///      signature type is the encodeType & encodeData.
    ///      This function takes in the encoded & hashed encodeType & encodeData, and verifies whether the
    ///      supposed signer actually signed the content of the signature.
    /// @param signatureContentHash          Hashed value of the signature's content
    /// @param signer                        Supposed signer of the signature
    /// @param v                             Part of the provided signature (v)
    /// @param r                             Part of the provided signature (r)
    /// @param s                             Part of the provided signature (s)
    function _validateSignature(
        bytes32 signatureContentHash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        string memory errorMsg
    ) internal view {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                keccak256(bytes(CONTRACT_NAME)),
                block.chainid,
                address(this)
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, signatureContentHash)
        );
        address recoveredSigner = ecrecover(digest, v, r, s);
        require(signer == recoveredSigner, errorMsg);
    }

    function modifyKudosClaimAttributes(
        uint256 id,
        int256 totalClaimCount, // -1 indicates infinite
        uint256 expirationTimestamp, // 0 indicates no expiration
        bool isSignatureRequired,
        bool isAllowlistRequired
    ) public onlyOwner whenNotPaused {
        require(tokenIdToKudosContainer[id].creator != address(0), "token does not exist");

        int256 diff;
        if (tokenIdToKudosContainer[id].claimabilityAttributes.totalClaimCount == -1) {
            // when it was infinite claim before, we impose a fresh new limit
            diff = totalClaimCount;
        } else {
            // otherwise we decrease the remaining claim count
            diff = totalClaimCount - tokenIdToKudosContainer[id].claimabilityAttributes.totalClaimCount;
        }
        if (diff < 0 && int256(tokenIdToKudosContainer[id].claimabilityAttributes.remainingClaimCount) < -diff) {
            tokenIdToKudosContainer[id].claimabilityAttributes.remainingClaimCount = 0;
        } else {
            tokenIdToKudosContainer[id].claimabilityAttributes.remainingClaimCount = uint256(int256(tokenIdToKudosContainer[id].claimabilityAttributes.remainingClaimCount) + diff);
        }

        tokenIdToKudosContainer[id].claimabilityAttributes.totalClaimCount = totalClaimCount;
        tokenIdToKudosContainer[id].claimabilityAttributes.expirationTimestamp = expirationTimestamp;
        tokenIdToKudosContainer[id].claimabilityAttributes.isSignatureRequired = isSignatureRequired;
        tokenIdToKudosContainer[id].claimabilityAttributes.isAllowlistRequired = isAllowlistRequired;
    }

    /// @notice Adds allowlisted addresses to an existing Kudos token. Note that this function is actually
    ///         unsafe in that there is no signature verification. We must trust the owner of the contract
    ///         to correctly verify off-chain that the operation is valid. This is added as a way for the team
    ///         to enable API integrations where partners want to add contributors to an existing Kudos token
    ///         programmatically.
    /// @param id                            ID of the Token
    /// @param allowlistedContributorRoots   Merkle roots of allowlisted contributors
    /// @param v                             Part of the creator's signature (v)
    /// @param r                             Part of the creator's signature (r)
    /// @param s                             Part of the creator's signature (s)
    function addAllowlistedAddressesBySig(
        uint256 id,
        KudosContributorsInputContainer memory allowlistedContributorRoots,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOwner whenNotPaused {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                keccak256(bytes(CONTRACT_NAME)),
                block.chainid,
                address(this)
            )
        );
        // Note: not verifying the content of allowlisted addresses for now
        bytes32 addAllowlistedAddressesHash = keccak256(
            abi.encode(
                ADD_ALLOWLISTED_ADDRESSES_TYPE_HASH,
                id
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, addAllowlistedAddressesHash)
        );
        address signatory = ecrecover(digest, v, r, s);

        // Check if token created by this creator
        require(tokenIdToKudosContainer[id].creator == signatory, "only creator can add allowlisted addresses");

        _addAllowlistedContributorRoots(id, allowlistedContributorRoots);
    }

    /// @notice Adds allowlisted addresses to an existing Kudos token. Note that this function is actually
    ///         unsafe in that there is no signature verification. We must trust the owner of the contract
    ///         to correctly verify off-chain that the operation is valid. This is added as a way for the team
    ///         to enable API integrations where partners want to add contributors to an existing Kudos token
    ///         programmatically.
    ///
    ///         In the future, we expect to push partners to use the addAllowlistedAddressesBySig function so at least
    ///         we can validate to a degree that the operation is at least user-signed.
    /// @param id                            ID of the Token
    /// @param allowlistedContributorRoots   Merkle roots of allowlisted contributors
    function unsafeAddAllowlistedContributors(
        uint256 id,
        KudosContributorsInputContainer memory allowlistedContributorRoots
    ) public onlyOwner whenNotPaused {
        require(tokenIdToKudosContainer[id].creator != address(0), "token should already exist");

        _addAllowlistedContributorRoots(id, allowlistedContributorRoots);
    }

    function _addAllowlistedContributorRoots(uint256 id, KudosContributorsInputContainer memory newAllowlistedContributorRoots) internal {
        tokenIdToContributors[id].addressContributorsMerkleRoot = newAllowlistedContributorRoots.addressContributorsMerkleRoot;
        tokenIdToContributors[id].stringContributorsMerkleRoot = newAllowlistedContributorRoots.stringContributorsMerkleRoot;
    }

    /// @notice We add a temporary backdoor function to update the contents of the toeknIdToContributors map.
    ///         Previously, we were storing the raw contributor list, but because this is extremely inefficient,
    ///         we only want to store the merkle roots instead. This backdoor function allows us to update the
    ///         existing Kudos tokens' contributor data.
    /// @param id                            ID of the Token
    /// @param allowlistedContributorRoots   Merkle roots of allowlisted contributors
    function backdoorUpdateContributors(
        uint256 id,
        KudosContributorsInputContainer memory allowlistedContributorRoots
    ) public onlyOwner whenPaused {
        require(tokenIdToKudosContainer[id].creator != address(0), "token should already exist");

        // clear allowlist to free up space
        delete tokenIdToContributors[id];
        
        tokenIdToContributors[id].addressContributorsMerkleRoot = allowlistedContributorRoots.addressContributorsMerkleRoot;
        tokenIdToContributors[id].stringContributorsMerkleRoot = allowlistedContributorRoots.stringContributorsMerkleRoot;
    }

    /// @notice Returns the allowlisted contributors as an array.
    /// @dev The solidity compiler automatically returns the getter for mappings with arrays
    ///      as map(key, idx), which prevents us from getting the entire array back for a given key.
    /// @param tokenId     ID of the token
    function getAllowlistedContributors(uint256 tokenId)
        public
        view
        returns (KudosContributorsContainer memory)
    {
        return tokenIdToContributors[tokenId];
    }

    /// @notice Returns the Kudos metadata for a given token ID
    /// @dev Getters generated by the compiler for a public storage variable
    ///      silently skips mappings and arrays inside structs.
    //       This is why we need our own getter function to return the entirety of the struct.
    ///      https://ethereum.stackexchange.com/questions/107027/how-to-return-an-array-of-structs-that-has-mappings-nested-within-them/107124
    /// @param tokenId     ID of the token
    function getKudosMetadata(uint256 tokenId)
        public
        view
        returns (KudosContainer memory)
    {
        return tokenIdToKudosContainer[tokenId];
    }

    /// @notice Owner can pause the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Owner can unpause the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev A way to convert an array of strings into a hashed byte32 value.
    ///      We append using encodePacked, which is the equivalent of hexlifying each
    ///      hashed string and concatenating them.
    function convertStringArraytoByte32(string[] memory inputArray)
        internal
        pure
        returns (bytes32)
    {
        bytes memory packedBytes;
        for (uint256 i = 0; i < inputArray.length; i++) {
            packedBytes = abi.encodePacked(
                packedBytes,
                keccak256(bytes(inputArray[i]))
            );
        }
        return keccak256(packedBytes);
    }

    function compareStringsbyBytes(string memory s1, string memory s2) private pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function generateAddressMerkleLeaf(address account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function generateStringMerkleLeaf(string memory account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(account));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";

contract ERC1155NonTransferableBurnableUpgradeable is
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable
{
    /// @dev Override of the token transfer hook that blocks all transfers BUT mints and burns.
    ///        This is a precursor to non-transferable tokens.
    ///        We may adopt something like ERC1238 in the future.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        require(
            (from == address(0) || to == address(0)),
            "Only mint and burn transfers are allowed"
        );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
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
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155Supply_init_unchained();
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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