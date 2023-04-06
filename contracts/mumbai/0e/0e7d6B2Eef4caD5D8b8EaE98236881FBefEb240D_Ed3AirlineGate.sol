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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEd3LoyaltyPoints.sol";

contract Ed3AirlineGate is Ownable {
    uint256 public ticketTotalSupply;
    uint256 public ticketPrice;
    uint256 public ticketLeft;
    address payable paymentAddress;
    address public ed3LoyaltyPoints;
    uint256 public immutable POINTS_PER_TICKET;
    uint256 public constant ONE_TICKET = 1;
    mapping(address => uint256) public userTickets;

    constructor(uint256 _ticketPrice, uint256 _totalSupply, address _ed3LoyaltyPoints, uint256 _pointsPerTicket) {
        ticketPrice = _ticketPrice;
        ticketLeft = _totalSupply;
        ed3LoyaltyPoints = _ed3LoyaltyPoints;
        POINTS_PER_TICKET = _pointsPerTicket;
        paymentAddress = payable(msg.sender);
    }

    function mint(address _to) external payable {
        require(msg.value >= ticketPrice, "Insufficient funds");
        require(ticketLeft > ONE_TICKET, "air ticket sold out");
        ticketLeft = ticketLeft - ONE_TICKET;
        userTickets[msg.sender] = userTickets[msg.sender] + ONE_TICKET;
        // 每次购买机票后可以得到 POINTS_PER_TICKET 积分
        IEd3LoyaltyPoints(ed3LoyaltyPoints).mint(_to, POINTS_PER_TICKET);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        payable(paymentAddress).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IEd3LoyaltyPoints {
    function mint(address _to, uint256 _mintTokenNumber) external;
}