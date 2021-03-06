pragma solidity ^0.8.0;
import "OrderBookEvents.sol";
import "OrderBookStorage.sol";
import "ISwapsImpl.sol";
import "IDeposits.sol";
import "Flags.sol";
import "SafeERC20.sol";

contract OrderBook is OrderBookEvents, OrderBookStorage, Flags {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SafeERC20 for IERC20;

    function initialize(address target) public onlyOwner {
        _setTarget(this.getDexRate.selector, target);
        _setTarget(this.clearOrder.selector, target);
        _setTarget(this.prelimCheck.selector, target);
        _setTarget(this.getClearOrderList.selector, target);
        _setTarget(this.getExecuteOrder.selector, target);
        _setTarget(this.queryRateReturn.selector, target);
        _setTarget(this.priceCheck.selector, target);
        _setTarget(this.executeOrder.selector, target);
        _setTarget(this.setPriceFeed.selector, target);
    }

    function _executeTradeOpen(IOrderBook.Order memory order) internal {
        IDeposits(VAULT).withdraw(order.orderID);
        (bool result, bytes memory data) = order.iToken.call(
            abi.encodeWithSelector(
                IToken(order.iToken).marginTrade.selector,
                order.loanID,
                order.leverage,
                order.loanTokenAmount,
                order.collateralTokenAmount,
                order.base,
                order.trader,
                order.loanDataBytes
            )
        );
        if (!result) {
            (address usedToken, uint256 amount) = order.loanTokenAmount > order.collateralTokenAmount
                ? (order.loanTokenAddress, order.loanTokenAmount)
                : (order.base, order.collateralTokenAmount);
            IERC20(usedToken).transfer(order.trader, amount);
        }
    }

    function _executeTradeClose(
        address trader,
        bytes32 loanID,
        uint256 amount,
        bytes memory loanDataBytes
    ) internal {
        address(PROTOCOL).call(
            abi.encodeWithSelector(
                PROTOCOL.closeWithSwap.selector,
                loanID,
                trader,
                amount,
                false,
                loanDataBytes
            )
        );
    }

    function _isActiveLoan(bytes32 ID) internal view returns (bool) {
        return PROTOCOL.loans(ID).active;
    }

    function clearOrder(bytes32 orderID) public view returns (bool) {
        IOrderBook.Order memory order = _allOrders[orderID];
        if (order.timeTillExpiration < block.timestamp) {
            return true;
        }
        uint256 amountUsed = order.collateralTokenAmount +
            order.loanTokenAmount;
        uint256 swapRate;
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            swapRate = queryRateReturn(
                order.loanTokenAddress,
                order.base,
                amountUsed
            );
        } else {
            swapRate = queryRateReturn(
                order.base,
                order.loanTokenAddress,
                amountUsed
            );
        }
        if (
            (
                order.amountReceived > swapRate
                    ? (order.amountReceived - swapRate) >
                        (order.amountReceived * 25) / 100
                    : (swapRate - order.amountReceived) > (swapRate * 25) / 100
            )
        ) {
            return true;
        }
        return false;
    }

    function getClearOrderList(uint start, uint end) external view returns (bool hasOrders, bytes memory payload) {
        require(end<=_allOrderIDs.length(), "OrderBook: end is past max orders");
        bytes32[] memory fullList = new bytes32[](7);
        uint iter = 0;
        bytes32 ID;
        for (uint256 i = start; (i < end && iter < 7);) {
            ID = _allOrderIDs.at(i);
            if (clearOrder(ID)) {
                hasOrders = true;
                fullList[iter] = ID;
                ++iter;
            }
            unchecked { ++i; }
        }
        payload = abi.encode(fullList);
    }

    function getExecuteOrder(uint start, uint end) external returns (bytes32 ID) {
        require(end<=_allOrderIDs.length(), "OrderBook: end is past max orders");
        bytes32 tempID;
        for (uint256 i = start; i < end;) {
            tempID = _allOrderIDs.at(i);
            if (prelimCheck(tempID)) {
                return tempID;
            }
            unchecked { ++i; } 
        }
    }

    function queryRateReturn(
        address start,
        address end,
        uint256 amount
    ) public view returns (uint256) {
        return IPriceFeeds(priceFeed)
            .queryReturn(start, end, amount);
    }

    function prelimCheck(bytes32 orderID) public returns (bool) {
        IOrderBook.Order memory order = _allOrders[orderID];
        uint256 amountUsed;
        address srcToken;
        srcToken = order.collateralTokenAmount > order.loanTokenAmount
            ? order.base
            : order.loanTokenAddress;
        if (order.timeTillExpiration < block.timestamp) {
            return false;
        }
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            if (order.loanID != 0 && !_isActiveLoan(order.loanID)) {
                return false;
            }
            uint256 dSwapValue;
            if (srcToken == order.loanTokenAddress) {
                amountUsed =
                    order.loanTokenAmount +
                    (order.loanTokenAmount * order.leverage) /
                    10**18; //adjusts leverage
            } else {
                amountUsed = queryRateReturn(
                    order.base,
                    order.loanTokenAddress,
                    order.collateralTokenAmount
                );
                amountUsed = (amountUsed * order.leverage) / 10**18;
            }
            dSwapValue =
                order.collateralTokenAmount +
                PROTOCOL.getSwapExpectedReturn(
                    order.loanTokenAddress,
                    order.base,
                    amountUsed,
                    order.loanDataBytes
                );

            if (order.amountReceived <= dSwapValue) {
                return true;
            }
        } else if (order.orderType == IOrderBook.OrderType.LIMIT_CLOSE) {
            if (!_isActiveLoan(order.loanID)) {
                return false;
            }
            uint256 dSwapValue;
            dSwapValue = PROTOCOL.getSwapExpectedReturn(
                order.base,
                order.loanTokenAddress,
                order.collateralTokenAmount,
                order.loanDataBytes
            );
            if (order.amountReceived <= dSwapValue) {
                return true;
            }
        } else {
            if (!_isActiveLoan(order.loanID)) {
                return false;
            }
            bool operand;
            if (_useOracle[order.trader]) {
                operand =
                    order.amountReceived >=
                    queryRateReturn(
                        order.base,
                        order.loanTokenAddress,
                        order.collateralTokenAmount
                    );
            } else {
                operand =
                    order.amountReceived >=
                    getDexRate(
                        order.base,
                        order.loanTokenAddress,
                        order.loanDataBytes,
                        order.collateralTokenAmount
                    );
            }
            if (operand) {
                return true;
            }
        }
        return false;
    }

    function getDexRate(
        address srcToken,
        address destToken,
        bytes memory payload,
        uint256 amountIn
    ) public returns (uint256 rate) {
        uint256 tradeSize = 10**IERC20Metadata(srcToken).decimals();
        rate = PROTOCOL.getSwapExpectedReturn(
            srcToken,
            destToken,
            amountIn,
            payload
        );
        rate = (rate * amountIn) / tradeSize;
    }

    function priceCheck(
        address srcToken,
        address destToken,
        bytes memory payload
    ) public returns (bool) {
        uint256 tradeSize = 10**IERC20Metadata(srcToken).decimals();
        uint256 dexRate = getDexRate(
            srcToken,
            destToken,
            payload,
            tradeSize
        );
        uint256 indexRate = queryRateReturn(srcToken, destToken, tradeSize);
        if (dexRate >= indexRate) {
            if (((dexRate - indexRate) * 1000) / dexRate <= 9) {
                return true;
            } else {
                return false;
            }
        } else {
            if (((indexRate - dexRate) * 1000) / indexRate <= 9) {
                return true;
            } else {
                return false;
            }
        }
    }

    function executeOrder(bytes32 orderID) external pausable {
        IOrderBook.Order memory order = _allOrders[orderID];
        require(
            order.status == IOrderBook.OrderStatus.ACTIVE,
            "OrderBook: non active"
        );
        address srcToken;
        uint256 amountUsed;
        srcToken = order.collateralTokenAmount > order.loanTokenAmount
            ? order.base
            : order.loanTokenAddress;
        require(
            order.timeTillExpiration > block.timestamp,
            "OrderBook: Order Expired"
        );
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            uint256 dSwapValue;
            if (srcToken == order.loanTokenAddress) {
                amountUsed =
                    order.loanTokenAmount +
                    (order.loanTokenAmount * order.leverage) /
                    10**18; //adjusts leverage
            } else {
                amountUsed = queryRateReturn(
                    order.base,
                    order.loanTokenAddress,
                    order.collateralTokenAmount
                );
                amountUsed = (amountUsed * order.leverage) / 10**18;
            }
            dSwapValue =
                order.collateralTokenAmount +
                PROTOCOL.getSwapExpectedReturn(
                    order.loanTokenAddress,
                    order.base,
                    amountUsed,
                    order.loanDataBytes
                );

            require(
                order.amountReceived <= dSwapValue,
                "OrderBook: amountOut too low"
            );
            _executeTradeOpen(order);
            _allOrders[orderID].status = IOrderBook.OrderStatus.EXECUTED;
            _allOrderIDs.remove(orderID);
            _histOrders[order.trader].remove(orderID);
            emit OrderExecuted(order.trader, orderID);
            return;
        }
        else if (order.orderType == IOrderBook.OrderType.LIMIT_CLOSE) {
            uint256 dSwapValue;
            dSwapValue = PROTOCOL.getSwapExpectedReturn(
                order.base,
                order.loanTokenAddress,
                order.collateralTokenAmount,
                order.loanDataBytes
            );
            require(
                order.amountReceived <= dSwapValue,
                "OrderBook: amountOut too low"
            );
            _executeTradeClose(
                order.trader,
                order.loanID,
                order.collateralTokenAmount,
                order.loanDataBytes
            );
            _allOrders[orderID].status = IOrderBook.OrderStatus.EXECUTED;
            _allOrderIDs.remove(orderID);
            _histOrders[order.trader].remove(orderID);
            emit OrderExecuted(order.trader, orderID);
            return;
        }
        else if (order.orderType == IOrderBook.OrderType.MARKET_STOP) {
            bool operand;
            if (_useOracle[order.trader]) {
                operand =
                    order.amountReceived >=
                    queryRateReturn(
                        order.base,
                        order.loanTokenAddress,
                        order.collateralTokenAmount
                    ); //TODO: Adjust for precision
            } else {
                operand =
                    order.amountReceived >=
                    getDexRate(
                        order.base,
                        order.loanTokenAddress,
                        order.loanDataBytes,
                        order.collateralTokenAmount
                    );
            }
            require(
                operand &&
                    priceCheck(
                        order.base,
                        order.loanTokenAddress,
                        order.loanDataBytes
                    ),
                "OrderBook: invalid swap rate"
            );
            _executeTradeClose(
                order.trader,
                order.loanID,
                order.collateralTokenAmount,
                order.loanDataBytes
            );
            _allOrders[orderID].status = IOrderBook.OrderStatus.EXECUTED;
            _allOrderIDs.remove(orderID);
            _histOrders[order.trader].remove(orderID);
            emit OrderExecuted(order.trader, orderID);
            return;
        }
    }

    function setPriceFeed(address newFeed) external onlyOwner {
        priceFeed = newFeed;
    }
}