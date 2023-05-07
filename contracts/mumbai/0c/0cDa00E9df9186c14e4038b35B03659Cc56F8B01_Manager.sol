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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";



/// @title Raffles Manager
/// @notice It consumes VRF v1 from Chainlink. It has the role
/// There are two type of roles - operator and user
/// Operator can create admin raffles and users can care user raffles
/// Raffle can use 3 type of assets - NFT, ETH and ERC20 token
/// @dev It saves in an ordered array the player wallet and the current
/// entries count. So buying entries has a complexity of O(1)
/// For calculating the winner, from the huge random number generated by Chainlink
/// a normalized random is generated by using the module method, adding 1 to have
/// a random from 1 to entriesCount.
/// So next step is to perform a binary search on the ordered array to get the
/// player O(log n)
/// Example:
/// 0 -> { 1, player1} as player1 buys 1 entry
/// 1 -> {51, player2} as player2 buys 50 entries
/// 2 -> {52, player3} as player3 buys 1 entry
/// 3 -> {53, player4} as player4 buys 1 entry
/// 4 -> {153, player5} as player5 buys 100 entries
/// So the setWinner method performs a binary search on that sorted array to get the upper bound.
/// If the random number generated is 150, the winner is player5. If the random number is 20, winner is player2

contract Manager is AccessControl, ReentrancyGuard, VRFConsumerBase {
  using SafeERC20 for IERC20;

  ////////// CHAINLINK VRF v1 /////////////////
  bytes32 internal keyHash; // chainlink
  uint256 internal fee; // fee paid in LINK to chainlink. 0.1 in Rinkeby, 2 in mainnet

  struct RandomResult {
    uint256 randomNumber; // random number generated by chainlink.
    uint256 nomalizedRandomNumber; // random number % entriesLength + 1. So between 1 and entries.length
  }

  // event sent when the random number is generated by the VRF
  event RandomNumberCreated(
    bytes32 indexed id,
    uint256 randomNumber,
    uint256 normalizedRandomNumber
  );

  struct RaffleInfo {
    bytes32 id; // raffleId
    uint256 size; // length of the entries array of that raffle
  }

  mapping(bytes32 => RandomResult) public requests;
  // map the requestId created by chainlink with the raffle info passed as param when calling getRandomNumber()
  mapping(bytes32 => RaffleInfo) public chainlinkRaffleInfo;

  /////////////// END CHAINKINK VRF V1 //////////////

  /// ENTRIES

  // Type of Raffle
  enum RAFFLETYPE {
    NFT, // NFT raffle
    ETH, // Native token raffle
    ERC20 // erc20 token raffle
  }
  // All the different status a rafVRFCoordinatorfle can have
  enum STATUS {
    CREATED, // the operator creates the raffle
    EARLY_CASHOUT, // the seller wants to cashout early
    CANCELLED, // the operator cancels the raffle and transfer the remaining funds after 30 days passes
    CLOSING_REQUESTED, // the operator sets a winner
    ENDED, // the raffle is finished, and NFT and funds were transferred
    CANCEL_REQUESTED // operator asks to cancel the raffle. Players has 30 days to ask for a refund
  }

  // Event sent when the raffle is created by the operator
  event RaffleCreated(
    bytes32 indexed raffleId,
    address indexed collateralAddress,
    uint256 indexed collateralParam,
    uint256 endTime,
    uint256 ticketSupply,
    address seller,
    RAFFLETYPE raffleType,
    bool operatorCreated
  );

  // Event sent when the raffle is finished (either early cashout or successful completion)
  event RaffleEnded(
    bytes32 indexed raffleId,
    address indexed winner,
    uint256 amountRaised,
    uint256 randomNumber
  );
  // Event sent when one or more entries are sold (info from the price structure)
  event EntrySold(
    bytes32 indexed raffleId,
    address indexed buyer,
    uint256 numTickets,
    uint256 soldEntries,
    uint256 price
  );
  // Event sent when a free entry is added by the operator
  event FreeEntry(bytes32 indexed raffleId, address[] buyer, uint256 amount, uint256 soldEntries);
  // Event sent when a raffle is asked to cancel by the operator
  event RaffleCancelled(bytes32 indexed raffleId, uint256 amountRaised);
  // The raffle is closed successfully and the platform receives the fee
  event FeeTransferredToPlatform(bytes32 indexed raffleId, uint256 amountTransferred);
  // When the raffle is asked to be cancelled and 30 days have passed, the operator can call a method
  // to transfer the remaining funds and this event is emitted
  event RemainingFundsTransferred(bytes32 indexed raffleId, uint256 amountInWeis);
  // When the raffle is asked to be cancelled and 30 days have not passed yet, the players can call a
  // method to refund the amount spent on the raffle and this event is emitted
  event Refund(bytes32 indexed raffleId, uint256 amountInWeis, address indexed player);
  event EarlyCashoutTriggered(bytes32 indexed raffleId, uint256 amountRaised);
  event SetWinnerTriggered(bytes32 indexed raffleId, uint256 amountRaised);
  // When new price structure created
  event PriceStructureCreated(
    bytes32 indexed raffleId,
    uint256 id,
    uint256 numTickets,
    uint256 price
  );

  /* every raffle has an array of price structure (max size = 5) with the different 
    prices for the different entries bought. The price for 1 entry is different than 
    for 5 entries where there is a discount*/
  struct PriceStructure {
    uint256 id;
    uint256 numTickets;
    uint256 price;
  }
  mapping(bytes32 => PriceStructure[5]) public prices;

  // Every raffle has a funding structure.
  struct FundingStructure {
    uint256 minTicketCount;
    uint256 maxTicketCount;
  }
  mapping(bytes32 => FundingStructure) public fundingList;

  // In order to calculate the winner, in this struct is saved for each bought the data
  struct EntriesBought {
    uint256 currentEntriesLength; // current amount of entries bought in the raffle
    address player; // wallet address of the player
  }
  // every raffle has a sorted array of EntriesBought. Each element is created when calling
  // either buyEntry or giveBatchEntriesForFree
  mapping(bytes32 => uint256) public soldTicketCount;
  mapping(bytes32 => uint256) public entriesCount;
  mapping(bytes32 => mapping(uint256 => EntriesBought)) public entries;

  // signature structure
  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  // Raffle create struct of operator(admin)
  struct OperatorCreateParam {
    RAFFLETYPE raffleType; // type of raffle
    address collateralAddress; // The address of the NFT of the raffle
    uint256 collateralParam; // The id of the NFT (ERC721)
    uint256 minTicketCount; // min entries count to sell
    uint256 maxTicketCount; // max entries count to sell
    uint256 endTime; // end time of raffle
  }

  // Raffle create struct of user
  struct UserCreateParam {
    RAFFLETYPE raffleType; // type of raffle
    address collateralAddress; // The address of the NFT of the raffle
    uint256 collateralParam; // The id of the NFT (ERC721)
    uint256 ticketSupply; // max entries count to sell
    uint256 ticketPrice; // mint price of ticket
    uint256 endTime; // end time of raffle
  }

  // Main raffle data struct
  struct RaffleStruct {
    RAFFLETYPE raffleType; // type of raffle
    STATUS status; // status of the raffle. Can be created, accepted, ended, etc
    bool operatorCreated; // if operator created, this value is true, else value is false
    address collateralAddress; // address of the NFT
    uint256 collateralParam; // NFT id of the NFT, amount of reward token
    address winner; // address of thed winner of the raffle. Address(0) if no winner yet
    uint256 randomNumber; // normalized (0-Entries array size) random number generated by the VRF
    uint256 amountRaised; // funds raised so far in wei
    address seller; // address of the seller of the NFT
    uint256 endTime; // end time of raffle
    uint256 cancellingDate;
    uint256 ticketPrice;
    address[] collectionWhitelist; // addresses of the required nfts. Will be empty if no NFT is required to buy
  }
  // The main structure is an array of raffles
  mapping(bytes32 => RaffleStruct) public raffles;

  // Map that contains the number of entries each user has bought, to prevent abuse, and the claiming info
  struct ClaimStruct {
    uint256 numTicketsPerUser;
    uint256 amountSpentInWeis;
    bool claimed;
  }
  mapping(bytes32 => ClaimStruct) public claimsData;

  // Map with the addresses linked to a particular raffle + nft
  mapping(bytes32 => address) public requiredNFTWallets;

  // The operator role is operated by a backend application
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

  // All operator raffle funds goes to vault
  address public immutable vault;

  // user can create raffle with signer signature
  address public signer;

  constructor(
    address _vault,
    address _signer,
    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash,
    uint256 _fee
  )
    VRFConsumerBase(
      _vrfCoordinator, // VRF Coordinator
      _linkToken // LINK Token
    )
  {
    // _setupRole(OPERATOR_ROLE, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    vault = _vault;
    signer = _signer;
    keyHash = _keyHash;
    fee = _fee;
  }

  /// external functions

  /// @param _params params to create raffle
  /// @param _prices Array of prices and amount of entries the customer could purchase
  /// @param _collectionWhitelist array with the required collections to participate in the raffle. Empty if there is no collection
  /// @notice Creates a raffle
  /// @dev creates a raffle struct and push it to the raffles array. Some data is stored in the funding data structure
  /// sends an event when finished
  /// @return raffleId
  function operatorCreateRaffle(
    OperatorCreateParam calldata _params,
    PriceStructure[] calldata _prices,
    address[] calldata _collectionWhitelist
  ) external payable onlyRole(OPERATOR_ROLE) returns (bytes32) {
    require(_params.endTime > block.timestamp, "Invalid end time");

    RaffleStruct memory raffle = RaffleStruct({
      raffleType: _params.raffleType,
      status: STATUS.CREATED,
      operatorCreated: true,
      collateralAddress: _params.collateralAddress,
      collateralParam: _params.collateralParam,
      winner: address(0),
      randomNumber: 0,
      amountRaised: 0,
      seller: msg.sender,
      endTime: _params.endTime,
      cancellingDate: 0,
      ticketPrice: 0,
      collectionWhitelist: _collectionWhitelist
    });

    bytes32 key = _getRaffleKey(raffle);
    raffles[key] = raffle;

    require(_prices.length > 0, "No prices");

    for (uint256 i = 0; i < _prices.length; i++) {
      require(_prices[i].numTickets > 0, "numTickets is 0");

      prices[key][i] = _prices[i];

      emit PriceStructureCreated(key, _prices[i].id, _prices[i].numTickets, _prices[i].price);
    }

    fundingList[key] = FundingStructure({
      minTicketCount: _params.minTicketCount,
      maxTicketCount: _params.maxTicketCount
    });

    if (_params.raffleType == RAFFLETYPE.NFT) {
      // transfer the asset to the contract
      //  IERC721 _asset = IERC721(raffle.collateralAddress);
      IERC721 token = IERC721(raffle.collateralAddress);
      token.transferFrom(msg.sender, address(this), raffle.collateralParam); // transfer the token to the contract
    } else if (_params.raffleType == RAFFLETYPE.ERC20) {
      // transfer the asset to the contract
      //  IERC20 _asset = IERC20(raffle.collateralAddress);
      IERC20 token = IERC20(raffle.collateralAddress);
      token.safeTransferFrom(msg.sender, address(this), raffle.collateralParam); // transfer the token to the contract
    } else {
      require(msg.value == raffle.collateralParam, "Invalid deposit amount");
    }

    emit RaffleCreated(
      key,
      _params.collateralAddress,
      _params.collateralParam,
      _params.endTime,
      _params.maxTicketCount,
      msg.sender,
      _params.raffleType,
      true
    );

    return key;
  }

  /// @param _params params to create raffle
  /// @param _collectionWhitelist array with the required collections to participate in the raffle. Empty if there is no collection
  /// @param _sig sigature of signer to validate collection
  /// @notice Creates a raffle
  /// @dev creates a raffle struct and push it to the raffles array. Some data is stored in the funding data structure
  /// sends an event when finished
  /// @return raffleId
  function userCreateRaffle(
    UserCreateParam calldata _params,
    address[] calldata _collectionWhitelist,
    Sig calldata _sig
  ) external payable returns (bytes32) {
    require(
      _params.endTime >= block.timestamp + 1 days && _params.endTime <= block.timestamp + 14 days,
      "Invalid end time - Min: 24 hours, Max: 14 days"
    );
    require(
      _validateCreateCollection(_params.collateralAddress, _sig),
      "This collection is not whitelisted"
    );

    RaffleStruct memory raffle = RaffleStruct({
      raffleType: _params.raffleType,
      status: STATUS.CREATED,
      operatorCreated: false,
      collateralAddress: _params.collateralAddress,
      collateralParam: _params.collateralParam,
      winner: address(0),
      randomNumber: 0,
      amountRaised: 0,
      seller: msg.sender,
      endTime: _params.endTime,
      cancellingDate: 0,
      ticketPrice: _params.ticketPrice,
      collectionWhitelist: _collectionWhitelist
    });

    bytes32 key = _getRaffleKey(raffle);
    raffles[key] = raffle;

    fundingList[key] = FundingStructure({minTicketCount: 0, maxTicketCount: _params.ticketSupply});

    if (_params.raffleType == RAFFLETYPE.NFT) {
      // transfer the asset to the contract
      //  IERC721 _asset = IERC721(raffle.collateralAddress);
      IERC721 token = IERC721(raffle.collateralAddress);
      token.transferFrom(msg.sender, address(this), raffle.collateralParam); // transfer the token to the contract
    } else if (_params.raffleType == RAFFLETYPE.ERC20) {
      // transfer the asset to the contract
      //  IERC20 _asset = IERC20(raffle.collateralAddress);
      IERC20 token = IERC20(raffle.collateralAddress);
      token.safeTransferFrom(msg.sender, address(this), raffle.collateralParam); // transfer the token to the contract
    } else {
      require(msg.value == raffle.collateralParam, "Invalid deposit amount");
    }

    emit PriceStructureCreated(key, 1, 1, _params.ticketPrice);
    emit RaffleCreated(
      key,
      _params.collateralAddress,
      _params.collateralParam,
      _params.endTime,
      _params.ticketSupply,
      msg.sender,
      _params.raffleType,
      true
    );

    return key;
  }

  /// @dev callable by players. Depending on the number of entries assigned to the price structure the player buys (_id parameter)
  /// one or more entries will be assigned to the player.
  /// Also it is checked the maximum number of entries per user is not reached
  /// As the method is payable, in msg.value there will be the amount paid by the user
  /// @notice If the operator set requiredNFTs when creating the raffle, only the owners of nft on that collection can make a call to this method. This will be
  /// used for special raffles
  /// @param _raffleId: id of the raffle
  /// @param _idOrTicketCount: id of the price structure if raffle is admin raffle, else count of entry
  /// @param _collection: collection of the tokenId used. Not used if there is no required nft on the raffle
  /// @param _tokenIdUsed: id of the token used in private raffles (to avoid abuse can not be reused on the same raffle)
  function buyEntry(
    bytes32 _raffleId,
    uint256 _idOrTicketCount,
    address _collection,
    uint256 _tokenIdUsed
  ) external payable nonReentrant {
    // check end time
    require(raffles[_raffleId].endTime >= block.timestamp, "Raffle already finished");
    require(
      raffles[_raffleId].operatorCreated || _idOrTicketCount > 0,
      "Ticket count should bigger than 0"
    );

    // if the raffle requires an nft
    if (raffles[_raffleId].collectionWhitelist.length > 0) {
      bool hasRequiredCollection = false;
      for (uint256 i = 0; i < raffles[_raffleId].collectionWhitelist.length; i++) {
        if (raffles[_raffleId].collectionWhitelist[i] == _collection) {
          hasRequiredCollection = true;
          break;
        }
      }
      require(hasRequiredCollection == true, "Not in required collection");
      IERC721 requiredNFT = IERC721(_collection);
      require(requiredNFT.ownerOf(_tokenIdUsed) == msg.sender, "Not the owner of tokenId");
      bytes32 hashRequiredNFT = keccak256(abi.encode(_collection, _raffleId, _tokenIdUsed));
      // check the tokenId has not been using yet in the raffle, to avoid abuse
      if (requiredNFTWallets[hashRequiredNFT] == address(0)) {
        requiredNFTWallets[hashRequiredNFT] = msg.sender;
      } else require(requiredNFTWallets[hashRequiredNFT] == msg.sender, "tokenId used");
    }

    require(msg.sender != address(0), "msg.sender is null"); // 37
    require(
      raffles[_raffleId].status == STATUS.CREATED,
      "Raffle is not in created or already finished"
    ); // 1808

    uint256 ticketCount = 0;
    uint256 price = 0;
    if (raffles[_raffleId].operatorCreated) {
      PriceStructure memory priceStruct = _getPriceStructForId(_raffleId, _idOrTicketCount);
      require(priceStruct.numTickets > 0, "id not supported");

      ticketCount = priceStruct.numTickets;
      price = priceStruct.price;
    } else {
      ticketCount = _idOrTicketCount;
      price = raffles[_raffleId].ticketPrice * ticketCount;
    }

    bytes32 hash = keccak256(abi.encode(msg.sender, _raffleId));
    // check entry price
    require(msg.value == price, "msg.value must be equal to the price"); // 1722
    // check there are enough entries left for this particular user
    require(
      raffles[_raffleId].operatorCreated ||
        claimsData[hash].numTicketsPerUser + ticketCount <=
        fundingList[_raffleId].maxTicketCount / 5,
      "Bought too many entries()"
    );
    require(
      soldTicketCount[_raffleId] + ticketCount <= fundingList[_raffleId].maxTicketCount,
      "Max ticket amount exceed"
    );

    soldTicketCount[_raffleId] += ticketCount;
    entriesCount[_raffleId]++;
    // add a new element to the entriesBought array, used to calc the winner
    EntriesBought memory entryBought = EntriesBought({
      player: msg.sender,
      currentEntriesLength: entriesCount[_raffleId]
    });
    entries[_raffleId][entriesCount[_raffleId]] = entryBought;

    raffles[_raffleId].amountRaised += msg.value; // 6917 gas
    //update claim data
    claimsData[hash].numTicketsPerUser += ticketCount;
    claimsData[hash].amountSpentInWeis += msg.value;

    emit EntrySold(_raffleId, msg.sender, ticketCount, entriesCount[_raffleId], price); // 2377
  }

  // // The operator can add free entries to the raffle
  // /// @param _raffleId Id of the raffle
  // /// @param _freePlayers array of addresses corresponding to the wallet of the users that won a free entrie
  // /// @dev only operator can make this call. Assigns a single entry per user, except if that user already reached the max limit of entries per user
  // function giveBatchEntriesForFree(
  //   bytes32 _raffleId,
  //   address[] memory _freePlayers
  // ) external nonReentrant onlyRole(OPERATOR_ROLE) {
  //   require(
  //     raffles[_raffleId].status == STATUS.CREATED,
  //     "Raffle is not in created or already finished"
  //   );

  //   uint256 freePlayersLength = _freePlayers.length;
  //   for (uint256 i = 0; i < freePlayersLength; i++) {
  //     address entry = _freePlayers[i];
  //     if (
  //       claimsData[keccak256(abi.encode(entry, _raffleId))].numTicketsPerUser + 1 <=
  //       raffles[_raffleId].maxEntries
  //     ) {
  //       // add a new element to the entriesBought array.
  //       // as this method only adds 1 entry per call, the amountbought is always 1
  //       EntriesBought memory entryBought = EntriesBought({
  //         player: entry,
  //         currentEntriesLength: entriesCount[_raffleId]
  //       });
  //       entries[_raffleId][entriesCount[_raffleId]] = entryBought;
  //       entriesCount[_raffleId]++;

  //       claimsData[keccak256(abi.encode(entry, _raffleId))].numTicketsPerUser++;
  //     }
  //   }

  //   emit FreeEntry(_raffleId, _freePlayers, freePlayersLength, entriesCount[_raffleId] - 1);
  // }

  // helper method to get the winner address of a raffle
  /// @param _raffleId Id of the raffle
  /// @param _normalizedRandomNumber Generated by chainlink
  /// @return the wallet that won the raffle
  /// @dev Uses a binary search on the sorted array to retreive the winner
  function getWinnerAddressFromRandom(
    bytes32 _raffleId,
    uint256 _normalizedRandomNumber
  ) public view returns (address) {
    uint256 position = _findUpperBound(_raffleId, _normalizedRandomNumber);
    return entries[_raffleId][position].player;
  }

  /// @param _raffleId Id of the raffle
  /// @notice the operator finish the raffle, if the desired funds has been reached
  /// @dev it triggers Chainlink VRF1 consumer, and generates a random number that is normalized and checked that corresponds to a MW player
  function setWinner(bytes32 _raffleId) external nonReentrant {
    RaffleStruct storage raffle = raffles[_raffleId];
    FundingStructure memory funding = fundingList[_raffleId];
    // Check if the raffle is already accepted or is called again because early cashout failed
    require(block.timestamp > raffle.endTime, "Raffle is not finished yet");
    require(raffle.status == STATUS.CREATED, "Raffle is not in created or already finished");
    // require sold tickets should bigger than min tickets
    require(
      !raffle.operatorCreated || soldTicketCount[_raffleId] >= funding.minTicketCount,
      "Not enough funds raised"
    );

    raffle.status = STATUS.CLOSING_REQUESTED;

    // this call trigers the VRF v1 process from Chainlink
    _getRandomNumber(_raffleId, entriesCount[_raffleId]);

    emit SetWinnerTriggered(_raffleId, raffle.amountRaised);
  }

  /// @param _raffleId Id of the raffle
  /// @dev The operator can cancel the raffle. The NFT is sent back to the seller
  /// The raised funds are send to the destination wallet. The buyers will
  /// be refunded offchain in the metawin wallet
  function cancelRaffle(bytes32 _raffleId) external nonReentrant onlyRole(OPERATOR_ROLE) {
    RaffleStruct memory raffle = raffles[_raffleId];
    //FundingStructure memory funding = fundingList[_raffleId];
    // Dont cancel twice, or cancel an already ended raffle
    require(
      raffle.status != STATUS.ENDED &&
        raffle.status != STATUS.CANCELLED &&
        raffle.status != STATUS.EARLY_CASHOUT &&
        raffle.status != STATUS.CLOSING_REQUESTED &&
        raffle.status != STATUS.CANCEL_REQUESTED,
      "Wrong status"
    );
    require(raffle.seller == msg.sender, "You are not creator of this raffle");

    // only if the raffle is in accepted status the NFT is staked and could have entries sold
    if (raffle.status == STATUS.CREATED) {
      // transfer nft to the owner
      IERC721 _asset = IERC721(raffle.collateralAddress);
      _asset.transferFrom(address(this), raffle.seller, raffle.collateralParam);
    }
    raffle.status = STATUS.CANCEL_REQUESTED;
    raffle.cancellingDate = block.timestamp;

    raffles[_raffleId] = raffle;

    emit RaffleCancelled(_raffleId, raffle.amountRaised);
  }

  /// @param _raffleId Id of the raffle
  /// @dev The player can claim a refund during the first 30 days after the raffle was cancelled
  /// in the map "ClaimsData" it is saves how much the player spent on that raffle, as they could
  /// have bought several entries
  function claimRefund(bytes32 _raffleId) external nonReentrant {
    RaffleStruct storage raffle = raffles[_raffleId];
    require(raffle.status == STATUS.CANCEL_REQUESTED, "wrong status");
    require(block.timestamp <= raffle.cancellingDate + 30 days, "claim time expired");

    ClaimStruct storage claimData = claimsData[keccak256(abi.encode(msg.sender, _raffleId))];

    require(claimData.claimed == false, "already refunded");

    raffle.amountRaised = raffle.amountRaised - claimData.amountSpentInWeis;

    claimData.claimed = true;
    (bool sent, ) = msg.sender.call{value: claimData.amountSpentInWeis}("");
    require(sent, "Fail send refund");

    emit Refund(_raffleId, claimData.amountSpentInWeis, msg.sender);
  }

  /// @param _raffleId Id of the raffle
  /// @dev after 30 days after cancelling passes, the operator can transfer to
  /// vault the remaining funds
  function transferRemainingFunds(bytes32 _raffleId) external nonReentrant onlyRole(OPERATOR_ROLE) {
    RaffleStruct memory raffle = raffles[_raffleId];
    require(raffle.status == STATUS.CANCEL_REQUESTED, "Wrong status");
    require(block.timestamp > raffle.cancellingDate + 30 days, "claim too soon");

    raffle.status = STATUS.CANCELLED;

    (bool sent, ) = vault.call{value: raffle.amountRaised}("");
    require(sent, "Fail send Eth to MW");

    emit RemainingFundsTransferred(_raffleId, raffle.amountRaised);

    raffle.amountRaised = 0;

    raffles[_raffleId] = raffle;
  }

  /// @param _newAddress new address of the platform signer
  /// @dev Change the wallet of the platform signer
  function setSignerAddress(address payable _newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    signer = _newAddress;
  }

  /// @param _raffleId Id of the raffle
  /// @param _player wallet of the player
  /// @return Claims data of the player on that raffle
  function getClaimData(
    bytes32 _raffleId,
    address _player
  ) external view returns (ClaimStruct memory) {
    return claimsData[keccak256(abi.encode(_player, _raffleId))];
  }

  /// @param to address of new admin
  /// @dev updates owner of manager contract
  function transferOwnership(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(DEFAULT_ADMIN_ROLE, to);
  }

  /// internal functions

  /// @dev this is the method that will be called by the smart contract to get a random number
  /// @param _id Id of the raffle
  /// @param _entriesSize length of the entries array of that raffle
  /// @return requestId Id generated by chainlink
  function _getRandomNumber(
    bytes32 _id,
    uint256 _entriesSize
  ) internal returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
    bytes32 result = requestRandomness(keyHash, fee);
    // result is the requestId generated by chainlink. It is saved in a map linked to the param id
    chainlinkRaffleInfo[result] = RaffleInfo({id: _id, size: _entriesSize});
    return result;
  }

  /// @dev Callback function used by VRF Coordinator. Is called by chainlink
  /// the random number generated is normalized to the size of the entries array, and an event is
  /// generated, that will be listened by the platform backend to be checked if corresponds to a
  /// member of the MW community, and if true will call _transferNFTAndFunds
  /// @param requestId id generated previously (on method getRandomNumber by chainlink)
  /// @param randomness random number (huge) generated by chainlink
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    // randomness is the actual random number. Now extract from the aux map the original param id of the call
    RaffleInfo memory raffleInfo = chainlinkRaffleInfo[requestId];
    // save the random number on the map with the original id as key
    uint256 normalizedRandomNumber = (randomness % raffleInfo.size) + 1;

    RandomResult memory result = RandomResult({
      randomNumber: randomness,
      nomalizedRandomNumber: normalizedRandomNumber
    });

    requests[raffleInfo.id] = result;

    // send the event with the original id and the random number
    emit RandomNumberCreated(raffleInfo.id, randomness, normalizedRandomNumber);

    _transferNFTAndFunds(raffleInfo.id, normalizedRandomNumber);
  }

  //////////////////////////////////////////////

  // The operator can call this method once they receive the event "RandomNumberCreated"
  // triggered by the VRF v1 consumer contract (RandomNumber.sol)
  /// @param _raffleId Id of the raffle
  /// @param _normalizedRandomNumber index of the array that contains the winner of the raffle. Generated by chainlink
  /// @notice it is the method that sets the winner and transfers funds and nft
  /// @dev called only after the backekd checks the winner is a member of MW. Only those who bought using the MW site
  /// can be winners, not those who made the call to "buyEntries" directly without using MW
  function _transferNFTAndFunds(
    bytes32 _raffleId,
    uint256 _normalizedRandomNumber
  ) internal nonReentrant {
    RaffleStruct memory raffle = raffles[_raffleId];
    // Only when the raffle has been asked to be closed and the platform
    require(
      raffle.status == STATUS.EARLY_CASHOUT || raffle.status == STATUS.CLOSING_REQUESTED,
      "Raffle in wrong status"
    );

    raffle.randomNumber = _normalizedRandomNumber;
    raffle.winner = getWinnerAddressFromRandom(_raffleId, _normalizedRandomNumber);
    raffle.status = STATUS.ENDED;

    raffles[_raffleId] = raffle;

    if (raffle.raffleType == RAFFLETYPE.NFT) {
      IERC721 _asset = IERC721(raffle.collateralAddress);
      _asset.transferFrom(address(this), raffle.winner, raffle.collateralParam); // transfer the tokens to the contract
    } else if (raffle.raffleType == RAFFLETYPE.ERC20) {
      IERC20 _asset = IERC20(raffle.collateralAddress);
      _asset.safeTransfer(raffle.winner, raffle.collateralParam); // transfer the tokens to the contract
    } else {
      (bool sent, ) = raffle.winner.call{value: raffle.collateralParam}("");
      require(sent, "Failed to send Ether");
    }

    if (raffle.operatorCreated) {
      // send all funds to vault for admin raffle
      (bool sent2, ) = vault.call{value: raffle.amountRaised}("");
      require(sent2, "Failed send Eth to MW");
    } else {
      // 5% is platform fee
      uint256 amountForPlatform = (raffle.amountRaised * 5) / 100;
      uint256 amountForSeller = raffle.amountRaised - amountForPlatform;
      // transfer amount (75%) to the seller.
      (bool sent1, ) = raffle.seller.call{value: amountForSeller}("");
      require(sent1, "Failed to send Ether");
      // transfer the amount to the platform
      (bool sent2, ) = vault.call{value: amountForPlatform}("");
      require(sent2, "Failed send Eth to MW");
      emit FeeTransferredToPlatform(_raffleId, amountForPlatform);
    }

    emit RaffleEnded(_raffleId, raffle.winner, raffle.amountRaised, _normalizedRandomNumber);
  }

  /// @param id id of raffle
  /// @param element uint256 to find. Goes from 1 to entriesLength
  /// @dev based on openzeppelin code (v4.0), modified to use an array of EntriesBought
  /// Searches a sorted array and returns the first index that contains a value greater or equal to element.
  /// If no such index exists (i.e. all values in the array are strictly less than element), the array length is returned. Time complexity O(log n).
  /// array is expected to be sorted in ascending order, and to contain no repeated elements.
  /// https://docs.openzeppelin.com/contracts/3.x/api/utils#Arrays-findUpperBound-uint256---uint256-
  function _findUpperBound(bytes32 id, uint256 element) internal view returns (uint256) {
    if (entriesCount[id] == 0) {
      return 0;
    }

    uint256 low = 0;
    uint256 high = entriesCount[id];

    while (low < high) {
      uint256 mid = Math.average(low, high);

      // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
      // because Math.average rounds down (it does integer division with truncation).
      if (entries[id][mid].currentEntriesLength > element) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
    if (low > 0 && entries[id][low - 1].currentEntriesLength == element) {
      return low - 1;
    } else {
      return low;
    }
  }

  /// @param raffle raffle structure to get key
  /// @notice get raffle kay for mapping
  /// @dev use hash of structure as a key
  /// @return bytes32 return key
  function _getRaffleKey(RaffleStruct memory raffle) internal view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          raffle.raffleType,
          raffle.collateralAddress,
          raffle.collateralParam,
          block.number
        )
      );
  }

  /* * Example of a price structure:
    1 ticket 0.02
    5 tickets 0.018 (10% discount)
    10 tickets 0.16  (20% discount)
    25 tickets 0.35  (30% discount) 
    50 tickets 0.6 (40% discount)
    */
  /// @param _idRaffle raffleId
  /// @param _id Id of the price structure
  /// @return the price structure of that particular Id + raffle
  /// @dev Returns the price structure, used in the frontend
  function _getPriceStructForId(
    bytes32 _idRaffle,
    uint256 _id
  ) internal view returns (PriceStructure memory) {
    for (uint256 i = 0; i < 5; i++) {
      if (prices[_idRaffle][i].id == _id) {
        return prices[_idRaffle][i];
      }
    }
    return PriceStructure({id: 0, numTickets: 0, price: 0});
  }

  /// @param collection address of collection
  /// @param sig signature of signer
  /// @dev validate collection is whitelisted in backend
  function _validateCreateCollection(
    address collection,
    Sig calldata sig
  ) internal view returns (bool) {
    bytes32 messageHash = keccak256(abi.encodePacked(_msgSender(), collection));

    bytes32 ethSignedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    return signer == ecrecover(ethSignedMessageHash, sig.v, sig.r, sig.s);
  }
}