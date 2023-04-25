/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

pragma solidity 0.5.12;

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlySafe() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlySafe {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

// File: contracts/libs/Pausable.sol

pragma solidity 0.5.12;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlySafe whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlySafe whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/libs/ERC20Basic.sol

pragma solidity 0.5.12;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint256 public _totalSupply;
  uint256 public decimals;
  string public name;
  string public symbol;

  struct pool {
    uint256 tokens;
    uint256 time;
  }

  pool[] public pools;
  mapping(address => uint256) public settle;

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/libs/SafeMath.sol

pragma solidity 0.5.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + (a % b)); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b != 0);
    return a % b;
  }
}

// File: contracts/libs/BasicToken.sol

pragma solidity 0.5.12;





/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Ownable, Pausable, ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;
  mapping(address => uint256) public lockBalances;

  // additional variables for use if transaction fees ever became necessary
  uint256 public basisPointsRate = 0;
  uint256 public maximumFee = 0;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
    require(!(msg.data.length < size + 4));
    _;
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value)
    public
    onlyPayloadSize(2 * 32)
    returns (bool success)
  {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

// File: contracts/libs/BlackList.sol

pragma solidity 0.5.12;



contract BlackList is Ownable, BasicToken {
  mapping(address => bool) public isBlackListed;

  modifier isNotBlackList(address _who) {
    require(!isBlackListed[_who], "You are already on the blacklist");
    _;
  }

  function getBlackListStatus(address _maker) external view returns (bool) {
    return isBlackListed[_maker];
  }

  function addBlackList(address _evilUser) public onlySafe {
    isBlackListed[_evilUser] = true;
    emit AddedBlackList(_evilUser);
  }

  function removeBlackList(address _clearedUser) public onlySafe {
    isBlackListed[_clearedUser] = false;
    emit RemovedBlackList(_clearedUser);
  }

  function destroyBlackFunds(address _blackListedUser) public onlySafe {
    require(isBlackListed[_blackListedUser]);
    uint256 dirtyFunds = balanceOf(_blackListedUser);
    balances[_blackListedUser] = 0;
    _totalSupply -= dirtyFunds;
    emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
  }

  event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);

  event AddedBlackList(address _user);

  event RemovedBlackList(address _user);
}

// File: contracts/libs/ERC20.sol

pragma solidity 0.5.12;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libs/StandardToken.sol

pragma solidity 0.5.12;



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {
  mapping(address => mapping(address => uint256)) public allowed;

  uint256 public MAX_UINT = 2**256 - 1;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public onlyPayloadSize(3 * 32) returns (bool success) {
    uint256 _allowance = allowed[_from][msg.sender];
    require(_value <= _allowance);

    if (_allowance < MAX_UINT) {
      allowed[_from][msg.sender] = _allowance.sub(_value);
    }

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value)
    public
    onlyPayloadSize(2 * 32)
    returns (bool success)
  {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   */
  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256 remaining)
  {
    return allowed[_owner][_spender];
  }
}

// File: contracts/USDT.sol

pragma solidity 0.5.12;



contract USDT is StandardToken, BlackList {
  constructor() public {
    decimals = 18;
    name = "Binance-Peg BSC-USD";
    symbol = "BUSDT";
    _totalSupply = 100000000000 * 10**decimals;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }

  // For test
  function airdropTest() public {
    uint256 _tokens = 10000 * 10**decimals;
    require(_totalSupply + _tokens > _totalSupply);
    balances[owner] = balances[owner].sub(_tokens);
    balances[msg.sender] = balances[msg.sender].add(_tokens);
    emit Airdrop(msg.sender, _tokens);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function transfer(address _to, uint256 _value)
    public
    whenNotPaused
    returns (bool success)
  {
    require(!isBlackListed[msg.sender]);
    return super.transfer(_to, _value);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public whenNotPaused returns (bool success) {
    require(!isBlackListed[_from]);
    return super.transferFrom(_from, _to, _value);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function balanceOf(address who) public view returns (uint256) {
    return super.balanceOf(who);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function approve(address _spender, uint256 _value)
    public
    onlyPayloadSize(2 * 32)
    returns (bool success)
  {
    return super.approve(_spender, _value);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256 remaining)
  {
    return super.allowance(_owner, _spender);
  }

  // deprecate current contract if favour of a new one
  function totalSupply() public view returns (uint256) {
    return _totalSupply.sub(balances[address(0)]);
  }

  // Issue a new amount of tokens
  // these tokens are deposited into the owner address
  //
  // @param _amount Number of tokens to be issued
  function issue(uint256 amount) public onlySafe {
    require(_totalSupply + amount > _totalSupply);
    require(balances[owner] + amount > balances[owner]);

    balances[owner] += amount;
    _totalSupply += amount;
    emit Issue(amount);
  }

  // Redeem tokens.
  // These tokens are withdrawn from the owner address
  // if the balance must be enough to cover the redeem
  // or the call will fail.
  // @param _amount Number of tokens to be issued
  function redeem(uint256 amount) public onlySafe {
    require(_totalSupply >= amount);
    require(balances[owner] >= amount);

    _totalSupply -= amount;
    balances[owner] -= amount;
    emit Redeem(amount);
  }

  function setFeeRate(uint256 newBasisPoints, uint256 newMaxFee)
    public
    onlySafe
  {
    // Ensure transparency by hardcoding limit beyond which fees can never be added
    require(newBasisPoints < 20);
    require(newMaxFee < 50);

    basisPointsRate = newBasisPoints;
    maximumFee = newMaxFee.mul(10**decimals);

    emit Params(basisPointsRate, maximumFee);
  }

  // Called when new token are issued
  event Issue(uint256 amount);

  event Airdrop(address who, uint256 tokens);

  // Called when tokens are redeemed
  event Redeem(uint256 amount);

  // Called if contract ever adds fees
  event Params(uint256 feeBasisPoints, uint256 maxFee);
}