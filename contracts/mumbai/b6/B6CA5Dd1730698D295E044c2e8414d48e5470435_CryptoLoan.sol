// SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

contract CryptoLoan is Ownable {
    // event borrower
    event loanApplied(string email, address userAddress);
    event loanAmountRepaid(string email, uint256 term, uint256 amount);
    event assetReleased(string email, address userAddress);

    //Constants
    address tokenAddress = 0x490cDF9F2Da7080259DfF3E98bB3743765A87a77; // Address of the test ERC20 token (U$DT)
    IERC20 token = IERC20(tokenAddress);

    mapping(string => User) users;
    mapping(address => string) addressToEmail;
    string[] userKeys;
    address[] userAddress;
    Installment[] installments;

    struct User {
        string phone;
        uint256 collateralAmount;
        uint256 loanAmount;
        uint256 startDate;
        uint256 endDate;
        uint256 period;
        uint256 interestRate;
        string remark;
        uint256 initialMarketPrice;
        bool active;
        uint256[] installmentIndexes;
    }

    struct Installment {
        uint256 amount;
        uint256 dueDate;
        uint256 paidDate;
        bool paid;
    }

    // Function to enroll user details
    function addUser(
        string memory email,
        string memory phone,
        uint256 loanAmount,
        uint256 endDate,
        uint256 period,
        uint256 interestRate,
        uint256 currentAssetValue,
        uint256[] memory installmentAmounts,
        uint256[] memory installmentDueDates
    ) public payable {
        // Check if email is already in use
        require(
            bytes(addressToEmail[msg.sender]).length == 0,
            "Address already in use"
        );
        require(users[email].collateralAmount == 0, "Email already in use");
        require(msg.value >= 1 ether, "Please send minimum 1 ETH");

        // Create new user
        User memory user = User({
            phone: phone,
            collateralAmount: msg.value,
            loanAmount: loanAmount,
            startDate: block.timestamp,
            endDate: endDate,
            period: period,
            interestRate: interestRate,
            remark: "Applied",
            initialMarketPrice: currentAssetValue,
            active: true,
            installmentIndexes: new uint256[](0)
        });

        // _transferRelayFee();
        users[email] = user;
        addressToEmail[msg.sender] = email;
        userKeys.push(email);
        userAddress.push(msg.sender);

        require(
            (installmentAmounts.length == installmentDueDates.length),
            "Invalid Payment Schedule Details"
        );
        // Add loan installments
        for (uint256 i = 0; i < installmentAmounts.length; ) {
            uint256 installmentIndex = installments.length;
            Installment memory installment = Installment(
                installmentAmounts[i],
                installmentDueDates[i],
                0,
                false
            );
            installments.push(installment);
            users[email].installmentIndexes.push(installmentIndex);

            unchecked {
                ++i;
            }
        }
        emit loanApplied(email, msg.sender);
    }

    // Function to get user details and installments given their email
    function getUserDetails(
        string memory email
    )
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            string memory,
            bool
        )
    {
        // Check if user exists
        require(
            bytes(users[email].phone).length != 0,
            "User email does not exist"
        );
        require(
            msg.sender == getAddressByEmail(email) || msg.sender == owner(),
            "Not authorized"
        );

        // Retrieve user details
        User storage user = users[email];

        // Return user details and installment information
        return (
            getAddressByEmail(email),
            email,
            user.phone,
            user.collateralAmount,
            user.loanAmount,
            user.initialMarketPrice,
            user.startDate,
            user.endDate,
            user.remark,
            user.active
        );
    }

    // Function to get User Payment schedule
    function getUserPaymentSchedule(
        string memory email
    )
        public
        view
        returns (
            uint256[] memory installmentAmounts,
            uint256[] memory installmentDueDates,
            uint256[] memory installmentPaidDates,
            bool[] memory installmentPaid,
            uint256 unpaidInstallments
        )
    {
        // Check if user exists
        require(
            bytes(users[email].phone).length != 0,
            "User email does not exist"
        );
        require(
            msg.sender == getAddressByEmail(email) || msg.sender == owner(),
            "Not authorized"
        );

        // Retrieve user details
        User storage user = users[email];
        uint256 installmentIndexes = user.installmentIndexes.length;

        // Create arrays to hold installment details
        installmentAmounts = new uint256[](installmentIndexes);
        installmentDueDates = new uint256[](installmentIndexes);
        installmentPaidDates = new uint256[](installmentIndexes);
        installmentPaid = new bool[](installmentIndexes);
        unpaidInstallments = 0; // initialize counter to zero

        // Retrieve installment details for each installment index
        for (uint256 i = 0; i < installmentIndexes; ) {
            Installment storage installment = installments[
                user.installmentIndexes[i]
            ];
            installmentAmounts[i] = installment.amount;
            installmentDueDates[i] = installment.dueDate;
            installmentPaidDates[i] = installment.paidDate;
            installmentPaid[i] = installment.paid;

            if (!installment.paid) {
                unpaidInstallments++; // increment counter if installment is unpaid
            }

            unchecked {
                ++i;
            }
        }
    }

    // Function to edit user details after Loan Approval
    function editUser(
        string memory email,
        uint256 loanAmount,
        uint256 startDate,
        uint256 endDate,
        string memory remark,
        bool active
    ) public onlyOwner {
        // Check if user exists
        // require(bytes(addressToEmail[msg.sender]).length != 0, "User address does not exist");
        require(
            bytes(users[email].phone).length != 0,
            "User email does not exist"
        );
        // Update user details
        users[email].loanAmount = loanAmount;
        users[email].startDate = startDate;
        users[email].endDate = endDate;
        users[email].remark = remark;
        users[email].active = active;
    }

    // Function to edit user details and installments aftrer Loan approval
    function editPaymentSchedule(
        string memory email,
        uint256 index,
        uint256 paidDueDate,
        bool _paid
    ) public onlyOwner {
        // Check if user exists
        require(bytes(users[email].phone).length != 0, "User does not exist");
        // require(msg.sender == getAddressByEmail(email) || msg.sender == owner(), "Not authorized");

        // Retrieve user details
        User storage user = users[email];
        uint256[] storage installmentIndexes = user.installmentIndexes;

        // Retrieve the installment at the specified index
        require(index < installmentIndexes.length, "Invalid index");
        uint256 installmentIndex = installmentIndexes[index];
        Installment storage installment = installments[installmentIndex];

        // _transferRelayFee();
        // Update the due date for the installment
        installment.dueDate = paidDueDate;
        installment.paid = _paid;
    }

    function getAddressByEmail(
        string memory email
    ) private view returns (address) {
        for (uint i = 0; i < userAddress.length; ) {
            if (
                keccak256(bytes(addressToEmail[userAddress[i]])) ==
                keccak256(bytes(email))
            ) {
                return userAddress[i];
            }
            unchecked {
                ++i;
            }
        }
        return address(0);
    }

    function getEmailbyAddress(
        address _userAddress
    ) public view onlyOwner returns (string memory) {
        return addressToEmail[_userAddress];
    }

    function getAddressList() public view onlyOwner returns (address[] memory) {
        return userAddress;
    }

    // Function to check is Connected address is exist
    function isAddressExist(
        address connectedAddress
    ) public view returns (bool) {
        for (uint256 i = 0; i < userAddress.length; ) {
            if (userAddress[i] == connectedAddress) {
                return true; // Address exists
            }
            unchecked {
                ++i;
            }
        }
        return false; // Address doesn't exist
    }

    // Function to Check ETH Balance in the Contract
    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    // Transfer the ETH back to Borrower after successful repayment
    function releaseCollateraltoBorrower(
        string memory email
    ) external onlyOwner {
        User storage user = users[email];
        require(
            bytes(users[email].phone).length != 0,
            "User email does not exist"
        );
        address _userAddress = getAddressByEmail(email);
        // require(users[email].endDate <= block.timestamp, "Loan Period not yet completed");
        require(users[email].active == false, "Loan status still open");
        require(address(this).balance >= 1 ether, "Insufficient balance");
        transferEthtoAddress(payable(getAddressByEmail(email)), 1 ether);
        editUser(email, 0, user.startDate, block.timestamp, "cleared", false);
        emit assetReleased(email, _userAddress);
    }

    // Transfer the ETH to Lender for Liquidation
    function assetLiquidation(string memory email) external onlyOwner {
        User storage user = users[email];
        // require(bytes(addressToEmail[msg.sender]).length != 0, "User address does not exist");
        require(
            bytes(users[email].phone).length != 0,
            "User email does not exist"
        );
        editUser(email, 0, user.startDate, block.timestamp, "default", false);
    }

    // Amount Repayment
    function loanAmountRepayment(
        string memory email,
        uint256 amount,
        uint256 index
    ) private {
        // Check if the caller is either the associated address or contract owner
        require(
            bytes(users[email].phone).length != 0,
            "User email does not exist"
        );
        require(
            bytes(addressToEmail[msg.sender]).length != 0,
            "User address does not exist"
        );
        require(
            msg.sender == getAddressByEmail(email) || msg.sender == owner(),
            "Not authorized"
        );
        depositTokens(amount);
        // editPaymentSchedule(email, index, block.timestamp, true);
        emit loanAmountRepaid(email, index, amount);
    }

    // Function to repay ERC-20 tokens
    function depositTokens(uint256 amount) internal {
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Token allowance not enough");
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");
        // Deposit ERC20 tokens into the contract
    }

    // Transfer the ETH to destination Address
    function transferEthtoAddress(
        address payable recipient,
        uint256 amount
    ) internal onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        recipient.transfer(amount);
    }

    // Function to withdraw ERC20 tokens from the Contract
    function transferTokens(
        address recipient,
        uint256 amount
    ) external onlyOwner {
        token.transfer(recipient, amount);
    }

    // Function to user details, installments, address with email from the Contract
    function removeUserByEmail(string memory email) public onlyOwner {
        address userAddressToRemove = getAddressByEmail(email);
        require(
            bytes(users[email].phone).length != 0,
            "User email does not exist"
        );
        require(
            bytes(addressToEmail[userAddressToRemove]).length != 0,
            "User address does not exist"
        );

        string memory userKey = addressToEmail[userAddressToRemove];
        User storage user = users[userKey];

        // Remove installments associated with the user
        for (uint256 i = 0; i < user.installmentIndexes.length; ) {
            uint256 index = user.installmentIndexes[i];
            delete installments[index];
            unchecked {
                ++i;
            }
        }

        // Clear the user's installmentIndexes array
        delete user.installmentIndexes;

        // Remove user details
        delete users[userKey];
        delete addressToEmail[userAddressToRemove];

        // Remove user key from userKeys array
        for (uint256 i = 0; i < userKeys.length; ) {
            if (
                keccak256(abi.encodePacked(userKeys[i])) ==
                keccak256(abi.encodePacked(userKey))
            ) {
                delete userKeys[i];
                break;
            }
            unchecked {
                ++i;
            }
        }

        // Remove user address from userAddress array
        for (uint256 i = 0; i < userAddress.length; ) {
            if (userAddress[i] == userAddressToRemove) {
                delete userAddress[i];
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    receive() external payable {}

    /// @notice to withdraw fund from the deployed contract to specific address '_to'

    function withdrawFund(address payable _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Fund Transfer failed!");
    }

    /// @notice to execute the Smart Contract

    function contractClosure(address payable _to) public onlyOwner {
        selfdestruct(_to);
    }
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