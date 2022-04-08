// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./WunderPoolGamma.sol";
import "./PoolGovernanceTokenGamma.sol";

contract PoolLauncherGamma {
  address public USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address[] public launchedPools;

  mapping (address => address[]) public memberPools;

  event PoolLaunched(address indexed creator, address indexed poolAddress, string name, address governanceTokenAddress, string governanceTokenName, uint entryBarrier);

  function createNewPool(string memory _poolName, uint _entryBarrier, string memory _tokenName, string memory _tokenSymbol, uint _invest) public {
    PoolGovernanceTokenGamma newToken = new PoolGovernanceTokenGamma(_tokenName, _tokenSymbol, msg.sender, _invest);
    WunderPoolGamma newPool = new WunderPoolGamma(_poolName, msg.sender, address(this), address(newToken), _entryBarrier);
    require(ERC20Interface(USDC).transferFrom(msg.sender, address(newPool), _invest), "USDC Transfer failed");
    newToken.setPoolAddress(address(newPool));
    launchedPools.push(address(newPool));
    memberPools[msg.sender].push(address(newPool));
    emit PoolLaunched(msg.sender, address(newPool), _poolName, address(newToken), _tokenName, _entryBarrier);
  }

  function poolsOfMember(address _member) public view returns(address[] memory) {
    return memberPools[_member];
  }

  function addPoolToMembersPools(address _pool, address _member) external {
    require(WunderPoolGamma(payable(_pool)).isMember(_member), "Not a Member");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./WunderVaultGamma.sol";

interface IPoolLauncherGamma {
  function addPoolToMembersPools(address _pool, address _member) external;
  function removePoolFromMembersPools(address _pool, address _member) external;
}

contract WunderPoolGamma is WunderVaultGamma {
  enum VoteType { None, For, Against }

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

  mapping (uint => Proposal) public proposals;
  uint[] public proposalIds;

  address[] public members;
  mapping (address => bool) public memberLookup;
  
  string public name;
  address public launcherAddress;
  uint public entryBarrier;

  modifier onlyMember {
    require(isMember(msg.sender), "Not a Member");
    _;
  }

  event NewProposal(uint indexed id, address indexed creator, string title);
  event Voted(uint indexed proposalId, address indexed voter, uint mode);
  event ProposalExecuted(uint indexed proposalId, address indexed executor, bytes[] result);
  event NewMember(address indexed memberAddress, uint stake);

  constructor (string memory _name, address _creator, address _launcher, address _governanceToken, uint _entryBarrier) WunderVaultGamma(_governanceToken) {
    name = _name;
    launcherAddress = _launcher;
    entryBarrier = _entryBarrier;
    members.push(_creator);
    memberLookup[_creator] = true;
    addToken(USDC, false, 0);
  }

  receive() external payable {}

  function createProposal(string memory _title, string memory _description, address _contractAddress, string memory _action, bytes memory _param, uint _transactionValue, uint _deadline) public onlyMember {
    address[] memory _contractAddresses = new address[](1);
    _contractAddresses[0] = _contractAddress;
    string[] memory _actions = new string[](1);
    _actions[0] = _action;
    bytes[] memory _params = new bytes[](1);
    _params[0] = _param;
    uint[] memory _transactionValues = new uint[](1);
    _transactionValues[0] = _transactionValue;
    
    createMultiActionProposal(_title, _description, _contractAddresses, _actions, _params, _transactionValues, _deadline);
  }

  function createMultiActionProposal(string memory _title, string memory _description, address[] memory _contractAddresses, string[] memory _actions, bytes[] memory _params, uint[] memory _transactionValues, uint _deadline) public onlyMember {
    require(_contractAddresses.length == _actions.length && _actions.length == _params.length && _params.length == _transactionValues.length, "Inconsistent amount of transactions");
    require(bytes(_title).length > 0, "Missing Title");
    require(_deadline > block.timestamp, "Invalid Deadline");

    for (uint256 index = 0; index < _contractAddresses.length; index++) {
      require(_contractAddresses[index] != address(0), "Missing Address");
      require(bytes(_actions[index]).length > 0, "Missing Action");
    }
    
    uint nextProposalId = proposalIds.length;
    proposalIds.push(nextProposalId);

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

  function hasVoted(uint proposalId, address account) public view returns (VoteType) {
    return proposals[proposalId].hasVoted[account];
  }

  function vote(uint _proposalId, uint _mode) public onlyMember {
    Proposal storage proposal = proposals[_proposalId];
    require(proposal.actions.length > 0, "Does not exist");
    require(block.timestamp <= proposal.deadline, "Voting period has ended");
    require(hasVoted(_proposalId, msg.sender) == VoteType.None, "Already voted");

    if (_mode == uint8(VoteType.Against)) {
      proposal.hasVoted[msg.sender] = VoteType.Against;
      proposal.noVoters.push(msg.sender);
    } else if (_mode == uint8(VoteType.For)) {
      proposal.hasVoted[msg.sender] = VoteType.For;
      proposal.yesVoters.push(msg.sender);
    } else {
      revert("Invalid VoteType (1=YES, 2=NO)");
    }
    emit Voted(_proposalId, msg.sender, _mode);
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
    require(proposal.actions.length > 0, "Does not exist");
    require(!proposal.executed, "Already executed");
    (uint yesVotes, uint noVotes) = calculateVotes(_proposalId);
    require((noVotes * 2) <= totalGovernanceTokens(), "Majority voted against execution");
    require((yesVotes * 2) > totalGovernanceTokens() || proposal.deadline <= block.timestamp, "Voting still allowed");

    uint transactionTotal = 0;
    for (uint256 index = 0; index < proposal.transactionValues.length; index++) {
      transactionTotal += proposal.transactionValues[index];
    }

    require(transactionTotal <= address(this).balance, "Not enough funds");
    
    proposal.executed = true;
    
    bytes[] memory results = new bytes[](proposal.contractAddresses.length);

    for (uint256 index = 0; index < proposal.contractAddresses.length; index++) {
      address contractAddress = proposal.contractAddresses[index];
      bytes memory callData = bytes.concat(abi.encodeWithSignature(proposal.actions[index]), proposal.params[index]);

      bool success = false;
      bytes memory result;
      (success, result) = contractAddress.call{value: proposal.transactionValues[index]}(callData);
      require(success, "Execution failed");
      results[index] = result;
    }
    
    emit ProposalExecuted(_proposalId, msg.sender, results);
  }

  function joinPool(uint amount) public {
    require((amount >= entryBarrier && amount >= governanceTokenPrice()) || governanceTokensOf(msg.sender) > 0, "Your stake is not high enough");
    require(ERC20Interface(USDC).transferFrom(msg.sender, address(this), amount), "USDC Transfer failed");
    addMember(msg.sender);
    _issueGovernanceTokens(msg.sender, amount);
    emit NewMember(msg.sender, amount);
  }

  function fundPool(uint amount) external {
    require(ERC20Interface(USDC).transferFrom(msg.sender, address(this), amount), "USDC Transfer failed");
    _issueGovernanceTokens(msg.sender, amount);
  }

  function addMember(address _newMember) internal {
    require(!isMember(_newMember), "Already Member");
    members.push(_newMember);
    memberLookup[_newMember] = true;
    IPoolLauncherGamma(launcherAddress).addPoolToMembersPools(address(this), _newMember);
  }

  function isMember(address _maybeMember) public view returns (bool) {
    return memberLookup[_maybeMember];
  }

  function poolMembers() public view returns(address[] memory) {
    return members;
  }

  function getAllProposalIds() public view returns(uint[] memory) {
    return proposalIds;
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
    _distributeAllNftsEvenly(members);
    _destroyGovernanceToken();
    selfdestruct(payable(msg.sender));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PoolGovernanceTokenGamma is ERC20 {
  address public launcherAddress;
  address public poolAddress;
  uint public price;

  constructor(string memory name, string memory symbol, address _creatorAddress, uint _amount) ERC20(name, symbol) {
    launcherAddress = msg.sender;
    _mint(_creatorAddress, 100);
    price = _amount / 100;
  }

  function decimals() public pure override returns(uint8) {
    return 0;
  }

  function setPoolAddress(address _poolAddress) external {
    require(msg.sender == launcherAddress);
    poolAddress = _poolAddress;
  }

  function issue(address _receiver, uint _amount) external {
    require(msg.sender == poolAddress || msg.sender == launcherAddress);
    _mint(_receiver, _amount);
  }

  function destroy() external {
    require(msg.sender == poolAddress);
    selfdestruct(payable(msg.sender));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20Interface {
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address, uint) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
}

interface IGovernanceToken {
  function issue(address, uint) external;
  function destroy() external;
  function price() external view returns(uint);
}

contract WunderVaultGamma {
  address public USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  
  address public governanceToken;
  address internal quickSwapRouterAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
  
  address[] public ownedTokenAddresses;
  mapping(address => bool) public ownedTokenLookup;

  address[] public ownedNftAddresses;
  mapping(address => uint[]) ownedNftLookup;

  modifier onlyPool {
    require(msg.sender == address(this), "Not allowed. Try submitting a proposal");
    _;
  }

  event TokenAdded(address indexed tokenAddress, bool _isERC721, uint _tokenId);
  event MaticWithdrawed(address indexed receiver, uint amount);
  event TokensWithdrawed(address indexed tokenAddress, address indexed receiver, uint amount);

  constructor(address _tokenAddress) {
    governanceToken = _tokenAddress;
  }
  
  function addToken(address _tokenAddress, bool _isERC721, uint _tokenId) public {
    (, bytes memory nameData) = _tokenAddress.call(abi.encodeWithSignature("name()"));
    (, bytes memory symbolData) = _tokenAddress.call(abi.encodeWithSignature("symbol()"));
    (, bytes memory balanceData) = _tokenAddress.call(abi.encodeWithSignature("balanceOf(address)", address(this)));

    require(nameData.length > 0, "Invalid Token");
    require(symbolData.length > 0, "Invalid Token");
    require(balanceData.length > 0, "Invalid Token");

    if (_isERC721) {
      if (ownedNftLookup[_tokenAddress].length == 0) {
        ownedNftAddresses.push(_tokenAddress);
      }
      ownedNftLookup[_tokenAddress].push(_tokenId);
    } else if (!ownedTokenLookup[_tokenAddress]) {
      ownedTokenAddresses.push(_tokenAddress);
      ownedTokenLookup[_tokenAddress] = true;
    }
    emit TokenAdded(_tokenAddress, _isERC721, _tokenId);
  }

  function getOwnedTokenAddresses() public view returns(address[] memory) {
    return ownedTokenAddresses;
  }

  function getOwnedNftAddresses() public view returns(address[] memory) {
    return ownedNftAddresses;
  }

  function getOwnedNftTokenIds(address _contractAddress) public view returns(uint[] memory) {
    return ownedNftLookup[_contractAddress];
  }
  
  function _distributeNftsEvenly(address _tokenAddress, address[] memory _receivers) public onlyPool {
    for (uint256 i = 0; i < ownedNftLookup[_tokenAddress].length; i++) {
      uint sum = 0;
      uint randomNumber = uint256(keccak256(abi.encode(_tokenAddress, ownedNftLookup[_tokenAddress][i], block.timestamp))) % totalGovernanceTokens();
      for (uint256 j = 0; j < _receivers.length; j++) {
        sum += governanceTokensOf(_receivers[j]);
        if (sum >= randomNumber) {
          (bool success,) = _tokenAddress.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(this), _receivers[j], ownedNftLookup[_tokenAddress][i]));
          require(success, "Transfer failed");
          break;
        }
      }
    }
  }

  function _distributeAllNftsEvenly(address[] memory _receivers) public onlyPool {
    for (uint256 i = 0; i < ownedNftAddresses.length; i++) {
      _distributeNftsEvenly(ownedNftAddresses[i], _receivers);
    }
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
    if (_amount > 0) {
      uint balance = ERC20Interface(_tokenAddress).balanceOf(address(this));
      require(balance >= _amount, "Amount exceeds balance");
      require(ERC20Interface(_tokenAddress).transfer(_receiver, _amount), "Withdraw Failed");
      emit TokensWithdrawed(_tokenAddress, _receiver, _amount);
    }
  }

  function _withdrawMatic(address _receiver, uint _amount) public onlyPool {
    if (_amount > 0) {
      require(address(this).balance >= _amount, "Amount exceeds balance");
      payable(_receiver).transfer(_amount);
      emit MaticWithdrawed(_receiver, _amount);
    }
  }

  function _issueGovernanceTokens(address _newUser, uint _value) internal {
    if (governanceTokenPrice() == 0) {
      IGovernanceToken(governanceToken).issue(_newUser, 100);
    } else {
      IGovernanceToken(governanceToken).issue(_newUser, _value / governanceTokenPrice());
    }
  }

  function governanceTokensOf(address _user) public view returns(uint balance) {
    return ERC20Interface(governanceToken).balanceOf(_user);
  }

  function totalGovernanceTokens() public view returns(uint balance) {
    return ERC20Interface(governanceToken).totalSupply();
  }

  function governanceTokenPrice() public view returns(uint price) {
    return IGovernanceToken(governanceToken).price();
  }

  function _destroyGovernanceToken() internal {
    IGovernanceToken(governanceToken).destroy();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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