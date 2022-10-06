/**
 *Submitted for verification at polygonscan.com on 2022-10-05
*/

// SPDX-License-Identifier: MIT
// TODO: Add soldoc

pragma solidity ^0.8.7;

// Get a link to Bet token
interface IBetToken {
    // Transfer bet tokens
    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    // Transfer bet tokens on behalf
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);        
}

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 */
contract AccessControl {
	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @notice Creates an access control instance,
	 *      setting contract creator to have full privileges
	 */
	constructor() {
		// contract creator has full privileges
		userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns(uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}
}

/**
   * @title Betting Vault Basic Version 1.0
   *
   * @author Hashdev
   */
contract BettingVaultBasic is AccessControl {
    // Address of bet token used in betting
    address public immutable betToken;

    // TODO
    uint32 public constant FEATURE_DEPOSIT = 0x0000_0001;

    // TODO
    uint32 public constant FEATURE_WITHDRAW = 0x0000_0002;

    // TODO
    uint32 public constant FEATURE_BET = 0x0000_0004;

    // TODO
    uint32 public constant FEATURE_MULTIBET = 0x0000_0004;

    // TODO
    uint32 public constant FEATURE_TRANSFER = 0x0000_0010;

    // TODO
    uint32 public constant FEATURE_TRANSFER_BATCH = 0x0000_0020;

    // TODO
    uint32 public constant ROLE_TOKEN_TRANSFER = 0x0001_0000;

    // TODO
    uint32 public constant ROLE_TOKEN_TRANSFER_BATCH = 0x0002_0000;

    // TODO
    uint256 public totalDepositedAmount;

    // TODO
    struct BetData {
        uint256 bet;
        uint256 paid;
        uint256 retain;
    }

    // TODO
    mapping (uint => BetData) public betId;
    
    // TODO
    mapping (address => mapping (uint => BetData)) public betData;

    // TODO
    mapping (address => uint) public balance;

    // TODO
    event Deposit (
        address indexed depositor,
        address indexed executor,
        uint256 amount
    );

    // TODO
    event Withdraw (
        address indexed by,
        address indexed to,
        uint256 amount
    );

    // TOOD
    event Bet (
        address indexed bettor,
        address indexed executor,
        uint256 indexed betId,
        uint256 amount
    );

    // TODO
    event Transferred(
        address indexed to,
        address indexed executor,
        uint256 amount,
        bool isWithdrawn
    );

    /**
	   * @dev Creates/deploys Betting Vault Basic Version 1.0
	   *
	   * @param bet_ address of bet token
	   */
    constructor(address bet_) {
        // Setup smart contract internal state
        betToken = bet_;
    }
    
    /**
	   * @dev Deposits bet tokens into vault
	   *
       * @param to_ TODO
	   * @param amount_ bet tokens amount to be deposited
	   */
    function deposit(address to_, uint256 amount_) external {
        require(isFeatureEnabled(FEATURE_DEPOSIT), "Feature disable");

        // Transfer bet tokens from depositor to vault
        IBetToken(betToken).transferFrom(msg.sender, address(this), amount_);
        
        balance[to_] += amount_;

        totalDepositedAmount += amount_;

        // Emits an event
        emit Deposit(to_, msg.sender, amount_);
    }

    // TODO
    function withdraw(address to_, uint256 amount_) external {
        require(isFeatureEnabled(FEATURE_WITHDRAW), "Feature disable");

        // TODO
        balance[msg.sender] -= amount_;

        totalDepositedAmount -= amount_;
        
        // Transfer bet tokens from depositor to vault
        IBetToken(betToken).transfer(to_, amount_);

        // Emits an event
        emit Withdraw(msg.sender, to_, amount_);
    }

    // TODO
    function bet(uint256 betId_, uint256 amount_) external {
        require(isFeatureEnabled(FEATURE_BET), "Feature disable");

        uint256 _bal = balance[msg.sender];
        
        if(_bal >= amount_) {
            
            balance[msg.sender] -= amount_; 
        } else {
            
            uint256 _diff = amount_ - _bal;

            IBetToken(betToken).transferFrom(msg.sender, address(this), _diff);

            delete balance[msg.sender];
        }

        betData[msg.sender][betId_].bet += amount_;

        betId[betId_].bet += amount_;

        emit Bet(msg.sender, msg.sender, betId_, amount_); 
    }

    // TODO
    function multiBet(uint256[] calldata betId_, uint256[] calldata amount_) external {
        require(isFeatureEnabled(FEATURE_MULTIBET), "Feature disable");

        require(betId_.length == amount_.length, "Invalid inputs");

        uint256 _total;

        uint256 _bal = balance[msg.sender];

        for(uint i; i < betId_.length; i++) {
            
            betData[msg.sender][betId_[i]].bet += amount_[i];

            betId[betId_[i]].bet += amount_[i];

            emit Bet(msg.sender, msg.sender, betId_[i], amount_[i]);
        
            _total += amount_[i];
        }

        if(_bal >= _total) {
            
            balance[msg.sender] -= _total; 
        } else {
            
            uint256 _diff = _total - _bal;

            IBetToken(betToken).transferFrom(msg.sender, address(this), _diff);

            delete balance[msg.sender];
        }
    }

    // TODO
    function transfer(address to_, uint256 amount_, bool withdraw_) external {
        require(isFeatureEnabled(FEATURE_TRANSFER), "Feature disable");

        require(isSenderInRole(ROLE_TOKEN_TRANSFER), "access denied");
        
        if(withdraw_) {
            // Transfer bet tokens to given address
            IBetToken(betToken).transfer(to_, amount_);
        } else {
            balance[to_] += amount_;
        }
        
        // Emits an event
        emit Transferred(to_, msg.sender, amount_, withdraw_);
    }

    // TODO
    function transferBatch(address[] calldata to_, uint256[] calldata amount_, bool withdraw_) external {
        require(isFeatureEnabled(FEATURE_TRANSFER_BATCH), "Feature disable");

        require(isSenderInRole(ROLE_TOKEN_TRANSFER_BATCH), "access denied");

        require(to_.length == amount_.length, "Invalid inputs");

        for(uint i; i < to_.length; i++) {
            if(withdraw_) {
                // Transfer bet tokens to given address
                IBetToken(betToken).transfer(to_[i], amount_[i]);
            } else {
                balance[to_[i]] += amount_[i];
            }

            // Emits an event
            emit Transferred(to_[i], msg.sender, amount_[i], withdraw_);
        }
    }

}