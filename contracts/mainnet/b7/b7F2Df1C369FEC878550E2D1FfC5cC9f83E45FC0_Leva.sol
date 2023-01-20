/**
 *Submitted for verification at polygonscan.com on 2023-01-20
*/

// SPDX-License-Identifier: MIT

// File: IParidex.sol



pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

interface IParidex {
    function isMan(address _sender) external returns (bool);
    function isPari(address _pari) external returns (bool);
    function isLeva(address _leva) external returns (bool);
    function getPari() external returns (address);
    function getLevaList() external returns (address[] memory);
    function getSmartLock() external returns (bool);
    function getSLNONContract() external returns (bool);
    function addLiquidity(address factory, address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAuto(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(address factory, address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityAuto(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function consultLeva2Usd(address _leva, uint _amount) external returns (uint);
    function consultPari2Usd(uint _amount) external returns (uint);
    function consultPari2Leva(address _leva, uint _pariAmount) external returns (uint);
    function consultLeva2Pari(address _leva, uint _levaAmount) external returns (uint);
    function consultLeva2Leva(address _levaIn, address _levaOut, uint _levaInAmount) external returns (uint);
    function consultSmart(address _inToken, address _outToken, uint _inAmount) external returns (uint);
    function swapPari2Leva(address _leva, uint _pariAmount, uint _minLevaAmount) external returns (uint out);
    function swapLeva2Pari(address _leva, uint _levaAmount, uint _minPariAmount) external returns (uint out);
    function swapLeva2Leva(address _levaIn, address _levaOut, uint _levaAmount, uint _minLevaAmount) external returns (uint out);
    function swapSmart(address _inToken, address _outToken, uint _inAmount, uint _minOutAmount) external returns (uint out);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint steps, uint deadline) external returns (address[] memory factories, uint[] memory amounts);
    function arbitrage(address _token, uint _amount, address _middleToken) external returns (uint revenue, address[] memory factories, uint[] memory amounts);
    function stabilize(address _sender, address _taker, uint _amount) external returns (uint revenue, address[] memory factories, uint[] memory amounts);
    function addLeva(address _leva) external returns (bool);
    function removeLeva(address _leva) external returns (bool);
    function changePari(address _pari) external returns (bool);
    function changeStableCoin2Usd(address _stablecoin2usd) external returns (bool);
    function changeSTABLECOIN(address _STABLECOIN) external returns (bool);
    function changeAnyOracle(address _anyOracle) external returns (bool);
    function changeTax(uint _tax) external returns (bool);
    function changeSmartLock(bool _smartLock) external returns (bool);
    function changeSLNONContract(bool _SLNONContract) external returns (bool);
    function changeTrigger(address _trigger) external returns (bool);
    function changeMan(address _manager) external returns (bool);
    function migrate(address _newInstance) external returns (bool);
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

// File: IPari.sol



pragma solidity ^0.8.7;



interface IPari is IERC20, IERC20Metadata {
    function burn(uint amount) external;
    function burnFrom(address account, uint amount) external;
    function burnNGet(address _leva, uint _amount) external returns (uint);
    function burnFromNGet(address _leva, address _account, uint _amount) external returns (uint);
    function mint(address _to, uint _amount) external returns (bool);
    function manMint(address _to, uint _amount) external returns (bool);
    function setParidex(address _paridex) external returns (bool);
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

// File: Leva.sol



pragma solidity ^0.8.7;




contract Leva is ERC20 {
    address public paridex;
    address public pegOracle;

    event FailedStabilization(address indexed from, address indexed to, uint amount, bytes reason);
    event ParidexChanged(address indexed _paridex);
    event PegOracleChanged(address indexed _pegOracle);

    constructor(
        string memory _name,
        string memory _symbol,
        uint _initialSupply,
        address _paridex,
        address _pegOracle
    ) ERC20(_name, _symbol) {
        paridex = _paridex;
        pegOracle = _pegOracle;
        _mint(_msgSender(), _initialSupply);
    }

    function _onlyPari() internal {
        require(IParidex(paridex).isPari(_msgSender()), "ONLY_PARI");
    }

    function _onlyMan() internal {
        if(_msgSender() != paridex) {
            require(IParidex(paridex).isMan(_msgSender()), "ONLY_MANAGER");
        }
    }

    function _smartLocked() internal {
        require(!IParidex(paridex).getSmartLock() || (IParidex(paridex).getSLNONContract() && !_isContractOrNull(_msgSender())) || _msgSender() == paridex || IParidex(paridex).isMan(_msgSender()), "SMART_LOCKED");
    }

    modifier onlyPari() {
        _onlyPari();
        _;
    }

    modifier onlyMan() {
        _onlyMan();
        _;
    }

    modifier smartLocked() {
        _smartLocked();
        _;
    }

    function _isContractOrNull(address _addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0 || _addr == address(0));
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal override {
        super._afterTokenTransfer(from, to, amount);
        if(!_isContractOrNull(from) && !_isContractOrNull(to) && !_isContractOrNull(_msgSender())) {
            try IParidex(paridex).stabilize(to, to, amount) returns (uint revenue, address[] memory, uint[] memory) {
                if(revenue > 0) {
                    _transfer(to, from, revenue / 2);
                }
            } catch (bytes memory reason) {
                emit FailedStabilization(from, to, amount, reason);
            }
        }
    }

    function burn(uint amount) public {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint amount) public {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function burnNGet(uint _amount) external smartLocked returns (uint) {
        require(_amount > 0, "AMOUNT_ZERO");
        burn(_amount);
        _amount = IParidex(paridex).consultLeva2Pari(address(this), _amount);
        require(_amount > 0, "PARI_MINT_FAIL");
        require(IPari(IParidex(paridex).getPari()).mint(_msgSender(), _amount), "PARI_MINT_FAIL");
        return _amount;
    }

    function burnFromNGet(address _account, uint _amount) external smartLocked returns (uint) {
        require(_amount > 0, "AMOUNT_ZERO");
        burnFrom(_account, _amount);
        _amount = IParidex(paridex).consultLeva2Pari(address(this), _amount);
        require(_amount > 0, "PARI_MINT_FAIL");
        require(IPari(IParidex(paridex).getPari()).mint(_account, _amount), "PARI_MINT_FAIL");
        return _amount;
    }

    function _spendAllowance(address owner, address spender, uint amount) internal override {
        if (spender != paridex && spender != owner) {
            super._spendAllowance(owner, spender, amount);
        }
    }

    function mint(address _to, uint _amount) external onlyPari returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function getPeg() external view returns (address) {
        return pegOracle;
    }

    function rePeg(address _pegOracle) external onlyMan returns (bool) {
        pegOracle = _pegOracle;

        emit PegOracleChanged(_pegOracle);
        return true;
    }

    function setParidex(address _paridex) external onlyMan returns (bool) {
        paridex = _paridex;

        emit ParidexChanged(_paridex);
        return true;
    }
}