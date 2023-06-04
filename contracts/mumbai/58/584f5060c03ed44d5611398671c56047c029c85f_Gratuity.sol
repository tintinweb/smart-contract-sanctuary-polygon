/**
 *Submitted for verification at polygonscan.com on 2023-06-03
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

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

// File: contracts/Institution.sol

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;



contract Gratuity is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _gratuitiesGiven;

  uint256 totalGratuity;

  address payable public owner;

  constructor() payable {
    owner = payable(msg.sender);
  }

  struct GratuityItem {
    address sender;
    uint256 amount;
    string message;
  }
  GratuityItem[] public gratuityItems;

  event GratuityItemGifted(address sender, uint256 amount, string message);

  function getAllGratuityItems() external view returns (GratuityItem[] memory) {
    return gratuityItems;
  }

  function getTotalGratuity() external view returns (uint256) {
    return totalGratuity;
  }

  function deposit(string calldata _message) public payable {
    require(msg.value > 0, 'You must send Matic');
    totalGratuity += msg.value;
    _gratuitiesGiven.increment();
    gratuityItems.push(GratuityItem({sender: msg.sender, amount: msg.value, message: _message}));
    emit GratuityItemGifted(msg.sender, msg.value, _message);
  }

  // Function to withdraw all Ether from this contract.
  function withdraw() public onlyOwner {
    uint256 amount = address(this).balance;

    (bool success, ) = msg.sender.call{value: amount}('');
    require(success, 'Failed to withdraw Matic');
  }

  // Function to transfer Ether from this contract to address from input
  function transfer(address payable _to, uint256 _amount) public onlyOwner nonReentrant {
    // Note that "to" is declared as payable
    (bool success, ) = _to.call{value: _amount}('');
    require(success, 'Failed to send Ether');
  }

  modifier onlyOwner() {
    require(isOwner(), 'caller is not the owner');
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }
}