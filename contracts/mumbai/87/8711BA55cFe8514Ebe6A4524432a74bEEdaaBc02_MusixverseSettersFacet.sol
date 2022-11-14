// contracts/Musixverse/facets/MusixverseSettersFacet.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { MusixverseEternalStorage } from "../common/MusixverseEternalStorage.sol";
import { Modifiers } from "../common/Modifiers.sol";

contract MusixverseSettersFacet is MusixverseEternalStorage, Modifiers, AccessControl {
	function updateName(string memory newName) public onlyOwner {
		s.name = newName;
	}

	function updateSymbol(string memory newSymbol) public onlyOwner {
		s.symbol = newSymbol;
	}

	function updateContractURI(string memory newURI) public onlyOwner {
		s.contractURI = newURI;
	}

	function updateBaseURI(string memory newURI) public onlyOwner {
		s.baseURI = newURI;
	}

	function updatePlatformFeePercentage(uint8 newPlatformFeePercentage) public onlyOwner {
		s.PLATFORM_FEE_PERCENTAGE = newPlatformFeePercentage;
	}

	function updateReferralCutPercentage(uint8 newReferralCutPercentage) public onlyOwner {
		s.REFERRAL_CUT = newReferralCutPercentage;
	}

	function verifyArtistAndGrantMinterRole(address artistAddress, string memory username) public virtual {
		// Check that the calling account has the admin role
		require(hasRole(s.ADMIN_ROLE, msg.sender), "Caller does not have admin role");
		// Grant the minter role to the verified artist
		_setupRole(s.MINTER_ROLE, artistAddress);
		// Trigger an event
		emit ArtistVerified(msg.sender, artistAddress, username, username);
	}

	function grantAdminRole(address adminAddress) public virtual onlyOwner {
		// Grant the minter role to the verified artist
		_setupRole(s.ADMIN_ROLE, adminAddress);
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

// contracts/Musixverse/common/MusixverseEternalStorage.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { MusixverseAppStorage } from "../libraries/LibMusixverseAppStorage.sol";

contract MusixverseEternalStorage {
	MusixverseAppStorage internal s;
}

// contracts/Musixverse/common/Modifiers.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";

contract Modifiers {
	modifier onlyOwner() {
		LibDiamond.enforceIsContractOwner();
		_;
	}

	/***********************************|
    |              Events               |
    |__________________________________*/

	event TokenCreated(address indexed creator, uint256 indexed trackId, uint256 indexed tokenId, uint256 price, uint256 localTokenId);

	event TrackMinted(
		address indexed creator,
		uint256 indexed trackId,
		uint256 maxTokenId,
		uint256 price,
		string URIHash,
		string indexed indexedURIHash
	);

	event TokenPurchased(uint256 indexed tokenId, address indexed referrer, address previousOwner, address indexed newOwner, uint256 price);

	event TokenPriceUpdated(address indexed caller, uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice);

	event TokenOnSaleUpdated(address indexed caller, uint256 indexed tokenId, bool onSale);

	event TokenCommentUpdated(address indexed caller, uint256 indexed tokenId, string previousComment, string newComment);

	event ArtistVerified(address indexed caller, address indexed artistAddress, string username, string indexed indexedUsername);
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

// contracts/Musixverse/libraries/LibMusixverseAppStorage.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

/// @dev Note: This contract is meant to declare any storage and is append-only. DO NOT modify old variables!

import { Counters } from "./LibCounters.sol";

/***********************************|
|    Variables, structs, mappings   |
|__________________________________*/

struct TrackNftCreationData {
	uint16 amount;
	uint256 price;
	string URIHash;
	string unlockableContentURIHash;
	address[] collaborators;
	uint16[] percentageContributions;
	uint16 resaleRoyaltyPercentage;
	bool onSale;
	uint256 unlockTimestamp;
}

struct Track {
	string metadataHash;
	string unlockableContentHash;
	address artistAddress;
	uint16 resaleRoyaltyPercentage;
	uint256 unlockTimestamp;
	uint256 listingPrice;
	uint256 minTokenId;
	uint256 maxTokenId;
}

struct Token {
	uint256 trackId;
	uint256 price;
	bool onSale;
	bool soldOnce;
}

struct RoyaltyInfo {
	address payable recipient;
	uint256 percentage;
}

struct MusixverseAppStorage {
	string name;
	string symbol;
	string contractURI;
	string baseURI;
	uint8 PLATFORM_FEE_PERCENTAGE;
	address payable PLATFORM_ADDRESS;
	// Cut percentage relative to PLATFORM_FEE_PERCENTAGE
	uint8 REFERRAL_CUT;
	// Role identifier for the admin role
	bytes32 ADMIN_ROLE;
	// Role identifier for the minter role
	bytes32 MINTER_ROLE;
	Counters.Counter mxvLatestTokenId;
	Counters.Counter totalTracks;
	// Mapping from track ID to track data
	mapping(uint256 => Track) trackNFTs;
	// Mapping from token ID to token data
	mapping(uint256 => Token) tokens;
	// Mapping from token ID to owner address
	mapping(uint256 => address) owners;
	// Mapping from track ID to royalty info
	mapping(uint256 => RoyaltyInfo[]) royalties;
	// Mapping from token ID to comment
	mapping(uint256 => string) commentWall;
}

library LibMusixverseAppStorage {
	function diamondStorage() internal pure returns (MusixverseAppStorage storage ds) {
		assembly {
			ds.slot := 0
		}
	}

	function abs(int256 x) internal pure returns (uint256) {
		return uint256(x >= 0 ? x : -x);
	}
}

// contracts/Musixverse/libraries/Counters.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.4;

/*
█████    █████  ████   ████  ████    ████
██████  ██████   ████ ████   ████    ████
████ ████ ████     █████      ████  ████
████  ██  ████   ████ ████      ██████
████      ████  ████   ████      ████
*/

/**
 * @title Counters
 * @author Pushpit (@pushpit07)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC1155 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
	struct Counter {
		// This variable should never be directly accessed by users of the library: interactions must be restricted to
		// the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
		// this feature: see https://github.com/ethereum/solidity/issues/4637
		uint256 _value; // default: 0
	}

	function current(Counter storage counter) internal view returns (uint256) {
		return counter._value;
	}

	function increment(Counter storage counter, uint256 amount) internal {
		require(amount > 0, "Counter: increment amount should be greater than 0");
		unchecked {
			counter._value += amount;
		}
	}

	function decrement(Counter storage counter, uint256 amount) internal {
		require(amount > 0, "Counter: decrement amount should be greater than 0");
		uint256 value = counter._value;
		require(value > 0, "Counter: decrement overflow");
		require(value - amount >= 0, "Counter: difference should be greater than or equal to 0");
		unchecked {
			counter._value = value - amount;
		}
	}

	function reset(Counter storage counter) internal {
		counter._value = 0;
	}
}

// contracts/shared/libraries/LibDiamond.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamond standard.

library LibDiamond {
	bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("musixverse.diamond.storage");

	struct FacetAddressAndPosition {
		address facetAddress;
		uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
	}

	struct FacetFunctionSelectors {
		bytes4[] functionSelectors;
		uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
	}

	struct DiamondStorage {
		// maps function selector to the facet address and
		// the position of the selector in the facetFunctionSelectors.selectors array
		mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
		// maps facet addresses to function selectors
		mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
		// facet addresses
		address[] facetAddresses;
		// Used to query if a contract implements an interface.
		// Used to implement ERC-165.
		mapping(bytes4 => bool) supportedInterfaces;
		// owner of the contract
		address contractOwner;
	}

	function diamondStorage() internal pure returns (DiamondStorage storage ds) {
		bytes32 position = DIAMOND_STORAGE_POSITION;
		assembly {
			ds.slot := position
		}
	}

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function setContractOwner(address _newOwner) internal {
		DiamondStorage storage ds = diamondStorage();
		address previousOwner = ds.contractOwner;
		ds.contractOwner = _newOwner;
		emit OwnershipTransferred(previousOwner, _newOwner);
	}

	function contractOwner() internal view returns (address contractOwner_) {
		contractOwner_ = diamondStorage().contractOwner;
	}

	function enforceIsContractOwner() internal view {
		require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
	}

	event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

	// Internal function version of diamondCut
	function diamondCut(
		IDiamondCut.FacetCut[] memory _diamondCut,
		address _init,
		bytes memory _calldata
	) internal {
		for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
			IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
			if (action == IDiamondCut.FacetCutAction.Add) {
				addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
			} else if (action == IDiamondCut.FacetCutAction.Replace) {
				replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
			} else if (action == IDiamondCut.FacetCutAction.Remove) {
				removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
			} else {
				revert("LibDiamondCut: Incorrect FacetCutAction");
			}
		}
		emit DiamondCut(_diamondCut, _init, _calldata);
		initializeDiamondCut(_init, _calldata);
	}

	function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
		require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
		DiamondStorage storage ds = diamondStorage();
		require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
		uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
		// add new facet address if it does not exist
		if (selectorPosition == 0) {
			addFacet(ds, _facetAddress);
		}
		for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
			bytes4 selector = _functionSelectors[selectorIndex];
			address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
			require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
			addFunction(ds, selector, selectorPosition, _facetAddress);
			selectorPosition++;
		}
	}

	function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
		require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
		DiamondStorage storage ds = diamondStorage();
		require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
		uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
		// add new facet address if it does not exist
		if (selectorPosition == 0) {
			addFacet(ds, _facetAddress);
		}
		for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
			bytes4 selector = _functionSelectors[selectorIndex];
			address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
			require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
			removeFunction(ds, oldFacetAddress, selector);
			addFunction(ds, selector, selectorPosition, _facetAddress);
			selectorPosition++;
		}
	}

	function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
		require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
		DiamondStorage storage ds = diamondStorage();
		// if function does not exist then do nothing and return
		require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
		for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
			bytes4 selector = _functionSelectors[selectorIndex];
			address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
			removeFunction(ds, oldFacetAddress, selector);
		}
	}

	function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
		enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
		ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
		ds.facetAddresses.push(_facetAddress);
	}

	function addFunction(
		DiamondStorage storage ds,
		bytes4 _selector,
		uint96 _selectorPosition,
		address _facetAddress
	) internal {
		ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
		ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
		ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
	}

	function removeFunction(
		DiamondStorage storage ds,
		address _facetAddress,
		bytes4 _selector
	) internal {
		require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
		// an immutable function is a function defined directly in a diamond
		require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
		// replace selector with last selector, then delete last selector
		uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
		uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
		// if not the same then replace _selector with lastSelector
		if (selectorPosition != lastSelectorPosition) {
			bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
			ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
			ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
		}
		// delete the last selector
		ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
		delete ds.selectorToFacetAndPosition[_selector];

		// if no more selectors for facet address then delete the facet address
		if (lastSelectorPosition == 0) {
			// replace facet address with last facet address and delete last facet address
			uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
			uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
			if (facetAddressPosition != lastFacetAddressPosition) {
				address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
				ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
				ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
			}
			ds.facetAddresses.pop();
			delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
		}
	}

	function initializeDiamondCut(address _init, bytes memory _calldata) internal {
		if (_init == address(0)) {
			require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
		} else {
			require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
			if (_init != address(this)) {
				enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
			}
			(bool success, bytes memory error) = _init.delegatecall(_calldata);
			if (!success) {
				if (error.length > 0) {
					// bubble up the error
					revert(string(error));
				} else {
					revert("LibDiamondCut: _init function reverted");
				}
			}
		}
	}

	function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
		uint256 contractSize;
		assembly {
			contractSize := extcodesize(_contract)
		}
		require(contractSize > 0, _errorMessage);
	}
}

// contracts/shared/interfaces/IDiamondCut.sol
// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.0;

interface IDiamondCut {
	enum FacetCutAction {
		Add,
		Replace,
		Remove
	}
	// Add=0, Replace=1, Remove=2

	struct FacetCut {
		address facetAddress;
		FacetCutAction action;
		bytes4[] functionSelectors;
	}

	/// @notice Add/replace/remove any number of functions and optionally execute
	///         a function with delegatecall
	/// @param _diamondCut Contains the facet addresses and function selectors
	/// @param _init The address of the contract or facet to execute _calldata
	/// @param _calldata A function call, including function selector and arguments
	///                  _calldata is executed with delegatecall on _init
	function diamondCut(
		FacetCut[] calldata _diamondCut,
		address _init,
		bytes calldata _calldata
	) external;

	event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}