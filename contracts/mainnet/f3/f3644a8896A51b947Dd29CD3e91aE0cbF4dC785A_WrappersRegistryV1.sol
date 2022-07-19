//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CryptovoxelsAccessControl.sol";
import "./Wrappers/ICollectionWrapper.sol";
/**
 * @dev This is a contract dedicating to registering CollectionWrappers made around other contracts in case they don't support ERC721 or ERC1155.
 * If a contract doesn't support ERC721 or ERC1155 we don't know how to interact with them.
 * Therefore we use wrappers (or proxies) to standardize them and tell us how to interact with those contracts.
 */
contract WrappersRegistryV1 is Pausable {
	/// Contract name
    string private _name;
	///@dev Access control address
    address internal _accessControl;

	/**
	* Wrapper struct
	* @dev implementation - the contract the wrapper is for
	* @dev wrapper - the address of the wrapper
	* @dev name - name of the wrapper
	* @dev deleted - Know if wrapper is deleted or not.
	*/
	struct Wrapper {
		address implementation;
		address wrapper;
		string name;
		bool deleted;
	}

	event Registered(uint indexed id, address indexed implementation_,address indexed wrapper, string name);
	event Unregistered(uint indexed id, string name);

	mapping (address => uint) WrapperToId;
	mapping (string => uint) WrapperNameToId;
	mapping (address => uint) ImplementationToId;
	mapping (address => bool) registeredImplementationLookup;

	Wrapper[] wrappers;

	///@dev name of the contract
    function name() public view virtual returns (string memory) {
        return _name;
    }

	modifier whenAddressFree(address _addr) {
		if (isRegistered(_addr))
			return;
		_;
	}

	modifier whenWrapper(uint _id) {
		require(!wrappers[_id].deleted);
		_;
	}

	modifier whenNameFree(string memory name__) {
		if (WrapperNameToId[name__] != 0)
			return;
		_;
	}

    modifier onlyMember(address _addr){
        require(CryptovoxelsAccessControl(_accessControl).isMember(_addr),'Functionality limited to members');
    _;
    }

	constructor (address _accessControlImpl){
		_name = "Voxels Marketplace wrappers registy v1";
		_accessControl = _accessControlImpl;

		//@dev we add address 0 as the first wrapper, so we know index 0 is invalid
		WrapperToId[address(0)]=0;
		WrapperNameToId['']=0;
		ImplementationToId[address(0)]=0;
		wrappers.push(Wrapper(
			address(0),
            address(0),
			'',
            false
		));
	}

    function togglePause() public onlyMember(msg.sender){
        if(this.paused()){
            _unpause();
        }else{
            _pause();
        }
    }
	/**
	 * @notice remove a wrapper, its name and implementation from the registry
	 * @param _id uint, Id of the wrapper.
	 */
	function unregister(uint _id)
		external
		whenWrapper(_id)
		onlyMember(msg.sender)
	{
		delete WrapperToId[wrappers[_id].wrapper];
		delete WrapperNameToId[wrappers[_id].name];
		delete ImplementationToId[wrappers[_id].implementation];
		delete registeredImplementationLookup[wrappers[_id].implementation];
		wrappers[_id].deleted = true;

        emit Unregistered(_id, wrappers[_id].name);
	}
	/**
	 * @notice Get a wrapper given an ID
	 * @param _id uint, Id of the wrapper.
	 */
	function getWrapper(uint _id)
		external
		view
		whenWrapper(_id)
		returns (
			address implementation,
			address wrapper,
			string memory name_
		)
	{
		Wrapper storage t = wrappers[_id];
		implementation = t.implementation;
		wrapper = t.wrapper;
		name_ = t.name;
	}
	/**
	 * @notice Get a wrapper from its address
	 * @param _addr address, address of the wrapper
	 */
	function fromAddress(address _addr)
		external
		view
		whenWrapper(WrapperToId[_addr])
		returns (
			uint id_,
			address implementation_,
			address wrapper_,
			string memory name_
		)
	{
		id_ = WrapperToId[_addr];
		Wrapper storage t = wrappers[id_];
		implementation_ = t.implementation;
		wrapper_ = t.wrapper;
		name_ = t.name;
	}
	/**
	 * @notice Get a wrapper from the implementation address
	 * @param _addr address, address of the implementation
	 */
	function fromImplementationAddress(address _addr)
		public
		view
		whenWrapper(ImplementationToId[_addr])
		returns (
			uint id_,
			address implementation_,
			address wrapper_,
			string memory name_
		)
	{
		id_ = ImplementationToId[_addr];
		Wrapper storage t = wrappers[id_];
		implementation_ = t.implementation;
		wrapper_ = t.wrapper;
		name_ = t.name;
	}
	/**
	 * @notice Get a wrapper from its name
	 * @param name__ string, the name of the wrapper
	 */
	function fromName(string memory name__)
		external
		view
		whenWrapper(WrapperNameToId[name__])
		returns (
			uint id_,
			address implementation_,
			address wrapper_,
			string memory name_
		)
	{
		id_ = WrapperNameToId[name__];
		Wrapper storage t = wrappers[id_];
		implementation_ = t.implementation;
		wrapper_ = t.wrapper;
		name_ = t.name;
	}

	/**
	 * @notice register an implementation, its wrapper and the wrapper's name
	 * @param implementation_ address of the implementation
	 * @param wrapper_ address of the wrapper contract
	 * @param name_ string
	 */
	function register(
		address implementation_,
		address wrapper_,
		string memory name_
	)
		public
        whenNotPaused
		whenAddressFree(wrapper_)
		whenNameFree(name_)
		onlyMember(msg.sender)
		returns (bool registered)
	{
		require(IERC165(wrapper_).supportsInterface(type(ICollectionWrapper).interfaceId),"Contract does not support Wrapper interface");
		wrappers.push(Wrapper(
			implementation_,
            wrapper_,
			name_,
            false
		));
        uint length = wrappers.length;
		WrapperToId[wrapper_] = length -1;
		WrapperNameToId[name_] = length -1;
		registeredImplementationLookup[implementation_] =true;
		ImplementationToId[implementation_] = length -1;

		emit Registered(
            wrappers.length - 1,
			implementation_,
			wrapper_,
			name_
		);
		return true;
	}
	///@dev check if wrapper address exists
    function isRegistered(address _address) public view returns(bool) {
        return WrapperToId[_address] != 0;
    }

	/**
	 * @param _impl implementation address
	 * @return _isWrapped bool whether or not the implementation is wrapped
	 */
	function isWrapped(address _impl) public view returns (bool _isWrapped){
		return registeredImplementationLookup[_impl];
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// Contract already deployed

contract CryptovoxelsAccessControl is AccessControl, Ownable {

  /// @dev Create the admin role, with `_msgSender` as a first member.
  constructor () {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /// @dev Restricted to members of Cryptovoxels.
  modifier onlyMember() {
    require(isMember(_msgSender()), "Restricted to members.");
    _;
  }
  /// @dev Return `true` if the `account` belongs to Cryptovoxels.
  function isMember(address account)
    public view returns (bool)
  {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }
  /// @dev Add a member of Cryptovoxels.
  function addMember(address account) external onlyMember {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }
  /// @dev Remove yourself from Cryptovoxels team.
  function leave() external {
    renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

    /// @dev Remove yourself from Cryptovoxels team.
  function removeMember(address account) external onlyMember {
    revokeRole(DEFAULT_ADMIN_ROLE, account);
  }

    /// @dev Override revokeRole, owner Of Contract should always be an admin
    function revokeRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        require(account != owner(),'Cant revoke role of owner of contract');
        super._revokeRole(role, account);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
/**
 * INTERFACE of CollectionWrapper. Extend this for your wrapper.
 * The goal of this contract is to wrap an NFT smart contract that does not support ERC721 or ERC1155
 * This way the wrapper can tell us how to interact with a contract.
 */
interface ICollectionWrapper{

    /**
    * @dev This function should be public and should be overriden.
    * It should obtain an address and a tokenId as input and should return a uint256 value;
    * @dev This should be overriden with a set of instructions to obtain the balance of the user
    * When overriding this, if you do not need _tokenId, just ignore the input.
    * See ERC165 for help on interface support.
    * @param _user address of the user
    * @param _tokenId Token id of the NFT (if applicable)
    * @return bool
    * 
    */
    function balanceOf (address _user,uint _tokenId) external view  returns (uint256);

    /**
    * This function should be public and should be overriden.
    * It should obtain a uint256 token Id as input and should return an address (or address zero is no owner);
    * @dev This should be overriden and replaced with a set of instructions obtaining the owner of the given tokenId;
    *
    * @param _tokenId token id we want to grab the owner of.
    * @param _potentialOwner A potential owner, set address zero if no potentialOwner; This is necessary for ERC1155. Set zero address if none
    * @return address
    * 
    */
    function ownerOf(uint256 _tokenId,address _potentialOwner) external view  returns (address);

    /**
    * This function should be public and should be overriden.
    * It should obtain basic inputs to allow transfer of an NFT to another address.
    * @dev This should be overriden and replaced with a set of instructions telling your contract to transfer NFTs.
    *
    * @param _from Address of the owner
    * @param _to Address of the receiver
    * @param _tokenId token id we want to grab the owner of.
    * @param _quantity Quantity of the token to send; if your NFT doesn't have a quantity, just ignore.
    * @return address
    * 
    */
    function transferFrom(address _from, address _to,uint256 _tokenId,uint256 _quantity) external returns (bool);

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