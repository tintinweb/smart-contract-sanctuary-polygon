/**
 *Submitted for verification at polygonscan.com on 2022-06-20
*/

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @title Partially-automated admin controls
/// @author Peter T. Flynn
/// @notice Allows for role-based permission control over individual functions in arbitrary,
/// external contracts. Designed to be used as the "owner" of said external contracts.
/// @dev Many of the "getter" functions are not meant to be called on-chain, and are for
/// convenience only
contract AutomatedAdmin {

	// Up to eight different roles to which users may be assigned. Three are built-in, while
	// five more are available for creation. Built-in role indices are as follows:
	//	Admin 		=> 	0
	//	Safety		=>	1
	//	Automation	=>	2
	enum Roles {
		Admin, Safety, Automation,
		Unnamed01, Unnamed02, Unnamed03, Unnamed04, Unnamed05 
	}

	struct Slot0 {
		// Indicates whether [contractCall] is available to non-[Admin]s
		bool locked;
		// A bitmap indicating which roles are enabled versus disabled
		bytes1 roleMap;
		// The number of users currently assigned the [Admin] role
		uint240 adminCount;
	}

	struct Transaction {
		// The address which queued the transaction
		address addressCreator;
		// The address to call
		address addressTo;
		// The wei to be sent
		uint value;
		// The data to be sent in the call
		bytes data;
		// A human-legible description of the transaction
		string description;
	}

	// Bitmaps corresponding to a role, or multiple roles. For readability.
	bytes1 constant ADMIN = 0x01;
	bytes1 constant ADMIN_AND_SAFETY = 0x03;
	bytes1 constant ADMIN_SAFETY_AND_AUTOMATION = 0x07;

	// Gas saving storage slot
	Slot0 private slot0;
	// Bitmaps corresponding to a given user's roles
	mapping(address => bytes1) private roles;
	// A bitmap corresponding to which roles are allowed to call the given function within the
	// given contract address
	mapping(address => mapping(bytes4 => bytes1)) private permissions;
	// A [Transaction] struct corresponding to a hash constructed from the transaction's info
	mapping(bytes32 => Transaction) private transactions;
	// Human-legible names for each role
	string[8] private roleNames;

	/// @notice Emitted when the lock is engaged, or disengaged
	/// @param sender The transactor
	/// @param state [true] for locked, [false] for unlocked 
	event LockToggle(address indexed sender, bool state);
	/// @notice Emitted when a user is added to a role
	/// @param sender The transactor
	/// @param user The user added to the role
	/// @param role The index of the role
	event RoleAdd(address indexed sender, address indexed user, Roles role);
	/// @notice Emitted when a user is removed from a role
	/// @param sender The transactor
	/// @param user The user removed from the role
	/// @param role The index of the role
	event RoleRemove(address indexed sender, address indexed user, Roles role);
	/// @notice Emitted when a new role is created (enabled)
	/// @param sender The transactor
	/// @param role The index of the new role
	/// @param name The human-legible name for the role
	event RoleCreate(address indexed sender, Roles role, string name);
	/// @notice Emitted when a role is destroyed (disabled)
	/// @param sender The transactor
	/// @param role The index of the role
	event RoleDestroy(address indexed sender, Roles role);
	/// @notice Emitted when a role is renamed
	/// @param sender The transactor
	/// @param role The index of the role
	/// @param name The new name for the role
	event RoleRename(address indexed sender, Roles role, string name);
	/// @notice Emitted when permissions are set for a contract's function
	/// @param sender The transactor
	/// @param _contract The address of the external contract where the function resides
	/// @param functionSig The four-byte function signature
	/// @param _roles An array of role indexes which are allowed to call this function
	event SetPermissions(
		address indexed sender,
		address indexed _contract,
		bytes4 indexed functionSig,
		Roles[] _roles
	);
	/// @notice Emitted when an external contract is called
	/// @param sender The transactor
	/// @param _contract The address of the external contract
	/// @param value The wei sent to the contract
	/// @param data The data sent to the contract
	event ContractCall(address indexed sender, address indexed _contract, uint value, bytes data);
	/// @notice Emitted when a transaction is queued
	/// @param sender The transactor
	/// @param _hash The keccak256 hash which corresponds to the stored transaction
	/// @param to The external address which the transaction will interact with
	/// @param value The wei to be sent to the address in the transaction
	/// @param data The data to be sent in the transaction
	/// @param description The human-legible description of the transaction
	event TransactionQueue(
		address indexed sender,
		bytes32 indexed _hash,
		address indexed to,
		uint value,
		bytes data,
		string description
	);
	/// @notice Emitted when a transaction is sent by an admin
	/// @dev Refer to the [TransactionQueue] event with the same [_hash] for transaction info
	/// @param sender The transactor
	/// @param _hash The keccak256 hash which corresponds to the stored transaction
	event TransactionSend(
		address indexed sender,
		bytes32 indexed _hash
	);

	/// @notice Returned when attempting to queue a transaction which is missing vital data, or
	/// when attempting to call a hash which is missing a corresponding transaction
	/// @param index The index within the hash array for the malformed transaction (if applicable)
	error BadTransaction(uint index);
	/// @notice Returned when a transaction fails within a batch call
	/// @param index The index within the hash array of the failed transaction
	/// @param returnData The data returned by the failed transaction
	error BatchCallFailed(uint index, bytes returnData);
	/// @notice Returned when a contractCall() fails
	/// @param returnData The data returned by the failed transaction
	error CallFailed(bytes returnData);
	/// @notice Returns when an [Admin] attempts to remove their own address as an [Admin], and they
	/// are the only [Admin]
	error CannotRemoveLastAdmin();
	/// @notice Returns when a transaction was not supplied with the value required
	/// @param expected The amount of wei required
	/// @param given The amount of wei given
	error DifferentValue(uint expected, uint given);
	/// @notice Returned when the [Admin] has locked contract calls
	error Locked();
	/// @notice Returned when the requested change is invalid
	error NoChange();
	/// @notice Returned when the caller is not allowed to call the specific function
	error NotAuthorized();
	/// @notice Returned when a batch of transactions were not supplied with sufficient wei
	error NotEnoughValue();
	/// @notice Returned when an [Admin] attempts to modify a built-in role
	error PermanentRole();

	// Reverts when the caller does not have one of the required roles
	modifier canCall(bytes1 _roles) {
		if (_roles & roles[msg.sender] == 0)
			revert NotAuthorized();
		_;
	}

	// Constructs the built-in roles, and assigns the [msg.sender] to the [Admin] role
	constructor() {
		slot0.roleMap = ADMIN_SAFETY_AND_AUTOMATION;
		slot0.adminCount = 1;
		roleNames[0] = "Admin";
		roleNames[1] = "Safety";
		roleNames[2] = "Automation";
		roles[msg.sender] = ADMIN;
	}

	/// @notice Locks the contractCall() function, such that it can only be called
	/// by the [Admin] role
	function lock() external canCall(ADMIN_SAFETY_AND_AUTOMATION) {
		slot0.locked = true;
		emit LockToggle(msg.sender, true);
	}

	/// @notice Unlocks the contractCall() function, such that it will now obey set permissions
	function unlock() external canCall(ADMIN) {
		slot0.locked = false;
		emit LockToggle(msg.sender, false);
	}

	/// @notice Adds the given user to the given role
	/// @param user The user to be added to the role
	/// @param role The index of the role to add the user to
	function roleAdd(address user, Roles role) external canCall(ADMIN) {
		if (role == Roles.Admin && roles[user] & 0x01 == 0)
			slot0.adminCount++;
		roles[user] |= bytes1(0x01) << uint(role);
		emit RoleAdd(msg.sender, user, role);
	}

	/// @notice Removes the given user from the given role
	/// @param user The user to removed from the role
	/// @param role The index of the role to remove the user from
	function roleRemove(address user, Roles role) external canCall(ADMIN) {
		Slot0 memory _slot0 = slot0;
		if (role == Roles.Admin) {
			if (_slot0.adminCount == 1)
				revert CannotRemoveLastAdmin();
			if (roles[user] & ADMIN != 0)
				_slot0.adminCount--;
		}
		roles[user] ^= bytes1(0x01) << uint(role);
		slot0 = _slot0;
		emit RoleAdd(msg.sender, user, role);
	}

	/// @notice Enables, and names a new role
	/// @param role The index of the role to enable
	/// @param name A human-legible name for the role (not used programmatically)
	function roleCreate(Roles role, string calldata name) external canCall(ADMIN) {
		if (uint8(role) < 3)
			revert PermanentRole();
		bytes1 roleNew = bytes1(0x01) << uint(role);
		if (slot0.roleMap & roleNew != 0)
			revert NoChange();
		slot0.roleMap |= roleNew;
		roleNames[uint(role)] = name;
		emit RoleCreate(msg.sender, role, name);
	}

	/// @notice Disables a role, making it ineligible for function permissions
	/// @param role The index of the role to disable
	function roleDestroy(Roles role) external canCall(ADMIN) {
		if (uint8(role) < 3)
			revert PermanentRole();
		delete roleNames[uint(role)];
		slot0.roleMap ^= bytes1(0x01) << uint(role);
		emit RoleDestroy(msg.sender, role);
	}

	/// @notice Renames a role. This has no effect on contract operation, and is for convenience
	/// only.
	/// @param role The index of the role to rename
	/// @param name The new name for the role
	function roleRename(Roles role, string calldata name) external  canCall(ADMIN) {
		if (uint8(role) < 3)
			revert PermanentRole();
		if ((bytes1(0x01) << uint(role)) & slot0.roleMap == 0)
			revert NoChange();
		roleNames[uint(role)] = name;
		emit RoleRename(msg.sender, role, name);
	}

	/// @notice Sets the roles which are allowed to call a given function, within a given contract.
	/// The contract is designated by its address, and the function is designated by its four-byte
	/// signature.
	/// @param _contract The address of the contract
	/// @param functionSig The four-byte signature of the function
	/// @param _roles An array of role indices which are granted the ability to call the function
	function setPermissions(
		address _contract,
		bytes4 functionSig,
		Roles[] calldata _roles
	) external canCall(ADMIN) {
		permissions[_contract][functionSig] = rolesToBits(_roles);
		emit SetPermissions(msg.sender, _contract, functionSig, _roles);
	}

	/// @notice Calls the given contract with the given data, acting as the AutomatedAdmin contract.
	/// Only allows the call if the user has the appropriate permissions for the given function.
	/// @dev All transaction value is passed through. Function signature is read from [data].
	/// @param _contract The address of the contract to call
	/// @param data The data to pass to the call
	function contractCall(
		address _contract,
		bytes calldata data
	) payable external returns (bytes memory) {
		Slot0 memory _slot0 = slot0;
		if (_slot0.locked)
			revert Locked();
		bytes4 selector;
		assembly {
			selector := calldataload(data.offset)
		}
		if (roles[msg.sender] & _slot0.roleMap & permissions[_contract][selector] == 0)
			onlyAdmin();
		(bool success, bytes memory returnData) = _contract.call{value: msg.value}(data);
		if (!success)
			revert CallFailed(returnData);
		emit ContractCall(msg.sender, _contract, msg.value, data);
		return returnData;
	}

	/// @notice Allows any user in the [Admin], [Safety], or [Automation] roles to queue arbitrary
	/// transactions. A hash is returned which is used to call the transaction later. Storing
	/// transactions in this fashion is highly gas-inefficient, but is very convenient for [Admin]s
	/// who are less versed in the blockchain than some of their team members.
	/// @dev The hash is returned, but is also stored in an event for easy retrieval
	/// @param to The address to send the queued transaction to
	/// @param value The wei required by the queued transaction
	/// @param data The data to be sent in the queued transaction
	/// @param description A human-legible description of the transaction's purpose, and action(s)
	/// (not used programmatically)
	/// @return _hash A hash which corresponds to the transaction in storage. The queued
	/// transaction is referred to by this hash from here on out.
	function transactionQueue(
		address to,
		uint value,
		bytes calldata data,
		string calldata description
	) external canCall(ADMIN_SAFETY_AND_AUTOMATION) returns (bytes32 _hash) {
		if (to == address(0) || (data.length == 0 && value == 0))
			revert BadTransaction(0);
		_hash = keccak256(abi.encodePacked(to,value,data));
		transactions[_hash] = Transaction(msg.sender, to, value, data, description);
		emit TransactionQueue(msg.sender, _hash, to, value, data, description);
	}

	/// @notice Allows the [Admin] role to send a pre-queued transaction
	/// @dev Stored transactions are deleted after sending, successful or not
	/// @param _hash The hash for the transaction, given when it was queued
	/// @return success Whether the transaction completed successfully
	/// @return returnData The data returned by the contract call (may be empty)
	function transactionSend(
		bytes32 _hash
	) payable external canCall(ADMIN) returns (bool success, bytes memory returnData) {
		Transaction memory _tx = transactions[_hash];
		if (_tx.addressCreator == address(0))
			revert BadTransaction(0);
		if (msg.value != _tx.value)
			revert DifferentValue(_tx.value, msg.value);
		(success, returnData) = _tx.addressTo.call{value: _tx.value}(_tx.data);
		delete transactions[_hash];
		emit TransactionSend(msg.sender, _hash);
	}

	/// @notice Allows the [Admin] role to send a batch of pre-queued transactions in sequence
	/// @dev Stored transactions are deleted, only if all transactions are successful
	/// @param hashes An array of hashes corresponding to stored transactions
	/// @return returnData An array of data, corresponding to what was returned by each
	/// transaction, in order
	function transactionSendBatch(
		bytes32[] calldata hashes
	) payable external canCall(ADMIN) returns (bytes[] memory returnData) {
		returnData = new bytes[](hashes.length);
		uint remainingValue = msg.value;
		Transaction memory _tx;
		for (uint i; i < hashes.length;) {
			_tx = transactions[hashes[i]];
			if (_tx.addressCreator == address(0))
				revert BadTransaction(i);
			if (remainingValue < _tx.value)
				revert NotEnoughValue();
			(bool success, bytes memory _returnData) =
				_tx.addressTo.call{value: _tx.value}(_tx.data);
			if (!success)
				revert BatchCallFailed(i, _returnData);
			returnData[i] = _returnData;
			delete transactions[hashes[i]];
			emit TransactionSend(msg.sender, hashes[i]);
			unchecked {
				remainingValue -= _tx.value;
				++i;
			}
		}
	}

	/// @notice Returns whether the given address has permission to call the given function within
	/// the given contract
	/// @param user The address of the user to get permissions for
	/// @param _contract The address of the contract where the function resides
	/// @param functionSig The four-byte signature of the function
	/// @return bool [true] if the address has permission to call the function, otherwise [false]
	function getCallable(
		address user,
		address _contract,
		bytes4 functionSig
	) external view returns (bool) {
		return permissions[_contract][functionSig] & roles[user] != 0;
	}

	/// @notice Given a queued transaction's hash, retrieve all its info
	/// @param _hash The queued transaction's hash
	/// @return Transaction A struct, representing all information about a queued transaction
	function getTransaction(bytes32 _hash) external view returns (Transaction memory) {
		return transactions[_hash];
	}

	/// @notice Returns a human-legible list of roles
	/// @dev Meant to be called off-chain
	/// @return string A list of roles
	function getRolesList() external view returns (string memory) {
		return string.concat("\n> Roles available are: ", roleBitsToString(0xFF), ".");
	}

	/// @notice Returns a human-legible list of roles which have permission to call the given
	/// function within the given contract
	/// @dev Meant to be called off-chain
	/// @param _contract The address of the contract where the function resides
	/// @param functionSig The four-byte signature of the function
	/// @return string A list of roles
	function getPermissions(
		address _contract,
		bytes4 functionSig
	) external view returns (string memory) {
		return string.concat(
			"\n> This function can be called by: ",
			roleBitsToString(permissions[_contract][functionSig]),
			"."
		);
	}

	/// @notice Returns a human-legible list of roles which the given user has been added to
	/// @dev Meant to be called off-chain
	/// @param user The address of the user in question
	/// @return list The list of roles
	function getRolesUser(address user) external view returns (string memory list) {
		list = "\n> User's roles are: ";
		bytes1 _roles = roles[user] & slot0.roleMap;
		bool anyRole = false;
		for (uint i; i < 8;) {
			if (_roles & 0x01 != 0) {
				if (_roles >> 1 == 0) {
					if (anyRole)
						return string.concat(list, 'and "', roleNames[i], '".');
					return string.concat("\n> User's role is: \"", roleNames[i], '".');
				}
				list = string.concat(list, '"', roleNames[i], '", ');
				anyRole = true;
			}
			_roles >>= 1;
			unchecked {
				++i;
			}
		}
	}

	// Function only for readability's sake, in a situation where clarity is important
	function onlyAdmin() private view {
		if (roles[msg.sender] & ADMIN == 0)
			revert NotAuthorized();
	}

	// Should only be used in functions meant to be called off-chain
	function roleBitsToString(bytes1 _roles) private view returns (string memory list) {
		_roles &= slot0.roleMap;
		_roles >>= 1;
		list = "the ";
		bool _onlyAdmin = true;
		string memory thisRole = "Admin";
		for (uint i = 1; i < 8;) {
			if (_roles & 0x01 != 0) {
				list = string.concat(list, '"', thisRole, '", ');
				thisRole = roleNames[i];
				_onlyAdmin = false;
			}
			_roles >>= 1;
			unchecked {
				++i;
			}
		}
		if (_onlyAdmin) {
			return 'the "Admin", and nobody else';
		}
		list = string.concat(list, 'and "', thisRole, '"');
	}

	// Takes an array of role indices and generates a bitmap which can be compared
	// to [slot0.roleMap]
	function rolesToBits(Roles[] calldata _roles) private pure returns (bytes1 bitMap) {
		for (uint i; i < _roles.length;) {
			bitMap |= bytes1(0x01) << uint8(_roles[i]);
			unchecked {
				++i;
			}
		}
	}
}