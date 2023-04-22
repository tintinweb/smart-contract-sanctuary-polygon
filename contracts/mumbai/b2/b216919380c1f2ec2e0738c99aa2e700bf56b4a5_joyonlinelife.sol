/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: MIT

// File: joyboy_ICO-master/contracts/Referral.sol



pragma solidity ^0.8.9;


contract refer {
    
struct User {
    bool referred;
    address referred_by;
}

struct Referal_levels {
    uint256 level_1;
    uint256 level_2;
}

mapping(address => Referal_levels) public refer_info;
mapping(address => User) public user_info;

function referee(address ref_add) public {
        require(user_info[msg.sender].referred == false, " Already referred ");
        require(ref_add != msg.sender, " You cannot refer yourself ");

        user_info[msg.sender].referred_by = ref_add;
        user_info[msg.sender].referred = true;

        address level1 = user_info[msg.sender].referred_by;
        address level2 = user_info[level1].referred_by;

        if ((level1 != msg.sender) && (level1 != address(0))) {
            refer_info[level1].level_1 += 1;
        }
        if ((level2 != msg.sender) && (level2 != address(0))) {
            refer_info[level2].level_2 += 1;
        }
        
       
}
}


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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        return 8;
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

// File: joyboy_ICO-master/contracts/joyonlinelife.sol


pragma solidity ^0.8.9;




// if ico fails there owner's will get 95% of their matic back since 5% will be charges including gas fees and ICO processing fees
contract joyonlinelife is ERC20 {
    address public admin;
    address payable public depositAddress;

    // if ICO is successfull only then the tokens will be transfered to the owner wallet
    // else matic's will be reversed back to the owner
    mapping(address => uint) public joyBalance;

    // keeps a record of matic invested by every wallet address
    mapping(address => uint) public investedAmt;

    // 8220 matic to find if ICO was a success or not
    uint256 public hardCap = 100000000000000000;

    // tracks the raisedAmount
    uint256 public raisedAmount;

    // ICO sale starts immediately as the contract is deployed
    uint256 public saleStart = block.timestamp;
    // ICO sale ends after 6 months
    uint256 public saleEnd = block.timestamp + 14515200;

    // max investment is 300 matic
    uint256 public maxInvestment = 3000000;
    // min investment is 30 matic
    uint256 public minInvestment = 300000;

    uint256 public tokensMinted;

    uint256 public preSaleAmt = 10000000000 * 10 ** decimals();
    uint256 public seedSaleAmt = 200000000 * 10 ** decimals();
    uint256 public finalSaleAmt = 10000000000 * 10 ** decimals();

    uint256 public preTokens = 10000000000 * 10 ** decimals();
    uint256 public seedTokens = 0;
    uint256 public finalTokens = 10000000000 * 10 ** decimals();

    // enum to track the state of the contract
    enum IcoState { 
        beforeStart,
        running, 
        afterEnd, 
        halted }
    IcoState public icoState;

    // enum to track the sale of the contract
    enum SaleState { 
        pre_Sale, 
        seed_Sale, 
        final_Sale, 
        Sale_END 
    }
    SaleState public saleState;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Sender must be an admin");
        _;
    }

    constructor(
        address payable _deposit
    ) ERC20("joy of online life", "JOY"){
        depositAddress = _deposit;
        admin = msg.sender;
        icoState = IcoState.beforeStart;
        _mint(admin, 1000000000000 * 10 ** decimals());
        joyBalance[admin] = 1000000000000 * 10 ** decimals();
    }

    // emergency stop for joyonlinelife
    function haltICO() public onlyAdmin {
        icoState = IcoState.halted;
    }

    // resuming joyonlinelife
    function resumeICO() public onlyAdmin {
        icoState = IcoState.running;
    }

    // function to change deposit address in case the original one got issues
    function changeDepositAddress(
        address payable _newDeposit
    ) public onlyAdmin {
        depositAddress = _newDeposit;
    }

    // fetch the current state of joyonlinelife
    function getCurrentICOState() public payable returns(IcoState) {
        if (icoState == IcoState.halted) {
            return IcoState.halted;
        } else if (block.timestamp < saleStart) {
            return IcoState.beforeStart;
        } else if (block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return IcoState.running;
        } else {
            return IcoState.afterEnd;
        }
    }

    // function to check the raised amount of matic
    function checkRaisedAmt() internal view returns(uint256) {
        return raisedAmount;
    }

    // investing function
    function invest() public payable returns(bool) {
        
        icoState = getCurrentICOState();
        // investment only possible if IcoState is running
        require(icoState == IcoState.running, "joyonlinelife is not in running state");

        // address must not have invested previously        
        require(joyBalance[msg.sender] == 0, "User must invest only once according to our policy");
                
        require(msg.value >= minInvestment && msg.value <= maxInvestment, "Investment amount must be more than 0.05 matic and less than 5 matic");

        // hardcap not reached
        require(raisedAmount + msg.value <= hardCap, "hardCap reached");
        raisedAmount += msg.value;

        // tokens calculation
        uint256 tokens = buyTokens(msg.value);

        // add tokens to investor balance from founder balance
        joyBalance[msg.sender] += tokens;
        joyBalance[admin] -= tokens;

        investedAmt[msg.sender] += msg.value;
        
        return true;          
    }

    // function to buyTokens 
    function buyTokens(
        uint256 msgValue
    ) internal returns(uint256) {
        if(saleState == SaleState.pre_Sale) {
            uint256 _tokens = preSale(msgValue);
            return _tokens;
        } else if (saleState == SaleState.seed_Sale) {
            uint256 _tokens = seedSale(msgValue);
            return _tokens;
        } else {
            uint256 _tokens = finalSale(msgValue);
            return _tokens;
        }
    }

    // calculate tokens provided the sale is preSale
    function preSale(
        uint _msgValue
    ) internal returns(uint256 tokens) {
        uint256 _tokens = 0;
        // calculated considering matic value as 1$
        _tokens = _msgValue * 1 * 10 ** 3;
        if((preTokens + _tokens) >= preSaleAmt){
            // find the amount required to fill up the pre sale amount
            // newValue is the value of tokens needed to fill the rest of the presale
            uint256 newValue = (preSaleAmt - preTokens)/(1 * 10 ** 3);
            
            // update the preTokens 
            preTokens = preSaleAmt;
            // update the ico State
            saleState = SaleState.seed_Sale; 

            // call seed Sale
            return seedSale(_msgValue-newValue);
        } else {
            preTokens += _tokens;
            return _tokens;
        }
    }

    // calculate tokens provided the sale is seed Sale
    function seedSale(
        uint256 _msgValue
    ) internal returns(uint256 tokens) {
        uint256 _tokens = 0;
        // calculated considering matic value as 1$
        _tokens = _msgValue * 20 * 10 ** 1;
        if((seedTokens + _tokens) >= seedSaleAmt){
            // find the amount required to fill up the seed sale amount
            uint256 newValue = (seedSaleAmt - seedTokens)/(20 * 10 ** 1);
            
            // update the seedTokens 
            seedTokens = seedSaleAmt;
            // update the ico State
            saleState = SaleState.final_Sale; 

            // call seed Sale
            return finalSale(_msgValue-newValue);
        } else {
            seedTokens += _tokens;
            return _tokens;
        }
    }

    // calculate tokens provided the sale is final Sale
    function finalSale(
        uint256 _msgValue
    ) internal returns(uint256 tokens) {
        uint256 _tokens = 0;
        // calculated considering matic value as 2500$ and 1 token = 1$ for final sale
        _tokens = _msgValue * 25 * 10 ** 2;
        if((finalTokens + _tokens) >= finalSaleAmt){
            // find the amount required to fill up the final sale amount
            // uint256 newValue = (finalSaleAmt - finalTokens)/(25 * 10 ** 2);
            
            // update the finalTokens 
            finalTokens = finalSaleAmt;
            // update the ico State
            saleState = SaleState.Sale_END; 
        } else {
            finalTokens += _tokens;
            return _tokens;
        }
    }

    // function to check if the ico was a success
    function successCheck() public view returns(bool) {
        require(block.timestamp >= saleEnd, "joyonlinelife hasn't expired yet, Try after saleEnd!");

        if(checkRaisedAmt() >= hardCap) {
            return true;
        } else {
            return false;
        }        
    }
    
    function withdraw() public payable {
        require(block.timestamp >= saleEnd);

        // if it was a success then transfer all the matic received to the deposit address and transfer JOY tokens to their wallet
        if(successCheck() == true) {         
            // transfer JOY tokens to their owners wallet
            _transfer(admin, msg.sender, joyBalance[msg.sender]);
            joyBalance[msg.sender] = 0;

        }
        // if not then revert the matic to the concerned authority and empty their joyBalances
        else {
            payable(msg.sender).transfer(investedAmt[msg.sender]);
            investedAmt[msg.sender] = 0;
        }
    }

    // only applicable if the joyonlinelife is success and the sale has ended
    function transfermatic() public payable onlyAdmin {
        require(block.timestamp >= saleEnd, "joyonlinelife hasn't expired yet, Try after saleEnd!");
        require(successCheck() == true, "joyonlinelife was not a success");

        // transfer all the matic received to the deposit address
        payable(depositAddress).transfer(raisedAmount);
    }
}

// calculation:
/*
To purchase all 1 million tokens, you need to calculate the total amount in US dollars and matic for each sale.

For the pre-sale tokens:
The total amount in US dollars would be $0.01 x 100 million = $1,000,000
The total amount in matic would be $,1,000,000 / $1 (1 matic = $1) = 1,000,000 matic


*/