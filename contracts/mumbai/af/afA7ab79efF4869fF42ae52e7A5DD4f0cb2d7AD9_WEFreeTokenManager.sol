// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/**
 * @title WEFreeTokenManager
 * @author Mihai Lazarut
 * @dev This contract allows participation in reveals where tokens can be won as a prize.
 * A player can register only one ticket per reveal without paying a ticket price.
 * The contract uses Chainlink VRF v2 for generating random numbers to determine the winner.
 */
contract WEFreeTokenManager is
    AccessControl,
    ReentrancyGuard,
    VRFConsumerBaseV2,
    ConfirmedOwner
{
    /* Chainlink VRF v2 */

    /**
     * @dev Emitted when a random number request is sent to Chainlink VRF
     * @param revealId - Id of the reveal for which the random number is requested
     * @param numberOfTickets - Total number of tickets in the reveal
     *
     * This event is emitted when a random number request is sent to the
     * Chainlink VRF using the `requestRandomWords` function. It provides
     * information about the reveal and the number of tickets associated with it.
     */
    event RequestRandomNumberSent(uint256 revealId, uint256 numberOfTickets);

    /**
     * @dev Emitted when a random number request is fulfilled by Chainlink VRF
     * @param requestId - Id of the fulfilled random number request
     * @param randomWords - Array of random words received from the Chainlink VRF
     *
     * This event is emitted when the Chainlink VRF fulfills a random number
     * request and the `fulfillRandomWords` function is called. It provides
     * information about the requestId and the randomWords received from the VRF.
     */
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    /**
     * @dev Struct to store the status and details of a random number request
     * @param fulfilled - Whether the request has been successfully fulfilled
     * @param exists - Whether a requestId exists
     * @param randomWords - Array of random words received from Chainlink VRF
     * @param revealId - Id of the reveal associated with the request
     * @param numberOfTickets - Total number of tickets in the associated reveal
     *
     * This struct is used to store the details and status of a random number
     * request sent to the Chainlink VRF. It includes information such as
     * whether the request has been fulfilled, the randomWords received from
     * the VRF, the revealId, and the number of tickets in the reveal.
     */
    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
        uint256 revealId;
        uint256 numberOfTickets;
    }

    /*
     * @dev Mapping to store the RequestStatus structs for each random number request
     * @param requestId - Id of the random number request
     * @param RequestStatus - Struct containing the status and details of the request
     *
     * This mapping is used to store and access the RequestStatus structs for
     * each random number request. It allows for easy lookup of the request
     * details and status using the requestId.
     */
    mapping(uint256 => RequestStatus) public s_requests;

    /**
     * @dev Instance of the Chainlink VRF Coordinator V2 contract
     *
     * This variable holds the reference to the Chainlink VRF Coordinator V2 contract
     * which is used to interact with the Chainlink VRF service. It is used to send
     * random number requests, and the fulfillment of these requests will be handled
     * through this contract.
     */
    VRFCoordinatorV2Interface COORDINATOR;

    /**
     * @dev Chainlink VRF subscription ID
     *
     * This variable stores the Chainlink VRF subscription ID that is associated
     * with the current smart contract. The subscription ID is used when sending
     * random number requests to the Chainlink VRF service, and it ensures that the
     * smart contract has the required funds to cover the cost of the request.
     */
    uint64 s_subscriptionId;

    /**
     * @dev Chainlink VRF key hash
     *
     * This variable stores the Chainlink VRF key hash associated with the current
     * smart contract. The key hash is used when sending random number requests to
     * the Chainlink VRF service, and it helps identify the corresponding public key
     * that should be used by the Chainlink VRF node to verify the VRF proof.
     *
     * The key hash is specific to the network and the gas lane chosen. For a list of
     * available gas lanes on each network, see:
     * https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
     */
    bytes32 keyHash;

    /**
     * @dev Callback gas limit for Chainlink VRF fulfillRandomWords function
     *
     * This variable specifies the gas limit for the callback request to the
     * fulfillRandomWords() function when a random number request is fulfilled by
     * the Chainlink VRF service. Storing each word costs about 20,000 gas.
     * However, this contract uses a higher value (500,000) to account for potential
     * gas fluctuations.
     *
     * Test and adjust this limit based on the network that you select, the size
     * of the request, and the processing of the callback request in the
     * fulfillRandomWords() function.
     */
    uint32 callbackGasLimit = 500_000;

    /**
     * @dev The number of block confirmations required for the random number request
     * to be considered secure by the Chainlink VRF service.
     *
     * The default value is 3, but you can set this higher to increase security.
     * In this contract, the value is set to 20 for added security.
     */
    uint16 requestConfirmations = 20;

    /**
     * @dev The number of random words requested from the Chainlink VRF service.
     *
     * This value cannot exceed the maximum allowed by the VRFCoordinatorV2
     * (VRFCoordinatorV2.MAX_NUM_WORDS). In this contract, the value is set to 1,
     * as only one random word is needed.
     */
    uint32 numWords = 1;

    /* End Chainlink VRF v2 */

    /**
     * @dev This event is emitted when a new reveal is created using the `createReveal` function.
     * @param revealId - The unique identifier of the newly created reveal.
     * @param prizeTokens - The amount of tokens the winner will receive.
     *
     * This event allows users and external applications to track the creation of new reveals
     * and their associated information.
     */
    event RevealStarted(uint256 indexed revealId, uint256 prizeTokens);

    /**
     * @dev This event is emitted when a reveal is completed, and the winner is determined using the
     * `sendWinnerPrize` function. It contains the following information:
     * @param revealId - The unique identifier of the completed reveal.
     * @param winner - The address of the winner who will receive the token prize.
     * @param prizeTokens - The amount of tokens the winner will receive.
     * @param winnerTicketNumber - The winning ticket number that determined the winner.
     *
     * This event allows users and external applications to track the completion of reveals,
     * the winners, and their associated prizes.
     */
    event RevealCompleted(
        uint256 indexed revealId,
        address winner,
        uint256 prizeTokens,
        uint256 winnerTicketNumber
    );

    /**
     * @dev This event is emitted when a reveal is cancelled using the `cancelReveal` function.
     * @param revealId - The unique identifier of the cancelled reveal.
     *
     * This event allows users and external applications to track the cancellation of reveals.
     */
    event RevealCancelled(uint256 indexed revealId);

    /**
     * @dev This event is emitted when a user successfully register a ticket for a reveal using the
     * `participate` function.
     * @param revealId - The unique identifier of the reveal for which ticket is registered.
     * @param sender - The address of the user who registered the ticket.
     * @param ticketNumber - The number of the registered ticket for the reveal.
     *
     * This event allows users and external applications to track the registered tickets for reveals.
     */
    event TicketRegistered(
        uint256 indexed revealId,
        address sender,
        uint256 ticketNumber
    );

    /**
     * @dev Enumeration representing the different statuses of a reveal.
     *
     * A reveal can be in one of the following statuses:
     * - `Started`: The reveal is active and players can register a ticket..
     * - `Completed`: The reveal has ended, a winner has been selected, and the prize has been sent.
     * - `Cancelled`: The reveal has been canceled because there are no participants after the reveal date.
     *
     * This enumeration is used in the RevealStruct to track the current status of a reveal.
     */
    enum RevealStatus {
        Started,
        Completed,
        Cancelled
    }

    /**
     * @dev The RevealStruct struct represents a reveal in the contract.
     *
     * @param registeredTickets - The number of tickets that have been registered so far.
     * @param firstAvailableTicketNumber - The first ticket number that is available for registration.
     * @param winner - The address of the winner of the reveal.
     * @param randomNumber - The random number generated by ChainLink used to determine the winner.
     * @param prizeTokens - The prize tokens for the winner.
     * @param revealDate - The date after which the winner is chosen if there is at least one registered ticket.
     * @param status - The current status of the reveal (Started, Completed, or Refunding).
     */
    struct RevealStruct {
        uint256 registeredTickets;
        uint256 firstAvailableTicketNumber;
        address winner;
        uint256 randomNumber;
        uint256 prizeTokens;
        uint256 revealDate;
        RevealStatus status;
    }

    /**
     * @dev `reveals` is an array that stores all created RevealStruct instances in the contract.
     */
    RevealStruct[] public reveals;

    /**
     * @dev `tickets` is a nested mapping that keeps track of the participant address for each ticket number
     * within a specific reveal. The first key represents the reveal ID, and the second key represents
     * the ticket number.
     */
    mapping(uint256 => mapping(uint256 => address)) private tickets;

    /**
     * @dev `playerAlreadyRegistered` is a map that shows if the player has already registered a ticket.
     * The key is generated by hashing the reveal ID and the player's address, ensuring a unique
     * identifier for each player-reveal combination.
     */
    mapping(bytes32 => bool) public playerAlreadyRegistered;

    /**
     * @dev The address of the prize token contract.
     *
     * This is a public variable that stores the address of the prize token contract.
     * This address is used in the contract to interact with the prize token for various operations, such as
     * transferring the prize token to the winner of a reveal.
     */
    address public prizeTokenAddress;

    /**
     * @dev The total amount of locked tokens for active reveals.
     *
     * This is a public variable that keeps track of the total amount of tokens locked in the contract
     * for active reveals. When a new reveal is created, its prize tokens are locked into the contract
     * by calling the `lockPrizeTokens` function, which increases the `lockedTokens` value by the
     * amount of the prize tokens. When a reveal is completed, and the prize is sent to the winner,
     * the value of `lockedTokens` is decreased by the amount of prize tokens.
     */
    uint256 public lockedTokens = 0;

    /**
     * @dev The address of the supervisor.
     *
     * This public variable stores the address of the supervisor who has specific
     * permissions within the contract, such as creating reveals.
     */
    address payable public supervisorAddress;

    /**
     *
     * @dev `SUPERVISOR_ROLE` is a constant variable of type bytes32 that represents the role of the
     * supervisor. This variable is used in the onlyRole modifier to restrict access to certain
     * functions only to users with the SUPERVISOR_ROLE.
     */
    bytes32 public constant SUPERVISOR_ROLE = keccak256("SUPERVISOR");

    /**
     * @dev Contract constructor
     * @param _subscriptionId - The subscription ID for VRF
     * @param _vrfCoordinator - The address of the VRF Coordinator contract
     * @param _keyHash - The key hash used for VRF
     * @param _prizeTokenAddress - The address of the prize token contract
     * @param _supervisorAddress - The address of the supervisor for funds management
     *
     * The constructor initializes the contract with the necessary parameters,
     * setting the VRF subscription ID, VRF Coordinator address, key hash, prize token
     * address, and supervisor address. Inherits from VRFConsumerBaseV2 and
     * ConfirmedOwner.
     */
    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        address _prizeTokenAddress,
        address _supervisorAddress
    ) VRFConsumerBaseV2(_vrfCoordinator) ConfirmedOwner(msg.sender) {
        require(
            _vrfCoordinator != address(0),
            "Invalid VRF Coordinator address"
        );
        require(_subscriptionId > 0, "Invalid VRF subscription ID");
        require(_keyHash != bytes32(0), "Invalid VRF key hash");
        require(
            _prizeTokenAddress != address(0),
            "Invalid prize token address"
        );
        require(_supervisorAddress != address(0), "Invalid supervisor address");

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        prizeTokenAddress = _prizeTokenAddress;
        supervisorAddress = payable(_supervisorAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPERVISOR_ROLE, msg.sender);
        _setupRole(SUPERVISOR_ROLE, _supervisorAddress);
    }

    /**
     * @dev Creates a new reveal
     * @param _prizeTokens - Prize tokens for the winner
     * @param _daysUntilReveal - Number of days until the reveal
     * @return revealId - Id of the newly created reveal
     *
     * Requirements:
     * - The `_prizeTokens` must be greater than 0.
     * - The `_daysUntilCancellation` must be greater than 0.
     *
     * This function creates a new reveal and initializes its properties.
     * It locks the prize tokens for the reveal.
     * The reveal is then added to the `reveals` array and a `RevealStarted` event
     * is emitted.
     */
    function createReveal(
        uint256 _prizeTokens,
        uint256 _daysUntilReveal
    ) external onlyRole(SUPERVISOR_ROLE) returns (uint256) {
        require(_prizeTokens > 0, "Invalid _prizeTokens");
        require(_daysUntilReveal > 0, "Invalid _daysUntilReveal");

        lockPrizeTokens(_prizeTokens);

        uint256 revealId = reveals.length;

        RevealStruct memory reveal = RevealStruct({
            registeredTickets: 0,
            firstAvailableTicketNumber: 1,
            winner: address(0),
            randomNumber: 0,
            prizeTokens: _prizeTokens,
            revealDate: block.timestamp + _daysUntilReveal * 1 days,
            status: RevealStatus.Started
        });

        reveals.push(reveal);

        emit RevealStarted(revealId, _prizeTokens);

        return revealId;
    }

    /**
     * @dev Locks the prize tokens for the reveal
     * @param prizeTokens - prize tokens to be locked
     *
     * This function ensures that the prize tokens for the reveal are locked in the
     * contract by checking if the contract's prize tokens balance is sufficient to cover
     * the new prize. If the condition is met, the `lockedTokens` variable is
     * increased by the value of `prizeTokens`.
     *
     * Requirements:
     * - The contract's prize tokens balance must be greater than or equal to the sum of
     *   the current `lockedTokens` and the `prizeTokens`.
     */
    function lockPrizeTokens(uint256 prizeTokens) internal {
        /* Get prize token contract reference */
        IERC20 prizeTokenContract = IERC20(prizeTokenAddress);

        /* Check the balance */
        require(
            prizeTokenContract.balanceOf(address(this)) >=
                lockedTokens + prizeTokens,
            "Insufficient prize tokens balance to lock"
        );

        lockedTokens += prizeTokens;
    }

    /**
     * @dev Buys tickets for a reveal
     * @param _revealId - The reveal ID
     *
     * This function allows a user to participate in a given reveal.
     * Requirements:
     * - `_revealId` must be valid.
     * - The reveal must be in the `Started` status.
     * - `msg.sender` must be a valid address.
     * - the player must not have already registered one ticket for this reveal.
     *
     * Emits a `TicketRegistered` event.
     */
    function participate(uint256 _revealId) external nonReentrant {
        require(_revealId < reveals.length, "Invalid _revealId");
        RevealStruct storage reveal = reveals[_revealId];
        require(reveal.status == RevealStatus.Started, "Reveal is not started");
        require(msg.sender != address(0), "msg.sender is not a valid address");
        bytes32 hash = keccak256(abi.encode(_revealId, msg.sender));
        require(
            playerAlreadyRegistered[hash] == false,
            "Player already registered one ticket"
        );

        uint256 ticketNumber = reveal.firstAvailableTicketNumber;
        if (tickets[_revealId][ticketNumber] == address(0)) {
            tickets[_revealId][ticketNumber] = msg.sender;
        } else {
            revert("This ticket is already registered");
        }

        playerAlreadyRegistered[hash] = true;

        reveal.registeredTickets += 1;
        reveal.firstAvailableTicketNumber += 1;

        emit TicketRegistered(_revealId, msg.sender, ticketNumber);
    }

    /**
     * @dev Sets the winner for the reveal
     * @param _revealId - Id of the reveal
     *
     * Requirements:
     * - `_revealId` must be a valid reveal id.
     * - The reveal status must be "Started".
     * - The random number for the reveal must not have been generated yet.
     * - The reveal date has passed
     *
     * This function requests a random number from Chainlink VRF v2 if there is at least one
     * registered ticket and uses it to determine the winner of the reveal.
     * If there is not at least one ticket registered, then the reveal is canceled.
     */
    function setWinner(
        uint256 _revealId
    ) external nonReentrant onlyRole(SUPERVISOR_ROLE) {
        require(_revealId < reveals.length, "Invalid reveal ID");
        RevealStruct storage reveal = reveals[_revealId];
        require(reveal.status == RevealStatus.Started, "Reveal is not started");
        require(reveal.randomNumber == 0, "Random number already generated");
        require(
            block.timestamp > reveal.revealDate,
            "There is still time for this reveal"
        );

        if (reveal.registeredTickets > 0) {
            requestRandomWords(_revealId, reveal.registeredTickets);
        } else {
            cancelReveal(_revealId);
        }
    }

    /**
     * @dev Requests random words from the Chainlink VRF v2
     * @param _revealId - Id of the reveal
     * @param _numberOfTickets - Total number of tickets in the reveal
     * @return requestId - Id of the random number request
     *
     * Requirements:
     * - The Chainlink VRF v2 subscription must be set and funded.
     *
     * This function sends a random number request to the Chainlink VRF v2
     * and stores the request details, including reveal id and the number
     * of tickets, to be used later when the random number is received.
     */
    function requestRandomWords(
        uint256 _revealId,
        uint256 _numberOfTickets
    ) internal returns (uint256 requestId) {
        /* Will revert if subscription is not set and funded */
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            revealId: _revealId,
            numberOfTickets: _numberOfTickets
        });
        emit RequestRandomNumberSent(_revealId, _numberOfTickets);
        return requestId;
    }

    /**
     * @dev Fulfills the random number request and determines the winner
     * @param _requestId - Id of the random number request
     * @param _randomWords - Array of random words received from the Chainlink VRF v2
     *
     * Requirements:
     * - The random number request must exist.
     *
     * This function is called by the Chainlink VRF v2 when the random number
     * is ready. It sets the request status to fulfilled and stores the
     * random words. It then calculates the winning ticket number based
     * on the first random word and the number of tickets for the reveal.
     * Finally, it calls the `sendWinnerPrize` function to send the prize
     * to the winner.
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        uint256 winnerTicketNumber = (_randomWords[0] %
            s_requests[_requestId].numberOfTickets) + 1;
        uint256 revealId = s_requests[_requestId].revealId;

        sendWinnerPrize(revealId, winnerTicketNumber);

        emit RequestFulfilled(_requestId, _randomWords);
    }

    /**
     * @dev Sends the prize tokens to the winner and completes the reveal.
     * @param _revealId - Id of the reveal
     * @param _winnerTicketNumber - Winner's ticket number
     *
     * Requirements:
     * - `_revealId` must be a valid reveal id.
     * - `_winnerTicketNumber` must be a valid ticket number for the reveal.
     * - The reveal must have a winner address set.
     *
     * This function does the following:
     * 1. Sets the winner's ticket number in the reveal.
     * 2. Sends the prize tokens to the winner.
     * 3. Updates the total lockedTokens by subtracting the prize.
     * 4. Emits a `RevealCompleted` event.
     */
    function sendWinnerPrize(
        uint256 _revealId,
        uint256 _winnerTicketNumber
    ) internal nonReentrant {
        require(_revealId < reveals.length, "Invalid _revealId");
        RevealStruct storage reveal = reveals[_revealId];
        require(
            _winnerTicketNumber > 0 &&
                _winnerTicketNumber <= reveal.registeredTickets,
            "Invalid _winnerTicketNumber"
        );

        reveal.randomNumber = _winnerTicketNumber;
        reveal.winner = tickets[_revealId][_winnerTicketNumber];
        reveal.status = RevealStatus.Completed;

        IERC20 prizeTokenContract = IERC20(prizeTokenAddress);
        prizeTokenContract.transfer(reveal.winner, reveal.prizeTokens);
        lockedTokens -= reveal.prizeTokens;

        emit RevealCompleted(
            _revealId,
            reveal.winner,
            reveal.prizeTokens,
            _winnerTicketNumber
        );
    }

    /**
     * @dev Cancels an existing reveal by changing its status to "Cancelled" and transferring
     * the prize tokens back to the supervisor.
     * @param _revealId - The ID of the reveal to cancel
     *
     * Requirements:
     * - `_revealId` must be a valid reveal id.
     * - The reveal must be in the Started status
     * - The current timestamp must be greater than the revealDate
     *
     * Emits a RevealCancelled event with the reveal ID
     */
    function cancelReveal(uint256 _revealId) internal {
        require(_revealId < reveals.length, "Invalid _revealId");
        RevealStruct storage reveal = reveals[_revealId];
        require(
            reveal.status == RevealStatus.Started,
            "The reveal is not in the Started status"
        );
        require(
            block.timestamp > reveal.revealDate,
            "There is still time for this reveal"
        );
        reveal.status = RevealStatus.Cancelled;

        IERC20 prizeTokenContract = IERC20(prizeTokenAddress);
        prizeTokenContract.transfer(supervisorAddress, reveal.prizeTokens);
        lockedTokens -= reveal.prizeTokens;

        emit RevealCancelled(_revealId);
    }

    /**
     * @dev Returns the address that registered the ticket with the specified ticket number in
     * the given reveal
     * @param _revealId - The reveal ID
     * @param _ticketNumber - The ticket number
     * @return - The address that registered the specified ticket in the given reveal
     *
     * This function retrieves the address of the user who registered a specific ticket
     * in a given reveal.
     *
     * Requirements:
     * - `_revealId` must be valid.
     * - `_ticketNumber` must be valid.
     */
    function getTicketAddress(
        uint256 _revealId,
        uint256 _ticketNumber
    ) public view returns (address) {
        return tickets[_revealId][_ticketNumber];
    }

    /**
     * @dev Set the supervisor address
     * @param _newAddress - new supervisor address
     *
     * This function allows the contract owner to update the supervisor address.
     * The caller must have the DEFAULT_ADMIN_ROLE to execute this function.
     */
    function setSupervisorAddress(
        address payable _newAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        supervisorAddress = _newAddress;
    }

    /**
     *@dev Gets the number of reveals created
     *@return The total number of reveals created
     *This function returns the total number of reveals that have been created so far
     *by querying the reveals array's length.
     */
    function getRevealCount() external view returns (uint256) {
        return reveals.length;
    }

    /**
     * @dev Used to see if a player is already registered for a reveal
     * @param _revealId - The reveal ID
     * @param _playerAddress - The player's address
     * @return - Returns true if the _playerAddress is already registered for the specified _revealId
     *
     * Requirements:
     * - `_revealId` must be valid.
     * - `_playerAddress` must be a valid address.
     */
    function isPlayerAlreadyRegistered(
        uint256 _revealId,
        address _playerAddress
    ) external view returns (bool) {
        bytes32 hash = keccak256(abi.encode(_revealId, _playerAddress));
        return playerAlreadyRegistered[hash];
    }

    /**
     * @dev Receive function to accept matic
     *
     * This function is a fallback function that allows the contract to receive matic
     * when no other function is called. This function is marked as `external` and
     * `payable`, meaning it can be called from outside the contract and can receive
     * matic.
     *
     */
    receive() external payable {}

    /**
     * @dev Helper function for testing
     *
     */
    function setCancellationDate(
        uint256 _revealId,
        uint256 _minutes
    ) external nonReentrant onlyRole(SUPERVISOR_ROLE) {
        RevealStruct storage reveal = reveals[_revealId];
        require(
            reveal.status == RevealStatus.Started,
            "The reveal is not in the Started status"
        );
        reveal.revealDate = block.timestamp + _minutes * 1 minutes;
    }
}