// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "./ColorableRegistry.sol";
import "./Ownable.sol";
import "./ICrayonStorage.sol";
import "./ColorableOwnershipManager.sol";

contract ColoringManager is Ownable {

    event ApplyColor(
        address indexed collection,
        uint256 indexed tokenId,
        bytes indexed colorMap 
    );

    ColorableOwnershipManager public ownershipManager;
    ICrayonStorage public crayonStorage;
    ColorableRegistry public colorableRegistry;

    constructor(address ownershipManager_, address crayonStorage_, address colorableRegistry_) {
        setOwnershipManager(ownershipManager_);
        setCrayonStorage(crayonStorage_);
        setCrayonRegistry(colorableRegistry_);
    }

    function setOwnershipManager(address ownershipManager_) public onlyOwner {
        require(address(ownershipManager_) != address(0x0), "ColoringManager#setOwnershipManager: NULL_CONTRACT_ADDRESS");
        ownershipManager = ColorableOwnershipManager(ownershipManager_);
    }

    function setCrayonStorage(address crayonStorage_) public onlyOwner {
        require(address(crayonStorage_) != address(0x0), "ColoringManager#setCrayonStorage: NULL_CONTRACT_ADDRESS");
        crayonStorage = ICrayonStorage(crayonStorage_);
    }

    function setCrayonRegistry(address colorableRegistry_) public onlyOwner {
        require(address(colorableRegistry_) != address(0x0), "ColoringManager#setCrayonRegistry: NULL_CONTRACT_ADDRESS");
        colorableRegistry = ColorableRegistry(colorableRegistry_);
    }

    function colorInCanvas(address collection, uint256 tokenId, string[] memory traitTypes, string[] memory traitNames, uint256[] memory areasToColor, uint256[] memory colorIds) public {
        require(colorableRegistry.registeredColorableCollections(collection), "ColoringManager#colorInCanvas: COLLECTION_NOT_REGISTERED");
        // verify that caller owns tokenId in collection, also verifies that the token exists
        require(ownershipManager.ownerOf(collection, tokenId) == msg.sender, "ColoringManager#colorInCanvas: UNAUTHORIZED");
        // verify crayon ownership & colors exist
        // loop through all colors, check if caller owns enough crayons
        uint256 _loopThrough = colorIds.length;

        // loop through all colorIds and mark down the colorIds that are requested in this request
        uint256[] memory numColorsNeeded = new uint256[](_loopThrough);
        for (uint256 i = 0; i < _loopThrough; i++) {
            numColorsNeeded[colorIds[i]]++;
        }
        
        for (uint256 i = 0; i < _loopThrough; i++) {
            uint256 _numColorsNeeded = numColorsNeeded[i];
            if (_numColorsNeeded > 0) {
                require(_numColorsNeeded <= crayonStorage.balanceOf(msg.sender, i), "ColoringManager#colorInCanvas: INSUFFICIENT_CRAYON_BALANCE");
            }
        }

        // verify colorMapping
        ColorableSectionMap _colorableSectionMap = colorableRegistry.collectionColorableSectionMaps(collection);
        // TODO: verify the colorableSectionMapping contract is set
        require(address(_colorableSectionMap) != address(0x0), "ColoringManager#colorInCanvas: COLORABLE_SECTION_MAP_NOT_SET"); 
        _colorableSectionMap.verifyColorMap(traitTypes, traitNames, areasToColor);
        require(areasToColor.length == colorIds.length, "ColoringManager#colorInCanvas: COLOR_LENGTH_MISMATCH");

        emit ApplyColor(collection, tokenId, abi.encode(traitTypes, traitNames, areasToColor, colorIds)); 
    }

}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "./ColorableSectionMap.sol";

// handles registrations
abstract contract ColorableRegistry {
    mapping(address => bool) public registeredColorableCollections;
    mapping(address => ColorableSectionMap) public collectionColorableSectionMaps;

    function _setIsRegisteredForColorableCollection(address _collection, address _colorableSectionMap, bool _isRegistered) internal {
        registeredColorableCollections[_collection] = _isRegistered;
        // TODO: verify that the colorableSectionMap implements the correct interface
        collectionColorableSectionMaps[_collection] = ColorableSectionMap(_colorableSectionMap);
    }
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed oldOwner_,
        address indexed newOwner_
    );

    constructor() {
        owner = msg.sender;
    }

    function _onlyOwner() internal view {
      require(owner == msg.sender, "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);
    }

    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(
            newOwner_ != address(0x0),
            "Ownable: new owner is the zero address!"
        );
        _transferOwnership(newOwner_);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ICrayonStorage is IERC1155 {
    /**
        required before colouring to allow colorContract to burn crayons
    */
    function setApprovalForColorContract(bool approved) external;
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Ownable.sol";
// import "./IColorableOwnershipManager.sol";

interface IStateReceiver {
	function onStateReceive(uint256 stateId, bytes calldata data) external;
}

contract ColorableOwnershipManager is 
    AccessControl
{
    bytes32 public constant STATE_RECEIVER = keccak256("STATE_RECEIVER");
    bytes32 public constant OWNERSHIP_SETTER_ROLE = keccak256("OWNERSHIP_SETTER_ROLE");
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);        
        _grantRole(OWNERSHIP_SETTER_ROLE, msg.sender); // TODO: make this role only give access to certain collections
    }

    mapping(address => mapping(uint256 => address)) public ownerOf;
    mapping(address => mapping(address => uint256)) public balanceOf;
    IStateReceiver public stateReceiver;

    function setStateReceiver(address newStateReceiver) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stateReceiver = IStateReceiver(newStateReceiver);
        grantRole(STATE_RECEIVER, newStateReceiver);
    }

    function syncOwnership(address collection, uint256 tokenId, address newOwner) public virtual onlyRole(STATE_RECEIVER) {
        address _oldOwner = ownerOf[collection][tokenId];
        balanceOf[collection][_oldOwner]--;
        ownerOf[collection][tokenId] = newOwner;
        balanceOf[collection][newOwner]++;
    }

    // length of owners and length of tokenIds should be the totalSupply of the entire collection to ensure consistency with Root Contract
    function setOwnershipData(address collection, address[] memory owners, uint256[] memory tokenIds) public onlyRole(OWNERSHIP_SETTER_ROLE) {
        // TODO: restrict only owner of the collection to execute method
        uint256 _loopThrough = tokenIds.length;
        require(_loopThrough == owners.length, "ColorableOwnership: owners and tokenIds length mismatch");

        for (uint256 i = 0; i < _loopThrough; i++) {
            uint256 _tokenId = tokenIds[i];
            address _owner = owners[i];
            ownerOf[collection][_tokenId] = _owner;
            balanceOf[collection][_owner]++;
        }     
    }    

    function resetOwnershipData(address collection, uint256 totalSupply) public onlyRole(OWNERSHIP_SETTER_ROLE) {
        // TODO: restrict only owner of the collection to execute method
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            address _owner = ownerOf[collection][i];
            balanceOf[collection][_owner] = 0;
            ownerOf[collection][i] = address(0x0);
        }
    }
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "./Ownable.sol";

abstract contract ColorableSectionMapBase {
    // mapping of traitTypes, traitNames, and mapping of colorableSections for the trait
    mapping(string => mapping(string => mapping(uint256 => bool))) public colorableAreas;
    mapping(string => mapping(string => uint256)) public numColorableAreas;

    // pass in an array of arrays 
    function _setColorableAreas(string[] memory _traitTypes, string[] memory _traitNames, uint256[] memory _colorableAreas) internal virtual {
        require(_traitTypes.length == _traitNames.length && _traitNames.length == _colorableAreas.length, 
            "ColorableSectionMap#PARAM_LENGTH_MIS_MATCH");
        uint256 _loopThrough = _traitTypes.length;
        for (uint256 i = 0; i < _loopThrough; i++) {
            colorableAreas[_traitTypes[i]][_traitNames[i]][_colorableAreas[i]] = true;
            numColorableAreas[_traitTypes[i]][_traitNames[i]]++;
        }
    }

    function verifyColorMap(string[] memory traitTypes, string[] memory traitNames, uint256[] memory areasToColor) public view {
        require(traitTypes.length == traitNames.length && 
            traitNames.length == areasToColor.length, "ColorableSectionMap#colorInCanvas: COLORMAP_LENGTH_MISMATCH");
        uint256 _loopThrough = traitTypes.length;
        for (uint256 i = 0; i < _loopThrough; i++) {
            string memory _traitType = traitTypes[i];
            string memory _traitNames = traitNames[i];
            uint256 _areaToColor = areasToColor[i];
            bool _isColorableArea = colorableAreas[_traitType][_traitNames][_areaToColor];
            require(_isColorableArea, "verifyColorMap#colorInCanvas: AREA_NOT_COLORABLE");
        }
    }
}

contract ColorableSectionMap is ColorableSectionMapBase, Ownable {
    address public colorableCollection;
    string public name;

    constructor(address _collection, string memory _name) {
        colorableCollection = _collection;
        name = _name;
    }

    function setColorableAreas(string[] memory _traitTypes, string[] memory _traitNames, uint256[] memory _colorableAreas) public onlyOwner {
        _setColorableAreas(_traitTypes, _traitNames, _colorableAreas);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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