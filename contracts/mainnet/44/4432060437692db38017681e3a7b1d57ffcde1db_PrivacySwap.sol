/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract PrivacySwap {
    // Store the owner's address for fees
    address public owner = 0x9f751906f858fc881960bc0d71e66478FE6E16E5;

    // Store each deposit in a struct
    struct Deposit {
        uint256 amount;
        address tokenAddress;
        bool withdrawn;
    }

    // Map each deposit to a unique hash
    mapping(bytes32 => Deposit) private deposits;

    // Let users deposit ERC20 tokens
    function deposit(address token, uint256 amount, bytes32 secretHash) external {
        // Transfer the tokens to this contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Record the deposit
        deposits[secretHash] = Deposit(amount, token, false);
    }

    // Let users withdraw their deposit to a different address
    function withdraw(bytes32 secret, address to) external {
        // Calculate the hash of the secret
        bytes32 secretHash = keccak256(abi.encodePacked(secret));

        // Get the deposit
        Deposit storage userDeposit = deposits[secretHash];

        // Ensure the deposit exists and has not been withdrawn
        require(userDeposit.amount > 0 && !userDeposit.withdrawn, "Invalid secret.");

        // Mark the deposit as withdrawn
        userDeposit.withdrawn = true;

        // Calculate the fee and the withdrawal amount
        uint256 fee = userDeposit.amount / 100;
        uint256 amount = userDeposit.amount - fee;

        // Send the fee to the owner
        IERC20(userDeposit.tokenAddress).transfer(owner, fee);

        // Perform the withdrawal
        IERC20(userDeposit.tokenAddress).transfer(to, amount);
    }

    // Let users batch withdraw their deposit to different addresses
    function batchWithdraw(bytes32 secret, address[] memory to, uint256[] memory amounts) external {
        // Calculate the hash of the secret
        bytes32 secretHash = keccak256(abi.encodePacked(secret));

        // Get the deposit
        Deposit storage userDeposit = deposits[secretHash];

        // Ensure the deposit exists and has not been withdrawn
        require(userDeposit.amount > 0 && !userDeposit.withdrawn, "Invalid secret.");
        require(to.length == amounts.length, "Mismatched inputs.");
        uint256 total = 0;
        for (uint i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        require(total == userDeposit.amount, "Mismatched amounts.");

        // Mark the deposit as withdrawn
        userDeposit.withdrawn = true;

        // Calculate the fee
        uint256 fee = userDeposit.amount / 100;

        // Send the fee to the owner
        IERC20(userDeposit.tokenAddress).transfer(owner, fee);

        // Perform the batch withdrawal
        for (uint i = 0; i < to.length; i++) {
            uint256 withdrawAmount = amounts[i] - (amounts[i]/100);
            IERC20(userDeposit.tokenAddress).transfer(to[i], withdrawAmount);
        }
    }
}