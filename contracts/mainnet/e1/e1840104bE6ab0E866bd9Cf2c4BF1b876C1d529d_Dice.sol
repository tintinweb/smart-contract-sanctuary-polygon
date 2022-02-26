// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/// @notice Minimal interface for Bank.
/// @author Romuald Hog.
interface IBank {
    /// @notice Gets the token's allow status used on the games smart contracts.
    /// @param token Address of the token.
    /// @return Whether the token is enabled for bets.
    function isAllowedToken(address token) external view returns (bool);

    /// @notice Payouts a winning bet, and allocate the house edge fee.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param profit Number of tokens to be sent to the gamer.
    /// @param fees Bet amount and bet profit fees amount.
    function payout(
        address payable user,
        address token,
        uint256 profit,
        uint256 fees
    ) external payable;

    /// @notice Accounts a loss bet, allocate the house edge fee, and manage the balance overflow.
    /// @dev In case of an ERC20, the bet amount should be transfered prior to this tx.
    /// @dev In case of the gas token, the bet amount is sent along with this tx.
    /// @param user Address of the gamer.
    /// @param tokenAddress Address of the token.
    /// @param amount Loss bet amount.
    /// @param fees Bet amount fees amount.
    function cashIn(
        address user,
        address tokenAddress,
        uint256 amount,
        uint256 fees
    ) external payable;

    /// @notice Calculates the max bet amount based on the token balance, the balance risk, and the game multiplier.
    /// @param token Address of the token.
    /// @param multiplier The bet amount leverage determines the user's profit amount. 10000 = 100% = no profit.
    /// @return Maximum bet amount for the token.
    /// @dev The multiplier should be at least 10000.
    function getMaxBetAmount(address token, uint256 multiplier)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// import "hardhat/console.sol";

interface IReferral {
    /// @notice Adds an address as referrer.
    /// @param user The address of the user.
    /// @param referrer The address would set as referrer of user.
    function addReferrer(address user, address referrer) external;

    /// @notice Updates referrer's last active timestamp.
    /// @param user The address would like to update active time.
    function updateReferrerActivity(address user) external;

    /// @notice Calculates and allocate referrer(s) credits to uplines.
    /// @param user Address of the gamer to find referrer(s).
    /// @param token The token to allocate.
    /// @param amount The number of tokens allocated for referrer(s).
    function payReferral(
        address user,
        address token,
        uint256 amount
    ) external returns (uint256);

    /// @notice Utils function for check whether an address has the referrer.
    /// @param user The address of the user.
    /// @return Whether user has a referrer.
    function hasReferrer(address user) external view returns (bool);
}

/// @title Multi-level referral program
/// @author Thundercore, customized by Romuald Hog
/// @dev All rates are in basis point.
contract Referral is AccessControl, Pausable {
    using SafeERC20 for IERC20;

    /// @notice The struct of account information.
    /// @param referrer The referrer addresss.
    /// @param referredCount The total referral amount of an address.
    /// @param lastActiveTimestamp The last active timestamp of an address.
    struct Account {
        address referrer;
        uint24 referredCount;
        uint32 lastActiveTimestamp;
    }

    /// @notice The struct of referee amount to bonus rate.
    /// @param lowerBound The minial referee amount.
    /// @param rate The bonus rate for each referee amount.
    struct RefereeBonusRate {
        uint16 lowerBound;
        uint16 rate;
    }

    /// @notice The bonus rate for each level.
    /// @dev The max depth is 3.
    uint16[3] public levelRate;

    /// @notice The seconds that a user does not update will be seen as inactive.
    uint24 public secondsUntilInactive;

    /// @notice The flag to enable not paying to inactive uplines.
    bool public onlyRewardActiveReferrers;

    /// @notice The bonus rate mapping to each referree amount. The max depth is 3.
    RefereeBonusRate[3] public refereeBonusRateMap;

    /// @notice Maps users addresses to tokens addresses to credits amount.
    mapping(address => mapping(address => uint256)) private _credits;

    /// @notice Maps users addresses to referrer account information.
    mapping(address => Account) private _accounts;

    /// @notice Role associated to Games smart contracts.
    bytes32 public constant GAME_ROLE = keccak256("GAME_ROLE");

    /// @notice Role associated to the Bank smart contracts.
    bytes32 public constant BANK_ROLE = keccak256("BANK_ROLE");

    /// @notice Emitted after the configuration is set.
    /// @param secondsUntilInactive The seconds that a user does not update will be seen as inactive.
    /// @param onlyRewardActiveReferrers The flag to enable not paying to inactive uplines.
    /// @param levelRate The bonus rate for each level.
    event SetReferral(
        uint24 secondsUntilInactive,
        bool onlyRewardActiveReferrers,
        uint16[3] levelRate
    );

    /// @notice Emitted after a bonus rate configuration is set.
    /// @param lowerBound Number of minimum referee to benefit the bonus rate.
    /// @param rate The bonus rate.
    event SetReferreeBonusRate(uint16 lowerBound, uint16 rate);

    /// @notice Emitted after setting the referrer of a referee.
    /// @param referee The address of the user
    /// @param referrer The address would set as referrer of user
    event RegisteredReferer(address indexed referee, address indexed referrer);

    /// @notice Emitted after referrer's activity.
    /// @param referrer The address of the user.
    /// @param lastActiveTimestamp The last active timestamp of the referrer.
    event SetLastActiveTimestamp(
        address indexed referrer,
        uint32 lastActiveTimestamp
    );

    /// @notice Emitted after adding credit to a referrer.
    /// @param user Address of the referrer.
    /// @param token Address of the token.
    /// @param amount Amount of credited tokens.
    /// @param level The referrer level.
    event AddReferralCredit(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint16 indexed level
    );

    /// @notice Emitted after the referrer withdraw credits.
    /// @param payee Address of the referrer.
    /// @param token Address of the token.
    /// @param amount Amount of credited tokens.
    event WithdrawnReferralCredit(
        address indexed payee,
        address indexed token,
        uint256 amount
    );

    /// @notice Referral level should be at least one, length not exceed 3, and total not exceed 100%.
    error WrongLevelRate();

    /// @notice One of referee bonus rate exceeds 100%.
    /// @param rate The referee bonus rate.
    error WrongRefereeBonusRate(uint16 rate);

    /// @notice Sets the Referral program configuration. c.f. `Referral._setReferral`.
    /// @param _secondsUntilInactive The seconds that a user does not update will be seen as inactive.
    /// @param _onlyRewardActiveReferrers The flag to enable not paying to inactive uplines.
    /// @param _levelRate The bonus rate for each level. The max depth is 3.
    /// @param _refereeBonusRateMap The bonus rate mapping to each referree amount. The max depth is 3.
    constructor(
        uint24 _secondsUntilInactive,
        bool _onlyRewardActiveReferrers,
        uint16[3] memory _levelRate,
        uint16[6] memory _refereeBonusRateMap
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setReferral(
            _secondsUntilInactive,
            _onlyRewardActiveReferrers,
            _levelRate,
            _refereeBonusRateMap
        );
    }

    receive() external payable {}

    /// @notice Gets the bonus rate based on the referred count.
    /// @param referredCount The number of referrees.
    /// @return The bonus rate.
    function _getRefereeBonusRate(uint24 referredCount)
        private
        view
        returns (uint16)
    {
        uint16 rate = refereeBonusRateMap[0].rate;
        uint256 refereeBonusRateMapLength = refereeBonusRateMap.length;
        for (uint8 i = 1; i < refereeBonusRateMapLength; i++) {
            RefereeBonusRate memory refereeBonusRate = refereeBonusRateMap[i];
            if (referredCount < refereeBonusRate.lowerBound) {
                break;
            }
            rate = refereeBonusRate.rate;
        }
        return rate;
    }

    /// @notice Checks whether the referee is one of referrer uplines.
    /// @param referrer Address of the referrer.
    /// @param referee Address of the referee.
    /// @return Whether the referee is already on referrer's upper levels.
    function _isCircularReference(address referrer, address referee)
        private
        view
        returns (bool)
    {
        address parent = referrer;
        uint256 levelRateLength = levelRate.length;
        for (uint8 i; i < levelRateLength; i++) {
            if (parent == address(0)) {
                break;
            }

            if (parent == referee) {
                return true;
            }

            parent = _accounts[parent].referrer;
        }

        return false;
    }

    /// @notice Sets the Referral program configuration.
    /// @param _secondsUntilInactive The seconds that a user does not update will be seen as inactive.
    /// @param _onlyRewardActiveReferrers The flag to enable not paying to inactive uplines.
    /// @param _levelRate The bonus rate for each level. The max depth is 3.
    /// @param _refereeBonusRateMap The bonus rate mapping to each referree amount. The max depth is 3.
    /// @dev The map should be pass as [<lower amount>, <rate>, ....]. For example, you should pass [1, 2500, 5, 5000, 10, 10000].
    ///
    ///  25%     50%     100%
    ///   | ----- | ----- |----->
    ///  1ppl    5ppl    10ppl
    ///
    /// @dev refereeBonusRateMap's lower amount should be ascending
    function setReferral(
        uint24 _secondsUntilInactive,
        bool _onlyRewardActiveReferrers,
        uint16[3] memory _levelRate,
        uint16[6] memory _refereeBonusRateMap
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 levelRateTotal;
        uint256 levelRateLength = _levelRate.length;
        for (uint8 i; i < levelRateLength; i++) {
            levelRateTotal += _levelRate[i];
        }
        if (levelRateTotal > 10000) {
            revert WrongLevelRate();
        }

        secondsUntilInactive = _secondsUntilInactive;
        onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
        levelRate = _levelRate;

        emit SetReferral(
            secondsUntilInactive,
            onlyRewardActiveReferrers,
            levelRate
        );

        uint8 j;
        uint256 refereeBonusRateMapLength = _refereeBonusRateMap.length;
        for (uint8 i; i < refereeBonusRateMapLength; i += 2) {
            uint16 refereeBonusLowerBound = _refereeBonusRateMap[i];
            uint16 refereeBonusRate = _refereeBonusRateMap[i + 1];
            if (refereeBonusRate > 10000) {
                revert WrongRefereeBonusRate(refereeBonusRate);
            }
            refereeBonusRateMap[j] = RefereeBonusRate(
                refereeBonusLowerBound,
                refereeBonusRate
            );
            emit SetReferreeBonusRate(refereeBonusLowerBound, refereeBonusRate);
            j++;
        }
    }

    /// @notice Adds an address as referrer.
    /// @param user Address of the gamer.
    /// @param referrer The address would set as referrer of user.
    function addReferrer(address user, address referrer)
        external
        onlyRole(GAME_ROLE)
    {
        if (referrer == address(0)) {
            // Referrer cannot be 0x0 address
            return;
        } else if (_isCircularReference(referrer, user)) {
            // Referee cannot be one of referrer uplines
            return;
        } else if (_accounts[user].referrer != address(0)) {
            // Address have been registered upline
            return;
        }

        Account storage userAccount = _accounts[user];
        Account storage parentAccount = _accounts[referrer];

        userAccount.referrer = referrer;
        userAccount.lastActiveTimestamp = uint32(block.timestamp);
        parentAccount.referredCount += 1;

        emit RegisteredReferer(user, referrer);
    }

    /// @notice Calculates and allocate referrer(s) credits to uplines.
    /// @param user Address of the gamer to find referrer(s).
    /// @param token The token to allocate.
    /// @param amount The number of tokens allocated for referrer(s).
    function payReferral(
        address user,
        address token,
        uint256 amount
    ) external onlyRole(BANK_ROLE) returns (uint256) {
        uint256 totalReferral;
        Account memory userAccount = _accounts[user];

        if (userAccount.referrer != address(0)) {
            uint256 levelRateLength = levelRate.length;
            for (uint8 i; i < levelRateLength; i++) {
                address parent = userAccount.referrer;
                Account memory parentAccount = _accounts[parent];

                if (parent == address(0)) {
                    break;
                }

                if (
                    !onlyRewardActiveReferrers ||
                    (parentAccount.lastActiveTimestamp + secondsUntilInactive >=
                        block.timestamp)
                ) {
                    uint256 credit = (((amount * levelRate[i]) / 10000) *
                        _getRefereeBonusRate(parentAccount.referredCount)) /
                        10000;
                    totalReferral += credit;

                    _credits[parent][token] += credit;

                    emit AddReferralCredit(parent, token, credit, i + 1);
                }

                userAccount = parentAccount;
            }
        }
        return totalReferral;
    }

    /// @notice Updates referrer's last active timestamp.
    /// @param user Address of the gamer.
    function updateReferrerActivity(address user) external onlyRole(GAME_ROLE) {
        Account storage userAccount = _accounts[user];
        if (userAccount.referredCount > 0) {
            uint32 lastActiveTimestamp = uint32(block.timestamp);
            userAccount.lastActiveTimestamp = lastActiveTimestamp;
            emit SetLastActiveTimestamp(user, lastActiveTimestamp);
        }
    }

    /// @notice Referrer withdraw credits.
    /// @param tokens The tokens addresses.
    function withdrawCredits(address[] calldata tokens) external {
        address payable payee = payable(msg.sender);
        for (uint8 i; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 credit = _credits[payee][token];
            if (credit > 0) {
                _credits[payee][token] = 0;

                if (token == address(0)) {
                    payee.transfer(credit);
                } else {
                    IERC20(token).safeTransfer(payee, credit);
                }

                emit WithdrawnReferralCredit(payee, token, credit);
            }
        }
    }

    /// @notice Utils function for check whether an address has the referrer.
    /// @param user Address of the gamer.
    /// @return Whether user has a referrer.
    function hasReferrer(address user) external view returns (bool) {
        return _accounts[user].referrer != address(0);
    }

    /// @notice Gets the referrer's token credits.
    /// @param payee Address of the referrer.
    /// @param token Address of the token.
    /// @return The number of tokens available to withdraw.
    function referralCreditOf(address payee, address token)
        external
        view
        returns (uint256)
    {
        return _credits[payee][token];
    }

    /// @notice Gets the referrer's account information.
    /// @param user Address of the referrer.
    /// @return The account information.
    function getReferralAccount(address user)
        external
        view
        returns (Account memory)
    {
        return _accounts[user];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Game} from "./Game.sol";

/// @title BetSwirl's Dice game
/// @notice The game is played with a 100 sided dice. The game's goal is to guess whether the lucky number will be above your chosen number.
/// @author Romuald Hog (based on Yakitori's Dice)
/// @dev The cap is the dice number chosen by the gamer.
contract Dice is Game {
    /// @notice Dice bet information struct.
    /// @param bet The Bet struct information.
    /// @param face The chosen dice number.
    /// @dev Used to package bet information for the front-end.
    struct DiceBet {
        Bet bet;
        uint8 cap;
    }

    /// @notice Maps bets IDs to chosen dice number.
    mapping(uint256 => uint8) public diceBets;

    /// @notice Maximum dice number that a gamer can choose.
    /// @dev Dice cap 99 gives 1% chance.
    uint8 public constant MAX_CAP = 99;

    /// @notice Maps the tokens addresses to the minimum cap
    /// @dev This is used to prevent a user from setting defavorable bet
    mapping(address => uint8) public tokensMinCap;

    /// @notice Emitted after a bet is placed.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param cap The chosen dice number.
    event PlaceBet(
        uint256 id,
        address indexed user,
        address indexed token,
        uint8 cap
    );

    /// @notice Emitted after a bet is rolled.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param amount The bet amount.
    /// @param cap The chosen dice number.
    /// @param rolled The rolled dice number.
    /// @param payout The payout amount.
    event Roll(
        uint256 id,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint8 cap,
        uint8 rolled,
        uint256 payout
    );

    /// @notice Emitted after the minimum cap is set.
    /// @param token Address of the token.
    /// @param minCap The new minimum cap.
    event SetMinCap(address indexed token, uint256 minCap);

    /// @notice Provided cap is under the minimum.
    /// @param cap The cap chosen by user.
    /// @param minCap is the minimum cap defined based on the house edge.
    /// @param maxCap is the maximum cap defined.
    error CapNotInRange(uint8 cap, uint8 minCap, uint8 maxCap);

    /// @notice Initialize the game base contract.
    /// @param bankAddress The address of the bank.
    /// @param chainlinkCoordinatorAddress Address of the Chainlink VRF Coordinator.
    /// @param numRandomWords How many random words is needed to resolve a game's bet.
    constructor(
        address bankAddress,
        address referralProgramAddress,
        address chainlinkCoordinatorAddress,
        uint16 numRandomWords
    )
        Game(
            bankAddress,
            referralProgramAddress,
            chainlinkCoordinatorAddress,
            numRandomWords
        )
    {}

    /// @notice Sets the game house edge rate for a specific token, and the minimum cap to prevent defavorable bets.
    /// @param token Address of the token.
    /// @param _houseEdge House edge rate.
    function setHouseEdgeAndMinCap(address token, uint16 _houseEdge)
        external
        onlyOwner
    {
        _setHouseEdge(token, _houseEdge);

        uint8 oldMinCap = tokensMinCap[token];
        uint8 newMinCap;
        uint8 maxCap = MAX_CAP;
        uint256 amount = 10000;
        for (uint8 cap = 1; cap < maxCap; cap++) {
            uint256 payout = getPayout(amount, cap);
            uint256 fees = _getFees(token, payout);
            if (amount / (payout - fees) < 1) {
                newMinCap = tokensMinCap[token] = cap;
                break;
            }
        }
        if (oldMinCap != newMinCap) {
            emit SetMinCap(token, newMinCap);
        }
    }

    /// @notice Creates a new bet and stores the chosen dice number.
    /// @param cap The chosen dice number.
    /// @param token Address of the token.
    /// @param tokenAmount The number of tokens bet.
    /// @param referrer Address of the referrer.
    function wager(
        uint8 cap,
        address token,
        uint256 tokenAmount,
        address referrer
    ) external payable whenNotPaused {
        if (cap < tokensMinCap[token] || cap > MAX_CAP) {
            revert CapNotInRange(cap, tokensMinCap[token], MAX_CAP);
        }

        Bet memory bet = _newBet(
            token,
            tokenAmount,
            getPayout(10000, cap),
            referrer
        );
        diceBets[bet.id] = cap;

        emit PlaceBet(bet.id, bet.user, bet.token, cap);
    }

    /// @notice Resolves the bet using the Chainlink randomness.
    /// @param id The bet ID.
    /// @param randomWords Random words list. Contains only one for this game.
    // solhint-disable-next-line private-vars-leading-underscore
    function fulfillRandomWords(uint256 id, uint256[] memory randomWords)
        internal
        override
    {
        uint8 cap = diceBets[id];
        Bet storage bet = bets[id];

        uint256 rolled = (randomWords[0] % 100) + 1;

        uint256 payout = _resolveBet(
            bet,
            rolled > cap,
            getPayout(bet.amount, cap)
        );

        emit Roll(
            bet.id,
            bet.user,
            bet.token,
            bet.amount,
            cap,
            uint8(rolled),
            payout
        );
    }

    /// @notice Gets the list of a user unresolved bets.
    /// @param user Address of the gamer.
    /// @param dataLength The amount of unresolved bets to return.
    /// @return A list of Dice bet.
    function getLastUserUnresolvedBets(address user, uint256 dataLength)
        external
        view
        returns (DiceBet[] memory)
    {
        Bet[] memory unresolvedBets = _getLastUserUnresolvedBets(
            user,
            dataLength
        );
        DiceBet[] memory unresolvedDiceBets = new DiceBet[](
            unresolvedBets.length
        );
        for (uint256 i; i < unresolvedBets.length; i++) {
            unresolvedDiceBets[i] = DiceBet(
                unresolvedBets[i],
                diceBets[unresolvedBets[i].id]
            );
        }
        return unresolvedDiceBets;
    }

    /// @notice Calculates the target payout amount.
    /// @param betAmount Bet amount.
    /// @param cap The chosen dice number.
    /// @return The target payout amount.
    function getPayout(uint256 betAmount, uint8 cap)
        public
        pure
        returns (uint256)
    {
        return (betAmount * 100) / (100 - cap);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import {IBank} from "../bank/IBank.sol";
import {IReferral} from "../bank/Referral.sol";

// import "hardhat/console.sol";

/// @title Game base contract
/// @author Romuald Hog
/// @notice This should be parent contract of each games.
/// It defines all the games common functions and state variables.
/// @dev All rates are in basis point. Chainlink VRF v2 is used.
abstract contract Game is Ownable, Pausable, Multicall, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;

    /// @notice Bet information struct.
    /// @param resolved Whether the bet has been resolved.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param id Bet ID generated by Chainlink VRF.
    /// @param amount The bet amount.
    /// @param blockNumber Block number of the bet used to refund in case Chainlink's callback fail.
    struct Bet {
        bool resolved;
        address payable user;
        address token;
        uint256 id;
        uint256 amount;
        uint256 blockNumber;
    }

    /// @notice Chainlink VRF configuration struct.
    /// @param subId Subscription ID.
    /// @param callbackGasLimit How much gas you would like in your callback to do work with the random words provided.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    struct ChainlinkConfig {
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        bytes32 keyHash;
    }

    /// @notice Chainlink VRF configuration state.
    ChainlinkConfig public chainlinkConfig;

    /// @notice Reference to the VRFCoordinatorV2 deployed contract.
    VRFCoordinatorV2Interface public chainlinkCoordinator;

    /// @notice How many random words is needed to resolve a game's bet.
    uint16 private immutable _numRandomWords;

    /// @notice Maps bets IDs to Bet information.
    mapping(uint256 => Bet) public bets;

    /// @notice Maps users addresses to bets IDs
    mapping(address => uint256[]) internal _userBets;

    /// @notice Maps tokens addresses to house edge rate.
    mapping(address => uint16) public tokensHouseEdges;

    /// @notice Maps tokens addresses to minimum bet amount.
    mapping(address => uint256) public tokensMinBetAmount;

    /// @notice The bank that manage to payout a won bet and collect a loss bet, and to interact with Referral program.
    IBank public bank;

    /// @notice Referral program contract.
    IReferral public referralProgram;

    /// @notice Emitted after the bank is set.
    /// @param bank Address of the bank contract.
    event SetBank(address bank);

    /// @notice Emitted after the referral program is set.
    /// @param referralProgram The referral program address.
    event SetReferralProgram(address referralProgram);

    /// @notice Emitted after the house edge is set for a token.
    /// @param token Address of the token.
    /// @param houseEdge House edge rate.
    event SetHouseEdge(address indexed token, uint16 houseEdge);

    /// @notice Emitted after the minimum bet amount is set for a token.
    /// @param token Address of the token.
    /// @param minBetAmount Minimum bet amount.
    event SetTokenMinBetAmount(address indexed token, uint256 minBetAmount);

    /// @notice Emitted after the bet amount transfer to the user failed.
    /// @param id The bet ID.
    /// @param amount Number of tokens failed to transfer.
    /// @param reason The reason provided by the external call.
    event BetAmountTransferFail(uint256 id, uint256 amount, string reason);

    /// @notice Emitted after the bet amount fee transfer to the bank failed.
    /// @param id The bet ID.
    /// @param amount Number of tokens failed to transfer.
    /// @param reason The reason provided by the external call.
    event BetAmountFeeTransferFail(uint256 id, uint256 amount, string reason);

    /// @notice Emitted after the bet profit transfer to the user failed.
    /// @param id The bet ID.
    /// @param amount Number of tokens failed to transfer.
    /// @param reason The reason provided by the external call.
    event BetProfitTransferFail(uint256 id, uint256 amount, string reason);

    /// @notice Emitted after the bet amount transfer to the bank failed.
    /// @param id The bet ID.
    /// @param amount Number of tokens failed to transfer.
    /// @param reason The reason provided by the external call.
    event BankCashInFail(uint256 id, uint256 amount, string reason);

    /// @notice Emitted after the bet amount ERC20 transfer to the bank failed.
    /// @param id The bet ID.
    /// @param amount Number of tokens failed to transfer.
    /// @param reason The reason provided by the external call.
    event BankTransferFail(uint256 id, uint256 amount, string reason);

    /// @notice Emitted after the bet amount is transfered to the user.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param amount Number of tokens refunded.
    event BetRefunded(uint256 id, address user, uint256 amount);

    /// @notice Insufficient bet amount.
    /// @param token Bet's token address.
    /// @param value Bet amount.
    error UnderMinBetAmount(address token, uint256 value);

    /// @notice Bet provided doesn't exist or was already resolved.
    /// @param id Bet ID.
    error NotPendingBet(uint256 id);

    /// @notice Bet isn't resolved yet.
    /// @param id Bet ID.
    error NotFulfilled(uint256 id);

    /// @notice House edge is capped at 4%.
    /// @param houseEdge House edge rate.
    error ExcessiveHouseEdge(uint16 houseEdge);

    /// @notice Token is not allowed.
    /// @param token Bet's token address.
    error ForbiddenToken(address token);

    /// @notice Initialize contract's state variables and VRF Consumer.
    /// @param bankAddress The address of the bank.
    /// @param chainlinkCoordinatorAddress Address of the Chainlink VRF Coordinator.
    /// @param numRandomWords How many random words is needed to resolve a game's bet.
    constructor(
        address bankAddress,
        address referralProgramAddress,
        address chainlinkCoordinatorAddress,
        uint16 numRandomWords
    ) VRFConsumerBaseV2(chainlinkCoordinatorAddress) {
        setBank(IBank(bankAddress));
        setReferralProgram(IReferral(referralProgramAddress));
        chainlinkCoordinator = VRFCoordinatorV2Interface(
            chainlinkCoordinatorAddress
        );
        _numRandomWords = numRandomWords;
    }

    /// @notice Sets the game house edge rate for a specific token.
    /// @param token Address of the token.
    /// @param houseEdge House edge rate.
    /// @dev The house edge rate couldn't exceed 4%.
    function _setHouseEdge(address token, uint16 houseEdge) internal onlyOwner {
        if (houseEdge > 400) {
            revert ExcessiveHouseEdge(houseEdge);
        }
        tokensHouseEdges[token] = houseEdge;
        emit SetHouseEdge(token, houseEdge);
    }

    /// @notice Creates a new bet, request randomness to Chainlink, add the referrer,
    /// transfer the ERC20 tokens to the contract or refund the bet amount overflow if the bet amount exceed the maxBetAmount.
    /// @param token Address of the token.
    /// @param tokenAmount The number of tokens bet.
    /// @param multiplier The bet amount leverage determines the user's profit amount. 10000 = 100% = no profit.
    /// @param referrer Address of the referrer.
    /// @return A new Bet struct information.
    function _newBet(
        address token,
        uint256 tokenAmount,
        uint256 multiplier,
        address referrer
    ) internal whenNotPaused returns (Bet memory) {
        if (bank.isAllowedToken(token) == false) {
            revert ForbiddenToken(token);
        }

        bool isGasToken = token == address(0);
        uint256 betAmount = isGasToken ? msg.value : tokenAmount;

        if (betAmount < 10000 wei || betAmount < tokensMinBetAmount[token]) {
            revert UnderMinBetAmount(token, betAmount);
        }
        uint256 maxBetAmount = bank.getMaxBetAmount(token, multiplier);
        uint256 betAmountOverflow;
        if (betAmount > maxBetAmount) {
            betAmountOverflow = betAmount - maxBetAmount;
            betAmount = maxBetAmount;
        }

        // Create bet
        address user = msg.sender;
        uint256 id = chainlinkCoordinator.requestRandomWords(
            chainlinkConfig.keyHash,
            chainlinkConfig.subId,
            chainlinkConfig.requestConfirmations,
            chainlinkConfig.callbackGasLimit,
            _numRandomWords
        );
        Bet memory newBet = Bet(
            false,
            payable(user),
            token,
            id,
            betAmount,
            block.number
        );
        _userBets[user].push(id);
        bets[id] = newBet;

        // Add referrer
        if (
            referrer != address(0) &&
            _userBets[user].length == 1 &&
            !referralProgram.hasReferrer(user)
        ) {
            referralProgram.addReferrer(user, referrer);
        } else {
            referralProgram.updateReferrerActivity(user);
        }

        // If ERC20, transfer the tokens
        if (!isGasToken) {
            IERC20(token).safeTransferFrom(user, address(this), betAmount);
        } else if (betAmountOverflow != 0) {
            payable(user).transfer(betAmountOverflow);
        }

        return newBet;
    }

    /// @notice Resolves the bet based on the game child contract result.
    /// In case bet is won, the bet amount minus the house edge is transfered to user from the game contract, and the profit is transfered to the user from the Bank.
    /// In case bet is lost, the bet amount is transfered to the Bank from the game contract.
    /// @param bet The Bet struct information.
    /// @param wins Whether the bet is winning.
    /// @param payout What should be sent to the user in case of a won bet. Payout = bet amount + profit amount.
    /// @return The payout amount.
    /// @dev Should not revert as it resolves the bet with the randomness.
    function _resolveBet(
        Bet storage bet,
        bool wins,
        uint256 payout
    ) internal returns (uint256) {
        address payable user = bet.user;
        if (bet.resolved == true || user == address(0)) {
            revert NotPendingBet(bet.id);
        }
        address token = bet.token;
        uint256 betAmount = bet.amount;
        bool isGasToken = bet.token == address(0);

        bet.resolved = true;

        // Check for the result
        if (wins) {
            uint256 profit = payout - betAmount;
            uint256 betAmountFee = _getFees(token, betAmount);
            uint256 profitFee = _getFees(token, profit);
            uint256 fee = betAmountFee + profitFee;

            payout -= fee;

            uint256 betAmountPayout = betAmount - betAmountFee;
            uint256 profitPayout = profit - profitFee;
            // Transfer the bet amount from the contract
            if (isGasToken) {
                if (!user.send(betAmountPayout)) {
                    emit BetAmountTransferFail(
                        bet.id,
                        betAmount,
                        "Missing gas token funds"
                    );
                }
            } else {
                try
                    IERC20(token).transfer(user, betAmountPayout)
                {} catch Error(string memory reason) {
                    emit BetAmountTransferFail(bet.id, betAmountPayout, reason);
                }
                try
                    IERC20(token).transfer(address(bank), betAmountFee)
                {} catch Error(string memory reason) {
                    emit BetAmountFeeTransferFail(bet.id, betAmountFee, reason);
                }
            }

            // Transfer the payout from the bank
            try
                bank.payout{value: isGasToken ? betAmountFee : 0}(
                    user,
                    token,
                    profitPayout,
                    fee
                )
            {} catch Error(string memory reason) {
                emit BetProfitTransferFail(bet.id, profitPayout, reason);
            }
        } else {
            payout = 0;
            if (!isGasToken) {
                try
                    IERC20(token).transfer(address(bank), betAmount)
                {} catch Error(string memory reason) {
                    emit BankTransferFail(bet.id, betAmount, reason);
                }
            }
            try
                bank.cashIn{value: isGasToken ? betAmount : 0}(
                    user,
                    token,
                    betAmount,
                    _getFees(token, betAmount)
                )
            {} catch Error(string memory reason) {
                emit BankCashInFail(bet.id, betAmount, reason);
            }
        }

        return payout;
    }

    /// @notice Gets the list of a user unresolved bets.
    /// @param user Address of the gamer.
    /// @param dataLength The amount of unresolved bets to return.
    /// @return A list of Bet.
    function _getLastUserUnresolvedBets(address user, uint256 dataLength)
        internal
        view
        returns (Bet[] memory)
    {
        uint256[] memory userBetsIds = _userBets[user];
        uint256 betsLength = userBetsIds.length;

        if (betsLength < dataLength) {
            dataLength = betsLength;
        }

        uint32 unresolvedBetsCounter;
        if (betsLength > 0) {
            for (uint256 i = betsLength; i >= dataLength; i--) {
                if (bets[userBetsIds[i - 1]].resolved == false) {
                    unresolvedBetsCounter++;
                }
            }
        }
        Bet[] memory unresolvedBets = new Bet[](unresolvedBetsCounter);
        if (unresolvedBetsCounter > 0) {
            unresolvedBetsCounter = 0;
            for (uint256 i = betsLength; i >= dataLength; i--) {
                if (bets[userBetsIds[i - 1]].resolved == false) {
                    unresolvedBets[unresolvedBetsCounter] = bets[
                        userBetsIds[i - 1]
                    ];
                    unresolvedBetsCounter++;
                }
            }
        }

        return unresolvedBets;
    }

    /// @notice Calculates the amount's fee based on the house edge.
    /// @param token Address of the token.
    /// @param amount From which the fee amount will be calculated.
    /// @return The fee amount.
    function _getFees(address token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return (tokensHouseEdges[token] * amount) / 10000;
    }

    /// @notice Sets the minimum bet amount for a specific token.
    /// @param token Address of the token.
    /// @param tokenMinBetAmount Minimum bet amount.
    function setTokenMinBetAmount(address token, uint256 tokenMinBetAmount)
        external
        onlyOwner
    {
        tokensMinBetAmount[token] = tokenMinBetAmount;
        emit SetTokenMinBetAmount(token, tokenMinBetAmount);
    }

    /// @notice Pauses the contract to disable new bets.
    function pause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @notice Sets the Chainlink VRF V2 configuration.
    /// @param subId Subscription ID.
    /// @param callbackGasLimit How much gas you would like in your callback to do work with the random words provided.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    function setChainlinkConfig(
        uint64 subId,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        bytes32 keyHash
    ) external onlyOwner {
        chainlinkConfig.subId = subId;
        chainlinkConfig.callbackGasLimit = callbackGasLimit;
        chainlinkConfig.requestConfirmations = requestConfirmations;
        chainlinkConfig.keyHash = keyHash;
    }

    /// @notice Withdraws remaining tokens.
    /// @param token Address of the token.
    /// @param amount Number of tokens.
    /// @dev Useful in case some transfers failed during the bet resolution callback.
    function inCaseTokensGetStuck(address token, uint256 amount)
        external
        onlyOwner
    {
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }

    /// @notice Refunds the bet to the user if the Chainlink VRF callback failed.
    /// @param id The Bet ID.
    function refundBet(uint256 id) external {
        Bet storage bet = bets[id];
        if (bet.resolved == true) {
            revert NotPendingBet(id);
        } else if (block.number < bet.blockNumber + 30) {
            revert NotFulfilled(id);
        }

        bet.resolved = true;

        if (bet.token == address(0)) {
            bet.user.transfer(bet.amount);
        } else {
            IERC20(bet.token).safeTransfer(bet.user, bet.amount);
        }

        emit BetRefunded(id, bet.user, bet.amount);
    }

    /// @notice Sets the Bank contract.
    /// @param _bank Address of the Bank contract.
    function setBank(IBank _bank) public onlyOwner {
        bank = _bank;
        emit SetBank(address(_bank));
    }

    /// @notice Sets the new referral program.
    /// @param _referralProgram The referral program address.
    function setReferralProgram(IReferral _referralProgram) public onlyOwner {
        referralProgram = _referralProgram;
        emit SetReferralProgram(address(referralProgram));
    }
}