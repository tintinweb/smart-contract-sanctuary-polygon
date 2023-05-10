// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

pragma solidity ^0.8.15;

struct Avatar {
    /// @dev bool value for knowing if an id was created
    uint8 created;
    /// @dev the mint type of the nft
    /// @dev Ex: Genesis -> 0, Refurbished -> 1
    uint16 mintType;
    /// @dev the type of the nft
    /// @dev check avatarTypeConfig from nftContract
    uint16 avatarType;
    /// @dev an array with the values of each attribute
    uint64[] attributes;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Avatar.sol";

/**
 * @notice Interface used to interact with the Nft contract
 */
interface NftInterface {
    /// @notice View function to get an avatar by id
    function getAvatar(uint256 _tokenId) external view returns (Avatar memory);

    /// @notice Mint function
    function mint(
        address _to,
        uint16 _avatarType,
        uint64[] calldata _attributes
    ) external;

    /// @notice Burn function
    function burn(uint256 _tokenId) external;

    /// @notice View function to get the owner of a token by id
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Update avatar function
    function updateAvatar(
        uint256 _targetId,
        uint16 _mintType,
        uint64[] calldata _attributes
    ) external;

    /// @notice Checking the availability of attributes for creating Genesis Nfts
    function checkAttributesTaken(uint16 _avatarType, uint64[] calldata _attributes) external returns (bool);

    /// @notice Get the name of the parts of an avatarType
    function getAvatarTypeParts(uint16 _avatarType) external view returns (string[] memory);

    function checkAvatarTypeHasParts(uint16 _avatarType) external view returns (bool);

    function invalidNumberOfAttribute(uint16 _avatarType, uint64[] calldata _attributes) external view returns (bool);
}

/**
 * @author Softbinator Technologies
 * @notice This Contract is used to handle the interaction with the Nft Contract.
 * @notice The user should interact with the Nft Contract only through this contract
 */
contract CustomContract is Pausable, AccessControl {
    using Strings for uint16;

    /// @notice Interface address used for interaction
    NftInterface public nft;

    /// @dev put both vars in same slot for gas optimisation
    /// @notice The number used for knowing how many Nfts can be used in recycle, except Target
    uint128 public nrOfRecycledNfts;
    /// @notice The number used for knowing how many Nfts attributes have to be sent for recycle
    uint128 public nrOfAttributePerRecycledNft;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant RECYCLE_ROLE = keccak256("RECYCLE_ROLE");

    error RecycleWrongInputDuplicatePart();
    error InvalidNumberOfRecycleTokens();
    error RecycleNotOwnerOfTokens();
    error InvalidNumberOfNftAttributes();
    error MinimumReplacementsError();
    error AttributesAlreadyTaken();
    error DifferentAvatarTypesInRecycle();
    error PartsNotDefined();
    error InvalidNumberOfAttributesForAvatarType();

    /// @notice Event triggered on changing Nft contract address
    event ChangeNftAddress(NftInterface newNft);

    /// @notice Event triggered on recycling avatars
    event Recycle(uint256 indexed tokenId, uint64[] newAttributes);

    /// @notice Event triggered on setting maximum number of attributes
    event SetMaxNrAttributes(uint256 maxNrAttributes);

    /// @notice Event triggered on settingthe number of recycled nfts
    event SetNrOfRecycledNfts(uint256 newNrOfRecycledNfts);

    /// @notice Event triggered on minting Genesis Nft
    event MintNft(address indexed to, uint16 _avatarType, uint64[] attributes);

    event SetNrOfAttributePerRecycledNft(uint128 newNrOfAttributePerRecycledNft);

    constructor(NftInterface _nft, uint128 _nrOfRecycledNfts, uint128 _nrOfAttributePerRecycledNft) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(RECYCLE_ROLE, msg.sender);

        nft = _nft;
        nrOfRecycledNfts = _nrOfRecycledNfts;
        nrOfAttributePerRecycledNft = _nrOfAttributePerRecycledNft;
    }

    /**
     * @notice Mint an unique Genesis NFT with a signature generated on backend.
     * @dev This function is called by user after he gets the seed from backend.
     * @param _to represents the future owner
     * @param _attributes represents a vector with the values of each attribute
     */
    function mintNft(
        address _to,
        uint16 _avatarType,
        uint64[] calldata _attributes
    ) external whenNotPaused onlyRole(MINTER_ROLE) {
        if (!nft.checkAvatarTypeHasParts(_avatarType)) {
            revert PartsNotDefined();
        }

        if (nft.invalidNumberOfAttribute(_avatarType, _attributes)) {
            revert InvalidNumberOfAttributesForAvatarType();
        }

        /// @dev check if the generated attributes have been used in the past by a Genesis
        if (nft.checkAttributesTaken(_avatarType, _attributes)) {
            revert AttributesAlreadyTaken();
        }

        nft.mint(_to, _avatarType, _attributes);
        emit MintNft(_to, _avatarType, _attributes);
    }

    /**
     * @notice Using recycle an user can update a nft with custom attributes.
     * @notice If the target Nft is Genesis, then it will become Refurbished
     * @dev The number of _recycleNft has to be eqaul with nrOfRecycledNfts
     * @dev For recycling to be successful must be at least one attribute that is changed at target nft from _recycleNft
     * @dev A recycleNft can't have more attributes then maxNrAttributes
     * @param _ownerNfts represents owner of the nfts
     * @param _targetId represents the token id of the target Nft
     * @param _tokenIds represents the ids of the nfts used for recycle
     * @param _tokenAttributes represents an array of arrays, where an an array contains the
     * attributes parts to be used on target
     */
    function recycle(
        address _ownerNfts,
        uint256 _targetId,
        uint256[] calldata _tokenIds,
        uint256[][] calldata _tokenAttributes
    ) external whenNotPaused onlyRole(RECYCLE_ROLE) {
        if (_tokenIds.length != nrOfRecycledNfts || _tokenIds.length != _tokenAttributes.length) {
            revert InvalidNumberOfRecycleTokens();
        }

        /// @dev This check can revert
        checkForOwnership(_targetId, _ownerNfts);

        Avatar memory targetAvatar = nft.getAvatar(_targetId);
        uint256 maxNrAttributes = nft.getAvatarTypeParts(targetAvatar.avatarType).length;

        /// @dev An array for checking if there are duplicates of attributes in the recycle method
        uint8[] memory partExist = new uint8[](maxNrAttributes);

        /// @dev Build a new array to store the new attributes of the Refurbished Nft
        uint64[] memory newAttributes = new uint64[](maxNrAttributes);

        /// @dev Bool variable for checking if there is at least one attributes replaced in recycle
        /// @dev If it is False at the and then the transaction should revert
        bool hasReplacement = false;

        for (uint256 i=0; i < targetAvatar.attributes.length; i++) {
            newAttributes[i] = targetAvatar.attributes[i];
        }
        for (uint256 i=0; i < _tokenIds.length; i++) {
            /// @dev This check can revert
            checkForOwnership(_tokenIds[i], _ownerNfts);

            Avatar memory currentAvatar;

            /// @dev This check can revert
            checkForNrOfAttributes(_tokenAttributes[i].length, maxNrAttributes);

            if (_tokenAttributes[i].length > 0) {
                /// Bring all attributes here to have them local and not make more calls

                currentAvatar = nft.getAvatar(_tokenIds[i]);

                /// @dev This check can revert
                checkAvatarType(targetAvatar.avatarType, currentAvatar.avatarType);

                for (uint256 j=0; j < _tokenAttributes[i].length; j++) {
                    uint256 currentPartPosition = _tokenAttributes[i][j];

                    /// @dev This check can revert
                    checkForDuplicates(partExist[currentPartPosition]);

                    partExist[currentPartPosition] = 1;
                    hasReplacement = true;
                    newAttributes[currentPartPosition] = currentAvatar.attributes[currentPartPosition];
                }
            }
        }
        /// @dev Check if the recycle function updates at least one attribute
        if (!hasReplacement) {
            revert MinimumReplacementsError();
        }

        /// @dev Burn used Nfts
        for (uint256 i=0; i < _tokenIds.length; i++) {
            nft.burn(_tokenIds[i]);
        }

        /// @dev Update targetNft with the new attributes
        nft.updateAvatar(_targetId, 1, newAttributes);
        emit Recycle(_targetId, newAttributes);
    }

    /**
     * @notice Check if the sender is the owner of a token
     * @param _tokenId represents the id of an avatar
     */
    function checkForOwnership(uint256 _tokenId, address _ownerNfts) private view {
        if (nft.ownerOf(_tokenId) != _ownerNfts) {
            revert RecycleNotOwnerOfTokens();
        }
    }

    /**
     * @notice Check if target avatar has a different avatar type than the nfts that will be burned
     * @param _targetAvatarType represents the type of the target avatar
     * @param _currentAvatarType represents the type of the recycled avatar
     */
    function checkAvatarType(uint16 _targetAvatarType, uint16 _currentAvatarType) private pure {
        if (_targetAvatarType != _currentAvatarType) {
            revert DifferentAvatarTypesInRecycle();
        }
    }

    /**
     * @notice Check if an avatar has more attributes replacements than maximum number of attributes
     * @param _length represents the attributes array length of a token to be recycled
     */
    function checkForNrOfAttributes(uint256 _length, uint256 _maxNrAttributes) private view {
        if (
            _length > _maxNrAttributes || (_length != nrOfAttributePerRecycledNft && nrOfAttributePerRecycledNft != 0)
        ) {
            revert InvalidNumberOfNftAttributes();
        }
    }

    /**
     * @notice Check if the param is equal to 1, and if it is true then revert
     * @param _exist represents the value of an attribute in a frequency array
     */
    function checkForDuplicates(uint256 _exist) private pure {
        if (_exist == 1) {
            revert RecycleWrongInputDuplicatePart();
        }
    }

    /**
     * @notice Set the number of the nfts that have to be recycled
     */
    function setNrOfRecycledNfts(uint8 _nrOfRecycledNfts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nrOfRecycledNfts = _nrOfRecycledNfts;
        emit SetNrOfRecycledNfts(_nrOfRecycledNfts);
    }

    /**
     * @notice Set the number of the nft attributes that can be selected at recycle for each nft
     */
    function setNrOfAttributePerRecycledNft(
        uint128 newNrOfAttributePerRecycledNft
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nrOfAttributePerRecycledNft = newNrOfAttributePerRecycledNft;
        emit SetNrOfAttributePerRecycledNft(newNrOfAttributePerRecycledNft);
    }

    /**
     * @notice Set the Nft contract address
     */
    function setNftContract(NftInterface _nft) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nft = _nft;
        emit ChangeNftAddress(_nft);
    }

    function getAvatarDetails(uint256 _tokenId)
        external
        view
        returns (
            uint8,
            uint16,
            uint16,
            uint64[] memory
        )
    {
        Avatar memory avatar = nft.getAvatar(_tokenId);
        return (avatar.created, avatar.mintType, avatar.avatarType, avatar.attributes);
    }
}