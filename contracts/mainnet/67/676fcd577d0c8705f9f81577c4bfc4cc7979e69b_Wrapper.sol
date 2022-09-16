/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

// SPDX-License-Identifier: MIT
// File: contracts/IBEP20.sol


pragma solidity >=0.4.22 <0.9.0;

interface IBEP20 {
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
// File: contracts/Context.sol


pragma solidity >=0.4.22 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
// File: contracts/SafeMath.sol


pragma solidity >=0.4.22 <0.9.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}
// File: contracts/WrappedToken.sol


pragma solidity >=0.4.22 <0.9.0;

//imports




abstract contract WrappedToken is Context, IBEP20 {
	using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _divisor;

    string private constant _name   = "Wrapped Optimus";
    string private constant _symbol = "wOPT";
    uint256 public constant BIG_INT = ~uint128(0);
    
    constructor() {
        _divisor = BIG_INT;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply.div(divisor());
    }

    function divisor() public view returns (uint256) {
        return _divisor;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account].div(divisor());
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender].div(divisor());
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount.mul(divisor()));
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount.mul(divisor()));
        _transfer(from, to, amount.mul(divisor()));
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount.mul(divisor()));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender).mul(divisor()) + addedValue.mul(divisor()));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender); //no conversion required
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance.mul(divisor()) - subtractedValue.mul(divisor()));
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount.div(divisor()));

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount.div(divisor()));

        _afterTokenTransfer(from, to, amount.div(divisor()));
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount.div(divisor()));

        _totalSupply         += amount;
        _balances[account]   += amount;
        emit Transfer(address(0), account, amount.div(divisor()));

        _afterTokenTransfer(address(0), account, amount.div(divisor()));
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount.div(divisor()));

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount.div(divisor()));

        _afterTokenTransfer(account, address(0), amount.div(divisor()));
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount.div(divisor()));
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender).mul(divisor());
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount); // no conversion required
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
// File: contracts/Wrapper.sol


pragma solidity >=0.4.22 <0.9.0;

//imports




interface IREBASER {
    function divisor() external view returns (uint256);
}

contract Wrapper is WrappedToken {
	using SafeMath for uint256;

    address public admin;
    address public rebaser;

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not authorized.");
        _;
    }

    constructor(address _rebaser) {
        rebaser = _rebaser;
        admin   = msg.sender;
    }

    function wrap(uint256 amount) public {
        address sender = msg.sender;

        //transfer amount OPT2 from sender
        IBEP20(rebaser).transferFrom(sender, address(this), amount);

        //mint amount wOPT2
        _mint(sender, toWrapped(amount));
    }

    function unwrap(uint256 amount) public {
        address sender = msg.sender;

        //burn amount wOPT2
        _burn(sender, amount.mul(divisor()));

        //transfer amount OPT2 tokens to sender
        IBEP20(rebaser).transfer(sender, fromWrapped(amount.mul(divisor())));
    }

    function toWrapped(uint256 amountTokens) public view returns (uint256) {
        return amountTokens.mul(IREBASER(rebaser).divisor());
    }

    function fromWrapped(uint256 amountWrapped) public view returns (uint256) {
        return amountWrapped.div(IREBASER(rebaser).divisor());
    }

    function isAdmin(address atAddress) private view returns (bool) {
        return atAddress == admin;
    }

    function setRebaserAddress(address toAddress) external onlyAdmin {
        rebaser = toAddress;
    }
}