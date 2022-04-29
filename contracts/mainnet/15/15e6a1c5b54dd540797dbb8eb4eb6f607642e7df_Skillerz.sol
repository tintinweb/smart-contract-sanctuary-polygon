/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: Skillerz.sol



pragma solidity ^0.8.7;



/// @title Skillerz NFT Smart Contract

/// @notice This contract provides Skillerz NFTs in 20 batches with each 300 NFTs

/// @dev The initDict() function will set the base structure of the btaches. Advisable to updated baseURI values before installation.








contract Skillerz is ERC721Enumerable, Ownable{

    using Strings for uint256;



    /// @notice base attributes of the contract*/

    string public baseExtension = ".json";

    uint256 public tokenCounter;

    string public revealJson;

    bool public revealed;

    string public contractURI;

    bool public paused;



    /// @notice minting prices

    uint256 public mintingPrice = 0.03 ether;

    uint256 public whitelistPrice = 0.03 ether;



    /// @notice supply 

    uint256 public maxMintAmount = 10;

    uint256 public maxSupply = 6000;



    /// @notice Dict for the collections

    /// @dev idCounter is needed to know the next free tokenId per collection.

    struct Collections {

        bool active;

        uint256 maxSupply;

        string name;

        uint256 counter;

        string baseURI;

        uint256 reserved;

        uint256 reservedCounter;

        uint256 idCounter;

    }

    mapping(uint256 => Collections) public CollectionsDict;



    /// @notice whitelist params

    bool public whitelistActive = false;

    uint256 public maxWhitelistAmount = 3;

    uint256 public whitelistSize = 0;

    mapping(address => bool) public whitelist;

    mapping(address => uint256) whitelistClaimed;





    /// @notice events to be logged

    /// @dev only logging according to third party business interests

    event mintNFTCalled(address indexed caller, address indexed receiver, uint256 tokenID);

    event mintWhitelistNFTCalled(address indexed caller, address indexed receiver, uint256 tokenID);

    event mintingStateChanged(uint256 collectionID, bool newValue);

    event whitelistStateChanged(bool newValue);

    event pausedChanged(bool newValue);

    event mintingPriceChanged(uint256 oldPrice, uint256 newPrice);

    event whitelistPriceChanged(uint256 oldPrice, uint256 newPrice);

    event wethAddressChanged(address oldWETHAddress, address newWETHAddress);

    event pairUpdated(address oldPairAddress, address newPairAddress);



    /// @notice declaring ETH token, pair and tolerance value

    ERC20 token = ERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    

    /// @notice Polygon WMATIC/WETH pair

    address pricePair = 0xadbF1854e5883eB8aa7BAf50705338739e558E5b;



    /// @notice tolerance is used to accept volatility in MATIC/WETH pair

    uint256 private tolerance = 2;



    /// @notice constructor

    /// @dev sets approval that the owner can withdraw WETH from the contract 0xff.. as unlimited

    constructor(string memory _newContractURI, string memory _newRevealJson) ERC721("Skillerz", "SKZ") {

        tokenCounter = 0;

        contractURI = _newContractURI;

        revealJson = _newRevealJson;

        initDict();

        ERC20(token).approve(msg.sender, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    }



    /// @notice public minting. Free for contract owner

    /// @param _to addres to whom the NFT will be minted

    /// @param _mintAmount amount of NFTs that should be minted. Can not exeed maxMintAmount

    /// @param _collectionID the id of the batch number from which a NFT should be minted from

    /// @param _eth bool to check what currency is used. 1 = WETH, 0 = MATIC

    function mintNFT(address _to, uint256 _mintAmount, uint256 _collectionID, bool _eth) public payable {

        require(!paused, "Contract is paused!");



        require(whitelistActive == false, "Only Whitelist minting is allowed");

        require(CollectionsDict[_collectionID].active == true, "Minting of mintable collection is not active yet");

        require(tokenCounter + _mintAmount <= maxSupply, "Maximum of possible NFTs is reached");

        require(_mintAmount > 0, "At least one token must be minted");

        require(_mintAmount <= maxMintAmount, "Exceeds maximal possible tokens to mint on a try");

        require(CollectionsDict[_collectionID].counter + 

                _mintAmount +

                CollectionsDict[_collectionID].reserved - 

                CollectionsDict[_collectionID].reservedCounter <= 

                CollectionsDict[_collectionID].maxSupply, "Maximum Supply of the collection is reached"); 

 

        if(msg.sender != owner()) {

            if(_eth) {

                require(ERC20(token).balanceOf(msg.sender) >= mintingPrice * _mintAmount, "To less WETH in your wallet");

                require(ERC20(token).allowance(msg.sender, address(this)) >= mintingPrice * _mintAmount, "Not allowed to spend WETH");

                ERC20(token).transferFrom(msg.sender, address(this), mintingPrice * _mintAmount);

            } else {

                uint256 matic = getMATICvalue(mintingPrice * _mintAmount);

                require(msg.value >= matic - (matic * tolerance / 100), "Tolerance underflow: Amount of MATIC is to less");

                require(msg.value <= matic + (matic * tolerance / 100), "Tolerance overflow: Amount of MATIC is to high");

            }

        }   

        

        for (uint256 i = 1; i <= _mintAmount; i++) {

            tokenCounter++;

            CollectionsDict[_collectionID].counter++;

            CollectionsDict[_collectionID].idCounter++;

            _safeMint(_to, CollectionsDict[_collectionID].idCounter);

            emit mintNFTCalled(msg.sender, _to, tokenCounter);

        }   

    }



    /// @notice whitelist minting. Free for contract owner

    /// @param _to addres to whom the NFT will be minted

    /// @param _mintAmount amount of NFTs that should be minted. Can not exceed maxMintAmount

    /// @param _collectionID the id of the batch number from which a NFT should be minted from

    /// @param _eth bool to check what currency is used. 1 = WETH, 0 = MATIC

    function mintWhitelistNFT(address _to, uint256 _mintAmount, uint256 _collectionID, bool _eth) public payable {

        require(!paused, "Contract is paused!");



        require(whitelistActive == true, "Whitelist minting not activated!");

        require(CollectionsDict[_collectionID].active == true, "Minting of mintable collection is not active yet");

        require(tokenCounter + _mintAmount <= maxSupply, "Maximum of possible NFTs is reached");

        require(_mintAmount > 0, "At least one token must be minted");

        require(_mintAmount <= maxMintAmount, "Exceeds maximal possible tokens to mint on a try");

        require(CollectionsDict[_collectionID].counter + 

                _mintAmount +

                CollectionsDict[_collectionID].reserved - 

                CollectionsDict[_collectionID].reservedCounter <= 

                CollectionsDict[_collectionID].maxSupply, "Maximum Supply of the collection is reached"); 

        require(isWhitelisted(msg.sender), "You are not whitelisted!");

        require(maxWhitelistAmount >= _mintAmount, "Only 3 mints are allowed for whitlist users");

        require(_mintAmount + getWhitelistClaim(msg.sender) <= maxWhitelistAmount, "You exceed your whitelist limit");

        

        if(_eth) {

            require(ERC20(token).balanceOf(msg.sender) >= whitelistPrice * _mintAmount, "To less WETH in your wallet");

            require(ERC20(token).allowance(msg.sender, address(this)) >= whitelistPrice * _mintAmount, "Not allowed to spend WETH");

            ERC20(token).transferFrom(msg.sender, address(this), whitelistPrice * _mintAmount);

        } else {

            uint256 matic = getMATICvalue(whitelistPrice * _mintAmount);

            require(msg.value >= matic - (matic * tolerance / 100), "Tolerance underflow: Amount of MATIC is to less");

            require(msg.value <= matic + (matic * tolerance / 100), "Tolerance overflow: Amount of MATIC is to high");

        }       



        for (uint256 i = 1; i <= _mintAmount; i++) {

            tokenCounter++;

            whitelistClaimed[msg.sender] += 1;

            CollectionsDict[_collectionID].counter++;

            CollectionsDict[_collectionID].idCounter++;

            _safeMint(_to, CollectionsDict[_collectionID].idCounter);

            emit mintWhitelistNFTCalled(msg.sender, _to, tokenCounter);

        }

    }



    /// @notice read URI of Token for Metadata

    /// @dev overrides the erc721 standard because of the collection dependecy

    /// @param tokenId represents the ID of the NFT to view

    function tokenURI(uint256 tokenId) public view virtual override

        returns (string memory)

    {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed) {

            return string(abi.encodePacked(CollectionsDict[getCollectionOfNFT(tokenId)].baseURI, tokenId.toString(), baseExtension));

        } else {

            return string(revealJson);

        }

    }



    /// @notice get NFTs of specific address

    /// @param _owner Wallet address to input. Not to be confused with the Ownable owner

    /// @return tokenIds as a list of all the NFT ids the wallet owns

    function getNFTContract(address _owner) public view returns (uint256[] memory) {

        uint256 ownerTokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint256 i; i < ownerTokenCount; i++) {

            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);

        }

        return tokenIds;

    }



    /// @notice checks if user is whitelisted

    /// @param _address to be checked if in the whitelist array

    /// @return bool only checks if true or false

    function isWhitelisted(address _address) public view returns(bool) {

        return whitelist[_address];

    }



    /// @notice checks how many NFT a whitelist address has claimed yet

    /// @param _address to be checked for claims

    /// @return uint256 returns the amount of NFTs the address claimed with mintWhitelistNFT()

    /// @dev only mints with the mintWhitelistNFT() function are counted

    function getWhitelistClaim(address _address) public view returns(uint256) {

        return whitelistClaimed[_address];

    }



    /// @notice get mintingPrice in MATIC

    /// @param _value to be converted into MATIC

    /// @return uint256 amount in MATIC

    /// @dev token1 = MATIC, token2 = WETH

    function getMATICvalue(uint256 _value) public view returns(uint256) {

        IUniswapV2Pair pair = IUniswapV2Pair(pricePair);

        (uint p0, uint p1,) = pair.getReserves();



        uint256 maticvalue = _value * p0 / p1;

        return maticvalue;

    }



    /// @notice only owner functions

    

    /// @notice sets minting price

    /// @param _newPrice represents the new price in WEI format

    function setmintingPrice(uint256 _newPrice) public onlyOwner {

        emit mintingPriceChanged(mintingPrice, _newPrice);

        mintingPrice = _newPrice;

    }



    /// @notice sets whitelist minting price

    /// @param _newPrice represents the new price in WEI format

    function setwhitelistPrice(uint256 _newPrice) public onlyOwner {

        emit whitelistPriceChanged(whitelistPrice, _newPrice);

        whitelistPrice = _newPrice;

    }



    /// @notice sets tolerance for MATIC/ETH conversion

    /// @param _newTolerance represents the new tolerance value as number used as percent

    function setTolerance(uint256 _newTolerance) public onlyOwner {

        tolerance = _newTolerance;

    }



    /// @notice sets maximal amout of nft to mint in one transaction

    /// @param _newmaxMintAmount as a number for the maximum

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {

        maxMintAmount = _newmaxMintAmount;

    }



    /// @notice sets maximal amout of nft to mint on whitelist mint per tranaciton

    /// @param _newmaxMintAmount as a number of for the maximum

    function setmaxWhitelistAmount(uint256 _newmaxMintAmount) public onlyOwner {

        maxWhitelistAmount = _newmaxMintAmount;

    }



    /// @notice changes base uri

    /// @param _newBaseURI a string holding a URL

    /// @param _collectionID a number that must be written in the CollectionsDict

    /// @dev The _newBaseURI must contain a / at the end

    function setBaseURI(string memory _newBaseURI, uint256 _collectionID) public onlyOwner {

        CollectionsDict[_collectionID].baseURI = _newBaseURI;

    }



    /// @notice changes contract uri

    /// @param _newContractURI a string holding a URL

    /// @dev inupt must be a url to a .json file

    function setContractURI(string memory _newContractURI) public onlyOwner {

        contractURI = _newContractURI;

    }



    /// @notice changes reveal URI

    /// @param _newRevealJson a string holding a URL

    /// @dev inupt must be a url to a .json file

    function setRevealURI(string memory _newRevealJson) public onlyOwner {

        revealJson = _newRevealJson;

    }



    /// @notice changes extension of base uri

    /// @param _newBaseExtension a string holding a file extension. erc721 suggests it to be .json

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {

        baseExtension = _newBaseExtension;

    }



    /// @notice activates normal minting per collection

    /// @param _collectionID as a number representing a collection in the CollectionsDict

    function switchMintingActive(uint256 _collectionID) public onlyOwner {

        if(CollectionsDict[_collectionID].active) {

            CollectionsDict[_collectionID].active = false;

        } else {

            CollectionsDict[_collectionID].active = true;

        }

        emit mintingStateChanged(_collectionID, CollectionsDict[_collectionID].active);

    }



    /// @notice activates whitelist minting

    /// @dev normal minting will be blocked as long as whitelistActive = true

    function switchWhitelistActive() public onlyOwner {

        if(whitelistActive) {

            whitelistActive = false;

        } else {

            whitelistActive = true;

        }

        emit whitelistStateChanged(whitelistActive);

    }



    /// @notice switch reveal

    function switchRevealed() public onlyOwner {

        if(revealed) {

            revealed = false;

        } else {

            revealed = true;

        }

    }



    /// @notice switches paused

    /// @dev normal and whitelist minting is stopped. Reserved minting is still possible

    function switchPaused() public onlyOwner {

        if(paused) {

            paused = false;

        } else {

            paused = true;

        }

        emit pausedChanged(paused);

    }



    /// @notice updates reserved amount

    /// @param _newReserved as number how many NFT of target collection should be reserved

    /// @param _collectionID number of collection, whichs reserved should be updated

    /// @dev The input value _newReserved can not be smaller than the current already minted reserved NFTs for the collection

    function updateReserved(uint256 _newReserved, uint256 _collectionID) public onlyOwner {

        require(_newReserved <= CollectionsDict[_collectionID].maxSupply - CollectionsDict[_collectionID].counter, "Reserved must be smaller than totalsupply - counter");

        require(_newReserved >= CollectionsDict[_collectionID].reservedCounter, "New reserved must be larger or equal the already reserved minted");

        CollectionsDict[_collectionID].reserved = _newReserved;

    }

    

    /// @notice withdraws all MATIC from the contract to the owner wallet

    function withdraw() public payable onlyOwner {

        require(payable(msg.sender).send(address(this).balance));

    }



    /// @notice withdraws all WETH from the contract to the owner wallet

    function withdrawToken() public payable onlyOwner {

        uint256 amount = ERC20(token).balanceOf(address(this));

        ERC20(token).transfer(msg.sender, amount);

    }



    /// @notice Uploads a list of wallet addresses and saves it in the whitelist array

    /// @param accounts as a list of addresses

    /// @return uint256 returns the amount of addresses successfully saved

    /// @dev this is a very heavy function consuming a lot of gas. Limit set to 200 per transaction

    function bulkSetWhitelist(address[] memory accounts) public onlyOwner returns (uint256) {

        uint256 taskCounter = 0;

        for (uint256 i = 0; i < 201; i++) {

            if(!whitelist[accounts[i]]) {

                whitelist[accounts[i]] = true;

                whitelistSize++;

                taskCounter++;

            }

        }

        return taskCounter;

    }



    /// @notice reserved minting for the owner per collection

    /// @notice The functions mints the next open NFT ID of the target collection and updates the reserved counter

    /// @param _to the address to which the minted NFTs will go

    /// @param _mintAmount number of how many reserved NFT should be minted

    /// @param _collectionID Number of the target collection to be minted from

    function mintReserved(address _to, uint256 _mintAmount, uint256 _collectionID) public onlyOwner {



        require(_mintAmount > 0, "At least one token must be minted");



        require(CollectionsDict[_collectionID].active == true, "Minting of mintable collection is not active yet");

        require(CollectionsDict[_collectionID].reservedCounter + _mintAmount <= CollectionsDict[_collectionID].reserved , "Minting of mintable collection is not active yet");

        require(CollectionsDict[_collectionID].counter + _mintAmount <= CollectionsDict[_collectionID].maxSupply, "Maximum of available NFTs in this collection is reached");



        for (uint256 i = 1; i <= _mintAmount; i++) {

            tokenCounter++;

            CollectionsDict[_collectionID].reservedCounter++;

            CollectionsDict[_collectionID].counter++;

            CollectionsDict[_collectionID].idCounter++;

            _safeMint(_to, CollectionsDict[_collectionID].idCounter);

        }   

    }



    /// @notice this function changes the WETH contract address. Needed if current address will be invalid

    /// @param _newETH contract address of the new WETH token

    /// @dev unlimited approval for ERC20 token transfer is set for the owner

    function updtoken(address _newETH) public onlyOwner {

        emit wethAddressChanged(address(token), _newETH);

        ERC20(_newETH).approve(msg.sender, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

        token = ERC20(_newETH);

    }



    /// @notice updates the uniswap price pair if this will be invalid

    /// @param _newPair contract address of the new price pair

    function updPricePair(address _newPair) public onlyOwner {

        emit pairUpdated(pricePair, _newPair);

        pricePair = _newPair;

    }



    /// @notice Airdrop function that mints a NFT to all wallet addresses in the input list

    /// @param _list as a list of addresses

    /// @param _collectionID Number of the target colleciton to be minted from

    /// @dev this is a very heavy function consuming a lot of gas. Limit set to 200 per transaction

    /// @dev Airdropping is only possible for one collection per transaction. If multiple collection airdrops needed, funciton must be called multiple times.

    function airdopNFT(address[] memory _list, uint256 _collectionID) public onlyOwner {

        for(uint256 i; i < 201; i++) {

            mintNFT(_list[i], 1, _collectionID, false);

        }

    }



    /// @notice internal state functions

    

    /// @notice reads collection based on nft id. Is a internal function of the contract

    /// @param _id for the NFT that must be checked

    /// @return uint256 number of the collection the asked NFT is part of

    function getCollectionOfNFT(uint256 _id) private pure returns(uint256) {

        if(_id < 301) {

            return 1;

        } else if(_id < 601) {

            return 2;

        } else if(_id < 901) {

            return 3;

        } else if (_id < 1201) {

            return 4;

        } else if(_id < 1501) {

            return 5;

        } else if(_id < 1801) {

            return 6;

        } else if(_id < 2101) {

            return 7;

        } else if(_id < 2401) {

            return 8;

        } else if(_id < 2701){

            return 9;

        } else if(_id < 3001) {

            return 10;

        } else if(_id < 3301) {

            return 11;

        } else if(_id < 3601) {

            return 12;

        } else if(_id < 3901) {

            return 13;

        } else if(_id < 4201) {

            return 14;

        } else if(_id < 4501) {

            return 15;

        } else if(_id < 4801) {

            return 16;

        } else if(_id < 5101) {

            return 17;

        } else if(_id < 5401) {

            return 18;

        } else if(_id < 5701) {

            return 19;

        } else if(_id < 6001) {

            return 20;

        } else {

            return 0;

        }

    }



    /// @notice initialization of the collection dict. Only called once

    /// @dev before installation all values need to be verified as only few are changeable

    function initDict() private {

        CollectionsDict[1].active = false;

        CollectionsDict[1].maxSupply = 300;

        CollectionsDict[1].name = "Empathy Skillerz";

        CollectionsDict[1].counter = 0;

        CollectionsDict[1].baseURI = "";

        CollectionsDict[1].reserved = 15;

        CollectionsDict[1].reservedCounter = 0;

        CollectionsDict[1].idCounter = 0;



        CollectionsDict[2].active = false;

        CollectionsDict[2].maxSupply = 300;

        CollectionsDict[2].name = "Communication Skillerz";

        CollectionsDict[2].counter = 0;

        CollectionsDict[2].baseURI = "";

        CollectionsDict[2].reserved = 15;

        CollectionsDict[2].reservedCounter = 0;

        CollectionsDict[2].idCounter = 300;



        CollectionsDict[3].active = false;

        CollectionsDict[3].maxSupply = 300;

        CollectionsDict[3].name = "Build Network Skillerz";

        CollectionsDict[3].counter = 0;

        CollectionsDict[3].baseURI = "";

        CollectionsDict[3].reserved = 15;

        CollectionsDict[3].reservedCounter = 0;

        CollectionsDict[3].idCounter = 600;



        CollectionsDict[4].active = false;

        CollectionsDict[4].maxSupply = 300;

        CollectionsDict[4].name = "Critical Thinking Skillerz";

        CollectionsDict[4].counter = 0;

        CollectionsDict[4].baseURI = "";

        CollectionsDict[4].reserved = 15;

        CollectionsDict[4].reservedCounter = 0;

        CollectionsDict[4].idCounter = 900;



        CollectionsDict[5].active = false;

        CollectionsDict[5].maxSupply = 300;

        CollectionsDict[5].name = "Business Mindset Skillerz ";

        CollectionsDict[5].counter = 0;

        CollectionsDict[5].baseURI = "";

        CollectionsDict[5].reserved = 15;

        CollectionsDict[5].reservedCounter = 0;

        CollectionsDict[5].idCounter = 1200;



        CollectionsDict[6].active = false;

        CollectionsDict[6].maxSupply = 300;

        CollectionsDict[6].name = "Work Ethics Skillerz";

        CollectionsDict[6].counter = 0;

        CollectionsDict[6].baseURI = "";

        CollectionsDict[6].reserved = 15;

        CollectionsDict[6].reservedCounter = 0;

        CollectionsDict[6].idCounter = 1500;



        CollectionsDict[7].active = false;

        CollectionsDict[7].maxSupply = 300;

        CollectionsDict[7].name = "Client Oriented Skillerz";

        CollectionsDict[7].counter = 0;

        CollectionsDict[7].baseURI = "";

        CollectionsDict[7].reserved = 15;

        CollectionsDict[7].reservedCounter = 0;

        CollectionsDict[7].idCounter = 1800;



        CollectionsDict[8].active = false;

        CollectionsDict[8].maxSupply = 300;

        CollectionsDict[8].name = "Manage Frustration Skillerz";

        CollectionsDict[8].counter = 0;

        CollectionsDict[8].baseURI = "";

        CollectionsDict[8].reserved = 15;

        CollectionsDict[8].reservedCounter = 0;

        CollectionsDict[8].idCounter = 2100;



        CollectionsDict[9].active = false;

        CollectionsDict[9].maxSupply = 300;

        CollectionsDict[9].name = "Time Management Skillerz";

        CollectionsDict[9].counter = 0;

        CollectionsDict[9].baseURI = "";

        CollectionsDict[9].reserved = 15;

        CollectionsDict[9].reservedCounter = 0;

        CollectionsDict[9].idCounter = 2400;



        CollectionsDict[10].active = false;

        CollectionsDict[10].maxSupply = 300;

        CollectionsDict[10].name = "Inspire Others Skillerz";

        CollectionsDict[10].counter = 0;

        CollectionsDict[10].baseURI = "";

        CollectionsDict[10].reserved = 15;

        CollectionsDict[10].reservedCounter = 0;

        CollectionsDict[10].idCounter = 2700;



        CollectionsDict[11].active = false;

        CollectionsDict[11].maxSupply = 300;

        CollectionsDict[11].name = "Attention To Details Skillerz";

        CollectionsDict[11].counter = 0;

        CollectionsDict[11].baseURI = "";

        CollectionsDict[11].reserved = 15;

        CollectionsDict[11].reservedCounter = 0;

        CollectionsDict[11].idCounter = 3000;



        CollectionsDict[12].active = false;

        CollectionsDict[12].maxSupply = 300;

        CollectionsDict[12].name = "Deliver On Promises Skillerz";

        CollectionsDict[12].counter = 0;

        CollectionsDict[12].baseURI = "";

        CollectionsDict[12].reserved = 15;

        CollectionsDict[12].reservedCounter = 0;

        CollectionsDict[12].idCounter = 3300;



        CollectionsDict[13].active = false;

        CollectionsDict[13].maxSupply = 300;

        CollectionsDict[13].name = "Eager To Learn Skillerz";

        CollectionsDict[13].counter = 0;

        CollectionsDict[13].baseURI = "";

        CollectionsDict[13].reserved = 15;

        CollectionsDict[13].reservedCounter = 0;

        CollectionsDict[13].idCounter = 3600;



        CollectionsDict[14].active = false;

        CollectionsDict[14].maxSupply = 300;

        CollectionsDict[14].name = "Enthusiasm Skillerz";

        CollectionsDict[14].counter = 0;

        CollectionsDict[14].baseURI = "";

        CollectionsDict[14].reserved = 15;

        CollectionsDict[14].reservedCounter = 0;

        CollectionsDict[14].idCounter = 3900;



        CollectionsDict[15].active = false;

        CollectionsDict[15].maxSupply = 300;

        CollectionsDict[15].name = "Pragmatism Skillerz";

        CollectionsDict[15].counter = 0;

        CollectionsDict[15].baseURI = "";

        CollectionsDict[15].reserved = 15;

        CollectionsDict[15].reservedCounter = 0;

        CollectionsDict[15].idCounter = 4200;



        CollectionsDict[16].active = false;

        CollectionsDict[16].maxSupply = 300;

        CollectionsDict[16].name = "Active Listening Skillerz";

        CollectionsDict[16].counter = 0;

        CollectionsDict[16].baseURI = "";

        CollectionsDict[16].reserved = 15;

        CollectionsDict[16].reservedCounter = 0;

        CollectionsDict[16].idCounter = 4500;



        CollectionsDict[17].active = false;

        CollectionsDict[17].maxSupply = 300;

        CollectionsDict[17].name = "Creativity Skillerz";

        CollectionsDict[17].counter = 0;

        CollectionsDict[17].baseURI = "";

        CollectionsDict[17].reserved = 15;

        CollectionsDict[17].reservedCounter = 0;

        CollectionsDict[17].idCounter = 4800;



        CollectionsDict[18].active = false;

        CollectionsDict[18].maxSupply = 300;

        CollectionsDict[18].name = "Team Player Skillerz";

        CollectionsDict[18].counter = 0;

        CollectionsDict[18].baseURI = "";

        CollectionsDict[18].reserved = 15;

        CollectionsDict[18].reservedCounter = 0;

        CollectionsDict[18].idCounter = 5100;



        CollectionsDict[19].active = false;

        CollectionsDict[19].maxSupply = 300;

        CollectionsDict[19].name = "Self Starter Skillerz";

        CollectionsDict[19].counter = 0;

        CollectionsDict[19].baseURI = "";

        CollectionsDict[19].reserved = 15;

        CollectionsDict[19].reservedCounter = 0;

        CollectionsDict[19].idCounter = 5400;



        CollectionsDict[20].active = false;

        CollectionsDict[20].maxSupply = 300;

        CollectionsDict[20].name = "Flexibility Skillerz";

        CollectionsDict[20].counter = 0;

        CollectionsDict[20].baseURI = "";

        CollectionsDict[20].reserved = 15;

        CollectionsDict[20].reservedCounter = 0;

        CollectionsDict[20].idCounter = 5700;

    }

}