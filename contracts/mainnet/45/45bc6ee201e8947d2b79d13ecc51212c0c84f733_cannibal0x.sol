/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

//SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
 function add(uint256 a, uint256 b) internal pure returns (uint256) {
  uint256 c = a + b;
  require(c >= a, "SafeMath: addition overflow");

  return c;
 }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
  return sub(a, b, "SafeMath: subtraction overflow");
 }
 function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
  require(b <= a, errorMessage);
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
  return div(a, b, "SafeMath: division by zero");
 }
 function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
  // Solidity only automatically asserts when dividing by 0
  require(b > 0, errorMessage);
  uint256 c = a / b;
  // assert(a == b * c + a % b); // There is no case in which this doesn't hold

  return c;
 }
}


/**
 * Interface for standard ERC-20

 // inherited by Burnable
 */
interface IERC20 {
 function totalSupply() external view returns (uint256);
 function decimals() external view returns (uint8);
 function symbol() external view returns (string memory);
 function name() external view returns (string memory);
 function getOwner() external view returns (address);
 function balanceOf(address account) external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function allowance(address _owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}




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



/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external  override view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external  override  view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external  override  view returns (uint8);
}
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
    function name() public view virtual override(IERC20, IERC20Metadata) returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override(IERC20, IERC20Metadata) returns (string memory) {
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
    function decimals() public view virtual override(IERC20, IERC20Metadata) returns (uint8) {
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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

    function getOwner() external view virtual override returns (address) {}
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
 address internal owner;
 mapping (address => bool) internal authorizations;

 constructor(address _owner) {
  owner = _owner;
  authorizations[_owner] = true;
 }

 /**
  * Function modifier to require caller to be contract owner
  */
 modifier onlyOwner() {
  require(isOwner(msg.sender), "!OWNER"); _;
 }

 /**
  * Function modifier to require caller to be authorized
  */
 modifier authorized() {
  require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
 }

 /**
  * Authorize address. Owner only
  */
 function authorize(address adr) public onlyOwner {
  authorizations[adr] = true;
 }

 /**
  * Remove address' authorization. Owner only
  */
 function unauthorize(address adr) public onlyOwner {
  authorizations[adr] = false;
 }

 /**
  * Check if address is owner
  */
 function isOwner(address account) public view returns (bool) {
  return account == owner;
 }

 /**
  * Return address' authorization status
  */
 function isAuthorized(address adr) public view returns (bool) {
  return authorizations[adr];
 }

 /**
  * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
  */
 function transferOwnership(address payable adr) public onlyOwner {
  owner = adr;
  authorizations[adr] = true;
  emit OwnershipTransferred(adr);
 }

 event OwnershipTransferred(address owner);
}

interface IUniswapV2Factory {
 function getPair(address tokenA, address tokenB) external view returns (address pair);
 function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
 function factory() external pure returns (address);
 function WETH() external pure returns (address);

 function addLiquidity(
  address tokenA,
  address tokenB,
  uint amountADesired,
  uint amountBDesired,
  uint amountAMin,
  uint amountBMin,
  address to,
  uint deadline
 ) external returns (uint amountA, uint amountB, uint liquidity);

 function addLiquidityETH(
  address token,
  uint amountTokenDesired,
  uint amountTokenMin,
  uint amountETHMin,
  address to,
  uint deadline
 ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

 function swapExactTokensForTokensSupportingFeeOnTransferTokens(
  uint amountIn,
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
 ) external;

 function swapExactETHForTokensSupportingFeeOnTransferTokens(
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
 ) external payable;

 function swapExactTokensForETHSupportingFeeOnTransferTokens(
  uint amountIn,
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
 ) external;
}


contract cannibal0x is ERC20("Cannibal0x DarkX", "dark0x"), Auth {
    using SafeMath for uint256;

    IERC20 public tokenBase; // DarkX
    address DEAD_ADDR = 0x000000000000000000000000000000000000dEaD;
    address ZERO_ADDR = 0x0000000000000000000000000000000000000000;
    address public WMATIC; // = 0x0d50f0B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // main net wmatic address
    address public MATIC_ADDR = 0x0000000000000000000000000000000000001010;
    uint8 constant _decimals = 9;
    uint256 public _maxTxAmount = type(uint256).max; //

    uint256 public totalCorrupters;
    uint256 public allTimeCorrupted;
    uint256 public allTimeRedeemed;
    uint256 public tokensDevoured;
    uint256 public baseRecaptured;
    uint256 public _totalSupply = 1000 * (10 ** _decimals);
    uint256 _numerRate = 8000; // fractional amount of cannibal0x
    uint256 public toScale;


    struct AddressRecords {
        uint256 totalCorrupted;
        uint256 totalRedeemed;
        uint256 timeOfCorruption;
    }

    mapping(address => AddressRecords) public addressRecord;

    event onCorruptTokens(address indexed _caller, uint256 _amount, uint256 _timestamp);
    event onUnstakeTokens(address indexed _caller, uint256 _amount, uint256 _timestamp);
    event onCannibalization(address indexed _caller, uint256 _amount, uint256 _timestamp);
    event onRecapture (address indexed _caller , uint256 _amount, uint256 _timestamp);


    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) unConsumeable; // internal operating cost exemption
    mapping(address => bool) isTxLimitExempt;

    uint256 liqFee = 500;
    uint256 selfCannibalize = 1300;
    uint256 devBudget = 200;
    uint256 recaptureFee = 500;
    uint256 totalConsumption = 2500; //25%
    uint256 feeDenom = 10000;

    address public autoLiq;
    address public developmentWallet;

    uint256 targetLiquidity = 30;
    uint256 targetLiquidityDenominator = 100;

    IUniswapV2Router public router;
    address defaultRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // uniswap address for all networks.

    // 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; //quickswap router polygon mainnet
    address public pair;

    uint256 public launchedAt;

    uint256 cannibalFrenzyNumerator = 200;
    uint256 cannibalFrenzyDenominator = 100;
    uint256 cannibalFrenzyTriggeredAt;
    uint256 cannibalFrenzyLength = 30 minutes;

    bool public autoCannibalizeEnabled = false;
    uint256 autoCannibalizeCap;
    uint256 autoCannibalizeAccumulator;
    uint256 valueToCannibalize;
    uint256 autoCannibalizeBlockPeriod;
    uint256 autoCannibalizeBlockLast;

    bool public swapEnabled = true;
    uint256 public minimumBeforeSwap = _totalSupply / 1000;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }



    /*
 constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol)
*/
    constructor(address _Base, address _router) Auth(msg.sender) {
        tokenBase = IERC20(_Base);
        router = _router != address(0) ? IUniswapV2Router(_router) : IUniswapV2Router(defaultRouter);
        WMATIC = router.WETH();
        pair = IUniswapV2Factory(router.factory()).createPair(WMATIC, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(tokenBase)][address(this)] = type(uint256).max;

        unConsumeable[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        unConsumeable[autoLiq] = true;
       // unConsumeable[pair] = true;
        isTxLimitExempt[pair];
        isTxLimitExempt[autoLiq] = true;
        unConsumeable[developmentWallet] = true;
        isTxLimitExempt[developmentWallet] = true;
        //unConsumeable[msg.sender] = true;
        //isTxLimitExempt[msg.sender] = true;
        // require(address _Base != address(0),"non-Zero address required");

        _balances[developmentWallet] = _totalSupply;
        emit Transfer(address(0), developmentWallet, _totalSupply);

         autoLiq = 0x6C77B1284165E20F6feFa55E854d2A9103EFFA9F;
         developmentWallet = 0x13d423e789F614c3d3e06F47895611c2bb6c2e91;
    }
        receive() external payable { }

    function setScale(uint256 numerRate) external authorized{
        require(_numerRate >= 5000, "Scale rate must be more than %50");
        _numerRate = numerRate;
        if (_numerRate == 0){ _numerRate = 8000;}
        feeDenom = 10000;
        toScale = _numerRate.div(feeDenom);

    }

    function setFeeReceivers(address _autoLiq, address _developmentWallet) external authorized {
        autoLiq = _autoLiq;
        developmentWallet = _developmentWallet;
    }
/*
    function statsOf(address _user) public view returns (uint256 _totalCorrupted, uint256 _totalRedeemed) {
        return (addressRecord[_user].totalCorrupted, addressRecord[_user].totalRedeemed);
    }*/

    function statsOf(address _user) public view returns (uint256 _totalCorrupted, uint256 _totalRedeemed, uint256 _timeOfCorruption) {
        return (addressRecord[_user].totalCorrupted, addressRecord[_user].totalRedeemed, addressRecord[_user].timeOfCorruption);
    }

    function baseToCorrupted(uint256 _amount) public view returns (uint256) {
        uint256 baseBalance = tokenBase.balanceOf(address(this));
        uint256 totalCannibal0x = this.totalSupply();
        uint256 _amt = _amount.mul(toScale);

        if (totalCannibal0x == 0 || baseBalance == 0) {
            return _amt;
        } else {
            return _amt.mul(totalCannibal0x).div(baseBalance);
        }
    }

    function corruptedToBase(uint256 _amount) public view returns (uint256 _baseAmount) {
        uint256 totalCannibal0x = this.totalSupply();
        return _amount.mul(tokenBase.balanceOf(address(this))).div(totalCannibal0x);
    }

    // Corrupt tokenBase, get cannibal0xs for staking
    function corruptTokens(uint256 amount) public {
      //check the user's balance
        uint256 userBalance = tokenBase.balanceOf(msg.sender);
                require(userBalance >= amount, "Buy more base tokens, and try again"); //if value is more than they have, BREAK

        uint256 baseBalance = tokenBase.balanceOf(address(this));
        uint256 totalCannibal0x = this.totalSupply();
        uint256 amt = amount.mul(toScale); /*  numer/feeDenom = (8000/10000) * 1e18;  */

        if (addressRecord[msg.sender].totalCorrupted == 0) {
            totalCorrupters += 1;
        }

        if (totalCannibal0x == 0 || baseBalance == 0) {
            uint256 mintAmount = amt;
            _mint(msg.sender, mintAmount);
        } else {
            uint256 mintAmount = amt.mul(totalCannibal0x).div(baseBalance);
            _mint(msg.sender, mintAmount);
        }

        tokenBase.transferFrom(msg.sender, address(this), amount);
        addressRecord[msg.sender].totalCorrupted += amt;
        // addressRecord[msg.sender].timeOfCorruption = block.timestamp;

        allTimeCorrupted += amt;
        emit onCorruptTokens(msg.sender, amt, block.timestamp);
    }


 function deposit() external payable {
    uint256 balanceBefore = tokenBase.balanceOf(address(this));

    address[] memory path = new address[](2);
    path[0] = WMATIC;
    path[1] = address(tokenBase);

    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
        0,
        path,
        address(this),
        block.timestamp
    );

    uint256 amount = tokenBase.balanceOf(address(this)).sub(balanceBefore);

    baseRecaptured += amount;
    emit onRecapture(msg.sender, amount, block.timestamp);
 }
    // Unstake cannibal0xs, claim back tokenBase
    function redeem(uint256 _cannibal0x) public {
        require(addressRecord[msg.sender].timeOfCorruption + 21 days < block.timestamp || unConsumeable[msg.sender]);
        uint256 totalCannibal0x = this.totalSupply();
        uint256 redeemAmount = _cannibal0x.mul(tokenBase.balanceOf(address(this))).div(totalCannibal0x);
        uint256 _userBalance = this.balanceOf(msg.sender);
        require(_userBalance >= _cannibal0x, "You need to corrupt more tokens first, and try again");


        _burn(msg.sender, _cannibal0x);
        tokenBase.transfer(msg.sender, redeemAmount);

        addressRecord[msg.sender].totalRedeemed += redeemAmount;
        allTimeRedeemed += redeemAmount;


        emit onUnstakeTokens(msg.sender, _cannibal0x, block.timestamp);
    }

    function canRecoverTokens(IERC20 token) internal view returns (bool) {
        return address(token) != address(this) && address(token) != address(tokenBase);
    }


      //function totalSupply() external view override returns (uint256) { return _totalSupply;}
      //function decimals() external pure override returns (uint8) { return _decimals; }
      //function symbol() external pure override returns (string memory) { return symbol; }
      //function name() external pure override returns (string memory) { return name; }
      //function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
// was commented out.
    function allowance(address holder, address spender) public view override returns (uint256) { return _allowances[holder][spender]; }
//
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }
// was commented out.
     function transfer(address recipient, uint256 amount) public override returns (bool) {
         return _transferFrom(msg.sender, recipient, amount);
    }

      function transferFrom(address sender, address recipient, uint256 amount) public  override returns (bool) {
       if(_allowances[sender][msg.sender] != type(uint256).max){ // New restrictions in solidity 0.8: https://docs.soliditylang.org/en/breaking/080-breaking-changes.html#new-restrictions
         _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
              }

       return _transferFrom(sender, recipient, amount);
    }
//
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkTxLimit(sender, amount);

        if (shouldSwapBack()) {
            swapBack();
        }
        if (shouldAutoCannibalize()) {
            doCannibalize();
        }

        if (!launched() && recipient == pair) {
            require(_balances[sender] > 0);
            launch();
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
// portion taken to be consumed/used by token
        uint256 amountReceived = shouldConsume(sender) ? doConsume(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldConsume(address sender) internal view returns (bool) {
        return !unConsumeable[sender]; // check address for costs exemption
    }

    function getTotalConsumption(bool selling) public view returns (uint256) {
        if (launchedAt + 1 >= block.number) {
            return feeDenom.sub(1);
        }
        if (selling && cannibalFrenzyTriggeredAt.add(cannibalFrenzyLength) > block.timestamp) {
            return getFrenziedConsumption();
        }
        return totalConsumption;
    }

    function getFrenziedConsumption() public view returns (uint256) {
        uint256 remainingTime = cannibalFrenzyTriggeredAt.add(cannibalFrenzyLength).sub(block.timestamp);
        uint256 feeIncrease = totalConsumption.mul(cannibalFrenzyNumerator).div(cannibalFrenzyDenominator).sub(totalConsumption);
        return totalConsumption.add(feeIncrease.mul(remainingTime).div(cannibalFrenzyLength));
    }
// takeFee |
    function doConsume(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalConsumption(receiver == pair)).div(feeDenom);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair && !inSwap && swapEnabled && _balances[address(this)] >= minimumBeforeSwap;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiqCosts = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liqFee;
        uint256 amountToLiquify = minimumBeforeSwap.mul(dynamicLiqCosts).div(totalConsumption).div(2);
        uint256 amountToSwap = minimumBeforeSwap.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WMATIC;

        uint256 balanceBefore = address(this).balance; // Eth or Native token.

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = totalConsumption.sub(dynamicLiqCosts.div(2));

        uint256 amountETHforLiq = amountETH.mul(dynamicLiqCosts).div(totalETHFee).div(2); // builds a trading pair, incase users wish to sell or buy cannibal0x tokens.
        uint256 amountETHforDevelopment = amountETH.mul(devBudget).div(totalETHFee); // just to keep the lights on. ;)
        uint256 amountETHforRecapure = amountETH.mul(recaptureFee).div(totalETHFee); // increases contract's poolBalance held in reserve++.

        try this.deposit{value: amountETHforRecapure}() {} catch {}
        (bool success, bytes memory data) = payable(developmentWallet).call{value: amountETHforDevelopment, gas: 30000}("");
        require(success); //Else, this reverts the tx.

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHforLiq}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiq,
                block.timestamp
            );
            emit AutoLiquify(amountETHforLiq, amountToLiquify);
        }
    }

    function shouldAutoCannibalize() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            autoCannibalizeEnabled &&
            autoCannibalizeBlockLast + autoCannibalizeBlockPeriod <= block.number &&
            address(this).balance >= valueToCannibalize;
    }

    function triggerFrenzy(uint256 amount, bool triggerCannibalMultiplier) external authorized {
        buyTokens(amount, DEAD_ADDR);
        if (triggerCannibalMultiplier) {
            cannibalFrenzyTriggeredAt = block.timestamp;
            emit cannibalFrenzyActive(cannibalFrenzyLength);
        }
        allTimeRedeemed += amount;
        emit onCannibalization(msg.sender, amount, block.timestamp);
    }

    function clearCannibalMultiplier() external authorized {
        cannibalFrenzyTriggeredAt = 0;
    }

    function doCannibalize() internal { // internal mechanical trigger
        buyTokens(valueToCannibalize, DEAD_ADDR);
        autoCannibalizeBlockLast = block.number;
        autoCannibalizeAccumulator = autoCannibalizeAccumulator.add(valueToCannibalize);
        if (autoCannibalizeAccumulator > autoCannibalizeCap) {
            autoCannibalizeEnabled = false;
        }
        tokensDevoured += valueToCannibalize;
        emit onCannibalization(msg.sender, valueToCannibalize, block.timestamp);
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WMATIC;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, to, block.timestamp);
    }

    function setAutoCannibalizeSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoCannibalizeEnabled = _enabled;
        autoCannibalizeCap = _cap;
        autoCannibalizeAccumulator = 0;
        valueToCannibalize = _amount;
        autoCannibalizeBlockPeriod = _period;
        autoCannibalizeBlockLast = block.number;
    }

    function setFrenzyMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        cannibalFrenzyNumerator = numerator;
        cannibalFrenzyDenominator = denominator;
        cannibalFrenzyLength = length;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setUnConsumeable(address holder, bool exempt) external authorized {
        unConsumeable[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setOperationCosts(
        uint256 _liqFee,
        uint256 _recaptureFee,
        uint256 _selfCannibalize,
        uint256 _devBudget,
        uint256 _feeDenom
    ) external authorized {
        liqFee = _liqFee;
        selfCannibalize = _selfCannibalize;
        devBudget = _devBudget;
        recaptureFee = _recaptureFee;

        totalConsumption = _liqFee.add(_selfCannibalize).add(_recaptureFee).add(_devBudget);
        feeDenom = _feeDenom;
        require(totalConsumption < feeDenom / 4);// 25% || 2500
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        minimumBeforeSwap = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD_ADDR)).sub(balanceOf(ZERO_ADDR));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    event cannibalFrenzyActive(uint256 duration);

    function getOwner() external view override returns (address) {}
}