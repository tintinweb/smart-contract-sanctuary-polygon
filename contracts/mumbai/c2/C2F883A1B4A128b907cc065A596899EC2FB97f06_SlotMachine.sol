/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: Zenithia/slot.sol


pragma solidity ^0.8.0;


contract SlotMachine is Ownable{
    uint256 constant public WINNING_PROBABILITY = 50; // 50% winning probability
    mapping(address => uint256) public userDeposits;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public userWinnings;

    event Deposit(address indexed user, uint256 amount);
    event Play(address indexed user, uint256 amount, bool win, uint256 random);
    event Withdraw(address indexed user, uint256 amount);

    function deposit() public payable {
        userDeposits[msg.sender] += msg.value;
        userBalance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() public {
        uint256 payoutAmount = userBalance[msg.sender];
        require(payoutAmount > 0, "No deposited funds to withdraw");

        uint256 contractBalance = address(this).balance;
        uint256 transferAmount = contractBalance >= payoutAmount ? payoutAmount : contractBalance;

        userBalance[msg.sender] -= transferAmount;

        (bool success, ) = msg.sender.call{value: transferAmount}("");
        require(success, "Transfer failed.");
        
        emit Withdraw(msg.sender, payoutAmount);
    }

    function play(uint256 amountToPlay) public {
        require(userBalance[msg.sender] >= amountToPlay, "Insufficient balance amount for this address");

        userBalance[msg.sender] -= amountToPlay;
    
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 100;
        bool win = random < WINNING_PROBABILITY;

        if (win) {
            uint256 payoutAmount = amountToPlay * 2;
            userBalance[msg.sender] += payoutAmount;
            userWinnings[msg.sender] += payoutAmount;
        }

        emit Play(msg.sender, amountToPlay, win, random);
    }

    function collectContractBalance() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No contract balance to claim");

        (bool success, ) = owner().call{value: contractBalance}("");
        require(success, "Transfer failed.");
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        super.transferOwnership(newOwner);
    }

    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }
}