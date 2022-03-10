// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./WunderVaultBeta.sol";

interface IPoolLauncherBeta {
  function addPoolToMembersPools(address _pool, address _member) external;
  function removePoolFromMembersPools(address _pool, address _member) external;
}

contract WunderPoolBeta is AccessControl, WunderVaultBeta {
  bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");

  struct Proposal {
    string title;
    string description;
    address[] contractAddresses;
    string[] actions;
    bytes[] params;
    uint[] transactionValues;
    uint deadline;
    address[] yesVoters;
    address[] noVoters;
    uint createdAt;
    bool executed;
    mapping(address => VoteType) hasVoted;
  }

  enum VoteType {
    None,
    For,
    Against
  }

  mapping (uint => Proposal) public proposals;
  uint[] public proposalIds;
  uint[] public openProposalIds;

  address[] public members;
  string public name;
  address public launcherAddress;
  uint public entryBarrier;

  event NewProposal(uint indexed id, address indexed creator, string title);
  event Voted(uint indexed proposalId, address indexed voter, uint mode);
  event ProposalExecuted(uint indexed proposalId, address indexed executor, bytes[] result);

  constructor (string memory _name, address _creator, address _launcher, address _governanceToken, uint _entryBarrier) payable WunderVaultBeta(_governanceToken) {
    name = _name;
    launcherAddress = _launcher;
    entryBarrier = _entryBarrier;
    members.push(_creator);
    _grantRole(MEMBER_ROLE, _creator);
  }

  receive() external payable {
    _issueGovernanceTokens(msg.sender, msg.value);
  }

  function createProposal(string memory _title, string memory _description, address _contractAddress, string memory _action, bytes memory _param, uint _transactionValue, uint _deadline) public onlyRole(MEMBER_ROLE) {
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

  function hasVoted(uint256 proposalId, address account) public view returns (VoteType) {
    return proposals[proposalId].hasVoted[account];
  }

  function vote(uint proposalId, uint mode) public onlyRole(MEMBER_ROLE) {
    Proposal storage proposal = proposals[proposalId];
    require(proposal.actions.length > 0, "Voting not permitted: Proposal does not exist");
    require(block.timestamp <= proposal.deadline, "Voting not permitted: Voting period has ended");
    require(hasVoted(proposalId, msg.sender) == VoteType.None, "Voting not permitted: Voter has already voted");

    if (mode == uint8(VoteType.Against)) {
      proposal.hasVoted[msg.sender] = VoteType.Against;
      proposal.noVoters.push(msg.sender);
    } else if (mode == uint8(VoteType.For)) {
      proposal.hasVoted[msg.sender] = VoteType.For;
      proposal.yesVoters.push(msg.sender);
    } else {
      revert("Voting not permitted: Invalid value for VoteType (1 = YES, 2 = NO)");
    }

    emit Voted(proposalId, msg.sender, mode);
  }

  function calculateVotes(uint _proposalId) public view returns(uint yesVotes, uint noVotes) {
    Proposal storage proposal = proposals[_proposalId];
    uint yes;
    uint no;
    for (uint256 i = 0; i < proposal.noVoters.length; i++) {
      no += governanceTokensOf(proposal.noVoters[i]);
    }
    for (uint256 i = 0; i < proposal.yesVoters.length; i++) {
      yes += governanceTokensOf(proposal.yesVoters[i]);
    }
    return(yes, no);
  }

  function executeProposal(uint _proposalId) public {
    Proposal storage proposal = proposals[_proposalId];
    require(proposal.actions.length > 0, "Execution not permitted: Proposal does not exist");
    require(!proposal.executed, "Execution not permitted: Proposal already executed");
    (uint yesVotes, uint noVotes) = calculateVotes(_proposalId);
    require((noVotes * 2) <= totalGovernanceTokens(), "Execution not permitted: Majority voted against execution");
    require((yesVotes * 2) > totalGovernanceTokens() || proposal.deadline <= block.timestamp, "Execution not permitted: Voting is still allowed");

    uint transactionTotal = 0;
    for (uint256 index = 0; index < proposal.transactionValues.length; index++) {
      transactionTotal += proposal.transactionValues[index];
    }

    require(transactionTotal <= address(this).balance, "Execution not permitted: Pool does not have enough funds");
    
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

  function enterPool() public payable {
    require(msg.value >= entryBarrier && msg.value >= governanceTokenPrice(), "Your stake is not high enough");
    addMember(msg.sender);
    _issueGovernanceTokens(msg.sender, msg.value);
  }

  function addMember(address _newMember) internal {
    require(!isMember(_newMember), "Is already a Member");
    members.push(_newMember);
    _grantRole(MEMBER_ROLE, _newMember);
    IPoolLauncherBeta(launcherAddress).addPoolToMembersPools(address(this), _newMember);
  }

  function isMember(address _member) public view returns (bool) {
    return hasRole(MEMBER_ROLE, _member);
  }

  function poolMembers() public view returns(address[] memory) {
    return members;
  }

  function getAllProposalIds() public view returns(uint[] memory) {
    return proposalIds;
  }

  function getAllOpenProposalIds() public view returns(uint[] memory) {
    return openProposalIds;
  }

  function getProposal(uint _proposalId) public view returns(string memory title, string memory description, uint transactionCount, uint deadline, uint yesVotes, uint noVotes, uint totalVotes, uint createdAt, bool executed) {
    Proposal storage proposal = proposals[_proposalId];
    (uint yes, uint no) = calculateVotes(_proposalId);
    return (proposal.title, proposal.description, proposal.actions.length, proposal.deadline, yes, no, totalGovernanceTokens(), proposal.createdAt, proposal.executed);
  }

  function getProposalTransaction(uint _proposalId, uint _transactionIndex) public view returns(string memory action, bytes memory param, uint transactionValue, address contractAddress) {
    Proposal storage proposal = proposals[_proposalId];
    return (proposal.actions[_transactionIndex], proposal.params[_transactionIndex], proposal.transactionValues[_transactionIndex], proposal.contractAddresses[_transactionIndex]);
  }
  
  function liquidatePool() public onlyPool {
    _distributeFullBalanceOfAllTokensEvenly(members);
    _distributeAllMaticEvenly(members);
    _destroyGovernanceToken();
    selfdestruct(payable(msg.sender));
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
pragma solidity ^0.8.9;

interface ERC20Interface {
  function name() external view returns(string memory);
  function symbol() external view returns(string memory);
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address, uint) external returns (bool);
}

interface IPoolGovernanceTokenBeta {
  function issue(address, uint) external;
  function destroy() external;
  function price() external view returns(uint);
}

contract WunderVaultBeta {
  address[] public ownedTokenAddresses;
  address public governanceToken;
  address internal quickSwapRouterAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
  
  event TokenAdded(address indexed tokenAddress, uint balance);
  event MaticWithdrawed(address indexed receiver, uint amount);
  event TokensWithdrawed(address indexed tokenAddress, address indexed receiver, uint amount);

  modifier onlyPool {
    require(msg.sender == address(this), "Only the Pool is allowed to execute this function. Try submitting a proposal");
    _;
  }

  constructor(address _tokenAddress) {
    governanceToken = _tokenAddress;
  }
  
  function addToken(address _tokenAddress) public {
    (, bytes memory nameData) = _tokenAddress.call(abi.encodeWithSignature("name()"));
    (, bytes memory symbolData) = _tokenAddress.call(abi.encodeWithSignature("symbol()"));
    (, bytes memory balanceData) = _tokenAddress.call(abi.encodeWithSignature("balanceOf(address)", address(this)));

    require(nameData.length > 0, "Not a valid ERC20 Token");
    require(symbolData.length > 0, "Not a valid ERC20 Token");
    require(balanceData.length > 0, "Not a valid ERC20 Token");

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
  
  function _distributeSomeBalanceOfTokenEvenly(address _tokenAddress, address[] memory _receivers, uint _amount) public onlyPool {
    for (uint256 index = 0; index < _receivers.length; index++) {
      _withdrawTokens(_tokenAddress, _receivers[index], _amount * governanceTokensOf(_receivers[index]) / totalGovernanceTokens());
    }
  }

  function _distributeFullBalanceOfTokenEvenly(address _tokenAddress, address[] memory _receivers) public onlyPool {
    uint balance = ERC20Interface(_tokenAddress).balanceOf(address(this));

    _distributeSomeBalanceOfTokenEvenly(_tokenAddress, _receivers, balance);
  }

  function _distributeFullBalanceOfAllTokensEvenly(address[] memory _receivers) public onlyPool {
    for (uint256 index = 0; index < ownedTokenAddresses.length; index++) {
      _distributeFullBalanceOfTokenEvenly(ownedTokenAddresses[index], _receivers);
    }
  }

  function _distributeMaticEvenly(address[] memory _receivers, uint _amount) public onlyPool {
    for (uint256 index = 0; index < _receivers.length; index++) {
      _withdrawMatic(_receivers[index], _amount * governanceTokensOf(_receivers[index]) / totalGovernanceTokens());
    }
  }

  function _distributeAllMaticEvenly(address[] memory _receivers) public onlyPool {
    uint balance = address(this).balance;
    _distributeMaticEvenly(_receivers, balance);
  }

  function _withdrawTokens(address _tokenAddress, address _receiver, uint _amount) public onlyPool {
    uint balance = ERC20Interface(_tokenAddress).balanceOf(address(this));
    require(balance >= _amount, "Withdraw Amount exceeds balance of Vault");
    require(ERC20Interface(_tokenAddress).transfer(_receiver, _amount), "Withdraw Failed");
    emit TokensWithdrawed(_tokenAddress, _receiver, _amount);
  }

  function _withdrawMatic(address _receiver, uint _amount) public onlyPool {
    require(address(this).balance >= _amount, "Withdraw Amount exceeds balance of Vault");
    payable(_receiver).transfer(_amount);
    emit MaticWithdrawed(_receiver, _amount);
  }

  function _issueGovernanceTokens(address _newUser, uint _value) internal {
    if (governanceTokenPrice() == 0) {
      IPoolGovernanceTokenBeta(governanceToken).issue(_newUser, 100);
    } else {
      IPoolGovernanceTokenBeta(governanceToken).issue(_newUser, _value / governanceTokenPrice());
    }
  }

  function governanceTokensOf(address _user) public view returns(uint balance) {
    return ERC20Interface(governanceToken).balanceOf(_user);
  }

  function totalGovernanceTokens() public view returns(uint balance) {
    return ERC20Interface(governanceToken).totalSupply();
  }

  function governanceTokenPrice() public view returns(uint price) {
    return IPoolGovernanceTokenBeta(governanceToken).price();
  }

  function _destroyGovernanceToken() internal {
    IPoolGovernanceTokenBeta(governanceToken).destroy();
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