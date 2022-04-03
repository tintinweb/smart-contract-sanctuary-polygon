// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./AccessControlEnumerable.sol";

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
contract LegacyERC20V1 is Context, AccessControlEnumerable, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name="TEST";
    string private _symbol="S#$";
    uint8 override public decimals=18;
    address public LK_Redistribution_holders=0x064C796F390e31A9Afb02Fb0DA73897c7f60dd3B; //G Chrome
    address public LK_Charity=0x9Ed86212dC70DFf3B75A6E80b46bf68dd47f2A8C;
    address public LK_Liveevents = 0xf78e1e6b54132471b4bb5BF272e9351b9FA49eF1;
    uint256 public basePercent = 100;

//    event TLK_Token_Swap_event(address indexed from, address indexed to, uint256 value, uint tokenid);
    //event LK_Approve_market_contract_event(address from, uint amount);
    event Transfer_LK_Redistr(string str, address sender, address recipient,uint amount);
    event Transfer_LK_Liveevents(string str, address sender, address recipient,uint amount);
    event Transfer_LK_Charity(string str, address sender, address recipient,uint amount);

    function set_TLK_Distributorn_address(address live_addr, address redistribution_addr, address charity2) onlyOwner public {
        if(redistribution_addr != address(0) && live_addr != address(0) && charity2 != address(0)){
            LK_Liveevents = live_addr;
            LK_Charity = charity2;
            LK_Redistribution_holders = redistribution_addr;
        }
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint256  totalSupply_, uint8 decimals_ ) {
        _name = name_;
        _symbol = symbol_;        
         decimals = decimals_;    
          _mint(msg.sender, (totalSupply_ * 10 ** 18)); //Original code
          //_mint(msg.sender, (1000));
    }  

    /*constructor(){
        //_mint(address(this), (10000 * 10 ** 18));
        _mint(msg.sender, (10000000 * 10 ** 18));
        }*/

    //function set_Redistribution(address) 

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
    function Getdecimals() public view virtual returns (uint8) {
        return decimals;
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
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public onlyOwner virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public onlyOwner virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function onePercentv1(uint256 _value) public  pure returns(uint256){
        uint256 roundValue = SafeMath.ceil(_value,10);
        uint256 twoPercent_v =SafeMath.div(SafeMath.mul(roundValue,1), 100);
        return twoPercent_v;
    }

    function twoPercentv1(uint256 _value) public  pure returns(uint256){
        uint256 roundValue = SafeMath.ceil(_value,10);
        uint256 twoPercent_v =SafeMath.div(SafeMath.mul(roundValue,2), 100);
        return twoPercent_v;
    }

    /*function onePercent(uint256 _value) public view returns (uint256)  {
        uint256 roundValue = SafeMath.ceil(_value, basePercent);
        uint256 onePercent_v = SafeMath.div(SafeMath.mul(roundValue, basePercent), 10000);
        return onePercent_v;
    }

     function twoPercent(uint256 _value) public view returns (uint256)  {
        uint256 roundValue = SafeMath.ceil(_value, basePercent);
        uint256 twoPercent_v = SafeMath.div(SafeMath.mul(roundValue, basePercent), 20000);
        return twoPercent_v;
    }*/

    /*function TLK_distribute_tokens(uint256 token_amount) payable public{
        require(msg.value > 0, "Msg.value shoule be greater than zero");
        //require(token_amount <= 0, "Token amount is zero");
        require(_msgSender() != address(0), "ERC20: transfer from the zero address");            
        address sender = address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        address recipient = msg.sender;
        require(token_amount > 0, "Amount should greater than zero");
        uint256 senderBalance = _balances[address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4)];
        require(senderBalance >= token_amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - token_amount;
        }
        _balances[msg.sender] += token_amount;
        
        //LK_Redistribution_holders.transfer(msg.value * 1/100+1);
        emit Transfer(sender, recipient, token_amount);

        _afterTokenTransfer(sender, recipient, token_amount);
        //transfer(msg.sender,token_amount);
        //LK_Redistribution_holders.transfer(msg.value * 1/100);
    }*/

    function _transfer( //Dec 07 2021
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        uint per1 = onePercentv1(amount);
        uint per2_cal = twoPercentv1(amount);
        uint per2 = twoPercentv1(amount) + twoPercentv1(amount);
        uint total_value_to_be_transferred = senderBalance + per1 + per2;        
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(total_value_to_be_transferred >= amount, "ERC20: transfer amount exceeds balance after adding distributor percentage");
        uint total_deduction = per1 + per2 + amount;
        unchecked {
            //_balances[sender] = senderBalance - amount;
            require(senderBalance > total_deduction, "Total deduction is greater than token sender balance.");
            _balances[sender] = senderBalance - total_deduction;
        }
        _balances[recipient] += amount;
        if(per2_cal != 0){            
            _balances[LK_Redistribution_holders] += per2_cal;
            _balances[LK_Liveevents] += per2_cal;
            emit Transfer_LK_Redistr("Redistribution", sender, LK_Redistribution_holders, per2_cal);
            emit Transfer_LK_Liveevents("Live Events", sender, LK_Liveevents, per2_cal);
        }
        if(per1 != 0 ){
        _balances[LK_Charity] += onePercentv1(amount);
        emit Transfer_LK_Charity("Charity", sender, LK_Charity, per1);
        }

        //emit Distribute_event(LK_Charity, amount);        
        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /*function calculation_check (uint amount) public view  returns (uint){
        uint256 senderBalance = _balances[msg.sender];
        uint per1 = onePercent(amount);
        uint per2 = twoPercent(amount) + twoPercent(amount);
        //uint total_value_to_be_transferred = senderBalance + per1 + per2; 
        uint total_deduction = per1 + per2 + amount;
        return(total_deduction);
        //_balances[msg.sender] = senderBalance - total_deduction;

        //return (total_value_to_be_transferred);
        //return(_balances[msg.sender]);
    }*/
    

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /*function LK_mint_tokens(address account, uint256 amount) public onlyOwner{
        amount = (amount * 10 ** 18);
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }*/
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function LK_owner_mint(address to, uint256 amount) public onlyOwner  {
        //require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
         _mint(to, amount);
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

     /* function LK_TLK_NFT_swap( 
        address sender,
        address recipient,
        uint256 amount,
        uint tokenId
    ) external {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        //emit TLK_Token_Swap_event(sender, recipient, amount, tokenId); //emit the events when the TLK token sent to the NFT creator.

        _afterTokenTransfer(sender, recipient, amount);
        //IERC721()
    }

     function LK_Approve_market_contract(address market, uint amount) public
    {
        //Intiate to purchase the NFT tokens.
        _approve(_msgSender(), market, amount);
        emit LK_Approve_market_contract_event(market, amount);

    }*/ 

}


    /*function _transfer( //Dec 07 2021
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }*/