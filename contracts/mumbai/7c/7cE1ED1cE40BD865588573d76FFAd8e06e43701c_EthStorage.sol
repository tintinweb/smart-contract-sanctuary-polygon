// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract EthStorage {
    event Deposit(address indexed user, uint256 amount);
    event UserWithdrawal(address indexed user, uint256 amount);
    event AdminFeeWithdrawn(address indexed admin, uint256 amount);

    address payable public admin;
    bool public adminFeeWithdrawn = false;
    uint256 public feePercentage = 10; // Fee percentage is  10 means 10%
    mapping(address => uint256) public balances;

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Only the contract owner can call this function."
        );
        _;
    }

    modifier onlyUser() {
        require(
            msg.sender != address(0),
            "Only a valid user can call this function."
        );
        _;
    }

    constructor() {
        admin = payable(msg.sender);
    }

    function deposit() external payable onlyUser {
        require(msg.value > 0, "Deposit amount must be greater than 0.");

        uint256 fee = (msg.value * feePercentage) / 100;

        uint256 userBalanceBefore = balances[msg.sender];

        uint256 userBalance = msg.value - fee;
        balances[msg.sender] += userBalance;

        uint256 userBalanceAfter = balances[msg.sender];

        emit Deposit(msg.sender, userBalance);

        require(
            userBalanceAfter > userBalanceBefore,
            "User balance update failed"
        );

        if (fee > 0) {
            uint256 adminBalanceBefore = address(admin).balance;

            payable(admin).transfer(fee);

            uint256 adminBalanceAfter = address(admin).balance;

            require(
                adminBalanceAfter > adminBalanceBefore,
                "Fee transfer to admin failed"
            );

            emit AdminFeeWithdrawn(admin, fee);
        }
    }

    function withdrawAmount(uint256 requiredAmount) external {
        require(
            requiredAmount > 0,
            "Required amount must be greater than zero"
        );

        uint256 userBalance = balances[msg.sender];

        require(
            userBalance >= requiredAmount,
            "Insufficient balance for withdrawal"
        );

        uint256 fee = (requiredAmount * feePercentage) / 100;

        uint256 userAmountAfterFee = requiredAmount - fee;

        balances[msg.sender] -= requiredAmount;

        payable(msg.sender).transfer(userAmountAfterFee);

        emit UserWithdrawal(msg.sender, userAmountAfterFee);
    }

    function withdrawAdminFee() external onlyAdmin {
        require(msg.sender == admin, "Only the admin can withdraw the fee");

        uint256 adminBalanceBefore = address(this).balance;

        uint256 fee = 0.01 ether;
        if (feePercentage > 0) {
            fee = (adminBalanceBefore * feePercentage) / 1000;
        }

        require(fee > 0, "No fee available for withdrawal");

        payable(admin).transfer(fee);
        require(!adminFeeWithdrawn, "Fee already withdrawn by admin");

        adminFeeWithdrawn = true;

        uint256 adminBalanceAfter = address(this).balance;

        require(
            adminBalanceAfter == adminBalanceBefore - fee,
            "Admin balance update failed"
        );
        emit AdminFeeWithdrawn(admin, fee);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getAdminBalance() external view returns (uint256) {
        return address(admin).balance;
    }

    function getUserBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }

    function updateFeePercentage(uint256 newFee) external onlyAdmin {
        feePercentage = newFee;
    }
}