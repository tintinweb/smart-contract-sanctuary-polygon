/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

// File: contracts/interfaces/IManager.sol


pragma solidity ^0.8.12;

interface IManager {
    // Passive fund methods
    function calculatePassiveBrokerage(uint256 amount)
        external
        view
        returns (uint256);

    function calculateTransferPassiveBrokerage(
        uint256 _passiveTransferBrokerage
    ) external view returns (uint256);

    // Active fund methods
    function performanceFeeLimit() external view returns (uint256);

    function platformFeeOnPerformance() external view returns (uint256);

    function calculateActiveBrokerage(uint256 amount)
        external
        view
        returns (uint256);

    function calculatePlatformFeeOnPerformance(uint256 amount)
        external
        view
        returns (uint256);

    function pauser() external view returns (address);

    function terminator() external view returns (address);

    // Path management
    function getPath(address tokenIn, address tokenOut)
        external
        view
        returns (address[] memory);
}

// File: contracts/interfaces/IUniswapV2Router02.sol


pragma solidity ^0.8.12;

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

// File: contracts/interfaces/IUniswapV2Router02.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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

// File: contracts/ActiveFund.sol


pragma solidity ^0.8.12;







contract ActiveFund is Ownable, ReentrancyGuard, Pausable {
    // Composit details.
    address[] public currencies;
    uint256[] public shares;

    // Decimal precision
    uint256 public constant decimalPrecision = 10000;

    // Platform manager for the fund.
    IManager manager;

    // Initial fund price in dollor
    uint256 public initialPriceInDoller;

    // Address of usd contract
    address public usd;

    // Router for exchange
    IUniswapV2Router02 router;

    // ERC20 standard
    string public name;
    string public symbol;
    uint256 public totalSupply = 0;
    uint256 public constant decimals = 18;

    // Performance fee percentage and earned till now.
    uint256 public performanceFee;
    uint256 public preformanceFeeEarned = 0;

    // Profit percentage after that performance fee will be charged.
    uint256 chargableProfitPercentage;

    // termination
    bool public terminated = false;

    event Redeemed(address user, uint256 amount);

    // Investment storages.
    struct Investment {
        uint256 atPrice;
        uint256 timestamp;
        uint256 token;
    }

    struct UserInverstmentStats {
        uint256 startingIndex;
        uint256 endingIndex;
    }

    // Mapping to store every user's investments.
    mapping(address => mapping(uint256 => Investment)) public userInverstments;

    // Mapping to store every user's stats
    mapping(address => UserInverstmentStats) public userInverstmentStats;

    // Initialize the fund.
    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory _currencies,
        uint256[] memory _shares,
        uint256 _initialPriceInDoller,
        address _router,
        address _fundManager,
        address _manager,
        uint256 _performanceFee,
        uint256 _chargableProfitPercentage,
        address _usd
    ) {
        _transferOwnership(_fundManager);

        // Validate shares
        {
            uint256 sum = 0;
            for (uint256 i = 0; i < _shares.length; i++) {
                sum += _shares[i];
            }
            require(
                sum == 100 * decimalPrecision,
                "ActiveFund: The sum of shares must be 100%"
            );
            require(
                _shares.length == _currencies.length,
                "ActiveFund: Shares and Currencies must have same length"
            );
        }
        name = _name;
        symbol = _symbol;
        currencies = _currencies;
        shares = _shares;
        initialPriceInDoller = _initialPriceInDoller;
        router = IUniswapV2Router02(_router);
        manager = IManager(_manager);
        _setPerformanceFee(_performanceFee);
        chargableProfitPercentage = _chargableProfitPercentage;
        usd = _usd;
    }

    // Private method to set performance fees.
    function _setPerformanceFee(uint256 _performanceFee) private {
        require(
            _performanceFee <= manager.performanceFeeLimit(),
            "ActiveFund: Can't exceed the performance limit"
        );
        performanceFee = _performanceFee;
    }

    // Terminating the fund.
    modifier whenNotTerminated() {
        require(!terminated, "ActiveFund: Fund is terminated.");
        _;
    }

    function getCurrencyCount() external view returns (uint256) {
        return currencies.length;
    }

    function terminate() external whenNotTerminated nonReentrant {
        require(
            msg.sender == manager.terminator(),
            "ActiveFund: terminator only."
        );
        _swapTokenToDollor(totalSupply, address(this));
        terminated = true;
    }

    // Method to update the performance fee.
    function setPerformanceFee(uint256 _performanceFee)
        external
        onlyOwner
        whenNotPaused
        whenNotTerminated
    {
        _setPerformanceFee(_performanceFee);
    }

    function setChargableProfitPercentage(uint256 _percentage)
        external
        onlyOwner
        whenNotPaused
        whenNotTerminated
    {
        chargableProfitPercentage = _percentage;
    }

    // Method to pause/unpause the fund.
    function pause() external whenNotPaused whenNotTerminated {
        require(
            msg.sender == manager.pauser(),
            "ActiveFund: Only allowed to Pauser"
        );
        _pause();
    }

    function unpause() external whenPaused whenNotTerminated {
        require(
            msg.sender == manager.pauser(),
            "ActiveFund: Only allowed to Pauser"
        );
        _unpause();
    }

    // Method to contvert Fund amount into doller.
    function InDoller(uint256 _amount, address currency)
        public
        view
        returns (uint256)
    {
        uint256[] memory amounts = router.getAmountsIn(
            _amount,
            manager.getPath(usd, currency)
        );
        return amounts[0];
    }

    // Method to return total fund in dollers
    function totalFundInDoller() public view returns (uint256 sum) {
        for (uint256 i = 0; i < currencies.length; i++) {
            sum += InDoller(
                IERC20(currencies[i]).balanceOf(address(this)),
                currencies[i]
            );
        }
    }

    // Method to return the tokens price in dollers
    function currentPriceInDollerPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return initialPriceInDoller;
        } else {
            return ((totalFundInDoller() * 1 ether) / totalSupply);
        }
    }

    // Method to get exact dollor for exact amount.
    function tokenInDollor(uint256 _amount) private view returns (uint256) {
        return ((currentPriceInDollerPerToken() * _amount) / (1 ether));
    }

    // Method to swap amount from dollor to compsits
    function swapComposits(uint256 _amount) private {
        // loop through composits
        for (uint256 i = 0; i < shares.length; i++) {
            // Calculate currenct currency's composite.
            uint256 amount = (_amount * shares[i]) / (100 * decimalPrecision);
            if (amount > 0) {
                // Allow router the spending limit.
                IERC20(usd).approve(address(router), amount);

                // Swap and except any amount in return.
                router.swapExactTokensForTokens(
                    amount, // Amount in dollor
                    0, // Accept any amount in return
                    manager.getPath(usd, currencies[i]), // The exchange path
                    address(this), // Get exchnaged value to this contract itself.
                    block.timestamp // Perform this exchange in this transaction only.
                );
            }
        }
    }

    // Method to Invest
    function invest(uint256 amount)
        external
        nonReentrant
        whenNotPaused
        whenNotTerminated
    {
        // Check USD allowance.
        IERC20 _usd = IERC20(usd);
        require(
            _usd.allowance(msg.sender, address(this)) >= amount,
            "ActiveFund: Spending not allowed on usdc"
        );

        // Calculate brokerage.
        uint256 brokerage = manager.calculateActiveBrokerage(amount);
        amount -= brokerage;

        // Transfer amount to fund contract and trasury.
        _usd.transferFrom(msg.sender, address(this), amount);
        _usd.transferFrom(msg.sender, address(manager), brokerage);

        // Calculate token.
        uint256 token = (amount * 1 ether) / currentPriceInDollerPerToken();

        // Swap the composits.
        swapComposits(amount);

        // Mint new tokens.
        userInverstments[msg.sender][
            userInverstmentStats[msg.sender].endingIndex
        ] = Investment(currentPriceInDollerPerToken(), block.timestamp, token);

        // Update the totalSupply
        totalSupply += token;

        // Update user stats.
        userInverstmentStats[msg.sender].endingIndex++;
    }

    // Method to return the
    function balanceOf(address investor) public view returns (uint256) {
        uint256 balance = 0;
        for (
            uint256 i = userInverstmentStats[investor].startingIndex;
            i < userInverstmentStats[investor].endingIndex;
            i++
        ) {
            balance += userInverstments[investor][i].token;
        }
        return balance;
    }

    // Private method to swap token composits from dollor.
    function _swapTokenToDollor(uint256 _amount, address receiver) private {
        // Loop through all currencies.
        for (uint256 i = 0; i < currencies.length; i++) {
            uint256 amount = (_amount *
                IERC20(currencies[i]).balanceOf(address(this))) / totalSupply;

            if (amount > 0) {
                // Allow router the spending limit.
                IERC20(currencies[i]).approve(address(router), amount);

                // Swap and except any amount in return.
                router.swapExactTokensForTokens(
                    amount, // Amount in dollor
                    0, // Accept any amount in return
                    manager.getPath(currencies[i], usd), // The exchange path
                    receiver, // Get exchnaged value to this contract itself.
                    block.timestamp // Perform this exchange in this transaction only.
                );
            }
        }
    }

    // Internal function to calculate performance fee.
    function calculatePerformanceFee(uint256 oldPrice, uint256 _amount)
        public
        view
        returns (uint256)
    {
        if (oldPrice >= currentPriceInDollerPerToken()) {
            return 0;
        } else {
            uint256 oldTokenValue = (oldPrice * _amount) / 1 ether;
            uint256 newTokenValue = (currentPriceInDollerPerToken() * _amount) /
                1 ether;
            if (newTokenValue <= oldTokenValue) {
                return 0;
            }
            uint256 profitPercentage = ((newTokenValue - oldTokenValue) *
                100 *
                decimalPrecision) / oldPrice;

            if (profitPercentage > chargableProfitPercentage) {
                uint256 _perfromanceFeeInDollor = ((newTokenValue -
                    oldTokenValue) * performanceFee) / (100 * decimalPrecision);

                return
                    (_perfromanceFeeInDollor * 1 ether) /
                    currentPriceInDollerPerToken();
            }
            return 0;
        }
    }

    // Internal method to update the stats after the redeem.
    function _redeem(uint256 amount) private returns (uint256) {
        // Calculate decuctable amount and performance fee.
        uint256 balance = 0;
        uint256 _performanceFee = 0;
        for (
            uint256 i = userInverstmentStats[msg.sender].startingIndex;
            i < userInverstmentStats[msg.sender].endingIndex;
            i++
        ) {
            // Check the remaing amount to be redeemed from all inversments
            uint256 _required = amount > balance ? amount - balance : 0;
            uint256 _amount;
            uint256 _boughtAt;
            if (_required > userInverstments[msg.sender][i].token) {
                // Calculate PerformaceFee for available invesment.
                _amount = userInverstments[msg.sender][i].token;
                _boughtAt = userInverstments[msg.sender][i].atPrice;
                _performanceFee += calculatePerformanceFee(_boughtAt, _amount);
                balance += _amount;
                // Delete the investment and update the starting index.
                delete userInverstments[msg.sender][i];
                userInverstmentStats[msg.sender].startingIndex++;
            } else {
                // Calculate PerformaceFee for available invesment.
                _amount = _required;
                _boughtAt = userInverstments[msg.sender][i].atPrice;
                _performanceFee += calculatePerformanceFee(_boughtAt, _amount);
                balance += _amount;
                // Update the current index and terminate the loop.
                userInverstments[msg.sender][i].token -= _required;
                break;
            }
        }

        // Update the performance fee earned by FundManager.
        preformanceFeeEarned += _performanceFee;

        // Update the withdrawable fund.
        balance -= _performanceFee;

        return balance;
    }

    // method to redeem the investments.
    function redeem(uint256 amount) external nonReentrant whenNotTerminated {
        // Check for the balance
        require(
            balanceOf(msg.sender) >= amount,
            "ActiveFund: Redeem requested more than balance."
        );

        uint256 tokenToSend = _redeem(amount);

        // swap the fund in dollor.
        _swapTokenToDollor(tokenToSend, msg.sender);

        // update totalSupply.
        totalSupply -= tokenToSend;

        emit Redeemed(msg.sender, tokenToSend);
    }

    // method to get fund.
    function revertInvestment() external nonReentrant {
        require(terminated, "ActiveFund: Fund is not terminated yet");

        // get amount
        uint256 amount = balanceOf(msg.sender);

        // update the stats
        uint256 tokenToSend = _redeem(amount);

        // Transfer the usdAmount
        uint256 usdAmount = (tokenToSend / totalSupply) *
            IERC20(usd).balanceOf(address(this));
        IERC20(usd).transfer(msg.sender, usdAmount);

        // update totalSupply.
        totalSupply -= tokenToSend;
    }

    // Method to claim the gained performance fee.
    function claimPerformanceFee() external nonReentrant onlyOwner {
        uint256 platformFee = manager.calculatePlatformFeeOnPerformance(
            preformanceFeeEarned
        );
        IERC20 _usd = IERC20(usd);
        // Transfer amount to fund manager and trasury.
        _usd.transferFrom(
            address(this),
            msg.sender,
            preformanceFeeEarned - platformFee
        );
        _usd.transferFrom(address(this), address(manager), platformFee);

        preformanceFeeEarned = 0;
    }

    function updateComposits(
        address[] memory _currencies,
        uint256[] memory _shares,
        address[] memory _fromCurrencies,
        address[] memory _toCurrencies,
        uint256[] memory _amounts
    ) external onlyOwner {
        // Validate shares
        {
            uint256 sum = 0;
            for (uint256 i = 0; i < _shares.length; i++) {
                sum += _shares[i];
            }
            require(
                sum == 100 * decimalPrecision,
                "PassiveFund: The sum of shares must be 100%"
            );
            require(
                _shares.length == _currencies.length,
                "PassiveFund: Shares and Currencies must have same length"
            );
            require(
                _fromCurrencies.length == _toCurrencies.length &&
                    _toCurrencies.length == _amounts.length,
                "ActiveFund: The length for swapping must be same."
            );
        }
        currencies = _currencies;
        shares = _shares;

        // Perform the exchanges
        for (uint256 i = 0; i < _fromCurrencies.length; i++) {
            uint256 amount = _amounts[i];
            // Allow router the spending limit.
            IERC20(_fromCurrencies[i]).approve(address(router), amount);

            // Swap and except any amount in return.
            router.swapExactTokensForTokens(
                amount, // Amount in dollor
                0, // Accept any amount in return
                manager.getPath(_fromCurrencies[i], _toCurrencies[i]), // The exchange path
                msg.sender, // Get exchnaged value to this contract itself.
                block.timestamp // Perform this exchange in this transaction only.
            );
        }
    }
}