import "../interfaces/ITicket.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error INSUFFICIENT_FUNDS();
error TICKETS_MINTED_REACHED_MAX();
error HOME_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
error AWAY_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
error CONTRACT_IS_PAUSED();
error EVENT_HAS_ALREADY_STARTED();


//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


contract ReceiveRefundedTicketFromContract is Ownable, ReentrancyGuard {
event ReceiveRefundedTicket(address To, bool HomeOrAway, uint SeatLevel, uint TokenId, uint Amount);

 address public ticket;
 bool paused;
 uint status = 0;
 uint immutable timeUntilEventStarts;
 constructor(uint _time, address _ticket) {
       timeUntilEventStarts = block.timestamp + _time;
       ticket = _ticket;
}

   modifier onlyWhenNotPaused {
      if(paused == true) {
         revert CONTRACT_IS_PAUSED();
      }
      _;
   }

   modifier balanceUnderThree {
     uint balance = ITicket(ticket).balanceOf(msg.sender);
     if(balance == 2) {
      revert TICKETS_MINTED_REACHED_MAX();
     }
     _;
   }

   modifier onlyIfEventHasntStarted {
      if(block.timestamp > timeUntilEventStarts) {
        revert EVENT_HAS_ALREADY_STARTED();
      }
      _;
   }


   function refundTicketLevelOne(bool _homeOrAway, uint _tokenId) onlyWhenNotPaused onlyIfEventHasntStarted nonReentrant balanceUnderThree external payable {
    if(msg.value != 5 ether) {
      revert INSUFFICIENT_FUNDS();
    }
     if(_homeOrAway == true) {
       if(_tokenId < 1 || _tokenId > 100) {
         revert HOME_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     } else if(_homeOrAway == false) {
       if(_tokenId < 101 || _tokenId > 200) {
         revert AWAY_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     }
      status = 5;
      (bool success, ) = payable(ticket).call{value: 5 ether}("");
      require(success, "Failed to send ether");
      ITicket(ticket).receiveRefundedTicket(msg.sender, _tokenId, _homeOrAway, 1);
      status = 0;
      emit ReceiveRefundedTicket(msg.sender, _homeOrAway, 1, _tokenId, 5 ether);
   }

   function refundTicketLevelTwo(bool _homeOrAway, uint _tokenId) onlyWhenNotPaused onlyIfEventHasntStarted nonReentrant balanceUnderThree external payable {
    if(msg.value != 4 ether) {
      revert INSUFFICIENT_FUNDS();
    }
    if(_homeOrAway == true) {
       if(_tokenId < 201 || _tokenId > 300) {
         revert HOME_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     } else if(_homeOrAway == false) {
       if(_tokenId < 301 || _tokenId > 400) {
         revert AWAY_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     }
      status = 5;
      (bool success, ) = payable(ticket).call{value: 4 ether}("");
      require(success, "Failed to send ether");
      ITicket(ticket).receiveRefundedTicket(msg.sender, _tokenId, _homeOrAway, 2);
      status = 0;
      emit ReceiveRefundedTicket(msg.sender, _homeOrAway, 2, _tokenId, 4 ether);
   }

    function refundTicketLevelThree(bool _homeOrAway, uint _tokenId) onlyWhenNotPaused onlyIfEventHasntStarted nonReentrant balanceUnderThree external payable {
     if(msg.value != 3 ether) {
      revert INSUFFICIENT_FUNDS();
    }
    if(_homeOrAway == true) {
       if(_tokenId < 401 || _tokenId > 500) {
         revert HOME_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     } else if(_homeOrAway == false) {
       if(_tokenId < 501 || _tokenId > 600) {
         revert AWAY_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     }
      status = 5;
      (bool success, ) = payable(ticket).call{value: 3 ether}("");
      require(success, "Failed to send ether");
      ITicket(ticket).receiveRefundedTicket(msg.sender, _tokenId, _homeOrAway, 3);
      status = 0;
      emit ReceiveRefundedTicket(msg.sender, _homeOrAway, 3, _tokenId, 3 ether);
   }

    function refundTicketLevelFour(bool _homeOrAway, uint _tokenId) onlyWhenNotPaused onlyIfEventHasntStarted nonReentrant balanceUnderThree external payable {
    if(msg.value != 2 ether) {
      revert INSUFFICIENT_FUNDS();
    }
    if(_homeOrAway == true) {
       if(_tokenId < 601 || _tokenId > 700) {
         revert HOME_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     } else if(_homeOrAway == false) {
       if(_tokenId < 701 || _tokenId > 800) {
         revert AWAY_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     }
      status = 5;
      (bool success, ) = payable(ticket).call{value: 2 ether}("");
      require(success, "Failed to send ether");
      ITicket(ticket).receiveRefundedTicket(msg.sender, _tokenId, _homeOrAway, 4);
      status = 0;
      emit ReceiveRefundedTicket(msg.sender, _homeOrAway, 4, _tokenId, 2 ether);
   }

    function refundTicketLevelFive(bool _homeOrAway, uint _tokenId) onlyWhenNotPaused onlyIfEventHasntStarted nonReentrant balanceUnderThree external payable {
    if(msg.value != 1 ether) {
      revert INSUFFICIENT_FUNDS();
    }
     if(_homeOrAway == true) {
       if(_tokenId < 801 || _tokenId > 900) {
         revert HOME_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     } else if(_homeOrAway == false) {
       if(_tokenId < 901 || _tokenId > 1000) {
         revert AWAY_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     }
      status = 5;
      (bool success, ) = payable(ticket).call{value: 1 ether}("");
      require(success, "Failed to send ether");
      ITicket(ticket).receiveRefundedTicket(msg.sender, _tokenId, _homeOrAway, 5);
      status = 0;
      emit ReceiveRefundedTicket(msg.sender, _homeOrAway, 5, _tokenId, 1 ether);
   }

    function refundTicketLevelSix(bool _homeOrAway, uint _tokenId) onlyWhenNotPaused onlyIfEventHasntStarted nonReentrant balanceUnderThree external payable {
    if(msg.value != 0.5 ether) {
      revert INSUFFICIENT_FUNDS();
    }
     if(_homeOrAway == true) {
       if(_tokenId < 1001 || _tokenId > 1100) {
         revert HOME_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     } else if(_homeOrAway == false) {
       if(_tokenId < 1101 || _tokenId > 1200) {
         revert AWAY_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     }
      status = 5;
      (bool success, ) = payable(ticket).call{value: 0.5 ether}("");
      require(success, "Failed to send ether");
      ITicket(ticket).receiveRefundedTicket(msg.sender, _tokenId, _homeOrAway, 6);
      status = 0;
      emit ReceiveRefundedTicket(msg.sender, _homeOrAway, 6, _tokenId, 0.5 ether);
   }

    function refundTicketLevelSeven(bool _homeOrAway, uint _tokenId) onlyWhenNotPaused onlyIfEventHasntStarted nonReentrant balanceUnderThree external payable {
    if(msg.value != 0.25 ether) {
      revert INSUFFICIENT_FUNDS();
    }
     if(_homeOrAway == true) {
       if(_tokenId < 1201 || _tokenId > 1300) {
         revert HOME_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     } else if(_homeOrAway == false) {
       if(_tokenId < 1301 || _tokenId > 1400) {
         revert AWAY_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     }
      status = 5;
      (bool success, ) = payable(ticket).call{value: 0.25 ether}("");
      require(success, "Failed to send ether");
      ITicket(ticket).receiveRefundedTicket(msg.sender, _tokenId, _homeOrAway, 7);
      status = 0;
      emit ReceiveRefundedTicket(msg.sender, _homeOrAway, 7, _tokenId, 0.25 ether);
   }

    function refundTicketLevelEight(bool _homeOrAway, uint _tokenId) onlyWhenNotPaused onlyIfEventHasntStarted nonReentrant balanceUnderThree external payable {
    if(msg.value != 0.125 ether) {
      revert INSUFFICIENT_FUNDS();
    }
     if(_homeOrAway == true) {
       if(_tokenId < 1401 || _tokenId > 1500) {
         revert HOME_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     } else if(_homeOrAway == false) {
       if(_tokenId < 1501 || _tokenId > 1600) {
         revert AWAY_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     }
      status = 5;
      (bool success, ) = payable(ticket).call{value: 0.125 ether}("");
      require(success, "Failed to send ether");
      ITicket(ticket).receiveRefundedTicket(msg.sender, _tokenId, _homeOrAway, 8);
      status = 0;
      emit ReceiveRefundedTicket(msg.sender, _homeOrAway, 8, _tokenId, 0.125 ether);
   }

     function refundTicketLevelNine(bool _homeOrAway, uint _tokenId) onlyWhenNotPaused onlyIfEventHasntStarted nonReentrant balanceUnderThree external payable {
     if(msg.value != 0.1 ether) {
      revert INSUFFICIENT_FUNDS();
    }
    if(_homeOrAway == true) {
       if(_tokenId < 1601 || _tokenId > 1700) {
         revert HOME_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     } else if(_homeOrAway == false) {
       if(_tokenId < 1701 || _tokenId > 1800) {
         revert AWAY_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     }
      status = 5;
      (bool success, ) = payable(ticket).call{value: 0.1 ether}("");
      require(success, "Failed to send ether");
      ITicket(ticket).receiveRefundedTicket(msg.sender, _tokenId, _homeOrAway, 9);
      status = 0;
      emit ReceiveRefundedTicket(msg.sender, _homeOrAway, 9, _tokenId, 0.1 ether);
   }

    function refundTicketLevelTen(bool _homeOrAway, uint _tokenId) onlyWhenNotPaused onlyIfEventHasntStarted nonReentrant balanceUnderThree external payable {
    if(msg.value != 0.05 ether) {
      revert INSUFFICIENT_FUNDS();
    }
     if(_homeOrAway == true) {
       if(_tokenId < 1801 || _tokenId > 1900) {
         revert HOME_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     } else if(_homeOrAway == false) {
       if(_tokenId < 1901 || _tokenId > 2000) {
         revert AWAY_TOKEN_ID_FOR_SEAT_LEVEL_OUT_OF_BOUNDS();
       }
     }
      status = 5;
      (bool success, ) = payable(ticket).call{value: 0.05 ether}("");
      require(success, "Failed to send ether");
      ITicket(ticket).receiveRefundedTicket(msg.sender, _tokenId, _homeOrAway, 10);
      status = 0;
      emit ReceiveRefundedTicket(msg.sender, _homeOrAway, 10, _tokenId, 0.05 ether);
   }

   function setPause(bool _value) external onlyOwner {
      paused = _value;
   }

   function areYouAllowedToReceiveTicketFromContract() public view returns(bool) {
     return status == 5;
   }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ITicket {
   function transferTicket(address from, address to, uint256 tokenId, bytes memory data, bool homeOrAway, uint seatLevel) external;
   function refundTicketToContract(address from, uint256 tokenId, bool homeOrAway, uint seatLevel) external; 
   function receiveRefundedTicket(address to, uint256 tokenId, bool homeOrAway, uint seatLevel) external;
   function balanceOf(address owner) external view returns (uint256 balance);
}

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