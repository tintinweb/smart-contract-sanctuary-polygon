// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {Managerable} from "./extensions/Managerable.sol";
import {IdentitiesFactory} from "./IdentitiesFactory.sol";
import {TrustedIssuersCollection} from "./TrustedIssuersCollection.sol";
import {ClaimTopicsCollection} from "./ClaimTopicsCollection.sol";
import {IGatekeeperBaseVerifier} from "./interfaces/IGatekeeperBaseVerifier.sol";
import {IIdentity} from "./interfaces/IIdentity.sol";
import {IIdentityCallbackHandler} from "./interfaces/IIdentityCallbackHandler.sol";
import {IClaimIssuer} from "./interfaces/IClaimIssuer.sol";

contract GateKeeper is
    IGatekeeperBaseVerifier,
    IIdentityCallbackHandler,
    ERC165Upgradeable,
    Managerable,
    IdentitiesFactory,
    TrustedIssuersCollection,
    ClaimTopicsCollection
{
    /**
     * @notice  Contract initialization using proxy
     */
    function initialize(
        address identityImplementation,
        uint256[] memory claimTopics,
        address payable collectorWallet
    ) external initializer {
        __Gatekeeper_init(identityImplementation, claimTopics, collectorWallet);
    }

    function removeClaimByUser(
        bytes32 claimId
    ) external payable mChargesFee(CHARGEABLE_TYPE_REVOKE_CLAIM) {
        IIdentity identity = IIdentity(getIdentity(msg.sender));
        identity.removeClaim(claimId);
    }

    function addClaimCallback(
        bytes32 claimId,
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    ) external {
        address userAddress = getIdentityWallet(msg.sender);
        if (userAddress != address(0)) {
            emit ClaimAddedCallback(
                msg.sender,
                userAddress,
                claimId,
                topic,
                scheme,
                issuer,
                signature,
                data,
                uri
            );
        }
    }

    function isUserVerified(
        address userAddress,
        uint256[] memory requiredClaimTopics
    ) external view mAddressNotZero(userAddress) returns (bool) {
        require(requiredClaimTopics.length > 0, "No required claim topics");

        IIdentity identity = IIdentity(getIdentity(userAddress));

        if (address(identity) == address(0)) {
            return false;
        }
        address issuer;
        bytes memory sig;
        bytes memory data;
        uint256 claimTopicInd;
        for (
            claimTopicInd = 0;
            claimTopicInd < requiredClaimTopics.length;
            claimTopicInd++
        ) {
            bytes32[] memory claimIds = identity.getClaimIdsByTopic(
                requiredClaimTopics[claimTopicInd]
            );
            if (claimIds.length == 0) {
                return false;
            }
            for (uint256 j = 0; j < claimIds.length; j++) {
                (, , issuer, sig, data, ) = identity.getClaim(claimIds[j]);

                if (
                    isTrustedIssuer(issuer) &&
                    hasClaimTopic(issuer, requiredClaimTopics[claimTopicInd]) &&
                    IClaimIssuer(issuer).isClaimValid(
                        identity,
                        requiredClaimTopics[claimTopicInd],
                        sig,
                        data
                    )
                ) {
                    // found valid claim that satisfies gatekeeper, no need to check other claims within current claim topic.
                    break;
                } else if (j == (claimIds.length - 1)) {
                    // if it is last iteration and no valid claim found - return false,
                    //user can be considered as not verified if he has no valid claim for at least one required claim topic
                    return false;
                }
            }
        }
        return true;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            AccessControlUpgradeable,
            ERC165Upgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IIdentityCallbackHandler).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Gatekeeper_init(
        address identityImplementation,
        uint256[] memory claimTopics,
        address payable collectorWallet
    ) internal onlyInitializing {
        __IdentitiesFactory_init(identityImplementation, collectorWallet);
        __TrustedIssuersCollection_init();
        __ClaimTopicsCollection_init(claimTopics);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IClaimIssuer} from "./IClaimIssuer.sol";

interface ITrustedIssuersCollection {
    /**
     *  this event is emitted when a trusted issuer is added in the registry.
     *  the event is emitted by the addTrustedIssuer function
     *  `IClaimIssuer` is the address of the trusted issuer's ClaimIssuer contract
     *  `claimTopics` is the set of claims that the trusted issuer is allowed to emit
     */
    event TrustedIssuerAdded(
        IClaimIssuer indexed trustedIssuer,
        uint256[] claimTopics
    );

    /**
     *  this event is emitted when a trusted issuer is removed from the registry.
     *  the event is emitted by the removeTrustedIssuer function
     *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
     */
    event TrustedIssuerRemoved(IClaimIssuer indexed trustedIssuer);

    /**
     *  this event is emitted when the set of claim topics is changed for a given trusted issuer.
     *  the event is emitted by the updateIssuerClaimTopics function
     *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
     *  `claimTopics` is the set of claims that the trusted issuer is allowed to emit
     */
    event TrustedIssuerClaimTopicsUpdated(
        IClaimIssuer indexed trustedIssuer,
        uint256[] claimTopics
    );

    /**
     *  @dev registers a ClaimIssuer contract as trusted claim issuer.
     *  Requires that a ClaimIssuer contract doesn't already exist
     *  Requires that the claimTopics set is not empty
     *  @param trustedIssuer The ClaimIssuer contract address of the trusted claim issuer.
     *  @param claimTopics the set of claim topics that the trusted issuer is allowed to emit
     *  This function can only be called by the owner of the Trusted Issuers Collection contract
     *  emits a `TrustedIssuerAdded` event
     */
    function addTrustedIssuer(
        IClaimIssuer trustedIssuer,
        uint256[] calldata claimTopics
    ) external;

    /**
     *  @dev Removes the ClaimIssuer contract of a trusted claim issuer.
     *  Requires that the claim issuer contract to be registered first
     *  @param trustedIssuer the claim issuer to remove.
     *  This function can only be called by the owner of the Trusted Issuers Collection contract
     *  emits a `TrustedIssuerRemoved` event
     */
    function removeTrustedIssuer(IClaimIssuer trustedIssuer) external;

    /**
     *  @dev Updates the set of claim topics that a trusted issuer is allowed to emit.
     *  Requires that this ClaimIssuer contract already exists in the registry
     *  Requires that the provided claimTopics set is not empty
     *  @param trustedIssuer the claim issuer to update.
     *  @param claimTopics the set of claim topics that the trusted issuer is allowed to emit
     *  This function can only be called by the owner of the Trusted Issuers Collection contract
     *  emits a `ClaimTopicsUpdated` event
     */
    function updateIssuerClaimTopics(
        IClaimIssuer trustedIssuer,
        uint256[] calldata claimTopics
    ) external;

    /**
     *  @dev Function for getting all the trusted claim issuers stored.
     *  @return array of all claim issuers registered.
     */
    function getTrustedIssuers() external view returns (IClaimIssuer[] memory);

    /**
     *  @dev Checks if the ClaimIssuer contract is trusted
     *  @param issuer the address of the ClaimIssuer contract
     *  @return true if the issuer is trusted, false otherwise.
     */
    function isTrustedIssuer(address issuer) external view returns (bool);

    /**
     *  @dev Function for getting all the claim topic of trusted claim issuer
     *  Requires the provided ClaimIssuer contract to be registered in the trusted issuers registry.
     *  @param trustedIssuer the trusted issuer concerned.
     *  @return The set of claim topics that the trusted issuer is allowed to emit
     */
    function getTrustedIssuerClaimTopics(
        IClaimIssuer trustedIssuer
    ) external view returns (uint256[] memory);

    /**
     *  @dev Function for checking if the trusted claim issuer is allowed
     *  to emit a certain claim topic
     *  @param issuer the address of the trusted issuer's ClaimIssuer contract
     *  @param claimTopic the Claim Topic that has to be checked to know if the `issuer` is allowed to emit it
     *  @return true if the issuer is trusted for this claim topic.
     */
    function hasClaimTopic(
        address issuer,
        uint256 claimTopic
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IIdentityCallbackHandler is IERC165Upgradeable {
    event ClaimAddedCallback(
        address indentityAddress,
        address userAddress,
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );

    function addClaimCallback(
        bytes32 claimId,
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IERC734} from "./IERC734.sol";
import {IERC735} from "./IERC735.sol";
import {IIdentityCallbackHandler} from "./IIdentityCallbackHandler.sol";

// solhint-disable-next-line no-empty-blocks
interface IIdentity is IERC734, IERC735 {
    function getCreator() external view returns (IIdentityCallbackHandler);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IIdentity} from "./IIdentity.sol";

interface IIdentitiesFactory {
    /**
     *  this event is emitted when an Identity is registered into the Identity Collection.
     *  the event is emitted by the 'registerIdentity' function
     *  `userAddress` is the address of the user's wallet
     *  `identity` is the address of the Identity smart contract
     */
    event IdentityDeployed(
        address indexed userAddress,
        address indexed identity
    );

    /**
     *  @dev Deploy an identity proxy contract corresponding to a user address.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param userAddress The address of the user
     *  emits `IdentityDeployed` event
     */
    function deployIdentity(address userAddress) external returns (address);

    /**
     *  @dev Deploy an identity proxy contract corresponding to a user address.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param userAddress The address of the user
     *  @param topic The type of claim
     *  @param scheme The scheme with which this claim SHOULD be verified or how it should be processed.
     *  @param issuer The issuers identity contract address, or the address used to sign the above signature.
     *  @param signature Signature which is the proof that the claim issuer issued a claim of topic for this identity.
     *  it MUST be a signed message of the following structure: keccak256(abi.encode(address identityHolder_address, uint256 _ topic, bytes data))
     *  @param data The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
     *  @param uri The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
     *  emits `IdentityDeployed` event
     */
    function deployIdentityWithClaim(
        address userAddress,
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    ) external returns (address);

    /**
     *  @dev Deploy an identity proxy contract corresponding to msg.sender address.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  emits `IdentityDeployed` event
     */
    function deploySelfIdentity() external payable returns (address);

    /**
     *  @dev Deploy an identity proxy contract corresponding to msg.sender address.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param topic The type of claim
     *  @param scheme The scheme with which this claim SHOULD be verified or how it should be processed.
     *  @param issuer The issuers identity contract address, or the address used to sign the above signature.
     *  @param signature Signature which is the proof that the claim issuer issued a claim of topic for this identity.
     *  it MUST be a signed message of the following structure: keccak256(abi.encode(address identityHolder_address, uint256 _ topic, bytes data))
     *  @param data The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
     *  @param uri The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
     *  emits `IdentityDeployed` event
     */
    function deploySelfIdentityWithClaim(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    ) external payable returns (address);

    function setIdentityImplementation(address newIdentityImpl) external;

    function getIdentityImplementation() external view returns (address);

    function predictIdentityAddress(
        address userAddress
    ) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IIdentity} from "./IIdentity.sol";

interface IIdentitiesCollection {
    /**
     *  this event is emitted when an Identity is removed from the Identity Collection.
     *  the event is emitted by the 'deleteIdentity' function
     *  `userAddress` is the address of the user's wallet
     *  `identity` is the address of the Identity smart contract
     */
    event IdentityRemoved(
        address indexed userAddress,
        address indexed identity
    );

    /**
     *  this event is emitted when an Identity has been registered or updated
     *  the event is emitted by the 'updateIdentity' function
     *  `userAddress` is the address of the user's wallet
     *  `oldIdentity` is the old Identity contract's address to update
     *  `newIdentity` is the new Identity contract's
     */
    event IdentityRegistered(
        address indexed userAddress,
        address indexed oldIdentity,
        address indexed newIdentity
    );

    /**
     *  @dev Register or updates an identity contract corresponding to a user address.
     *  Requires that the user address should be the owner of the identity contract.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param userAddress The address of the user
     *  @param identity The address of the user's new identity contract
     *  emits `IdentityUpdated` event
     */
    function registerIdentity(address userAddress, address identity) external;

    /**
     *  @dev Removes an user from the identity collection.
     *  Requires that the user have an identity contract already deployed that will be deleted.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param userAddress The address of the user to be removed
     *  emits `IdentityRemoved` event
     */
    function deleteIdentity(address userAddress) external;

    /**
     *  @dev This functions checks whether a wallet has its Identity registered or not
     *  in the Identity Collection.
     *  @param userAddress The address of the user to be checked.
     *  @return 'True' if the address is contained in the Identity Collection, 'false' if not.
     */
    function isWalletRegistered(
        address userAddress
    ) external view returns (bool);

    /**
     *  @dev This functions checks whether Identity address is registered or not
     *  in the Identity Collection.
     *  @param identityAddress The address of the user to be checked.
     *  @return 'True' if the identityAddress is contained in the Identity Collection, 'false' if not.
     */
    function isIdentityRegistered(
        address identityAddress
    ) external view returns (bool);

    /**
     *  @dev Returns the identity address of user.
     *  @param userAddress The wallet of the user
     */
    function getIdentity(address userAddress) external view returns (address);

    function getIdentityWallet(
        address identityAddress
    ) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

interface IGatekeeperBaseVerifier {
    function isUserVerified(
        address userAddress,
        uint256[] memory requiredClaimTopics
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

/**
 * @dev interface of the ERC735 (Claim Holder) standard as defined in the EIP.
 */
interface IERC735 {
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    /**
     * @dev Emitted when a claim was added.
     *
     * Specification: MUST be triggered when a claim was successfully added.
     */
    event ClaimAdded(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );

    /**
     * @dev Emitted when a claim was removed.
     *
     * Specification: MUST be triggered when removeClaim was successfully called.
     */
    event ClaimRemoved(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );

    /**
     * @dev Add or update a claim.
     *
     * Triggers Event: `ClaimRequested`, `ClaimAdded`, `ClaimChanged`
     *
     * Specification: Requests the ADDITION or the CHANGE of a claim from an issuer.
     * Claims can requested to be added by anybody, including the claim holder itself (self issued).
     *
     * _signature is a signed message of the following structure:
     * `keccak256(abi.encode(address identityHolder_address, uint256 topic, bytes data))`.
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address + uint256 topic))`.
     *
     * This COULD implement an approval process for pending claims, or add them right away.
     * MUST return a claimRequestId (use claim ID) that COULD be sent to the approve function.
     */
    function addClaim(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes calldata signature,
        bytes calldata data,
        string calldata uri
    ) external returns (bytes32 claimRequestId);

    /**
     * @dev Removes a claim.
     *
     * Triggers Event: `ClaimRemoved`
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function removeClaim(bytes32 claimId) external returns (bool success);

    /**
     * @dev Get a claim by its ID.
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function getClaim(
        bytes32 claimId
    )
        external
        view
        returns (
            uint256 topic,
            uint256 scheme,
            address issuer,
            bytes memory signature,
            bytes memory data,
            string memory uri
        );

    /**
     * @dev Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(
        uint256 topic
    ) external view returns (bytes32[] memory claimIds);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

/**
 * @dev interface of the ERC734 (Key Holder) standard as defined in the EIP.
 */
interface IERC734 {
    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }
    /**
     * @dev Emitted when an execution request was approved.
     *
     * Specification: MUST be triggered when approve was successfully called.
     */
    event Approved(uint256 indexed executionId, bool approved);

    /**
     * @dev Emitted when an execute operation was approved and successfully performed.
     *
     * Specification: MUST be triggered when approve was called and the execution was successfully approved.
     */
    event Executed(
        uint256 indexed executionId,
        address indexed to,
        uint256 indexed value,
        bytes data
    );

    /**
     * @dev Emitted when an execution request was performed via `execute`.
     *
     * Specification: MUST be triggered when execute was successfully called.
     */
    event ExecutionRequested(
        uint256 indexed executionId,
        address indexed to,
        uint256 indexed value,
        bytes data
    );

    event ExecutionFailed(
        uint256 indexed executionId,
        address indexed to,
        uint256 indexed value,
        bytes data
    );

    /**
     * @dev Emitted when a key was added to the Identity.
     *
     * Specification: MUST be triggered when addKey was successfully called.
     */
    event KeyAdded(
        bytes32 indexed key,
        uint256 indexed purpose,
        uint256 indexed keyType
    );

    /**
     * @dev Emitted when a key was removed from the Identity.
     *
     * Specification: MUST be triggered when removeKey was successfully called.
     */
    event KeyRemoved(
        bytes32 indexed key,
        uint256 indexed purpose,
        uint256 indexed keyType
    );

    /**
     * @dev Adds a _key to the identity. The _purpose specifies the purpose of the key.
     *
     * Triggers Event: `KeyAdded`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function addKey(
        bytes32 key,
        uint256 purpose,
        uint256 keyType
    ) external returns (bool success);

    /**
     * @dev Approves an execution or claim addition.
     *
     * Triggers Event: `Approved`, `Executed`
     *
     * Specification:
     * This SHOULD require n of m approvals of keys purpose 1, if the _to of the execution is the identity contract itself, to successfully approve an execution.
     * And COULD require n of m approvals of keys purpose 2, if the _to of the execution is another contract, to successfully approve an execution.
     */
    function approve(uint256 id, bool approve) external returns (bool success);

    /**
     * @dev Passes an execution instruction to an ERC725 identity.
     *
     * Triggers Event: `ExecutionRequested`, `Executed`
     *
     * Specification:
     * SHOULD require approve to be called with one or more keys of purpose 1 or 2 to approve this execution.
     * Execute COULD be used as the only accessor for `addKey` and `removeKey`.
     */
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (uint256 executionId);

    /**
     * @dev Removes _purpose for _key from the identity.
     *
     * Triggers Event: `KeyRemoved`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function removeKey(
        bytes32 key,
        uint256 purpose
    ) external returns (bool success);

    /**
     * @dev Returns the full key data, if present in the identity.
     */
    function getKey(
        bytes32 publicKey
    )
        external
        view
        returns (uint256[] memory purposes, uint256 keyType, bytes32 key);

    /**
     * @dev Returns the list of purposes associated with a key.
     */
    function getKeyPurposes(
        bytes32 key
    ) external view returns (uint256[] memory purposes);

    /**
     * @dev Returns an array of public key bytes32 held by this identity.
     */
    function getKeysByPurpose(
        uint256 purpose
    ) external view returns (bytes32[] memory keys);

    /**
     * @dev Returns TRUE if a key is present and has the given purpose. If the key is not present it returns FALSE.
     */
    function keyHasPurpose(
        bytes32 key,
        uint256 purpose
    ) external view returns (bool exists);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

interface IClaimTopicsCollection {
    /**
     *  @dev Get the trusted claim topics for the security token
     *  @return Array of trusted claim topics
     */
    function getClaimTopics() external view returns (uint256[] memory);

    /**
     *  @dev check if claim topis is valid
     *  @return true is valid
     */
    function isClaimTopic(uint256 claimTopic) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IERC735} from "./IIdentity.sol";
import {IIdentity} from "./IIdentity.sol";

interface IClaimIssuer is IERC735 {
    function isClaimValid(
        IIdentity identity,
        uint256 claimTopic,
        bytes calldata sig,
        bytes calldata data
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IdentitiesFactoryDeployHook {
    /* solhint-disable no-empty-blocks */
    function _afterIdentityDeployed(
        address userAddress,
        address identityAddress
    ) internal virtual {}
    /* solhint-enable no-empty-blocks */
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IdentitiesFactoryDeployHook} from "./IdentitiesFactoryDeployHook.sol";
import {Identity} from "../Identity.sol";
import {IIdentitiesFactory} from "../interfaces/IIdentitiesFactory.sol";

abstract contract IdentitiesFactoryClone is
    Initializable,
    IIdentitiesFactory,
    IdentitiesFactoryDeployHook
{
    address internal _identityImplementation;

    function predictIdentityAddress(
        address userAddress
    ) public view returns (address) {
        bytes32 salt = _identitySalt(userAddress);
        return
            Clones.predictDeterministicAddress(
                _identityImplementation,
                salt,
                address(this)
            );
    }

    function _deployIdentity(address userAddress) internal returns (address) {
        bytes32 salt = _identitySalt(userAddress);

        address clone = Clones.cloneDeterministic(
            _identityImplementation,
            salt
        );
        Identity(clone).initialize(userAddress, address(this));
        _afterIdentityDeployed(userAddress, address(clone));
        emit IdentityDeployed(userAddress, address(clone));
        return clone;
    }

    function _deployIdentityWithClaim(
        address userAddress,
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    ) internal returns (address) {
        bytes32 salt = _identitySalt(userAddress);

        address clone = Clones.cloneDeterministic(
            _identityImplementation,
            salt
        );
        Identity(clone).initialize(userAddress, address(this));
        _afterIdentityDeployed(userAddress, address(clone));
        emit IdentityDeployed(userAddress, address(clone));
        Identity(clone).addClaim(topic, scheme, issuer, signature, data, uri);

        return clone;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __IdentitiesFactoryClone_init(
        address identityImplementation
    ) internal onlyInitializing {
        _identityImplementation = identityImplementation;
    }

    function _setIdentityImplementation(
        address newIdentityImplementation
    ) internal {
        _identityImplementation = newIdentityImplementation;
    }

    function _getIdentityImplementation() internal view returns (address) {
        return _identityImplementation;
    }

    function _identitySalt(
        address userAddress
    ) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(userAddress)));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @dev Implementation managing identities collection
 */
contract Managerable is AccessControlUpgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /**
     * @dev  Requires check if the passed addresses are not zero addresses
     * @param   inputAddress - any address
     */
    modifier mAddressNotZero(address inputAddress) {
        require(
            inputAddress != address(0),
            "Address can not be a zero address"
        );
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Managerable_init() internal onlyInitializing {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Managerable} from "./Managerable.sol";

contract Chargable is Initializable, Managerable {
    uint256 public constant CHARGEABLE_TYPE_DEPLOY_IDENTITY = 1;
    uint256 public constant CHARGEABLE_TYPE_REVOKE_CLAIM = 2;
    mapping(uint256 => uint256) private _fees;
    address payable private _collectorWallet;

    modifier mChargesFee(uint256 chargableType) {
        if (_fees[chargableType] > 0) {
            require(msg.value == _fees[chargableType], "Not enough tokens");
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(_collectorWallet).call{
                gas: 200_000,
                value: _fees[chargableType]
            }("");
            require(success, "Error on sending tokens");
        }
        _;
    }

    function setFee(
        uint256 chargableType,
        uint256 amount
    ) public onlyRole(MANAGER_ROLE) {
        _fees[chargableType] = amount;
    }

    function setCollectorWallet(
        address payable collectorWallet
    ) public onlyRole(MANAGER_ROLE) {
        _collectorWallet = collectorWallet;
    }

    function getFee(uint256 chargableType) public view returns (uint256) {
        return _fees[chargableType];
    }

    function getCollectorWallet() public view returns (address) {
        return _collectorWallet;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Chargable_init(
        address payable collectorWallet
    ) internal onlyInitializing {
        __Managerable_init();

        _collectorWallet = collectorWallet;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IClaimIssuer} from "./interfaces/IClaimIssuer.sol";
import {ITrustedIssuersCollection} from "./interfaces/ITrustedIssuersCollection.sol";
import {Managerable} from "./extensions/Managerable.sol";

contract TrustedIssuersCollection is ITrustedIssuersCollection, Managerable {
    IClaimIssuer[] private _trustedIssuers;
    mapping(address => uint256) private _trustedIssuersIndexing;

    mapping(address => uint256[]) private _trustedIssuerClaimTopics;

    /**
     * @notice  Requires check for saved trusted issuer
     * @param   inputAddress address passed for checking
     */
    modifier mIssuerExists(address inputAddress) {
        require(
            _trustedIssuerClaimTopics[address(inputAddress)].length != 0,
            "Trusted issuer does not exits"
        );
        _;
    }

    /**
     * @notice  Requires check for non empty topic
     * @param   claimTopics topic passed for check.
     */
    modifier mClaimTopicsNotEmpty(uint256[] calldata claimTopics) {
        require(claimTopics.length > 0, "Trusted claim topics cannot be empty");
        _;
    }

    /**
     * @notice  Registers a ClaimIssuer contract as trusted claim issuer
     * @param   trustedIssuer  is the address of the trusted issuer's ClaimIssuer contract
     * @param   claimTopics  is the set of claims that the trusted issuer is allowed to emit
     */
    function addTrustedIssuer(
        IClaimIssuer trustedIssuer,
        uint256[] calldata claimTopics
    ) external override onlyRole(MANAGER_ROLE) {
        _addTrustedIssuer(trustedIssuer, claimTopics);
    }

    /**
     * @notice  Removes the ClaimIssuer contract of a trusted claim issuer
     * @param   trustedIssuer  is the address of the trusted issuer's ClaimIssuer contract
     */
    function removeTrustedIssuer(
        IClaimIssuer trustedIssuer
    ) external override onlyRole(MANAGER_ROLE) {
        _removeTrustedIssuer(trustedIssuer);
    }

    /**
     * @notice  Updates the set of claim topics that a trusted issuer is allowed to emit
     * @param   trustedIssuer  is the address of the trusted issuer's ClaimIssuer contract
     * @param   claimTopics  is the set of claims that the trusted issuer is allowed to emit
     */
    function updateIssuerClaimTopics(
        IClaimIssuer trustedIssuer,
        uint256[] calldata claimTopics
    ) external override onlyRole(MANAGER_ROLE) {
        _updateIssuerClaimTopics(trustedIssuer, claimTopics);
    }

    /**
     * @notice  Function for getting all the trusted claim issuers stored
     * @return  IClaimIssuer[]  .
     */
    function getTrustedIssuers()
        external
        view
        override
        returns (IClaimIssuer[] memory)
    {
        return _trustedIssuers;
    }

    /**
     * @notice  Checks if the ClaimIssuer contract is trusted
     * @param   issuer  the address of the trusted issuer's ClaimIssuer contract
     * @return  bool  .
     */
    function isTrustedIssuer(
        address issuer
    ) public view override returns (bool) {
        return _trustedIssuerClaimTopics[address(issuer)].length != 0;
    }

    /**
     * @notice  Function for getting all the claim topic of trusted claim issuer
     * @param   trustedIssuer  is the address of the trusted issuer's ClaimIssuer contract
     * @return  uint256[]  .
     */
    function getTrustedIssuerClaimTopics(
        IClaimIssuer trustedIssuer
    )
        public
        view
        override
        mIssuerExists(address(trustedIssuer))
        returns (uint256[] memory)
    {
        return _trustedIssuerClaimTopics[address(trustedIssuer)];
    }

    /**
     * @notice  Function for getting all the claim topic of trusted claim issuer
     * @param   trustedIssuer  is the address of the trusted issuer's ClaimIssuer contract
     * @return  uint256[]  .
     */
    function getTrustedIssuerIndexing(
        address trustedIssuer
    ) public view returns (uint256) {
        return _trustedIssuersIndexing[trustedIssuer];
    }

    /**
     * @notice  Function for checking if the trusted claim issuer is allowed
     * @param   issuer the address of the trusted issuer's ClaimIssuer contract
     * @param   claimTopic the Claim Topic that has to be checked to know if the `issuer` is allowed to emit it
     * @return  bool  .
     */
    function hasClaimTopic(
        address issuer,
        uint256 claimTopic
    ) public view override returns (bool) {
        uint256[] memory claimTopics = _trustedIssuerClaimTopics[issuer];
        for (uint256 i = 0; i < _trustedIssuerClaimTopics[issuer].length; i++) {
            if (claimTopics[i] == claimTopic) {
                return true;
            }
        }
        return false;
    }

    function _addTrustedIssuer(
        IClaimIssuer trustedIssuer,
        uint256[] calldata claimTopics
    )
        internal
        mClaimTopicsNotEmpty(claimTopics)
        mAddressNotZero(address(trustedIssuer))
    {
        require(
            _trustedIssuerClaimTopics[address(trustedIssuer)].length == 0,
            "trusted Issuer already exists"
        );
        _trustedIssuers.push(trustedIssuer);
        _trustedIssuerClaimTopics[address(trustedIssuer)] = claimTopics;
        _trustedIssuersIndexing[address(trustedIssuer)] =
            _trustedIssuers.length -
            1;
        emit TrustedIssuerAdded(trustedIssuer, claimTopics);
    }

    function _removeTrustedIssuer(
        IClaimIssuer trustedIssuer
    )
        internal
        mIssuerExists(address(trustedIssuer))
        mAddressNotZero(address(trustedIssuer))
    {
        uint256 length = _trustedIssuers.length;
        uint256 trustedIssuerIndex = _trustedIssuersIndexing[
            address(trustedIssuer)
        ];
        _trustedIssuers[trustedIssuerIndex] = _trustedIssuers[length - 1];
        _trustedIssuersIndexing[
            address(_trustedIssuers[length - 1])
        ] = trustedIssuerIndex;
        _trustedIssuers.pop();
        delete _trustedIssuerClaimTopics[address(trustedIssuer)];
        delete _trustedIssuersIndexing[address(trustedIssuer)];
        emit TrustedIssuerRemoved(trustedIssuer);
    }

    function _updateIssuerClaimTopics(
        IClaimIssuer trustedIssuer,
        uint256[] calldata claimTopics
    )
        internal
        mIssuerExists(address(trustedIssuer))
        mAddressNotZero(address(trustedIssuer))
        mClaimTopicsNotEmpty(claimTopics)
    {
        _trustedIssuerClaimTopics[address(trustedIssuer)] = claimTopics;
        emit TrustedIssuerClaimTopicsUpdated(trustedIssuer, claimTopics);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __TrustedIssuersCollection_init() internal onlyInitializing {
        __Managerable_init();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IERC734} from "./interfaces/IERC734.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the `IERC734` "KeyHolder" and the `IERC735` "ClaimHolder" interfaces
 * into a common Identity Contract.
 * This implementation has a separate contract were it declares all storage,
 * allowing for it to be used as an upgradable logic contract.
 */
contract KeyHolder is Initializable, IERC734 {
    // keys as defined by IERC734
    mapping(bytes32 => Key) internal _keys;

    // keys for a given purpose
    // purpose 1 = MANAGEMENT
    // purpose 2 = ACTION
    // purpose 3 = CLAIM
    mapping(uint256 => bytes32[]) internal _keysByPurpose;

    uint256 public constant KEY_TYPE_ECDSA = 1;
    uint256 public constant KEY_PURPOSE_MANAGEMENT_KEY = 1;
    uint256 public constant KEY_PURPOSE_ACTION_KEY = 2;
    uint256 public constant KEY_PURPOSE_CLAIM_SIGNER_KEY = 3;
    uint256 public constant KEY_PURPOSE_ENCRYPTION_KEY = 4;

    // status on initialization
    bool internal _initialized = false;

    // execution data
    mapping(uint256 => Execution) internal _executions;

    // nonce used by the execute/approve function
    uint256 internal _executionNonce;

    // todo: add modifier only action key
    /**
     * @notice requires management key to call this function, or internal call
     */
    modifier mOnlyManagementKey() {
        require(
            msg.sender == address(this) ||
                keyHasPurpose(
                    keccak256(abi.encode(msg.sender)),
                    KEY_PURPOSE_MANAGEMENT_KEY
                ),
            "Sender does not have management key"
        );
        _;
    }

    /**
     * @dev See {IERC734-execute}.
     * @notice Passes an execution instruction to the keymanager.
     * If the sender is an ACTION key and the destination address is not the identity contract itself, then the
     * execution is immediately approved and performed.
     * If the destination address is the identity itself, then the execution would be performed immediately only if
     * the sender is a MANAGEMENT key.
     * Otherwise, the execute method triggers an ExecutionRequested event, and the execution request must be approved
     * using the `approve` method.
     * @return executionId to use in the approve function, to approve or reject this execution.
     */
    function execute(
        address to,
        uint256 value,
        bytes memory data
    ) external payable override returns (uint256 executionId) {
        uint256 _executionId = _executionNonce;
        require(!_executions[_executionId].executed, "Already executed");
        _executions[_executionId].to = to;
        _executions[_executionId].value = value;
        _executions[_executionId].data = data;
        _executionNonce++;

        emit ExecutionRequested(_executionId, to, value, data);

        // todo: inconsistency in description and logic
        // according to description it should be smth like
        /* if (keyHasPurpose(keccak256(abi.encode(msg.sender)), 1)) {
            approve(_executionId, true);
        }
        else if (_to != address(this) && keyHasPurpose(keccak256(abi.encode(msg.sender)), 2)){
            approve(_executionId, true);
        }
        */
        if (
            keyHasPurpose(
                keccak256(abi.encode(msg.sender)),
                KEY_PURPOSE_MANAGEMENT_KEY
            ) ||
            keyHasPurpose(
                keccak256(abi.encode(msg.sender)),
                KEY_PURPOSE_ACTION_KEY
            )
        ) {
            approve(_executionId, true);
        }

        return _executionId;
    }

    /**
     * @dev See {IERC734-getKey}.
     * @notice Implementation of the getKey function from the ERC-734 standard
     * @param publicKey The public key.  for non-hex and long keys, its the Keccak256 hash of the key
     * @return purposes Returns the full key data, if present in the identity.
     * @return keyType Returns the full key data, if present in the identity.
     * @return key Returns the full key data, if present in the identity.
     */
    function getKey(
        bytes32 publicKey
    )
        external
        view
        override
        returns (uint256[] memory purposes, uint256 keyType, bytes32 key)
    {
        return (
            _keys[publicKey].purposes,
            _keys[publicKey].keyType,
            _keys[publicKey].key
        );
    }

    /**
     * @dev See {IERC734-getKeypurpose}.
     * @notice gets the purpose of a key
     * @param key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
     * @return purposes Returns the purpose of the specified key
     */
    function getKeyPurposes(
        bytes32 key
    ) external view override returns (uint256[] memory purposes) {
        return (_keys[key].purposes);
    }

    /**
     * @dev See {IERC734-getKeysByPurpose}.
     * @notice gets all the keys with a specific purpose from an identity
     * @param purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
     * @return keys Returns an array of public key bytes32 hold by this identity and having the specified purpose
     */
    function getKeysByPurpose(
        uint256 purpose
    ) external view override returns (bytes32[] memory keys) {
        return _keysByPurpose[purpose];
    }

    /**
     * @notice implementation of the addKey function of the ERC-734 standard
     * Adds a _key to the identity. The _purpose specifies the purpose of key. Initially we propose four purpose:
     * 1: MANAGEMENT keys, which can manage the identity
     * 2: ACTION keys, which perform actions in this identities name (signing, logins, transactions, etc.)
     * 3: CLAIM signer keys, used to sign claims on other identities which need to be revokable.
     * 4: ENCRYPTION keys, used to encrypt data e.g. hold in claims.
     * MUST only be done by keys of purpose 1, or the identity itself.
     * If its the identity itself, the approval process will determine its approval.
     * @param key keccak256 representation of an ethereum address
     * @param keyType type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
     * @param purposeType a uint256 specifying the key type, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
     * @return success Returns TRUE if the addition was successful and FALSE if not
     */
    function addKey(
        bytes32 key,
        uint256 purposeType,
        uint256 keyType
    ) public override mOnlyManagementKey returns (bool success) {
        if (_keys[key].key == key) {
            uint256[] memory _purposes = _keys[key].purposes;
            for (
                uint256 keyPurposeIndex = 0;
                keyPurposeIndex < _purposes.length;
                keyPurposeIndex++
            ) {
                uint256 purpose = _purposes[keyPurposeIndex];

                if (purpose == purpose) {
                    revert("Conflict: Key already has purpose");
                }
            }

            _keys[key].purposes.push(purposeType);
        } else {
            _keys[key].key = key;
            _keys[key].purposes = [purposeType];
            _keys[key].keyType = keyType;
        }

        _keysByPurpose[purposeType].push(key);

        emit KeyAdded(key, purposeType, keyType);

        return true;
    }

    /**
     *  @dev See {IERC734-approve}.
     *  @notice Approves an execution or claim addition.
     *  If the sender is an ACTION key and the destination address is not the identity contract itself, then the
     *  approval is authorized and the operation would be performed.
     *  If the destination address is the identity itself, then the execution would be authorized and performed only
     *  if the sender is a MANAGEMENT key.
     */
    function approve(
        uint256 id,
        bool approval
    ) public override returns (bool success) {
        require(
            id < _executionNonce,
            "Cannot approve a non-existing execution"
        );

        // todo: inconsistency in description and logic
        // according to description it should be smth like
        /*
        if(_executions[_id].to == address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Sender does not have management key");
        }
        else {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), "Sender does not have action key");
        }
        */
        // description
        require(
            keyHasPurpose(
                keccak256(abi.encode(msg.sender)),
                KEY_PURPOSE_ACTION_KEY
            ),
            "Sender does not have action key"
        );

        emit Approved(id, approval);

        if (approval == true) {
            _executions[id].approved = true;

            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = _executions[id].to.call{
                value: (_executions[id].value)
            }(_executions[id].data);

            if (success) {
                emit Executed(
                    id,
                    _executions[id].to,
                    _executions[id].value,
                    _executions[id].data
                );

                return true;
            } else {
                emit ExecutionFailed(
                    id,
                    _executions[id].to,
                    _executions[id].value,
                    _executions[id].data
                );

                revert("Execution failed.");
            }
        } else {
            _executions[id].approved = false;
        }
        return true;
    }

    /**
     * @dev See {IERC734-removeKey}.
     * @notice Remove the purpose from a key.
     */
    function removeKey(
        bytes32 key,
        uint256 purpose
    ) public override mOnlyManagementKey returns (bool success) {
        require(_keys[key].key == key, "NonExisting: Key isn't registered");
        uint256[] memory _purposes = _keys[key].purposes;

        uint256 purposeIndex = 0;
        while (_purposes[purposeIndex] != purpose) {
            purposeIndex++;

            if (purposeIndex == _purposes.length) {
                revert("Key doesn't have such purpose");
            }
        }

        _purposes[purposeIndex] = _purposes[_purposes.length - 1];
        _keys[key].purposes = _purposes;
        _keys[key].purposes.pop();

        uint256 keyIndex = 0;
        uint256 arrayLength = _keysByPurpose[purpose].length;

        while (_keysByPurpose[purpose][keyIndex] != key) {
            keyIndex++;

            if (keyIndex >= arrayLength) {
                break;
            }
        }

        _keysByPurpose[purpose][keyIndex] = _keysByPurpose[purpose][
            arrayLength - 1
        ];
        _keysByPurpose[purpose].pop();

        uint256 keyType = _keys[key].keyType;

        if (_purposes.length - 1 == 0) {
            delete _keys[key];
        }

        emit KeyRemoved(key, purpose, keyType);

        return true;
    }

    /**
     * @dev See {IERC734-keyHasPurpose}.
     * @notice Returns true if the key has MANAGEMENT purpose or the specified purpose.
     */
    function keyHasPurpose(
        bytes32 key,
        uint256 purpose
    ) public view virtual override returns (bool result) {
        Key memory keyBase = _keys[key];
        if (keyBase.key == 0) return false;

        for (
            uint256 keyPurposeIndex = 0;
            keyPurposeIndex < keyBase.purposes.length;
            keyPurposeIndex++
        ) {
            uint256 purposeBase = keyBase.purposes[keyPurposeIndex];

            // todo compare with constant
            if (purposeBase == 1 || purposeBase == purpose) return true;
        }

        return false;
    }

    /**
     * @notice Initializer internal function for the Identity contract.
     *
     * @param initialManagementKey The ethereum address to be set as the management key of the identity.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Key_init(
        address initialManagementKey
    ) internal onlyInitializing {
        bytes32 _key = keccak256(abi.encode(initialManagementKey));
        _keys[_key].key = _key;
        _keys[_key].purposes = [KEY_PURPOSE_MANAGEMENT_KEY];
        _keys[_key].keyType = KEY_TYPE_ECDSA;
        _keysByPurpose[KEY_PURPOSE_MANAGEMENT_KEY].push(_key);
        emit KeyAdded(_key, KEY_PURPOSE_MANAGEMENT_KEY, KEY_TYPE_ECDSA);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Key_init(
        address initialManagementKey,
        address initialClaimKey
    ) internal onlyInitializing {
        bytes32 _key = keccak256(abi.encode(initialManagementKey));
        _keys[_key].key = _key;
        _keys[_key].purposes = [KEY_PURPOSE_MANAGEMENT_KEY];
        _keys[_key].keyType = KEY_TYPE_ECDSA;
        _keysByPurpose[KEY_PURPOSE_MANAGEMENT_KEY].push(_key);
        emit KeyAdded(_key, KEY_PURPOSE_MANAGEMENT_KEY, KEY_TYPE_ECDSA);

        bytes32 _gatekeeperKey = keccak256(abi.encode(initialClaimKey));
        _keys[_gatekeeperKey].key = _gatekeeperKey;
        _keys[_gatekeeperKey].purposes = [KEY_PURPOSE_CLAIM_SIGNER_KEY];
        _keys[_gatekeeperKey].keyType = KEY_TYPE_ECDSA;
        _keysByPurpose[KEY_PURPOSE_CLAIM_SIGNER_KEY].push(_gatekeeperKey);
        emit KeyAdded(
            _gatekeeperKey,
            KEY_PURPOSE_CLAIM_SIGNER_KEY,
            KEY_TYPE_ECDSA
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {ClaimHolder} from "./ClaimHolder.sol";
import {IIdentity} from "./interfaces/IIdentity.sol";
import {IIdentityCallbackHandler} from "./interfaces/IIdentityCallbackHandler.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the `IERC734` "KeyHolder" and the `IERC735` "ClaimHolder" interfaces
 * into a common Identity Contract.
 * This implementation has a separate contract were it declares all storage,
 * allowing for it to be used as an upgradable logic contract.
 */
contract Identity is Initializable, IIdentity, ClaimHolder {
    IIdentityCallbackHandler internal _creator;

    function initialize(
        address initialManagementKey,
        address initialClaimKey
    ) external virtual initializer {
        require(
            initialManagementKey != address(0),
            "Invalid argument - zero address"
        );
        __Key_init(initialManagementKey, initialClaimKey);
        _setCreator(msg.sender);
    }

    function getCreator() public view returns (IIdentityCallbackHandler) {
        return _creator;
    }

    function _setCreator(address creatorAddress) internal {
        require(
            IIdentityCallbackHandler(creatorAddress).supportsInterface(
                type(IIdentityCallbackHandler).interfaceId
            ),
            "Creator interface is incorrect"
        );
        _creator = IIdentityCallbackHandler(creatorAddress);
    }

    function _afterClaimAdded(
        bytes32 claimId,
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    ) internal override {
        IIdentityCallbackHandler creator = getCreator();
        if (address(creator) != address(0)) {
            creator.addClaimCallback(
                claimId,
                topic,
                scheme,
                issuer,
                signature,
                data,
                uri
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IdentitiesFactoryClone} from "./factories/IdentitiesFactoryClone.sol";
import {IIdentitiesFactory} from "./interfaces/IIdentitiesFactory.sol";
import {IdentitiesCollection} from "./IdentitiesCollection.sol";
import {IIdentity} from "./interfaces/IIdentity.sol";
import {Chargable} from "./extensions/Chargable.sol";

contract IdentitiesFactory is
    Initializable,
    IIdentitiesFactory,
    IdentitiesFactoryClone,
    Chargable,
    IdentitiesCollection
{
    function setIdentityImplementation(
        address newIdentityImplementation
    ) public onlyRole(MANAGER_ROLE) {
        _setIdentityImplementation(newIdentityImplementation);
    }

    function deployIdentity(
        address userAddress
    )
        public
        onlyRole(MANAGER_ROLE)
        mAddressNotZero(userAddress)
        returns (address)
    {
        return _deployIdentity(userAddress);
    }

    function deployIdentityWithClaim(
        address userAddress,
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    )
        public
        onlyRole(MANAGER_ROLE)
        mAddressNotZero(userAddress)
        returns (address)
    {
        address identityProxyAddress = _deployIdentityWithClaim(
            userAddress,
            topic,
            scheme,
            issuer,
            signature,
            data,
            uri
        );
        return identityProxyAddress;
    }

    function deploySelfIdentity()
        public
        payable
        mChargesFee(CHARGEABLE_TYPE_DEPLOY_IDENTITY)
        mIdentityNotRegistered(msg.sender)
        returns (address)
    {
        return _deployIdentity(msg.sender);
    }

    function deploySelfIdentityWithClaim(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    )
        public
        payable
        mChargesFee(CHARGEABLE_TYPE_DEPLOY_IDENTITY)
        mIdentityNotRegistered(msg.sender)
        returns (address)
    {
        address identityProxyAddress = _deployIdentityWithClaim(
            msg.sender,
            topic,
            scheme,
            issuer,
            signature,
            data,
            uri
        );
        return identityProxyAddress;
    }

    function getIdentityImplementation() public view returns (address) {
        return _getIdentityImplementation();
    }

    function _afterIdentityDeployed(
        address userAddress,
        address identityAddress
    ) internal virtual override {
        _registerIdentity(userAddress, identityAddress);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __IdentitiesFactory_init(
        address identityImplementation,
        address payable collectorWallet
    ) internal onlyInitializing {
        __IdentitiesCollection_init();
        __IdentitiesFactoryClone_init(identityImplementation);
        __Chargable_init(collectorWallet);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Managerable} from "./extensions/Managerable.sol";
import {IIdentity} from "./interfaces/IIdentity.sol";
import {IIdentitiesCollection} from "./interfaces/IIdentitiesCollection.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation managing identities collection
 */
contract IdentitiesCollection is
    Initializable,
    Managerable,
    IIdentitiesCollection
{
    mapping(address => address) internal _identities; // wallet address => identity address
    mapping(address => address) internal _wallets; // reverse mapping: identity address => wallet address

    /**
     * @dev  Requires identity to be assigned and not be default zero address
     * @param   userAddress - user wallet address
     */
    modifier mIdentityNotRegistered(address userAddress) {
        require(
            address(_identities[userAddress]) == address(0),
            "User should not have identity assigned"
        );
        _;
    }

    /**
     * @dev  Requires identity to be assigned and not be default zero address
     * @param   userAddress - user wallet address
     */
    modifier mIdentityRegistered(address userAddress) {
        require(
            address(_identities[userAddress]) != address(0),
            "User does not have identity assigned"
        );
        _;
    }

    /**
     * @dev  Set an identity contract corresponding to a user address.
     * @param   userAddress  - user wallet address
     * @param   identity  identity interface
     */
    function registerIdentity(
        address userAddress,
        address identity
    )
        public
        onlyRole(MANAGER_ROLE)
        mAddressNotZero(address(identity))
        mAddressNotZero(userAddress)
    {
        _registerIdentity(userAddress, identity);
    }

    /**
     * @dev  Delete user registered instance from the identity registry.
     * @param   userAddress  - user wallet address
     */
    function deleteIdentity(
        address userAddress
    )
        public
        onlyRole(MANAGER_ROLE)
        mAddressNotZero(userAddress)
        mIdentityRegistered(userAddress)
    {
        _deleteIdentity(userAddress);
    }

    /**
     * @dev  Returns whether user identity was registered for wallet
     * @param   userAddress  - user wallet address
     * @return  bool  .
     */
    function isWalletRegistered(
        address userAddress
    ) public view override returns (bool) {
        return address(_identities[userAddress]) != address(0);
    }

    /**
     * @dev  Returns whether identity was registered
     * @param   identityAddress  - user wallet address
     * @return  bool
     */
    function isIdentityRegistered(
        address identityAddress
    ) public view override returns (bool) {
        return address(_wallets[identityAddress]) != address(0);
    }

    /**
     * @dev  Returns the identity address of user
     * @param   userAddress  - user wallet address
     * @return  address  .
     */
    function getIdentity(
        address userAddress
    ) public view override returns (address) {
        return _identities[userAddress];
    }

    /**
     * @dev  Returns the identity wallet address
     * @param   identityAddress  - user identity address
     * @return  address  user wallet address
     */
    function getIdentityWallet(
        address identityAddress
    ) public view override returns (address) {
        return _wallets[identityAddress];
    }

    /**
     * @notice  Register user identity corresponding to a user address
     * @param   userAddress  - user wallet address
     * @param   identity  identity interface
     */
    function _registerIdentity(address userAddress, address identity) internal {
        address oldIdentity = _identities[userAddress];
        _identities[userAddress] = identity;
        emit IdentityRegistered(userAddress, oldIdentity, identity);
    }

    /**
     * @notice  Delete user registered instance from the identity registry.
     * @param   userAddress  - user wallet address
     */
    function _deleteIdentity(address userAddress) internal {
        delete _identities[userAddress];
        emit IdentityRemoved(userAddress, _identities[userAddress]);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __IdentitiesCollection_init() internal onlyInitializing {
        __Managerable_init();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IClaimTopicsCollection} from "./interfaces/IClaimTopicsCollection.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Managerable} from "./extensions/Managerable.sol";

contract ClaimTopicsCollection is
    Initializable,
    IClaimTopicsCollection,
    Managerable
{
    uint256[] private _claimTopics;
    mapping(uint256 => uint256) private _claimTopicsIndexing;

    event ClaimTopicAdded(uint256 indexed claimTopic);
    event ClaimTopicRemoved(uint256 indexed claimTopic);

    /**
     * @dev  Get the trusted claim topics for the security token
     * @return  uint256[]  .
     */
    function getClaimTopics()
        external
        view
        override
        returns (uint256[] memory)
    {
        return _claimTopics;
    }

    /**
     * @dev  Remove a trusted claim topic (For example: KYC=1, AML=2)
     * @param   claimTopic  claim topic identification
     */
    function removeClaimTopic(
        uint256 claimTopic
    ) public onlyRole(MANAGER_ROLE) {
        _removeClaimTopic(claimTopic);
    }

    /**
     * @dev  Add a trusted claim topic (For example: KYC=1, AML=2)
     * @param   claimTopic  claim topic identification
     */
    function addClaimTopic(uint256 claimTopic) public onlyRole(MANAGER_ROLE) {
        _addClaimTopic(claimTopic);
    }

    /**
     * @dev  check if claim topis is valid
     * @param   claimTopic  claim topic identification
     * @return  bool  .
     */
    function isClaimTopic(
        uint256 claimTopic
    ) public view override returns (bool) {
        return _claimTopics[_claimTopicsIndexing[claimTopic]] == claimTopic;
    }

    /**
     * @dev  Add a batch of trusted claim topics
     * @param   claimTopics  claim topic identification
     */
    function _addClaimTopicBatch(uint256[] memory claimTopics) internal {
        for (uint256 i = 0; i < claimTopics.length; i++) {
            _addClaimTopic(claimTopics[i]);
        }
    }

    function _addClaimTopic(uint256 claimTopic) internal {
        for (uint256 i = 0; i < _claimTopics.length; i++) {
            require(!isClaimTopic(claimTopic), "ClaimTopic already exists");
        }
        _claimTopics.push(claimTopic);
        _claimTopicsIndexing[claimTopic] = _claimTopics.length - 1;
        emit ClaimTopicAdded(claimTopic);
    }

    function _removeClaimTopic(uint256 claimTopic) internal {
        require(isClaimTopic(claimTopic), "ClaimTopic does not exist");
        uint256 length = _claimTopics.length;
        uint256 claimTopicsIndex = _claimTopicsIndexing[claimTopic];
        _claimTopics[claimTopicsIndex] = _claimTopics[length - 1];
        _claimTopicsIndexing[_claimTopics[length - 1]] = claimTopicsIndex;
        _claimTopics.pop();
        delete _claimTopicsIndexing[claimTopic];
        emit ClaimTopicRemoved(claimTopic);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ClaimTopicsCollection_init(
        uint256[] memory claimTopic
    ) internal onlyInitializing {
        __Managerable_init();

        _addClaimTopicBatch(claimTopic);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IERC735} from "./interfaces/IERC735.sol";
import {KeyHolder} from "./KeyHolder.sol";
import {IClaimIssuer, IIdentity} from "./interfaces/IClaimIssuer.sol";

// **Warning!** This file is a protoype version of our work around ERC 725.
// This file is now out of date and **should not be used**.
// Our current identity contracts are here:
// https://github.com/OriginProtocol/origin/tree/master/origin-contracts/contracts/identity

contract ClaimHolder is KeyHolder, IERC735 {
    // claims held by the identity
    mapping(bytes32 => Claim) internal _claims;

    // array of claims for a given topic
    mapping(uint256 => bytes32[]) internal _claimsByTopic;

    mapping(bytes32 => Claim) public claims;

    /**
     * @notice requires claim key to call this function, or internal call
     */
    modifier mOnlyClaimKey() {
        require(
            msg.sender == address(this) ||
                keyHasPurpose(
                    keccak256(abi.encode(msg.sender)),
                    KEY_PURPOSE_CLAIM_SIGNER_KEY
                ),
            "Sender does not have claim signer key"
        );
        _;
    }

    /**
     * @dev See {IERC735-getClaimIdsByTopic}.
     * @notice Implementation of the getClaimIdsByTopic function from the ERC-735 standard.
     * used to get all the claims from the specified topic
     * @param topic The identity of the claim i.e. keccak256(abi.encode(issuer, topic))
     * @return claimIds Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(
        uint256 topic
    ) external view override returns (bytes32[] memory claimIds) {
        return _claimsByTopic[topic];
    }

    /**
     * @dev See {IERC735-addClaim}.
     * @notice Implementation of the addClaim function from the ERC-735 standard
     *  Require that the msg.sender has claim signer key.
     *
     * @param topic The type of claim
     * @param scheme The scheme with which this claim SHOULD be verified or how it should be processed.
     * @param issuer The issuers identity contract address, or the address used to sign the above signature.
     * @param signature Signature which is the proof that the claim issuer issued a claim of topic for this identity.
     * it MUST be a signed message of the following structure:
     * keccak256(abi.encode(address identityHolder_address, uint256 _ topic, bytes data))
     * @param data The hash of the claim data, sitting in another
     * location, a bit-mask, call data, or actual data based on the claim scheme.
     * @param uri The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
     *
     * @return claimRequestId Returns claimRequestId: COULD be
     * send to the approve function, to approve or reject this claim.
     * triggers ClaimAdded event.
     */
    function addClaim(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    ) public override mOnlyClaimKey returns (bytes32 claimRequestId) {
        if (issuer != address(this)) {
            require(
                IClaimIssuer(issuer).isClaimValid(
                    IIdentity(address(this)),
                    topic,
                    signature,
                    data
                ),
                "invalid claim"
            );
        }

        bytes32 claimId = keccak256(abi.encode(issuer, topic));

        if (_claims[claimId].issuer != issuer) {
            _claimsByTopic[topic].push(claimId);
        }

        _claims[claimId].topic = topic;
        _claims[claimId].scheme = scheme;
        _claims[claimId].issuer = issuer;
        _claims[claimId].signature = signature;
        _claims[claimId].data = data;
        _claims[claimId].uri = uri;

        emit ClaimAdded(claimId, topic, scheme, issuer, signature, data, uri);
        _afterClaimAdded(claimId, topic, scheme, issuer, signature, data, uri);

        return claimId;
    }

    /**
     * @dev See {IERC735-removeClaim}.
     * @notice Implementation of the removeClaim function from the ERC-735 standard
     * Require that the msg.sender has management key.
     * Can only be removed by the claim issuer, or the claim holder itself.
     *
     * @param claimId The identity of the claim i.e. keccak256(abi.encode(issuer, topic))
     *
     * @return success Returns TRUE when the claim was removed.
     * triggers ClaimRemoved event
     */
    function removeClaim(
        bytes32 claimId
    ) public override mOnlyClaimKey returns (bool success) {
        uint256 topic = _claims[claimId].topic;
        if (topic == 0) {
            revert("There is no claim with this ID");
        }

        uint256 claimIndex = 0;
        while (_claimsByTopic[topic][claimIndex] != claimId) {
            claimIndex++;

            if (claimIndex >= _claimsByTopic[topic].length) {
                break;
            }
        }

        _claimsByTopic[topic][claimIndex] = _claimsByTopic[topic][
            _claimsByTopic[topic].length - 1
        ];
        _claimsByTopic[topic].pop();

        emit ClaimRemoved(
            claimId,
            topic,
            _claims[claimId].scheme,
            _claims[claimId].issuer,
            _claims[claimId].signature,
            _claims[claimId].data,
            _claims[claimId].uri
        );

        delete _claims[claimId];

        return true;
    }

    /**
     * @dev See {IERC735-getClaim}.
     * @notice Implementation of the getClaim function from the ERC-735 standard.
     *
     * @param claimId The identity of the claim i.e. keccak256(abi.encode(issuer, topic))
     *
     * @return topic Returns all the parameters of the claim for the
     * specified claimId (topic, scheme, signature, issuer, data, uri) .
     * @return scheme Returns all the parameters of the claim for the
     * specified claimId (topic, scheme, signature, issuer, data, uri) .
     * @return issuer Returns all the parameters of the claim for the
     * specified claimId (topic, scheme, signature, issuer, data, uri) .
     * @return signature Returns all the parameters of the claim for the
     * specified claimId (topic, scheme, signature, issuer, data, uri) .
     * @return data Returns all the parameters of the claim for the
     * specified claimId (topic, scheme, signature, issuer, data, uri) .
     * @return uri Returns all the parameters of the claim for the
     * specified claimId (topic, scheme, signature, issuer, data, uri) .
     */
    function getClaim(
        bytes32 claimId
    )
        public
        view
        override
        returns (
            uint256 topic,
            uint256 scheme,
            address issuer,
            bytes memory signature,
            bytes memory data,
            string memory uri
        )
    {
        return (
            _claims[claimId].topic,
            _claims[claimId].scheme,
            _claims[claimId].issuer,
            _claims[claimId].signature,
            _claims[claimId].data,
            _claims[claimId].uri
        );
    }

    /* solhint-disable no-empty-blocks */
    function _afterClaimAdded(
        bytes32 claimId,
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    ) internal virtual {}
    /* solhint-enable no-empty-blocks */
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
library Clones {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
                        StringsUpgradeable.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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