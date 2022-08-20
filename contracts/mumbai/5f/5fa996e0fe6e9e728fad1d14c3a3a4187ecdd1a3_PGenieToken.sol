//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./IDEXRouter.sol";
import "./SafeMath.sol";

contract PGenieToken is IERC20, IERC20Metadata, Ownable{

    using SafeMath for uint256;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    IDEXRouter public router;
    address public pair;
    
    /**
     * When doing transaction, the fee or limit need to be ignored for these addresses.
     * _isFeeExempt : address list which is not involved in fee
     * _isTxLimitExempt : address list which is not involved in limit 
     */ 
    mapping (address => bool) _isFeeExempt;
    mapping (address => bool) _isTxLimitExempt;

    /**
     * @dev Fee values.
     * _buyToken : when someone buy tokens, it costs this fee. 
     * _sellFee  : when someone sell tokens, it costs this fee.
     * _txFee    : when someone send tokens to other, it costs this fee.
     * _totalFee : totalFee is sum up of all fees totalFee = _buyFe  
     */
    uint256 private _buyFee;
    uint256 private _sellFee;
    uint256 private _txFee;
    uint256 private _totalFee;

    /**
     * Divided tokens for every purpose based on tokenamics
     */
    
    address public idoWallet =  address(0x54B9c83ecae19a7B3944456a97A80e5238e251Cf); //IDO wallet
    uint256 public idoTokens = 475000000e18;

    address public airDropWallet =  address(0x11aF0aC0789CD474BcaD4eB653ed48EC13044360); //Airdrop wallet
    uint256 public airDropTokens = 200000000e18;
    
    address public preSaleWallet =  address(0x6bbFF05ad7E53b26395Ed33B322fC9A87151edA5); //pre-sale wallet
    uint256 public preSaleTokens = 200000000e18;
    
    address public developmentTeamWallet = address(0x1178423EEcEeBE0c5831B69C5847770B0891B55c); //development team wallet
	uint256 public developmentTeamTokens = 300000000e18;

	address public developmentWallet = address(0x40E973fCEF03b3Bf5D93b919a3c9D03b16715a38); //development wallet
	uint256 public developmentTokens = 300000000e18;

	address public foundersWallet  = address(0x396d91dc1444950E029E63a19C33aC4A16F56d1B); //founders wallet
	uint256 public foundersTokens = 700000000e18;

	address public communityWallet  = address(0x9c6E8358E3EA6859c8F2CEA73270426c71683189); //comunnity wallet
	uint256 public communityTokens = 3500000000e18;

	address public treasuryWallet = address(0x9745c37d1787C2d41C11FfbD13F53deF7a9D015D); //treasury wallet
	uint256 public treasuryTokens = 210000000e18;
	
	address public investorsWallet = address(0x1DedbBC8cC232cCe12a56B63ef7B11C6B5fC73B9); //investors wallet
	uint256 public investorsTokens = 515200000e18;

    address public marketingWallet = address(0x6c97CC39170aB51755aE6587d58C715D2fdc8B14); //marketing wallet
	uint256 public marketingTokens = 599800000e18;

    address public feeWallet = address(0xaf28a6996B867229430FbC39c948625548babd8F); //wallet for fee

    // transaction limit
    uint256 private _maxTxAmount;

    // daily limit supply
    uint256 private _dailySupplyLimit;

    // amount of daily supply
    uint256 private _dailySupplyAmount;

    // claiming last date
    uint256 private _clamingLastUpdatedDate;

    mapping (address => uint256) public dailyUserAmount;
    mapping (address => uint256) public endDateUserClaim;

    //Address mapping with limited amount
    mapping (address => uint256) public limitedAddresses;

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
        _totalSupply = 7000000000 * (10 ** decimals());
        
        _balances[msg.sender] = _totalSupply;
        
        _dailySupplyAmount= 0;

        //set daily supply limit
        _dailySupplyLimit = 500000 * (10 ** decimals()); 

        //set fees 
        _buyFee = 200; 
        _sellFee = 300;
        _txFee = 100;

        //router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // rinkby address
        router = IDEXRouter(0x8954AfA98594b838bda56FE4C12a09D7739D179b); // Polygon address

        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this)); //pair address

        //exclude owner and this contract from fee
        _isFeeExempt[owner()] = true;
        _isFeeExempt[address(this)] = true;

        //exclude owner and this contract from limit
        _isTxLimitExempt[owner()] = true;
        _isTxLimitExempt[address(this)] = true;

        _clamingLastUpdatedDate = block.timestamp;

    }

    receive() external payable { }

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
        address owner = msg.sender;
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
        address owner = msg.sender;
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
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
        address owner = msg.sender;
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
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        checkTxLimit(from, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
        }

        //get fee
        uint256 amountReceived = shouldTakeFee(from) ? takeFee(from, to, amount) : amount;

        _balances[to] += amountReceived;

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     Set all Transaction fees which is disappeard when sending tokens
     */
    function setTransactionFees(uint buyFee_, uint sellFee_, uint txFee_) external onlyOwner {
        _buyFee = buyFee_;
        _sellFee = sellFee_;
        _txFee = txFee_;        
    } 

    // Set Transaction Limit
    function setTxLimit(uint256 maxTxAmount_) external onlyOwner {
        require(maxTxAmount_ >= _totalSupply / 1000, "Trasaction limit should be more than 0.1% of totalsupply.");
        _maxTxAmount = maxTxAmount_;
    }

    //check the txLimit
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || _isTxLimitExempt[sender], "Transaction Limit Exceeded");
        require(limitedAddresses[sender] == 0 || amount <= limitedAddresses[sender], "Trasaction limit of this address exceeded");
    }
    
    // Checked if the transcation need to cost fee or not.
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !_isFeeExempt[sender];
    }

    // Calculating the amount of tokens from fee (%) 
    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint fee;
        if(sender == pair)  // when buying tokens
            fee = _buyFee;
        else if(receiver == pair)
            fee = _sellFee;         // when selling tokens
        else
            fee = _txFee;           // when sending tokens
        
        uint256 feeAmount = amount.mul(fee).div(10 ** 4);

        // send the fee to address every
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        _totalFee += feeAmount;

        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }
    
    //send the total fees to wallet.
    function sendFeetoWallet(address to) public payable onlyOwner{
        transfer(to, _totalFee);
        _totalFee = 0;
    }

    // Add address to fee excluded list
    function setFeeExempt(address account_, bool value_) external onlyOwner() {
        _isFeeExempt[account_] = value_;
    }

    // Add address to limit excluded list
    function setTxLimitExempt(address account_, bool value_) external onlyOwner() {
        _isTxLimitExempt[account_] = value_;
    }

    // Set daily supply limit amount
    function setDailySupplyLimit(uint256 dailySupplyLimit_) external onlyOwner() {
        _dailySupplyLimit = dailySupplyLimit_;
    }

    /**
     * Claiming from points to tokens with daily limit
     * when current date is same as last updated date, it adds tokens to dailySupplyAmount till it would not bigger than dailySupplyLimit
     * If dailySupplyAmount is bigger than dailySupplyLimit, rest of points is not converted to tokens.
     * when the day goes tomorrow, _clamingLastUpdatedDate is updated current date and dailySupplyAmount will be updated 0.
     * daily supply amount should be sent from community wallet to users. 
     */
    function claimTokensFromPoints(address to, uint256 tokens_) external payable {

        if((_clamingLastUpdatedDate + 1 days) <= block.timestamp) {
            _clamingLastUpdatedDate = block.timestamp;
            _dailySupplyAmount = 0;
        }
        
        if(_dailySupplyAmount + tokens_ < _dailySupplyLimit) {
            transferFrom(communityWallet, to, tokens_);
            _dailySupplyAmount += tokens_; 

        }
        else {
            uint256 canClaimAmount = tokens_ - ((_dailySupplyAmount + tokens_) - _dailySupplyLimit);
            if(canClaimAmount != 0) {
                transferFrom(communityWallet, to, canClaimAmount);
            }
            _dailySupplyAmount = _dailySupplyLimit;
        }
    }

    //Set limite for specific address
    function setLimitSpecificWallet(address wallet_, uint256 limitAmount_) external onlyOwner {
        limitedAddresses[wallet_] = limitAmount_;
    }
}