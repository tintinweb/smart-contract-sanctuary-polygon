// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface BColor {
    function getColor() external view returns (bytes32);
}

contract BBronze is BColor {
    function getColor() external pure override returns (bytes32) {
        return bytes32("BRONZE");
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BColor.sol";

contract BConst is BBronze {
    uint256 public constant BONE = 10**18;

    uint256 public constant MIN_BOUND_TOKENS = 2;
    uint256 public constant MAX_BOUND_TOKENS = 8;

    uint256 public constant MIN_FEE = BONE / 10**6;
    uint256 public constant MAX_FEE = BONE / 10;
    uint256 public constant EXIT_FEE = 0;

    uint256 public constant MIN_WEIGHT = BONE;
    uint256 public constant MAX_WEIGHT = BONE * 50;
    uint256 public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint256 public constant MIN_BALANCE = BONE / 10**12;

    uint256 public constant INIT_POOL_SUPPLY = BONE * 100;

    uint256 public constant MIN_BPOW_BASE = 1 wei;
    uint256 public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant BPOW_PRECISION = BONE / 10**10;

    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BNum.sol";

contract BMath is BBronze, BConst, BNum {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) public pure returns (uint256 spotPrice) {
        uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint256 ratio = bdiv(numer, denom);
        uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
        return (spotPrice = bmul(ratio, scale));
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint256 adjustedIn = bsub(BONE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint256 foo = bpow(y, weightRatio);
        uint256 bar = bsub(BONE, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountIn) {
        uint256 weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint256 diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint256 y = bdiv(tokenBalanceOut, diff);
        uint256 foo = bpow(y, weightRatio);
        foo = bsub(foo, BONE);
        tokenAmountIn = bsub(BONE, swapFee);
        tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/

    // Charge the trading fee for the proportion of tokenAi
    ///  which is implicitly traded to the other pool tokens.
    // That proportion is (1- weightTokenIn)
    // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 poolAmountOut) {
        uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        uint256 tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

        uint256 newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint256 tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

        // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
        uint256 poolRatio = bpow(tokenInRatio, normalizedWeight);
        uint256 newPoolSupply = bmul(poolRatio, poolSupply);
        poolAmountOut = bsub(newPoolSupply, poolSupply);
        return poolAmountOut;
    }

    /**********************************************************************************************
    // calcSingleInGivenPoolOut                                                                  //
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
    // bI = balanceIn          tAi =  --------------------------------------------               //
    // wI = weightIn                              /      wI  \                                   //
    // tW = totalWeight                          |  1 - ----  |  * sF                            //
    // sF = swapFee                               \      tW  /                                   //
    **********************************************************************************************/
    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountIn) {
        uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint256 newPoolSupply = badd(poolSupply, poolAmountOut);
        uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

        //uint newBalTi = poolRatio^(1/weightTi) * balTi;
        uint256 boo = bdiv(BONE, normalizedWeight);
        uint256 tokenInRatio = bpow(poolRatio, boo);
        uint256 newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
        uint256 tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
        // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
        //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
        //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
        uint256 zar = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint256 poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
        uint256 newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
        uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint256 tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
        uint256 newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint256 tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);

        // charge swap fee on the output token side
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcPoolInGivenSingleOut                                                                  //
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
    // ps = poolSupply                 \\ -----------------------------------/                /  //
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
    // tW = totalWeight           -------------------------------------------------------------  //
    // sF = swapFee                                        ( 1 - eF )                            //
    // eF = exitFee                                                                              //
    **********************************************************************************************/
    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) public pure returns (uint256 poolAmountIn) {
        // charge swap fee on the output token side
        uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
        uint256 zoo = bsub(BONE, normalizedWeight);
        uint256 zar = bmul(zoo, swapFee);
        uint256 tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

        uint256 newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint256 tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

        //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
        uint256 poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint256 newPoolSupply = bmul(poolRatio, poolSupply);
        uint256 poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

        // charge exit fee on the pool token side
        // pAi = pAiAfterExitFee/(1-exitFee)
        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
        return poolAmountIn;
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BConst.sol";

contract BNum is BConst {
    function btoi(uint256 a) internal pure returns (uint256) {
        return a / BONE;
    }

    function bfloor(uint256 a) internal pure returns (uint256) {
        return btoi(a) * BONE;
    }

    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole = bfloor(exp);
        uint256 remain = bsub(exp, whole);

        uint256 wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256) {
        // term 0:
        uint256 a = exp;
        (uint256 x, bool xneg) = bsubSign(base, BONE);
        uint256 term = BONE;
        uint256 sum = term;
        bool negative = false;

        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;
            (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BToken.sol";
import "./BMath.sol";

contract BPool is BBronze, BToken, BMath {
    struct Record {
        bool bound; // is token bound to pool
        uint256 index; // private
        uint256 denorm; // denormalized weight
        uint256 balance;
    }

    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut
    );

    event LOG_JOIN(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);

    event LOG_EXIT(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);

    event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        require(!_mutex, "ERR_REENTRY");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        require(!_mutex, "ERR_REENTRY");
        _;
    }

    bool private _mutex;

    address private _factory; // BFactory address to push token exitFee to
    address private _controller; // has CONTROL role
    bool private _publicSwap; // true if PUBLIC can call SWAP functions

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint256 private _swapFee;
    bool private _finalized;

    address[] private _tokens;
    mapping(address => Record) private _records;
    uint256 private _totalWeight;

    constructor() {
        _controller = msg.sender;
        _factory = msg.sender;
        _swapFee = MIN_FEE;
        _publicSwap = false;
        _finalized = false;
    }

    function isPublicSwap() external view returns (bool) {
        return _publicSwap;
    }

    function isFinalized() external view returns (bool) {
        return _finalized;
    }

    function isBound(address t) external view returns (bool) {
        return _records[t].bound;
    }

    function getNumTokens() external view returns (uint256) {
        return _tokens.length;
    }

    function getCurrentTokens() external view _viewlock_ returns (address[] memory tokens) {
        return _tokens;
    }

    function getFinalTokens() external view _viewlock_ returns (address[] memory tokens) {
        require(_finalized, "ERR_NOT_FINALIZED");
        return _tokens;
    }

    function getDenormalizedWeight(address token) external view _viewlock_ returns (uint256) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].denorm;
    }

    function getTotalDenormalizedWeight() external view _viewlock_ returns (uint256) {
        return _totalWeight;
    }

    function getNormalizedWeight(address token) external view _viewlock_ returns (uint256) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        uint256 denorm = _records[token].denorm;
        return bdiv(denorm, _totalWeight);
    }

    function getBalance(address token) external view _viewlock_ returns (uint256) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].balance;
    }

    function getSwapFee() external view _viewlock_ returns (uint256) {
        return _swapFee;
    }

    function getController() external view _viewlock_ returns (address) {
        return _controller;
    }

    function setSwapFee(uint256 swapFee) external _logs_ _lock_ {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(swapFee >= MIN_FEE, "ERR_MIN_FEE");
        require(swapFee <= MAX_FEE, "ERR_MAX_FEE");
        _swapFee = swapFee;
    }

    function setController(address manager) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _controller = manager;
    }

    function setPublicSwap(bool public_) external _logs_ _lock_ {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _publicSwap = public_;
    }

    function finalize() external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_finalized, "ERR_IS_FINALIZED");
        require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");

        _finalized = true;
        _publicSwap = true;

        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
    }

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    )
        external
        _logs_ // _lock_  Bind does not lock because it jumps to `rebind`, which does
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0, // balance and denorm will be validated
            balance: 0 // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance, denorm);
    }

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) public _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
        require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

        // Adjust the denorm and totalWeight
        uint256 oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
            require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
        } else if (denorm < oldWeight) {
            _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
        }
        _records[token].denorm = denorm;

        // Adjust the balance record and actual token balance
        uint256 oldBalance = _records[token].balance;
        _records[token].balance = balance;
        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
        } else if (balance < oldBalance) {
            // In this case liquidity is being withdrawn, so charge EXIT_FEE
            uint256 tokenBalanceWithdrawn = bsub(oldBalance, balance);
            uint256 tokenExitFee = bmul(tokenBalanceWithdrawn, EXIT_FEE);
            _pushUnderlying(token, msg.sender, bsub(tokenBalanceWithdrawn, tokenExitFee));
            _pushUnderlying(token, _factory, tokenExitFee);
        }
    }

    function unbind(address token) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        uint256 tokenBalance = _records[token].balance;
        uint256 tokenExitFee = bmul(tokenBalance, EXIT_FEE);

        _totalWeight = bsub(_totalWeight, _records[token].denorm);

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint256 index = _records[token].index;
        uint256 last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({bound: false, index: 0, denorm: 0, balance: 0});

        _pushUnderlying(token, msg.sender, bsub(tokenBalance, tokenExitFee));
        _pushUnderlying(token, _factory, tokenExitFee);
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token) external _logs_ _lock_ {
        require(_records[token].bound, "ERR_NOT_BOUND");
        _records[token].balance = IERC20Balancer(token).balanceOf(address(this));
    }

    function getSpotPrice(address tokenIn, address tokenOut) external view _viewlock_ returns (uint256 spotPrice) {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
    }

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external
        view
        _viewlock_
        returns (uint256 spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, 0);
    }

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external _logs_ _lock_ {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint256 poolTotal = totalSupply();
        uint256 ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external _logs_ _lock_ {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint256 poolTotal = totalSupply();
        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
        uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
        uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(_factory, exitFee);
        _burnPoolShare(pAiAfterExitFee);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;
            uint256 tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
            _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
    }

    function calcExitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
        external
        view
        returns (uint256[] memory)
    {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint256 poolTotal = totalSupply();
        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
        uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
        uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);

        uint256[] memory _amounts = new uint256[](_tokens.length * 2);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint256 bal = _records[t].balance;

            _amounts[i] = bmul(ratio, bal);
            _amounts[_tokens.length + i] = minAmountsOut[i];
            require(_amounts[i] >= minAmountsOut[i], "ERR_LIMIT_OUT");
        }

        return _amounts;
    }

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external _logs_ _lock_ returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        uint256 spotPriceBefore =
            calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountOut = calcOutGivenIn(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountIn,
            _swapFee
        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return (tokenAmountOut, spotPriceAfter);
    }

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external _logs_ _lock_ returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

        uint256 spotPriceBefore =
            calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountIn = calcInGivenOut(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountOut,
            _swapFee
        );
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            _swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return (tokenAmountIn, spotPriceAfter);
    }

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external _logs_ _lock_ returns (uint256 poolAmountOut) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        Record storage inRecord = _records[tokenIn];

        poolAmountOut = calcPoolOutGivenSingleIn(
            inRecord.balance,
            inRecord.denorm,
            _totalSupply,
            _totalWeight,
            tokenAmountIn,
            _swapFee
        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return poolAmountOut;
    }

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external _logs_ _lock_ returns (uint256 tokenAmountIn) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");

        Record storage inRecord = _records[tokenIn];

        tokenAmountIn = calcSingleInGivenPoolOut(
            inRecord.balance,
            inRecord.denorm,
            _totalSupply,
            _totalWeight,
            poolAmountOut,
            _swapFee
        );

        require(tokenAmountIn != 0, "ERR_MATH_APPROX");
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);

        emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return tokenAmountIn;
    }

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external _logs_ _lock_ returns (uint256 tokenAmountOut) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");

        Record storage outRecord = _records[tokenOut];

        tokenAmountOut = calcSingleOutGivenPoolIn(
            outRecord.balance,
            outRecord.denorm,
            _totalSupply,
            _totalWeight,
            poolAmountIn,
            _swapFee
        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(bsub(poolAmountIn, exitFee));
        _pushPoolShare(_factory, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return tokenAmountOut;
    }

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external _logs_ _lock_ returns (uint256 poolAmountIn) {
        require(_finalized, "ERR_NOT_FINALIZED");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

        Record storage outRecord = _records[tokenOut];

        poolAmountIn = calcPoolInGivenSingleOut(
            outRecord.balance,
            outRecord.denorm,
            _totalSupply,
            _totalWeight,
            tokenAmountOut,
            _swapFee
        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

        emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(bsub(poolAmountIn, exitFee));
        _pushPoolShare(_factory, exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return poolAmountIn;
    }

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety

    function _pullUnderlying(
        address erc20,
        address from,
        uint256 amount
    ) internal {
        bool xfer = IERC20Balancer(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pushUnderlying(
        address erc20,
        address to,
        uint256 amount
    ) internal {
        bool xfer = IERC20Balancer(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pullPoolShare(address from, uint256 amount) internal {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint256 amount) internal {
        _push(to, amount);
    }

    function _mintPoolShare(uint256 amount) internal {
        _mint(amount);
    }

    function _burnPoolShare(uint256 amount) internal {
        _burn(amount);
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BNum.sol";

interface IERC20Balancer {
    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);
}

contract BTokenBase is BNum {
    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) internal _allowance;
    uint256 internal _totalSupply;

    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    function _mint(uint256 amt) internal {
        _balance[address(this)] = badd(_balance[address(this)], amt);
        _totalSupply = badd(_totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint256 amt) internal {
        require(_balance[address(this)] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        _totalSupply = bsub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(
        address src,
        address dst,
        uint256 amt
    ) internal {
        require(_balance[src] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[src] = bsub(_balance[src], amt);
        _balance[dst] = badd(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint256 amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint256 amt) internal {
        _move(from, address(this), amt);
    }
}

contract BToken is BTokenBase, IERC20Balancer {
    string private _name = "Balancer Pool Token";
    string private _symbol = "BPT";
    uint8 private _decimals = 18;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function allowance(address src, address dst) external view override returns (uint256) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view override returns (uint256) {
        return _balance[whom];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function approve(address dst, uint256 amt) external override returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint256 amt) external returns (bool) {
        _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint256 amt) external returns (bool) {
        uint256 oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = bsub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint256 amt) external override returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external override returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender], "ERR_BTOKEN_BAD_CALLER");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMathUint256.sol";
import "./SafeMathInt256.sol";

abstract contract CalculateLinesToBPoolOdds {
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    uint256 constant MAX_BPOOL_WEIGHT = 50e18;

    function ratioOdds(uint256[] memory _proportions) internal pure returns (uint256[] memory _odds) {
        uint256 _total = sum(_proportions);

        _odds = new uint256[](_proportions.length);
        for (uint256 i = 0; i < _proportions.length; i++) {
            _odds[i] = (MAX_BPOOL_WEIGHT).mul(_proportions[i]).div(_total);
            require(_odds[i] >= 1e18, "min outcome weight is 2%");
        }
    }

    function sum(uint256[] memory _numbers) private pure returns (uint256 _sum) {
        for (uint256 i = 0; i < _numbers.length; i++) {
            _sum += _numbers[i];
        }
    }

    function evenOdds(bool _invalid, uint256 _outcomes) internal pure returns (uint256[] memory _odds) {
        uint256 _size = _outcomes + (_invalid ? 1 : 0);
        _odds = new uint256[](_size);

        if (_invalid) _odds[0] = 1e18; // 2%

        uint256 _each = (_invalid ? 49e18 : 50e18) / _outcomes;
        for (uint256 i = _invalid ? 1 : 0; i < _size; i++) {
            _odds[i] = _each;
        }
    }

    function oddsFromLines(int256 _moneyline1, int256 _moneyline2) internal pure returns (uint256[] memory _odds) {
        uint256 _odds1 = __calcLineToOdds(_moneyline1);
        uint256 _odds2 = __calcLineToOdds(_moneyline2);

        uint256 _total = _odds1 + _odds2;

        _odds1 = uint256(49e18).mul(_odds1).div(_total);
        _odds2 = uint256(49e18).mul(_odds2).div(_total);

        // Moneyline odds are too skewed: would have under 2% odds.
        require(_odds1 >= 1e18);
        require(_odds2 >= 1e18);

        _odds = new uint256[](3);
        _odds[0] = 1e18; // Invalid, 2%
        _odds[1] = _odds1;
        _odds[2] = _odds2;
    }

    function __calcLineToOdds(int256 _line) internal pure returns (uint256) {
        if (_line < 0) {
            // favored
            uint256 _posLine = uint256(-_line);
            return _posLine.mul(49e18).div(_posLine.add(100)); // 49e18 * _line / (_line + 100)
        } else {
            // underdog
            return uint256(4900e18).div(uint256(_line).add(100)); // 49e18 * 100 / (_line + 100)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../turbo/AbstractMarketFactoryV3.sol";
import "./Sport.sol";
import "./CalculateLinesToBPoolOdds.sol";
import "./TokenNamesFromTeams.sol";

abstract contract HasHeadToHeadMarket is
    AbstractMarketFactoryV3,
    Sport,
    CalculateLinesToBPoolOdds,
    TokenNamesFromTeams
{
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    uint256 private headToHeadMarketType;
    string private noContestName;

    uint256 constant HeadToHeadAway = 1;
    uint256 constant HeadToHeadHome = 2;

    constructor(uint256 _marketType, string memory _noContestName) {
        headToHeadMarketType = _marketType;
        noContestName = _noContestName;
    }

    function makeHeadToHeadMarket(
        int256[2] memory _moneylines,
        string memory _homeTeamName,
        string memory _awayTeamName
    ) internal returns (uint256) {
        // moneylines is [home,away] but the outcomes are listed [NC,away,home] so they must be reversed
        return
            makeSportsMarket(
                noContestName,
                _homeTeamName,
                _awayTeamName,
                oddsFromLines(_moneylines[1], _moneylines[0])
            );
    }

    function resolveHeadToHeadMarket(
        uint256 _marketId,
        uint256 _homeScore,
        uint256 _awayScore
    ) internal {
        uint256 _shareTokenIndex = calcHeadToHeadWinner(_homeScore, _awayScore);
        endMarket(_marketId, _shareTokenIndex);
    }

    function calcHeadToHeadWinner(uint256 _homeScore, uint256 _awayScore) private pure returns (uint256) {
        if (_homeScore > _awayScore) {
            return HeadToHeadHome;
        } else if (_homeScore < _awayScore) {
            return HeadToHeadAway;
        } else {
            return NoContest;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Full is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IOwnable {
    function getOwner() external view returns (address);

    function transferOwnership(address _newOwner) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

abstract contract LineHelper {
    function build1Line() internal pure returns (int256[] memory _lines) {
        _lines = new int256[](1);
    }

    function build3Lines(int256 _homeSpread, int256 _totalScore) internal pure returns (int256[] memory _lines) {
        _lines = new int256[](3);
        // 0 is the Head-to-Head market, which has no lines
        _lines[1] = addHalfPoint(_homeSpread);
        _lines[2] = addHalfPoint(_totalScore);
    }

    function addHalfPoint(int256 _line) internal pure returns (int256) {
        // The line is a quantity of tenths. So 55 is 5.5 and -6 is -60.
        // If the line is a whole number then make it a half point more extreme, to eliminate ties.
        // So 50 becomes 55, -60 becomes -65, and 0 becomes 5.
        if (_line >= 0 && _line % 10 == 0) {
            return _line + 5;
        } else if (_line < 0 && (-_line) % 10 == 0) {
            return _line - 5;
        } else {
            return _line;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Ownable.sol";

abstract contract ManagedByLink is Ownable {
    event LinkNodeChanged(address newLinkNode);

    address public linkNode;

    constructor(address _linkNode) {
        linkNode = _linkNode;
    }

    function setLinkNode(address _newLinkNode) external onlyOwner {
        linkNode = _newLinkNode;
        emit LinkNodeChanged(_newLinkNode);
    }

    modifier onlyLinkNode() {
        require(msg.sender == linkNode);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IOwnable.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable is IOwnable {
    address internal owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOwner() public view override returns (address) {
        return owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public override onlyOwner returns (bool) {
        require(_newOwner != address(0));
        onTransferOwnership(owner, _newOwner);
        owner = _newOwner;
        return true;
    }

    // Subclasses of this token may want to send additional logs through the centralized Augur log emitter contract
    function onTransferOwnership(address, address) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Sport.sol";
import "./ManagedByLink.sol";

abstract contract ResolvesByFiat is Sport, ManagedByLink {
    function resolveEvent(
        uint256 _eventId,
        SportsEventStatus _eventStatus,
        uint256 _homeTeamId, // for verifying team stability
        uint256 _awayTeamId, // for verifying team stability
        uint256 _whoWon
    ) public onlyLinkNode {
        SportsEvent storage _event = sportsEvents[_eventId];

        require(_event.status == SportsEventStatus.Scheduled);
        require(SportsEventStatus(_eventStatus) != SportsEventStatus.Scheduled);

        if (eventIsNoContest(_event, _eventStatus, _homeTeamId, _awayTeamId, _whoWon)) {
            resolveInvalidEvent(_eventId);
        } else {
            resolveValidEvent(_event, _whoWon);
        }

        sportsEvents[_eventId].status = _eventStatus;
    }

    function resolveValidEvent(SportsEvent memory _event, uint256 _whoWon) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

abstract contract Rewardable {
    // Rewards will be paid out over the lifetime of an event.
    // An value of zero will start rewards immediately and proceed based on the values set in master chef.

    // _Id here is the market id passed to the amm factory when creating a pool.
    function getRewardEndTime(uint256 _marketId) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * @title SafeMathInt256
 * @dev Int256 math operations with safety checks that throw on error
 */
library SafeMathInt256 {
    // Signed ints with n bits can range from -2**(n-1) to (2**(n-1) - 1)
    int256 private constant INT256_MIN = -2**(255);
    int256 private constant INT256_MAX = (2**(255) - 1);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // No need to check for dividing by 0 -- Solidity automatically throws on division by 0
        int256 c = a / b;
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        require(((a >= 0) && (b >= a - INT256_MAX)) || ((a < 0) && (b <= a - INT256_MIN)));
        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        require(((a >= 0) && (b <= INT256_MAX - a)) || ((a < 0) && (b >= INT256_MIN - a)));
        return a + b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function abs(int256 a) internal pure returns (int256) {
        if (a < 0) {
            return -a;
        }
        return a;
    }

    function getInt256Min() internal pure returns (int256) {
        return INT256_MIN;
    }

    function getInt256Max() internal pure returns (int256) {
        return INT256_MAX;
    }

    // Float [fixed point] Operations
    function fxpMul(
        int256 a,
        int256 b,
        int256 base
    ) internal pure returns (int256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(
        int256 a,
        int256 b,
        int256 base
    ) internal pure returns (int256) {
        return div(mul(a, base), b);
    }

    function sqrt(int256 y) internal pure returns (int256 z) {
        if (y > 3) {
            int256 x = (y + 1) / 2;
            z = y;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * @title SafeMathUint256
 * @dev Uint256 math operations with safety checks that throw on error
 */
library SafeMathUint256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function subS(
        uint256 a,
        uint256 b,
        string memory message
    ) internal pure returns (uint256) {
        require(b <= a, message);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            uint256 x = (y + 1) / 2;
            z = y;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getUint256Min() internal pure returns (uint256) {
        return 0;
    }

    function getUint256Max() internal pure returns (uint256) {
        // 2 ** 256 - 1
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function isMultipleOf(uint256 a, uint256 b) internal pure returns (bool) {
        return a % b == 0;
    }

    // Float [fixed point] Operations
    function fxpMul(
        uint256 a,
        uint256 b,
        uint256 base
    ) internal pure returns (uint256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(
        uint256 a,
        uint256 b,
        uint256 base
    ) internal pure returns (uint256) {
        return div(mul(a, base), b);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../turbo/AbstractMarketFactoryV3.sol";
import "./LineHelper.sol";

abstract contract Sport is AbstractMarketFactoryV3, LineHelper {
    event SportsEventCreated(
        uint256 id,
        uint256[] markets,
        int256[] lines,
        uint256 homeTeamId,
        uint256 awayTeamId,
        string homeTeamName,
        string awayTeamName,
        uint256 estimatedStartTime
    );

    enum SportsEventStatus {Unknown, Scheduled, Final, Postponed, Canceled}
    struct SportsEvent {
        SportsEventStatus status;
        uint256[] markets;
        int256[] lines;
        uint256 estimatedStartTime;
        uint256 homeTeamId;
        uint256 awayTeamId;
        string homeTeamName;
        string awayTeamName;
        uint256 homeScore;
        uint256 awayScore;
    }
    // EventId => EventDetails
    mapping(uint256 => SportsEvent) public sportsEvents;
    uint256[] public listOfSportsEvents;
    mapping(uint256 => uint256) public marketIdToEventIdMapping;
    uint256 constant NoContest = 0;

    function eventCount() public view returns (uint256) {
        return listOfSportsEvents.length;
    }

    function getSportsEvent(uint256 _eventId) public view returns (SportsEvent memory) {
        return sportsEvents[_eventId];
    }

    function getSportsEventByIndex(uint256 _index) public view returns (SportsEvent memory _event, uint256 _eventId) {
        _eventId = listOfSportsEvents[_index];
        _event = getSportsEvent(_eventId);
    }

    function makeSportsEvent(
        uint256 _eventId,
        uint256[] memory _markets,
        int256[] memory _lines,
        uint256 _estimatedStartTime,
        uint256 _homeTeamId,
        uint256 _awayTeamId,
        string memory _homeTeamName,
        string memory _awayTeamName
    ) internal {
        // Cannot create markets for an event twice.
        require(sportsEvents[_eventId].status == SportsEventStatus.Unknown, "event exists");

        for (uint256 i = 0; i < _markets.length; i++) {
            marketIdToEventIdMapping[_markets[i]] = _eventId;
        }

        listOfSportsEvents.push(_eventId);
        sportsEvents[_eventId].status = SportsEventStatus.Scheduled; // new events must be Scheduled
        sportsEvents[_eventId].markets = _markets;
        sportsEvents[_eventId].lines = _lines;
        sportsEvents[_eventId].estimatedStartTime = _estimatedStartTime;
        sportsEvents[_eventId].homeTeamId = _homeTeamId;
        sportsEvents[_eventId].awayTeamId = _awayTeamId;
        sportsEvents[_eventId].homeTeamName = _homeTeamName;
        sportsEvents[_eventId].awayTeamName = _awayTeamName;
        // homeScore and awayScore default to zero, which is correct for new events

        emit SportsEventCreated(
            _eventId,
            _markets,
            _lines,
            _homeTeamId,
            _awayTeamId,
            _homeTeamName,
            _awayTeamName,
            _estimatedStartTime
        );
    }

    uint256 constant WhoWonUnknown = 0;
    uint256 constant WhoWonHome = 1;
    uint256 constant WhoWonAway = 2;
    uint256 constant WhoWonDraw = 3;

    function eventIsNoContest(
        SportsEvent memory _event,
        SportsEventStatus _eventStatus,
        uint256 _homeTeamId,
        uint256 _awayTeamId,
        uint256 _whoWon // pass in WhoWonUnknown if using a scoring sport
    ) internal pure returns (bool) {
        bool _draw = _whoWon == WhoWonDraw;
        bool _notFinal = _eventStatus != SportsEventStatus.Final;
        bool _unstableHomeTeamId = _event.homeTeamId != _homeTeamId;
        bool _unstableAwayTeamId = _event.awayTeamId != _awayTeamId;
        return _draw || _notFinal || _unstableHomeTeamId || _unstableAwayTeamId;
    }

    function resolveInvalidEvent(uint256 _eventId) internal {
        uint256[] memory _marketIds = sportsEvents[_eventId].markets;
        for (uint256 i = 0; i < _marketIds.length; i++) {
            uint256 _marketId = _marketIds[i];
            if (_marketId == 0) continue; // skip non-created markets
            endMarket(_marketId, NoContest);
        }
    }

    // TODO is this needed? getSportsEvent should do the same
    function getEventMarkets(uint256 _eventId) public view returns (uint256[] memory _markets) {
        uint256[] storage _original = sportsEvents[_eventId].markets;
        uint256 _len = _original.length;
        _markets = new uint256[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _markets[i] = _original[i];
        }
    }

    function getRewardEndTime(uint256 _marketId) public view override returns (uint256) {
        uint256 _eventId = marketIdToEventIdMapping[_marketId];
        return getSportsEvent(_eventId).estimatedStartTime;
    }
}

// TODO change this to work with the Fetcher contracts and use it there, since it's offchain-read-only.
abstract contract SportView is Sport {
    // Only usable off-chain. Gas cost can easily eclipse block limit.
    // Lists all events that could be resolved with a call to resolveEvent.
    // Not all will be resolvable because this does not ensure the game ended.
    function listResolvableEvents() external view returns (uint256[] memory) {
        uint256 _totalResolvable = countResolvableEvents();
        uint256[] memory _resolvableEvents = new uint256[](_totalResolvable);

        uint256 n = 0;
        for (uint256 i = 0; i < listOfSportsEvents.length; i++) {
            if (n > _totalResolvable) break;
            uint256 _eventId = listOfSportsEvents[i];
            if (isEventResolvable(_eventId)) {
                _resolvableEvents[n] = _eventId;
                n++;
            }
        }

        return _resolvableEvents;
    }

    function countResolvableEvents() internal view returns (uint256) {
        uint256 _totalResolvable = 0;
        for (uint256 i = 0; i < listOfSportsEvents.length; i++) {
            uint256 _eventId = listOfSportsEvents[i];
            if (isEventResolvable(_eventId)) {
                _totalResolvable++;
            }
        }
        return _totalResolvable;
    }

    // Returns true if a call to resolveEvent is potentially useful.
    function isEventResolvable(uint256 _eventId) internal view returns (bool) {
        uint256[] memory _markets = getEventMarkets(_eventId);

        bool _unresolved = false; // default because non-existing markets aren't resolvable
        for (uint256 i = 0; i < _markets.length; i++) {
            uint256 _marketId = _markets[i];
            if (_marketId != 0 && !isMarketResolved(_marketId)) {
                _unresolved = true;
                break;
            }
        }

        return _unresolved;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Sport.sol";

abstract contract TokenNamesFromTeams is Sport {
    uint256 constant Away = 1;
    uint256 constant Home = 2;

    function makeSportsMarket(
        string memory _noContestName,
        string memory _homeTeamName,
        string memory _awayTeamName,
        uint256[] memory _odds
    ) internal returns (uint256) {
        string[] memory _outcomeNames = makeOutcomeNames(_noContestName, _homeTeamName, _awayTeamName);
        return startMarket(msg.sender, _outcomeNames, _odds, true);
    }

    function makeOutcomeNames(
        string memory _noContestName,
        string memory _homeTeamName,
        string memory _awayTeamName
    ) private pure returns (string[] memory _names) {
        _names = new string[](3);
        _names[NoContest] = _noContestName;
        _names[Away] = _awayTeamName;
        _names[Home] = _homeTeamName;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

abstract contract Versioned {
    string internal version;

    constructor(string memory _version) {
        version = _version;
    }

    function getVersion() public view returns (string memory) {
        return version;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/IERC20Full.sol";
import "../balancer/BPool.sol";
import "./TurboShareTokenFactory.sol";
import "./FeePot.sol";
import "../libraries/Rewardable.sol";

abstract contract AbstractMarketFactoryV3 is TurboShareTokenFactory, Ownable, Rewardable {
    using SafeMathUint256 for uint256;

    event MarketCreated(uint256 id, string[] names, uint256[] initialOdds);
    event MarketResolved(uint256 id, address winner, uint256 winnerIndex, string winnerName);
    event MarketActivated(uint256 id);

    event SharesMinted(uint256 id, uint256 amount, address receiver);
    event SharesBurned(uint256 id, uint256 amount, address receiver);
    event WinningsClaimed(
        uint256 id,
        address winningOutcome,
        uint256 winningIndex,
        string winningName,
        uint256 amount,
        uint256 settlementFee,
        uint256 payout,
        address indexed receiver
    );

    IERC20Full public collateral;
    FeePot public feePot;

    // fees are out of 1e18 and only apply to new markets
    uint256 public stakerFee;
    uint256 public settlementFee;
    uint256 public protocolFee;

    address public protocol; // collects protocol fees

    uint256 public accumulatedProtocolFee = 0;
    // settlement address => amount of collateral
    mapping(address => uint256) public accumulatedSettlementFees;

    // How many shares equals one collateral.
    // Necessary to account for math errors from small numbers in balancer.
    // shares = collateral / shareFactor
    // collateral = shares * shareFactor
    uint256 public shareFactor;

    struct Market {
        address settlementAddress;
        OwnedERC20[] shareTokens;
        OwnedERC20 winner;
        uint256 winnerIndex;
        uint256 settlementFee;
        uint256 protocolFee;
        uint256 stakerFee;
        uint256 creationTimestamp;
        uint256 resolutionTimestamp; // when winner is declared
        uint256[] initialOdds;
        bool active; // false if not ready to use or if resolved
    }
    Market[] internal markets;

    uint256 private constant MAX_UINT = 2**256 - 1;

    constructor(
        address _owner,
        IERC20Full _collateral,
        uint256 _shareFactor,
        FeePot _feePot,
        uint256[3] memory _fees, // staker, settlement, protocol
        address _protocol
    ) {
        owner = _owner; // controls fees for new markets
        collateral = _collateral;
        shareFactor = _shareFactor;
        feePot = _feePot;
        stakerFee = _fees[0];
        settlementFee = _fees[1];
        protocolFee = _fees[2];
        protocol = _protocol;

        _collateral.approve(address(_feePot), MAX_UINT);

        // First market is always empty so that marketid zero means "no market"
        markets.push(makeEmptyMarket());
    }

    // Returns an empty struct if the market doesn't exist.
    // Can check market existence before calling this by comparing _id against markets.length.
    // Can check market existence of the return struct by checking that shareTokens[0] isn't the null address
    function getMarket(uint256 _id) public view returns (Market memory) {
        if (_id >= markets.length) {
            return makeEmptyMarket();
        } else {
            return markets[_id];
        }
    }

    function marketCount() public view returns (uint256) {
        return markets.length;
    }

    // Returns factory-specific details about a market.
    // function getMarketDetails(uint256 _id) public view returns (MarketDetails memory);

    function mintShares(
        uint256 _id,
        uint256 _shareToMint,
        address _receiver
    ) public {
        require(markets.length > _id);
        require(markets[_id].active);

        uint256 _cost = calcCost(_shareToMint);
        collateral.transferFrom(msg.sender, address(this), _cost);

        Market memory _market = markets[_id];
        for (uint256 _i = 0; _i < _market.shareTokens.length; _i++) {
            _market.shareTokens[_i].trustedMint(_receiver, _shareToMint);
        }

        emit SharesMinted(_id, _shareToMint, _receiver);
    }

    function burnShares(
        uint256 _id,
        uint256 _sharesToBurn,
        address _receiver
    ) public returns (uint256) {
        require(markets.length > _id);
        require(markets[_id].active);

        Market memory _market = markets[_id];
        for (uint256 _i = 0; _i < _market.shareTokens.length; _i++) {
            // errors if sender doesn't have enough shares
            _market.shareTokens[_i].trustedBurn(msg.sender, _sharesToBurn);
        }

        uint256 _payout = calcCost(_sharesToBurn);
        uint256 _protocolFee = _payout.mul(_market.protocolFee).div(10**18);
        uint256 _stakerFee = _payout.mul(_market.stakerFee).div(10**18);
        _payout = _payout.sub(_protocolFee).sub(_stakerFee);

        accumulatedProtocolFee += _protocolFee;
        collateral.transfer(_receiver, _payout);
        feePot.depositFees(_stakerFee);

        emit SharesBurned(_id, _sharesToBurn, msg.sender);
        return _payout;
    }

    function claimWinnings(uint256 _id, address _receiver) public returns (uint256) {
        require(isMarketResolved(_id), "market unresolved");

        Market memory _market = markets[_id];
        uint256 _winningShares = _market.winner.trustedBurnAll(msg.sender);
        _winningShares = (_winningShares / shareFactor) * shareFactor; // remove unusable dust

        uint256 _payout = calcCost(_winningShares); // will fail if there are no winnings to claim
        uint256 _settlementFee = _payout.mul(_market.settlementFee).div(10**18);
        _payout = _payout.sub(_settlementFee);

        accumulatedSettlementFees[_market.settlementAddress] += _settlementFee;
        collateral.transfer(_receiver, _payout);

        uint256 _winningIndex = _market.winnerIndex;
        string memory _winningName = _market.winner.name();

        emit WinningsClaimed(
            _id,
            address(_market.winner),
            _winningIndex,
            _winningName,
            _winningShares,
            _settlementFee,
            _payout,
            _receiver
        );
        return _payout;
    }

    function claimManyWinnings(uint256[] memory _ids, address _receiver) public returns (uint256) {
        uint256 _totalWinnings = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            _totalWinnings = _totalWinnings.add(claimWinnings(_ids[i], _receiver));
        }
        return _totalWinnings;
    }

    function claimSettlementFees(address _receiver) public returns (uint256) {
        uint256 _fees = accumulatedSettlementFees[msg.sender];
        if (_fees > 0) {
            accumulatedSettlementFees[msg.sender] = 0;
            collateral.transfer(_receiver, _fees);
        }
        return _fees;
    }

    function claimProtocolFees() public returns (uint256) {
        require(msg.sender == protocol || msg.sender == address(this));
        uint256 _fees = accumulatedProtocolFee;
        if (_fees > 0) {
            accumulatedProtocolFee = 0;
            collateral.transfer(protocol, _fees);
        }
        return _fees;
    }

    function setSettlementFee(uint256 _newFee) external onlyOwner {
        settlementFee = _newFee;
    }

    function setStakerFee(uint256 _newFee) external onlyOwner {
        stakerFee = _newFee;
    }

    function setProtocolFee(uint256 _newFee) external onlyOwner {
        protocolFee = _newFee;
    }

    function setProtocol(address _newProtocol, bool _claimFirst) external onlyOwner {
        if (_claimFirst) {
            claimProtocolFees();
        }
        protocol = _newProtocol;
    }

    function startMarket(
        address _settlementAddress,
        string[] memory _names,
        uint256[] memory _initialOdds,
        bool _active
    ) internal returns (uint256 _marketId) {
        _marketId = markets.length;
        markets.push(
            Market(
                _settlementAddress,
                createShareTokens(_names, address(this)),
                OwnedERC20(0),
                0,
                settlementFee,
                protocolFee,
                stakerFee,
                block.timestamp,
                0,
                _initialOdds,
                _active
            )
        );
        emit MarketCreated(_marketId, _names, _initialOdds);
        if (_active) {
            emit MarketActivated(_marketId);
        }
    }

    function activateMarket(uint256 _marketId) internal {
        markets[_marketId].active = true;
        emit MarketActivated(_marketId);
    }

    function makeEmptyMarket() private pure returns (Market memory) {
        OwnedERC20[] memory _tokens = new OwnedERC20[](0);
        uint256[] memory _initialOdds = new uint256[](0);
        return Market(address(0), _tokens, OwnedERC20(0), 0, 0, 0, 0, 0, 0, _initialOdds, false);
    }

    function endMarket(uint256 _marketId, uint256 _winningOutcome) internal {
        Market storage _market = markets[_marketId];
        OwnedERC20 _winner = _market.shareTokens[_winningOutcome];

        _market.winner = _winner;
        _market.active = false;
        _market.winnerIndex = _winningOutcome;
        _market.resolutionTimestamp = block.timestamp;
        string memory _outcomeName = _winner.name();
        emit MarketResolved(_marketId, address(_winner), _winningOutcome, _outcomeName);
    }

    function isMarketResolved(uint256 _id) public view returns (bool) {
        Market memory _market = markets[_id];
        return _market.winner != OwnedERC20(0);
    }

    // shares => collateral
    // Shares must be both greater than (or equal to) and divisible by shareFactor.
    function calcCost(uint256 _shares) public view returns (uint256) {
        require(_shares >= shareFactor && _shares % shareFactor == 0);
        return _shares / shareFactor;
    }

    // collateral => shares
    function calcShares(uint256 _collateralIn) public view returns (uint256) {
        return _collateralIn * shareFactor;
    }

    function onTransferOwnership(address, address) internal override {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/SafeMathUint256.sol";
import "../libraries/IERC20Full.sol";

contract FeePot is ERC20 {
    using SafeMathUint256 for uint256;

    uint256 internal constant magnitude = 2**128;

    IERC20Full public collateral;
    IERC20Full public reputationToken;

    uint256 public magnifiedFeesPerShare;

    mapping(address => uint256) public magnifiedFeesCorrections;
    mapping(address => uint256) public storedFees;

    uint256 public feeReserve;

    constructor(IERC20Full _collateral, IERC20Full _reputationToken)
        ERC20(
            string(abi.encodePacked("S_", _reputationToken.symbol())),
            string(abi.encodePacked("S_", _reputationToken.symbol()))
        )
    {
        collateral = _collateral;
        reputationToken = _reputationToken;

        require(_collateral != IERC20Full(0));
    }

    function depositFees(uint256 _amount) public returns (bool) {
        collateral.transferFrom(msg.sender, address(this), _amount);
        uint256 _totalSupply = totalSupply(); // after collateral.transferFrom to prevent reentrancy causing stale totalSupply
        if (_totalSupply == 0) {
            feeReserve = feeReserve.add(_amount);
            return true;
        }
        if (feeReserve > 0) {
            _amount = _amount.add(feeReserve);
            feeReserve = 0;
        }
        magnifiedFeesPerShare = magnifiedFeesPerShare.add((_amount).mul(magnitude) / _totalSupply);
        return true;
    }

    function withdrawableFeesOf(address _owner) public view returns (uint256) {
        return earnedFeesOf(_owner).add(storedFees[_owner]);
    }

    function earnedFeesOf(address _owner) public view returns (uint256) {
        uint256 _ownerBalance = balanceOf(_owner);
        uint256 _magnifiedFees = magnifiedFeesPerShare.mul(_ownerBalance);
        return _magnifiedFees.sub(magnifiedFeesCorrections[_owner]) / magnitude;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        storedFees[_from] = storedFees[_from].add(earnedFeesOf(_from));
        super._transfer(_from, _to, _amount);

        magnifiedFeesCorrections[_from] = magnifiedFeesPerShare.mul(balanceOf(_from));
        magnifiedFeesCorrections[_to] = magnifiedFeesCorrections[_to].add(magnifiedFeesPerShare.mul(_amount));
    }

    function stake(uint256 _amount) external returns (bool) {
        reputationToken.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        magnifiedFeesCorrections[msg.sender] = magnifiedFeesCorrections[msg.sender].add(
            magnifiedFeesPerShare.mul(_amount)
        );
        return true;
    }

    function exit(uint256 _amount) external returns (bool) {
        redeemInternal(msg.sender);
        _burn(msg.sender, _amount);
        reputationToken.transfer(msg.sender, _amount);
        magnifiedFeesCorrections[msg.sender] = magnifiedFeesPerShare.mul(balanceOf(msg.sender));
        return true;
    }

    function redeem() public returns (bool) {
        redeemInternal(msg.sender);
        magnifiedFeesCorrections[msg.sender] = magnifiedFeesPerShare.mul(balanceOf(msg.sender));
        return true;
    }

    function redeemInternal(address _account) internal {
        uint256 _withdrawableFees = withdrawableFeesOf(_account);
        if (_withdrawableFees > 0) {
            storedFees[_account] = 0;
            collateral.transfer(_account, _withdrawableFees);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./AbstractMarketFactoryV3.sol";
import "./FeePot.sol";
import "../libraries/SafeMathInt256.sol";
import "../libraries/Sport.sol";
import "../libraries/ResolveByFiat.sol";
import "../libraries/HasHeadToHeadMarket.sol";
import "../libraries/Versioned.sol";

contract MMAMarketFactoryV3 is AbstractMarketFactoryV3, SportView, ResolvesByFiat, HasHeadToHeadMarket, Versioned {
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    uint256 constant HeadToHead = 0;
    string constant InvalidName = "No Contest / Draw";

    constructor(
        address _owner,
        IERC20Full _collateral,
        uint256 _shareFactor,
        FeePot _feePot,
        uint256[3] memory _fees,
        address _protocol,
        address _linkNode
    )
        AbstractMarketFactoryV3(_owner, _collateral, _shareFactor, _feePot, _fees, _protocol)
        Versioned("v1.2.0")
        ManagedByLink(_linkNode)
        HasHeadToHeadMarket(HeadToHead, InvalidName)
    {}

    function createEvent(
        uint256 _eventId,
        string memory _homeTeamName,
        uint256 _homeTeamId,
        string memory _awayTeamName,
        uint256 _awayTeamId,
        uint256 _startTimestamp,
        int256[2] memory _moneylines // [home,away]
    ) public onlyLinkNode returns (uint256[] memory _marketIds) {
        _marketIds = makeMarkets(_moneylines, _homeTeamName, _awayTeamName);
        makeSportsEvent(
            _eventId,
            _marketIds,
            build1Line(),
            _startTimestamp,
            _homeTeamId,
            _awayTeamId,
            _homeTeamName,
            _awayTeamName
        );
    }

    function makeMarkets(
        int256[2] memory _moneylines,
        string memory _homeTeamName,
        string memory _awayTeamName
    ) internal returns (uint256[] memory _marketIds) {
        _marketIds = new uint256[](1);
        _marketIds[HeadToHead] = makeHeadToHeadMarket(_moneylines, _homeTeamName, _awayTeamName);
    }

    function resolveValidEvent(SportsEvent memory _event, uint256 _whoWon) internal override {
        resolveHeadToHeadMarket(_event.markets[HeadToHead], _whoWon);
    }

    function resolveHeadToHeadMarket(uint256 _marketId, uint256 _whoWon) internal {
        uint256 _shareTokenIndex = calcHeadToHeadWinner(_whoWon);
        endMarket(_marketId, _shareTokenIndex);
    }

    function calcHeadToHeadWinner(uint256 _whoWon) internal pure returns (uint256) {
        if (WhoWonHome == _whoWon) {
            return HeadToHeadHome;
        } else if (WhoWonAway == _whoWon) {
            return HeadToHeadAway;
        } else {
            return NoContest; // shouldn't happen here
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/Ownable.sol";

contract OwnedERC20 is ERC20, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        address _owner
    ) ERC20(name_, symbol_) {
        owner = _owner;
    }

    function trustedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _transfer(_from, _to, _amount);
    }

    function trustedMint(address _target, uint256 _amount) external onlyOwner {
        _mint(_target, _amount);
    }

    function trustedBurn(address _target, uint256 _amount) external onlyOwner {
        _burn(_target, _amount);
    }

    function trustedBurnAll(address _target) external onlyOwner returns (uint256) {
        uint256 _balance = balanceOf(_target);
        _burn(_target, _balance);
        return _balance;
    }

    function onTransferOwnership(address, address) internal override {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./OwnedShareToken.sol";

abstract contract TurboShareTokenFactory {
    function createShareTokens(string[] memory _names, address _owner) internal returns (OwnedERC20[] memory) {
        uint256 _numOutcomes = _names.length;
        OwnedERC20[] memory _tokens = new OwnedERC20[](_numOutcomes);

        for (uint256 _i = 0; _i < _numOutcomes; _i++) {
            _tokens[_i] = new OwnedERC20(_names[_i], _names[_i], _owner);
        }
        return _tokens;
    }
}

abstract contract TurboShareTokenFactoryV1 {
    function createShareTokens(
        string[] memory _names,
        string[] memory _symbols,
        address _owner
    ) internal returns (OwnedERC20[] memory) {
        uint256 _numOutcomes = _names.length;
        OwnedERC20[] memory _tokens = new OwnedERC20[](_numOutcomes);

        for (uint256 _i = 0; _i < _numOutcomes; _i++) {
            _tokens[_i] = new OwnedERC20(_names[_i], _symbols[_i], _owner);
        }
        return _tokens;
    }
}