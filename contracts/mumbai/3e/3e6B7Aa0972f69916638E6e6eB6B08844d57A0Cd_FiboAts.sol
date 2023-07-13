//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./limitOrders.sol";
import "../signatures/EIP712.sol";

/// @title provides order settlement for Fibo's alternative trading system
// XXX: make this upgradeable
contract FiboAts is FiboEIP712, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using FiboLimitOrders for FiboLimitOrders.LimitOrder;

    struct ExecutionDetails {
        /// @notice the address of the account which bought `assetToken`
        address buyer;
        /// @notice the address of the account which sold `assetToken`
        address seller;
        /// @notice the price (measured in `denominationToken`) paid by `buyer` for each share of `assetToken`
        uint256 pricePerShare;
        /// @notice the number of shares of `assetToken` traded between `buyer` and `seller`
        uint256 quantity;
        /// @notice the total amount (measured in `denominationToken`) paid by `buyer`
        /// this due to rounding, this may not be exactly equal to `quantity * pricePerShare`
        uint256 totalPrice;
    }

    /// @notice emitted whenever an order is matched on-chain
    /// @param assetToken the address of the primary asset being traded
    /// @param denominationToken the address of the token denominating the price of the primary asset
    /// @param details additional information about the execution; see documentation for the `ExecutionDetails` struct for more information
    event TradeExecution(
        address indexed assetToken,
        address indexed denominationToken,
        ExecutionDetails details
    );

    /// @notice emitted whenever an order is cancelled on-chain
    /// @param trader the user cancelling the order
    /// @param orderHash the hash of the order being cancelled
    event OrderCancelled(address trader, bytes32 orderHash);

    /// @notice used to determine which part of a trade caused the error
    enum TradeFailureParty {
        taker,
        maker,
        other
    }

    enum TradeFailureReason {
        none,
        invalid_input,
        invalid_signature,
        expired,
        executed_or_cancelled,
        insufficient_approval,
        insufficient_balance,
        transfer_failed,
        makers_out_of_order,
        old_nonce,
        no_cross,
        overflow,
        invalid_post_trade_signature,
        incorrect_price
    }

    /// @notice whenever an attempted trade transaction fails, this error will be used as the revert output
    /// @param party indicates which part of an execution caused the error.
    /// taker: the taker order could not be executed (order was invalid or assets couldn't be transferred)
    /// maker: the maker order could not be executed (order was invalid or assets couldn't be transferred)
    /// other: the trade couldn't clear for reasons that aren't the fault of either the maker or taker
    /// @param reason a description of the error that occurred
    error TradeFailure(TradeFailureParty party, TradeFailureReason reason);

    /// @notice tracks how many shares have already been executed for each order so that
    /// they can't execute for more than the signer authorized
    mapping(bytes32 => uint256) public executionAmounts;

    /// @dev tracks which order batches have been cancelled
    /// if a user has cancelled a batch, then any order from that user with a matching batch id cannot trade
    mapping(address => mapping(uint256 => bool)) private cancelledBatches;

    /// @notice only orders with a matching `blockNonce` field can be executed
    /// @dev this field is updated to effectively cancel all previously-placed orders
    uint256 public blockNonce;

    bytes32 private constant LIMIT_ORDER_TYPE_HASH =
        keccak256(
            "LimitOrder(address trader,address assetToken,address denominationToken,bool isBuy,uint256 quantity,uint256 price,uint256 expiration,uint256 blockNonce,uint256 batchId,uint256 salt)"
        );

    // XXX: only until we make this upgradeable
    constructor() {
        initialize();
    }

    function initialize() public initializer {
        __Ownable_init();
        _updateDomain("FiboAts", "1");
    }

    function haltTrading() external onlyOwner {
        // XXX
    }

    /// @notice get the hash of an order based on its details
    /// this may be useful as a concise way to reference that order in other apis
    /// the hash is also a function of this particular contract deployment, and will not be compatible with other instances of the `FiboAts` contract
    /// @param order details of the order whose hash should be computed
    /// @return orderHash the hash of that order for this contract
    function getOrderHash(FiboLimitOrders.LimitOrder memory order)
        public
        view
        returns (bytes32 orderHash)
    {
        bytes memory orderEncoding = abi.encode(order);
        orderHash = _generateObjectHash(LIMIT_ORDER_TYPE_HASH, orderEncoding);
    }

    /// @notice cancel an order on-chain
    /// this will prevent the order from ever executing
    /// orders can also be cancelled off-chain through the fibo api, without signing a transaction on-chain
    /// only the contract owner or the order's `trader` can call this function
    /// @param order details of the order to cancel
    function cancelOrder(FiboLimitOrders.LimitOrder calldata order) external {
        require(
            msg.sender == order.trader || msg.sender == owner(),
            "only trader or owner can cancel"
        );

        bytes memory orderEncoding = abi.encode(order);
        bytes32 orderHash = _generateObjectHash(LIMIT_ORDER_TYPE_HASH, orderEncoding);

        // setting execution amount to the max value will prevent any future executions because any trade attempts will overflow
        executionAmounts[orderHash] = type(uint256).max;

        emit OrderCancelled(order.trader, orderHash);
    }

    /// @notice cancel a batch of orders, which will no longer be able to execute on-chain
    /// after this call, no order will be able to execute if it meets the following criteria:
    /// * `trader` field matches the `msg.sender` of the `cancelBatch` call
    /// * `batchId` field matches to `batchId` argument of the `cancelBatch` call
    /// @param batchId the batch of orders to cancel
    function cancelBatch(uint256 batchId) external {
        cancelledBatches[msg.sender][batchId] = true;
    }

    /// @notice match crossing orders against each other
    /// this function will execute as many shares as possible from `takerOrder`, and transfer all corresponding assets between the counterparties
    /// this function will revert if any of those transfers fail
    /// @param takerOrder a newly submitted order which crosses with other orders already on the book
    /// @param makerOrder an order which was already resting on the book
    function matchOrders(
        FiboLimitOrders.SignedLimitOrder calldata takerOrder,
        FiboLimitOrders.SignedLimitOrder calldata makerOrder,
        uint256 totalPrice,
        uint256 quantity
    ) external onlyOwner {
        bytes32 takerHash = _generateObjectHash(LIMIT_ORDER_TYPE_HASH, abi.encode(takerOrder.order));
        bytes32 makerHash = _generateObjectHash(LIMIT_ORDER_TYPE_HASH, abi.encode(makerOrder.order));

        verifyOrder(
            takerOrder,
            TradeFailureParty.taker
        );
        verifyOrder(
            makerOrder,
            TradeFailureParty.maker
        );

        uint256 takerQuantity = getSharesRemaining(takerOrder.order);
        if (takerQuantity < quantity) {
            revert TradeFailure({
                party: TradeFailureParty.taker,
                reason: TradeFailureReason.executed_or_cancelled
            });
        }

        uint256 makerQuantity = getSharesRemaining(makerOrder.order);
        if (makerQuantity < quantity) {
            revert TradeFailure({
                party: TradeFailureParty.maker,
                reason: TradeFailureReason.executed_or_cancelled
            });
        }

        (bool crosses, uint256 computedTotalPrice) = takerOrder.order.getCrossingTotalPrice(
            makerOrder.order,
            quantity
        );
        if (!crosses) {
            revert TradeFailure({
                party: TradeFailureParty.maker,
                reason: TradeFailureReason.no_cross
            });
        }

        if (totalPrice != computedTotalPrice) {
            revert TradeFailure({
                party: TradeFailureParty.other,
                reason: TradeFailureReason.incorrect_price
            });
        }

        executionAmounts[takerHash] += quantity;
        executionAmounts[makerHash] += quantity;

        executeOrder(takerOrder.order, makerOrder.order.trader, quantity, totalPrice);

        takerQuantity -= quantity;
    }

    function getSharesRemaining(FiboLimitOrders.LimitOrder memory order)
        public
        view
        returns (uint256 shares)
    {
        bytes32 orderHash = _generateObjectHash(LIMIT_ORDER_TYPE_HASH, abi.encode(order));
        uint256 sharesExecuted = executionAmounts[orderHash];
        if (sharesExecuted >= order.quantity) {
            return 0;
        }

        return order.quantity - sharesExecuted;
    }

    /// @dev transfer tokens between parties and return the results
    /// some ERC-20 implementations revert upon failure, but we want to provide our own structured revert reasons, which is why we wrap the transfer call here
    function attemptTransfer(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 quantity
    ) private returns (bool success, TradeFailureReason reason) {
        // even though it costs extra gas, make these checks manually so that we can expose proper reasons
        // even if the transfer call just returns false
        if (token.allowance(from, address(this)) < quantity) {
            return (false, TradeFailureReason.insufficient_approval);
        }

        if (token.balanceOf(from) < quantity) {
            return (false, TradeFailureReason.insufficient_balance);
        }

        bytes memory returnData;
        (success, returnData) = address(token).call(
            abi.encodePacked(token.transferFrom.selector, abi.encode(from, to, quantity))
        );

        if (!success) {
            return (false, TradeFailureReason.transfer_failed);
        }

        bool transferResult = abi.decode(returnData, (bool));
        if (!transferResult) {
            return (false, TradeFailureReason.transfer_failed);
        }

        return (true, TradeFailureReason.none);
    }

    /// @dev this function is for internal use only to perform the actual trade execution
    /// it does not perform any validation checks whatsoever, and assumes that the caller has already performed all necessary validation
    function executeOrder(
        FiboLimitOrders.LimitOrder memory takerOrder,
        address counterparty,
        uint256 quantity,
        uint256 totalPrice
    ) private {
        address buyer;
        address seller;

        if (takerOrder.isBuy) {
            buyer = takerOrder.trader;
            seller = counterparty;
        } else {
            buyer = counterparty;
            seller = takerOrder.trader;
        }

        bool transferResult;
        TradeFailureReason transferReason;

        (transferResult, transferReason) = attemptTransfer(
            IERC20Upgradeable(takerOrder.assetToken),
            seller,
            buyer,
            quantity
        );
        if (!transferResult) {
            revert TradeFailure({
                party: takerOrder.isBuy ? TradeFailureParty.maker : TradeFailureParty.taker,
                reason: transferReason
            });
        }

        (transferResult, transferReason) = attemptTransfer(
            IERC20Upgradeable(takerOrder.denominationToken),
            buyer,
            seller,
            totalPrice
        );
        if (!transferResult) {
            revert TradeFailure({
                party: takerOrder.isBuy ? TradeFailureParty.taker : TradeFailureParty.maker,
                reason: transferReason
            });
        }

        (bool valid, uint256 pricePerShare) = totalPrice.tryDiv(quantity);
        if (!valid) {
            revert TradeFailure({
                party: TradeFailureParty.other,
                reason: TradeFailureReason.overflow
            });
        }

        emit TradeExecution(
            takerOrder.assetToken,
            takerOrder.denominationToken,
            ExecutionDetails({
                buyer: buyer,
                seller: seller,
                pricePerShare: pricePerShare,
                quantity: quantity,
                totalPrice: totalPrice
            })
        );
    }

    /// @dev this function is for internal use only to verify that an order is valid to execute
    function getOrderError(
        FiboLimitOrders.SignedLimitOrder memory order
    ) private view returns (TradeFailureReason reason) {
        if (order.order.batchId > 0 && cancelledBatches[order.order.trader][order.order.batchId]) {
            return TradeFailureReason.executed_or_cancelled;
        }

        if (order.order.expiration > 0 && order.order.expiration <= block.timestamp) {
            return TradeFailureReason.expired;
        }

        if (order.order.blockNonce != blockNonce) {
            return TradeFailureReason.old_nonce;
        }

        if (
            !_verifySignature(
                LIMIT_ORDER_TYPE_HASH,
                abi.encode(order.order),
                order.order.trader,
                order.signature
            )
        ) {
            return TradeFailureReason.invalid_signature;
        }

        return TradeFailureReason.none;
    }

    function verifyOrder(
        FiboLimitOrders.SignedLimitOrder memory order,
        TradeFailureParty party
    ) private view {
        TradeFailureReason reason = getOrderError(order);

        if (reason != TradeFailureReason.none) {
            revert TradeFailure({party: party, reason: reason});
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol";

import "./signatureTypes.sol";

abstract contract FiboEIP712 {
    string public EIP712_name;
    string public EIP712_version;
    bytes32 internal _domainHash;

    function _updateDomain(string memory contractName, string memory version) internal {
        EIP712_name = contractName;
        EIP712_version = version;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        _domainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(EIP712_name)),
                keccak256(bytes(EIP712_version)),
                chainId,
                address(this)
            )
        );
    }

    function _generateObjectHash(bytes32 typeHash, bytes memory data)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", _domainHash, keccak256(bytes.concat(typeHash, data)))
            );
    }

    function _verifySignature(
        bytes32 typeHash,
        bytes memory data,
        address signer,
        Signature memory signature
    ) internal view returns (bool) {
        bytes32 objectHash = _generateObjectHash(typeHash, data);
        if (signature.sigType == SignatureType.SignatureEOA) {
            EOASignature memory eoaSig = abi.decode(signature.signatureData, (EOASignature));
            return _verifyEOASignature(objectHash, eoaSig, signer);
        } else if (signature.sigType == SignatureType.SignatureContract) {
            return _verifyContractSignature(objectHash, signer);
        } else {
            revert("unknown signature type");
        }
    }

    function _verifyEOASignature(
        bytes32 objectHash,
        EOASignature memory signature,
        address signer
    ) internal pure returns (bool) {
        return signer == ecrecover(objectHash, signature.v, signature.r, signature.s);
    }

    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant EIP1271_MAGICVALUE = 0x1626ba7e;

    // based on eip-1271: https://eips.ethereum.org/EIPS/eip-1271
    function _verifyContractSignature(bytes32 objectHash, address signer)
        internal
        view
        returns (bool)
    {
        bytes memory emptyBytes;
        bytes4 magicValue = IERC1271Upgradeable(signer).isValidSignature(objectHash, emptyBytes);
        return magicValue == EIP1271_MAGICVALUE;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../signatures/signatureTypes.sol";

library FiboLimitOrders {
    using SafeMathUpgradeable for uint256;

    struct LimitOrder {
        /// @notice the address of the account placing this order
        address trader;
        /// @notice the address of the asset being traded
        /// in the context of the fibo product this will typically be a property token
        address assetToken;
        /// @notice the address of the token denominating the "price" of the primary asset
        /// in the context of the fibo product with will typically be a stablecoin
        address denominationToken;
        /// @notice true if `trader` wants to transfer out `denominationToken` and receive `assetToken`
        /// and false, if they want to transfer out `assetToken` and receive `denominationToken`
        bool isBuy;
        /// @notice the number of tokens of `assetToken` that `trader` is willing to trade
        uint256 quantity;
        /// @notice the number of tokens of `denominationToken` that `trader` wants to trade in exchange
        /// for each token of `assetToken`
        uint256 price;
        /// @notice unix timestamp after which this order can no longer be executed
        /// if set to 0, the order never expires
        uint256 expiration;
        /// @notice must be taken from the ats contract at the time that the order is created
        /// this order can only execute as long as the contract's `blockNonce` value hasn't changed
        uint256 blockNonce;
        uint256 batchId;
        /// @notice can have any value and is meaningless as long as it's different from other orders
        /// this allows a user to submit multiple orders with otherwise identical details
        uint256 salt;
    }

    struct SignedLimitOrder {
        LimitOrder order;
        Signature signature;
    }

    uint256 private constant PRICE_DENOMINATOR = 1e18;

    /// @notice computes whether or not two limit orders should trade with each other, and if so, at what price
    /// this function only compares the orders based on their inherent information, and should not be considered an exhaustive check of order validity
    /// for example, this function does *not* verify an order's signature, or check that it hasnb't been cancelled
    /// @param takerOrder a newly placed order trading against resting orders
    /// @param makerOrder a resting order expected to match with `takerOrder`
    /// @param shareCount the number of shares to trade if these orders match with each other
    /// @dev this may not necessarily be the same as taking the minimum of the two orders' quantities,
    /// because they may have already had some number of shares executed against them, meaning that their
    /// remaining number of shares is lower
    /// @return crosses true if the orders match with each other, false otherwise
    /// @return crossingTotalPrice the total price (measured in `denominationToken`) that should be be paid for this transaction
    function getCrossingTotalPrice(LimitOrder calldata takerOrder, LimitOrder calldata makerOrder, uint256 shareCount)
        public
        pure
        returns (bool crosses, uint256 crossingTotalPrice)
    {
        // orders must have same tokens
        if (
            takerOrder.assetToken != makerOrder.assetToken ||
            takerOrder.denominationToken != makerOrder.denominationToken
        ) {
            return (false, 0);
        }

        // orders must have opposite sides
        if ((takerOrder.isBuy && makerOrder.isBuy) || (!takerOrder.isBuy && !makerOrder.isBuy)) {
            return (false, 0);
        }

        if (takerOrder.isBuy) {
            if (takerOrder.price < makerOrder.price) {
                return (false, 0);
            }
        } else {
            if (takerOrder.price > makerOrder.price) {
                return (false, 0);
            }
        }

        bool valid;
        uint256 takerTotal;
        uint256 makerTotal;
        uint256 midPriceTotal;

        (valid, takerTotal) = takerOrder.price.tryMul(shareCount);
        require(valid, "taker price overflow");

        (valid, makerTotal) = makerOrder.price.tryMul(shareCount);
        require(valid, "maker price overflow");

        (valid, midPriceTotal) = takerTotal.tryAdd(makerTotal);
        require(valid, "total price overflow");

        return (true, midPriceTotal.div(2));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

enum SignatureType {
    SignatureEOA,
    SignatureContract
}

struct EOASignature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

struct Signature {
    SignatureType sigType;
    bytes signatureData;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}