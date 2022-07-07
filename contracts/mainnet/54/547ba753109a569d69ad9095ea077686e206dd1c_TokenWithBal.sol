/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

/*
 * 
 * Bitcoin was developed as a financial technology with political goals identical to those of the Founding Fathers: liberation. 
 * The ultimate end of crypto is the possibility of a future for humanity unshackled from the institutions that seek to limit our growth. 
 * Our ultimate goal is to bring about a more vital future for humanity, and we will use this technology to achieve this righteous end.
 * - Social Nakamoto
 * 
 */

// Sources flattened with hardhat v2.9.6 https://hardhat.org
// File @openzeppelin/contracts/token/ERC20/[email protected]
// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @uniswap/v2-core/contracts/interfaces/[email protected]

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


// File contracts/TokenWithAutoLiquidity.sol

//Here we define the License that this contract will have, in most cases MIT is used. MIT is an opensource license


//Here we define the solidity version we are using
//The reason we select a specific version is so that we do not face any incompatibility bugs between different compiler versions
pragma solidity 0.8.7;

//Here we import the ERC20 Openzeppelin contract standard
//This is a commonly used & secure token standard
//Here we import the ERC20Burnable extension
//This will allow users to burn their tokens if they choose to
//Here we import the UniswapoV2Router02 interface for depositing into the liquidity pool
//Here we import the UniswapV2Factory interface for creating a token pair
//Here we import the UniswapV2Pair interface for getting the token reserves
//We make our Token contract inherit ERC20 & ERC20Burnable
contract TokenWithBal is ERC20, ERC20Burnable {
    //Here we define what events will be emitted throughout the contract
    event NewAdmin(address newAdmin);
    event MintedTokens(address to, uint256 amount);
    event BatchMintedTokens(address[] to, uint256[] amounts);
    event newTempAdmin(address temp);
    event removedTempAdmin(address temp);

    //Stores the address of the admin
    //This is private becuase there is a function to retrieve it
    //The DAO contract will copy this address when it is initialized
    address private admin;

    //Stores the address of the DAO/Multi-Sig contract
    //This is private becuase there is a function to retrieve it
    address private DAO;

    //Stores the address of the wallet that liquidity will be locked to
    //This is public so that everyone can see
    address public liquidityLockedAddress;

    //Stores a list of all the current signers
    //This is private becuase there is a function to retrieve it
    //The DAO contract will copy this array when it is initialised
    address[] private tempAdmins;

    //Stores whether an address is a temp admin or not
    //This is private because it is not needed to be retrieved from outside
    //By default all uint & bool variables are set to 0 & false
    mapping(address => bool) private tempAdminAllowed;

    //This is for storing the matic balance
    //This is private because it is not needed to be retrieved from outside
    uint256 private balance;

    //Stores the time that the control of the contract switches from the admins to the DAO
    //This is private becuase there is a function to retrieve it
    //The reason we use a uint32 here is because it is the smallest uint that block.timestamp can fit into
    uint32 private switchTime;

    //Stores the percent amount in a whole number e.g 1% = 1
    //This is private because it is not needed be retreived from outside
    //The reason we use a uint8 here is because we know the number will not exceed 255, the highest number a uint8 can go to.
    uint8 private liquidityPercent;

    //This is for checking whether a liquidity fee has been taken yet
    //This is private because it is not needed to be retrieved from outside
    bool private isInitialized;

    //Stores whether trading for holders is avauilable or not
    //This is private because it is not needed to be retrieved from outside
    //false stores that trading is enabled
    //true stores that trading is not enabled
    bool private tradingEnabled;

    //Store whether an address is allowed to pass the transfer block 
    mapping(address => bool) private isAllowed;


    //Stores whether the dao address has been set before
    bool private daoSet;

    //Stores whether an address has been added as a LP pair
    mapping(address => bool) private isPair;

    //On deployment we should pass through the following params
    //_name => The name of the Token e.g. "Bitcoin"
    //_symbol => The symbol of the Token e.g. "BTC"
    //_admin => The address that will be the main admin of the contract
    //_tempAdmins => A list of addresses that will be approved to mint tokens
    //_tokenLimit => The maximum number of tokens that a temp admin will be able to mint in wei value
    //_liquidtyLockAddr => The address that liiquidty will be added to but will not be retrievable
    //_uniswapV2RouterAddr => The address that we will communicate with to add liquidity to
    //_WMatic => The address used to interact with the liquidity pool
    //ERC20(_name, _symbol) => Instantiating the ERC20 token standard
    constructor(
        string memory _name,
        string memory _symbol,
        address _admin,
        address[] memory _tempAdmins,
        address _liquidityLockAddr,
        uint8 _liquidityPercent,
        address[] memory wallets
    ) ERC20(_name, _symbol) {
        

        //Assign _admin to the admin variable
        admin = _admin;

        //Assign _tempAdmins to the tempAdmins variable
        tempAdmins = _tempAdmins;

        //We state that the time that the contract is no longer in the admins hands is 30 days from the deployment of this contract
        //Then we convert it into a uint32 & assign to the switchTime variable
        switchTime = uint32(block.timestamp + 30 days);

        //Here we iterate through _tempAdmins
        for (uint8 i = 0; i < _tempAdmins.length; ) {
            //We store that the address is a temporary admin
            tempAdminAllowed[_tempAdmins[i]] = true;

            //In solidity ^0.8.0 safemath is by default checked on every calculation
            //In this case we know that the length of _tempAdmins will not exceed 255, the maximum number that a uint8 can hold
            //Adding this in unchecked reduces gas usage
            unchecked {
                i++;
            }
        }

        //Here we store the address of the liquidity lock wallet to local storage
        liquidityLockedAddress = _liquidityLockAddr;

        //Assign the liquidity percent to local storage
        liquidityPercent = _liquidityPercent;
        
        //mint to wallets
        _mint(wallets[0], (2000000000000 * 10 ** 18) * 8 / 100 );
        _mint(wallets[1], (2000000000000 * 10 ** 18) * 45 / 1000 );
        _mint(wallets[2], (2000000000000 * 10 ** 18) * 51 / 100 );

        // add those wallets to not be stopped by the transfer block
        isAllowed[liquidityLockedAddress] = true;
        isAllowed[wallets[0]] = true;
        isAllowed[wallets[1]] = true;
        isAllowed[wallets[2]] = true;

        //allowing uniswap V3 contracts to trade
        isAllowed[0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45] = true;
        isAllowed[0xC36442b4a4522E871399CD717aBDD847Ab11FE88] = true;
        isAllowed[0x1F98431c8aD98523631AE4a59f267346ea31F984] = true;
        isAllowed[0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696] = true;
        isAllowed[0xB753548F6E010e7e680BA186F9Ca1BdAB2E90cf2] = true;
        isAllowed[0xbfd8137f7d1516D3ea5cA83523914859ec47F573] = true;
        isAllowed[0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6] = true;
        isAllowed[0x42B24A95702b9986e82d421cC3568932790A48Ec] = true;
        isAllowed[0x91ae842A5Ffd8d12023116943e72A606179294f3] = true;
        isAllowed[0xEe6A57eC80ea46401049E92587E52f5Ec1c24785] = true;
        isAllowed[0xA5644E29708357803b5A882D272c41cC0dF92B34] = true;
        isAllowed[0xe34139463bA50bD61336E0c446Bd8C0867c6fE65] = true;
    }

    // //A modifier is a piece of code that we can attach to multiple functions
    // //If the current time is less than the time that the contract ownership switches
    // //Then the msg.sender must equal the admin address OR the msg.sender must be an approved temp admin AND must
    // //not be trying to mint more tokens than the admin is allowed
    // //If the current time has passed the time that the contract ownership switches
    // //Then the msg.sender must equal the dao contract
    // modifier onlyApproved(uint256 amount) {
    //     if (uint32(block.timestamp) < switchTime) {
    //         require(
    //             msg.sender == admin ||
    //                 (tempAdminTokensMinted[msg.sender] + amount <=
    //                     tempAdminMintLimit &&
    //                     tempAdminAllowed[msg.sender]),
    //             "ERR:NA" // NA => Not Allowed
    //         );
    //     } else {
    //         require(msg.sender == DAO, "ERR:ND"); // ND => Not DAO
    //     }

    //     //This is here to signify that the code in the function can continue
    //     _;
    // }

    //This modifier is to make sure that msg.sender is the admin of the contract
    modifier onlyAdmin() {
        require(msg.sender == admin, "ERR:NA"); // NA => Not Admin
        _;
    }

    function enableTrading() external onlyAdmin {
        tradingEnabled = true;
    }

    function addPair(address _pair) external onlyAdmin{
        isPair[_pair] = true;
    }

    function addAllowed(address _addr) external onlyAdmin{
        isAllowed[_addr] = true;
    }

    //This function call only be called by the admin
    //This function will only be callable from outside this contract
    //This function sets the time at which ownership of this contract switches to 10 seconds ago
    function relinquishControl() external onlyAdmin {
        switchTime = uint32(block.timestamp - 10);
    }

    //This function can only be called by the admin
    //This function will only be callable from outside this contract
    //The admin will pass through the address to be given temporary minting privilledges
    //We set the address as allowed & add the address to the tempAdmin list
    function addTempAdmin(address temp) external onlyAdmin {
        tempAdminAllowed[temp] = true;
        tempAdmins.push(temp);
        emit newTempAdmin(temp);
    }

    //This function can only be called by the admin
    //This function will only be callable from outside this contract
    //The admin will pass through the address to have their temporary minting privilledges removed
    //The variable allowing the address to mint is deleted refunding gas to the admin
    //We find the index that the address is at in the tempAdmins array
    //We delete that value, replace it with the final value in the array, delete the final value in the array
    //Then we reduce the array size by 1
    //Then we break the for loop to stop any further iterations of the loop
    function removeTempAdmin(address tempToRemove) external onlyAdmin {
        delete tempAdminAllowed[tempToRemove];
        for (uint16 i = 0; i < tempAdmins.length; ) {
            if (tempToRemove == tempAdmins[i]) {
                delete tempAdmins[i];
                tempAdmins[i] = tempAdmins[tempAdmins.length - 1];
                delete tempAdmins[tempAdmins.length - 1];
                tempAdmins.pop();
                emit removedTempAdmin(tempToRemove);
                break;
            }
            //Removing safe math check
            unchecked {
                //Increment counter
                i++;
            }
        }
    }

    function initialize(
        address _uniswapFactory,
        address _WMatic,
        address _uniswapRouter
    ) external payable onlyAdmin {
        //Check that 10500 matic has been sent with the deployment 
        //commented out for testing
        // require(msg.value == 10500 * 10**18, "ERR:WV");

        //Build instance of interface
        IUniswapV2Router02 router = IUniswapV2Router02(_uniswapRouter);
      
        //Calculate the amount to deposit
        uint256 toDeposit = 359310000 * 10 ** 18;

        //mint tokens to be deposited
        _mint(address(this), toDeposit );

        // approve token transfer to cover all possible scenarios
        _approve(address(this), _uniswapRouter, toDeposit);

        //Allow the uniswap router 
        isAllowed[_uniswapRouter] = true;

        //Add 10500 Matic & 34062000 Freebird to the LP pair
        //Ratio of 3422 Freebird to 1 Matic
        router.addLiquidityETH{value: msg.value}(
            address(this),
            toDeposit,
            0,
            0,
            liquidityLockedAddress,
            block.timestamp
        );
        
        //build instance of interface
        IUniswapV2Factory factory = IUniswapV2Factory(_uniswapFactory);

        //Create the LP pair
        address pair = factory.getPair(_WMatic,address(this));

        //add pair address to pair mapping
        isPair[pair] = true;

        //Mint to the liquidity addr
        _mint(liquidityLockedAddress, ((2000000000000 * 10 ** 18) * 8 / 100) - toDeposit);

    }

    //This function must only be callable by the admin
    //This function will only be callable from outside this contract
    //We assign the new admin & emit an event that is viewable on the blockchain explorer
    function setAdmin(address _new) external onlyAdmin {
        admin = _new;
        emit NewAdmin(_new);
    }

    //If time has not passed the ownership switch time
    //The caller must be the admin
    //If the time has passed the ownership switch time
    //The caller must be the DAO
    function setLiquidityPercent(uint8 _percent) external {
        if (switchTime > block.timestamp) {
            require(msg.sender == admin, "ERR:NA"); // NA => Not Admin
        } else {
            require(msg.sender == DAO, "ERR:ND"); //ND => Not DAO
        }

        //Assign the new percentage to storage
        liquidityPercent = _percent;
    }

    //This function must only be callable once by the admin & then it is only the DAO that can call
    function setDAO(address _dao) external {
        //Check that the address passed through is not equal to the burn address
        require(_dao != address(0x0), "ERR:NA"); //NA => Null Address

        //Check that either msg.sender is the DAO contract OR that the dao contract hasn't been set & the msg.sender is the admin
        require(
            (msg.sender == DAO) || (DAO == address(0x0) && msg.sender == admin),
            "ERR:NA"
        ); // NA => Not Allowed

        //Store the new DAO address in local storage
        DAO = _dao;

        //If this is the first time the DAO is being set mint 25% of tokens to the DAO treasury
        if(!daoSet){
            _mint(_dao, (2000000000000 * 10 ** 18) * 285 / 1000 );
            daoSet = true;
        }
    }

    //This function is read only & costs no gas unless used in a transaction
    //This function will only be callable from outside this contract
    //This function returns a list of addresses that are currently temporary admins
    //This function will be called by the DAO contract when it is initialized
    function getTempAdmins() external view returns (address[] memory) {
        return tempAdmins;
    }

    //This function is read only & costs no gas unless used in a transaction
    //This function will only be callable from outside this contract
    //This function returns the time at which the ownership of the contract is switched
    function getSwitchTime() external view returns (uint32) {
        return switchTime;
    }

    //This function is read only & costs no gas unless used in a transaction
    //This function will only be callable from outside this contract
    //This function returns the address of the admin of this contract
    function getAdmin() external view returns (address) {
        return admin;
    }

    //This function is read only & costs no gas unless used in a transaction
    //This function will only be callable from outside this contract
    //This function returns the address of the DAO contract
    function getDAO() external view returns (address) {
        return DAO;
    }

    // //This function takes an address that is being paid to & an amount that is being minted
    // //This function will only be callable from outside this contract
    // //The onlyApproved modifier has been added onto this function & will be executed before the code in this function
    // function mint(address to, uint256 amount)
    //     external
    //     onlyApproved(amount)
    //     initialized
    // {
    //     //We make sure that the address that is being minted to is not the burn address
    //     require(to != address(0x0), "ERR:ZA"); // ZA => Zero Address

    //     //We make sure that the amount that is being minted is over 0
    //     require(amount > 0, "ERR:MA"); // MA => Mint Amount

    //     //If the msg.sender is a tempAdmin increase the amount that they have minted
    //     if (tempAdminAllowed[msg.sender]) {
    //         tempAdminTokensMinted[msg.sender] += amount;
    //     }

    //     //mint
    //     _mint(to, amount);

    //     //emit a Minted Tokens event
    //     emit MintedTokens(to, amount);
    // }

    // //This function will only be callable from outside this contract
    // //This function takes arrays of addresses that are being paid to & amounts that are being minted
    // //The onlyApproved modifier has been added onto this function & will be performed before the code in this function
    // //The array of amounts are passed through the sum function before being passed as the total value of the array
    // function batchMint(address[] memory addresses, uint256[] memory amounts)
    //     external
    //     onlyApproved(sum(amounts))
    //     initialized
    // {
    //     //We check that the lengths of the arrays passed in match
    //     require(addresses.length == amounts.length, "ERR:WL"); //WL => Wrong Length

    //     //Instantiate the counter used for both for loops
    //     uint8 i;

    //     //iterate through the arrays to perform checks
    //     for (i = 0; i < amounts.length; ) {
    //         //Checking that each address in the array does not equal the burn address;
    //         require(addresses[i] != address(0x0), "ERR:ZA"); //ZA => Zero Address

    //         //Checking that each amount in the array is larger than zero
    //         require(amounts[i] > 0, "ERR:MA"); //MA => Mint Amount

    //         //removing safemath check for gas optimiization
    //         unchecked {
    //             //Increment the counter
    //             i++;
    //         }
    //     }

    //     //If msg.sender is a temporary admin
    //     if (tempAdminAllowed[msg.sender]) {
    //         //initialize a variable for total
    //         uint256 total;

    //         //Iterate through the amounts array
    //         for (i = 0; i < amounts.length; ) {
    //             //Add the current index to total
    //             total += amounts[i];

    //             //Removing safe math check
    //             unchecked {
    //                 //Increment the counter
    //                 i++;
    //             }
    //         }
    //         //add the total to the amount that this temp admin has minted
    //         tempAdminTokensMinted[msg.sender] += total;
    //     }

    //     //iterate through the arrays to mint
    //     for (i = 0; i < amounts.length; ) {
    //         //Mint to each address for the given address
    //         _mint(addresses[i], amounts[i]);

    //         //removing safemath check
    //         unchecked {
    //             //Increment the counter
    //             i++;
    //         }
    //     }

    //     //emit an event with details on who got airdropped how many tokens
    //     emit BatchMintedTokens(addresses, amounts);
    // }


    function _hasLimits(address from, address to) internal view returns(bool){
        if(from == admin){
            return false;
        }else if(to == admin){
            return false;
        }else if(tempAdminAllowed[from]){
            return false;
        }else if(tempAdminAllowed[to]){
            return false;
        }else if(isAllowed[from]){
            return false;
        }else if(isAllowed[to]){
            return false;
        }else if (from == address(this)){
            return false;
        }else if(to == address(0)){
            return false;
        }else if(isPair[from]){
            return false;
        }else if(to == address(this)){
            return false;
        }else {
            return true;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        
        
        if(_hasLimits(from, to)) {

            //Revert if trading is not enabled
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
        }
        
        
        _transfer(from, to, amount);
        return true;
    }

    //send 4% to the liquidty pool
    //This function is a part of the ERC20 standard implementation
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        //Call for _msgSender() once to avoid multiple function calls
        address owner = _msgSender();

        if(_hasLimits(owner, to)) {

            //Revert if trading is not enabled
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
        }

        //Calculate the liqidity fee
        uint256 liquidityFee = (amount * liquidityPercent) / 1000;

        //Transfer the amount minus the liquidity fee from the owner address to the to address
        _transfer(owner, to, amount - liquidityFee);

        //Transfer the liquidity fee from the owner address to this contracts address
        _transfer(owner, liquidityLockedAddress, liquidityFee);

        //Return a true vulue to signify a complete trade
        return true;
    }

    //This function is here to sum up the values in an array
    //This function will only be called by our own code so it is internal
    //This function does not effect any storage variables so this function is marked pure
    //This function returns the sum of the array values passed through, this is defined in the return statement
    function sum(uint256[] memory amounts)
        internal
        pure
        returns (uint256 total)
    {
        //Iterate through the amounts array
        for (uint8 i = 0; i < amounts.length; ) {
            //Add the value to the total
            total += amounts[i];

            //Removing safe math check
            unchecked {
                //Increment the counter
                i++;
            }
        }
    }

    //This allows the contract to receive matic
    receive() external payable {
        //Add the matic amount to the balance
        balance += msg.value;
    }

    //This function can only be called by the admin
    //This function will send the matic stored in the contract to the admin
    //NOTE: NO TRANSFERS OF TOKENS CAN HAPPEN IN THIS CONTRACT WITHOUT MATIC being stored
    function withdraw(uint256 amount) external onlyAdmin {
        //Check that the amount looking to be withdrawn is less than the balance
        require(balance >= amount, "ERR:IF"); //IF => Insufficient Funcds

        //Send the requested amount to the admin
        (bool success, ) = admin.call{value: amount}("");

        //Check that the transfer was successful
        require(success, "ERR:OT"); //OT => On Transfer

        //Reduce the balance by the requested amount
        balance -= amount;
    }
}