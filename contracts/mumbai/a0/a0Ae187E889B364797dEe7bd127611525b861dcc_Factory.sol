/**
 *Submitted for verification at polygonscan.com on 2023-07-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Factory 
{
    uint256 private constant ONE_HUNDRED = 100**10; // 100000000000000000000;
    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint private constant MAX_DECIMALS = 18;
    uint private constant INITIAL_TOKEN_LIMIT = 2;

    // Platform Owner Parameters
    address public platformOwner;
    uint256 public platformFeePercent;
    address public platformFeeAddress;

    // Factory Owner Parameters
    address[] private tokens;
    uint256 public tokenCount;
    mapping(address => uint) public tokenRegistered;
    mapping(address => uint) public totalToken; // Deployer => Total of deployed tokens
    mapping(address => string) public tokenData;
    mapping(address => address) public tokenOwner;
    mapping(address => uint[2]) public tokenPrimaryDistributionPeriod;
    mapping(address => address[]) private tokenInitialPriceReceivingToken;
    mapping(address => mapping(address => uint256)) private tokenInitialPrice; // Token Address => Receiving Address => Price
    mapping(address => uint256) public tokenFeePercentForLiquidity;
    mapping(address => PrimaryPurchase[]) private tokenPurchase;
    mapping(address => mapping(address => uint256)) private tokenLiquidityBag; // Token Address => Receiving Address => Amount
    mapping(address => mapping(address => uint256)) private tokenLiquidityComputed; // Token Address => Receiving Address => Amount
    mapping(address => string) public tokenDeployConstructorCode;
    mapping(address => uint256) public tokenIndex;
    mapping(address => uint) public tokenActive;
    mapping(address => address[]) private tokenListByOwner;

    uint256 private constant STATUS_OWNER_NOT_ENTERED = 1;
    uint256 private constant STATUS_OWNER_ENTERED = 2;
    uint256 private reentrancyForPlatformOwnerStatus;
    mapping(address => uint256) private reentrancyForTokenOwnerStatus;

    uint private constant SUBSCRIPTION_PRODUCT_ID = 1;
    address public subscription;

    struct ReceivingTokenDetails {
        address receivingToken;
        uint256 initialPrice;
        uint256 liquidityBag;
        uint256 liquidityComputed;
    }

    struct PrimaryDistributionForecast {
        uint256 quotePrice;
        uint256 platformFeeValueFromSource;
        uint256 amountToBuyUsingSource;
        uint256 amountForBuyerToReceive;
        uint256 liquidityFeePercent;
        uint256 liquidityFeeValue;
        uint256 amountForTokenOwner;
    }

    struct PrimaryPurchase {
        uint time;
        address buyer;
        address receivingToken;
        uint256 sourceAmount;
        uint256 destinationAmount;
    }

    event TokenDeployed(address tokenAddress);
    event PrimaryDistributionBought(address tokenAddress, address tokenSource, uint256 sourceAmount, uint256 receivedAmount);

    modifier onlyPlatformOwner()
    {
        require(msg.sender == platformOwner, 'FN'); // Forbidden
        _;
    }

    modifier onlySubscribed()
    {
        require(subscription != address(0), "NS"); // Subscription not started
        require(ISubscription(subscription).getActivationRemainingTime(SUBSCRIPTION_PRODUCT_ID, msg.sender) > 0, "NA"); // Account not active
        _;
    }

    modifier onlyTokenOnwer(address tokenAddress)
    {
        require(msg.sender == tokenOwner[tokenAddress], 'FN'); // Forbidden
        _;
    }

    modifier noReentrancyForPlatformOwner()
    {
        require(reentrancyForPlatformOwnerStatus != STATUS_OWNER_ENTERED, "REE");
        reentrancyForPlatformOwnerStatus = STATUS_OWNER_ENTERED;
        _;
        reentrancyForPlatformOwnerStatus = STATUS_OWNER_NOT_ENTERED;
    }

    modifier noReentrancyForTokenOwner()
    {
        require(reentrancyForTokenOwnerStatus[msg.sender] != STATUS_OWNER_ENTERED, "REEO");
        reentrancyForTokenOwnerStatus[msg.sender] = STATUS_OWNER_ENTERED;
        _;
        reentrancyForTokenOwnerStatus[msg.sender] = STATUS_OWNER_NOT_ENTERED;
    }

    modifier validToken(address tokenAddress) 
    {
        require(tokenRegistered[tokenAddress] == 1, "NREG"); // Not Registered Token
        require(tokenActive[tokenAddress] == 1, "INTK"); // Invalid Token
        _;
    }

    modifier validAddress(address _address) 
    {
       require(_address != address(0), "INAD"); // Invalid address
       _;
    }

    modifier validWallet()
    {
        require(Hlp.isContract(msg.sender) == false, "ISCNTRCT"); // Wallet is a contract
        require(tx.origin == msg.sender, "INWOR"); // Invalid wallet origin
        _;
    }

    modifier deployValidation(uint256 initialSupply, uint256 primaryDistributionAmount, uint256 feePercentForLiquidity)
    {
        require(initialSupply >= primaryDistributionAmount, 'INS'); // Invalid supply
        require(feePercentForLiquidity <= ONE_HUNDRED, 'INFL'); // Invalid fee percent for liquidity
        require(totalToken[msg.sender] < ISubscription(subscription).getActivationTimeLimit(SUBSCRIPTION_PRODUCT_ID, msg.sender), 'DLR'); // Deploy limit reached
        _;
    }

    modifier registerValidation(address tokenAddress)
    {
        require(tokenRegistered[tokenAddress] == 0, 'ARG'); // Already registered
        _;
    }

    modifier initialPriceValidation(uint256[] memory initialPrice, address[] memory initialPriceReceivingToken)
    {
        require(initialPrice.length > 0, 'NIP'); // No initial price
        require(initialPrice.length == initialPriceReceivingToken.length, 'INIP'); // Invalid initial price length

        for(uint ix = 0; ix < initialPriceReceivingToken.length; ix++)
        {
            require(initialPriceReceivingToken[ix] != address(0), "TKIN"); // Token invalid address
            require(initialPrice[ix] > 0, "ZIP"); // Zero initial price
        }
        _;
    }

    modifier buyFromPrimaryDistributionValidation(address tokenAddress, address tokenSource, uint256 sourceAmount)
    {
        require(tokenPrimaryDistributionPeriod[tokenAddress][0] <= block.timestamp && tokenPrimaryDistributionPeriod[tokenAddress][1] >= block.timestamp, "PNSC"); // Primary Distribution Not Started Or Closed
        require(sourceAmount > 0, "ZSA"); // Zero Source Amount
        require(tokenInitialPrice[tokenAddress][tokenSource] > 0, "UNP"); // Undefined Price
        _;
    }

    modifier allowanceForTransferFrom(address[3] memory addressesParameters, uint256 amount)
    {
        // token = addressesParameters[0]
        // fromTransferAddress = addressesParameters[1]
        // spenderOrDelegate = addressesParameters[2]
        require(IERC20( addressesParameters[0] ).allowance(addressesParameters[1], addressesParameters[2]) >= amount, "AL"); //Allowance Error
        _;
    }

    modifier changePrimateDistributionTimeValidation(address tokenAddress, uint[2] memory newValue)
    {
        require(tokenPrimaryDistributionPeriod[tokenAddress][1] >= block.timestamp, "PDC"); // Primary Distribution Closed
        
        // Check if primary status is started
        if(tokenPrimaryDistributionPeriod[tokenAddress][0] <= block.timestamp)
        {
            // Cannot modify start date if primary started
            require(newValue[0] == tokenPrimaryDistributionPeriod[tokenAddress][0], "SCBM"); // Start Date Cannot be modified
        }
        require(newValue[0] < newValue[1], "ISE"); // Invalid Stard and End Time
        require(newValue[1] > block.timestamp, "IPT"); // Invalid Primary Distribution Time
        _;
    }

    modifier validStartEndDate(uint startDate, uint endDate)
    {
        require(startDate >= block.timestamp - 86400, "ISD"); // Invalid Start Date
        require(endDate > block.timestamp + 86400, "IED"); // Invalid End Date
        _;
    }

    constructor()
    {
        // Platform initial setup
        platformOwner = msg.sender; 
        platformFeeAddress = msg.sender;
        platformFeePercent = (10**18)*2; // 2%
        reentrancyForPlatformOwnerStatus = STATUS_OWNER_NOT_ENTERED;
    }

    /*
        SUBSCRIBED FUNCTIONS
    */
    function deployToken(uint256[6] memory valuedParameters, string[4] memory textParameters, uint256[] memory initialPrice, address[] memory initialPriceReceivingToken, address tokenOwnerAddress) external validAddress(tokenOwnerAddress)
    {
        // initialSupply = valuedParameters[0]
        // primaryDistributionAmount = valuedParameters[1]
        // primaryDistributionStartTime = valuedParameters[2]
        // primaryDistributionEndTime = valuedParameters[3]
        // feePercentForLiquidity = valuedParameters[4]
        // decimalUnits = valuedParameters[5]

        // name = textParameters[0]
        // symbol = textParameters[1]
        // data = textParameters[2]
        // deployConstructorCode = textParameters[3]

        ERCToken token = new ERCToken(valuedParameters[0], valuedParameters[1], textParameters[0], uint8(valuedParameters[5]), textParameters[1], tokenOwnerAddress, address(this));
        
        address tokenAddress = address(token);

        internalRegisterToken(tokenAddress, [valuedParameters[1], valuedParameters[2], valuedParameters[3], valuedParameters[4]], textParameters[2], textParameters[3], tokenOwnerAddress, initialPrice, initialPriceReceivingToken);

        // return tokenAddress;
    }

    function registerToken(address tokenAddress, uint256[4] memory valuedParameters, string memory data, address tokenOwnerAddress, uint256[] memory initialPrice, address[] memory initialPriceReceivingToken) external validAddress(tokenAddress) registerValidation(tokenAddress) allowanceForTransferFrom([tokenAddress, msg.sender, address(this)], valuedParameters[0])
    {
        internalRegisterToken(tokenAddress, valuedParameters, data, "", tokenOwnerAddress, initialPrice, initialPriceReceivingToken);

        // Transfer the amount for Primary Distribution
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), valuedParameters[0]);
    }

    function internalRegisterToken(address tokenAddress, uint256[4] memory valuedParameters, string memory data, string memory deployConstructorCode, address tokenOwnerAddress, uint256[] memory initialPrice, address[] memory initialPriceReceivingToken) private validWallet onlySubscribed deployValidation(IERC20(tokenAddress).totalSupply(), valuedParameters[0], valuedParameters[3]) validStartEndDate(valuedParameters[1], valuedParameters[2])
    {
        // primaryDistributionAmount = valuedParameters[0]
        // primaryDistributionStartTime = valuedParameters[1]
        // primaryDistributionEndTime = valuedParameters[2]
        // feePercentForLiquidity = valuedParameters[3]

        tokens.push(tokenAddress);
        tokenIndex[tokenAddress] = tokenCount;
        tokenCount += 1;
        
        tokenData[tokenAddress] = data;
        tokenOwner[tokenAddress] = tokenOwnerAddress;
        tokenListByOwner[tokenOwnerAddress].push(tokenAddress);

        tokenFeePercentForLiquidity[tokenAddress] = valuedParameters[3];
        tokenPrimaryDistributionPeriod[tokenAddress][0] = valuedParameters[1];
        tokenPrimaryDistributionPeriod[tokenAddress][1] = valuedParameters[2];
        tokenDeployConstructorCode[tokenAddress] = deployConstructorCode;

        // Set as active and registered befire set initial price
        tokenActive[tokenAddress] = 1;
        tokenRegistered[tokenAddress] = 1;

        totalToken[msg.sender] = totalToken[msg.sender] + 1;

        // Set initial price for all receiving tokens
        internalSetTokenInitialPrice(tokenAddress, initialPrice, initialPriceReceivingToken);

        reentrancyForTokenOwnerStatus[tokenOwnerAddress] = STATUS_OWNER_NOT_ENTERED;
        
        emit TokenDeployed(tokenAddress);
    }

    /*
        PLATFORM OWNER FUNCTIONS
    */
    function setPlatformOwner(address newValue) external onlyPlatformOwner noReentrancyForPlatformOwner validAddress(newValue)
    {
        platformOwner = newValue;
    }

    function setSubscription(address value) external onlyPlatformOwner noReentrancyForPlatformOwner
    {
        subscription = value;
    }

    function setPlatformFeePercent(uint256 newValue) external onlyPlatformOwner noReentrancyForPlatformOwner
    {
        platformFeePercent = newValue;
    }

    function setPlatformFeeAddress(address newValue) external onlyPlatformOwner noReentrancyForPlatformOwner
    {
        platformFeeAddress = newValue;
    }

    function transferFund(address tokenAddress, address to, uint256 amountInWei) external onlyPlatformOwner noReentrancyForPlatformOwner validAddress(tokenAddress) validAddress(to)
    {
        //Withdraw token
        IERC20(tokenAddress).transfer(to, amountInWei);
        // bool txOk = IERC20(tokenAddress).transfer(to, amountInWei);
        // require(txOk, "TXE"); // TXE = Transaction Error
    }

    /*
        TOKEN OWNER FUNCTIONS
    */
    function setTokenActive(address tokenAddress, uint newValue) external onlyTokenOnwer(tokenAddress) noReentrancyForTokenOwner validAddress(tokenAddress) validWallet
    {
        tokenActive[tokenAddress] = newValue;
    }

    // Active subscription required
    function setTokenData(address tokenAddress, string calldata data) external onlyTokenOnwer(tokenAddress) noReentrancyForTokenOwner onlySubscribed validAddress(tokenAddress) validToken(tokenAddress) validWallet
    {
        tokenData[tokenAddress] = data;
    }

    function setTokenPrimaryDistributionPeriod(address tokenAddress, uint[2] memory newValue) external onlyTokenOnwer(tokenAddress) noReentrancyForTokenOwner validAddress(tokenAddress) validToken(tokenAddress) changePrimateDistributionTimeValidation(tokenAddress, newValue) validWallet
    {
        tokenPrimaryDistributionPeriod[tokenAddress] = newValue;
    }

    function setTokenFeePercentForLiquidity(address tokenAddress, uint256 newValue) external onlyTokenOnwer(tokenAddress) noReentrancyForTokenOwner validAddress(tokenAddress) validToken(tokenAddress) validWallet
    {
        tokenFeePercentForLiquidity[tokenAddress] = newValue;
    }

    function setTokenInitialPrice(address tokenAddress, uint256[] memory initialPrice, address[] memory initialPriceReceivingToken) external onlyTokenOnwer(tokenAddress) noReentrancyForTokenOwner validWallet
    {
        internalSetTokenInitialPrice(tokenAddress, initialPrice, initialPriceReceivingToken);
    }

    function internalSetTokenInitialPrice(address tokenAddress, uint256[] memory initialPrice, address[] memory initialPriceReceivingToken) internal validAddress(tokenAddress) validToken(tokenAddress) initialPriceValidation(initialPrice, initialPriceReceivingToken)
    {
        tokenInitialPriceReceivingToken[tokenAddress] = initialPriceReceivingToken;
        for(uint ix = 0; ix < initialPriceReceivingToken.length; ix++)
        {
            address receivingToken = initialPriceReceivingToken[ix];
            tokenInitialPrice[tokenAddress][receivingToken] = initialPrice[ix];
        }
    }

    function getBackResidualFromDistributionAmount(address tokenAddress) external onlyTokenOnwer(tokenAddress) noReentrancyForTokenOwner validWallet
    {
        uint endTime = tokenPrimaryDistributionPeriod[tokenAddress][1];

        require(
            endTime > 0 && 
            endTime < block.timestamp, 
        "PF"); // Primary Distribution Not Finished
        
        
        uint256 balance = getPrimaryDistributionReserveBalance(tokenAddress);
        if(balance > 0)
        {
            bool txOk = IERC20(tokenAddress).transfer(tokenOwner[tokenAddress], balance);
            require(txOk, "TXE"); // TXE = Transaction Error
        }
    }

    /*
        OPENED FUNCTIONS
    */
    function getTokenList() external view returns(address[] memory list)
    {
        return tokens;
    }


    function getTokenListByOwner(address ownerAddress) external view returns(address[] memory list)
    {
        return tokenListByOwner[ownerAddress];
    }

    function getReceivingTokenDetails(address tokenAddress) external view returns(ReceivingTokenDetails[] memory list)
    {
        ReceivingTokenDetails[] memory result = new ReceivingTokenDetails[](tokenInitialPriceReceivingToken[tokenAddress].length);

        for(uint ix = 0; ix < tokenInitialPriceReceivingToken[tokenAddress].length; ix++)
        {
            address receivingToken = tokenInitialPriceReceivingToken[tokenAddress][ix];
            uint256 initialPrice = tokenInitialPrice[tokenAddress][receivingToken];
            // uint256 feeValue = (initialPrice * platformFeePercent) / ONE_HUNDRED;

            result[ix] = ReceivingTokenDetails({
                receivingToken: receivingToken,
                initialPrice: initialPrice,
                liquidityBag: tokenLiquidityBag[tokenAddress][receivingToken],
                liquidityComputed: tokenLiquidityComputed[tokenAddress][receivingToken]
            });
        }
        
        return result;
    }

    function getPrimaryPurchaseHistory(address tokenAddress) external view returns (PrimaryPurchase[] memory list)
    {
        return tokenPurchase[tokenAddress];
    }

    function getPrimaryDistributionReserveBalance(address tokenAddress) public view returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf( address(this) );
    }

    function getForecastBuyFromPrimaryDistribution(address[2] memory addressesParameter, uint256 sourceAmount) public view returns (PrimaryDistributionForecast memory)
    {
        // tokenAddress = addressesParameter[0]
        // tokenSource = addressesParameter[1]

        uint256 amountToBuyUsingSource = sourceAmount - ((sourceAmount * platformFeePercent) / ONE_HUNDRED);
        uint256 amountForBuyerToReceive = SafeMath.safeDivFloat(amountToBuyUsingSource, tokenInitialPrice[ addressesParameter[0] ][ addressesParameter[1] ], IERC20( addressesParameter[1] ).decimals() );
        uint256 liquidityFeeValue = (amountToBuyUsingSource * tokenFeePercentForLiquidity[ addressesParameter[0] ]) / ONE_HUNDRED;

        PrimaryDistributionForecast memory forecast = PrimaryDistributionForecast({
            quotePrice: tokenInitialPrice[ addressesParameter[0] ][ addressesParameter[1] ],
            platformFeeValueFromSource: ((sourceAmount * platformFeePercent) / ONE_HUNDRED),
            amountToBuyUsingSource: amountToBuyUsingSource,
            amountForBuyerToReceive: amountForBuyerToReceive,
            liquidityFeePercent: tokenFeePercentForLiquidity[ addressesParameter[0] ],
            liquidityFeeValue: liquidityFeeValue,
            amountForTokenOwner: amountToBuyUsingSource - liquidityFeeValue
        });

        return forecast;
    }

    function buyFromPrimaryDistribution(address[3] memory addressesParameters, uint256 sourceAmount) external validAddress(addressesParameters[0]) validAddress(addressesParameters[1]) validToken(addressesParameters[0]) validWallet buyFromPrimaryDistributionValidation(addressesParameters[0], addressesParameters[1], sourceAmount) allowanceForTransferFrom([addressesParameters[1], msg.sender, address(this)], sourceAmount)
    {
        // tokenAddress = addressesParameters[0]
        // tokenSource = addressesParameters[1]
        // swapRouter = addressesParameters[2]

        PrimaryDistributionForecast memory forecast = getForecastBuyFromPrimaryDistribution( [addressesParameters[0], addressesParameters[1]], sourceAmount);

        require(IERC20(addressesParameters[0]).balanceOf( address(this) ) >= forecast.amountForBuyerToReceive, "NB"); // Not enough balance

        // Set Liquidity Bag
        tokenLiquidityBag[addressesParameters[0]][addressesParameters[1]] += forecast.liquidityFeeValue;

        // Purchase register
        tokenPurchase[addressesParameters[0]].push(PrimaryPurchase({
            time: block.timestamp,
            buyer: msg.sender,
            receivingToken: addressesParameters[1],
            sourceAmount: sourceAmount,
            destinationAmount: forecast.amountForBuyerToReceive
        }));

        // Transfer platform fee payment
        IERC20(addressesParameters[1]).transferFrom(msg.sender, platformFeeAddress, forecast.platformFeeValueFromSource);

        // Separate liquidity fee from amount for token owner to keep with this contract (Liquidity Bag)
        IERC20(addressesParameters[1]).transferFrom(msg.sender, address(this), forecast.liquidityFeeValue);

        // Deflation using Liquidity Bag (50% to swap 50% to liquidity) if pair exists, otherwise keep accumulated to bag
        computeLiquidity(addressesParameters);

        // Transfer buy amount (deducted fees) to token owner
        IERC20(addressesParameters[1]).transferFrom(msg.sender, tokenOwner[addressesParameters[0]], forecast.amountForTokenOwner);

        // Send bought tokens to buyer
        IERC20(addressesParameters[0]).transfer(msg.sender, forecast.amountForBuyerToReceive);

        emit PrimaryDistributionBought(addressesParameters[0], addressesParameters[1], sourceAmount, forecast.amountForBuyerToReceive);
    }

    function computeLiquidity(address[3] memory addressesParameters) private
    {
        // tokenAddress = addressesParameters[0]
        // tokenSource = addressesParameters[1]
        // swapRouter = addressesParameters[2]

        // Deflation using Liquidity Bag (50% to swap 50% to liquidity) if pair exists, otherwise keep accumulated to bag
        address pairAddressWithPlatformToken = getPairAddress(addressesParameters[2], addressesParameters[1], addressesParameters[0]);

        if(pairAddressWithPlatformToken != address(0))
        {
            // Pair exists
            uint256 platformFee = tokenLiquidityBag[addressesParameters[0]][addressesParameters[1]];
            uint256 platformFeeSwapAMount = platformFee/2;
            uint256 platformFeeLiquidityAmount = platformFee - platformFeeSwapAMount;

            // Do swap
            uint256 swapToAmount = getAmountOutMin(addressesParameters[2], addressesParameters[1], addressesParameters[0], platformFeeSwapAMount);
            internalSwap(addressesParameters[2], addressesParameters[1], addressesParameters[0], platformFeeSwapAMount, swapToAmount, address(this));

            // Calculate proportion of Token A and B do add liquidity
            uint256 balanceOfTokenAInPair = IERC20(addressesParameters[1]).balanceOf(pairAddressWithPlatformToken);
            uint256 balanceOfTokenBInPair = IERC20( addressesParameters[0]).balanceOf(pairAddressWithPlatformToken);
            uint256 addProportionInWei = SafeMath.safeDivFloat(balanceOfTokenBInPair, balanceOfTokenAInPair, MAX_DECIMALS);
            uint256 amountBToAdd = SafeMath.safeMulFloat(platformFeeLiquidityAmount, addProportionInWei, MAX_DECIMALS);  

            // Add liquidity if has token address balance
            if(amountBToAdd >= getPrimaryDistributionReserveBalance(addressesParameters[0]))
            {
                addLiquidity(addressesParameters[2], addressesParameters[1], addressesParameters[0], platformFeeLiquidityAmount, amountBToAdd);
            }

            // Add amount to computed liquidity
            tokenLiquidityComputed[addressesParameters[0]][addressesParameters[1]] += tokenLiquidityBag[addressesParameters[0]][addressesParameters[1]];

            // Set bag to zero
            tokenLiquidityBag[addressesParameters[0]][addressesParameters[1]] = 0;
        }
    }

    /*
        AMM FUNCTIONS
    */
    function getPairAddress(address swapRouter, address tokenA, address tokenB) private view returns (address)
    {
        address factory = IUniswapV2Router(swapRouter).factory();
        address pairAddress = IUniswapV2Factory(factory).getPair(tokenA, tokenB);

        return pairAddress;
    }

    function getAmountOutMin(address swapRouter, address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256) 
    {

       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
       //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        // if (tokenIn == chainWrapToken || tokenOut == chainWrapToken || multihopWithWrapToken == 0) 
        // {
        //     path = new address[](2);
        //     path[0] = tokenIn;
        //     path[1] = tokenOut;
        // } 
        // else 
        // {
        //     path = new address[](3);
        //     path[0] = tokenIn;
        //     path[1] = chainWrapToken;
        //     path[2] = tokenOut;
        // }

        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amountOutMins = IUniswapV2Router(swapRouter).getAmountsOut(amountIn, path);
        return amountOutMins[path.length -1];  
    }

    function internalSwap(address swapRouter, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, address to) private 
    {
        // if(tokenIn != chainWrapToken)
        // {
        //     require( IERC20(tokenIn).balanceOf( address(this) ) >= amountIn, "LOWSWAPBALANCE" ); //Low balance before swap

        //     // We need to allow the uniswapv2 router to spend the token we just sent to this contract
        //     // by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
        //     IERC20(tokenIn).approve(swapRouter, amountIn);
        // }

        require( IERC20(tokenIn).balanceOf( address(this) ) >= amountIn, "LWSBLC" ); //Low balance before swap

        // We need to allow the uniswapv2 router to spend the token we just sent to this contract
        // by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
        IERC20(tokenIn).approve(swapRouter, amountIn);


        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;

        // if (tokenIn == chainWrapToken || tokenOut == chainWrapToken || multihopWithWrapToken == 0) 
        // {
        //     path = new address[](2);
        //     path[0] = tokenIn;
        //     path[1] = tokenOut;
        // } 
        // else 
        // {
        //     path = new address[](3);
        //     path[0] = tokenIn;
        //     path[1] = chainWrapToken;
        //     path[2] = tokenOut;
        // }

        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        // if (tokenOut == chainWrapToken)
        // {
        //     IUniswapV2Router(swapRouter).swapExactTokensForETH(amountIn, amountOutMin, path, to, block.timestamp);
        // }
        // else
        // {
        //     IUniswapV2Router(swapRouter).swapExactTokensForTokens(amountIn, amountOutMin, path, to, block.timestamp);
        // }

        IUniswapV2Router(swapRouter).swapExactTokensForTokens(amountIn, amountOutMin, path, to, block.timestamp);
    }

    function addLiquidity(address swapRouter, address tokenA, address tokenB, uint256 amountA, uint256 amountB) private 
    {
        address counterChainWrapToken;
        uint256 counterChainWrapAmount;
        uint256 chainWrapAmount;

        // approve token transfer to cover all possible scenarios
        // if(tokenA != chainWrapToken)
        // {
        //     usingChainWrapToken = 1;
        //     counterChainWrapToken = tokenB;
        //     counterChainWrapAmount = amountB;
        //     chainWrapAmount = amountA;
        //     IERC20(tokenA).approve(swapRouter, amountA);
        // }

        // if(tokenB != chainWrapToken)
        // {
        //     usingChainWrapToken = 1;
        //     counterChainWrapToken = tokenA;
        //     counterChainWrapAmount = amountA;
        //     chainWrapAmount = amountB;
        //     IERC20(tokenB).approve(swapRouter, amountB);
        // }

        counterChainWrapToken = tokenB;
        counterChainWrapAmount = amountB;
        chainWrapAmount = amountA;
        IERC20(tokenA).approve(swapRouter, amountA);

        counterChainWrapToken = tokenA;
        counterChainWrapAmount = amountA;
        chainWrapAmount = amountB;
        IERC20(tokenB).approve(swapRouter, amountB);

        // add the liquidity and burn
        // if(usingChainWrapToken == 1)
        // {
        //     IUniswapV2Router(swapRouter).addLiquidityETH{value: chainWrapAmount}(
        //         counterChainWrapToken,
        //         counterChainWrapAmount,
        //         0, // slippage is unavoidable
        //         0, // slippage is unavoidable
        //         BURN_ADDRESS,
        //         block.timestamp
        //     );            
        // }
        // else
        // {
        //     IUniswapV2Router(swapRouter).addLiquidity(
        //         tokenA,
        //         tokenB,
        //         amountA,
        //         amountB,
        //         0, // slippage is unavoidable
        //         0, // slippage is unavoidable
        //         BURN_ADDRESS,
        //         block.timestamp
        //     );  
        // }

        IUniswapV2Router(swapRouter).addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            BURN_ADDRESS,
            block.timestamp
        ); 
    }
}

contract ERCToken
{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balances;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowed;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* This notifies clients about the amount approval */
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(uint256 initialSupply, uint256 primaryDistributionAmount, string memory tokenName, uint8 decimalUnits, string memory tokenSymbol, address contractOwner, address primaryDistributor)
    {
        require(initialSupply >= primaryDistributionAmount, 'ERR: Invalid supply');
        balances[contractOwner] = initialSupply - primaryDistributionAmount;           // Give the owner all initial tokens except primary distribution amount
        balances[primaryDistributor] = primaryDistributionAmount;
        totalSupply = initialSupply;    // Update total supply
        name = tokenName;               // Set the name for display purposes
        symbol = tokenSymbol;           // Set the symbol for display purposes
        decimals = decimalUnits;        // Amount of decimals for display purposes
		owner = contractOwner;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        require(_to != address(0), 'ERR: Unable to transfer to 0x0 address. Use burn() instead'); // Prevent transfer to 0x0 address. Use burn() instead
		require(_value > 0, 'ERR: Invalid transfer value'); 
        require(balances[msg.sender] >= _value, 'ERR: Not enough balance');            // Check if the sender has enough
        require(balances[_to] + _value >= balances[_to], 'ERR: Overflow check');      // Check for overflows

        balances[msg.sender] = safeSub(balances[msg.sender], _value);        // Subtract from the sender
        balances[_to] = balances[_to] + _value;    // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);    // Notify anyone listening that this transfer took place

        return true;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) external returns (bool success)
    {
		require(_value > 0, 'ERR: Invalid amount'); 

        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address delegate) external view returns (uint256) 
    {
        return allowed[_owner][delegate];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));

        allowed[msg.sender][spender] = allowed[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));

        allowed[msg.sender][spender] = safeSub(allowed[msg.sender][spender], subtractedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function balanceOf(address tokenOwner) external view returns (uint256) 
    {
        return balances[tokenOwner];
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success)
    {
        require(_to != address(0), 'ERR: Unable to transfer to 0x0 address. Use burn() instead');      // Prevent transfer to 0x0 address. Use burn() instead
		require(_value > 0, 'ERR: Invalid transfer value');                                     
        require(balances[_from] >= _value, 'ERR: Not enough balance');                         // Check if the sender has enough
        require(balances[_to] + _value >= balances[_to], 'ERR: Overflow check');              // Check for overflows
        require(_value <= allowed[_from][msg.sender], 'ERR: Insufficient allowance');         // Check allowance

        balances[_from] = safeSub(balances[_from], _value);                          // Subtract from the sender
        balances[_to] = balances[_to] + _value;                              // Add the same to the recipient
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) external returns (bool success) 
    {
        require(balances[msg.sender] >= _value, 'ERR: Not enough balance');        // Check if the sender has enough
		require(_value > 0, 'ERR: Invalid burn value'); 

        balances[msg.sender] = safeSub(balances[msg.sender], _value);    // Subtract from the sender
        totalSupply = safeSub(totalSupply,_value);                         // Updates totalSupply

        emit Burn(msg.sender, _value);
        return true;
    }

    function mint(address account, uint256 _value) external returns (bool success)
    {
        require(msg.sender == owner, 'ERR: Forbidden');
        
        require(account != address(0), "ERR: Cannot mint to the zero address");
        require(_value > 0, 'ERR: Invalid mint value');

        totalSupply = totalSupply + _value;
        balances[account] = balances[account] + _value;

        emit Transfer(address(0), account, _value);
        return true;
    }
	
	function freeze(uint256 _value) external returns (bool success) 
    {
        require(balances[msg.sender] >= _value, 'ERR: Not enough balance');        // Check if the sender has enough
        require(_value > 0, 'ERR: Invalid freeze value'); 
        balances[msg.sender] = safeSub(balances[msg.sender], _value);    // Subtract from the sender
        freezeOf[msg.sender] = freezeOf[msg.sender] + _value;      // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) external returns (bool success) 
    {
        require(freezeOf[msg.sender] >= _value, 'ERR: Not enough frozen balance');  // Check if the sender has enough
		require(_value > 0, 'ERR: Invalid unfreeze value'); 
        freezeOf[msg.sender] = safeSub(freezeOf[msg.sender], _value);      // Subtract from the sender
		balances[msg.sender] = balances[msg.sender] + _value;
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    function setOwner(address newValue) public returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        owner = newValue;
        return true;
    }

    // safeSub: Safe Math Functions
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        require(b <= a, "ERR: subtraction overflow");
        uint256 c = a - b;

        return c;
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

interface ISubscription
{
    function getActivationRemainingTime(
        uint serviceId, 
        address userAddress
    ) external view returns (uint256);
    
    function getActivationTimeLimit(
        uint serviceId, 
        address userAddress
    ) external view returns (uint256);
}

// ****************************************************
// ***************** HELPER FUNCTIONS *****************
// ****************************************************
library Hlp 
{
    function isContract(address account) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

library SafeMath {
    function safeMulFloat(uint256 a, uint256 b, uint decimals) internal pure returns(uint256)
    {
        if (a == 0 || decimals == 0)  
        {
            return 0;
        }

        uint result = a * b / safePow(10, uint256(decimals));

        return result;
    }

    function safeDivFloat(uint256 a, uint256 b, uint256 decimals) internal pure returns (uint256)
    {
        require(b > 0, "ZDIV");
        uint256 c = (a * safePow(10,decimals)) / b;

        return c;
    }

    function safePow(uint256 n, uint256 e) internal pure returns(uint256)
    {
        if (e == 0) 
        {
            return 1;
        } 
        else if (e == 1) 
        {
            return n;
        } 
        else 
        {
            uint256 p = safePow(n,  e / 2);
            p = p * p;

            if ( (e % 2) == 1) 
            {
                p = p * n;
            }

            return p;
        }
    }
}