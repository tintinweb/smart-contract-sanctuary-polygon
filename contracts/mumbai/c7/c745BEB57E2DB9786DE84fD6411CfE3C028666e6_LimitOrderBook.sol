// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IPerpetualManager.sol";
import "../interfaces/IPerpetualOrder.sol";
import "../interfaces/IClientOrder.sol";
import "../../libraries/Bytes32Pagination.sol";
import "../../libraries/OrderFlags.sol";
import "../functions/PerpetualHashFunctions.sol";

/**
 * @title Limit/Stop Order Book Proxy Contract.
 *
 * @notice A new perpetual limit order book contract.
 * Each order is sent to the perpetual-specific limit order book contract instance. Executions can be started by
 * any participant but only go via instances of this contract.
 * Orders can be posted by anyone but they require valid signatures if not submitted by the trader. This allows brokers
 * to offer a gas-free execution of orders to their traders (the broker pays for gas).
 * Orders cannot be replayed.
 * The order submitted by the client is of type ClientOrder that contains a
 * possible parent/child link. The ClientOrder data is transformed into a Order struct which
 * strips off the parent/child link and adds the submitted-block number.
 * The submitted block number is relevant to avoid early execution (front-running prevention).
 * The parent/child link is important for orders that are conditional on other orders.
 * Parent child structure is as follows:
 *  - relationship is reflected with the two order-digests parentChildDigest1 and parentChildDigest2
 *  - a child can only be executed if the linked parent: is executed/ is cancelled/ never existed
 *  - a parent can be executed if other conditions (e.g. limit price) hold
 *  - if a parent is cancelled due to some trade failure (e.g. Market Order hits slippage limit), children are cancelled too
 *  - parents can still be cancelled by trader which does not imply the children are cancelled
 *
 * */
contract LimitOrderBook is IPerpetualOrder, IClientOrder, PerpetualHashFunctions {
    using Bytes32Pagination for bytes32[];
    uint256 private constant MAX_ORDERS_PER_TRADER = 50;
    // Events
    event PerpetualLimitOrderCreated(
        uint24 indexed perpetualId,
        address indexed trader,
        address brokerAddr,
        Order order,
        bytes32 digest
    );

    event ExecutionFailed(
        uint24 indexed perpetualId,
        address indexed trader,
        bytes32 digest,
        string reason
    );

    enum OrderStatus {
        CANCELED,
        EXECUTED,
        OPEN,
        UNKNOWN
    }
    struct OrderDependency {
        // Parents have either 2 non-zero entries,
        // or just the first !=0
        // A child has parentChildEntry1=0 and
        // stores the single parent in entry2
        bytes32 parentChildDigest1;
        bytes32 parentChildDigest2;
    }

    uint8 internal immutable iCancelDelaySec;
    uint16 internal immutable postingFeeTbps;
    // Stores perpetual id - specific to a perpetual
    uint24 public immutable perpetualId;
    // timestamp when the market was observed to re-open.
    // used to prevent cancel orders being executed right after re-open.
    // marketCloseSwitchTimestamp>0: timestamp when the market was opened
    // marketCloseSwitchTimestamp<0: abs(.) timestamp when the market was closed
    int64 public marketCloseSwitchTimestamp;

    // Array of digests of all orders - irrespecitve of deletion
    bytes32[] public allDigests;

    // Address of trader => digests (orders)
    mapping(address => bytes32[]) public digestsOfTrader;

    // Digest of an order => the order and its data
    mapping(bytes32 => IPerpetualOrder.Order) public orderOfDigest;

    // OrderDigest => Signature
    mapping(bytes32 => bytes) public orderSignature;

    // OrderDigest => Dependencies
    mapping(bytes32 => OrderDependency) public orderDependency;

    // Next order digest of a digest
    mapping(bytes32 => bytes32) public nextOrderHash;

    //Previous order digest of a digest
    mapping(bytes32 => bytes32) public prevOrderHash;

    // Stores last order digest
    bytes32 public lastOrderHash;

    // Order actual count - after addition/removal
    uint256 public orderCount;

    // Perpetual Manager
    IPerpetualManager public immutable perpManager;

    /**
     * @notice Creates the Perpetual Limit Order Book.
     * @dev Replacement of constructor by initialize function for Upgradable Contracts
     * This function will be called only once while deploying order book using Factory.
     * @param _perpetualManagerAddr the address of perpetual proxy manager.
     * @param _perpetualId The id of perpetual.
     * @param _iCancelDelaySec How many seconds do we need to wait for canceling to be allowed
     * */
    constructor(
        address _perpetualManagerAddr,
        uint24 _perpetualId,
        uint8 _iCancelDelaySec,
        uint16 _postingFeeTbps
    ) {
        require(_perpetualManagerAddr != address(0), "perpetual manager invalid");
        require(_perpetualId != uint24(0), "perpetualId invalid");
        perpetualId = _perpetualId;
        perpManager = IPerpetualManager(_perpetualManagerAddr);
        iCancelDelaySec = _iCancelDelaySec;
        postingFeeTbps = _postingFeeTbps;
        marketCloseSwitchTimestamp = int64(uint64(block.timestamp));
    }

    /**
     * @notice Creates Limit/Stop Order using order object with the following fields:
     * iPerpetualId  global id for perpetual
     * traderAddr    address of trader
     * fAmount       amount in base currency to be traded
     * fLimitPrice   limit price
     * fTriggerPrice trigger price, non-zero for stop orders
     * iDeadline     deadline for price (seconds timestamp)
     * referrerAddr  address of abstract referrer
     * flags         trade flags
     * @param _order the order details.
     * @param _signature The traders signature.
     * */
    function postOrder(ClientOrder calldata _order, bytes calldata _signature) external {
        _handleMarketOpening();
        _postOrder(_order, _signature);
    }

    /**
     * @notice Creates Limit/Stop Orders using an array of order objects with the following fields:
     * iPerpetualId  global id for perpetual
     * traderAddr    address of trader
     * fAmount       amount in base currency to be traded
     * fLimitPrice   limit price
     * fTriggerPrice trigger price, non-zero for stop orders
     * iDeadline     deadline for price (seconds timestamp)
     * referrerAddr  address of abstract referrer
     * flags         trade flags
     * @param _orders the orders' details.
     * @param _signatures The traders signatures. Required if broker submits order, otherwise it can be bytes32(0)
     * */
    function postOrders(ClientOrder[] calldata _orders, bytes[] calldata _signatures) external {
        require(_orders.length > 0, "no orders");
        require(_orders.length == _signatures.length, "arrays mismatch");
        _handleMarketOpening();
        for (uint256 i = 0; i < _orders.length; ) {
            _postOrder(_orders[i], _signatures[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Internal version of postOrder
     * @param _order the order details.
     * @param _signature The traders signature. Required if broker submits order, otherwise it can be bytes32(0)
     * @return digest of the order
     */
    function _postOrder(ClientOrder calldata _order, bytes memory _signature)
        internal
        returns (bytes32 digest)
    {
        // Validations
        require(perpetualId == _order.iPerpetualId, "wrong order book");
        require(_order.traderAddr != address(0), "invalid-trader");
        require(_order.fAmount != 0, "invalid amount");
        require(_order.iDeadline > block.timestamp, "invalid-deadline");
        // executionTimestamp prior to now+7 days
        require(
            _order.executionTimestamp < _order.iDeadline &&
                _order.executionTimestamp < block.timestamp + 604800,
            "invalid exec ts"
        );
        if (OrderFlags.isStopOrder(_order.flags)) {
            require(_order.fTriggerPrice > 0, "invalid trigger price");
        }

        // copy client-order into a more lean perp-order
        Order memory perpOrder = _clientOrderToPerpOrder(_order);
        // set order submission time
        perpOrder.submittedTimestamp = uint32(block.timestamp);

        _checkBrokerSignature(perpOrder);
        digest = _getDigest(perpOrder, address(perpManager), true);
        // no link to itself
        require(
            _order.parentChildDigest1 != digest && _order.parentChildDigest1 != digest,
            "order links itself"
        );
        // register the dependency between orders
        _addOrderDependency(_order, digest);

        // if broker submits the trader on behalf of the trader,
        // the trader needs to have a signature in the order
        if (msg.sender != _order.traderAddr) {
            //if no signature reverts with ECDSA: invalid signature length
            address signatory = ECDSA.recover(digest, _signature);
            //Verify address is not null and PK is not null either.
            require(signatory != address(0), "invalid signature or PK");
            require(signatory == perpOrder.traderAddr, "invalid signature");
        }

        require(orderOfDigest[digest].traderAddr == address(0), "order-exists");
        require(
            digestsOfTrader[perpOrder.traderAddr].length < MAX_ORDERS_PER_TRADER,
            "max num orders exceeded"
        );
        // prevent clogging order books through replay of adversary, immunefy 9652
        require(!perpManager.isOrderExecuted(digest), "order already executed");
        require(!perpManager.isOrderCanceled(digest), "order was canceled");

        // register
        _addOrder(digest, perpOrder, _signature);

        // posting fee = cancellation fee (rebated if executed)
        perpManager.chargePostingFee(perpOrder, postingFeeTbps);

        emit PerpetualLimitOrderCreated(
            _order.iPerpetualId,
            _order.traderAddr,
            _order.brokerAddr,
            perpOrder,
            digest
        );
        return digest;
    }

    function _clientOrderToPerpOrder(ClientOrder calldata _order)
        internal
        pure
        returns (Order memory perpOrder)
    {
        perpOrder.flags = _order.flags;
        perpOrder.iPerpetualId = _order.iPerpetualId;
        perpOrder.brokerFeeTbps = _order.brokerFeeTbps;
        perpOrder.traderAddr = _order.traderAddr;
        perpOrder.brokerAddr = _order.brokerAddr;
        perpOrder.brokerSignature = _order.brokerSignature;
        perpOrder.fAmount = _order.fAmount;
        perpOrder.fLimitPrice = _order.fLimitPrice;
        perpOrder.fTriggerPrice = _order.fTriggerPrice;
        perpOrder.leverageTDR = _order.leverageTDR;
        perpOrder.iDeadline = _order.iDeadline;
        perpOrder.executionTimestamp = _order.executionTimestamp;

        return perpOrder;
    }

    function _perpOrderToClientOrder(Order storage _order, bytes32 _orderDigest)
        internal
        view
        returns (ClientOrder memory clientOrder)
    {
        clientOrder.flags = _order.flags;
        clientOrder.iPerpetualId = _order.iPerpetualId;
        clientOrder.brokerFeeTbps = _order.brokerFeeTbps;
        clientOrder.traderAddr = _order.traderAddr;
        clientOrder.brokerAddr = _order.brokerAddr;
        clientOrder.brokerSignature = _order.brokerSignature;
        clientOrder.fAmount = _order.fAmount;
        clientOrder.fLimitPrice = _order.fLimitPrice;
        clientOrder.fTriggerPrice = _order.fTriggerPrice;
        clientOrder.leverageTDR = _order.leverageTDR;
        clientOrder.iDeadline = _order.iDeadline;
        clientOrder.executionTimestamp = _order.executionTimestamp;
        OrderDependency memory dpcy = orderDependency[_orderDigest];
        clientOrder.parentChildDigest1 = dpcy.parentChildDigest1;
        clientOrder.parentChildDigest2 = dpcy.parentChildDigest2;
        return clientOrder;
    }

    /**
     * marketCloseSwitchBlock stores the last block that the market was
     * observed to be closed or opened. If the market was closed,
     * the sign is negative, if the market is open, the sign is positive.
     * Example 123, this means the market was first observed to be opened
     *  at block 123
     * Example -345, this means the market was first observed to be closed
     *  at block 345
     */
    function _handleMarketOpening() internal {
        bool isClosed = perpManager.isPerpMarketClosed(perpetualId);
        if (marketCloseSwitchTimestamp > 0 && isClosed) {
            // the market was open marketCloseSwitchBlock>0, but
            // is closed now
            marketCloseSwitchTimestamp = -int64(uint64(block.timestamp));
        } else if (marketCloseSwitchTimestamp < 0 && !isClosed) {
            // the market was closed marketCloseSwitchBlock<0, but
            // is open now
            marketCloseSwitchTimestamp = int64(uint64(block.timestamp));
        }
    }

    /**
     * @notice Execute Order or cancel & remove it (if expired).
     * @dev Interacts with the PerpetualTradeManager.
     * @param _digest hash of the order.
     * @param _referrerAddr address that will receive referral rebate
     * */
    function executeOrder(
        bytes32 _digest,
        address _referrerAddr,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes
    ) external payable {
        // submit oracle updates: reverts if data is invalid (too old, wrong feeds)
        uint256 maxAcceptableFeedAge = block.timestamp - orderOfDigest[_digest].submittedTimestamp;
        // slither-disable-next-line reentrancy-eth : this is not an external contract, it's the proxy
        perpManager.updatePriceFeeds{ value: msg.value }(
            perpetualId,
            _updateData,
            _publishTimes,
            maxAcceptableFeedAge
        );
        _executeOrder(_digest, _referrerAddr);
    }

    /**
     * @notice Execute Orders or cancel & remove them (if expired).
     * @dev Interacts with the PerpetualTradeManager.
     * @param _digests hash of the order.
     * @param _referrerAddr address that will receive referral rebate
     * */
    function executeOrders(
        bytes32[] calldata _digests,
        address _referrerAddr,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes
    ) external payable {
        require(_digests.length > 0, "no orders");

        // submit oracle updates: reverts if data is invalid (too old, wrong feeds)
        uint256 shortestTimeElapsed = block.timestamp -
            orderOfDigest[_digests[0]].submittedTimestamp;
        for (uint256 i = 1; i < _digests.length; i++) {
            uint256 age = block.timestamp - orderOfDigest[_digests[i]].submittedTimestamp;
            shortestTimeElapsed = shortestTimeElapsed < age ? shortestTimeElapsed : age;
        }
        // set 'maxAcceptableFeedAge' to the shortest time elapsed between order posting and now
        // to ensure the price is newer than the order.
        // slither-disable-next-line reentrancy-eth : this is not an external contract, it's the proxy
        perpManager.updatePriceFeeds{ value: msg.value }(
            perpetualId,
            _updateData,
            _publishTimes,
            shortestTimeElapsed
        );
        for (uint256 i = 0; i < _digests.length; ) {
            _executeOrder(_digests[i], _referrerAddr);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Cancels limit/stop order
     * @dev Order can be cancelled by the trader himself or it can be
     * removed by the relayer if it has expired.
     * @param _digest hash of the order.
     * @param _signature signed cancel-order; 0 if order expired
     * */
    function cancelOrder(
        bytes32 _digest,
        bytes calldata _signature,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes
    ) external payable {
        Order memory order = orderOfDigest[_digest];
        require(perpetualId == order.iPerpetualId, "order not found");
        // slither-disable-next-line reentrancy-eth : this is not an external contract, it's the proxy
        perpManager.updatePriceFeeds{ value: msg.value }(
            perpetualId,
            _updateData,
            _publishTimes,
            0
        );
        _handleMarketOpening();

        // market is open:
        uint64 tsStart = marketCloseSwitchTimestamp >= 0
            ? uint64(marketCloseSwitchTimestamp)
            : uint64(-marketCloseSwitchTimestamp);
        if (tsStart < order.submittedTimestamp) {
            tsStart = order.submittedTimestamp;
        }
        // cannot cancel when market is closed, or not sufficient delay since close
        if (marketCloseSwitchTimestamp < 0 || block.timestamp < tsStart + iCancelDelaySec) {
            emit ExecutionFailed(perpetualId, order.traderAddr, _digest, "cancel delay required");
        } else {
            // allow only signed cancel if cancel was not executed by trader
            if (msg.sender != order.traderAddr) {
                bytes32 cancelDigest = _getDigest(order, address(perpManager), false);
                address signatory = ECDSA.recover(cancelDigest, _signature);
                require(signatory == order.traderAddr, "trader must sign cancel order");
            }
            perpManager.executeCancelOrder(perpetualId, _digest);
            _removeOrder(_digest);
        }
    }

    /**
     * check the broker signature (if there is one).
     * @param _order order with stored broker signature
     */
    function _checkBrokerSignature(Order memory _order) internal view {
        if (_order.brokerSignature.length == 0) {
            return;
        }
        bytes32 digest = _getBrokerDigest(_order, address(perpManager));
        address signatory = ECDSA.recover(digest, _order.brokerSignature);
        require(signatory != address(0), "invalid broker sig");
        require(signatory == _order.brokerAddr, "invalid broker sig");
    }

    /**
     * @notice Execute Order or cancel & remove it
     * @param _digest order Id (hash of the order)
     * @param _referrerAddr Address to credit for the order execution
     */
    function _executeOrder(bytes32 _digest, address _referrerAddr) internal {
        Order memory order = orderOfDigest[_digest];
        address trader = order.traderAddr;
        require(trader != address(0x0), "order not found");
        order.referrerAddr = _referrerAddr;
        _handleMarketOpening();
        // check whether this is a child order that has an outstanding dependency,
        // if so revert (orders stay in order book)
        require(!_hasOutstandingDependency(_digest), "dpcy not fulfilled");
        // Remove the order (locally) if it has expired
        bool removeDependency; // = false;
        if (block.timestamp <= order.iDeadline) {
            require(block.timestamp >= order.executionTimestamp, "exec too early");
            try perpManager.tradeViaOrderBook(order) returns (bool orderSuccess) {
                perpManager.rebatePostingFee(order, postingFeeTbps);
                if (!orderSuccess) {
                    // market orders do not revert on price exceeds limit, instead the trade-function
                    // returns false. This is to have a "fill-or-kill" behavior for market orders
                    // with slippage protection. Hence the event here:
                    emit ExecutionFailed(perpetualId, trader, _digest, "price exceeds limit");
                    // remove dependent orders if parent order execution failed to to slippage
                    removeDependency = true;
                }
            } catch Error(string memory reason) {
                /*
                    order should be removed in the following cases
                        "already closed" <- REMOVE THIS IN CONTRACT AND TESTS
                        "trade amount too small" <- no rebate
                        "position too small" <- no rebate
                        "no amount to close" <-  REMOVE THIS IN CONTRACT AND TESTS; no rebate
                        "trader has no position to close" <- no rebate
                        "allowance not enough" <- no rebate
                        "balance not enough" <- no rebate
                        "margin not enough" <- no rebate
                        "state should be NORMAL" <- no rebate (rare)
                        "cannot be closing if no exposure" <- indifferent
                        "Trade amt>max amt for trader/AMM" <- rebate
                        Do not delete dependencies:
                            "order was cancelled" <- no rebate    <- don't delete children
                            "order already executed" <- no rebate <- don't delete children
                            market order: "price exceeds limit" <- we end up in !orderSuccess above
                    order should remain in order book (=revert) if
                        "Trade amt>max amt for trader/AMM"
                        "delay required"
                        "market is closed"
                        "trade is close only"
                        limit/stop order: "price exceeds limit"
                        "trigger cond not met"
                    isFillOrKill -> always remove order, except when delay was not met
                */
                if (_isStringEqual(reason, "Trade amt>max amt for trader/AMM")) {
                    perpManager.rebatePostingFee(order, postingFeeTbps);
                    removeDependency = true;
                } else if (
                    _isStringEqual(reason, "delay required") ||
                    (!OrderFlags.isFillOrKill(order.flags) &&
                        (_isStringEqual(reason, "Trade amt>max amt for trader/AMM") ||
                            _isStringEqual(reason, "market is closed") ||
                            _isStringEqual(reason, "trigger cond not met") ||
                            (!OrderFlags.isMarketOrder(order.flags) &&
                                (_isStringEqual(reason, "trade is close only") ||
                                    _isStringEqual(reason, "price exceeds limit") ||
                                    _isStringEqual(reason, "outdated oracles")))))
                ) {
                    // order should remain in order book, re-throw error
                    revert(reason);
                } else if (
                    _isStringEqual(reason, "order was cancelled") ||
                    _isStringEqual(reason, "order already executed")
                ) {
                    removeDependency = false;
                } else {
                    removeDependency = true;
                }
                // emit event
                emit ExecutionFailed(perpetualId, trader, _digest, reason);
            }
        } else {
            // deadline exceeded
            emit ExecutionFailed(perpetualId, trader, _digest, "deadline");
            // also remove dependent orders
            removeDependency = true;
        }
        // if expired or executed or caught in "orderly fail", we remove the order
        // if the order does not match with prices, there is a revert so
        // we do not end up here
        _wipeOrder(_digest, removeDependency);
    }

    /**
     * Check whether there is a dependent parent order that has not been executed
     * Returns false if the order is a parent order,
     * returns false if the order has no parent order,
     * returns false if parent order was executed or cancelled
     * returns false if the parent order does not exist
     * @param _digest order digest for the order we check
     * @return boolean whether has dependent parent order (that is not executed or cancelled)
     */
    function _hasOutstandingDependency(bytes32 _digest) internal view returns (bool) {
        OrderDependency storage dpcy = orderDependency[_digest];
        if (dpcy.parentChildDigest1 != bytes32(0)) {
            // is a parent order
            return false;
        }
        bytes32 parentDigest = dpcy.parentChildDigest2;
        if (
            parentDigest == bytes32(0) || // no parent, Jesus
            perpManager.isOrderCanceled(parentDigest) || // parent order was cancelled
            perpManager.isOrderExecuted(parentDigest) || // parent order was executed
            orderOfDigest[parentDigest].traderAddr == address(0) // parent order does not exist
        ) {
            return false;
        }
        return true;
    }

    /**
     * Remove order from this order book and add to cancel list in perpetual manager proxy
     * @param _digest   order digest
     */
    function _wipeOrder(bytes32 _digest, bool _removeDependency) internal {
        // remove from this order book
        _removeOrder(_digest);
        // ensure order cannot be replayed: add to cancel list in perpetual manager
        if (!perpManager.isOrderExecuted(_digest)) {
            perpManager.executeCancelOrder(perpetualId, _digest);
        }
        // remove dependent orders if this was a parent order
        if (_removeDependency) {
            _wipeDependentOrders(_digest);
        }
        delete orderDependency[_digest];
    }

    /**
     * If _parentDigest is indeed a parent order, children will be
     * removed.
     * Delete orderDependency for a given parent order.
     * Delete child orders and their dependency entries.
     * @param _parentDigest orderId of parent order
     */
    function _wipeDependentOrders(bytes32 _parentDigest) internal {
        (bytes32 child1, bytes32 child2) = _getValidChildren(_parentDigest);
        if (child1 != bytes32(0)) {
            _wipeOrder(child1, false);
        }
        if (child2 != bytes32(0)) {
            _wipeOrder(child2, false);
        }
    }

    /**
     * @param _order  client order with potential order dependency
     * @param _digest digest of the order we are registring the dependency for
     */
    function _addOrderDependency(ClientOrder calldata _order, bytes32 _digest) internal {
        if (_order.parentChildDigest1 == bytes32(0) && _order.parentChildDigest2 == bytes32(0)) {
            return;
        }
        OrderDependency memory dpcy;
        dpcy.parentChildDigest1 = _order.parentChildDigest1;
        dpcy.parentChildDigest2 = _order.parentChildDigest2;
        orderDependency[_digest] = dpcy;
    }

    /**
     * Parent can have one or two children, child only has 1 parent, hence:
     * Parent: _dpcy.parentChildEntry1!=0
     * Child: _dpcy.parentChildEntry2!=0 && _dpcy.parentChildEntry1==0
     * @param _dpcy dependency struct
     */
    function _isParentOrder(OrderDependency storage _dpcy) internal view returns (bool) {
        return _dpcy.parentChildDigest1 != bytes32(0);
    }

    /**
     * Return digests of 2 children (or 0)
     * @param _parent digest of parent order
     * @return bytes32(0) or digest of child order 1
     * @return bytes32(0) or digest of child order 2
     */
    function _getValidChildren(bytes32 _parent) internal view returns (bytes32, bytes32) {
        OrderDependency storage dpcy = orderDependency[_parent];
        if (!_isParentOrder(dpcy)) {
            return (bytes32(0), bytes32(0));
        }
        bytes32 child1 = dpcy.parentChildDigest1;
        OrderDependency storage dpcyChild1 = orderDependency[child1];
        if (dpcyChild1.parentChildDigest2 != _parent) {
            // child order does not have parent entry
            child1 = bytes32(0);
        }
        if (dpcy.parentChildDigest2 == bytes32(0)) {
            // parent only has 1 child entry
            return (child1, bytes32(0));
        }
        bytes32 child2 = dpcy.parentChildDigest2;
        OrderDependency storage dpcyChild2 = orderDependency[child2];
        if (dpcyChild2.parentChildDigest2 != _parent) {
            // child order does not have parent entry
            return (child1, bytes32(0));
        }
        return (child1, child2);
    }

    /**
     * @notice Internal function to add order to order book.
     * */
    function _addOrder(
        bytes32 _digest,
        Order memory _order,
        bytes memory _signature
    ) internal {
        orderOfDigest[_digest] = _order;
        orderSignature[_digest] = _signature;
        allDigests.push(_digest);
        digestsOfTrader[_order.traderAddr].push(_digest);
        // add order to orderbook linked list
        nextOrderHash[lastOrderHash] = _digest;
        prevOrderHash[_digest] = lastOrderHash;
        lastOrderHash = _digest;
        orderCount = orderCount + 1;
    }

    /**
     * @notice Internal function to remove order from order book.
     * @dev We do not remove entry from orderOfDigest & orderSignature & orderDependency.
     * */
    function _removeOrder(bytes32 _digest) internal {
        if (_digest == bytes32(0)) {
            // zero digest is always empty
            return;
        }
        // remove from trader's order-array 'orderOfDigest'
        Order storage order = orderOfDigest[_digest];
        bytes32[] storage orderArr = digestsOfTrader[order.traderAddr];
        // done if nothing to remove
        if (orderArr.length == 0) {
            return;
        }
        uint256 k;
        while (k < orderArr.length) {
            if (orderArr[k] == _digest) {
                orderArr[k] = orderArr[orderArr.length - 1];
                orderArr.pop();
                k = MAX_ORDERS_PER_TRADER;
            }
            unchecked {
                ++k;
            }
        }
        // remove order
        delete orderOfDigest[_digest];

        // remove from linked list needed
        if (lastOrderHash == _digest) {
            lastOrderHash = prevOrderHash[_digest];
        } else {
            prevOrderHash[nextOrderHash[_digest]] = prevOrderHash[_digest];
        }
        bytes32 prevHash = prevOrderHash[_digest];
        nextOrderHash[prevHash] = nextOrderHash[_digest];
        // delete obsolete entries
        delete prevOrderHash[_digest];
        delete nextOrderHash[_digest];
        orderCount = orderCount - 1;
    }

    /**
     * Return the order status: OPEN, EXECUTED, CANCELED, UNKNOWN order
     * @param _digest   order identifier
     */
    function getOrderStatus(bytes32 _digest) external view returns (OrderStatus) {
        if (perpManager.isOrderCanceled(_digest)) {
            return OrderStatus.CANCELED;
        }
        if (perpManager.isOrderExecuted(_digest)) {
            return OrderStatus.EXECUTED;
        }
        if (orderOfDigest[_digest].traderAddr == address(0)) {
            return OrderStatus.UNKNOWN;
        }
        return OrderStatus.OPEN;
    }

    /**
     * @notice Returns the number of (active) limit orders of a trader
     * @param trader address of trader.
     * */
    function numberOfDigestsOfTrader(address trader) external view returns (uint256) {
        return digestsOfTrader[trader].length;
    }

    /**
     * @notice Returns the number of all limit orders - including those
     * that are cancelled/removed.
     * */
    function numberOfAllDigests() external view returns (uint256) {
        return allDigests.length;
    }

    /**
     * @notice Returns the number of all limit orders - excluding those
     * that are cancelled/removed.
     * */
    function numberOfOrderBookDigests() external view returns (uint256) {
        return orderCount;
    }

    /**
     * @notice Returns an array of digests of orders of a trader
     * @param trader address of trader.
     * @param page start/offset.
     * @param limit count.
     * */
    function limitDigestsOfTrader(
        address trader,
        uint256 page,
        uint256 limit
    ) external view returns (bytes32[] memory) {
        return digestsOfTrader[trader].paginate(page, limit);
    }

    /**
     * @notice Returns an array of all digests - including those
     * that are cancelled/removed.
     * */
    function allLimitDigests(uint256 page, uint256 limit)
        external
        view
        returns (bytes32[] memory)
    {
        return allDigests.paginate(page, limit);
    }

    /**
     * @notice Returns the address of trader for an order digest
     * @param digest order digest.
     * @return trader address
     * */
    function getTrader(bytes32 digest) external view returns (address trader) {
        Order storage order = orderOfDigest[digest];
        trader = order.traderAddr;
    }

    /**
     * @notice Returns all orders(specified by offset/start and limit/count) of a trader
     * @param trader address of trader.
     * @param offset start.
     * @param limit count.
     * @return orders : array of orders
     * */
    function getOrders(
        address trader,
        uint256 offset,
        uint256 limit
    ) external view returns (ClientOrder[] memory orders) {
        orders = new ClientOrder[](limit);
        bytes32[] storage digests = digestsOfTrader[trader];
        for (uint256 i = 0; i < limit; ) {
            if (i + offset < digests.length) {
                bytes32 digest = digests[i + offset];
                orders[i] = _perpOrderToClientOrder(orderOfDigest[digest], digest);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns the signature of trader for an order digest.
     * @param digest digest of an order.
     * @return signature signature of the trader who created the order.
     * */
    function getSignature(bytes32 digest) public view returns (bytes memory signature) {
        return orderSignature[digest];
    }

    /**
     * @notice Returns the details of the specified number of orders from
     * the passed starting digest
     * @param _startAfter digest to start.
     * @param _numElements number of orders to display.
     * return (orders, orderHashes) : (order hash details, orderHashes).
     * */
    function pollLimitOrders(bytes32 _startAfter, uint256 _numElements)
        external
        view
        returns (ClientOrder[] memory orders, bytes32[] memory orderHashes)
    {
        uint256 k;
        orders = new ClientOrder[](_numElements);
        orderHashes = new bytes32[](_numElements);
        bytes32 current = _startAfter;
        while (k < _numElements) {
            bytes32 next = nextOrderHash[current];
            orders[k] = _perpOrderToClientOrder(orderOfDigest[next], next);
            orderHashes[k] = next;
            k++;
            current = next;
            if (current == bytes32(0)) {
                // no more elements in list, we're done
                k = _numElements;
            }
        }
    }

    function _isStringEqual(string memory _a, string memory _b) internal pure returns (bool) {
        return
            (bytes(_a).length == bytes(_b).length) &&
            (keccak256(bytes(_a)) == keccak256(bytes(_b)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library OrderFlags {
    uint32 internal constant MASK_CLOSE_ONLY = 0x80000000;
    uint32 internal constant MASK_MARKET_ORDER = 0x40000000;
    uint32 internal constant MASK_STOP_ORDER = 0x20000000;
    uint32 internal constant MASK_FILL_OR_KILL = 0x10000000;
    uint32 internal constant MASK_KEEP_POS_LEVERAGE = 0x08000000;
    uint32 internal constant MASK_LIMIT_ORDER = 0x04000000;

    /**
     * @dev Check if the flags contain close-only flag
     * @param flags The flags
     * @return bool True if the flags contain close-only flag
     */
    function isCloseOnly(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_CLOSE_ONLY) > 0;
    }

    /**
     * @dev Check if the flags contain market flag
     * @param flags The flags
     * @return bool True if the flags contain market flag
     */
    function isMarketOrder(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_MARKET_ORDER) > 0;
    }

    /**
     * @dev Check if the flags contain fill-or-kill flag
     * @param flags The flags
     * @return bool True if the flags contain fill-or-kill flag
     */
    function isFillOrKill(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_FILL_OR_KILL) > 0;
    }

    /**
     * @dev We keep the position leverage for a closing position, if we have
     * an order with the flag MASK_KEEP_POS_LEVERAGE, or if we have
     * a limit or stop order.
     * @param flags The flags
     * @return bool True if we should keep the position leverage on close
     */
    function keepPositionLeverageOnClose(uint32 flags) internal pure returns (bool) {
        return (flags & (MASK_KEEP_POS_LEVERAGE | MASK_STOP_ORDER | MASK_LIMIT_ORDER)) > 0;
    }

    /**
     * @dev Check if the flags contain stop-loss flag
     * @param flags The flags
     * @return bool True if the flags contain stop-loss flag
     */
    function isStopOrder(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_STOP_ORDER) > 0;
    }

    /**
     * @dev Check if the flags contain limit-order flag
     * @param flags The flags
     * @return bool True if the flags contain limit-order flag
     */
    function isLimitOrder(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_LIMIT_ORDER) > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Bytes32Pagination {
    function paginate(
        bytes32[] memory hashes,
        uint256 page,
        uint256 limit
    ) internal pure returns (bytes32[] memory result) {
        result = new bytes32[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i < hashes.length) {
                result[i] = hashes[page * limit + i];
            } else {
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IPerpetualFactory.sol";
import "./IPerpetualPoolFactory.sol";
import "./IPerpetualDepositManager.sol";
import "./IPerpetualWithdrawManager.sol";
import "./IPerpetualWithdrawAllManager.sol";
import "./IPerpetualLiquidator.sol";
import "./IPerpetualTreasury.sol";
import "./IPerpetualSettlement.sol";
import "./IPerpetualGetter.sol";
import "./ILibraryEvents.sol";
import "./IPerpetualTradeLogic.sol";
import "./IAMMPerpLogic.sol";
import "./IPerpetualUpdateLogic.sol";
import "./IPerpetualRebalanceLogic.sol";
import "./IPerpetualMarginLogic.sol";
import "./IPerpetualLimitTradeManager.sol";
import "./IPerpetualBrokerFeeLogic.sol";

interface IPerpetualManager is
    IPerpetualFactory,
    IPerpetualPoolFactory,
    IPerpetualDepositManager,
    IPerpetualWithdrawManager,
    IPerpetualWithdrawAllManager,
    IPerpetualLiquidator,
    IPerpetualTreasury,
    IPerpetualTradeLogic,
    IPerpetualBrokerFeeLogic,
    IPerpetualLimitTradeManager,
    IPerpetualSettlement,
    IPerpetualGetter,
    IAMMPerpLogic,
    ILibraryEvents,
    IPerpetualUpdateLogic,
    IPerpetualRebalanceLogic,
    IPerpetualMarginLogic
{}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Trader/Broker facing order struct
 * @notice this order struct is sent to the limit order book and converted into an IPerpetualOrder
 */
interface IClientOrder {
    struct ClientOrder {
        uint24 iPerpetualId; // unique id of the perpetual
        int128 fLimitPrice; // order will not execute if realized price is above (buy) or below (sell) this price
        uint16 leverageTDR; // leverage, set to 0 if deposit margin and trade separate; format: two-digit integer (e.g., 12.34 -> 1234)
        uint32 executionTimestamp; // the order will not be executed before this timestamp, allows TWAP orders
        uint32 flags; // Order-flags are specified in OrderFlags.sol
        uint32 iDeadline; // order will not be executed after this deadline
        address brokerAddr; // can be empty, address of the broker
        int128 fTriggerPrice; // trigger price for stop-orders|0. Order can be executed if the mark price is below this price (sell order) or above (buy)
        int128 fAmount; // signed amount of base-currency. Will be rounded to lot size
        bytes32 parentChildDigest1; // see notice in LimitOrderBook.sol
        address traderAddr; // address of the trader
        bytes32 parentChildDigest2; // see notice in LimitOrderBook.sol
        uint16 brokerFeeTbps; // broker fee in tenth of a basis point
        bytes brokerSignature; // signature, can be empty if no brokerAddr provided
        //address referrerAddr; <- will be set by LimitOrderBook
        //uint64 submittedBlock <- will be set by LimitOrderBook
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IPerpetualOrder.sol";

contract PerpetualHashFunctions {
    string private constant NAME = "Perpetual Trade Manager";

    //The EIP-712 typehash for the contract's domain.
    bytes32 private constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    //The EIP-712 typehash for the Order struct used by the contract.
    bytes32 private constant TRADE_ORDER_TYPEHASH =
        keccak256(
            "Order(uint24 iPerpetualId,uint16 brokerFeeTbps,address traderAddr,address brokerAddr,int128 fAmount,int128 fLimitPrice,int128 fTriggerPrice,uint32 iDeadline,uint32 flags,uint16 leverageTDR,uint32 executionTimestamp)"
        );

    bytes32 private constant TRADE_BROKER_TYPEHASH =
        keccak256(
            "Order(uint24 iPerpetualId,uint16 brokerFeeTbps,address traderAddr,uint32 iDeadline)"
        );

    /**
     * @notice Creates the hash for an order
     * @param _order the address of perpetual proxy manager.
     * @param _contract The id of perpetual.
     * @param _createOrder true if order is to be executed, false for cancel-order digest
     * @return hash of order and _createOrder-flag
     * */
    function _getDigest(
        IPerpetualOrder.Order memory _order,
        address _contract,
        bool _createOrder
    ) internal view returns (bytes32) {
        /*
         * The DOMAIN_SEPARATOR is a hash that uniquely identifies a
         * smart contract. It is built from a string denoting it as an
         * EIP712 Domain, the name of the token contract, the version,
         * the chainId in case it changes, and the address that the
         * contract is deployed at.
         */
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(NAME)), _getChainId(), _contract)
        );

        // ORDER_TYPEHASH
        bytes32 structHash = _getStructHash(_order);

        bytes32 digest = keccak256(abi.encode(domainSeparator, structHash, _createOrder));

        digest = ECDSA.toEthSignedMessageHash(digest);
        return digest;
    }

    /**
     * @dev Get digest a broker would sign, given an order and perpetual
     * @param _order Order struct
     * @param _contract Address of the perpetual manager
     */
    function _getBrokerDigest(IPerpetualOrder.Order memory _order, address _contract)
        internal
        view
        returns (bytes32)
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(NAME)), _getChainId(), _contract)
        );
        // ORDER_TYPEHASH
        bytes32 structHash = _getStructBrokerHash(_order);
        bytes32 digest = keccak256(abi.encode(domainSeparator, structHash));
        digest = ECDSA.toEthSignedMessageHash(digest);
        return digest;
    }

    /**
     * @dev Chain Id
     */
    function _getChainId() internal view returns (uint256) {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    /**
     * @notice Creates the hash of the order-struct
     * @dev order.referrerAddr is not hashed,
     * because it is to be set by the referrer
     * @param _order : order struct
     * @return bytes32 hash of order
     * */
    function _getStructHash(IPerpetualOrder.Order memory _order) internal pure returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                TRADE_ORDER_TYPEHASH,
                _order.iPerpetualId,
                _order.brokerFeeTbps, // trader needs to sign for the broker fee
                _order.traderAddr,
                _order.brokerAddr, // trader needs to sign for broker
                _order.fAmount,
                _order.fLimitPrice,
                _order.fTriggerPrice,
                _order.iDeadline,
                _order.flags,
                _order.leverageTDR,
                _order.executionTimestamp
            )
        );
        return structHash;
    }

    /**
     * @dev Hash an order struct, used when creating the digest for a broker to sign.
     * @param _order Order struct
     */
    function _getStructBrokerHash(IPerpetualOrder.Order memory _order)
        internal
        pure
        returns (bytes32)
    {
        bytes32 structHash = keccak256(
            abi.encode(
                TRADE_BROKER_TYPEHASH,
                _order.iPerpetualId,
                _order.brokerFeeTbps,
                _order.traderAddr,
                _order.iDeadline
            )
        );
        return structHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPerpetualOrder {
    struct Order {
        uint16 leverageTDR; // 12.43x leverage is represented by 1243 (two-digit integer representation); 0 if deposit and trade separate
        uint16 brokerFeeTbps; // broker can set their own fee
        uint24 iPerpetualId; // global id for perpetual
        address traderAddr; // address of trader
        uint32 executionTimestamp; // normally set to current timestamp; order will not be executed prior to this timestamp.
        address brokerAddr; // address of the broker or zero
        uint32 submittedTimestamp;
        uint32 flags; // order flags
        uint32 iDeadline; //deadline for price (seconds timestamp)
        address referrerAddr; // address of the referrer set by contract
        int128 fAmount; // amount in base currency to be traded
        int128 fLimitPrice; // limit price
        int128 fTriggerPrice; //trigger price. Non-zero for stop orders.
        bytes brokerSignature; //signature of broker (or 0)
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPerpetualFactory {
    function createPerpetual(
        uint8 _iPoolId,
        bytes4[2] calldata _baseQuoteS2,
        bytes4[2] calldata _baseQuoteS3,
        int128[7] calldata _baseParams,
        int128[5] calldata _underlyingRiskParams,
        int128[13] calldata _defaultFundRiskParams,
        uint256 _eCollateralCurrency
    ) external;

    function activatePerpetual(uint24 _perpetualId) external;

    function setPerpetualOracles(
        uint24 _iPerpetualId,
        bytes4[2] calldata _baseQuoteS2,
        bytes4[2] calldata _baseQuoteS3
    ) external;

    function setPerpetualBaseParams(uint24 _iPerpetualId, int128[7] calldata _baseParams) external;

    function setPerpetualRiskParams(
        uint24 _iPerpetualId,
        int128[5] calldata _underlyingRiskParams,
        int128[13] calldata _defaultFundRiskParams
    ) external;

    function setPerpetualParam(
        uint24 _iPerpetualId,
        string memory _varName,
        int128 _value
    ) external;

    function setPerpetualParamPair(
        uint24 _iPerpetualId,
        string memory _name,
        int128 _value1,
        int128 _value2
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPerpetualPoolFactory {
    function setPerpetualPoolFactory(address _shareTokenFactory) external;

    function createLiquidityPool(
        address _marginTokenAddress,
        uint16 _iTargetPoolSizeUpdateTime,
        int128 _fMaxTransferPerConvergencePeriod,
        int128 _fBrokerCollateralLotSize
    ) external returns (uint8);

    function runLiquidityPool(uint8 _liqPoolID) external;

    function setAMMPerpLogic(address _AMMPerpLogic) external;

    function setPoolParam(
        uint8 _poolId,
        string memory _name,
        int128 _value
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPerpetualDepositManager {
    function deposit(
        uint24 _iPerpetualId,
        int128 _fAmount,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes
    ) external payable;

    function depositToDefaultFund(uint8 _poolId, int128 _fAmount) external;

    function brokerDepositToDefaultFund(uint8 _poolId, uint32 _iLots) external;

    function withdrawFromDefaultFund(uint8 _poolId, int128 _fAmount) external;

    function transferEarningsToTreasury(uint8 _poolId, int128 _fAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPerpetualWithdrawAllManager {
    function withdrawAll(
        uint24 _iPerpetualId,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPerpetualLiquidator {
    function liquidateByAMM(
        uint24 _perpetualIndex,
        address _liquidatorAddr,
        address _traderAddr,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes
    ) external payable returns (int128 liquidatedAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPerpetualTreasury {
    struct WithdrawRequest {
        address lp;
        uint256 shareTokens;
        uint64 withdrawTimestamp;
    }

    function addLiquidity(uint8 _iPoolIndex, uint256 _tokenAmount) external;

    function pauseLiquidityProvision(uint8 _poolId, bool _pauseOn) external;

    function addAMMLiquidityToPerpetual(uint24 _iPerpetualId, int128 _fTokenAmount) external;

    function withdrawLiquidity(uint8 _iPoolIndex, uint256 _shareAmount) external;

    function executeLiquidityWithdrawal(uint8 _poolId, address _lpAddr) external;

    function getCollateralTokenAmountForPricing(uint8 _poolId) external view returns (int128);

    function getShareTokenPriceD18(uint8 _poolId) external view returns (uint256 price);

    function getTokenAmountToReturn(uint8 _poolId, uint256 _shareAmount)
        external
        view
        returns (uint256);

    function getWithdrawRequests(
        uint8 poolId,
        uint256 _fromIdx,
        uint256 numRequests
    ) external view returns (WithdrawRequest[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPerpetualSettlement {
    function adjustSettlementPrice(
        uint24 _perpetualId,
        int128 _fSettlementS2,
        int128 _fSettlementS3
    ) external;

    function togglePerpEmergencyState(uint24 _perpetualId) external;

    function settleNextTraderInPool(uint8 _id) external returns (bool);

    function settle(uint24 _perpetualID, address _traderAddr) external;

    function transferValueToTreasury() external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPerpetualWithdrawManager {
    function withdraw(
        uint24 _iPerpetualId,
        int128 _fAmount,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "../interfaces/IPerpetualOrder.sol";

interface IPerpetualTradeLogic {
    function executeTrade(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 _fTraderPos,
        int128 _fTradeAmount,
        int128 _fPrice,
        bool _isClose
    ) external returns (int128);

    function preTrade(IPerpetualOrder.Order memory _order) external returns (int128, int128);

    function distributeFeesLiquidation(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 _fDeltaPositionBC
    ) external returns (int128);

    function distributeFees(IPerpetualOrder.Order memory _order, bool _hasOpened)
        external
        returns (int128);

    function validateStopPrice(
        bool _isLong,
        int128 _fMarkPrice,
        int128 _fTriggerPrice
    ) external pure;

    function getMaxSignedOpenTradeSizeForPos(
        uint24 _perpetualId,
        int128 _fCurrentTraderPos,
        bool _isBuy
    ) external view returns (int128);

    function queryPerpetualPrice(
        uint24 _iPerpetualId,
        int128 _fTradeAmountBC,
        int128[2] calldata _fIndexPrice
    ) external view returns (int128);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../functions/AMMPerpLogic.sol";

interface IAMMPerpLogic {
    function volatilitySpread(
        uint16 _jumpTbps,
        uint16 _MinimalSpreadTbps,
        uint256 _numBlockSinceJump,
        int128 _fLambda
    ) external pure returns (int128);

    function holdingPeriodPenalty(uint256 _numBlockSinceLastOpen, int128 _fLambda)
        external
        pure
        returns (uint16);

    function calculateDefaultFundSize(
        int128[2] calldata _fK2AMM,
        int128 _fk2Trader,
        int128 _fCoverN,
        int128[2] calldata fStressRet2,
        int128[2] calldata fStressRet3,
        int128[2] calldata fIndexPrices,
        AMMPerpLogic.CollateralCurrency _eCCY
    ) external pure returns (int128);

    function calculateRiskNeutralPD(
        AMMPerpLogic.AMMVariables memory _ammVars,
        AMMPerpLogic.MarketVariables calldata _mktVars,
        int128 _fTradeAmount,
        bool _withCDF
    ) external view returns (int128, int128);

    function calculateBoundedSlippage(
        AMMPerpLogic.AMMVariables memory _ammVars,
        int128 _fTradeAmount
    ) external view returns (int128);

    function calculatePerpetualPrice(
        AMMPerpLogic.AMMVariables calldata _ammVars,
        AMMPerpLogic.MarketVariables calldata _mktVars,
        int128 _fTradeAmount,
        int128 _fBidAskSpread,
        int128 _fIncentiveSpread
    ) external view returns (int128);

    function getTargetCollateralM1(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);

    function getTargetCollateralM2(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);

    function getTargetCollateralM3(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);

    function getDepositAmountForLvgPosition(
        int128 _fPosition0,
        int128 _fBalance0,
        int128 _fTradeAmount,
        int128 _fTargetLeverage,
        int128 _fPrice,
        int128 _fS2Mark,
        int128 _fS3
    ) external pure returns (int128);

    function relativeFeeToCCAmount(
        int128 _fDeltaPos,
        int128 _fTreasuryFeeRate,
        int128 _fPnLPartRate,
        int128 _fReferralRebate,
        address _referrerAddr
    )
        external
        pure
        returns (
            int128,
            int128,
            int128
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../core/PerpStorage.sol";
import "../../interface/IShareTokenFactory.sol";

interface IPerpetualGetter {
    struct PerpetualStaticInfo {
        uint24 id;
        address limitOrderBookAddr;
        int32 fInitialMarginRate;
        int32 fMaintenanceMarginRate;
        uint8 perpetualState;
        AMMPerpLogic.CollateralCurrency collCurrencyType;
        bytes4 S2BaseCCY; //base currency of S2
        bytes4 S2QuoteCCY; //quote currency of S2
        bytes4 S3BaseCCY; //base currency of S3
        bytes4 S3QuoteCCY; //quote currency of S3
        int128 fLotSizeBC;
        int128 fReferralRebateCC;
        bytes32[] priceIds;
        bool[] isPyth;
    }

    function getPoolCount() external view returns (uint8);

    function getPerpetualId(uint8 _poolId, uint8 _perpetualIndex) external view returns (uint24);

    function getLiquidityPool(uint8 _poolId)
        external
        view
        returns (PerpStorage.LiquidityPoolData memory);

    function getLiquidityPools(uint8 _poolIdFrom, uint8 _poolIdTo)
        external
        view
        returns (PerpStorage.LiquidityPoolData[] memory);

    function getPoolIdByPerpetualId(uint24 _perpetualId) external view returns (uint8);

    function getPerpetual(uint24 _perpetualId)
        external
        view
        returns (PerpStorage.PerpetualData memory);

    function getPerpetuals(uint24[] calldata perpetualIds)
        external
        view
        returns (PerpStorage.PerpetualData[] memory);

    function queryMidPrices(uint24[] calldata perpetualIds, int128[] calldata idxPriceDataPairs)
        external
        view
        returns (int128[] memory);

    function getMarginAccount(uint24 _perpetualId, address _traderAddress)
        external
        view
        returns (PerpStorage.MarginAccount memory);

    function isActiveAccount(uint24 _perpetualId, address _traderAddress)
        external
        view
        returns (bool);

    function getAMMPerpLogic() external view returns (address);

    function getShareTokenFactory() external view returns (IShareTokenFactory);

    function getActivePerpAccounts(uint24 _perpetualId) external view returns (address[] memory);

    function getPerpetualCountInPool(uint8 _poolId) external view returns (uint8);

    function getAMMState(uint24 _perpetualId, int128[2] calldata _fIndexPrice)
        external
        view
        returns (int128[15] memory);

    function getTraderState(
        uint24 _perpetualId,
        address _traderAddress,
        int128[2] calldata _fIndexPrice
    ) external view returns (int128[11] memory);

    function getActivePerpAccountsByChunks(
        uint24 _perpetualId,
        uint256 _from,
        uint256 _to
    ) external view returns (address[] memory);

    function isTraderMaintenanceMarginSafe(uint24 _perpetualId, address _traderAddress)
        external
        view
        returns (bool);

    function countActivePerpAccounts(uint24 _perpetualId) external view returns (uint256);

    function getOraclePrice(bytes4[2] memory _baseQuote) external view returns (int128 fPrice);

    function getOracleFactory() external view returns (address);

    function getTreasuryAddress() external view returns (address);

    function getOrderBookFactoryAddress() external view returns (address);

    function getOrderBookAddress(uint24 _perpetualId) external view returns (address);

    function isMarketClosed(bytes4 _baseCurrency, bytes4 _quoteCurrency)
        external
        view
        returns (bool);

    function isPerpMarketClosed(uint24 _perpetualId) external view returns (bool isClosed);

    function getPriceInfo(uint24 _perpetualId)
        external
        view
        returns (bytes32[] memory, bool[] memory);

    function getPoolStaticInfo(uint8 _poolFromIdx, uint8 _poolToIdx)
        external
        view
        returns (
            uint24[][] memory,
            address[] memory,
            address[] memory,
            address _oracleFactoryAddress
        );

    function getPerpetualStaticInfo(uint24[] calldata perpetualIds)
        external
        view
        returns (PerpetualStaticInfo[] memory);

    function getLiquidatableAccounts(uint24 _perpetualId, int128[2] calldata _fIndexPrice)
        external
        view
        returns (address[] memory unsafeAccounts);

    function getNextLiquidatableTrader(uint24 _perpetualId, int128[2] calldata _fIndexPrice)
        external
        view
        returns (address traderAddr);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPerpetualUpdateLogic {
    function updateAMMTargetFundSize(uint24 _iPerpetualId, int128 fTargetFundSize) external;

    function updateDefaultFundTargetSizeRandom(uint8 _iPoolIndex) external;

    function updateDefaultFundTargetSize(uint24 _iPerpetualId) external;

    function updateFundingAndPricesBefore(uint24 _iPerpetualId0, uint24 _iPerpetualId1) external;

    function updateFundingAndPricesAfter(uint24 _iPerpetualId0, uint24 _iPerpetualId1) external;

    function setNormalState(uint24 _iPerpetualId) external;

    function setInitialFundAllocationWeight(uint24 _iPerpetualId) external;

    /**
     * Set emergency state
     * @param _iPerpetualId Perpetual id
     */
    function setEmergencyState(uint24 _iPerpetualId) external;

    /**
     * @notice Set external treasury (DAO)
     * @param _treasury treasury address
     */
    function setTreasury(address _treasury) external;

    /**
     * @notice Set order book factory (DAO)
     * @param _orderBookFactory order book factory address
     */
    function setOrderBookFactory(address _orderBookFactory) external;

    /**
     * @notice Set oracle factory (DAO)
     * @param _oracleFactory oracle factory address
     */
    function setOracleFactory(address _oracleFactory) external;

    /**
     * @notice Set delay for trades to be executed
     * @param _delay    delay in number of blocks
     */
    function setBlockDelay(uint8 _delay) external;

    /**
     * @notice Submits price updates to the feeds used by a given perpetual.
     * @dev Reverts if the submission does not match the perpetual or
     * if the feed rejects it for a reason other than being unnecessary.
     * If this function returns false, sender is not charged msg.value.
     * @param _perpetualId Perpetual Id
     * @param _updateData Data to send to price feeds
     * @param _publishTimes Publish timestamps
     * @param _maxAcceptableFeedAge Maximum age of update in seconds
     */
    function updatePriceFeeds(
        uint24 _perpetualId,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes,
        uint256 _maxAcceptableFeedAge
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./IPerpetualOrder.sol";

/**
 * @notice  The libraryEvents defines events that will be raised from modules (contract/modules).
 * @dev     DO REMEMBER to add new events in modules here.
 */
interface ILibraryEvents {
    // PerpetualModule
    event Clear(uint24 indexed perpetualId, address indexed trader);
    event Settle(uint24 indexed perpetualId, address indexed trader, int256 amount);
    event SetNormalState(uint24 indexed perpetualId);
    event SetEmergencyState(
        uint24 indexed perpetualId,
        int128 fSettlementMarkPremiumRate,
        int128 fSettlementS2Price,
        int128 fSettlementS3Price
    );
    event SettleState(uint24 indexed perpetualId);
    event SetClearedState(uint24 indexed perpetualId);
    event UpdateUnitAccumulatedFunding(uint24 perpetualId, int128 unitAccumulativeFunding);

    // Participation pool
    event LiquidityAdded(
        uint64 indexed poolId,
        address indexed user,
        uint256 tokenAmount,
        uint256 shareAmount
    );
    event LiquidityProvisionPaused(bool pauseOn, uint8 poolId);
    event LiquidityRemoved(
        uint64 indexed poolId,
        address indexed user,
        uint256 tokenAmount,
        uint256 shareAmount
    );
    event LiquidityWithdrawalInitiated(
        uint64 indexed poolId,
        address indexed user,
        uint256 shareAmount
    );

    // setters
    // oracles
    event SetOracles(uint24 indexed perpetualId, bytes4[2] baseQuoteS2, bytes4[2] baseQuoteS3);
    // perp parameters
    event SetPerpetualBaseParameters(uint24 indexed perpetualId, int128[7] baseParams);
    event SetPerpetualRiskParameters(
        uint24 indexed perpetualId,
        int128[5] underlyingRiskParams,
        int128[13] defaultFundRiskParams
    );
    event SetParameter(uint24 indexed perpetualId, string name, int128 value);
    event SetParameterPair(uint24 indexed perpetualId, string name, int128 value1, int128 value2);
    // pool parameters
    event SetPoolParameter(uint8 indexed poolId, string name, int128 value);

    event TransferAddressTo(string name, address oldOBFactory, address newOBFactory); // only governance
    event SetBlockDelay(uint8 delay);

    // fee structure parameters
    event SetBrokerDesignations(uint32[] designations, uint16[] fees);
    event SetBrokerTiers(uint256[] tiers, uint16[] feesTbps);
    event SetTraderTiers(uint256[] tiers, uint16[] feesTbps);
    event SetTraderVolumeTiers(uint256[] tiers, uint16[] feesTbps);
    event SetBrokerVolumeTiers(uint256[] tiers, uint16[] feesTbps);
    event SetUtilityToken(address tokenAddr);

    event BrokerLotsTransferred(
        uint8 indexed poolId,
        address oldOwner,
        address newOwner,
        uint32 numLots
    );
    event BrokerVolumeTransferred(
        uint8 indexed poolId,
        address oldOwner,
        address newOwner,
        int128 fVolume
    );

    // funds
    event UpdateAMMFundCash(
        uint24 indexed perpetualId,
        int128 fNewAMMFundCash,
        int128 fNewLiqPoolTotalAMMFundsCash
    );
    event UpdateParticipationFundCash(
        uint8 indexed poolId,
        int128 fDeltaAmountCC,
        int128 fNewFundCash
    );
    event UpdateDefaultFundCash(uint8 indexed poolId, int128 fDeltaAmountCC, int128 fNewFundCash);

    // brokers
    event UpdateBrokerAddedCash(uint8 indexed poolId, uint32 iLots, uint32 iNewBrokerLots);

    // TradeModule

    event Trade(
        uint24 indexed perpetualId,
        address indexed trader,
        bytes16 indexed positionId,
        IPerpetualOrder.Order order,
        bytes32 orderDigest,
        int128 newPositionSizeBC,
        int128 price,
        int128 fFeeCC,
        int128 fPnlCC
    );

    event UpdateMarginAccount(
        uint24 indexed perpetualId,
        address indexed trader,
        bytes16 indexed positionId,
        int128 fPositionBC,
        int128 fCashCC,
        int128 fLockedInValueQC,
        int128 fFundingPaymentCC,
        int128 fOpenInterestBC
    );

    event Liquidate(
        uint24 perpetualId,
        address indexed liquidator,
        address indexed trader,
        bytes16 indexed positionId,
        int128 amountLiquidatedBC,
        int128 liquidationPrice,
        int128 newPositionSizeBC,
        int128 fFeeCC,
        int128 fPnlCC
    );

    event TransferFeeToReferrer(
        uint24 indexed perpetualId,
        address indexed trader,
        address indexed referrer,
        int128 referralRebate
    );
    event TransferFeeToBroker(uint24 indexed perpetualId, address indexed broker, int128 feeCC);

    event PerpetualLimitOrderCancelled(uint24 indexed perpetualId, bytes32 indexed orderHash);
    event DistributeFees(
        uint8 indexed poolId,
        uint24 indexed perpetualId,
        address indexed trader,
        int128 protocolFeeCC,
        int128 participationFundFeeCC
    );

    // PerpetualManager/factory
    event RunLiquidityPool(uint8 _liqPoolID);
    event LiquidityPoolCreated(
        uint8 id,
        address marginTokenAddress,
        address shareTokenAddress,
        uint16 iTargetPoolSizeUpdateTime,
        int128 fMaxTransferPerConvergencePeriod,
        int128 fBrokerCollateralLotSize
    );
    event PerpetualCreated(
        uint8 poolId,
        uint24 id,
        int128[7] baseParams,
        int128[5] underlyingRiskParams,
        int128[13] defaultFundRiskParams,
        uint256 eCollateralCurrency
    );

    // emit tokenAddr==0x0 if the token paid is the aggregated token, otherwise the address of the token
    event TokensDeposited(uint24 indexed perpetualId, address indexed trader, int128 amount);
    event TokensWithdrawn(uint24 indexed perpetualId, address indexed trader, int128 amount);

    event UpdateMarkPrice(
        uint24 indexed perpetualId,
        int128 fMidPricePremium,
        int128 fMarkPricePremium,
        int128 fSpotIndexPrice
    );

    event UpdateFundingRate(uint24 indexed perpetualId, int128 fFundingRate);

    event UpdateAMMFundTargetSize(
        uint24 indexed perpetualId,
        uint8 indexed liquidityPoolId,
        int128 fAMMFundCashCCInPerpetual,
        int128 fTargetAMMFundSizeInPerpetual,
        int128 fAMMFundCashCCInPool,
        int128 fTargetAMMFundSizeInPool
    );

    event UpdateDefaultFundTargetSize(
        uint8 indexed liquidityPoolId,
        int128 fDefaultFundCashCC,
        int128 fTargetDFSize
    );

    event UpdateReprTradeSizes(
        uint24 indexed perpetualId,
        int128 fCurrentTraderExposureEMA,
        int128 fCurrentAMMExposureEMAShort,
        int128 fCurrentAMMExposureEMALong
    );

    event TransferEarningsToTreasury(uint8 _poolId, int128 fEarnings, int128 newDefaultFundSize);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPerpetualRebalanceLogic {
    function rebalance(uint24 _iPerpetualId) external;

    function decreasePoolCash(uint8 _iPoolIdx, int128 _fAmount) external;

    function increasePoolCash(uint8 _iPoolIdx, int128 _fAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IPerpetualOrder.sol";

interface IPerpetualMarginLogic is IPerpetualOrder {
    function depositMarginForOpeningTrade(
        uint24 _iPerpetualId,
        int128 _fDepositRequired,
        Order memory _order
    ) external returns (bool);

    function withdrawDepositFromMarginAccount(uint24 _iPerpetualId, address _traderAddr) external;

    function reduceMarginCollateral(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 _fAmountToWithdraw
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IPerpetualOrder.sol";

interface IPerpetualLimitTradeManager is IPerpetualOrder {
    function tradeViaOrderBook(Order calldata _order) external returns (bool);

    function chargePostingFee(Order calldata _order, uint16 _feeTbps) external;

    function rebatePostingFee(Order calldata _order, uint16 _feeTbps) external;

    function executeCancelOrder(uint24 _perpetualId, bytes32 _digest) external;

    function isOrderExecuted(bytes32 digest) external view returns (bool);

    function isOrderCanceled(bytes32 digest) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "../interfaces/IPerpetualOrder.sol";
import "../../interface/ISpotOracle.sol";

interface IPerpetualBrokerFeeLogic {
    function determineExchangeFee(IPerpetualOrder.Order memory _order)
        external
        view
        returns (uint16);

    function updateVolumeEMAOnNewTrade(
        uint24 _iPerpetualId,
        address _traderAddr,
        address _brokerAddr,
        int128 _tradeAmountBC
    ) external;

    function queryExchangeFee(
        uint8 _poolId,
        address _traderAddr,
        address _brokerAddr
    ) external view returns (uint16);

    function splitProtocolFee(uint16 fee) external pure returns (int128, int128);

    function setFeesForDesignation(uint32[] calldata _designations, uint16[] calldata _fees)
        external;

    function getLastPerpetualBaseToUSDConversion(uint24 _iPerpetualId)
        external
        view
        returns (int128);

    function getFeeForTraderVolume(uint8 _poolId, address _traderAddr)
        external
        view
        returns (uint16);

    function getFeeForBrokerVolume(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (uint16);

    function setOracleFactoryForPerpetual(uint24 _iPerpetualId, address _oracleAddr) external;

    function setBrokerTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setTraderTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setTraderVolumeTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setBrokerVolumeTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setUtilityTokenAddr(address tokenAddr) external;

    function getBrokerInducedFee(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (uint16);

    function getBrokerDesignation(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (uint32);

    function getFeeForBrokerDesignation(uint32 _brokerDesignation) external view returns (uint16);

    function getFeeForBrokerStake(address brokerAddr) external view returns (uint16);

    function getFeeForTraderStake(address traderAddr) external view returns (uint16);

    function getCurrentTraderVolume(uint8 _poolId, address _traderAddr)
        external
        view
        returns (int128);

    function getCurrentBrokerVolume(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (int128);

    function transferBrokerLots(
        uint8 _poolId,
        address _transferToAddr,
        uint32 _lots
    ) external;

    function transferBrokerOwnership(uint8 _poolId, address _transferToAddr) external;

    function setInitialVolumeForFee(
        uint8 _poolId,
        address _brokerAddr,
        uint16 _feeTbps
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../libraries/ABDKMath64x64.sol";
import "../../libraries/ConverterDec18.sol";
import "../../perpetual/interfaces/IAMMPerpLogic.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AMMPerpLogic is Ownable, IAMMPerpLogic {
    using ABDKMath64x64 for int128;
    /* solhint-disable const-name-snakecase */
    int128 internal constant ONE_64x64 = 0x10000000000000000; // 2^64
    int128 internal constant TWO_64x64 = 0x20000000000000000; // 2*2^64
    int128 internal constant FOUR_64x64 = 0x40000000000000000; //4*2^64
    int128 internal constant HALF_64x64 = 0x8000000000000000; //0.5*2^64
    int128 internal constant TWENTY_64x64 = 0x140000000000000000; //20*2^64
    int128 private constant CDF_CONST_0 = 0x023a6ce358298c;
    int128 private constant CDF_CONST_1 = -0x216c61522a6f3f;
    int128 private constant CDF_CONST_2 = 0xc9320d9945b6c3;
    int128 private constant CDF_CONST_3 = -0x01bcfd4bf0995aaf;
    int128 private constant CDF_CONST_4 = -0x086de76427c7c501;
    int128 private constant CDF_CONST_5 = 0x749741d084e83004;
    int128 private constant CDF_CONST_6 = 0xcc42299ea1b28805;
    int128 private constant CDF_CONST_7 = 0x0281b263fec4e0a007;
    /* solhint-enable const-name-snakecase */

    enum CollateralCurrency {
        QUOTE,
        BASE,
        QUANTO
    }

    struct AMMVariables {
        // all variables are
        // signed 64.64-bit fixed point number
        int128 fLockedValue1; // L1 in quote currency
        int128 fPoolM1; // M1 in quote currency
        int128 fPoolM2; // M2 in base currency
        int128 fPoolM3; // M3 in quanto currency
        int128 fAMM_K2; // AMM exposure (positive if trader long)
        int128 fCurrentTraderExposureEMA; // current average unsigned trader exposure
    }

    struct MarketVariables {
        int128 fIndexPriceS2; // base index
        int128 fIndexPriceS3; // quanto index
        int128 fSigma2; // standard dev of base currency
        int128 fSigma3; // standard dev of quanto currency
        int128 fRho23; // correlation base/quanto currency
    }

    /**
     * Calculate a half-spread that depends on past jumps
     * @dev if more than 30 seconds the function returns minimal spread.
     * Accuracy of this is obviously parametrization dependent
     * @param _jumpTbps    jump spread based on return of oracle price
     * @param _minimalSpreadTbps   minimal spread the EMA converges to
     * @param _numSecSinceJump    time passed since jump
     * @param _fLambda   convergence
     * @return fHalfSpread (int128)
     */
    function volatilitySpread(
        uint16 _jumpTbps,
        uint16 _minimalSpreadTbps,
        uint256 _numSecSinceJump,
        int128 _fLambda
    ) external pure returns (int128) {
        // v0 = (1-L**numBlocksSinceJump) * minimalSpread
        // v1 = jump*L**numBlocksSinceJump
        // return v0+v1
        if (_numSecSinceJump > 30) {
            return ConverterDec18.tbpsToABDK(_minimalSpreadTbps);
        }
        return _emaWithTimeJumps(_minimalSpreadTbps, _jumpTbps, _fLambda, _numSecSinceJump);
    }

    /**
     * Calculate the penalty for closing a position before the holding period is satisfied
     * @dev The penalty is 8 bps for same second and decreases exponentially to 0 at 32 seconds
     * @param _secondsSinceLastOpen how much time passed since the position was opened
     * @param _fLambda lambda for the exponential decay: penalty_nSeconds ~ lambda ^ nSeconds
     * @return penalty Penalty in tbps
     */
    function holdingPeriodPenalty(uint256 _secondsSinceLastOpen, int128 _fLambda)
        external
        pure
        returns (uint16 penalty)
    {
        if (_secondsSinceLastOpen > 32) {
            return 0;
        }
        penalty = ConverterDec18.ABDKToTbps(
            _emaWithTimeJumps(0, 80, _fLambda, _secondsSinceLastOpen)
        );
    }

    /**
     * Calculate a EWMA when the last observation happened n periods ago
     * @dev Given is x_t = (1 - lambda) * mean + lambda * x_t-1, and x_0 = _newObs
     * it returns the value of x_deltaTime
     * @param _mean long term mean
     * @param _newObs observation deltaTime periods ago
     * @param _fLambda lambda of the EWMA
     * @param _deltaTime number of periods elapsed
     * @return result EWMA at deltaPeriods
     */
    function _emaWithTimeJumps(
        uint16 _mean,
        uint16 _newObs,
        int128 _fLambda,
        uint256 _deltaTime
    ) internal pure returns (int128 result) {
        _fLambda = _fLambda.pow(_deltaTime);
        result = ConverterDec18.tbpsToABDK(_mean).mul(ONE_64x64.sub(_fLambda));
        result = result.add(_fLambda.mul(ConverterDec18.tbpsToABDK(_newObs)));
    }

    /**
     *  Calculate the normal CDF value of _fX, i.e.,
     *  k=P(X<=_fX), for X~normal(0,1)
     *  The approximation is of the form
     *  Phi(x) = 1 - phi(x) / (x + exp(p(x))),
     *  where p(x) is a polynomial of degree 6
     *  @param _fX signed 64.64-bit fixed point number
     *  @return fY approximated normal-cdf evaluated at X
     */
    function _normalCDF(int128 _fX) internal pure returns (int128 fY) {
        bool isNegative = _fX < 0;
        if (isNegative) {
            _fX = _fX.neg();
        }
        if (_fX > FOUR_64x64) {
            fY = int128(0);
        } else {
            fY = _fX.mul(CDF_CONST_0).add(CDF_CONST_1);
            fY = _fX.mul(fY).add(CDF_CONST_2);
            fY = _fX.mul(fY).add(CDF_CONST_3);
            fY = _fX.mul(fY).add(CDF_CONST_4);
            fY = _fX.mul(fY).add(CDF_CONST_5).mul(_fX).neg().exp();
            fY = fY.mul(CDF_CONST_6).add(_fX);
            fY = _fX.mul(_fX).mul(HALF_64x64).neg().exp().div(CDF_CONST_7).div(fY);
        }
        if (!isNegative) {
            fY = ONE_64x64.sub(fY);
        }
        return fY;
    }

    /**
     *  Calculate the target size for the default fund
     *
     *  @param _fK2AMM       signed 64.64-bit fixed point number, Conservative negative[0]/positive[1] AMM exposure
     *  @param _fk2Trader    signed 64.64-bit fixed point number, Conservative (absolute) trader exposure
     *  @param _fCoverN      signed 64.64-bit fixed point number, cover-n rule for default fund parameter
     *  @param fStressRet2   signed 64.64-bit fixed point number, negative[0]/positive[1] stress returns for base/quote pair
     *  @param fStressRet3   signed 64.64-bit fixed point number, negative[0]/positive[1] stress returns for quanto/quote currency
     *  @param fIndexPrices  signed 64.64-bit fixed point number, spot price for base/quote[0] and quanto/quote[1] pairs
     *  @param _eCCY         enum that specifies in which currency the collateral is held: QUOTE, BASE, QUANTO
     *  @return approximated normal-cdf evaluated at X
     */
    function calculateDefaultFundSize(
        int128[2] calldata _fK2AMM,
        int128 _fk2Trader,
        int128 _fCoverN,
        int128[2] calldata fStressRet2,
        int128[2] calldata fStressRet3,
        int128[2] calldata fIndexPrices,
        AMMPerpLogic.CollateralCurrency _eCCY
    ) external pure override returns (int128) {
        require(_fK2AMM[0] < 0, "_fK2AMM[0] must be negative");
        require(_fK2AMM[1] > 0, "_fK2AMM[1] must be positive");
        require(_fk2Trader > 0, "_fk2Trader must be positive");

        int128[2] memory fEll;
        // downward stress scenario
        fEll[0] = (_fK2AMM[0].abs().add(_fk2Trader.mul(_fCoverN))).mul(
            ONE_64x64.sub((fStressRet2[0].exp()))
        );
        // upward stress scenario
        fEll[1] = (_fK2AMM[1].abs().add(_fk2Trader.mul(_fCoverN))).mul(
            (fStressRet2[1].exp().sub(ONE_64x64))
        );
        int128 fIstar;
        if (_eCCY == AMMPerpLogic.CollateralCurrency.BASE) {
            fIstar = fEll[0].div(fStressRet2[0].exp());
            int128 fI2 = fEll[1].div(fStressRet2[1].exp());
            if (fI2 > fIstar) {
                fIstar = fI2;
            }
        } else if (_eCCY == AMMPerpLogic.CollateralCurrency.QUANTO) {
            fIstar = fEll[0].div(fStressRet3[0].exp());
            int128 fI2 = fEll[1].div(fStressRet3[1].exp());
            if (fI2 > fIstar) {
                fIstar = fI2;
            }
            fIstar = fIstar.mul(fIndexPrices[0].div(fIndexPrices[1]));
        } else {
            assert(_eCCY == AMMPerpLogic.CollateralCurrency.QUOTE);
            if (fEll[0] > fEll[1]) {
                fIstar = fEll[0].mul(fIndexPrices[0]);
            } else {
                fIstar = fEll[1].mul(fIndexPrices[0]);
            }
        }
        return fIstar;
    }

    /**
     *  Calculate the risk neutral Distance to Default (Phi(DD)=default probability) when
     *  there is no quanto currency collateral.
     *  We assume r=0 everywhere.
     *  The underlying distribution is log-normal, hence the log below.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param fSigma2 current Market variables (price&params)
     *  @param _fSign signed 64.64-bit fixed point number, sign of denominator of distance to default
     *  @return _fThresh signed 64.64-bit fixed point number, number for which the log is the unnormalized distance to default
     */
    function _calculateRiskNeutralDDNoQuanto(
        int128 fSigma2,
        int128 _fSign,
        int128 _fThresh
    ) internal pure returns (int128) {
        require(_fThresh > 0, "argument to log must be >0");
        int128 _fLogTresh = _fThresh.ln();
        int128 fSigma2_2 = fSigma2.mul(fSigma2);
        int128 fMean = fSigma2_2.div(TWO_64x64).neg();
        int128 fDistanceToDefault = ABDKMath64x64.sub(_fLogTresh, fMean).div(fSigma2);
        // because 1-Phi(x) = Phi(-x) we change the sign if _fSign<0
        // now we would like to get the normal cdf of that beast
        if (_fSign < 0) {
            fDistanceToDefault = fDistanceToDefault.neg();
        }
        return fDistanceToDefault;
    }

    /**
     *  Calculate the standard deviation for the random variable
     *  evolving when quanto currencies are involved.
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _mktVars current Market variables (price&params)
     *  @param _fC3 signed 64.64-bit fixed point number current AMM/Market variables
     *  @param _fC3_2 signed 64.64-bit fixed point number, squared fC3
     *  @return fSigmaZ standard deviation, 64.64-bit fixed point number
     */
    function _calculateStandardDeviationQuanto(
        MarketVariables memory _mktVars,
        int128 _fC3,
        int128 _fC3_2
    ) internal pure returns (int128 fSigmaZ) {
        int128 fVarA;
        {
            // fVarA = (exp(sigma2^2) - 1)
            int128 fSigma2_2 = _mktVars.fSigma2.mul(_mktVars.fSigma2);
            fVarA = ABDKMath64x64.sub(fSigma2_2.exp(), ONE_64x64);
        }
        int128 fVarB;
        {
            // fVarB1 = exp(sigma2*sigma3*rho)
            int128 fVarB1 = (_mktVars.fSigma2.mul(_mktVars.fSigma3).mul(_mktVars.fRho23)).exp();
            // fVarB = 2*(exp(sigma2*sigma3*rho) - 1)
            fVarB = ABDKMath64x64.sub(fVarB1, ONE_64x64).mul(TWO_64x64);
        }
        int128 fVarC;
        {
            // fVarC = exp(sigma3^2) - 1
            int128 fSigma3_2 = _mktVars.fSigma3.mul(_mktVars.fSigma3);
            fVarC = ABDKMath64x64.sub(fSigma3_2.exp(), ONE_64x64);
        }
        // sigmaZ = fVarA*C^2 + fVarB*C + fVarC
        fSigmaZ = ABDKMath64x64.add(fVarA.mul(_fC3_2), fVarB.mul(_fC3)).add(fVarC);
        fSigmaZ = fSigmaZ.sqrt();
        return fSigmaZ;
    }

    /**
     *  Calculate the risk neutral Distance to Default (Phi(DD)=default probability) when
     *  presence of quanto currency collateral.
     *
     *  We approximate the distribution with a normal distribution
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number
     *  @param _ammVars current AMM/Market variables
     *  @param _mktVars current Market variables (price&params)
     *  @param _fSign 64.64-bit fixed point number, current AMM/Market variables
     *  @return _fLambdasigned 64.64-bit fixed point number
     */
    function _calculateRiskNeutralDDWithQuanto(
        AMMVariables memory _ammVars,
        MarketVariables memory _mktVars,
        int128 _fSign,
        int128 _fThresh
    ) internal pure returns (int128) {
        require(_fSign > 0, "no sign in quanto case");
        // 1) Calculate C3
        int128 fC3 = _mktVars.fIndexPriceS2.mul(_ammVars.fPoolM2.sub(_ammVars.fAMM_K2)).div(
            _ammVars.fPoolM3.mul(_mktVars.fIndexPriceS3)
        );
        int128 fC3_2 = fC3.mul(fC3);

        // 2) Calculate Variance
        int128 fSigmaZ = _calculateStandardDeviationQuanto(_mktVars, fC3, fC3_2);

        // 3) Calculate mean
        int128 fMean = ABDKMath64x64.add(fC3, ONE_64x64);
        // 4) Distance to default
        int128 fDistanceToDefault = ABDKMath64x64.sub(_fThresh, fMean).div(fSigmaZ);
        return fDistanceToDefault;
    }

    function calculateRiskNeutralPD(
        AMMVariables memory _ammVars,
        MarketVariables calldata _mktVars,
        int128 _fTradeAmount,
        bool _withCDF
    ) external view virtual override returns (int128, int128) {
        return _calculateRiskNeutralPD(_ammVars, _mktVars, _fTradeAmount, _withCDF);
    }

    /**
     *  Calculate the risk neutral default probability (>=0).
     *  Function decides whether pricing with or without quanto CCY is chosen.
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars         current AMM variables.
     *  @param _mktVars         current Market variables (price&params)
     *  @param _fTradeAmount    Trade amount (can be 0), hence amounts k2 are not already factored in
     *                          that is, function will set K2:=K2+k2, L1:=L1+k2*s2 (k2=_fTradeAmount)
     *  @param _withCDF         bool. If false, the normal-cdf is not evaluated (in case the caller is only
     *                          interested in the distance-to-default, this saves calculations)
     *  @return (default probabilit, distance to default) ; 64.64-bit fixed point numbers
     */
    function _calculateRiskNeutralPD(
        AMMVariables memory _ammVars,
        MarketVariables calldata _mktVars,
        int128 _fTradeAmount,
        bool _withCDF
    ) internal pure returns (int128, int128) {
        int128 dL = _fTradeAmount.mul(_mktVars.fIndexPriceS2);
        int128 dK = _fTradeAmount;
        _ammVars.fLockedValue1 = _ammVars.fLockedValue1.add(dL);
        _ammVars.fAMM_K2 = _ammVars.fAMM_K2.add(dK);
        // -L1 - k*s2 - M1
        int128 fNumerator = (_ammVars.fLockedValue1.neg()).sub(_ammVars.fPoolM1);
        // s2*(M2-k2-K2) if no quanto, else M3 * s3
        int128 fDenominator = _ammVars.fPoolM3 == 0
            ? (_ammVars.fPoolM2.sub(_ammVars.fAMM_K2)).mul(_mktVars.fIndexPriceS2)
            : _ammVars.fPoolM3.mul(_mktVars.fIndexPriceS3);

        // handle cases when denominator close to zero
        // or when we have opposite signs (to avoid ln(-|value|))
        // when M3 > 0, denominator is always > 0
        int128 fThresh = fDenominator == 0 ? int128(0) : fNumerator.div(fDenominator);
        if (fThresh <= 0 && _ammVars.fPoolM3 == 0) {
            if (fNumerator <= 0 || (fThresh == 0 && fDenominator > 0)) {
                return (int128(0), TWENTY_64x64.neg());
            } else {
                return (int128(ONE_64x64), TWENTY_64x64);
            }
        }
        // sign tells us whether we consider norm.cdf(f(threshold)) or 1-norm.cdf(f(threshold))
        // we recycle fDenominator to store the sign since it's no longer used
        fDenominator = fDenominator < 0 ? ONE_64x64.neg() : ONE_64x64;
        int128 dd = _ammVars.fPoolM3 == 0
            ? _calculateRiskNeutralDDNoQuanto(_mktVars.fSigma2, fDenominator, fThresh)
            : _calculateRiskNeutralDDWithQuanto(_ammVars, _mktVars, fDenominator, fThresh);

        int128 q;
        if (_withCDF) {
            q = _normalCDF(dd);
        }
        // undo changing the struct
        return (q, dd);
    }

    function calculateBoundedSlippage(AMMVariables calldata _ammVars, int128 _fTradeAmount)
        external
        view
        virtual
        override
        returns (int128)
    {
        return _calculateBoundedSlippage(_ammVars, _fTradeAmount);
    }

    /**
     *  Calculate additional/non-risk based slippage.
     *  Ensures slippage is bounded away from zero for small trades,
     *  and plateaus for larger-than-average trades, so that price becomes risk based.
     *
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars current AMM variables - we need the current average exposure per trader
     *  @param _fTradeAmount 64.64-bit fixed point number, signed size of trade
     *  @return 64.64-bit fixed point number, a number between minus one and one
     */
    function _calculateBoundedSlippage(AMMVariables calldata _ammVars, int128 _fTradeAmount)
        internal
        pure
        returns (int128)
    {
        int128 fTradeSizeEMA = _ammVars.fCurrentTraderExposureEMA;
        int128 fSlippageSize = ONE_64x64;
        if (_fTradeAmount.abs() < fTradeSizeEMA) {
            fSlippageSize = fSlippageSize.sub(_fTradeAmount.abs().div(fTradeSizeEMA));
            fSlippageSize = ONE_64x64.sub(fSlippageSize.mul(fSlippageSize));
        }
        return _fTradeAmount > 0 ? fSlippageSize : fSlippageSize.neg();
    }

    /**
     *  Calculate AMM price.
     *
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars current AMM variables.
     *  @param _mktVars current Market variables (price&params)
     *                 Trader amounts k2 must already be factored in
     *                 that is, K2:=K2+k2, L1:=L1+k2*s2
     *  @param _fTradeAmount 64.64-bit fixed point number, signed size of trade
     *  @param _fHBidAskSpread half bid-ask spread, 64.64-bit fixed point number
     *  @return 64.64-bit fixed point number, AMM price
     */
    function calculatePerpetualPrice(
        AMMVariables calldata _ammVars,
        MarketVariables calldata _mktVars,
        int128 _fTradeAmount,
        int128 _fHBidAskSpread,
        int128 _fIncentiveSpread
    ) external view virtual override returns (int128) {
        // add minimal spread in quote currency
        _fHBidAskSpread = _fTradeAmount > 0 ? _fHBidAskSpread : _fHBidAskSpread.neg();
        if (_fTradeAmount == 0) {
            _fHBidAskSpread = 0;
        }
        // get risk-neutral default probability (always >0)
        {
            int128 fQ;
            int128 dd;
            int128 fkStar = _ammVars.fPoolM2.sub(_ammVars.fAMM_K2);
            (fQ, dd) = _calculateRiskNeutralPD(_ammVars, _mktVars, _fTradeAmount, true);
            if (_ammVars.fPoolM3 != 0) {
                // amend K* (see whitepaper)
                int128 nominator = _mktVars.fRho23.mul(_mktVars.fSigma2);
                nominator = nominator.mul(_mktVars.fSigma3).exp().sub(ONE_64x64);
                int128 denom = (_mktVars.fSigma2).mul(_mktVars.fSigma2).exp().sub(ONE_64x64);
                int128 h = nominator.div(denom).mul(_ammVars.fPoolM3);
                h = h.mul(_mktVars.fIndexPriceS3).div(_mktVars.fIndexPriceS2);
                fkStar = fkStar.add(h);
            }
            // decide on sign of premium
            if (_fTradeAmount < fkStar) {
                fQ = fQ.neg();
            }
            _fHBidAskSpread = _fHBidAskSpread.add(fQ);
        }
        // get additional slippage
        if (_fTradeAmount != 0) {
            _fIncentiveSpread = _fIncentiveSpread.mul(
                _calculateBoundedSlippage(_ammVars, _fTradeAmount)
            );
            _fHBidAskSpread = _fHBidAskSpread.add(_fIncentiveSpread);
        }
        // s2*(1 + sign(qp-q)*q + sign(k)*minSpread)
        return _mktVars.fIndexPriceS2.mul(ONE_64x64.add(_fHBidAskSpread));
    }

    /**
     *  Calculate target collateral M1 (Quote Currency), when no M2, M3 is present
     *  The targeted default probability is expressed using the inverse
     *  _fTargetDD = Phi^(-1)(targetPD)
     *  _fK2 in absolute terms must be 'reasonably large'
     *  sigma3, rho23, IndexpriceS3 not relevant.
     *  @param _fK2 signed 64.64-bit fixed point number, !=0, EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number, >0, EWMA of actual L.
     *  @param  _mktVars contains 64.64 values for fIndexPriceS2*, fIndexPriceS3, fSigma2*, fSigma3, fRho23
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M1Star signed 64.64-bit fixed point number, >0
     */
    function getTargetCollateralM1(
        int128 _fK2,
        int128 _fL1,
        MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure virtual override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 == 0);
        assert(_mktVars.fIndexPriceS3 == 0);
        assert(_mktVars.fRho23 == 0);
        int128 fMu2 = HALF_64x64.neg().mul(_mktVars.fSigma2).mul(_mktVars.fSigma2);
        int128 ddScaled = _fK2 < 0
            ? _mktVars.fSigma2.mul(_fTargetDD)
            : _mktVars.fSigma2.mul(_fTargetDD).neg();
        int128 A1 = ABDKMath64x64.exp(fMu2.add(ddScaled));
        return _fK2.mul(_mktVars.fIndexPriceS2).mul(A1).sub(_fL1);
    }

    /**
     *  Calculate target collateral *M2* (Base Currency), when no M1, M3 is present
     *  The targeted default probability is expressed using the inverse
     *  _fTargetDD = Phi^(-1)(targetPD)
     *  _fK2 in absolute terms must be 'reasonably large'
     *  sigma3, rho23, IndexpriceS3 not relevant.
     *  @param _fK2 signed 64.64-bit fixed point number, EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number, EWMA of actual L.
     *  @param _mktVars contains 64.64 values for fIndexPriceS2, fIndexPriceS3, fSigma2, fSigma3, fRho23
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M2Star signed 64.64-bit fixed point number
     */
    function getTargetCollateralM2(
        int128 _fK2,
        int128 _fL1,
        MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure virtual override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 == 0);
        assert(_mktVars.fIndexPriceS3 == 0);
        assert(_mktVars.fRho23 == 0);
        int128 fMu2 = HALF_64x64.mul(_mktVars.fSigma2).mul(_mktVars.fSigma2).neg();
        int128 ddScaled = _fL1 < 0
            ? _mktVars.fSigma2.mul(_fTargetDD)
            : _mktVars.fSigma2.mul(_fTargetDD).neg();
        int128 A1 = ABDKMath64x64.exp(fMu2.add(ddScaled)).mul(_mktVars.fIndexPriceS2);
        return _fK2.sub(_fL1.div(A1));
    }

    /**
     *  Calculate target collateral M3 (Quanto Currency), when no M1, M2 not present
     *
     *  @param _fK2 signed 64.64-bit fixed point number. EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number.  EWMA of actual L.
     *  @param  _mktVars contains 64.64 values for
     *           fIndexPriceS2, fIndexPriceS3, fSigma2, fSigma3, fRho23 - all required
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M2Star signed 64.64-bit fixed point number
     */
    function getTargetCollateralM3(
        int128 _fK2,
        int128 _fL1,
        MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 != 0);
        assert(_mktVars.fIndexPriceS3 != 0);
        assert(_mktVars.fRho23 != 0);
        // we solve the quadratic equation A x^2 + Bx + C = 0
        // B = 2 * [X + Y * target_dd^2 * (exp(rho*sigma2*sigma3) - 1) ]
        // C = X^2  - Y^2 * target_dd^2 * (exp(sigma2^2) - 1)
        // where:
        // X = L1 / S3 - Y and Y = K2 * S2 / S3
        // we re-use L1 for X and K2 for Y to save memory since they don't enter the equations otherwise
        _fK2 = _fK2.mul(_mktVars.fIndexPriceS2).div(_mktVars.fIndexPriceS3); // Y
        _fL1 = _fL1.div(_mktVars.fIndexPriceS3).sub(_fK2); // X
        // we only need the square of the target DD
        _fTargetDD = _fTargetDD.mul(_fTargetDD);
        // and we only need B/2
        int128 fHalfB = _fL1.add(
            _fK2.mul(
                _fTargetDD.mul(
                    _mktVars.fRho23.mul(_mktVars.fSigma2).mul(_mktVars.fSigma3).exp().sub(
                        ONE_64x64
                    )
                )
            )
        );
        int128 fC = _fL1.mul(_fL1).sub(
            _fK2.mul(_fK2).mul(_fTargetDD).mul(
                _mktVars.fSigma2.mul(_mktVars.fSigma2).exp().sub(ONE_64x64)
            )
        );
        // A = 1 - (exp(sigma3^2) - 1) * target_dd^2
        int128 fA = ONE_64x64.sub(
            _mktVars.fSigma3.mul(_mktVars.fSigma3).exp().sub(ONE_64x64).mul(_fTargetDD)
        );
        // we re-use C to store the discriminant: D = (B/2)^2 - A * C
        fC = fHalfB.mul(fHalfB).sub(fA.mul(fC));
        if (fC < 0) {
            // no solutions -> AMM is in profit, probability is smaller than target regardless of capital
            return int128(0);
        }
        // we want the larger of (-B/2 + sqrt((B/2)^2-A*C)) / A and (-B/2 - sqrt((B/2)^2-A*C)) / A
        // so it depends on the sign of A, or, equivalently, the sign of sqrt(...)/A
        fC = ABDKMath64x64.sqrt(fC).div(fA);
        fHalfB = fHalfB.div(fA);
        return fC > 0 ? fC.sub(fHalfB) : fC.neg().sub(fHalfB);
    }

    /**
     *  Calculate the required deposit for a new position
     *  of size _fPosition+_fTradeAmount and leverage _fTargetLeverage,
     *  having an existing position with balance fBalance0 and size _fPosition.
     *  This is the amount to be added to the margin collateral and can be negative (hence remove).
     *  Fees not factored-in.
     *  @param _fPosition0   signed 64.64-bit fixed point number. Position in base currency
     *  @param _fBalance0   signed 64.64-bit fixed point number. Current balance.
     *  @param _fTradeAmount signed 64.64-bit fixed point number. Trade amt in base currency
     *  @param _fTargetLeverage signed 64.64-bit fixed point number. Desired leverage
     *  @param _fPrice signed 64.64-bit fixed point number. Price for the trade of size _fTradeAmount
     *  @param _fS2Mark signed 64.64-bit fixed point number. Mark-price
     *  @param _fS3 signed 64.64-bit fixed point number. Collateral 2 quote conversion
     *  @return signed 64.64-bit fixed point number. Required cash_cc
     */
    function getDepositAmountForLvgPosition(
        int128 _fPosition0,
        int128 _fBalance0,
        int128 _fTradeAmount,
        int128 _fTargetLeverage,
        int128 _fPrice,
        int128 _fS2Mark,
        int128 _fS3
    ) external pure override returns (int128) {
        int128 fPnL = _fTradeAmount.mul(_fS2Mark.sub(_fPrice));
        fPnL = fPnL.div(_fS3);
        int128 fLvgFrac = _fPosition0.add(_fTradeAmount).abs().mul(_fS2Mark);
        fLvgFrac = fLvgFrac.div(_fS3).div(_fTargetLeverage);
        return _fBalance0.add(fPnL).sub(fLvgFrac).neg();
    }

    /**
     * Computes the total absolute fee corresponding to a trade size and relative fees
     * @param _fDeltaPosCC Trade size, could be signed
     * @param _fTreasuryFeeRate Treasury fee rate
     * @param _fPnLPartRate PnL Participation fund fee rate
     * @param _fReferralRebate Referal rebate (absolute fee)
     * @param _referrerAddr Address of the referrer
     * @return Fee paid to the treasury (the AMM fund), in collateral currency
     * @return Fee paid to the PnL participation fund, in collateral currency
     * @return Fee paid to the referrer, in collateral currency
     */
    function relativeFeeToCCAmount(
        int128 _fDeltaPosCC,
        int128 _fTreasuryFeeRate,
        int128 _fPnLPartRate,
        int128 _fReferralRebate,
        address _referrerAddr
    )
        external
        pure
        returns (
            int128,
            int128,
            int128
        )
    {
        int128 fDeltaPos = _fDeltaPosCC.abs();
        int128 fTreasuryFee = fDeltaPos.mul(_fTreasuryFeeRate);
        int128 fPnLparticipantFee = fDeltaPos.mul(_fPnLPartRate);
        int128 fReferralRebate = _referrerAddr != address(0) ? _fReferralRebate : int128(0);
        return (fTreasuryFee, fPnLparticipantFee, fReferralRebate);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.8.19;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF, "ABDK.fromInt");
        return int128(x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        return int64(x >> 64);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        require(x <= 0x7FFFFFFFFFFFFFFF, "ABDK.fromUInt");
        return int128(int256(x << 64));
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        require(x >= 0, "ABDK.toUInt");
        return uint64(uint128(x >> 64));
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        int256 result = x >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.from128x128");
        return int128(result);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        return int256(x) << 64;
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) + y;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.add");
        return int128(result);
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) - y;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.sub");
        return int128(result);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        int256 result = (int256(x) * y) >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.mul");
        return int128(result);
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        if (x == MIN_64x64) {
            require(
                y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                    y <= 0x1000000000000000000000000000000000000000000000000,
                "ABDK.muli-1"
            );
            return -y << 63;
        } else {
            bool negativeResult = false;
            if (x < 0) {
                x = -x;
                negativeResult = true;
            }
            if (y < 0) {
                y = -y;
                // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint256 absoluteResult = mulu(x, uint256(y));
            if (negativeResult) {
                require(
                    absoluteResult <=
                        0x8000000000000000000000000000000000000000000000000000000000000000,
                    "ABDK.muli-2"
                );
                return -int256(absoluteResult);
                // We rely on overflow behavior here
            } else {
                require(
                    absoluteResult <=
                        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                    "ABDK.muli-3"
                );
                return int256(absoluteResult);
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 0;

        require(x >= 0, "ABDK.mulu-1");

        uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = uint256(int256(x)) * (y >> 128);

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.mulu-2");
        hi <<= 64;

        require(
            hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo,
            "ABDK.mulu-3"
        );
        return hi + lo;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        require(y != 0, "ABDK.div-1");
        int256 result = (int256(x) << 64) / y;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.div-2");
        return int128(result);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        require(y != 0, "ABDK.divi-1");

        bool negativeResult = false;
        if (x < 0) {
            x = -x;
            // We rely on overflow behavior here
            negativeResult = true;
        }
        if (y < 0) {
            y = -y;
            // We rely on overflow behavior here
            negativeResult = !negativeResult;
        }
        uint128 absoluteResult = divuu(uint256(x), uint256(y));
        if (negativeResult) {
            require(absoluteResult <= 0x80000000000000000000000000000000, "ABDK.divi-2");
            return -int128(absoluteResult);
            // We rely on overflow behavior here
        } else {
            require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.divi-3");
            return int128(absoluteResult);
            // We rely on overflow behavior here
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        require(y != 0, "ABDK.divu-1");
        uint128 result = divuu(x, y);
        require(result <= uint128(MAX_64x64), "ABDK.divu-2");
        return int128(result);
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64, "ABDK.neg");
        return -x;
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64, "ABDK.abs");
        return x < 0 ? -x : x;
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        require(x != 0, "ABDK.inv-1");
        int256 result = int256(0x100000000000000000000000000000000) / x;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.inv-2");
        return int128(result);
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        return int128((int256(x) + int256(y)) >> 1);
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        int256 m = int256(x) * int256(y);
        require(m >= 0, "ABDK.gavg-1");
        require(
            m < 0x4000000000000000000000000000000000000000000000000000000000000000,
            "ABDK.gavg-2"
        );
        return int128(sqrtu(uint256(m)));
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        bool negative = x < 0 && y & 1 == 1;

        uint256 absX = uint128(x < 0 ? -x : x);
        uint256 absResult;
        absResult = 0x100000000000000000000000000000000;

        if (absX <= 0x10000000000000000) {
            absX <<= 63;
            while (y != 0) {
                if (y & 0x1 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                if (y & 0x2 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                if (y & 0x4 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                if (y & 0x8 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                y >>= 4;
            }

            absResult >>= 64;
        } else {
            uint256 absXShift = 63;
            if (absX < 0x1000000000000000000000000) {
                absX <<= 32;
                absXShift -= 32;
            }
            if (absX < 0x10000000000000000000000000000) {
                absX <<= 16;
                absXShift -= 16;
            }
            if (absX < 0x1000000000000000000000000000000) {
                absX <<= 8;
                absXShift -= 8;
            }
            if (absX < 0x10000000000000000000000000000000) {
                absX <<= 4;
                absXShift -= 4;
            }
            if (absX < 0x40000000000000000000000000000000) {
                absX <<= 2;
                absXShift -= 2;
            }
            if (absX < 0x80000000000000000000000000000000) {
                absX <<= 1;
                absXShift -= 1;
            }

            uint256 resultShift;
            while (y != 0) {
                require(absXShift < 64, "ABDK.pow-1");

                if (y & 0x1 != 0) {
                    absResult = (absResult * absX) >> 127;
                    resultShift += absXShift;
                    if (absResult > 0x100000000000000000000000000000000) {
                        absResult >>= 1;
                        resultShift += 1;
                    }
                }
                absX = (absX * absX) >> 127;
                absXShift <<= 1;
                if (absX >= 0x100000000000000000000000000000000) {
                    absX >>= 1;
                    absXShift += 1;
                }

                y >>= 1;
            }

            require(resultShift < 64, "ABDK.pow-2");
            absResult >>= 64 - resultShift;
        }
        int256 result = negative ? -int256(absResult) : int256(absResult);
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.pow-3");
        return int128(result);
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        require(x >= 0, "ABDK.sqrt");
        return int128(sqrtu(uint256(int256(x)) << 64));
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        require(x > 0, "ABDK.log_2");

        int256 msb;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {
            xc >>= 64;
            msb += 64;
        }
        if (xc >= 0x100000000) {
            xc >>= 32;
            msb += 32;
        }
        if (xc >= 0x10000) {
            xc >>= 16;
            msb += 16;
        }
        if (xc >= 0x100) {
            xc >>= 8;
            msb += 8;
        }
        if (xc >= 0x10) {
            xc >>= 4;
            msb += 4;
        }
        if (xc >= 0x4) {
            xc >>= 2;
            msb += 2;
        }
        if (xc >= 0x2) msb += 1;
        // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = uint256(int256(x)) << uint256(127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0, "ABDK.ln");

            return
                int128(
                    int256((uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128)
                );
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000, "ABDK.exp_2-1");
        // Overflow

        if (x < -0x400000000000000000) return 0;
        // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0)
            result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
        if (x & 0x4000000000000000 > 0)
            result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
        if (x & 0x2000000000000000 > 0)
            result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
        if (x & 0x1000000000000000 > 0)
            result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
        if (x & 0x800000000000000 > 0)
            result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
        if (x & 0x400000000000000 > 0)
            result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
        if (x & 0x200000000000000 > 0)
            result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
        if (x & 0x100000000000000 > 0)
            result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
        if (x & 0x80000000000000 > 0)
            result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
        if (x & 0x40000000000000 > 0)
            result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
        if (x & 0x20000000000000 > 0)
            result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
        if (x & 0x10000000000000 > 0)
            result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
        if (x & 0x8000000000000 > 0)
            result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
        if (x & 0x4000000000000 > 0)
            result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
        if (x & 0x2000000000000 > 0)
            result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
        if (x & 0x1000000000000 > 0)
            result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
        if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
        if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
        if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
        if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
        if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
        if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
        if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
        if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
        if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
        if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
        if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
        if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
        if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
        if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
        if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
        if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
        if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
        if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
        if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
        if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
        if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
        if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
        if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
        if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
        if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
        if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
        if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
        if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
        if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
        if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
        if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
        if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
        if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
        if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
        if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
        if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
        if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
        if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
        if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
        if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
        if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
        if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
        if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
        if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
        if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
        if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
        if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
        if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

        result >>= uint256(int256(63 - (x >> 64)));
        require(result <= uint256(int256(MAX_64x64)), "ABDK.exp_2-2");

        return int128(int256(result));
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000, "ABDK.exp");
        // Overflow

        if (x < -0x400000000000000000) return 0;
        // Underflow

        return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        require(y != 0, "ABDK.divuu-1");

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1;
            // No need to shift xc anymore

            result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.divuu-2");

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo;
            // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo;
            // We rely on overflow behavior here

            assert(xh == hi >> 128);

            result += xl / y;
        }

        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.divuu-3");
        return uint128(result);
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ABDKMath64x64.sol";

library ConverterDec18 {
    using ABDKMath64x64 for int128;
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    int256 private constant DECIMALS = 10**18;

    int128 private constant ONE_64x64 = 0x010000000000000000;

    int128 public constant HALF_TBPS = 92233720368548; //1e-5 * 0.5 * 2**64

    // convert tenth of basis point to dec 18:
    uint256 public constant TBPSTODEC18 = 0x9184e72a000; // hex(10^18 * 10^-5)=(10^13)
    // convert tenth of basis point to ABDK 64x64:
    int128 public constant TBPSTOABDK = 0xa7c5ac471b48; // hex(2^64 * 10^-5)
    // convert two-digit integer reprentation to ABDK
    int128 public constant TDRTOABDK = 0x28f5c28f5c28f5c; // hex(2^64 * 10^-5)

    function tbpsToDec18(uint16 Vtbps) internal pure returns (uint256) {
        return TBPSTODEC18 * uint256(Vtbps);
    }

    function tbpsToABDK(uint16 Vtbps) internal pure returns (int128) {
        return int128(uint128(TBPSTOABDK) * uint128(Vtbps));
    }

    function TDRToABDK(uint16 V2Tdr) internal pure returns (int128) {
        return int128(uint128(TDRTOABDK) * uint128(V2Tdr));
    }

    function ABDKToTbps(int128 Vabdk) internal pure returns (uint16) {
        // add 0.5 * 1e-5 to ensure correct rounding to tenth of bps
        return uint16(uint128(Vabdk.add(HALF_TBPS) / TBPSTOABDK));
    }

    function fromDec18(int256 x) internal pure returns (int128) {
        int256 result = (x * ONE_64x64) / DECIMALS;
        require(x >= MIN_64x64 && x <= MAX_64x64, "result out of range");
        return int128(result);
    }

    function toDec18(int128 x) internal pure returns (int256) {
        return (int256(x) * DECIMALS) / ONE_64x64;
    }

    function toUDec18(int128 x) internal pure returns (uint256) {
        require(x >= 0, "negative value");
        return uint256(toDec18(x));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

pragma solidity 0.8.19;

interface IShareTokenFactory {
    function createShareToken(uint8 _poolId) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../../interface/IShareTokenFactory.sol";
import "../../libraries/ABDKMath64x64.sol";
import "./../functions/AMMPerpLogic.sol";
import "../../libraries/EnumerableSetUpgradeable.sol";
import "../../libraries/EnumerableBytes4Set.sol";
import "../../governance/Maintainable.sol";

/* solhint-disable max-states-count */
contract PerpStorage is Maintainable, Pausable, ReentrancyGuard {
    using ABDKMath64x64 for int128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableBytes4Set for EnumerableBytes4Set.Bytes4Set; // enumerable map of bytes4 or addresses
    /**
     * @notice  Perpetual state:
     *          - INVALID:      Uninitialized or not non-existent perpetual.
     *          - INITIALIZING: Only when LiquidityPoolData.isRunning == false. Traders cannot perform operations.
     *          - NORMAL:       Full functional state. Traders are able to perform all operations.
     *          - EMERGENCY:    Perpetual is unsafe and the perpetual needs to be settled.
     *          - SETTLE:       Perpetual ready to be settled
     *          - CLEARED:      All margin accounts are cleared. Traders can withdraw remaining margin balance.
     */
    enum PerpetualState {
        INVALID,
        INITIALIZING,
        NORMAL,
        EMERGENCY,
        SETTLE,
        CLEARED
    }

    // margin and liquidity pool are held in 'collateral currency' which can be either of
    // quote currency, base currency, or quanto currency
    // solhint-disable-next-line const-name-snakecase
    int128 internal constant ONE_64x64 = 0x10000000000000000; // 2^64
    int128 internal constant FUNDING_INTERVAL_SEC = 0x70800000000000000000; //3600 * 8 * 0x10000000000000000 = 8h in seconds scaled by 2^64 for ABDKMath64x64
    int128 internal constant CEIL_PNL_SHARE = 0xc000000000000000; //=0.75: participants get PnL proportional to min[PFund/(PFund+allAMMFundSizes), 75%]
    int128 internal constant CEIL_AMT_FUND_WITHDRAWAL = 0xc000000000000000; //=0.75: maximal relative amount we withdraw from the default fund and stakers in rebalance
    int128 internal constant MIN_NUM_LOTS_PER_POSITION = 0x0a0000000000000000; // 10, minimal position size in number of lots
    uint8 internal constant MASK_ORDER_CANCELLED = 0x1;
    uint8 internal constant MASK_ORDER_EXECUTED = 0x2;
    // at target, 1% of missing amount is transferred
    // at every rebalance
    uint8 internal iPoolCount;
    // delay required for trades to mitigate oracle front-running in seconds
    uint8 internal iTradeDelaySec;
    address internal ammPerpLogic;

    IShareTokenFactory internal shareTokenFactory;

    //pool id (incremental index, starts from 1) => pool data
    mapping(uint8 => LiquidityPoolData) internal liquidityPools;

    //bytes32 id = keccak256(abi.encodePacked(poolId, perpetualIndex));
    //perpetual id (hash(poolId, perpetualIndex)) => pool id
    mapping(uint24 => uint8) internal perpetualPoolIds;

    address internal orderBookFactory;

    /**
     * @notice  Data structure to store oracle price data.
     */
    struct PriceTimeData {
        int128 fPrice;
        uint64 time;
    }

    /**
     * @notice  Data structure to store user margin information.
     */
    struct MarginAccount {
        int128 fLockedInValueQC; // unrealized value locked-in when trade occurs in
        int128 fCashCC; // cash in collateral currency (base, quote, or quanto)
        int128 fPositionBC; // position in base currency (e.g., 1 BTC for BTCUSD)
        int128 fUnitAccumulatedFundingStart; // accumulated funding rate
        uint64 iLastOpenTimestamp; // timestamp in seconds when the position was last opened/increased
        uint16 feeTbps; // exchange fee in tenth of a basis point
        uint16 brokerFeeTbps; // broker fee in tenth of a basis point
        bytes16 positionId; // unique id for the position (for given trader, and perpetual). Current position, zero otherwise.
    }

    /**
     * @notice  Store information for a given perpetual market.
     */
    struct PerpetualData {
        // ------
        uint8 poolId;
        uint24 id;
        int32 fInitialMarginRate; //parameter: initial margin
        int32 fSigma2; // parameter: volatility of base-quote pair
        uint32 iLastFundingTime; //timestamp since last funding rate payment
        uint32 iLastSettlementPriceUpdateTimestamp; // timestamp when last price was observed happened
        uint32 iLastPriceJumpTimestamp; // timestamp when last price jump happened
        uint32 iLastDefaultFundTransfer; // state: timestamp in seconds. Last time we transferred from the DF into this perp's AMM pool
        int32 fMaintenanceMarginRate; // parameter: maintenance margin
        // ------
        PerpetualState state; // Perpetual AMM state
        AMMPerpLogic.CollateralCurrency eCollateralCurrency; //parameter: in what currency is the collateral held?
        uint16 minimalSpreadTbps; //parameter: minimal spread between long and short perpetual price
        bytes4 S2BaseCCY; //base currency of S2
        uint16 incentiveSpreadTbps; //parameter: maximum spread added to the PD
        bytes4 S2QuoteCCY; //quote currency of S2
        uint16 jumpSpreadTbps; // spread that is adjusted based on price jumps
        bytes4 S3BaseCCY; //base currency of S3
        uint16 liquidationPenaltyRateTbps; //parameter: penalty if AMM closes the position and not the trader
        bytes4 S3QuoteCCY; //quote currency of S3
        int32 fSigma3; // parameter: volatility of quanto-quote pair
        //-------
        PriceTimeData currentMarkPremiumRate; //relative diff to index price EMA, used for markprice.
        //-------
        int128[2] fStressReturnS3; // parameter: negative and positive stress returns for quanto-quote asset
        int128[2] fDFLambda; // parameter: EMA lambda for AMM and trader exposure K,k: EMA*lambda + (1-lambda)*K. 0 regular lambda, 1 if current value exceeds past
        int128[2] fCurrentAMMExposureEMA; // 0: negative aggregated exposure (storing negative value), 1: positive
        int128[2] fAMMTargetDD; // parameter: target distance to default (=inverse of default probability), [0] baseline [1] stress
        int128[2] fStressReturnS2; // parameter: negative and positive stress returns for base-quote asset
        //-------
        int128 premiumRatesEMA; // EMA of premium rate
        int128 fTargetDFSize; // target default fund size
        //-------
        int128 fFundAllocationWeightCC; // state: current unnormalized weight for this perpetual during allocation of funds from the PnL pool
        int128 fOpenInterest; //open interest is the amount of long positions in base currency or, equiv., the amount of short positions.
        //-------
        int128 fTargetAMMFundSize; //target AMM fund size
        int128 fCurrentTraderExposureEMA; // trade amounts (storing absolute value)
        //-------
        int128 fCurrentFundingRate; // current instantaneous funding rate
        int128 fUnitAccumulatedFunding; //accumulated funding in collateral currency
        //-------
        int128 fLotSizeBC; //parameter: minimal trade unit (in base currency) to avoid dust positions
        int128 fkStar; // signed trade size that minimizes the AMM risk
        //-------
        int128 fAMMFundCashCC; // fund-cash in this perpetual - not margin
        int128 fSettlementS3PriceData; //quanto index
        //-------
        int128 fMinimalTraderExposureEMA; // parameter: minimal value for fCurrentTraderExposureEMA that we don't want to undershoot
        int128 fMinimalAMMExposureEMA; // parameter: minimal value for fCurrentTraderExposureEMA that we don't want to undershoot
        //-------
        //-------
        int128 fAMMMinSizeCC; // parameter: minimal size of AMM pool, regardless of current exposure
        int128 fTotalMarginBalance; //calculated for settlement, in collateral currency
        //-------
        int128 fReferralRebateCC; //parameter: referall rebate in collateral currency
        int128 fSettlementS2PriceData; //base-quote pair. Used as last price in normal state.
        //-------
        uint32 iLastTargetPoolSizeTime; //timestamp (seconds) since last update of fTargetDFSize and fTargetAMMFundSize
        int32 fMarkPriceEMALambda; // parameter: Lambda parameter for EMA used in mark-price for funding rates
        int32 fFundingRateClamp; // parameter: funding rate clamp between which we charge 1bps
        int32 fMaximalTradeSizeBumpUp; // parameter: >1, users can create a maximal position of size fMaximalTradeSizeBumpUp*fCurrentAMMExposureEMA
        int32 fRho23; // parameter: correlation of quanto/base returns
        int32 fDFCoverNRate; // parameter: cover-n rule for default fund. E.g., fDFCoverNRate=0.05 -> we try to cover 5% of active accounts with default fund
        // -----
    }

    address internal oracleFactoryAddress;

    // users
    mapping(uint24 => EnumerableSetUpgradeable.AddressSet) internal activeAccounts; //perpetualId => traderAddressSet
    // accounts
    mapping(uint24 => mapping(address => MarginAccount)) internal marginAccounts;

    // broker maps: poolId -> brokeraddress-> lots contributed
    // contains non-zero entries for brokers. Brokers pay default fund contributions.
    mapping(uint8 => mapping(address => uint32)) internal brokerMap;

    struct LiquidityPoolData {
        bool isRunning; // state
        uint8 iPerpetualCount; // state
        uint8 id; // parameter: index, starts from 1
        uint16 iTargetPoolSizeUpdateTime; //parameter: timestamp in seconds. How often we update the pool's target size
        address marginTokenAddress; //parameter: address of the margin token
        // -----
        int128 fFundAllocationNormalizationCC; // state: sum of all perpetual weights during fund allocation (cheaper than re-normalizing w/each trade)
        int128 fDefaultFundCashCC; // state: profit/loss
        // -----
        uint64 prevAnchor; // state: keep track of timestamp since last withdrawal was initiated
        int32 fRedemptionRate; // state: used for settlement in case of AMM default
        address shareTokenAddress; // parameter
        // -----
        int128 fPnLparticipantsCashCC; // state: addLiquidity/withdrawLiquidity + profit/loss - rebalance
        int128 fAMMFundCashCC; // state: profit/loss - rebalance (sum of cash in individual perpetuals)
        // -----
        int128 fTargetAMMFundSize; // state: target AMM pool size for all perpetuals in pool (sum)
        int128 fTargetDFSize; // state: target default fund size for all perpetuals in pool
        // -----
        int128 fMaxTransferPerConvergencePeriod; // param: how many funds can be transferred in FUND_TRANSFER_CONVERGENCE_HOURS hours
        int128 fBrokerCollateralLotSize; // param:how much collateral do brokers deposit when providing "1 lot" (not trading lot)
        // -----
        uint128 prevTokenAmount; // state
        uint128 nextTokenAmount; // state
        // -----
        uint128 totalSupplyShareToken; // state
    }

    address internal treasuryAddress; // address for the protocol treasury

    //pool id => perpetual id list
    mapping(uint8 => uint24[]) internal perpetualIds;

    //pool id => perpetual id => data
    mapping(uint8 => mapping(uint24 => PerpetualData)) internal perpetuals;

    /// @dev flag whether MarginTradeOrder was already executed or cancelled
    mapping(bytes32 => uint8) internal executedOrCancelledOrders;

    //proxy
    mapping(bytes32 => EnumerableBytes4Set.Bytes4Set) internal moduleActiveFuncSignatureList;
    mapping(bytes32 => address) internal moduleNameToAddress;
    mapping(address => bytes32) internal moduleAddressToModuleName;
}
/* solhint-enable max-states-count */

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @title Library for managing loan sets.
 *
 * @notice Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * Include with `using EnumerableBytes4Set for EnumerableBytes4Set.Bytes4Set;`.
 * */
library EnumerableBytes4Set {
    struct Bytes4Set {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes4 => uint256) index;
        bytes4[] values;
    }

    /**
     * @notice Add an address value to a set. O(1).
     *
     * @param set The set of values.
     * @param addrvalue The address to add.
     *
     * @return False if the value was already in the set.
     */
    function addAddress(Bytes4Set storage set, address addrvalue) internal returns (bool) {
        bytes4 value;
        assembly {
            value := addrvalue
        }
        return addBytes4(set, value);
    }

    /**
     * @notice Add a value to a set. O(1).
     *
     * @param set The set of values.
     * @param value The new value to add.
     *
     * @return False if the value was already in the set.
     */
    function addBytes4(Bytes4Set storage set, bytes4 value) internal returns (bool) {
        if (!contains(set, value)) {
            set.values.push(value);
            set.index[value] = set.values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Remove an address value from a set. O(1).
     *
     * @param set The set of values.
     * @param addrvalue The address to remove.
     *
     * @return False if the address was not present in the set.
     */
    function removeAddress(Bytes4Set storage set, address addrvalue) internal returns (bool) {
        bytes4 value;
        assembly {
            value := addrvalue
        }
        return removeBytes4(set, value);
    }

    /**
     * @notice Remove a value from a set. O(1).
     *
     * @param set The set of values.
     * @param value The value to remove.
     *
     * @return False if the value was not present in the set.
     */
    function removeBytes4(Bytes4Set storage set, bytes4 value) internal returns (bool) {
        if (contains(set, value)) {
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            /// If the element we're deleting is the last one,
            /// we can just remove it without doing a swap.
            if (lastIndex != toDeleteIndex) {
                bytes4 lastValue = set.values[lastIndex];

                /// Move the last value to the index where the deleted value is.
                set.values[toDeleteIndex] = lastValue;

                /// Update the index for the moved value.
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            /// Delete the index entry for the deleted value.
            delete set.index[value];

            /// Delete the old entry for the moved value.
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Find out whether a value exists in the set.
     *
     * @param set The set of values.
     * @param value The value to find.
     *
     * @return True if the value is in the set. O(1).
     */
    function contains(Bytes4Set storage set, bytes4 value) internal view returns (bool) {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function containsAddress(Bytes4Set storage set, address addrvalue)
        internal
        view
        returns (bool)
    {
        bytes4 value;
        assembly {
            value := addrvalue
        }
        return set.index[value] != 0;
    }

    /**
     * @notice Get all set values.
     *
     * @param set The set of values.
     * @param start The offset of the returning set.
     * @param count The limit of number of values to return.
     *
     * @return output An array with all values in the set. O(N).
     *
     * @dev Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(
        Bytes4Set storage set,
        uint256 start,
        uint256 count
    ) internal view returns (bytes4[] memory output) {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        end = set.values.length < end ? set.values.length : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new bytes4[](end - start);
        for (uint256 i; i < end - start; i++) {
            output[i] = set.values[i + start];
        }
        return output;
    }

    /**
     * @notice Get the legth of the set.
     *
     * @param set The set of values.
     *
     * @return the number of elements on the set. O(1).
     */
    function length(Bytes4Set storage set) internal view returns (uint256) {
        return set.values.length;
    }

    /**
     * @notice Get an item from the set by its index.
     *
     * @dev Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     *
     * @param set The set of values.
     * @param index The index of the value to return.
     *
     * @return the element stored at position `index` in the set. O(1).
     */
    function get(Bytes4Set storage set, uint256 index) internal view returns (bytes4) {
        return set.values[index];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// D8X, 2022

pragma solidity 0.8.19;

/**
 * This is a modified version of the OpenZeppelin ownable contract
 * Modifications
 * - instead of an owner, we have two actors: maintainer and governance
 * - maintainer can have certain priviledges but cannot transfer maintainer mandate
 * - governance can exchange maintainer and exchange itself
 * - renounceOwnership is removed
 *
 *
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
abstract contract Maintainable {
    address private _maintainer;
    address private _governance;

    event MaintainerTransferred(address indexed previousMaintainer, address indexed newMaintainer);
    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);

    /**
     * @dev Initializes the contract setting the deployer as the initial maintainer.
     */
    constructor() {
        _transferMaintainer(msg.sender);
        _transferGovernance(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function maintainer() public view virtual returns (address) {
        return _maintainer;
    }

    /**
     * @dev Returns the address of the governance.
     */
    function governance() public view virtual returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMaintainer() {
        require(maintainer() == msg.sender, "only maintainer");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(governance() == msg.sender, "only governance");
        _;
    }

    /**
     * @dev Transfers maintainer mandate of the contract to a new account (`newMaintainer`).
     * Can only be called by the governance.
     */
    function transferMaintainer(address newMaintainer) public virtual {
        require(msg.sender == _governance, "only governance");
        require(newMaintainer != address(0), "zero address");
        _transferMaintainer(newMaintainer);
    }

    /**
     * @dev Transfers governance mandate of the contract to a new account (`newGovernance`).
     * Can only be called by the governance.
     */
    function transferGovernance(address newGovernance) public virtual {
        require(msg.sender == _governance, "only governance");
        require(newGovernance != address(0), "zero address");
        _transferGovernance(newGovernance);
    }

    /**
     * @dev Transfers maintainer of the contract to a new account (`newMaintainer`).
     * Internal function without access restriction.
     */
    function _transferMaintainer(address newMaintainer) internal virtual {
        address oldM = _maintainer;
        _maintainer = newMaintainer;
        emit MaintainerTransferred(oldM, newMaintainer);
    }

    /**
     * @dev Transfers governance of the contract to a new account (`newGovernance`).
     * Internal function without access restriction.
     */
    function _transferGovernance(address newGovernance) internal virtual {
        address oldG = _governance;
        _governance = newGovernance;
        emit GovernanceTransferred(oldG, newGovernance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: idx out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function enumerate(
        AddressSet storage set,
        uint256 start,
        uint256 count
    ) internal view returns (address[] memory output) {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        uint256 len = length(set);
        end = len < end ? len : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new address[](end - start);
        for (uint256 i; i < end - start; i++) {
            output[i] = at(set, i + start);
        }
        return output;
    }

    function enumerateAll(AddressSet storage set) internal view returns (address[] memory output) {
        return enumerate(set, 0, length(set));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface ISpotOracle {
    /**
     * @dev The market is closed if the market is not in its regular trading period.
     */
    function isMarketClosed() external view returns (bool);

    function setMarketClosed(bool _marketClosed) external;

    /**
     * @dev The oracle service was shutdown and never online again.
     */
    function isTerminated() external view returns (bool);

    function setTerminated(bool _terminated) external;

    /**
     *  Spot price.
     */
    function getSpotPrice() external view returns (int128, uint256);

    /**
     * Get base currency symbol.
     */
    function getBaseCurrency() external view returns (bytes4);

    /**
     * Get quote currency symbol.
     */
    function getQuoteCurrency() external view returns (bytes4);

    /**
     * Price Id
     */
    function priceId() external view returns (bytes32);

    /**
     * Address of the underlying feed.
     */
    function priceFeed() external view returns (address);

    /**
     * Conservative update period of this feed in seconds.
     */
    function feedPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}