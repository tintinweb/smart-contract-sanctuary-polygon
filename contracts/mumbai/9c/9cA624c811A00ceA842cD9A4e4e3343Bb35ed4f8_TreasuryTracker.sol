// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

import "./interfaces/ITreasuryTracker.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface ITangibleNFT {}

interface ITangibleFractionsNFT {
    function tnft() external view returns (ITangibleNFT nft);

    function tnftTokenId() external view returns (uint256 tokenId);

    function fractionShares(uint256 fractionId)
        external
        view
        returns (uint256 share);

    function fullShare() external view returns (uint256 fullShare);
}

//UPDATE TO TRACK GOLD BARS SPECIALLY!
contract TreasuryTracker is ITreasuryTracker, AccessControl {
    struct TokenArray {
        uint256[] tokenIds;
    }
    struct ContractItem {
        bool selling;
        uint256 index;
    }

    struct TnftTreasuryItem {
        address tnft;
        uint256 tokenId;
        uint256 indexInCurrentlySelling;
    }

    struct FractionTreasuryItem {
        address ftnft;
        uint256 fractionId;
        uint256 indexInCurrentlySelling;
    }

    //fractions
    address[] public fractionContractsInTreasury;
    mapping(address => ContractItem) public isFtnftInTreasury;
    mapping(address => uint256[]) public fractionTokensInTreasury;
    mapping(address => FractionIdData[]) public fractionTokensDataInTreasury;
    mapping(address => mapping(uint256 => FractionTreasuryItem))
        public fractiInTreasuryMapper;

    //return whole array
    function getFractionContractsInTreasury()
        external
        view
        returns (address[] memory)
    {
        return fractionContractsInTreasury;
    }

    //return size
    function fractionContractsInTreasurySize() external view returns (uint256) {
        return fractionContractsInTreasury.length;
    }

    //return whole array
    function getFractionTokensInTreasury(address ftnft)
        external
        view
        returns (uint256[] memory)
    {
        return fractionTokensInTreasury[ftnft];
    }

    //return whole batch arrays
    function getFractionTokensInTreasuryBatch(address[] calldata ftnfts)
        external
        view
        returns (TokenArray[] memory result)
    {
        uint256 length = ftnfts.length;
        result = new TokenArray[](length);
        for (uint256 i; i < length; i++) {
            TokenArray memory temp = TokenArray(
                fractionTokensInTreasury[ftnfts[i]]
            );
            result[i] = temp;
        }
        return result;
    }

    //return size
    function fractionTokensInTreasurySize(address ftnft)
        external
        view
        returns (uint256)
    {
        return fractionTokensInTreasury[ftnft].length;
    }

    function getFractionTokensDataInTreasury(address ftnft)
        external
        view
        returns (FractionIdData[] memory fData)
    {
        return fractionTokensDataInTreasury[ftnft];
    }

    address[] public tnftCategoriesInTreasury;
    mapping(address => ContractItem) public isTnftInTreasury;
    mapping(address => uint256[]) public tnftTokensInTreasury;
    mapping(address => mapping(uint256 => TnftTreasuryItem))
        public tnftSaleMapper;

    //return whole array
    function getTnftCategoriesInTreasury()
        external
        view
        returns (address[] memory)
    {
        return tnftCategoriesInTreasury;
    }

    //return size
    function tnftCategoriesInTreasurySize() external view returns (uint256) {
        return tnftCategoriesInTreasury.length;
    }

    //return whole array
    function getTnftTokensInTreasury(address tnft)
        external
        view
        returns (uint256[] memory)
    {
        return tnftTokensInTreasury[tnft];
    }

    //return whole batch arrays
    function getTnftTokensInTreasuryBatch(address[] calldata tnfts)
        external
        view
        returns (TokenArray[] memory result)
    {
        uint256 length = tnfts.length;
        result = new TokenArray[](length);
        for (uint256 i; i < length; i++) {
            TokenArray memory temp = TokenArray(tnftTokensInTreasury[tnfts[i]]);
            result[i] = temp;
        }
        return result;
    }

    //return size
    function tnftTokensInTreasurySize(address tnft)
        external
        view
        returns (uint256)
    {
        return tnftTokensInTreasury[tnft].length;
    }

    address public treasury;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setTreasury(address _treasury)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        treasury = _treasury;
    }

    function tnftTreasuryPlaced(
        address tnft,
        uint256 tokenId,
        bool place
    ) external override {
        require(msg.sender == treasury);

        if (place) {
            //check if something from this category is on sale already
            if (!isTnftInTreasury[tnft].selling) {
                //add category to actively selling list
                tnftCategoriesInTreasury.push(tnft);
                isTnftInTreasury[tnft].selling = true;
                isTnftInTreasury[tnft].index =
                    tnftCategoriesInTreasury.length -
                    1;
            }
            //something is added to marketplace

            tnftTokensInTreasury[tnft].push(tokenId);
            TnftTreasuryItem memory tsi = TnftTreasuryItem(
                tnft,
                tokenId,
                (tnftTokensInTreasury[tnft].length - 1)
            );
            tnftSaleMapper[tnft][tokenId] = tsi;
        } else {
            //something is removed from marketplace
            uint256 indexInTokenSale = tnftSaleMapper[tnft][tokenId]
                .indexInCurrentlySelling;
            _removeCurrentlySellingTnft(tnft, indexInTokenSale);
            delete tnftSaleMapper[tnft][tokenId];
            if (tnftTokensInTreasury[tnft].length == 0) {
                //all tokens are removed, nothing in category is selling anymore
                _removeCategory(isTnftInTreasury[tnft].index);
                delete isTnftInTreasury[tnft];
            }
        }
    }

    function ftnftTreasuryPlaced(
        address ftnft,
        uint256 tokenId,
        bool place
    ) external override {
        require(msg.sender == treasury);

        if (place) {
            //check if something from this category is on sale already
            if (!isFtnftInTreasury[ftnft].selling) {
                //add category to actively selling list
                fractionContractsInTreasury.push(ftnft);
                isFtnftInTreasury[ftnft].selling = true;
                isFtnftInTreasury[ftnft].index =
                    fractionContractsInTreasury.length -
                    1;
            }
            //something is added to marketplace
            fractionTokensInTreasury[ftnft].push(tokenId);
            //fill fraction data
            FractionIdData memory fData;
            fData.fractionId = tokenId;
            fData.share = ITangibleFractionsNFT(ftnft).fractionShares(tokenId);
            fData.tnft = address(ITangibleFractionsNFT(ftnft).tnft());
            fData.tnftTokenId = ITangibleFractionsNFT(ftnft).tnftTokenId();
            fractionTokensDataInTreasury[ftnft].push(fData);

            FractionTreasuryItem memory fsi = FractionTreasuryItem(
                ftnft,
                tokenId,
                (fractionTokensInTreasury[ftnft].length - 1)
            );
            fractiInTreasuryMapper[ftnft][tokenId] = fsi;
        } else {
            //something is removed from marketplace
            uint256 indexInTokenSale = fractiInTreasuryMapper[ftnft][tokenId]
                .indexInCurrentlySelling;
            _removeCurrentlySellingFraction(ftnft, indexInTokenSale);
            delete fractiInTreasuryMapper[ftnft][tokenId];
            if (fractionTokensInTreasury[ftnft].length == 0) {
                //all tokens are removed, nothing in category is selling anymore
                _removeFraction(isFtnftInTreasury[ftnft].index);
                delete isFtnftInTreasury[ftnft];
            }
        }
    }

    //this function is not preserving order, and we don't care about it
    function _removeCurrentlySellingFraction(address ftnft, uint256 index)
        internal
    {
        require(index < fractionTokensInTreasury[ftnft].length, "IndexF");
        //take last token
        uint256 tokenId = fractionTokensInTreasury[ftnft][
            fractionTokensInTreasury[ftnft].length - 1
        ];
        FractionIdData memory fData = fractionTokensDataInTreasury[ftnft][
            fractionTokensDataInTreasury[ftnft].length - 1
        ];

        //replace it with the one we are removing
        fractionTokensInTreasury[ftnft][index] = tokenId;
        fractionTokensDataInTreasury[ftnft][index] = fData;
        //set it's new index in saleData
        fractiInTreasuryMapper[ftnft][tokenId].indexInCurrentlySelling = index;
        fractionTokensInTreasury[ftnft].pop();
        fractionTokensDataInTreasury[ftnft].pop();
    }

    function updateFractionData(address ftnft, uint256 tokenId)
        external
        override
    {
        uint256 indexInTokenSale = fractiInTreasuryMapper[ftnft][tokenId]
            .indexInCurrentlySelling;
        fractionTokensDataInTreasury[ftnft][indexInTokenSale]
            .share = ITangibleFractionsNFT(ftnft).fractionShares(tokenId);
    }

    //this function is not preserving order, and we don't care about it
    function _removeCurrentlySellingTnft(address tnft, uint256 index) internal {
        require(index < tnftTokensInTreasury[tnft].length, "IndexT");
        //take last token
        uint256 tokenId = tnftTokensInTreasury[tnft][
            tnftTokensInTreasury[tnft].length - 1
        ];

        //replace it with the one we are removing
        tnftTokensInTreasury[tnft][index] = tokenId;
        //set it's new index in saleData
        tnftSaleMapper[tnft][tokenId].indexInCurrentlySelling = index;
        tnftTokensInTreasury[tnft].pop();
    }

    function _removeCategory(uint256 index) internal {
        require(index < tnftCategoriesInTreasury.length, "IndexC");
        //take last token
        address _tnft = tnftCategoriesInTreasury[
            tnftCategoriesInTreasury.length - 1
        ];

        //replace it with the one we are removing
        tnftCategoriesInTreasury[index] = _tnft;
        //set it's new index in saleData
        isTnftInTreasury[_tnft].index = index;
        tnftCategoriesInTreasury.pop();
    }

    function _removeFraction(uint256 index) internal {
        require(index < fractionContractsInTreasury.length, "IndexFr");
        //take last token
        address _ftnft = fractionContractsInTreasury[
            fractionContractsInTreasury.length - 1
        ];

        //replace it with the one we are removing
        fractionContractsInTreasury[index] = _ftnft;
        //set it's new index in saleData
        isFtnftInTreasury[_ftnft].index = index;
        fractionContractsInTreasury.pop();
    }

    //add MIGRATE FUNCTIONS
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

interface ITreasuryTracker {
    struct FractionIdData {
        address tnft;
        uint256 tnftTokenId;
        uint256 share;
        uint256 fractionId;
    }

    function tnftTreasuryPlaced(
        address tnft,
        uint256 tokenId,
        bool placed
    ) external;

    function ftnftTreasuryPlaced(
        address ftnft,
        uint256 tokenId,
        bool placed
    ) external;

    function updateFractionData(address ftnft, uint256 tokenId) external;

    function getFractionTokensDataInTreasury(address ftnft)
        external
        view
        returns (FractionIdData[] memory fData);
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