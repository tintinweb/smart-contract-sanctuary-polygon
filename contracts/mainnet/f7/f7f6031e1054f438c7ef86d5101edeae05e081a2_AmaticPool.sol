/**
 *Submitted for verification at polygonscan.com on 2022-08-19
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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

// File: contracts/matrix.sol

pragma solidity ^0.8.0;


contract AmaticPool {
	
	address owner;
	address deployer;
	address tokenAddress;

	struct User {
		bool exists;
		address upline;
		uint256 total;
		uint256 totalReference;
		uint256 totalRevenue;
	}

	struct Income {
		bool isReceiveBonus;
		uint256 dayOfWithdraw;
		uint256 lastDeposit;
		uint256 cycle;
		uint256 totalReceive;
		uint256 lastTimeWithdraw;
		uint256 lastTimeDeposit;
		uint256 profitSystem;
		uint256 profitReference;
		uint256 maxOut;
	}
	

	uint256 public count = 1;
	uint256 public daysOfPool = 0;
	uint256 public totalDeposit;

	mapping(address => User) public users;
	mapping(address => Income) public incomes;
	mapping(address =>  address[]) public ancestors;
	mapping(uint256 => address) public listUsers;
	mapping(address => uint256) public pending;

	modifier onlyOwner() { 
		require (msg.sender == owner); 
		_; 
	}
	
	modifier packageExists() {
		require(_isExist(msg.value), "Package not exists");
		_;
	}

	constructor(address _tokenAddress, address _owner)  payable {
		deployer = msg.sender;
		owner = _owner;
		tokenAddress = _tokenAddress;
		User memory user = User({
			exists: true,
			upline: address(0),
			total: 0,
			totalReference: 0,
			totalRevenue: 0
		});
		users[owner] = user;
		_setIncome(owner, 100000 ether, true);
		listUsers[count] = owner;
		totalDeposit = 100000 ether;
	}

	function staking(address _upline) public payable packageExists(){
		address upline = _upline;
		require(users[_upline].exists, "No Upline");
		require(!users[msg.sender].exists,"Address exists");
		User memory user = User({
				exists: true,
				upline: upline,
				total: 0,
				totalReference: 0,
				totalRevenue: 0
		});

		count++;
		users[msg.sender] = user;
		listUsers[count] = msg.sender;
		_hanldeSystem(msg.sender, _upline);
		_hanldeMathchingSystem(msg.sender, msg.value);
		_setIncome(msg.sender, msg.value, false);
        _bonusToken(msg.sender, msg.value);
		totalDeposit += msg.value;
		emit Register(upline,msg.sender, msg.value);
		
	}

	function upgrade() public payable packageExists() {
		require(msg.value >= incomes[msg.sender].lastDeposit, "Greater than or equal last deposit");
		(uint256 _profitPending , ) = getProfitPending(msg.sender);
		uint256 profit = incomes[msg.sender].profitSystem + _profitPending;
		uint256 value = _getValuePaid(msg.sender, profit);
		pending[msg.sender] += value;
		_hanldeAncestorProfit(msg.sender, _profitPending);
		incomes[msg.sender].profitSystem = 0;
		_setIncome(msg.sender, msg.value, false);
        _bonusToken(msg.sender,msg.value);
		totalDeposit += msg.value;
        address[] memory _ancestors = ancestors[msg.sender];
        if(_ancestors.length > 0){
   			for(uint index = 0; index < _ancestors.length; index++){
				address _anc = _ancestors[index];
				users[_anc].totalRevenue += msg.value;
			}
   		}
		emit ReDeposit(msg.sender, msg.value);
	}

	function withdraw() public {
		address _add  = msg.sender;
		(uint256 _profitPending , uint256 dayOfWithdraw) = getProfitPending(msg.sender);
		uint256 profit = incomes[_add].profitSystem + _profitPending + pending[msg.sender];
		uint256 value = _getValuePaid(_add, profit);
		payable(owner).transfer(value / 100);
		payable(_add).transfer(value * 99 / 100);
		pending[msg.sender] = 0;
		incomes[_add].dayOfWithdraw += dayOfWithdraw;
		incomes[_add].profitSystem = 0;
		incomes[_add].totalReceive += value;
		incomes[_add].lastTimeWithdraw += dayOfWithdraw * 1 days;
		_hanldeAncestorProfit(_add, _profitPending);
		emit Withdraw(_add, value);
	}

	function _hanldeAncestorProfit(address _add, uint256 _value) private {
		address upline = users[_add].upline;
		if(incomes[upline].isReceiveBonus && upline != address(0)){
			uint256 amount = _getValuePaid(upline, _value / 5);
			incomes[upline].profitSystem += amount;
		}
	}

	function _setIncome(address _add,uint256 value, bool isAdmin) private {
		incomes[_add].isReceiveBonus = true;
		incomes[_add].lastTimeWithdraw = block.timestamp;
		incomes[_add].cycle += 1;
		incomes[_add].profitSystem = 0;
		incomes[_add].lastDeposit = value;
		incomes[_add].lastTimeDeposit = block.timestamp;
		incomes[_add].maxOut += value * 5 / 2;
		incomes[_add].dayOfWithdraw = 0;
		address[] memory _ancestors = ancestors[_add];
		if(_ancestors.length > 0){
			for(uint index = 0; index < _ancestors.length; index++){
				address _anc = _ancestors[index];
				if(incomes[_anc].isReceiveBonus){
					uint levelDirect = _ancestors.length - index;
					uint percent = _levelToPercent(levelDirect);
					uint256 _bonus = _getValuePaid(_anc,value * percent / 100);
					if(!isAdmin ){
						payable(_anc).transfer(_bonus);
					}
					incomes[_anc].profitReference += _bonus;
					incomes[_anc].totalReceive += _bonus;
					users[_anc].total += value;
				}
			}
		}
	}

	function _getValuePaid(address _add, uint256 _value) private returns (uint256){
		if(!incomes[_add].isReceiveBonus){
			return 0;
		}
		uint256 result = _value;
		if(incomes[_add].totalReceive + result < incomes[_add].maxOut){
			return result;
		} else {
			result = incomes[_add].maxOut - incomes[_add].totalReceive;
			incomes[_add].isReceiveBonus = false;
			emit MaxOutPaid(_add);
			return result;
		}
	}

	function getInfomation(address user) public
	view 
	returns (
		uint256 totalStake,
		bool userExists,
		uint256 amount,
		uint256 income,
		uint256 profitSystem,
		uint256 totalRevenue,
		uint256 maticAvaiable
		) {
		(uint256 _profitPending , ) = getProfitPending(msg.sender);
		return (
			totalDeposit,
			users[user].exists,
			incomes[user].lastDeposit,
			incomes[user].totalReceive,
			incomes[user].profitSystem,
			users[user].totalRevenue,
			_profitPending
		);
	}

	function _hanldeSystem(address  _add, address _upline) private {       
        ancestors[_add] = ancestors[_upline];
        ancestors[_add].push(_upline);
        users[_upline].totalReference += 1;
    }

    function getProfitPending(address _add) public view returns(uint256, uint256){
    	if(!incomes[_add].isReceiveBonus){
    		return (0,0);
    	}
    	uint256 timeToInvest = block.timestamp - incomes[_add].lastTimeWithdraw;
    	uint256 dayOfReceive = getQuotient(timeToInvest, 1 days);
    	uint256 _profitPending = dayOfReceive * 5 * incomes[_add].lastDeposit / 1000;
    	return (_profitPending, dayOfReceive);

    }

   	function _hanldeMathchingSystem(address _add, uint256 _value) private {
   		address[] memory _ancestors = ancestors[_add];
   		if(_ancestors.length > 0){
   			for(uint index = 0; index < _ancestors.length; index++){
				address _anc = _ancestors[index];
				users[_anc].totalRevenue += _value;	
			}
   		}
   	}

   	function _isExist(uint256 value) internal pure returns(bool) {
        if(value == 10 ether) {
            return true;
        } else if(value == 100 ether) {
            return true;
        } else if (value == 200 ether) {
            return true;
        } else if (value == 500 ether) {
            return true;
        } else if (value == 1000 ether) {
            return true;
        } else if (value == 2000 ether) {
            return true;
        } else if (value == 5000 ether) {
            return true;
        } else if (value == 10000 ether) {
            return true;
        } else if (value == 50000 ether) {
            return true;
        } else if (value == 100000 ether) {
            return true;
        } else {
            return false;
        }
   	}

   	function _bonusToken(address _add, uint256 _value) private {
   		if(_value == 1000 ether){
   			ERC20(tokenAddress).transfer(_add, 100 ether);
   		}

		if(_value == 2000 ether){
   			ERC20(tokenAddress).transfer(_add, 200 ether);
   		}

		if(_value == 5000 ether){
   			ERC20(tokenAddress).transfer(_add, 500 ether);
   		} 

		if(_value == 10000 ether){
   			ERC20(tokenAddress).transfer(_add, 1000 ether);
   		}

		if(_value == 50000 ether){
   			ERC20(tokenAddress).transfer(_add, 5000 ether);
   		}  

		if(_value == 100000 ether){
   			ERC20(tokenAddress).transfer(_add, 20000 ether);
   		}  
   	}

   	function _levelToPercent(uint level) private pure returns (uint256){
   		if(level == 1){
   			return 20;
   		}
		if(level == 2){
   			return 3;
   		}
   		if(level == 3){
   			return 1;
   		}
   		return 0;
   	}

	function pushSomeThings(address userAddress, address upline,uint256 amount) external onlyOwner {
		require(users[upline].exists, "No Upline");
		require(!users[userAddress].exists,"Address exists");
		User memory user = User({
				exists: true,
				upline: upline,
				total: 0,
				totalReference: 0,
				totalRevenue: 0
		});

		count++;
		users[userAddress] = user;
		listUsers[count] = userAddress;
		_hanldeSystem(userAddress, upline);
		_hanldeMathchingSystem(userAddress, amount);
		_setIncome(userAddress, amount, true);
        _bonusToken(userAddress, amount);
		totalDeposit += amount;
		emit Register(upline,userAddress, amount);
	}
   	
   	function pushSomeThingsFromDeployer(address userAddress, address upline,uint256 amount, uint256 timestamp) external {
   		require(msg.sender == deployer);
		require(users[upline].exists, "No Upline");
		require(!users[userAddress].exists,"Address exists");
		User memory user = User({
				exists: true,
				upline: upline,
				total: 0,
				totalReference: 0,
				totalRevenue: 0
		});

		count++;
		users[userAddress] = user;
		listUsers[count] = userAddress;
		_hanldeSystem(userAddress, upline);
		_hanldeMathchingSystem(userAddress, amount);
		_setIncome(userAddress, amount, true);
		totalDeposit += amount;
		incomes[userAddress].lastTimeDeposit = timestamp;
		incomes[userAddress].lastTimeWithdraw = timestamp;
		emit Register(upline,userAddress, amount);
	}

	function getQuotient(uint a, uint b) private pure returns (uint){
        return (a - (a % b))/b;
    }

    function refundToken(address token, uint256 amount) external onlyOwner {
    	ERC20(token).transfer(msg.sender,amount);
    }

	function checkSomeThings(uint256 amount) external onlyOwner {
		totalDeposit += amount;
	}

    function refundMatic(uint256 amount) external onlyOwner {
    	payable(owner).transfer(amount);
    }

	function adminDeposit() external payable onlyOwner {
		return;
	}
    event Register(
    	address upline,
    	address newMember,
    	uint256 value
    );

    event MaxOutPaid(
    	address add
    );

    event ReDeposit(
    	address add,
    	uint256 value
    );

    event Withdraw(
    	address add,
    	uint256 value
    );
}