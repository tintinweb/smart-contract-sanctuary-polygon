/**
 ▄█     █▄  ███    █▄   ▄███████▄     ▄████████  ▄███████▄  ███    █▄  
███     ███ ███    ███ ██▀     ▄██   ███    ███ ██▀     ▄██ ███    ███ 
███     ███ ███    ███       ▄███▀   ███    ███       ▄███▀ ███    ███ 
███     ███ ███    ███  ▀█▀▄███▀▄▄   ███    ███  ▀█▀▄███▀▄▄ ███    ███ 
███     ███ ███    ███   ▄███▀   ▀ ▀███████████   ▄███▀   ▀ ███    ███ 
███     ███ ███    ███ ▄███▀         ███    ███ ▄███▀       ███    ███ 
███ ▄█▄ ███ ███    ███ ███▄     ▄█   ███    ███ ███▄     ▄█ ███    ███ 
 ▀███▀███▀  ████████▀   ▀████████▀   ███    █▀   ▀████████▀ ████████▀  
                                                                       
Author : Hephyrius.eth

Website: wuzazu.xyz
Twitter:https://twitter.com/WuzazuGame
Telegram: https://t.me/wuzazu

SPDX-License-Identifier: UNLICENSED
**/

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

struct RoundSummary {
    uint roundNumber;
    uint startTime;
    uint endTime;
    uint nWagers;
    uint[] asWuzazu;
    uint[] asDollars;
    uint[] asMatic;
    bool resolved;
}

struct PlayerSummary {
    uint roundNumber;
    uint[] asWuzazu;
    uint[] asDollars;
    uint[] asMatic;
    bool claimed;
    bool wagerMade;
    bool won;
}

struct RoundResults {
    uint roundNumber;
    uint winner;
    uint randomSeed;
    uint gasUsed;
    uint difficulty;
    address coinbase;
    bytes32 blockHash;
    bytes32 roundHash;
}

struct CurrentState {
    uint8 gameState;
    uint currentRound;
    uint roundTime;
    uint balance;
    uint fees;
    uint burns;
}

enum GameState{ IDLE, RUNNING, RESOLVING, PAUSED}

contract IWuzazuGame {
    uint public nClasses;
    uint public precision;
    uint public minimumBet;
    address public wrappedNative;
    address public usdc;
    address public router;
    address public  protocolToken;
    mapping(address => bool) public operators;
    uint public   burnFees;
    uint public   protocolFees;
    uint public   rolloverFees;
    uint public unclaimedFees;
    uint public totalToBurn;
    uint public roundTime;
    uint public currentRound;
    GameState public state;
    mapping(uint => uint) public roundStartTime;
    mapping(uint => uint) public roundEndTime;
    mapping(uint => uint) public roundNWagers;
    mapping(uint => uint[3]) public roundWagersPerClass;
    
    mapping(uint => uint) public roundRolledOver;
    mapping(uint => uint) public roundToRollOver;
    mapping(uint => uint) public roundDonations;
    mapping(uint => uint) public roundFees;
    mapping(uint => uint) public roundBurned;
    mapping(uint => bool) public roundResolved;
    mapping(uint => uint) public totalWagered;
    mapping(uint => uint)  public finalWagered;

    mapping(uint => uint) public roundGasUsed;
    mapping(uint => uint) public roundBlockDifficulty;
    mapping(uint => bytes32) public roundBlockHash;
    mapping(uint => address) public roundCoinbase;
    mapping(uint => uint) public roundWinner;

    mapping(address => mapping(uint => uint[3])) public playerWagersPerClass;
    mapping(address => mapping(uint => bool)) public playerWagerClaimed;
    mapping(address => mapping(uint => bool)) public playerWagerMade;

    function toggleOperator(address _operator, bool _state) external virtual{}
    function pauseGame() external virtual{}
    function unpauseGame() external virtual{}
    function updateFees(uint _burnFees, uint _protocolFees, uint _rolloverFees) external virtual{}
    function updateRoundTimer(uint newRoundTime) external virtual{}
    function recoverToken(address token) external virtual{}
    function recoverNative() external virtual{}
    function donate(uint amount) external virtual{}
    function startRound() external virtual{}
    function wager(uint team, uint amount, uint minOut) external virtual returns(uint difference){}
    function closeRound() external virtual{}
    function resolveRound() external virtual{}
    function claimFees(bool asUsdc, uint minOut) external virtual{}
    function triggerBurn() external virtual{}
    function claimRewards(uint round, bool matic, uint minOut) external virtual returns(uint reward){}
    function roundHash(uint round) external view virtual returns(bytes32 seed){}
    function randomSeed(uint round) external view virtual returns(uint seed){}
}

contract WuzazuHelper {

    IWuzazuGame public protocol;

    constructor(address _protocol) public {
        protocol = IWuzazuGame(_protocol);
    }

    //Functions used in UI

    function tokenValue(address[] memory path, uint amount) public view returns(uint value){
        value = IUniswapV2Router02(protocol.router()).getAmountsOut(amount, path)[path.length - 1];
    } 

    function tokenValueinMatic(uint amount) public view returns(uint value){
        if(amount > 0){
            address[] memory path = new address[](3);
            path[0] = protocol.protocolToken();
            path[1] = protocol.usdc();
            path[2] = protocol.wrappedNative();
            value = IUniswapV2Router02(protocol.router()).getAmountsOut(amount, path)[path.length - 1];
        }
    } 

    function tokenValueinUSD(uint amount) public view returns(uint value){
        if(amount > 0){
            address[] memory path = new address[](2);
            path[0] = protocol.protocolToken();
            path[1] = protocol.usdc();
            value = IUniswapV2Router02(protocol.router()).getAmountsOut(amount, path)[path.length - 1];
        }
    } 

    function getRoundSummary(uint round) public view returns(RoundSummary memory summary) {
        summary = RoundSummary({
            roundNumber:    round,
            startTime:      protocol.roundStartTime(round),
            endTime :       protocol.roundEndTime(round),
            nWagers:        protocol.roundNWagers(round),
            asWuzazu:       new uint[](10),
            asDollars:      new uint[](10),
            asMatic:        new uint[](10),
            resolved:       protocol.roundResolved(round)
        });

        for(uint i=0; i<3; i++){
            summary.asWuzazu[i] = protocol.roundWagersPerClass(round , i);

        }

        summary.asWuzazu[3] = protocol.totalWagered(round);
        summary.asWuzazu[4] = protocol.finalWagered(round);
        summary.asWuzazu[5] = protocol.roundRolledOver(round);
        summary.asWuzazu[6] = protocol.roundToRollOver(round);
        summary.asWuzazu[7] = protocol.roundFees(round);
        summary.asWuzazu[8] = protocol.roundBurned(round);
        summary.asWuzazu[9] = protocol.roundDonations(round);

        for(uint i = 0; i < summary.asDollars.length; i++){
            uint v = summary.asWuzazu[i];
            summary.asDollars[i] = tokenValueinUSD(v);
            summary.asMatic[i] = tokenValueinMatic(v);
        }



    }

    function getRoundSummaries(uint[] memory rounds) public view returns(RoundSummary[] memory summary) {
        summary = new RoundSummary[](rounds.length);
        
        for(uint i=0; i<rounds.length; i++){
            summary[i] = getRoundSummary(rounds[i]);
        }
    }

    function getPlayerSummary(uint round, address player) public view returns(PlayerSummary memory summary) {
        summary = PlayerSummary({
            roundNumber:    round,
            claimed:        protocol.playerWagerClaimed(player,round),
            wagerMade:      protocol.playerWagerMade(player , round),
            asWuzazu:       new uint[](4),
            asDollars:      new uint[](4),
            asMatic:        new uint[](4),
            won:            false
        });

        for(uint i=0; i<3; i++){
            uint v = protocol.playerWagersPerClass(player, round, i);
            summary.asWuzazu[i] = v;
            summary.asDollars[i] = tokenValueinUSD(v);
            summary.asMatic[i] = tokenValueinMatic(v);
        }

        if(summary.wagerMade && protocol.roundResolved(round) && (summary.asWuzazu[protocol.roundWinner(round)] > 0)) {
            summary.won = true;
            uint percentage = (protocol.playerWagersPerClass(player, round, protocol.roundWinner(round)) * protocol.precision()) / protocol.roundWagersPerClass(round, protocol.roundWinner(round));
            uint reward = (protocol.finalWagered(round) * percentage) / protocol.precision();

            summary.asWuzazu[3] = reward;
            summary.asDollars[3] = tokenValueinUSD(reward);
            summary.asMatic[3] = tokenValueinMatic(reward);
        }
    }

    function getPlayerSummaries(uint[] memory rounds, address player) public view returns(PlayerSummary[] memory summary) {
        summary = new PlayerSummary[](rounds.length);
        
        for(uint i=0; i<rounds.length; i++){
            summary[i] = getPlayerSummary(rounds[i], player);
        }
    }

    function getRoundResult(uint round) public view returns(RoundResults memory summary) {
        summary = RoundResults({
            roundNumber:    round,
            winner:         protocol.roundWinner(round),
            randomSeed:     protocol.randomSeed(round),
            blockHash:      protocol.roundBlockHash(round),
            roundHash:      protocol.roundHash(round),
            gasUsed:        protocol.roundGasUsed(round),
            difficulty:     protocol.roundBlockDifficulty(round),
            coinbase:       protocol.roundCoinbase(round)
        });

    }

    function getRoundResults(uint[] memory rounds) public view returns(RoundResults[] memory summary) {
        summary = new RoundResults[](rounds.length);
        
        for(uint i=0; i<rounds.length; i++){
            summary[i] = getRoundResult(rounds[i]);
        }
    }

    function getCurrentGameState() public view returns(CurrentState memory currentState){
        currentState = CurrentState({
            currentRound : protocol.currentRound(),
            gameState : uint8(protocol.state()),
            roundTime: protocol.roundTime(),
            balance: IERC20(protocol.protocolToken()).balanceOf(address(protocol)),
            fees: protocol.unclaimedFees(),
            burns: protocol.totalToBurn()
        });
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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