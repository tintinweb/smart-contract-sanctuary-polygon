/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: stakesmartcontract.sol

pragma solidity ^0.8.8;



  contract Stake {
    // Mapping to store transfer details by user wallet address and transfer counter
    mapping(address => mapping(uint => TransferDetails)) public transferHistory;

    // Mapping to store affiliate count by affiliate address
    mapping(address => uint) public affiliateCount;

    // Mapping to track if a user has used a specific affiliate address
    mapping(address => mapping(address => bool)) public userHasUsedAffiliate;
    address payable public recipient;

    constructor(address payable _recipient) {
        recipient = _recipient;
    }

    // Struct to store transfer details
    struct TransferDetails {
        uint inrValue;
        uint amount;
        uint recipientAmount;
        uint contractAmount;
        uint affiliateAmount;
        address affiliateAddress;
        uint timestamp;
        uint withdrawnAmount;
        uint withdrawTimestamp;
        uint tokenPrice;
    }

    // Declare a counter variable
    mapping(address => uint) transferCounter;

    function getAllTransferHistory(address userAddress) external view returns (TransferDetails[] memory) {
        uint totalTransfers = transferCounter[userAddress];
        uint validTransferCount = 0;

        // Calculate the number of valid transfers (transfers with non-zero amounts)
        for (uint i = 1; i <= totalTransfers; i++) {
            TransferDetails storage transferInfo = transferHistory[userAddress][i];
            if (transferInfo.recipientAmount > 0 || transferInfo.contractAmount > 0) {
                validTransferCount++;
            }
        }

        TransferDetails[] memory allTransfers = new TransferDetails[](validTransferCount);
        uint currentValidTransferIndex = 0;

        // Store the valid transfers in the result array
        for (uint i = 1; i <= totalTransfers; i++) {
            TransferDetails storage transferInfo = transferHistory[userAddress][i];
            if (transferInfo.recipientAmount > 0 || transferInfo.contractAmount > 0) {
                allTransfers[currentValidTransferIndex] = transferInfo;
                currentValidTransferIndex++;
            }
        }

        return allTransfers;
    }

    // Function to convert uint to string
    function uint2str(uint number) internal pure returns (string memory) {
        if (number == 0) {
            return "0";
        }
        uint length = 0;
        uint temp = number;

        while (temp > 0) {
            length++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(length);

        while (number > 0) {
            length--;
            buffer[length] = bytes1(uint8(48 + number % 10));
            number /= 10;
        }
        return string(buffer);
    }

    function transfer(IERC20 token, address payable affiliate, uint amount, uint tokenPrice) external payable {
        // Calculate the amounts to send
        uint recipientAmount;
        uint contractAmount;
        uint affiliateAmount;

        uint inrValue = amount * tokenPrice;

        // Get the user's transfer counter
        uint userTransferCounter = transferCounter[msg.sender];

        if (affiliate == address(0)) {
            recipientAmount = amount * 85 / 100;
            contractAmount = amount - recipientAmount;
        } else {
            recipientAmount = amount * 75 / 100;
            contractAmount = amount * 15 / 100;
            affiliateAmount = amount * 10 / 100;

            // Increase affiliate count if the user has not used the affiliate address before
            if (!userHasUsedAffiliate[msg.sender][affiliate]) {
                affiliateCount[affiliate]++;
                userHasUsedAffiliate[msg.sender][affiliate] = true;
            }
        }

        // Only store the transfer details if recipientAmount or contractAmount is non-zero
        if (recipientAmount > 0 || contractAmount > 0) {
            // Increment the user's transfer counter
            userTransferCounter++;

            // Update the user's transfer counter
            transferCounter[msg.sender] = userTransferCounter;

            // Generate a unique transfer identifier only if recipientAmount or contractAmount is non-zero
            TransferDetails storage transferInfo = transferHistory[msg.sender][userTransferCounter];
            transferInfo.amount = amount;
            transferInfo.recipientAmount = recipientAmount;
            transferInfo.contractAmount = contractAmount;
            transferInfo.affiliateAmount = affiliateAmount;
            transferInfo.affiliateAddress = affiliate;
            transferInfo.timestamp = block.timestamp;
            transferInfo.tokenPrice = tokenPrice;
            transferInfo.inrValue = inrValue;

            // Approve the transfer from the sender
            IERC20(token).approve(msg.sender, amount);

            // Transfer the amounts
            if (recipientAmount > 0) {
                IERC20(token).transferFrom(msg.sender, recipient, recipientAmount);
            }
            if (contractAmount > 0) {
                IERC20(token).transferFrom(msg.sender, address(this), contractAmount);
            }
            // Send the affiliate amount if applicable
            if (affiliateAmount > 0) {
                IERC20(token).transferFrom(msg.sender, affiliate, affiliateAmount);
            }
        }
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    // Function to withdraw a specific transfer amount by transferId
    function withdraw(uint256 transferId, uint tokenPrice) external {
    TransferDetails storage transferInfo = transferHistory[msg.sender][transferId];
    uint256 withdrawalTimestamp = transferInfo.withdrawTimestamp;
    uint256 updatedWithdrawTimestamp;
    uint256 remainingAmount;
    uint256 affiliateShare;

    // Check if this is the first withdrawal or subsequent withdrawal
    if (withdrawalTimestamp == 0) {
        require(block.timestamp >= transferInfo.timestamp + 600, "Waiting period not over");
        updatedWithdrawTimestamp = block.timestamp;
    } else {
        require(block.timestamp >= withdrawalTimestamp + 600, "Waiting period not over");
        updatedWithdrawTimestamp = block.timestamp;
    }

    require(transferInfo.inrValue > 0, "Transfer not found");
    require(transferInfo.recipientAmount > 0, "Transfer not completed");

    // Determine the daily withdrawal limit based on the affiliateCount
    if (affiliateCount[msg.sender] >= 9) {
        remainingAmount = (transferInfo.inrValue * 5) / 100; // 5% as monthly withdraw limit
    } else if (affiliateCount[msg.sender] >= 6) {
        remainingAmount = (transferInfo.inrValue * 4) / 100; // 4% as monthly withdraw limit
    } else if (affiliateCount[msg.sender] >= 3) {
        remainingAmount = (transferInfo.inrValue * 3) / 100; // 3% as monthly withdraw limit
    } else {
        remainingAmount = (transferInfo.inrValue * 2) / 100; // 1% as monthly withdraw limit
    }

    // Calculate the minutes passed since the transfer or last withdrawal
    uint256 minutesPassed;
    if (withdrawalTimestamp == 0) {
        minutesPassed = (block.timestamp - transferInfo.timestamp) / 600;
    } else {
        minutesPassed = (block.timestamp - withdrawalTimestamp) / 600;
    }

    // Adjust the remaining amount based on minutes passed
    remainingAmount = (remainingAmount / tokenPrice) * minutesPassed;

    // Ensure the user has not already withdrawn the amount
    if (transferInfo.withdrawnAmount + remainingAmount < transferInfo.amount * 2) {
        remainingAmount = remainingAmount;
    } else if (transferInfo.withdrawnAmount + remainingAmount >= transferInfo.amount * 2) {
        remainingAmount = transferInfo.amount * 2 - transferInfo.withdrawnAmount;
    }

    // Calculate the affiliate share
    affiliateShare = remainingAmount * 10 / 100;

    // Transfer the remaining amount to the user's wallet within the smart contract
    IERC20(0x67fFdCD10770223C0E762b44aC674b5782A689c6).transfer(msg.sender, remainingAmount);

    // Transfer the affiliate share to the affiliate address if applicable
    if (transferInfo.affiliateAddress != address(0) && affiliateShare > 0) {
        IERC20(0x67fFdCD10770223C0E762b44aC674b5782A689c6).transfer(transferInfo.affiliateAddress, affiliateShare);
    }

    // Update the withdrawn amount and withdrawal timestamp
    transferInfo.withdrawnAmount += remainingAmount;
    transferInfo.withdrawTimestamp = updatedWithdrawTimestamp;
}

}