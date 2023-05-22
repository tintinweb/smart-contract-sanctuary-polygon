/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: contracts/DynamiteToken.sol


pragma solidity ^0.8.17;

 
 
abstract contract ERC20{
 
function name() virtual public view returns (string memory);
function symbol() virtual public view returns (string memory);
function decimals() virtual public view returns (uint8);
function totalSupply() virtual public view returns (uint256);
function balanceOf(address _owner) virtual public view returns (uint256 balance);
function transfer(address _to, uint256 _value) virtual public returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
function approve(address _spender, uint256 _value) virtual public returns (bool success);
function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);
function increaseAllowance(address _spender, uint256 _value) public virtual returns (bool);
function decreaseAllowance(address _spender, uint256 _value) public virtual returns (bool);
 
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
event IncreaseAllowance(address indexed _owner, address indexed _spender, uint256 _value);
event DecreaseAllowance(address indexed _owner, address indexed _spender, uint256 _value);
}
 
// Germ Blaster contract
contract DynamiteToken is ERC20, ReentrancyGuard {
  string public _symbol;
  string public _name;
  uint8 public _decimal;
  uint public _totalSupply;
  int public earnSupply;
 
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint256)) allowances;
 
  constructor(){
    _symbol = "DYT"; 
    _name = "Dynamite"; 
    _decimal = 18;
    _totalSupply = 1000000000000000000000000000000;
    balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
}
 
// standard erc20 functions
 
function name() public override view returns (string memory){
  return _name;
}
 
function symbol() public override view returns (string memory){
  return _symbol;
}
 
function decimals() public override view returns (uint8){
  return _decimal;
}
 
function totalSupply() public override view returns (uint256){
  return _totalSupply;
}
 
function balanceOf(address _owner) public override view returns (uint256 balance){
  return balances[_owner];
}
 
function transferFrom(address _from, address _to, uint256 _value) public override nonReentrant() returns (bool success){
  address _spender = msg.sender;
  require(balances[_from] >= _value, "not enough balance");
  require(allowances[_from][_spender] >= _value, "not enough allowance");
  balances[_from] -= _value;
  balances[_to] += _value;
  allowances[_from][_spender] -= _value;
  emit Approval(_from, _spender, _value);
  emit Transfer(_from, _to, _value);
  return true;
}
 
function transfer(address _to, uint256 _value) public override nonReentrant() returns (bool success){
  require(balances[msg.sender] >= _value, "not enough balance");
  balances[msg.sender] -= _value;
  balances[_to] += _value;
  emit Transfer(msg.sender, _to, _value);
  return true;
}
 
function approve(address _spender, uint256 _value) public override nonReentrant() returns (bool success){
  require(msg.sender != address(0), "cannot approve from the zero address");
  require(_spender != address(0), "cannot approve to the zero address");
  allowances[msg.sender][_spender] = _value;
  emit Approval(msg.sender, _spender, _value);
  return true;
}
 
function allowance(address _owner, address _spender) public view override returns (uint256 remaining){
  return allowances[_owner][_spender];
}
 
function decreaseAllowance(address _spender, uint256 _value) public override nonReentrant() returns (bool) {
  require(allowances[msg.sender][_spender] >= _value, "not enough allowance");
  require(msg.sender != address(0), "cannot approve from the zero address");
  require(_spender != address(0), "cannot approve to the zero address");
  allowances[msg.sender][_spender] -= _value;
  emit DecreaseAllowance(msg.sender, _spender, _value);
  return true;
  }
 
function increaseAllowance(address _spender, uint256 _value) public override nonReentrant() returns (bool) {
  require(msg.sender != address(0), "cannot approve from the zero address");
  require(msg.sender != address(0), "cannot approve to the zero address");
  allowances[msg.sender][_spender] += _value;
  emit IncreaseAllowance(msg.sender, _spender, _value);
  return true;
}
}