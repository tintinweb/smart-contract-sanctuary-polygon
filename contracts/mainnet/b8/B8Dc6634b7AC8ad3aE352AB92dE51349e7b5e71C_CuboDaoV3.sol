// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Cubo.sol";
import "./Dai.sol";

// CuboDao V3
contract CuboDaoV3 {
  uint public totalNodes;
  address [] public accountAddresses; // all addresses that have at least one node

  Cubo public cuboAddress;
  Dai public daiAddress;
  address private owner;

  uint public accountNodeLimit = 100;

  struct Node {
    uint nodeType;
    uint createdAt;
  }

  struct Account {
    bool exists;
    bool archived;  // allows for account blacklisting
    mapping(uint => Node) nodes;
    uint nodesLength;
    uint lastWithdrawalAt; // timestamp of latest reward withdrawal
  }

  mapping(address => Account) public accounts;

  // Rewards per node type
  uint [] public nodeMultiplers = [
    1 * 10 ** 17,  // 0 - PLAN reward: 0.1 CUBO
    3 * 10 ** 17,  // 1 - FEMT reward: 0.3 CUBO
    6 * 10 ** 17,  // 2 - PICO reward: 0.6 CUBO
    1 * 10 ** 18,  // 3 - NANO reward: 1 CUBO
    3 * 10 ** 18,  // 4 - MINI reward: 3 CUBO
    7 * 10 ** 18,  // 5 - KILO reward: 7 CUBO
    16 * 10 ** 18, // 6 - MEGA reward: 16 CUBO
    100 * 10 ** 18 // 7 - GIGA reward: 100 CUBO
  ];

  uint [] public requiredAmounts = [
    25   * 10 ** 18, // 0 - PLAN: 25 DAI   - 25 CUBO
    50   * 10 ** 18, // 1 - FEMT: 50 DAI   - 50 CUBO
    75   * 10 ** 18, // 2 - PICO: 75 DAI   - 75 CUBO
    100  * 10 ** 18, // 3 - NANO: 100 DAI  - 100 CUBO
    250  * 10 ** 18, // 4 - MINI: 250 DAI  - 250 CUBO
    500  * 10 ** 18, // 5 - KILO: 500 DAI  - 500 CUBO
    1000 * 10 ** 18, // 6 - MEGA: 1000 DAI - 1000 CUBO
    5000 * 10 ** 18  // 7 - GIGA: 5000 DAI - 5000 CUBO
  ];

  uint [] public rotTargetForNodes = [
    2.16  * 10 ** 7,  // 0 - PLAN: 250 days in seconds
    1.443 * 10 ** 7,  // 1 - FEMT: 167 days in seconds
    1.08  * 10 ** 7,  // 2 - PICO: 125 days in seconds
    8.64  * 10 ** 6,  // 3 - NANO: 100 days in seconds
    7.258 * 10 ** 6,  // 4 - MINI:  84 days in seconds
    6.221 * 10 ** 6,  // 5 - KILO:  72 days in seconds
    5.443 * 10 ** 6,  // 6 - MEGA:  63 days in seconds
    4.32  * 10 ** 6   // 7 - GIGA:  50 days in seconds
  ];

  // cooldown period to get 10% more rewards
  uint public cooldownTimeInSeconds = 1.21 * 10 ** 6;  // 14 days in seconds
  // Percentages to cut rewards by after ROT is reached
  uint public percentageOfRewardBeforeCooldown  = 50;  // 50%
  uint public percentageOfRewardAfterCooldown   = 60;  // 60%

  constructor(Cubo _cuboAddress, Dai _daiAddress) {
    owner = msg.sender;
    cuboAddress = _cuboAddress;
    daiAddress = _daiAddress;
  }

  function migrateMultiple(address [] memory _addresses, uint [][] memory _nodeArgs) external {
    require(msg.sender == owner, 'Only owner can run this method.');

    for(uint i=0; i< _addresses.length; i++) {
      address a = _addresses[i];
      uint nodeType = _nodeArgs[i][0];
      uint nodeCreatedAt = _nodeArgs[i][1];

      if(!accounts[a].exists){
        accounts[a].exists = true;
        accounts[a].nodesLength = 0;
        accounts[a].lastWithdrawalAt = block.timestamp;
        accountAddresses.push(a);
      }

      accounts[a].nodes[accounts[a].nodesLength] = Node(nodeType, nodeCreatedAt);
      accounts[a].nodesLength++;
      totalNodes++;
    }
  }

  // Update node daily rewards
  function setNodeMultipliers(uint _newRewards, uint _nodeType) external{
    require(msg.sender == owner, 'Only owner can run this method.');
    require(_newRewards > 0, "Reward cant be is zero!");
    require(_nodeType >= 0 && _nodeType <= 7, "Node type not recognized");

    nodeMultiplers[_nodeType] = _newRewards;
  }

  // Update node prices
  function setRequiredAmounts(uint _newAmountRequired, uint _nodeType) external{
    require(msg.sender == owner, 'Only owner can run this method.');
    require(_newAmountRequired > 0, "Required amount cant be is zero!");
    require(_nodeType >= 0 && _nodeType <= 7, "Node type not recognized");

    requiredAmounts[_nodeType] = _newAmountRequired;
  }

  // Update node ROT target
  function setRotTargetForNode(uint _newRotTarget, uint _nodeType) external{
    require(msg.sender == owner, 'Only owner can run this method.');
    require(_newRotTarget > 0, "ROT target cant be is zero!");
    require(_nodeType >= 0 && _nodeType <= 7, "Node type not recognized");

    rotTargetForNodes[_nodeType] = _newRotTarget;
  }

  // setter for accountNodeLimit
  function setAccountNodeLimit(uint _nodeLimit) external {
    require(_nodeLimit > 0, "Node limit must be greater than 0");
    require(msg.sender == owner, 'Only owner can run this method.');

    accountNodeLimit = _nodeLimit;
  }

  function setCooldownTimeInSeconds(uint _cooldownTimeInSeconds) external {
    require(msg.sender == owner, 'Only owner can run this method.');

    cooldownTimeInSeconds = _cooldownTimeInSeconds;
  }

  function setPercentageOfRewardBeforeCooldown(uint _percentageOfRewardBeforeCooldown) external {
    require(msg.sender == owner, 'Only owner can run this method.');

    percentageOfRewardBeforeCooldown = _percentageOfRewardBeforeCooldown;
  }

  function setPercentageOfRewardAfterCooldown(uint _percentageOfRewardAfterCooldown) external {
    require(msg.sender == owner, 'Only owner can run this method.');

    percentageOfRewardAfterCooldown = _percentageOfRewardAfterCooldown;
  }

  function archiveAccount(address _address) external {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'Only owner can run this method.');

    Account storage account = accounts[_address];
    require(!account.archived, 'This account is already archived.');

    account.archived = true;
    totalNodes -= account.nodesLength;
  }

  function activateAccount(address _address) external {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'Only owner can run this method.');

    Account storage account = accounts[_address];
    require(account.archived, 'This account is already active.');

    account.archived = false;
    totalNodes += account.nodesLength;
  }

  // totalNodes getter
  function getTotalNodes() external view returns(uint) {
    return totalNodes;
  }

  // cuboNodesAddresses getters
  function getAccountsLength() external view returns(uint) {
    return accountAddresses.length;
  }

  function getAccountsAddressForIndex(uint _index) external view returns(address) {
    return accountAddresses[_index];
  }

  // accounts getter
  function getAccount(address _address) external view returns(Node[] memory, uint, uint, bool) {
    Account storage acc = accounts[_address];

    Node[] memory nodes = new Node[](acc.nodesLength);
    for (uint i = 0; i < acc.nodesLength; i++) {
      nodes[i] = acc.nodes[i];
    }

    return(nodes, acc.nodesLength, acc.lastWithdrawalAt, acc.archived);
  }

  function getNodesForAccount(address _address) external view returns(uint[][] memory) {
    Account storage acc = accounts[_address];

    uint[][] memory nodesArr = new uint[][](acc.nodesLength);
    for (uint i = 0; i < acc.nodesLength; i++) {
      nodesArr[i] = new uint[](2);
      nodesArr[i][0] = acc.nodes[i].nodeType;
      nodesArr[i][1] = acc.nodes[i].createdAt;
    }

    return(nodesArr);
  }

  // create a node given the address, type and amounts are correct
  function mintNode(address _address, uint _cuboAmount, uint _daiAmount, uint _nodeType) external {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == _address, 'Only user can create a node.');
    require(_nodeType >= 0 && _nodeType <= 7, 'Invalid node type');
    require(_cuboAmount == requiredAmounts[_nodeType], 'You must provide the corrent exact amount of CUBO');
    require(_daiAmount == requiredAmounts[_nodeType], 'You must provide the corrent exact amount of DAI');

    Account storage account;

    if(accounts[_address].exists){
      account = accounts[_address];
    }
    else{
      accounts[_address].exists = true;
      accounts[_address].nodesLength = 0;
      accounts[_address].lastWithdrawalAt = block.timestamp;
      accountAddresses.push(_address);
      account = accounts[_address];
    }

    require(!account.archived, 'This account is blacklisted.');
    require(account.nodesLength < accountNodeLimit, 'Maximum nodes limit reached!');

    account.nodes[account.nodesLength] = Node(_nodeType, block.timestamp);
    account.nodesLength++;
    totalNodes++;

    cuboAddress.transferFrom(_address, address(this), _cuboAmount);
    daiAddress.transferFrom(_address, address(this), _daiAmount);
  }

  function isWithdrawalAvailable(address _to, uint _timestamp) external view returns(bool){
    require(_to != address(0), "_to is address 0");
    require(msg.sender == _to, 'Only user can see its own funds.');

    Account storage account = accounts[_to];
    require(!account.archived, 'This account is blacklisted.');

    return ((_timestamp - account.lastWithdrawalAt) / 86400) >= 1;
  }

  // Get amount to be returned for a single node
  function estimateInterestSingleNode(address _to, uint _nodeId, uint _timestamp) external view returns(uint) {
    require(_to != address(0), "_to is address 0");
    require(msg.sender == _to, 'Only user can see its own funds.');

    Account storage account = accounts[_to];
    require(!account.archived, 'This account is blacklisted.');

    return estimateWithdrawAmountForNode(account, account.nodes[_nodeId], _timestamp);
  }

  // estimate receives the current timestamp so we can show in the UI the total pending
  // value of rewards to be withdrawn
  function estimateInterestToWithdraw(address _to, uint _timestamp) external view returns(uint) {
    require(_to != address(0), "_to is address 0");
    require(msg.sender == _to, 'Only user can see its own funds.');

    Account storage account = accounts[_to];
    require(!account.archived, 'This account is blacklisted.');

    return estimateWithdrawAmountForAccount(account, _timestamp);
  }

  // does the same as the method above, but actually transfers the tokens owed.
  // Gets the timestamp from the block instead of it being a parameter
  function withdrawInterest(address _to) external {
    require(_to != address(0), "_to is address 0");
    require(msg.sender == _to, 'Only user can widthraw its own funds.');

    Account storage account = accounts[_to];
    require(!account.archived, 'This account is blacklisted.');

    // calc if 24h past since last widthrawl
    uint daysSinceLastWithdrawal = (block.timestamp - account.lastWithdrawalAt) / 86400;
    require(daysSinceLastWithdrawal >= 1, 'Interest accumulated must be greater than zero.');

    uint amount = estimateWithdrawAmountForAccount(account, block.timestamp);
    account.lastWithdrawalAt = block.timestamp;
    cuboAddress.transfer(_to, amount);
  }

  // Private function
  function estimateWithdrawAmountForAccount(Account storage _account, uint _timestamp) private view returns(uint) {
    uint amount = 0;
    for(uint i=0; i<_account.nodesLength; i++){
      Node memory node = _account.nodes[i];
      amount += estimateWithdrawAmountForNode(_account, node, _timestamp);
    }
    return amount;
  }

  function estimateWithdrawAmountForNode(Account storage _account, Node memory _node, uint _timestamp) private view returns(uint) {
    uint latestTimestamp;
    if(_node.createdAt <= _account.lastWithdrawalAt){
      latestTimestamp = _account.lastWithdrawalAt;
    }
    else {
      latestTimestamp = _node.createdAt;
    }

    uint reward;
    uint rotReachedTimestamp = _node.createdAt + rotTargetForNodes[_node.nodeType];

    // ROT was reached between withdrawals
    if(_timestamp > rotReachedTimestamp && _account.lastWithdrawalAt < rotReachedTimestamp){
      // First pay rewards in full for period when they should be
      uint amount;
      reward = nodeMultiplers[_node.nodeType] / 86400;
      amount = reward * (rotReachedTimestamp - _account.lastWithdrawalAt);

      // Then pay either with cooldown cuts or not depending on time of withdrawal
      if((_timestamp - rotReachedTimestamp) > cooldownTimeInSeconds) {
        reward = ((nodeMultiplers[_node.nodeType] / 86400) / 100) * percentageOfRewardAfterCooldown;
      }
      else {
        reward = ((nodeMultiplers[_node.nodeType] / 86400) / 100) * percentageOfRewardBeforeCooldown;
      }
      amount += reward * (_timestamp - rotReachedTimestamp);
      return amount;
    }
    // ROT was reached
    else if(_timestamp > rotReachedTimestamp){
      if((_timestamp - _account.lastWithdrawalAt) > cooldownTimeInSeconds) {
        reward = ((nodeMultiplers[_node.nodeType] / 86400) / 100) * percentageOfRewardAfterCooldown;
      }
      else {
        reward = ((nodeMultiplers[_node.nodeType] / 86400) / 100) * percentageOfRewardBeforeCooldown;
      }
      // Daily Reward In Seconds * seconds Since last withdrawal
      return reward * (_timestamp - latestTimestamp);
    }
    // ROT not reached yet
    else if(_timestamp <= rotReachedTimestamp){
      reward = nodeMultiplers[_node.nodeType] / 86400;
      // Daily Reward In Seconds * seconds Since last withdrawal
      return reward * (_timestamp - latestTimestamp);
    }
    else{
      // no else cases
      revert("Couldn't handle timestamp provided");
    }
  }

  function transferCubo(address _address, uint _amount) external {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'Only owner can run this method');
    cuboAddress.transfer(_address, _amount);
  }

  function transferDai(address _address, uint _amount) external {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'Only owner can run this method');
    daiAddress.transfer(_address, _amount);
  }

  // Same as mintNode, but without payment. Usually used for people that contribute a lot
  // to the project and for giveaways
  function awardNode(address _address, uint _nodeType) external {
    require(_address != address(0), "_address is address 0");
    require(msg.sender == owner, 'Only owner can run this method');
    require(_nodeType >= 0 && _nodeType <= 7, 'Invalid node type');

    Account storage account;

    if(accounts[_address].exists){
      account = accounts[_address];
    }
    else{
      accounts[_address].exists = true;
      accounts[_address].nodesLength = 0;
      accounts[_address].lastWithdrawalAt = block.timestamp;
      accountAddresses.push(_address);
      account = accounts[_address];
    }

    require(account.nodesLength < accountNodeLimit, '100 nodes maximum already reached!');

    account.nodes[account.nodesLength] = Node(_nodeType, block.timestamp);
    account.nodesLength++;
    totalNodes++;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Dai is ERC20 {
  constructor() ERC20('Mock DAI token', 'mDAI') {
    _mint(msg.sender, 1000000 * 10 ** 18);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Cubo is ERC20 {
  address private owner;
  address private cuboDao;
  uint private limit = 100000000 * 10 ** 18;

  constructor() ERC20('CUBO token', 'CUBO') {
    owner = msg.sender;

    _mint(msg.sender, 2000000 * 10 ** 18);
  }

  function setDaoContract(address _cuboDao) public{
    require(msg.sender == owner, 'You must be the owner to run this.');
    cuboDao = _cuboDao;
  }

  function setTranferLimit(uint _limit) public{
    require(msg.sender == owner, 'You must be the owner to run this.');
    limit = _limit;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override(ERC20) returns (bool) {
    require(amount <= limit, 'This transfer exceeds the allowed limit!');
    return super.transferFrom(sender, recipient, amount);
  }

  function transfer(address recipient, uint256 amount) public override(ERC20) returns (bool) {
    require(amount <= limit, 'This transfer exceeds the allowed limit!');
    return super.transfer(recipient, amount);
  }

  function mint(uint256 _amount) public {
    require(msg.sender == cuboDao || msg.sender == owner, 'Can only be used by CuboDao or owner.');
    _mint(msg.sender, _amount);
  }

  function burn(uint256 _amount) public {
    require(msg.sender == cuboDao || msg.sender == owner, 'Can only be used by CuboDao or owner.');
    _burn(msg.sender, _amount);
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