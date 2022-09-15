// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "./lib/ContextMixin.sol";

import "./interfaces/IDSponsor.sol";

/**
 * @title A sponsoring contract
 * @author Anthony Gourraud
 * @notice Give for each token of an ERC721 contract a right to advertise.
 *  Token owners are considered as "sponsors" and can provide sponsoring information
 *  for properties specified by sponsee, regarding an off-chain promotion purpose
 * ("link" and "logo" keys to add at the end of a newsletter, "audioAd" towards a pre-roll on podcasts for example)
 *
 * Sponsee can :
 * - allow or disallow any string as sponsoring property
 * - validates data (or not) sponsors submit
 * - grant or revoke any other address with sponsee powers
 * (SET_PROPERTIES_ROLE and VALIDATE_ROLE via {AccessControl})
 *
 * Sponsors, as token owners, can :
 * - submit data related to an allowed property for tokens they own
 * (string data can be "https://mywebsite.com" for "link" property, set to tokenId "1" for example)
 * - transfer a token to another address, new owner will be the only one able to set sponsoring data
 */
contract DSponsor is AccessControl, ContextMixin, IDSponsor {
    struct SponsoData {
        string lastDataValidated;
        string lastDataSubmitted;
        string lastRejectionReason;
    }

    bytes32 public constant SET_PROPERTIES_ROLE =
        keccak256("SET_PROPERTIES_ROLE");
    bytes32 public constant VALIDATE_ROLE = keccak256("VALIDATE_ROLE");

    /// @notice Avoid high storage cost and protect against sort of "DDoS" attack
    uint256 public constant MAX_SPONSOR_STRING_DATA_LENGTH = 100;

    /** @notice Sponsoring conditions, expected to be an immutable document
     * stored on IPFS or Arweave (but it's not required)
     */
    string public RULES_URI;

    IERC721 public immutable NFT_CONTRACT;

    /*
     * For sponsoring allowed property, use bytes32 from string input
     * See {_propertyStringToBytes32}
     */
    mapping(bytes32 => bool) private _allowedProperties;

    // tokenId => bytes32StringProperty => stringDatas
    mapping(uint256 => mapping(bytes32 => SponsoData)) private _sponsoDatas;

    /* ****************
     *  ERRORS
     *****************/
    error isNotERC721Contract();

    /* ****************
     *  MODIFIERS
     *****************/

    modifier limitStringLength(string memory s) {
        if (bytes(s).length > MAX_SPONSOR_STRING_DATA_LENGTH)
            revert StringLengthExceedLimit();
        _;
    }

    modifier onlyAllowedProperty(bytes32 property) {
        if (!_isAllowedProperty(property)) revert UnallowedProperty();
        _;
    }

    modifier onlySponsor(uint256 tokenId) {
        if (_msgSender() != NFT_CONTRACT.ownerOf(tokenId))
            revert UnallowedSponsorOperation();
        _;
    }

    /* ****************
     *  CONTRACT CONSTRUCTOR
     *****************/

    /**
     * @param ERC721Contract ERC721 compliant address
     * @param rulesURI Document with sponsoring conditions. IPFS or Arweave links might be more approriate
     * @param sponsee Controller who gives sponsoring opportunity
     */
    constructor(
        IERC721 ERC721Contract,
        string memory rulesURI,
        address sponsee
    ) {
        if (sponsee == address(0)) revert SponseeCannotBeZeroAddress();

        try ERC721Contract.supportsInterface(0x80ac58cd) returns (
            bool
        ) {} catch (bytes memory) {
            revert isNotERC721Contract();
        }

        NFT_CONTRACT = IERC721(ERC721Contract);
        RULES_URI = rulesURI;

        _setupRole(DEFAULT_ADMIN_ROLE, sponsee);
        _setupRole(SET_PROPERTIES_ROLE, sponsee);
        _setupRole(VALIDATE_ROLE, sponsee);
    }

    /* ****************
     *  EXTERNAL FUNCTIONS
     *****************/

    /**
     * @notice Enable or disable a specific sponsoring key
     * @param propertyString - Can be any string, according off-chain sponsee promotion purpose
     * @param allowed - Set `false` to disable `propertyString` usage
     *
     * Emits {PropertyUpdate} event
     */
    function setProperty(string memory propertyString, bool allowed)
        external
        onlyRole(SET_PROPERTIES_ROLE)
    {
        _setProperty(propertyString, allowed);
    }

    /**
     * @notice Sponsoring data submission
     * @param tokenId - Concerned token
     * @param property - Concerned property
     * @param data - Can be any string
     * but cannot exceed have a length greater than {MAX_SPONSOR_STRING_DATA_LENGTH}
     *
     * Emits {NewSponsoData} event
     */
    function setSponsoData(
        uint256 tokenId,
        string memory property,
        string memory data
    ) external onlySponsor(tokenId) limitStringLength(data) {
        _setSponsoData(tokenId, _propertyStringToBytes32(property), data);
        emit NewSponsoData(tokenId, property, data);
    }

    /**
     * @notice Validate (or not) data submitted by sponsor. If rejected, inform a reason.
     * @param tokenId - Concerned token
     * @param property - Concerned property
     * @param validated - If `true`, submitted data is validated, previous data replaced for given tokenId and property
     * @param reason Explain why it gets rejected (optionnal)
     *
     * Emits {NewSponsoDataValidation} event
     */
    function setSponsoDataValidation(
        uint256 tokenId,
        string memory property,
        bool validated,
        string memory reason
    ) external onlyRole(VALIDATE_ROLE) {
        string memory data;
        data = _setSponsoDataValidation(
            tokenId,
            _propertyStringToBytes32(property),
            validated,
            reason
        );

        emit NewSponsoDataValidation(
            tokenId,
            property,
            validated,
            data,
            reason
        );
    }

    /* ****************
     *  EXTERNAL GETTERS
     *****************/

    function getAccessContract() external view returns (address) {
        return address(NFT_CONTRACT);
    }

    function getSponsoData(uint256 tokenId, string memory propertyString)
        external
        view
        returns (
            string memory lastDataValidated,
            string memory lastDataSubmitted,
            string memory lastRejectionReason
        )
    {
        SponsoData storage sponsoData = _sponsoDatas[tokenId][
            _propertyStringToBytes32(propertyString)
        ];

        lastDataValidated = sponsoData.lastDataValidated;
        lastDataSubmitted = sponsoData.lastDataSubmitted;
        lastRejectionReason = sponsoData.lastRejectionReason;
    }

    function isAllowedProperty(string memory propertyString)
        external
        view
        returns (bool)
    {
        return _isAllowedProperty(_propertyStringToBytes32(propertyString));
    }

    /* ****************
     *  INTERNAL OVERRIDE FUNCTIONS
     *****************/

    /* @dev Used instead of msg.sender as transactions won't be sent
     * by the original token owner, but by relayer.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    /* ****************
     *  PRIVATE DATA HANDLERS
     *****************/

    function _setProperty(bytes32 propertyBytes, bool allowed) private {
        _allowedProperties[propertyBytes] = allowed;
    }

    function _setProperty(string memory propertyString, bool allowed) private {
        if (bytes(propertyString).length > 0) {
            _setProperty(_propertyStringToBytes32(propertyString), allowed);
            emit PropertyUpdate(propertyString, allowed);
        }
    }

    function _setSponsoData(
        uint256 tokenId,
        bytes32 property,
        string memory data
    ) private onlyAllowedProperty(property) {
        string memory lastDataValidated = _sponsoDatas[tokenId][property]
            .lastDataValidated;
        _sponsoDatas[tokenId][property] = SponsoData(
            lastDataValidated,
            data,
            ""
        );
    }

    function _setSponsoDataValidation(
        uint256 tokenId,
        bytes32 property,
        bool validated,
        string memory reason
    ) private onlyAllowedProperty(property) returns (string memory) {
        string memory data = _sponsoDatas[tokenId][property].lastDataSubmitted;

        if (bytes(data).length == 0) revert NoDataSubmitted();
        if (validated) {
            _sponsoDatas[tokenId][property] = SponsoData(data, "", "");
        } else {
            _sponsoDatas[tokenId][property].lastRejectionReason = reason;
        }
        return data;
    }

    /* ****************
     *  PRIVATE GETTERS
     *****************/

    function _isAllowedProperty(bytes32 propertyBytes)
        private
        view
        returns (bool)
    {
        return _allowedProperties[propertyBytes];
    }

    function _propertyStringToBytes32(string memory p)
        private
        pure
        returns (bytes32)
    {
        return keccak256(bytes(p));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IDSponsor {
    event NewSponsoData(
        uint256 indexed tokenId,
        string indexed property,
        string data
    );
    event NewSponsoDataValidation(
        uint256 indexed tokenId,
        string indexed property,
        bool indexed validated,
        string data,
        string reason
    );
    event PropertyUpdate(string indexed property, bool indexed allowed);

    error NoDataSubmitted();
    error SponseeCannotBeZeroAddress();
    error StringLengthExceedLimit();
    error UnallowedProperty();
    error UnallowedSponsorOperation();

    function setProperty(string memory propertyString, bool allowed) external;

    function setSponsoData(
        uint256 tokenId,
        string memory property,
        string memory data
    ) external;

    function setSponsoDataValidation(
        uint256 tokenId,
        string memory property,
        bool validated,
        string memory reason
    ) external;

    function getAccessContract() external view returns (address);

    function getSponsoData(uint256 tokenId, string memory propertyString)
        external
        view
        returns (
            string memory lastDataValidated,
            string memory lastDataSubmitted,
            string memory lastRejectionReason
        );

    function isAllowedProperty(string memory propertyString)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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