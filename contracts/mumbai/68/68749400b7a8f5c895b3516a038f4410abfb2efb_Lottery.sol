/**
 *Submitted for verification at polygonscan.com on 2023-06-21
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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: contracts/Lottery.sol


pragma solidity ^0.8.0;


contract Lottery is Ownable {
    uint public ticketPrice;
    bytes32 public commitment;
    uint[] public winningNumbers;
    
    mapping(address => bytes32) public ticketHashes;
    mapping(address => uint[]) public tickets;
    
    event TicketPurchased(address indexed player, bytes32 hash);
    event WinnerSelected(uint[] winningNumbers);
    
    constructor() {
        ticketPrice = 1 ether; // Set the ticket price in Ether
    }
    
    function purchaseTicket(bytes32 hash) public payable {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        
        ticketHashes[msg.sender] = hash;
        emit TicketPurchased(msg.sender, hash);
    }
    
    function revealTicket(uint[] memory numbers) public {
        require(keccak256(abi.encodePacked(numbers)) == ticketHashes[msg.sender], "Invalid ticket hash");
        require(validateNumbers(numbers), "Invalid ticket numbers");
        
        tickets[msg.sender] = numbers;
    }
    
    function selectWinningNumbers() public onlyOwner {
        require(commitment != bytes32(0), "No commitment made");
        require(winningNumbers.length == 0, "Winning numbers already selected");
        
        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), commitment)));
        uint[] memory numbers = generateWinningNumbers(seed);
        winningNumbers = numbers;
        
        emit WinnerSelected(numbers);
    }
    
    function claimPrize() public {
        require(checkWinningNumbers(msg.sender), "No winning ticket found");
        
        uint prizeAmount = address(this).balance;
        require(prizeAmount > 0, "No prize funds available");
        
        // Distribute the prize to the winner
        payable(msg.sender).transfer(prizeAmount);
    }
    
    function commitNumbers(bytes32 hash) public onlyOwner {
        commitment = hash;
    }
    
    function revealNumbers(uint256[] memory numbers) public onlyOwner {
        require(keccak256(abi.encodePacked(numbers)) == commitment, "Invalid commitment");
        require(validateNumbers(numbers), "Invalid numbers");
        
        winningNumbers = numbers;
        
        emit WinnerSelected(numbers);
    }
    
    function checkWinningNumbers(address player) public view returns (bool) {
        uint[] memory playerNumbers = tickets[player];
        
        if (playerNumbers.length != 6) {
            return false;
        }
        
        for (uint i = 0; i < playerNumbers.length; i++) {
            if (playerNumbers[i] != winningNumbers[i]) {
                return false;
            }
        }
        
        return true;
    }
    
    function validateNumbers(uint[] memory numbers) internal pure returns (bool) {
        // Implement additional number validation logic if necessary
        return true;
    }
    
    function generateWinningNumbers(uint256 seed) internal pure returns (uint[] memory) {
        uint[] memory numbers = new uint[](6);
        
        // Generate the winning numbers based on the seed and any specific logic you require
        // Example: Assign the first 6 digits of the seed as the winning numbers
        for (uint i = 0; i < 6; i++) {
            numbers[i] = uint8(seed >> (i * 8));
        }
        
        return numbers;
    }

    // Additional functions for managing the contract can be implemented here
}