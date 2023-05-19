// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)
// Sheqel token version 0.1

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";
import "Uniswap.sol";
import "DistributorV2.sol";
import "Reserve.sol";
import "LiquidityManager.sol";
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

// Sheqel Token Contract0
contract SheqelToken is Context, IERC20, IERC20Metadata {
    address public admin;
    bool isFirstLiquidityProviding = true;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 public _totalSupply;

    string private _name;
    string private _symbol;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    Distributor public distributor;
    IUniswapV2Pair public uniswapV2PairContract;

    address public reserveAddress;
    Reserve public reserveContract;
    LiquidityManager liquidityManager;
    address public liquidityManagerAddress;
    address public spookySwapAddress; //0xF491e7B69E4244ad4002BC14e878a34207E38c29; FTM
    address public MDOAddress;
    address public teamAddress;

    address public WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;// 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; FTM
    IERC20 public USDC;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address _reserveAddress, address _MDOAddress, uint256 _tSupply, address _spookyswapAddress, address _USDCAddress) {
        // Setting up the variables
        _name = "Sheqel";
        _symbol = "SHQ";
        _totalSupply = _tSupply;
        _balances[_reserveAddress]= _totalSupply;

        reserveAddress = _reserveAddress;
        reserveContract = Reserve(reserveAddress);
        spookySwapAddress = _spookyswapAddress;
        MDOAddress = _MDOAddress;
        teamAddress = msg.sender;

        USDC = IERC20(_USDCAddress); //IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); FTM


        liquidityManager = new LiquidityManager(_USDCAddress, _spookyswapAddress, _reserveAddress);
        liquidityManagerAddress = address(liquidityManager);


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            spookySwapAddress
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), address(USDC));
            

        uniswapV2Router = _uniswapV2Router;

        uniswapV2PairContract = IUniswapV2Pair(uniswapV2Pair);

        //distributor = new HolderRewarderDistributor(spookySwapAddress, _reserveAddress);

        _isExcludedFromFee[address(this)] = true;


    }

    function setDistributor(address _addr) external {
        require(msg.sender == teamAddress, "Must be team address");
        distributor = Distributor(_addr);
        // Setup initial mint
        //distributor.transferShare(_deployer, _amount);
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        //require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
                _balances[sender] = senderBalance - amount;
        }

        if(recipient != reserveAddress && sender != reserveAddress && !isFirstLiquidityProviding/*&& recipient != uniswapV2Pair && recipient != address(uniswapV2Router)*/){

            // Taking the tax and returning the amount left
            
            uint256 amountRecieved = _takeTax(amount);

            _balances[recipient] += amountRecieved;
            emit Transfer(sender, recipient, amountRecieved);


        }
        else {
            if (isFirstLiquidityProviding == true) {
                isFirstLiquidityProviding = false;
            }
            // Not taxing the transaction
            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);

        }


        //_afterTokenTransfer(sender, recipient, amountRecieved);
    }

    /** @dev Creates `amount` tokens and takes all the necessary taxes for the account.
     */
    function _takeTax(uint256 amount)
        internal
        returns (uint256 amountRecieved)
    {
        // Calculating the tax
        uint256 reserve = (amount * 130) / 10000;
        uint256 rewards = (amount * 370) / 10000;
        uint256 MDO = (amount * 60) / 10000;
        uint256 UBR = (amount * 100) / 10000;
        uint256 liquidity = (amount * 40) / 10000;

        // Adding the liquidity to the contract
        _addToLiquidity(liquidity); 

        // Sending the tokens to the reserve
        _sendToReserve(reserve);

        // Sending the MDO wallet
        _sendToMDO(MDO);

        // Adding to the Universal Basic Reward pool
        _addToUBR(UBR);

        // Adding to the rewards pool
        _addToRewards(rewards);

        return (amount - (reserve + rewards + MDO + UBR + liquidity));
    }

    function _addToRewards(uint256 amount) private {
        _balances[address(distributor)] = _balances[address(distributor)] + (amount);
        //swapTokenToUSDC(address(distributor), amount);

        distributor.addToCurrentShqToRewards(amount);
    }

    function _addToUBR(uint256 amount) private {
        _balances[address(distributor)] = _balances[address(distributor)] + (amount);
        //swapTokenToUSDC(address(distributor), amount);

        distributor.addToCurrentShqToUBR(amount);
    }

    function _addToLiquidity(uint256 amount) private {
        _balances[address(liquidityManager)] = _balances[address(liquidityManager)] + (amount);
        //liquidityManager.addToCurrentShqToLiquidity(amount);
    }

    function _sendToReserve(uint256 amount) private {
        _balances[address(this)] = _balances[address(this)] + (amount);
        swapTokenToUSDC(address(reserveAddress), amount);

        //swapTokenToUSDC(reserveAddress, amount); // Sending the USDC to the reserve
    }

        function _sendToMDO(uint256 amount) private {
        _balances[address(this)] = _balances[address(this)] + (amount);

        swapTokenToUSDC(MDOAddress, amount); // Sending the USDC to the reserve
    }


    function swapTokenToUSDC(address recipient, uint256 amount) internal {
        _approve(address(this), address(reserveContract), amount);
        reserveContract.sellShq(recipient, amount);
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

    // Will be called by a Keeper every day and will add to tokens taxed to the liquidity
    function initiateLiquidityProviding() public {
        liquidityManager.swapAndLiquify();
    }


    function getDistributor() public view returns(address){
        return address(distributor);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// Uniswap V2 router
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// Rewards Distributor
pragma solidity ^0.8.0;

import "ISheqelToken.sol"; 
import "IERC20.sol";
import "IReserve.sol";

contract Distributor {
    uint256 public lastDistribution;
    uint256 public currentShqToUBR;
    uint256 public currentShqToRewards;
    uint256 public currentUSDCToUBR;
    uint256 public currentUSDCToRewards;
    bool public shqSet = false;
    ISheqelToken public sheqelToken;
    IERC20 public USDC;
    address public teamAddress;
    IReserve public reserveContract;

    constructor(address _usdcAddress, address _reserveAddress) {
        teamAddress = msg.sender;
        USDC = IERC20(_usdcAddress);
        reserveContract = IReserve(_reserveAddress);
    }

    modifier onlyTeam() {
        require(msg.sender == teamAddress, "Caller must be team address");
        _;
    }

    modifier onlyToken() {
        require(msg.sender == address(sheqelToken), "Caller must be Sheqel Token");
        _;
    }

    modifier onlyReserve() {
        require(msg.sender == address(reserveContract), "Caller must be Reserve");
        _;
    }

    function setShq(address _addr) external onlyTeam() {
        require(shqSet == false, "SHQ Already set");
        sheqelToken = ISheqelToken(_addr);
        shqSet = true;
    }

    function addToCurrentShqToUBR(uint256 _amount) external onlyToken() {
        currentShqToUBR += _amount;
    }

    function addToCurrentShqToRewards(uint256 _amount) external onlyToken() {
        currentShqToRewards += _amount;
    }

    function addToCurrentUsdcToRewards(uint256 _amount) external onlyReserve() {
        currentUSDCToRewards += _amount;
    }

    function addToCurrentUsdcToUBR(uint256 _amount) external onlyReserve() {
        currentUSDCToUBR += _amount;
    }

    function processAllRewards(address[] calldata _addresses , uint256[] calldata _balances, uint256 _meanBalance, uint256 _numAddressesOverThreshold) onlyTeam() external{
        require(block.timestamp >= lastDistribution + 1 days, "Cannot distribute two times in a day");

        // Convert all SHQ to USDC
        if(currentShqToRewards > 0){
            currentUSDCToRewards += swapSHQToUSDC(currentShqToRewards);
            currentShqToRewards = 0;
        }
        if(currentShqToUBR > 0){
            currentUSDCToUBR += swapSHQToUSDC(currentShqToUBR);
            currentShqToUBR = 0;
        }   


        uint256 totalSuppy = sheqelToken.totalSupply();
        uint256 checkTotalSupply = 0;
        // Iterate through all addresses
        for (uint256 i = 0; i < _addresses.length; i++) {
            // Get the address
            address holder = _addresses[i];
            // Get the balance
            uint256 balance = _balances[i];

            // Calculate the rewards
            uint256 rewards = (balance * currentUSDCToRewards) / totalSuppy;
            // Send the rewards
            USDC.transfer(holder, rewards);

            // Calculate the UBR
            if(balance >= (_meanBalance/1000)) {
                uint256 UBR = (currentUSDCToUBR) / _numAddressesOverThreshold;
                // Send the UBR
                USDC.transfer(holder, UBR);
            }
        }
        // Update last distribution
        lastDistribution = block.timestamp;
    }

    function swapSHQToUSDC(uint256 amount) internal returns(uint256){
        uint256 balancePreswapUSDC = USDC.balanceOf(address(this));
        sheqelToken.approve(address(reserveContract), amount);
        reserveContract.sellShq(address(this), amount);

        return USDC.balanceOf(address(this)) - balancePreswapUSDC;
    }
}

pragma solidity ^0.8.0;

interface ISheqelToken {
    function getDistributor() external returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function MDOAddress() external returns (address);
    function liquidityManagerAddress() external returns (address);
    function reserveAddress() external view returns (address);



}

pragma solidity ^0.8.0;

interface IReserve {
    function sellShq(address _beneficiary, uint256 _shqAmount) external;
    function buyShq(address _beneficiary, uint256 _shqAmount) external;
    function buyShqWithUsdc(address _beneficiary, uint256 _usdcAmount) external;
}

pragma solidity ^0.8.0;

import "IERC20.sol";
import "ISheqelToken.sol";
import "Uniswap.sol";
import "DistributorV2.sol";

contract Reserve {
    ISheqelToken private sheqelToken;
    IERC20 private USDC;
    uint256 private shqToConvert;
    uint256 taxRate = 7;
    IUniswapV2Router02 private uniswapV2Router;
    address private WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address private teamAddress;
    bool shqAddressSet=false;


    Distributor public distributor;

    event ShqBought(uint256 amountSHQ, uint256 amountUSDC);
    event ShqSold(uint256 amountSHQ, uint256 amountUSDC);



    constructor(address _spookyswapRouter, address _usdcAddress) {
        // Contract constructed by the Sheqel token
        USDC = IERC20(_usdcAddress);
        uniswapV2Router = IUniswapV2Router02(_spookyswapRouter);
        teamAddress = msg.sender;
        shqToConvert = 0;
    }

    modifier onlyToken() {
        require(msg.sender == address(sheqelToken), "Must be Sheqel Token");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == address(teamAddress), "Must be Sheqel Team");
        _;
    }

    function setTaxRate(uint256 _taxRate) external onlyTeam() {
        taxRate = _taxRate;
    }
    function setSheqelTokenAddress(address _addr) public onlyTeam() {
        require(shqAddressSet == false, "Can only change the address once");
        sheqelToken = ISheqelToken(_addr);
        address distributorAddress = sheqelToken.getDistributor();
        distributor = Distributor(distributorAddress);
        shqAddressSet=true;

        // Initial buying of 999USDC


        // Burning
        sheqelToken.transfer(0x1234567890123456789012345678901234567890, 2*10**18);

        // Adding liquidity
        sheqelToken.transfer(teamAddress, 2000 * 10 ** 18);

        sheqelToken.transfer(teamAddress, 197998 * 10 ** 18);


        
    }

    function addToShqToConvert(uint256 amount) public onlyToken() {
        shqToConvert += amount;
    }

    function buyPrice() public view returns (uint256) {
        uint256 usdcInReserve = USDC.balanceOf(address(this)) * (10 ** 6);
        uint256 shqOutsideReserve = (sheqelToken.totalSupply() - sheqelToken.balanceOf(address(this))) / (10 ** 12);

        return (usdcInReserve / shqOutsideReserve); // Price in USDC (6 decimals)
    }

    function buyPriceWithTax() public view returns (uint256) {
        uint256 usdcInReserve = USDC.balanceOf(address(this)) * (10 ** 6);
        uint256 shqOutsideReserve = (sheqelToken.totalSupply() - sheqelToken.balanceOf(address(this))) / (10 ** 12);

        return (usdcInReserve / shqOutsideReserve) + ((usdcInReserve / shqOutsideReserve) * taxRate) / 100; // Price in USDC (6 decimals)
    }

    function sellPrice() public view returns (uint256) {
        uint256 totalShq = sheqelToken.totalSupply();
        uint256 shqInReserve = sheqelToken.balanceOf(address(this));
        uint256 usdcInReserve = USDC.balanceOf(address(this));
        uint256 shqOutsideReserve = totalShq - shqInReserve;
        uint256 shqBurned = sheqelToken.balanceOf(0x1234567890123456789012345678901234567890);

        //(((Tokens outside of the reserve + burned) * standardised price * 1.07 - USDC in reserve)+((Tokens inside the reserve + burned) * standardised price * 1.07)) /(tokens inside the reserve-1)
        // good return (((shqOutsideReserve + shqBurned) * buyPriceWithTax() - usdcInReserce) + ((shqInReserve + shqBurned) * buyPriceWithTax())) / (shqInReserve - 1); // Price in USDC (6 decimals)
        
        //  return ((totalShq * buyPriceWithTax())) / (shqInReserve - 1); // Price in USDC (6 decimals)
        //return ((((totalShq-shqInReserve) * taxRate)/100 - (usdcInReserve * 9)/10) + (shqInReserve)* buyPriceWithTax()) / (shqInReserve - 1); // Price in USDC (6 decimals) brand new formula
        // WORKS return ((totalShq * buyPriceWithTax()) - usdcInReserve) / (shqInReserve - 1); // Price in USDC (6 decimals)
        return ((shqInReserve * buyPriceWithTax()) + (shqOutsideReserve * buyPrice() * 1001)/1000 - usdcInReserve) / (shqInReserve - 1);
    }


    function buyShq(address _beneficiary, uint256 _shqAmount) external {
        require(_shqAmount > 0, "Amount of tokens purchased must be positive");
        _processPurchase(_beneficiary, _shqAmount);
    }

    function buyShqWithUsdc(address _beneficiary, uint256 _usdcAmount) public {
        require(_usdcAmount > 0, "Amount of tokens purchased must be positive");
        uint256 shqAmount = (_usdcAmount * (10 ** 18)) / sellPrice();
        _processPurchase(_beneficiary, shqAmount);
    }

    function sellShq(address _beneficiary, uint256 _shqAmount) external {
        require(_shqAmount > 0, "Amount of tokens sold must be positive");
        _processSell(_beneficiary, _shqAmount);
    }

    function _processSell(address _beneficiary, uint256 _shqAmount) internal {
        // Converting shq to usdc
        uint256 usdcAmount = (_shqAmount * buyPrice()) / (10 ** 18);
    
        // Making the user pay
        require(sheqelToken.transferFrom(msg.sender, address(this), _shqAmount), "Deposit failed");

        // Delivering the tokens
        uint256 usdcAmountTaxed = _takeTax(usdcAmount);
        _deliverUsdc(_beneficiary, usdcAmountTaxed);

        emit ShqSold(usdcAmount, _shqAmount);

  }

    function _processPurchase(address _beneficiary, uint256 _shqAmount) internal {
        require(sheqelToken.balanceOf(address(this)) - _shqAmount >= 2 * 10**18, "Cannot buy remaining SHQ");
        // Converting shq to usdc
        uint256 usdcAmount = (_shqAmount * sellPrice()) / (10 ** 18);
    
        // Making the user pay
        require(USDC.transferFrom(msg.sender, address(this), usdcAmount), "Deposit failed");

        // Paying the tax
        _takeTax(usdcAmount);

        // Delivering the tokens
        _deliverShq(_beneficiary, _shqAmount);


        emit ShqBought(_shqAmount, usdcAmount);
    }

    function _deliverShq(address _beneficiary, uint256 _shqAmount) internal {
        sheqelToken.transfer(_beneficiary, _shqAmount);
    }

    function _deliverUsdc(address _beneficiary, uint256 _usdcAmount) internal {
        USDC.transfer(_beneficiary, _usdcAmount);
    }

  /** @dev Creates `amount` tokens and takes all the necessary taxes for the account.*/
     
    function _takeTax(uint256 amount)
        internal
        returns (uint256 amountRecieved)
    {
        // Calculating the tax
        uint256 reserve = (amount * 130) / 10000;
        uint256 rewards = (amount * 370) / 10000;
        uint256 MDO = (amount * 60) / 10000;
        uint256 UBR = (amount * 100) / 10000;
        uint256 liquidity = (amount * 40) / 10000;


        // Adding the liquidity to the contract
        _addToLiquidity(liquidity); 

        // Sending the tokens to the reserve
        _sendToReserve(reserve);

        // Sending the MDO wallet
        _sendToMDO(MDO);

        // Adding to the Universal Basic Reward pool
        _addToUBR(UBR);

        // Adding to the rewards pool
        _addToRewards(rewards);

        return (amount - (reserve + rewards + MDO + UBR + liquidity));
    }

    function _addToLiquidity(uint256 _amount) private {
        USDC.transfer(sheqelToken.liquidityManagerAddress(), _amount);
    }

    function _sendToReserve(uint256 amount) private {
        USDC.transfer(address(this), amount);
    }

    function _addToRewards(uint256 amount) private {
        USDC.transfer(address(distributor), amount);

        distributor.addToCurrentUsdcToRewards(amount);
    }

    function _addToUBR(uint256 amount) private {
        USDC.transfer(address(distributor), amount);

        distributor.addToCurrentUsdcToUBR(amount);
    }

    function _sendToMDO(uint256 amount) private {
        address MDOAddress = sheqelToken.MDOAddress();
        USDC.transfer(MDOAddress, amount);
    }

}

// SPDX-License-Identifier: MIT
// Liquidity Manager
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Uniswap.sol";
import "IReserve.sol";

contract LiquidityManager {
    IERC20 public sheqelToken;
    IERC20 public USDC;
    IUniswapV2Router02 public uniswapV2Router;
    IReserve public reserve;

    constructor(address _usdcAddress, address _spookySwapAddress, address _reserveAddress) {
        sheqelToken = IERC20(msg.sender);
        USDC = IERC20(_usdcAddress);
        uniswapV2Router = IUniswapV2Router02(_spookySwapAddress);
        reserve = IReserve(_reserveAddress);
    }

    modifier onlyToken() {
        require(msg.sender == address(sheqelToken), "Must be Sheqel Token");
        _;
    }

    /*function addToCurrentShqToLiquidity(uint256 _amount) onlyToken() public {
        currentShqToLiquidity += _amount;
    }*/

    function swapAndLiquify() onlyToken() public {
        // Converting all USDC to SHQ
        uint256 currentUSDCBalance = USDC.balanceOf(address(this));
        if(currentUSDCBalance > 0) {
            USDC.approve(address(reserve), currentUSDCBalance);
            reserve.buyShqWithUsdc(address(this), currentUSDCBalance);
        }
        uint256 currentShqToLiquidity = sheqelToken.balanceOf(address(this));
        require(currentShqToLiquidity > 0, "No SHQ to sell");
        // split the contract balance into halves
        uint256 half = currentShqToLiquidity / 2;
        uint256 otherHalf = currentShqToLiquidity - half;

        uint256 initialUSDCBalance = USDC.balanceOf(address(this));

        // swap tokens for USDC
        sheqelToken.approve(address(reserve), otherHalf);
        reserve.sellShq(address(this), otherHalf); 


        uint256 newBalance = USDC.balanceOf(address(this)) - (initialUSDCBalance);

        // add liquidity to uniswap
        addLiquidity(half, newBalance);
    }

    function addLiquidity(uint256 _shqAmount, uint256 _usdcAmount) private {
        // approve token transfer to cover all possible scenarios
        USDC.approve(address(uniswapV2Router), _usdcAmount);
        sheqelToken.approve(address(uniswapV2Router), _shqAmount);
        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(sheqelToken),
            address(USDC),
            _shqAmount,
            _usdcAmount,
            0, 
            0, 
            address(this),
            block.timestamp + 15
        );
    }
}