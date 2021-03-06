pragma solidity ^0.8.0;
import "OrderBookEvents.sol";
import "OrderBookStorage.sol";
import "IDeposits.sol";

contract OrderBookOrderPlace is OrderBookEvents, OrderBookStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function initialize(address target) public onlyOwner {
        _setTarget(this.placeOrder.selector, target);
        _setTarget(this.amendOrder.selector, target);
        _setTarget(this.cancelOrder.selector, target);
        _setTarget(this.cancelOrderProtocol.selector, target);
        _setTarget(this.changeStopType.selector, target);
    }

    function _caseChecks(bytes32 ID, address collateral, address loanToken)
        internal
        view
        returns (bool)
    {
        IBZx.LoanReturnData memory data = PROTOCOL.getLoan(ID);
        return 
            data.loanToken == loanToken &&
            data.collateralToken == collateral &&
            PROTOCOL.delegatedManagers(ID, address(this));
    }

    function _isActiveLoan(bytes32 ID) internal view returns (bool) {
        return PROTOCOL.loans(ID).active;
    }

    function _commonChecks(IOrderBook.Order calldata order) internal {
        require(!(order.collateralTokenAmount>0) || !(order.loanTokenAmount >0), "OrderBook: collateral and loan token cannot be non-zero");
        require(PROTOCOL.supportedTokens(order.loanTokenAddress), "OrderBook: Unsupported loan token");
        require(PROTOCOL.supportedTokens(order.base), "OrderBook: Unsupported collateral");
        require(order.loanID != 0
                    ? _caseChecks(order.loanID, order.base, order.loanTokenAddress)
                    : true,
                "OrderBook: case checks failed");
        require(order.orderType == IOrderBook.OrderType.LIMIT_OPEN
                    ? PROTOCOL.loanPoolToUnderlying(order.iToken) == order.loanTokenAddress
                    : true,
                "OrderBook: Not a loan pool");
        require(order.orderType == IOrderBook.OrderType.LIMIT_OPEN
                    ? order.loanID == 0 ||
                        _isActiveLoan(order.loanID)
                    : _isActiveLoan(order.loanID),
                "OrderBook: non-active loan specified");
        require(order.loanDataBytes.length < 3500, "OrderBook: loanDataBytes too complex");
        require(order.trader == msg.sender, "OrderBook: invalid trader");
    }

    function placeOrder(IOrderBook.Order calldata order) external pausable {
        _commonChecks(order);
        (uint256 amountUsed, address usedToken) = order.loanTokenAmount > order.collateralTokenAmount
            ? (order.loanTokenAmount, order.loanTokenAddress)
            : (order.collateralTokenAmount, order.base);
        address srcToken;
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            if (usedToken == order.base) {
                amountUsed = IPriceFeeds(priceFeed).queryReturn(
                    order.base,
                    order.loanTokenAddress,
                    amountUsed
                );
                amountUsed = (amountUsed * order.leverage) / 10**18;
                srcToken = order.loanTokenAddress;
            } else {
                amountUsed +=
                    (amountUsed * order.leverage) /
                    10**18; //adjusts leverage
                srcToken = order.loanTokenAddress;
            }
        } else {
            srcToken = order.base;
        }
        require(
            IPriceFeeds(priceFeed).queryReturn(srcToken, USDC, amountUsed) >=
                MIN_AMOUNT_IN_USDC,
            "OrderBook: Order too small"
        );
        require(order.status==IOrderBook.OrderStatus.ACTIVE, "OrderBook: invalid order state");
        mainOBID++;
        bytes32 ID = keccak256(abi.encode(msg.sender, mainOBID));
        require(IDeposits(VAULT).getTokenUsed(ID) == address(0), "Orderbook: collision"); //in the very unlikely chance of collision on ID error is thrown
        _allOrders[ID] = order;
        _allOrders[ID].orderID = ID;
        _histOrders[msg.sender].add(ID);
        _allOrderIDs.add(ID);
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            IDeposits(VAULT).deposit(ID, amountUsed, msg.sender, usedToken);
        }
        emit OrderPlaced(
            msg.sender,
            order.orderType,
            order.amountReceived,
            ID,
            order.base,
            order.loanTokenAddress
        );
    }

    function amendOrder(IOrderBook.Order calldata order) external pausable {
        _commonChecks(order);
        require(
            order.base == _allOrders[order.orderID].base &&
                order.loanTokenAddress ==
                _allOrders[order.orderID].loanTokenAddress,
            "OrderBook: invalid tokens"
        );
        require(
            _allOrders[order.orderID].status==IOrderBook.OrderStatus.ACTIVE,
            "OrderBook: inactive order specified"
        );
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            (uint256 amountUsed, address usedToken) = order.loanTokenAmount > order.collateralTokenAmount
                ? (order.loanTokenAmount, order.loanTokenAddress)
                : (order.collateralTokenAmount, order.base);
            uint256 storedAmount = IDeposits(VAULT).getDeposit(
                order.orderID
            );
            require(
                usedToken ==
                    IDeposits(VAULT).getTokenUsed(order.orderID),
                "OrderBook: invalid used token"
            );
            uint256 amountUsedOld = _allOrders[order.orderID].loanTokenAmount +
                _allOrders[order.orderID].collateralTokenAmount;
            if (amountUsedOld > amountUsed) {
                IDeposits(VAULT).partialWithdraw(
                    msg.sender,
                    order.orderID,
                    amountUsedOld - amountUsed
                );
            } else {
                IDeposits(VAULT).deposit(
                    order.orderID,
                    amountUsed - amountUsedOld,
                    msg.sender,
                    usedToken
                );
            }
        }
        _allOrders[order.orderID] = order;
        emit OrderAmended(
            msg.sender,
            order.orderType,
            order.amountReceived,
            order.orderID,
            order.base,
            order.loanTokenAddress
        );
    }

    function cancelOrder(bytes32 orderID) external pausable {
        require(_allOrders[orderID].status==IOrderBook.OrderStatus.ACTIVE, "OrderBook: inactive order");
        _allOrders[orderID].status = IOrderBook.OrderStatus.CANCELLED;
        require(_histOrders[msg.sender].remove(orderID), "OrderBook: not owner of order");
        _allOrderIDs.remove(orderID);
        if (_allOrders[orderID].orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            address usedToken = IDeposits(VAULT).getTokenUsed(
                orderID
            );
            IDeposits(VAULT).withdrawToTrader(msg.sender, orderID);
        }
        emit OrderCancelled(msg.sender, orderID);
    }

    function cancelOrderProtocol(bytes32 orderID) external pausable {
        IOrderBook.Order memory order = _allOrders[orderID];
        address trader = order.trader;
        require(order.status==IOrderBook.OrderStatus.ACTIVE, "OrderBook: inactive order");
        uint256 amountUsed = order.collateralTokenAmount +
            order.loanTokenAmount;
        uint256 swapRate;
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            swapRate = IPriceFeeds(priceFeed).queryReturn(
                order.loanTokenAddress,
                order.base,
                amountUsed
            );
        } else {
            swapRate = IPriceFeeds(priceFeed).queryReturn(
                order.base,
                order.loanTokenAddress,
                amountUsed
            );
        }
        require(
            (
                order.amountReceived > swapRate
                    ? (order.amountReceived - swapRate) >
                        (order.amountReceived * 25) / 100
                    : (swapRate - order.amountReceived) >
                        (swapRate * 25) / 100
            ) || order.timeTillExpiration < block.timestamp,
            "OrderBook: no conditions met"
        );

        _allOrders[orderID].status = IOrderBook.OrderStatus.CANCELLED;
        _histOrders[trader].remove(orderID);
        _allOrderIDs.remove(orderID);
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            address usedToken = IDeposits(VAULT).getTokenUsed(orderID);
            IDeposits(VAULT).withdrawToTrader(trader, orderID);
        }
        emit OrderCancelled(trader, orderID);
    }

    function changeStopType(bool stop) external pausable {
        _useOracle[msg.sender] = stop;
    }
}