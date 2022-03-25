/**
 *Submitted for verification at polygonscan.com on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library SafeMath {  function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b;  require(c >= a, "SafeMath: addition overflow");  return c; }    /**@dev Returns the addition of two unsigned integers, reverting on overflow. Counterpart to Solidity's `+` operator. Requirements: - Addition cannot overflow. */
                    function sub(uint256 a, uint256 b) internal pure returns (uint256) { return sub(a, b, "SafeMath: subtraction overflow"); }  /** @dev Returns the subtraction of two unsigned integers, reverting on overflow (when the result is negative). Counterpart to Solidity's `-` operator. Requirements: - Subtraction cannot overflow. */
                    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b <= a, errorMessage); uint256 c = a - b; return c; } /**@dev Returns the subtraction of two unsigned integers, reverting with custom message on overflow (when the result is negative).* Counterpart to Solidity's `-` operator. Requirements: * - Subtraction cannot overflow. */
                    function subz(uint256 a, uint256 b) internal pure returns (uint256) {if (b >= a) {return 0;} uint256 c = a - b;return c;}
                    function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {  return 0;} uint256 c = a * b;  require(c / a == b, "SafeMath: multiplication overflow"); return c;}   /**@dev Returns the multiplication of two unsigned integers, reverting on overflow. Counterpart to Solidity's `*` operator. Requirements: - Multiplication cannot overflow.*/// Gas optimization: this is cheaper than requiring 'a' not being zero, but the benefit is lost if 'b' is also tested. See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
                    function div(uint256 a, uint256 b) internal pure returns (uint256) {return div(a, b, "SafeMath: division by zero");}  /**@dev Returns the integer division of two unsigned integers. Reverts on division by zero. The result is rounded towards zero. Counterpart to Solidity's `/` operator. Note: this function uses a`revert` opcode (which leaves remaining gas untouched) while Solidity uses an invalid opcode to revert (consuming all remaining gas). Requirements: - The divisor cannot be zero. */
                    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {  require(b > 0, errorMessage); // Solidity only automatically asserts when dividing by 0
                                                                                                    uint256 c = a / b; // assert(a == b * c + a % b); // There is no case in which this doesn't hold
                                                                                                    return c;}  /** @dev Returns the integer division of two unsigned integers. Reverts with custom message on division by zero. The result is rounded towards zero.Counterpart to Solidity's `/` operator. Note: this function uses a `revert` opcode (which leaves remaining gas untouched) while Solidity uses an invalid opcode to revert (consuming all remaining gas). Requirements: - The divisor cannot be zero.*/
                    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return mod(a, b, "SafeMath: modulo by zero");}      /** @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), Reverts when dividing by zero. Counterpart to Solidity's `%` operator. This function uses a `revert` opcode (which leaves remaining gas untouched) while Solidity uses an invalid opcode to revert (consuming all remaining gas). Requirements: - The divisor cannot be zero.*/
                    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {require(b != 0, errorMessage);return a % b;}  /**@dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), Reverts with custom message when dividing by zero. Counterpart to Solidity's `%` operator. This function uses a `revert` opcode (which leaves remaining gas untouched) while Solidity uses an invalid opcode to revert (consuming all remaining gas). Requirements: - The divisor cannot be zero.*/
}

contract StableIncomeSystem  {
    using SafeMath for uint256;


  bool public paused = false;
  bool public canPause = true;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    address private _owner;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    
    uint256 internal _totalSupply;



    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);  //10^26^26^26
    uint256 public constant BURN_RATE = 200;  //per 10000
    
    uint256 private constant _tTotal = 1 * 10**8 * 10**18;  //10^26
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private rBurned;

    string public constant name = 'SIS Token';
    string public constant symbol = 'SIS';
    uint8 public constant decimals = 18;
    string public constant network = 'Polygon';
    string public constant baseCurrency = 'Matic';
    
    uint256 public _maxTxAmount = 50000000 * 10**6 * 10**9;
    mapping(address => bool) private _isBot;
    address[] private _confirmedBots;




    uint256 private constant PRIMARY_BENEFICIARY_INVESTMENT_PERC = 100;
    uint256 private constant PRIMARY_BENEFICIARY_REINVESTMENT_PERC = 60;
    uint256 public constant PLAN_TERM = 80 days;

    uint256 public constant MIN_WITHDRAW = 0.4 ether;
    uint256 public constant MIN_INVESTMENT = 1 ether;
    uint256 public constant TIME_STEP = 7 days;
    // uint256 private constant TIME_STEP = 10; //fast test mode
    uint256 public constant DAILY_INTEREST_RATE = 20;
    uint256 public constant DAILY_AUTO_REINVEST_RATE = 200;
    uint256 public constant ON_WITHDRAW_AUTO_REINVEST_RATE = 200;
	uint256 private constant PERCENTS_DIVIDER = 1000;
	uint256 private constant TOTAL_RETURN = 1000;
	uint256 public constant TOTAL_REF = 100;
	uint256[] public REFERRAL_PERCENTS = [50, 40, 30, 20, 10];
    uint256 private constant TOTAL_DIVIDER = 100000000000000000000000000;

    address payable private primaryBENEFICIARY;

    uint256 public totalInvested;
    uint256 public totalWithdrawal;
    uint256 public totalReinvested;
    uint256 public totalReferralReward;

    struct Investor {
        address addr;
        address ref;
        uint256[5] refs;
        uint256 totalDeposit;
        uint256 totalWithdraw;
        uint256 totalReinvest;
        uint256 dividends;
        uint256 totalRef;
        uint256 investmentCount;
		uint256 depositTime;
		uint256 lastWithdrawDate;
    }
    struct InvestorInvestment {
        Investment[] investmentslist;
    }
    struct Investment {
        uint256 investmentDate;
        uint256 investment;
        uint256 dividendCalculatedDate;
        bool isExpired;
        uint256 lastWithdrawalDate;
        uint256 dividends;
        uint256 withdrawn;
    }

    mapping(address => mapping (uint256 => uint256)) public myReferralReward;
    mapping(address => Investor) public investors;
    mapping(address => InvestorInvestment)  investorinvestments;
    mapping(address => Investment) investments;


  event Pause();
  event Unpause();
  event NotPausable();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Buy(address indexed account, uint256 value);  /***@dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`). Note that `value` may be zero.  */
    event Sell(address indexed account, uint256 value);  /***@dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`). Note that `value` may be zero.  */
    event Transfer(address indexed from, address indexed to, uint256 value);  /***@dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`). Note that `value` may be zero.  */
    event Approval(address indexed owner, address indexed spender, uint256 value);  /** @dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance. */

    event Burn(address indexed from, address indexed to, uint256 value); 
    event OnInvest(address investor, uint256 amount);
    event OnReinvest(address investor, uint256 amount);
	event OnWithdraw(address investor, uint256 amount); 


    modifier nonReentrant() {require(_status != _ENTERED, "Reentrant call");    _status = _ENTERED;  _;  _status = _NOT_ENTERED;}

    receive() external  payable {}
    fallback() external  payable {invest(bytesToAddress(msg.data));}
    constructor(address payable _primaryAddress ) {
                _status = _NOT_ENTERED;
                address msgSender = _msgSender(); _owner = msgSender; emit OwnershipTransferred(address(0), msgSender); 
                require( _primaryAddress != address(0), "Primary address cannot be null" ); primaryBENEFICIARY = _primaryAddress; 
                _rOwned[address(this)] = _rTotal;   emit Transfer(address(0), address(this), _tTotal);}

    modifier whenNotPaused() {require(!paused || msg.sender == owner()); _;}
    modifier whenPaused() {require(paused); _;}
    function pause() onlyOwner whenNotPaused public {require(canPause == true); paused = true; emit Pause();}
    function unpause() onlyOwner whenPaused public {require(paused == true); paused = false; emit Unpause();}
    function notPausable() onlyOwner public{paused = false; canPause = false; emit NotPausable();}

    function _msgSender() internal view virtual returns (address payable) {return payable(msg.sender);}
    function _msgData() internal view virtual returns (bytes memory) {this;  return msg.data;}



    function owner() public view returns (address) { return _owner;}                                  /** @dev Returns the address of the current owner.*/
    modifier onlyOwner() {require(_owner == _msgSender(), "Ownable: caller is not the owner"); _; }   /**@dev Throws if called by any account other than the owner.*/
    function renounceOwnership() public onlyOwner { emit OwnershipTransferred(_owner, address(0));_owner = address(0);}  /** @dev Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*/
    function transferOwnership(address newOwner) public onlyOwner {_transferOwnership(newOwner);}  /** @dev Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner. */
    function _transferOwnership(address newOwner) internal {require(newOwner != address(0), "Ownable: new owner is the zero address");emit OwnershipTransferred(_owner, newOwner); _owner = newOwner;}  /**@dev Transfers ownership of the contract to a new account (`newOwner`).*/


 
    function getOwner() external view virtual returns (address) { return owner();}
    function allowance(address holder, address spender) external virtual view returns (uint256) {return _allowances[holder][spender];}
    function approve(address spender, uint256 value) external virtual whenNotPaused returns (bool) {_approve(msg.sender, spender, value);return true;}

    function increaseAllowance(address spender, uint256 addedValue) external virtual whenNotPaused returns (bool) {_approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));return true;}
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual whenNotPaused returns (bool) {_approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));return true;}
    function _mint(address account, uint256 value) internal virtual {require(account != address(0));_totalSupply = _totalSupply.add(value);_balances[account] = _balances[account].add(value);emit Transfer(address(0), account, value);}
    function _burn(address account, uint256 value) internal virtual {require(account != address(0));_totalSupply = _totalSupply.sub(value);_balances[account] = _balances[account].sub(value);emit Transfer(account, address(0), value);}
    function _approve(address holder, address spender, uint256 value) internal virtual {require(spender != address(0));require(holder != address(0));_allowances[holder][spender] = value;emit Approval(holder, spender, value);}
    function _burnFrom(address account, uint256 value) internal virtual {_burn(account, value);_approve(account, msg.sender, _allowances[account][msg.sender].sub(value));}




    function totalSupply() external view virtual returns (uint256) { return _tTotal-totalBurned();}
    function balanceOf(address account) public view virtual returns (uint256) {if (_isExcluded[account]) return _tOwned[account];  return tokenFromReflection(_rOwned[account]);}
    
    function totalBurned() public  virtual view returns (uint256) {return tokenFromReflection(rBurned);}
    function transfer(address recipient, uint256 amount) public virtual whenNotPaused  returns (bool) {_transfer(_msgSender(), recipient, amount);return true;}

    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        require(amount <= _allowances[sender][_msgSender()], "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }
    function isExcluded(address account) public  virtual view returns (bool) {return _isExcluded[account];}
    function totalFees() public  virtual view returns (uint256) {return _tFeeTotal;}
    function setMaxTxPercent(uint256 maxTxPercent) external virtual  onlyOwner() {_maxTxAmount = ((_tTotal * maxTxPercent) / 10**2);}
    function setMaxTxAmount(uint256 maxTxAmount) external  virtual onlyOwner() {_maxTxAmount = maxTxAmount;}

    function reflect(uint256 tAmount) public  virtual {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public  virtual view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public  virtual view returns(uint256) {require(rAmount <= _rTotal, "Amount must be less than total reflections"); uint256 currentRate =  _getRate(); return (rAmount / currentRate);}

    function excludeFromReward(address account)  virtual external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account)  virtual external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(sender != owner() && recipient != owner()) {
          require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
          require(!_isBot[sender], 'Bots not allowed here!');
          require(!_isBot[recipient], 'Bots not allowed here!');
        }
            
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount - (((rAmount).div(20000)).mul(BURN_RATE));
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount - (((rAmount).div(20000)).mul(BURN_RATE));      
        _reflectFee(rFee, tFee); 
        rBurned = rBurned + (((rAmount).div(20000)).mul(BURN_RATE));
        emit Burn(sender, recipient, ((rAmount).div(20000)).mul(BURN_RATE));
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount - (((rAmount).div(20000)).mul(BURN_RATE));
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount - (((tAmount).div(20000)).mul(BURN_RATE));
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount - (((rAmount).div(20000)).mul(BURN_RATE));           
        _reflectFee(rFee, tFee);
        rBurned = rBurned + (((rAmount).div(20000)).mul(BURN_RATE));
        emit Burn(sender, recipient, ((rAmount).div(20000)).mul(BURN_RATE));
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount - (((tAmount).div(20000)).mul(BURN_RATE));
        _rOwned[sender] = _rOwned[sender] - rAmount - (((rAmount).div(20000)).mul(BURN_RATE));
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount - (((rAmount).div(20000)).mul(BURN_RATE));   
        _reflectFee(rFee, tFee);
        rBurned = rBurned + (((rAmount).div(20000)).mul(BURN_RATE));
        emit Burn(sender, recipient, ((rAmount).div(20000)).mul(BURN_RATE));
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount - (((tAmount).div(20000)).mul(BURN_RATE));
        _rOwned[sender] = _rOwned[sender] - rAmount - (((rAmount).div(20000)).mul(BURN_RATE));
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount - (((tAmount).div(20000)).mul(BURN_RATE));
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount - (((rAmount).div(20000)).mul(BURN_RATE));        
        _reflectFee(rFee, tFee);
        rBurned = rBurned + (((rAmount).div(20000)).mul(BURN_RATE));
        emit Burn(sender, recipient, ((rAmount).div(20000)).mul(BURN_RATE));
        emit Transfer(sender, recipient, tTransferAmount);
    }
     

    function _reflectFee(uint256 rFee, uint256 tFee) private {_rTotal = _rTotal - rFee;_tFeeTotal = _tFeeTotal + tFee;}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tFee = ((tAmount / 100) * 2);
        uint256 tTransferAmount = tAmount - tFee;
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();return (rSupply / tSupply);}

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < (_rTotal / _tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function isBot(address account) public  virtual view returns (bool) {return _isBot[account];}
    
    function _blacklistBot(address account) external onlyOwner() {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We cannot blacklist Pancakeswap');
        require(!_isBot[account], "Account is already blacklisted");
        _isBot[account] = true;
        _confirmedBots.push(account);
    }

    function _amnestyBot(address account) external onlyOwner() {
        require(_isBot[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _confirmedBots.length; i++) {
            if (_confirmedBots[i] == account) {
                _confirmedBots[i] = _confirmedBots[_confirmedBots.length - 1];
                _isBot[account] = false;
                _confirmedBots.pop();
                break;
            }
        }
    }



    function changePrimaryBeneficiary(address payable newAddress) public onlyOwner {require(newAddress != address(0), "Address cannot be null"); primaryBENEFICIARY = newAddress;}

    function invest() public payable whenNotPaused  {if (_invest(msg.sender, primaryBENEFICIARY, msg.value)) {emit OnInvest(msg.sender, msg.value);}} 
    function invest(address _ref) public payable whenNotPaused  {if (_invest(msg.sender, _ref, msg.value)) {emit OnInvest(msg.sender, msg.value);}}
    
    function getBalance() public view returns (uint256) {return address(this).balance;}
    function bytesToAddress(bytes memory bys) private pure returns (address addr) { assembly {addr := mload(add(bys,20))} }

    function _invest(address _addr, address _ref, uint256 _amount ) private returns (bool){
        require(_amount >= MIN_INVESTMENT, "Minimum investment is 1 Matic");
        require(_ref != _addr, "Ref address cannot be same with caller");

        Investor storage _investor = investors[_addr];
        if (_investor.addr == address(0)) {
            _investor.addr = _addr;
            _investor.depositTime = block.timestamp;
            _investor.lastWithdrawDate = block.timestamp;
        }

        if (_investor.ref == address(0)) {
				_investor.ref = _ref;

			address upline = _investor.ref;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
                   investors[upline].refs[i] =investors[upline].refs[i].add(1);
					upline = investors[upline].ref;
				} else break;
			}
		}

		if (_investor.ref != address(0)) {
			address upline = _investor.ref;
			for (uint256 i = 1; i < 6; i++) {
				if (upline != address(0)) {
					uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					investors[upline].totalRef = investors[upline].totalRef.add(amount);
        myReferralReward[upline][0] = myReferralReward[upline][0].add(amount);
        myReferralReward[upline][i] = myReferralReward[upline][i].add(amount);
					totalReferralReward = totalReferralReward.add(amount);
					payable(upline).transfer(amount);
					upline = investors[upline].ref;
				} else break;
			}
		}else{
			uint256 amount = _amount.mul(TOTAL_REF).div(PERCENTS_DIVIDER);
        myReferralReward[primaryBENEFICIARY][0] = myReferralReward[primaryBENEFICIARY][0].add(amount);
			primaryBENEFICIARY.transfer(amount);
			totalReferralReward = totalReferralReward.add(amount);
		}

        if(block.timestamp > _investor.depositTime){_investor.dividends = getDividends(_addr);}
        _investor.depositTime = block.timestamp;
        _investor.investmentCount = _investor.investmentCount.add(1);
        _investor.totalDeposit = _investor.totalDeposit.add(_amount);
        totalInvested = totalInvested.add(_amount);

        investorinvestments[_addr].investmentslist.push(
            Investment({investmentDate: block.timestamp,
                        investment: _amount,
                        dividendCalculatedDate: block.timestamp,
                        lastWithdrawalDate: block.timestamp,
                        isExpired: false,
                        dividends: 0,
                        withdrawn: 0}));

        _sendRewardOnInvestment(_amount);
        uint256 tokensupply = balanceOf(address(this));
        if(tokensupply >= _amount) {
                                    this.transfer(primaryBENEFICIARY, (_amount).mul(this.totalSupply()).mul(10).div(TOTAL_DIVIDER).div(100));
                                    this.transfer(_addr, (_amount).mul(this.totalSupply()).div(TOTAL_DIVIDER));}
        else if(tokensupply >= 0 && tokensupply < _amount){
                                    this.transfer(primaryBENEFICIARY, tokensupply.mul(10).div(100));
                                    this.transfer(_addr, tokensupply);}
        return true;
    }

    function _reinvest(address _addr,uint256 _amount) private returns(bool){
        Investor storage _investor = investors[_addr];
        require(_investor.totalDeposit > 0, "not active user");

        if(block.timestamp > _investor.depositTime){_investor.dividends = getDividends(_addr);}
        _investor.totalDeposit = _investor.totalDeposit.add(_amount);
        _investor.totalReinvest = _investor.totalReinvest.add(_amount);
        totalReinvested = totalReinvested.add(_amount);

        investorinvestments[_addr].investmentslist.push(
            Investment({
                investmentDate: block.timestamp,
                investment: _amount,
                dividendCalculatedDate: block.timestamp,
                lastWithdrawalDate: block.timestamp,
                isExpired: false,
                dividends: 0,
                withdrawn: 0}));

        uint256 tokensupply = balanceOf(address(this));
        if(tokensupply >= _amount) {
                                    this.transfer(primaryBENEFICIARY, (_amount).mul(this.totalSupply()).mul(5).div(TOTAL_DIVIDER).div(100));
                                    this.transfer(_addr, (_amount).mul(this.totalSupply()).div(TOTAL_DIVIDER));}
        else if(tokensupply >= 0 && tokensupply < _amount){
                                    this.transfer(primaryBENEFICIARY, tokensupply.mul(5).div(100));
                                    this.transfer(_addr, tokensupply);}
        _sendRewardOnReinvestment(_amount);
        return true;
    }

    function _sendRewardOnInvestment(uint256 _amount) private {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 rewardForPrimaryBENEFICIARY = _amount.mul(PRIMARY_BENEFICIARY_INVESTMENT_PERC).div(1000);
        primaryBENEFICIARY.transfer(rewardForPrimaryBENEFICIARY);
    }
    
    function _sendRewardOnReinvestment(uint256 _amount) private {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 rewardForPrimaryBENEFICIARY = _amount.mul(PRIMARY_BENEFICIARY_REINVESTMENT_PERC).div(1000);
        primaryBENEFICIARY.transfer(rewardForPrimaryBENEFICIARY);
    }

    function payoutOf(address _addr) view public returns(uint256 payout, uint256 max_payout) {
        max_payout = investors[_addr].totalDeposit.mul(TOTAL_RETURN).div(PERCENTS_DIVIDER);

        if(investors[_addr].totalWithdraw < max_payout && block.timestamp > investors[_addr].depositTime) {
            payout = investors[_addr].totalDeposit.mul(DAILY_INTEREST_RATE).mul(block.timestamp.sub(investors[_addr].depositTime)).div(
                TIME_STEP.mul(PERCENTS_DIVIDER)
            );
            payout = payout.add(investors[_addr].dividends);

            if(investors[_addr].totalWithdraw.add(payout) > max_payout) {payout = max_payout.subz(investors[_addr].totalWithdraw);}
        }
    }

    function getDividends(address addr) public view returns (uint256) {
        uint256 dividendAmount = 0;
        (dividendAmount,) = payoutOf(addr);
        return dividendAmount;    }


    function getInvestments(address addr) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory)
        {InvestorInvestment storage investorinvestment = investorinvestments[addr];
        uint256[] memory investmentDates = new uint256[](investorinvestment.investmentslist.length);
        uint256[] memory investmentslist = new uint256[](investorinvestment.investmentslist.length);
        uint256[] memory withdrawn = new uint256[](investorinvestment.investmentslist.length);
        bool[] memory isExpireds = new bool[](investorinvestment.investmentslist.length);
        for (uint256 i; i < investorinvestment.investmentslist.length; i++) {
            require(investorinvestment.investmentslist[i].investmentDate != 0, "wrong investment date");
            withdrawn[i] = investorinvestment.investmentslist[i].withdrawn;
            investmentDates[i] = investorinvestment.investmentslist[i].investmentDate;
            investmentslist[i] = investorinvestment.investmentslist[i].investment;
            if (investorinvestment.investmentslist[i].isExpired) {isExpireds[i] = true;} 
            else {isExpireds[i] = false;
                  if (PLAN_TERM > 0) {if (block.timestamp >= investorinvestment.investmentslist[i].investmentDate.add(PLAN_TERM)) {isExpireds[i] = true;}}}}
        return (investmentDates, investmentslist, withdrawn, isExpireds);}

    function getContractInformation() public view returns (uint256, uint256, uint256, uint256, uint256)
        {   uint256 contractBalance = getBalance();
            return (contractBalance, totalInvested, totalWithdrawal, totalReinvested, totalReferralReward);
    }
    
    function reinvest() public whenNotPaused  {
		require(investors[msg.sender].lastWithdrawDate.add(TIME_STEP) <= block.timestamp,"Withdrawal limit is 1 withdrawal in 7 days");
        uint256 dividendAmount = getDividends(msg.sender);
        uint256 _amountToReinvest = dividendAmount.mul(DAILY_AUTO_REINVEST_RATE).div(1000);        //10% daily reinvestment
        _reinvest(msg.sender, _amountToReinvest);
        investors[msg.sender].lastWithdrawDate = block.timestamp;
		investors[msg.sender].depositTime = block.timestamp;  
    }

    function withdraw() public nonReentrant whenNotPaused {
		require(investors[msg.sender].lastWithdrawDate.add(TIME_STEP) <= block.timestamp,"Withdrawal limit is 1 withdrawal in 7 days");
        uint256 _amountToReinvest=0;
		uint256 _reinvestAmount=0;
		uint256 totalToReinvest=0;
        uint256 max_payout = investors[msg.sender].totalDeposit.mul(TOTAL_RETURN).div(PERCENTS_DIVIDER);
        uint256 dividendAmount = getDividends(msg.sender);

        if(investors[msg.sender].totalWithdraw.add(dividendAmount) > max_payout) {
                dividendAmount = max_payout.subz(investors[msg.sender].totalWithdraw);
        }

        require(dividendAmount >= MIN_WITHDRAW, "Min withdraw amount is 0.4 matic");
        _amountToReinvest = dividendAmount.mul(DAILY_AUTO_REINVEST_RATE).div(1000);        //25% daily reinvestment
        _reinvestAmount = dividendAmount.mul(ON_WITHDRAW_AUTO_REINVEST_RATE).div(1000);        //25% reinvest on withdraw
        totalToReinvest = _amountToReinvest.add(_reinvestAmount);
        _reinvest(msg.sender, totalToReinvest);
        uint256 remainingAmount = dividendAmount.subz(_reinvestAmount);
        totalWithdrawal = totalWithdrawal.add(remainingAmount);
        if(remainingAmount > getBalance()){remainingAmount = getBalance();}

        investors[msg.sender].totalWithdraw = investors[msg.sender].totalWithdraw.add(dividendAmount);
		investors[msg.sender].lastWithdrawDate = block.timestamp;
		investors[msg.sender].depositTime = block.timestamp;
		investors[msg.sender].dividends = 0;

        payable(msg.sender).transfer(remainingAmount);
		emit OnWithdraw(msg.sender, remainingAmount);
    }
    
    function getInvestorRefs(address addr) public view returns (uint256, uint256, uint256, uint256, uint256)
    {   Investor storage investor = investors[addr];
        return (investor.refs[0], investor.refs[1], investor.refs[2], investor.refs[3], investor.refs[4]);
    }
}