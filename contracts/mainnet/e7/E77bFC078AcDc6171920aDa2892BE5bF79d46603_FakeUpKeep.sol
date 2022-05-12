// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./LimitOrder.sol";

contract FakeUpKeep is KeeperCompatible, Pausable, Ownable {
    address private limitOrderAddress;

    constructor( address _limitOrderAddress) {
        limitOrderAddress = _limitOrderAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        (upkeepNeeded, performData) = LimitOrder(limitOrderAddress).checkUpkeep();
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override {
        LimitOrder(limitOrderAddress).performUpkeep(performData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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