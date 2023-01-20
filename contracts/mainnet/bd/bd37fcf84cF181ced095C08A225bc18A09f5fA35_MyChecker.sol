// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
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

// Polygon WMATIC/WETH pool checker for uniswap v3 automation
// checker contract: should just check the condintion
// CHECKER 1. check whether current tick is in range (compare current tick with position's tickLower, tickUpper)
// CHECKER 2. check whether user's USD calculated value of token0 and token 1 is almost same (within 1%)
// CHECKER 3. check whether total value in user's account is over than 100 USD

// TODO before gelato automation -> ERC20 approve to gelato account, uniswap [swap, mint], setApprovalForAll to gelato account

// the interfaces to import
// import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IUniswapV3Resolver} from "../checker/IUniswapV3Resolver.sol";
import {IERC20} from "../checker/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {INonfungiblePositionManager} from "../checker/INonfungiblePositionManager.sol";
import {AggregatorV3Interface} from "../checker/AggregatorV3Interface.sol";
import {PoolConfig, PoolData, PositionInfo, MintParams, CollectParams, DecreaseLiquidityParams} from "../checker/MyStructs.sol";
import {IExecutor} from "../executor/IExecutor.sol";

// Address that should whitelist : 0xE67a53A07E51cE69C7AB01c26923172D4EEda5D8 (내꺼 젤라토임)
// uint 256 max = 115792089237316195423570985008687907853269984665640564039457584007913129639935

// checker contract
contract MyChecker {
    IUniswapV3Resolver public uniswapV3Resolver;
    INonfungiblePositionManager public nonfungiblePositionManager;
    IERC20 public token0;
    IERC20 public token1;
    AggregatorV3Interface public priceFeed0;
    AggregatorV3Interface public priceFeed1;

    // examples (WMATIC/WETH pool) // token0 = WMATIC, token1 = WETH
    // 0x8dA60dee0815a08d16C066b07814b10722fA9306 // polygon Instadapp UniswapV3Resolver address
    // 0xC36442b4a4522E871399CD717aBDD847Ab11FE88 // polygon UniswapV3 NFT Manager address

    // 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270 // polygon WMATIC address
    // 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619 // polygon WETH address

    // 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0 // polygon WMATIC / USD chainlink oracle address
    // 0xF9680D99D6C9589e2a93a78A04A279e509205945 // polygon WETH / USD chainlink oracle address

    address public executorAddress;
    string public name; // just for preventing confusion

    // -------------------- Preventing Accident... ------------------- //
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function withdrawToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function withdrawNFT(address _nft, uint256 _tokenId) external onlyOwner {
        IERC721 nft = IERC721(_nft);
        nft.transferFrom(address(this), owner, _tokenId);
    }

    function setExecutorAddress(address _executorAddress) external onlyOwner {
        executorAddress = _executorAddress;
    }

    // ------------------------------------------------------------- //

    constructor(
        address _executorAddress,
        address _uniswapV3Resolver,
        address _nonfungiblePositionManager,
        address _token0,
        address _token1,
        address _priceFeed0,
        address _priceFeed1,
        string memory _name
    ) {
        // constructor
        executorAddress = _executorAddress; // my address

        uniswapV3Resolver = IUniswapV3Resolver(_uniswapV3Resolver);
        nonfungiblePositionManager = INonfungiblePositionManager(
            _nonfungiblePositionManager
        );

        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        priceFeed0 = AggregatorV3Interface(_priceFeed0);
        priceFeed1 = AggregatorV3Interface(_priceFeed1);

        name = _name;
        owner = msg.sender;
    }

    function getTokenBalance(address _token) public view returns (uint256) {
        IERC20 token = IERC20(_token);
        uint256 tokenBalance = token.balanceOf(executorAddress);
        uint8 tokenDecimals = token.decimals();

        if (tokenDecimals != 18) {
            tokenBalance = tokenBalance * (10**uint256(18 - tokenDecimals));
        }

        return tokenBalance;
    }

    function gettoken0USDValue() public view returns (uint256 token0USDValue) {
        uint256 token0Balance = getTokenBalance(address(token0));
        // get the latest price
        (, int256 price0, , , ) = priceFeed0.latestRoundData();

        // calculate the USD value of token0
        return (token0Balance * uint256(price0));
    }

    function gettoken1USDValue() public view returns (uint256 token1USDValue) {
        uint256 token1Balance = getTokenBalance(address(token1));
        // get the latest price
        (, int256 price1, , , ) = priceFeed1.latestRoundData();

        // calculate the USD value of token1
        return (token1Balance * uint256(price1));
    }

    function getTotalUSDValue() public view returns (uint256 totalUSDValue) {
        uint256 token0USDValue = gettoken0USDValue();
        uint256 token1USDValue = gettoken1USDValue();

        return token0USDValue + token1USDValue;
    }

    function getLatestTokenId() public view returns (uint256 tokenId) {
        uint256[] memory tokenIds = uniswapV3Resolver.getUserNFTs(
            executorAddress
        );
        return tokenIds[tokenIds.length - 1];
    }

    function getMyLiquidity() public view returns (uint128 liquidity) {
        uint256 tokenId = getLatestTokenId();
        PositionInfo memory positionInfo = uniswapV3Resolver
            .getPositionInfoByTokenId(tokenId);
        return positionInfo.liquidity;
    }

    function getPoolFee() public view returns (uint24 poolFee) {
        uint256 tokenId = getLatestTokenId();
        PositionInfo memory positionInfo = uniswapV3Resolver
            .getPositionInfoByTokenId(tokenId);
        return positionInfo.fee;
    }

    // execPayload examples
    // 	execPayload = abi.encodeWithSelector(
    // 	IHarvester.harvestVault.selector,
    // 	address(vault)
    // );

    function isValueDiff() public view returns (bool) {
        uint256 token0USDValue = gettoken0USDValue();
        uint256 token1USDValue = gettoken1USDValue();

        // check whether the value of token0 and token1 is almost same (within 5%)
        if (
            token0USDValue >= (token1USDValue * 95) / 100 &&
            token0USDValue <= (token1USDValue * 105) / 100
        ) {
            // if the value of token0 and token1 is almost same, return false
            return (false);
        } else {
            // if the value of token0 and token1 is not almost same, return true
            return (true);
        }
    }

    function havingMoreThan10USD() public view returns (bool) {
        uint256 totalUSDValue = getTotalUSDValue();

        if (totalUSDValue >= 10 * (10**26)) {
            // if the total USD value is more than 10, return true
            return (true);
        } else {
            // if the total USD value is less than 10, return false
            return (false);
        }
    }

    function isInRange() public view returns (bool) {
        uint256 tokenId = getLatestTokenId();
        // TODO: I might need to loop through all the token Ids.
        // In this case, collect function should be executed only when liquidity is over certain amount

        PositionInfo memory positionInfo = uniswapV3Resolver
            .getPositionInfoByTokenId(tokenId);

        if (
            positionInfo.currentTick >= positionInfo.tickLower &&
            positionInfo.currentTick <= positionInfo.tickUpper
            // && positionInfo.liquidity >= 100000
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isPositionEmpty() public view returns (bool) {
        uint256 tokenId = getLatestTokenId();
        // TODO: I might need to loop through all the token Ids.
        // In this case, collect function should be executed only when liquidity is over certain amount

        PositionInfo memory positionInfo = uniswapV3Resolver
            .getPositionInfoByTokenId(tokenId);

        if (positionInfo.liquidity < 100) {
            return true;
        } else {
            return false;
        }
    }

    function checkShouldSwap()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        bool moreThan10USD = havingMoreThan10USD();
        bool valDiff = isValueDiff();
        bool isEmpty = isPositionEmpty();

        if (moreThan10USD && valDiff && isEmpty) {
            // swap through 1inch or other dex aggregator with less slippage [or prevent MEV bot]
            // prepare swap Parameter, then encode params with selector
            uint256 token0USDValue = gettoken0USDValue();
            uint256 token1USDValue = gettoken1USDValue();

            bool shouldSwapToken0 = token0USDValue > token1USDValue
                ? true
                : false;

            address tokenIn = shouldSwapToken0
                ? address(token0)
                : address(token1);

            address tokenOut = shouldSwapToken0
                ? address(token1)
                : address(token0);

            uint24 poolFee = getPoolFee();

            uint256 amountOfUsdValueToSwap = token0USDValue > token1USDValue
                ? (token0USDValue - token1USDValue) / 2
                : (token1USDValue - token0USDValue) / 2;

            uint256 tokenInBalance = getTokenBalance(tokenIn);

            uint256 amountIn = (amountOfUsdValueToSwap / (10**8)) /
                tokenInBalance;
            if (IERC20(tokenIn).decimals() != 18) {
                amountIn = amountIn / (10**(18 - IERC20(tokenIn).decimals()));
            }

            uint256 amountOutMinimum;
            if (shouldSwapToken0) {
                (, int256 price0, , , ) = priceFeed0.latestRoundData();
                amountOutMinimum =
                    ((amountOfUsdValueToSwap / uint256(price0)) * 9992) /
                    10000;
            } else {
                (, int256 price1, , , ) = priceFeed1.latestRoundData();
                amountOutMinimum =
                    ((amountOfUsdValueToSwap / uint256(price1)) * 9992) /
                    10000;
            }

            execPayload = abi.encodeWithSelector(
                IExecutor.swapExactInputSingleHop.selector,
                tokenIn,
                tokenOut,
                poolFee,
                amountIn,
                amountOutMinimum,
                uint160(0)
            );

            return (true, execPayload);
        } else {
            return (false, "shouldn't execute swap");
        }
    }

    function checkShouldMint()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        bool moreThan10USD = havingMoreThan10USD();
        bool valDiff = isValueDiff();
        bool isEmpty = isPositionEmpty();

        if (moreThan10USD && !valDiff && isEmpty) {
            // 1. calculate upperTick and lowerTick based on current balance
            // 2. getSingleMintAmount -> calculate tokenb , minAmount (resolver.sol)
            // 3. mint new position through nonfungible position manager

            return (true, "should mint position");
        } else {
            return (false, "shouldn't mint position");
        }
    }

    function checkShouldCollect()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        // get the tokenId of the position from the executorAddress that is the most recent one
        uint256 tokenId = getLatestTokenId();
        uint128 liquidity = getMyLiquidity();
        bool inRange = isInRange();
        bool isEmpty = isPositionEmpty();

        // check whether current tick is in range (compare current tick with position's tickLower, tickUpper)

        if (isEmpty) {
            // if the position is empty, return false
            return (false, "position is empty");
        }

        if (inRange) {
            // if the current tick is in range, return false
            return (false, "position is in range");
        } else {
            // if the current tick is not in range, return true
            // multicall function should be executed
            // 1. decreaseLiquidity
            // 2. collect

            DecreaseLiquidityParams
                memory decreaseLiquidityParams = DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: liquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp + 100
                });

            bytes memory exec1 = abi.encodeWithSelector(
                INonfungiblePositionManager.decreaseLiquidity.selector,
                decreaseLiquidityParams
            );

            CollectParams memory collectParams = CollectParams({
                tokenId: tokenId,
                recipient: executorAddress,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

            bytes memory exec2 = abi.encodeWithSelector(
                INonfungiblePositionManager.collect.selector,
                collectParams
            );

            bytes[] memory execs = new bytes[](2);
            execs[0] = exec1;
            execs[1] = exec2;

            return (
                true,
                abi.encodeWithSelector(
                    IExecutor.multiCallNFTManager.selector, // or directly call multicall from nftmanager
                    execs
                )
            );
        }
    }
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

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {CollectParams, DecreaseLiquidityParams, MintParams} from "./MyStructs.sol";

interface INonfungiblePositionManager {
    // function increaseLiquidity(IncreaseLiquidityParams calldata params)
    //     external
    //     payable
    //     returns (uint128 liquidity);

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function approve(address to, uint256 tokenId) external;

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function setApprovalForAll(address operator, bool _approved) external;

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {PoolConfig, PoolData, PositionInfo, MintParams} from "./MyStructs.sol";

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
    uint128 tokenOwed0; //
    uint128 tokenOwed1; //
    uint256 amount0;
    uint256 amount1;
    uint256 collectAmount0;
    uint256 collectAmount1;
}

struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
}

struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity; // maxLiquidity
    uint256 amount0Min; // 0
    uint256 amount1Min; // 0
    uint256 deadline; // current Timestamp (block.timestamp)
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IExecutor {
    function multiCallNFTManager(bytes[] calldata _data) external;

    function swapExactInputSingleHop(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint256 amountIn,
        uint256 amountOutMinimum, // should be calculated thoroughly by checker
        uint160 sqrtPriceLimitX96 // just give 0
    ) external returns (uint256 amountOut);

    function mintNewPosition(
        uint256 amount0ToAdd,
        uint256 amount1ToAdd,
        uint24 _fee,
        int24 _tickLower,
        int24 _tickUpper
    )
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );
}