// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {ClaimIssuer} from "./ClaimIssuer.sol";
import {Identity} from "./Identity.sol";
import {IClaimRevoker} from "./interfaces/IClaimRevoker.sol";
import {IIdentity} from "./interfaces/IIdentity.sol";

contract ClaimIssuerRevocable is ClaimIssuer, IClaimRevoker {
    mapping(bytes => bool) private _revokedClaims;

    /**
     *  @dev See {IClaimIssuer-revokeClaim}.
     */
    function revokeClaim(
        bytes32 claimId,
        address identity
    ) external override mOnlyManagementKey returns (bool) {
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;

        (foundClaimTopic, scheme, issuer, sig, data, ) = Identity(identity)
            .getClaim(claimId);

        require(!_revokedClaims[sig], "Claim already revoked");

        _revokedClaims[sig] = true;
        emit ClaimRevoked(sig);
        return true;
    }

    /**
     *  @dev See {IClaimIssuer-isClaimRevoked}.
     */
    function isClaimRevoked(
        bytes memory sig
    ) public view override returns (bool) {
        return _revokedClaims[sig];
    }

    /**
     *  @dev See {IClaimIssuer-isClaimValid}.
     */
    function _isClaimValid(
        IIdentity identity,
        uint256 claimTopic,
        bytes memory sig,
        bytes memory data
    ) internal view override returns (bool claimValid) {
        return (super._isClaimValid(identity, claimTopic, sig, data) &&
            !isClaimRevoked(sig));
    }
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

interface IClaimRevoker {
    event ClaimRevoked(bytes sig);

    function revokeClaim(
        bytes32 claimId,
        address identity
    ) external returns (bool);

    function isClaimRevoked(bytes calldata sig) external view returns (bool);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {ClaimHolder} from "./ClaimHolder.sol";
import {IIdentity} from "./interfaces/IIdentity.sol";
import {IClaimIssuer} from "./interfaces/IClaimIssuer.sol";

contract ClaimIssuer is IClaimIssuer, ClaimHolder {
    /**
     * @notice When using this contract as an implementation for a proxy, call this initializer with a delegatecall.
     *
     * @param initialManagementKey The ethereum address to be set as the management key of the ONCHAINID.
     */
    function initialize(
        address initialManagementKey
    ) external virtual initializer {
        require(
            initialManagementKey != address(0),
            "Invalid argument - zero address"
        );
        __Key_init(initialManagementKey);
    }

    /**
     *  @dev See {IClaimIssuer-isClaimValid}.
     */
    function isClaimValid(
        IIdentity identity,
        uint256 claimTopic,
        bytes memory sig,
        bytes memory data
    ) external view override returns (bool claimValid) {
        return _isClaimValid(identity, claimTopic, sig, data);
    }

    /**
     *  @dev helper method for unit tests - should be deleted later
     */
    function getHashes(
        IIdentity identity,
        uint256 claimTopic,
        bytes memory data
    ) public view virtual returns (bytes32, bytes32) {
        bytes32 dataHash = keccak256(abi.encode(identity, claimTopic, data));
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)
        );
        return (dataHash, prefixedHash);
    }

    /**
     *  @dev See {IClaimIssuer-getRecoveredAddress}.
     */
    function getRecoveredAddress(
        bytes memory sig,
        bytes32 dataHash
    ) public pure returns (address addr) {
        bytes32 ra;
        bytes32 sa;
        uint8 va;

        // Check the signature length
        if (sig.length != 65) {
            return address(0);
        }

        // Divide the signature in r, s and v variables
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ra := mload(add(sig, 32))
            sa := mload(add(sig, 64))
            va := byte(0, mload(add(sig, 96)))
        }

        if (va < 27) {
            va += 27;
        }

        address recoveredAddress = ecrecover(dataHash, va, ra, sa);

        return (recoveredAddress);
    }

    function _isClaimValid(
        IIdentity identity,
        uint256 claimTopic,
        bytes memory sig,
        bytes memory data
    ) internal view virtual returns (bool claimValid) {
        bytes32 dataHash = keccak256(abi.encode(identity, claimTopic, data));
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)
        );

        address recovered = getRecoveredAddress(sig, prefixedHash);
        bytes32 hashedAddr = keccak256(abi.encode(recovered));

        return keyHasPurpose(hashedAddr, KEY_PURPOSE_CLAIM_SIGNER_KEY);
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