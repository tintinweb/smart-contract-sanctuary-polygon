// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IUniswapFactory.sol";
import "../interfaces/IUniswapRouter02.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../libraries/UniswapV2Library.sol";

library BTCLCore {
    error PAIR_NOT_SET();
    error UPKEEP_FAILED();
    error LOTTERY_PAUSED();
    error TRANSFER_FAILED();
    error ONE_CENT_IN_TOKEN();
    error ROUND_NOT_FINISHED();
    error INCORRECT_TIMESTAMP();
    error INVALID_VRF_REQUEST();
    error UNAUTHORIZED_WINNER();
    error UNAUTHORIZED_TREASURY();
    error PRIZE_ALREADY_CLAIMED();

    enum Status {
        Open,
        Drawing,
        Completed
    }

    struct RoundStatus {
        Status roundStatus;    // Round active lottery status
        uint requestId;        // Round Chainlink VRF Request ID
        uint totalTickets;     // Round Tickets Purchased
        uint totalBets;        // Round Bet ID Number
        uint[] randomness;     // Round Random Numbers
    }

    struct Round {
        RoundStatus status; // Round Info
        mapping(address => bool) winnerClaimed; // Round winner prizes claimed
        mapping(address => bool) claimedTreasury; // Round treasury fees claimed
        mapping(address => uint) contributed; // MATIC Contributed
        // mapping(uint => address) luckyWinners; // Winner Address with Lucky Reward
        // mapping(uint => uint) luckyTickets; // Verifiably Fair Ticket Number
        // mapping(uint => uint) luckyPrizes; // Verifiably Fair Dynamic Prizes
        mapping(uint => uint) betID; // Compacted address and tickets purchased for every betID
    }

    // Bitmasks
    uint public constant BITMASK_PURCHASER = (1 << 160) - 1;
    uint public constant BITMASK_LAST_INDEX = ((1 << 96) - 1) << 160;

    // Bit positions
    uint public constant BITPOS_LAST_INDEX = 160;

    // uint256 - 160 caractere sunt adresa 
    //         -  96 caractere sunt nr ticketelor

    /* ============ Events ============ */
    // Event emitted when a new lottery round is opened
    event LotteryOpened(uint roundNr);
    // Event emitted when a lottery round is closed
    event LotteryClosed(uint roundNr, uint totalTickets, uint totalPlayers);
    // Event emitted when a player purchases lottery tickets
    event TicketsPurchased(uint roundNr, address player, uint amount, uint totalBets, uint totalTickets);
    // Event emitted when Team Multisig claims fees and transfers them to the Gnosis Vault Multisig
    event TreasuryClaimedSingle(address player, uint amount);
    event TreasuryClaimedMulti(address player, uint[] amount);
    // Event emitted when Team Multisig claims fees and transfers them to the Gnosis Vault Multisig
    event WinnerClaimedPrizeSingle(address player, uint rounds);
    event WinnerClaimedPrizeMulti(address player, uint[] rounds);
    // Event emitted when Team Multisig claims fees and transfers them to the Gnosis Vault Multisig
    event TokensLiquified(uint amountToken, uint amountETH, uint liquidity);

    /**
     * @dev Check if the current round meets the requirements for requesting a new VRF seed.
     * @return A boolean indicating if the conditions for requesting a new VRF seed have been met.
     */
    function checkUpkeepVRF(
        Status status,
        uint requestId,
        uint totalBets,
        uint maxPlayers
    ) public pure returns (bool) {
        if (status == Status.Open && requestId == 0 && totalBets == maxPlayers) return true;
        return false;
    }

    /**
     * @dev Create UniV2 Pair
     * @param btclpToken address of BTCLP Token Address
     * @param routerAddress address of UniV2 Router Address
     * @param tokenAddress address of Token used to create pair with
     */
    function createPair(
        address btclpToken,
        address routerAddress,
        address tokenAddress
    ) internal returns (address swapPair, IUniswapRouter02 swapRouter) {
        IUniswapRouter02 _swapRouter = IUniswapRouter02(routerAddress);
        swapPair = IUniswapFactory(_swapRouter.factory()).createPair(
            btclpToken,
            tokenAddress
        );
        swapRouter = _swapRouter; // _swapRouter.WETH()
    }

    // /**
    //  * @dev Add UniV2 Liquidity using Native Tokens for underling Token Pair
    //  * @param tokenAmount amount of ERC20 Tokens
    //  * @param nativeAmount amount of native coins
    //  * @param uniRouter address of UNI V2 Router
    //  * @param lpReceiver address of LP Holder
    //  */
    // function addLiquidityETH(
    //     uint256 tokenAmount,
    //     uint256 nativeAmount,
    //     address uniRouter,
    //     address lpReceiver
    // ) external payable {
    //     IUniswapRouter02 swapRouter = IUniswapRouter02(uniRouter);
    //     (uint256 amountToken, uint256 amountETH, uint256 liquidity) = swapRouter.addLiquidityETH{value: nativeAmount}(
    //         address(this),
    //         tokenAmount,
    //         0, // slippage is unavoidable
    //         0, // slippage is unavoidable
    //         lpReceiver,
    //         block.timestamp
    //     );
    //     emit TokensLiquified(amountToken, amountETH, liquidity);
    // }

    // Swap WETH to DAI
    function swapSingleHopExactAmountIn(
        address uniRouter,
        address _tokenA,
        address _tokenB,
        uint amountIn,
        uint amountOutMin
    ) external returns (uint amountOut) {
        IUniswapRouter02 swapRouter = IUniswapRouter02(uniRouter);
        IERC20(_tokenA).transferFrom(msg.sender, address(this), amountIn);
        IERC20(_tokenB).approve(address(swapRouter), amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;

        uint[] memory amounts = swapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        // amounts[0] = WETH amount, amounts[1] = DAI amount
        return amounts[1];
    }

    /**
     * @dev Add UniV2 Liquidity using ERC20 Tokens for underling Token Pair
     * @param _amountA amount of Token A
     * @param _amountB amount of Token B
     * @param _tokenA address of Token A
     * @param _tokenB address of Token B
     * @param lpReceiver address of LP Holder
     */
    function addLiquidity(
        uint _amountA,
        uint _amountB,
        address _tokenA,
        address _tokenB,
        address uniRouter,
        address lpReceiver
    ) external {
        IUniswapRouter02 swapRouter = IUniswapRouter02(uniRouter);
        // IWETH(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        // IWETH(_tokenB).transferFrom(msg.sender, address(this), _amountB);

        IERC20(_tokenA).approve(address(swapRouter), _amountA);
        IERC20(_tokenB).approve(address(swapRouter), _amountB);

        (uint amountA, uint amountB, uint liquidity) = swapRouter.addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            0,
            0,
            lpReceiver,
            block.timestamp
        );

        emit TokensLiquified(amountA, amountB, liquidity);
    }

    /**
     * @dev Price Calculator
     * @param btclpToken address of BTCLP Token Address
     * @param factoryAddress address of UniV2 Factory Address
     * @param tokenAddress address of Token used to derive live price
     * @return btclpAmount amount of BTCLP Tokens for given token amount
     */
    function pairPriceInfo(
        address btclpToken,
        address factoryAddress,
        address tokenAddress,
        uint256 tokenAmount
    ) public view returns (uint256 btclpAmount) {
        if (
            tokenAmount <
            ((10 ** IERC20Metadata(tokenAddress).decimals()) / 1e2)
        ) revert ONE_CENT_IN_TOKEN();
        IUniswapV2Pair pair = IUniswapV2Pair(
            UniswapV2Library.pairFor(factoryAddress, btclpToken, tokenAddress)
        );
        if (address(pair) == address(0)) revert PAIR_NOT_SET();
        (uint256 reserves0, uint256 reserves1, ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = tokenAddress == pair.token0()
            ? (reserves1, reserves0)
            : (reserves0, reserves1);
        uint256 numerator = (10 ** IERC20Metadata(tokenAddress).decimals()) *
            reserveA; // Numerator Reserve
        uint256 denominator = reserveB; // Denominator Reserve
        uint256 amountOutCents = (numerator / denominator) / 1e2; // 1 cent of USDC
        uint256 amountInBTCLP = tokenAmount / 1e4; // 1 cent of BTCLP Tokens
        uint256 amountInBTCLPCents = amountInBTCLP * amountOutCents; // Total BTCLP Tokens in cents
        btclpAmount = amountInBTCLPCents + (amountInBTCLPCents / 100); // Live Price in BTCLP Tokens
    }

    // function pairPriceInfoo(address btclpToken, address factoryAddress, address tokenAddress, uint256 tokenAmount) public view returns (uint256 btclpAmount) {
    //     if (tokenAmount < 1e4) revert ONE_CENT_IN_TOKEN();
    //     IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factoryAddress, btclpToken, tokenAddress));
    //     if (address(pair) == address(0)) revert PAIR_NOT_SET();
    //     (uint256 reserves0, uint256 reserves1,) = pair.getReserves();
    //     (uint256 reserveA, uint256 reserveB) = tokenAddress == pair.token0() ? (reserves1, reserves0) : (reserves0, reserves1);
    //     uint256 numerator = 1e6 * reserveA; // Numerator Reserve
    //     uint256 denominator = reserveB;     // Denominator Reserve
    //     uint256 amountOutCents = (numerator / denominator) / 1e2; // 1 cent of USDC
    //     uint256 amountInBTCLP = tokenAmount / 1e4; // 1 cent of BTCLP Tokens
    //     uint256 amountInBTCLPCents = amountInBTCLP * amountOutCents; // Total BTCLP Tokens in cents
    //     btclpAmount = amountInBTCLPCents + (amountInBTCLPCents / 100); // Live Price in BTCLP Tokens
    // }

    /**
     * @dev Rewards Calculator
     * @param totalWinners number of active participants
     * @param totalAmount number of tickets in stablecoins
     * @param decimals number of decimals for token precission
     * @return rewards an array of rewards depending on how many players have joined
     */
    function calculateRewards(
        uint totalWinners,
        uint totalAmount,
        uint decimals
    ) public pure returns (uint[] memory rewards) {
        if (totalWinners < 1 || totalWinners > 10) return (new uint[](0));
        rewards = new uint[](totalWinners);

        if(totalWinners == 1){
            rewards[0] = totalAmount * (10 ** decimals);     // 100%
            return rewards;
        }
        if(totalWinners == 2){
            rewards[0] = (7 * totalAmount) * (10 ** decimals) / 10;     // 70%
            rewards[1] = (3 * totalAmount) * (10 ** decimals) / 10;     // 30%
            return rewards;
        }
        if (totalWinners == 3) {
            rewards[0] = ((45 * totalAmount) * (10 ** decimals)) / 100; // 45%
            rewards[1] = ((30 * totalAmount) * (10 ** decimals)) / 100; // 30%
            rewards[2] = ((25 * totalAmount) * (10 ** decimals)) / 100; // 25%
            return rewards;
        }
        if (totalWinners == 4) {
            rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
            rewards[1] = ((3 * totalAmount) * (10 ** decimals)) / 10; // 30%
            rewards[2] = ((15 * totalAmount) * (10 ** decimals)) / 100; // 15%
            rewards[3] = ((5 * totalAmount) * (10 ** decimals)) / 100; // 5%
            return rewards;
        }
        if (totalWinners == 5) {
            rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10;   // 50%
            rewards[1] = ((21 * totalAmount) * (10 ** decimals)) / 100; // 21%
            rewards[2] = ((12 * totalAmount) * (10 ** decimals)) / 100; // 12%
            rewards[3] = ((9 * totalAmount) * (10 ** decimals)) / 100;  // 9%
            rewards[4] = ((8 * totalAmount) * (10 ** decimals)) / 100;  // 8%
            return rewards;
        }
        if (totalWinners == 6) {
            rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
            rewards[1] = ((2 * totalAmount) * (10 ** decimals)) / 10; // 20%
            rewards[2] = ((1 * totalAmount) * (10 ** decimals)) / 10; // 10%
            rewards[3] = ((8 * totalAmount) * (10 ** decimals)) / 100; // 8%
            rewards[4] = ((7 * totalAmount) * (10 ** decimals)) / 100; // 7%
            rewards[5] = ((5 * totalAmount) * (10 ** decimals)) / 100; // 5%
            return rewards;
        }
        if (totalWinners == 7) {
            rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
            rewards[1] = ((2 * totalAmount) * (10 ** decimals)) / 10; // 20%
            rewards[2] = ((8 * totalAmount) * (10 ** decimals)) / 100; // 8%
            rewards[3] = ((7 * totalAmount) * (10 ** decimals)) / 100; // 7%
            rewards[4] = ((6 * totalAmount) * (10 ** decimals)) / 100; // 6%
            rewards[5] = ((5 * totalAmount) * (10 ** decimals)) / 100; // 5%
            rewards[6] = ((4 * totalAmount) * (10 ** decimals)) / 100; // 4%
            return rewards;
        }
        if (totalWinners == 8) {
            rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
            rewards[1] = ((15 * totalAmount) * (10 ** decimals)) / 100; // 15%
            rewards[2] = ((1 * totalAmount) * (10 ** decimals)) / 10; // 10%
            rewards[3] = ((7 * totalAmount) * (10 ** decimals)) / 100; // 7%
            rewards[4] = ((6 * totalAmount) * (10 ** decimals)) / 100; // 6%
            rewards[5] = ((5 * totalAmount) * (10 ** decimals)) / 100; // 5%
            rewards[6] = ((4 * totalAmount) * (10 ** decimals)) / 100; // 4%
            rewards[7] = ((3 * totalAmount) * (10 ** decimals)) / 100; // 3%
            return rewards;
        }
        if (totalWinners == 9) {
            rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
            rewards[1] = ((15 * totalAmount) * (10 ** decimals)) / 100; // 15%
            rewards[2] = ((8 * totalAmount) * (10 ** decimals)) / 100; // 8%
            rewards[3] = ((7 * totalAmount) * (10 ** decimals)) / 100; // 7%
            rewards[4] = ((6 * totalAmount) * (10 ** decimals)) / 100; // 6%
            rewards[5] = ((5 * totalAmount) * (10 ** decimals)) / 100; // 5%
            rewards[6] = ((4 * totalAmount) * (10 ** decimals)) / 100; // 4%
            rewards[7] = ((3 * totalAmount) * (10 ** decimals)) / 100; // 3%
            rewards[8] = ((2 * totalAmount) * (10 ** decimals)) / 100; // 2%
            return rewards;
        }
        if (totalWinners == 10) {
            rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
            rewards[1] = ((2 * totalAmount) * (10 ** decimals)) / 10; // 18%
            rewards[2] = ((1 * totalAmount) * (10 ** decimals)) / 10; // 10%
            rewards[3] = ((6 * totalAmount) * (10 ** decimals)) / 100; // 6%
            rewards[4] = ((44 * totalAmount) * (10 ** decimals)) / 1000; // 4.4%
            rewards[5] = ((3 * totalAmount) * (10 ** decimals)) / 100; // 3%
            rewards[6] = ((24 * totalAmount) * (10 ** decimals)) / 1000; // 2.4%
            rewards[7] = ((22 * totalAmount) * (10 ** decimals)) / 1000; // 2.2%
            rewards[8] = ((2 * totalAmount) * (10 ** decimals)) / 100; // 2%
            rewards[9] = ((2 * totalAmount) * (10 ** decimals)) / 100; // 2%
            return rewards;
        }
    }

    // /**
    //  * @dev Rewards Calculator
    //  * @param numParticipants number of active participants
    //  * @param totalAmount number of tickets in stablecoins
    //  * @param decimals number of decimals for token precission
    //  * @return rewards an array of rewards depending on how many players have joined
    //  * @return numWinners an array of rewards and how many prizes
    //  */
    // function calculateRewards(
    //     uint numParticipants,
    //     uint totalAmount,
    //     uint decimals
    // ) public pure returns (uint[] memory rewards, uint numWinners) {
    //     if (numParticipants < 10) return (new uint[](0), 0);
    //     numWinners = numParticipants / 10;
    //     rewards = new uint[](numWinners);

    //     if(numWinners == 1){
    //         rewards[0] = totalAmount * (10 ** decimals);     // 100%
    //         return (rewards, numWinners);
    //     }
    //     if(numWinners == 2){
    //         rewards[0] = (7 * totalAmount) * (10 ** decimals) / 10;     // 70%
    //         rewards[1] = (3 * totalAmount) * (10 ** decimals) / 10;     // 30%
    //         return (rewards, numWinners);
    //     }
    //     if (numWinners == 3) {
    //         rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
    //         rewards[1] = ((3 * totalAmount) * (10 ** decimals)) / 10; // 30%
    //         rewards[2] = ((2 * totalAmount) * (10 ** decimals)) / 10; // 20%
    //         return (rewards, numWinners);
    //     }
    //     if (numWinners == 4) {
    //         rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
    //         rewards[1] = ((3 * totalAmount) * (10 ** decimals)) / 10; // 30%
    //         rewards[2] = ((15 * totalAmount) * (10 ** decimals)) / 100; // 15%
    //         rewards[3] = ((5 * totalAmount) * (10 ** decimals)) / 100; // 5%
    //         return (rewards, numWinners);
    //     }
    //     if (numWinners == 5) {
    //         rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
    //         rewards[1] = ((25 * totalAmount) * (10 ** decimals)) / 100; // 25%
    //         rewards[2] = ((11 * totalAmount) * (10 ** decimals)) / 100; // 11%
    //         rewards[3] = ((9 * totalAmount) * (10 ** decimals)) / 100; // 9%
    //         rewards[4] = ((5 * totalAmount) * (10 ** decimals)) / 100; // 5%
    //         return (rewards, numWinners);
    //     }
    //     if (numWinners == 6) {
    //         rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
    //         rewards[1] = ((2 * totalAmount) * (10 ** decimals)) / 10; // 20%
    //         rewards[2] = ((1 * totalAmount) * (10 ** decimals)) / 10; // 10%
    //         rewards[3] = ((8 * totalAmount) * (10 ** decimals)) / 100; // 8%
    //         rewards[4] = ((7 * totalAmount) * (10 ** decimals)) / 100; // 7%
    //         rewards[5] = ((5 * totalAmount) * (10 ** decimals)) / 100; // 5%
    //         return (rewards, numWinners);
    //     }
    //     if (numWinners == 7) {
    //         rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
    //         rewards[1] = ((2 * totalAmount) * (10 ** decimals)) / 10; // 20%
    //         rewards[2] = ((8 * totalAmount) * (10 ** decimals)) / 100; // 8%
    //         rewards[3] = ((7 * totalAmount) * (10 ** decimals)) / 100; // 7%
    //         rewards[4] = ((6 * totalAmount) * (10 ** decimals)) / 100; // 6%
    //         rewards[5] = ((5 * totalAmount) * (10 ** decimals)) / 100; // 5%
    //         rewards[6] = ((4 * totalAmount) * (10 ** decimals)) / 100; // 4%
    //         return (rewards, numWinners);
    //     }
    //     if (numWinners == 8) {
    //         rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
    //         rewards[1] = ((15 * totalAmount) * (10 ** decimals)) / 100; // 15%
    //         rewards[2] = ((1 * totalAmount) * (10 ** decimals)) / 10; // 10%
    //         rewards[3] = ((7 * totalAmount) * (10 ** decimals)) / 100; // 7%
    //         rewards[4] = ((6 * totalAmount) * (10 ** decimals)) / 100; // 6%
    //         rewards[5] = ((5 * totalAmount) * (10 ** decimals)) / 100; // 5%
    //         rewards[6] = ((4 * totalAmount) * (10 ** decimals)) / 100; // 4%
    //         rewards[7] = ((3 * totalAmount) * (10 ** decimals)) / 100; // 3%
    //         return (rewards, numWinners);
    //     }
    //     if (numWinners == 9) {
    //         rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
    //         rewards[1] = ((15 * totalAmount) * (10 ** decimals)) / 100; // 15%
    //         rewards[2] = ((8 * totalAmount) * (10 ** decimals)) / 100; // 8%
    //         rewards[3] = ((7 * totalAmount) * (10 ** decimals)) / 100; // 7%
    //         rewards[4] = ((6 * totalAmount) * (10 ** decimals)) / 100; // 6%
    //         rewards[5] = ((5 * totalAmount) * (10 ** decimals)) / 100; // 5%
    //         rewards[6] = ((4 * totalAmount) * (10 ** decimals)) / 100; // 4%
    //         rewards[7] = ((3 * totalAmount) * (10 ** decimals)) / 100; // 3%
    //         rewards[8] = ((2 * totalAmount) * (10 ** decimals)) / 100; // 2%
    //         return (rewards, numWinners);
    //     }
    //     if (numWinners == 10) {
    //         rewards[0] = ((5 * totalAmount) * (10 ** decimals)) / 10; // 50%
    //         rewards[1] = ((2 * totalAmount) * (10 ** decimals)) / 10; // 18%
    //         rewards[2] = ((1 * totalAmount) * (10 ** decimals)) / 10; // 10%
    //         rewards[3] = ((6 * totalAmount) * (10 ** decimals)) / 100; // 6%
    //         rewards[4] = ((44 * totalAmount) * (10 ** decimals)) / 1000; // 4.4%
    //         rewards[5] = ((3 * totalAmount) * (10 ** decimals)) / 100; // 3%
    //         rewards[6] = ((24 * totalAmount) * (10 ** decimals)) / 1000; // 2.4%
    //         rewards[7] = ((22 * totalAmount) * (10 ** decimals)) / 1000; // 2.2%
    //         rewards[8] = ((2 * totalAmount) * (10 ** decimals)) / 100; // 2%
    //         rewards[9] = ((2 * totalAmount) * (10 ** decimals)) / 100; // 2%
    //         return (rewards, numWinners);
    //     }
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

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

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './IUniswapRouter01.sol';

interface IUniswapRouter02 is IUniswapRouter01 {
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

// SPDX-License-Identifier: UNLICENCED
pragma solidity =0.8.17;

import '../interfaces/IUniswapV2Pair.sol';

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        bytes32 tmp = keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ));
        pair = address(uint160(uint256(tmp)));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = (reserveIn * amountOut) * 1000;
        uint denominator = (reserveOut -amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
pragma solidity 0.8.17;

interface IUniswapRouter01 {
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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

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