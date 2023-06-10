// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
// import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract StratEx is AutomationCompatibleInterface {

    AggregatorV3Interface internal priceFeed;
    address public constant routerAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint256 public constant minimunAmountAllowed = 150000000000000000;
    // ToDo
    uint256 public constant minToDelete = 1500000000000000;

    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);

    uint256 public constant balanceToSpentBPS = 2500; // 25% of the balance will be used to make the swappings

    struct Bot {
        address user;
        uint256 upper_range;
        uint256 lower_range;
        uint256[] grids;
        uint256 currentGrid;
        uint256 buyCounter;
        uint256 sellCounter;
        uint256 lastExecutionTime;
        bool isCancelled;
        address tokenIn;
        address tokenOut;
    }
    Bot[] public bots;
    uint256 public botCounter = 0;
    enum OrderType {
        BuyOrder, 
        SellOrder,
        UpdateCurrentGrid,
        ByPass    
    }

    struct PerformData {
        uint256 botId;
        uint256 breachIndex;
        OrderType orderType;
    }

    // Bot ID => breachIndex => isbreached
    mapping(uint256 => mapping(uint256 => bool)) public breachedBotGrids;
    // Bot ID => breachIndex => amount buy ordered
    mapping(uint256 => mapping(uint256 => uint256)) public boughtBotAmounts;

    // Bot ID => token address => amount
    mapping(uint256 => mapping (address => uint256)) public balances;

    event NewBot(address indexed user, uint256 indexed botId, uint256 upper_range, uint256 lower_range, uint256 no_of_grids, uint256 amount, address tokenIn, address tokenOut);
    event OrderExecuted(address indexed user, uint256 indexed botId, OrderType ordertype, uint256 gridIndex, uint256 qty , uint256 price, uint256 timestamp);
    event Deposit(address indexed user, uint256 indexed botId, uint256 amount);

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    function CreateBot(uint256 _upper_range , uint256 _lower_range, uint256 _no_of_grids, uint256 _amount, address tokenIn, address tokenOut) public {
        uint256 currentPrice = getScaledPrice();
        require(currentPrice >= _lower_range, "current price should be greater than lower range");
        IERC20(tokenIn).transferFrom(msg.sender, address(this), _amount);
        balances[botCounter][tokenIn] += _amount;
        uint256[] memory grids;
        Bot memory newBot = Bot({
            user: msg.sender,
            upper_range: _upper_range,
            lower_range: _lower_range,
            grids: grids,
            currentGrid: 0,
            buyCounter: 0,
            sellCounter: 0,
            lastExecutionTime: block.timestamp,
            isCancelled: false,
            tokenIn: tokenIn,
            tokenOut: tokenOut
        });       
        bots.push(newBot);
        uint256 dist = (_upper_range - _lower_range) / _no_of_grids;
        uint256 k = 0;
        for (uint256 i = 0; i <= _no_of_grids; i++) {
            bots[botCounter].grids.push(_lower_range + k);
            k = k + dist;
        }

        bots[botCounter].currentGrid = calculateGrid(bots[botCounter].grids, currentPrice);
        emit NewBot(msg.sender, botCounter, _upper_range, _lower_range, _no_of_grids, _amount, tokenIn, tokenOut);
        botCounter++;
    }

    function getGrids(uint256 _botIndex) public view returns (uint256[] memory _grids)  {
        return bots[_botIndex].grids;
    }

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A // ETH-USD in Mumbai Testnet
        );
    }

    function calculateGrid(uint256[] memory grids, uint256 _currentPrice) public pure returns (uint256 _currentGrid) {
        // Add grid below lower range (0) and upper range (grids.length + 1)
        for (uint256 i = 0; i < grids.length; i++) {
            if (i == 0 && _currentPrice < grids[i]) return i;
            if (i == (grids.length - 1) && _currentPrice >= grids[i]) return (i + 1);
            if (_currentPrice >= grids[i] && _currentPrice < grids[i + 1]) return (i + 1);
        }
    }

    function checkOrderExecution(uint256 _botId, uint256 _newGrid, uint256 _currentGrid) internal view returns (bool _upkeepNeeded, OrderType _ordertype, uint256 _buyGrid) {
        if ((_newGrid < _currentGrid) && !breachedBotGrids[_botId][_currentGrid-1]){
            _ordertype =OrderType.BuyOrder;
            _upkeepNeeded = true;
        }else if ((_newGrid > _currentGrid) && (_newGrid > 1)) {
            // find minimun order placed to get the maximum profit
            bool hasBuyOrderPlaced; 
            for (uint256 i = 0; i < bots[_botId].grids.length; i++) {
                if (breachedBotGrids[_botId][i] && _newGrid > i) {
                    _buyGrid = i;
                    hasBuyOrderPlaced = true;
                    break;
                }
            }
            if (hasBuyOrderPlaced) {
                _ordertype = OrderType.SellOrder;
                _upkeepNeeded = true; 
            }
        }
        if (!_upkeepNeeded && _newGrid != _currentGrid) {
            _ordertype = OrderType.UpdateCurrentGrid;
            _upkeepNeeded = true;
        }
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData)
    {
        PerformData[] memory performDataUnencoded = new PerformData[](botCounter); // for each botId related the PerfomData

        uint256 price = getScaledPrice();

        bool hasAlmostOneBotToExecute;
        for (uint256 i = 0; i < botCounter; i++) {
            if (bots[i].upper_range == 0 || bots[i].isCancelled) continue; // bots[] can be deleted so to avoid processing empty voids we put this control
            uint256 newGrid = calculateGrid(bots[i].grids, price);
            OrderType ordertype;
            (upkeepNeeded, ordertype, ) = checkOrderExecution(i, newGrid, bots[i].currentGrid);
            if (upkeepNeeded) {
                performDataUnencoded[i] = PerformData(i, newGrid, ordertype);
                hasAlmostOneBotToExecute = true;
            } else {
                performDataUnencoded[i] = PerformData(0, 0, OrderType.ByPass);
            }
        }
        if (hasAlmostOneBotToExecute) performData = abi.encode(performDataUnencoded);
        return (upkeepNeeded, performData); 
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 price = getScaledPrice();
        
        PerformData[] memory performDataDecoded = abi.decode(performData, (PerformData[]));

        for (uint256 i = 0; i < performDataDecoded.length; i++) {
            PerformData memory performDataIndividual = performDataDecoded[i];
            if (performDataIndividual.orderType == OrderType.ByPass) continue;
            // if number of grid are 5, it means that we could have grids from 0 to 6
            Bot storage bot = bots[performDataIndividual.botId];
            if (bots[i].upper_range == 0 && bot.isCancelled) continue;
            // check again if the order should be executed. To avoid malicious external requests
            OrderType checkedOrdertype;
            uint256 checkedNewGrid = calculateGrid(bot.grids, price);
            bool botNeedExecution;
            uint256 buyGrid;
            (botNeedExecution, checkedOrdertype, buyGrid) = checkOrderExecution(performDataIndividual.botId, checkedNewGrid, bot.currentGrid);
            if (!botNeedExecution) continue;

            uint256 amountToSwap;
            if(checkedOrdertype == OrderType.BuyOrder) {
                amountToSwap = (balances[performDataIndividual.botId][bot.tokenIn] * balanceToSpentBPS) / 10000;
                // autocancel bot
                if (amountToSwap < minimunAmountAllowed) {
                    bot.isCancelled = true;
                    continue;
                }
                executeOrder(checkedOrdertype, performDataIndividual.botId, amountToSwap, performDataIndividual.breachIndex, checkedNewGrid, price);
            }
            if(checkedOrdertype == OrderType.SellOrder) {
                amountToSwap = boughtBotAmounts[performDataIndividual.botId][buyGrid];
                executeOrder(checkedOrdertype, performDataIndividual.botId, amountToSwap, buyGrid, checkedNewGrid, price);   
            }
            if (checkedOrdertype == OrderType.UpdateCurrentGrid) {
                bot.currentGrid = performDataIndividual.breachIndex;
            }
            bot.lastExecutionTime = block.timestamp;
        }
    }

    function executeOrder(OrderType _ordertype, uint256 _botId, uint256 _amountToSwap, uint256 _breachIndex, uint256 _newGrid, uint256 _price) internal {
        if (_ordertype == OrderType.BuyOrder) {
            uint256 qty = swapExactInputSingle(_amountToSwap, bots[_botId].tokenIn, bots[_botId].tokenOut);
            balances[_botId][bots[_botId].tokenIn] -= _amountToSwap;
            balances[_botId][bots[_botId].tokenOut] += qty;
            bots[_botId].buyCounter++;
            breachedBotGrids[_botId][_breachIndex] = true;
            boughtBotAmounts[_botId][_breachIndex] = qty; // store WETH that bot has gathered as a profit swap
            bots[_botId].currentGrid = _breachIndex;
            emit OrderExecuted(bots[_botId].user, _botId, _ordertype, _breachIndex, qty, _price, block.timestamp);
        } else if(_ordertype == OrderType.SellOrder) {
            uint256 qty = swapExactInputSingle(_amountToSwap, bots[_botId].tokenOut, bots[_botId].tokenIn);
            balances[_botId][bots[_botId].tokenIn] += qty;
            balances[_botId][bots[_botId].tokenOut] -= _amountToSwap;
            bots[_botId].sellCounter++;
            delete breachedBotGrids[_botId][_breachIndex];
            delete boughtBotAmounts[_botId][_breachIndex];
            bots[_botId].currentGrid = _newGrid;
            emit OrderExecuted(bots[_botId].user, _botId, _ordertype, _breachIndex, qty, _price, block.timestamp);
        }
    }


    function swapExactInputSingle(uint256 amountIn, address tin , address tout) internal returns (uint256 amountOut)
    {
        IERC20(tin).approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn:  tin,
                tokenOut: tout,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
    }
    
    function withdraw(uint256 _amount, uint256 botId, address token) public {
        require(msg.sender == bots[botId].user, "Only owner can withdraw");
        require(balances[botId][token] >= _amount, "Insufficient balance");
        require(IERC20(token).balanceOf(address(this)) >= _amount, "Insufficient balance");        
        IERC20(token).transfer(msg.sender, _amount);
        balances[botId][token] -= _amount;
        if (balances[botId][token] < minToDelete) {
            bots[botId].isCancelled = true;
        }
    }

    function getDecimals() internal view returns (uint8) {
        return priceFeed.decimals();
    }

    function getOraclePrice() public view returns (int) {
        (
            /* uint80 roundID */,
            int _price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return _price;
    }

    function getScaledPrice() internal view returns (uint256) {
        int _price = getOraclePrice();
        uint8 decimals = getDecimals();
        uint256 convertedPrice = uint256(_price) / (10**uint256(decimals));
        return convertedPrice;
    }

     // function to cancel/resume bot execution
    function toggleBot(uint256 botIndex) external {
        require(bots[botIndex].user == msg.sender, "Only user can toogle");
        bots[botIndex].isCancelled = !bots[botIndex].isCancelled;
    }

    function deleteBot(uint256 botIndex) external {
        require(bots[botIndex].user == msg.sender, "Only user can toogle");
        require(balances[botIndex][bots[botIndex].tokenIn] < minToDelete, "Balance should be 0");
        require(balances[botIndex][bots[botIndex].tokenOut] < minToDelete, "Balance should be 0");
        delete bots[botIndex];
    }

    function deposit(uint256 _amount, uint256 _botId) external {
        Bot memory bot = bots[_botId];
        IERC20(bot.tokenIn).transferFrom(msg.sender, address(this), _amount);
        balances[_botId][bot.tokenIn] += _amount;
        emit Deposit(msg.sender, _botId, _amount);
    }
    
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}