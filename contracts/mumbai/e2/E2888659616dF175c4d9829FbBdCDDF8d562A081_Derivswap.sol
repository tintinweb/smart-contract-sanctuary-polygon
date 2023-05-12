//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./PythStructs.sol";
import "./DRVSStructs.sol";
import "./Orderbook.sol";
import "./IWETH9.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

interface IderivswapLiqManager {
    function mintNewPosition(
        uint256 amount0ToAdd,
        uint256 amount1ToAdd
    )
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function decreaseLiquidityCurrentRange()
        external
        returns (uint256 amount0, uint256 amount1);
}

interface IEarnBox {
    function inject_profit() external payable;
}

interface IPositionSwapRouter {
    function external_settle_order_cleanup(
        uint256 maker_order_id,
        uint256 taker_order_id
    ) external;
}

contract Derivswap {
    address public owner;
    int256 public protocol_earnings_native;
    mapping(address => uint256) protocol_earnings_by_asset;
    uint256 public eth_swapped_for_drvs;
    uint256 public earn_box_fees_injected;
    Orderbook public derivswap_orderbook;
    address public orderbook_address;
    ISwapRouter public immutable swapRouter;
    IERC20 public drvs;
    mapping(address => bool) public whitelisted_collateral;
    mapping(address => uint) public collateral_id;
    IUniswapV3Factory public unifactory;
    address public derivswapLiqManagerAddress;
    IderivswapLiqManager public derivswapLiqManager;
    IEarnBox public earnBox;
    IPositionSwapRouter public positionSwapRouter;
    uint256 initialLiqThreshold = 1 * (10 ** 17);
    bool public initialLiquidityPulled = false;
    bool public initialLiquidityProvided = false;
    address public pool_address;
    address public DRVS;
    address public WETH9;
    IWETH9 private weth;
    uint24 private constant poolFee = 3000;

    event NewMakerOrder(
        address _maker,
        uint256 _maker_order_ID,
        address _collateral,
        uint256 _amt,
        uint256 timestamp
    );
    event Taken(
        address _taker,
        uint256 _maker_order_ID,
        uint256 lockUpEnds,
        uint256 _timestamp
    );
    event Settled(
        address _settler,
        uint256 _taker_order_ID,
        uint256 _maker_order_ID,
        uint256 _winner_payout,
        uint256 _settler_fee,
        uint256 _maker_rebate,
        uint256 _protocol_p,
        address _collateral_profit,
        uint256 _timestamp
    );
    event Received(address, uint256);
    event SwappedForHedgex(
        uint256 amtInput,
        uint256 amtOutput,
        uint256 timestamp
    );
    event SwapFailure(uint256 _timestamp);
    event InitialLiquidityProvided(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    constructor(
        address _liquidityManager,
        address _hedgexTokenAddress,
        address payable _derivswap_orderbook,
        address _swapRouter,
        address _weth,
        address _uniFactory
    ) {
        //USDT:1,USDC:2,NATIVE:0
        address[2] memory whitelisted_coins = [
            0xAE91C872d378cFF75Ca099634487Bf94BF71CA94,
            0xb5896008024610447c3cf4d64D64b12AFF00Fd66
        ];
        for (uint i = 0; i < whitelisted_coins.length; i++) {
            whitelisted_collateral[whitelisted_coins[i]] = true;
            collateral_id[whitelisted_coins[i]] = i + 1;
            protocol_earnings_by_asset[whitelisted_coins[i]] = 0;
        }
        unifactory = IUniswapV3Factory(_uniFactory);
        WETH9 = _weth;
        weth = IWETH9(WETH9);
        swapRouter = ISwapRouter(_swapRouter);
        derivswapLiqManagerAddress = _liquidityManager;
        derivswapLiqManager = IderivswapLiqManager(_liquidityManager);
        DRVS = _hedgexTokenAddress;
        pool_address = unifactory.getPool(_hedgexTokenAddress, WETH9, 3000);
        drvs = IERC20(_hedgexTokenAddress);
        orderbook_address = _derivswap_orderbook;
        derivswap_orderbook = Orderbook(_derivswap_orderbook);
        owner = msg.sender;
        protocol_earnings_native = 0;
        eth_swapped_for_drvs = 0;
        earn_box_fees_injected = 0;
    }

    function owner_set_earn_box(address _earn_box) public {
        require(msg.sender == owner);
        earnBox = IEarnBox(_earn_box);
    }

    function owner_set_position_swap_router(address _swap_router) public {
        require(msg.sender == owner);
        positionSwapRouter = IPositionSwapRouter(_swap_router);
    }

    function protocol_claim_quarter_of_excess_profit() public {
        require(msg.sender == owner);
        require(protocol_earnings_native>0, "Protocol earnings native < 0");

        uint256 protocol_earnings_total = uint256(protocol_earnings_native);
        protocol_earnings_native -= int256(((uint256(protocol_earnings_native) -
            eth_swapped_for_drvs -
            earn_box_fees_injected) * 25) / 100);
        payable(owner).transfer(
            ((protocol_earnings_total -
                eth_swapped_for_drvs -
                earn_box_fees_injected) * 25) / 100
        );
    }

    //Create maker order. Earn 1% of match fee for doing so.
    function makeOrder(
        uint256 expiryType,
        uint256 expiryValue,
        int64 ratio,
        DRVSStructs.Leg[] memory legs,
        address collateral,
        uint256 alternative_collateral_amount
    ) public payable {
        if (collateral == address(0)) {
            require(
                msg.value != 0,
                "Value needs to be > 0 for native collateral."
            );
        } else {
            require(
                whitelisted_collateral[collateral] == true,
                "Collateral not supported."
            );
            IERC20 collateral_token = IERC20(collateral);
            uint256 allowance = collateral_token.allowance(
                msg.sender,
                address(this)
            );
            uint256 users_balance = collateral_token.balanceOf(msg.sender);
            require(
                users_balance >= alternative_collateral_amount,
                "ERC20 balance insufficient for chosen collateral asset."
            );
            require(
                allowance >= alternative_collateral_amount,
                "Insufficent allowance ERC-20."
            );
            bool success = collateral_token.transferFrom(
                msg.sender,
                address(this),
                alternative_collateral_amount
            );
            require(success, "Token transfer failed");
        }
        require(ratio != 0, "E03");
        require((ratio >= 100 || ratio <= -100), "E04");
        if (ratio <= -100) {
            require(
                ratio <= -110,
                "Minus money positions must be at minimum -110. If you're trying to place an even money position, use the +100 ratio instead."
            );
        }

        require(expiryType == 1 || expiryType == 2, "Invalid expiryType");
        if (expiryType == 2) {
            require(
                expiryValue > block.timestamp,
                "Can't pick an expiration date that has already passed."
            );
        } else {
            require(
                expiryValue > 100,
                "Expiry must be at least 100 seconds from the current time"
            );
            // Valid lock-up periods: (1 Hour, 1 Day, 1 Month)
            require(
                (expiryValue == 101 ||
                    expiryValue == 86400 ||
                    expiryValue == 604800),
                "E02"
            );
        }

        // Encode info to be passed to orderbook
        bytes memory gameInfoEncoded = abi.encode(
            msg.sender,
            collateral,
            collateral == address(0)
                ? msg.value
                : alternative_collateral_amount,
            expiryType,
            expiryValue,
            ratio
        );
        bytes memory legsEncoded = abi.encode(legs);

        // Create maker order on orderbook
        (
            address _sender,
            uint256 orderID,
            uint256 valueSent
        ) = derivswap_orderbook.orderbook_make_order(
                gameInfoEncoded,
                legsEncoded
            );
        emit NewMakerOrder(
            _sender,
            orderID,
            collateral,
            valueSent,
            block.timestamp
        );
    }

    //Match an exisiting maker-order.
    function takeOrder(
        uint256 makerOrderID,
        uint256 take_amount,
        bytes[] calldata priceUpdateData
    ) public payable {
        // Fetch pyth update fee (if maker order collateral type != adddress(0), wei balance may be insufficent to update! IMPORTANT)
        uint256 pyth_update_fee = derivswap_orderbook.pyth_update_fee(
            priceUpdateData
        );

        (, , address maker_order_collateral, , , , , ) = derivswap_orderbook
            .makerOrdersByID(makerOrderID);

        if (maker_order_collateral != address(0)) {
            require(
                msg.value == pyth_update_fee,
                "If collateral isn't native, pyth update fee payment is required."
            );
        }

        // Transfer pyth update fee to orderbook
        payable(orderbook_address).transfer(pyth_update_fee);

        if (maker_order_collateral == address(0)) {} else {
            IERC20 collateral_token = IERC20(maker_order_collateral);
            uint256 allowance = collateral_token.allowance(
                msg.sender,
                address(this)
            );
            require(
                allowance >= take_amount,
                "ERC20 allowance insufficient for chosen collateral asset."
            );
            uint256 users_balance = collateral_token.balanceOf(msg.sender);
            require(
                users_balance >= take_amount,
                "ERC20 balance insufficient for chosen collateral asset."
            );

            bool success = collateral_token.transferFrom(
                msg.sender,
                address(this),
                take_amount
            );
            require(success, "Token transfer failed");
        }

        // Encode info to be passed to orderbook
        bytes memory takerInfoEncoded = abi.encode(
            msg.sender,
            maker_order_collateral == address(0) ? msg.value : take_amount,
            makerOrderID
        );

        // Create taker order on orderbook
        (
            address sender,
            uint256 maker_order_ID,
            uint256 expiry,
            uint256 time_taken
        ) = derivswap_orderbook.orderbook_take_order(
                takerInfoEncoded,
                priceUpdateData
            );
        emit Taken(sender, maker_order_ID, expiry, time_taken);
    }

    //Settle order with expired lock-up period.
    function settleOrder(
        uint256 takerOrder_ID,
        bytes[] calldata priceUpdateData,
        bytes32[] calldata maker_leg_feed_ids
    ) public payable {
        // Fetch pyth update fee, transfer eth fee to orderbook where update will occur.
        uint256 pyth_update_fee = derivswap_orderbook.pyth_update_fee(
            priceUpdateData
        );
        (, , , , , uint256 makerOrderID, , ) = derivswap_orderbook
            .takerOrdersByID(takerOrder_ID);
        (, , address maker_order_collateral, , , , , ) = derivswap_orderbook
            .makerOrdersByID(makerOrderID);
        if (maker_order_collateral != address(0)) {
            require(
                msg.value == pyth_update_fee,
                "Msg.value must == pyth_update_fee if alternative collateral is set on the maker order."
            );
        }

        payable(orderbook_address).transfer(pyth_update_fee);

        // Encode calldata to pass to ordderbook
        bytes memory settleInfo = abi.encode(msg.sender, takerOrder_ID);

        // Place order on orderbook contract
        (
            DRVSStructs.MakerOrder memory maker,
            DRVSStructs.TakerOrder memory taker,
            DRVSStructs.Payout memory payout
        ) = derivswap_orderbook.orderbook_settle_order(
                settleInfo,
                priceUpdateData,
                maker_leg_feed_ids
            );

        uint256 protocol_profit;
        if (maker.collateral == address(0)) {
            protocol_profit = payout.protocol_profit - (pyth_update_fee);
            protocol_earnings_native =
                protocol_earnings_native +
                int256(protocol_profit);
        } else {
            protocol_profit = payout.protocol_profit;
            protocol_earnings_native =
                protocol_earnings_native - int256(pyth_update_fee);
        }

        //Position Swap Router Cleanup
        positionSwapRouter.external_settle_order_cleanup(
            maker.order_ID,
            taker.order_ID
        );

        if (maker.collateral == address(0)) {
            //DRVS Buyback function
            if (initialLiquidityProvided == true) {
                if (drvs.balanceOf(pool_address) > ((5 * (10 ** 18)))) {
                    //Uniswap V3 Swap ETH for DRVS. 1/4 of protocol's fee spent on buyback.
                    swapExactInputSingle(protocol_profit / 4);
                    eth_swapped_for_drvs += (protocol_profit / 4);
                } else {
                    //Halve Liquidity once DRVS balance in pool is less than 5 Tokens.
                    if (initialLiquidityPulled == false) {
                        halveLiquidity();
                    }
                }
                //TODO: Earn box, inject protocol_earnings_deducted / 4
                earnBox.inject_profit{value: protocol_profit / 4}();
                earn_box_fees_injected += (protocol_profit / 4);
            }
            if (protocol_earnings_by_asset[address(0)] >= initialLiqThreshold) {
                // LP Provide once protocol earnings (native token) >= initial threshold (public)
                if (initialLiquidityProvided == false) {
                    provideLiquidity();
                }
            }
            // Pay out Winner's Total
            payable(payout.winnerAddress).transfer(payout.winning_payout);
            // Pay out Settler Fee
            payable(msg.sender).transfer(payout.settler_fee);
            // Pay out Maker Fee
            if (payout.maker_rebate != 0) {
                payable(maker.user).transfer(payout.maker_rebate);
            }
        } else {
            IERC20 collateral_token = IERC20(maker.collateral);

            // Pay out Winner's Total
            collateral_token.transfer(
                payout.winnerAddress,
                payout.winning_payout
            );
            // Pay out Settler Fee
            collateral_token.transfer(msg.sender, payout.settler_fee);
            // Pay out Maker Fee
            if (payout.maker_rebate != 0) {
                collateral_token.transfer(maker.user, payout.maker_rebate);
            }
        }

        //Token Buyback Handler

        emit Settled(
            msg.sender,
            takerOrder_ID,
            taker.makerOrder_ID,
            payout.winning_payout,
            payout.settler_fee,
            payout.maker_rebate,
            protocol_profit,
            maker.collateral,
            block.timestamp
        );
    }

    function cancelOrder(uint256 _maker_order_id) public {
        (bool success, uint256 amt) = derivswap_orderbook
            .orderbook_cancel_order(_maker_order_id, msg.sender);
        if (success == true) {
            address payable payable_user = payable(msg.sender);
            payable_user.transfer(amt);
        } else {
            revert();
        }
    }

    // Public swap ETH->DRVS
    function swap_for_drvs() public payable returns (uint256 amountOut) {
        weth.deposit{value: msg.value}();
        TransferHelper.safeApprove(WETH9, address(swapRouter), msg.value);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: DRVS,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: msg.value,
                //Set slippage paramter! important.
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
    }

    //Uniswap V3 Swap Exact Input Single, Internal DRVS Token Buyback Fuction
    function swapExactInputSingle(uint256 amountIn) internal returns (uint256) {
        // Wrap ether
        weth.deposit{value: amountIn}();

        // Grant approval to Uniswap V3 router
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);

        // Uniswap V3 construct swap paramters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: DRVS,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                //Set slippage paramter! important.
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // Uniswap V3 Router Swap
        uint256 amountOut = swapRouter.exactInputSingle(params);
        emit SwappedForHedgex(amountIn, amountOut, block.timestamp);
        return (amountOut);
    }

    //Uniswap V3 LP Position Halvening Event Function
    function halveLiquidity() internal {
        derivswapLiqManager.decreaseLiquidityCurrentRange();
        initialLiquidityPulled = true;
    }

    //Uniswap V3, Initial Liquidity Provide Function
    function provideLiquidity() internal {
        require(initialLiquidityProvided == false, "E17");
        require(protocol_earnings_native > 0, 'Protocl earnings native is negative.');
        if(protocol_earnings_native>0){
            require(uint256(protocol_earnings_native) >= initialLiqThreshold, "E18");
        }

        // Deposit and wrap ether
        weth.deposit{value: initialLiqThreshold}();

        // Grant approval to liquidity manager
        TransferHelper.safeApprove(
            WETH9,
            derivswapLiqManagerAddress,
            initialLiqThreshold
        );

        // Transfer WETH to Liquidity Manager to be provided as liquidity on Uniswap V3. Liquidity Manager holds supply of DRVS ERC-20.
        TransferHelper.safeTransferFrom(
            WETH9,
            address(this),
            derivswapLiqManagerAddress,
            initialLiqThreshold
        );

        // Mint LP position on Liquidity Manager.
        derivswapLiqManager.mintNewPosition(
            (100 * (10 ** 18)),
            initialLiqThreshold
        );
        initialLiquidityProvided = true;
        // emit InitialLiquidityProvided(tokenId,liquidity,amount0,amount1);
    }

    function ownerpull() public {
        require(msg.sender == owner);
        address payable _owner = payable(owner);
        _owner.transfer(address(this).balance);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./DRVSStructs.sol";

library Settler {
    //Negate64 Odds Reversal Helper
    function negate64(int64 _i) public pure returns (uint64) {
        return uint64(-_i);
    }

    function settlement_evaluation(bytes calldata positionInfo)
        public
        pure
        returns (address payable temp_winner)
    {
        (
            DRVSStructs.Leg[] memory legs,
            DRVSStructs.ClosePrice[] memory close_prices,
            DRVSStructs.MakerOrder memory maker,
            DRVSStructs.TakerOrder memory taker
        ) = abi.decode(
                positionInfo,
                (
                    DRVSStructs.Leg[],
                    DRVSStructs.ClosePrice[],
                    DRVSStructs.MakerOrder,
                    DRVSStructs.TakerOrder
                )
            );

        if (maker.num_legs == 1) {
            if (close_prices[0].close_price.price > legs[0].priceTarget) {
                if (legs[0].outlook == true) {
                    temp_winner = payable(maker.user);
                } else if (legs[0].outlook == false) {
                    temp_winner = payable(taker.user);
                }
            } else if (
                close_prices[0].close_price.price < legs[0].priceTarget
            ) {
                if (legs[0].outlook == true) {
                    temp_winner = payable(taker.user);
                } else if (legs[0].outlook == false) {
                    temp_winner = payable(maker.user);
                }
            } else {
                // Handle Tie Scenario
            }
        }
        //Multi Leg Position Statement
        if (maker.num_legs > 1) {
            bool maker_won = true;
            for (uint256 z = 0; z < maker.num_legs; z++) {
                if (close_prices[z].close_price.price > legs[z].priceTarget) {
                    if (legs[z].outlook == true) {} else if (
                        legs[z].outlook == false
                    ) {
                        maker_won = false;
                    }
                } else if (
                    close_prices[z].close_price.price < legs[z].priceTarget
                ) {
                    if (legs[z].outlook == true) {
                        maker_won = false;
                    } else if (legs[z].outlook == false) {}
                } else {
                    // Handle Tie Scenario
                }
            }
            if (maker_won == false) {
                temp_winner = payable(taker.user);
            } else {
                temp_winner = payable(maker.user);
            }
        }
        return (temp_winner);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {

    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./DRVSStructs.sol";

library Probability {
   function orderbook_calculate_implied_probability(int64 ratio)
        public
        pure
        returns (
            uint256 implied_probability,
            uint256 implied_probability_opposite_side,
            uint256 implied_probability_opposite_side_with_vig,
            int256 opposite_odds256
        )
    {
        uint256 base = 100;
        uint256 vig = 500;
        require(ratio >= 100 || ratio <= -100);

        //100 with two decimal places .xx
        if (ratio > 0) {
            if (ratio > 700) {
                vig = 400;
            }
            if (ratio > 1000) {
                vig = 300;
            }
            if (ratio > 2000) {
                vig = 150;
            }
            if (ratio > 5000) {
                vig = 100;
            }

            uint256 winningAmount = (base * (uint64(ratio))) / 100;
            uint256 fullPayout = base + winningAmount;
            //Percentage form .xx decimal precision
            implied_probability = (base * 10000) / fullPayout;
            implied_probability_opposite_side = 10000 - implied_probability;
            implied_probability_opposite_side_with_vig = (implied_probability_opposite_side +
                vig);
            //.xxxxxx precision
            uint256 decimal_odds = (10000000000 /
                (implied_probability_opposite_side_with_vig));
            uint256 opposite_odds = uint256(
                100000000 / (decimal_odds - 1000000)
            );
            opposite_odds256 = -int256(opposite_odds);
            // return(int256())
        } else if (ratio < -100) {
            if(ratio >= -122){
                require(ratio <= -110,"Ratio must be >= 110 if position is minus money.");
                vig = 175;
            }
            if (ratio < -700) {
                vig = 400;
            }
            if (ratio < -1000) {
                vig = 300;
            }
            if (ratio < -2000) {
                vig = 150;
            }
            if (ratio < -5000) {
                vig = 100;
            }
            //No precision
            uint256 winningAmount = ((base * 10000) / (uint64(-ratio))) / 100;
            uint256 fullPayout = base + winningAmount;
            implied_probability = (base * 10000) / fullPayout;
            implied_probability_opposite_side = 10000 - implied_probability;
            implied_probability_opposite_side_with_vig = (implied_probability_opposite_side +
                vig);
            uint256 decimal_odds = (10000000000 /
                (implied_probability_opposite_side_with_vig));
            uint256 opposite_odds = uint256((decimal_odds - 1000000)) / 10000;
            opposite_odds256 = int256(opposite_odds);
            
        }
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./DRVSStructs.sol";
import "./Settler.sol";
library Payout {
   function orderbook_calculate_payout(
        address winnerAddress,
        DRVSStructs.MakerOrder memory maker,
        DRVSStructs.TakerOrder memory taker
    ) public pure returns (DRVSStructs.Payout memory payout) {
        uint256 maker_rebate;
        uint256 winning_payout;
        uint256 protocol_profit;
        uint256 settler_fee;
        if (winnerAddress == maker.user) {
            // DRVSStructs.Payout memeory newPayout = new DRVSStructs.Payout(winnerAddress,())
            maker_rebate = 0;
            winning_payout =
                (((taker.ethPosted) * 900) / 1000) +
                maker.collateralPosted;
            protocol_profit =
                (taker.ethPosted + maker.collateralPosted) -
                winning_payout;
            settler_fee = (protocol_profit * 10) / 100;
            protocol_profit -= settler_fee;

            // Construct settle-order struct. Maker ->settler->winner payout
        } else if (winnerAddress == taker.user) {
            maker_rebate = (((maker.collateralPosted) * 10) / 1000);
            if (maker.ratio > 0) {
                winning_payout =
                    ((taker.ethPosted * 100) / uint256(-taker.ratio)) +
                    taker.ethPosted;
            } else if (maker.ratio < 0) {
                winning_payout =
                    ((taker.ethPosted * uint256(taker.ratio)) / 100) +
                    taker.ethPosted;
            }
            protocol_profit =
                (maker.collateralPosted + taker.ethPosted) -
                winning_payout;
            settler_fee = (protocol_profit * 10) / 100;
            protocol_profit -= settler_fee;
            protocol_profit -= maker_rebate;
        }
        return (
            DRVSStructs.Payout(
                winnerAddress,
                protocol_profit,
                winning_payout,
                maker_rebate,
                settler_fee
            )
        );
    }

     function orderbook_amtRequiredToTake(int64 ratio, uint256 collateralPosted)
        public
        pure
        returns (uint256 amtRequired)
    {
        // Fetch maker-order.

        if (ratio < 0) {
            //i.e. maker ratio is -400, taker amt should be MakerOrder.ethPosted / (400/100)
            amtRequired = (collateralPosted / Settler.negate64(ratio)) * 100;
        } else {
            //i.e. maker ratio is +400, taker amt should be MakerOrder.ethPosted / (400/100)
            amtRequired = (collateralPosted * uint64(ratio)) / 100;
        }
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./DRVSStructs.sol";
import "./IPyth.sol";
import "./Settler.sol";
import "./Probability.sol";
import "./Payout.sol";

contract Orderbook {
    IPyth pyth;
    address public Derivswap_Vault;
    address public owner;
    address public position_swap_router;
    uint256 makerOrderIDCount;
    uint256 takerOrderIDCount;
    mapping(bytes32 => uint256) public feedBidLiquidity;
    mapping(bytes32 => mapping(address => uint256))
        public feedBidLiquidityByAsset;
    mapping(uint256 => DRVSStructs.MakerOrder) public makerOrdersByID;
    mapping(uint256 => DRVSStructs.TakerOrder) public takerOrdersByID;
    mapping(bytes32 => uint256[]) public makerOrdersByFeedID;
    mapping(uint256 => bool) public makerOrderIDMatched;
    mapping(uint256 => bool) public makerOrderCanceled;
    mapping(uint256 => bool) public takerOrderIDSettled;
    mapping(uint256 => DRVSStructs.SettleOrder) public takerSettleOrder;
    mapping(uint256 => uint256) public makers_taker_ID;
    mapping(address => uint256[]) public userMakerOrders;
    mapping(address => uint256[]) public userTakerOrders;
    mapping(address => uint256) public userSettlerFeesEarned;
    mapping(uint256 => DRVSStructs.ClosePrice[]) public makersClosingPrices;
    mapping(uint256 => DRVSStructs.LockPrice[]) public makersLockPrices;
    mapping(uint256 => DRVSStructs.Leg[]) public makersLegs;

    constructor(address _pyth) {
        owner = msg.sender;
        pyth = IPyth(_pyth);
        makerOrderIDCount = 0;
        takerOrderIDCount = 0;
    }

    modifier onlyVault() {
        require(msg.sender == Derivswap_Vault);
        _;
    }

    function owner_set_hedgex(address DRVS_VAULT_ADDRESS) public {
        require(msg.sender == owner);
        Derivswap_Vault = DRVS_VAULT_ADDRESS;
    }

    function owner_set_position_swap_router(address _swapRouter) public {
        require(msg.sender == owner);
        position_swap_router = _swapRouter;
    }

    function orderbook_make_order(
        bytes calldata maker_info,
        bytes calldata legsEncoded
    ) external onlyVault returns (address, uint256, uint256) {
        // Decode calldata info & calldata legs [].
        (
            //  msg.sender,
            // collateral,
            // collateral==address(0)?msg.value:alternative_collateral_amount,
            // expiryType,
            // expiryValue,
            // ratio
            address sender,
            address collateral,
            uint256 valueSent,
            uint256 expiryType,
            uint256 expiryValue,
            int64 ratio
        ) = abi.decode(
                maker_info,
                (address, address, uint256, uint256, uint256, int64)
            );

        DRVSStructs.Leg[] memory legs = abi.decode(
            legsEncoded,
            (DRVSStructs.Leg[])
        );

        // Construct maker-order struct.
        DRVSStructs.MakerOrder memory newOrder = DRVSStructs.MakerOrder(
            makerOrderIDCount + 1,
            sender,
            collateral,
            valueSent,
            legs.length,
            expiryType,
            expiryValue,
            ratio
        );
        makerOrdersByID[makerOrderIDCount + 1] = newOrder;
        userMakerOrders[sender].push(makerOrderIDCount + 1);

        // Iterate through position's legs.
        for (uint256 x = 0; x < legs.length; x++) {
            // Require lower-bound < upper-bound threshold.
            require(
                legs[x].threshold.lowerBound < legs[x].threshold.upperBound,
                "05"
            );
            for (uint256 xy = 0; xy < legs.length; xy++) {
                if (xy != x) {
                    if (legs[xy].feedID == legs[x].feedID) {
                        revert("Duplicate feed id's not allowed.");
                    }
                }
            }

            makerOrdersByFeedID[legs[x].feedID].push(makerOrderIDCount + 1);

            // Increment liquidity per feed.
            feedBidLiquidityByAsset[legs[x].feedID][collateral] =
                feedBidLiquidityByAsset[legs[x].feedID][collateral] +
                valueSent;

            // Track maker order's legs.
            makersLegs[makerOrderIDCount + 1].push(legs[x]);
        }
        makerOrderIDCount++;
        return (sender, makerOrderIDCount + 1, valueSent);
    }

    function orderbook_take_order(
        bytes calldata takerOrderInfo,
        bytes[] calldata priceUpdateData
    ) external onlyVault returns (address, uint256, uint256, uint256) {
        // Decode calldata info & calldata updatedata.
        (address sender, uint256 valueSent, uint256 makerOrderID) = abi.decode(
            takerOrderInfo,
            (address, uint256, uint256)
        );

        // Fetch coorelated maker order to be matched.
        DRVSStructs.MakerOrder memory makerOrder = makerOrdersByID[
            makerOrderID
        ];

        // Valid price update data.
        require(priceUpdateData.length == makerOrder.num_legs, "06");

        // No wash trading.
        require(sender != makerOrdersByID[makerOrderID].user, "07");

        // Check to make sure order hasn't already been matched or canceled.
        require(
            (makerOrderIDMatched[makerOrderID] == false &&
                makerOrderCanceled[makerOrderID] == false),
            "08"
        );

        // Valid value sent required to match order.
        require(
            valueSent ==
                Payout.orderbook_amtRequiredToTake(
                    makerOrder.ratio,
                    makerOrder.collateralPosted
                ),
            "10"
        );

        // Fetch pyth update fee & update all price feeds assosciated with maker order.
        uint256 pyth_fee = pyth.getUpdateFee(priceUpdateData.length);
        pyth.updatePriceFeeds{value: pyth_fee}(priceUpdateData);

        // Iterate maker position's legs
        for (uint256 i = 0; i < makerOrder.num_legs; i++) {
            // Fetch newest price of each leg.
            PythStructs.Price memory priceAssetUSD = pyth.getPrice(
                makersLegs[makerOrder.order_ID][i].feedID
            );

            // Require asset price is currently within take threshold established by the maker. (PriceThreshold.lowerBounds < Current price < PriceThreshold.upperBounds)
            require(
                (makersLegs[makerOrderID][i].threshold.lowerBound <
                    priceAssetUSD.price) &&
                    (priceAssetUSD.price <
                        makersLegs[makerOrderID][i].threshold.upperBound),
                "12"
            );

            // Store lock-prices @ order-take. (visual verification for maker once order has been matched.)
            makersLockPrices[makerOrder.order_ID].push(
                DRVSStructs.LockPrice(
                    makersLegs[makerOrder.order_ID][i].feedID,
                    priceAssetUSD
                )
            );
        }

        // Initialize taker-order struct.
        DRVSStructs.TakerOrder memory newTakerOrder;
        (, , , int256 opposite_odds256) = Probability
            .orderbook_calculate_implied_probability(makerOrder.ratio);

        uint256 expiry_timestamp = makerOrder.expiryType == 1
            ? block.timestamp + makerOrder.expiryValue
            : makerOrder.expiryValue;
        if (makersLegs[makerOrder.order_ID].length > 1) {
            //Maker orders num_legs > 1, set outlook to false, any wrong outcome of maker order results in positive outcome for taker.
            newTakerOrder = DRVSStructs.TakerOrder(
                takerOrderIDCount + 1,
                sender,
                valueSent,
                block.timestamp,
                expiry_timestamp,
                makerOrderID,
                false,
                opposite_odds256
            );
        } else if (makersLegs[makerOrder.order_ID].length == 1) {
            //else, negate outlook of maker
            newTakerOrder = DRVSStructs.TakerOrder(
                takerOrderIDCount + 1,
                sender,
                valueSent,
                block.timestamp,
                expiry_timestamp,
                makerOrderID,
                !(makersLegs[makerOrderID][0].outlook),
                opposite_odds256
            );
        }
        takerOrdersByID[takerOrderIDCount + 1] = newTakerOrder;
        userTakerOrders[sender].push(takerOrderIDCount + 1);

        // Set maker order as matched & taken.
        makerOrderIDMatched[makerOrder.order_ID] = true;

        // Set assosciation between maker-order => taker-order.
        makers_taker_ID[makerOrderID] = takerOrderIDCount + 1;

        // Decrement open-bid liqudiity per feed.
        for (uint256 x = 0; x < makersLegs[makerOrderID].length; x++) {
            feedBidLiquidityByAsset[makersLegs[makerOrderID][x].feedID][makerOrder.collateral] =
                feedBidLiquidityByAsset[makersLegs[makerOrderID][x].feedID][makerOrder.collateral] -
                makerOrder.collateralPosted;
        }
        takerOrderIDCount++;
        return (sender, makerOrder.order_ID, expiry_timestamp, block.timestamp);
    }

    function orderbook_settle_order(
        bytes calldata settleInfo,
        bytes[] calldata priceUpdateData,
        bytes32[] calldata maker_leg_feed_ids
    )
        external
        onlyVault
        returns (
            DRVSStructs.MakerOrder memory _maker,
            DRVSStructs.TakerOrder memory _taker,
            DRVSStructs.Payout memory _payout
        )
    {
        // Decode calldata settleInfo & calldata priceUpdateData.
        (address sender, uint256 takerOrder_ID) = abi.decode(
            settleInfo,
            (address, uint256)
        );

        DRVSStructs.TakerOrder memory taker = takerOrdersByID[takerOrder_ID];
        DRVSStructs.MakerOrder memory maker = makerOrdersByID[
            taker.makerOrder_ID
        ];

        require(block.timestamp > (taker.expiry), "13");

        require(takerOrderIDSettled[takerOrder_ID] == false, "14");

        require(priceUpdateData.length == maker.num_legs, "15");

        uint256 pyth_fee = pyth.getUpdateFee(priceUpdateData);
        PythStructs.PriceFeed[] memory historical_prices = pyth
            .parsePriceFeedUpdates{value: pyth_fee}(
            priceUpdateData,
            maker_leg_feed_ids,
            uint64(taker.expiry) - 20,
            uint64(taker.expiry) + 20
        );
        // pyth.updatePriceFeeds{value: pyth_fee}(priceUpdateData);

        address payable winnerAddress;

        for (uint256 i = 0; i < maker.num_legs; i++) {
            // PythStructs.Price memory closingPrice = pyth.getPrice(
            //     makersLegs[maker.order_ID][i].feedID
            // );
            makersClosingPrices[maker.order_ID].push(
                DRVSStructs.ClosePrice(
                    makersLegs[maker.order_ID][i].feedID,
                    historical_prices[i].price
                )
            );
        }
        bytes memory encodedForSettler = abi.encode(
            makersLegs[maker.order_ID],
            makersClosingPrices[maker.order_ID],
            maker,
            taker
        );
        winnerAddress = Settler.settlement_evaluation(encodedForSettler);
        takerOrderIDSettled[takerOrder_ID] = true;
        DRVSStructs.Payout memory payout = Payout.orderbook_calculate_payout(
            winnerAddress,
            maker,
            taker
        );
        takerSettleOrder[taker.order_ID] = DRVSStructs.SettleOrder(
            maker.order_ID,
            taker.order_ID,
            maker.user,
            taker.user,
            winnerAddress,
            sender,
            payout.maker_rebate,
            payout.settler_fee,
            payout.winning_payout,
            maker.collateral,
            block.timestamp
        );
        userSettlerFeesEarned[sender] += payout.settler_fee;
        return (maker, taker, payout);
    }

    function orderbook_cancel_order(
        uint256 _makerOrderID,
        address sender
    ) external returns (bool success, uint256 amt) {
        require(
            (makerOrderCanceled[_makerOrderID] == false &&
                sender == makerOrdersByID[_makerOrderID].user)
        );
        makerOrderCanceled[_makerOrderID] = true;
        for (uint256 x = 0; x < makerOrdersByID[_makerOrderID].num_legs; x++) {
            feedBidLiquidityByAsset[makersLegs[_makerOrderID][x].feedID][makerOrdersByID[_makerOrderID].collateral] =
                feedBidLiquidityByAsset[makersLegs[_makerOrderID][x].feedID][makerOrdersByID[_makerOrderID].collateral] -
                (makerOrdersByID[_makerOrderID].collateralPosted);
        }
        return (true, makerOrdersByID[_makerOrderID].collateralPosted);
    }

    function amt_required_to_take(
        uint256 makerOrderID
    ) public view returns (uint256) {
        uint256 amtRequired = Payout.orderbook_amtRequiredToTake(
            makerOrdersByID[makerOrderID].ratio,
            makerOrdersByID[makerOrderID].collateralPosted
        );
        return amtRequired;
    }

    function pyth_update_fee(
        bytes[] calldata priceUpdateData
    ) public view returns (uint256 fee) {
        // Call getupdateFee on Pyth contract.
        fee = pyth.getUpdateFee(priceUpdateData.length);
    }

    // Cancel maker-order. Returns stake to msg.sender w/ no penalty fee.
    function cancelMakerOrder(
        uint256 _makerOrderID,
        address sender
    ) public returns (bool success, uint256 amt) {
        require(sender == makerOrdersByID[_makerOrderID].user);
        require(makerOrderCanceled[_makerOrderID] == false);
        makerOrderCanceled[_makerOrderID] = true;
        for (uint256 x = 0; x < makerOrdersByID[_makerOrderID].num_legs; x++) {
            feedBidLiquidityByAsset[makersLegs[_makerOrderID][x].feedID][makerOrdersByID[_makerOrderID].collateral] =
                feedBidLiquidityByAsset[makersLegs[_makerOrderID][x].feedID][makerOrdersByID[_makerOrderID].collateral] -
                (makerOrdersByID[_makerOrderID].collateralPosted);
        }
        return (true, makerOrdersByID[_makerOrderID].collateralPosted);
    }

    function calculate_taker_odds(
        uint256 maker_order_id
    ) public view returns (int256 opposite_odds256) {
        (, , , opposite_odds256) = Probability
            .orderbook_calculate_implied_probability(
                makerOrdersByID[maker_order_id].ratio
            );
    }

    function swap_router_bid_accepted(
        bytes calldata _data
    ) external returns (bool success) {
        (
            bool _underlyingIsMaker,
            uint256 _underlyingOrderID,
            address _takeOverUser
        ) = abi.decode(_data, (bool, uint256, address));
        require(msg.sender == position_swap_router);
        if (_underlyingIsMaker == true) {
            DRVSStructs.MakerOrder memory maker = makerOrdersByID[
                _underlyingOrderID
            ];
            maker.user = _takeOverUser;
            makerOrdersByID[_underlyingOrderID] = maker;
        } else if (_underlyingIsMaker == false) {
            DRVSStructs.TakerOrder memory taker = takerOrdersByID[
                _underlyingOrderID
            ];
            taker.user = _takeOverUser;
            takerOrdersByID[_underlyingOrderID] = taker;
        }
        return (true);
    }

    function swap_router_ask_accepted(
        bytes calldata _data
    ) external returns (bool, address) {
        (
            bool _underlyingIsMaker,
            uint256 _underlyingOrderID,
            address _takeOverUser
        ) = abi.decode(_data, (bool, uint256, address));
        require(msg.sender == position_swap_router);
        address seller;
        if (_underlyingIsMaker == true) {
            DRVSStructs.MakerOrder memory maker = makerOrdersByID[
                _underlyingOrderID
            ];
            seller = maker.user;
            maker.user = _takeOverUser;
            makerOrdersByID[_underlyingOrderID] = maker;
        } else if (_underlyingIsMaker == false) {
            DRVSStructs.TakerOrder memory taker = takerOrdersByID[
                _underlyingOrderID
            ];
            seller = taker.user;
            taker.user = _takeOverUser;
            takerOrdersByID[_underlyingOrderID] = taker;
        }
        return (true, seller);
    }

    function fetchUserOrders(
        address user,
        uint256 _orderType
    )
        public
        view
        returns (
            DRVSStructs.MakerOrder[] memory maker_orders_returned,
            DRVSStructs.TakerOrder[] memory taker_orders_returned
        )
    {
        DRVSStructs.MakerOrder[]
            memory maker_orders = new DRVSStructs.MakerOrder[](
                userMakerOrders[user].length
            );
        DRVSStructs.TakerOrder[]
            memory taker_orders = new DRVSStructs.TakerOrder[](
                userTakerOrders[user].length
            );

        if (_orderType == 1) {
            for (uint256 i = 0; i < userMakerOrders[user].length; i++) {
                DRVSStructs.MakerOrder memory maker = makerOrdersByID[
                    userMakerOrders[user][i]
                ];
                maker_orders[i] = maker;
            }
        } else if (_orderType == 2) {
            for (uint256 i = 0; i < userTakerOrders[user].length; i++) {
                DRVSStructs.TakerOrder memory taker = takerOrdersByID[
                    userTakerOrders[user][i]
                ];
                taker_orders[i] = taker;
            }
        }
        return (maker_orders, taker_orders);
    }

    function fetchFeedLiquidity(
        bytes32[] memory ids
    ) public view returns (uint256[] memory) {
        uint256[] memory volumes = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            volumes[i] = feedBidLiquidity[ids[i]];
        }
        return (volumes);
    }

    function fetchMakerOrdersByFeedID(
        bytes32 feedID
    ) public view returns (DRVSStructs.MakerOrder[] memory) {
        DRVSStructs.MakerOrder[]
            memory return_array = new DRVSStructs.MakerOrder[](
                makerOrdersByFeedID[feedID].length
            );
        uint256 count = 0;
        for (uint256 i = 0; i < makerOrdersByFeedID[feedID].length; i++) {
            if (
                makerOrderIDMatched[
                    makerOrdersByID[makerOrdersByFeedID[feedID][i]].order_ID
                ] ==
                false &&
                makerOrderCanceled[
                    makerOrdersByID[makerOrdersByFeedID[feedID][i]].order_ID
                ] ==
                false
            ) {
                return_array[count] = makerOrdersByID[
                    makerOrdersByFeedID[feedID][i]
                ];
                count++;
            }
        }
        DRVSStructs.MakerOrder[]
            memory shortened_array = new DRVSStructs.MakerOrder[](count);
        for (uint256 x = 0; x < count; x++) {
            shortened_array[x] = return_array[x];
        }
        return (shortened_array);
    }

    function getUserOrdersLength(
        address _user,
        uint256 _orderType
    ) public view returns (uint256) {
        if (_orderType == 1) {
            return userMakerOrders[_user].length;
        } else if (_orderType == 2) {
            return userTakerOrders[_user].length;
        } else {
            revert();
        }
    }

    function makerOrdersByFeedIDLength(
        bytes32 feedID
    ) public view returns (uint256) {
        return makerOrdersByFeedID[feedID].length;
    }

    receive() external payable {
        // emit Received(msg.sender, msg.value);
    }
}

pragma solidity =0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "./PythStructs.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth {
    /// @dev Emitted when an update for price feed with `id` is processed successfully.
    /// @param id The Pyth Price Feed ID.
    /// @param fresh True if the price update is more recent and stored.
    /// @param chainId ID of the source chain that the batch price update containing this price.
    /// This value comes from Wormhole, and you can find the corresponding chains at https://docs.wormholenetwork.com/wormhole/contracts.
    /// @param sequenceNumber Sequence number of the batch price update containing this price.
    /// @param lastPublishTime Publish time of the previously stored price.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(bytes32 indexed id, bool indexed fresh, uint16 chainId, uint64 sequenceNumber, uint lastPublishTime, uint publishTime, int64 price, uint64 conf);

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    /// @param batchSize Number of prices within the batch price update.
    /// @param freshPricesInBatch Number of prices that were more recent and were stored.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber, uint batchSize, uint freshPricesInBatch);

    /// @dev Emitted when a call to `updatePriceFeeds` is processed successfully.
    /// @param sender Sender of the call (`msg.sender`).
    /// @param batchCount Number of batches that this function processed.
    /// @param fee Amount of paid fee for updating the prices.
    event UpdatePriceFeeds(address indexed sender, uint batchCount, uint fee);

    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(bytes[] calldata updateData, bytes32[] calldata priceIds, uint64[] calldata publishTimes) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateDataSize Number of price updates.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(uint updateDataSize) external view returns (uint feeAmount);
     /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
import "./PythStructs.sol";

contract DRVSStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Leg {
        bytes32 feedID;
        bool outlook;
        int64 priceTarget;
        PriceThreshold threshold;
    }
    struct LockPrice {
        bytes32 feedID;
        PythStructs.Price lock_price;
    }
    struct ClosePrice {
        bytes32 feedID;
        PythStructs.Price close_price;
    }
    struct MakerOrder {
        uint256 order_ID;
        address user;
        address collateral;
        uint256 collateralPosted;
        uint256 num_legs;
        //1:lock-up-period, 2:timestamp
        uint256 expiryType;
        uint256 expiryValue;
        int64 ratio;
    }
    struct TakerOrder {
        uint256 order_ID;
        address user;
        uint256 ethPosted;
        uint256 timeStampTaken;
        uint256 expiry;
        uint256 makerOrder_ID;
        bool outlook;
        int256 ratio;
    }
    struct SettleOrder {
        uint256 makerOrderID;
        uint256 takerOrderID;
        address maker;
        address taker;
        address winner;
        address settler;
        uint256 makerFees;
        uint256 settlerFees;
        uint256 winnerPayout;
        address collateral;
        uint256 timeStampSettled;
        // ClosePrice[] close_prices;
    }
    struct Payout {
        address winnerAddress;
        uint256 protocol_profit;
        uint256 winning_payout;
        uint256 maker_rebate;
        uint256 settler_fee;
    }
    struct PriceThreshold {
        int64 lowerBound;
        int64 upperBound;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
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