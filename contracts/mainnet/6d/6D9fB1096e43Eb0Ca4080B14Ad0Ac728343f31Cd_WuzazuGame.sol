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
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IWrappedNative{
    function deposit() external payable;
    function withdraw(uint amount) external;
}

interface IBurnable {
    function burn(uint amount) external;
}

enum GameState{ IDLE, RUNNING, RESOLVING, PAUSED}

contract WuzazuGame is Ownable, ReentrancyGuard {

    //fees
    uint public   burnFees =         50;
    uint public   protocolFees =     500;
    uint public   rolloverFees =     950;
    uint constant maxFees =          2500;

    //Constants
    uint public constant precision = 10000;
    uint public constant nClasses = 3;
    uint public constant minimumBet = 1e18;
    address constant public wrappedNative = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant public router = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public immutable protocolToken;

    //Operators
    mapping(address => bool) public operators;

    //Revenues
    uint public unclaimedFees;
    uint public totalToBurn;

    //Game State
    uint public roundTime = 0;
    uint public currentRound;
    GameState public state = GameState.IDLE;
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

    //Player State
    mapping(address => mapping(uint => uint[3])) public playerWagersPerClass;
    mapping(address => mapping(uint => bool)) public playerWagerClaimed;
    mapping(address => mapping(uint => bool)) public playerWagerMade;

    //Events
    event FeesUpdated(uint burnPercent, uint protocolPercent, uint rolloverPercent, uint totalPercent);
    event GameStateChange(GameState previous, GameState current);
    event Wagered(address indexed player, uint indexed round, uint team,  uint amount);
    event Donation(address indexed donator, uint indexed round, uint amount);
    event RoundResolved(uint indexed round, uint randomNumber, uint winner);
    event FeesBurned(uint amount);
    event FeesClaimed(uint amount);
    event TokensRecovered(address token, uint amount);
    event RewardClaimed(address indexed player, uint indexed round, uint amount);

    constructor(address _protocolToken) public {
        protocolToken = _protocolToken;
        operators[msg.sender] = true;
    }

    receive() external payable {}

    modifier onlyOperators {
        require(operators[msg.sender] || msg.sender == owner(), "Invalid Caller");
        _;
    }

    function toggleOperator(address _operator, bool _state) external onlyOwner {
        operators[_operator] = _state;
    }

    function pauseGame() public onlyOperators {
        require(state == GameState.IDLE, "Invalid State");
        state = GameState.PAUSED;
        emit GameStateChange(GameState.IDLE, GameState.PAUSED);
    }

    function unpauseGame() public onlyOperators {
        require(state == GameState.PAUSED, "Invalid State");
        state = GameState.IDLE;
        emit GameStateChange(GameState.PAUSED, GameState.IDLE);
    }

    function updateFees(uint _burnFees, uint _protocolFees, uint _rolloverFees) public onlyOperators {
        require(state == GameState.PAUSED || state == GameState.IDLE, "Invalid State");
        uint totalFees = _burnFees + _protocolFees + _rolloverFees;
        require(totalFees <= maxFees, "Excessive Fees");
        burnFees = _burnFees;
        protocolFees = _protocolFees;
        rolloverFees = _rolloverFees;
        emit FeesUpdated(_burnFees, _protocolFees, _rolloverFees, totalFees);
    }

    function updateRoundTimer(uint newRoundTime) public onlyOwner {
        require(state == GameState.PAUSED || state == GameState.IDLE, "Invalid State");
        require(newRoundTime < 7 days, "Too Long");
        require(newRoundTime > 1 minutes, "Too Short");
        roundTime = newRoundTime;
    }

    function recoverToken(address token) public onlyOwner {
        require(token != protocolToken, "Cannot Recover Protocol Token");
        uint amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), amount);
        emit TokensRecovered(token, amount);
    }

    function recoverNative() public onlyOwner {
        uint amount = address(this).balance;
        payable(owner()).send(amount);
        emit TokensRecovered(address(0), amount);
    }

    function donate(uint amount) public nonReentrant {
        require(state == GameState.RUNNING, "Invalid State");
        require(roundEndTime[currentRound] > block.timestamp, "No More Donations");
        uint start = IERC20(protocolToken).balanceOf(address(this));
        IERC20(protocolToken).transferFrom(msg.sender, address(this), amount);
        uint difference = IERC20(protocolToken).balanceOf(address(this)) - start;

        totalWagered[currentRound] += difference;
        roundDonations[currentRound] += difference;
        emit Donation(msg.sender, currentRound, difference);
    }

    function startRound() public onlyOperators nonReentrant {
        require(state == GameState.IDLE, "Invalid State");

        currentRound += 1;
        roundStartTime[currentRound] = block.timestamp;
        roundEndTime[currentRound] = block.timestamp + roundTime;
        state = GameState.RUNNING;
        emit GameStateChange(GameState.IDLE, GameState.RUNNING);
    }

    function wager(uint team, uint amount, uint minOut) external payable nonReentrant returns(uint difference){
        uint256 startGas = gasleft();
        require(state == GameState.RUNNING, "Round Not Open");
        require(roundEndTime[currentRound] > block.timestamp, "No More Bets");

        uint startBalance = IERC20(protocolToken).balanceOf(address(this));

        if(msg.value > 0){
            require(amount == msg.value, "amount missmatch");

            address[] memory path = new address[](3);
            path[0] = wrappedNative;
            path[1] = usdc;
            path[2] = protocolToken;

            IWrappedNative(wrappedNative).deposit{value:msg.value}();
            IERC20(wrappedNative).approve(router, msg.value);
            IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(msg.value, minOut, path, address(this), block.timestamp);
        }
        else {
            IERC20(protocolToken).transferFrom(msg.sender, address(this), amount);
        }

        difference = IERC20(protocolToken).balanceOf(address(this)) - startBalance;

        //Update Round Specific Data
        roundWagersPerClass[currentRound][team] += difference;
        roundNWagers[currentRound] += 1;

        totalWagered[currentRound] = totalWagered[currentRound] + difference;

        //Update Player Specific Data
        playerWagersPerClass[msg.sender][currentRound][team] += difference;
        playerWagerMade[msg.sender][currentRound] = true;

        uint gasUsed = startGas - gasleft();
        roundGasUsed[currentRound] += gasUsed;
        emit Wagered(msg.sender, currentRound, team, difference);
    }

    function closeRound() external onlyOperators nonReentrant {
        require(state == GameState.RUNNING, "Invalid State");
        require(block.timestamp > roundEndTime[currentRound], "too early");
        roundBlockHash[currentRound] = blockhash(block.number);
        roundBlockDifficulty[currentRound] = block.difficulty;
        roundCoinbase[currentRound] = block.coinbase;
        state = GameState.RESOLVING;
        emit GameStateChange(GameState.RUNNING, GameState.RESOLVING);
    }

    function resolveRound() external onlyOperators nonReentrant {
        require(state == GameState.RESOLVING, "Invalid State");
        uint seed = randomSeed(currentRound);
        uint winner = seed % nClasses;
        roundWinner[currentRound] = winner;
        roundResolved[currentRound] = true;

        uint fee;
        uint rollOver;
        uint burn;

        if(roundNWagers[currentRound] < 1 || roundWagersPerClass[currentRound][winner] < minimumBet){

            fee = (totalWagered[currentRound] * protocolFees) / precision;
            burn = (totalWagered[currentRound] * burnFees) / precision;
            rollOver = totalWagered[currentRound] - fee - burn;
            finalWagered[currentRound] = 0;
        }
        else{
            fee = (totalWagered[currentRound] * protocolFees) / precision;
            burn = (totalWagered[currentRound] * burnFees) / precision;
            rollOver = (totalWagered[currentRound] * rolloverFees) / precision;
            finalWagered[currentRound] = totalWagered[currentRound] - fee - rollOver - burn;
        }

        totalWagered[currentRound + 1] = rollOver;
        roundRolledOver[currentRound + 1] = rollOver;
        roundToRollOver[currentRound] = rollOver;
        roundFees[currentRound] = fee;
        roundBurned[currentRound] = burn;
        unclaimedFees += fee;
        totalToBurn += burn;
        state = GameState.IDLE;
        emit GameStateChange(GameState.RESOLVING, GameState.IDLE);
        emit RoundResolved(currentRound, seed, winner);
    }

    function claimFees(bool asUsdc, uint minOut) external onlyOperators nonReentrant {
        uint _unclaimedFees = unclaimedFees;
        require(_unclaimedFees > 0, "noFees");
        if(asUsdc){
            address[] memory path = new address[](2);
            path[0] = protocolToken;
            path[1] = usdc;

            IERC20(protocolToken).approve(router, _unclaimedFees);
            IUniswapV2Router02(router).swapExactTokensForTokens(_unclaimedFees, minOut, path, owner(), block.timestamp);
        }
        else{
            IERC20(protocolToken).transfer(owner(), _unclaimedFees);
        }
        emit FeesClaimed(_unclaimedFees);
        unclaimedFees = 0;
    }

    function triggerBurn() external onlyOperators nonReentrant {
        uint _totalToBurn = totalToBurn;
        require(_totalToBurn > 0, "nothing to burn");
        IBurnable(protocolToken).burn(_totalToBurn);
        emit FeesBurned(_totalToBurn);
        totalToBurn = 0;
    }

    function claimRewards(uint round, bool matic, uint minOut) external nonReentrant returns(uint reward) {
        require(roundResolved[round], "round not resolved");
        require(playerWagerClaimed[msg.sender][round] == false, "claimed");
        require(playerWagersPerClass[msg.sender][round][roundWinner[round]] > 0, "no bets");
        
        playerWagerClaimed[msg.sender][round] = true;

        uint percentage = (playerWagersPerClass[msg.sender][round][roundWinner[round]] * precision) / roundWagersPerClass[round][roundWinner[round]];
        reward = (finalWagered[round] * percentage) / precision;

        if(matic){
            address[] memory path = new address[](3);
            path[0] = protocolToken;
            path[1] = usdc;
            path[2] = wrappedNative;

            IERC20(protocolToken).approve(router, reward);
            IUniswapV2Router02(router).swapExactTokensForETH(reward, minOut, path, msg.sender, block.timestamp);
        }
        else{
            IERC20(protocolToken).transfer(msg.sender, reward);
        }

        emit RewardClaimed(msg.sender, round, reward);
    }

    //generate a seed from round data
    function roundHash(uint round) public view returns(bytes32 seed) {
        if(roundEndTime[round] <  block.timestamp){
            seed = keccak256(abi.encodePacked(keccak256(abi.encodePacked(round, roundBlockHash[round], roundStartTime[round], roundEndTime[round], roundNWagers[round], roundWagersPerClass[round], roundGasUsed[round], roundBlockDifficulty[round], roundCoinbase[round]))));
        }
    }

    //Generate a number from combined hash
    function randomSeed(uint round) public view returns(uint seed){
        seed = uint(roundHash(round));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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