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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TicketSaleApp is Ownable {
    using Counters for Counters.Counter;

    //Counters.Counter private _ticketCounter;

    uint256 private ticketPrice = 1000000000000000000; //1 CWAR
    uint256 private walletPer = 20;
    uint256 private rewardPer = 75;
    uint256 private tournamentPer = 5;
    uint256 private _ticketCounter = 0;
    bool private saleIsActive = true;

    address payable walletAddress;
    address payable rewardWallet;
    address payable tournamentWallet;

    mapping(address => uint256) private ticketHolders;

    IERC20 public tokenAddress;

    //EVENTS
    event TicketAdded(address _address, uint256 _amount, uint256 time);

    constructor(
        address payable _walletAddress,
        address payable _rewardWallet,
        address payable _tournamentWallet,
        address _tokenAddress
    ) {
        //tokenAddress = IERC20(_tokenAddress);

        walletAddress = _walletAddress;
        rewardWallet = _rewardWallet;
        tournamentWallet = _tournamentWallet;
        tokenAddress = IERC20(_tokenAddress);
    }

    /////////////////////////////
    // CONTRACT ACTIONS
    /////////////////////////////

    function buyTicket(uint256 _amount) public payable returns (uint256){
        uint256 total_cost = ticketPrice * _amount;
        require(saleIsActive, "Sale is not active!!");
        require(tokenAddress.balanceOf(msg.sender) >= total_cost, "CWTEST Amount is not enough!");
        require(tokenAddress.transferFrom(msg.sender, walletAddress, (total_cost * walletPer)/100), "CWTEST couldn't transferred to wallet!");
        require(tokenAddress.transferFrom(msg.sender, rewardWallet, (total_cost * rewardPer)/100), "CWTEST couldn't transferred to reward!");
        require(tokenAddress.transferFrom(msg.sender, tournamentWallet, (total_cost * tournamentPer)/100), "CWTEST couldn't transferred to tournament!");
        
        //require(msg.value >= ticketPrice * _amount, "Amount is not enough!");

        /*
        (bool wa, ) = walletAddress.call{value: (msg.value * walletPer) / 100}(
            ""
        );
        require(wa, "Ethers couldn't transferred to wallet!");
        (bool rw, ) = rewardWallet.call{value: (msg.value * rewardPer) / 100}(
            ""
        );
        require(rw, "Ethers couldn't transferred to reward!");
        (bool tw, ) = tournamentWallet.call{
            value: (msg.value * tournamentPer) / 100
        }("");
        require(tw, "Ethers couldn't transferred to tournament!");
        */

        addTickets(msg.sender, _amount);
        return _amount;
    }

    function addTickets(address _addr, uint256 _amount) internal {
        ticketHolders[_addr] = ticketHolders[_addr] + _amount;
        _ticketCounter = _ticketCounter + _amount;

        emit TicketAdded(_addr, _amount, block.timestamp);
    }

    /////////////////////////////
    // CONTRACT MANAGEMENT
    /////////////////////////////
    function change_wallet(address new_address) public onlyOwner {
        walletAddress = payable(new_address);
    }

    function change_rewardWallet(address new_address) public onlyOwner {
        rewardWallet = payable(new_address);
    }

    function change_tournamentWallet(address new_address) public onlyOwner {
        tournamentWallet = payable(new_address);
    }

    function change_ticketPrice(uint256 new_price) public onlyOwner {
        ticketPrice = new_price;
    }

    function flip_sale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function change_walletPer(uint256 new_per) public onlyOwner {
        walletPer = new_per;
    }

    function change_rewardPer(uint256 new_per) public onlyOwner {
        rewardPer = new_per;
    }

    function change_tournamentPer(uint256 new_per) public onlyOwner {
        tournamentPer = new_per;
    }

    /////////////////////////////
    // CONTRACT READONLY DATA
    /////////////////////////////

    function getTicketNumberByOwner(
        address _addr
    ) external view returns (uint256) {
        return ticketHolders[_addr];
    }

    function getTicketPrice() external view returns (uint256) {
        return ticketPrice;
    }

    function getSoldTicketAmount() external view returns (uint256) {
        return _ticketCounter;
    }

    function getSaleStatu() external view returns (bool) {
        return saleIsActive;
    }
}