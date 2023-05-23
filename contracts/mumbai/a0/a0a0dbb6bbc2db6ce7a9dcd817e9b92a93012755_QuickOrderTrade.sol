/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/OrderHeapLib.sol


pragma solidity ^0.8.0;

library OrderHeapLib {
    enum HeapType {
        MinHeap,
        MaxHeap
    }

    struct Order {
        uint256 id;
        address token;
        uint256 price;
        uint256 amount;
        uint256 payed;
        uint256 accPayed;
        address user;
        bool isBuy;
    }

    struct HeapData {
        Order[] data;
        mapping(uint256 => uint256) indexMap;
        HeapType heapType;
    }

    function top(HeapData storage heap) internal view returns (Order memory) {
        require(heap.data.length > 0, "Heap is empty");
        return heap.data[0];
    }

    function push(HeapData storage heap, Order memory order) internal {
        heap.data.push(order);
        heap.indexMap[order.id] = heap.data.length - 1;
        siftUp(heap, heap.data.length - 1);
    }

    function pop(HeapData storage heap) internal returns (Order memory) {
        require(heap.data.length > 0, "Heap is empty");

        Order memory order = heap.data[0];

        heap.data[0] = heap.data[heap.data.length - 1];
        heap.indexMap[heap.data[0].id] = 0;

        heap.data.pop();
        delete heap.indexMap[order.id];

        if (heap.data.length > 0) {
            siftDown(heap, 0);
        }
        return order;
    }

    function remove(HeapData storage heap, Order memory order) internal {
        require(heap.data.length > 0, "Heap is empty");

        uint256 i = heap.indexMap[order.id];
        require(i < heap.data.length, "Order not found");
        delete heap.indexMap[order.id];

        if (i == heap.data.length - 1) {
            heap.data.pop();
            return;
        }

        Order memory tmp = heap.data[i];
        heap.data[i] = heap.data[heap.data.length - 1];
        heap.indexMap[heap.data[i].id] = i;

        heap.data.pop();

        if (
            (heap.heapType == HeapType.MaxHeap && tmp.price > order.price) ||
            (heap.heapType == HeapType.MinHeap && tmp.price < order.price)
        ) {
            siftUp(heap, i);
        } else {
            siftDown(heap, i);
        }
    }

    function parent(uint256 i) private pure returns (uint256) {
        return (i - 1) / 2;
    }

    function leftChild(uint256 i) private pure returns (uint256) {
        return 2 * i + 1;
    }

    function rightChild(uint256 i) private pure returns (uint256) {
        return 2 * i + 2;
    }

    function siftUp(HeapData storage heap, uint256 i) private {
        if (heap.heapType == HeapType.MaxHeap) {
            while (i > 0 && heap.data[parent(i)].price < heap.data[i].price) {
                uint256 p = parent(i);

                Order memory tmp = heap.data[i];
                heap.data[i] = heap.data[p];
                heap.data[p] = tmp;

                heap.indexMap[heap.data[i].id] = i;
                heap.indexMap[heap.data[p].id] = p;

                i = parent(i);
            }
        } else {
            while (i > 0 && heap.data[parent(i)].price > heap.data[i].price) {
                uint256 p = parent(i);

                Order memory tmp = heap.data[i];
                heap.data[i] = heap.data[parent(i)];
                heap.data[parent(i)] = tmp;

                heap.indexMap[heap.data[i].id] = i;
                heap.indexMap[heap.data[p].id] = p;

                i = parent(i);
            }
        }
    }

    function siftDown(HeapData storage heap, uint256 i) private {
        if (heap.heapType == HeapType.MaxHeap) {
            while (leftChild(i) < heap.data.length) {
                uint256 j = leftChild(i);
                if (
                    j < heap.data.length - 1 &&
                    heap.data[j].price < heap.data[j + 1].price
                ) {
                    j++;
                }
                if (heap.data[i].price >= heap.data[j].price) {
                    break;
                }
                Order memory tmp = heap.data[i];
                heap.data[i] = heap.data[j];
                heap.data[j] = tmp;

                heap.indexMap[heap.data[i].id] = i;
                heap.indexMap[heap.data[j].id] = j;

                i = j;
            }
        } else {
            while (leftChild(i) < heap.data.length) {
                uint256 j = leftChild(i);
                if (
                    j < heap.data.length - 1 &&
                    heap.data[j].price > heap.data[j + 1].price
                ) {
                    j++;
                }
                if (heap.data[i].price <= heap.data[j].price) {
                    break;
                }
                Order memory tmp = heap.data[i];
                heap.data[i] = heap.data[j];
                heap.data[j] = tmp;

                heap.indexMap[heap.data[i].id] = i;
                heap.indexMap[heap.data[j].id] = j;

                i = j;
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: contracts/trade_without_commits.sol


pragma solidity ^0.8.0;



contract QuickOrderTrade {
    using OrderHeapLib for OrderHeapLib.HeapData;

    address public governance;
    address public underlying;
    uint256 public constant PRICE_PRECISION = 1e30;

    mapping(address => bool) public tokenListed;

    mapping(address => OrderHeapLib.HeapData) public buyOrders;
    mapping(address => OrderHeapLib.HeapData) public sellOrders;
    uint256 public orderCount;

    struct OrderMetaData {
        address token;
        bool isBuy;
    }
    mapping(uint256 => OrderMetaData) public ordersMeta;

    event TokenListed(address token);
    event TokenDelisted(address token);

    event OrderPlaced(
        uint256 id,
        address user,
        bool    isBuy,
        address indexed token,
        uint256 price,
        uint256 amount
    );

    event OrderMatched(
        address indexed token,
        uint256 price,
        uint256 amount,
        uint256 buyOrderId,
        address buyer,
        uint256 buyOrderLeftAmount,
        uint256 sellOrderId,
        address seller,
        uint256 sellOrderLeftAmount
    );

    event OrderCanceled(
        uint256 id,
        address user,
        bool    isBuy,
        address indexed token,
        uint256 price,
        uint256 amount
    );

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    constructor() {
        governance = tx.origin;
    }

    function setGovernance(address _governance) external onlyGov {
        governance = _governance;
    }

    function setUnderlying(address _underlying) external onlyGov {
        underlying = _underlying;
    }

    function listToken(address _token) public onlyGov {
        require(!tokenListed[_token], "token listed");
        tokenListed[_token] = true;

        OrderHeapLib.HeapData storage buyOrder = buyOrders[_token];
        buyOrder.heapType = OrderHeapLib.HeapType.MaxHeap;

        OrderHeapLib.HeapData storage sellOrder = sellOrders[_token];
        sellOrder.heapType = OrderHeapLib.HeapType.MinHeap;

        emit TokenListed(_token);
    }

    function listTokens(address[] calldata _tokens) external {
        for (uint256 i = 0; i < _tokens.length; i++) {
            listToken(_tokens[i]);
        }
    }

    function calcTokenToUnderlying(
        address token,
        uint256 amount,
        uint256 price
    ) public view returns (uint256) {
        return
        (amount * price * (10**IERC20Metadata(underlying).decimals())) /
        (PRICE_PRECISION * (10**IERC20Metadata(token).decimals()));
    }

    function buyOrdersDetail(address token)
    public
    view
    returns (OrderHeapLib.Order[] memory)
    {
        return buyOrders[token].data;
    }

    function sellOrdersDetail(address token)
    public
    view
    returns (OrderHeapLib.Order[] memory)
    {
        return sellOrders[token].data;
    }

    function ordersDetail(address token)
    public
    view
    returns (OrderHeapLib.Order[] memory, OrderHeapLib.Order[] memory)
    {
        return (buyOrders[token].data, sellOrders[token].data);
    }

    function getOrderDetail(uint256 orderId)
    public
    view
    returns (OrderHeapLib.Order memory)
    {
        OrderMetaData memory orderMeta = ordersMeta[orderId];
        uint256 index = orderMeta.isBuy
        ? buyOrders[orderMeta.token].indexMap[orderId]
        : sellOrders[orderMeta.token].indexMap[orderId];

        return orderMeta.isBuy
        ? buyOrders[orderMeta.token].data[index]
        : sellOrders[orderMeta.token].data[index];
    }

    function placeOrder(
        address token,
        uint256 price,
        uint256 amount,
        bool isBuy
    ) external {
        require(tokenListed[token], "Token not listed");
        require(amount > 0, "Amount must be greater than 0");

        orderCount++;
        emit OrderPlaced(orderCount, msg.sender, isBuy, token, price, amount);

        OrderHeapLib.Order memory order = OrderHeapLib.Order(
            orderCount,
            token,
            price,
            amount,
            0,
            0,
            msg.sender,
            isBuy
        );
        ordersMeta[orderCount] = OrderMetaData(token, isBuy);

        if (isBuy) {
            uint256 underlyingAmount = calcTokenToUnderlying(
                token,
                amount,
                price
            );
            IERC20(underlying).transferFrom(
                msg.sender,
                address(this),
                underlyingAmount
            );
            order.payed = underlyingAmount;

            matchOrders(order);

            if (order.amount > 0) {
                buyOrders[token].push(order);
            }
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);

            matchOrders(order);

            if (order.amount > 0) {
                sellOrders[token].push(order);
            }
        }

    }

    function closeOrder(uint256 orderId) external {
        OrderMetaData memory orderMeta = ordersMeta[orderId];
        uint256 index = orderMeta.isBuy
        ? buyOrders[orderMeta.token].indexMap[orderId]
        : sellOrders[orderMeta.token].indexMap[orderId];
        OrderHeapLib.Order memory order = orderMeta.isBuy
        ? buyOrders[orderMeta.token].data[index]
        : sellOrders[orderMeta.token].data[index];

        require(msg.sender == order.user, "invalid user");
        require(order.amount > 0, "invalid order id");

        if (order.isBuy) {
            IERC20(underlying).transfer(
                order.user,
                order.payed - order.accPayed
            );

            buyOrders[order.token].remove(order);
        } else {
            IERC20(order.token).transfer(order.user, order.amount);

            sellOrders[order.token].remove(order);
        }

        delete ordersMeta[orderId];
        emit OrderCanceled(
            orderId,
            order.user,
            order.isBuy,
            order.token,
            order.price,
            order.amount
        );
    }

    function matchOrders(OrderHeapLib.Order memory order) internal {
        if (order.isBuy) {
            uint256 actualPayed = 0;
            uint256 dealAmount = 0;

            while (
                order.amount > 0 &&
                sellOrders[order.token].data.length > 0 &&
                sellOrders[order.token].top().price <= order.price
            ) {
                OrderHeapLib.Order memory sellOrder = sellOrders[order.token].top();

                uint256 curAmount = 0;

                if (order.amount >= sellOrder.amount) {
                    curAmount = sellOrder.amount;

                    sellOrders[order.token].pop();
                } else {
                    curAmount = order.amount;
                    sellOrders[order.token].data[0].amount -= curAmount;
                }

                order.amount -= curAmount;
                dealAmount += curAmount;

                if (curAmount > 0) {
                    uint256 underlyingAmount = calcTokenToUnderlying(order.token, curAmount, sellOrder.price);
                    actualPayed += underlyingAmount;
                    IERC20(underlying).transfer(sellOrder.user, underlyingAmount);
                }

                emit OrderMatched(
                    order.token,
                    sellOrder.price,
                    curAmount,
                    order.id,
                    order.user,
                    order.amount,
                    sellOrder.id,
                    sellOrder.user,
                    sellOrder.amount
                );
            }

            if (dealAmount > 0) {
                IERC20(order.token).transfer(order.user, dealAmount);
            }

            order.accPayed += actualPayed;
            if (order.amount == 0 && order.payed > order.accPayed) {
                IERC20(underlying).transfer(order.user, order.payed - order.accPayed);
            }
        } else {
            uint256 actualEarned = 0;

            while (
                order.amount > 0 &&
                buyOrders[order.token].data.length > 0 &&
                buyOrders[order.token].top().price >= order.price
            ) {
                OrderHeapLib.Order memory buyOrder = buyOrders[order.token].top();

                uint256 curAmount = 0;

                if (order.amount >= buyOrder.amount) {
                    curAmount = buyOrder.amount;

                    buyOrders[order.token].pop();
                } else {
                    curAmount = order.amount;
                    buyOrders[order.token].data[0].amount -= curAmount;
                }

                order.amount -= curAmount;

                if (curAmount > 0) {
                    uint256 underlyingAmount = calcTokenToUnderlying(order.token, curAmount, buyOrder.price);
                    actualEarned += underlyingAmount;
                    IERC20(order.token).transfer(buyOrder.user, curAmount);

                    buyOrder.accPayed += underlyingAmount;
                }

                emit OrderMatched(
                    order.token,
                    buyOrder.price,
                    curAmount,
                    buyOrder.id,
                    buyOrder.user,
                    buyOrder.amount,
                    order.id,
                    order.user,
                    order.amount
                );
            }

            if (actualEarned > 0) {
                IERC20(underlying).transfer(order.user, actualEarned);
            }
        }
    }
}