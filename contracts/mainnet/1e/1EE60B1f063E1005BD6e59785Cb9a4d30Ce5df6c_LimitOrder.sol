// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SushiRouterInterface.sol";
import "./IdentityInterface.sol";

contract LimitOrder {
    // mainnet address: 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
    address private sushiRouterAddress;

    event OrderCreated(
        address sender,
        IERC20 fromToken,
        IERC20 toToken,
        uint64 expiry,
        uint64 slippage,
        uint fromTokenAmount,
        uint toTokenAmount,
        uint orderId
    );
    event OrderStatusChanged(
        uint orderId,
        OrderStatus status
    );

    enum OrderStatus{ PENDING, COMPLETED, CANCELED }
    struct Order {
        address sender;
        IERC20 fromToken;
        IERC20 toToken;
        uint64 expiry;
        uint64 slippage;
        uint fromTokenAmount;
        uint toTokenAmount;
        uint orderId;
        OrderStatus status;
    }

    mapping(uint => Order) public orders;
    mapping(address => uint[]) public userOrderReferences;
    uint public orderCount;

    constructor(address _sushiRouter) {
        sushiRouterAddress = _sushiRouter;
    }

    modifier futureTime(uint _time) {
        require(_time > block.timestamp, "Time has already passed");
        _;
    }

    modifier validPercentage(uint _percentage) {
        require(_percentage < 10000, 'Please choose a valid slippage');
        _;
    }

    modifier orderExists(uint _orderId) {
        require(_orderId <= orderCount, 'Order does not exist');
        _;
    }

    modifier orderBelongsToSender(uint _orderId) {
        require(orders[_orderId].sender == msg.sender, 'Invalid order');
        _;
    }

    modifier orderPending(uint _orderId) {
        require(orders[_orderId].status == OrderStatus.PENDING, 'Order cannot be cancelled');
        _;
    }

    function createOrder(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint64 _expiry,
        uint64 _slippage,
        uint _fromTokenAmount,
        uint _toTokenAmount
    ) public futureTime(_expiry) validPercentage(_slippage) {
        Order memory _order = Order(
            msg.sender,
            _fromToken,
            _toToken,
            _expiry,
            _slippage,
            _fromTokenAmount,
            _toTokenAmount,
            orderCount,
            OrderStatus.PENDING
        );
        orders[orderCount] = _order;
        userOrderReferences[msg.sender].push(orderCount);

        emit OrderCreated(
            msg.sender,
            _fromToken,
            _toToken,
            _expiry,
            _slippage,
            _fromTokenAmount,
            _toTokenAmount,
            orderCount
        );

        orderCount++;
    }

    function getOrders() public view returns(Order[] memory) {
        Order[] memory userOrders = new Order[](userOrderReferences[msg.sender].length);

        for(uint orderId = 0; orderId < userOrderReferences[msg.sender].length; orderId++) {
            uint userOrderId = userOrderReferences[msg.sender][orderId];
            userOrders[orderId] = orders[userOrderId];
        }

        return userOrders;
    }

    function cancelOrder(uint _orderId) public
        orderExists(_orderId)
        orderBelongsToSender(_orderId)
        orderPending(_orderId) {
        orders[_orderId].status = OrderStatus.CANCELED;
        emit OrderStatusChanged(_orderId, OrderStatus.CANCELED);
    }

    function checkUpkeep() public view returns (bool upkeepNeeded, bytes memory performData) {
        uint[] memory idsTempArr = new uint[](orderCount);
        uint idsForExecCount = 0;

        // TODO: implement logic for iterating ONLY over the pending orders here
        for (uint i = 0; i < orderCount; i++) {
            Order memory orderTemp = orders[i];

            // check for pending orders
            // TODO: remove, related to upper todo.
            if (orderTemp.status != OrderStatus.PENDING) {
                continue;
            }

            // check expiry
            if (orderTemp.expiry <= block.timestamp) {
                // TODO: flag as expired
                continue;
            }

            // check amount out
            if (getSwapOutputAmount(orderTemp) >= orderTemp.toTokenAmount) {
                idsTempArr[idsForExecCount] = i;
                idsForExecCount++;
            }
        }

        // format check result
        uint[] memory idsForExec = new uint[](idsForExecCount);
        for (uint i = 0; i < idsForExecCount; i++) {
            idsForExec[i] = idsTempArr[i];
        }
        upkeepNeeded = idsForExecCount > 0;
        performData = abi.encode(idsForExec);

        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external {
        (uint[] memory idsForExec) = abi.decode(performData, (uint[]));
        uint idsForExecCount = idsForExec.length;

        // TODO: group orders by sender(wallet)

        for (uint i = 0; i < idsForExecCount; i++) {
            Order memory orderTemp = orders[idsForExec[i]];
            require(orderTemp.expiry > block.timestamp, "Order is expired.");
            require(getSwapOutputAmount(orderTemp) >= orderTemp.toTokenAmount, "Order price does not match.");

            // update order to completed
            orderTemp.status = OrderStatus.COMPLETED;
            orders[idsForExec[i]] = orderTemp;

            // build transaction array as that's what is expected as argument for executeBySender
            IdentityInterface.Transaction[] memory txnsTemp = new IdentityInterface.Transaction[](1);

            // prep address array for encoding
            address[] memory swapPath = new address[](2);
            swapPath[0] = address(orderTemp.fromToken);
            swapPath[1] = address(orderTemp.toToken);

            txnsTemp[0] = IdentityInterface.Transaction(
                sushiRouterAddress,
                0,
                abi.encodeWithSignature(
                    "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                    orderTemp.fromTokenAmount,
                    orderTemp.toTokenAmount,
                    swapPath,
                    orderTemp.sender,
                    uint(orderTemp.expiry)
                )
            );

            IdentityInterface(payable(orderTemp.sender)).executeBySender(txnsTemp);
        }
    }

    function getSwapOutputAmount(Order memory _order) private view returns (uint) {
        address[] memory pairPath = new address[](2);
        pairPath[0] = address(_order.fromToken);
        pairPath[1] = address(_order.toToken);

        uint[] memory amounts = SushiRouterInterface(sushiRouterAddress).getAmountsOut(
            _order.fromTokenAmount,
            pairPath
        );

        return amounts[1];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.7;

abstract contract SushiRouterInterface {
    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual returns (uint[] memory amounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.7;

abstract contract IdentityInterface {

    struct Transaction {
		address to;
		uint value;
		bytes data;
	}
    function executeBySender(Transaction[] calldata txns) virtual external;
}