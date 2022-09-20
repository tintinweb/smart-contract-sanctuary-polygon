// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title - Orderbook contract
 * @notice - This contract has role that switch open/cancel to put on sale of TCOE
 */
contract Orderbook is Ownable, Pausable {
    uint256 public ordersCounter = 0;
    uint256 public itemsSold = 0;

    // DAI Interface
    IERC20 DAI;
    // TCOE Interface
    IERC20 TCOE;
    // Dai x TCOE
    uint256 public daiPerTCOE = 50770000000000000000;
    // Biotoken Address
    address private biotokenAddress;

    mapping(uint256 => OrderSale) private idToOrderSale;

    struct OrderSale {
        uint256 orderId;
        address seller;
        address owner;
        uint256 amount;
        bool sold;
        bool deleted;
    }

    event OrderSaleCreated(
        uint256 indexed orderId,
        address seller,
        address owner,
        uint256 amount,
        bool sold,
        bool deleted
    );

    event OrderSaleCanceled(
        uint256 indexed orderId,
        address seller,
        address owner,
        uint256 amount,
        bool sold,
        bool deleted
    );

    constructor(
        address TCOEaddress,
        address DAIaddress,
        address BiotokenAddress
    ) {
        TCOE = IERC20(TCOEaddress);
        DAI = IERC20(DAIaddress);
        biotokenAddress = BiotokenAddress;
    }

    /* Updates the price of Dai x TCOE */
    function updateDaiPerTCOE(uint256 _newValue) public onlyOwner isNotPaused {
        daiPerTCOE = _newValue;
    }

    /* Creates the order sale to sell TCOE */
    function createTokenSale(uint256 _amount) public isNotPaused {
        uint256 counter = ordersCounter;

        idToOrderSale[counter] = OrderSale(
            counter,
            msg.sender,
            address(this),
            _amount,
            false,
            false
        );

        TCOE.transferFrom(msg.sender, address(this), _amount);

        emit OrderSaleCreated(
            counter,
            msg.sender,
            address(this),
            _amount,
            false,
            false
        );

        ordersCounter = ordersCounter++;
    }

    /* Returns an specific order */
    function getOrderSale(uint256 orderId)
        public
        view
        returns (OrderSale memory)
    {
        return idToOrderSale[orderId];
    }

    /* Returns all orders */
    function getAllOrders() public view returns (OrderSale[] memory) {
        uint256 itemCount = ordersCounter;
        uint256 currentIndex = 0;
        OrderSale[] memory items = new OrderSale[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            OrderSale storage currentToken = idToOrderSale[i];
            items[currentIndex] = currentToken;
            currentIndex += 1;
        }
        return items;
    }

    /* Creates the sale of TCOE */
    /* Transfers TCOE to buyer and DAI to seller */
    function acceptSaleOrder(uint256 orderId) public isNotPaused {
        require(
            idToOrderSale[orderId].deleted == false,
            "Order must be active"
        );

        address seller = idToOrderSale[orderId].seller;

        uint256 DAIToTransfer = (idToOrderSale[orderId].amount * daiPerTCOE) /
            1 ether;
        uint256 TCOEToTransfer = idToOrderSale[orderId].amount;

        // Modifico metadata de la orden
        idToOrderSale[orderId].owner = msg.sender;
        idToOrderSale[orderId].sold = true;
        itemsSold = itemsSold++;

        // Transfiero los DAI al vendedor
        DAI.transferFrom(msg.sender, seller, DAIToTransfer);

        // Transfiero fee a Biotoken address - 0.0025 % TCOE
        uint256 fee = (TCOEToTransfer * 25) / 1000000;
        TCOE.transfer(biotokenAddress, fee);

        // Transfiero los TCOE restantes al comprador
        TCOE.transfer(msg.sender, TCOEToTransfer - fee);
    }

    /* Cancels the sale of TCOE */
    function cancelSaleOrder(uint256 orderId) public isNotPaused {
        require(
            idToOrderSale[orderId].deleted == false,
            "Order must be active"
        );
        require(
            idToOrderSale[orderId].seller == msg.sender,
            "Only Seller can cancel"
        );

        uint256 TCOEToTransfer = idToOrderSale[orderId].amount;

        idToOrderSale[orderId].deleted = true;
        idToOrderSale[orderId].owner = msg.sender;

        TCOE.transfer(msg.sender, TCOEToTransfer);

        emit OrderSaleCanceled(
            orderId,
            idToOrderSale[orderId].seller,
            idToOrderSale[orderId].seller,
            idToOrderSale[orderId].amount,
            false,
            true
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract module which provides a basic pause control mechanism,
 * to pause contract specific functions.
 *
 * By default, the owner can only change the state of the main contract.
 *
 * This module is used through inheritance. It will make available the modifier
 * `isNotPaused`, which can be applied to your functions to restrict their use 
 * when the contract is paused
 */
abstract contract Pausable is Ownable {
    bool private _paused;

    event PausedStateChanged(bool newState);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier isNotPaused() {
        _checkPaused();
        _;
    }

    /**
     * @dev Returns the state of the contract.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _checkPaused() internal view virtual {
        require(_paused == false, "Pausable: contract paused");
    }

    /**
     * @dev Changes contract state.
     */
    function setPaused() public onlyOwner {
        _paused = !_paused;
        emit PausedStateChanged(_paused);
    }
}