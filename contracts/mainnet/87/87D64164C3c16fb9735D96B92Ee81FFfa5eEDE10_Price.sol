/**
 *Submitted for verification at polygonscan.com on 2022-05-07
*/

/**
 * This smart-contract has been built by Mobula to be called on client-side applications and isn't optimized at all. 
 * We highly recommend to wait for the optimized version before integrating this in a smart-contract.
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

contract Price {
    address owner = 0x0490d25a95befDDe088C8A3D741B5Afba29cB8D9;
    address public WMATIC = 0x0000000000000000000000000000000000001010;
    address public USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public BUSDT = 0x692597b009d13C4049a947CAB2239b7d6517875F;

    address[] public commonTokens;
    mapping(address => uint256) public indexOfCommonTokens;

    address[] public commonDEXes;
    mapping(address => uint256) public indexOfCommonDEXes;


    function addCommonToken(address tokenAddress) public {
        require(
            owner == msg.sender,
            "Only the DAO can add a token."
        );
        indexOfCommonTokens[tokenAddress] = commonTokens.length;
        commonTokens.push(tokenAddress);
    } 

    function removeCommonTokens(address tokenAddress) public {
        require(
            owner == msg.sender,
            "Only the DAO can add a DEX."
        );
        commonTokens[indexOfCommonTokens[tokenAddress]] = commonTokens[commonTokens.length - 1];
        indexOfCommonTokens[commonTokens[commonTokens.length - 1]] = indexOfCommonTokens[tokenAddress];
        commonTokens.pop();
    } 

    function addCommonDEXes(address dexAddress) public {
        require(
            owner == msg.sender,
            "Only the DAO can add a DEX."
        );
        indexOfCommonDEXes[dexAddress] = commonDEXes.length;
        commonDEXes.push(dexAddress);
    } 

    function removeCommonDEXes(address dexAddress) public {
        require(
            owner == msg.sender,
            "Only the DAO can add a DEX."
        );
        commonDEXes[indexOfCommonDEXes[dexAddress]] = commonDEXes[commonDEXes.length - 1];
        indexOfCommonDEXes[commonDEXes[commonDEXes.length - 1]] = indexOfCommonDEXes[dexAddress];
        commonDEXes.pop();
    } 
    
    constructor() {
        addCommonToken(WMATIC);
        addCommonToken(USDT);
        addCommonToken(USDC);
        addCommonToken(BUSDT);
        addCommonDEXes(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
    }

    function getUSDPriceFromSpecificDEX(
        address tokenAddress,
        address factoryAddress
    )
        public
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 averagePrice;
        uint256 totalLiquidity;

        IUniswapV2Factory factory = IUniswapV2Factory(factoryAddress);

        for (uint8 i = 0; i < commonTokens.length; i++) {
            address pairAddress = factory.getPair(
                tokenAddress,
                commonTokens[i]
            );

            if (pairAddress != address(0)) {
                IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                uint256 pairPrice;
                uint256 pairLiquidity;

                if (tokenAddress == pair.token0() && reserve0 != 0) {
                   //If the token is WMATIC
                   if (i == 0) {
                       uint256 MATICUSDPrice = getBasicPrice(WMATIC);
                       pairPrice = MATICUSDPrice * reserve1 / reserve0;
                       pairLiquidity = MATICUSDPrice * reserve1 / 10**18;
                       totalLiquidity += pairLiquidity;
                   } else {
                       uint256 vsTokenDecimals = IERC20(commonTokens[i]).decimals();

                       if (vsTokenDecimals == 18) {
                            pairPrice = reserve1 * 10**18  / reserve0;
                            pairLiquidity = reserve1;
                            totalLiquidity += pairLiquidity;
                       } else {
                            pairPrice = reserve1 * 10**(18-vsTokenDecimals) * 10**18  / reserve0;
                            pairLiquidity = reserve1 * 10**(18-vsTokenDecimals);
                            totalLiquidity += pairLiquidity;
                       }

                   }
               } else if (reserve1 != 0) {
                   //If the token is WMATIC
                   if (i == 0) {
                       uint256 MATICUSDPrice = getBasicPrice(WMATIC);
                       pairPrice = MATICUSDPrice * reserve0 / reserve1;
                       pairLiquidity = MATICUSDPrice * reserve0 / 10**18;
                       totalLiquidity += pairLiquidity;
                   } else {
                       uint256 vsTokenDecimals = IERC20(commonTokens[i]).decimals();

                       if (vsTokenDecimals == 18) {
                            pairPrice = reserve0 * 10**18  / reserve1;
                            pairLiquidity = reserve0;
                            totalLiquidity += pairLiquidity;
                       } else {
                            pairPrice = reserve0 * 10**(18-vsTokenDecimals) * 10**18  / reserve1;
                            pairLiquidity = reserve0 * 10**(18-vsTokenDecimals);
                            totalLiquidity += pairLiquidity;
                       }
                       
                   }
               }

               averagePrice += pairPrice * pairLiquidity;

            }
        }

        if (totalLiquidity != 0) {
            return (averagePrice / totalLiquidity, totalLiquidity);
        } else {
            return (0, 0);
        }
        
    }

    function getGeneralUSDPrice(address tokenAddress) public view returns(uint256, uint256) {
        uint256 averagePrice;
        uint256 totalLiquidity;

        for (uint256 i = 0; i < commonDEXes.length; i++) {
            (uint256 dexPrice, uint256 dexLiquidity) = getUSDPriceFromSpecificDEX(tokenAddress, commonDEXes[i]);
            averagePrice += dexPrice * dexLiquidity;
            totalLiquidity += dexLiquidity;
        }

        if (totalLiquidity != 0) {
            return (averagePrice / totalLiquidity, totalLiquidity);
        } else {
            return (0, 0);
        }

    }

    function getBasicPrice(address tokenAddress) internal view returns (uint256 price) {
        IUniswapV2Factory factory = IUniswapV2Factory(commonDEXes[0]);
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(tokenAddress,commonTokens[1]));
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        if (tokenAddress == pair.token0()) {
            return reserve1 * 10**18 / reserve0;
        } else {
            return reserve0 * 10**18 / reserve1;
        }
    }

    function getUSDPriceFromSpecificDEXUsingStable(
        address tokenAddress,
        address factoryAddress
    )
        public
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 averagePrice;
        uint256 totalLiquidity;

        IUniswapV2Factory factory = IUniswapV2Factory(factoryAddress);

        for (uint8 i = 1; i < commonTokens.length; i++) {
            address pairAddress = factory.getPair(
                tokenAddress,
                commonTokens[i]
            );

            if (pairAddress != address(0)) {
                IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                uint256 pairPrice;
                uint256 pairLiquidity;

                if (tokenAddress == pair.token0() && reserve0 != 0) {
                       uint256 vsTokenDecimals = IERC20(commonTokens[i]).decimals();

                       if (vsTokenDecimals == 18) {
                            pairPrice = reserve1 * 10**18  / reserve0;
                            pairLiquidity = reserve1;
                            totalLiquidity += pairLiquidity;
                       } else {
                            pairPrice = reserve1 * 10**(18-vsTokenDecimals) * 10**18  / reserve0;
                            pairLiquidity = reserve1 * 10**(18-vsTokenDecimals);
                            totalLiquidity += pairLiquidity;
                       }
                   
               } else if (reserve1 != 0) {
                       uint256 vsTokenDecimals = IERC20(commonTokens[i]).decimals();

                       if (vsTokenDecimals == 18) {
                            pairPrice = reserve0 * 10**18  / reserve1;
                            pairLiquidity = reserve0;
                            totalLiquidity += pairLiquidity;
                       } else {
                            pairPrice = reserve0 * 10**(18-vsTokenDecimals) * 10**18  / reserve1;
                            pairLiquidity = reserve0 * 10**(18-vsTokenDecimals);
                            totalLiquidity += pairLiquidity;
                       }
                       
               }

               averagePrice += pairPrice * pairLiquidity;

            }
        }

        if (totalLiquidity != 0) {
            return (averagePrice / totalLiquidity, totalLiquidity);
        } else {
            return (0, 0);
        }
        
    }

    function getGeneralUSDPriceUsingStable(address tokenAddress) public view returns(uint256, uint256) {
        uint256 averagePrice;
        uint256 totalLiquidity;

        for (uint256 i = 0; i < commonDEXes.length; i++) {
            (uint256 dexPrice, uint256 dexLiquidity) = getUSDPriceFromSpecificDEXUsingStable(tokenAddress, commonDEXes[i]);
            averagePrice += dexPrice * dexLiquidity;
            totalLiquidity += dexLiquidity;
        }

        if (totalLiquidity != 0) {
            return (averagePrice / totalLiquidity, totalLiquidity);
        } else {
            return (0, 0);
        }
    }
}