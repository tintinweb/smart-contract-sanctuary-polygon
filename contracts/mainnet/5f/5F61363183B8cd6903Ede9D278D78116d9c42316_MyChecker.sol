// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

struct PoolConfig {
    address tokenA;
    address tokenB;
    uint24 fee;
}

struct PoolData {
    address token0;
    address token1;
    uint24 fee;
    address pool;
    bool isCreated;
    int24 currentTick;
    uint160 sqrtRatio;
}

struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
}

struct PositionInfo {
    address token0;
    address token1;
    address pool;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    int24 currentTick;
    uint128 liquidity;
    uint128 tokenOwed0;
    uint128 tokenOwed1;
    uint256 amount0;
    uint256 amount1;
    uint256 collectAmount0;
    uint256 collectAmount1;
}

interface IUniswapV3Resolver {
    function getPoolDetails(PoolConfig[] memory poolConfigs)
        external
        view
        returns (PoolData[] memory poolDatas);

    function getPositionInfoByTokenId(uint256 tokenId)
        external
        view
        returns (PositionInfo memory pInfo);

    function getPositionsInfo(address user, uint256[] memory stakedTokenIds)
        external
        view
        returns (
            uint256[] memory tokenIds,
            PositionInfo[] memory positionsInfo
        );

    function getMintAmount(MintParams memory mintParams)
        external
        view
        returns (
            address token0,
            address token1,
            uint256 liquidity,
            uint256 amount0,
            uint256 amount1,
            uint256 amount0Min,
            uint256 amount1Min
        );

    function getDepositAmount(
        uint256 tokenId,
        uint256 amountA,
        uint256 amountB,
        uint256 slippage
    )
        external
        view
        returns (
            uint256 liquidity,
            uint256 amount0,
            uint256 amount1,
            uint256 amount0Min,
            uint256 amount1Min
        );

    function getSingleDepositAmount(
        uint256 tokenId,
        address tokenA,
        uint256 amountA,
        uint256 slippage
    )
        external
        view
        returns (
            uint256 liquidity,
            address tokenB,
            uint256 amountB,
            uint256 amountAMin,
            uint256 amountBMin
        );

    function getSingleMintAmount(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 slippage,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    )
        external
        view
        returns (
            uint256 liquidity,
            uint256 amountB,
            uint256 amountAMin,
            uint256 amountBMin
        );

    function getWithdrawAmount(
        uint256 tokenId,
        uint256 liquidity,
        uint256 slippage
    )
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 amount0Min,
            uint256 amount1Min
        );

    function getCollectAmount(uint256 tokenId)
        external
        view
        returns (uint256 amountA, uint256 amountB);

    function getUserNFTs(address user)
        external
        view
        returns (uint256[] memory tokenIds);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// Polygon WMATIC/WETH pool checker for uniswap v3 automation
// checker contract: should just check the condintion
// TODO 1. check whether current tick is in range (compare current tick with position's tickLower, tickUpper)
// TODO 2. check whether user's USD calculated value of token0 and token 1 is almost same (within 1%)
// TODO 3. check whether total value in user's account is over than 100 USD

// the interfaces to import
// import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
// import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IUniswapV3Resolver, PoolConfig, PositionInfo, PoolData, MintParams} from "./IUniswapV3Resolver.sol";
import {IERC20} from "./IERC20.sol";

// fetching token price from chainlink oracle (if necessary)
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";

// checker contract
contract MyChecker {
    // INonfungiblePositionManager public immutable nonfungiblePositionManager =
    //     INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88); polygon UniswapV3 NFT Manager address

    IUniswapV3Resolver public immutable uniswapV3Resolver =
        IUniswapV3Resolver(0x8dA60dee0815a08d16C066b07814b10722fA9306); // polygon Instadapp UniswapV3Resolver address

    IERC20 public immutable token1 =
        IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619); // polygon WETH address

    IERC20 public immutable token2 =
        IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); // polygon WMATIC address

    AggregatorV3Interface public immutable priceFeed1 =
        AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945); // polygon WETH / USD chainlink oracle address

    AggregatorV3Interface public immutable priceFeed2 =
        AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0); // polygon WMATIC / USD chainlink oracle address

    // ETH / USD 0xF9680D99D6C9589e2a93a78A04A279e509205945
    // MATIC / USD 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
    // MATIC / ETH 0x327e23A4855b6F663a28c5161541d69Af8973302

    function checkIsNotInRange()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        // get the tokenId of the position from the msg.sender that is the most recent one
        uint256[] memory tokenIds = uniswapV3Resolver.getUserNFTs(msg.sender);
        uint256 tokenId = tokenIds[tokenIds.length - 1];

        PositionInfo memory positionInfo = uniswapV3Resolver
            .getPositionInfoByTokenId(tokenId);

        // check whether current tick is in range (compare current tick with position's tickLower, tickUpper)
        if (
            positionInfo.currentTick >= positionInfo.tickLower &&
            positionInfo.currentTick <= positionInfo.tickUpper
        ) {
            // if the current tick is in range, return false
            return (false, "position is in range");
        } else {
            // if the current tick is not in range, return true
            return (true, "position is not in range");
        }
    }

    function checkIsTheValueNotSame()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 token1Balance = token1.balanceOf(msg.sender);
        uint256 token2Balance = token2.balanceOf(msg.sender);
        uint8 token1Decimals = token1.decimals();
        uint8 token2Decimals = token2.decimals();

        // get the latest price
        (, int256 price1, , , ) = priceFeed1.latestRoundData();
        (, int256 price2, , , ) = priceFeed2.latestRoundData();

        // calculate the USD value of token1 and token2

        uint256 token1USDValue = (token1Balance * uint256(price1)) /
            (10**(8 + token1Decimals));
        uint256 token2USDValue = (token2Balance * uint256(price2)) /
            (10**(8 + token2Decimals));

        uint256 totalUSDValue = token1USDValue + token2USDValue;

        if (totalUSDValue <= 10) {
            // if the total USD value is more than 100, return true
            return (false, "the total USD value should be more than 10 USD");
        }

        // check whether the value of token1 and token2 is almost same (within 1%)
        if (
            token1USDValue >= (token2USDValue * 99) / 100 &&
            token1USDValue <= (token2USDValue * 101) / 100
        ) {
            // if the value of token1 and token2 is almost same, return false
            return (false, "the value of token1 and token2 is almost same");
        } else {
            // if the value of token1 and token2 is not almost same, return true
            return (true, "the value of token1 and token2 is not almost same");
        }
    }

    function checkHavingMoreThan100USD()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 token1Balance = token1.balanceOf(msg.sender);
        uint256 token2Balance = token2.balanceOf(msg.sender);
        uint8 token1Decimals = token1.decimals();
        uint8 token2Decimals = token2.decimals();

        // get the latest price
        (, int256 price1, , , ) = priceFeed1.latestRoundData();
        (, int256 price2, , , ) = priceFeed2.latestRoundData();

        // calculate the USD value of token1 and token2

        uint256 token1USDValue = (token1Balance * uint256(price1)) /
            (10**(8 + token1Decimals));
        uint256 token2USDValue = (token2Balance * uint256(price2)) /
            (10**(8 + token2Decimals));

        uint256 totalUSDValue = token1USDValue + token2USDValue;

        if (totalUSDValue >= 10) {
            // if the total USD value is more than 100, return true
            return (true, "the total USD value is more than 10");
        } else {
            // if the total USD value is less than 100, return false
            return (false, "the total USD value is less than 10");
        }
    }
}