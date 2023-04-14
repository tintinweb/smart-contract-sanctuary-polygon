// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IBatchMintable {
    function getPrimaryOwnersPointer(uint256 index) external view returns(address);

    function isPrimaryOwner(address tokenOwner) external view returns(bool);

    function mintBatch(bytes calldata addresses) external returns (uint256);

    function mintBatch(address pointer) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import {IEditionBase} from "./IEditionBase.sol";
import {IRealTimeMintable} from "./IRealTimeMintable.sol";

interface IEdition is IRealTimeMintable, IEditionBase {
    // just a convenience wrapper for the parent editions
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

struct EditionState {
    // how many tokens have been minted (can not be more than editionSize)
    uint64 numberMinted;
    // reserved space to keep the state a uint256
    uint16 __reserved;
    // Price to mint in twei (1 twei = 1000 gwei), so the supported price range is 0.000001 to 4294.967295 ETH
    // To accept ERC20 or a different price range, use a specialized sales contract as the approved minter
    uint32 salePriceTwei;
    // Royalty amount in bps (uint16 is large enough to store 10000 bps)
    uint16 royaltyBPS;
    // the edition can be minted up to this timestamp in seconds -- 0 means no end date
    uint64 endOfMintPeriod;
    // Total size of edition that can be minted
    uint64 editionSize;
}

interface IEditionBase {
    event ExternalUrlUpdated(string oldExternalUrl, string newExternalUrl);
    event PropertyUpdated(string name, string oldValue, string newValue);

    function contractURI() external view returns (string memory);

    function editionSize() external view returns (uint256);

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _animationUrl,
        string memory _imageUrl,
        uint256 _editionSize,
        uint256 _royaltyBPS,
        uint256 _mintPeriodSeconds
    ) external;

    function enableDefaultOperatorFilter() external;

    function endOfMintPeriod() external view returns (uint256);

    function isApprovedMinter(address minter) external view returns (bool);

    function isMintingEnded() external view returns (bool);

    function setApprovedMinter(address minter, bool allowed) external;

    function setExternalUrl(string calldata _externalUrl) external;

    function setOperatorFilter(address operatorFilter) external;

    function setStringProperties(string[] calldata names, string[] calldata values) external;

    function totalSupply() external view returns (uint256);

    function withdraw() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IRealTimeMintable {
    event PriceChanged(uint256 amount);

    function mint(address to) external payable returns (uint256);

    function safeMint(address to) external payable returns (uint256);

    function mintBatch(address[] memory recipients) external payable returns (uint256);

    function salePrice() external view returns (uint256);

    function setSalePrice(uint256 _salePrice) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ClonesUpgradeable} from "@openzeppelin-contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import {IBatchMintable} from "nft-editions/interfaces/IBatchMintable.sol";
import {IEdition} from "nft-editions/interfaces/IEdition.sol";

import {EditionData, IEditionFactory} from "src/editions/interfaces/IEditionFactory.sol";
import {IShowtimeVerifier, Attestation, SignedAttestation} from "src/interfaces/IShowtimeVerifier.sol";

import "./interfaces/Errors.sol";

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

contract EditionFactory is IEditionFactory {
    string internal constant SYMBOL = unicode"✦ SHOWTIME";

    IShowtimeVerifier public immutable showtimeVerifier;

    constructor(address _showtimeVerifier) {
        showtimeVerifier = IShowtimeVerifier(_showtimeVerifier);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC INTERFACE
    //////////////////////////////////////////////////////////////*/

    /// Create a new batch edition contract with a deterministic address, with delayed batch minting
    /// @param signedAttestation a signed message from Showtime authorizing this action on behalf of the edition creator
    /// @return editionAddress the address of the created edition
    function create(EditionData calldata data, SignedAttestation calldata signedAttestation)
        public
        returns (address editionAddress)
    {
        editionAddress = _createEdition(data, signedAttestation);

        // we don't mint at this stage, we expect subsequent calls to `mintBatch`
    }

    /// Create and mint a new batch edition contract with a deterministic address
    /// @param packedRecipients an abi.encodePacked() array of recipient addresses for the batch mint
    /// @param signedAttestation a signed message from Showtime authorizing this action on behalf of the edition creator
    /// @return editionAddress the address of the created edition
    function createWithBatch(
        EditionData calldata data,
        bytes calldata packedRecipients,
        SignedAttestation calldata signedAttestation
    ) external override returns (address editionAddress) {
        // this will revert if the attestation is invalid
        editionAddress = _createEdition(data, signedAttestation);

        // mint a batch, using a direct list of recipients
        IBatchMintable(editionAddress).mintBatch(packedRecipients);
    }

    /// Create and mint a new batch edition contract with a deterministic address
    /// @param pointer the address of the SSTORE2 pointer with the recipients of the batch mint for this edition
    /// @param signedAttestation a signed message from Showtime authorizing this action on behalf of the edition creator
    /// @return editionAddress the address of the created edition
    function createWithBatch(EditionData calldata data, address pointer, SignedAttestation calldata signedAttestation)
        external
        override
        returns (address editionAddress)
    {
        // this will revert if the attestation is invalid
        editionAddress = _createEdition(data, signedAttestation);

        // mint a batch, using an SSTORE2 pointer
        IBatchMintable(editionAddress).mintBatch(pointer);
    }

    function mintBatch(address editionAddress, address pointer, SignedAttestation calldata signedAttestation)
        external
        override
        returns (uint256 numMinted)
    {
        validateAttestation(signedAttestation, editionAddress, msg.sender);

        return IBatchMintable(editionAddress).mintBatch(pointer);
    }

    function mintBatch(
        address editionAddress,
        bytes calldata packedRecipients,
        SignedAttestation calldata signedAttestation
    ) external override returns (uint256 numMinted) {
        validateAttestation(signedAttestation, editionAddress, msg.sender);

        return IBatchMintable(editionAddress).mintBatch(packedRecipients);
    }

    /// do a single real time mint
    function mint(address editionAddress, address to, SignedAttestation calldata signedAttestation)
        external
        override
        returns (uint256 tokenId)
    {
        validateAttestation(signedAttestation, editionAddress, msg.sender);

        return IEdition(editionAddress).mint(to);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev we expect the signed attestation's context to correspond to the address of this contract (EditionFactory)
    /// @dev we expect the signed attestation's beneficiary to be the lowest 160 bits of hash(edition || relayer)
    /// @dev note: this function does _not_ burn the nonce for the attestation
    function validateAttestation(SignedAttestation calldata signedAttestation, address edition, address relayer)
        public
        view
        override
        returns (bool)
    {
        // verify that the context is valid
        address context = signedAttestation.attestation.context;
        address expectedContext = address(this);
        if (context != expectedContext) {
            revert AddressMismatch({expected: expectedContext, actual: context});
        }

        // verify that the beneficiary is valid
        address expectedBeneficiary = address(uint160(uint256(keccak256(abi.encodePacked(edition, relayer)))));
        address beneficiary = signedAttestation.attestation.beneficiary;
        if (beneficiary != expectedBeneficiary) {
            revert AddressMismatch({expected: expectedBeneficiary, actual: beneficiary});
        }

        // verify the signature _without_ burning
        // important: it's up to the clients of this function to make sure that the attestation can not be reused
        // for example:
        // - trying to deploy to an existing edition address will revert
        // - trying to deploy the same batch twice should revert
        if (!showtimeVerifier.verify(signedAttestation)) {
            revert VerificationFailed();
        }

        return true;
    }

    function getEditionId(EditionData calldata data) public pure override returns (uint256 editionId) {
        return uint256(keccak256(abi.encodePacked(data.creatorAddr, data.name, data.animationUrl, data.imageUrl)));
    }

    function getEditionAtId(address editionImpl, uint256 editionId) public view override returns (address) {
        if (editionImpl == address(0)) {
            revert NullAddress();
        }

        return ClonesUpgradeable.predictDeterministicAddress(editionImpl, bytes32(editionId), address(this));
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _createEdition(EditionData calldata data, SignedAttestation calldata signedAttestation)
        internal
        returns (address editionAddress)
    {
        uint256 editionId = getEditionId(data);
        address editionImpl = data.editionImpl;

        // we expect this to revert if editionImpl is null
        address predicted = address(getEditionAtId(editionImpl, editionId));
        validateAttestation(signedAttestation, predicted, msg.sender);

        // avoid burning all available gas if an edition already exists at this address
        if (predicted.code.length > 0) {
            revert DuplicateEdition(predicted);
        }

        // create the edition
        editionAddress = ClonesUpgradeable.cloneDeterministic(editionImpl, bytes32(editionId));
        IEdition edition = IEdition(editionAddress);

        // initialize it
        try edition.initialize(
            address(this), // owner
            data.name,
            SYMBOL,
            data.description,
            data.animationUrl,
            data.imageUrl,
            data.editionSize,
            data.royaltiesBPS,
            data.mintPeriodSeconds
        ) {
            // nothing to do
        } catch {
            // rethrow the problematic way until we have a better way
            // see https://github.com/ethereum/solidity/issues/12654
            assembly ("memory-safe") {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        emit CreatedEdition(editionId, data.creatorAddr, editionAddress, data.tags);

        // set the creator name
        string memory creatorName = data.creatorName;
        if (bytes(creatorName).length > 0) {
            string[] memory propertyNames = new string[](1);
            propertyNames[0] = "Creator";

            string[] memory propertyValues = new string[](1);
            propertyValues[0] = data.creatorName;

            edition.setStringProperties(propertyNames, propertyValues);
        }

        // set the external url
        string memory externalUrl = data.externalUrl;
        if (bytes(externalUrl).length > 0) {
            edition.setExternalUrl(data.externalUrl);
        }

        // configure the minter
        address minterAddr = data.minterAddr;
        if (minterAddr != address(0)) {
            edition.setApprovedMinter(minterAddr, true);
        }

        // configure the operator filter
        address operatorFilter = data.operatorFilter;
        if (operatorFilter != address(0)) {
            edition.setOperatorFilter(operatorFilter);
        }

        // and finally transfer ownership of the configured contract to the actual creator
        IOwnable(editionAddress).transferOwnership(data.creatorAddr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error AddressMismatch(address expected, address actual);
error DuplicateEdition(address);
error InvalidBatch();
error InvalidTimeLimit(uint256 offsetSeconds);
error NullAddress();
error VerificationFailed();
error UnexpectedContext(address context);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IShowtimeVerifier, SignedAttestation} from "src/interfaces/IShowtimeVerifier.sol";

/// @param editionImpl the address of the implementation contract for the edition to clone
/// @param creatorAddr the address that will be configured as the owner of the edition
/// @param minterAddr the address that will be configured as the allowed minter for the edition (0 for no minter)
/// @param name Name of the edition contract
/// @param description Description of the edition entry
/// @param animationUrl Animation url (optional) of the edition entry
/// @param imageUrl Metadata: Image url (semi-required) of the edition entry
/// @param editionSize Number of editions that can be minted in total (0 for an open edition)
/// @param royaltiesBPS royalties in basis points (1/100th of a percent)
/// @param mintPeriodSeconds duration in seconds after which editions can no longer be minted or purchased (0 to have no time limit)
/// @param externalUrl Metadata: External url (optional) of the edition entry
/// @param creatorName Metadata: Creator name (optional) of the edition entry
/// @param tags list of comma-separated tags for this edition, emitted as part of the CreatedBatchEdition event
/// @param operatorFilter address of an operator filter contract, or 0 for no filter (see https://github.com/ProjectOpenSea/operator-filter-registry)
struct EditionData {
    // factory configuration
    address editionImpl;
    address creatorAddr;
    address minterAddr;
    // initialization data
    string name;
    string description;
    string animationUrl;
    string imageUrl;
    uint256 editionSize;
    uint256 royaltiesBPS;
    uint256 mintPeriodSeconds;
    // supplemental data
    string externalUrl;
    string creatorName;
    string tags;
    address operatorFilter;
}

interface IEditionFactory {
    /// @dev we expect tags to be a comma-separated list of strings e.g. "music,location,password"
    event CreatedEdition(
        uint256 indexed editionId, address indexed creator, address editionContractAddress, string tags
    );

    function create(EditionData calldata data, SignedAttestation calldata signedAttestation)
        external
        returns (address editionAddress);

    function createWithBatch(
        EditionData calldata data,
        bytes calldata packedRecipients,
        SignedAttestation calldata signedAttestation
    ) external returns (address editionAddress);

    function createWithBatch(EditionData calldata data, address pointer, SignedAttestation calldata signedAttestation)
        external
        returns (address editionAddress);

    function mintBatch(address editionImpl, bytes calldata recipients, SignedAttestation calldata signedAttestation)
        external
        returns (uint256 numMinted);

    function mintBatch(address editionImpl, address pointer, SignedAttestation calldata signedAttestation)
        external
        returns (uint256 numMinted);

    function mint(address editionAddress, address to, SignedAttestation calldata signedAttestation)
        external
        returns (uint256 tokenId);

    function showtimeVerifier() external view returns (IShowtimeVerifier);


    function validateAttestation(SignedAttestation calldata signedAttestation, address edition, address relayer)
        external returns (bool);

    function getEditionId(EditionData calldata data) external view returns (uint256 editionId);

    function getEditionAtId(address editionImpl, uint256 editionId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct Attestation {
    address beneficiary;
    address context;
    uint256 nonce;
    uint256 validUntil;
}

struct SignedAttestation {
    Attestation attestation;
    bytes signature;
}

interface IShowtimeVerifier {
    error BadNonce(uint256 expected, uint256 actual);
    error DeadlineTooLong();
    error Expired();
    error NullAddress();
    error SignerExpired(address signer);
    error Unauthorized();
    error UnknownSigner();

    event SignerAdded(address signer, uint256 validUntil);
    event SignerRevoked(address signer);
    event ManagerUpdated(address newManager);

    function domainSeparator() external view returns (bytes32);

    function encode(Attestation memory attestation) external view returns (bytes memory);

    function MAX_ATTESTATION_VALIDITY_SECONDS() external view returns (uint256);

    function MAX_SIGNER_VALIDITY_DAYS() external view returns (uint256);

    function nonces(address) external view returns (uint256);

    function REQUEST_TYPE_HASH() external view returns (bytes32);

    function verify(SignedAttestation calldata signedAttestation) external view returns (bool);

    function verifyAndBurn(SignedAttestation calldata signedAttestation) external returns (bool);

    function verify(
        Attestation calldata attestation,
        bytes32 typeHash,
        bytes memory encodedData,
        bytes calldata signature
    ) external view returns (bool);

    function verifyAndBurn(
        Attestation calldata attestation,
        bytes32 typeHash,
        bytes memory encodedData,
        bytes calldata signature
    ) external returns (bool);

    function setManager(address _manager) external;

    function signerValidity(address signer) external view returns (uint256);

    function registerSigner(address signer, uint256 validityDays) external returns (uint256 validUntil);

    function revokeSigner(address signer) external;

    function registerAndRevoke(address signerToRegister, address signerToRevoke, uint256 validityDays)
        external
        returns (uint256 validUntil);
}