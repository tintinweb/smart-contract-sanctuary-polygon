/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Subscription 
{
    uint256 private constant ONE_HUNDRED = 100**10; // 100000000000000000000;
    uint256 private constant ZERO = 0;
    uint256 private constant PERIOD_30D_LENGTH = 60 * 60 * 24 * 30;
    uint256 private constant PERIOD_1Y_LENGTH = 60 * 60 * 24 * 360; // Not 365 each period has 30 days not 30~31
    uint256 private constant DEFAULT_INITIAL_USAGE_LIMIT = 1;

    uint256 private constant OWNER_NOT_ENTERED = 1;
    uint256 private constant OWNER_ENTERED = 2;
    uint256 private reentrancyForOwnerStatus;
    mapping(address => uint256) private reentrancyStatusLocked;

    mapping(uint => mapping(address => uint256)) private activationTimeLimit; // Service ID => User Address => Time
    mapping(uint => mapping(address => uint256)) private usageLimit; // Service ID => User Address => Amount Limit
    mapping(uint => uint256) private initialUsageLimit;
    mapping(uint => uint256) private priceSetup;
    mapping(uint => uint256) private priceToIncreaseLimit;
    mapping(uint => uint256) private price30D;
    mapping(uint => uint256) private price1Y;
    mapping(uint => mapping(address => uint256)) private activationDiscountPercent; // Service ID => User Address => Discount Percent

    address public owner;
    address public swapRouter;
    address public chainWrapToken;
    address public usdToken;
    address public paymentReceivingAddress;
    uint    public swapUsesMultihop;
    uint    public downtimeToUndoSetup;

    modifier onlyOwner
    {
        require(msg.sender == owner, 'FN'); // FN = Forbidden
        _;
    }

    modifier noReentrancyForOwner
    {
        require(reentrancyForOwnerStatus != OWNER_ENTERED, "REE");
        reentrancyForOwnerStatus = OWNER_ENTERED;
        _;
        reentrancyForOwnerStatus = OWNER_NOT_ENTERED;
    }

    modifier noReentrancy
    {
        require(reentrancyStatusLocked[msg.sender] == 0, "REE");
        reentrancyStatusLocked[msg.sender] = 1;
        _;
        reentrancyStatusLocked[msg.sender] = 0;
    }

    modifier validAddress(address _address) 
    {
       require(_address != address(0), "INVAD");
       _;
    }

    modifier validWallet()
    {
        require( !isContract(msg.sender), "CTR"); // Wallet is a contract
        require(tx.origin == msg.sender, "INVW"); // Invalid wallet origin
        _;
    }

    modifier noActivationValidation(uint serviceId, uint period)
    {
        require(activationTimeLimit[serviceId][msg.sender] < block.timestamp, "SAA"); // The service is already active
        require(price30D[serviceId] > 0, "UP30D"); // Undefined price for 30 days
        require(price1Y[serviceId] > 0, "UP1Y"); // Undefined price for 1 year
        require(period == PERIOD_30D_LENGTH || period == PERIOD_1Y_LENGTH, "IPER"); // Invalid period
        _;
    }

    modifier readyToIncreaseLimitValidation(uint serviceId)
    {
        require(priceToIncreaseLimit[serviceId] > 0, "UPIL"); // Undefined price for increase limit
        require(usageLimit[serviceId][msg.sender] > 0, "NALU"); // There is no active limit for user 
        _;
    }

    modifier ableToReceiveToken(address paymentToken)
    {
        if(paymentToken != usdToken)
        {
            address pairAddress = getPairAddress(paymentToken, usdToken);
            require(pairAddress != address(0), "NPA"); // No Pair With USD Token
        }
        _;
    }

    modifier allowanceForTransferFrom(address token, address fromTransferAddress, address spenderOrDelegate, uint256 amount)
    {
        require(IERC20(token).allowance(fromTransferAddress, spenderOrDelegate) >= amount, "AL"); //Allowance Error
        _;
    }

    modifier validPercentageValue(uint value)
    {
        require(value <= ONE_HUNDRED, "INVP"); // Invalid percentage value
        _;
    }


    event OnwerChange(address indexed newValue);
    event SwapRouterChange(address value);
    event ChainWrapTokenChange(address value);
    event USDTokenChange(address value);
    event PaymentReceivingAddressChange(address value);
    event SwapUsesMultihopChange(uint value);
    event ActivationDiscountPercentChange(uint serviceId, address userAddress, uint256 value);
    event ActivationPriceChange(uint serviceId, uint256 valuePriceSetup, uint256 valuePriceToIncreaseLimit, uint256 valuePrice30D, uint256 valuePrice1Y, uint256 valueInitialUsageLimit);

    constructor()
    {
        owner = msg.sender;
        reentrancyForOwnerStatus = OWNER_NOT_ENTERED;

        /*
        56: WBNB
        137: WMATIC
        1: WETH9
        43114: WAVAX
        97: WBNB testnet
        */
        chainWrapToken = block.chainid == 56 ?  address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) : 
                    (block.chainid == 137 ?     address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270) :
                    (block.chainid == 1 ?       address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) : 
                    (block.chainid == 43114 ?   address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7) : 
                    (block.chainid == 97 ?      address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd) : 
                                                address(0) ) ) ) );

        /*
        56: PancakeRouter
        137: SushiSwap UniswapV2Router02
        1: UniswapV2Router02
        43114: SushiSwap Router
        97: PancakeRouter testnet
        */
        swapRouter = block.chainid == 56 ?      address(0x10ED43C718714eb63d5aA57B78B54704E256024E) : 
                    (block.chainid == 137 ?     address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506) : 
                    (block.chainid == 1 ?       address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) : 
                    (block.chainid == 43114 ?   address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506) : 
                    (block.chainid == 97 ?      address(0xf3e4773A45fC572263a391E7fC7A721530bABf85) : 
                                                address(0) ) ) ) );

        /*
        56: USDT
        137: USDT
        1: USDT
        43114: USDT
        97: USDT testnet
        */
        usdToken = block.chainid == 56 ?        address(0x55d398326f99059fF775485246999027B3197955) : 
                    (block.chainid == 137 ?     address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F) : 
                    (block.chainid == 1 ?       address(0xdAC17F958D2ee523a2206206994597C13D831ec7) : 
                    (block.chainid == 43114 ?   address(0xde3A24028580884448a5397872046a019649b084) : 
                    (block.chainid == 97 ?      address(0x337610d27c682E347C9cD60BD4b3b107C9d34dDd) : 
                                                address(0) ) ) ) );

        paymentReceivingAddress = 0xE7ADcDfB326f3d1c1d513BBe2525D08a7c3C779a;
        swapUsesMultihop = 1;
        downtimeToUndoSetup = 60 * 60 * 24 * 7; // 7 days default
    }

    function getActivationRemainingTime(uint serviceId, address userAddress) external view returns (uint256)
    {
        uint256 timeLimit = activationTimeLimit[serviceId][userAddress];
        uint256 result = ZERO;
        if(timeLimit > block.timestamp)
        {
            result = timeLimit - block.timestamp;
        }
        
        return result;
    }

    function getActivationTimeLimit(uint serviceId, address userAddress) external view returns (uint256)
    {
        return activationTimeLimit[serviceId][userAddress];
    }

    function getUsageLimit(uint serviceId, address userAddress) external view returns (uint256)
    {
        return usageLimit[serviceId][userAddress];
    }

    function getActivationPlans(uint serviceId) external view returns (uint[] memory list)
    {
        uint[] memory result = new uint[](5);

        result[0] = priceSetup[serviceId];
        result[1] = priceToIncreaseLimit[serviceId];
        result[2] = price30D[serviceId];
        result[3] = price1Y[serviceId];
        result[4] = initialUsageLimit[serviceId];

        return result;
    }

    function getActivationPrice(uint serviceId, address paymentToken, uint period, address userAddress) public view returns (uint256)
    {
        uint256 priceUSD;
        if(period == PERIOD_30D_LENGTH)
        {
            priceUSD = price30D[serviceId];
        }
        else if(period == PERIOD_1Y_LENGTH)
        {
            priceUSD = price1Y[serviceId];
        }
        else
        {
            priceUSD = price1Y[serviceId];
        }

        uint256 discountPercent = activationDiscountPercent[serviceId][userAddress];

        if(discountPercent > 0)
        {
            priceUSD = priceUSD - ((priceUSD * discountPercent) / ONE_HUNDRED);
        }

        uint hasSetupFee = hasSetupFeeToCharge(serviceId, userAddress);
        if(hasSetupFee == 1)
        {
            priceUSD = priceUSD + priceSetup[serviceId];
        }

        if(paymentToken == usdToken)
        {
            return priceUSD;
        }

        uint256 priceInPaymentToken = getAmountOutMin(usdToken, paymentToken, priceUSD, swapUsesMultihop);
        return priceInPaymentToken;
    }

    function getIncreaseLimitPrice(uint serviceId, address paymentToken, uint256 amount) public view returns (uint256)
    {
        uint256 priceUSD = priceToIncreaseLimit[serviceId] * amount;

        if(paymentToken == usdToken)
        {
            return priceUSD;
        }

        if(priceUSD == 0)
        {
            return 0;
        }

        uint256 priceInPaymentToken = getAmountOutMin(usdToken, paymentToken, priceUSD, swapUsesMultihop);
        return priceInPaymentToken;
    }

    function activate(uint serviceId, address paymentToken, uint period) external noReentrancy validWallet validAddress(paymentToken) ableToReceiveToken(paymentToken) allowanceForTransferFrom(paymentToken, msg.sender, address(this), getActivationPrice(serviceId, paymentToken, period, msg.sender))
    {
        // Register
        internalActivate(serviceId, period);

        // Price definition
        uint256 amountToReceive = getActivationPrice(serviceId, paymentToken, period, msg.sender);
        
        if(amountToReceive > 0)
        {
            // Payment receiving
            // require(IERC20(paymentToken).allowance(msg.sender, address(this)) >= amountToReceive, "AL"); //Allowance Error

            if(paymentToken != usdToken)
            {
                // Receive here
                IERC20(paymentToken).transferFrom(msg.sender, address(this), amountToReceive);

                // Do swap
                uint256 swapToAmount = getAmountOutMin(paymentToken, usdToken, amountToReceive, swapUsesMultihop);
                internalSwap(paymentToken, usdToken, amountToReceive, swapToAmount, paymentReceivingAddress, swapUsesMultihop);
            }
            else
            {
                // Receive directly
                IERC20(paymentToken).transferFrom(msg.sender, paymentReceivingAddress, amountToReceive);
            }
        }
    }

    function activateUsingNetworkCoin(uint serviceId, uint period) external noReentrancy validWallet payable
    {
        // Register
        internalActivate(serviceId, period);

        // Receiving value check against Price
        uint256 amountToReceive = getActivationPrice(serviceId, chainWrapToken, period, msg.sender);
        require(msg.value >= amountToReceive, "LOWV"); // Low Value

        // Receive payment
        payable(paymentReceivingAddress).transfer(msg.value);

    }

    function internalActivate(uint serviceId, uint period) internal noActivationValidation(serviceId, period)
    {
        activationTimeLimit[serviceId][msg.sender] = block.timestamp + period;

        // On first activation set initial usage limit
        if(usageLimit[serviceId][msg.sender] == 0)
        {
            if(initialUsageLimit[serviceId] > 0)
            {
                usageLimit[serviceId][msg.sender] = initialUsageLimit[serviceId];
            }
            else
            {
                usageLimit[serviceId][msg.sender] = DEFAULT_INITIAL_USAGE_LIMIT;
            }
        }
    }


    function increaseUsageLimit(uint serviceId, address paymentToken, uint256 amount) external noReentrancy validWallet validAddress(paymentToken) ableToReceiveToken(paymentToken) allowanceForTransferFrom(paymentToken, msg.sender, address(this), getIncreaseLimitPrice(serviceId, paymentToken, amount))
    {
        // Register
        internalIncreaseUsageLimit(serviceId, amount);

        // Price definition
        uint256 amountToReceive = getIncreaseLimitPrice(serviceId, paymentToken, amount);
        
        if(amountToReceive > 0)
        {
            if(paymentToken != usdToken)
            {
                // Receive here
                IERC20(paymentToken).transferFrom(msg.sender, address(this), amountToReceive);

                // Do swap
                uint256 swapToAmount = getAmountOutMin(paymentToken, usdToken, amountToReceive, swapUsesMultihop);
                internalSwap(paymentToken, usdToken, amountToReceive, swapToAmount, paymentReceivingAddress, swapUsesMultihop);
            }
            else
            {
                // Receive directly
                IERC20(paymentToken).transferFrom(msg.sender, paymentReceivingAddress, amountToReceive);
            }
        }
    }

    function increaseUsageLimitUsingNetworkCoin(uint serviceId, uint256 amount) external noReentrancy validWallet payable
    {
        // Register
       internalIncreaseUsageLimit(serviceId, amount);

        // Receiving value check against Price
        uint256 amountToReceive = getIncreaseLimitPrice(serviceId, chainWrapToken, amount);
        require(msg.value >= amountToReceive, "LOWV"); // Low Value

        // Receive payment
        payable(paymentReceivingAddress).transfer(msg.value);
    }

    function internalIncreaseUsageLimit(uint serviceId, uint256 amount) internal readyToIncreaseLimitValidation(serviceId)
    {
        usageLimit[serviceId][msg.sender] = usageLimit[serviceId][msg.sender] + amount;
    }


    function hasSetupFeeToCharge(uint serviceId, address userAddress) public view returns (uint)
    {
        uint256 timeLimit = activationTimeLimit[serviceId][userAddress];

        if(timeLimit == ZERO)
        {
            // Never activated (has setup fee)
            return 1;
        }

        if(timeLimit >= block.timestamp)
        {
            // Already active (no setup fee)
            return 0;
        }

        uint elapsedTime = block.timestamp - timeLimit;
        if(elapsedTime >= downtimeToUndoSetup)
        {
            // Previous setup was undone (has setup fee)
            return 1;
        }
        else
        {
            // Make use of the previous configuration (no setup fee)
            return 0;
        }

    }


    function setOwner(address newValue) external onlyOwner noReentrancyForOwner validAddress(newValue) validWallet
    {
        owner = newValue;
        emit OnwerChange(newValue);
    }

    function setSwapRouter(address value) external onlyOwner noReentrancyForOwner validWallet validAddress(value)
    {
        swapRouter = value;
        emit SwapRouterChange(value);
    }

    function setChainWrapToken(address value) external onlyOwner noReentrancyForOwner validWallet validAddress(value)
    {
        chainWrapToken = value;
        emit ChainWrapTokenChange(value);
    }

    function setUSDToken(address value) external onlyOwner noReentrancyForOwner validWallet validAddress(value)
    {
        usdToken = value;
        emit USDTokenChange(value);
    }

    function setPaymentReceivingAddress(address value) external onlyOwner noReentrancyForOwner validWallet validAddress(value)
    {
        paymentReceivingAddress = value;
        emit PaymentReceivingAddressChange(value);
    }

    function setSwapUsesMultihop(uint value) external onlyOwner noReentrancyForOwner validWallet
    {
        swapUsesMultihop = value;
        emit SwapUsesMultihopChange(value);
    }

    function getActivationDiscountPercent(uint serviceId, address userAddress) external view returns (uint256)
    {
        return activationDiscountPercent[serviceId][userAddress];
    }

    function setActivationDiscountPercent(uint serviceId, address userAddress, uint256 value) external onlyOwner noReentrancyForOwner validWallet validAddress(userAddress) validPercentageValue(value)
    {
        activationDiscountPercent[serviceId][userAddress] = value;
        emit ActivationDiscountPercentChange(serviceId, userAddress, value);
    }

    function setActivationPrice(uint[] memory serviceIdList, uint256[] memory priceSetupList, uint256[] memory priceToIncreaseLimitList, uint256[] memory price30DList, uint256[] memory price1YList, uint256[] memory initialUsageLimitList) external onlyOwner noReentrancyForOwner validWallet
    {
        require(serviceIdList.length == priceSetupList.length && 
                serviceIdList.length == priceToIncreaseLimitList.length && 
                serviceIdList.length == price30DList.length && 
                serviceIdList.length == price1YList.length &&
                serviceIdList.length == initialUsageLimitList.length, 
        "ISZ"); // Invalid Size
        
        for(uint ix = 0; ix < serviceIdList.length; ix++)
        {
            uint serviceId = serviceIdList[ix];
            uint256 valuePriceSetup = priceSetupList[ix];
            uint256 valuePriceToIncreaseLimit = priceToIncreaseLimitList[ix];
            uint256 valuePrice30D = price30DList[ix];
            uint256 valuePrice1Y = price1YList[ix];
            uint256 valueInitialUsageLimit = initialUsageLimitList[ix];

            priceSetup[serviceId] = valuePriceSetup;
            priceToIncreaseLimit[serviceId] = valuePriceToIncreaseLimit;
            price30D[serviceId] = valuePrice30D;
            price1Y[serviceId] = valuePrice1Y;
            initialUsageLimit[serviceId] = valueInitialUsageLimit;

            emit ActivationPriceChange(serviceId, valuePriceSetup, valuePriceToIncreaseLimit, valuePrice30D, valuePrice1Y, valueInitialUsageLimit);
        }
    }

    function setDowntimeToUndoSetup(uint newValue) external onlyOwner noReentrancyForOwner validWallet
    {
        downtimeToUndoSetup = newValue;
    }

    function removeSubscription(uint serviceId, address userAddress) external onlyOwner noReentrancyForOwner validWallet
    {
        activationTimeLimit[serviceId][userAddress] = 0;
        usageLimit[serviceId][userAddress] = 0;
    }

    // AMM Functions
    function getPairAddress(address tokenA, address tokenB) private view returns (address)
    {
        address factory = IUniswapV2Router(swapRouter).factory();
        address pairAddress = IUniswapV2Factory(factory).getPair(tokenA, tokenB);

        return pairAddress;
    }

    function getAmountOutMin(address tokenIn, address tokenOut, uint256 amountIn, uint multihopWithWrapToken) public view returns (uint256) 
    {

       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
       //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (tokenIn == chainWrapToken || tokenOut == chainWrapToken || multihopWithWrapToken == 0) 
        {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
        } 
        else 
        {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = chainWrapToken;
            path[2] = tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router(swapRouter).getAmountsOut(amountIn, path);
        return amountOutMins[path.length -1];  
    }

    function internalSwap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, address to, uint multihopWithWrapToken) private 
    {
        if(tokenIn != chainWrapToken)
        {
            require( IERC20(tokenIn).balanceOf( address(this) ) >= amountIn, "LOWSWAPBALANCE" ); //Low balance before swap

            // We need to allow the uniswapv2 router to spend the token we just sent to this contract
            // by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
            IERC20(tokenIn).approve(swapRouter, amountIn);
        }

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;

        if (tokenIn == chainWrapToken || tokenOut == chainWrapToken || multihopWithWrapToken == 0) 
        {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
        } 
        else 
        {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = chainWrapToken;
            path[2] = tokenOut;
        }

        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        if (tokenOut == chainWrapToken)
        {
            IUniswapV2Router(swapRouter).swapExactTokensForETH(amountIn, amountOutMin, path, to, block.timestamp);
        }
        else
        {
            IUniswapV2Router(swapRouter).swapExactTokensForTokens(amountIn, amountOutMin, path, to, block.timestamp);
        }

    }

    function isContract(address account) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// ****************************************************
// ******************** INTERFACE *********************
// ****************************************************
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ****************************************************
// ***************** UNIV2 INTERFACES *****************
// ****************************************************
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

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
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
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router {
    function factory() external view returns (address);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  
    function swapExactTokensForTokens(
        //amount of tokens we are sending in
        uint256 amountIn,
        
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
    
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
    
        //this is the address we are going to send the output tokens to
        address to,
    
        //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external returns (uint[] memory amounts);

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
    
}