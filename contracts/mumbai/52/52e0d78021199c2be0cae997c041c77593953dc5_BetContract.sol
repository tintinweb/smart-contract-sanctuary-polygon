/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol


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
     * @dev Automatically decreases the allowance granted to `spender` by the caller.
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

// File: Bet.sol

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.7;

contract BetContract is ERC20
    {
    address public Owner;
    struct DepositStruct
    {
         uint _numTokens;
    }
    struct StructBetDetails
    {
        address user;
        uint BetTime;
        uint BetTokens;
        uint TimesBenefit;
        uint WonTokens;
        uint LostTokens;
        string _HeadOrTail;
        bool result;
    }
    StructBetDetails[] private TxnHistory;
    mapping(address=>mapping(uint=>StructBetDetails)) private BetDetails;
    mapping(address=>DepositStruct) private DepositDetails;
    mapping(address=>uint) private _balances;
    event Edeposit(address who,uint _numTokens,uint _TxnFees);
    event EWithdraw(address _who,uint _amount,uint _txnFees);
    event EBuyTokens(address _who,uint _amount,uint _numTokens,bool _Deposited);
    uint private Count;
     
    modifier OnlyOwner
    {
          require(msg.sender==Owner,"Only owner can withdraw");
          _;
    }
    
    constructor()  ERC20("BetToken","BTKN")                    
    {
           Owner=msg.sender;
          _mint(Owner,10000000000000000000000000000);
          _balances[Owner]+=10000000000000000000000000000;
    }

    function BuyTokens(address _user,uint _NumTokens) public payable
    {
          uint NumTokens=_balances[Owner];
          if(_user==0x0000000000000000000000000000000000000000)
          {
              DepositDetails[msg.sender]._numTokens+=_NumTokens;
              payable(Owner).transfer(msg.value);
              emit Transfer(Owner,0x0000000000000000000000000000000000000000,_NumTokens);
              emit EBuyTokens(msg.sender, msg.value, _NumTokens, true);
          }
          else
          {
              uint TxnFees=(_NumTokens*3/100)*100;
              uint DepositTokens=_NumTokens-TxnFees/100;
              _balances[_user]+=DepositTokens;
              _balances[Owner]=NumTokens-DepositTokens;
              payable(Owner).transfer(msg.value);
              emit Transfer(Owner,_user,DepositTokens);
              emit EBuyTokens(_user, msg.value, DepositTokens, false);
          }
    }

    function DepositEth(uint _NumTokens) public 
    {
        uint TxnFees=(_NumTokens*3/100)*100;//it should be in 2.5 percentage 
        uint TokensToBeDeposit=_NumTokens-TxnFees/100;
        //all amount go to owner wallet - smart contract
        // he deposit 100 and get 95 in his account
         _balances[Owner]+=_NumTokens;
         _balances[msg.sender]=_balances[msg.sender]-_NumTokens;
         DepositDetails[msg.sender]._numTokens+=TokensToBeDeposit;
         emit Edeposit(msg.sender,TokensToBeDeposit,TxnFees);
    }

    function DepositedTokens(address _user) public view returns(uint)
    {
        return DepositDetails[_user]._numTokens;
    }

    function balanceOf(address _user) public view override returns(uint)
    {
        return _balances[_user];
    }

    function Bet(address _user,uint _BetNumTokens,uint _TimesProfit,string memory _HeadOrTail) public
    {
        require(DepositDetails[_user]._numTokens>=_BetNumTokens,"You don not have  enough tokens for bet");
        require(_BetNumTokens*_TimesProfit<=_balances[Owner],"Owner does not have enough tokens to give profit");
        /* bool _Outcome;
        uint Random=uint256(keccak256(abi.encode(_user)));
        if(Random%3==0){
            _Outcome=true;
        }
        else{
            _Outcome=false;
        }
       if(_IsHeadBet==_Outcome){
            uint NumTokens=_BetNumTokens*_TimesProfit;
            _balances[_user]+=NumTokens;
            _balances[Owner]=_balances[Owner]-NumTokens;
        BetDetails[_user][Count]=StructBetDetails(_user,block.timestamp,_BetNumTokens,NumTokens,0,_TimesProfit,_IsHeadBet,_Outcome);
        TxnHistory.push(BetDetails[_user][Count]);
        }
        else{
        _balances[Owner]+=_BetNumTokens;
        DepositDetails[_user]._numTokens=DepositDetails[_user]._numTokens-_BetNumTokens;
        BetDetails[_user][Count]=StructBetDetails(_user,block.timestamp,_BetNumTokens,0,_BetNumTokens,_TimesProfit,_IsHeadBet,_Outcome);
        TxnHistory.push(BetDetails[_user][Count]);
        }
    }
    */

    bool result  = flipCoin(_HeadOrTail);
    if(result == true) {
    uint NumTokens = _BetNumTokens*_TimesProfit;
    _balances[Owner]=_balances[Owner]-NumTokens;
    _balances[_user]+=NumTokens;
    BetDetails[_user][Count]=StructBetDetails(_user,block.timestamp,_BetNumTokens,NumTokens,0,_TimesProfit,_HeadOrTail,result);
    TxnHistory.push(BetDetails[_user][Count]);
    }
    else{
    _balances[Owner]+=_BetNumTokens;
    DepositDetails[_user]._numTokens = DepositDetails[_user]._numTokens-_BetNumTokens;
    BetDetails[_user][Count]=StructBetDetails(_user,block.timestamp,_BetNumTokens,0,_BetNumTokens,_TimesProfit,_HeadOrTail,result);
    TxnHistory.push(BetDetails[_user][Count]);
    }
    }

    function withdrawTokens(address _user,uint _NumTokens) public OnlyOwner
    {
        require(_NumTokens <= DepositDetails[_user]._numTokens,"Not enough token to withdraw");
        uint TxnFees = (_NumTokens*3/100)*100;
        uint NumWithdrawTokens = _NumTokens-TxnFees/100;
        DepositDetails[_user]._numTokens -= DepositDetails[_user]._numTokens-NumWithdrawTokens;
        _balances[_user] = NumWithdrawTokens;
        _balances[Owner] = _balances[Owner] -NumWithdrawTokens;
        emit EWithdraw(_user,NumWithdrawTokens,TxnFees);
    }

    function GetTransactionHistory() public view returns(StructBetDetails[] memory){
         return TxnHistory;
    }

    function transfer(address to, uint256 NumTokens) public  override returns (bool)
    {
         emit Transfer(msg.sender,to,NumTokens);
         _transfer(msg.sender, to, NumTokens);
         return true;
    }


    function flipCoin(string memory _HeadOrTail) public view returns(bool success) {
        success = false;
        uint random  = getRandomValue();
        if(random % 3 == 0 && keccak256(abi.encodePacked(_HeadOrTail)) == keccak256(abi.encodePacked("Head"))) {
            //Here code execute when Head come
            success = true;
            
        }
        else if(random % 3 != 0 && keccak256(abi.encodePacked(_HeadOrTail)) == keccak256(abi.encodePacked("Tail"))) {
            //Here code execute when Tail come
            success = true;
        }
    }
    function getRandomValue() public view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))%30;
    }

    }