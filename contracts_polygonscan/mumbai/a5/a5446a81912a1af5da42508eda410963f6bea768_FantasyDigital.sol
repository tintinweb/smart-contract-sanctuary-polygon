/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

pragma solidity ^0.8.9;
// SPDX-License-Identifier: Unlicensed

// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function RenounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function TransferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

contract Pausable is Ownable {
    event pause(bool isPause);

    bool public Paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!Paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(Paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function Pause() public onlyOwner whenNotPaused {
        Paused = true;
        emit pause(Paused);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function Unpause() public onlyOwner whenPaused {
        Paused = false;
        emit pause(Paused);
    }
}


contract FantasyDigital is Context, IERC20, Ownable, Pausable{

    //Token related variables
    uint256 public _totalSupply = 500000000 * 10**18;
    uint256 public maxTxLimit = _totalSupply * (25) / (10000);
    string _name = 'Fantast Token';
    string _symbol = 'FTXXX';
    uint8 _decimals = 18;

    //ERC20 standard variables
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    //Variables related to fees
    mapping (address => uint) private _isTimeLimit;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _excludeFromMaxTxLimit;
    mapping (address => bool) private _excludeFromTimeLimit;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private _FDTeamTax = 200;
    uint256 private _PromoTax= 200;
	uint256 private _BurnTax= 100;
    uint256 private ORIG_TAX_FEE;
    uint256 private ORIG_BURN_FEE;
    uint256 private ORIG_PROMO_FEE;
       
    address private TeamAcc;
    address private PromoAcc;
    address private BurnAcc = 0x000000000000000000000000000000000000dEaD;
	
    struct Fees {uint TeamFee;  uint PromoFee;  uint BurnFee; }

    uint8 public timeLimit = 3;
    
    function name() public view returns (string memory) { return _name;   }

    function symbol() public view returns (string memory) { return _symbol;  }

    function decimals() public view returns (uint8) { return _decimals;   }

    function totalSupply() public view override returns (uint256) {  return _totalSupply;  }

    function balanceOf(address account) public view override returns (uint256) {  return _balances[account];   }
    
    function FDTeamtax() public view returns (uint256) { return _FDTeamTax;  }
    function Promotax() public view returns (uint256) { return _PromoTax;  }
	function Burntax() public view returns (uint256) { return _BurnTax;  }

    function transfer(address recipient, uint256 amount) public virtual override whenNotPaused  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
	function getPromoaddress()  public view returns(address){  return PromoAcc;  }
    function getTeamAddress()  public view returns(address){  return TeamAcc;   }
	function getBurnAddress()  public view returns(address){  return BurnAcc;   }


    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
	function setBurnPercent(uint256 newburnRate) external onlyOwner {
        require(newburnRate <= 100, "RTT: Burn rate too high");
        _BurnTax = newburnRate;
    }
       
	function SetTeamTaxPercent(uint256 teamRate) external onlyOwner() {
        _FDTeamTax = teamRate;
    }
    
    function SetPromoTaxPercent(uint256 promoRate) external onlyOwner() {
        _PromoTax = promoRate;
    }
	
    function excludeFromTimeLimit(address addr) public onlyOwner {
        _excludeFromTimeLimit[addr] = true;
    }
    
    function setTimeLimit(uint8 value) public onlyOwner {
        timeLimit = value;
    }

    function setMaxTXLimit(uint8 value) public onlyOwner {
        maxTxLimit = value;
    }
   
    function ExcludeFromTax(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
     function excludeFromMaxTxLimit(address addr) public onlyOwner {
        _excludeFromMaxTxLimit[addr] = true;
    }
    
    function IncludeInTax(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
	
	function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused  returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount should be greater than zero");
		
        bool takeFee = true;

        if(sender!=owner() && !_excludeFromMaxTxLimit[sender]){
              require(amount <= maxTxLimit, 'Amount exceeds maximum transcation limit!');
           _excludeFromMaxTxLimit[msg.sender] = false; }
        
         if(!_excludeFromTimeLimit[sender]) {
            require(_isTimeLimit[sender] <= block.timestamp, 'Time limit error!');
        }
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            takeFee = false;
        }
		
		if (!takeFee) removeAllFee();
        
        _transferStandard(sender, recipient, amount);
    
        if (!takeFee) restoreAllFee();
		_isTimeLimit[sender] = block.timestamp + (timeLimit * 60);
   
    }
	
	function _transferStandard(address sender, address recipient, uint256 amount) private {
       (uint256 tAmount, uint256 TeamFee, uint256 PromoFee, uint256 BurnFee) = _getCalculatedFees(amount);
	   
        _standardTransferContent(sender, recipient, amount, tAmount);
    		
		_TeamTransfer(sender, TeamFee);
        _PromoTransfer(sender, PromoFee);
		_BurnTransfer(sender, BurnFee);
		
        emit Transfer(sender, recipient, tAmount);
    }
    
    function _standardTransferContent(address sender, address recipient, uint256 amount, uint256 tAmount) private {
		uint256 senderBalance = _balances[sender];
        unchecked {
            _balances[sender] = senderBalance - (amount);
        }
            _balances[recipient] = _balances[recipient] + (tAmount);
		}
 
    function _getCalculatedFees(uint256 amount) internal view returns(  uint256, uint256, uint256, uint256) {
        Fees memory fee;
     
        fee.TeamFee = amount * (_FDTeamTax) / (10000);
        fee.PromoFee = amount * (_PromoTax) / (10000);
		fee.BurnFee = amount * (_BurnTax) / (10000);

        uint256 deductedAmount = amount - (fee.TeamFee + fee.PromoFee + fee.BurnFee);

        return (deductedAmount, fee.TeamFee, fee.PromoFee, fee.BurnFee);
    }
	
    function _TeamTransfer(address sender, uint256 TeamFee) internal {
        if(TeamFee != 0) {
            _balances[TeamAcc] = _balances[TeamAcc] + (TeamFee);
            emit Transfer(sender, TeamAcc, TeamFee);
        }
    }

    function _PromoTransfer(address sender, uint256 PromoFee) internal {
        if(PromoFee != 0) {
            _balances[PromoAcc] = _balances[PromoAcc] + (PromoFee);
            emit Transfer(sender, PromoAcc, PromoFee);
        }
    }
	
	function _BurnTransfer(address sender, uint256 BurnFee) internal {
        if(BurnFee != 0) {
            _balances[BurnAcc] = _balances[BurnAcc] + (BurnFee);
            emit Transfer(sender, BurnAcc, BurnFee);
        }
    }
	
   function TransferOwnership(address newOwner) public override virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
	
	function removeAllFee() private {
        if(_FDTeamTax == 0 && _BurnTax == 0 && _PromoTax == 0) return;
        
        ORIG_TAX_FEE = _FDTeamTax;
        ORIG_BURN_FEE = _BurnTax;
        ORIG_PROMO_FEE = _PromoTax;
        
        _FDTeamTax = 0;
        _BurnTax = 0;
        _PromoTax = 0;
    }
    
    function restoreAllFee() private {
        _FDTeamTax = ORIG_TAX_FEE;
        _BurnTax = ORIG_BURN_FEE;
        _PromoTax = ORIG_PROMO_FEE;
    }

    constructor(address _PromoAcc, address _TeamAcc) {
    _balances[msg.sender] = _totalSupply;
        
        TeamAcc = _TeamAcc;
        PromoAcc = _PromoAcc;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[TeamAcc] = true;
        _isExcludedFromFee[PromoAcc] = true;
        _excludeFromMaxTxLimit[msg.sender] = true;
        _excludeFromMaxTxLimit[TeamAcc] = true;
        _excludeFromMaxTxLimit[PromoAcc] = true;
        _excludeFromTimeLimit[msg.sender] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
       _excludeFromTimeLimit[address(this)] = true;
    }
    function SetPromoAddress( address NewPromoAcc) external onlyOwner{
        PromoAcc=NewPromoAcc;
    }
   function SetTeamAddress (address NewTeamAcc) external onlyOwner{
       TeamAcc=NewTeamAcc;
   }
}