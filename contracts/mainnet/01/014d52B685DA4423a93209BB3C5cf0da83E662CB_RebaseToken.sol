/**
 *Submitted for verification at polygonscan.com on 2023-07-30
*/

// SPDX-License-Identifier: MIT

/*
The Rebasefy Protocol - TRIANGLE Rebasefy Token (Official)
Rebasefy is a DAO governance protocol with a set of management features to 
protect the asset and earn profit with each new rebase.

Website and dApp:
    https://rebasefy.com

Doc's and support
    docs.rebasefy.com
    [email protected]
*/

pragma solidity 0.8.18;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
 library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
} 


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() external view returns (uint256 _supply);
  function balanceOf(address _owner) external view returns (uint256 _balance);
  function approve(address _spender, uint256 _value) external returns (bool _success);
  function allowance(address _owner, address _spender) external view returns (uint256 _value);
  function transfer(address _to, uint256 _value) external returns (bool _success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
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


/*
* The SysCtrl service acts as an interface to manage the smart contract project 
* through secure multisig contracts or DAO-signed timelocks.
*/
contract SysCtrl is Context {

  event Minter(address indexed minter, bool active);

  address public communityDAO;
  bool    public tokenPaused = false;
  uint256 public minTimeRebase = 120;
  mapping (address => bool) public communityMinter;

  constructor() {
      communityDAO = _msgSender();
  }

  modifier onlyDAO() {
    require(_msgSender() == communityDAO, "Only for DAO community");
    _;
  }

  function sDAO(address _new) external onlyDAO {
    communityDAO = _new;
  }

  modifier onlyMinter() {
    require(communityMinter[_msgSender()], "Only for minter contract group");
    _;
  }

  function addMinter(address _new) external onlyDAO {
      communityMinter[_new] = true;
      emit Minter(_new, true);
  }

  function removeMinter(address _remove) external onlyDAO {
      communityMinter[_remove] = false;
      emit Minter(_remove, false);
  }

  modifier notPaused() {
    require(!tokenPaused, "The token market is paused");
    _;
  }

  function pauseMarket(bool _paused) external onlyDAO {
      tokenPaused = _paused;
  }

  function setMinTimeRebase(uint256 _newTime) external onlyDAO {
      minTimeRebase = _newTime;
  }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20, SysCtrl {
  using SafeMath for uint256;

  uint256 public totalSupply;
  uint256 public baseX;
  uint8 public constant DECIMALS = 18;
  mapping (address => uint256) public baseOf;

  mapping (address => mapping (address => uint256)) internal _allowance;

  function approve(address _spender, uint256 _value) public returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return _allowance[_owner][_spender];
  }

  function increaseAllowance(address _spender, uint256 _value) public returns (bool) {
    _approve(msg.sender, _spender, _allowance[msg.sender][_spender].add(_value));
    return true;
  }

  function decreaseAllowance(address _spender, uint256 _value) public returns (bool) {
    _approve(msg.sender, _spender, _allowance[msg.sender][_spender].sub(_value));
    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool _success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
    require(_allowance[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");  
    _allowance[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function _approve(address _owner, address _spender, uint256 _amount) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");
    _allowance[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }

  function _transfer(address _from, address _to, uint256 _value) internal notPaused {
    require(_from != address(0), "ERC20: transfer from the zero address");
    require(_to != address(0), "ERC20: transfer to the zero address");
    require(_to != address(this), "ERC20: transfer to this contract address");
    require(basetoValue(baseOf[_from]) >= _value,"ERC20: insufficient funds to transaction");
    uint256 _base = valuetoBase(_value);
    baseOf[_from] = baseOf[_from].sub(_base);
    baseOf[_to] = baseOf[_to].add(_base);
    emit Transfer(_from, _to, _value);
  }

  function valuetoBase(uint256 _value) public view returns (uint256 base) {
    uint256 fact = (baseX.mul(10**(DECIMALS))).div(totalSupply);
    base = (fact*_value).div(10**(DECIMALS));
  }

  function basetoValue(uint256 _base) public view returns (uint256 value) {
    uint256 fact = (totalSupply.mul(10**(DECIMALS))).div(baseX);
    value = (fact*_base).div(10**(DECIMALS));
  }

  function balanceOf(address _owner) external view returns (uint256 balance) {
     balance = basetoValue(baseOf[_owner]);
  }
}


/**
 * @title ERC20Detailed interface
 */
interface IERC20Detailed {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function decimals() external view returns (uint8 _decimals);
}


/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum/Polygon all the operations are done in wei.
 */
contract ERC20Detailed is ERC20, IERC20Detailed {
  string public name;
  string public symbol;
  uint8 public decimals;
}


/**
 * @title ERC20Mintable token
 * @dev Permission contract to mint and burn tokens through Rebasefy DAO
 * Allowed only for minters declared by DAO, such as internal swap service (swap in DAO protocol)
 */
contract ERC20Mintable is ERC20Detailed  {
  
  using SafeMath for uint256;

  function mint(address _to, uint256 _value) public onlyMinter returns (bool _success) {
    return _mint(_to, _value);
  }

  function _mint(address _to, uint256 _value) internal returns (bool success) {
    uint256 base = valuetoBase(_value);
    baseX = baseX.add(base);
    baseOf[_to] = baseOf[_to].add(base);
    totalSupply = totalSupply.add(_value);
    emit Transfer(_msgSender(), _to, _value);
    return true;
  }

  function yourselfburn(uint256 _value) public returns (bool _success) {
      require(basetoValue(baseOf[_msgSender()]) >= _value);
      return _burn(_msgSender(),_value);
  }

  function burn(address _account, uint256 _value) public onlyMinter returns (bool _success) {
      require(basetoValue(baseOf[_account]) >= _value);
      return _burn(_account,_value);
  }

  function _burn(address _account, uint256 _value) internal returns (bool success) {
    require(_account != address(0));
    uint256 base = valuetoBase(_value);
    baseX = baseX.sub(base);
    baseOf[_account] = baseOf[_account].sub(base);
    totalSupply = totalSupply.sub(_value);
    emit Transfer(_account, _msgSender(), _value);
    return true;
  }
}

/**
 * @title Rebase contract
 * @dev Allows performing the rebase on the contract in accordance with the DAO
 */
contract ERCRebase is ERC20Mintable {
  using SafeMath for uint256;
  event Rebase(address indexed contractDAO, uint256 indexed epoch, uint256 perc, uint256 _value);
  
  uint256 epoch = 0;
  uint256 lastRebase = 0;
  
  function rebase(uint256 _perc) external onlyMinter returns (bool _success) {
    require(_perc > 1 && _perc <= 10000, "the rebase (%) out of range");
    require(lastRebase+minTimeRebase <= block.timestamp, "Short period for rebase");
    return _rebase(_perc);
  }

  function _rebase(uint256 _perc) internal returns (bool success) {
    uint256 amount = totalSupply.div(100000).mul(_perc);    // 3 decimals for percentage
    totalSupply = totalSupply.add(amount);
    emit Rebase(_msgSender(), epoch, _perc, amount);
    epoch++;
    lastRebase = block.timestamp;
    return true;
  }
}

/**
 *  @title TRIANGLE Rebasefy Token (Official)
 *  @dev Initial supply for this token is 1 unit for division-by-zero prevention
 */
contract RebaseToken is ERCRebase {
  using SafeMath for uint256;
  constructor() {
    name = "Triangle Rebasefy Token";
    symbol = "reT";
    decimals = DECIMALS;
    totalSupply = uint256(1).mul(uint256(10)**decimals); // 1 token in totalSupply
    baseX = totalSupply;
    baseOf[address(0x0)] = uint256(1).mul(uint256(10)**decimals); // 1 token distributed to 0x0 for eternity
  }
}