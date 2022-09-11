pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
//import statements go here
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract autoBalancer is ERC20, KeeperCompatibleInterface {
    address public constant USDC_ADDRESS =
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    address public constant WMATIC_ADDRESS =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant SAND_ADDRESS =
        0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683;
    address public constant WETH_ADDRESS =
        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address public constant WBTC_ADDRESS =
        0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;

    address public constant MATIC_USD_ORACLE =
        0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
    address public constant BTC_USD_ORACLE =
        0xc907E116054Ad103354f2D350FD2514433D57F6f;
    address public constant ETH_USD_ORACLE =
        0xF9680D99D6C9589e2a93a78A04A279e509205945;
    address public constant SAND_USD_ORACLE =
        0x3D49406EDd4D52Fb7FFd25485f32E073b529C924;

    address[] public USDCToWMATICPath = [USDC_ADDRESS, WMATIC_ADDRESS];
    address[] public USDCToSANDPath = [USDC_ADDRESS, SAND_ADDRESS];
    address[] public USDCToWETHPath = [USDC_ADDRESS, WETH_ADDRESS];
    address[] public USDCToWBTCPath = [USDC_ADDRESS, WBTC_ADDRESS];

    address[] public WMATICToUSDCPath = [WMATIC_ADDRESS, USDC_ADDRESS];
    address[] public SANDToUSDCPath = [SAND_ADDRESS, USDC_ADDRESS];
    address[] public WETHToUSDCPath = [WETH_ADDRESS, USDC_ADDRESS];
    address[] public WBTCToUSDCPath = [WBTC_ADDRESS, USDC_ADDRESS];

    address public constant QUICKSWAP_ROUTER =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    uint256 public totalNumberOfShares;

    uint256 public lastTimeStamp;
    uint256 public interval = 3600;

    mapping(address => uint256) public userNumberOfShares;

    IUniswapV2Router02 public quickSwapRouter =
        IUniswapV2Router02(QUICKSWAP_ROUTER);

    struct Coin {
        string symbol;
        address tokenAddress;
        address oracleAddress;
        uint256 decimals;
        uint256 balance;
        uint256 usd_balance;
        int256 diff_from_average;
        uint256 usd_exchange_rate;
    }

    constructor() ERC20("autoBalancer", "ABA") {}

    function setInterval(uint256 new_interval) public {
        interval = new_interval;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice(address _oracle_address)
        public
        view
        returns (int256)
    {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_oracle_address).latestRoundData();
        return price;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        //we create the coin array and coin objects
        Coin[] memory array_coins = new Coin[](4);

        Coin memory wmatic;
        wmatic.tokenAddress = WMATIC_ADDRESS;
        wmatic.oracleAddress = MATIC_USD_ORACLE;
        Coin memory sand;
        sand.tokenAddress = SAND_ADDRESS;
        sand.oracleAddress = SAND_USD_ORACLE;
        Coin memory wbtc;
        wbtc.tokenAddress = WBTC_ADDRESS;
        wbtc.oracleAddress = BTC_USD_ORACLE;
        Coin memory weth;
        weth.tokenAddress = WETH_ADDRESS;
        weth.oracleAddress = ETH_USD_ORACLE;

        array_coins[0] = wmatic;
        array_coins[1] = sand;
        array_coins[2] = wbtc;
        array_coins[3] = weth;

        uint256 total_in_usd = 0;

        for (uint8 i = 0; i < array_coins.length; i++) {
            ERC20 coin_instance = ERC20(array_coins[i].tokenAddress);
            array_coins[i].balance = coin_instance.balanceOf(address(this));
            array_coins[i].usd_exchange_rate = uint256(
                getLatestPrice(array_coins[i].oracleAddress)
            );
            array_coins[i].decimals = uint256(coin_instance.decimals());
            uint256 decimal_conversion = 18 - array_coins[i].decimals;
            array_coins[i].usd_balance =
                (uint256(
                    array_coins[i].balance * array_coins[i].usd_exchange_rate
                ) * (10**decimal_conversion)) /
                (10**8);
            total_in_usd += array_coins[i].usd_balance;
        }

        for (uint8 i = 0; i < array_coins.length; i++) {
            array_coins[i].diff_from_average =
                int256(array_coins[i].usd_balance) -
                int256(total_in_usd / (array_coins.length));
        }

        int256 comparison_variable; // default 0, the lowest value of `uint256`
        uint8 maxCoin_index;
        uint8 minCoin_index;
        int256[] memory amounts = new int256[](array_coins.length - 1);
        address[] memory paths = new address[](2 * (array_coins.length - 1)); //this will take all n-1 paths eventually

        for (uint8 j = 0; j < array_coins.length - 1; j++) {
            // Coin memory max_coin = find_max(array_coins);
            for (uint8 i = 0; i < array_coins.length; i++) {
                if (
                    array_coins[i].diff_from_average != 0 &&
                    array_coins[i].diff_from_average > comparison_variable
                ) {
                    maxCoin_index = i;
                    comparison_variable = array_coins[i].diff_from_average;
                }
            }
            // Coin memory min_coin = find_min(array_coins);
            comparison_variable = type(int256).max; // the highest value of int256
            for (uint8 i = 0; i < array_coins.length; i++) {
                if (
                    array_coins[i].diff_from_average != 0 &&
                    array_coins[i].diff_from_average < comparison_variable
                ) {
                    minCoin_index = i;
                    comparison_variable = array_coins[i].diff_from_average;
                }
            }
            // we calculate the amount to be swapped, depending on which coin is further from average
            if (
                array_coins[maxCoin_index].diff_from_average >
                abs(array_coins[minCoin_index].diff_from_average) //maxCoin is further from average than minCoin
            ) {
                // so the amount we swap is minCoin's diff_from_average
                amounts[j] = abs(array_coins[minCoin_index].diff_from_average);
                // so we decrease maxCoin's average by that amount
                array_coins[maxCoin_index].diff_from_average -= amounts[j];
                // and set minCoin's diff to zero, so that it will be excluded from future loops
                array_coins[minCoin_index].diff_from_average = 0;
                // then we convert amounts[j] from usd to maxCoin currency (because we're always swapping from maxCoin)
                amounts[j] =
                    (amounts[j] * int256(10**8)) /
                    int256(array_coins[maxCoin_index].usd_exchange_rate) /
                    int256(
                        10**(18 - uint256(array_coins[maxCoin_index].decimals))
                    );
            } else {
                amounts[j] = abs(array_coins[maxCoin_index].diff_from_average);
                array_coins[minCoin_index].diff_from_average += amounts[j];
                array_coins[maxCoin_index].diff_from_average = 0;

                amounts[j] =
                    (amounts[j] * int256(10**8)) /
                    int256(array_coins[maxCoin_index].usd_exchange_rate) /
                    int256(
                        10**(18 - uint256(array_coins[maxCoin_index].decimals))
                    );
            }

            //we determine the paths that the swap will take (beginning and end)
            paths[2 * j] = array_coins[maxCoin_index].tokenAddress;
            paths[2 * j + 1] = array_coins[minCoin_index].tokenAddress;
        }

        performData = abi.encode(paths, amounts);
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            address[] memory paths;
            uint256[] memory amounts;
            address[] memory path_short = new address[](2);
            address[] memory path_long = new address[](3);

            (paths, amounts) = abi.decode(performData, (address[], uint256[]));
            for (uint8 i = 0; i < amounts.length; i++) {
                approve_spending(paths[2 * i], QUICKSWAP_ROUTER, amounts[i]);
                if (
                    paths[2 * i] == WMATIC_ADDRESS ||
                    paths[2 * i + 1] == WMATIC_ADDRESS
                ) {
                    path_short[0] = paths[2 * i];
                    path_short[1] = paths[2 * i + 1];
                    swap(
                        amounts[i],
                        uint256(0),
                        path_short,
                        address(this),
                        99999999999
                    );
                } else {
                    path_long[0] = paths[2 * i];
                    path_long[1] = WMATIC_ADDRESS;
                    path_long[2] = paths[2 * i + 1];
                    swap(
                        amounts[i],
                        uint256(0),
                        path_long,
                        address(this),
                        99999999999
                    );
                }
            }
        }
        // The performData is generated by the Keeper's call to your checkUpkeep function
    }

    function find_max(Coin[] memory coin_array)
        internal
        pure
        returns (Coin memory maxCoin)
    {
        require(coin_array.length > 0); // throw an exception if the condition is not met
        int256 maxDiff; // default 0, the lowest value of `uint256`

        for (uint256 i = 0; i < coin_array.length; i++) {
            if (coin_array[i].diff_from_average > maxDiff) {
                maxCoin = coin_array[i];
            }
        }
        return maxCoin;
    }

    function find_min(Coin[] memory coin_array)
        internal
        pure
        returns (Coin memory minCoin)
    {
        require(coin_array.length > 0); // throw an exception if the condition is not met
        int256 minDiff = type(int256).max; // default 0, the lowest value of `uint256`

        for (uint256 i = 0; i < coin_array.length; i++) {
            if (coin_array[i].diff_from_average < minDiff) {
                minCoin = coin_array[i];
            }
        }
        return minCoin;
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function updateSharesOnWithdrawal(address user) public {
        //make this ownable - only contract itself can update this?
        _burn(user, balanceOf(user));
    }

    function getUserShares(address user)
        public
        view
        returns (uint256 userShares)
    {
        return userNumberOfShares[user];
    }

    function approve_spending(
        address token_address,
        address spender_address,
        uint256 amount_to_approve
    ) public {
        ERC20(token_address).approve(spender_address, amount_to_approve);
    }

    receive() external payable {}

    function depositUserFunds(uint256 amount_) public {
        ERC20(USDC_ADDRESS).transferFrom(msg.sender, address(this), amount_);

        uint256 WMATIC_balanceInUSD = getUSDTokenBalanceOf(
            WMATIC_ADDRESS,
            MATIC_USD_ORACLE,
            18
        );
        uint256 SAND_balanceInUSD = getUSDTokenBalanceOf(
            SAND_ADDRESS,
            SAND_USD_ORACLE,
            18
        );
        uint256 WETH_balanceInUSD = getUSDTokenBalanceOf(
            WETH_ADDRESS,
            ETH_USD_ORACLE,
            18
        );
        uint256 WBTC_balanceInUSD = getUSDTokenBalanceOf(
            WBTC_ADDRESS,
            BTC_USD_ORACLE,
            8
        );

        uint256 Total_in_USD = WMATIC_balanceInUSD +
            SAND_balanceInUSD +
            WETH_balanceInUSD +
            WBTC_balanceInUSD;

        approve_spending(USDC_ADDRESS, QUICKSWAP_ROUTER, amount_);

        if (Total_in_USD > 0) {
            swapProportionately(
                WMATIC_balanceInUSD,
                SAND_balanceInUSD,
                WETH_balanceInUSD,
                WBTC_balanceInUSD,
                Total_in_USD,
                amount_
            );
        } else {
            swapIntoFourEqualParts(amount_);
        }

        if (Total_in_USD > 0) {
            updateSharesOnDeposit(msg.sender, Total_in_USD, amount_);
        } else {
            setSharesFirstTime(msg.sender, amount_);
        }
    }

    function getUSDTokenBalanceOf(
        address token_address,
        address oracle_address,
        uint256 token_decimals
    ) public view returns (uint256) {
        // uint256 token_decimals = ERC20(token_address).decimals();
        return
            (tokenBalanceOf(token_address, address(this)) *
                (uint256(getLatestPrice(oracle_address)))) /
            (10**(token_decimals + 2));
    }

    function swapProportionately(
        uint256 WMATIC_amount,
        uint256 SAND_amount,
        uint256 WETH_amount,
        uint256 WBTC_amount,
        uint256 totalUSDAmount,
        uint256 depositAmount
    ) public {
        uint256 WMATIC_share = (WMATIC_amount * (depositAmount)) /
            (totalUSDAmount);
        uint256 SAND_share = (SAND_amount * (depositAmount)) / (totalUSDAmount);
        uint256 WETH_share = (WETH_amount * (depositAmount)) / (totalUSDAmount);
        uint256 WBTC_share = (WBTC_amount * (depositAmount)) / (totalUSDAmount);

        swap(
            WMATIC_share,
            uint256(0),
            USDCToWMATICPath,
            address(this),
            99999999999
        );
        swap(
            SAND_share,
            uint256(0),
            USDCToSANDPath,
            address(this),
            99999999999
        );
        swap(
            WETH_share,
            uint256(0),
            USDCToWETHPath,
            address(this),
            99999999999
        );
        swap(
            WBTC_share,
            uint256(0),
            USDCToWBTCPath,
            address(this),
            99999999999
        );
    }

    function swapIntoFourEqualParts(uint256 amount) public {
        swap(
            amount / 4,
            uint256(0),
            USDCToWMATICPath,
            address(this),
            99999999999
        );
        swap(
            amount / 4,
            uint256(0),
            USDCToSANDPath,
            address(this),
            99999999999
        );
        swap(
            amount / 4,
            uint256(0),
            USDCToWETHPath,
            address(this),
            99999999999
        );
        swap(
            amount / 4,
            uint256(0),
            USDCToWBTCPath,
            address(this),
            99999999999
        );
    }

    function setSharesFirstTime(address user, uint256 deposit_amount) public {
        _mint(user, deposit_amount);
    }

    function updateSharesOnDeposit(
        address user,
        uint256 total_in_USD,
        uint256 deposit_amount
    ) public {
        //make this ownable - only contract itself can update this?
        uint256 newSharesForUser = (deposit_amount * (totalSupply())) /
            (total_in_USD);
        _mint(user, newSharesForUser);
    }

    function withdrawUserFunds(address user) public {
        //do I need an approval here?

        uint256 WMATIC_amount = (userNumberOfShares[user] *
            (tokenBalanceOf(WMATIC_ADDRESS, address(this)))) /
            (totalNumberOfShares);
        uint256 SAND_amount = (userNumberOfShares[user] *
            (tokenBalanceOf(SAND_ADDRESS, address(this)))) /
            (totalNumberOfShares);
        uint256 WETH_amount = (userNumberOfShares[user] *
            (tokenBalanceOf(WETH_ADDRESS, address(this)))) /
            (totalNumberOfShares);
        uint256 WBTC_amount = (userNumberOfShares[user] *
            (tokenBalanceOf(WBTC_ADDRESS, address(this)))) /
            (totalNumberOfShares);

        approve_spending(WMATIC_ADDRESS, QUICKSWAP_ROUTER, WMATIC_amount);
        approve_spending(SAND_ADDRESS, QUICKSWAP_ROUTER, SAND_amount);
        approve_spending(WETH_ADDRESS, QUICKSWAP_ROUTER, WETH_amount);
        approve_spending(WBTC_ADDRESS, QUICKSWAP_ROUTER, WBTC_amount);

        swapBackToUSDC(WMATIC_ADDRESS, WMATIC_amount);
        swapBackToUSDC(SAND_ADDRESS, SAND_amount);
        swapBackToUSDC(WETH_ADDRESS, WETH_amount);
        swapBackToUSDC(WBTC_ADDRESS, WBTC_amount);

        // approveSpendingWholeBalance(USDC_ADDRESS, BENTOBOX_MASTER_CONTRACT_ADDRESS);

        uint256 USDC_amount = tokenBalanceOf(USDC_ADDRESS, address(this));
        withdraw(USDC_amount, USDC_ADDRESS, user);

        updateSharesOnWithdrawal(user);
    }

    function withdraw(
        uint256 amount_,
        address token_address,
        address address_to
    ) public {
        ERC20 token_ = ERC20(token_address); //is this right?

        token_.transfer(address_to, amount_);
    }

    function approveSpendingWholeBalance(address _token, address _spender)
        public
    {
        uint256 tokenBalance = ERC20(_token).balanceOf(address(this));
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

    function tokenBalanceOf(address token_address, address user_address)
        public
        view
        returns (uint256 token_balance)
    {
        ERC20 _token = ERC20(token_address);
        token_balance = _token.balanceOf(user_address);
        return token_balance;
    }

    function swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _acct,
        uint256 _deadline
    ) public {
        quickSwapRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _acct,
            _deadline
        );
    }

    // function _mint(address account, uint256 amount) internal override {
    //     require(account != address(0), "ERC20: mint to the zero address");

    //     _beforeTokenTransfer(address(0), account, amount);

    //     _totalSupply = _totalSupply.add(amount);
    //     _balances[account] = _balances[account].add(amount);
    //     emit Transfer(address(0), account, amount);
    // }

    // function _burn(address account, uint256 amount) internal override {
    //     require(account != address(0), "ERC20: burn from the zero address");

    //     _beforeTokenTransfer(account, address(0), amount);

    //     _balances[account] = _balances[account].sub(
    //         amount,
    //         "ERC20: burn amount exceeds balance"
    //     );
    //     _totalSupply = _totalSupply.sub(amount);
    //     emit Transfer(account, address(0), amount);
    // }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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