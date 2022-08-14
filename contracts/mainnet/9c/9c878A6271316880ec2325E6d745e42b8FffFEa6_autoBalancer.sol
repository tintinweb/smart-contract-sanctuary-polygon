pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
//import statements go here
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract autoBalancer is KeeperCompatibleInterface {
    address public constant USDC_ADDRESS = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    
    address public constant WMATIC_ADDRESS = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant QUICK_ADDRESS = 0xB5C064F955D8e7F38fE0460C556a72987494eE17;
    address public constant WETH_ADDRESS = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address public constant WBTC_ADDRESS = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;

    address public constant MATIC_USD_ORACLE = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
    address public constant BTC_USD_ORACLE = 0xc907E116054Ad103354f2D350FD2514433D57F6f;
    address public constant ETH_USD_ORACLE = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
    address public constant QUICK_USD_ORACLE = 0xa058689f4bCa95208bba3F265674AE95dED75B6D;

    address[] public USDCToWMATICPath = [USDC_ADDRESS, WMATIC_ADDRESS];
    address[] public USDCToQUICKPath = [USDC_ADDRESS, QUICK_ADDRESS];
    address[] public USDCToWETHPath = [USDC_ADDRESS, WETH_ADDRESS];
    address[] public USDCToWBTCPath = [USDC_ADDRESS, WBTC_ADDRESS];

    address[] public WMATICToUSDCPath = [WMATIC_ADDRESS, USDC_ADDRESS];
    address[] public QUICKToUSDCPath = [QUICK_ADDRESS, USDC_ADDRESS];
    address[] public WETHToUSDCPath = [WETH_ADDRESS, USDC_ADDRESS];
    address[] public WBTCToUSDCPath = [WBTC_ADDRESS, USDC_ADDRESS];

    address public constant QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    
    uint256 public totalNumberOfShares;
    uint256 public lastTimeStamp;
    uint256 public interval;
    uint256 public counter;

    mapping(address => uint256) public userNumberOfShares; 

    IUniswapV2Router02 public quickSwapRouter = IUniswapV2Router02(QUICKSWAP_ROUTER);

    struct Coin {
        string symbol;
        address tokenAddress;
        address oracleAddress;
        // uint256 decimals;
        int256 balance;
        int256 usd_balance;
        int256 diff_from_average;
        int256 usd_exchange_rate;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice(address _oracle_address) public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_oracle_address).latestRoundData();
        return price;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // this is where I need to do off chain calcs to be fed into the rebalance
        Coin[] memory array_coins = new Coin[](4);
    
        Coin memory wmatic;
        wmatic.tokenAddress = WMATIC_ADDRESS;
        wmatic.oracleAddress = MATIC_USD_ORACLE;
        Coin memory quick;
        quick.tokenAddress = QUICK_ADDRESS;
        quick.oracleAddress = QUICK_USD_ORACLE;
        Coin memory wbtc;
        wbtc.tokenAddress = WBTC_ADDRESS;
        wbtc.oracleAddress = BTC_USD_ORACLE;
        Coin memory weth;
        weth.tokenAddress = WETH_ADDRESS;
        weth.oracleAddress = ETH_USD_ORACLE;

        array_coins[0] = wmatic;
        array_coins[1] = quick;
        array_coins[2] = wbtc;
        array_coins[3] = weth;
        
        int256 total_in_usd = 0;
        int no_of_assets = int256(array_coins.length);

        for (uint i = 0; i < array_coins.length; i++) {
            IERC20 coin_instance = IERC20(array_coins[i].tokenAddress);
            array_coins[i].balance = int256(coin_instance.balanceOf(address(this)));
            array_coins[i].usd_exchange_rate = getLatestPrice(array_coins[i].oracleAddress);
            // array_coins[i].decimals = getDecimals(array_coins[i].address);
            array_coins[i].usd_balance = array_coins[i].balance * array_coins[i].usd_exchange_rate / (10 ** 8); //do I need to reintroduce decimals here?
            total_in_usd += array_coins[i].usd_balance;
        }

        int256 target_per_asset = total_in_usd / no_of_assets;

        for (uint i = 0; i < array_coins.length; i++) {
            array_coins[i].diff_from_average = array_coins[i].usd_balance - target_per_asset;
        }

        // Coin memory max_coin = find_max(array_coins);
        int256 maxDiff; // default 0, the lowest value of `uint256`
        uint8 maxCoin_index;
        for (uint8 i = 0; i < array_coins.length; i++) {
            if (array_coins[i].diff_from_average > maxDiff) {
                maxCoin_index = i;
            }
        }
        // Coin memory min_coin = find_min(array_coins);
        int256 minDiff = type(int256).max; // the highest value of int256
        uint8 minCoin_index;
        for (uint8 i = 0; i < array_coins.length; i++) {
            if (array_coins[i].diff_from_average < minDiff) {
                minCoin_index = i;
            }
        }

        address[] memory path1 = new address[](2);
        path1[0] = array_coins[maxCoin_index].tokenAddress;
        path1[1] = array_coins[minCoin_index].tokenAddress;
        int256 amount1;
        if (array_coins[maxCoin_index].diff_from_average > abs(array_coins[minCoin_index].diff_from_average)) {
            amount1 = abs(array_coins[minCoin_index].diff_from_average);
        } else {
            amount1 = array_coins[maxCoin_index].diff_from_average;
        }

        performData = abi.encode(path1, amount1); //, path2, amount2, path3, amount3
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;
            // this is where I actually do the rebalance on chain
            address[] memory path1 = new address[](2);
            uint256 amount1;
            (path1, amount1)= abi.decode(performData, (address[], uint256)); //, path2, amount2, path3, amount3
            swap(amount1, uint256(0), path1, address(this), 99999999999);
            }
            // The performData is generated by the Keeper's call to your checkUpkeep function
    }

    function find_max(Coin[] memory coin_array) internal pure returns (Coin memory maxCoin) {
                require(coin_array.length > 0); // throw an exception if the condition is not met
                int256 maxDiff; // default 0, the lowest value of `uint256`

                for (uint256 i = 0; i < coin_array.length; i++) {
                    if (coin_array[i].diff_from_average > maxDiff) {
                        maxCoin = coin_array[i];
                    }
                }
                return maxCoin;
            }

    function find_min(Coin[] memory coin_array) internal pure returns (Coin memory minCoin) {
                require(coin_array.length > 0); // throw an exception if the condition is not met
                int256 minDiff = type(int256).max; // default 0, the lowest value of `uint256`

                for (uint256 i = 0; i < coin_array.length; i++) {
                    if (coin_array[i].diff_from_average < minDiff) {
                        minCoin = coin_array[i];
                    }
                }
                return minCoin;
            }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    function updateSharesOnWithdrawal(address user) public { //make this ownable - only contract itself can update this?
        require (userNumberOfShares[user] > 0, "Error - This user has no shares");
        totalNumberOfShares -= userNumberOfShares[user];
        userNumberOfShares[user] = 0;
    }

    function getUserShares(address user) public view returns (uint256 userShares) {
        return userNumberOfShares[user];
    }

    function approve_spending (address token_address, address spender_address, uint256 amount_to_approve) public {
            IERC20(token_address).approve(spender_address, amount_to_approve);
    }
    
    receive() external payable {
    }

    function depositUserFunds (uint256 amount_) public  {
        IERC20(USDC_ADDRESS).transferFrom(msg.sender, address(this), amount_);

        uint256 WMATIC_balanceInUSD = getUSDTokenBalanceOf(WMATIC_ADDRESS, MATIC_USD_ORACLE, 18);
        uint256 QUICK_balanceInUSD = getUSDTokenBalanceOf(QUICK_ADDRESS, QUICK_USD_ORACLE, 18);
        uint256 WETH_balanceInUSD = getUSDTokenBalanceOf(WETH_ADDRESS, ETH_USD_ORACLE, 18);
        uint256 WBTC_balanceInUSD = getUSDTokenBalanceOf(WBTC_ADDRESS, BTC_USD_ORACLE, 8);

        uint256 Total_in_USD = WMATIC_balanceInUSD + QUICK_balanceInUSD + WETH_balanceInUSD + WBTC_balanceInUSD;
        
        approve_spending(USDC_ADDRESS, QUICKSWAP_ROUTER, amount_);

        if (Total_in_USD > 0) {
            swapProportionately(WMATIC_balanceInUSD, QUICK_balanceInUSD, WETH_balanceInUSD, WBTC_balanceInUSD, Total_in_USD, amount_);
        } else {
            swapIntoFourEqualParts(amount_);
        }
        
        if (Total_in_USD > 0) {
            updateSharesOnDeposit(msg.sender, Total_in_USD, amount_);
        } else {
            setSharesFirstTime(msg.sender);
        }
    }

    function getUSDTokenBalanceOf(address token_address, address oracle_address, uint256 token_decimals) public view returns (uint256) {
        // uint256 token_decimals = ERC20(token_address).decimals();
        return tokenBalanceOf(token_address, address(this))
         * (uint256(getLatestPrice(oracle_address)))
         / (10**(token_decimals+2));
    }

    function swapProportionately(uint256 WMATIC_amount, uint256 QUICK_amount, uint256 WETH_amount, uint256 WBTC_amount, uint256 totalUSDAmount, uint256 depositAmount) public {
        uint256 WMATIC_share = WMATIC_amount * (depositAmount) / (totalUSDAmount); 
        uint256 QUICK_share = QUICK_amount * (depositAmount) / (totalUSDAmount);
        uint256 WETH_share = WETH_amount * (depositAmount) / (totalUSDAmount);
        uint256 WBTC_share = WBTC_amount * (depositAmount) / (totalUSDAmount);

        swap(WMATIC_share, uint256(0), USDCToWMATICPath, address(this), 99999999999);
        swap(QUICK_share, uint256(0), USDCToQUICKPath, address(this), 99999999999);
        swap(WETH_share, uint256(0), USDCToWETHPath, address(this), 99999999999);
        swap(WBTC_share, uint256(0), USDCToWBTCPath, address(this), 99999999999);
    }

    function swapIntoFourEqualParts(uint256 amount) public {
        swap(amount / 4, uint256(0), USDCToWMATICPath, address(this), 99999999999);
        swap(amount / 4, uint256(0), USDCToQUICKPath, address(this), 99999999999);
        swap(amount / 4, uint256(0), USDCToWETHPath, address(this), 99999999999);
        swap(amount / 4, uint256(0), USDCToWBTCPath, address(this), 99999999999);
    }

    function setSharesFirstTime(address user) public {
        userNumberOfShares[user] = 100000000;
        totalNumberOfShares = userNumberOfShares[user];
    }

    function updateSharesOnDeposit(address user, uint256 total_in_USD, uint256 deposit_amount) public { //make this ownable - only contract itself can update this?
        uint256 newSharesForUser = deposit_amount * (totalNumberOfShares) / (total_in_USD);
        totalNumberOfShares = totalNumberOfShares + newSharesForUser;
        if (userNumberOfShares[user] > 0) {
            userNumberOfShares[user] = userNumberOfShares[user] + newSharesForUser;
        } else {
            userNumberOfShares[user] = newSharesForUser;
        }
    }

    function withdrawUserFunds(address user) public {
        //do I need an approval here?

        uint256 WMATIC_amount = userNumberOfShares[user] * (tokenBalanceOf(WMATIC_ADDRESS, address(this))) / (totalNumberOfShares);
        uint256 QUICK_amount = userNumberOfShares[user] * (tokenBalanceOf(QUICK_ADDRESS, address(this))) / (totalNumberOfShares);
        uint256 WETH_amount = userNumberOfShares[user] * (tokenBalanceOf(WETH_ADDRESS, address(this))) / (totalNumberOfShares);
        uint256 WBTC_amount = userNumberOfShares[user] * (tokenBalanceOf(WBTC_ADDRESS, address(this))) / (totalNumberOfShares);

        approve_spending(WMATIC_ADDRESS, QUICKSWAP_ROUTER, WMATIC_amount);
        approve_spending(QUICK_ADDRESS, QUICKSWAP_ROUTER, QUICK_amount);
        approve_spending(WETH_ADDRESS, QUICKSWAP_ROUTER, WETH_amount);
        approve_spending(WBTC_ADDRESS, QUICKSWAP_ROUTER, WBTC_amount);

        swapBackToUSDC(WMATIC_ADDRESS, WMATIC_amount);
        swapBackToUSDC(QUICK_ADDRESS, QUICK_amount);
        swapBackToUSDC(WETH_ADDRESS, WETH_amount);
        swapBackToUSDC(WBTC_ADDRESS, WBTC_amount);

        // approveSpendingWholeBalance(USDC_ADDRESS, BENTOBOX_MASTER_CONTRACT_ADDRESS);

        uint256 USDC_amount = tokenBalanceOf(USDC_ADDRESS, address(this));
        withdraw(USDC_amount, USDC_ADDRESS, user);

        updateSharesOnWithdrawal(user);
    }

    function withdraw(uint256 amount_, address token_address, address address_to) public  {
        IERC20 token_ = IERC20(token_address); //is this right?

        token_.transfer(address_to, amount_);
    }

    function approveSpendingWholeBalance(address _token, address _spender) public {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        approve_spending(_token, _spender, tokenBalance);
    }

    function swapBackToUSDC(address _token, uint256 _amount) public {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = USDC_ADDRESS;
        swap(_amount, uint256(0), path, address(this), 99999999999);
    }
    
    // function withdraw_matic(uint256 amount_) public payable {
    //     transfer(msg.sender, amount_);
    // }

    function tokenBalanceOf(address token_address, address user_address) public view returns (uint256 token_balance) {
        IERC20 _token = IERC20(token_address);
        token_balance = _token.balanceOf(user_address);
        return token_balance;
    }
    
    function swap(uint256 _amountIn, uint256 _amountOutMin, address[] memory _path, address _acct, uint256 _deadline) public {
        
       quickSwapRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _acct,
            _deadline);
        }
        
    }

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    
    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
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