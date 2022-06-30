// SPDX-License-Identifier: MIT

// // File: @openzeppelin/contracts/utils/Context.sol
pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
//900

// File: contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// File: contracts/interfaces/IPolyLottoRaffle.sol
pragma solidity ^0.8.4;

interface IPolyLottoRaffle {
    enum RaffleCategory {
        BASIC,
        INVESTOR,
        WHALE
    }

    enum RaffleState {
        INACTIVE,
        WAITING_FOR_REBOOT,
        OPEN,
        TICKETS_DRAWN,
        PAYOUT,
        DEACTIVATED
    }

    struct RaffleStruct {
        uint256 ID; //Raffle ID
        uint256 noOfTicketsSold; // Tickets sold
        uint256 noOfPlayers;
        uint256 amountInjected;
        uint256[] winnersPayout; // Contains the % payouts of the winners
        address[] winners;
        uint256[] winningTickets; // Contains array of winning Tickets
        uint256 raffleStartTime;
        uint256 raffleEndTime;
        bool rollover;
    }

    struct RaffleData {
        uint256 ticketPrice;
        uint256 rafflePool;
        RaffleState raffleState;
    }

    /**
     * @notice Start raffle
     * @dev only callable by keeper address
     */

    function startRaffle() external;

    /**
     * @notice updates the price of the tickets
     * @param _amountOfTokenPerStable: Max no of token that can be gotten from one stable coin
     * @dev Callable by price updater contract only!
     */
    function setTicketPrice(uint256 _amountOfTokenPerStable) external;

    /**
     * @notice Buy tickets for the current lottery
     * @param _category: Raffle Category
     * @param _tickets: array of ticket numbers between 100,000 and 999,999
     * @dev Callable by users only, not contract!
     */
    function buyTickets(RaffleCategory _category, uint32[] calldata _tickets)
        external;

    /**
     * @notice gets the Winners of the current Raffle
     * @param _category: Raffle Category
     * @dev Callable by keepers contract
     */
    function getWinners(RaffleCategory _category) external;

    /**
     * @notice sets the raffle state to tickets drawn
     * @param _category: Raffle Category
     * @param _drawCompleted: boolean to tell contract when draw has finis
     * @dev Callable by randomGenerator contract 
    
     */
    function setRaffleAsDrawn(RaffleCategory _category, bool _drawCompleted)
        external;

    /**
     * @notice sends out winnings to the Raffle Winners
     * @param _category: Raffle Category
     * @dev Callable by keepers contract
     */
    function payoutWinners(RaffleCategory _category) external;

    /**
     * @notice rollovers user tickets, whenever a raffle is not valid
     * @param _category: Raffle Category
     * @dev Callable by keepers contracts
     */
    function rollover(RaffleCategory _category) external;

    /**
     * @notice Deactivates Raffle, can only be called if raffle is not valid
     * @dev Callable by operator
     */
    function deactivateRaffle() external;

    /**
     * @notice Activates Raffle, can only be called if raffle has been deactivated
     * @dev Callable by operator
     */
    function reactivateRaffle() external;

    /**
     * @notice Updates Raffle Token, for tickets purchase, refunds old tokens balance to users with rollover
     * @param _newTokenAddress: new Token Address
     * @dev Callable by operator, and can be only called once.
     */
    function updateRaffleToken(address _newTokenAddress) external;

    /**
     * @notice Inject funds
     * @param _category: Raffle Cateogory
     * @param _amount: amount to inject in current Raffle Token
     * @dev Callable by operator
     */
    function injectFunds(RaffleCategory _category, uint256 _amount) external;

    /**
     * @notice View current raffle id
     */
    function getRaffleID() external view returns (uint256);

    /**
     * @notice View Raffle Information
     */
    function getRaffle(RaffleCategory _category, uint256 _raffleID)
        external
        view
        returns (RaffleStruct memory);

    /**
     * @notice View general raffle information
     */
    function getRaffleData(RaffleCategory _category)
        external
        view
        returns (RaffleData memory);

    /**
     * @notice get number of winners
     */
    function getNoOfWinners() external view returns (uint256);

    /**
     * @notice returns param that shows that all raffle categories are in sync
     */
    function getRebootChecker() external view returns (uint256);

    /**
     * @notice returns param that shows if a random request has been made in a raffle category
     */
    function getRandomGenChecker(RaffleCategory _category)
        external
        view
        returns (bool);

    /**
     * @notice returns the raffle end time
     */
    function getRaffleEndTime() external view returns (uint256);

    /**
     * @notice returns the reboot end time
     */
    function getRebootEndTime() external view returns (uint256);
}

// File: contracts/interfaces/IPolyLottoPriceUpdater.sol
pragma solidity ^0.8.4;

interface IPolyLottoPriceUpdater {
    /**
     @notice Update stable coin;
     @param _newTokenAddress: Stable coin address
     @param _newTokenName: Stable coin name
     @dev Callable by operator only!
     */
    function updateStableToken(
        address _newTokenAddress,
        string memory _newTokenName
    ) external;

    /**
     @notice Updates the raffle token;
     @param _newTokenAddress: Token's address
     @dev Callable by PolyLotto raffle contract  only!
     */
    function updatePolyLottoToken(address _newTokenAddress) external;

    /**
     @notice Function to get update price of token against Stable Token
     @dev Callable by PolyLotto raffle contract only!
     */
    function updatePrice() external;

    /**
     * @notice update router supplying raffle with price of token
     * @param _dexName: Name of Decentralised Exchange with liquidity pool
     * @param _routerAddress: router address of that Exchange
     * @dev Callable by operator only!
     */
    function setRouter(string memory _dexName, address _routerAddress) external;
}

// Price updater contract
pragma solidity >=0.8.0 <0.9.0;

contract PolyLottoPriceUpdater is Ownable, IPolyLottoPriceUpdater {
    struct Router {
        string Dex;
        IUniswapV2Router02 routerAddress;
    }
    struct StableToken {
        string TokenName;
        address TokenAddress;
    }

    Router public DexRouter;
    address public PolyLottoToken;
    StableToken public _stableToken;
    address public operatorAddress;
    address public polyLottoRaffle;

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier onlyPolyLottoRaffle() {
        require(msg.sender == polyLottoRaffle, "Not operator");
        _;
    }

    modifier operatorOrRaffle() {
        require(
            msg.sender == polyLottoRaffle || msg.sender == operatorAddress,
            "Not operator"
        );
        _;
    }

    constructor(
        address _PolyLottoToken,
        address _stableTokenAddress,
        string memory _stableTokenName
    ) {
        PolyLottoToken = _PolyLottoToken;
        _stableToken.TokenName = _stableTokenName;
        _stableToken.TokenAddress = _stableTokenAddress;
    }

    function updateStableToken(
        address _newTokenAddress,
        string memory _newTokenName
    ) external override onlyOperator {
        require(_newTokenAddress != address(0), "Cannot be zero address");
        _stableToken.TokenName = _newTokenName;
        _stableToken.TokenAddress = _newTokenAddress;
    }

    function updatePolyLottoToken(address _newTokenAddress)
        external
        override
        onlyPolyLottoRaffle
    {
        require(_newTokenAddress != address(0), "Cannot be zero address");
        PolyLottoToken = _newTokenAddress;
    }

    /**
     * @notice Set the address for the PolyLotto Raffle
     * @param _polylottoAddress: address of the PolyLotto Raffle
     */
    function setPolyLottoAddress(address _polylottoAddress)
        external
        onlyOperator
    {
        require(_polylottoAddress != address(0), "Cannot be zero address");

        polyLottoRaffle = _polylottoAddress;
    }

    // Function to get update price of token against Stable Token

    function updatePrice() external override operatorOrRaffle {
        address[] memory tokens = new address[](2);
        //dai token
        tokens[0] = _stableToken.TokenAddress;
        //raffle token
        tokens[1] = PolyLottoToken;

        // to get how many raffle tokens we get for 1 usdc token
        uint256[] memory amounts = DexRouter.routerAddress.getAmountsOut(
            1 ether,
            tokens
        );
        // update the price
        IPolyLottoRaffle(polyLottoRaffle).setTicketPrice(amounts[1]);
    }

    function setRouter(string memory _dexName, address _routerAddress)
        external
        override
        onlyOperator
    {
        require(_routerAddress != address(0), "Cannot be zero address");
        DexRouter.Dex = _dexName;
        DexRouter.routerAddress = IUniswapV2Router02(_routerAddress);
    }

    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Cannot be zero address");
        operatorAddress = _operator;
    }
}