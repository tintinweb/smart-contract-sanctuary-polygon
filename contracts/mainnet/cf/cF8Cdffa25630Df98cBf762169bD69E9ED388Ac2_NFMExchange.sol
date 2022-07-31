/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// LIBRARIES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// SAFEMATH its a Openzeppelin Lib. Check out for more info @ https://docs.openzeppelin.com/contracts/2.x/api/math
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INTERFACES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getController() external pure returns (address);

    function _getNFM() external pure returns (address);

    function _getTimer() external pure returns (address);

    function _getDistribute() external pure returns (address);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMORACLE
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmOracle {
    function _getLatestPrice(address coin) external view returns (uint256);

}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IUNISWAPV2ROUTER01
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IUNISWAPV2ROUTER02
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IUNISWAPV2PAIR
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IUniswapV2Pair {
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
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IUNISWAPV2FACTORY
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMExchange.sol
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice This contract is a decentralized exchange for the NFM token. This contract enables any trading of ERC20 tokens.
/// @dev This DEX is based on the ERC20 standard
///            INFO:
///            In order for this contract to function smoothly, it is necessary to integrate the following interfaces:
///
///             -   Controller
///             -   IERC20
///             -   UniswapV2Router01
///             -   UniswapV2Router02
///             -   UniswapV2Pair
///             -   UniswapV2Factory
///
///             PARTICULARITIES:
///             -   Dex allows 2 modes:
///                     - Fixed price sale (Presale mode)
///                     - Dynamic sale (Price changes based on the markets)
///             -   Any number of currencies can be added to the exchange. As long as these currencies have the ERC20 standard
///             -   For security reasons (FlashLoan Attack on AMM), this contract uses 3 price oracles:
///                     - Uniswap Price
///                     - Onchain Oracle
///                     - Offchain Oracle
///             -   PreSale mode enables:
///                     - Fixed Sale Price
///                     - Fixed supply
///                     - Minimum purchase amount
///                     - Maximum purchase amount
///                     - Time limit
///                     - Trade free of charge
///                     - Free from price manipulations
///             -   Dynamic mode enables:
///                     - Fixed supply
///                     - Minimum purchase amount
///                     - Maximum purchase amount
///                     - Free from price manipulations
///                     - Trade free of charge
///             -   By exchanging currencies, an integrated onchain oracle in the contract is filled with prices. This oracle can later be used
///                 for other interfaces to avoid price manipulations.
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMExchange {
    //include SafeMath
    using SafeMath for uint256;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    INfmController private _Controller;
    address private _SController;
    address private _Owner;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    _isFixedPrice                   => boolean whether the trade should be executed with a fixed price or a dynamic price
    _PriceVsUSD                   => fixed selling price in USD if fixed price mode is set to true
    _OracleTimer                   => Time interval for entering prices into the onchain oracle
    _PreSaleMode                 => Sales mode, whether presale or dynamic
    _PreSaleStart                   => Countdown for presale mode
    _PreSaleEnd                   => Timestamp when the presale ends
    _PreSaleDexAmount       => PreSale total amount
    _CurrencyCounter           => currency counter
    _CurrencyArray               => Address list of all approved ERC20 tokens for exchange
    _USDC                            => Address of the USDC token
    _uniswapV2Router          => Address of the UniswapV2Router
    _MinUSD                         => Minimum trade amount in USD
    _MaxUSD                        => Maximum trade amount in USD
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    bool private _isFixedPrice = false;
    uint256 private _PriceVsUSD;
    uint256 private _OracleTimer;
    bool private _PreSaleMode = false;
    uint256 private _PreSaleStart;
    uint256 private _PreSaleEnd;
    uint256 private _PreSaleDexAmount;
    uint256 private _CurrencyCounter;
    address[] private _CurrencyArray;
    address private _USDC;
    address private _OracleAdr;
    address private _uniswapV2Router =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    uint256 private _MinUSD = 10 * 10**18;
    uint256 private _MaxUSD = 500000 * 10**18;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    _isCurrencyAllowed (Currency address, true if allowed false if not allowed);
    _Oracle (Currency address, price in USD);
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(address => bool) public _isCurrencyAllowed;
    mapping(address => uint256[]) public _Oracle;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTRACT EVENTS
    Trade(Buyer address, Coin address, Currency amount, NFM amount, Timestamp);
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    event Trade(
        address indexed Sender,
        address indexed Coin,
        uint256 Amount,
        uint256 NFM,
        uint256 Time
    );
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MODIFIER
    onlyOwner       => Only Controller listed Contracts and Owner can interact with this contract.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier onlyOwner() {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        _;
    }

    constructor(
        address Controller,
        address USDC,
        address OracleAdr
    ) {
        _Owner = msg.sender;
        INfmController _Cont = INfmController(address(Controller));
        _SController = Controller;
        _Controller = _Cont;
        _USDC = USDC;
        _CurrencyArray.push(USDC);
        _CurrencyCounter++;
        _isCurrencyAllowed[USDC] = true;
        _OracleTimer = block.timestamp + 3600;
        _OracleAdr = OracleAdr;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @setFixedPrice(uint256 FixedUSDPrice, bool OnOff) returns (bool);
    This function enables the fixed price mode
    USD Price against NFM needs to be in 18 digits format 
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function setFixedPrice(uint256 FixedUSDPrice, bool OnOff)
        public
        onlyOwner
        returns (bool)
    {
        _isFixedPrice = OnOff;
        _PriceVsUSD = FixedUSDPrice;
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @returnAllowedCurrencies(address Coin) returns (bool);
    This function is for checking a currency if it is eligible for trading
    Returns true if Currency is allowed 
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnAllowedCurrencies(address Coin) public view returns (bool) {
        return _isCurrencyAllowed[Coin];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @returnCurrenciesArray() returns (address);
    This function returns a list of all currencies.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnCurrenciesArray()
        public
        view
        returns (address[] memory Arr)
    {
        return _CurrencyArray;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @onOffPresale(bool Mode, uint256 DaysStart, uint256 DaysEnd, uint256 PresaleAmount) returns (bool);
    This function allows you to activate and deactivate the presale mode
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function onOffPresale(
        bool Mode,
        uint256 DaysStart,
        uint256 DaysEnd
    ) public onlyOwner returns (bool) {
        if (Mode == true) {
            _PreSaleMode = Mode;
            _PreSaleStart = block.timestamp + (3600 * 24 * DaysStart);
            _PreSaleEnd = block.timestamp + (3600 * 24 * (DaysEnd + DaysStart));
            _PreSaleDexAmount = IERC20(address(_Controller._getNFM()))
                .balanceOf(address(this));
        } else {
            _PreSaleMode = Mode;
            _PreSaleStart = 0;
            _PreSaleEnd = 0;
            _PreSaleDexAmount = 0;
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @returnRemainPresaleAmount() returns (uint256, bool);
    This function returns the remaining presale amount.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnRemainPresaleAmount() public view returns (uint256, bool) {
        if (_PreSaleMode == true) {
            return (
                IERC20(address(_Controller._getNFM())).balanceOf(address(this)),
                true
            );
        } else {
            return (0, false);
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @returnInicialandSold() returns (uint256, uint256, bool);
    This function returns the inicial presale amount and and the amount sold.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnInicialandSold()
        public
        view
        returns (
            uint256 Inicial,
            uint256 Sold,
            bool
        )
    {
        if (_PreSaleMode == true) {
            if (
                _PreSaleDexAmount <
                IERC20(address(_Controller._getNFM())).balanceOf(address(this))
            ) {
                return (0, 0, true);
            } else {
                return (
                    _PreSaleDexAmount,
                    SafeMath.sub(
                        _PreSaleDexAmount,
                        IERC20(address(_Controller._getNFM())).balanceOf(
                            address(this)
                        )
                    ),
                    true
                );
            }
        } else {
            return (0, 0, false);
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @returnPresaleTimers() returns (uint256, uint256, bool);
    This function returns the timestamp of the presale
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnPresaleTimers()
        public
        view
        returns (
            uint256 Start,
            uint256 End,
            bool Check
        )
    {
        if (_PreSaleMode == false) {
            return (0, 0, false);
        } else {
            return (_PreSaleStart, _PreSaleEnd, true);
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @setMinMaxUSD(uint256 Min, uint256 Max) returns (bool);
    This function sets the minimum and maximum amount for trading
    Amounts must be specified in USD and in 18 digit format
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function setMinMaxUSD(uint256 Min, uint256 Max)
        public
        onlyOwner
        returns (bool)
    {
        _MinUSD = Min;
        _MaxUSD = Max;
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @addOrDisableCoin(address Coin, bool Allow) returns (bool);
    This function is responsible for managing the currencies for exchange. New ones can be added or existing ones can be deactivated
    Add new Currency => Coin Address, true
    Deactivate Currency => Coin Address, false
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function addOrDisableCoin(address Coin, bool Allow)
        public
        onlyOwner
        returns (bool)
    {
        if (Allow == false) {
            _isCurrencyAllowed[Coin] = false;
        } else {
            _CurrencyArray.push(Coin);
            _CurrencyCounter++;
            _isCurrencyAllowed[Coin] = true;
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @createPairUv2(address Coin) returns (bool);
    This function is for inicialising or creating the uniswap pairs.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function createPairUv2(address Coin) public onlyOwner returns (bool) {
        IUniswapV2Factory(IUniswapV2Router02(_uniswapV2Router).factory())
            .createPair(
                address(_Controller._getNFM()),
                address(
                    Coin /*COIN ADDRESS */
                )
            );
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @updateSetFixedPrice() returns (bool);
    This function updates the fixed price if the dynamic price mode is activated.
    This mode should only be used if all 3 oracles exist. The NFM/USDC pair must exist on Uniswap oracle before it can be used.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function updateSetFixedPrice() internal onlyOwner returns (bool) {
        uint256 O2Price = checkOracle2Price(address(_Controller._getNFM()));
        uint256 MinPus = SafeMath.sub(
            _PriceVsUSD,
            SafeMath.div(SafeMath.mul(_PriceVsUSD, 3), 100)
        );
        uint256 MaxPus = SafeMath.add(
            _PriceVsUSD,
            SafeMath.div(SafeMath.mul(_PriceVsUSD, 3), 100)
        );
        if (O2Price != 0) {
            if (O2Price > MaxPus) {
                _PriceVsUSD = MaxPus;
            } else if (O2Price < MinPus) {
                _PriceVsUSD = MinPus;
            } else {
                _PriceVsUSD = O2Price;
            }
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @checkOracle1Price(address Coin) returns (uint256);
    This function checks the current price of the integrated onChain Oracle.
    The return value is a USD price in 18 digit format
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function checkOracle1Price(address Coin) public view returns (uint256) {
        uint256 Prounds = _Oracle[Coin].length;
        uint256 RoundCount = 0;
        uint256 sum = 0;
        if (Prounds > 10) {
            for (uint256 i = Prounds - 10; i < Prounds; i++) {
                sum += _Oracle[Coin][i];
                RoundCount++;
            }
        } else {
            for (uint256 i = 0; i < Prounds; i++) {
                sum += _Oracle[Coin][i];
                RoundCount++;
            }
        }
        sum = SafeMath.div(sum, RoundCount);

        return sum;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @checkOracle2Price(address Coin) returns (uint256);
    This function checks the current price of the UniswapV2 Oracle.
    The return value is a USD price in 18 digit format
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function checkOracle2Price(address Coin) public view returns (uint256) {
        address UniPair = IUniswapV2Factory(
            IUniswapV2Router02(address(_uniswapV2Router)).factory()
        ).getPair(Coin, _USDC);
        if (UniPair != address(0)) {
            IUniswapV2Pair pair = IUniswapV2Pair(UniPair);
            IERC20 token1 = IERC20(pair.token1());
            (uint256 Res0, uint256 Res1, ) = pair.getReserves();
            // decimals
            uint256 res0 = Res0 * (10**token1.decimals());
            uint256 make = SafeMath.mul(SafeMath.div(res0, Res1), 10**12);

            return make;
        } else {
            return 0;
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @setPriceOracle(address Coin, uint256[] memory Price) returns (bool);
    This function adds new prices to the onChain Oracle.
    The prices are saved as USD prices and in 18 digit format
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function setPriceOracle(address Coin, uint256[] memory Price)
        public
        onlyOwner
        returns (bool)
    {
        if (Price.length > 1) {
            _Oracle[Coin] = Price;
        } else {
            _Oracle[Coin].push(Price[0]);
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @calcNFMAmount(address Coin,uint256 amount,uint256 offchainOracle) returns (bool,uint256,uint256,bool,bool);
    This function calculates the NFM amount to exchange against the trade currency
    Amount must be passed in the currency format of the respective trading currency. (Example 10 USDC => 10000000 USDC)
    The offchain oracle price must be passed in 6 digit format (Example 125,25 US$ => 125250000 US$). If the price of the offchain 
    oracle is 0, the median price is automatically determined
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function calcNFMAmount(
        address Coin,
        uint256 amount,
        uint256 offchainOracle
    )
        public
        view
        returns (
            bool check,
            uint256 NFMsAmount,
            uint256 MedianPrice,
            bool MaxPrice,
            bool MinPrice
        )
    {
        uint256 NFMs;
        uint256 CoinDecimals = IERC20(address(Coin)).decimals();
        if (CoinDecimals < 18) {
            amount = amount * 10**(SafeMath.sub(18, CoinDecimals));
        }
        offchainOracle = offchainOracle * 10**12;
        uint256 Oracle2;
        if (Coin == _USDC) {
            Oracle2 = 1 * 10**18;
        } else {
            Oracle2 = checkOracle2Price(Coin);
        }

        uint256 Oracle = checkOracle1Price(Coin);
        //Calculate pricerange
        uint256 median;
        if (offchainOracle == 0 && Oracle2 == 0) {
            median = Oracle;
        } else if (offchainOracle == 0 && Oracle2 > 0) {
            median = SafeMath.div(SafeMath.add(Oracle2, Oracle), 2);
        } else {
            median = SafeMath.div(
                SafeMath.add(SafeMath.add(offchainOracle, Oracle2), Oracle),
                3
            );
        }
        //Allow max 3% Price Change downside
        uint256 MinRange = SafeMath.sub(
            Oracle,
            SafeMath.div(SafeMath.mul(Oracle, 3), 100)
        );
        //Allow max 3% Price Change upside
        uint256 MaxRange = SafeMath.add(
            Oracle,
            SafeMath.div(SafeMath.mul(Oracle, 3), 100)
        );

        //Check if MedianPrice is in Range
        if (median > MaxRange) {
            median = MaxRange;
        } else if (median < MinRange) {
            median = MinRange;
        } else {
            median = median;
        }
        uint256 MulAmount = SafeMath.mul(amount, median);
        //Calculate NFM Amount on USD Price;
        uint256 FullUSDAmount = SafeMath.div(MulAmount, 10**18);
        bool MaxVal = true;
        bool MinVal = true;
        if (FullUSDAmount > _MaxUSD) {
            MaxVal = false;
        }
        if (FullUSDAmount < _MinUSD) {
            MinVal = false;
        }
        NFMs = SafeMath.div(SafeMath.mul(FullUSDAmount, 10**18), _PriceVsUSD);

        return (true, NFMs, median, MaxVal, MinVal);
        ///NOW TRANSFER
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @SwapCoinVsNFM(address Coin, uint256 amount, uint256 offchainOracle) returns (bool);
    This function performs the swap.
    Amount must be passed in the currency format of the respective trading currency. (Example 10 USDC => 10000000 USDC)
    The offchain oracle price must be passed in 6 digit format (Example 125,25 US$ => 125250000 US$). If the price of the offchain 
    oracle is 0, the median price is automatically determined
                ***Before this function can be executed. Buyer must approve the amount to be exchanged to this contract.***
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function SwapCoinVsNFM(
        address Coin,
        uint256 amount,
        uint256 offchainOracle
    ) public returns (bool) {
        require(_isCurrencyAllowed[Coin] == true, "!C");
        uint256 latestprice = INfmOracle(_OracleAdr)._getLatestPrice(Coin);
        if (latestprice > 0) {
            offchainOracle = SafeMath.div(offchainOracle + latestprice, 2);
        }
        if (_PreSaleMode == true) {
            require(
                _PreSaleStart < block.timestamp &&
                    _PreSaleEnd > block.timestamp,
                "OoT"
            );
        }
        require(
            IERC20(address(Coin)).allowance(msg.sender, address(this)) >=
                amount,
            "<A"
        );

        (
            ,
            uint256 NFMsAmount,
            uint256 MedianPrice,
            bool MaxPrice,
            bool MinPrice
        ) = calcNFMAmount(Coin, amount, offchainOracle);
        require(MaxPrice == true, ">EA");
        require(MinPrice == true, "<EA");
        require(
            NFMsAmount <=
                IERC20(address(_Controller._getNFM())).balanceOf(address(this)),
            "<NFM"
        );
        if (block.timestamp > _OracleTimer) {
            _Oracle[Coin].push(MedianPrice);
            _OracleTimer = _OracleTimer + 3600;

            if (_isFixedPrice == false) {
                updateSetFixedPrice();
            }
        }
        require(
            IERC20(address(Coin)).transferFrom(
                msg.sender,
                address(this),
                amount
            ) == true,
            "<A"
        );
        require(
            IERC20(address(_Controller._getNFM())).transfer(
                msg.sender,
                NFMsAmount
            )
        );
        emit Trade(msg.sender, Coin, amount, NFMsAmount, block.timestamp);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @withdraw(address Coin, address To, uint256 amount, bool percent) returns (bool);
    This function is responsible for the withdraw.
    There are 3 ways to initiate payouts. Either as a fixed amount, the full amount or a percentage of the balance.
    Fixed Amount    =>   Address Coin, Address Receiver, Fixed Amount, false
    Total Amount     =>   Address Coin, Address Receiver, 0, false
    A percentage     =>   Address Coin, Address Receiver, percentage, true
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function withdraw(
        address Coin,
        address To,
        uint256 amount,
        bool percent
    ) public onlyOwner returns (bool) {
        require(To != address(0), "0A");
        uint256 CoinAmount = IERC20(address(Coin)).balanceOf(address(this));
        if (percent == true) {
            //makeCalcs on Percentatge
            uint256 AmountToSend = SafeMath.div(
                SafeMath.mul(CoinAmount, amount),
                100
            );
            IERC20(address(Coin)).transfer(To, AmountToSend);
            return true;
        } else {
            if (amount == 0) {
                IERC20(address(Coin)).transfer(To, CoinAmount);
            } else {
                IERC20(address(Coin)).transfer(To, amount);
            }
            return true;
        }
    }
}