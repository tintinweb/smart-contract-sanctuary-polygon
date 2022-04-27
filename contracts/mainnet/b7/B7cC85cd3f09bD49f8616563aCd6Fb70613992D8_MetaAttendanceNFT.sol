// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "../../../utils/BitTools.sol";
// import "../../../core/facets/restrictions/TransferRestriction.sol";
import "../../generic/tokens/ERC721EnumerableAutoIdPropertyManager.sol";

contract MetaAttendanceNFT is ERC721EnumerableAutoIdPropertyManager, BaseRelayRecipient, AccessControlUpgradeable, UUPSUpgradeable {
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;
    using BitTools for BitTools.BitMap;

    event EventAdded(uint256 eid);
    bytes32 public constant EVENT_MANAGER_ROLE = keccak256("EVENT_MANAGER_ROLE");

    struct Session {
        uint256 start;      //Timestamp of session start (Since this timestamp users can register their attendance)
        uint256 length;     //length of the session in seconds. (After start+length timestamp users can not register their attendance)
    }
    
    struct Event {
        Session[] sessions; //Array of sessions in the event     
        string baseURI;     //Base URI for this event
        address signer;     //Address which signs the attendance requests (can be zero if signature verification is not required)
    }

    struct TokenData {
        uint256 eventId;                    // Id of the event this token is issued for
        BitTools.BitMap bitmap;             // BitMap of atended sessions
    }

    string public contractURI;                                  // Stores contract-level metadata
    Event[] public events;                                      // Stores events data 
    mapping(uint248 => TokenData) private data;                 // Stores token data
    mapping(uint256 => mapping(uint256 => uint248)) private eventToTid; // Stores mapping of event id to a token for users (separate for each MetaNFT id)
    IMetaNFT private metaNFT;

    constructor() initializer {
    }

    function initialize(string calldata name_, string calldata symbol_, bytes32 property_, address metaNFT_, address trustedForwarder) external initializer {
        __MetaAttendanceNFT_init(name_, symbol_, property_, metaNFT_, trustedForwarder);
    }

    function __MetaAttendanceNFT_init(string memory name_, string memory symbol_, bytes32 property_, address metaNFT_, address trustedForwarder) internal onlyInitializing {
        __UUPSUpgradeable_init_unchained();
        __ERC721EnumerableAutoIdPropertyManager_init(name_, symbol_, property_);
        __MetaAttendanceNFT_init_unchained(metaNFT_, trustedForwarder);
    }

    function __MetaAttendanceNFT_init_unchained(address metaNFT_, address trustedForwarder) internal onlyInitializing  {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EVENT_MANAGER_ROLE, _msgSender());
        _setTrustedForwarder(trustedForwarder);
        metaNFT = IMetaNFT(metaNFT_);
    }

    function versionRecipient() external override virtual view returns (string memory) { // retuired by IRelayRecipient
        return "1.0";
    }

    function setContractURI(string calldata _contractURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _contractURI;
    }

    function addEvent(Session[] calldata sessions, string calldata baseURI, address signer) external onlyRole(EVENT_MANAGER_ROLE) returns(uint256) {
        require(sessions.length <= 0xff, "too many sessions");
        uint256 eid = events.length;
        Event storage p = events.push();
        p.baseURI = baseURI;
        p.signer = signer;
        for(uint256 i=0; i < sessions.length; i++){
            p.sessions.push(sessions[i]);
        }
        emit EventAdded(eid);
        return eid;
    }

    function addSession(uint256 eid, Session calldata session) external onlyRole(EVENT_MANAGER_ROLE) {
        require(eid < events.length, "wrong eid");
        Event storage evt = events[eid];
        require(evt.sessions.length < 0xff, "too many sessions");
        evt.sessions.push(session);
    }

    function setEventURI(uint256 eid, string calldata baseURI) external onlyRole(EVENT_MANAGER_ROLE) {
         Event storage evt = events[eid];
         evt.baseURI = baseURI;
    }

    function setSigner(uint256 eid, address signer) external onlyRole(EVENT_MANAGER_ROLE) {
         Event storage evt = events[eid];
         evt.signer = signer;
    }

    function changeSession(uint256 eid, uint256 sid, uint256 start, uint256 length) external onlyRole(EVENT_MANAGER_ROLE) {
        require(eid < events.length, "wrong eid");
        Event storage evt = events[eid];
        require(sid < evt.sessions.length, "wrong sid");
        evt.sessions[eid].start = start;
        evt.sessions[eid].length = length;
    }

    /**
     * @notice Attend to a selected event
     * @param eid Id of the event
     * @param sid Id of the session
     * @param signature Signature of the keccak256(abi.encode(eid, sid, msg.sender))
     * @return token id used for this session
     */
    function attend(uint256 eid, uint8 sid, bytes calldata  signature) external returns(uint256) {
        require(eid < events.length, "wrong eid");
        Event storage evt = events[eid];
        
        if(evt.signer != address(0)){
            address signer = keccak256(abi.encode(eid, sid, _msgSender())).recover(signature);
            require(signer == evt.signer);
        }
        
        return _attend(eid, sid, _msgSender());
    }

    function attendAs(address account, uint256 eid, uint8 sid) external onlyRole(EVENT_MANAGER_ROLE) returns(uint256) {
        require(eid < events.length, "wrong eid");
        return _attend(eid, sid, account);
    }

    function attended(uint256 eid, uint8 sid, address account) public view returns(bool) {
        require(eid < events.length, "wrong eid");
        Event storage evt = events[eid];
        require(sid < evt.sessions.length, "wrong sid");

        
        uint248 tid = _getTidForEvent(eid, account);
        if(tid == 0) return false;
        return data[tid].bitmap.get(sid);
    }

    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        uint248 tid = _uint2562uint248(tokenId);
        TokenData storage td = data[tid];
        Event storage evt = events[td.eventId];
        uint256 metadataId = td.bitmap.asUint();
        return string(abi.encodePacked(evt.baseURI, metadataId.toString()));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC721EnumerableAutoIdPropertyManager) returns (bool) {
        return AccessControlUpgradeable.supportsInterface(interfaceId) || ERC721EnumerableAutoIdPropertyManager.supportsInterface(interfaceId);
    }

    function _attend(uint256 eid, uint8 sid, address account) internal returns(uint248 tid){
        require(eid < events.length, "wrong eid");
        Event storage evt = events[eid];
        require(sid < evt.sessions.length, "wrong sid");
        Session storage ss = evt.sessions[sid];
        require(block.timestamp >= ss.start, "session not started");
        require(block.timestamp <= ss.start+ss.length, "session already finished");

        tid = _getOrMintTidForEvent(eid, account);
        data[tid].bitmap.set(sid);
    }

    function _getTidForEvent(uint256 eid, address account) internal view returns(uint248) {
        uint256 pid = _getMetaNFTId(account, property());
        if(pid == 0) return 0;
        return eventToTid[pid][eid];
    }

    function _getOrMintTidForEvent(uint256 eid, address account) internal returns(uint248) {
        uint256 pid = _getMetaNFTId(account, property());

        uint248 tid = _getTidForEvent(eid, account);
        if (tid > 0) {
            return tid;
        }

        tid = _mint(account);
        data[tid].eventId = eid;
        eventToTid[pid][eid] = tid;
        _MetaNFT().addRestriction(pid, property(), IMetaRestrictions.Restriction({
            rtype: keccak256("TransferRestriction"), //TransferRestriction.RTYPE
            data: bytes("")
        }));
        return tid;
    }

    function _beforeTokenTransfer(address from, address, uint248) internal virtual override {
        //Only allow minting
        require(from == address(0), "token is not transferrable");
    }

    function _MetaNFT() internal view virtual override returns(IMetaNFT) {
        return metaNFT;
    }

    function _authorizeUpgrade(address /*newImplementation*/) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
    }


    function _msgData() internal view virtual override(ContextUpgradeable, BaseRelayRecipient) returns (bytes calldata) {
        return BaseRelayRecipient._msgData();
    }

    function _msgSender() internal view virtual override(ContextUpgradeable, BaseRelayRecipient) returns (address sender) {
        return BaseRelayRecipient._msgSender();
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Library to manage a bitmap with 256 bits
 * Inspired by Openzeppelin's BitMaps
 */
library BitTools {

    struct BitMap {
        uint256 _data;
    }

    function asUint(BitMap storage bitmap) internal view returns(uint256) {
        return bitmap._data;
    }

    function get(BitMap storage bitmap, uint8 bit) internal view returns(bool) {
        uint256 mask = 1 << bit;
        return (bitmap._data & mask != 0);
    }

    function setTo(BitMap storage bitmap, uint8 bit, bool value) internal {
        if (value) {
            set(bitmap, bit);
        } else {
            unset(bitmap, bit);
        }
    }

    function set(BitMap storage bitmap, uint8 bit) internal {
        uint256 mask = 1 << bit;
        bitmap._data |= mask;
    }


    function unset(BitMap storage bitmap, uint8 bit) internal {
        uint256 mask = 1 << bit;
        bitmap._data &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "./ERC721PropertyManager.sol";

/**
 * @notice This version of ERC721PropertyManager implements IERC721Enumerable extension
 * @dev 
 */
abstract contract ERC721EnumerableAutoIdPropertyManager is ERC721PropertyManager, IERC721EnumerableUpgradeable {

    // Storing this localy to decrease gas usage
    uint248 private _mintCounter;


    function __ERC721EnumerableAutoIdPropertyManager_init(string memory name_, string memory symbol_, bytes32 property_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721PropertyManager_init_unchained(name_, symbol_, property_);
        __ERC721EnumerableAutoIdPropertyManager_init_unchained();
    }

    function __ERC721EnumerableAutoIdPropertyManager_init_unchained() internal onlyInitializing {

    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721PropertyManager) returns (bool) {
        return 
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256) {
        return _mintCounter;
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId) {
        uint256[] memory pids= _getAllMetaNFTIdsWithProperty(owner, property());
        if(pids.length == 0) return 0;
        uint256 totalCount;
        for(uint256 i=0; i<pids.length; i++){
            uint256 currentPidLength = _getDataSetLength(pids[i], property(), OWNED_TOKENS_PROPERTY_SET_KEY);
            if(totalCount+currentPidLength >= index) { // requested token is in this set
                bytes32[] memory tokensInPid = _getDataSetAllValues(pids[i], property(), OWNED_TOKENS_PROPERTY_SET_KEY);
                uint256 offset = index - totalCount;
                return uint256(_bytes322uint248(tokensInPid[offset]));
            }
            totalCount += currentPidLength;
        }
        return 0; //Should never happen, so return non-existing token
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external pure returns (uint256) {
        return index+1;
    }


    function _mint(address to) internal virtual returns(uint248) {
        uint248 newId = _generateTokenId();
        super._mint(to, newId);
        return newId;
    }

    function _mint(address to, uint248 tokenId) internal virtual override {
        uint248 newId = _generateTokenId();
        require(tokenId == newId, "wrong tokenId");
        super._mint(to, newId);
    }

    function _generateTokenId() internal virtual returns(uint248) {
        return ++_mintCounter;
    }


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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "../BasePropertyManager.sol";

/**
 * @title AllianceBlock ERC721 PropertyManager contract
 * @dev This contract is intended to implement OZ ERC721Upgradeable API
 * while storing data in a MetaNFT property
 * Based on https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC721/ERC721Upgradeable.sol
 * @dev Extends BasePropertyManager, IERC721Upgradeable, IERC721MetadataUpgradeable
 */
abstract contract ERC721PropertyManager is Initializable, ContextUpgradeable, ERC165Upgradeable, BasePropertyManager, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;


    /**
     * A key in Property's Set storage, to store token ids owned by this MetaNFT token
     * Uses a default partition 0x00
     */
    bytes32 internal constant OWNED_TOKENS_PROPERTY_SET_KEY  =  0x0000000000000000000000000000000000000000000000000000000000000001;

    /**
     * Used to partition a key space of the global bytes32 storage
     * Under this flag we store the mapping of erc721 token id "owned" by a specific MetaNFT
     * to that MetaNFT id
     */
    uint8 internal constant TOKEN_ID_MAP_GLOBAL_BYTES32_KEY_PARTITION = 0x01;

    /**
     * Used to partition a key space of the propertie's bytes32 storage
     * Under this flag we store the mapping of erc721 token id "owned" by a specific MetaNFT
     * to an approved spender
     */
    uint8 internal constant APPROVED_PROPERTY_BYTES32_KEY_PARTITION = 0x01;

    /**
     * Used to partition a key space of the propertie global Set storage
     * Under this flag we store the mapping of token owner to a set of approved operators
     */
    uint8 internal constant OPERATOR_GLOBAL_SET_KEY_PARTITION   = 0x02;



    string private _name;
    string private _symbol;
    bytes32 private _property;

    // Storing this localy to decrease gas usage
    mapping(uint248=>address) private _storedOwners;

    /**
     * @notice Internal Initialization function
     * @param name_ Name of the token
     * @param symbol_ Symbol of the token
     */
    function __ERC721PropertyManager_init(string memory name_, string memory symbol_, bytes32 property_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721PropertyManager_init_unchained(name_, symbol_, property_);
    }
    
    function __ERC721PropertyManager_init_unchained(string memory name_, string memory symbol_, bytes32 property_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _property = property_;
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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        uint248 tid = _uint2562uint248(tokenId);
        return _getOwnerOrRevert(tid);
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
        uint248 tid = _uint2562uint248(tokenId);
        require(_exists(tid), "ERC721Metadata: URI query for nonexistent token");

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
     * @notice Returns property to store data
     * Should not be overriden because property change may result in corrupted data
     */
    function property() public view returns(bytes32) {
        return _property;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        uint248 tid = _uint2562uint248(tokenId);
        address owner = _getOwnerOrRevert(tid);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tid);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        uint248 tid = _uint2562uint248(tokenId);
        require(_exists(tid), "ERC721: approved query for nonexistent token");

        return _getApproved(tid);
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
        return _isOperator(owner, operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint248 tid = _uint2562uint248(tokenId);
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tid), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tid);
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
        bytes memory _data
    ) public virtual override {
        uint248 tid = _uint2562uint248(tokenId);
        require(_isApprovedOrOwner(_msgSender(), tid), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tid, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        uint248 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint248 tokenId) internal view virtual returns (bool) {
        //require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = _getOwnerOrRevert(tokenId);
        _isApproved(tokenId, spender);
        return (spender == owner || _isOperator(owner, spender) || _getApproved(tokenId) == spender);
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
    function _safeMint(address to, uint248 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint248 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
    function _mint(address to, uint248 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _setOwner(tokenId, to);

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
    function _burn(uint248 tokenId) internal virtual {
        address owner = _getOwnerOrRevert(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _removeOwner(tokenId, owner);

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
        uint248 tokenId
    ) internal virtual {
        require(_getOwnerOrRevert(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _transferOwner(tokenId, to);

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint248 tokenId) internal virtual {
        _setApproved(tokenId, to);
        address owner = _storedOwners[tokenId]; // Here we can use this because _storedOwners was updated in _setApproved()
        emit Approval(owner, to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _setOperator(owner, operator, approved);
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint248 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
        uint248 tokenId
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
        uint248 tokenId
    ) internal virtual {}


    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint248 tokenId) internal view virtual returns (bool) {
        // bytes32 tidKey = _partitionedKeyForUint248(TOKEN_ID_MAP_GLOBAL_BYTES32_KEY_PARTITION, tokenId);
        // uint256 pid = uint256(_getGlobalDataBytes32(_property, tidKey));
        //return pid != 0;
        return (_storedOwners[tokenId] != address(0)); // Here we don't care if owner of MetaNFT token was transferred and storedOwner is obsolete
    }

    function _setOwner(uint248 tid, address owner) private {
        uint256 pid = _getOrMintMetaNFTId(owner, _property);
        _enablePropertyIfNotEnabled(pid, _property);
        _setOwnerPid(tid, pid);
        _storedOwners[tid] = owner;
    }

    function _removeOwner(uint248 tid, address /*owner*/) internal {
        uint256 pid = _getOwnerPidOrRevert(tid);
        _removeOwnerPid(tid, pid);
        _storedOwners[tid] = address(0);
    }

    function _transferOwner(uint248 tid, address to) internal {
        uint256 fromPid = _getOwnerPidOrRevert(tid); // It is verified in _transfer() that tid is owned by from
        uint256 toPid = _getOrMintMetaNFTId(to, _property);
        _enablePropertyIfNotEnabled(toPid, _property);
        _transferOwnerPid(tid, fromPid, toPid);
        _storedOwners[tid] = to;
    }

    function _getOwnerPid(uint248 tid) internal view returns(uint256){
        bytes32 tidKey = _partitionedKeyForUint248(TOKEN_ID_MAP_GLOBAL_BYTES32_KEY_PARTITION, tid);
        return uint256(_getGlobalDataBytes32(_property, tidKey));
    }
    function _getOwnerPidOrRevert(uint248 tid) internal view returns(uint256) {
        uint256 pid = _getOwnerPid(tid);
        require(pid != 0, "owner query for nonexistent token");
        return pid;
    }
    function _getOwnerOrRevert(uint248 tid) internal view returns(address){
        return _ownerOf(_getOwnerPidOrRevert(tid));
    }

    function _isApproved(uint248 tid, address spender) internal view returns(bool) {
        //TODO clear approved operators on PID transfer
        if(spender == address(0)) return false;
        uint256 pid = _getOwnerPidOrRevert(tid);
        
        address pidOwner = _ownerOf(pid);
        if(_storedOwners[tid] != pidOwner) return false; //This can happen if MetaNFT token was transferred

        bytes32 tidKey = _partitionedKeyForUint248(APPROVED_PROPERTY_BYTES32_KEY_PARTITION, tid);
        address approvedSigner = _bytes322address(_getDataBytes32(pid, _property, tidKey));
        return (spender == approvedSigner);
    }
    function _getApproved(uint248 tid) internal view returns(address) {
        uint256 pid = _getOwnerPidOrRevert(tid);

        address pidOwner = _ownerOf(pid);
        if(_storedOwners[tid] != pidOwner) return address(0); //This can happen if MetaNFT token was transferred

        bytes32 tidKey = _partitionedKeyForUint248(APPROVED_PROPERTY_BYTES32_KEY_PARTITION, tid);
        return _bytes322address(_getDataBytes32(pid, _property, tidKey));
    }

    function _setApproved(uint248 tid, address spender) internal {
        uint256 pid = _getOwnerPidOrRevert(tid);
        bytes32 tidKey = _partitionedKeyForUint248(APPROVED_PROPERTY_BYTES32_KEY_PARTITION, tid);

        address pidOwner = _ownerOf(pid);
        _storedOwners[tid] = pidOwner;        // Note: in _approve() we assume _storedOwners is updated here

        _setDataBytes32(pid, _property, tidKey, _address2bytes32(spender));
    }

    function _isOperator(address owner, address operator) internal view returns(bool) {
        bytes32 ownerKey = _partitionedKeyForAddress(OPERATOR_GLOBAL_SET_KEY_PARTITION, owner);
        return _getGlobalDataSetContainsValue(_property, ownerKey, _address2bytes32(operator));
    }
    function _setOperator(address owner, address operator, bool isOperator) internal {
        bytes32 ownerKey = _partitionedKeyForAddress(OPERATOR_GLOBAL_SET_KEY_PARTITION, owner);
        if(isOperator){
            _setGlobalDataSetAddValue(_property, ownerKey, _address2bytes32(operator));
        }else{
            _setGlobalDataSetRemoveValue(_property, ownerKey, _address2bytes32(operator));
        }
    }

    function _balanceOf(address owner) internal view returns(uint256) {
        uint256[] memory pids= _getAllMetaNFTIdsWithProperty(owner, _property);
        if(pids.length == 0) return 0;
        uint256 totalCount;
        for(uint256 i=0; i<pids.length; i++){
            totalCount += _getDataSetLength(pids[i], _property, OWNED_TOKENS_PROPERTY_SET_KEY);
        }
        return totalCount;
    }

    /**
     * @dev This function does not care about _storedOwners
     */
    function _setOwnerPid(uint248 tid, uint256 pid) private {
        bytes32 tidKey = _partitionedKeyForUint248(TOKEN_ID_MAP_GLOBAL_BYTES32_KEY_PARTITION, tid);
        _setGlobalDataBytes32(_property, tidKey, bytes32(pid));
        _setDataSetAddValue(pid, _property, OWNED_TOKENS_PROPERTY_SET_KEY, _uint2482bytes32(tid));
    }
    /**
     * @dev This function does not care about _storedOwners
     */
    function _removeOwnerPid(uint248 tid, uint256 pid) private {
        bytes32 tidKey = _partitionedKeyForUint248(TOKEN_ID_MAP_GLOBAL_BYTES32_KEY_PARTITION, tid);
        _setGlobalDataBytes32(_property, tidKey, bytes32(0));
        _setDataSetRemoveValue(pid, _property, OWNED_TOKENS_PROPERTY_SET_KEY, _uint2482bytes32(tid));
    }
    /**
     * @dev This function does not care about _storedOwners
     */
    function _transferOwnerPid(uint248 tid, uint256 from, uint256 to) private {
        bytes32 tidKey = _partitionedKeyForUint248(TOKEN_ID_MAP_GLOBAL_BYTES32_KEY_PARTITION, tid);
        _setGlobalDataBytes32(_property, tidKey, bytes32(to));
        _setDataSetRemoveValue(from, _property, OWNED_TOKENS_PROPERTY_SET_KEY, _uint2482bytes32(tid));
        _setDataSetAddValue(to, _property, OWNED_TOKENS_PROPERTY_SET_KEY, _uint2482bytes32(tid));
    }

    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.0;

import "../../interfaces/IMetaNFT.sol";
import "../../interfaces/IMetaRestrictions.sol";

/**
 * @title AllianceBlock BasePropertyManager contract
 * @dev Extends AccesControlUpgradeable
 * @notice Base Property Manager contains common methods to assign properties to MetaNFT
 */
abstract contract BasePropertyManager {

    function _MetaNFT() internal virtual view returns(IMetaNFT);

    /**
     * @notice Internal get MetaNFT id function
     * @param account address
     * @param property the property category
     * @return uint256 the id of the MetaNFT
    */
    function _getMetaNFTId(address account, bytes32 property) internal view returns(uint256) {
        return _MetaNFT().getToken(account, property);
    }

    function _getOrMintMetaNFTId(address account, bytes32 property) internal returns(uint256) {
        return _MetaNFT().getOrMintToken(account, property);
    }

    function _getAllMetaNFTIdsWithProperty(address account, bytes32 property) internal view returns(uint256[] memory) {
        return _MetaNFT().getAllTokensWithProperty(account, property);
    }

    function _ownerOf(uint256 pid) internal view returns(address) {
        return _MetaNFT().ownerOf(pid);
    }

    /**
     * @notice Internal check if MetaNFT has property function
     * @param pid the id of the MetaNFT
     * @param property the property category
     * @return bool true if the MetaNFT has the property
    */
    function _hasProperty(uint256 pid, bytes32 property) internal view returns(bool) {
        return _MetaNFT().hasProperty(pid, property);

    }

    function _addProperty(uint256 pid, bytes32 property, IMetaRestrictions.Restriction[] memory restrictions) internal {
        _MetaNFT().addProperty(pid, property, restrictions);
    }

    function _enablePropertyIfNotEnabled(uint256 pid, bytes32 property) internal {
        if(!_MetaNFT().hasProperty(pid, property)){
            _MetaNFT().addProperty(pid, property, new IMetaRestrictions.Restriction[](0));
        }
    }

    /**
     * @notice Internal get data from Category function
     * @param pid the id of the MetaNFT
     * @param property the property category
     * @param key the key of the data
     * @return bytes32 the data
    */
    function _getDataBytes32(uint256 pid, bytes32 property, bytes32 key) internal view returns(bytes32) {
        return _MetaNFT().getDataBytes32(pid, property, key);
    }

    function _getDataUint256(uint256 pid, bytes32 property, bytes32 key) internal view returns(uint256) {
        return uint256(_MetaNFT().getDataBytes32(pid, property, key));
    }

    function _getDataBytes(uint256 pid, bytes32 property, bytes32 key) internal view returns(bytes memory) {
        return _MetaNFT().getDataBytes(pid, property, key);
    }

    /**
     * @notice Internal set data to Category function
     * @param pid the id of the MetaNFT
     * @param property the property category
     * @param key the key of the data
     * @param value the value of the data
    */
    function _setDataBytes32(uint256 pid, bytes32 property, bytes32 key, bytes32 value) internal {
        _MetaNFT().setDataBytes32(pid, property, key, value);
    }

    function _setDataUint256(uint256 pid, bytes32 property, bytes32 key, uint256 value) internal {
        _MetaNFT().setDataBytes32(pid, property, key, bytes32(value));
    }

    function _setDataBytes(uint256 pid, bytes32 property, bytes32 key, bytes memory value) internal {
        _MetaNFT().setDataBytes(pid, property, key, value);
    }


    function _getDataSetContainsValue(uint256 pid, bytes32 prop, bytes32 key, bytes32 value) internal view returns(bool){
        return _MetaNFT().getDataSetContainsValue(pid, prop, key, value);
    }
    function _getDataSetAllValues(uint256 pid, bytes32 prop, bytes32 key) internal view returns(bytes32[] memory){
        return _MetaNFT().getDataSetAllValues(pid, prop, key);
    }
    function _getDataSetLength(uint256 pid, bytes32 prop, bytes32 key) internal view returns(uint256){
        return _MetaNFT().getDataSetLength(pid, prop, key);
    }
    function _setDataSetAddValue(uint256 pid, bytes32 prop, bytes32 key, bytes32 value) internal {
        _MetaNFT().setDataSetAddValue(pid, prop, key, value);
    }
    function _setDataSetRemoveValue(uint256 pid, bytes32 prop, bytes32 key, bytes32 value) internal {
        _MetaNFT().setDataSetRemoveValue(pid, prop, key, value);
    }
    function _getDataMapValue(uint256 pid, bytes32 prop, bytes32 key, bytes32 vKey) internal view returns(bytes32){
        return _MetaNFT().getDataMapValue(pid, prop, key, vKey);
    }
    function _getDataMapLength(uint256 pid, bytes32 prop, bytes32 key) internal view returns(uint256) {
        return _MetaNFT().getDataMapLength(pid, prop, key);
    }
    function _getDataMapAllEntries(uint256 pid, bytes32 prop, bytes32 key) internal view returns(bytes32[] memory, bytes32[] memory){
        return _MetaNFT().getDataMapAllEntries(pid, prop, key);
    }
    function _setDataMapSetValue(uint256 pid, bytes32 prop, bytes32 key, bytes32 vKey, bytes32 vValue) internal{
        _MetaNFT().setDataMapSetValue(pid, prop, key, vKey, vValue);
    }


    /**
     * @notice Internal get global data function
     * @param property the property category
     * @param key the key of the data
     * @return bytes32 the global data
    */
    function _getGlobalDataBytes32(bytes32 property, bytes32 key) internal view returns(bytes32) {
        return _MetaNFT().getGlobalDataBytes32(property, key);
    }

    /**
     * @notice Internal set global data function
     * @param property the property category
     * @param key the key of the data
     * @param value the value of the data to set
    */
    function _setGlobalDataBytes32(bytes32 property, bytes32 key, bytes32 value) internal {
        return _MetaNFT().setGlobalDataBytes32(property, key, value);
    }


    function _getGlobalDataBytes(bytes32 property, bytes32 key) internal view returns(bytes memory) {
        return _MetaNFT().getGlobalDataBytes(property, key);
    }
    function _setGlobalDataBytes(bytes32 property, bytes32 key, bytes memory value) internal {
        return _MetaNFT().setGlobalDataBytes(property, key, value);
    }

    function _getGlobalDataSetContainsValue(bytes32 prop, bytes32 key, bytes32 value) internal view returns(bool){
        return _MetaNFT().getGlobalDataSetContainsValue(prop, key, value);
    }
    function _getGlobalDataSetLength(bytes32 prop, bytes32 key) internal view returns(uint256) {
        return _MetaNFT().getGlobalDataSetLength(prop, key);
    }
    function _getGlobalDataSetAllValues(bytes32 prop, bytes32 key) internal view returns(bytes32[] memory){
        return _MetaNFT().getGlobalDataSetAllValues(prop, key);
    }
    function _setGlobalDataSetAddValue(bytes32 prop, bytes32 key, bytes32 value) internal {
        _MetaNFT().setGlobalDataSetAddValue(prop, key, value);
    }
    function _setGlobalDataSetRemoveValue(bytes32 prop, bytes32 key, bytes32 value) internal {
        _MetaNFT().setGlobalDataSetRemoveValue(prop, key, value);
    }
    function _getGlobalDataMapValue(bytes32 prop, bytes32 key, bytes32 vKey) internal view returns(bytes32){
        return _MetaNFT().getGlobalDataMapValue(prop, key, vKey);
    }
    function _getGlobalDataMapLength(bytes32 prop, bytes32 key) internal view returns(uint256) {
        return _MetaNFT().getGlobalDataMapLength(prop, key);
    }
    function _getGlobalDataMapAllEntries(bytes32 prop, bytes32 key) internal view returns(bytes32[] memory, bytes32[] memory){
        return _MetaNFT().getGlobalDataMapAllEntries(prop, key);
    }
    function _setGlobalDataMapSetValue(bytes32 prop, bytes32 key, bytes32 vKey, bytes32 vValue) internal {
        _MetaNFT().setGlobalDataMapSetValue(prop, key, vKey, vValue);
    }


    function _address2bytes32(address a) internal pure returns(bytes32) {
        return bytes32(uint256(uint160(a)));
    }

    function _bytes322address(bytes32 b) internal pure returns(address) {
        return address(uint160(uint256(b)));
    }

    function _uint2482bytes32(uint248 v) internal pure returns(bytes32) {
        return bytes32(uint256(v));
    }
    function _bytes322uint248(bytes32 v) internal pure returns(uint248) {
        return uint248(uint256(v));
    }

    function _uint2562uint248(uint256 v) internal pure returns(uint248) {
        require(v <= type(uint248).max, "uint248 conversion fail");
        return uint248(v);
    }



    /**
     * @notice Internal convert address to a partitioned key
     * @param partition Partition
     * @param account Address to convert
     * @return byte32 key
     */
    function _partitionedKeyForAddress(uint8 partition, address account) internal pure returns(bytes32) {
        bytes32 p = bytes32(bytes1(partition));
        bytes32 v = bytes32(uint256(uint160(account)));
        return p | v;
    }

    /**
     * @notice Internal convert address to a partitioned key
     * @param partition Partition
     * @param value Value to convert
     * @return byte32 key
     */
    function _partitionedKeyForUint248(uint8 partition, uint248 value) internal pure returns(bytes32) {
        bytes32 p = bytes32(bytes1(partition));
        bytes32 v = bytes32(uint256(uint248(value)));
        return p | v;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMetaToken.sol";
import "./IMetaProperties.sol";
import "./IMetaRestrictions.sol";
import "./IMetaGlobalData.sol";

interface IMetaNFT is IMetaToken, IMetaProperties, IMetaRestrictions, IMetaGlobalData {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAttachConflictResolver.sol";

interface IMetaRestrictions {

    struct Restriction {
        bytes32 rtype;
        bytes data;
    }


    function addRestriction(uint256 pid, bytes32 prop, Restriction calldata restr) external returns (uint256 idx);
    function removeRestriction(uint256 pid, bytes32 prop, uint256 ridx) external ;
    function removeRestrictions(uint256 pid, bytes32 prop, uint256[] calldata ridxs) external;
    function getRestrictions(uint256 pid, bytes32 prop) external view returns(Restriction[] memory);
    function moveRestrictions(uint256 fromPid, uint256 toPid, bytes32 prop) external returns (uint256[] memory newIdxs);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/token/ERC721/IERC721.sol";
import "./IAttachConflictResolver.sol";

interface IMetaToken is IERC721 {

    function mint(address beneficiary) external returns (uint256);
    function getToken(address beneficiary, bytes32 property) external view returns (uint256);
    function getOrMintToken(address beneficiary, bytes32 property) external returns (uint256);
    function getAllTokensWithProperty(address beneficiary, bytes32 property) external view returns (uint256[] memory);

    /**
     * @notice Joins two NFTs of the same owner
     * @param fromPid Second NFT (properties will be removed from this one)
     * @param toPid Main NFT (properties will be added to this one)
     */
    function attach(uint256 fromPid, uint256 toPid, bytes32[] calldata categories) external;

    /**
     * @notice Splits a MetaNFTs into two
     * @param pid Id of the NFT to split
     * @param category Category of the NFT to detatch
     * @return newPid Id of the new NFT holding the detached Category
     */
    function detach(uint256 pid, bytes32 category) external returns(uint256 newPid);


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMetaRestrictions.sol";

interface IMetaProperties {

    function addProperty(uint256 pid, bytes32 prop, IMetaRestrictions.Restriction[] calldata restrictions) external;
    function removeProperty(uint256 pid, bytes32 prop) external ;
    function hasProperty(uint256 pid, bytes32 prop) external view returns (bool) ;
    function hasProperty(address beneficiary, bytes32 prop) external view returns (bool);

    function setBeforePropertyTransferHook(bytes32 prop, address target, bytes4 selector)  external;

    function setDataBytes32(uint256 pid, bytes32 prop, bytes32 key, bytes32 value) external ;
    function getDataBytes32(uint256 pid, bytes32 prop, bytes32 key) external view returns(bytes32);
    function setDataBytes(uint256 pid, bytes32 prop, bytes32 key, bytes calldata value) external ;
    function getDataBytes(uint256 pid, bytes32 prop, bytes32 key) external view returns(bytes memory);


    function getDataSetContainsValue(uint256 pid, bytes32 prop, bytes32 key, bytes32 value) external view returns(bool);
    function getDataSetLength(uint256 pid, bytes32 prop, bytes32 key) external view returns(uint256);
    function getDataSetAllValues(uint256 pid, bytes32 prop, bytes32 key) external view returns(bytes32[] memory);
    function setDataSetAddValue(uint256 pid, bytes32 prop, bytes32 key, bytes32 value) external;
    function setDataSetRemoveValue(uint256 pid, bytes32 prop, bytes32 key, bytes32 value) external;

    function getDataMapValue(uint256 pid, bytes32 prop, bytes32 key, bytes32 vKey) external view returns(bytes32);
    function getDataMapLength(uint256 pid, bytes32 prop, bytes32 key) external view returns(uint256);
    function getDataMapAllEntries(uint256 pid, bytes32 prop, bytes32 key) external view returns(bytes32[] memory, bytes32[] memory);
    function setDataMapSetValue(uint256 pid, bytes32 prop, bytes32 key, bytes32 vKey, bytes32 vValue) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IMetaGlobalData {

    function setGlobalDataBytes32(bytes32 prop, bytes32 key, bytes32 value) external;
    function getGlobalDataBytes32(bytes32 prop, bytes32 key) external view returns(bytes32);

    function setGlobalDataBytes(bytes32 prop, bytes32 key, bytes calldata value) external;
    function getGlobalDataBytes(bytes32 prop, bytes32 key) external view returns(bytes memory);

    function getGlobalDataSetContainsValue(bytes32 prop, bytes32 key, bytes32 value) external view returns(bool);
    function getGlobalDataSetLength(bytes32 prop, bytes32 key) external view returns(uint256);
    function getGlobalDataSetAllValues(bytes32 prop, bytes32 key) external view returns(bytes32[] memory);
    function setGlobalDataSetAddValue(bytes32 prop, bytes32 key, bytes32 value) external;
    function setGlobalDataSetRemoveValue(bytes32 prop, bytes32 key, bytes32 value) external;

    function getGlobalDataMapValue(bytes32 prop, bytes32 key, bytes32 vKey) external view returns(bytes32);
    function getGlobalDataMapLength(bytes32 prop, bytes32 key) external view returns(uint256);
    function getGlobalDataMapAllEntries(bytes32 prop, bytes32 key) external view returns(bytes32[] memory, bytes32[] memory);
    function setGlobalDataMapSetValue(bytes32 prop, bytes32 key, bytes32 vKey, bytes32 vValue) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @notice ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool status);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAttachConflictResolver {
    function resolveConflictAndMoveProperty(uint256 from, uint256 to, bytes32 property) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}