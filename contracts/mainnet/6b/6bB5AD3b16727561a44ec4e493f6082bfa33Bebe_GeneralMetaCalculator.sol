// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./GeneralMeta.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title General Meta Calculator
 * @dev Contract to calculate the odds for the traits from the random value that Chainlink VRF returned
 * @author Phat Loot DeFi Developers
 * @custom:version v1.0
 * @custom:date 30 April 2022
 */
contract GeneralMetaCalculator is AccessControl {
    bytes32 public constant META_CALCULATOR_ROLE = keccak256("META_CALCULATOR_ROLE");

    GeneralMeta public metaContract;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(META_CALCULATOR_ROLE, msg.sender);

        metaContract = GeneralMeta(address(0xc91da4CA26E117D686625487c852C27124136714)); // Polygon
    }

    /**
     * @param tokenId The tokenId of the Guppy General
     */
    function calculateMetadata(uint256 tokenId, uint256 randomness) external onlyRole(META_CALCULATOR_ROLE) {
        // Expand randomness into 12 values
        uint256[] memory random = expand(randomness, 12);

        // Check if General is a King
        // Get a percentage with two decimals, a General becoming a King has a probability of 0.01%
        uint16 kingGeneral = getBetween(random[0], 1, 10000); 
        bool isKing = kingGeneral == 1;

        // Mood is 1/15 equally distributed
        uint16 mood = getBetween(random[1], 1, 15);

        // Check if King already exists for the found mood, if so, discard the King
        if (isKing && metaContract.getKing(mood) != 0) {
            isKing = false;
        }

        metaContract.setMetadata(
            tokenId,
            isKing,
            [
                mood,
                getBetween(random[2], 1, 425), // Eyes
                getBetween(random[3], 1, 1704), // Hat
                getBetween(random[4], 1, 701), // Texture
                getBetween(random[5], 1, 3516), // Neck
                getBetween(random[6], 1, 314), // Back
                getBetween(random[7], 1, 112), // Rarity
                getBetween(random[8], 1, 5), // Play Style
                getBetween(random[9], 20, 80), // Play Style 1 percentage
                getBetween(random[10], 1, 5), // Play Style 2
                getBetween(random[11], 1, 10000), // Golden Border percentage with two decimals
                kingGeneral // Supply value for completeness, it is however not used in favor of the bool
            ]
        );
    }

    function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function getBetween(
        uint256 random,
        uint16 start,
        uint16 end
    ) public pure returns (uint16) {
        return uint16((random % end) + start);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

error MetadataAlreadySet();
error KingAlreadySetForMood();

/**
 *   @dev Eyes
 *
 *   Variation      Type      Colour   Rarity   Probability (%)   Random range
 *  ----------- ------------ -------- -------- ----------------- --------------
 *           0   No Glasses        1      300   70.59%                     300
 *           1   Goggles           1       40   9.41%                      340
 *           2   Aviators          1       10   2.35%                      350
 *           3   Aviators          2       10   2.35%                      360
 *           4   Round             1       15   3.53%                      375
 *           5   Round             2       15   3.53%                      390
 *           6   Square            1       15   3.53%                      405
 *           7   Square            2       15   3.53%                      420
 *           8   Monocle           1        1   0.24%                      421
 *           9   Patch             1        2   0.47%                      423
 *          10   Patch             2        2   0.47%                      425
 */

/**
 *   @dev Hat
 *
 *   Variation    Type     Colour   Rarity   Probability (%)   Random range
 *  ----------- --------- -------- -------- ----------------- --------------
 *           0   No Hat         1      600   35.21%                     600
 *           1   Halo           1        2   0.12%                      602
 *           2   Cat            1        1   0.06%                      603
 *           3   Cat            2        1   0.06%                      604
 *           4   Crown          1       30   1.76%                      634
 *           5   Crown          2       30   1.76%                      664
 *           6   Tiara          1       30   1.76%                      694
 *           7   Tiara          2       30   1.76%                      724
 *           8   Archer         1       50   2.93%                      774
 *           9   Archer         2       50   2.93%                      824
 *          10   Archer         3       50   2.93%                      874
 *          11   Archer         4       50   2.93%                      924
 *          12   Bard           1       40   2.35%                      964
 *          13   Bard           2       40   2.35%                     1004
 *          14   Bard           3       40   2.35%                     1044
 *          15   Bard           4       40   2.35%                     1084
 *          16   Bard           5       40   2.35%                     1124
 *          17   Jester         1       25   1.47%                     1149
 *          18   Jester         2       25   1.47%                     1174
 *          19   Jester         3       25   1.47%                     1199
 *          20   Jester         4       25   1.47%                     1224
 *          21   Wizard         1       40   2.35%                     1264
 *          22   Wizard         2       40   2.35%                     1304
 *          23   Wizard         3       40   2.35%                     1344
 *          24   Wizard         4       40   2.35%                     1384
 *          25   Wizard         5       40   2.35%                     1424
 *          26   Warlord        1       20   1.17%                     1444
 *          27   Warlord        2       20   1.17%                     1464
 *          28   Knight         1      120   7.04%                     1584
 *          29   Knight         2      120   7.04%                     1704
 */

/**
 *   @dev Mood
 *
 *   Variation      Type      Rarity   Probability (%)   Random range
 *  ----------- ------------ -------- ----------------- --------------
 *           0   Grief             1   6.67%                        1
 *           1   Awe               1   6.67%                        2
 *           2   Terror            1   6.67%                        3
 *           3   Joy               1   6.67%                        4
 *           4   Vigilance         1   6.67%                        5
 *           5   Loneliness        1   6.67%                        6
 *           6   Love              1   6.67%                        7
 *           7   Trust             1   6.67%                        8
 *           8   Rage              1   6.67%                        9
 *           9   Deceit            1   6.67%                       10
 *          10   Serenity          1   6.67%                       11
 *          11   Greed             1   6.67%                       12
 *          12   Pride             1   6.67%                       13
 *          13   Zeal              1   6.67%                       14
 *          14   Courage           1   6.67%                       15
 */

/**
 *  @dev Texture
 *
 *   Variation     Type      Rarity   Probability (%)   Random range
 *  ----------- ----------- -------- ----------------- --------------
 *           0   Texture 1      300   42.80%                     300
 *           1   Texture 2      100   14.27%                     400
 *           2   Texture 3      100   14.27%                     500
 *           3   Texture 4      100   14.27%                     600
 *           4   Texture 5      100   14.27%                     700
 *           5   Texture 6        1   0.14%                      701
 */

/**
 *  @dev Neck
 *
 *   Variation     Type     Colour   Rarity   Probability (%)   Random range
 *  ----------- ---------- -------- -------- ----------------- --------------
 *           0   No Neck         1     3000   85.32%                    3000
 *           1   Necklace        1      210   5.97%                     3210
 *           2   Necklace        2      210   5.97%                     3420
 *           3   Scarf           1       15   0.43%                     3435
 *           4   Scarf           2       15   0.43%                     3450
 *           5   Scarf           3       15   0.43%                     3465
 *           6   Scarf           4       15   0.43%                     3480
 *           7   Choker          1        2   0.06%                     3482
 *           8   Choker          2        2   0.06%                     3484
 *           9   Choker          3        2   0.06%                     3486
 *          10   Chain           1       15   0.43%                     3501
 *          11   Chain           2       15   0.43%                     3516
 */

/**
 *  @dev Back
 *
 *   Variation      Type      Colour   Rarity   Probability (%)   Random range
 *  ----------- ------------ -------- -------- ----------------- --------------
 *           0   No Back           1      120   38.22%                     120
 *           1   Cape              1       12   3.82%                      132
 *           2   Cape              2       12   3.82%                      144
 *           3   Cape              3       12   3.82%                      156
 *           4   Tattered          1        6   1.91%                      162
 *           5   Tattered          2        6   1.91%                      168
 *           6   Adventurer        1       35   11.15%                     203
 *           7   Katanas           1       30   9.55%                      233
 *           8   Sword             1       28   8.92%                      261
 *           9   Staff             1       28   8.92%                      289
 *          10   Shield            1       25   7.96%                      314
 */

/**
 *  @dev Rarity
 *
 *   Variation     Type     Rarity   Probability (%)   Random range
 *  ----------- ---------- -------- ----------------- --------------
 *           0   Base           50   44.64%                      50
 *           1   Advanced       35   31.25%                      85
 *           2   Adept          20   17.86%                     105
 *           3   Ascended        7   6.25%                      112
 */

/**
 *  @dev Style
 *
 *   Variation     Type      Rarity   Probability (%)   Random range
 *  ----------- ----------- -------- ----------------- --------------
 *           0   Late-game        1   20.00%                       1
 *           1   Agro             1   20.00%                       2
 *           2   Tank             1   20.00%                       3
 *           3   Sustain          1   20.00%                       4
 *           4   Econ             1   20.00%                       5
 */

/**
 * @title General Meta
 * @dev Contract holding the metadata for a General that is computed by a Chainlink VRF random generated number.
 * @author Phat Loot DeFi Developers
 * @custom:version 1.0
 * @custom:date 30 April 2022
 */
contract GeneralMeta is AccessControl {
    bytes32 public constant META_SETTER_ROLE = keccak256("META_SETTER_ROLE");

    // All packed within a single 32 bytes slot
    struct Metadata {
        bool isKing;
        uint16 mood;
        uint16 eyes;
        uint16 hat;
        uint16 texture;
        uint16 neck;
        uint16 back;
        uint16 rarity;
        uint16 firstStyle;
        uint16 firstStyleValue;
        uint16 secondStyle;
        uint16 goldenBorder;
        uint16 kingGeneral;
    }

    // General tokenId => Metadata traits
    mapping(uint256 => Metadata) private _meta;

    // Mood => tokenId of General contract that is a King
    mapping(uint16 => uint256) private _moodToKing;

    // Fired when the metadata has been stored for a General with tokenId
    event MetadataSet(uint256 tokenId, Metadata metadata);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(META_SETTER_ROLE, msg.sender);
    }

    function setMetadata(
        uint256 tokenId,
        bool _isKing,
        uint16[12] memory traits
    ) external onlyRole(META_SETTER_ROLE) {
        if (_meta[tokenId].mood != 0) revert MetadataAlreadySet();

        if (_isKing && _moodToKing[traits[0]] != 0) revert KingAlreadySetForMood();

        if (_isKing) {
            _moodToKing[traits[0]] = tokenId;
        }

        _meta[tokenId] = Metadata(
            _isKing,
            traits[0],
            traits[1],
            traits[2],
            traits[3],
            traits[4],
            traits[5],
            traits[6],
            traits[7],
            traits[8],
            traits[9],
            traits[10],
            traits[11]
        );

        emit MetadataSet(tokenId, _meta[tokenId]);
    }

    function getMetadata(uint256 tokenId) external view returns (Metadata memory) {
        return _meta[tokenId];
    }

    function getKing(uint16 mood) external view returns (uint256 tokenId) {
        return _moodToKing[mood];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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