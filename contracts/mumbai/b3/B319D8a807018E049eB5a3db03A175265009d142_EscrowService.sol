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
pragma solidity >=0.8.0;
 
import "@openzeppelin/contracts/access/Ownable.sol";

interface Token {
    function decimals() external view returns (uint8);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external;
}

contract EscrowService is Ownable{

    uint8 public PLATFORM_FEE_RATE = 25 ; // platform fee rate is 25%
    uint256 public MAX_FEE = 25;
    
    enum EscrowState {
        OFFERED,
        AWAITING_DELIVERY,
        COMPLETE
    }

    struct Escrow {
        string name;
        address crypto;
        uint256 amount;
        address seller;
        address buyer;
        bool exists;
        EscrowState state;
    }

    mapping(address => uint256) public escrowBalances; //balances from each buyer/seller and escrow account

    mapping(string => Escrow) public stock; // whole stock of offered escrows for sell in escrow arragement

    constructor() {}


    //@dev: buyer funds are transfered to escrow account
    function credit(address _crypto, address _buyer, uint256 _amount) public onlyOwner {
        require(_crypto != address(0));
        require(Token(_crypto).allowance(_buyer, address(this)) >= _amount, "Crypto not allowed to transferFrom this buyer");

        Token(_crypto).transferFrom(_buyer, address(this), _amount);

        escrowBalances[_buyer] = escrowBalances[_buyer] + _amount;
        escrowBalances[address(this)] = escrowBalances[address(this)] + _amount;
    }

    // helper function
    function checkEscrowBalance (address buyer) public view returns (uint256) {
        return escrowBalances[buyer];
    }

    // helper function
    function getEscrow(string memory _escrowName) public view returns (Escrow memory) {
        return stock[_escrowName];
    }

    // @dev: buyer places order to buy crypto.
    // Escrow is marked as state AWAITING_DELIVERY
    // Escrow internal balance for buyer and seller is updated
    // @params: buyer address and name of the escrow to buy
    function order (address _buyer, string memory _escrowName) public onlyOwner {
        require(stock[_escrowName].exists, "Escrow does not exists");
        require(escrowBalances[_buyer] >= stock[_escrowName].amount, "Buyer has no sufficient funds");

        address seller = stock[_escrowName].seller;
        escrowBalances[_buyer] = escrowBalances[_buyer] - stock[_escrowName].amount;
        escrowBalances[seller] = escrowBalances[seller] + stock[_escrowName].amount;
        stock[_escrowName].state = EscrowState.AWAITING_DELIVERY;
    }

    // @dev: seller puts escrow for sale.
    // Escrow is markes as state OFFERED
    // Escrow is added to escrow stock mapping
    // @params: seller address and name of the escrow, amount and quantities to put for sale
    function offer (address _crypto, address _seller, string memory _escrowName, uint256 _escrowAmount) public {
        require(Token(_crypto).allowance(_seller, address(this)) >= _escrowAmount, "Crypto not allowed to transferFrom this buyer");

        Escrow memory escrow;
        escrow.crypto = _crypto;
        escrow.name = _escrowName;
        escrow.amount = _escrowAmount;
        escrow.seller = _seller;
        escrow.exists = true;
        escrow.state = EscrowState.OFFERED;

        Token(_crypto).transferFrom(_seller, address(this), _escrowAmount);

        stock[_escrowName] = escrow;
    }

    // @dev: buyer confirms reception of escrow
    // payment is transfered from escrow account to seller account
    // Escrow is marked as state COMPLETE
    // Escrow balance is decremented in escrow internal balance
    // @params: buyer address and name of the escrow to buy
    function complete (address _buyer, string memory _escrowName) public onlyOwner {
        address seller = stock[_escrowName].seller;
        stock[_escrowName].buyer = _buyer;
        stock[_escrowName].state = EscrowState.COMPLETE;

        uint256 amount = stock[_escrowName].amount;
        uint256 fee = PLATFORM_FEE_RATE * amount / 100;
        
        Token(stock[_escrowName].crypto).transfer(_buyer, amount-fee);

        escrowBalances[address(this)] = escrowBalances[address(this)] - stock[_escrowName].amount;
        escrowBalances[seller] = escrowBalances[seller] + stock[_escrowName].amount;
    }

    // @dev: buyer didn't receive escrow
    // Escrow internal balance for buyer and seller is updated
    // Escrow is reverted back to state OFFERED
    // @params: buyer address and name of the escrow to buy
    function complain (address _buyer, string memory _escrowName) public onlyOwner {        
        address seller = stock[_escrowName].seller;
        stock[_escrowName].buyer = address(0);
        stock[_escrowName].state = EscrowState.OFFERED;
        escrowBalances[_buyer] = escrowBalances[_buyer] + stock[_escrowName].amount;
        escrowBalances[seller] = escrowBalances[seller] - stock[_escrowName].amount; 
    }

}