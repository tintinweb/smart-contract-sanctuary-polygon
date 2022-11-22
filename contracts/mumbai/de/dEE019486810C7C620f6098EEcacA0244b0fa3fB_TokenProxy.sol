// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./interface/IClaimIssuer.sol";
import "./Identity.sol";

contract ClaimIssuer is IClaimIssuer, Identity {
    mapping (bytes => bool) public revokedClaims;

    constructor(address initialManagementKey) Identity(initialManagementKey, false) {}

    /**
     * @dev Revoke a claim previously issued, the claim is no longer considered as valid after revocation.
     * @param _claimId the id of the claim
     * @param _identity the address of the identity contract
     * @return isRevoked true when the claim is revoked
     */
    function revokeClaim(bytes32 _claimId, address _identity) public override delegatedOnly returns(bool) {
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory  sig;
        bytes  memory data;

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Permissions: Sender does not have management key");
        }

        ( foundClaimTopic, scheme, issuer, sig, data, ) = Identity(_identity).getClaim(_claimId);

        revokedClaims[sig] = true;
        return true;
    }

    /**
     * @dev Returns revocation status of a claim.
     * @param _sig the signature of the claim
     * @return isRevoked true if the claim is revoked and false otherwise
     */
    function isClaimRevoked(bytes memory _sig) public override view returns (bool) {
        if (revokedClaims[_sig]) {
            return true;
        }

        return false;
    }

    /**
     * @dev Checks if a claim is valid.
     * @param _identity the identity contract related to the claim
     * @param claimTopic the claim topic of the claim
     * @param sig the signature of the claim
     * @param data the data field of the claim
     * @return claimValid true if the claim is valid, false otherwise
     */
    function isClaimValid(IIdentity _identity, uint256 claimTopic, bytes memory sig, bytes memory data) public override view returns (bool claimValid)
    {
        bytes32 dataHash = keccak256(abi.encode(_identity, claimTopic, data));
        // Use abi.encodePacked to concatenate the message prefix and the message to sign.
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));

        // Recover address of data signer
        address recovered = getRecoveredAddress(sig, prefixedHash);

        // Take hash of recovered address
        bytes32 hashedAddr = keccak256(abi.encode(recovered));

        // Does the trusted identifier have they key which signed the user's claim?
        //  && (isClaimRevoked(_claimId) == false)
        if (keyHasPurpose(hashedAddr, 3) && (isClaimRevoked(sig) == false)) {
            return true;
        }

        return false;
    }

    function getRecoveredAddress(bytes memory sig, bytes32 dataHash)
        public override
        pure
        returns (address addr)
    {
        bytes32 ra;
        bytes32 sa;
        uint8 va;

        // Check the signature length
        if (sig.length != 65) {
            return address(0);
        }

        // Divide the signature in r, s and v variables
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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./interface/IIdentity.sol";
import "./version/Version.sol";
import "./storage/Storage.sol";

/**
 * @dev Implementation of the `IERC734` "KeyHolder" and the `IERC735` "ClaimHolder" interfaces into a common Identity Contract.
 * This implementation has a separate contract were it declares all storage, allowing for it to be used as an upgradable logic contract.
 */
contract Identity is Storage, IIdentity, Version {
    bool private initialized = false;
    bool private canInteract = true;

    constructor(address initialManagementKey, bool _isLibrary) {
        canInteract = !_isLibrary;

        if (canInteract) {
            __Identity_init(initialManagementKey);
        } else {
            initialized = true;
        }
    }

    /**
     * @notice Prevent any direct calls to the implementation contract (marked by canInteract = false).
     */
    modifier delegatedOnly() {
        require(canInteract == true, "Interacting with the library contract is forbidden.");
        _;
    }

    /**
     * @notice When using this contract as an implementation for a proxy, call this initializer with a delegatecall.
     *
     * @param initialManagementKey The ethereum address to be set as the management key of the ONCHAINID.
     */
    function initialize(address initialManagementKey) public {
        __Identity_init(initialManagementKey);
    }

    /**
     * @notice Computes if the context in which the function is called is a constructor or not.
     *
     * @return true if the context is a constructor.
     */
    function _isConstructor() private view returns (bool) {
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }

    /**
     * @notice Initializer internal function for the Identity contract.
     *
     * @param initialManagementKey The ethereum address to be set as the management key of the ONCHAINID.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Identity_init(address initialManagementKey) internal {
        require(!initialized || _isConstructor(), "Initial key was already setup.");
        initialized = true;
        canInteract = true;

        bytes32 _key = keccak256(abi.encode(initialManagementKey));
        keys[_key].key = _key;
        keys[_key].purposes = [1];
        keys[_key].keyType = 1;
        keysByPurpose[1].push(_key);
        emit KeyAdded(_key, 1, 1);
    }

    /**
     * @notice Implementation of the getKey function from the ERC-734 standard
     *
     * @param _key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
     *
     * @return purposes Returns the full key data, if present in the identity.
     * @return keyType Returns the full key data, if present in the identity.
     * @return key Returns the full key data, if present in the identity.
     */
    function getKey(bytes32 _key)
    public
    override
    view
    returns(uint256[] memory purposes, uint256 keyType, bytes32 key)
    {
        return (keys[_key].purposes, keys[_key].keyType, keys[_key].key);
    }

    /**
    * @notice gets the purposes of a key
    *
    * @param _key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
    *
    * @return _purposes Returns the purposes of the specified key
    */
    function getKeyPurposes(bytes32 _key)
    public
    override
    view
    returns(uint256[] memory _purposes)
    {
        return (keys[_key].purposes);
    }

    /**
        * @notice gets all the keys with a specific purpose from an identity
        *
        * @param _purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
        *
        * @return _keys Returns an array of public key bytes32 hold by this identity and having the specified purpose
        */
    function getKeysByPurpose(uint256 _purpose)
    public
    override
    view
    returns(bytes32[] memory _keys)
    {
        return keysByPurpose[_purpose];
    }

    /**
    * @notice implementation of the addKey function of the ERC-734 standard
    * Adds a _key to the identity. The _purpose specifies the purpose of key. Initially we propose four purposes:
    * 1: MANAGEMENT keys, which can manage the identity
    * 2: ACTION keys, which perform actions in this identities name (signing, logins, transactions, etc.)
    * 3: CLAIM signer keys, used to sign claims on other identities which need to be revokable.
    * 4: ENCRYPTION keys, used to encrypt data e.g. hold in claims.
    * MUST only be done by keys of purpose 1, or the identity itself.
    * If its the identity itself, the approval process will determine its approval.
    *
    * @param _key keccak256 representation of an ethereum address
    * @param _type type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
    * @param _purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
    *
    * @return success Returns TRUE if the addition was successful and FALSE if not
    */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _type)
    public
    delegatedOnly
    override
    returns (bool success)
    {
        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Permissions: Sender does not have management key");
        }

        if (keys[_key].key == _key) {
            for (uint keyPurposeIndex = 0; keyPurposeIndex < keys[_key].purposes.length; keyPurposeIndex++) {
                uint256 purpose = keys[_key].purposes[keyPurposeIndex];

                if (purpose == _purpose) {
                    revert("Conflict: Key already has purpose");
                }
            }

            keys[_key].purposes.push(_purpose);
        } else {
            keys[_key].key = _key;
            keys[_key].purposes = [_purpose];
            keys[_key].keyType = _type;
        }

        keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _type);

        return true;
    }

    /**
     * @notice Approves an execution or claim addition.
     * This SHOULD require n of m approvals of keys purpose 1, if the _to of the execution is the identity contract itself, to successfully approve an execution.
     * And COULD require n of m approvals of keys purpose 2, if the _to of the execution is another contract, to successfully approve an execution.
     */
    function approve(uint256 _id, bool _approve)
    public
    delegatedOnly
    override
    returns (bool success)
    {
        require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), "Sender does not have action key");

        emit Approved(_id, _approve);

        if (_approve == true) {
            executions[_id].approved = true;

            (success,) = executions[_id].to.call{value:(executions[_id].value)}(abi.encode(executions[_id].data, 0));

            if (success) {
                executions[_id].executed = true;

                emit Executed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );

                return true;
            } else {
                emit ExecutionFailed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );

                return false;
            }
        } else {
            executions[_id].approved = false;
        }
        return true;
    }

    /**
     * @notice Passes an execution instruction to the keymanager.
     * SHOULD require approve to be called with one or more keys of purpose 1 or 2 to approve this execution.
     * Execute COULD be used as the only accessor for addKey, removeKey and replaceKey and removeClaim.
     *
     * @return executionId SHOULD be sent to the approve function, to approve or reject this execution.
     */
    function execute(address _to, uint256 _value, bytes memory _data)
    public
    delegatedOnly
    override
    payable
    returns (uint256 executionId)
    {
        require(!executions[executionNonce].executed, "Already executed");
        executions[executionNonce].to = _to;
        executions[executionNonce].value = _value;
        executions[executionNonce].data = _data;

        emit ExecutionRequested(executionNonce, _to, _value, _data);

        if (keyHasPurpose(keccak256(abi.encode(msg.sender)), 2)) {
            approve(executionNonce, true);
        }

        executionNonce++;
        return executionNonce-1;
    }

    /**
    * @notice Remove the purpose from a key.
    */
    function removeKey(bytes32 _key, uint256 _purpose)
    public
    delegatedOnly
    override
    returns (bool success)
    {
        require(keys[_key].key == _key, "NonExisting: Key isn't registered");

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Permissions: Sender does not have management key"); // Sender has MANAGEMENT_KEY
        }

        require(keys[_key].purposes.length > 0, "NonExisting: Key doesn't have such purpose");

        uint purposeIndex = 0;
        while (keys[_key].purposes[purposeIndex] != _purpose) {
            purposeIndex++;

            if (purposeIndex >= keys[_key].purposes.length) {
                break;
            }
        }

        require(purposeIndex < keys[_key].purposes.length, "NonExisting: Key doesn't have such purpose");

        keys[_key].purposes[purposeIndex] = keys[_key].purposes[keys[_key].purposes.length - 1];
        keys[_key].purposes.pop();

        uint keyIndex = 0;

        while (keysByPurpose[_purpose][keyIndex] != _key) {
            keyIndex++;
        }

        keysByPurpose[_purpose][keyIndex] = keysByPurpose[_purpose][keysByPurpose[_purpose].length - 1];
        keysByPurpose[_purpose].pop();

        uint keyType = keys[_key].keyType;

        if (keys[_key].purposes.length == 0) {
            delete keys[_key];
        }

        emit KeyRemoved(_key, _purpose, keyType);

        return true;
    }


    /**
    * @notice Returns true if the key has MANAGEMENT purpose or the specified purpose.
    */
    function keyHasPurpose(bytes32 _key, uint256 _purpose)
    public
    override
    view
    returns(bool result)
    {
        Key memory key = keys[_key];
        if (key.key == 0) return false;

        for (uint keyPurposeIndex = 0; keyPurposeIndex < key.purposes.length; keyPurposeIndex++) {
            uint256 purpose = key.purposes[keyPurposeIndex];

            if (purpose == 1 || purpose == _purpose) return true;
        }

        return false;
    }

    /**
    * @notice Implementation of the addClaim function from the ERC-735 standard
    *  Require that the msg.sender has claim signer key.
    *
    * @param _topic The type of claim
    * @param _scheme The scheme with which this claim SHOULD be verified or how it should be processed.
    * @param _issuer The issuers identity contract address, or the address used to sign the above signature.
    * @param _signature Signature which is the proof that the claim issuer issued a claim of topic for this identity.
    * it MUST be a signed message of the following structure: keccak256(abi.encode(address identityHolder_address, uint256 _ topic, bytes data))
    * @param _data The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
    * @param _uri The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
    *
    * @return claimRequestId Returns claimRequestId: COULD be send to the approve function, to approve or reject this claim.
    * triggers ClaimAdded event.
    */
    function addClaim(
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes memory _signature,
        bytes memory _data,
        string memory _uri
    )
    public
    delegatedOnly
    override
    returns (bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encode(_issuer, _topic));

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 3), "Permissions: Sender does not have claim signer key");
        }

        if (claims[claimId].issuer != _issuer) {
            claimsByTopic[_topic].push(claimId);
            claims[claimId].topic = _topic;
            claims[claimId].scheme = _scheme;
            claims[claimId].issuer = _issuer;
            claims[claimId].signature = _signature;
            claims[claimId].data = _data;
            claims[claimId].uri = _uri;

            emit ClaimAdded(
                claimId,
                _topic,
                _scheme,
                _issuer,
                _signature,
                _data,
                _uri
            );
        } else {
            claims[claimId].topic = _topic;
            claims[claimId].scheme = _scheme;
            claims[claimId].issuer = _issuer;
            claims[claimId].signature = _signature;
            claims[claimId].data = _data;
            claims[claimId].uri = _uri;

            emit ClaimChanged(
                claimId,
                _topic,
                _scheme,
                _issuer,
                _signature,
                _data,
                _uri
            );
        }

        return claimId;
    }

    /**
    * @notice Implementation of the removeClaim function from the ERC-735 standard
    * Require that the msg.sender has management key.
    * Can only be removed by the claim issuer, or the claim holder itself.
    *
    * @param _claimId The identity of the claim i.e. keccak256(abi.encode(_issuer, _topic))
    *
    * @return success Returns TRUE when the claim was removed.
    * triggers ClaimRemoved event
    */
    function removeClaim(bytes32 _claimId) public delegatedOnly override returns (bool success) {
        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 3), "Permissions: Sender does not have CLAIM key");
        }

        if (claims[_claimId].topic == 0) {
            revert("NonExisting: There is no claim with this ID");
        }

        uint claimIndex = 0;
        while (claimsByTopic[claims[_claimId].topic][claimIndex] != _claimId) {
            claimIndex++;
        }

        claimsByTopic[claims[_claimId].topic][claimIndex] = claimsByTopic[claims[_claimId].topic][claimsByTopic[claims[_claimId].topic].length - 1];
        claimsByTopic[claims[_claimId].topic].pop();

        emit ClaimRemoved(
            _claimId,
            claims[_claimId].topic,
            claims[_claimId].scheme,
            claims[_claimId].issuer,
            claims[_claimId].signature,
            claims[_claimId].data,
            claims[_claimId].uri
        );

        delete claims[_claimId];

        return true;
    }

    /**
    * @notice Implementation of the getClaim function from the ERC-735 standard.
    *
    * @param _claimId The identity of the claim i.e. keccak256(abi.encode(_issuer, _topic))
    *
    * @return topic Returns all the parameters of the claim for the specified _claimId (topic, scheme, signature, issuer, data, uri) .
    * @return scheme Returns all the parameters of the claim for the specified _claimId (topic, scheme, signature, issuer, data, uri) .
    * @return issuer Returns all the parameters of the claim for the specified _claimId (topic, scheme, signature, issuer, data, uri) .
    * @return signature Returns all the parameters of the claim for the specified _claimId (topic, scheme, signature, issuer, data, uri) .
    * @return data Returns all the parameters of the claim for the specified _claimId (topic, scheme, signature, issuer, data, uri) .
    * @return uri Returns all the parameters of the claim for the specified _claimId (topic, scheme, signature, issuer, data, uri) .
    */
    function getClaim(bytes32 _claimId)
    public
    override
    view
    returns(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    )
    {
        return (
            claims[_claimId].topic,
            claims[_claimId].scheme,
            claims[_claimId].issuer,
            claims[_claimId].signature,
            claims[_claimId].data,
            claims[_claimId].uri
        );
    }

    /**
    * @notice Implementation of the getClaimIdsByTopic function from the ERC-735 standard.
    * used to get all the claims from the specified topic
    *
    * @param _topic The identity of the claim i.e. keccak256(abi.encode(_issuer, _topic))
    *
    * @return claimIds Returns an array of claim IDs by topic.
    */
    function getClaimIdsByTopic(uint256 _topic)
    public
    override
    view
    returns(bytes32[] memory claimIds)
    {
        return claimsByTopic[_topic];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IIdentity.sol";

interface IClaimIssuer is IIdentity {
    function revokeClaim(bytes32 _claimId, address _identity) external returns(bool);
    function getRecoveredAddress(bytes calldata sig, bytes32 dataHash) external pure returns (address);
    function isClaimRevoked(bytes calldata _sig) external view returns (bool);
    function isClaimValid(IIdentity _identity, uint256 claimTopic, bytes calldata sig, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev interface of the ERC734 (Key Holder) standard as defined in the EIP.
 */
interface IERC734 {

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
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when an execution request was performed via `execute`.
     *
     * Specification: MUST be triggered when execute was successfully called.
     */
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when a key was added to the Identity.
     *
     * Specification: MUST be triggered when addKey was successfully called.
     */
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when a key was removed from the Identity.
     *
     * Specification: MUST be triggered when removeKey was successfully called.
     */
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when the list of required keys to perform an action was updated.
     *
     * Specification: MUST be triggered when changeKeysRequired was successfully called.
     */
    event KeysRequiredChanged(uint256 purpose, uint256 number);


    /**
     * @dev Adds a _key to the identity. The _purpose specifies the purpose of the key.
     *
     * Triggers Event: `KeyAdded`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) external returns (bool success);

    /**
    * @dev Approves an execution or claim addition.
    *
    * Triggers Event: `Approved`, `Executed`
    *
    * Specification:
    * This SHOULD require n of m approvals of keys purpose 1, if the _to of the execution is the identity contract itself, to successfully approve an execution.
    * And COULD require n of m approvals of keys purpose 2, if the _to of the execution is another contract, to successfully approve an execution.
    */
    function approve(uint256 _id, bool _approve) external returns (bool success);

    /**
     * @dev Passes an execution instruction to an ERC725 identity.
     *
     * Triggers Event: `ExecutionRequested`, `Executed`
     *
     * Specification:
     * SHOULD require approve to be called with one or more keys of purpose 1 or 2 to approve this execution.
     * Execute COULD be used as the only accessor for `addKey` and `removeKey`.
     */
    function execute(address _to, uint256 _value, bytes calldata _data) external payable returns (uint256 executionId);

    /**
     * @dev Returns the full key data, if present in the identity.
     */
    function getKey(bytes32 _key) external view returns (uint256[] memory purposes, uint256 keyType, bytes32 key);

    /**
     * @dev Returns the list of purposes associated with a key.
     */
    function getKeyPurposes(bytes32 _key) external view returns(uint256[] memory _purposes);

    /**
     * @dev Returns an array of public key bytes32 held by this identity.
     */
    function getKeysByPurpose(uint256 _purpose) external view returns (bytes32[] memory keys);

    /**
     * @dev Returns TRUE if a key is present and has the given purpose. If the key is not present it returns FALSE.
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose) external view returns (bool exists);

    /**
     * @dev Removes _purpose for _key from the identity.
     *
     * Triggers Event: `KeyRemoved`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function removeKey(bytes32 _key, uint256 _purpose) external returns (bool success);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev interface of the ERC735 (Claim Holder) standard as defined in the EIP.
 */
interface IERC735 {

    /**
     * @dev Emitted when a claim request was performed.
     *
     * Specification: Is not clear
     */
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was added.
     *
     * Specification: MUST be triggered when a claim was successfully added.
     */
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was removed.
     *
     * Specification: MUST be triggered when removeClaim was successfully called.
     */
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was changed.
     *
     * Specification: MUST be triggered when changeClaim was successfully called.
     */
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Get a claim by its ID.
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function getClaim(bytes32 _claimId) external view returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);

    /**
     * @dev Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(uint256 _topic) external view returns(bytes32[] memory claimIds);

    /**
     * @dev Add or update a claim.
     *
     * Triggers Event: `ClaimRequested`, `ClaimAdded`, `ClaimChanged`
     *
     * Specification: Requests the ADDITION or the CHANGE of a claim from an issuer.
     * Claims can requested to be added by anybody, including the claim holder itself (self issued).
     *
     * _signature is a signed message of the following structure: `keccak256(abi.encode(address identityHolder_address, uint256 topic, bytes data))`.
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address + uint256 topic))`.
     *
     * This COULD implement an approval process for pending claims, or add them right away.
     * MUST return a claimRequestId (use claim ID) that COULD be sent to the approve function.
     */
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes calldata _signature, bytes calldata _data, string calldata _uri) external returns (bytes32 claimRequestId);

    /**
     * @dev Removes a claim.
     *
     * Triggers Event: `ClaimRemoved`
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function removeClaim(bytes32 _claimId) external returns (bool success);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC734.sol";
import "./IERC735.sol";

interface IIdentity is IERC734, IERC735 {}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IImplementationAuthority {
    function getImplementation() external view returns(address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../interface/IImplementationAuthority.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ImplementationAuthority is IImplementationAuthority, Ownable {

    event UpdatedImplementation(address newAddress);

    address implementation;

    constructor(address _implementation) {
        implementation = _implementation;
        emit UpdatedImplementation(_implementation);
    }

    /**
     * @dev get the address of the implementation contract.
     * @return implementation the address of the implementation contract
     */
    function getImplementation() external override view returns(address) {
        return implementation;
    }

    /**
     * @dev update the address of the implementation contract.
     * @param _newImplementation the implementation address
     */
    function updateImplementation(address _newImplementation) public onlyOwner {
        implementation = _newImplementation;
        emit UpdatedImplementation(_newImplementation);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "./Structs.sol";

contract Storage is Structs {
    uint256 internal executionNonce;
    mapping(bytes32 => Key) internal keys;
    mapping(uint256 => bytes32[]) internal keysByPurpose;
    mapping(uint256 => Execution) internal executions;
    mapping(bytes32 => Claim) internal claims;
    mapping(uint256 => bytes32[]) internal claimsByTopic;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Structs {

   /**
    * @dev Definition of the structure of a Key.
    *
    * Specification: Keys are cryptographic public keys, or contract addresses associated with this identity.
    * The structure should be as follows:
    *   - key: A public key owned by this identity
    *      - purposes: uint256[] Array of the key purposes, like 1 = MANAGEMENT, 2 = EXECUTION
    *      - keyType: The type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
    *      - key: bytes32 The public key. // Its the Keccak256 hash of the key
    */
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
    * @dev Definition of the structure of a Claim.
    *
    * Specification: Claims are information an issuer has about the identity holder.
    * The structure should be as follows:
    *   - claim: A claim published for the Identity.
    *      - topic: A uint256 number which represents the topic of the claim. (e.g. 1 biometric, 2 residence (ToBeDefined: number schemes, sub topics based on number ranges??))
    *      - scheme : The scheme with which this claim SHOULD be verified or how it should be processed. Its a uint256 for different schemes. E.g. could 3 mean contract verification, where the data will be call data, and the issuer a contract address to call (ToBeDefined). Those can also mean different key types e.g. 1 = ECDSA, 2 = RSA, etc. (ToBeDefined)
    *      - issuer: The issuers identity contract address, or the address used to sign the above signature. If an identity contract, it should hold the key with which the above message was signed, if the key is not present anymore, the claim SHOULD be treated as invalid. The issuer can also be a contract address itself, at which the claim can be verified using the call data.
    *      - signature: Signature which is the proof that the claim issuer issued a claim of topic for this identity. it MUST be a signed message of the following structure: `keccak256(abi.encode(identityHolder_address, topic, data))`
    *      - data: The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
    *      - uri: The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
    */
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @dev Version contract gives the versioning information of the implementation contract
 */
contract Version {
    /**
     * @dev Returns the string of the current version.
     */
    function version() public pure returns (string memory) {
        // version 2.0.0
        return "2.0.0";
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
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

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../../roles/AgentRole.sol';
import './ICompliance.sol';
import '../../token/IToken.sol';

abstract contract BasicCompliance is AgentRole, ICompliance {

    /// Mapping between agents and their statuses
    mapping(address => bool) private _tokenAgentsList;

    /// Mapping of tokens linked to the compliance contract
    IToken public _tokenBound;

    /**
     * @dev Throws if called by any address that is not a token bound to the compliance.
     */
    modifier onlyToken() {
        require(isToken(), 'error : this address is not a token bound to the compliance contract');
        _;
    }

    /**
     * @dev Throws if called by any address that is not owner of compliance or agent of the token.
     */
    modifier onlyAdmin() {
        require(owner() == msg.sender || (AgentRole(address(_tokenBound))).isAgent(msg.sender) ,
            'can be called only by Admin address');
        _;
    }

    /**
    *  @dev Returns the ONCHAINID (Identity) of the _userAddress
    *  @param _userAddress Address of the wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function _getIdentity(address _userAddress) internal view returns (address) {
        return address(_tokenBound.identityRegistry().identity(_userAddress));
    }

    /**
    *  @dev Returns the country of residence of the _userAddress
    *  @param _userAddress Address of the wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function _getCountry(address _userAddress) internal view returns (uint16) {
        return _tokenBound.identityRegistry().investorCountry(_userAddress);
    }

    /**
    *  @dev See {ICompliance-isTokenAgent}.
    */
    function isTokenAgent(address _agentAddress) public override view returns (bool) {
        if (!_tokenAgentsList[_agentAddress] && !(AgentRole(address(_tokenBound))).isAgent(_agentAddress)) {
            return false;
        }
        return true;
    }

    /**
    *  @dev See {ICompliance-isTokenBound}.
    */
    function isTokenBound(address _token) public override view returns (bool) {
        if (_token != address(_tokenBound)){
            return false;
        }
        return true;
    }

    /**
     *  @dev See {ICompliance-addTokenAgent}.
     *  this function is deprecated, but still implemented to avoid breaking interfaces
     */
    function addTokenAgent(address _agentAddress) external override onlyOwner {
        require(!_tokenAgentsList[_agentAddress], 'This Agent is already registered');
        _tokenAgentsList[_agentAddress] = true;
        emit TokenAgentAdded(_agentAddress);
    }

    /**
    *  @dev See {ICompliance-isTokenAgent}.
    */
    function removeTokenAgent(address _agentAddress) external override onlyOwner {
        require(_tokenAgentsList[_agentAddress], 'This Agent is not registered yet');
        _tokenAgentsList[_agentAddress] = false;
        emit TokenAgentRemoved(_agentAddress);
    }

    /**
     *  @dev See {ICompliance-bindToken}.
     */
    function bindToken(address _token) external override {
        require(owner() == msg.sender || (address(_tokenBound) == address(0) && msg.sender == _token),
            'only owner or token can call');
        _tokenBound = IToken(_token);
        emit TokenBound(_token);
    }

    /**
    *  @dev See {ICompliance-unbindToken}.
    */
    function unbindToken(address _token) external override {
        require(owner() == msg.sender || msg.sender == _token , 'only owner or token can call');
        require(_token == address(_tokenBound), 'This token is not bound');
        delete _tokenBound;
        emit TokenUnbound(_token);
    }

    /**
    *  @dev Returns true if the sender corresponds to a token that is bound with the Compliance contract
    */
    function isToken() internal view returns (bool) {
        return isTokenBound(msg.sender);
    }

}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import './BasicCompliance.sol';

contract DefaultCompliance is BasicCompliance {
    /**
    *  @dev See {ICompliance-transferred}.
    */
    function transferred(address _from, address _to, uint256 _value) external override {
    }

    /**
     *  @dev See {ICompliance-created}.
     */
    function created(address _to, uint256 _value) external override {
    }

    /**
     *  @dev See {ICompliance-destroyed}.
     */
    function destroyed(address _from, uint256 _value) external override {
    }

    /**
     *  @dev See {ICompliance-canTransfer}.
     */
    function canTransfer(address /*_from*/, address /*_to*/, uint256 /*_value*/) external view override returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../BasicCompliance.sol';

/**
 *  this feature allows to require the pre-validation of a transfer before allowing it to be executed
 *  This feature is also known as "conditional transfers" feature
 */
abstract contract ApproveTransfer is BasicCompliance {

    /**
     *  this event is emitted when a transfer is approved
     *  the event is emitted by the `approveTransfer` and `approveAndTransfer` functions
     *  `_from` is the address of the transfer sender
     *  `_to` is the address of the transfer receiver
     *  `_amount` is the amount of tokens that `_from` is allowed to send to `_to`
     *  note that the approved transfer has to be exactly of the approved amount `_amount`
     *  `_token` is the address of the token that is allowed to be transferred
     */
    event TransferApproved(address _from, address _to, uint _amount, address _token);

    /**
     *  this event is emitted when a transfer approval is removed
     *  the event is emitted by the `removeApproval` function
     *  `_from` is the address of the transfer sender
     *  `_to` is the address of the transfer receiver
     *  `_amount` is the amount of tokens that `_from` was allowed to send to `_to`
     *  `_token` is the address of the token that was allowed to be transferred
     */
    event ApprovalRemoved(address _from, address _to, uint _amount, address _token);

    /// Mapping of transfersApproved
    mapping(bytes32 => bool) private _transfersApproved;

    /**
    *  @dev Calculates the ID of a transfer
    *  transfer IDs are used to identify which transfer is approved and which is not at compliance contract level
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _amount the amount of tokens that `_from` would send to `_to`
    *  @param _token the address of the token that would be transferred
    *  returns the transferId of the transfer
    */
    function calculateTransferID (
        address _from,
        address _to,
        uint _amount,
        address _token
    ) internal pure returns (bytes32){
        bytes32 transferId = keccak256(abi.encode(_from, _to, _amount, _token));
        return transferId;
    }

    /**
    *  @dev Approves a transfer
    *  once a transfer is approved, the sender is allowed to execute it
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _amount the amount of tokens that `_from` would send to `_to`
    *  Only Admin can call this function, i.e. owner of compliance contract OR token agent
    *  emits a `TransferApproved` event
    */
    function approveTransfer(address _from, address _to, uint _amount) public onlyAdmin {
        bytes32 transferId = calculateTransferID (_from, _to, _amount, address(_tokenBound));
        require(!_transfersApproved[transferId], 'transfer already approved');
        _transfersApproved[transferId] = true;
        emit TransferApproved(_from, _to, _amount, address(_tokenBound));
    }

    /**
    *  @dev removes approval on a transfer previously approved
    *  requires the transfer to be previously approved
    *  once a transfer approval is removed, the sender is not allowed to execute it anymore
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _amount the amount of tokens that `_from` was allowed to send to `_to`
    *  Only Admin can call this function, i.e. owner of compliance contract OR token agent
    *  emits an `ApprovalRemoved` event
    */
    function removeApproval(address _from, address _to, uint _amount) external onlyAdmin {
        bytes32 transferId = calculateTransferID (_from, _to, _amount, address(_tokenBound));
        require(_transfersApproved[transferId], 'transfer not approved yet');
        _transfersApproved[transferId] = false;
        emit ApprovalRemoved(_from, _to, _amount, address(_tokenBound));
    }

    /**
    *  @dev updates the approval status of a transfer post-execution
    *  once an approved transfer is executed, the sender is not allowed to execute it anymore
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _amount the amount of tokens that `_from` was allowed to send to `_to`
    *  internal function, can be called only from the functions of the Compliance smart contract
    *  emits an `ApprovalRemoved` event if transfer was pre-approved, i.e. if function call was done by a regular
    *  token holder, token agents bypassing the approval requirements
    */
    function transferProcessed(address _from, address _to, uint _amount) internal {
        bytes32 transferId = calculateTransferID (_from, _to, _amount, address(_tokenBound));
        if (_transfersApproved[transferId]) {
            _transfersApproved[transferId] = false;
            emit ApprovalRemoved(_from, _to, _amount, address(_tokenBound));
        }
    }

    /**
    *  @dev Approves a transfer and execute it immediately
    *  As the function calls `transferFrom` on the token contract, the compliance contract, which is de facto sender of
    *  that function call has to be allowed to make such a call, i.e. the allowance should be >= `_amount` with
    *  Compliance contract address being the spender address
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _amount the amount of tokens that `_from` would send to `_to`
    *  Only Admin can call this function, i.e. owner of compliance contract OR token agent
    *  emits a `TransferApproved` event, an `ApprovalRemoved` event and a `Transfer` event
    */
    function approveAndTransfer(address _from, address _to, uint _amount) external {
        approveTransfer(_from, _to, _amount);
        _tokenBound.transferFrom(_from, _to, _amount);
    }

    /**
    *  @dev state update of the compliance feature post-transfer.
    *  calls the `transferProcessed` function to update approval status post-transfer
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` sent to `_to`
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function transferActionOnApproveTransfer(address _from, address _to, uint256 _value) internal {
        transferProcessed(_from, _to, _value);
    }

    /**
    *  @dev state update of the compliance feature post-minting.
    *  this compliance feature doesn't require state update post-minting
    *  @param _to the address of the minting beneficiary
    *  @param _value the amount of tokens minted on `_to` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function creationActionOnApproveTransfer(address _to, uint256 _value) internal {}

    /**
    *  @dev state update of the compliance feature post-burning.
    *  this compliance feature doesn't require state update post-burning
    *  @param _from the wallet address on which tokens burnt
    *  @param _value the amount of tokens burnt from `_from` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function destructionActionOnApproveTransfer(address _from, uint256 _value) internal {}

    /**
    *  @dev check on the compliance status of a transaction.
    *  If the check returns TRUE, the transfer is allowed to be executed, if the check returns FALSE, the compliance
    *  feature will block the transfer execution
    *  The check will verify if the transferID corresponding to the parameters of the transfer corresponds to a
    *  pre-approved transfer or not, and will return TRUE or FALSE according to the approval status of the said transfer
    *  If `_from` is a token agent, the transfer will pass whatever the approval status may be as agents bypass this
    *  compliance feature.
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` would send to `_to`
    */
    function complianceCheckOnApproveTransfer(address _from, address _to, uint256 _value) public view returns (bool) {
        if (!isTokenAgent(_from)) {
            bytes32 transferId = calculateTransferID (_from, _to, _value, address(_tokenBound));
            if (!_transfersApproved[transferId]){
                return false;
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../BasicCompliance.sol';

/**
 *  this feature allows to setup a blacklist of countries, investors with a blacklisted
 *  country of residence won't be allowed to receive tokens on their wallets
 */
abstract contract CountryRestrictions is BasicCompliance {

    /**
     *  this event is emitted whenever a Country has been restricted.
     *  the event is emitted by 'addCountryRestriction' and 'batchRestrictCountries' functions.
     *  `_country` is the numeric ISO 3166-1 of the restricted country.
     */
    event AddedRestrictedCountry(uint16 _country);

    /**
     *  this event is emitted whenever a Country has been unrestricted.
     *  the event is emitted by 'removeCountryRestriction' and 'batchUnrestrictCountries' functions.
     *  `_country` is the numeric ISO 3166-1 of the unrestricted country.
     */
    event RemovedRestrictedCountry(uint16 _country);

    /// Mapping between country and their restriction status
    mapping(uint16 => bool) private _restrictedCountries;

    /**
    *  @dev Returns true if country is Restricted
    *  @param _country, numeric ISO 3166-1 standard of the country to be checked
    */
    function isCountryRestricted(uint16 _country) public view returns (bool) {
        return (_restrictedCountries[_country]);
    }

    /**
    *  @dev Adds country restriction.
    *  Identities from those countries will be forbidden to manipulate Tokens linked to this Compliance.
    *  @param _country Country to be restricted, should be expressed by following numeric ISO 3166-1 standard
    *  Only the owner of the Compliance smart contract can call this function
    *  emits an `AddedRestrictedCountry` event
    */
    function addCountryRestriction(uint16 _country) public onlyOwner {
        require(!_restrictedCountries[_country], 'country already restricted');
        _restrictedCountries[_country] = true;
        emit AddedRestrictedCountry(_country);
    }

    /**
     *  @dev Removes country restriction.
     *  Identities from those countries will again be authorised to manipulate Tokens linked to this Compliance.
     *  @param _country Country to be unrestricted, should be expressed by following numeric ISO 3166-1 standard
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `RemovedRestrictedCountry` event
     */
    function removeCountryRestriction(uint16 _country) public onlyOwner {
        require(_restrictedCountries[_country], 'country not restricted');
        _restrictedCountries[_country] = false;
        emit RemovedRestrictedCountry(_country);
    }

    /**
    *  @dev Adds countries restriction in batch.
    *  Identities from those countries will be forbidden to manipulate Tokens linked to this Compliance.
    *  @param _countries Countries to be restricted, should be expressed by following numeric ISO 3166-1 standard
    *  Only the owner of the Compliance smart contract can call this function
    *  emits _countries.length `AddedRestrictedCountry` events
    */
    function batchRestrictCountries(uint16[] calldata _countries) external {
        for (uint i = 0; i < _countries.length; i++) {
            addCountryRestriction(_countries[i]);
        }
    }

    /**
     *  @dev Removes countries restriction in batch.
     *  Identities from those countries will again be authorised to manipulate Tokens linked to this Compliance.
     *  @param _countries Countries to be unrestricted, should be expressed by following numeric ISO 3166-1 standard
     *  Only the owner of the Compliance smart contract can call this function
     *  emits _countries.length `RemovedRestrictedCountry` events
     */
    function batchUnrestrictCountries(uint16[] calldata _countries) external {
        for (uint i = 0; i < _countries.length; i++) {
            removeCountryRestriction(_countries[i]);
        }
    }

    /**
    *  @dev state update of the compliance feature post-transfer.
    *  this compliance feature doesn't require state update post-transfer
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` sent to `_to`
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function transferActionOnCountryRestrictions(address _from, address _to, uint256 _value) internal {}

    /**
    *  @dev state update of the compliance feature post-minting.
    *  this compliance feature doesn't require state update post-minting
    *  @param _to the address of the minting beneficiary
    *  @param _value the amount of tokens minted on `_to` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function creationActionOnCountryRestrictions(address _to, uint256 _value) internal {}

    /**
    *  @dev state update of the compliance feature post-burning.
    *  this compliance feature doesn't require state update post-burning
    *  @param _from the wallet address on which tokens burnt
    *  @param _value the amount of tokens burnt from `_from` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function destructionActionOnCountryRestrictions(address _from, uint256 _value) internal {}

    /**
    *  @dev check on the compliance status of a transaction.
    *  If the check returns TRUE, the transfer is allowed to be executed, if the check returns FALSE, the compliance
    *  feature will block the transfer execution
    *  The check will verify if the country of residence of `_to` is restricted or not, in case the country is
    *  restricted, this feature will block the transfer
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` would send to `_to`
    */
    function complianceCheckOnCountryRestrictions (address _from, address _to, uint256 _value)
    public view returns (bool) {
        uint16 receiverCountry = _getCountry(_to);
        if (isCountryRestricted(receiverCountry)) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../BasicCompliance.sol';

/**
 *  this feature allows to setup a whitelist of countries, only investors with a whitelisted country
 *  of residence will be allowed to receive tokens
 */
abstract contract CountryWhitelisting is BasicCompliance {

    /**
     *  this event is emitted whenever a Country has been whitelisted.
     *  the event is emitted by 'whitelistCountry' and 'batchWhitelistCountries' functions.
     *  `_country` is the numeric ISO 3166-1 of the whitelisted country.
     */
    event WhitelistedCountry(uint16 _country);

    /**
     *  this event is emitted whenever a Country has been removed from the whitelist.
     *  the event is emitted by 'unwhitelistCountry' and 'batchBlacklistCountries' functions.
     *  `_country` is the numeric ISO 3166-1 of the whitelisted country.
     */
    event UnWhitelistedCountry(uint16 _country);

    /// Mapping between country and their whitelist status
    mapping(uint16 => bool) private _whitelistedCountries;

    /**
    *  @dev Returns true if country is whitelisted
    *  @param _country, numeric ISO 3166-1 standard of the country to be checked
    */
    function isCountryWhitelisted(uint16 _country) public view returns (bool) {
        return (_whitelistedCountries[_country]);
    }

    /**
    *  @dev whitelist country.
    *  Identities from those countries will be whitelisted & authorised to manipulate Tokens linked to this Compliance.
    *  @param _country Country to be whitelisted, should be expressed by following numeric ISO 3166-1 standard
    *  Only the owner of the Compliance smart contract can call this function
    *  emits an `WhitelistedCountry` event
    */
    function whitelistCountry(uint16 _country) public onlyOwner {
        require(!_whitelistedCountries[_country], 'country already whitelisted');
        _whitelistedCountries[_country] = true;
        emit WhitelistedCountry(_country);
    }

    /**
     *  @dev removes whitelisting status of a country.
     *  Identities from those countries will be de-whitelisted & forbidden
     *  to manipulate Tokens linked to this Compliance.
     *  @param _country Country to be de-whitelisted, should be expressed by following numeric ISO 3166-1 standard
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `UnwhitelistedCountry` event
     */
    function unWhitelistCountry(uint16 _country) public onlyOwner {
        require(_whitelistedCountries[_country], 'country not whitelisted');
        _whitelistedCountries[_country] = false;
        emit UnWhitelistedCountry(_country);
    }

    /**
    *  @dev Adds countries to the whitelist in batch.
    *  Identities from those countries will be whitelisted & authorized to manipulate Tokens linked to this Compliance.
    *  @param _countries Countries to be whitelisted, should be expressed by following numeric ISO 3166-1 standard
    *  Only the owner of the Compliance smart contract can call this function
    *  emits an `WhitelistedCountry` event
    */
    function batchWhitelistCountries(uint16[] memory _countries) external {
        for (uint i = 0; i < _countries.length; i++) {
            whitelistCountry(_countries[i]);
        }
    }

    /**
     *  @dev Removes countries from the whitelist in batch.
     *  Identities from those countries will be unwhitelisted.
     *  @param _countries Countries to be unwhitelisted, should be expressed by following numeric ISO 3166-1 standard
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `UnwhitelistedCountry` event
     */
    function batchUnWhitelistCountries(uint16[] memory _countries) external {
        for (uint i = 0; i < _countries.length; i++) {
            unWhitelistCountry(_countries[i]);
        }
    }

    /**
    *  @dev state update of the compliance feature post-transfer.
    *  this compliance feature doesn't require state update post-transfer
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` sent to `_to`
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function transferActionOnCountryWhitelisting(address _from, address _to, uint256 _value) internal {}

    /**
    *  @dev state update of the compliance feature post-minting.
    *  this compliance feature doesn't require state update post-minting
    *  @param _to the address of the minting beneficiary
    *  @param _value the amount of tokens minted on `_to` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function creationActionOnCountryWhitelisting(address _to, uint256 _value) internal {}

    /**
    *  @dev state update of the compliance feature post-burning.
    *  this compliance feature doesn't require state update post-burning
    *  @param _from the wallet address on which tokens burnt
    *  @param _value the amount of tokens burnt from `_from` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function destructionActionOnCountryWhitelisting(address _from, uint256 _value) internal {}

    /**
    *  @dev check on the compliance status of a transaction.
    *  If the check returns TRUE, the transfer is allowed to be executed, if the check returns FALSE, the compliance
    *  feature will block the transfer execution
    *  The check will verify if the country of residence of `_to` is whitelisted or not, in case the country is
    *  whitelisted, this feature will allow the transfer to pass, otherwise the transfer will be blocked
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` would send to `_to`
    */
    function complianceCheckOnCountryWhitelisting (address _from, address _to, uint256 _value)
    public view returns (bool) {
        uint16 receiverCountry = _getCountry(_to);
        if (isCountryWhitelisted(receiverCountry)) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../BasicCompliance.sol';

/**
 *  this feature allows to put a limits on transfer volumes on a daily basis as well as on a monthly basis
 *  Investors will not be allowed to send more tokens than the fixed limit per day/month
 */
abstract contract DayMonthLimits is BasicCompliance {

    /**
     *  this event is emitted whenever a DailyLimit has been updated.
     *  the event is emitted by 'setDailyLimit' and by Compliance's constructor.
     *  `_newDailyLimit` is the amount Limit of tokens to be transferred daily.
     */
    event DailyLimitUpdated(uint _newDailyLimit);

    /**
     *  this event is emitted whenever a MonthlyLimit has been updated.
     *  the event is emitted by 'setMonthlyLimit' and by Compliance's constructor.
     *  `_newMonthlyLimit` is the amount Limit of tokens to be transferred monthly.
     */
    event MonthlyLimitUpdated(uint _newMonthlyLimit);

    /// Getter for Tokens dailyLimit
    uint256 public dailyLimit;

    /// Getter for Tokens monthlyLimit
    uint256 public monthlyLimit;

    /// Struct of transfer Counters
    struct TransferCounter {
        uint256 dailyCount;
        uint256 monthlyCount;
        uint256 dailyTimer;
        uint256 monthlyTimer;
    }

    /// Mapping for users Counters
    mapping(address => TransferCounter) public usersCounters;

    /**
    *  @dev checks if the day has finished since the cooldown has been triggered for this identity
    *  @param _identity ONCHAINID to be checked
    */
    function _isDayFinished(address _identity) internal view returns (bool) {
        return (usersCounters[_identity].dailyTimer <= block.timestamp);
    }

    /**
    *  @dev checks if the month has finished since the cooldown has been triggered for this identity
    *  @param _identity ONCHAINID to be checked
    */
    function _isMonthFinished(address _identity) internal view returns (bool) {
        return (usersCounters[_identity].monthlyTimer <= block.timestamp);
    }

    /**
    *  @dev resets cooldown for the day if cooldown has reached time limit of 1 day
    *  @param _identity ONCHAINID to be checked
    */
    function _resetDailyCooldown(address _identity) internal {
        if (_isDayFinished(_identity)) {
            usersCounters[_identity].dailyTimer = block.timestamp + 1 days;
            usersCounters[_identity].dailyCount = 0;
        }
    }

    /**
    *  @dev resets cooldown for the month if cooldown has reached the time limit of 30days
    *  @param _identity ONCHAINID to be checked
    */
    function _resetMonthlyCooldown(address _identity) internal {
        if (_isMonthFinished(_identity)) {
            usersCounters[_identity].monthlyTimer = block.timestamp + 30 days;
            usersCounters[_identity].monthlyCount = 0;
        }
    }

    /**
    *  @dev Checks if daily and/or monthly cooldown must be reset, then check if _value sent has been exceeded,
    *  if not increases user's OnchainID counters.
    *  @param _userAddress, address on which counters will be increased
    *  @param _value, value of transaction)to be increased
    */
    function _increaseCounters(address _userAddress, uint256 _value) internal {
        address identity = _getIdentity(_userAddress);
        _resetDailyCooldown(identity);
        _resetMonthlyCooldown(identity);
        if ((usersCounters[identity].dailyCount + _value) <= dailyLimit) {
            usersCounters[identity].dailyCount += _value;
        }
        if ((usersCounters[identity].monthlyCount + _value) <= monthlyLimit) {
            usersCounters[identity].monthlyCount += _value;
        }
    }

    /**
    *  @dev Set the limit of tokens allowed to be transferred daily.
    *  @param _newDailyLimit The new daily limit of tokens
    *  Only the owner of the Compliance smart contract can call this function
    */
    function setDailyLimit(uint256 _newDailyLimit) external onlyOwner {
        dailyLimit = _newDailyLimit;
        emit DailyLimitUpdated(_newDailyLimit);
    }

    /**
     *  @dev Set the limit of tokens allowed to be transferred monthly.
     *  @param _newMonthlyLimit The new monthly limit of tokens
     *  Only the owner of the Compliance smart contract can call this function
     */
    function setMonthlyLimit(uint256 _newMonthlyLimit) external onlyOwner {
        monthlyLimit = _newMonthlyLimit;
        emit MonthlyLimitUpdated(_newMonthlyLimit);
    }

    /**
    *  @dev state update of the compliance feature post-transfer.
    *  counters of daily and monthly transfers are updated post-transfer
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` sent to `_to`
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function transferActionOnDayMonthLimits(address _from, address _to, uint256 _value) internal {
        _increaseCounters(_from, _value);
    }

    /**
    *  @dev state update of the compliance feature post-minting.
    *  this compliance feature doesn't require state update post-minting
    *  @param _to the address of the minting beneficiary
    *  @param _value the amount of tokens minted on `_to` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function creationActionOnDayMonthLimits(address _to, uint256 _value) internal {}

    /**
    *  @dev state update of the compliance feature post-burning.
    *  this compliance feature doesn't require state update post-burning
    *  @param _from the wallet address on which tokens burnt
    *  @param _value the amount of tokens burnt from `_from` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function destructionActionOnDayMonthLimits(address _from, uint256 _value) internal {}

    /**
    *  @dev check on the compliance status of a transaction.
    *  If the check returns TRUE, the transfer is allowed to be executed, if the check returns FALSE, the compliance
    *  feature will block the transfer execution
    *  The check will verify if the transfer is exceeding the limits (daily and/or monthly)
    *  If the transfer exceeds the limits, the check returns false and the transfer is blocked
    *  otherwise it returns true. Agents bypass this compliance feature
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` would send to `_to`
    */
    function complianceCheckOnDayMonthLimits(address _from, address _to, uint256 _value) public view returns (bool) {
        address senderIdentity = _getIdentity(_from);
        if (!isTokenAgent(_from)) {
            if (_value > dailyLimit) {
                return false;
            }
            if (!_isDayFinished(senderIdentity) &&
            ((usersCounters[senderIdentity].dailyCount + _value > dailyLimit)
            || (usersCounters[senderIdentity].monthlyCount + _value > monthlyLimit))) {
                return false;
            }
            if (_isDayFinished(senderIdentity) && _value + usersCounters[senderIdentity].monthlyCount > monthlyLimit) {
                return(_isMonthFinished(senderIdentity));
            }
        }
        return true;
    }

}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../BasicCompliance.sol';

/**
 *  this feature allows to put a limit on the monthly deposits one can make on a given exchange
 *  It won't be possible for an investor to send more than the monthly limit of tokens on a given exchange
 */
abstract contract ExchangeMonthlyLimits is BasicCompliance {

    /**
     *  this event is emitted whenever the Exchange Limit has been updated.
     *  the event is emitted by 'setExchangeMonthlyLimit'
     *  `_exchangeID` is the amount ONCHAINID address of the exchange.
     *  `_newExchangeMonthlyLimit` is the amount Limit of tokens to be transferred monthly to an exchange wallet.
     */
    event ExchangeMonthlyLimitUpdated(address _exchangeID, uint _newExchangeMonthlyLimit);

    /**
     *  this event is emitted whenever an ONCHAINID is tagged as being an exchange ID.
     *  the event is emitted by 'addExchangeID'.
     *  `_newExchangeID` is the ONCHAINID address of the exchange to add.
     */
    event ExchangeIDAdded(address _newExchangeID);

    /**
     *  this event is emitted whenever an ONCHAINID is untagged as belonging to an exchange.
     *  the event is emitted by 'removeExchangeID'.
     *  `_exchangeID` is the ONCHAINID being untagged as an exchange ID.
     */
    event ExchangeIDRemoved(address _exchangeID);

    /// Getter for Tokens monthlyLimit
    mapping(address => uint256) private exchangeMonthlyLimit;

    /// Struct of transfer Counters
    struct ExchangeTransferCounter {
        uint256 monthlyCount;
        uint256 monthlyTimer;
    }

    /// Mapping for users Counters
    mapping(address => mapping(address => ExchangeTransferCounter)) private exchangeCounters;

    /// Mapping for wallets tagged as exchange wallets
    mapping(address => bool) private exchangeIDs;

    /**
    *  @dev getter for `exchangeIDs` variable
    *  tells to the caller if an ONCHAINID belongs to an exchange or not
    *  @param _exchangeID ONCHAINID to be checked
    *  returns TRUE if the address corresponds to an exchange, FALSE otherwise
    */
    function isExchangeID(address _exchangeID) public view returns (bool){
        return exchangeIDs[_exchangeID];
    }

    /**
    *  @dev getter for `exchangeCounters` variable on the counter parameter of the ExchangeTransferCounter struct
    *  @param _exchangeID exchange ONCHAINID
    *  @param _investorID ONCHAINID to be checked
    *  returns current monthly counter of `_investorID` on `exchangeID` exchange
    */
    function getMonthlyCounter(address _exchangeID, address _investorID) public view returns (uint256) {
        return (exchangeCounters[_exchangeID][_investorID]).monthlyCount;
    }

    /**
    *  @dev getter for `exchangeCounters` variable on the timer parameter of the ExchangeTransferCounter struct
    *  @param _exchangeID exchange ONCHAINID
    *  @param _investorID ONCHAINID to be checked
    *  returns current timer of `_investorID` on `exchangeID` exchange
    */
    function getMonthlyTimer(address _exchangeID, address _investorID) public view returns (uint256) {
        return (exchangeCounters[_exchangeID][_investorID]).monthlyTimer;
    }

    /**
    *  @dev getter for `exchangeMonthlyLimit` variable
    *  @param _exchangeID exchange ONCHAINID
    *  returns the monthly limit set for that exchange
    */
    function getExchangeMonthlyLimit(address _exchangeID) public view returns (uint256) {
        return exchangeMonthlyLimit[_exchangeID];
    }

    /**
    *  @dev tags the ONCHAINID as being an exchange ID
    *  @param _exchangeID ONCHAINID to be tagged
    *  Function can be called only by owner of the compliance contract
    *  Cannot be called on an address already tagged as being an exchange
    *  emits an `ExchangeIDAdded` event
    */
    function addExchangeID(address _exchangeID) public onlyOwner {
        require(!isExchangeID(_exchangeID), 'ONCHAINID already tagged as exchange');
        exchangeIDs[_exchangeID] = true;
        emit ExchangeIDAdded(_exchangeID);
    }

    /**
    *  @dev untags the ONCHAINID as being an exchange ID
    *  @param _exchangeID ONCHAINID to be untagged
    *  Function can be called only by owner of the compliance contract
    *  Cannot be called on an address not tagged as being an exchange
    *  emits an `ExchangeIDRemoved` event
    */
    function removeExchangeID(address _exchangeID) public onlyOwner {
        require(isExchangeID(_exchangeID), 'ONCHAINID not tagged as exchange');
        exchangeIDs[_exchangeID] = false;
        emit ExchangeIDRemoved(_exchangeID);
    }

    /**
    *  @dev checks if the month has finished since the cooldown has been triggered for this identity
    *  @param _exchangeID ONCHAINID of the exchange
    *  @param _investorID ONCHAINID to be checked
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function _isExchangeMonthFinished(address _exchangeID, address _investorID) internal view returns (bool) {
        return (getMonthlyTimer(_exchangeID, _investorID) <= block.timestamp);
    }

    /**
    *  @dev resets cooldown for the month if cooldown has reached the time limit of 30days
    *  @param _exchangeID ONCHAINID of the exchange
    *  @param _investorID ONCHAINID to reset
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function _resetExchangeMonthlyCooldown(address _exchangeID, address _investorID) internal {
        if (_isExchangeMonthFinished(_exchangeID, _investorID)) {
            (exchangeCounters[_exchangeID][_investorID]).monthlyTimer = block.timestamp + 30 days;
            (exchangeCounters[_exchangeID][_investorID]).monthlyCount = 0;
        }
    }

    /**
    *  @dev Checks if monthly cooldown must be reset, then check if _value sent has been exceeded,
    *  if not increases user's OnchainID counters.
    *  @param _exchangeID ONCHAINID of the exchange
    *  @param _investorID address on which counters will be increased
    *  @param _value, value of transaction)to be increased
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function _increaseExchangeCounters(address _exchangeID, address _investorID, uint256 _value) internal {
        _resetExchangeMonthlyCooldown(_exchangeID, _investorID);

        if ((getMonthlyCounter(_exchangeID, _investorID) + _value) <= exchangeMonthlyLimit[_exchangeID]) {
            (exchangeCounters[_exchangeID][_investorID]).monthlyCount += _value;
        }
    }

    /**
     *  @dev Set the limit of tokens allowed to be transferred monthly.
     *  @param _exchangeID ONCHAINID of the exchange
     *  @param _newExchangeMonthlyLimit The new monthly limit of tokens
     *  Only the owner of the Compliance smart contract can call this function
     */
    function setExchangeMonthlyLimit(address _exchangeID, uint256 _newExchangeMonthlyLimit) external onlyOwner {
        exchangeMonthlyLimit[_exchangeID] = _newExchangeMonthlyLimit;
        emit ExchangeMonthlyLimitUpdated(_exchangeID, _newExchangeMonthlyLimit);
    }

    /**
    *  @dev state update of the compliance feature post-transfer.
    *  updates counters if the receiver address is linked to an exchange ONCHAINID and sender is not an agent
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` sent to `_to`
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function transferActionOnExchangeMonthlyLimits(address _from, address _to, uint256 _value) internal {
        address senderIdentity = _getIdentity(_from);
        address receiverIdentity = _getIdentity(_to);
        if(isExchangeID(receiverIdentity) && !isTokenAgent(_from)) {
            _increaseExchangeCounters(senderIdentity, receiverIdentity, _value);
        }
    }

    /**
    *  @dev state update of the compliance feature post-minting.
    *  this compliance feature doesn't require state update post-minting
    *  @param _to the address of the minting beneficiary
    *  @param _value the amount of tokens minted on `_to` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function creationActionOnExchangeMonthlyLimits(address _to, uint256 _value) internal {}

    /**
    *  @dev state update of the compliance feature post-burning.
    *  this compliance feature doesn't require state update post-burning
    *  @param _from the wallet address on which tokens burnt
    *  @param _value the amount of tokens burnt from `_from` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function destructionActionOnExchangeMonthlyLimits(address _from, uint256 _value) internal {}

    /**
    *  @dev check on the compliance status of a transaction.
    *  If the check returns TRUE, the transfer is allowed to be executed, if the check returns FALSE, the compliance
    *  feature will block the transfer execution
    *  The check will verify if the transfer is done to an exchange wallet, if it is the case it will check if the
    *  transfer respects the limitations in terms of authorized monthly deposit volume, if it does the check
    *  will return true, if the transfer doesn't respect the limitations it will return false and block the transfer
    *  Agents are allowed to bypass this check
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` would send to `_to`
    */
    function complianceCheckOnExchangeMonthlyLimits(address _from, address _to, uint256 _value) public view returns
    (bool) {
        address senderIdentity = _getIdentity(_from);
        address receiverIdentity = _getIdentity(_to);
        if (!isTokenAgent(_from) && _from != address(0)) {
            if (isExchangeID(receiverIdentity)) {
                if(_value > exchangeMonthlyLimit[receiverIdentity]) {
                    return false;
                }
                if (!_isExchangeMonthFinished(receiverIdentity, senderIdentity)
                && ((getMonthlyCounter(receiverIdentity, senderIdentity) + _value > exchangeMonthlyLimit[receiverIdentity]))) {
                    return false;
                }
            }
        }
        return true;
    }

}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../BasicCompliance.sol';

/**
 *  this feature allows to put a maximum balance for an investor
 */
abstract contract MaxBalance is BasicCompliance {

    /**
     *  this event is emitted when the max balance has been set.
     *  `_maxBalance` is the max amount of tokens that a user can hold .
     */
    event MaxBalanceSet(uint256 _maxBalance);

    /// maximum balance per investor ONCHAINID
    uint256 public maxBalance;

    /// mapping of balances per ONCHAINID
    mapping (address => uint256) public IDBalance;

    /**
     *  @dev sets max balance limit
     *  @param _max max amount of tokens owned by an individual
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `MaxBalanceSet` event
     */
    function setMaxBalance(uint256 _max) external onlyOwner {
        maxBalance = _max;
        emit MaxBalanceSet(_max);
    }

    /**
    *  @dev state update of the compliance feature post-transfer.
    *  updates the ONCHAINID-based balance of `_to` and `_from` post-transfer
    *  revert if post-transfer balance of `_to` is higher than max balance
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` sent to `_to`
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function transferActionOnMaxBalance(address _from, address _to, uint256 _value) internal {
        address _idFrom = _getIdentity(_from);
        address _idTo = _getIdentity(_to);
        IDBalance[_idTo] += _value;
        IDBalance[_idFrom] -= _value;
        require (IDBalance[_idTo] <= maxBalance, 'post-transfer balance too high');
    }

    /**
    *  @dev state update of the compliance feature post-minting.
    *  updates the ONCHAINID-based balance of `_to` post-minting
    *  revert if post-minting balance of `_to` is higher than max balance
    *  @param _to the address of the minting beneficiary
    *  @param _value the amount of tokens minted on `_to` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function creationActionOnMaxBalance(address _to, uint256 _value) internal {
        address _idTo = _getIdentity(_to);
        IDBalance[_idTo] += _value;
        require (IDBalance[_idTo] <= maxBalance, 'post-minting balance too high');
    }

    /**
    *  @dev state update of the compliance feature post-burning.
    *  updates the ONCHAINID-based balance of `_from` post-burning
    *  @param _from the wallet address on which tokens burnt
    *  @param _value the amount of tokens burnt from `_from` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function destructionActionOnMaxBalance(address _from, uint256 _value) internal {
        address _idFrom = _getIdentity(_from);
        IDBalance[_idFrom] -= _value;
    }

    /**
    *  @dev check on the compliance status of a transaction.
    *  If the check returns TRUE, the transfer is allowed to be executed, if the check returns FALSE, the compliance
    *  feature will block the transfer execution
    *  The check will verify if the transfer doesn't push the ONCHAINID-based balance of `_to` above
    *  the authorized threshold fixed by maxBalance
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` would send to `_to`
    */
    function complianceCheckOnMaxBalance (address _from, address _to, uint256 _value) public view returns (bool) {
        if (_value > maxBalance) {
            return false;
        }
        address _id = _getIdentity(_to);
        if ((IDBalance[_id] + _value) > maxBalance) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../BasicCompliance.sol';

/**
 *  this feature allows to put a supply limit on the token
 *  If an agent tries to mint more tokens than the maximum threshold, the minting will fail
 */
abstract contract SupplyLimit is BasicCompliance {

    /**
     *  this event is emitted when the supply limit has been set.
     *  `_limit` is the max amount of tokens in circulation.
     */
    event SupplyLimitSet(uint256 _limit);

    /// supply limit variable
    uint256 public supplyLimit;

    /**
     *  @dev sets supply limit.
     *  Supply limit has to be smaller or equal to the actual supply.
     *  @param _limit max amount of tokens to be created
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `SupplyLimitSet` event
     */
    function setSupplyLimit(uint256 _limit) external onlyOwner {
        supplyLimit = _limit;
        emit SupplyLimitSet(_limit);
    }

    /**
    *  @dev state update of the compliance feature post-transfer.
    *  this compliance feature doesn't require state update post-transfer
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` sent to `_to`
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function transferActionOnSupplyLimit(address _from, address _to, uint256 _value) internal {}

    /**
    *  @dev state update of the compliance feature post-minting.
    *  reverts if the post-minting supply is higher than the max supply
    *  @param _to the address of the minting beneficiary
    *  @param _value the amount of tokens minted on `_to` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function creationActionOnSupplyLimit(address _to, uint256 _value) internal {
        require(_tokenBound.totalSupply() <= supplyLimit, 'cannot mint more tokens');
    }

    /**
    *  @dev state update of the compliance feature post-burning.
    *  this compliance feature doesn't require state update post-burning
    *  @param _from the wallet address on which tokens burnt
    *  @param _value the amount of tokens burnt from `_from` wallet
    *  internal function, can be called only from the functions of the Compliance smart contract
    */
    function destructionActionOnSupplyLimit(address _from, uint256 _value) internal {}

    /**
    *  @dev check on the compliance status of a transaction.
    *  This check always returns true, real check is done at the creation action level
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _value the amount of tokens that `_from` would send to `_to`
    */
    function complianceCheckOnSupplyLimit (address _from, address _to, uint256 _value)
    internal view returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

interface ICompliance {
    /**
     *  this event is emitted when the Agent has been added on the allowedList of this Compliance.
     *  the event is emitted by the Compliance constructor and by the addTokenAgent function
     *  `_agentAddress` is the address of the Agent to add
     */
    event TokenAgentAdded(address _agentAddress);

    /**
     *  this event is emitted when the Agent has been removed from the agent list of this Compliance.
     *  the event is emitted by the Compliance constructor and by the removeTokenAgent function
     *  `_agentAddress` is the address of the Agent to remove
     */
    event TokenAgentRemoved(address _agentAddress);

    /**
     *  this event is emitted when a token has been bound to the compliance contract
     *  the event is emitted by the bindToken function
     *  `_token` is the address of the token to bind
     */
    event TokenBound(address _token);

    /**
     *  this event is emitted when a token has been unbound from the compliance contract
     *  the event is emitted by the unbindToken function
     *  `_token` is the address of the token to unbind
     */
    event TokenUnbound(address _token);

    /**
     *  @dev Returns true if the Address is in the list of token agents
     *  @param _agentAddress address of this agent
     */
    function isTokenAgent(address _agentAddress) external view returns (bool);

    /**
     *  @dev Returns true if the address given corresponds to a token that is bound with the Compliance contract
     *  @param _token address of the token
     */
    function isTokenBound(address _token) external view returns (bool);

    /**
     *  @dev adds an agent to the list of token agents
     *  @param _agentAddress address of the agent to be added
     *  Emits a TokenAgentAdded event
     */
    function addTokenAgent(address _agentAddress) external;

    /**
     *  @dev remove Agent from the list of token agents
     *  @param _agentAddress address of the agent to be removed (must be added first)
     *  Emits a TokenAgentRemoved event
     */
    function removeTokenAgent(address _agentAddress) external;

    /**
     *  @dev binds a token to the compliance contract
     *  @param _token address of the token to bind
     *  Emits a TokenBound event
     */
    function bindToken(address _token) external;

    /**
     *  @dev unbinds a token from the compliance contract
     *  @param _token address of the token to unbind
     *  Emits a TokenUnbound event
     */
    function unbindToken(address _token) external;

    /**
     *  @dev checks that the transfer is compliant.
     *  default compliance always returns true
     *  READ ONLY FUNCTION, this function cannot be used to increment
     *  counters, emit events, ...
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function canTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (bool);

    /**
     *  @dev function called whenever tokens are transferred
     *  from one wallet to another
     *  this function can update state variables in the compliance contract
     *  these state variables being used by `canTransfer` to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the compliance smart contract
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function transferred(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /**
     *  @dev function called whenever tokens are created
     *  on a wallet
     *  this function can update state variables in the compliance contract
     *  these state variables being used by `canTransfer` to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the compliance smart contract
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function created(address _to, uint256 _amount) external;

    /**
     *  @dev function called whenever tokens are destroyed
     *  this function can update state variables in the compliance contract
     *  these state variables being used by `canTransfer` to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the compliance smart contract
     *  @param _from The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     */
    function destroyed(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../features/ApproveTransfer.sol';

contract ApproveTransferTest is ApproveTransfer {
    /**
    *  @dev See {ICompliance-transferred}.
    */
    function transferred(address _from, address _to, uint256 _value) external onlyToken override {
        transferActionOnApproveTransfer(_from, _to, _value);
    }

    /**
     *  @dev See {ICompliance-created}.
     */
    function created(address _to, uint256 _value) external onlyToken override {
        creationActionOnApproveTransfer(_to, _value);
    }

    /**
     *  @dev See {ICompliance-destroyed}.
     */
    function destroyed(address _from, uint256 _value) external onlyToken override {
        destructionActionOnApproveTransfer(_from, _value);
    }

    /**
     *  @dev See {ICompliance-canTransfer}.
     */
    function canTransfer(address _from, address _to, uint256 _value) external view override returns (bool) {
        if (!complianceCheckOnApproveTransfer(_from, _to, _value))
        {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../features/CountryRestrictions.sol';

contract CountryRestrictionsTest is CountryRestrictions {
    /**
    *  @dev See {ICompliance-transferred}.
    */
    function transferred(address _from, address _to, uint256 _value) external onlyToken override {
        transferActionOnCountryRestrictions(_from, _to, _value);
    }

    /**
     *  @dev See {ICompliance-created}.
     */
    function created(address _to, uint256 _value) external onlyToken override {
        creationActionOnCountryRestrictions(_to, _value);
    }

    /**
     *  @dev See {ICompliance-destroyed}.
     */
    function destroyed(address _from, uint256 _value) external onlyToken override {
        destructionActionOnCountryRestrictions(_from, _value);
    }

    /**
     *  @dev See {ICompliance-canTransfer}.
     */
    function canTransfer(address _from, address _to, uint256 _value) external view override returns (bool) {
        if (!complianceCheckOnCountryRestrictions(_from, _to, _value))
        {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../features/CountryWhitelisting.sol';

contract CountryWhitelistingTest is CountryWhitelisting {
    /**
    *  @dev See {ICompliance-transferred}.
    */
    function transferred(address _from, address _to, uint256 _value) external onlyToken override {
        transferActionOnCountryWhitelisting(_from, _to, _value);
    }

    /**
     *  @dev See {ICompliance-created}.
     */
    function created(address _to, uint256 _value) external onlyToken override {
        creationActionOnCountryWhitelisting(_to, _value);
    }

    /**
     *  @dev See {ICompliance-destroyed}.
     */
    function destroyed(address _from, uint256 _value) external onlyToken override {
        destructionActionOnCountryWhitelisting(_from, _value);
    }

    /**
     *  @dev See {ICompliance-canTransfer}.
     */
    function canTransfer(address _from, address _to, uint256 _value) external view override returns (bool) {
        if (!complianceCheckOnCountryWhitelisting(_from, _to, _value))
        {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../features/DayMonthLimits.sol';

contract DayMonthLimitsTest is DayMonthLimits {
    /**
    *  @dev See {ICompliance-transferred}.
    */
    function transferred(address _from, address _to, uint256 _value) external onlyToken override {
        transferActionOnDayMonthLimits(_from, _to, _value);
    }

    /**
     *  @dev See {ICompliance-created}.
     */
    function created(address _to, uint256 _value) external onlyToken override {
        creationActionOnDayMonthLimits(_to, _value);
    }

    /**
     *  @dev See {ICompliance-destroyed}.
     */
    function destroyed(address _from, uint256 _value) external onlyToken override {
        destructionActionOnDayMonthLimits(_from, _value);
    }

    /**
     *  @dev See {ICompliance-canTransfer}.
     */
    function canTransfer(address _from, address _to, uint256 _value) external view override returns (bool) {
        if (!complianceCheckOnDayMonthLimits(_from, _to, _value))
        {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../features/ExchangeMonthlyLimits.sol';

contract ExchangeMonthlyLimitsTest is ExchangeMonthlyLimits {
    /**
    *  @dev See {ICompliance-transferred}.
    */
    function transferred(address _from, address _to, uint256 _value) external onlyToken override {
        transferActionOnExchangeMonthlyLimits(_from, _to, _value);
    }

    /**
     *  @dev See {ICompliance-created}.
     */
    function created(address _to, uint256 _value) external onlyToken override {
        creationActionOnExchangeMonthlyLimits(_to, _value);
    }

    /**
     *  @dev See {ICompliance-destroyed}.
     */
    function destroyed(address _from, uint256 _value) external onlyToken override {
        destructionActionOnExchangeMonthlyLimits(_from, _value);
    }

    /**
     *  @dev See {ICompliance-canTransfer}.
     */
    function canTransfer(address _from, address _to, uint256 _value) external view override returns (bool) {
        if (!complianceCheckOnExchangeMonthlyLimits(_from, _to, _value))
        {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../features/MaxBalance.sol';

contract MaxBalanceTest is MaxBalance {
    /**
    *  @dev See {ICompliance-transferred}.
    */
    function transferred(address _from, address _to, uint256 _value) external onlyToken override {
        transferActionOnMaxBalance(_from, _to, _value);
    }

    /**
     *  @dev See {ICompliance-created}.
     */
    function created(address _to, uint256 _value) external onlyToken override {
        creationActionOnMaxBalance(_to, _value);
    }

    /**
     *  @dev See {ICompliance-destroyed}.
     */
    function destroyed(address _from, uint256 _value) external onlyToken override {
        destructionActionOnMaxBalance(_from, _value);
    }

    /**
     *  @dev See {ICompliance-canTransfer}.
     */
    function canTransfer(address _from, address _to, uint256 _value) external view override returns (bool) {
        if (!complianceCheckOnMaxBalance(_from, _to, _value))
        {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../features/SupplyLimit.sol';

contract SupplyLimitTest is SupplyLimit {
    /**
    *  @dev See {ICompliance-transferred}.
    */
    function transferred(address _from, address _to, uint256 _value) external onlyToken override {
        transferActionOnSupplyLimit(_from, _to, _value);
    }

    /**
     *  @dev See {ICompliance-created}.
     */
    function created(address _to, uint256 _value) external onlyToken override {
        creationActionOnSupplyLimit(_to, _value);
    }

    /**
     *  @dev See {ICompliance-destroyed}.
     */
    function destroyed(address _from, uint256 _value) external onlyToken override {
        destructionActionOnSupplyLimit(_from, _value);
    }

    /**
     *  @dev See {ICompliance-canTransfer}.
     */
    function canTransfer(address _from, address _to, uint256 _value) external view override returns (bool) {
        if (!complianceCheckOnSupplyLimit(_from, _to, _value))
        {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

interface IModularCompliance {

    /// events

    /// @dev Event emitted for each executed interaction with a module contract.
    ///
    /// For gas efficiency, only the interaction calldata selector (first 4
    /// bytes) is included in the event. For interactions without calldata or
    /// whose calldata is shorter than 4 bytes, the selector will be `0`.
    event ModuleInteraction(address indexed target, bytes4 selector);

    /**
     *  this event is emitted when a token has been bound to the compliance contract
     *  the event is emitted by the bindToken function
     *  `_token` is the address of the token to bind
     */
    event TokenBound(address _token);

    /**
     *  this event is emitted when a token has been unbound from the compliance contract
     *  the event is emitted by the unbindToken function
     *  `_token` is the address of the token to unbind
     */
    event TokenUnbound(address _token);

    /**
     *  this event is emitted when a module has been added to the list of modules bound to the compliance contract
     *  the event is emitted by the addModule function
     *  `_module` is the address of the compliance module
     */
    event ModuleAdded(address _module);

    /**
     *  this event is emitted when a module has been removed from the list of modules bound to the compliance contract
     *  the event is emitted by the removeModule function
     *  `_module` is the address of the compliance module
     */
    event ModuleRemoved(address _module);

    /// functions

    /**
     *  @dev getter for the address of the token bound
     *  returns the address of the token
     */
    function getTokenBound() external view returns (address);

    /**
     *  @dev checks if a module is bound to the compliance contract
     *  returns true if module is bound, false otherwise
     */
    function isModuleBound(address _module) external view returns (bool);

    /**
     *  @dev binds a token to the compliance contract
     *  @param _token address of the token to bind
     *  This function can be called ONLY by the owner of the compliance contract
     *  Emits a TokenBound event
     */
    function bindToken(address _token) external;

    /**
     *  @dev unbinds a token from the compliance contract
     *  @param _token address of the token to unbind
     *  This function can be called ONLY by the owner of the compliance contract
     *  Emits a TokenUnbound event
     */
    function unbindToken(address _token) external;

    /**
     *  @dev adds a module to the list of compliance modules
     *  @param _module address of the module to add
     *  This function can be called ONLY by the owner of the compliance contract
     *  Emits a ModuleAdded event
     */
    function addModule(address _module) external;

    /**
     *  @dev removes a module from the list of compliance modules
     *  @param _module address of the module to remove
     *  This function can be called ONLY by the owner of the compliance contract
     *  Emits a ModuleRemoved event
     */
    function removeModule(address _module) external;

    /**
     *  @dev getter for the modules bound to the compliance contract
     *  returns address array of module contracts bound to the compliance
     */
    function getModules() external view returns (address[] memory);

    function callModuleFunction(bytes calldata callData, address _module) external;

    /**
     *  @dev checks that the transfer is compliant.
     *  default compliance always returns true
     *  READ ONLY FUNCTION, this function cannot be used to increment
     *  counters, emit events, ...
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfe
     *  This function will call moduleCheck() on every module bound to the compliance
     *  If each of the module checks return TRUE, this function will return TRUE as well
     *  returns FALSE otherwise
     */
    function canTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (bool);

    /**
     *  @dev function called whenever tokens are transferred
     *  from one wallet to another
     *  this function can update state variables in the modules bound to the compliance
     *  these state variables being used by the module checks to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the modules
     *  This function can be called ONLY by the token contract bound to the compliance
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the transfer
     *  This function calls moduleTransferAction() on each module bound to the compliance contract
     */
    function transferred(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /**
     *  @dev function called whenever tokens are created on a wallet
     *  this function can update state variables in the modules bound to the compliance
     *  these state variables being used by the module checks to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the modules
     *  This function can be called ONLY by the token contract bound to the compliance
     *  @param _to The address of the receiver
     *  @param _amount The amount of tokens involved in the minting
     *  This function calls moduleMintAction() on each module bound to the compliance contract
     */
    function created(address _to, uint256 _amount) external;

    /**
     *  @dev function called whenever tokens are destroyed from a wallet
     *  this function can update state variables in the modules bound to the compliance
     *  these state variables being used by the module checks to decide if a transfer
     *  is compliant or not depending on the values stored in these state variables and on
     *  the parameters of the modules
     *  This function can be called ONLY by the token contract bound to the compliance
     *  @param _from The address on which tokens are burnt
     *  @param _amount The amount of tokens involved in the burn
     *  This function calls moduleBurnAction() on each module bound to the compliance contract
     */
    function destroyed(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

contract MCStorage {
    /// token linked to the compliance contract
    address internal _tokenBound;

    /// Array of modules bound to the compliance
    address[] internal modules;

    /// Mapping of module binding status
    mapping(address => bool) internal moduleBound;
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '../../token/IToken.sol';
import './IModularCompliance.sol';
import './MCStorage.sol';
import './modules/IModule.sol';


contract ModularCompliance is IModularCompliance, OwnableUpgradeable, MCStorage {

    /**
     * @dev Throws if called by any address that is not a token bound to the compliance.
     */
    modifier onlyToken() {
        require(msg.sender == _tokenBound, 'error : this address is not a token bound to the compliance contract');
        _;
    }

    function init() public initializer {
        __Ownable_init();
    }

    /**
     *  @dev See {IModularCompliance-getTokenBound}.
     */
    function getTokenBound() public view override returns (address) {
        return _tokenBound;
    }

    /**
     *  @dev See {IModularCompliance-bindToken}.
     */
    function bindToken(address _token) external override {
        require(owner() == msg.sender || (_tokenBound == address(0) && msg.sender == _token),
        'only owner or token can call');
        _tokenBound = _token;
        emit TokenBound(_token);
    }

    /**
    *  @dev See {IModularCompliance-unbindToken}.
    */
    function unbindToken(address _token) external override {
        require(owner() == msg.sender || msg.sender == _token , 'only owner or token can call');
        require(_token == _tokenBound, 'This token is not bound');
        delete _tokenBound;
        emit TokenUnbound(_token);
    }

    /**
     *  @dev See {IModularCompliance-addModule}.
     */
    function addModule(address _module) external override onlyOwner {
        require(!moduleBound[_module], 'module already bound');
        modules.push(_module);
        IModule(_module).bindCompliance(address(this));
        moduleBound[_module] = true;
        emit ModuleAdded(_module);
    }

    /**
     *  @dev See {IModularCompliance-removeModule}.
     */
    function removeModule(address _module) external override onlyOwner {
        require(moduleBound[_module], 'module not bound');
        uint256 length = modules.length;
        for (uint256 i = 0; i < length; i++) {
            if (modules[i] == _module) {
                modules[i] = modules[length - 1];
                modules.pop();
                IModule(_module).unbindCompliance(address(this));
                moduleBound[_module] = false;
                emit ModuleRemoved(_module);
                break;
            }
        }
    }

    /**
     *  @dev See {IModularCompliance-isModuleBound}.
     */
    function isModuleBound(address _module) external view override returns (bool) {
        return moduleBound[_module];
    }

    /**
     *  @dev See {IModularCompliance-getModules}.
     */
    function getModules() external view override returns (address[] memory) {
        return modules;
    }

    /**
    *  @dev See {IModularCompliance-transferred}.
    */
    function transferred(address _from, address _to, uint256 _value) external onlyToken override {
        uint256 length = modules.length;
        for (uint256 i = 0; i < length; i++) {
            IModule(modules[i]).moduleTransferAction(_from, _to, _value);
        }
    }

    /**
     *  @dev See {IModularCompliance-created}.
     */
    function created(address _to, uint256 _value) external onlyToken override {
        uint256 length = modules.length;
        for (uint256 i = 0; i < length; i++) {
            IModule(modules[i]).moduleMintAction(_to, _value);
        }
    }

    /**
     *  @dev See {IModularCompliance-destroyed}.
     */
    function destroyed(address _from, uint256 _value) external onlyToken override {
        uint256 length = modules.length;
        for (uint256 i = 0; i < length; i++) {
            IModule(modules[i]).moduleBurnAction(_from, _value);
        }
    }

    /**
     *  @dev See {IModularCompliance-canTransfer}.
     */
    function canTransfer(address _from, address _to, uint256 _value) external view override returns (bool) {
        uint256 length = modules.length;
        for (uint256 i = 0; i < length; i++) {
            if (!IModule(modules[i]).moduleCheck(_from, _to, _value, address(this))) {
                return false;
            }
        }
        return true;
    }

    /**
     *  @dev calls any onlyCompliance function available on the module contract
     *  Compliance has to be bound to the module to be able to make this call
     *  Only Owner can call
     *  @param callData the transaction data, abi encoded
     *  @param _module the module address
     *  require the module to be bound to the compliance contract
     */
    function callModuleFunction(bytes calldata callData, address _module) external override onlyOwner {
        require(moduleBound[_module], 'call only on bound module');
        // NOTE: Use assembly to call the interaction instead of a low level
        // call for two reasons:
        // - We don't want to copy the return data, since we discard it for
        // interactions.
        // - Solidity will under certain conditions generate code to copy input
        // calldata twice to memory (the second being a "memcopy loop").
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            calldatacopy(freeMemoryPointer, callData.offset, callData.length)
            if iszero(
            call(
            gas(),
            _module,
            0,
            freeMemoryPointer,
            callData.length,
            0,
            0
            ))
            {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        emit ModuleInteraction(_module, selector(callData));

    }

    /// @dev Extracts the Solidity ABI selector for the specified interaction.
    /// @param callData Interaction data.
    /// @return result The 4 byte function selector of the call encoded in
    /// this interaction.
    function selector(bytes calldata callData) internal pure returns (bytes4 result) {
        if (callData.length >= 4) {
            // NOTE: Read the first word of the interaction's calldata. The
            // value does not need to be shifted since `bytesN` values are left
            // aligned, and the value does not need to be masked since masking
            // occurs when the value is accessed and not stored:
            // <https://docs.soliditylang.org/en/v0.7.6/abi-spec.html#encoding-of-indexed-event-parameters>
            // <https://docs.soliditylang.org/en/v0.7.6/assembly.html#access-to-external-variables-functions-and-libraries>
            // solhint-disable-next-line no-inline-assembly
            assembly {
                result := calldataload(callData.offset)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import './IModule.sol';
import '../../../roles/AgentRole.sol';

abstract contract AbstractModule is IModule {

    /// compliance contract binding status
    mapping(address => bool) private complianceBound;

    /**
     * @dev Throws if `_compliance` is not a bound compliance contract address.
     */
    modifier onlyBoundCompliance(address _compliance) {
        require(complianceBound[_compliance], 'compliance not bound');
        _;
    }

    /**
     * @dev Throws if called from an address that is not a bound compliance contract.
     */
    modifier onlyComplianceCall() {
        require(complianceBound[msg.sender], 'only bound compliance can call');
        _;
    }

    /**
     *  @dev See {IModule-isComplianceBound}.
     */
    function isComplianceBound(address _compliance) external view override returns (bool) {
        return complianceBound[_compliance];
    }

    /**
     *  @dev See {IModule-bindCompliance}.
     */
    function bindCompliance(address _compliance) external override {
        require(!complianceBound[_compliance], 'compliance already bound');
        require(msg.sender == _compliance, 'only compliance contract can call');
        complianceBound[_compliance] = true;
        emit ComplianceBound(_compliance);
    }

    /**
     *  @dev See {IModule-unbindCompliance}.
     */
    function unbindCompliance(address _compliance) external onlyComplianceCall override {
        complianceBound[_compliance] = false;
        emit ComplianceUnbound(_compliance);
    }

}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../IModularCompliance.sol';
import '../../../token/IToken.sol';
import './AbstractModule.sol';
import '../../../roles/AgentRole.sol';

/**
 *  this module allows to require the pre-validation of a transfer before allowing it to be executed
 */
contract ConditionalTransferModule is AbstractModule {
    /**
     *  this event is emitted whenever a transfer is approved.
     *  the event is emitted by 'approveTransfer' function.
     *  `_from` is the address of transfer sender.
     *  `_to` is the address of transfer recipient
     *  `_amount` is the token amount to be sent (take care of decimals)
     *  `_token` is the token address of the token concerned by the approval
     */
    event TransferApproved(address _from, address _to, uint _amount, address _token);

    /**
     *  this event is emitted whenever a transfer approval is removed.
     *  the event is emitted by 'unApproveTransfer' function.
     *  `_from` is the address of transfer sender.
     *  `_to` is the address of transfer recipient
     *  `_amount` is the token amount to be sent (take care of decimals)
     *  `_token` is the token address of the token concerned by the approval
     */
    event ApprovalRemoved(address _from, address _to, uint _amount, address _token);

    /// Mapping between transfer details and their approval status (amount of transfers approved) per compliance
    mapping(address => mapping(bytes32 => uint)) private _transfersApproved;

    /**
     *  @dev Returns true if transfer is approved
     *  @param _compliance the modular compliance address
     *  @param _transferHash, bytes corresponding to the transfer details, hashed
     *  requires `_compliance` to be bound to this module
     */
    function isTransferApproved(address _compliance, bytes32 _transferHash) public view onlyBoundCompliance(_compliance)
    returns (bool) {
        if (((_transfersApproved[_compliance])[_transferHash]) > 0) {
            return true;
        }
        return false;
    }

    /**
     *  @dev Returns the amount of identical transfers approved
     *  @param _compliance the modular compliance address
     *  @param _transferHash, bytes corresponding to the transfer details, hashed
     *  requires `_compliance` to be bound to this module
     */
    function getTransferApprovals(address _compliance, bytes32 _transferHash) public view
    onlyBoundCompliance(_compliance) returns (uint) {
        return (_transfersApproved[_compliance])[_transferHash];
    }

    /**
     *  @dev Calculates the hash of a transfer approval
     *  @param _from the address of the transfer sender
     *  @param _to the address of the transfer receiver
     *  @param _amount the amount of tokens that `_from` would send to `_to`
     *  @param _token the address of the token that would be transferred
     *  returns the transferId of the transfer
     */
    function calculateTransferHash (
        address _from,
        address _to,
        uint _amount,
        address _token
    ) public pure returns (bytes32){
        bytes32 transferHash = keccak256(abi.encode(_from, _to, _amount, _token));
        return transferHash;
    }

    /**
    *  @dev Approves a transfer
    *  once a transfer is approved, the sender is allowed to execute it
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _amount the amount of tokens that `_from` would send to `_to`
    *  Only a bound compliance can call this function
    *  emits a `TransferApproved` event
    */
    function approveTransfer(address _from, address _to, uint _amount) public onlyComplianceCall {
        bytes32 transferHash = calculateTransferHash(_from, _to, _amount, IModularCompliance(msg.sender).getTokenBound());
        _transfersApproved[msg.sender][transferHash]++;
        emit TransferApproved(_from, _to, _amount, IModularCompliance(msg.sender).getTokenBound());
    }

    /**
    *  @dev removes approval on a transfer previously approved
    *  requires the transfer to be previously approved
    *  once a transfer approval is removed, the sender is not allowed to execute it anymore
    *  @param _from the address of the transfer sender
    *  @param _to the address of the transfer receiver
    *  @param _amount the amount of tokens that `_from` was allowed to send to `_to`
    *  Only a bound compliance can call this function
    *  emits an `ApprovalRemoved` event
    */
    function unApproveTransfer(address _from, address _to, uint _amount) public onlyComplianceCall {
        bytes32 transferHash = calculateTransferHash(_from, _to, _amount, IModularCompliance(msg.sender).getTokenBound());
        require(_transfersApproved[msg.sender][transferHash] > 0, 'not approved');
        _transfersApproved[msg.sender][transferHash]--;
        emit ApprovalRemoved(_from, _to, _amount, IModularCompliance(msg.sender).getTokenBound());

    }

    /**
    *  @dev Approves transfers in batch
    *  once a transfer is approved, the sender is allowed to execute it
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_from.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _from the array of addresses of the transfer senders
    *  @param _to the array of addresses of the transfer receivers
    *  @param _amount the array of tokens amounts that `_from` would send to `_to`
    *  Only a bound compliance can call this function
    *  emits `_from.length` `TransferApproved` events
    */
    function batchApproveTransfers(address[] calldata _from, address[] calldata _to, uint[] calldata _amount)
    external onlyComplianceCall {
        for (uint256 i = 0; i < _from.length; i++){
            approveTransfer(_from[i], _to[i], _amount[i]);
        }
    }

    /**
    *  @dev removes approval on a transfer previously approved
    *  requires the transfer to be previously approved
    *  once a transfer approval is removed, the sender is not allowed to execute it anymore
    *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_from.length` IS TOO HIGH,
    *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
    *  @param _from the array of addresses of the transfer senders
    *  @param _to the array of addresses of the transfer receivers
    *  @param _amount the array of token amounts that `_from` were allowed to send to `_to`
    *  Only a bound compliance can call this function
    *  emits `_from.length` `ApprovalRemoved` events
    */
    function batchUnApproveTransfers(address[] calldata _from, address[] calldata _to, uint[] calldata _amount)
    external onlyComplianceCall {
        for (uint256 i = 0; i < _from.length; i++){
            unApproveTransfer(_from[i], _to[i], _amount[i]);
        }
    }

    /**
     *  @dev See {IModule-moduleTransferAction}.
     *  transfer approval is removed post-transfer if it was pre-approved
     *  the check on whether the transfer was pre-approved or not here is to allow forced transfers to bypass the module
     */
    function moduleTransferAction(
        address _from,
        address _to,
        uint256 _value)
    external override onlyComplianceCall {
        bytes32 transferHash = calculateTransferHash(_from, _to, _value, IModularCompliance(msg.sender).getTokenBound());
        if(_transfersApproved[msg.sender][transferHash] > 0) {
            _transfersApproved[msg.sender][transferHash]--;
            emit ApprovalRemoved(_from, _to, _value, IModularCompliance(msg.sender).getTokenBound());
        }
    }

    /**
     *  @dev See {IModule-moduleMintAction}.
     *  no mint action required in this module
     */
    function moduleMintAction(
        address _to,
        uint256 _value
    ) external override onlyComplianceCall {}

    /**
     *  @dev See {IModule-moduleBurnAction}.
     *  no burn action required in this module
     */
    function moduleBurnAction(
        address _from,
        uint256 _value
    ) external override onlyComplianceCall {}

    /**
     *  @dev See {IModule-moduleCheck}.
     *  checks if the transfer is approved or not
     */
    function moduleCheck(
        address _from,
        address _to,
        uint256 _value,
        address _compliance
    ) external view override onlyBoundCompliance(_compliance) returns (bool) {
        bytes32 transferHash = calculateTransferHash(_from, _to, _value, IModularCompliance(_compliance).getTokenBound());
        return isTransferApproved(_compliance, transferHash);
    }

}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../IModularCompliance.sol';
import '../../../token/IToken.sol';
import './AbstractModule.sol';

contract CountryAllowModule is AbstractModule {
    /**
     *  this event is emitted whenever a Country has been allowed.
     *  the event is emitted by 'addAllowedCountry' and 'batchAllowCountries' functions.
     *  `_country` is the numeric ISO 3166-1 of the restricted country.
     */
    event CountryAllowed(address _compliance, uint16 _country);
    /**
     *  this event is emitted whenever a Country has been disallowed.
     *  the event is emitted by 'removeAllowedCountry' and 'batchDisallowCountries' functions.
     *  `_country` is the numeric ISO 3166-1 of the disallowed country.
     */
    event CountryUnallowed(address _compliance, uint16 _country);

    /// Mapping between country and their allowance status per compliance contract
    mapping(address => mapping(uint16 => bool)) private _allowedCountries;

    /// Custom Errors
    error CountryAlreadyAllowed(address _compliance, uint16 _country);
    error CountryNotAllowed(address _compliance, uint16 _country);

    /**
     *  @dev Returns true if country is Allowed
     *  @param _country, numeric ISO 3166-1 standard of the country to be checked
     */
    function isCountryAllowed(address _compliance, uint16 _country) public view onlyBoundCompliance(_compliance) returns (bool) {
        return _allowedCountries[_compliance][_country];
    }

    /**
     *  @dev Adds country allowance.
     *  Identities from this country will be able to manipulate Tokens linked to this Compliance.
     *  @param _country Country to be allowed, should be expressed by following numeric ISO 3166-1 standard
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `AddedAllowedCountry` event
     */
    function addAllowedCountry(uint16 _country) external onlyComplianceCall {
        if ((_allowedCountries[msg.sender])[_country] == true) revert CountryAlreadyAllowed(msg.sender, _country);
        (_allowedCountries[msg.sender])[_country] = true;
        emit CountryAllowed(msg.sender, _country);
    }

    /**
     *  @dev Removes country allowance.
     *  Identities from those countries will lose the authorization to manipulate Tokens linked to this Compliance.
     *  @param _country Country to be unrestricted, should be expressed by following numeric ISO 3166-1 standard
     *  Can be called only for a compliance contract that is bound to the CountryAllowModule
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `RemoveAllowedCountry` event
     */
    function removeAllowedCountry(uint16 _country) external onlyComplianceCall {
        if ((_allowedCountries[msg.sender])[_country] == false) revert CountryNotAllowed(msg.sender, _country);
        (_allowedCountries[msg.sender])[_country] = false;
        emit CountryUnallowed(msg.sender, _country);
    }

    /**
     *  @dev Adds country allowance in batch.
     *  Identities from those countries will be allowed to manipulate Tokens linked to this Compliance.
     *  @param _countries Countries to be restricted, should be expressed by following numeric ISO 3166-1 standard
     *  Can be called only for a compliance contract that is bound to the CountryAllowModule
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `AddedAllowedCountry` event
     */
    function batchAllowCountries(uint16[] calldata _countries) external onlyComplianceCall {
        for (uint256 i = 0; i < _countries.length; i++) {
            (_allowedCountries[msg.sender])[_countries[i]] = true;
            emit CountryAllowed(msg.sender, _countries[i]);
        }
    }

    /**
     *  @dev Removes country allowance in batch.
     *  Identities from those countries will lose the authorization to manipulate Tokens linked to this Compliance.
     *  @param _countries Countries to be disallowed, should be expressed by following numeric ISO 3166-1 standard
     *  Can be called only for a compliance contract that is bound to the CountryAllowModule
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `RemoveAllowedCountry` event
     */
    function batchDisallowCountries(uint16[] calldata _countries) external onlyComplianceCall {
        for (uint256 i = 0; i < _countries.length; i++) {
            (_allowedCountries[msg.sender])[_countries[i]] = false;
            emit CountryUnallowed(msg.sender, _countries[i]);
        }
    }

    /**
     *  @dev function used to get the country of a wallet address.
     *  @param _compliance the compliance contract address for which the country verification is required
     *  @param _userAddress the address of the wallet to be checked
     *  Returns the ISO 3166-1 standard country code of the wallet owner
     *  internal function, used only by the contract itself to process checks on investor countries
     */
    function _getCountry(address _compliance, address _userAddress) internal view returns (uint16) {
        return IToken(IModularCompliance(_compliance).getTokenBound()).identityRegistry().investorCountry(_userAddress);
    }

    /**
     *  @dev See {IModule-moduleTransferAction}.
     *  no transfer action required in this module
     */
    function moduleTransferAction(
        address _from,
        address _to,
        uint256 _value
    ) external override onlyComplianceCall {}

    /**
     *  @dev See {IModule-moduleMintAction}.
     *  no mint action required in this module
     */
    function moduleMintAction(
        address _to,
        uint256 _value
    ) external override onlyComplianceCall {}

    /**
     *  @dev See {IModule-moduleBurnAction}.
     *  no burn action required in this module
     */
    function moduleBurnAction(
        address _from,
        uint256 _value
    ) external override onlyComplianceCall {}

    /**
     *  @dev See {IModule-moduleCheck}.
     *  checks if the country of address _to is allowed for this _compliance
     *  returns TRUE if the country of _to is allowed for this _compliance
     *  returns FALSE if the country of _to is not allowed for this _compliance
     */
    function moduleCheck(
        address _from,
        address _to,
        uint256 _value,
        address _compliance
    ) external view override onlyBoundCompliance(_compliance) returns (bool) {
        uint16 receiverCountry = _getCountry(_compliance, _to);
        return isCountryAllowed(_compliance, receiverCountry);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../IModularCompliance.sol';
import '../../../token/IToken.sol';
import './AbstractModule.sol';

contract CountryRestrictModule is AbstractModule {
    /**
     *  this event is emitted whenever a Country has been restricted.
     *  the event is emitted by 'addCountryRestriction' and 'batchRestrictCountries' functions.
     *  `_country` is the numeric ISO 3166-1 of the restricted country.
     */
    event AddedRestrictedCountry(address _compliance, uint16 _country);

    /**
     *  this event is emitted whenever a Country has been unrestricted.
     *  the event is emitted by 'removeCountryRestriction' and 'batchUnrestrictCountries' functions.
     *  `_country` is the numeric ISO 3166-1 of the unrestricted country.
     */
    event RemovedRestrictedCountry(address _compliance, uint16 _country);

    /// Mapping between country and their restriction status per compliance contract
    mapping(address => mapping(uint16 => bool)) private _restrictedCountries;

    /**
     *  @dev Returns true if country is Restricted
     *  @param _country, numeric ISO 3166-1 standard of the country to be checked
     */
    function isCountryRestricted(address _compliance, uint16 _country) public view onlyBoundCompliance(_compliance) returns (bool) {
        return ((_restrictedCountries[_compliance])[_country]);
    }

    /**
     *  @dev Adds country restriction.
     *  Identities from those countries will be forbidden to manipulate Tokens linked to this Compliance.
     *  @param _country Country to be restricted, should be expressed by following numeric ISO 3166-1 standard
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `AddedRestrictedCountry` event
     */
    function addCountryRestriction(uint16 _country) external onlyComplianceCall {
        require((_restrictedCountries[msg.sender])[_country] == false, 'country already restricted');
        (_restrictedCountries[msg.sender])[_country] = true;
        emit AddedRestrictedCountry(msg.sender, _country);
    }

    /**
     *  @dev Removes country restriction.
     *  Identities from those countries will again be authorised to manipulate Tokens linked to this Compliance.
     *  @param _country Country to be unrestricted, should be expressed by following numeric ISO 3166-1 standard
     *  Can be called only for a compliance contract that is bound to the CountryRestrict Module
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `RemovedRestrictedCountry` event
     */
    function removeCountryRestriction(uint16 _country) external onlyComplianceCall {
        require((_restrictedCountries[msg.sender])[_country] == true, 'country not restricted');
        (_restrictedCountries[msg.sender])[_country] = false;
        emit RemovedRestrictedCountry(msg.sender, _country);
    }

    /**
     *  @dev Adds countries restriction in batch.
     *  Identities from those countries will be forbidden to manipulate Tokens linked to this Compliance.
     *  @param _countries Countries to be restricted, should be expressed by following numeric ISO 3166-1 standard
     *  Can be called only for a compliance contract that is bound to the CountryRestrict Module
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `AddedRestrictedCountry` event
     */
    function batchRestrictCountries(uint16[] calldata _countries) external onlyComplianceCall {
        for (uint256 i = 0; i < _countries.length; i++) {
            (_restrictedCountries[msg.sender])[_countries[i]] = true;
            emit AddedRestrictedCountry(msg.sender, _countries[i]);
        }
    }

    /**
     *  @dev Removes country restrictions in batch.
     *  Identities from those countries will again be authorised to manipulate Tokens linked to this Compliance.
     *  @param _countries Countries to be unrestricted, should be expressed by following numeric ISO 3166-1 standard
     *  Can be called only for a compliance contract that is bound to the CountryRestrict Module
     *  Only the owner of the Compliance smart contract can call this function
     *  emits an `RemovedRestrictedCountry` event
     */
    function batchUnrestrictCountries(uint16[] calldata _countries) external onlyComplianceCall {
        for (uint256 i = 0; i < _countries.length; i++) {
            (_restrictedCountries[msg.sender])[_countries[i]] = false;
            emit RemovedRestrictedCountry(msg.sender, _countries[i]);
        }
    }

    /**
     *  @dev function used to get the country of a wallet address.
     *  @param _compliance the compliance contract address for which the country verification is required
     *  @param _userAddress the address of the wallet to be checked
     *  Returns the ISO 3166-1 standard country code of the wallet owner
     *  internal function, used only by the contract itself to process checks on investor countries
     */
    function _getCountry(address _compliance, address _userAddress) internal view returns (uint16) {
        return IToken(IModularCompliance(_compliance).getTokenBound()).identityRegistry().investorCountry(_userAddress);
    }

    /**
     *  @dev See {IModule-moduleTransferAction}.
     *  no transfer action required in this module
     */
    function moduleTransferAction(
        address _from,
        address _to,
        uint256 _value
    ) external override onlyComplianceCall {}

    /**
     *  @dev See {IModule-moduleMintAction}.
     *  no mint action required in this module
     */
    function moduleMintAction(
        address _to,
        uint256 _value
    ) external override onlyComplianceCall {}

    /**
     *  @dev See {IModule-moduleBurnAction}.
     *  no burn action required in this module
     */
    function moduleBurnAction(
        address _from,
        uint256 _value
    ) external override onlyComplianceCall {}

    /**
     *  @dev See {IModule-moduleCheck}.
     *  checks if the country of address _to is not restricted for this _compliance
     *  returns TRUE if the country of _to is not restricted for this _compliance
     *  returns FALSE if the country of _to is restricted for this _compliance
     */
    function moduleCheck(
        address _from,
        address _to,
        uint256 _value,
        address _compliance
    ) external view override onlyBoundCompliance(_compliance) returns (bool) {
        uint16 receiverCountry = _getCountry(_compliance, _to);
        if (isCountryRestricted(_compliance, receiverCountry)) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

interface IModule {

    /// events

    /**
     *  this event is emitted when the compliance contract is bound to the module.
     *  the event is emitted by the bindCompliance function
     *  `_compliance` is the address of the compliance contract being bound
     */
    event ComplianceBound(address _compliance);

    /**
     *  this event is emitted when the compliance contract is unbound from the module.
     *  the event is emitted by the unbindCompliance function
     *  `_compliance` is the address of the compliance contract being unbound
     */
    event ComplianceUnbound(address _compliance);

    /// functions

    /**
     *  @dev getter for compliance binding status on module
     *  @param _compliance address of the compliance contract
     */
    function isComplianceBound(address _compliance) external view returns (bool);

    /**
     *  @dev binds the module to a compliance contract
     *  once the module is bound, the compliance contract can interact with the module
     *  this function can be called ONLY by the compliance contract itself (_compliance), through the
     *  addModule function, which calls bindCompliance
     *  the module cannot be already bound to the compliance
     *  @param _compliance address of the compliance contract
     *  Emits a ComplianceBound event
     */
    function bindCompliance(address _compliance) external;

    /**
     *  @dev unbinds the module from a compliance contract
     *  once the module is unbound, the compliance contract cannot interact with the module anymore
     *  this function can be called ONLY by the compliance contract itself (_compliance), through the
     *  removeModule function, which calls unbindCompliance
     *  @param _compliance address of the compliance contract
     *  Emits a ComplianceUnbound event
     */
    function unbindCompliance(address _compliance) external;

    /**
     *  @dev action performed on the module during a transfer action
     *  this function is used to update variables of the module upon transfer if it is required
     *  if the module is static this function remains empty
     *  This function can be called ONLY by the compliance contract itself (_compliance)
     *  This function can be called only on a compliance contract that is bound to the module
     *  @param _from address of the transfer sender
     *  @param _to address of the transfer receiver
     *  @param _value amount of tokens sent
     */
    function moduleTransferAction(address _from, address _to, uint256 _value) external;

    /**
     *  @dev action performed on the module during a mint action
     *  this function is used to update variables of the module upon minting if it is required
     *  if the module is static this function remains empty
     *  This function can be called ONLY by the compliance contract itself (_compliance)
     *  This function can be called only on a compliance contract that is bound to the module
     *  @param _to address used for minting
     *  @param _value amount of tokens minted
     */
    function moduleMintAction(address _to, uint256 _value) external;

    /**
     *  @dev action performed on the module during a burn action
     *  this function is used to update variables of the module upon burning if it is required
     *  if the module is static this function remains empty
     *  This function can be called ONLY by the compliance contract itself (_compliance)
     *  This function can be called only on a compliance contract that is bound to the module
     *  @param _from address on which tokens are burnt
     *  @param _value amount of tokens burnt
     */
    function moduleBurnAction(address _from, uint256 _value) external;

    /**
     *  @dev compliance check on the module for a specific transaction on a specific compliance contract
     *  this function is used to check if the transfer is allowed by the module
     *  This function can be called only on a compliance contract that is bound to the module
     *  @param _from address of the transfer sender
     *  @param _to address of the transfer receiver
     *  @param _value amount of tokens sent
     *  @param _compliance address of the compliance contract concerned by the transfer action
     *  the function returns TRUE if the module allows the transfer, FALSE otherwise
     */
    function moduleCheck(address _from, address _to, uint256 _value, address _compliance) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;
import '../roles/AgentRole.sol';
import '../token/IToken.sol';


contract DVDTransferManager is Ownable {

    /**
     * @dev Emitted when a DVD transfer is initiated by `maker` to swap `token1Amount` tokens `token1` (TREX or not)
     * for `token2Amount` tokens `token2` with `taker`
     * this event is emitted by the `initiateDVDTransfer` function
     */
    event DVDTransferInitiated(bytes32 indexed transferID, address maker, address indexed token1, uint256 token1Amount, address taker, address indexed token2, uint256 token2Amount);

    /**
     * @dev Emitted when a DVD transfer is validated by `taker` and executed either by `taker` either by the agent of the TREX token
     * if the TREX token is subject to conditional transfers
     * this event is emitted by the `takeDVDTransfer` function
     */
    event DVDTransferExecuted(bytes32 indexed transferID);

    /**
     * @dev Emitted when a DVD transfer is cancelled
     * this event is emitted by the `cancelDVDTransfer` function
     */
    event DVDTransferCancelled(bytes32 indexed transferID);

    /**
     * @dev Emitted when a DVD transfer is cancelled
     * this event is emitted by the `cancelDVDTransfer` function
     */
    event FeeModified(bytes32 indexed parity, address token1, address token2, uint fee1, uint fee2, uint feeBase, address fee1Wallet, address fee2Wallet);

    struct Delivery {
        address counterpart;
        address token;
        uint256 amount;
    }

    struct Fee {
        uint token1Fee;
        uint token2Fee;
        uint feeBase;
        address fee1Wallet;
        address fee2Wallet;
    }

    struct TxFees {
        uint txFee1;
        uint txFee2;
        address fee1Wallet;
        address fee2Wallet;
    }

    // fee details linked to a parity of tokens
    mapping(bytes32 => Fee) public fee;

    // tokens to deliver by DVD transfer maker
    mapping(bytes32 => Delivery) public token1ToDeliver;

    // tokens to deliver by DVD transfer taker
    mapping(bytes32 => Delivery) public token2ToDeliver;

    // nonce of the transaction allowing the creation of unique transferID
    uint256 public txNonce;

    // initiates the nonce at 0
    constructor(){
        txNonce = 0;
    }


    /**
     *  @dev calculates the parity byte signature
     *  @param _token1 the address of the base token
     *  @param _token2 the address of the counterpart token
     *  return the byte signature of the parity
     */
    function calculateParity (address _token1, address _token2) public pure returns (bytes32) {
        bytes32 parity = keccak256(abi.encode(_token1, _token2));
        return parity;
    }

    /**
     *  @dev check if `_token` corresponds to a functional TREX token (with identity registry initiated)
     *  @param _token the address token to check
     *  the function will try to call `identityRegistry()` on the address, which is a getter specific to TREX tokens
     *  if the call pass and returns an address it means that the token is a TREX, otherwise it's not a TREX
     *  return `true` if the token is a TREX, `false` otherwise
     */
    function isTREX(address _token) public view returns (bool) {
        try IToken(_token).identityRegistry() returns (IIdentityRegistry _ir) {
            if (address(_ir) != address(0)) {
                return true;
            }
        return false;
        }
        catch {
            return false;
        }
    }

    /**
     *  @dev check if `_user` is a TREX agent of `_token`
     *  @param _token the address token to check
     *  @param _user the wallet address
     *  if `_token` is a TREX token this function will check if `_user` is registered as an agent on it
     *  return `true` if `_user` is agent of `_token`, return `false` otherwise
     */
    function isTREXAgent(address _token, address _user) public view returns (bool) {
    if (isTREX(_token)){
        return AgentRole(_token).isAgent(_user);
    }
        return false;
    }

    /**
     *  @dev check if `_user` is a TREX owner of `_token`
     *  @param _token the address token to check
     *  @param _user the wallet address
     *  if `_token` is a TREX token this function will check if `_user` is registered as an owner on it
     *  return `true` if `_user` is owner of `_token`, return `false` otherwise
     */
    function isTREXOwner(address _token, address _user) public view returns (bool) {
        if (isTREX(_token)){
            return Ownable(_token).owner() == _user;
        }
        return false;
    }

    /**
     *  @dev calculates the transferID depending on DVD transfer parameters
     *  @param _nonce the nonce of the transfer on the smart contract
     *  @param _maker the address of the DVD transfer maker (initiator of the transfer)
     *  @param _token1 the address of the token that the maker is providing
     *  @param _token1Amount the amount of tokens `_token1` provided by the maker
     *  @param _taker the address of the DVD transfer taker (executor of the transfer)
     *  @param _token2 the address of the token that the taker is providing
     *  @param _token2Amount the amount of tokens `_token2` provided by the taker
     *  return the identifier of the DVD transfer as a byte signature
     */
    function calculateTransferID (
        uint256 _nonce,
        address _maker,
        address _token1,
        uint256 _token1Amount,
        address _taker,
        address _token2,
        uint256 _token2Amount
    ) public pure returns (bytes32){
        bytes32 transferID = keccak256(abi.encode(_nonce, _maker, _token1, _token1Amount, _taker, _token2, _token2Amount));
        return transferID;
    }

    /**
     *  @dev modify the fees applied to a parity of tokens (tokens can be TREX or ERC20)
     *  @param _token1 the address of the base token for the parity `_token1`/`_token2`
     *  @param _token2 the address of the counterpart token for the parity `_token1`/`_token2`
     *  @param _fee1 the fee to apply on `_token1` leg of the DVD transfer per 10^`_feeBase`
     *  @param _fee2 the fee to apply on `_token2` leg of the DVD transfer per 10^`_feeBase`
     *  @param _feeBase the precision of the fee setting, e.g. if `_feeBase` == 2 then `_fee1` and `_fee2` are in % (fee/10^`_feeBase`)
     *  @param _fee1Wallet the wallet address receiving fees applied on `_token1`
     *  @param _fee2Wallet the wallet address receiving fees applied on `_token2`
     *  `_token1` and `_token2` need to be ERC20 or TREX tokens addresses, otherwise the transaction will fail
     *  `msg.sender` has to be owner of the DVD contract or the owner of the TREX token involved in the parity (if any)
     *  requires fees to be lower than 100%
     *  requires `_feeBase` to be higher or equal to 2 (precision 10^2)
     *  requires `_feeBase` to be lower or equal to 5 (precision 10^5) to avoid overflows
     *  requires `_fee1Wallet` & `_fee2Wallet` to be non empty addresses if `_fee1` & `_fee2` are respectively set
     *  note that if fees are not set for a parity the default fee is basically 0%
     *  emits a `FeeModified` event
     */
    function modifyFee(address _token1, address _token2, uint _fee1, uint _fee2, uint _feeBase, address _fee1Wallet, address _fee2Wallet) external {
        require(msg.sender == owner() || isTREXOwner(_token1, msg.sender) || isTREXOwner(_token2, msg.sender), 'Ownable: only owner can call');
        require(IERC20(_token1).totalSupply() != 0 && IERC20(_token2).totalSupply() != 0, 'invalid address : address is not an ERC20');
        require(_fee1 <= 10**_feeBase && _fee1 >= 0 && _fee2 <= 10**_feeBase && _fee2 >= 0 && _feeBase <= 5 && _feeBase >= 2, 'invalid fee settings');
        if (_fee1 > 0) {
            require(_fee1Wallet != address(0), 'fee wallet 1 cannot be zero address');
        }
        if (_fee2 > 0) {
            require(_fee2Wallet != address(0), 'fee wallet 2 cannot be zero address');
        }
        bytes32 _parity = calculateParity(_token1, _token2);
        Fee memory parityFee;
        parityFee.token1Fee = _fee1;
        parityFee.token2Fee = _fee2;
        parityFee.feeBase = _feeBase;
        parityFee.fee1Wallet = _fee1Wallet;
        parityFee.fee2Wallet = _fee2Wallet;
        fee[_parity] = parityFee;
        emit FeeModified(_parity, _token1, _token2, _fee1, _fee2, _feeBase, _fee1Wallet, _fee2Wallet);
        bytes32 _reflectParity = calculateParity(_token2, _token1);
        Fee memory reflectParityFee;
        reflectParityFee.token1Fee = _fee2;
        reflectParityFee.token2Fee = _fee1;
        reflectParityFee.feeBase = _feeBase;
        reflectParityFee.fee1Wallet = _fee2Wallet;
        reflectParityFee.fee2Wallet = _fee1Wallet;
        fee[_reflectParity] = reflectParityFee;
        emit FeeModified(_reflectParity, _token2, _token1, _fee2, _fee1, _feeBase, _fee2Wallet, _fee1Wallet);
    }

    /**
     *  @dev initiates a DVD transfer between `msg.sender` & `_counterpart`
     *  @param _token1 the address of the token (ERC20 or TREX) provided by `msg.sender`
     *  @param _token1Amount the amount of `_token1` that `msg.sender` will send to `_counterpart` at DVD execution time
     *  @param _counterpart the address of the counterpart, which will receive `_token1Amount` of `_token1` in exchange for
     *  `_token2Amount` of `_token2`
     *  @param _token2 the address of the token (ERC20 or TREX) provided by `_counterpart`
     *  @param _token2Amount the amount of `_token2` that `_counterpart` will send to `msg.sender` at DVD execution time
     *  requires `msg.sender` to have enough `_token1` tokens to process the DVD transfer
     *  requires `DVDTransferManager` contract to have the necessary allowance to process the DVD transfer on `msg.sender`
     *  requires `_counterpart` to not be the 0 address
     *  requires `_token1` & `_token2` to be valid token addresses
     *  emits a `DVDTransferInitiated` event
     */
    function initiateDVDTransfer(address _token1, uint256 _token1Amount, address _counterpart, address _token2, uint256 _token2Amount) external {
        require(IERC20(_token1).balanceOf(msg.sender) >= _token1Amount, 'Not enough tokens in balance');
        require(IERC20(_token1).allowance(msg.sender, address(this)) >= _token1Amount, 'not enough allowance to initiate transfer');
        require (_counterpart != address(0), 'counterpart cannot be null');
        require(IERC20(_token2).totalSupply() != 0, 'invalid address : address is not an ERC20');
        Delivery memory token1;
        token1.counterpart = msg.sender;
        token1.token = _token1;
        token1.amount = _token1Amount;
        Delivery memory token2;
        token2.counterpart = _counterpart;
        token2.token = _token2;
        token2.amount = _token2Amount;
        bytes32 transferID = calculateTransferID(txNonce, token1.counterpart, token1.token, token1.amount, token2.counterpart, token2.token, token2.amount);
        token1ToDeliver[transferID] = token1;
        token2ToDeliver[transferID] = token2;
        emit DVDTransferInitiated(transferID,token1.counterpart, token1.token, token1.amount, token2.counterpart, token2.token, token2.amount);
        txNonce++;
    }

    /**
     *  @dev execute a DVD transfer that was previously initiated through the `initiateDVDTransfer` function
     *  @param _transferID the DVD transfer identifier as calculated through the `calculateTransferID` function for the initiated DVD transfer to execute
     *  requires `_transferID` to exist (DVD transfer has to be initiated)
     *  requires that taker (counterpart sending token2) has enough tokens in balance to process the DVD transfer
     *  requires that `DVDTransferManager` contract has enough allowance to process the `token2` leg of the DVD transfer
     *  requires that `msg.sender` is the taker OR the TREX agent in case a TREX token is involved in the transfer (in case of conditional transfer
     *  the agent can call the function when the transfer has been approved)
     *  if fees apply on one side or both sides of the transfer the fees will be sent, at transaction time, to the fees wallet previously set
     *  in case fees apply the counterparts will receive less than the amounts included in the DVD transfer as part of the transfer is redirected to the
     *  fee wallet at transfer execution time
     *  if one or both legs of the transfer are TREX, then all the relevant checks apply on the transaction (compliance + identity checks)
     *  and the transaction WILL FAIL if the TREX conditions of transfer are not respected, please refer to {Token-transfer} and {Token-transferFrom} to
     *  know more about TREX conditions for transfers
     *  once the DVD transfer is executed the `_transferID` is removed from the pending `_transferID` pool
     *  emits a `DVDTransferExecuted` event
     */
    function takeDVDTransfer(bytes32 _transferID) external {
        Delivery memory token1 = token1ToDeliver[_transferID];
        Delivery memory token2 = token2ToDeliver[_transferID];
        require(token1.counterpart != address(0) && token2.counterpart != address(0), 'transfer ID does not exist');
        IERC20 token1Contract = IERC20(token1.token);
        IERC20 token2Contract = IERC20(token2.token);
        require (msg.sender == token2.counterpart || isTREXAgent(token1.token, msg.sender) || isTREXAgent(token2.token, msg.sender), 'transfer has to be done by the counterpart or by owner');
        require(token2Contract.balanceOf(token2.counterpart) >= token2.amount, 'Not enough tokens in balance');
        require(token2Contract.allowance(token2.counterpart, address(this)) >= token2.amount, 'not enough allowance to transfer');
        TxFees memory fees = calculateFee(_transferID);
        if (fees.txFee1 != 0) {
        token1Contract.transferFrom(token1.counterpart, token2.counterpart, (token1.amount - fees.txFee1));
        token1Contract.transferFrom(token1.counterpart, fees.fee1Wallet, fees.txFee1);
        }
        if (fees.txFee1 == 0) {
            token1Contract.transferFrom(token1.counterpart, token2.counterpart, token1.amount);
        }
        if (fees.txFee2 != 0) {
            token2Contract.transferFrom(token2.counterpart, token1.counterpart, (token2.amount - fees.txFee2));
            token2Contract.transferFrom(token2.counterpart, fees.fee2Wallet, fees.txFee2);
        }
        if (fees.txFee2 == 0) {
            token2Contract.transferFrom(token2.counterpart, token1.counterpart, token2.amount);
        }
        delete token1ToDeliver[_transferID];
        delete token2ToDeliver[_transferID];
        emit DVDTransferExecuted(_transferID);
    }

    /**
     *  @dev delete a pending DVD transfer that was previously initiated through the `initiateDVDTransfer` function from the pool
     *  @param _transferID the DVD transfer identifier as calculated through the `calculateTransferID` function for the initiated DVD transfer to delete
     *  requires `_transferID` to exist (DVD transfer has to be initiated)
     *  requires that `msg.sender` is the taker or the maker or the `DVDTransferManager` contract owner or the TREX agent in case a TREX token is involved in the transfer
     *  once the `cancelDVDTransfer` is executed the `_transferID` is removed from the pending `_transferID` pool
     *  emits a `DVDTransferCancelled` event
     */
    function cancelDVDTransfer(bytes32 _transferID) external {
        Delivery memory token1 = token1ToDeliver[_transferID];
        Delivery memory token2 = token2ToDeliver[_transferID];
        require(token1.counterpart != address(0) && token2.counterpart != address(0), 'transfer ID does not exist');
        require (msg.sender == token2.counterpart || msg.sender == token1.counterpart || msg.sender == owner() || isTREXAgent(token1.token, msg.sender) || isTREXAgent(token2.token, msg.sender), 'you are not allowed to cancel this transfer');
        delete token1ToDeliver[_transferID];
        delete token2ToDeliver[_transferID];
        emit DVDTransferCancelled(_transferID);
    }

    /**
     *  @dev calculates the fees to apply to a specific transfer depending on the fees applied to the parity used in the transfer
     *  @param _transferID the DVD transfer identifier as calculated through the `calculateTransferID` function for the transfer to calculate fees on
     *  requires `_transferID` to exist (DVD transfer has to be initiated)
     *  returns the fees to apply on each leg of the transfer in the form of a `TxFees` struct
     */
    function calculateFee(bytes32 _transferID) public view returns(TxFees memory) {
        TxFees memory fees;
        Delivery memory token1 = token1ToDeliver[_transferID];
        Delivery memory token2 = token2ToDeliver[_transferID];
        require(token1.counterpart != address(0) && token2.counterpart != address(0), 'transfer ID does not exist');
        bytes32 parity = calculateParity(token1.token, token2.token);
        Fee memory feeDetails = fee[parity];
        if (feeDetails.token1Fee != 0 || feeDetails.token2Fee != 0 ){
            uint _txFee1 = (token1.amount * feeDetails.token1Fee * 10**(feeDetails.feeBase - 2)) / (10**feeDetails.feeBase);
            uint _txFee2 = (token2.amount * feeDetails.token2Fee * 10**(feeDetails.feeBase - 2)) / (10**feeDetails.feeBase);
            fees.txFee1 = _txFee1;
            fees.txFee2 = _txFee2;
            fees.fee1Wallet = feeDetails.fee1Wallet;
            fees.fee2Wallet = feeDetails.fee2Wallet;
            return fees;
        }
        else {
            fees.txFee1 = 0;
            fees.txFee2 = 0;
            fees.fee1Wallet = address(0);
            fees.fee2Wallet = address(0);
            return fees;
        }
    }

}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TestERC20 is Ownable, ERC20Pausable {

    constructor(string memory name, string memory symbol, uint256 amount) ERC20(name, symbol) {
        _mint(msg.sender, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
pragma solidity ^0.8.0;

interface ITREXFactory {

    /// event emitted whenever a single contract is deployed by the factory
    event Deployed(address _addr);

    /// event emitted when the implementation authority of the factory contract is set
    event ImplementationAuthoritySet(address _implementationAuthority);

    /// event emitted by the factory when a full suite of T-REX contracts is deployed
    event TREXSuiteDeployed(address _token, address _ir, address _irs, address _tir, address _ctr, string _salt);

    struct TokenDetails {
        // address of the owner of all contracts
        address owner;
        // name of the token
        string name;
        // symbol / ticker of the token
        string symbol;
        // decimals of the token (can be between 0 and 18)
        uint8 decimals;
        // identity registry storage address
        // set it to ZERO address if you want to deploy a new storage
        // if an address is provided, please ensure that the factory is set as owner of the contract
        address irs;
        // ONCHAINID of the token
        address ONCHAINID;
        // list of agents of the identity registry (can be set to an AgentManager contract)
        address[] irAgents;
        // list of agents of the token
        address[] tokenAgents;
        // modules to bind to the compliance, indexes are corresponding to the settings callData indexes
        // if a module doesn't require settings, it can be added at the end of the array, at index > settings.length
        address[] complianceModules;
        // settings calls for compliance modules
        bytes[] complianceSettings;
    }

    struct ClaimDetails {
        // claim topics required
        uint256[] claimTopics;
        // trusted issuers addresses
        address[] issuers;
        // claims that issuers are allowed to emit, by index, index corresponds to the `issuers` indexes
        uint256[][] issuerClaims;
    }

    /**
     *  @dev getter for token address corresponding to salt string
     *  @param _salt The salt string that was used to deploy the token
     */
    function getToken(string calldata _salt) external view returns(address);

    /**
     *  @dev setter for implementation authority contract address
     *  the implementation authority contract contains the addresses of all implementation contracts
     *  the proxies created by the factory will use the different implementations available
     *  in the implementation authority contract
     *  Only owner can call.
     *  emits `ImplementationAuthoritySet` event
     *  @param _implementationAuthority The address of the implementation authority smart contract
     */
    function setImplementationAuthority(address _implementationAuthority) external;

    /**
     *  @dev function used to deploy a new TREX token and set all the parameters as required by the issuer paperwork
     *  this function will deploy and set the contracts as follow :
     *  Token : deploy the token contract (proxy) and set the name, symbol, ONCHAINID, decimals, owner, agents,
     *  IR address , Compliance address
     *  Identity Registry : deploy the IR contract (proxy) and set the owner, agents,
     *  IRS address, TIR address, CTR address
     *  IRS : deploy IRS contract (proxy) if required (address set as 0 in the TokenDetails, bind IRS to IR, set owner
     *  CTR : deploy CTR contract (proxy), set required claims, set owner
     *  TIR : deploy TIR contract (proxy), set trusted issuers, set owner
     *  Compliance: deploy modular compliance, bind with token, add modules, set modules parameters, set owner
     *  All contracts are deployed using CREATE2 opcode, and therefore are deployed at a predetermined address
     *  The address can be the same on all EVM blockchains as long as the factory address is the same as well
     *  Only owner can call.
     *  emits `TREXSuiteDeployed` event
     *  @param _salt the salt used to make the contracts deployments with CREATE2
     *  @param _tokenDetails The details of the token to deploy (see struct TokenDetails for more details)
     *  @param _claimDetails The details of the claims and claim issuers (see struct ClaimDetails for more details)
     */
    function deployTREXSuite(string memory _salt, TokenDetails calldata _tokenDetails, ClaimDetails calldata _claimDetails) external;

    /**
     *  @dev function that can be used to recover the ownership of contracts owned by the factory
     *  typically used for IRS contracts owned by the factory (ownership of IRS is mandatory to call bind function)
     *  @param _contract The smart contract address
     *  @param _newOwner The address to transfer ownership to
     *  Only owner can call.
     */
    function recoverContractOwnership(address _contract, address _newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
pragma solidity ^0.8.0;

import '../roles/AgentRole.sol';
import '../token/IToken.sol';
import '../registry/interface/IClaimTopicsRegistry.sol';
import '../registry/interface/IIdentityRegistry.sol';
import '../compliance/modular/IModularCompliance.sol';
import '../registry/interface/ITrustedIssuersRegistry.sol';
import '../registry/interface/IIdentityRegistryStorage.sol';
import '../proxy/authority/ITREXImplementationAuthority.sol';
import '../proxy/TokenProxy.sol';
import '../proxy/ClaimTopicsRegistryProxy.sol';
import '../proxy/IdentityRegistryProxy.sol';
import '../proxy/IdentityRegistryStorageProxy.sol';
import '../proxy/TrustedIssuersRegistryProxy.sol';
import '../proxy/ModularComplianceProxy.sol';
import './ITREXFactory.sol';


contract TREXFactory is ITREXFactory, Ownable {

    /// the address of the implementation authority contract used in the tokens deployed by the factory
    address public implementationAuthority;

    /// mapping containing info about the token contracts corresponding to salt already used for CREATE2 deployments
    mapping(string => address) public tokenDeployed;

    /// constructor is setting the implementation authority of the factory
    constructor(address _implementationAuthority) {
        setImplementationAuthority(_implementationAuthority);
    }

    /**
     *  @dev See {ITREXFactory-getToken}.
     */
    function getToken(string calldata _salt) external override view returns(address) {
        return tokenDeployed[_salt];
    }

    /**
     *  @dev See {ITREXFactory-setImplementationAuthority}.
     */
    function setImplementationAuthority(address _implementationAuthority) public override onlyOwner {
        // should not be possible to set an implementation authority that is not complete
        require(
            (ITREXImplementationAuthority(_implementationAuthority)).getTokenImplementation() != address(0)
            && (ITREXImplementationAuthority(_implementationAuthority)).getCTRImplementation() != address(0)
            && (ITREXImplementationAuthority(_implementationAuthority)).getIRImplementation() != address(0)
            && (ITREXImplementationAuthority(_implementationAuthority)).getIRSImplementation() != address(0)
            && (ITREXImplementationAuthority(_implementationAuthority)).getMCImplementation() != address(0)
            && (ITREXImplementationAuthority(_implementationAuthority)).getTIRImplementation() != address(0),
            'invalid Implementation Authority');
        implementationAuthority = _implementationAuthority;
        emit ImplementationAuthoritySet(_implementationAuthority);
    }

    /// deploy function with create2 opcode call
    /// returns the address of the contract created
    function deploy(string memory salt, bytes memory bytecode) internal returns (address) {
        bytes memory implInitCode = bytecode;
        address addr;
        assembly {
            let encoded_data := add(0x20, implInitCode) // load initialization code.
            let encoded_size := mload(implInitCode)     // load init code's length.
            addr := create2(0, encoded_data, encoded_size, salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr);
        return addr;
    }

    /**
     *  @dev See {ITREXFactory-deployTREXSuite}.
     */
    function deployTREXSuite(string memory _salt, TokenDetails calldata _tokenDetails, ClaimDetails calldata
        _claimDetails)
    external override onlyOwner {
        require(tokenDeployed[_salt] == address(0), 'token already deployed');
        require((_claimDetails.issuers).length == (_claimDetails.issuerClaims).length, 'claim pattern not valid');
        ITrustedIssuersRegistry tir = ITrustedIssuersRegistry(deployTIR(_salt, implementationAuthority));
        IClaimTopicsRegistry ctr = IClaimTopicsRegistry(deployCTR(_salt, implementationAuthority));
        IModularCompliance mc = IModularCompliance(deployMC(_salt, implementationAuthority));
        IIdentityRegistryStorage irs;
        if (_tokenDetails.irs == address(0)) {
            irs = IIdentityRegistryStorage(deployIRS(_salt, implementationAuthority));
        }
        else {
            irs = IIdentityRegistryStorage(_tokenDetails.irs);
        }
        IIdentityRegistry ir = IIdentityRegistry(deployIR(_salt, implementationAuthority, address(tir), address (ctr), address (irs)));
        IToken token = IToken(deployToken
        (
            _salt,
            implementationAuthority,
            address(ir),
            address(mc),
            _tokenDetails.name,
            _tokenDetails.symbol,
            _tokenDetails.decimals,
            _tokenDetails.ONCHAINID
        ));
        for (uint256 i = 0; i < (_claimDetails.claimTopics).length; i++) {
            ctr.addClaimTopic(_claimDetails.claimTopics[i]);
        }
        for (uint256 i = 0; i < (_claimDetails.issuers).length; i++) {
            tir.addTrustedIssuer(IClaimIssuer((_claimDetails).issuers[i]), _claimDetails.issuerClaims[i]);
        }
        irs.bindIdentityRegistry(address(ir));
        AgentRole(address(ir)).addAgent(address(token));
        for (uint256 i = 0; i < (_tokenDetails.irAgents).length; i++) {
            AgentRole(address(ir)).addAgent(_tokenDetails.irAgents[i]);
        }
        for (uint256 i = 0; i < (_tokenDetails.tokenAgents).length; i++) {
            AgentRole(address(token)).addAgent(_tokenDetails.tokenAgents[i]);
        }
        for (uint256 i = 0; i < (_tokenDetails.complianceModules).length; i++) {
            if (!mc.isModuleBound(_tokenDetails.complianceModules[i])) {
                mc.addModule(_tokenDetails.complianceModules[i]);
            }
            if (i < (_tokenDetails.complianceSettings).length) {
                mc.callModuleFunction(_tokenDetails.complianceSettings[i], _tokenDetails.complianceModules[i]);
            }
        }
        tokenDeployed[_salt] = address(token);
        (Ownable(address(token))).transferOwnership(_tokenDetails.owner);
        (Ownable(address(ir))).transferOwnership(_tokenDetails.owner);
        (Ownable(address(tir))).transferOwnership(_tokenDetails.owner);
        (Ownable(address(ctr))).transferOwnership(_tokenDetails.owner);
        (Ownable(address(mc))).transferOwnership(_tokenDetails.owner);
        emit TREXSuiteDeployed(address(token), address(ir), address(irs), address(tir), address(ctr), _salt);
    }

    /// function used to deploy a trusted issuers registry using CREATE2
    function deployTIR
    (
        string memory _salt,
        address _implementationAuthority
    ) internal returns (address){
        bytes memory _code = type(TrustedIssuersRegistryProxy).creationCode;
        bytes memory _constructData = abi.encode(_implementationAuthority);
        bytes memory bytecode = abi.encodePacked(_code, _constructData);
        return deploy(_salt, bytecode);
    }

    /// function used to deploy a claim topics registry using CREATE2
    function  deployCTR
    (
        string memory _salt,
        address _implementationAuthority
    ) internal returns (address) {
        bytes memory _code = type(ClaimTopicsRegistryProxy).creationCode;
        bytes memory _constructData = abi.encode(_implementationAuthority);
        bytes memory bytecode = abi.encodePacked(_code, _constructData);
        return deploy(_salt, bytecode);
    }

    /// function used to deploy modular compliance contract using CREATE2
    function  deployMC
    (
        string memory _salt,
        address _implementationAuthority
    ) internal returns (address) {
        bytes memory _code = type(ModularComplianceProxy).creationCode;
        bytes memory _constructData = abi.encode(_implementationAuthority);
        bytes memory bytecode = abi.encodePacked(_code, _constructData);
        return deploy(_salt, bytecode);
    }

    /// function used to deploy an identity registry storage using CREATE2
    function deployIRS
    (
        string memory _salt,
        address _implementationAuthority
    ) internal returns (address) {
        bytes memory _code = type(IdentityRegistryStorageProxy).creationCode;
        bytes memory _constructData = abi.encode(_implementationAuthority);
        bytes memory bytecode = abi.encodePacked(_code, _constructData);
        return deploy(_salt, bytecode);
    }

    /// function used to deploy an identity registry using CREATE2
    function deployIR
    (
        string memory _salt,
        address _implementationAuthority,
        address _trustedIssuersRegistry,
        address _claimTopicsRegistry,
        address _identityStorage
    ) internal returns (address) {
        bytes memory _code = type(IdentityRegistryProxy).creationCode;
        bytes memory _constructData = abi.encode
        (
            _implementationAuthority,
            _trustedIssuersRegistry,
            _claimTopicsRegistry,
            _identityStorage
        );
        bytes memory bytecode = abi.encodePacked(_code, _constructData);
        return deploy(_salt, bytecode);
    }

    /// function used to deploy a token using CREATE2
    function deployToken
    (
        string memory _salt,
        address _implementationAuthority,
        address _identityRegistry,
        address _compliance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _ONCHAINID
    ) internal returns (address) {
        bytes memory _code = type(TokenProxy).creationCode;
        bytes memory _constructData = abi.encode
        (
            _implementationAuthority,
            _identityRegistry,
            _compliance,
            _name,
            _symbol,
            _decimals,
            _ONCHAINID
        );
        bytes memory bytecode = abi.encodePacked(_code, _constructData);
        return deploy(_salt, bytecode);
    }

    /**
     *  @dev See {ITREXFactory-recoverContractOwnership}.
     */
    function recoverContractOwnership(address _contract, address _newOwner) external override onlyOwner {
        (Ownable(_contract)).transferOwnership(_newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// imports here are just for testing purpose

import '@onchain-id/solidity/contracts/ClaimIssuer.sol';
import '@onchain-id/solidity/contracts/Identity.sol';
import '@onchain-id/solidity/contracts/proxy/ImplementationAuthority.sol';

contract Migrations {
    address public owner;
    uint256 public lastCompletedMigration;

    constructor() {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function setCompleted(uint256 completed) external restricted {
        lastCompletedMigration = completed;
    }

    function upgrade(address new_address) external restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(lastCompletedMigration);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

interface ITREXImplementationAuthority {
    function getTokenImplementation() external view returns (address);

    function setTokenImplementation(address _tokenImplementation) external;

    function getCTRImplementation() external view returns (address);

    function setCTRImplementation(address _ctrImplementation) external;

    function getIRImplementation() external view returns (address);

    function setIRImplementation(address _irImplementation) external;

    function getIRSImplementation() external view returns (address);

    function setIRSImplementation(address _irsImplementation) external;

    function getTIRImplementation() external view returns (address);

    function setTIRImplementation(address _tirImplementation) external;

    function getMCImplementation() external view returns (address);

    function setMCImplementation(address _mcImplementation) external;
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './ITREXImplementationAuthority.sol';

contract TREXImplementationAuthority is ITREXImplementationAuthority, Ownable {
    event UpdatedTokenImplementation(address tokenImplem);
    event UpdatedCTRImplementation(address ctrImplem);
    event UpdatedIRImplementation(address irImplem);
    event UpdatedIRSImplementation(address irsImplem);
    event UpdatedTIRImplementation(address tirImplem);
    event UpdatedMCImplementation(address mcImplem);
    address private tokenImplementation;
    address private ctrImplementation;
    address private irImplementation;
    address private irsImplementation;
    address private tirImplementation;
    address private mcImplementation;

    function getTokenImplementation() public view override returns (address) {
        return tokenImplementation;
    }

    function setTokenImplementation(address _tokenImplementation) public override onlyOwner {
        tokenImplementation = _tokenImplementation;
        emit UpdatedTokenImplementation(_tokenImplementation);
    }

    function getCTRImplementation() public view override returns (address) {
        return ctrImplementation;
    }

    function setCTRImplementation(address _ctrImplementation) public override onlyOwner {
        ctrImplementation = _ctrImplementation;
        emit UpdatedCTRImplementation(_ctrImplementation);
    }

    function getIRImplementation() public view override returns (address) {
        return irImplementation;
    }

    function setIRImplementation(address _irImplementation) public override onlyOwner {
        irImplementation = _irImplementation;
        emit UpdatedIRImplementation(_irImplementation);
    }

    function getIRSImplementation() public view override returns (address) {
        return irsImplementation;
    }

    function setIRSImplementation(address _irsImplementation) public override onlyOwner {
        irsImplementation = _irsImplementation;
        emit UpdatedIRSImplementation(_irsImplementation);
    }

    function getTIRImplementation() public view override returns (address) {
        return tirImplementation;
    }

    function setTIRImplementation(address _tirImplementation) public override onlyOwner {
        tirImplementation = _tirImplementation;
        emit UpdatedTIRImplementation(_tirImplementation);
    }

    function getMCImplementation() public view override returns (address) {
        return mcImplementation;
    }

    function setMCImplementation(address _mcImplementation) public override onlyOwner {
        mcImplementation = _mcImplementation;
        emit UpdatedMCImplementation(_mcImplementation);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import './authority/ITREXImplementationAuthority.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract ClaimTopicsRegistryProxy is Initializable {
    address public implementationAuthority;

    constructor(address _implementationAuthority) {
        implementationAuthority = _implementationAuthority;

        address logic = (ITREXImplementationAuthority(implementationAuthority)).getCTRImplementation();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = logic.delegatecall(abi.encodeWithSignature('init()'));
        require(success, 'Initialization failed.');
    }

    fallback() external payable {
        address logic = (ITREXImplementationAuthority(implementationAuthority)).getCTRImplementation();

        assembly {
        // solium-disable-line
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), logic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import './authority/ITREXImplementationAuthority.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract IdentityRegistryProxy is Initializable {
    address public implementationAuthority;

    constructor(
        address _implementationAuthority,
        address _trustedIssuersRegistry,
        address _claimTopicsRegistry,
        address _identityStorage
    ) {
        implementationAuthority = _implementationAuthority;

        address logic = (ITREXImplementationAuthority(implementationAuthority)).getIRImplementation();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) =
        logic.delegatecall(
            abi.encodeWithSignature('init(address,address,address)', _trustedIssuersRegistry, _claimTopicsRegistry, _identityStorage)
        );
        require(success, 'Initialization failed.');
    }

    fallback() external payable {
        address logic = (ITREXImplementationAuthority(implementationAuthority)).getIRImplementation();

        assembly {
        // solium-disable-line
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), logic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import './authority/ITREXImplementationAuthority.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract IdentityRegistryStorageProxy is Initializable {
    address public implementationAuthority;

    constructor(address _implementationAuthority) {
        implementationAuthority = _implementationAuthority;

        address logic = (ITREXImplementationAuthority(implementationAuthority)).getIRSImplementation();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = logic.delegatecall(abi.encodeWithSignature('init()'));
        require(success, 'Initialization failed.');
    }

    fallback() external payable {
        address logic = (ITREXImplementationAuthority(implementationAuthority)).getIRSImplementation();

        assembly {
        // solium-disable-line
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), logic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import './authority/ITREXImplementationAuthority.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract ModularComplianceProxy is Initializable {
    address public implementationAuthority;

    constructor(address _implementationAuthority) {
        implementationAuthority = _implementationAuthority;

        address logic = (ITREXImplementationAuthority(implementationAuthority)).getMCImplementation();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = logic.delegatecall(abi.encodeWithSignature('init()'));
        require(success, 'Initialization failed.');
    }

    fallback() external payable {
        address logic = (ITREXImplementationAuthority(implementationAuthority)).getMCImplementation();

        assembly {
        // solium-disable-line
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), logic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import './authority/ITREXImplementationAuthority.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract TokenProxy is Initializable {
    address public implementationAuthority;

    constructor(
        address _implementationAuthority,
        address _identityRegistry,
        address _compliance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _onchainID
    ) {
        implementationAuthority = _implementationAuthority;

        address logic = (ITREXImplementationAuthority(implementationAuthority)).getTokenImplementation();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) =
            logic.delegatecall(
                abi.encodeWithSignature(
                    'init(address,address,string,string,uint8,address)',
                    _identityRegistry,
                    _compliance,
                    _name,
                    _symbol,
                    _decimals,
                    _onchainID
                )
            );
        require(success, 'Initialization failed.');
    }

    fallback() external payable {
        address logic = (ITREXImplementationAuthority(implementationAuthority)).getTokenImplementation();

        assembly {
            // solium-disable-line
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), logic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import './authority/ITREXImplementationAuthority.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract TrustedIssuersRegistryProxy is Initializable {

    address public implementationAuthority;

    constructor(address _implementationAuthority) {
        implementationAuthority = _implementationAuthority;

        address logic = (ITREXImplementationAuthority(implementationAuthority)).getTIRImplementation();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = logic.delegatecall(abi.encodeWithSignature('init()'));
        require(success, 'Initialization failed.');
    }

    fallback() external payable {
        address logic = (ITREXImplementationAuthority(implementationAuthority)).getTIRImplementation();

        assembly {
        // solium-disable-line
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), logic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '../storage/CTRStorage.sol';
import '../interface/IClaimTopicsRegistry.sol';

contract ClaimTopicsRegistry is IClaimTopicsRegistry, OwnableUpgradeable, CTRStorage {

    function init() public initializer {
        __Ownable_init();
    }

    /**
     *  @dev See {IClaimTopicsRegistry-addClaimTopic}.
     */
    function addClaimTopic(uint256 _claimTopic) external override onlyOwner {
        uint256 length = claimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            require(claimTopics[i] != _claimTopic, 'claimTopic already exists');
        }
        claimTopics.push(_claimTopic);
        emit ClaimTopicAdded(_claimTopic);
    }

    /**
     *  @dev See {IClaimTopicsRegistry-removeClaimTopic}.
     */
    function removeClaimTopic(uint256 _claimTopic) external override onlyOwner {
        uint256 length = claimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            if (claimTopics[i] == _claimTopic) {
                claimTopics[i] = claimTopics[length - 1];
                claimTopics.pop();
                emit ClaimTopicRemoved(_claimTopic);
                break;
            }
        }
    }

    /**
     *  @dev See {IClaimTopicsRegistry-getClaimTopics}.
     */
    function getClaimTopics() external view override returns (uint256[] memory) {
        return claimTopics;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';
import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

import '../interface/IClaimTopicsRegistry.sol';
import '../interface/ITrustedIssuersRegistry.sol';
import '../interface/IIdentityRegistry.sol';
import '../../roles/AgentRoleUpgradeable.sol';
import '../interface/IIdentityRegistryStorage.sol';
import '../storage/IRStorage.sol';


contract IdentityRegistry is IIdentityRegistry, AgentRoleUpgradeable, IRStorage {

    /**
     *  @dev the constructor initiates the Identity Registry smart contract
     *  @param _trustedIssuersRegistry the trusted issuers registry linked to the Identity Registry
     *  @param _claimTopicsRegistry the claim topics registry linked to the Identity Registry
     *  @param _identityStorage the identity registry storage linked to the Identity Registry
     *  emits a `ClaimTopicsRegistrySet` event
     *  emits a `TrustedIssuersRegistrySet` event
     *  emits an `IdentityStorageSet` event
     */
    function init(
        address _trustedIssuersRegistry,
        address _claimTopicsRegistry,
        address _identityStorage
    ) public initializer {
        tokenTopicsRegistry = IClaimTopicsRegistry(_claimTopicsRegistry);
        tokenIssuersRegistry = ITrustedIssuersRegistry(_trustedIssuersRegistry);
        tokenIdentityStorage = IIdentityRegistryStorage(_identityStorage);
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
        emit IdentityStorageSet(_identityStorage);
        __Ownable_init();
    }

    /**
     *  @dev See {IIdentityRegistry-identity}.
     */
    function identity(address _userAddress) public view override returns (IIdentity) {
        return tokenIdentityStorage.storedIdentity(_userAddress);
    }

    /**
     *  @dev See {IIdentityRegistry-investorCountry}.
     */
    function investorCountry(address _userAddress) external view override returns (uint16) {
        return tokenIdentityStorage.storedInvestorCountry(_userAddress);
    }

    /**
     *  @dev See {IIdentityRegistry-issuersRegistry}.
     */
    function issuersRegistry() external view override returns (ITrustedIssuersRegistry) {
        return tokenIssuersRegistry;
    }

    /**
     *  @dev See {IIdentityRegistry-topicsRegistry}.
     */
    function topicsRegistry() external view override returns (IClaimTopicsRegistry) {
        return tokenTopicsRegistry;
    }

    /**
     *  @dev See {IIdentityRegistry-identityStorage}.
     */
    function identityStorage() external view override returns (IIdentityRegistryStorage) {
        return tokenIdentityStorage;
    }

    /**
     *  @dev See {IIdentityRegistry-registerIdentity}.
     */
    function registerIdentity(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) public override onlyAgent {
        tokenIdentityStorage.addIdentityToStorage(_userAddress, _identity, _country);
        emit IdentityRegistered(_userAddress, _identity);
    }

    /**
     *  @dev See {IIdentityRegistry-batchRegisterIdentity}.
     */
    function batchRegisterIdentity(
        address[] calldata _userAddresses,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    ) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            registerIdentity(_userAddresses[i], _identities[i], _countries[i]);
        }
    }

    /**
     *  @dev See {IIdentityRegistry-updateIdentity}.
     */
    function updateIdentity(address _userAddress, IIdentity _identity) external override onlyAgent {
        IIdentity oldIdentity = identity(_userAddress);
        tokenIdentityStorage.modifyStoredIdentity(_userAddress, _identity);
        emit IdentityUpdated(oldIdentity, _identity);
    }

    /**
     *  @dev See {IIdentityRegistry-updateCountry}.
     */
    function updateCountry(address _userAddress, uint16 _country) external override onlyAgent {
        tokenIdentityStorage.modifyStoredInvestorCountry(_userAddress, _country);
        emit CountryUpdated(_userAddress, _country);
    }

    /**
     *  @dev See {IIdentityRegistry-deleteIdentity}.
     */
    function deleteIdentity(address _userAddress) external override onlyAgent {
        IIdentity oldIdentity = identity(_userAddress);
        tokenIdentityStorage.removeIdentityFromStorage(_userAddress);
        emit IdentityRemoved(_userAddress, oldIdentity);
    }

    /**
     *  @dev See {IIdentityRegistry-isVerified}.
     */
    function isVerified(address _userAddress) external view override returns (bool) {
        if (address(identity(_userAddress)) == address(0)) {
            return false;
        }
        uint256[] memory requiredClaimTopics = tokenTopicsRegistry.getClaimTopics();
        if (requiredClaimTopics.length == 0) {
            return true;
        }
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;
        uint256 claimTopic;
        for (claimTopic = 0; claimTopic < requiredClaimTopics.length; claimTopic++) {
            bytes32[] memory claimIds = identity(_userAddress).getClaimIdsByTopic(requiredClaimTopics[claimTopic]);
            if (claimIds.length == 0) {
                return false;
            }
            for (uint256 j = 0; j < claimIds.length; j++) {
                (foundClaimTopic, scheme, issuer, sig, data, ) = identity(_userAddress).getClaim(claimIds[j]);

                try IClaimIssuer(issuer).isClaimValid(identity(_userAddress), requiredClaimTopics[claimTopic], sig,
                data) returns(bool _validity){
                    if (
                        _validity
                        && tokenIssuersRegistry.hasClaimTopic(issuer, requiredClaimTopics[claimTopic])
                        && tokenIssuersRegistry.isTrustedIssuer(issuer)
                    ) {
                        j = claimIds.length;
                    }
                    if (!tokenIssuersRegistry.isTrustedIssuer(issuer) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!tokenIssuersRegistry.hasClaimTopic(issuer, requiredClaimTopics[claimTopic]) && j == (claimIds.length - 1)) {
                        return false;
                    }
                    if (!_validity && j == (claimIds.length - 1)) {
                        return false;
                    }
                }
                catch {
                    if (j == (claimIds.length - 1)) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    /**
     *  @dev See {IIdentityRegistry-setIdentityRegistryStorage}.
     */
    function setIdentityRegistryStorage(address _identityRegistryStorage) external override onlyOwner {
        tokenIdentityStorage = IIdentityRegistryStorage(_identityRegistryStorage);
        emit IdentityStorageSet(_identityRegistryStorage);
    }

    /**
     *  @dev See {IIdentityRegistry-setClaimTopicsRegistry}.
     */
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external override onlyOwner {
        tokenTopicsRegistry = IClaimTopicsRegistry(_claimTopicsRegistry);
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
    }

    /**
     *  @dev See {IIdentityRegistry-setTrustedIssuersRegistry}.
     */
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external override onlyOwner {
        tokenIssuersRegistry = ITrustedIssuersRegistry(_trustedIssuersRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
    }

    /**
     *  @dev See {IIdentityRegistry-contains}.
     */
    function contains(address _userAddress) external view override returns (bool) {
        if (address(identity(_userAddress)) == address(0)) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

import '../../roles/AgentRoleUpgradeable.sol';
import '../interface/IIdentityRegistryStorage.sol';
import '../storage/IRSStorage.sol';

contract IdentityRegistryStorage is IIdentityRegistryStorage, AgentRoleUpgradeable, IRSStorage {

    function init() public initializer {
        __Ownable_init();
    }

    /**
     *  @dev See {IIdentityRegistryStorage-linkedIdentityRegistries}.
     */
    function linkedIdentityRegistries() external view override returns (address[] memory) {
        return identityRegistries;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-storedIdentity}.
     */
    function storedIdentity(address _userAddress) external view override returns (IIdentity) {
        return identities[_userAddress].identityContract;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-storedInvestorCountry}.
     */
    function storedInvestorCountry(address _userAddress) external view override returns (uint16) {
        return identities[_userAddress].investorCountry;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-addIdentityToStorage}.
     */
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external override onlyAgent {
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        require(address(identities[_userAddress].identityContract) == address(0), 'identity contract already exists, please use update');
        identities[_userAddress].identityContract = _identity;
        identities[_userAddress].investorCountry = _country;
        emit IdentityStored(_userAddress, _identity);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-modifyStoredIdentity}.
     */
    function modifyStoredIdentity(address _userAddress, IIdentity _identity) external override onlyAgent {
        require(address(identities[_userAddress].identityContract) != address(0), 'this user has no identity registered');
        require(address(_identity) != address(0), 'contract address can\'t be a zero address');
        IIdentity oldIdentity = identities[_userAddress].identityContract;
        identities[_userAddress].identityContract = _identity;
        emit IdentityModified(oldIdentity, _identity);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-modifyStoredInvestorCountry}.
     */
    function modifyStoredInvestorCountry(address _userAddress, uint16 _country) external override onlyAgent {
        require(address(identities[_userAddress].identityContract) != address(0), 'this user has no identity registered');
        identities[_userAddress].investorCountry = _country;
        emit CountryModified(_userAddress, _country);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-removeIdentityFromStorage}.
     */
    function removeIdentityFromStorage(address _userAddress) external override onlyAgent {
        require(address(identities[_userAddress].identityContract) != address(0), 'you haven\'t registered an identity yet');
        IIdentity oldIdentity = identities[_userAddress].identityContract;
        delete identities[_userAddress];
        emit IdentityUnstored(_userAddress, oldIdentity);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-bindIdentityRegistry}.
     */
    function bindIdentityRegistry(address _identityRegistry) external override {
        addAgent(_identityRegistry);
        identityRegistries.push(_identityRegistry);
        emit IdentityRegistryBound(_identityRegistry);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-unbindIdentityRegistry}.
     */
    function unbindIdentityRegistry(address _identityRegistry) external override {
        require(identityRegistries.length > 0, 'identity registry is not stored');
        uint256 length = identityRegistries.length;
        for (uint256 i = 0; i < length; i++) {
            if (identityRegistries[i] == _identityRegistry) {
                identityRegistries[i] = identityRegistries[length - 1];
                identityRegistries.pop();
                break;
            }
        }
        removeAgent(_identityRegistry);
        emit IdentityRegistryUnbound(_identityRegistry);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '../interface/ITrustedIssuersRegistry.sol';
import '../storage/TIRStorage.sol';


contract TrustedIssuersRegistry is ITrustedIssuersRegistry, OwnableUpgradeable, TIRStorage {

    function init() public initializer {
        __Ownable_init();
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-addTrustedIssuer}.
     */
    function addTrustedIssuer(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external override onlyOwner {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length == 0, 'trusted Issuer already exists');
        require(_claimTopics.length > 0, 'trusted claim topics cannot be empty');
        trustedIssuers.push(_trustedIssuer);
        trustedIssuerClaimTopics[address(_trustedIssuer)] = _claimTopics;
        emit TrustedIssuerAdded(_trustedIssuer, _claimTopics);
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-removeTrustedIssuer}.
     */
    function removeTrustedIssuer(IClaimIssuer _trustedIssuer) external override onlyOwner {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length != 0, 'trusted Issuer doesn\'t exist');
        uint256 length = trustedIssuers.length;
        for (uint256 i = 0; i < length; i++) {
            if (trustedIssuers[i] == _trustedIssuer) {
                trustedIssuers[i] = trustedIssuers[length - 1];
                trustedIssuers.pop();
                break;
            }
        }
        delete trustedIssuerClaimTopics[address(_trustedIssuer)];
        emit TrustedIssuerRemoved(_trustedIssuer);
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-updateIssuerClaimTopics}.
     */
    function updateIssuerClaimTopics(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external override onlyOwner {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length != 0, 'trusted Issuer doesn\'t exist');
        require(_claimTopics.length > 0, 'claim topics cannot be empty');
        trustedIssuerClaimTopics[address(_trustedIssuer)] = _claimTopics;
        emit ClaimTopicsUpdated(_trustedIssuer, _claimTopics);
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-getTrustedIssuers}.
     */
    function getTrustedIssuers() external view override returns (IClaimIssuer[] memory) {
        return trustedIssuers;
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-isTrustedIssuer}.
     */
    function isTrustedIssuer(address _issuer) external view override returns (bool) {
        uint256 length = trustedIssuers.length;
        for (uint256 i = 0; i < length; i++) {
            if (address(trustedIssuers[i]) == _issuer) {
                return true;
            }
        }
        return false;
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-getTrustedIssuerClaimTopics}.
     */
    function getTrustedIssuerClaimTopics(IClaimIssuer _trustedIssuer) external view override returns (uint256[] memory) {
        require(trustedIssuerClaimTopics[address(_trustedIssuer)].length != 0, 'trusted Issuer doesn\'t exist');
        return trustedIssuerClaimTopics[address(_trustedIssuer)];
    }

    /**
     *  @dev See {ITrustedIssuersRegistry-hasClaimTopic}.
     */
    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view override returns (bool) {
        uint256 length = trustedIssuerClaimTopics[_issuer].length;
        uint256[] memory claimTopics = trustedIssuerClaimTopics[_issuer];
        for (uint256 i = 0; i < length; i++) {
            if (claimTopics[i] == _claimTopic) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

interface IClaimTopicsRegistry {
    /**
     *  this event is emitted when a claim topic has been added to the ClaimTopicsRegistry
     *  the event is emitted by the 'addClaimTopic' function
     *  `claimTopic` is the required claim added to the Claim Topics Registry
     */
    event ClaimTopicAdded(uint256 indexed claimTopic);

    /**
     *  this event is emitted when a claim topic has been removed from the ClaimTopicsRegistry
     *  the event is emitted by the 'removeClaimTopic' function
     *  `claimTopic` is the required claim removed from the Claim Topics Registry
     */
    event ClaimTopicRemoved(uint256 indexed claimTopic);

    /**
     * @dev Add a trusted claim topic (For example: KYC=1, AML=2).
     * Only owner can call.
     * emits `ClaimTopicAdded` event
     * @param _claimTopic The claim topic index
     */
    function addClaimTopic(uint256 _claimTopic) external;

    /**
     *  @dev Remove a trusted claim topic (For example: KYC=1, AML=2).
     *  Only owner can call.
     *  emits `ClaimTopicRemoved` event
     *  @param _claimTopic The claim topic index
     */
    function removeClaimTopic(uint256 _claimTopic) external;

    /**
     *  @dev Get the trusted claim topics for the security token
     *  @return Array of trusted claim topics
     */
    function getClaimTopics() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import './ITrustedIssuersRegistry.sol';
import './IClaimTopicsRegistry.sol';
import './IIdentityRegistryStorage.sol';

import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';
import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

interface IIdentityRegistry {
    /**
     *  this event is emitted when the ClaimTopicsRegistry has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `claimTopicsRegistry` is the address of the Claim Topics Registry contract
     */
    event ClaimTopicsRegistrySet(address indexed claimTopicsRegistry);

    /**
     *  this event is emitted when the IdentityRegistryStorage has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `identityStorage` is the address of the Identity Registry Storage contract
     */
    event IdentityStorageSet(address indexed identityStorage);

    /**
     *  this event is emitted when the ClaimTopicsRegistry has been set for the IdentityRegistry
     *  the event is emitted by the IdentityRegistry constructor
     *  `trustedIssuersRegistry` is the address of the Trusted Issuers Registry contract
     */
    event TrustedIssuersRegistrySet(address indexed trustedIssuersRegistry);

    /**
     *  this event is emitted when an Identity is registered into the Identity Registry.
     *  the event is emitted by the 'registerIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityRegistered(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity is removed from the Identity Registry.
     *  the event is emitted by the 'deleteIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityRemoved(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity has been updated
     *  the event is emitted by the 'updateIdentity' function
     *  `oldIdentity` is the old Identity contract's address to update
     *  `newIdentity` is the new Identity contract's
     */
    event IdentityUpdated(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

    /**
     *  this event is emitted when an Identity's country has been updated
     *  the event is emitted by the 'updateCountry' function
     *  `investorAddress` is the address on which the country has been updated
     *  `country` is the numeric code (ISO 3166-1) of the new country
     */
    event CountryUpdated(address indexed investorAddress, uint16 indexed country);

    /**
     *  @dev Register an identity contract corresponding to a user address.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's identity contract
     *  @param _country The country of the investor
     *  emits `IdentityRegistered` event
     */
    function registerIdentity(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     *  @dev Removes an user from the identity registry.
     *  Requires that the user have an identity contract already deployed that will be deleted.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user to be removed
     *  emits `IdentityRemoved` event
     */
    function deleteIdentity(address _userAddress) external;

    /**
     *  @dev Replace the actual identityRegistryStorage contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _identityRegistryStorage The address of the new Identity Registry Storage
     *  emits `IdentityStorageSet` event
     */
    function setIdentityRegistryStorage(address _identityRegistryStorage) external;

    /**
     *  @dev Replace the actual claimTopicsRegistry contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _claimTopicsRegistry The address of the new claim Topics Registry
     *  emits `ClaimTopicsRegistrySet` event
     */
    function setClaimTopicsRegistry(address _claimTopicsRegistry) external;

    /**
     *  @dev Replace the actual trustedIssuersRegistry contract with a new one.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  @param _trustedIssuersRegistry The address of the new Trusted Issuers Registry
     *  emits `TrustedIssuersRegistrySet` event
     */
    function setTrustedIssuersRegistry(address _trustedIssuersRegistry) external;

    /**
     *  @dev Updates the country corresponding to a user address.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _country The new country of the user
     *  emits `CountryUpdated` event
     */
    function updateCountry(address _userAddress, uint16 _country) external;

    /**
     *  @dev Updates an identity contract corresponding to a user address.
     *  Requires that the user address should be the owner of the identity contract.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by a wallet set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's new identity contract
     *  emits `IdentityUpdated` event
     */
    function updateIdentity(address _userAddress, IIdentity _identity) external;

    /**
     *  @dev function allowing to register identities in batch
     *  This function can only be called by a wallet set as agent of the smart contract
     *  Requires that none of the users has an identity contract already registered.
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _userAddresses The addresses of the users
     *  @param _identities The addresses of the corresponding identity contracts
     *  @param _countries The countries of the corresponding investors
     *  emits _userAddresses.length `IdentityRegistered` events
     */
    function batchRegisterIdentity(
        address[] calldata _userAddresses,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    ) external;

    /**
     *  @dev This functions checks whether a wallet has its Identity registered or not
     *  in the Identity Registry.
     *  @param _userAddress The address of the user to be checked.
     *  @return 'True' if the address is contained in the Identity Registry, 'false' if not.
     */
    function contains(address _userAddress) external view returns (bool);

    /**
     *  @dev This functions checks whether an identity contract
     *  corresponding to the provided user address has the required claims or not based
     *  on the data fetched from trusted issuers registry and from the claim topics registry
     *  @param _userAddress The address of the user to be verified.
     *  @return 'True' if the address is verified, 'false' if not.
     */
    function isVerified(address _userAddress) external view returns (bool);

    /**
     *  @dev Returns the onchainID of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function identity(address _userAddress) external view returns (IIdentity);

    /**
     *  @dev Returns the country code of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function investorCountry(address _userAddress) external view returns (uint16);

    /**
     *  @dev Returns the IdentityRegistryStorage linked to the current IdentityRegistry.
     */
    function identityStorage() external view returns (IIdentityRegistryStorage);

    /**
     *  @dev Returns the TrustedIssuersRegistry linked to the current IdentityRegistry.
     */
    function issuersRegistry() external view returns (ITrustedIssuersRegistry);

    /**
     *  @dev Returns the ClaimTopicsRegistry linked to the current IdentityRegistry.
     */
    function topicsRegistry() external view returns (IClaimTopicsRegistry);
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

interface IIdentityRegistryStorage {
    /**
     *  this event is emitted when an Identity is registered into the storage contract.
     *  the event is emitted by the 'registerIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityStored(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity is removed from the storage contract.
     *  the event is emitted by the 'deleteIdentity' function
     *  `investorAddress` is the address of the investor's wallet
     *  `identity` is the address of the Identity smart contract (onchainID)
     */
    event IdentityUnstored(address indexed investorAddress, IIdentity indexed identity);

    /**
     *  this event is emitted when an Identity has been updated
     *  the event is emitted by the 'updateIdentity' function
     *  `oldIdentity` is the old Identity contract's address to update
     *  `newIdentity` is the new Identity contract's
     */
    event IdentityModified(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);

    /**
     *  this event is emitted when an Identity's country has been updated
     *  the event is emitted by the 'updateCountry' function
     *  `investorAddress` is the address on which the country has been updated
     *  `country` is the numeric code (ISO 3166-1) of the new country
     */
    event CountryModified(address indexed investorAddress, uint16 indexed country);

    /**
     *  this event is emitted when an Identity Registry is bound to the storage contract
     *  the event is emitted by the 'addIdentityRegistry' function
     *  `identityRegistry` is the address of the identity registry added
     */
    event IdentityRegistryBound(address indexed identityRegistry);

    /**
     *  this event is emitted when an Identity Registry is unbound from the storage contract
     *  the event is emitted by the 'removeIdentityRegistry' function
     *  `identityRegistry` is the address of the identity registry removed
     */
    event IdentityRegistryUnbound(address indexed identityRegistry);

    /**
     *  @dev Returns the identity registries linked to the storage contract
     */
    function linkedIdentityRegistries() external view returns (address[] memory);

    /**
     *  @dev Returns the onchainID of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function storedIdentity(address _userAddress) external view returns (IIdentity);

    /**
     *  @dev Returns the country code of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function storedInvestorCountry(address _userAddress) external view returns (uint16);

    /**
     *  @dev adds an identity contract corresponding to a user address in the storage.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's identity contract
     *  @param _country The country of the investor
     *  emits `IdentityStored` event
     */
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     *  @dev Removes an user from the storage.
     *  Requires that the user have an identity contract already deployed that will be deleted.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user to be removed
     *  emits `IdentityUnstored` event
     */
    function removeIdentityFromStorage(address _userAddress) external;

    /**
     *  @dev Updates the country corresponding to a user address.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _country The new country of the user
     *  emits `CountryModified` event
     */
    function modifyStoredInvestorCountry(address _userAddress, uint16 _country) external;

    /**
     *  @dev Updates an identity contract corresponding to a user address.
     *  Requires that the user address should be the owner of the identity contract.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's new identity contract
     *  emits `IdentityModified` event
     */
    function modifyStoredIdentity(address _userAddress, IIdentity _identity) external;

    /**
     *  @notice Adds an identity registry as agent of the Identity Registry Storage Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  This function adds the identity registry to the list of identityRegistries linked to the storage contract
     *  @param _identityRegistry The identity registry address to add.
     */
    function bindIdentityRegistry(address _identityRegistry) external;

    /**
     *  @notice Removes an identity registry from being agent of the Identity Registry Storage Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  This function removes the identity registry from the list of identityRegistries linked to the storage contract
     *  @param _identityRegistry The identity registry address to remove.
     */
    function unbindIdentityRegistry(address _identityRegistry) external;
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';

interface ITrustedIssuersRegistry {
    /**
     *  this event is emitted when a trusted issuer is added in the registry.
     *  the event is emitted by the addTrustedIssuer function
     *  `trustedIssuer` is the address of the trusted issuer's ClaimIssuer contract
     *  `claimTopics` is the set of claims that the trusted issuer is allowed to emit
     */
    event TrustedIssuerAdded(IClaimIssuer indexed trustedIssuer, uint256[] claimTopics);

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
    event ClaimTopicsUpdated(IClaimIssuer indexed trustedIssuer, uint256[] claimTopics);

    /**
     *  @dev registers a ClaimIssuer contract as trusted claim issuer.
     *  Requires that a ClaimIssuer contract doesn't already exist
     *  Requires that the claimTopics set is not empty
     *  @param _trustedIssuer The ClaimIssuer contract address of the trusted claim issuer.
     *  @param _claimTopics the set of claim topics that the trusted issuer is allowed to emit
     *  This function can only be called by the owner of the Trusted Issuers Registry contract
     *  emits a `TrustedIssuerAdded` event
     */
    function addTrustedIssuer(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external;

    /**
     *  @dev Removes the ClaimIssuer contract of a trusted claim issuer.
     *  Requires that the claim issuer contract to be registered first
     *  @param _trustedIssuer the claim issuer to remove.
     *  This function can only be called by the owner of the Trusted Issuers Registry contract
     *  emits a `TrustedIssuerRemoved` event
     */
    function removeTrustedIssuer(IClaimIssuer _trustedIssuer) external;

    /**
     *  @dev Updates the set of claim topics that a trusted issuer is allowed to emit.
     *  Requires that this ClaimIssuer contract already exists in the registry
     *  Requires that the provided claimTopics set is not empty
     *  @param _trustedIssuer the claim issuer to update.
     *  @param _claimTopics the set of claim topics that the trusted issuer is allowed to emit
     *  This function can only be called by the owner of the Trusted Issuers Registry contract
     *  emits a `ClaimTopicsUpdated` event
     */
    function updateIssuerClaimTopics(IClaimIssuer _trustedIssuer, uint256[] calldata _claimTopics) external;

    /**
     *  @dev Function for getting all the trusted claim issuers stored.
     *  @return array of all claim issuers registered.
     */
    function getTrustedIssuers() external view returns (IClaimIssuer[] memory);

    /**
     *  @dev Checks if the ClaimIssuer contract is trusted
     *  @param _issuer the address of the ClaimIssuer contract
     *  @return true if the issuer is trusted, false otherwise.
     */
    function isTrustedIssuer(address _issuer) external view returns (bool);

    /**
     *  @dev Function for getting all the claim topic of trusted claim issuer
     *  Requires the provided ClaimIssuer contract to be registered in the trusted issuers registry.
     *  @param _trustedIssuer the trusted issuer concerned.
     *  @return The set of claim topics that the trusted issuer is allowed to emit
     */
    function getTrustedIssuerClaimTopics(IClaimIssuer _trustedIssuer) external view returns (uint256[] memory);

    /**
     *  @dev Function for checking if the trusted claim issuer is allowed
     *  to emit a certain claim topic
     *  @param _issuer the address of the trusted issuer's ClaimIssuer contract
     *  @param _claimTopic the Claim Topic that has to be checked to know if the `issuer` is allowed to emit it
     *  @return true if the issuer is trusted for this claim topic.
     */
    function hasClaimTopic(address _issuer, uint256 _claimTopic) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

contract CTRStorage {
    /// @dev All required Claim Topics
    uint256[] internal claimTopics;
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

contract IRSStorage {
    /// @dev struct containing the identity contract and the country of the user
    struct Identity {
        IIdentity identityContract;
        uint16 investorCountry;
    }
    /// @dev mapping between a user address and the corresponding identity
    mapping(address => Identity) internal identities;

    /// @dev array of Identity Registries linked to this storage
    address[] internal identityRegistries;
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../interface/IClaimTopicsRegistry.sol';
import '../interface/ITrustedIssuersRegistry.sol';
import '../interface/IIdentityRegistryStorage.sol';

contract IRStorage {
    /// @dev Address of the ClaimTopicsRegistry Contract
    IClaimTopicsRegistry internal tokenTopicsRegistry;

    /// @dev Address of the TrustedIssuersRegistry Contract
    ITrustedIssuersRegistry internal tokenIssuersRegistry;

    /// @dev Address of the IdentityRegistryStorage Contract
    IIdentityRegistryStorage internal tokenIdentityStorage;
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';

contract TIRStorage {
    /// @dev Array containing all TrustedIssuers identity contract address.
    IClaimIssuer[] internal trustedIssuers;

    /// @dev Mapping between a trusted issuer index and its corresponding claimTopics.
    mapping(address => uint256[]) internal trustedIssuerClaimTopics;
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

import './Roles.sol';

contract AgentRole is Ownable {
    using Roles for Roles.Role;

    event AgentAdded(address indexed _agent);
    event AgentRemoved(address indexed _agent);

    Roles.Role private _agents;

    modifier onlyAgent() {
        require(isAgent(msg.sender), 'AgentRole: caller does not have the Agent role');
        _;
    }

    function isAgent(address _agent) public view returns (bool) {
        return _agents.has(_agent);
    }

    function addAgent(address _agent) public onlyOwner {
        _agents.add(_agent);
        emit AgentAdded(_agent);
    }

    function removeAgent(address _agent) public onlyOwner {
        _agents.remove(_agent);
        emit AgentRemoved(_agent);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import './Roles.sol';

contract AgentRoleUpgradeable is OwnableUpgradeable {
    using Roles for Roles.Role;

    event AgentAdded(address indexed _agent);
    event AgentRemoved(address indexed _agent);

    Roles.Role private _agents;

    modifier onlyAgent() {
        require(isAgent(msg.sender), 'AgentRole: caller does not have the Agent role');
        _;
    }

    function isAgent(address _agent) public view returns (bool) {
        return _agents.has(_agent);
    }

    function addAgent(address _agent) public onlyOwner {
        _agents.add(_agent);
        emit AgentAdded(_agent);
    }

    function removeAgent(address _agent) public onlyOwner {
        _agents.remove(_agent);
        emit AgentRemoved(_agent);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@onchain-id/solidity/contracts/interface/IIdentity.sol';

import '../../../token/IToken.sol';
import '../../../registry/interface/IIdentityRegistry.sol';
import './AgentRoles.sol';

contract AgentManager is AgentRoles {
    /// @dev the token managed by this AgentManager contract
    IToken public token;

    constructor(address _token) {
        token = IToken(_token);
    }

    /**
     *  @dev calls the `forcedTransfer` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-forcedTransfer}.
     *  Requires that `_onchainID` is set as TransferManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callForcedTransfer(
        address _from,
        address _to,
        uint256 _amount,
        IIdentity _onchainID
    ) external {
        require(
            isTransferManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Transfer Manager'
        );
        token.forcedTransfer(_from, _to, _amount);
    }

    /**
     *  @dev calls the `batchForcedTransfer` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-batchForcedTransfer}.
     *  Requires that `_onchainID` is set as TransferManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callBatchForcedTransfer(
        address[] calldata _fromList,
        address[] calldata _toList,
        uint256[] calldata _amounts,
        IIdentity _onchainID
    ) external {
        require(
            isTransferManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Transfer Manager'
        );
        token.batchForcedTransfer(_fromList, _toList, _amounts);
    }

    /**
     *  @dev calls the `pause` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-pause}.
     *  Requires that `_onchainID` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callPause(IIdentity _onchainID) external {
        require(isFreezer(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        token.pause();
    }

    /**
     *  @dev calls the `unpause` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-unpause}.
     *  Requires that `_onchainID` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callUnpause(IIdentity _onchainID) external {
        require(isFreezer(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        token.unpause();
    }

    /**
     *  @dev calls the `mint` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-mint}.
     *  Requires that `_onchainID` is set as SupplyModifier on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callMint(
        address _to,
        uint256 _amount,
        IIdentity _onchainID
    ) external {
        require(
            isSupplyModifier(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        token.mint(_to, _amount);
    }

    /**
     *  @dev calls the `batchMint` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-batchMint}.
     *  Requires that `_onchainID` is set as SupplyModifier on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callBatchMint(
        address[] calldata _toList,
        uint256[] calldata _amounts,
        IIdentity _onchainID
    ) external {
        require(
            isSupplyModifier(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        token.batchMint(_toList, _amounts);
    }

    /**
     *  @dev calls the `burn` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-burn}.
     *  Requires that `_onchainID` is set as SupplyModifier on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callBurn(
        address _userAddress,
        uint256 _amount,
        IIdentity _onchainID
    ) external {
        require(
            isSupplyModifier(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        token.burn(_userAddress, _amount);
    }

    /**
     *  @dev calls the `batchBurn` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-batchBurn}.
     *  Requires that `_onchainID` is set as SupplyModifier on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callBatchBurn(
        address[] calldata _userAddresses,
        uint256[] calldata _amounts,
        IIdentity _onchainID
    ) external {
        require(
            isSupplyModifier(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Supply Modifier'
        );
        token.batchBurn(_userAddresses, _amounts);
    }

    /**
     *  @dev calls the `setAddressFrozen` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-setAddressFrozen}.
     *  Requires that `_onchainID` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetAddressFrozen(
        address _userAddress,
        bool _freeze,
        IIdentity _onchainID
    ) external {
        require(isFreezer(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        token.setAddressFrozen(_userAddress, _freeze);
    }

    /**
     *  @dev calls the `batchSetAddressFrozen` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-batchSetAddressFrozen}.
     *  Requires that `_onchainID` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callBatchSetAddressFrozen(
        address[] calldata _userAddresses,
        bool[] calldata _freeze,
        IIdentity _onchainID
    ) external {
        require(isFreezer(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        token.batchSetAddressFrozen(_userAddresses, _freeze);
    }

    /**
     *  @dev calls the `freezePartialTokens` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-freezePartialTokens}.
     *  Requires that `_onchainID` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callFreezePartialTokens(
        address _userAddress,
        uint256 _amount,
        IIdentity _onchainID
    ) external {
        require(isFreezer(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        token.freezePartialTokens(_userAddress, _amount);
    }

    /**
     *  @dev calls the `batchFreezePartialTokens` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-batchFreezePartialTokens}.
     *  Requires that `_onchainID` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callBatchFreezePartialTokens(
        address[] calldata _userAddresses,
        uint256[] calldata _amounts,
        IIdentity _onchainID
    ) external {
        require(isFreezer(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        token.batchFreezePartialTokens(_userAddresses, _amounts);
    }

    /**
     *  @dev calls the `unfreezePartialTokens` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-unfreezePartialTokens}.
     *  Requires that `_onchainID` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callUnfreezePartialTokens(
        address _userAddress,
        uint256 _amount,
        IIdentity _onchainID
    ) external {
        require(isFreezer(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        token.unfreezePartialTokens(_userAddress, _amount);
    }

    /**
     *  @dev calls the `batchUnfreezePartialTokens` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-batchUnfreezePartialTokens}.
     *  Requires that `_onchainID` is set as Freezer on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callBatchUnfreezePartialTokens(
        address[] calldata _userAddresses,
        uint256[] calldata _amounts,
        IIdentity _onchainID
    ) external {
        require(isFreezer(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), 'Role: Sender is NOT Freezer');
        token.batchUnfreezePartialTokens(_userAddresses, _amounts);
    }

    /**
     *  @dev calls the `recoveryAddress` function on the Token contract
     *  AgentManager has to be set as agent on the token smart contract to process this function
     *  See {IToken-recoveryAddress}.
     *  Requires that `_managerOnchainID` is set as RecoveryAgent on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_managerOnchainID`
     *  @param _managerOnchainID the onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callRecoveryAddress(
        address _lostWallet,
        address _newWallet,
        address _onchainID,
        IIdentity _managerOnchainID
    ) external {
        require(
            isRecoveryAgent(address(_managerOnchainID)) && _managerOnchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Recovery Agent'
        );
        token.recoveryAddress(_lostWallet, _newWallet, _onchainID);
    }

    /**
     *  @dev calls the `registerIdentity` function on the Identity Registry contract
     *  AgentManager has to be set as agent on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-registerIdentity}.
     *  Requires that `ManagerOnchainID` is set as WhiteListManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_managerOnchainID`
     *  @param _managerOnchainID the onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callRegisterIdentity(
        address _userAddress,
        IIdentity _onchainID,
        uint16 _country,
        IIdentity _managerOnchainID
    ) external {
        require(
            isWhiteListManager(address(_managerOnchainID)) && _managerOnchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        token.identityRegistry().registerIdentity(_userAddress, _onchainID, _country);
    }

    /**
     *  @dev calls the `updateIdentity` function on the Identity Registry contract
     *  AgentManager has to be set as agent on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-updateIdentity}.
     *  Requires that `_onchainID` is set as WhiteListManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callUpdateIdentity(
        address _userAddress,
        IIdentity _identity,
        IIdentity _onchainID
    ) external {
        require(
            isWhiteListManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        token.identityRegistry().updateIdentity(_userAddress, _identity);
    }

    /**
     *  @dev calls the `updateCountry` function on the Identity Registry contract
     *  AgentManager has to be set as agent on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-updateCountry}.
     *  Requires that `_onchainID` is set as WhiteListManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callUpdateCountry(
        address _userAddress,
        uint16 _country,
        IIdentity _onchainID
    ) external {
        require(
            isWhiteListManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        token.identityRegistry().updateCountry(_userAddress, _country);
    }

    /**
     *  @dev calls the `deleteIdentity` function on the Identity Registry contract
     *  AgentManager has to be set as agent on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-deleteIdentity}.
     *  Requires that `_onchainID` is set as WhiteListManager on the AgentManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callDeleteIdentity(address _userAddress, IIdentity _onchainID) external {
        require(
            isWhiteListManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT WhiteList Manager'
        );
        token.identityRegistry().deleteIdentity(_userAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

import '../../Roles.sol';

contract AgentRoles is Ownable {
    using Roles for Roles.Role;

    event RoleAdded(address indexed _agent, string _role);
    event RoleRemoved(address indexed _agent, string _role);

    Roles.Role private _supplyModifiers;
    Roles.Role private _freezers;
    Roles.Role private _transferManagers;
    Roles.Role private _recoveryAgents;
    Roles.Role private _complianceAgents;
    Roles.Role private _whiteListManagers;
    Roles.Role private _agentAdmin;

    modifier onlyAdmin() {
        require(owner() == msg.sender || isAgentAdmin(_msgSender()), 'Role: Sender is NOT Admin');
        _;
    }

    /// @dev AgentAdmin Role _agentAdmin

    function isAgentAdmin(address _agent) public view returns (bool) {
        return _agentAdmin.has(_agent);
    }

    function addAgentAdmin(address _agent) external onlyAdmin {
        _agentAdmin.add(_agent);
        string memory _role = 'AgentAdmin';
        emit RoleAdded(_agent, _role);
    }

    function removeAgentAdmin(address _agent) external onlyAdmin {
        _agentAdmin.remove(_agent);
        string memory _role = 'AgentAdmin';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev SupplyModifier Role _supplyModifiers

    function isSupplyModifier(address _agent) public view returns (bool) {
        return _supplyModifiers.has(_agent);
    }

    function addSupplyModifier(address _agent) external onlyAdmin {
        _supplyModifiers.add(_agent);
        string memory _role = 'SupplyModifier';
        emit RoleAdded(_agent, _role);
    }

    function removeSupplyModifier(address _agent) external onlyAdmin {
        _supplyModifiers.remove(_agent);
        string memory _role = 'SupplyModifier';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev Freezer Role _freezers

    function isFreezer(address _agent) public view returns (bool) {
        return _freezers.has(_agent);
    }

    function addFreezer(address _agent) external onlyAdmin {
        _freezers.add(_agent);
        string memory _role = 'Freezer';
        emit RoleAdded(_agent, _role);
    }

    function removeFreezer(address _agent) external onlyAdmin {
        _freezers.remove(_agent);
        string memory _role = 'Freezer';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev TransferManager Role _transferManagers

    function isTransferManager(address _agent) public view returns (bool) {
        return _transferManagers.has(_agent);
    }

    function addTransferManager(address _agent) external onlyAdmin {
        _transferManagers.add(_agent);
        string memory _role = 'TransferManager';
        emit RoleAdded(_agent, _role);
    }

    function removeTransferManager(address _agent) external onlyAdmin {
        _transferManagers.remove(_agent);
        string memory _role = 'TransferManager';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev RecoveryAgent Role _recoveryAgents

    function isRecoveryAgent(address _agent) public view returns (bool) {
        return _recoveryAgents.has(_agent);
    }

    function addRecoveryAgent(address _agent) external onlyAdmin {
        _recoveryAgents.add(_agent);
        string memory _role = 'RecoveryAgent';
        emit RoleAdded(_agent, _role);
    }

    function removeRecoveryAgent(address _agent) external onlyAdmin {
        _recoveryAgents.remove(_agent);
        string memory _role = 'RecoveryAgent';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev ComplianceAgent Role _complianceAgents

    function isComplianceAgent(address _agent) public view returns (bool) {
        return _complianceAgents.has(_agent);
    }

    function addComplianceAgent(address _agent) external onlyAdmin {
        _complianceAgents.add(_agent);
        string memory _role = 'ComplianceAgent';
        emit RoleAdded(_agent, _role);
    }

    function removeComplianceAgent(address _agent) external onlyAdmin {
        _complianceAgents.remove(_agent);
        string memory _role = 'ComplianceAgent';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev WhiteListManager Role _whiteListManagers

    function isWhiteListManager(address _agent) public view returns (bool) {
        return _whiteListManagers.has(_agent);
    }

    function addWhiteListManager(address _agent) external onlyAdmin {
        _whiteListManagers.add(_agent);
        string memory _role = 'WhiteListManager';
        emit RoleAdded(_agent, _role);
    }

    function removeWhiteListManager(address _agent) external onlyAdmin {
        _whiteListManagers.remove(_agent);
        string memory _role = 'WhiteListManager';
        emit RoleRemoved(_agent, _role);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../../Roles.sol';

contract AgentRolesUpgradeable is OwnableUpgradeable

 {
    using Roles for Roles.Role;

    event RoleAdded(address indexed _agent, string _role);
    event RoleRemoved(address indexed _agent, string _role);

    Roles.Role private _supplyModifiers;
    Roles.Role private _freezers;
    Roles.Role private _transferManagers;
    Roles.Role private _recoveryAgents;
    Roles.Role private _complianceAgents;
    Roles.Role private _whiteListManagers;
    Roles.Role private _agentAdmin;

    modifier onlyAdmin() {
        require(owner() == msg.sender || isAgentAdmin(_msgSender()), 'Role: Sender is NOT Admin');
        _;
    }

    /// @dev AgentAdmin Role _agentAdmin

    function isAgentAdmin(address _agent) public view returns (bool) {
        return _agentAdmin.has(_agent);
    }

    function addAgentAdmin(address _agent) external onlyAdmin {
        _agentAdmin.add(_agent);
        string memory _role = 'AgentAdmin';
        emit RoleAdded(_agent, _role);
    }

    function removeAgentAdmin(address _agent) external onlyAdmin {
        _agentAdmin.remove(_agent);
        string memory _role = 'AgentAdmin';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev SupplyModifier Role _supplyModifiers

    function isSupplyModifier(address _agent) public view returns (bool) {
        return _supplyModifiers.has(_agent);
    }

    function addSupplyModifier(address _agent) external onlyAdmin {
        _supplyModifiers.add(_agent);
        string memory _role = 'SupplyModifier';
        emit RoleAdded(_agent, _role);
    }

    function removeSupplyModifier(address _agent) external onlyAdmin {
        _supplyModifiers.remove(_agent);
        string memory _role = 'SupplyModifier';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev Freezer Role _freezers

    function isFreezer(address _agent) public view returns (bool) {
        return _freezers.has(_agent);
    }

    function addFreezer(address _agent) external onlyAdmin {
        _freezers.add(_agent);
        string memory _role = 'Freezer';
        emit RoleAdded(_agent, _role);
    }

    function removeFreezer(address _agent) external onlyAdmin {
        _freezers.remove(_agent);
        string memory _role = 'Freezer';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev TransferManager Role _transferManagers

    function isTransferManager(address _agent) public view returns (bool) {
        return _transferManagers.has(_agent);
    }

    function addTransferManager(address _agent) external onlyAdmin {
        _transferManagers.add(_agent);
        string memory _role = 'TransferManager';
        emit RoleAdded(_agent, _role);
    }

    function removeTransferManager(address _agent) external onlyAdmin {
        _transferManagers.remove(_agent);
        string memory _role = 'TransferManager';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev RecoveryAgent Role _recoveryAgents

    function isRecoveryAgent(address _agent) public view returns (bool) {
        return _recoveryAgents.has(_agent);
    }

    function addRecoveryAgent(address _agent) external onlyAdmin {
        _recoveryAgents.add(_agent);
        string memory _role = 'RecoveryAgent';
        emit RoleAdded(_agent, _role);
    }

    function removeRecoveryAgent(address _agent) external onlyAdmin {
        _recoveryAgents.remove(_agent);
        string memory _role = 'RecoveryAgent';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev ComplianceAgent Role _complianceAgents

    function isComplianceAgent(address _agent) public view returns (bool) {
        return _complianceAgents.has(_agent);
    }

    function addComplianceAgent(address _agent) external onlyAdmin {
        _complianceAgents.add(_agent);
        string memory _role = 'ComplianceAgent';
        emit RoleAdded(_agent, _role);
    }

    function removeComplianceAgent(address _agent) external onlyAdmin {
        _complianceAgents.remove(_agent);
        string memory _role = 'ComplianceAgent';
        emit RoleRemoved(_agent, _role);
    }

    /// @dev WhiteListManager Role _whiteListManagers

    function isWhiteListManager(address _agent) public view returns (bool) {
        return _whiteListManagers.has(_agent);
    }

    function addWhiteListManager(address _agent) external onlyAdmin {
        _whiteListManagers.add(_agent);
        string memory _role = 'WhiteListManager';
        emit RoleAdded(_agent, _role);
    }

    function removeWhiteListManager(address _agent) external onlyAdmin {
        _whiteListManagers.remove(_agent);
        string memory _role = 'WhiteListManager';
        emit RoleRemoved(_agent, _role);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../../../token/IToken.sol';
import '../../../registry/interface/IIdentityRegistry.sol';
import '../../../registry/interface/ITrustedIssuersRegistry.sol';
import '../../../registry/interface/IClaimTopicsRegistry.sol';
import '../../../compliance/legacy/ICompliance.sol';
import './OwnerRoles.sol';
import '../../AgentRole.sol';
import '@onchain-id/solidity/contracts/interface/IIdentity.sol';
import '@onchain-id/solidity/contracts/interface/IClaimIssuer.sol';

contract OwnerManager is OwnerRoles {
    /// @dev the token that is managed by this OwnerManager Contract
    IToken public token;

    /// @dev Event emitted for each executed interaction with the compliance contract.
    ///
    /// For gas efficiency, only the interaction calldata selector (first 4
    /// bytes) is included in the event. For interactions without calldata or
    /// whose calldata is shorter than 4 bytes, the selector will be `0`.
    event ComplianceInteraction(address indexed target, bytes4 selector);

    /**
     *  @dev the constructor initiates the OwnerManager contract
     *  and sets msg.sender as owner of the contract
     *  @param _token the token managed by this OwnerManager contract
     */
    constructor(address _token) {
        token = IToken(_token);
    }

    /**
     *  @dev calls the `setIdentityRegistry` function on the token contract
     *  OwnerManager has to be set as owner on the token smart contract to process this function
     *  See {IToken-setIdentityRegistry}.
     *  Requires that `_onchainID` is set as RegistryAddressSetter on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetIdentityRegistry(address _identityRegistry, IIdentity _onchainID) external {
        require(
            isRegistryAddressSetter(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Registry Address Setter'
        );
        token.setIdentityRegistry(_identityRegistry);
    }

    /**
     *  @dev calls the `setCompliance` function on the token contract
     *  OwnerManager has to be set as owner on the token smart contract to process this function
     *  See {IToken-setCompliance}.
     *  Requires that `_onchainID` is set as ComplianceSetter on the OwnerManager contract
     *  Requires that msg.sender is a MANAGEMENT KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetCompliance(address _compliance, IIdentity _onchainID) external {
        require(
            isComplianceSetter(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Compliance Setter'
        );
        token.setCompliance(_compliance);
    }

    /**
     *  @dev calls any onlyOwner function available on the compliance contract
     *  OwnerManager has to be set as owner on the compliance smart contract to process this function
     *  Requires that `_onchainID` is set as ComplianceManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callComplianceFunction(bytes calldata callData, IIdentity _onchainID) external {
        require(
            isComplianceManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Compliance Manager');
        address target = address(token.compliance());

        // NOTE: Use assembly to call the interaction instead of a low level
        // call for two reasons:
        // - We don't want to copy the return data, since we discard it for
        // interactions.
        // - Solidity will under certain conditions generate code to copy input
        // calldata twice to memory (the second being a "memcopy loop").
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            calldatacopy(freeMemoryPointer, callData.offset, callData.length)
            if iszero(
                call(
                    gas(),
                    target,
                    0,
                    freeMemoryPointer,
                    callData.length,
                    0,
                    0
                    ))
                {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

        emit ComplianceInteraction(target, selector(callData));

        }

    /// @dev Extracts the Solidity ABI selector for the specified interaction.
    /// @param callData Interaction data.
    /// @return result The 4 byte function selector of the call encoded in
    /// this interaction.
    function selector(bytes calldata callData) internal pure returns (bytes4 result) {
        if (callData.length >= 4) {
        // NOTE: Read the first word of the interaction's calldata. The
        // value does not need to be shifted since `bytesN` values are left
        // aligned, and the value does not need to be masked since masking
        // occurs when the value is accessed and not stored:
        // <https://docs.soliditylang.org/en/v0.7.6/abi-spec.html#encoding-of-indexed-event-parameters>
        // <https://docs.soliditylang.org/en/v0.7.6/assembly.html#access-to-external-variables-functions-and-libraries>
        // solhint-disable-next-line no-inline-assembly
            assembly {
                result := calldataload(callData.offset)
                }
            }
        }

    /**
     *  @dev calls the `setName` function on the token contract
     *  OwnerManager has to be set as owner on the token smart contract to process this function
     *  See {IToken-setName}.
     *  Requires that `_onchainID` is set as TokenInfoManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetTokenName(string calldata _name, IIdentity _onchainID) external {
        require(
            isTokenInfoManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Token Information Manager'
        );
        token.setName(_name);
    }

    /**
     *  @dev calls the `setSymbol` function on the token contract
     *  OwnerManager has to be set as owner on the token smart contract to process this function
     *  See {IToken-setSymbol}.
     *  Requires that `_onchainID` is set as TokenInfoManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetTokenSymbol(string calldata _symbol, IIdentity _onchainID) external {
        require(
            isTokenInfoManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Token Information Manager'
        );
        token.setSymbol(_symbol);
    }

    /**
     *  @dev calls the `setOnchainID` function on the token contract
     *  OwnerManager has to be set as owner on the token smart contract to process this function
     *  See {IToken-setOnchainID}.
     *  Requires that `_tokenOnchainID` is set as TokenInfoManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetTokenOnchainID(address _tokenOnchainID, IIdentity _onchainID) external {
        require(
            isTokenInfoManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Token Information Manager'
        );
        token.setOnchainID(_tokenOnchainID);
    }

    /**
     *  @dev calls the `setClaimTopicsRegistry` function on the Identity Registry contract
     *  OwnerManager has to be set as owner on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-setClaimTopicsRegistry}.
     *  Requires that `_onchainID` is set as RegistryAddressSetter on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetClaimTopicsRegistry(address _claimTopicsRegistry, IIdentity _onchainID) external {
        require(
            isRegistryAddressSetter(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Registry Address Setter'
        );
        token.identityRegistry().setClaimTopicsRegistry(_claimTopicsRegistry);
    }

    /**
     *  @dev calls the `setTrustedIssuersRegistry` function on the Identity Registry contract
     *  OwnerManager has to be set as owner on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-setTrustedIssuersRegistry}.
     *  Requires that `_onchainID` is set as RegistryAddressSetter on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callSetTrustedIssuersRegistry(address _trustedIssuersRegistry, IIdentity _onchainID) external {
        require(
            isRegistryAddressSetter(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT Registry Address Setter'
        );
        token.identityRegistry().setTrustedIssuersRegistry(_trustedIssuersRegistry);
    }

    /**
     *  @dev calls the `addTrustedIssuer` function on the Trusted Issuers Registry contract
     *  OwnerManager has to be set as owner on the Trusted Issuers Registry smart contract to process this function
     *  See {ITrustedIssuersRegistry-addTrustedIssuer}.
     *  Requires that `_onchainID` is set as IssuersRegistryManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callAddTrustedIssuer(
        IClaimIssuer _trustedIssuer,
        uint256[] calldata _claimTopics,
        IIdentity _onchainID
    ) external {
        require(
            isIssuersRegistryManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT IssuersRegistryManager'
        );
        token.identityRegistry().issuersRegistry().addTrustedIssuer(_trustedIssuer, _claimTopics);
    }

    /**
     *  @dev calls the `removeTrustedIssuer` function on the Trusted Issuers Registry contract
     *  OwnerManager has to be set as owner on the Trusted Issuers Registry smart contract to process this function
     *  See {ITrustedIssuersRegistry-removeTrustedIssuer}.
     *  Requires that `_onchainID` is set as IssuersRegistryManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callRemoveTrustedIssuer(IClaimIssuer _trustedIssuer, IIdentity _onchainID) external {
        require(
            isIssuersRegistryManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT IssuersRegistryManager'
        );
        token.identityRegistry().issuersRegistry().removeTrustedIssuer(_trustedIssuer);
    }

    /**
     *  @dev calls the `updateIssuerClaimTopics` function on the Trusted Issuers Registry contract
     *  OwnerManager has to be set as owner on the Trusted Issuers Registry smart contract to process this function
     *  See {ITrustedIssuersRegistry-updateIssuerClaimTopics}.
     *  Requires that `_onchainID` is set as IssuersRegistryManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callUpdateIssuerClaimTopics(
        IClaimIssuer _trustedIssuer,
        uint256[] calldata _claimTopics,
        IIdentity _onchainID
    ) external {
        require(
            isIssuersRegistryManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT IssuersRegistryManager'
        );
        token.identityRegistry().issuersRegistry().updateIssuerClaimTopics(_trustedIssuer, _claimTopics);
    }

    /**
     *  @dev calls the `addClaimTopic` function on the Claim Topics Registry contract
     *  OwnerManager has to be set as owner on the Claim Topics Registry smart contract to process this function
     *  See {IClaimTopicsRegistry-addClaimTopic}.
     *  Requires that `_onchainID` is set as ClaimRegistryManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callAddClaimTopic(uint256 _claimTopic, IIdentity _onchainID) external {
        require(
            isClaimRegistryManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT ClaimRegistryManager'
        );
        token.identityRegistry().topicsRegistry().addClaimTopic(_claimTopic);
    }

    /**
     *  @dev calls the `removeClaimTopic` function on the Claim Topics Registry contract
     *  OwnerManager has to be set as owner on the Claim Topics Registry smart contract to process this function
     *  See {IClaimTopicsRegistry-removeClaimTopic}.
     *  Requires that `_onchainID` is set as ClaimRegistryManager on the OwnerManager contract
     *  Requires that msg.sender is an ACTION KEY on `_onchainID`
     *  @param _onchainID the _onchainID contract of the caller, e.g. "i call this function and i am Bob"
     */
    function callRemoveClaimTopic(uint256 _claimTopic, IIdentity _onchainID) external {
        require(
            isClaimRegistryManager(address(_onchainID)) && _onchainID.keyHasPurpose(keccak256(abi.encode(msg.sender)), 2),
            'Role: Sender is NOT ClaimRegistryManager'
        );
        token.identityRegistry().topicsRegistry().removeClaimTopic(_claimTopic);
    }

    /**
     *  @dev calls the `transferOwnershipOnTokenContract` function on the token contract
     *  OwnerManager has to be set as owner on the token smart contract to process this function
     *  See {IToken-transferOwnershipOnTokenContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callTransferOwnershipOnTokenContract(address _newOwner) external onlyAdmin {
        Ownable(address(token)).transferOwnership(_newOwner);
    }

    /**
     *  @dev calls the `transferOwnershipOnIdentityRegistryContract` function on the Identity Registry contract
     *  OwnerManager has to be set as owner on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-transferOwnershipOnIdentityRegistryContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callTransferOwnershipOnIdentityRegistryContract(address _newOwner) external onlyAdmin {
        Ownable(address(token.identityRegistry())).transferOwnership(_newOwner);
    }

    /**
     *  @dev calls the `transferOwnershipOnComplianceContract` function on the Compliance contract
     *  OwnerManager has to be set as owner on the Compliance smart contract to process this function
     *  See {ICompliance-transferOwnershipOnComplianceContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callTransferOwnershipOnComplianceContract(address _newOwner) external onlyAdmin {
        Ownable(address(token.compliance())).transferOwnership(_newOwner);
    }

    /**
     *  @dev calls the `transferOwnershipOnClaimTopicsRegistryContract` function on the Claim Topics Registry contract
     *  OwnerManager has to be set as owner on the Claim Topics registry smart contract to process this function
     *  See {IClaimTopicsRegistry-transferOwnershipOnClaimTopicsRegistryContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callTransferOwnershipOnClaimTopicsRegistryContract(address _newOwner) external onlyAdmin {
        Ownable(address(token.identityRegistry().topicsRegistry())).transferOwnership(_newOwner);
    }

    /**
     *  @dev calls the `transferOwnershipOnIssuersRegistryContract` function on the Trusted Issuers Registry contract
     *  OwnerManager has to be set as owner on the Trusted Issuers registry smart contract to process this function
     *  See {ITrustedIssuersRegistry-transferOwnershipOnIssuersRegistryContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callTransferOwnershipOnIssuersRegistryContract(address _newOwner) external onlyAdmin {
        Ownable(address(token.identityRegistry().issuersRegistry())).transferOwnership(_newOwner);
    }

    /**
     *  @dev calls the `addAgentOnTokenContract` function on the token contract
     *  OwnerManager has to be set as owner on the token smart contract to process this function
     *  See {IToken-addAgentOnTokenContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callAddAgentOnTokenContract(address _agent) external onlyAdmin {
        AgentRole(address(token)).addAgent(_agent);
    }

    /**
     *  @dev calls the `removeAgentOnTokenContract` function on the token contract
     *  OwnerManager has to be set as owner on the token smart contract to process this function
     *  See {IToken-removeAgentOnTokenContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callRemoveAgentOnTokenContract(address _agent) external onlyAdmin {
        AgentRole(address(token)).removeAgent(_agent);
    }

    /**
     *  @dev calls the `addAgentOnIdentityRegistryContract` function on the Identity Registry contract
     *  OwnerManager has to be set as owner on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-addAgentOnIdentityRegistryContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callAddAgentOnIdentityRegistryContract(address _agent) external onlyAdmin {
        AgentRole(address(token.identityRegistry())).addAgent(_agent);
    }

    /**
     *  @dev calls the `removeAgentOnIdentityRegistryContract` function on the Identity Registry contract
     *  OwnerManager has to be set as owner on the Identity Registry smart contract to process this function
     *  See {IIdentityRegistry-removeAgentOnIdentityRegistryContract}.
     *  Requires that msg.sender is an Admin of the OwnerManager contract
     */
    function callRemoveAgentOnIdentityRegistryContract(address _agent) external onlyAdmin {
        AgentRole(address(token.identityRegistry())).removeAgent(_agent);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

import '../../Roles.sol';

contract OwnerRoles is Ownable {
    using Roles for Roles.Role;

    event RoleAdded(address indexed _owner, string _role);
    event RoleRemoved(address indexed _owner, string _role);

    Roles.Role private _ownerAdmin;
    Roles.Role private _registryAddressSetter;
    Roles.Role private _complianceSetter;
    Roles.Role private _complianceManager;
    Roles.Role private _claimRegistryManager;
    Roles.Role private _issuersRegistryManager;
    Roles.Role private _tokenInfoManager;

    modifier onlyAdmin() {
        require(owner() == msg.sender || isOwnerAdmin(_msgSender()), 'Role: Sender is NOT Admin');
        _;
    }

    /// @dev OwnerAdmin Role _ownerAdmin

    function isOwnerAdmin(address _owner) public view returns (bool) {
        return _ownerAdmin.has(_owner);
    }

    function addOwnerAdmin(address _owner) external onlyAdmin {
        _ownerAdmin.add(_owner);
        string memory _role = 'OwnerAdmin';
        emit RoleAdded(_owner, _role);
    }

    function removeOwnerAdmin(address _owner) external onlyAdmin {
        _ownerAdmin.remove(_owner);
        string memory _role = 'OwnerAdmin';
        emit RoleRemoved(_owner, _role);
    }

    /// @dev RegistryAddressSetter Role _registryAddressSetter

    function isRegistryAddressSetter(address _owner) public view returns (bool) {
        return _registryAddressSetter.has(_owner);
    }

    function addRegistryAddressSetter(address _owner) external onlyAdmin {
        _registryAddressSetter.add(_owner);
        string memory _role = 'RegistryAddressSetter';
        emit RoleAdded(_owner, _role);
    }

    function removeRegistryAddressSetter(address _owner) external onlyAdmin {
        _registryAddressSetter.remove(_owner);
        string memory _role = 'RegistryAddressSetter';
        emit RoleRemoved(_owner, _role);
    }

    /// @dev ComplianceSetter Role _complianceSetter

    function isComplianceSetter(address _owner) public view returns (bool) {
        return _complianceSetter.has(_owner);
    }

    function addComplianceSetter(address _owner) external onlyAdmin {
        _complianceSetter.add(_owner);
        string memory _role = 'ComplianceSetter';
        emit RoleAdded(_owner, _role);
    }

    function removeComplianceSetter(address _owner) external onlyAdmin {
        _complianceSetter.remove(_owner);
        string memory _role = 'ComplianceSetter';
        emit RoleRemoved(_owner, _role);
    }

    /// @dev ComplianceManager Role _complianceManager

    function isComplianceManager(address _owner) public view returns (bool) {
        return _complianceManager.has(_owner);
    }

    function addComplianceManager(address _owner) external onlyAdmin {
        _complianceManager.add(_owner);
        string memory _role = 'ComplianceManager';
        emit RoleAdded(_owner, _role);
    }

    function removeComplianceManager(address _owner) external onlyAdmin {
        _complianceManager.remove(_owner);
        string memory _role = 'ComplianceManager';
        emit RoleRemoved(_owner, _role);
    }

    /// @dev ClaimRegistryManager Role _claimRegistryManager

    function isClaimRegistryManager(address _owner) public view returns (bool) {
        return _claimRegistryManager.has(_owner);
    }

    function addClaimRegistryManager(address _owner) external onlyAdmin {
        _claimRegistryManager.add(_owner);
        string memory _role = 'ClaimRegistryManager';
        emit RoleAdded(_owner, _role);
    }

    function removeClaimRegistryManager(address _owner) external onlyAdmin {
        _claimRegistryManager.remove(_owner);
        string memory _role = 'ClaimRegistryManager';
        emit RoleRemoved(_owner, _role);
    }

    /// @dev IssuersRegistryManager Role _issuersRegistryManager

    function isIssuersRegistryManager(address _owner) public view returns (bool) {
        return _issuersRegistryManager.has(_owner);
    }

    function addIssuersRegistryManager(address _owner) external onlyAdmin {
        _issuersRegistryManager.add(_owner);
        string memory _role = 'IssuersRegistryManager';
        emit RoleAdded(_owner, _role);
    }

    function removeIssuersRegistryManager(address _owner) external onlyAdmin {
        _issuersRegistryManager.remove(_owner);
        string memory _role = 'IssuersRegistryManager';
        emit RoleRemoved(_owner, _role);
    }

    /// @dev TokenInfoManager Role _tokenInfoManager

    function isTokenInfoManager(address _owner) public view returns (bool) {
        return _tokenInfoManager.has(_owner);
    }

    function addTokenInfoManager(address _owner) external onlyAdmin {
        _tokenInfoManager.add(_owner);
        string memory _role = 'TokenInfoManager';
        emit RoleAdded(_owner, _role);
    }

    function removeTokenInfoManager(address _owner) external onlyAdmin {
        _tokenInfoManager.remove(_owner);
        string memory _role = 'TokenInfoManager';
        emit RoleRemoved(_owner, _role);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../../Roles.sol';

contract OwnerRolesUpgradeable is OwnableUpgradeable

 {
    using Roles for Roles.Role;

    event RoleAdded(address indexed _owner, string _role);
    event RoleRemoved(address indexed _owner, string _role);

    Roles.Role private _ownerAdmin;
    Roles.Role private _registryAddressSetter;
    Roles.Role private _complianceSetter;
    Roles.Role private _claimRegistryManager;
    Roles.Role private _issuersRegistryManager;
    Roles.Role private _tokenInfoManager;

    modifier onlyAdmin() {
        require(owner() == msg.sender || isOwnerAdmin(_msgSender()), 'Role: Sender is NOT Admin');
        _;
    }

    /// @dev OwnerAdmin Role _ownerAdmin

    function isOwnerAdmin(address _owner) public view returns (bool) {
        return _ownerAdmin.has(_owner);
    }

    function addOwnerAdmin(address _owner) external onlyAdmin {
        _ownerAdmin.add(_owner);
        string memory _role = 'OwnerAdmin';
        emit RoleAdded(_owner, _role);
    }

    function removeOwnerAdmin(address _owner) external onlyAdmin {
        _ownerAdmin.remove(_owner);
        string memory _role = 'OwnerAdmin';
        emit RoleRemoved(_owner, _role);
    }

    /// @dev RegistryAddressSetter Role _registryAddressSetter

    function isRegistryAddressSetter(address _owner) public view returns (bool) {
        return _registryAddressSetter.has(_owner);
    }

    function addRegistryAddressSetter(address _owner) external onlyAdmin {
        _registryAddressSetter.add(_owner);
        string memory _role = 'RegistryAddressSetter';
        emit RoleAdded(_owner, _role);
    }

    function removeRegistryAddressSetter(address _owner) external onlyAdmin {
        _registryAddressSetter.remove(_owner);
        string memory _role = 'RegistryAddressSetter';
        emit RoleRemoved(_owner, _role);
    }

    /// @dev ComplianceSetter Role _complianceSetter

    function isComplianceSetter(address _owner) public view returns (bool) {
        return _complianceSetter.has(_owner);
    }

    function addComplianceSetter(address _owner) external onlyAdmin {
        _complianceSetter.add(_owner);
        string memory _role = 'ComplianceSetter';
        emit RoleAdded(_owner, _role);
    }

    function removeComplianceSetter(address _owner) external onlyAdmin {
        _complianceSetter.remove(_owner);
        string memory _role = 'ComplianceSetter';
        emit RoleRemoved(_owner, _role);
    }

    /// @dev ClaimRegistryManager Role _claimRegistryManager

    function isClaimRegistryManager(address _owner) public view returns (bool) {
        return _claimRegistryManager.has(_owner);
    }

    function addClaimRegistryManager(address _owner) external onlyAdmin {
        _claimRegistryManager.add(_owner);
        string memory _role = 'ClaimRegistryManager';
        emit RoleAdded(_owner, _role);
    }

    function removeClaimRegistryManager(address _owner) external onlyAdmin {
        _claimRegistryManager.remove(_owner);
        string memory _role = 'ClaimRegistryManager';
        emit RoleRemoved(_owner, _role);
    }

    /// @dev IssuersRegistryManager Role _issuersRegistryManager

    function isIssuersRegistryManager(address _owner) public view returns (bool) {
        return _issuersRegistryManager.has(_owner);
    }

    function addIssuersRegistryManager(address _owner) external onlyAdmin {
        _issuersRegistryManager.add(_owner);
        string memory _role = 'IssuersRegistryManager';
        emit RoleAdded(_owner, _role);
    }

    function removeIssuersRegistryManager(address _owner) external onlyAdmin {
        _issuersRegistryManager.remove(_owner);
        string memory _role = 'IssuersRegistryManager';
        emit RoleRemoved(_owner, _role);
    }

    /// @dev TokenInfoManager Role _tokenInfoManager

    function isTokenInfoManager(address _owner) public view returns (bool) {
        return _tokenInfoManager.has(_owner);
    }

    function addTokenInfoManager(address _owner) external onlyAdmin {
        _tokenInfoManager.add(_owner);
        string memory _role = 'TokenInfoManager';
        emit RoleAdded(_owner, _role);
    }

    function removeTokenInfoManager(address _owner) external onlyAdmin {
        _tokenInfoManager.remove(_owner);
        string memory _role = 'TokenInfoManager';
        emit RoleRemoved(_owner, _role);
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), 'Roles: account already has role');
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), 'Roles: account does not have role');
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), 'Roles: account is the zero address');
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import '../registry/interface/IIdentityRegistry.sol';
import '../compliance/modular/IModularCompliance.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @dev interface
interface IToken is IERC20 {
    /**
     *  this event is emitted when the token information is updated.
     *  the event is emitted by the token constructor and by the setTokenInformation function
     *  `_newName` is the name of the token
     *  `_newSymbol` is the symbol of the token
     *  `_newDecimals` is the decimals of the token
     *  `_newVersion` is the version of the token, current version is 3.0
     *  `_newOnchainID` is the address of the onchainID of the token
     */
    event UpdatedTokenInformation(string _newName, string _newSymbol, uint8 _newDecimals, string _newVersion, address _newOnchainID);

    /**
     *  this event is emitted when the IdentityRegistry has been set for the token
     *  the event is emitted by the token constructor and by the setIdentityRegistry function
     *  `_identityRegistry` is the address of the Identity Registry of the token
     */
    event IdentityRegistryAdded(address indexed _identityRegistry);

    /**
     *  this event is emitted when the Compliance has been set for the token
     *  the event is emitted by the token constructor and by the setCompliance function
     *  `_compliance` is the address of the Compliance contract of the token
     */
    event ComplianceAdded(address indexed _compliance);

    /**
     *  this event is emitted when an investor successfully recovers his tokens
     *  the event is emitted by the recoveryAddress function
     *  `_lostWallet` is the address of the wallet that the investor lost access to
     *  `_newWallet` is the address of the wallet that the investor provided for the recovery
     *  `_investorOnchainID` is the address of the onchainID of the investor who asked for a recovery
     */
    event RecoverySuccess(address _lostWallet, address _newWallet, address _investorOnchainID);

    /**
     *  this event is emitted when the wallet of an investor is frozen or unfrozen
     *  the event is emitted by setAddressFrozen and batchSetAddressFrozen functions
     *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `_isFrozen` is the freezing status of the wallet
     *  if `_isFrozen` equals `true` the wallet is frozen after emission of the event
     *  if `_isFrozen` equals `false` the wallet is unfrozen after emission of the event
     *  `_owner` is the address of the agent who called the function to freeze the wallet
     */
    event AddressFrozen(address indexed _userAddress, bool indexed _isFrozen, address indexed _owner);

    /**
     *  this event is emitted when a certain amount of tokens is frozen on a wallet
     *  the event is emitted by freezePartialTokens and batchFreezePartialTokens functions
     *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `_amount` is the amount of tokens that are frozen
     */
    event TokensFrozen(address indexed _userAddress, uint256 _amount);

    /**
     *  this event is emitted when a certain amount of tokens is unfrozen on a wallet
     *  the event is emitted by unfreezePartialTokens and batchUnfreezePartialTokens functions
     *  `_userAddress` is the wallet of the investor that is concerned by the freezing status
     *  `_amount` is the amount of tokens that are unfrozen
     */
    event TokensUnfrozen(address indexed _userAddress, uint256 _amount);

    /**
     *  this event is emitted when the token is paused
     *  the event is emitted by the pause function
     *  `_userAddress` is the address of the wallet that called the pause function
     */
    event Paused(address _userAddress);

    /**
     *  this event is emitted when the token is unpaused
     *  the event is emitted by the unpause function
     *  `_userAddress` is the address of the wallet that called the unpause function
     */
    event Unpaused(address _userAddress);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 1 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * balanceOf() and transfer().
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the address of the onchainID of the token.
     * the onchainID of the token gives all the information available
     * about the token and is managed by the token issuer or his agent.
     */
    function onchainID() external view returns (address);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the TREX version of the token.
     * current version is 3.0.0
     */
    function version() external view returns (string memory);

    /**
     *  @dev Returns the Identity Registry linked to the token
     */
    function identityRegistry() external view returns (IIdentityRegistry);

    /**
     *  @dev Returns the Compliance contract linked to the token
     */
    function compliance() external view returns (IModularCompliance);

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    /**
     *  @dev Returns the freezing status of a wallet
     *  if isFrozen returns `true` the wallet is frozen
     *  if isFrozen returns `false` the wallet is not frozen
     *  isFrozen returning `true` doesn't mean that the balance is free, tokens could be blocked by
     *  a partial freeze or the whole token could be blocked by pause
     *  @param _userAddress the address of the wallet on which isFrozen is called
     */
    function isFrozen(address _userAddress) external view returns (bool);

    /**
     *  @dev Returns the amount of tokens that are partially frozen on a wallet
     *  the amount of frozen tokens is always <= to the total balance of the wallet
     *  @param _userAddress the address of the wallet on which getFrozenTokens is called
     */
    function getFrozenTokens(address _userAddress) external view returns (uint256);

    /**
     *  @dev sets the token name
     *  @param _name the name of token to set
     *  Only the owner of the token smart contract can call this function
     *  emits a `UpdatedTokenInformation` event
     */
    function setName(string calldata _name) external;

    /**
     *  @dev sets the token symbol
     *  @param _symbol the token symbol to set
     *  Only the owner of the token smart contract can call this function
     *  emits a `UpdatedTokenInformation` event
     */
    function setSymbol(string calldata _symbol) external;

    /**
     *  @dev sets the onchain ID of the token
     *  @param _onchainID the address of the onchain ID to set
     *  Only the owner of the token smart contract can call this function
     *  emits a `UpdatedTokenInformation` event
     */
    function setOnchainID(address _onchainID) external;

    /**
     *  @dev pauses the token contract, when contract is paused investors cannot transfer tokens anymore
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `Paused` event
     */
    function pause() external;

    /**
     *  @dev unpauses the token contract, when contract is unpaused investors can transfer tokens
     *  if their wallet is not blocked & if the amount to transfer is <= to the amount of free tokens
     *  This function can only be called by a wallet set as agent of the token
     *  emits an `Unpaused` event
     */
    function unpause() external;

    /**
     *  @dev sets an address frozen status for this token.
     *  @param _userAddress The address for which to update frozen status
     *  @param _freeze Frozen status of the address
     *  This function can only be called by a wallet set as agent of the token
     *  emits an `AddressFrozen` event
     */
    function setAddressFrozen(address _userAddress, bool _freeze) external;

    /**
     *  @dev freezes token amount specified for given address.
     *  @param _userAddress The address for which to update frozen tokens
     *  @param _amount Amount of Tokens to be frozen
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `TokensFrozen` event
     */
    function freezePartialTokens(address _userAddress, uint256 _amount) external;

    /**
     *  @dev unfreezes token amount specified for given address
     *  @param _userAddress The address for which to update frozen tokens
     *  @param _amount Amount of Tokens to be unfrozen
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `TokensUnfrozen` event
     */
    function unfreezePartialTokens(address _userAddress, uint256 _amount) external;

    /**
     *  @dev sets the Identity Registry for the token
     *  @param _identityRegistry the address of the Identity Registry to set
     *  Only the owner of the token smart contract can call this function
     *  emits an `IdentityRegistryAdded` event
     */
    function setIdentityRegistry(address _identityRegistry) external;

    /**
     *  @dev sets the compliance contract of the token
     *  @param _compliance the address of the compliance contract to set
     *  Only the owner of the token smart contract can call this function
     *  calls bindToken on the compliance contract
     *  emits a `ComplianceAdded` event
     */
    function setCompliance(address _compliance) external;

    /**
     *  @dev force a transfer of tokens between 2 whitelisted wallets
     *  In case the `from` address has not enough free tokens (unfrozen tokens)
     *  but has a total balance higher or equal to the `amount`
     *  the amount of frozen tokens is reduced in order to have enough free tokens
     *  to proceed the transfer, in such a case, the remaining balance on the `from`
     *  account is 100% composed of frozen tokens post-transfer.
     *  Require that the `to` address is a verified address,
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The number of tokens to transfer
     *  @return `true` if successful and revert if unsuccessful
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `TokensUnfrozen` event if `_amount` is higher than the free balance of `_from`
     *  emits a `Transfer` event
     */
    function forcedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    /**
     *  @dev mint tokens on a wallet
     *  Improved version of default mint method. Tokens can be minted
     *  to an address if only it is a verified address as per the security token.
     *  @param _to Address to mint the tokens to.
     *  @param _amount Amount of tokens to mint.
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `Transfer` event
     */
    function mint(address _to, uint256 _amount) external;

    /**
     *  @dev burn tokens on a wallet
     *  In case the `account` address has not enough free tokens (unfrozen tokens)
     *  but has a total balance higher or equal to the `value` amount
     *  the amount of frozen tokens is reduced in order to have enough free tokens
     *  to proceed the burn, in such a case, the remaining balance on the `account`
     *  is 100% composed of frozen tokens post-transaction.
     *  @param _userAddress Address to burn the tokens from.
     *  @param _amount Amount of tokens to burn.
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `TokensUnfrozen` event if `_amount` is higher than the free balance of `_userAddress`
     *  emits a `Transfer` event
     */
    function burn(address _userAddress, uint256 _amount) external;

    /**
     *  @dev recovery function used to force transfer tokens from a
     *  lost wallet to a new wallet for an investor.
     *  @param _lostWallet the wallet that the investor lost
     *  @param _newWallet the newly provided wallet on which tokens have to be transferred
     *  @param _investorOnchainID the onchainID of the investor asking for a recovery
     *  This function can only be called by a wallet set as agent of the token
     *  emits a `TokensUnfrozen` event if there is some frozen tokens on the lost wallet if the recovery process is successful
     *  emits a `Transfer` event if the recovery process is successful
     *  emits a `RecoverySuccess` event if the recovery process is successful
     *  emits a `RecoveryFails` event if the recovery process fails
     */
    function recoveryAddress(
        address _lostWallet,
        address _newWallet,
        address _investorOnchainID
    ) external returns (bool);

    /**
     *  @dev function allowing to issue transfers in batch
     *  Require that the msg.sender and `to` addresses are not frozen.
     *  Require that the total value should not exceed available balance.
     *  Require that the `to` addresses are all verified addresses,
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_toList.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _toList The addresses of the receivers
     *  @param _amounts The number of tokens to transfer to the corresponding receiver
     *  emits _toList.length `Transfer` events
     */
    function batchTransfer(address[] calldata _toList, uint256[] calldata _amounts) external;

    /**
     *  @dev function allowing to issue forced transfers in batch
     *  Require that `_amounts[i]` should not exceed available balance of `_fromList[i]`.
     *  Require that the `_toList` addresses are all verified addresses
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_fromList.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _fromList The addresses of the senders
     *  @param _toList The addresses of the receivers
     *  @param _amounts The number of tokens to transfer to the corresponding receiver
     *  This function can only be called by a wallet set as agent of the token
     *  emits `TokensUnfrozen` events if `_amounts[i]` is higher than the free balance of `_fromList[i]`
     *  emits _fromList.length `Transfer` events
     */
    function batchForcedTransfer(
        address[] calldata _fromList,
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external;

    /**
     *  @dev function allowing to mint tokens in batch
     *  Require that the `_toList` addresses are all verified addresses
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_toList.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _toList The addresses of the receivers
     *  @param _amounts The number of tokens to mint to the corresponding receiver
     *  This function can only be called by a wallet set as agent of the token
     *  emits _toList.length `Transfer` events
     */
    function batchMint(address[] calldata _toList, uint256[] calldata _amounts) external;

    /**
     *  @dev function allowing to burn tokens in batch
     *  Require that the `_userAddresses` addresses are all verified addresses
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _userAddresses The addresses of the wallets concerned by the burn
     *  @param _amounts The number of tokens to burn from the corresponding wallets
     *  This function can only be called by a wallet set as agent of the token
     *  emits _userAddresses.length `Transfer` events
     */
    function batchBurn(address[] calldata _userAddresses, uint256[] calldata _amounts) external;

    /**
     *  @dev function allowing to set frozen addresses in batch
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _userAddresses The addresses for which to update frozen status
     *  @param _freeze Frozen status of the corresponding address
     *  This function can only be called by a wallet set as agent of the token
     *  emits _userAddresses.length `AddressFrozen` events
     */
    function batchSetAddressFrozen(address[] calldata _userAddresses, bool[] calldata _freeze) external;

    /**
     *  @dev function allowing to freeze tokens partially in batch
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _userAddresses The addresses on which tokens need to be frozen
     *  @param _amounts the amount of tokens to freeze on the corresponding address
     *  This function can only be called by a wallet set as agent of the token
     *  emits _userAddresses.length `TokensFrozen` events
     */
    function batchFreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external;

    /**
     *  @dev function allowing to unfreeze tokens partially in batch
     *  IMPORTANT : THIS TRANSACTION COULD EXCEED GAS LIMIT IF `_userAddresses.length` IS TOO HIGH,
     *  USE WITH CARE OR YOU COULD LOSE TX FEES WITH AN "OUT OF GAS" TRANSACTION
     *  @param _userAddresses The addresses on which tokens need to be unfrozen
     *  @param _amounts the amount of tokens to unfreeze on the corresponding address
     *  This function can only be called by a wallet set as agent of the token
     *  emits _userAddresses.length `TokensUnfrozen` events
     */
    function batchUnfreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external;
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

import './IToken.sol';
import '@onchain-id/solidity/contracts/interface/IERC734.sol';
import '@onchain-id/solidity/contracts/interface/IERC735.sol';
import '@onchain-id/solidity/contracts/interface/IIdentity.sol';
import '../registry/interface/IClaimTopicsRegistry.sol';
import './TokenStorage.sol';
import '../roles/AgentRoleUpgradeable.sol';

contract Token is IToken, AgentRoleUpgradeable, TokenStorage {

    /**
     *  @dev the constructor initiates the token contract
     *  msg.sender is set automatically as the owner of the smart contract
     *  @param _identityRegistry the address of the Identity registry linked to the token
     *  @param _compliance the address of the compliance contract linked to the token
     *  @param _name the name of the token
     *  @param _symbol the symbol of the token
     *  @param _decimals the decimals of the token
     *  @param _onchainID the address of the onchainID of the token
     *  emits an `UpdatedTokenInformation` event
     *  emits an `IdentityRegistryAdded` event
     *  emits a `ComplianceAdded` event
     */
    function init(
        address _identityRegistry,
        address _compliance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _onchainID
    ) public initializer {
        __Ownable_init();
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        tokenOnchainID = _onchainID;
        tokenPaused = true;
        setIdentityRegistry(_identityRegistry);
        setCompliance(_compliance);
        emit UpdatedTokenInformation(tokenName, tokenSymbol, tokenDecimals, TOKEN_VERSION, tokenOnchainID);
    }

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(!tokenPaused, 'Pausable: paused');
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(tokenPaused, 'Pausable: not paused');
        _;
    }

    /**
     *  @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     *  @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address _userAddress) public view override returns (uint256) {
        return _balances[_userAddress];
    }

    /**
     *  @dev See {IERC20-allowance}.
     */
    function allowance(address _owner, address _spender) external view virtual override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    /**
     *  @dev See {IERC20-approve}.
     */
    function approve(address _spender, uint256 _amount) external virtual override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /**
     *  @dev See {ERC20-increaseAllowance}.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) external virtual returns (bool) {
        _approve(msg.sender, _spender, _allowances[msg.sender][_spender] + (_addedValue));
        return true;
    }

    /**
     *  @dev See {ERC20-decreaseAllowance}.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external virtual returns (bool) {
        _approve(msg.sender, _spender, _allowances[msg.sender][_spender] - _subtractedValue);
        return true;
    }

    /**
     *  @dev See {ERC20-_mint}.
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {
        require(_from != address(0), 'ERC20: transfer from the zero address');
        require(_to != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(_from, _to, _amount);

        _balances[_from] = _balances[_from] - _amount;
        _balances[_to] = _balances[_to] + _amount;
        emit Transfer(_from, _to, _amount);
    }

    /**
     *  @dev See {ERC20-_mint}.
     */
    function _mint(address _userAddress, uint256 _amount) internal virtual {
        require(_userAddress != address(0), 'ERC20: mint to the zero address');

        _beforeTokenTransfer(address(0), _userAddress, _amount);

        _totalSupply = _totalSupply + _amount;
        _balances[_userAddress] = _balances[_userAddress] + _amount;
        emit Transfer(address(0), _userAddress, _amount);
    }

    /**
     *  @dev See {ERC20-_burn}.
     */
    function _burn(address _userAddress, uint256 _amount) internal virtual {
        require(_userAddress != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(_userAddress, address(0), _amount);

        _balances[_userAddress] = _balances[_userAddress] - _amount;
        _totalSupply = _totalSupply - _amount;
        emit Transfer(_userAddress, address(0), _amount);
    }

    /**
     *  @dev See {ERC20-_approve}.
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_owner != address(0), 'ERC20: approve from the zero address');
        require(_spender != address(0), 'ERC20: approve to the zero address');

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     *  @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {}

    /**
     *  @dev See {IToken-decimals}.
     */
    function decimals() external view override returns (uint8) {
        return tokenDecimals;
    }

    /**
     *  @dev See {IToken-name}.
     */
    function name() external view override returns (string memory) {
        return tokenName;
    }

    /**
     *  @dev See {IToken-onchainID}.
     */
    function onchainID() external view override returns (address) {
        return tokenOnchainID;
    }

    /**
     *  @dev See {IToken-symbol}.
     */
    function symbol() external view override returns (string memory) {
        return tokenSymbol;
    }

    /**
     *  @dev See {IToken-version}.
     */
    function version() external view override returns (string memory) {
        return TOKEN_VERSION;
    }

    /**
     *  @dev See {IToken-setName}.
     */
    function setName(string calldata _name) external override onlyOwner {
        tokenName = _name;
        emit UpdatedTokenInformation(tokenName, tokenSymbol, tokenDecimals, TOKEN_VERSION, tokenOnchainID);
    }

    /**
     *  @dev See {IToken-setSymbol}.
     */
    function setSymbol(string calldata _symbol) external override onlyOwner {
        tokenSymbol = _symbol;
        emit UpdatedTokenInformation(tokenName, tokenSymbol, tokenDecimals, TOKEN_VERSION, tokenOnchainID);
    }

    /**
     *  @dev See {IToken-setOnchainID}.
     */
    function setOnchainID(address _onchainID) external override onlyOwner {
        tokenOnchainID = _onchainID;
        emit UpdatedTokenInformation(tokenName, tokenSymbol, tokenDecimals, TOKEN_VERSION, tokenOnchainID);
    }

    /**
     *  @dev See {IToken-paused}.
     */
    function paused() external view override returns (bool) {
        return tokenPaused;
    }

    /**
     *  @dev See {IToken-isFrozen}.
     */
    function isFrozen(address _userAddress) external view override returns (bool) {
        return frozen[_userAddress];
    }

    /**
     *  @dev See {IToken-getFrozenTokens}.
     */
    function getFrozenTokens(address _userAddress) external view override returns (uint256) {
        return frozenTokens[_userAddress];
    }

    /**
     *  @notice ERC-20 overridden function that include logic to check for trade validity.
     *  Require that the msg.sender and to addresses are not frozen.
     *  Require that the value should not exceed available balance .
     *  Require that the to address is a verified address
     *  @param _to The address of the receiver
     *  @param _amount The number of tokens to transfer
     *  @return `true` if successful and revert if unsuccessful
     */
    function transfer(address _to, uint256 _amount) public override whenNotPaused returns (bool) {
        require(!frozen[_to] && !frozen[msg.sender], 'wallet is frozen');
        require(_amount <= balanceOf(msg.sender) - (frozenTokens[msg.sender]), 'Insufficient Balance');
        if (tokenIdentityRegistry.isVerified(_to) && tokenCompliance.canTransfer(msg.sender, _to, _amount)) {
            tokenCompliance.transferred(msg.sender, _to, _amount);
            _transfer(msg.sender, _to, _amount);
            return true;
        }
        revert('Transfer not possible');
    }

    /**
     *  @dev See {IToken-pause}.
     */
    function pause() external override onlyAgent whenNotPaused {
        tokenPaused = true;
        emit Paused(msg.sender);
    }

    /**
     *  @dev See {IToken-unpause}.
     */
    function unpause() external override onlyAgent whenPaused {
        tokenPaused = false;
        emit Unpaused(msg.sender);
    }

    /**
     *  @dev See {IToken-identityRegistry}.
     */
    function identityRegistry() external view override returns (IIdentityRegistry) {
        return tokenIdentityRegistry;
    }

    /**
     *  @dev See {IToken-compliance}.
     */
    function compliance() external view override returns (IModularCompliance) {
        return tokenCompliance;
    }

    /**
     *  @dev See {IToken-batchTransfer}.
     */
    function batchTransfer(address[] calldata _toList, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _toList.length; i++) {
            transfer(_toList[i], _amounts[i]);
        }
    }

    /**
     *  @notice ERC-20 overridden function that include logic to check for trade validity.
     *  Require that the from and to addresses are not frozen.
     *  Require that the value should not exceed available balance .
     *  Require that the to address is a verified address
     *  @param _from The address of the sender
     *  @param _to The address of the receiver
     *  @param _amount The number of tokens to transfer
     *  @return `true` if successful and revert if unsuccessful
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external override whenNotPaused returns (bool) {
        require(!frozen[_to] && !frozen[_from], 'wallet is frozen');
        require(_amount <= balanceOf(_from) - (frozenTokens[_from]), 'Insufficient Balance');
        if (tokenIdentityRegistry.isVerified(_to) && tokenCompliance.canTransfer(_from, _to, _amount)) {
            tokenCompliance.transferred(_from, _to, _amount);
            _transfer(_from, _to, _amount);
            _approve(_from, msg.sender, _allowances[_from][msg.sender] - (_amount));
            return true;
        }

        revert('Transfer not possible');
    }

    /**
     *  @dev See {IToken-forcedTransfer}.
     */
    function forcedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) public override onlyAgent returns (bool) {
        uint256 freeBalance = balanceOf(_from) - (frozenTokens[_from]);
        if (_amount > freeBalance) {
            uint256 tokensToUnfreeze = _amount - (freeBalance);
            frozenTokens[_from] = frozenTokens[_from] - (tokensToUnfreeze);
            emit TokensUnfrozen(_from, tokensToUnfreeze);
        }
        if (tokenIdentityRegistry.isVerified(_to)) {
            _transfer(_from, _to, _amount);
            tokenCompliance.transferred(_from, _to, _amount);
            return true;
        }
        revert('Transfer not possible');
    }

    /**
     *  @dev See {IToken-batchForcedTransfer}.
     */
    function batchForcedTransfer(
        address[] calldata _fromList,
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external override {
        for (uint256 i = 0; i < _fromList.length; i++) {
            forcedTransfer(_fromList[i], _toList[i], _amounts[i]);
        }
    }

    /**
     *  @dev See {IToken-mint}.
     */
    function mint(address _to, uint256 _amount) public override onlyAgent {
        require(tokenIdentityRegistry.isVerified(_to), 'Identity is not verified.');
        require(tokenCompliance.canTransfer(address(0), _to, _amount), 'Compliance not followed');
        _mint(_to, _amount);
        tokenCompliance.created(_to, _amount);
    }

    /**
     *  @dev See {IToken-batchMint}.
     */
    function batchMint(address[] calldata _toList, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _toList.length; i++) {
            mint(_toList[i], _amounts[i]);
        }
    }

    /**
     *  @dev See {IToken-burn}.
     */
    function burn(address _userAddress, uint256 _amount) public override onlyAgent {
        uint256 freeBalance = balanceOf(_userAddress) - frozenTokens[_userAddress];
        if (_amount > freeBalance) {
            uint256 tokensToUnfreeze = _amount - (freeBalance);
            frozenTokens[_userAddress] = frozenTokens[_userAddress] - (tokensToUnfreeze);
            emit TokensUnfrozen(_userAddress, tokensToUnfreeze);
        }
        _burn(_userAddress, _amount);
        tokenCompliance.destroyed(_userAddress, _amount);
    }

    /**
     *  @dev See {IToken-batchBurn}.
     */
    function batchBurn(address[] calldata _userAddresses, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            burn(_userAddresses[i], _amounts[i]);
        }
    }

    /**
     *  @dev See {IToken-setAddressFrozen}.
     */
    function setAddressFrozen(address _userAddress, bool _freeze) public override onlyAgent {
        frozen[_userAddress] = _freeze;

        emit AddressFrozen(_userAddress, _freeze, msg.sender);
    }

    /**
     *  @dev See {IToken-batchSetAddressFrozen}.
     */
    function batchSetAddressFrozen(address[] calldata _userAddresses, bool[] calldata _freeze) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            setAddressFrozen(_userAddresses[i], _freeze[i]);
        }
    }

    /**
     *  @dev See {IToken-freezePartialTokens}.
     */
    function freezePartialTokens(address _userAddress, uint256 _amount) public override onlyAgent {
        uint256 balance = balanceOf(_userAddress);
        require(balance >= frozenTokens[_userAddress] + _amount, 'Amount exceeds available balance');
        frozenTokens[_userAddress] = frozenTokens[_userAddress] + (_amount);
        emit TokensFrozen(_userAddress, _amount);
    }

    /**
     *  @dev See {IToken-batchFreezePartialTokens}.
     */
    function batchFreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            freezePartialTokens(_userAddresses[i], _amounts[i]);
        }
    }

    /**
     *  @dev See {IToken-unfreezePartialTokens}.
     */
    function unfreezePartialTokens(address _userAddress, uint256 _amount) public override onlyAgent {
        require(frozenTokens[_userAddress] >= _amount, 'Amount should be less than or equal to frozen tokens');
        frozenTokens[_userAddress] = frozenTokens[_userAddress] - (_amount);
        emit TokensUnfrozen(_userAddress, _amount);
    }

    /**
     *  @dev See {IToken-batchUnfreezePartialTokens}.
     */
    function batchUnfreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external override {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            unfreezePartialTokens(_userAddresses[i], _amounts[i]);
        }
    }

    /**
     *  @dev See {IToken-setIdentityRegistry}.
     */
    function setIdentityRegistry(address _identityRegistry) public override onlyOwner {
        tokenIdentityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistryAdded(_identityRegistry);
    }

    /**
     *  @dev See {IToken-setCompliance}.
     */
    function setCompliance(address _compliance) public override onlyOwner {
        if (address(tokenCompliance) != address(0)) {
            tokenCompliance.unbindToken(address(this));
        }
        tokenCompliance = IModularCompliance(_compliance);
        tokenCompliance.bindToken(address(this));
        emit ComplianceAdded(_compliance);
    }

    /**
     *  @dev See {IToken-recoveryAddress}.
     */
    function recoveryAddress(
        address _lostWallet,
        address _newWallet,
        address _investorOnchainID
    ) external override onlyAgent returns (bool) {
        require(balanceOf(_lostWallet) != 0, 'no tokens to recover');
        IIdentity _onchainID = IIdentity(_investorOnchainID);
        bytes32 _key = keccak256(abi.encode(_newWallet));
        if (_onchainID.keyHasPurpose(_key, 1)) {
            uint256 investorTokens = balanceOf(_lostWallet);
            uint256 _frozenTokens = frozenTokens[_lostWallet];
            tokenIdentityRegistry.registerIdentity(_newWallet, _onchainID, tokenIdentityRegistry.investorCountry(_lostWallet));
            tokenIdentityRegistry.deleteIdentity(_lostWallet);
            forcedTransfer(_lostWallet, _newWallet, investorTokens);
            if (_frozenTokens > 0) {
                freezePartialTokens(_newWallet, _frozenTokens);
            }
            if (frozen[_lostWallet] == true) {
                setAddressFrozen(_newWallet, true);
            }
            emit RecoverySuccess(_lostWallet, _newWallet, _investorOnchainID);
            return true;
        }
        revert('Recovery not possible');
    }
}

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//

/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2022, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;
import '../compliance/modular/IModularCompliance.sol';
import '../registry/interface/IIdentityRegistry.sol';

contract TokenStorage {
    /// @dev ERC20 basic variables
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;

    /// @dev Token information
    string internal tokenName;
    string internal tokenSymbol;
    uint8 internal tokenDecimals;
    address internal tokenOnchainID;
    string internal constant TOKEN_VERSION = '4.0.0';

    /// @dev Variables of freeze and pause functions
    mapping(address => bool) internal frozen;
    mapping(address => uint256) internal frozenTokens;

    bool internal tokenPaused = false;

    /// @dev Identity Registry contract used by the onchain validator system
    IIdentityRegistry internal tokenIdentityRegistry;

    /// @dev Compliance contract linked to the onchain validator system
    IModularCompliance internal tokenCompliance;
}