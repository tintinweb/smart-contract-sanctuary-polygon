// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./structs/VotingStructs.sol";

/**
 * @author Softbinator Technologies
 * @notice Contract for voting on ENF proposals
 */
contract ENFVoting is AccessControl {
    bytes32 public constant PROPOSAL_ROLE = keccak256("PROPOSAL_ROLE");
    bytes32 public constant VOTES_ROLE = keccak256("VOTES_ROLE");

    /// @dev mapping to store proposals by their id
    mapping(uint256 => Proposal) private _proposals;
    /// @dev mapping to store on a proposalId the amount of votes for each address
    mapping(uint256 => mapping(address => Voted)) private _voted;
    /// @dev mapping to store for each address their votes
    mapping(address => uint256) private _votes;
    /// @dev array with all voters address
    address[] private _voters;

    uint256 private _currentProposalId;

    /// @dev array to store all proposalIds
    uint256[] private _proposalIds;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PROPOSAL_ROLE, msg.sender);
        _grantRole(VOTES_ROLE, msg.sender);
    }

    function addVotesBatch(address[] calldata owners, uint256[] calldata amounts) external {
        if (owners.length != amounts.length) {
            revert InvalidParams();
        }
        uint256 i;
        for (; i < owners.length; ++i) {
            addVotes(owners[i], amounts[i]);
        }
    }

    function addVotes(address owner, uint256 amount) private onlyRole(VOTES_ROLE) {
        // can't give 0 votes to an owner
        if (amount == 0) {
            revert InvalidNoOfVotes();
        }

        // can't modify the no of votes
        if (_votes[owner] != 0) {
            revert VoterAlreadyAdded();
        }

        _votes[owner] = amount;
        _voters.push(owner);

        emit VotesAdded(owner, amount);
    }

    function removeVoter(address owner, uint256 ownerIndex) external onlyRole(VOTES_ROLE) {
        address[] memory votersLocal = _voters;
        if (votersLocal[ownerIndex] != owner) {
            revert InvalidOwnerRemoval();
        }

        _votes[owner] = 0;

        _voters[ownerIndex] = votersLocal[votersLocal.length - 1];
        _voters.pop();
        emit VoterRemoved(owner);
    }

    function updateVoter(address owner, uint256 newNoOfVotes) external onlyRole(VOTES_ROLE) {
        if (newNoOfVotes == 0) {
            revert InvalidAmountForUpdatingVoter();
        }

        uint256 oldNoOfVotes = _votes[owner];

        if (oldNoOfVotes == 0) {
            revert InvalidVoter();
        }

        _votes[owner] = newNoOfVotes;
        emit VoterUpdated(owner, oldNoOfVotes, newNoOfVotes);
    }

    /**
     * @notice Create a proposal
     * @param title represents the title of the proposal
     * @param description represents the description of the proposal
     * @param startBlockNumber at this block the proposal can be voted
     * @param endBlockNumber after this block the proposal can't be voted
     */
    function propose(
        string memory title,
        string memory description,
        uint64 startBlockNumber,
        uint64 endBlockNumber
    ) external onlyRole(PROPOSAL_ROLE) {
        /// @dev by nature startBlockNumber can't be 0
        if (startBlockNumber >= endBlockNumber || startBlockNumber < block.number) {
            revert InvalidParams();
        }

        /// @dev a proposal can't be created if the current proposal is active
        if (_proposals[_currentProposalId].status == ProposalStatus.active) {
            revert ProposalActive();
        }

        uint256 proposalId = calculateProposalId(title, description);

        /// @dev if start block is 0 than the proposal was not created
        if (_proposals[proposalId].startBlockNumber != 0) {
            revert ProposalAlreadyCreated();
        }

        _proposals[proposalId] = Proposal({
            title: title,
            description: description,
            startBlockNumber: startBlockNumber,
            endBlockNumber: endBlockNumber,
            forVotes: 0,
            againstVotes: 0,
            status: ProposalStatus.active
        });

        _currentProposalId = proposalId;

        _proposalIds.push(proposalId);
        emit ProposalCreated(proposalId);
    }

    function castVote(VoteType option) external {
        Proposal memory currentProposalLocal = _proposals[_currentProposalId];

        /// @dev can't vote if Proposal is canceled, over or it didn't start
        if (
            currentProposalLocal.status != ProposalStatus.active || currentProposalLocal.endBlockNumber < block.number
        ) {
            revert ProposalOver();
        }

        /// @dev can't vote if the proposal didn't start
        if (currentProposalLocal.startBlockNumber > block.number) {
            revert ProposalNotStarted();
        }

        Voted memory votedStatus = _voted[_currentProposalId][msg.sender];

        /// @dev can't vote if already voted
        if (votedStatus.noOfVotes != 0) {
            revert AlreadyVoted();
        }

        uint256 noOfVotes = _votes[msg.sender];

        if (noOfVotes == 0) {
            revert InvalidNoOfVotes();
        }

        votedStatus.noOfVotes = noOfVotes;
        votedStatus.option = option;

        _voted[_currentProposalId][msg.sender] = votedStatus;

        /// @dev add votes for the choosen option
        if (option == VoteType.For) {
            currentProposalLocal.forVotes += noOfVotes;
        } else if (option == VoteType.Against) {
            currentProposalLocal.againstVotes += noOfVotes;
        } else {
            revert InvalidVoteType();
        }

        _proposals[_currentProposalId] = currentProposalLocal;
        emit VoteCasted(msg.sender, noOfVotes, option);
    }

    /**
     * @notice Cancel current proposal.
     * @notice It can be canceled only if the Proposal didn't start
     */
    function cancelProposal() external onlyRole(PROPOSAL_ROLE) {
        uint256 proposalId = _currentProposalId;
        if (block.number < _proposals[proposalId].startBlockNumber) {
            _proposals[proposalId].status = ProposalStatus.canceled;
        } else {
            revert CannotCancelProposalAfterStarting();
        }

        emit ProposalCanceled(msg.sender, proposalId, block.number);
    }

    /**
     * @notice Finish current proposal.
     * @notice It can be finished only if the proposal was active and the current block is past end block of the proposal
     * @notice It can be finished by anyone
     */
    function finishProposal() external {
        uint256 proposalId = _currentProposalId;
        Proposal memory proposal = _proposals[proposalId];

        if (block.number > proposal.endBlockNumber && proposal.status == ProposalStatus.active) {
            _proposals[proposalId].status = ProposalStatus.finished;
        } else {
            revert ProposalCannotBeFinished();
        }

        emit ProposalFinished(msg.sender, proposalId, block.number);
    }

    function proposals(uint256 proposalId) external view returns (Proposal memory) {
        return _proposals[proposalId];
    }

    function currentProposal() external view returns (Proposal memory) {
        return _proposals[_currentProposalId];
    }

    function currentProposalId() external view returns (uint256) {
        return _currentProposalId;
    }

    function votes(address owner) external view returns (uint256) {
        return _votes[owner];
    }

    function voted(uint256 proposalId, address owner) external view returns (Voted memory) {
        return _voted[proposalId][owner];
    }

    function calculateProposalId(string memory title, string memory description)
        public
        pure
        returns (uint256 proposalId)
    {
        proposalId = uint256(keccak256(abi.encode(title, description)));
    }

    function proposalIds() external view returns (uint256[] memory) {
        return _proposalIds;
    }

    function voters(uint256 startIndex, uint256 count) external view returns (address[] memory) {
        if (_voters.length == 0) {
            return new address[](0);
        }
        uint256 index;
        uint256 i = startIndex;
        uint256 length = startIndex + count <= _voters.length ? startIndex + count : _voters.length;
        if (length < startIndex) {
            revert StartIndexGreaterThanLength();
        }
        address[] memory votersLocal = new address[](length - startIndex);
        for (; i < length; ++i) {
            votersLocal[index++] = _voters[i];
        }
        return votersLocal;
    }

    error AlreadyVoted();
    error InvalidVoteType();
    error ProposalActive();
    error ProposalOver();
    error ProposalNotStarted();
    error InvalidParams();
    error CannotCancelProposalAfterStarting();
    error ProposalAlreadyCreated();
    error ProposalCannotBeFinished();
    error InvalidNoOfVotes();
    error VoterAlreadyAdded();
    error InvalidOwnerRemoval();
    error InvalidAmountForUpdatingVoter();
    error InvalidVoter();
    error StartIndexGreaterThanLength();

    event ProposalCreated(uint256 id);
    event VoteCasted(address indexed owner, uint256 votes, VoteType options);
    event VotesAdded(address indexed owner, uint256 amount);
    event ProposalCanceled(address indexed account, uint256 proposalId, uint256 blockNumber);
    event ProposalFinished(address indexed account, uint256 proposalId, uint256 blockNumber);
    event VoterRemoved(address indexed account);
    event VoterUpdated(address indexed account, uint256 oldNoOfVotes, uint256 newNoOfVotes);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

enum VoteType {
    Against,
    For
}

enum ProposalStatus {
    canceled,
    finished,
    active
}

struct Proposal {
    string title;
    string description;
    uint64 startBlockNumber;
    uint64 endBlockNumber;
    ProposalStatus status;
    uint256 forVotes;
    uint256 againstVotes;
}

struct Voted {
    uint256 noOfVotes;
    VoteType option;
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