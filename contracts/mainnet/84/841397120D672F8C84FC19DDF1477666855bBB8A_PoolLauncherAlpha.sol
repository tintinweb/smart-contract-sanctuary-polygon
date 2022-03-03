/**
 *Submitted for verification at polygonscan.com on 2022-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

contract WunderVaultAlpha {
  address[] public ownedTokenAddresses;

  event TokenAdded(address indexed tokenAddress, uint balance);
  event MaticWithdrawed(address indexed receiver, uint amount);
  event TokensWithdrawed(address indexed tokenAddress, address indexed receiver, uint amount);

  function addToken(address _tokenAddress) public {
    (, bytes memory nameData) = _tokenAddress.call(abi.encodeWithSignature("name()"));
    (, bytes memory symbolData) = _tokenAddress.call(abi.encodeWithSignature("symbol()"));
    (, bytes memory balanceData) = _tokenAddress.call(abi.encodeWithSignature("balanceOf(address)", address(this)));

    require(nameData.length > 0, "Not a valid ERC20 Token: Token has no name() function");
    require(symbolData.length > 0, "Not a valid ERC20 Token: Token has no symbol() function");
    require(balanceData.length > 0, "Not a valid ERC20 Token: Token has no balanceOf() function");

    require(toUint256(balanceData) > 0, "Token will not be added: Token not owned by contract");
    ownedTokenAddresses.push(_tokenAddress);

    emit TokenAdded(_tokenAddress, toUint256(balanceData));
  }

  function toUint256(bytes memory _bytes) internal pure returns (uint256 value) {
    assembly {
      value := mload(add(_bytes, 0x20))
    }
  }

  function getOwnedTokenAddresses() public view returns(address[] memory) {
    return ownedTokenAddresses;
  }

  function _distributeAllTokensEvenly(address[] memory _receivers) internal {
    for (uint256 index = 0; index < ownedTokenAddresses.length; index++) {
      _distributeTokensEvenly(ownedTokenAddresses[index], _receivers);
    }
  }

  function _distributeTokensEvenly(address _tokenAddress, address[] memory _receivers) internal {
    (, bytes memory balanceBytes) = _tokenAddress.call(abi.encodeWithSignature("balanceOf(address)", address(this)));
    uint balance = toUint256(balanceBytes);

    for (uint256 index = 0; index < _receivers.length; index++) {
      _withdrawTokens(_tokenAddress, _receivers[index], balance / _receivers.length);
    }
  }

  function _distributeMaticEvenly(address[] memory _receivers) internal {
    uint balance = address(this).balance;

    for (uint256 index = 0; index < _receivers.length; index++) {
      _withdrawMatic(_receivers[index], balance / _receivers.length);
    }
  }

  function _withdrawTokens(address _tokenAddress, address _receiver, uint _amount) internal {
    (, bytes memory balance) = _tokenAddress.call(abi.encodeWithSignature("balanceOf(address)", address(this)));
    require(toUint256(balance) >= _amount, "Withdraw Amount exceeds balance of Vault");

    (bool success,) = _tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", _receiver, _amount));
    require(success, "Withdraw Failed");
    emit TokensWithdrawed(_tokenAddress, _receiver, _amount);
  }

  function _withdrawMatic(address _receiver, uint _amount) internal {
    require(address(this).balance >= _amount, "Withdraw Amount exceeds balance of Vault");
    payable(_receiver).transfer(_amount);
    emit MaticWithdrawed(_receiver, _amount);
  }
}

contract WunderPoolAlpha is AccessControl, WunderVaultAlpha {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");

  struct Proposal {
    string title;
    string description;
    address[] contractAddresses;
    string[] actions;
    bytes[] params;
    uint[] transactionValues;
    uint deadline;
    uint yesVotes;
    uint noVotes;
    uint abstainVotes;
    uint createdAt;
    bool executed;
    mapping(address => bool) hasVoted;
  }

  enum VoteType {
    For,
    Against,
    Abstain
  }

  mapping (uint => Proposal) public proposals;
  uint[] public proposalIds;
  uint[] public openProposalIds;

  address[] public members;
  string public poolName;

  event NewProposal(uint indexed id, address indexed creator, string title);
  event Voted(uint indexed proposalId, address indexed voter, uint mode);
  event ProposalExecuted(uint indexed proposalId, address indexed executor, bytes[] result);

  constructor (string memory _poolName, address _creator) {
    poolName = _poolName;
    _grantRole(ADMIN_ROLE, _creator);
    _grantRole(MEMBER_ROLE, _creator);
    members.push(_creator);
  }

  receive() external payable {}

  function createProposal(string memory _title, string memory _description, address _contractAddress, string memory _action, bytes memory _param, uint _transactionValue, uint _deadline) public onlyRole(MEMBER_ROLE) {
    require(bytes(_title).length > 0, "Invalid Proposal: Missing Parameter Title");
    require(_contractAddress != address(0), "Invalid Proposal: Missing Parameter Contract Address");
    require(bytes(_action).length > 0, "Invalid Proposal: Missing Parameter Action");
    require(_deadline > 0, "Invalid Proposal: Missing Parameter Deadline");
    require(_deadline > block.timestamp, "Invalid Proposal: Deadline needs to be in the Future");

    address[] memory _contractAddresses = new address[](1);
    _contractAddresses[0] = _contractAddress;
    string[] memory _actions = new string[](1);
    _actions[0] = _action;
    bytes[] memory _params = new bytes[](1);
    _params[0] = _param;
    uint[] memory _transactionValues = new uint[](1);
    _transactionValues[0] = _transactionValue;

    _createProposal(_title, _description, _contractAddresses, _actions, _params, _transactionValues, _deadline);
  }

  function createMultiActionProposal(string memory _title, string memory _description, address[] memory _contractAddresses, string[] memory _actions, bytes[] memory _params, uint[] memory _transactionValues, uint _deadline) public onlyRole(MEMBER_ROLE) {
    _createProposal(_title, _description, _contractAddresses, _actions, _params, _transactionValues, _deadline);
  }

  function _createProposal(string memory _title, string memory _description, address[] memory _contractAddresses, string[] memory _actions, bytes[] memory _params, uint[] memory _transactionValues, uint _deadline) internal {
    require(_contractAddresses.length == _actions.length && _actions.length == _params.length && _params.length == _transactionValues.length, "Invalid Proposal: Inconsistens amount of transactions");
    require(bytes(_title).length > 0, "Invalid Proposal: Missing Parameter Title");
    require(_deadline > 0, "Invalid Proposal: Missing Parameter Deadline");
    require(_deadline > block.timestamp, "Invalid Proposal: Deadline needs to be in the Future");

    for (uint256 index = 0; index < _contractAddresses.length; index++) {
      require(_contractAddresses[index] != address(0), "Invalid Proposal: Missing Parameter Contract Address");
      require(bytes(_actions[index]).length > 0, "Invalid Proposal: Missing Parameter Action");
    }

    uint nextProposalId = proposalIds.length;
    proposalIds.push(nextProposalId);
    openProposalIds.push(nextProposalId);

    Proposal storage newProposal = proposals[nextProposalId];
    newProposal.title = _title;
    newProposal.description = _description;
    newProposal.actions = _actions;
    newProposal.params = _params;
    newProposal.transactionValues = _transactionValues;
    newProposal.contractAddresses = _contractAddresses;
    newProposal.deadline = _deadline;
    newProposal.createdAt = block.timestamp;
    newProposal.executed = false;

    emit NewProposal(nextProposalId, msg.sender, _title);
  }

  function hasVoted(uint256 proposalId, address account) public view returns (bool) {
    return proposals[proposalId].hasVoted[account];
  }

  function vote(uint proposalId, uint mode) public onlyRole(MEMBER_ROLE) {
    Proposal storage proposal = proposals[proposalId];
    require(proposal.actions.length > 0, "Voting not permitted: Proposal does not exist");
    require(block.timestamp <= proposal.deadline, "Voting not permitted: Voting period has ended");
    require(!hasVoted(proposalId, msg.sender), "Voting not permitted: Voter has already voted");
    proposal.hasVoted[msg.sender] = true;

    if (mode == uint8(VoteType.Against)) {
      proposal.noVotes += 1;
    } else if (mode == uint8(VoteType.For)) {
      proposal.yesVotes += 1;
    } else if (mode == uint8(VoteType.Abstain)) {
      proposal.abstainVotes += 1;
    } else {
      revert("Voting not permitted: Invalid value for VoteType (0 = YES, 1 = NO, 2 = ABSTAIN)");
    }

    emit Voted(proposalId, msg.sender, mode);
  }

  function executeProposal(uint _proposalId) public payable {
    Proposal storage proposal = proposals[_proposalId];
    require(proposal.actions.length > 0, "Execution not permitted: Proposal does not exist");
    require(!proposal.executed, "Execution not permitted: Proposal already executed");

    uint transactionTotal = 0;
    for (uint256 index = 0; index < proposal.transactionValues.length; index++) {
      transactionTotal += proposal.transactionValues[index];
    }

    require(transactionTotal <= address(this).balance, "Execution not permitted: Pool does not have enough funds");
    require((proposal.noVotes * 2) <= members.length, "Execution not permitted: Majority voted against execution");
    require((proposal.yesVotes * 2) >= members.length || proposal.deadline <= block.timestamp, "Execution not permitted: Voting is still allowed");

    proposal.executed = true;
    for (uint256 index = 0; index < openProposalIds.length; index++) {
      if (openProposalIds[index] == _proposalId) {
        openProposalIds[index] = openProposalIds[openProposalIds.length - 1];
        delete openProposalIds[openProposalIds.length - 1];
        openProposalIds.pop();
      }
    }

    bytes[] memory results = new bytes[](proposal.contractAddresses.length);

    for (uint256 index = 0; index < proposal.contractAddresses.length; index++) {
      address contractAddress = proposal.contractAddresses[index];
      bytes memory callData = bytes.concat(abi.encodeWithSignature(proposal.actions[index]), proposal.params[index]);

      bool success = false;
      bytes memory result;
      if (proposal.transactionValues[index] > 0) {
        (success, result) = contractAddress.call{value: proposal.transactionValues[index]}(callData);
      } else {
        (success, result) = contractAddress.call(callData);
      }
      require(success, "Execution failed");
      results[index] = result;
    }

    emit ProposalExecuted(_proposalId, msg.sender, results);
  }

  function addMember(address _newMember) external onlyRole(ADMIN_ROLE) {
    members.push(_newMember);
    _grantRole(MEMBER_ROLE, _newMember);
  }

  function removeMember(address _member) external onlyRole(ADMIN_ROLE) {
    for (uint256 index = 0; index < members.length; index++) {
      if (members[index] == _member) {
        members[index] = members[members.length - 1];
        delete members[members.length - 1];
        members.pop();
      }
    }
    _revokeRole(MEMBER_ROLE, _member);
  }

  function poolMembers() public view returns(address[] memory) {
    return members;
  }

  function addAdmin(address _newAdmin) external onlyRole(ADMIN_ROLE) {
    _grantRole(ADMIN_ROLE, _newAdmin);
  }

  function removeAdmin(address _admin) external onlyRole(ADMIN_ROLE) {
    _revokeRole(ADMIN_ROLE, _admin);
  }

  function getAllProposalIds() public view returns(uint[] memory) {
    return proposalIds;
  }

  function getAllOpenProposalIds() public view returns(uint[] memory) {
    return openProposalIds;
  }

  function getProposal(uint _proposalId) public view returns(string memory title, string memory description, uint transactionCount, uint deadline, uint yesVotes, uint noVotes, uint abstainVotes, uint createdAt, bool executed) {
    Proposal storage proposal = proposals[_proposalId];
    return (proposal.title, proposal.description, proposal.actions.length, proposal.deadline, proposal.yesVotes, proposal.noVotes, proposal.abstainVotes, proposal.createdAt, proposal.executed);
  }

  function getProposalTransaction(uint _proposalId, uint _transactionIndex) public view returns(string memory action, bytes memory param, uint transactionValue, address contractAddress) {
    Proposal storage proposal = proposals[_proposalId];
    return (proposal.actions[_transactionIndex], proposal.params[_transactionIndex], proposal.transactionValues[_transactionIndex], proposal.contractAddresses[_transactionIndex]);
  }

  function liquidatePool() external onlyRole(ADMIN_ROLE) {
    _distributeAllTokensEvenly(members);
    _distributeMaticEvenly(members);
    selfdestruct(payable(msg.sender));
  }
}

contract PoolLauncherAlpha {
  address[] public launchedPools;

  mapping (address => address[]) public creatorToPools;

  event PoolLaunched(address indexed creator, address indexed poolAddress, string name);

  function createNewPool(string memory _poolName) public {
    WunderPoolAlpha newPool = new WunderPoolAlpha(_poolName, msg.sender);
    launchedPools.push(address(newPool));
    creatorToPools[msg.sender].push(address(newPool));
    emit PoolLaunched(msg.sender, address(newPool), _poolName);
  }

  function poolsOfCreator(address _creator) public view returns(address[] memory) {
    return creatorToPools[_creator];
  }

  function allPools() public view returns(address[] memory) {
    return launchedPools;
  }
}