/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.9.1 https://hardhat.org

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

 
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


// File contracts/IMarketplace.sol

 

pragma solidity ^0.8.9;

interface IMarketplace {
    enum ProductState {
        NotDeployed,                // non-existent or deleted
        Deployed                    // created or redeployed
    }

    enum WhitelistState{
        None,
        Pending,
        Approved,
        Rejected
    }

    function createProduct(
        bytes32 id,
        string memory name,
        address beneficiary,
        uint pricePerSecond,
        address pricingTokenAddress,
        uint minimumSubscriptionSeconds
    ) external;

    function ownerCreateProduct(
        bytes32 id,
        string memory name,
        address beneficiary,
        uint pricePerSecond,
        address pricingToken,
        uint minimumSubscriptionSeconds,
        address productOwner
    ) external;

    // product events
    event ProductCreated(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, address pricingTokenAddress, uint minimumSubscriptionSeconds);
    event ProductUpdated(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, address pricingTokenAddress, uint minimumSubscriptionSeconds);
    event ProductDeleted(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, address pricingTokenAddress, uint minimumSubscriptionSeconds);
    event ProductImported(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, address pricingTokenAddress, uint minimumSubscriptionSeconds);
    event ProductRedeployed(address indexed owner, bytes32 indexed id, string name, address beneficiary, uint pricePerSecond, address pricingTokenAddress, uint minimumSubscriptionSeconds);
    event ProductOwnershipOffered(address indexed owner, bytes32 indexed id, address indexed to);
    event ProductOwnershipChanged(address indexed newOwner, bytes32 indexed id, address indexed oldOwner);

    // subscription events
    event Subscribed(bytes32 indexed productId, address indexed subscriber, uint endTimestamp);
    event NewSubscription(bytes32 indexed productId, address indexed subscriber, uint endTimestamp);
    event SubscriptionExtended(bytes32 indexed productId, address indexed subscriber, uint endTimestamp);
    event SubscriptionImported(bytes32 indexed productId, address indexed subscriber, uint endTimestamp);
    event SubscriptionTransferred(bytes32 indexed productId, address indexed from, address indexed to, uint secondsTransferred);

    // whitelist events
    event WhitelistRequested(bytes32 indexed productId, address indexed subscriber);
    event WhitelistApproved(bytes32 indexed productId, address indexed subscriber);
    event WhitelistRejected(bytes32 indexed productId, address indexed subscriber);
    event WhitelistEnabled(bytes32 indexed productId);
    event WhitelistDisabled(bytes32 indexed productId);

    // txFee events
    event TxFeeChanged(uint256 indexed newTxFee);

    // admin functionality events
    event Halted();
    event Resumed();

    function getSubscription(bytes32 productId, address subscriber) external view returns (bool isValid, uint endTimestamp);
    function hasValidSubscription(bytes32 productId, address subscriber) external view returns (bool isValid);

    function getProduct(bytes32 id) external view returns (string memory name, address owner, address beneficiary, uint pricePerSecond, address pricingTokenAddress, uint minimumSubscriptionSeconds, ProductState state, bool requiresWhitelist);

    function buy(bytes32 productId, uint subscriptionSeconds) external;

    function buyFor(bytes32 productId, uint subscriptionSeconds, address recipient) external;
}


// File contracts/Uniswap2Adapter.sol

 

pragma solidity ^0.8.9;


contract Uniswap2Adapter {

    IMarketplace public marketplace;
    IUniswapV2Router02 public uniswapRouter;
    address public liquidityToken;

    constructor(address _marketplace, address _uniswapRouter) {
        marketplace = IMarketplace(_marketplace);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    function _getPriceInfo(bytes32 productId) internal view returns (uint, address) {
        (, address owner,, uint pricePerSecond, address pricingTokenAddress,,,) = marketplace.getProduct(productId);
        require(owner != address(0), "not found");
        return (pricePerSecond, pricingTokenAddress);
    }

    function buyWithERC20(bytes32 productId, uint minSubscriptionSeconds,uint timeWindow, address erc20_address, uint amount) public {
        require(erc20_address != address(0), "use buyWithETH instead");
        (uint pricePerSecond, address pricingTokenAddress) = _getPriceInfo(productId);

        if (pricePerSecond == 0x0) {
            //subscription is free. return payment and subscribe
            marketplace.buyFor(productId, minSubscriptionSeconds, msg.sender);
            return;
        }

        IERC20 fromToken = IERC20(erc20_address);
        require(fromToken.transferFrom(msg.sender, address(this), amount), "must pre approve token transfer");
        require(fromToken.approve(address(uniswapRouter), 0), "approval failed");
        require(fromToken.approve(address(uniswapRouter), amount), "approval failed");

        _buyWithUniswap(productId, minSubscriptionSeconds, timeWindow, pricePerSecond, amount, erc20_address, pricingTokenAddress);
    }

    function buyWithETH(bytes32 productId, uint minSubscriptionSeconds,uint timeWindow) public payable{
        (uint pricePerSecond, address pricingTokenAddress) = _getPriceInfo(productId);

        if (pricePerSecond == 0x0) {
            //subscription is free. return payment and subscribe
            if (msg.value > 0x0) {
                payable(msg.sender).transfer(msg.value);
            }
            marketplace.buyFor(productId, minSubscriptionSeconds, msg.sender);
            return;
        }

        _buyWithUniswap(productId, minSubscriptionSeconds, timeWindow, pricePerSecond, msg.value, uniswapRouter.WETH(), pricingTokenAddress);
    }

    /**
     * Swap buyer tokens for product tokens and buy subscription seconds for the product
     * @param productId the product id in bytes32
     * @param minSubscriptionSeconds minimum seconds received, without reverting the transaction
     * @param timeWindow the time window in which the transaction should be completed
     * @param amount the tokens paid for the subscription
     * @param fromToken the buyer's token. If equal with uniswapRouter.WETH(), it means ETH
     * @param toToken the product's token
     * @dev https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02
     */
    function _buyWithUniswap(bytes32 productId, uint minSubscriptionSeconds, uint timeWindow, uint pricePerSecond, uint amount, address fromToken, address toToken) internal{
        // TODO: amountOutMin must be retrieved from an oracle of some kind
        uint amountOutMin = 1; // The minimum amount of output tokens that must be received for the transaction not to revert.
        address[] memory path = _uniswapPath(fromToken, toToken); // An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
        address to = address(this); // Recipient of the output tokens.
        uint deadline = block.timestamp + timeWindow; // Unix timestamp after which the transaction will revert.

        // swapExactETHForTokens/swapExactTokensForTokens returns the input token amount and all subsequent output token amounts.
        uint receivedTokens;
        if (fromToken == address(uniswapRouter.WETH())) {
            receivedTokens = uniswapRouter.swapExactETHForTokens{ value: amount }(amountOutMin, path, to, deadline)[path.length - 1];
        }
        else {
            receivedTokens = uniswapRouter.swapExactTokensForTokens(amount, amountOutMin, path, to, deadline)[path.length - 1];
        }

        uint subscriptionSeconds = receivedTokens / pricePerSecond;
        require(subscriptionSeconds >= minSubscriptionSeconds, "error_minSubscriptionSeconds");

        require(IERC20(toToken).approve(address(marketplace), receivedTokens), "approval failed");
        marketplace.buyFor(productId, subscriptionSeconds, msg.sender); // TODO: use _msgSender for GSN compatibility
    }

    function _uniswapPath(address fromCoin, address toCoin) internal view returns (address[] memory path) {
        if (liquidityToken == address(0)) {
            //no intermediate
            path = new address[](2);
            path[0] = fromCoin;
            path[1] = toCoin;
            return path;
        }
        //use intermediate liquidity token
        path = new address[](3);
        path[0] = fromCoin;
        path[1] = liquidityToken;
        path[2] = toCoin;
        return path;
    }

    /**
     * ERC677 token callback
     * If the data bytes contains a product id, the subscription is extended for that product
     * @dev The amount transferred is in pricingTokenAddress.
     * @dev msg.sender is the contract which supports ERC677.
     * @param sender The EOA initiating the transaction through transferAndCall.
     * @param amount The amount to be transferred (in wei).
     * @param data The extra data to be passed to the contract. Contains the product id.
     */
    function onTokenTransfer(address sender, uint amount, bytes calldata data) external {
        require(data.length == 32, "error_badProductId");
        
        bytes32 productId;
        assembly { productId := calldataload(data.offset) } // solhint-disable-line no-inline-assembly

        IERC20 fromToken = IERC20(msg.sender);
        require(fromToken.approve(address(uniswapRouter), 0), "approval failed");
        require(fromToken.approve(address(uniswapRouter), amount), "approval failed"); // current contract has amount tokens and can approve the router to spend them

        (uint pricePerSecond, address pricingTokenAddress) = _getPriceInfo(productId);

        address[] memory path = _uniswapPath(msg.sender, pricingTokenAddress);
        uint receivedTokens = uniswapRouter.swapExactTokensForTokens(amount, 1, path, address(this), block.timestamp + 86400)[path.length - 1];

        require(IERC20(pricingTokenAddress).approve(address(marketplace), 0), "approval failed");
        require(IERC20(pricingTokenAddress).approve(address(marketplace), receivedTokens), "approval failed");
        uint subscriptionSeconds = receivedTokens / pricePerSecond;
        marketplace.buyFor(productId, subscriptionSeconds, sender);
    }
}