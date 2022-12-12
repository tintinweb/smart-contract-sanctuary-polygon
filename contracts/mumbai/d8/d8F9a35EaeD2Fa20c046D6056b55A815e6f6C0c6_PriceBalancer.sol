// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../4. Interfaces/IPriceOracle.sol";
import "../4. Interfaces/IQuickSwap.sol";
import "../4. Interfaces/IQuickSwapRouter.sol";

contract PriceBalancer is Ownable {
    // Variables
    address public owner2;
    bool public isVested = false;
    uint256 public vestingTime;
    uint256 public buyPrice;
    uint256 public sellPrice;
    uint256 public buyTarget;
    uint256 public sellTarget;
    uint256 public limit;
    uint256 public usdcBalanceRef;
    uint256 public timestampRef;
    address public usdcAddress; // 0x3813e82e6f7098b9583FC0F33a962D02018B6803
    address public rdkAddress;

    IPriceOracle priceOracle;
    IQuickSwap pair;
    IQuickSwapRouter router;

    enum OperationType {
        BUY,
        SELL
    }

    event UpdateRef(
        uint256 indexed usdcBalanceRef,
        uint256 indexed timestampRef
    );
    event BuyTokens(uint256 indexed inputAmount);
    event SellTokens(uint256 indexed inputAmount);

    constructor(
        address _owner1,
        address _owner2,
        address _pairAddress,
        address _routerAddress,
        address _usdcAddress,
        address _rdkAddress,
        uint256 _buyPrice,
        uint256 _sellPrice,
        uint256 _buyTarget,
        uint256 _sellTarget,
        uint256 _limit
    ) {
        Ownable(_owner1);
        owner2 = _owner2;
        priceOracle = IPriceOracle(_pairAddress);
        pair = IQuickSwap(_pairAddress);
        router = IQuickSwapRouter(_routerAddress);
        usdcAddress = _usdcAddress;
        rdkAddress = _rdkAddress;
        buyPrice = _buyPrice;
        sellPrice = _sellPrice;
        buyTarget = _buyTarget;
        sellTarget = _sellTarget;
        limit = _limit;
    }

    /******************************************************
     *                                                    *
     *                   MAIN FUNCTIONS                   *
     *                                                    *
     ******************************************************/

    // Main function to execute the trade if necessary
    function execute() external onlyOwners {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        uint256 scaleUp = 10**30; // scale 18 and decimals diff 12
        uint256 currentPrice = (scaleUp * uint256(reserve0)) /
            uint256(reserve1);
        bool bought;
        bool sold;
        bool updated;

        if (
            currentPrice <= buyPrice &&
            address(this).balance > usdcBalanceRef - limit
        ) bought = _buyTokens();
        if (currentPrice >= sellPrice) {
            sold = _sellTokens();
        }
        updated = _updateBalanceRef(address(this).balance);
        require(
            bought || sold || updated,
            "priceBalancer: price not in range to operate and no ref to be updated"
        );
    }

    // Withdraw  ALL tokens from contract
    function withdrawAllTokens(address _tokenAddress)
        external
        onlyOwners
        withdrawable
    {
        IERC20(_tokenAddress).transfer(
            msg.sender,
            IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

    // Withdraw some tokens from contract
    function withdrawTokens(address _tokenAddress, uint256 _amount)
        external
        onlyOwners
        withdrawable
    {
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
    }

    // Move contract reserves to liquidity pool
    function addLiquidity(uint256 usdcAmount, uint256 rdkAmount)
        external
        onlyOwners
    {
        IERC20(usdcAddress).approve(address(router), usdcAmount);
        IERC20(rdkAddress).approve(address(router), rdkAmount);
        router.addLiquidity(
            usdcAddress,
            rdkAddress,
            usdcAmount,
            rdkAmount,
            0,
            0,
            address(this),
            block.timestamp + 120
        );
    }

    // Redeem LP tokens to get the liquidity back to this contract
    function removeLiquidity(uint256 lpAmount) external onlyOwners {
        IERC20(address(pair)).approve(address(router), lpAmount);
        router.removeLiquidity(
            usdcAddress,
            rdkAddress,
            lpAmount,
            0,
            0,
            address(this),
            block.timestamp + 120
        );
    }

    function _buyTokens() internal returns (bool) {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        uint256 inputAmount = getInputAmount(
            buyTarget,
            uint256(reserve0),
            uint256(reserve1),
            OperationType.BUY
        );
        address[] memory path = new address[](2);
        path[0] = usdcAddress;
        path[1] = rdkAddress;

        IERC20(usdcAddress).approve(address(router), inputAmount);
        router.swapExactTokensForTokens(
            inputAmount,
            0,
            path,
            address(this),
            block.timestamp + 120
        );
        emit BuyTokens(inputAmount);
        return true;
    }

    function _sellTokens() internal returns (bool) {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        uint256 inputAmount = getInputAmount(
            buyTarget,
            uint256(reserve0),
            uint256(reserve1),
            OperationType.SELL
        );
        address[] memory path = new address[](2);
        path[0] = rdkAddress;
        path[1] = usdcAddress;

        IERC20(rdkAddress).approve(address(router), inputAmount);
        router.swapExactTokensForTokens(
            inputAmount,
            0,
            path,
            address(this),
            block.timestamp + 120
        );
        emit SellTokens(inputAmount);
        return true;
    }

    function _updateBalanceRef(uint256 usdcBalance) internal returns (bool) {
        if (
            usdcBalance > usdcBalanceRef ||
            block.timestamp > timestampRef + 86400
        ) {
            usdcBalanceRef = usdcBalance;
            timestampRef = block.timestamp;
            emit UpdateRef(usdcBalanceRef, timestampRef);
            return true;
        }

        return false;
    }

    /******************************************************
     *                                                    *
     *                       HELPERS                      *
     *                                                    *
     ******************************************************/

    // uint inputAmount = (sqrt((priceNumerator * inputReserve * outputReserve) / priceDenominator) * priceDenominator) / priceNumerator - inputReserve;
    function getInputAmount(
        uint256 targetPrice,
        uint256 x,
        uint256 y,
        OperationType operationType
    ) public pure returns (uint256) {
        uint256 scaleUp = 10**18;
        return
            operationType == OperationType.BUY
                ? uint256(
                    y -
                        (sqrt((targetPrice * x * y) / scaleUp) * scaleUp) /
                        targetPrice
                )
                : uint256(
                    (sqrt((targetPrice * x * y) / scaleUp) * scaleUp) /
                        targetPrice -
                        y
                );
    }

    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /******************************************************
     *                                                    *
     *                   ADMIN SETTERS                    *
     *                                                    *
     ******************************************************/

    // Set prices at whitch the contract will buy / sell
    function setPrices(uint256 _buyPrice, uint256 _sellPrice)
        external
        onlyOwners
    {
        buyPrice = _buyPrice;
        sellPrice = _sellPrice;
    }

    // Set prices to be targeted when the contract buys / sells
    function setTargets(uint256 _buyTarget, uint256 _sellTarget)
        external
        onlyOwners
    {
        buyTarget = _buyTarget;
        sellTarget = _sellTarget;
    }

    // Limit of value to be spent byt the contract during the last 24H
    function setLimit(uint256 _limit) external onlyOwners {
        limit = _limit;
    }

    // Change the owner2
    function changeOwner2(address _newOwner) public {
        // only the current owner or owner2 can change the owner2
        require(
            msg.sender == owner() || msg.sender == owner2,
            "TwoOwners: Only the current owner or owner2 can change owner2"
        );
        owner2 = _newOwner;
    }

    function updateTimeRef() external onlyOwners {
        timestampRef = block.timestamp;
    }

    function vestTokens() external onlyOwners {
        isVested = true;
        vestingTime = block.timestamp + 31536000;
    }

    /******************************************************
     *                                                    *
     *                      MODIFIERS                     *
     *                                                    *
     ******************************************************/

    modifier onlyOwners() {
        require(
            owner() == _msgSender() || owner2 == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    modifier withdrawable() {
        require(
            isVested == false || block.timestamp > vestingTime,
            "Ownable: caller is not the owner"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuickSwap {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuickSwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceOracle {
  function getTokenToUsdt(uint tokenQuantity) external view returns(uint exchange);
  function getUsdtToToken(uint usdtQuantity) external view returns(uint exchange);
  function getLatestPrice() external view returns (int);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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