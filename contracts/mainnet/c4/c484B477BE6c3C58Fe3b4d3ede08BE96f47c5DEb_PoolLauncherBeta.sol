/**
 *Submitted for verification at polygonscan.com on 2022-03-10
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





/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}







/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}





contract PoolGovernanceTokenBeta is ERC20 {
  address public launcherAddress;
  address public poolAddress;
  uint public price;

  constructor(string memory name, string memory symbol, address _creatorAddress, uint _amount) ERC20(name, symbol) {
    _mint(_creatorAddress, 100);
    price = _amount / 100;
    launcherAddress = msg.sender;
  }

  function decimals() public pure override returns(uint8) {
    return 0;
  }

  function setPoolAddress(address _poolAddress) external {
    require(msg.sender == launcherAddress, "Only the Launcher can set the PoolAddress");
    poolAddress = _poolAddress;
  }

  function issue(address _receiver, uint _amount) external {
    require(msg.sender == poolAddress, "Only the Pool can issue new tokens");
    _mint(_receiver, _amount);
  }

  function destroy() external {
    require(msg.sender == poolAddress, "Only the Pool can destroy this contract");
    selfdestruct(payable(msg.sender));
  }
}






interface IWunderPoolBeta {
  function isMember(address _member) external view returns(bool);
}

contract PoolLauncherBeta {
  address[] public launchedPools;

  mapping (address => address[]) public memberPools;

  event PoolLaunched(address indexed creator, address indexed poolAddress, string name, string governanceTokenName);

  function createNewPool(string memory _poolName, uint _entryBarrier, string memory _tokenName, string memory _tokenSymbol) public payable {
    PoolGovernanceTokenBeta newToken = new PoolGovernanceTokenBeta(_tokenName, _tokenSymbol, msg.sender, msg.value);
    WunderPoolBeta newPool = new WunderPoolBeta{value: msg.value}(_poolName, msg.sender, address(this), address(newToken), _entryBarrier);
    newToken.setPoolAddress(address(newPool));
    launchedPools.push(address(newPool));
    memberPools[msg.sender].push(address(newPool));
    emit PoolLaunched(msg.sender, address(newPool), _poolName, _tokenName);
  }

  function poolsOfMember(address _member) public view returns(address[] memory) {
    return memberPools[_member];
  }

  function addPoolToMembersPools(address _pool, address _member) external {
    require(IWunderPoolBeta(_pool).isMember(_member), "User is not Member of the Pool");
    memberPools[_member].push(_pool);
  }

  function removePoolFromMembersPools(address _pool, address _member) external {
    address[] storage pools = memberPools[_member];
    for (uint256 index = 0; index < pools.length; index++) {
      if (pools[index] == _pool) {
        pools[index] = pools[pools.length - 1];
        delete pools[pools.length - 1];
        pools.pop();
      }
    }
  }

  function allPools() public view returns(address[] memory) {
    return launchedPools;
  }
}