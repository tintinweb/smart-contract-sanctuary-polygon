// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity =0.8.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Manager is AccessControl, ReentrancyGuard, VRFConsumerBase, Ownable {
    ////////// CHAINLINK VRF v1 /////////////////
    bytes32 internal keyHash;
    uint256 internal fee;

    struct RandomResult {
        uint256 randomNumber; // random number generated by chainlink.
        uint256 nomalizedRandomNumber; // random number % entriesLength + 1
    }

    struct RaffleInfo {
        uint256 id; // raffleId
        uint256 size; // length of the entries array of that raffle
    }

    // event sent when the random number is generated by the VRF
    event RandomNumberCreated(
        uint256 indexed raffleId,
        uint256 randomNumber,
        uint256 normalizedRandomNumber
    );

    mapping(uint256 => RandomResult) public requests;
    // map the requestId created by chainlink with the raffle info passed as param when calling getRandomNumber()
    mapping(bytes32 => RaffleInfo) public chainlinkRaffleInfo;
    // Add a new mapping to store requestIds for each raffle
    mapping(uint256 => bytes32) private raffleRequestIds;

    /////////////// END CHAINKINK VRF V1 //////////////

    // Event sent when the raffle is created by the operator
    event RaffleCreated(
        uint256 indexed raffleId,
        address indexed nftAddress,
        uint256 indexed nftId
    );

    // Event sent when the owner of the nft stakes it for the raffle
    event RaffleStarted(uint256 indexed raffleId, address indexed seller);

    // Event sent when the raffle is finished
    event RaffleEnded(
        uint256 indexed raffleId,
        address indexed winner,
        uint256 amountRaised,
        uint256 randomNumber
    );

    // Event sent when one or more entry tickets are sold
    event EntrySold(
        uint256 indexed raffleId,
        address indexed buyer,
        uint256 currentSize
    );

    // Event sent when a free entry is added by the operator
    event FreeEntry(
        uint256 indexed raffleId,
        address[] buyer,
        uint256 amount,
        uint256 currentSize
    );

    // Event sent when a raffle is asked to cancel by the operator
    event RaffleCancelled(uint256 indexed raffleId, uint256 amountRaised);

    // The raffle is closed successfully and the platform receives the fee
    event FeeTransferredToPlatform(
        uint256 indexed raffleId,
        uint256 amountTransferred
    );
    // When the raffle is asked to be cancelled and 30 days have passed, the operator can call a method
    // to transfer the remaining funds and this event is emitted
    event RemainingFundsTransferred(
        uint256 indexed raffleId,
        uint256 amountInWeis
    );

    // When the raffle is asked to be cancelled and 30 days have not passed yet, the players can call a
    // method to refund the amount spent on the raffle and this event is emitted
    event Refund(
        uint256 indexed raffleId,
        uint256 amountInWeis,
        address indexed player
    );

    event SetWinnerTriggered(uint256 indexed raffleId, uint256 amountRaised);

    event StatusChangedInEmergency(uint256 indexed raffleId, uint256 newStatus);

    /* every raffle has an array of price structure with the different 
    prices for the different entries bought */
    struct PriceStructure {
        uint256 id;
        uint256 numEntries;
        uint256 price;
    }
    mapping(uint256 => PriceStructure[1]) public prices;

    // Every raffle has a funding structure.
    struct FundingStructure {
        uint256 minimumFundsInWeis;
    }
    mapping(uint256 => FundingStructure) public fundingList;

    // In order to calculate the winner, in this struct is saved for each bought the data
    struct EntriesBought {
        uint256 currentEntriesLength; // current amount of entries bought in the raffle
        address player; // wallet address of the player
    }

    // every raffle has a sorted array of EntriesBought. Each element is created when calling
    // either buyEntry or giveBatchEntriesForFree
    mapping(uint256 => EntriesBought[]) public entriesList;

    // Main raffle data struct
    struct RaffleStruct {
        STATUS status; // status of the raffle. Can be created, accepted, ended, etc
        uint256 maxEntries; // maximum number of entries, aka total ticket supply
        address collateralAddress; // address of the NFT
        uint256 collateralId; // NFT id of the collateral NFT
        address winner; // address of the winner of the raffle. Address(0) if no winner yet
        uint256 randomNumber; // normalized (0-Entries array size) random number generated by the VRF
        uint256 amountRaised; // funds raised so far in wei
        address seller; // address of the seller of the NFT
        uint256 platformPercentage; // percentage of the funds raised that goes to the platform
        uint256 entriesLength; // the length of the entries array is saved here
        uint256 expiryTimeStamp;
    }

    // The main structure is an array of raffles
    RaffleStruct[] public raffles;

    // Map that contains the number of entries each user has bought, to prevent abuse, and the claiming info
    struct ClaimStruct {
        uint256 numEntriesPerUser;
        uint256 amountSpentInWeis;
        bool claimed;
    }
    mapping(bytes32 => ClaimStruct) public claimsData;

    // All the different status VRFCoordinator can have
    enum STATUS {
        CREATED, // the operator creates the raffle
        ACCEPTED, // the seller stakes the nft for the raffle
        EARLY_CASHOUT, // the seller wants to cashout early
        CANCELLED, // the operator cancels the raffle and transfer the remaining funds after 30 days passes
        CLOSING_REQUESTED, // the operator sets a winner
        ENDED, // the raffle is finished, and NFT and funds were transferred
        CANCEL_REQUESTED, // operator asks to cancel the raffle. Players has 30 days to ask for a refund
        CLOSING_FAILED // the operator failed to set a winner
    }

    // The operator role is operated by a backend application
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

    // address of the wallet controlled by the platform that will receive the platform fee
    address payable public destinationWallet =
        payable(0x520dcCE3c0d35804312c186DB4DB8d9249C4Ee5B);

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash
    )
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _linkToken // LINK Token
        )
    {
        _setupRole(
            OPERATOR_ROLE,
            address(0x11E7Fa3Bc863bceD1F1eC85B6EdC9b91FdD581CF)
        );
        _setupRole(
            DEFAULT_ADMIN_ROLE,
            address(0x11E7Fa3Bc863bceD1F1eC85B6EdC9b91FdD581CF)
        );

        keyHash = _keyHash;
        fee = 0.0001 * 10 ** 18; // in polygon, the fee must be 0.0001 LINK
    }

    /// @dev this is the method that will be called by the smart contract to get a random number
    /// @param _id Id of the raffle
    /// @param _entriesSize length of the entries array of that raffle
    /// @return requestId Id generated by chainlink
    function getRandomNumber(
        uint256 _id,
        uint256 _entriesSize
    ) internal returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - please fund contract"
        );
        bytes32 result = requestRandomness(keyHash, fee);

        // result is the requestId generated by chainlink. It is saved in a map linked to the param id
        chainlinkRaffleInfo[result] = RaffleInfo({id: _id, size: _entriesSize});
        return result;
    }

    /// @dev Callback function used by VRF Coordinator. Is called by chainlink
    /// the random number generated is normalized to the size of the entries array, and an event is
    /// generated, that will be listened by the platform backend to be checked if corresponds to a
    /// particular raffle, and if true will call transferNFTAndFunds
    /// @param requestId id generated previously (on method getRandomNumber by chainlink)
    /// @param randomness random number (huge) generated by chainlink
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal override {
        // Get the raffle info from the map
        RaffleInfo memory raffleInfo = chainlinkRaffleInfo[requestId];

        // Check if the requestId has already been fulfilled
        if (raffles[raffleInfo.id].status == STATUS.ENDED) {
            return;
        }

        uint256 normalizedRandomNumber = (randomness % raffleInfo.size) + 1;

        // save the random number on the map with the original id as key
        RandomResult memory result = RandomResult({
            randomNumber: randomness,
            nomalizedRandomNumber: normalizedRandomNumber
        });

        requests[raffleInfo.id] = result;

        // send the event with the original id and the random number
        emit RandomNumberCreated(
            raffleInfo.id,
            randomness,
            normalizedRandomNumber
        );

        transferNFTAndFunds(raffleInfo.id, normalizedRandomNumber);
    }

    // The operator can call this method once they receive the event "RandomNumberCreated"
    // triggered by the VRF v1 consumer contract
    /// @param _raffleId Id of the raffle
    /// @param _normalizedRandomNumber index of the array that contains the winner of the raffle. Generated by chainlink
    /// @notice it is the method that sets the winner and transfers funds and nft
    /// @dev called by Chainlink callback function fulfillRandomness
    function transferNFTAndFunds(
        uint256 _raffleId,
        uint256 _normalizedRandomNumber
    ) internal nonReentrant {
        RaffleStruct storage raffle = raffles[_raffleId];

        // Only callable when the raffle is requested to be closed
        require(
            raffle.status == STATUS.EARLY_CASHOUT ||
                raffle.status == STATUS.CLOSING_REQUESTED,
            "Raffle in wrong status"
        );

        raffle.randomNumber = _normalizedRandomNumber;

        if (raffle.amountRaised == 0) {
            raffle.winner = raffle.seller;
        } else {
            raffle.winner = getWinnerAddressFromRandom(
                _raffleId,
                _normalizedRandomNumber
            );
        }

        IERC721 _asset = IERC721(raffle.collateralAddress);
        _asset.transferFrom(address(this), raffle.winner, raffle.collateralId); // transfer the NFT to the winner

        uint256 amountForPlatform = (raffle.amountRaised *
            raffle.platformPercentage) / 10000;
        uint256 amountForSeller = raffle.amountRaised - amountForPlatform;

        // transfer 95% to the seller
        (bool sent, ) = raffle.seller.call{value: amountForSeller}("");
        require(sent, "Failed to send Ether");

        // transfer 5% to the platform
        (bool sent2, ) = destinationWallet.call{value: amountForPlatform}("");
        require(sent2, "Failed send Eth to MW");

        raffle.status = STATUS.ENDED;

        emit FeeTransferredToPlatform(_raffleId, amountForPlatform);

        emit RaffleEnded(
            _raffleId,
            raffle.winner,
            raffle.amountRaised,
            _normalizedRandomNumber
        );
    }

    // helper unction to view the current status of the raffle
    /// @param _raffleId Id of the raffle
    function getRaffleStatus(uint256 _raffleId) public view returns (STATUS) {
        RaffleStruct storage raffle = raffles[_raffleId];
        return raffle.status;
    }

    // helper function for onlyOwner to extract the NFT from the contract
    // in the case of a failed raffle. This is to avoid the NFT being stuck in the contract
    // if the chainlink callback function does not exectute as expected
    /// @param _raffleId Id of the raffle
    function extractNFT(uint256 _raffleId) public onlyOwner {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(raffle.collateralId != 0, "Raffle collateralId is not set");
        require(
            raffle.collateralAddress != address(0),
            "Raffle collateralAddress is not set"
        );
        IERC721(raffle.collateralAddress).safeTransferFrom(
            address(this),
            owner(),
            raffle.collateralId
        );
    }

    // helper function for onlyOwner to extract the funds from the contract
    // in the case of a failed raffle. This is to avoid the funds being stuck in the contract
    // if the chainlink callback function does not exectute as expected
    /// @param _raffleId Id of the raffle
    function extractFunds(uint256 _raffleId) public payable onlyOwner {
        RaffleStruct storage raffle = raffles[_raffleId];
        require(raffle.collateralId != 0, "Raffle collateralId is not set");
        require(
            raffle.collateralAddress != address(0),
            "Raffle collateralAddress is not set"
        );

        payable(owner()).transfer(raffle.amountRaised);
    }

    // helper function to get the number of all the entries bought for a
    // particular raffle
    /// @param _raffleId Id of the raffle
    function getNumberOfEntries(
        uint256 _raffleId
    ) public view returns (uint256) {
        RaffleStruct storage raffle = raffles[_raffleId];
        return raffle.entriesLength;
    }

    // helper function to get all of the raffle struct data
    // for a particular raffle Id
    /// @param _raffleId Id of the raffle
    function getRaffle(
        uint256 _raffleId
    )
        public
        view
        returns (
            STATUS,
            uint256,
            address,
            uint256,
            address,
            uint256,
            uint256,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        RaffleStruct storage raffle = raffles[_raffleId];
        return (
            raffle.status,
            raffle.amountRaised,
            raffle.collateralAddress,
            raffle.collateralId,
            raffle.seller,
            raffle.entriesLength,
            raffle.randomNumber,
            raffle.winner,
            raffle.platformPercentage,
            raffle.expiryTimeStamp,
            raffle.maxEntries
        );
    }

    // function to create a raffle
    /// @param _collateralAddress The address of the NFT of the raffle
    /// @param _collateralId The id of the NFT (ERC721)
    /// @param _prices Array of prices and amount of entries the customer could purchase
    /// @notice Creates a raffle
    /// @dev creates a raffle struct and push it to the raffles array. Some data is stored in the funding data structure
    /// sends an event when finished
    /// @return raffleId
    function createRaffle(
        uint256 _maxEntries,
        address _collateralAddress,
        uint256 _collateralId,
        uint256 _pricePerTicketInWeis,
        PriceStructure[] calldata _prices,
        address _raffleCreator,
        uint256 _expiryTimeStamp
    ) external returns (uint256) {
        uint256 _minimumFundsInWeis = 1; //TODO what is the impact of this
        uint _commissionInBasicPoints = 500;

        require(_collateralAddress != address(0), "NFT is null");
        require(_collateralId != 0, "NFT id is null");
        require(_maxEntries > 0, "Max entries is needs to be greater than 0");

        /* instantiate the raffle struct and push it to the raffles array
         the winner defaults to the raffle creator if no one buys a ticket */
        RaffleStruct memory raffle = RaffleStruct({
            status: STATUS.CREATED,
            maxEntries: _maxEntries,
            collateralAddress: _collateralAddress,
            collateralId: _collateralId,
            winner: _raffleCreator,
            randomNumber: 0,
            amountRaised: 0,
            seller: _raffleCreator,
            platformPercentage: _commissionInBasicPoints,
            entriesLength: 0,
            expiryTimeStamp: _expiryTimeStamp
        });

        raffles.push(raffle);

        PriceStructure memory p = PriceStructure({
            id: _prices[0].id,
            numEntries: _maxEntries,
            price: _pricePerTicketInWeis
        });

        uint raffleID = raffles.length - 1;
        prices[raffleID][0] = p;

        fundingList[raffleID] = FundingStructure({
            minimumFundsInWeis: _minimumFundsInWeis
        });

        emit RaffleCreated(raffleID, _collateralAddress, _collateralId);

        stakeNFT(raffleID);
        return raffleID;
    }

    // function for the creator of the raffle to stake the NFT
    // the NFT is transferred to the contract and the status of the raffle is set to ACCEPTED
    /// @param _raffleId Id of the raffle
    function stakeNFT(uint256 _raffleId) internal {
        RaffleStruct storage raffle = raffles[_raffleId];

        // ensure the raffle is in the CREATED state. This should be the next state after the raffle is created
        require(raffle.status == STATUS.CREATED, "Raffle not CREATED");

        IERC721 token = IERC721(raffle.collateralAddress);
        require(
            token.ownerOf(raffle.collateralId) == msg.sender,
            "NFT is not owned by caller"
        );

        raffle.status = STATUS.ACCEPTED;
        token.transferFrom(msg.sender, address(this), raffle.collateralId); // transfer the token to the contract

        emit RaffleStarted(_raffleId, msg.sender);
    }

    /// function to buy a ticket for a raffle. The user can buy multiple tickets at once
    /// As the method is payable, in msg.value there will be the amount paid by the user
    /// @param _raffleId: id of the raffle
    /// @param _numberOfTickets: number of tickets the user wants to buy
    function buyEntry(
        uint256 _raffleId,
        uint256 _numberOfTickets
    ) external payable nonReentrant {
        RaffleStruct storage raffle = raffles[_raffleId];
        PriceStructure memory priceStruct = getPriceStructForId(_raffleId);

        require(
            raffle.seller != msg.sender,
            "The seller cannot buy his/her own tickets"
        );
        require(msg.sender != address(0), "msg.sender is null");
        require(
            raffle.status == STATUS.ACCEPTED,
            "Raffle is not in accepted. AKA the NFT was never staked / sent to the contract"
        );
        require(raffle.expiryTimeStamp > block.timestamp, "Raffle has expired");
        require(
            raffle.entriesLength < raffle.maxEntries,
            "Raffle has reached max entries"
        );
        require(priceStruct.numEntries > 0, "priceStruct.numEntries");
        require(
            _numberOfTickets <= priceStruct.numEntries,
            "buying more than the maximum tickets"
        );
        require(
            msg.value == _numberOfTickets * priceStruct.price,
            "msg.value must be equal to the price * number of tickets"
        );

        bytes32 hash = keccak256(abi.encode(msg.sender, _raffleId));

        EntriesBought memory entryBought = EntriesBought({
            player: msg.sender,
            currentEntriesLength: _numberOfTickets
        });
        entriesList[_raffleId].push(entryBought);

        // update raffle data
        raffle.amountRaised += msg.value;
        raffle.entriesLength = raffle.entriesLength + _numberOfTickets;

        //update claim data
        claimsData[hash].numEntriesPerUser += priceStruct.numEntries;
        claimsData[hash].amountSpentInWeis += msg.value;

        emit EntrySold(_raffleId, msg.sender, _numberOfTickets);
    }

    // helper function to get the price structure for a given raffle
    /// @param _idRaffle: id of the raffle
    /// @return priceStruct: price structure for the raffle
    function getPriceStructForId(
        uint256 _idRaffle
    ) internal view returns (PriceStructure memory) {
        return prices[_idRaffle][0];
    }

    // helper method to get the winner address of a raffle
    /// @param _raffleId Id of the raffle
    /// @param _normalizedRandomNumber Generated by chainlink
    /// @return the wallet that won the raffle
    /// @dev Uses a binary search on the sorted array to retreive the winner address
    function getWinnerAddressFromRandom(
        uint256 _raffleId,
        uint256 _normalizedRandomNumber
    ) public view returns (address) {
        RaffleStruct storage raffle = raffles[_raffleId];

        uint256 position = findUpperBound(
            entriesList[_raffleId],
            _normalizedRandomNumber
        );

        address candidate = entriesList[_raffleId][position].player;
        // general case
        if (candidate != raffle.seller) return candidate;
        // special case. The user is blacklisted, so try next on the left until find a non-blacklisted
        else {
            bool ended = false;
            uint256 i = position;
            while (
                ended == false && entriesList[_raffleId][i].player == address(0)
            ) {
                if (i == 0) i = entriesList[_raffleId].length - 1;
                else i = i - 1;
                // we came to the beginning without finding a non blacklisted player
                if (i == position) ended == true;
            }
            return entriesList[_raffleId][i].player;
        }
    }

    /// @param array sorted array of EntriesBought. CurrentEntriesLength is the numeric field used to sort
    /// @param element uint256 to find. Goes from 1 to entriesLength
    /// @dev based on openzeppelin code (v4.0), modified to use an array of EntriesBought
    /// Searches a sorted array and returns the first index that contains a value greater or equal to element.
    /// If no such index exists (i.e. all values in the array are strictly less than element), the array length is returned. Time complexity O(log n).
    /// array is expected to be sorted in ascending order, and to contain no repeated elements.
    /// https://docs.openzeppelin.com/contracts/3.x/api/utils#Arrays-findUpperBound-uint256---uint256-
    function findUpperBound(
        EntriesBought[] storage array,
        uint256 element
    ) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid].currentEntriesLength > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1].currentEntriesLength == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    // function to set the winner of a raffle. Technically anyone can call this function to trigger the chainlink VRF
    /// @param _raffleId Id of the raffle
    /// @dev it triggers Chainlink VRF1 consumer, and generates a random number that is normalized to the number of entries
    function setWinner(uint256 _raffleId) external nonReentrant {
        RaffleStruct storage raffle = raffles[_raffleId];
        FundingStructure storage funding = fundingList[_raffleId];

        require(
            raffle.status == STATUS.ACCEPTED ||
                raffle.status == STATUS.CLOSING_FAILED,
            "Raffle in wrong status"
        );
        require(
            raffle.expiryTimeStamp < block.timestamp,
            "Raffle not expired yet"
        );

        // Only update status if the request to Chainlink VRF is successful
        // TODO: this isn't working properly because sometimes the chainlink callback function is never executed.
        bytes32 requestId = getRandomNumber(_raffleId, raffle.entriesLength);
        if (requestId != bytes32(0)) {
            raffleRequestIds[_raffleId] = requestId;
            raffle.status = STATUS.CLOSING_REQUESTED;
            emit SetWinnerTriggered(_raffleId, raffle.amountRaised);
        } else {
            raffle.status = STATUS.CLOSING_FAILED;
        }
    }

    // function to manually set the winner of a raffle. Only callable by the owner
    // this is useful in case Chainlink VRF fails to generate a random number
    // and the raffle is stuck in CLOSING_REQUESTED status
    /// @param _raffleId Id of the raffle
    /// @param _normalizedRandomNumber random number we want to use to set the winner
    function transferNFTAndFundsEmergency(
        uint256 _raffleId,
        uint256 _normalizedRandomNumber
    ) public nonReentrant onlyOwner {
        RaffleStruct storage raffle = raffles[_raffleId];

        // Only callable when the raffle is requested to be closed
        require(
            raffle.status == STATUS.CLOSING_REQUESTED,
            "Raffle in wrong status"
        );

        raffle.randomNumber = _normalizedRandomNumber;

        if (raffle.amountRaised == 0) {
            raffle.winner = raffle.seller;
        } else {
            raffle.winner = getWinnerAddressFromRandom(
                _raffleId,
                _normalizedRandomNumber
            );
        }

        IERC721 _asset = IERC721(raffle.collateralAddress);
        _asset.transferFrom(address(this), raffle.winner, raffle.collateralId); // transfer the NFT to the winner

        uint256 amountForPlatform = (raffle.amountRaised *
            raffle.platformPercentage) / 10000;
        uint256 amountForSeller = raffle.amountRaised - amountForPlatform;

        // transfer 95% to the seller
        (bool sent, ) = raffle.seller.call{value: amountForSeller}("");
        require(sent, "Failed to send Ether");

        // transfer 5% to the platform
        (bool sent2, ) = destinationWallet.call{value: amountForPlatform}("");
        require(sent2, "Failed send Eth to MW");

        raffle.status = STATUS.ENDED;

        emit FeeTransferredToPlatform(_raffleId, amountForPlatform);

        emit RaffleEnded(
            _raffleId,
            raffle.winner,
            raffle.amountRaised,
            _normalizedRandomNumber
        );
    }

    // this is the method to be called by the owner to re-trigger getting a random
    // number when the raffle is stuck in CLOSING_REQUESTED status because the
    // Chainlink VRF callback function was never executed
    /// @param _id Id of the raffle
    /// @param _entriesSize length of the entries array of that raffle
    /// @return requestId Id generated by chainlink
    function getRandomNumberEmergency(
        uint256 _id,
        uint256 _entriesSize
    ) public onlyOwner returns (bytes32 requestId) {
        RaffleStruct storage raffle = raffles[_id];

        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - please fund contract"
        );
        require(
            raffle.status == STATUS.CLOSING_REQUESTED,
            "Raffle in wrong status"
        );
        bytes32 result = requestRandomness(keyHash, fee);

        // result is the requestId generated by chainlink. It is saved in a map linked to the param id
        chainlinkRaffleInfo[result] = RaffleInfo({id: _id, size: _entriesSize});
        return result;
    }
}