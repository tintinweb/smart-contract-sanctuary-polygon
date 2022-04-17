/**
 *Submitted for verification at polygonscan.com on 2022-04-16
*/

/**

Dukecoin is not a Meme Coin. It is a new payment ecosystem that deploys a digital currency and makes innovative use of blockchain technology. 
Digital Currency also known as “Cryptocurrency” which is a form of digital asset based on a network that is distributed across a large number of computers. 
This decentralized structure allows them to exist outside the control of governments and central authorities

Website : https://dukecoin.co/

Whitepaper : https://dukecoin.co/DUKECOINwhitepaper12.pdf

Facebook : https://www.facebook.com/Duke-Coin-109529568009863/

Twitter : https://twitter.com/Dukecoin2?s=08

Instagram : https://www.instagram.com/dukecoinofficial?r=nametag

Telegram : https://t.me/dukecoin

Github : https://github.com/dukecoin

Publish Date : 14th April 2022


*/

pragma solidity 0.5.16;

interface IPOLY20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {

  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract POLY20Token is Context, IPOLY20, Ownable {

  event Pause();
  event Unpause();

  bool public autoReflection = false;

  bool public paused = false;
  bool public canPause = true;

  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => bool) private _isIncludedForFee;

  mapping (address => bool) private _isExcludeForRefelection;

  address[] public tokenHolders;
  
  mapping (address => bool) public reflectionpoolEligible;

  uint256 private _totalSupply;
  uint256 constant private perDistribution = 100;

  uint8 public _decimals;
  string public _symbol;
  string public _name;

  uint256 public _reflectionsPer;
  uint256 public _reflectionsCollected;
  uint256 public _reflectionsDistributed;
  uint256 public _reflectionsAvailable;

  address public _marketingWalletAddress;
  uint256 public _marketingPer;
  uint256 public _marketingCollected;

  address public _liquidityWalletAddress;
  uint256 public _liquidityPer;
  uint256 public _liquidityCollected;

  uint256 public _burnPer;
  uint256 public _totalAutoBurn;

  constructor() public {
    _name = "Duke Coin";
    _symbol = "DKC";
    _decimals = 18;
    _totalSupply = 100000000000000000000000000;
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {POLY20-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {POLY20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {POLY20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {POLY20-allowance}.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {POLY20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {POLY20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {POLY20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    require(paused != true, "Duke Coin: Coin Is Paused now");
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "POLY20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {POLY20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {POLY20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "POLY20: decreased allowance below zero"));
    return true;
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   */
  function burn(uint256 amount) public returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }


   /**
     * @dev called by the owner to pause, triggers stopped state
   **/
   
   function pause() onlyOwner public {
        require(canPause == true);
        paused = true;
        emit Pause();
   } 
   
   /**
   * @dev called by the owner to unpause, returns to normal state
   */
    
    function unpause() onlyOwner public {
        require(paused == true);
        paused = false;
        emit Unpause();
    }

    function update_reflectionsPer(uint256 reflectionsPer) external {
         require(owner() == msg.sender, 'Admin what?');
        _reflectionsPer = reflectionsPer;
    }

    function update_marketingWalletAddress(address marketingWalletAddress) external {
        require(owner() == msg.sender, 'Admin what?');
        _marketingWalletAddress = marketingWalletAddress;
    }

    function update_marketingPer(uint256 marketingPer) external {
        require(owner() == msg.sender, 'Admin what?');
        _marketingPer = marketingPer;
    }

    function update_liquidityWalletAddress(address liquidityWalletAddress) external {
        require(owner() == msg.sender, 'Admin what?');
        _liquidityWalletAddress = liquidityWalletAddress;
    }

    function update_liquidityPer(uint256 liquidityPer) external {
        require(owner() == msg.sender, 'Admin what?');
        _liquidityPer = liquidityPer;
    }

    function update_burnPer(uint256 burnPer) external {
        require(owner() == msg.sender, 'Admin what?');
        _burnPer = burnPer;
    }

    function isIncludedForFee(address account) public view returns(bool) {
        return _isIncludedForFee[account];
    }

    function updateAutoRefelectionStatus(bool status) public onlyOwner{
        autoReflection=status;
    }
   
    function excludeFromFee(address account) public onlyOwner {
        _isIncludedForFee[account] = false;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isIncludedForFee[account] = true;
    }

    function isExcludedForReflection(address account) public view returns(bool) {
        return _isExcludeForRefelection[account];
    }

    function excludeFromReflection(address account) public onlyOwner {
        _isExcludeForRefelection[account] = true;
    }
    
    function includeInReflection(address account) public onlyOwner {
        _isExcludeForRefelection[account] = false;
    }

    function _verifyReflection(uint256 _amount) public onlyOwner {
     if(_amount<=_reflectionsAvailable)
     {
      if(tokenHolderCount() > 0){
      for(uint8 i = 0; i < tokenHolderCount(); i++) {
         address _tokenHolder = tokenHolders[i];
         if(reflectionpoolEligible[_tokenHolder] &&  !_isExcludeForRefelection[_tokenHolder])
         {
            uint256 _tokenHolderSharePer=(_balances[_tokenHolder].mul(perDistribution)).div(_totalSupply);
            uint256 _tokenHolderShare=_amount.mul(_tokenHolderSharePer).div(perDistribution);            
            _reflectionsDistributed=_reflectionsDistributed.add(_tokenHolderShare);
            _reflectionsAvailable=_reflectionsAvailable.sub(_tokenHolderShare);
            _balances[_tokenHolder] = _balances[_tokenHolder].add(_tokenHolderShare); 
         }
       }
      }
     }
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "POLY20: transfer from the zero address");
    require(recipient != address(0), "POLY20: transfer to the zero address");
    require(paused != true, "Duke Coin: Coin Is Paused now");

    //indicates if fee should be deducted from transfer
    bool takeFee = false;
        
    //if any account belongs to _isIncludedForFee account then take the fee start Fee Here

    //If User Coin Buy Then Sender Will Will Be Router Address of Any Defi Exchange
    if(_isIncludedForFee[sender]){
      takeFee = true;
    }
    //If User Coin Sell Then Receiver Will Will Be Router Address of Any Defi Exchange
    if(_isIncludedForFee[recipient]){
      takeFee = true;
    }

    //if any account belongs to _isIncludedForFee account then take the fee end Fee Here

     uint256 netamount=amount;

    if(takeFee == true) {

      uint256 _reflectionsValue = calculatereflectionsValue(amount);
      uint256 _marketingValue = calculatemarketingValue(amount);
      uint256 _liquidityValue = calculateliquidityValue(amount);
      uint256 _burnValue = calculateburnValue(amount);

      netamount=netamount.sub(_reflectionsValue);
      netamount=netamount.sub(_marketingValue);
      netamount=netamount.sub(_liquidityValue);
      netamount=netamount.sub(_burnValue);

      _balances[sender] = _balances[sender].sub(amount, "POLY20: transfer amount exceeds balance");

      _marketingCollected=_marketingCollected.add(_marketingValue);
      _liquidityCollected=_liquidityCollected.add(_liquidityValue);
      _reflectionsCollected=_reflectionsCollected.add(_reflectionsValue);
      _reflectionsAvailable=_reflectionsAvailable.add(_reflectionsValue);
      _totalAutoBurn=_totalAutoBurn.add(_burnValue);

      _balances[_marketingWalletAddress]=_balances[_marketingWalletAddress].add(_marketingValue); 
      _balances[_liquidityWalletAddress]=_balances[_liquidityWalletAddress].add(_liquidityValue); 
      if(autoReflection)
      {
        _reflection(_reflectionsValue);
      }
      _totalSupply = _totalSupply.sub(_burnValue);

      _balances[recipient] = _balances[recipient].add(netamount);


    }
    else {

      _balances[sender] = _balances[sender].sub(amount, "POLY20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);  

    }

    
    //Sender Reflection Eligibility Status
    if(_balances[sender]>0) {
        if(!reflectionpoolEligible[sender]){
            reflectionpoolEligible[sender] = true;
            tokenHolders.push(sender);
        }
    }
    else {
          reflectionpoolEligible[sender] = false;
    }

    //Receiver Reflection Eligibility Status
    if(_balances[recipient]>0) {
        if(!reflectionpoolEligible[recipient]){
          reflectionpoolEligible[recipient] = true;
          tokenHolders.push(recipient);
        }
    }
    else {
          reflectionpoolEligible[recipient] = false;
    }

    emit Transfer(sender, recipient, amount);

  }

  function _reflection(uint256 _reflectionsValue) internal {
      if(tokenHolderCount() > 0){
      for(uint8 i = 0; i < tokenHolderCount(); i++) {
         address _tokenHolder = tokenHolders[i];
         if(reflectionpoolEligible[_tokenHolder] && !_isExcludeForRefelection[_tokenHolder])
         {
            uint256 _tokenHolderSharePer=(_balances[_tokenHolder].mul(perDistribution)).div(_totalSupply);
            uint256 _tokenHolderShare=_reflectionsValue.mul(_tokenHolderSharePer).div(perDistribution);            
            _reflectionsDistributed=_reflectionsDistributed.add(_tokenHolderShare);
            _reflectionsAvailable=_reflectionsAvailable.sub(_tokenHolderShare);
            _balances[_tokenHolder] = _balances[_tokenHolder].add(_tokenHolderShare); 
         }
       }
     }
  }

  function tokenHolderCount() public view returns(uint) {
    return tokenHolders.length;
  }

  function calculatereflectionsValue(uint256 _amount) private view returns (uint256) {
     return _amount.mul(_reflectionsPer).div(perDistribution);
  }

  function calculatemarketingValue(uint256 _amount) private view returns (uint256) {
     return _amount.mul(_marketingPer).div(perDistribution);
  }

  function calculateliquidityValue(uint256 _amount) private view returns (uint256) {
     return _amount.mul(_liquidityPer).div(perDistribution);
  }

  function calculateburnValue(uint256 _amount) private view returns (uint256) {
     return _amount.mul(_burnPer).div(perDistribution);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "POLY20: mint to the zero address");
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "POLY20: burn from the zero address");
    _balances[account] = _balances[account].sub(amount, "POLY20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(paused != true, "Duke Coin: Coin Is Paused now");
    require(owner != address(0), "POLY20: approve from the zero address");
    require(spender != address(0), "POLY20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "POLY20: burn amount exceeds allowance"));
  }

}