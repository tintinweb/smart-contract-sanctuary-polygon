// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IAnchainSoulbound721.sol";
import "./ISoulboundAccess.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SoulboundManager is IAnchainSoulbound721{
    using Counters for Counters.Counter;
    //multi wallets for tighter requirements and multisig changability
    // bytes32 public constant COLD_WALLET = keccak256("COLD_WALLET");
    // bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    // bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    // bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // bool[5] public roles = [false, false, false, false, false];
    // address[5] public roleAddresses;

    // uint256 public constant adminRoles = 5;
    // uint256 public sigs = 0;
    // bool[5] private _signatures = [false, false, false, false, false];
    struct PreloadedMetadata{
        uint256 index;
        string uri;
        address verifiedUser;
    }
    bool paused = false;

    event ManagedContract(uint256 index, address a);
    event AddedPreloadedSoulbound(uint256 index, address user, string uri);

    //address[] public soulboundAddresses;

    //IAnchainSoulbound721[] private anchainSoulbound721Contracts;
   // mapping (address => PreloadedMetadata) loadedSoulbound;
    mapping (uint256 => mapping (address => PreloadedMetadata)) loadedSoulbound;
    Counters.Counter private collectionsCounter;
    mapping (uint256 => IAnchainSoulbound721) private soulboundContracts;
    mapping (uint256 => address) contractAddresses;
    ISoulboundAccess accessContract;

    //need to add, add certifications to store nft uri to AnchainSoulbound721.sol
    //^^ that wont work silly, you need to include custom names for name time and place minted.


    //constructor
    constructor(address managerContract) {
        //_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        accessContract = ISoulboundAccess(managerContract);
    }

    //TODO: Change Access Control with Cold hot wallet

    modifier isNotPaused(){
        require(!paused, "Contract Paused!");
        _;
    }

    function changeAccessControlContract(address newContract) public {
        require(accessContract.accessIsNotPaused(), "Access is Paused");
        require(accessContract.isColdHotWallet(msg.sender), "Sender is not Manager Role");
        accessContract = ISoulboundAccess(newContract);
    }

    function pauseManager() public {
        require(accessContract.accessIsNotPaused(), "Access is Paused");
        require(accessContract.isManagerRole(msg.sender), "Sender is not Manager Role");
        require(!paused, "Manager already paused!");
        paused = true;
    }

    function unpauseManager() public{
        require(accessContract.accessIsNotPaused(), "Access is Paused");
        require(accessContract.isManagerRole(msg.sender), "Sender is not Manager Role");
        require(paused, "Manager already unpaused!");
        paused = false;
    }

    function preloadSoulbound(uint256 index, address user, string memory uri) public {
        require(accessContract.accessIsNotPaused(), "Access is Paused");
        require(accessContract.isManagerRole(msg.sender), "Sender is not Manager Role");
        loadedSoulbound[index][user] = PreloadedMetadata(index, uri, user);
        emit AddedPreloadedSoulbound(index, user, uri);
    }
    function batchPreloadSoulbound(uint256[] memory index, address[] memory user, string[] memory uri, uint256 length) public {
        require(accessContract.accessIsNotPaused(), "Access is Paused");
        require(accessContract.isManagerRole(msg.sender), "Sender is not Manager Role");
        for(uint256 i = 0; i < length; i++){
            preloadSoulbound(index[i], user[i], uri[i]);
        }
    }

    //pause check
    function mintPreloaded(uint256 index) public{
        require(loadedSoulbound[index][msg.sender].verifiedUser!=address(0), "No NFT Preloaded for this address");
        soulboundContracts[index].safeMint(msg.sender, loadedSoulbound[index][msg.sender].uri);
        delete loadedSoulbound[index][msg.sender];

    }


    // Add contract to manager
    function addContract(address contractAddress) public isNotPaused{
        require(accessContract.accessIsNotPaused(), "Access is Paused");
        require(accessContract.isManagerRole(msg.sender), "Sender is not Manager Role");
        uint256 index = collectionsCounter.current();
        contractAddresses[index] = contractAddress;
        soulboundContracts[index] = IAnchainSoulbound721(contractAddress);
        collectionsCounter.increment();
    }

    function getSoulboundContractAddress(uint256 index) public isNotPaused returns (address a){
        require(accessContract.accessIsNotPaused(), "Access is Paused");
        require(accessContract.isManagerRole(msg.sender), "Sender is not Manager Role");

        return contractAddresses[index];

    }
    // TODO: Remove contracts from manager

    // TODO: Get all contracts
    function getAllContracts() public{
        for(uint256 i = 0; i < collectionsCounter.current(); i++){
            emit ManagedContract(i, contractAddresses[i]);
        }
    }

    // Mint nft from ith contract with j uri
    function mintSoulbound(address to, uint256 index, string memory uri) public isNotPaused {
        require(accessContract.accessIsNotPaused(), "Access is Paused");
        require(accessContract.isMinterRole(msg.sender), "Sender is not Minter Role");
        soulboundContracts[index].safeMint(to, uri);
    }

    // Transfer
    function transferSoulbound(address from, address to, uint256 tokenId, uint256 index) public isNotPaused{
        require(accessContract.accessIsNotPaused(), "Access is Paused");
        require(accessContract.isTransferRole(msg.sender), "Sender is not Transfer Role");
        soulboundContracts[index].safeTransferFrom(from, to, tokenId);
    }

    // TODO: Batch Transfer: Later

    // Burn
    function burnSoulbound(uint256 tokenId, uint256 index) public isNotPaused{
        require(accessContract.accessIsNotPaused(), "Access is Paused");
        require(accessContract.isBurnerRole(msg.sender), "Sender is not Burner Role");
        soulboundContracts[index].burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract IAnchainSoulbound721{
    function pause() public {}
    function unpause() public {}
    function safeMint(address to, string memory uri) public {}
    function burn(uint256 tokenId) public {}
    function tokenURI(uint256 tokenId) public view returns (string memory) {}
    function safeTransferFrom( address from, address to, uint256 tokenId ) public virtual {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface ISoulboundAccess {
  function BURNER_ROLE (  ) external view returns ( bytes32 );
  function COLD_HOT_WALLET (  ) external view returns ( bytes32 );
  function COLD_WALLET (  ) external view returns ( bytes32 );
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function MANAGER_ROLE (  ) external view returns ( bytes32 );
  function MINTER_ROLE (  ) external view returns ( bytes32 );
  function TRANSFER_ROLE (  ) external view returns ( bytes32 );
  function accessIsNotPaused (  ) external view returns ( bool ret );
  function addRoles (  ) external view returns ( bool );
  function assignRole ( address a, bytes32 role ) external;
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function isBurnerRole ( address a ) external view returns ( bool ret );
  function isColdHotWallet ( address a ) external view returns ( bool ret );
  function isColdWallet ( address a ) external view returns ( bool ret );
  function isManagerRole ( address a ) external view returns ( bool ret );
  function isMinterRole ( address a ) external view returns ( bool ret );
  function isRole ( address a ) external view returns ( bool ret );
  function isTransferRole ( address a ) external view returns ( bool ret );
  function pauseAccess (  ) external;
  function paused (  ) external view returns ( bool );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function roleHolders ( uint256, uint256 ) external view returns ( bool );
  function signToOverwrite ( bytes32 role ) external;
  function sigs (  ) external view returns ( uint256 );
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function unpauseAccess (  ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
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

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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