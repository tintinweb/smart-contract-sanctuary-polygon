// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../extensions/Roles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Vesting is Roles {
    event AddNewPhase(
        uint256 indexPhase,
        string phaseName,
        uint256 toTime,
        uint256 amountToken
    );

    event EditPhase(
        uint256 indexPhase,
        string phaseName,
        uint256 toTime,
        uint256 amountToken
    );

    event DeletePhase(uint256 phaseId);

    event NewMerkleTree(uint256 phaseId, bytes32 merkleRoot);

    event UserClaimRewardSuccess(uint256 phaseId, address user, uint256 amount);

    struct PhaseVesting {
        bool isActive;
        string phaseName;
        uint256 toTime;
        uint256 amountToken;
    }

    PhaseVesting[] public phaseStorage;
    mapping(uint256 => mapping(address => bool)) public hasClaimed; // phaseId -> user address -> isClaimed

    // bytes32[] public merkleRoot;
    mapping(uint256 => bytes32) public merkleRoot;

    uint256 public totalReward;
    uint256 public remainingReward;
    address public rewardToken;

    uint constant ONE = 10 ** 18;

    constructor(address[] memory _admins) Roles(_admins) {}

    function initRewardToken(
        address _rewardToken
    ) public onlyRole(GUARDIAN_ROLE) {
        require(rewardToken == address(0), "Already set");
        rewardToken = _rewardToken;
    }

    function getPhaseLength() public view returns (uint256) {
        return phaseStorage.length;
    }

    function getAllPhase() public view returns (PhaseVesting[] memory) {
        return phaseStorage;
    }

    function getPreviousTime(
        uint256 _phaseId
    ) public view returns (bool, uint256) {
        if (_phaseId == 0) return (false, 0);
        for (uint256 i = _phaseId - 1; i >= 0; i--) {
            if (phaseStorage[i].isActive) {
                return (true, phaseStorage[i].toTime);
            }
            if(i == 0) break;
        }
        return (false, 0);
    }

    function getLaterTime(
        uint256 _phaseId
    ) public view returns (bool, uint256) {
        for (uint256 i = _phaseId + 1; i < phaseStorage.length; i++) {
            if (phaseStorage[i].isActive) {
                return (true, phaseStorage[i].toTime);
            }
        }
        return (false, 0);
    }

    function addNewPhase(
        string memory phaseName,
        uint256 toTime,
        uint256 amountToken
    ) public onlyRole(GUARDIAN_ROLE) {
        // init data
        if (phaseStorage.length == 0) {
            totalReward = IERC20(rewardToken).balanceOf(address(this));
            remainingReward = IERC20(rewardToken).balanceOf(address(this));
        }

        require(amountToken > 0, "reward amount not correct");

        require(
            remainingReward >= amountToken,
            "Do not have enough token to release"
        );
        require(toTime > block.timestamp, "start time not correct");

        (bool hasPre, uint256 toTimePrevious) = getPreviousTime(
            phaseStorage.length
        );
        if (hasPre) {
            require(
                toTime > toTimePrevious,
                "Phase distributed time not correct"
            );
        }

        emit AddNewPhase(phaseStorage.length, phaseName, toTime, amountToken);

        phaseStorage.push(
            PhaseVesting({
                isActive: true,
                phaseName: phaseName,
                toTime: toTime,
                amountToken: amountToken
            })
        );

        remainingReward -= amountToken;
    }

    function deletePhase(uint256 _phaseId) public onlyRole(GUARDIAN_ROLE) {
        require(_phaseId < phaseStorage.length, "phase not correct");

        PhaseVesting storage currentPhase = phaseStorage[_phaseId];

        require(currentPhase.isActive, "phase not active");

        require(
            currentPhase.toTime > block.timestamp,
            "Can not modifier used phase"
        );

        remainingReward += currentPhase.amountToken;

        currentPhase.isActive = false;

        emit DeletePhase(_phaseId);
    }

    function editPhase(
        uint256 _phaseId,
        string memory _name,
        uint256 _toTime,
        uint256 _amountToken
    ) public onlyRole(GUARDIAN_ROLE) {
        require(_phaseId < phaseStorage.length, "phase not correct");

        require(_amountToken > 0, "reward amount not correct");

        require(_toTime > block.timestamp, "start time not correct");

        PhaseVesting storage currentPhase = phaseStorage[_phaseId];

        require(
            currentPhase.toTime > block.timestamp,
            "Can not modifier used phase"
        );

        (bool hasPre, uint256 toTimePrevious) = getPreviousTime(
            _phaseId
        );
        if (hasPre) {
            require(_toTime > toTimePrevious, "Distributed time not correct");
        }

        (bool hasLater, uint256 toTimeLater) = getLaterTime(
            _phaseId
        );

        if (hasLater) {
            require(_toTime < toTimeLater, "Distributed time not correct");
        }

        require(
            remainingReward + currentPhase.amountToken > _amountToken,
            "Do not have enough token"
        );

        emit EditPhase(_phaseId, _name, _toTime, _amountToken);
        remainingReward += currentPhase.amountToken;
        remainingReward -= _amountToken;

        currentPhase.phaseName = _name;
        currentPhase.toTime = _toTime;
        currentPhase.amountToken = _amountToken;
    }

    function pushMerkleTree(
        uint256 phaseId,
        bytes32 _root
    ) public onlyRole(GUARDIAN_ROLE) {
        require(merkleRoot[phaseId] == bytes32(0), "already set");
        require(phaseStorage[phaseId].isActive, "phase not active");

        require(block.timestamp > phaseStorage[phaseId].toTime, "Not end yet");
        emit NewMerkleTree(phaseId, _root);
        merkleRoot[phaseId] = _root;
    }

    function claimReward(
        uint256 phaseId,
        uint256 percentage,
        bytes32[] calldata merkleProof
    ) public {
        require(!hasClaimed[phaseId][msg.sender], "Rewards: Already claimed");

        (bool claimStatus, ) = _canClaim(
            phaseId,
            msg.sender,
            percentage,
            merkleProof
        );

        require(claimStatus, "Rewards: Invalid proof");

        // Set mapping for user and round as true
        hasClaimed[phaseId][msg.sender] = true;

        // amount will receive is totalReward * percentage / 10 ** 18
        uint256 amountRewardForUser = (phaseStorage[phaseId].amountToken *
            percentage) / 10 ** 18;

        // transfer for user
        IERC20(rewardToken).transfer(msg.sender, amountRewardForUser);

        //emit event
        emit UserClaimRewardSuccess(phaseId, msg.sender, amountRewardForUser);
    }

    /**
     * @notice Check whether it is possible to claim and how much based on previous distribution
     * @param user address of the user
     * @param percentage percentage to claim
     * @param merkleProof array with the merkle proof
     */
    function canClaim(
        uint256 _phaseId,
        address user,
        uint256 percentage,
        bytes32[] calldata merkleProof
    ) external view returns (bool, uint256) {
        return _canClaim(_phaseId, user, percentage, merkleProof);
    }

    /**
     * @notice Check whether it is possible to claim and how much based on previous distribution
     * @param user address of the user
     * @param percentage amount to claim
     * @param merkleProof array with the merkle proof
     */
    function _canClaim(
        uint256 _phaseId,
        address user,
        uint256 percentage,
        bytes32[] calldata merkleProof
    ) internal view returns (bool, uint256) {
        // Compute the node and verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(user, percentage));
        bool canUserClaim = MerkleProof.verify(
            merkleProof,
            merkleRoot[_phaseId],
            node
        );

        if ((!canUserClaim) || (hasClaimed[_phaseId][user])) {
            return (false, 0);
        } else {
            return (true, percentage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Roles is AccessControl {
    // keccak256("BIG_GUARDIAN_ROLE")
    bytes32 public constant BIG_GUARDIAN_ROLE =
        0x05c653944982f4fec5b037dad255d4ecd85c5b85ea2ec7654def404ae5f686ec;
    // keccak256("GUARDIAN_ROLE")
    bytes32 public constant GUARDIAN_ROLE =
        0x55435dd261a4b9b3364963f7738a7a662ad9c84396d64be3365284bb7f0a5041;
    // keccak256("WHITELIST_ROLE")
    bytes32 public constant WHITELIST_ROLE =
        0xdc72ed553f2544c34465af23b847953efeb813428162d767f9ba5f4013be6760;

    constructor(address[] memory _admins) {
        for (uint i = 0; i < _admins.length; i++) {
            _setupRole(GUARDIAN_ROLE, _admins[i]);
            _setupRole(WHITELIST_ROLE, _admins[i]);
        }

        _setRoleAdmin(GUARDIAN_ROLE, BIG_GUARDIAN_ROLE);
        _setRoleAdmin(WHITELIST_ROLE, GUARDIAN_ROLE);
        _setRoleAdmin(BIG_GUARDIAN_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(BIG_GUARDIAN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    }

    function grantGuardian(
        address _guardian
    ) public onlyRole(getRoleAdmin(GUARDIAN_ROLE)) {
        require(_guardian != address(0), "Guardian address is invalid!");
        grantRole(GUARDIAN_ROLE, _guardian);
    }

    function grantWhitelist(
        address _whitelist
    ) external onlyRole(GUARDIAN_ROLE) {
        require(_whitelist != address(0), "Whitelist address is invalid!");
        grantRole(WHITELIST_ROLE, _whitelist);
    }

    function isGuardian(address _guardian) public view returns (bool) {
        return hasRole(GUARDIAN_ROLE, _guardian);
    }

    function isBigGuardian(address _guardian) public view returns (bool) {
        return hasRole(BIG_GUARDIAN_ROLE, _guardian);
    }

    function isWhitelist(address _whitelist) public view returns (bool) {
        return hasRole(WHITELIST_ROLE, _whitelist);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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