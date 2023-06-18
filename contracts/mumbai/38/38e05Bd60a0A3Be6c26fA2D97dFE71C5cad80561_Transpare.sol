/**
 *Submitted for verification at polygonscan.com on 2023-06-17
*/

// File: Transpare/SlotMachine.sol


pragma solidity ^0.8.0;

contract SlotMachine {
    uint256[] symbols = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint256[] valueMultipliers = [11, 12, 13, 14, 20, 25, 30, 50, 70, 100]; // Multiplied by 10 for solidity
    uint256 rows = 3;
    uint256 columns = 5;

    // Event to emit when a new matrix is created
    event NewMatrix(uint256[][] matrix);

    // This function creates a pseudo-random matrix
    function createMatrix() private returns (uint256[][] memory) {
        uint256[][] memory matrix = new uint256[][](rows);
        for (uint256 i = 0; i < rows; i++) {
            matrix[i] = new uint256[](columns);
            for (uint256 j = 0; j < columns; j++) {
                // Note: this is NOT truly random and NOT safe for production use
                uint256 randomSymbol = symbols[
                    (uint256(keccak256(abi.encodePacked(block.timestamp, i, j))) % symbols.length)
                ];
                matrix[i][j] = randomSymbol;
            }
        }

        // Emit the event with the created matrix
        emit NewMatrix(matrix);

        return matrix;
    }

    // This function calculates a multiplier for the given matrix
    function calculateLineMultiplier(uint256[][] memory matrix) private view returns (uint256) {
        uint256 totalLineMultiplier = 0;

        for (uint256 i = 0; i < rows; i++) {
            uint256 startSymbol = matrix[i][0];
            uint256 lineLength = 1;

            for (uint256 j = 1; j < columns; j++) {
                bool columnContainsStartSymbol = false;
                for (uint256 k = 0; k < rows; k++) {
                    if (matrix[k][j] == startSymbol) {
                        columnContainsStartSymbol = true;
                        break;
                    }
                }
                if (columnContainsStartSymbol) {
                    lineLength++;
                } else {
                    break;
                }
            }

            uint256 lineMultiplier = 0;
            if (lineLength == 3) {
                lineMultiplier = 2e16 * valueMultipliers[startSymbol];
            } else if (lineLength == 4) {
                lineMultiplier = 15e16 * valueMultipliers[startSymbol];
            } else if (lineLength == 5) {
                lineMultiplier = 8e17 * valueMultipliers[startSymbol];
            }
            totalLineMultiplier += lineMultiplier;
        }

        return totalLineMultiplier;
    }

    function calculateBoardClearMultiplier(uint256[][] memory matrix) private view returns (uint256) {
        uint256 totalBoardClearMultiplier = 0;

        for (uint256 i = 0; i < symbols.length; i++) {
            uint256 count = 0;
            for (uint256 j = 0; j < matrix.length; j++) {
                for (uint256 k = 0; k < matrix[j].length; k++) {
                    if (matrix[j][k] == symbols[i]) {
                        count++;
                    }
                }
            }
            uint256 boardClearMultiplier = 0;
            if (count == 5) {
                boardClearMultiplier = 2e16 * valueMultipliers[symbols[i]];
            } else if (count == 6) {
                boardClearMultiplier = 1e17 * valueMultipliers[symbols[i]];
            } else if (count == 7) {
                boardClearMultiplier = 25e17 * valueMultipliers[symbols[i]];
            } else if (count == 8) {
                boardClearMultiplier = 1e18 * valueMultipliers[symbols[i]];
            } else if (count == 9) {
                boardClearMultiplier = 25e17 * valueMultipliers[symbols[i]];
            } else if (count == 10) {
                boardClearMultiplier = 5e18 * valueMultipliers[symbols[i]];
            } else if (count == 11) {
                boardClearMultiplier = 1e19 * valueMultipliers[symbols[i]];
            } else if (count == 12) {
                boardClearMultiplier = 25e18 * valueMultipliers[symbols[i]];
            } else if (count == 13) {
                boardClearMultiplier = 5e19 * valueMultipliers[symbols[i]];
            } else if (count == 14) {
                boardClearMultiplier = 25e19 * valueMultipliers[symbols[i]];
            } else if (count == 15) {
                boardClearMultiplier = 1e21 * valueMultipliers[symbols[i]];
            }
            totalBoardClearMultiplier += boardClearMultiplier;
        }

        return totalBoardClearMultiplier;
    }

    // This is the main function that users call to play the game
    function playSlotMachine() external returns (uint256, uint256[][] memory) {
        uint256[][] memory matrix = createMatrix();
        uint256 totalLineMultiplier = calculateLineMultiplier(matrix);
        uint256 totalBoardClearMultiplier = calculateBoardClearMultiplier(matrix);
        uint256 totalMultiplier = totalLineMultiplier + totalBoardClearMultiplier;
        return (totalMultiplier, matrix);
    }
}
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

// File: Transpare/Transpare.sol


pragma solidity ^0.8.0;



contract Transpare is Ownable, SlotMachine {
    SlotMachine public slotMachine; // New state variable

    mapping(address => uint256) public userDeposits;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public userWinnings;

    uint256 public maxBetPercentage; // Maximum bet percentage allowed

    event Deposit(address indexed user, uint256 amount);
    event Play(address indexed user, uint256 userNumber, uint256 random, bool win, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event MaxBetPercentageChanged(uint256 newPercentage);
    event PlaySlotMachine(
        address indexed user,
        uint256[] topRow,
        uint256[] middleRow,
        uint256[] bottomRow,
        uint256 totalMultiplier,
        uint256 amountToPlay,
        uint256 payoutAmount
    );
    
    constructor(address _slotMachine) {
        maxBetPercentage = 1; // Default maximum bet percentage is 1%
        slotMachine = SlotMachine(_slotMachine); // Initialize slotMachine
    }

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

    function play(uint256 amountToPlay, uint256 userNumber) public {
        require(userBalance[msg.sender] >= amountToPlay, "Insufficient balance amount for this address");
        require(userNumber >= 1 && userNumber <= 100, "Number must be between 1 and 100");

        uint256 maxBet = ((address(this).balance * maxBetPercentage) / 100); // Calculate the maximum bet amount
        require(amountToPlay <= maxBet, "Amount exceeds maximum bet limit");

        userBalance[msg.sender] -= amountToPlay;

        bool win = false;
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 101;
        if ((userNumber > 50 && random > 50) || (userNumber <= 50 && random <= 50)) {
            win = true;
        }

        if (win) {
            uint256 payoutAmount = (amountToPlay * 196) / 100;
            userBalance[msg.sender] += payoutAmount;
            userWinnings[msg.sender] += payoutAmount;
        }

        emit Play(msg.sender, userNumber, random, win, amountToPlay);
    }

    function playSlotMachine(uint256 amountToPlay) public {
        require(userBalance[msg.sender] >= amountToPlay, "Insufficient balance for this address");

        uint256 maxBet = ((address(this).balance * maxBetPercentage) / 100); // Calculate the maximum bet amount
        require(amountToPlay <= maxBet, "Amount exceeds maximum bet limit");

        userBalance[msg.sender] -= amountToPlay;

        // Call the SlotMachine contract's play function directly
        (uint256 totalMultiplier, uint256[][] memory matrix) = slotMachine.playSlotMachine();

        // Extract the top, middle, and bottom rows from the matrix
        uint256[] memory topRow = new uint256[](matrix[0].length);
        uint256[] memory middleRow = new uint256[](matrix[0].length);
        uint256[] memory bottomRow = new uint256[](matrix[0].length);

        for (uint256 i = 0; i < matrix[0].length; i++) {
            topRow[i] = matrix[0][i];
            middleRow[i] = matrix[1][i];
            bottomRow[i] = matrix[2][i];
        }

        // Add the winnings to the user's balance
        uint256 payoutAmount = (totalMultiplier * amountToPlay) / 1e18;
        userBalance[msg.sender] += payoutAmount;

        // Emit the new event with the top, middle, and bottom rows as separate parameters
        emit PlaySlotMachine(
            msg.sender,
            topRow,
            middleRow,
            bottomRow,
            totalMultiplier,
            amountToPlay,
            payoutAmount
        );    
    }

    function concatenateRow(uint256[] memory row) internal pure returns (string memory) {
        bytes memory result = new bytes(row.length);
        for (uint256 i = 0; i < row.length; i++) {
            result[i] = bytes1(uint8(row[i] + 48)); // Convert the number to its ASCII representation
        }
        return string(result);
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

    function setMaxBetPercentage(uint256 newMaxBetPercentage) public onlyOwner {
        require(newMaxBetPercentage <= 100, "Invalid percentage value");
        maxBetPercentage = newMaxBetPercentage;
        emit MaxBetPercentageChanged(newMaxBetPercentage);
    }
}