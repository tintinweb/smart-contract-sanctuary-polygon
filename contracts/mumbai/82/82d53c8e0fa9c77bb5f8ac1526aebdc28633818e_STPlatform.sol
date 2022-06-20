/**
 *Submitted for verification at polygonscan.com on 2022-06-19
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: contracts/Platform.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;



/// @dev All error codes generated within the contract
error invalidentry();
error ownerOnly();
error incorrectValue();
error notSeller();
error noBalance();

/// @title OTC Trading on Social Trading Platform 
/// @author Ikhlas
/// @dev All function calls are currently implemented without any side effects
/// @custom:experimental - pending security audits - Use with caution
contract STPlatform {
    using Counters for Counters.Counter;

/// @notice Counter for order numbers 
    Counters.Counter public orderNumber;

/// @notice _owner - Owner address
    address public _owner;


/// @notice Orders records with order number, Token Contract,Number of Tokens and Matic
    struct orders {
        uint256 _orderNumber;
        address seller;
        uint256 tokenQuantity;
        address tokenContract;
        uint256 maticAmount;
    }

    mapping(uint256 => orders) public Orders;


/// @notice Events 
    event Log(string _function, address _sender, uint256 _value, bytes _data);
    event Rec(string _function, address _sender, uint256 _value);

/// @notice Constructor 
    constructor() {
        _owner = msg.sender;
    }


/// @notice Creating Orders for Selling
    function createOrder(address _tokenContract, uint256 _tokenQuantity, uint256 _maticAmount) public {

                    (bool success, ) = (_tokenContract).call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender,address(this),_tokenQuantity));
            require(success);

            Orders[orderNumber.current()] = orders(
                orderNumber.current(),
                msg.sender,
                _tokenQuantity,
                _tokenContract,
                _maticAmount
            );
            orderNumber.increment();
    }

/// @notice Trade round - For redeeming orders
    function redeemOrder(uint256 _orderNumber) public payable {
            if (msg.value == 0) revert incorrectValue();
            if (msg.value > Orders[_orderNumber].maticAmount)
                revert incorrectValue();
            uint256 purchaseQuantity = (msg.value *
                (Orders[_orderNumber].tokenQuantity)) /
                (Orders[_orderNumber].maticAmount);
            Orders[_orderNumber].tokenQuantity -= purchaseQuantity;
            Orders[_orderNumber].maticAmount -= msg.value;

                    (bool success, ) = (Orders[_orderNumber].tokenContract).call(abi.encodeWithSignature("transfer(address,uint256)",
                    msg.sender,
                    purchaseQuantity
                )
            );
            require(success);

            payable(Orders[_orderNumber].seller).transfer(msg.value);
    }

/// @notice Trade round - For cancelling orders
    function cancelOrder(uint256 _orderNumber) public {
            if (msg.sender != Orders[_orderNumber].seller) revert notSeller();
                    (bool success, ) = (Orders[_orderNumber].tokenContract).call(
                    abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    msg.sender,
                    Orders[_orderNumber].tokenQuantity
                )
            );
            require(success);

            Orders[_orderNumber].tokenQuantity = 0;
            Orders[_orderNumber].maticAmount = 0;
    }

    fallback() external payable {
        emit Log("fallback message failed", msg.sender, msg.value, msg.data);
    }

    receive() external payable {
        emit Rec("fallback message failed", msg.sender, msg.value);
    }
}