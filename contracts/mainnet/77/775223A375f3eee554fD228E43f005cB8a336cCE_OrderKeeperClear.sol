pragma solidity ^0.8.0;
import "IOrderBook.sol";
import "IERC20Metadata.sol";
import "PausableGuardian_0_8.sol";

contract OrderKeeperClear is PausableGuardian_0_8 {
    address public implementation;
	IERC20Metadata public constant WRAPPED_TOKEN = IERC20Metadata(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    IOrderBook public orderBook;

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (uint256 start, uint256 end) = abi.decode(checkData, (uint256, uint256));
        uint256 orderIDLength = orderBook.getTotalOrderIDs();
        if (start > orderIDLength) {
            return (upkeepNeeded, performData);
        }
        if(end > orderIDLength) {
            end  = orderIDLength;
        }
        return orderBook.getClearOrderList(start, end);
    }

    function performUpkeep(bytes calldata performData) external pausable {
        bytes32[] memory orderId = abi.decode(performData, (bytes32[]));
        //emit OrderExecuted(trader,orderId);
        for (uint i;i<orderId.length;) {
            if(orderId[i]==0) {
                unchecked { ++i; }
                continue;
            }
            orderBook.cancelOrderProtocol(orderId[i]);
            unchecked { ++i; }
        }
    }

    function setOrderBook(IOrderBook contractAddress) external onlyOwner {
        orderBook = contractAddress;
    }

    function withdrawIncentivesReceived(address receiver) external onlyOwner {
        WRAPPED_TOKEN.transfer(receiver, WRAPPED_TOKEN.balanceOf(address(this)));
    }
}

pragma solidity ^0.8.0;

interface IOrderBook {
    enum OrderType {
        LIMIT_OPEN,
        LIMIT_CLOSE,
        MARKET_STOP
    }

    enum OrderStatus {
        ACTIVE,
        CANCELLED,
        EXECUTED
    }

    /*
    Used values for different order types:
        LIMIT_OPEN:
            loanID
            orderID
            amountReceived
            leverage
            loanTokenAmount
            collateralTokenAmount
            trader
            iToken
            loanTokenAddress
            base
            orderType
            status
            timeTillExpiration
            loanDataBytes
        LIMIT_CLOSE and MARKET_STOP:
            loanID
            orderID
            amountReceived
            loanTokenAmount
            collateralTokenAmount
            trader
            iToken
            loanTokenAddress
            base
            orderType
            status
            timeTillExpiration
            loanDataBytes
    */
    struct Order {
        bytes32 loanID; //ID of the loan on OOKI protocol
        bytes32 orderID; //order ID
        uint256 amountReceived; //amount received from the trade executing. Denominated in base for limit open and loanTokenAddress for limit close and market stop
        uint256 leverage; //leverage amount
        uint256 loanTokenAmount; //loan token amount denominated in loanTokenAddress
        uint256 collateralTokenAmount; //collateral token amount denominated in base
        address trader; //trader placing order
        address iToken; //iToken being interacted with
        address loanTokenAddress; //loan token
        address base; //collateral token
        OrderType orderType; //order type
        OrderStatus status; //order status
        uint64 timeTillExpiration; //Time till expiration. Useful for GTD and time-based cancellation
        bytes loanDataBytes; //data passed for margin trades
    }

    /// Returns Deposits contract address
    /// @return vault Deposits Contract
    function VAULT() external view returns(address vault);

    /// Returns Protocol contract address
    /// @return protocol ooki protocol contract
    function PROTOCOL() external view returns(address protocol);

    /// Returns minimum trade size in USDC
    /// @return size USDC amount
    function MIN_AMOUNT_IN_USDC() external view returns(uint256 size);

    /// Places new Order
    /// @param order Order Struct
    function placeOrder(Order calldata order) external;

    /// Amends Order
    /// @param order Order Struct
    function amendOrder(Order calldata order) external;

    /// Cancels Order
    /// @param orderID ID of order to be canceled
    function cancelOrder(bytes32 orderID) external;

    /// Cancels Order
    /// @param orderID ID of order to be canceled
    function cancelOrderProtocol(bytes32 orderID) external returns (uint256);

    /// Force cancels order
    /// @param orderID ID of order to be canceled
    function cancelOrderGuardian(bytes32 orderID) external;

    /// Changes stop type between index and dex price
    /// @param stopType true = index, false = dex price
    function changeStopType(bool stopType) external;

    /// Set price feed contract address
    /// @param newFeed new price feed contract
    function setPriceFeed(address newFeed) external;

    /// Set gas price to be used for incentives (if price feed does not already contain it)
    /// @param gasPrice gas price in gwei
    function setGasPrice(uint256 gasPrice) external;

    /// Return price feed contract address
    /// @return priceFeed Price Feed Contract Address
    function priceFeed() external view returns (address priceFeed);

    /// Returns gas price used for incentive calculations
    /// @return gasPrice gas price in gwei
    function getGasPrice() external view returns (uint256 gasPrice);

    /// Deposit Gas Token to pay out incentives for orders to be executed
    /// @param amount when depositing wrapped token, this is amount to be deposited (leave as 0 if sending native token)
    function depositGasFeeToken(uint256 amount) external payable;

    /// Withdraw Gas Token (received as native token)
    /// @param amount amount to be withdrawn
    function withdrawGasFeeToken(uint256 amount) external;

    /// Return amount received through a specified swap
    /// @param srcToken source token address
    /// @param destToken destination token address
    /// @param payload loanDataBytes passed for margin trades
    /// @param amountIn amount in for the swap
    function getDexRate(address srcToken, address destToken, bytes calldata payload, uint256 amountIn) external returns(uint256);

    /// Checks if order is able to be cleared from books due to failing to meet all requirements
    /// @param orderID order ID
    function clearOrder(bytes32 orderID) external view returns (bool);

    /// Returns list of orders that are up to be cleared. Used for Chainlink Keepers
    /// @param start starting index
    /// @param end ending index
    /// @return hasOrders true if the payload contains any orders
    /// @return payload bytes32[] encoded with the order IDs up for clearing from books
    function getClearOrderList(uint start, uint end) external view returns (bool hasOrders, bytes memory payload);

    /// Returns an order ID available for execution. Used for Chainlink Keepers
    /// @param start starting index
    /// @param end ending index
    /// @return ID order ID up for execution. If equal to 0 there is no order ID up for execution in the specified index range
    function getExecuteOrder(uint start, uint end) external returns (bytes32 ID);

    /// Checks if order meets requirements for execution
    /// @param orderID order ID of order being checked
    function prelimCheck(bytes32 orderID) external returns (bool);

    /// Returns oracle rate for a swap
    /// @param srcToken source token address
    /// @param destToken destination token address
    /// @param amount swap amount
    function queryRateReturn(address srcToken, address destToken, uint256 amount) external view returns(uint256);

    /// Checks if dex rate is within acceptable bounds from oracle rate
    /// @param srcToken source token address
    /// @param destToken destination token address
    /// @param payload loanDataBytes used for margin trade
    function priceCheck(address srcToken, address destToken, bytes calldata payload) external returns(bool);

    /// Executes Order
    /// @param orderID order ID
    /// @return incentiveAmountReceived amount received in gas token from exeuction of order
    function executeOrder(bytes32 orderID) external returns(uint256 incentiveAmountReceived);

    /// sets token allowances
    /// @param spenders addresses that will be given allowance
    /// @param tokens token addresses
    function adjustAllowance(address[] calldata spenders, address[] calldata tokens) external;

    /// revokes token allowances
    /// @param spenders addresses that will have allowance revoked
    /// @param tokens token addresses
    function revokeAllowance(address[] calldata spenders, address[] calldata tokens) external;

    /// Retrieves active orders for a trader
    /// @param trader address of trader
    function getActiveOrders(address trader) external view returns (Order[] memory);

    /// Retrieves active orders for a trader
    /// @param trader address of trader
    /// @param start starting index
    /// @param end ending index
    function getActiveOrdersLimited(address trader, uint256 start, uint256 end) external view returns (Order[] memory);

    /// Retrieves order corresponding to an order ID
    /// @param orderID order ID
    function getOrderByOrderID(bytes32 orderID) external view returns (Order memory);

    /// Retrieves active order IDs for a trader
    /// @param trader address of trader
    function getActiveOrderIDs(address trader) external view returns (bytes32[] memory);

    /// Returns total active orders count for a trader
    /// @param trader address of trader
    function getTotalOrders(address trader) external view returns (uint256);

    /// Returns total active orders count
    function getTotalOrderIDs() external view returns (uint256);

    /// Returns total active order IDs
    function getOrderIDs() external view returns (bytes32[] memory);
    
    /// Returns total active orders
    function getOrders() external view returns (Order[] memory);

    /// Returns active order IDs
    /// @param start starting index
    /// @param end ending index
    function getOrderIDsLimited(uint256 start, uint256 end) external view returns (bytes32[] memory);

    /// Returns active orders
    /// @param start starting index
    /// @param end ending index
    function getOrdersLimited(uint256 start, uint256 end) external view returns (Order[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;

import "Ownable.sol";

contract PausableGuardian_0_8 is Ownable {
    // keccak256("Pausable_FunctionPause")
    bytes32 internal constant Pausable_FunctionPause = 0xa7143c84d793a15503da6f19bf9119a2dac94448ca45d77c8bf08f57b2e91047;

    // keccak256("Pausable_GuardianAddress")
    bytes32 internal constant Pausable_GuardianAddress = 0x80e6706973d0c59541550537fd6a33b971efad732635e6c3b99fb01006803cdf;

    modifier pausable() {
        require(!_isPaused(msg.sig) || msg.sender == getGuardian(), "paused");
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");_;
    }

    function _isPaused(bytes4 sig) public view returns (bool isPaused) {
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            isPaused := sload(slot)
        }
    }

    function toggleFunctionPause(bytes4 sig) public {
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            sstore(slot, 1)
        }
    }

    function toggleFunctionUnPause(bytes4 sig) public {
        // only DAO can unpause, and adding guardian temporarily
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            sstore(slot, 0)
        }
    }

    function changeGuardian(address newGuardian) public {
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        assembly {
            sstore(Pausable_GuardianAddress, newGuardian)
        }
    }

    function getGuardian() public view returns (address guardian) {
        assembly {
            guardian := sload(Pausable_GuardianAddress)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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