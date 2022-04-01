// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

/**
 * @title Panacea
 * @dev Contract for Panacea.
 */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import './SignatureUtils.sol';
import "./VerifySignature.sol";
import "./DateUtils.sol";

contract Panacea {
  // Name of the Contract
  string public name = "Panacea";

  // Owner of the Contract
  address public owner;

  // Address of the USDT contract
  IERC20 public usdtToken;

  // Address of the Deposit Address
  address private depositAddress;

  // Incrementatl ID
  uint256 private currentId = 0; //health ID that will automatically be assigned
  
	// Contract Limits
	uint256 private accountLimitAmount = 5; // month index used for storing the proper month that must be paid
  uint256 private minimumMonthlyPaymentAmount = 375000000;
	bool private contractStatus = true;

	// Contract Rules
	mapping(uint256 => uint256) private tierPaymentsToReceive; // number of months that the contract must be paid to receive payouts

  // Total Amounts Processed by Contract
  uint256 private totalDepositAmount = 0;
  uint256 private totalPayoutAmount = 0;

  // Addreses Associated with the Contract
  address[] private associatedAddresses;

  //// Mappings
  // Mapping of Addresses and whether they are Admins
  mapping(address => bool) private isAdmin;
  // Mapping of Addresses and whetehr they are Users
  mapping(address => bool) private isUser;
  // Mapping of Addresses and their associated Accounts
  mapping(address => mapping(uint256 => Account)) private accounts;
  // Mapping of Addresses and their associated User Account
  // mapping(address => UserAccount) private userAccounts;
  // Mapping of Addresses and their associated Payouts
  mapping(address => Payout[]) private userPayouts;
  // Mapping of Addresses and their Associated Account Type Payouts
  mapping(address => mapping(uint256 => Payout[])) private userAccountTypePayouts;
  // Mapping of Addresses and their associated Deposits
  mapping(address => Deposit[]) private userDeposits;
  // Mapping of Addresses and their Total Payed Amount
  mapping(address => uint256) private userTotalPayedAmount;
  // Mapping of Addresses and their Total Deposit Amount
  mapping(address => uint256) private userTotalDepositAmount;
  // Mapping of Addresses and their Monthly Payout Amount
  mapping(address => uint256) private userMonthlyPayoutAmount;
  // Mapping of Addresses and their Total Payed Amount for Account Type
  mapping(address => mapping(uint256 => uint256)) private userTotalPayedAmountForAccountType;
  // Mapping of Addresses and their Total Deposit Amount for Account Type
  mapping(address => mapping(uint256 => uint256)) private userTotalDepositAmountForAccountType;
  // Mapping of Addresses that have been Blacklisted
  mapping(address => bool) private blacklist;
  // Tiers and Associated Payout Lengths
  mapping(uint256 => uint256) private tierLengths;
  // Account Type Tiers
  mapping(uint256 => uint256) private accountTiers;
  // Mapping of Pay Indexes for each Account
  // mapping(uint256 => uint256) private payIndex;
  // Mapping of NOnces for each account
  // @security - Update functions to use this Nonce
  // mapping(address => uint256) private nonceOfAccount;

  // Constants
  uint256 private randomSeed = 133711142;
  //// Structs
  // User Account
  // Used to Store User Information
  // @security - Store the Nonce in the User. When we create the nonce we we store it in the user as a private variable.
  // struct UserAccount {
  //   bool loggedIn;
  //   uint256 nonce;
  // }

  // Account
  // Used to store information about a particular account type
  // Account Types:
  // 0. Health Account
  // 1. Auto Account
  // 2. Debt Account
  // 3. Tuition Account
  // 4. Home Account
  // 5. Retirement Account
  struct Account {
    uint256 id; // Unique ID for the Account
    uint256 accountType; // Type of Account
    uint256 monthlyPremium; // Monthly Premium
    uint256 signupDate; // Date of Signup
    bool exists; // Whether the Account Exists
    address payoutAddress; // Address to send the Payout to
    uint256 payIndex; // Pay Index
    uint256 paidTotal; // Total Amount Paid
    bool principalPaid; // Whether the Principal has been Paid
    uint256 depositAmount; // Amount of Deposit
    uint256 tier; // Tier of the Account Type
    uint256 payoutsLeft; // Number of Payouts Left
    uint256 fundedTotal; // Number of 
  }

  // Payout
  // Used to Store Payout Information
  struct Payout {
    uint256 id;
    uint256 accountId;
    uint256 amount;
    uint256 status; // Stored as a UInt for memory purposes
    address payedTo;
    uint256 timestamp;
    uint256 payIndex;
    uint256 fundAmount;
  }

  // Deposit
  // Used to Store Deposit Information
  struct Deposit {
    uint256 id;
    uint256 accountId;
    uint256 amount;
    uint256 status;
    address payedFrom;
    uint256 timestamp;
  }

  // Checks to make sure msg.sender is the owner of the contract.
  modifier isOwner() {
    require(msg.sender == owner, "Caller is not owner");
    _;
  }

  // Checks to make sure msg.sender is an admin on the contract.
  modifier isAdminUser() {
    require(isAdmin[msg.sender] == true, "Must be an admin User");
    _;
  }

  // Checks to make sure the Contract Status is Active
  modifier isActiveContract() {
    require(contractStatus == true, "Contract is not Active");
    _;
  }

  // Checks to make sure sender is not blacklisted
  modifier isNotBlacklisted() {
    require(blacklist[msg.sender] == false, "Must not be blacklisted");
    _;
  }

  // Check to make sure they dont already have an account of a specific type.
  modifier hasNoAccountType(uint256 accountType) {
    // Check if a user exists for an address
    require(accounts[msg.sender][accountType].exists == false, "Must have no Account type");
    _;
  }
  
  // Called when Contract is deployed
  event ContractCreated();
  // Called when a new Owner is Set
  event OwnerSet(address indexed oldOwner, address indexed newOwner);
  // Called when a new Account is created
  event AccountCreated(uint256 indexed id, address indexed owner, uint256 accountType);
  // Called when a deposit is made
  event DepositCreated(address indexed owner, uint256 amount, uint256 indexed accountType);
  // Called when a Payout has been created
  event PayoutCreated(address indexed owner, uint256 amount, uint256 indexed accountType);
  // Called when a User has been blacklisted
  event BlackListedUser(address indexed owner);

  // Initalized Contract
  // @dev Initalizes the contract
  // @param _usdtToken Address of the USDT Contract
  // @param _depositAddress Address of the Deposit Address to send funds to
  // @security - This is only time we set the deposit address
  constructor() {
    owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    isAdmin[msg.sender] = true;
    isUser[msg.sender] = true;
    usdtToken = IERC20(msg.sender);
    depositAddress = msg.sender;
    associatedAddresses = [msg.sender];
    emit OwnerSet(address(0), owner);
    emit ContractCreated();
    // Set Tier Length of the Contracts
    tierLengths[1] = 72;
    tierLengths[2] = 360;
    // Set the Tier Types for Account Types
    accountTiers[0] = 2;
    accountTiers[1] = 1;
    accountTiers[2] = 1;
    accountTiers[3] = 1;
    accountTiers[4] = 2;
    accountTiers[5] = 2;
    // Set the Tier Payments to Receive
    tierPaymentsToReceive[1] = 14;
    tierPaymentsToReceive[2] = 16;
  }

  // Verify Signature
  // @dev Verifies the signature of a message
  // @security - Add Message Hash on Backend and make sure they match from Frontend
  // function verifySignature(bytes32 messageHash, bytes memory signature)
  //   private
  //   view
  //   isNotBlacklisted
  //   returns (bool)
  // {
  //   require(
  //     // Check if the address is a valid address
  //     msg.sender == SignatureUtils.recoverAddress(messageHash, signature, 0),
  //     'Signature is not valid'
  //   );
  //   return true;
  // }

  // Add Associated Address
  // @dev Adds an address to the associated addresses
  // @param associatedAddress Address to add to the associated addresses
  // @security - done - No security issue but modify to only be unique
  function addAssociatedAddress(address associatedAddress) private {
    // Check whether the address is already associated and does not equal 0x0
    if (associatedAddress != address(0) && isUser[associatedAddress] == false) {
      associatedAddresses.push(associatedAddress);
    }
  }

  // Transfer Function
  // Create a SafeERC20 Transfer to the USDT Contract Address
  // Then Emits an Event To Say the Deposit was Created
  // @param from The Address of the User
  // @param amount The Amount of USDT to Deposit
  // @param accountType The Type of Account to Deposit to
  // @security - Private function should be ok.
  function transferFromUserToContract(
    address from,
    uint256 amount,
    uint256 accountType
  ) private returns (bool success) {
    // usdtToken.approve(address(this), amount);
    usdtToken.transferFrom(msg.sender, depositAddress, amount);
    // Create a New Deposit and Push it into the User's Deposit Array
    userDeposits[from].push(
      Deposit(currentId, accountType, amount, 1, msg.sender, block.timestamp)
    );
    currentId++;
    emit DepositCreated(from, amount, accountType);
    return true;
  }

  // Create Account
  // @dev Create a new account for a user
  // @param yearlyAmount Amount of the Account for one year
  // @param accountType The Type of Account to Create
  // @param messageHash The Signature of the Message to check
  // @param signature The Signature of the User
  // @security - done - Change so only the signature is being passed in. Then make sure the message hash is generated on the backend. Check with mark on the lower limit of account creation.
  // @signatureMessage - "You are signing this message to create an account with the following nonce: " + nonce
  function createAccount(
    uint256 totalAmount,
    uint256 accountType,
    bytes memory signature
  ) public hasNoAccountType(accountType) isActiveContract {
    // Check that the Value is Greater than 0
    // require(totalAmount > 0, "Must have a value greater than 0");
    // Check if the Account Type is Valid
    require(accountType <= accountLimitAmount && accountType >= 0, "must be between 0 and limit");
    // Add Account to User's Account Array
    uint256 tier = accountTiers[accountType];
    uint256 tierLength = tierLengths[tier];
    // Calculate Monthly Amount for Payout
    uint256 monthlyAmount = totalAmount / tierPaymentsToReceive[tier];
    // Check if the User has the Minimum Monthly Payment
    require(monthlyAmount >= minimumMonthlyPaymentAmount, "Needs higher monthly payment");
    // Get the User Nonce from the User
    uint256 userNonce = getNonce(accountType);
		// Block Time
		uint256 blockTime = block.timestamp;
    // Concatenate the message and the nonce
    string
      memory message = "You are signing this message to create an account with the following nonce: ";
    string memory messageWithNonce = string(abi.encodePacked(message, uint2str(userNonce)));
    // Check if the Signature is Valid
    require(
      VerifySignature.verify(msg.sender, messageWithNonce, signature),
      "Signature is not valid"
    );
    // Transfer from User to Contract
    bool transfer = transferFromUserToContract(msg.sender, totalAmount, accountType);
    require(transfer, "Failed to transfer funds");
    // Calculate the Next Month Pay Index
    uint256 twoMonthTimeStamp = DateUtils.addMonths(blockTime, 2);
    uint256 payIndex = DateUtils.getMonth(twoMonthTimeStamp);
    // If Account PayIndex == 0 then set the payIndex to 1 for January
    if (payIndex == 0) {
      payIndex = 1;
    }
    accounts[msg.sender][accountType] = Account(
      currentId,
      accountType,
      monthlyAmount,
      blockTime,
      true,
      msg.sender,
      payIndex,
			0,
			false,
      totalAmount,
      tier,
      tierLength,
      0
    );
    // Emit Account Created Event
    emit AccountCreated(currentId, msg.sender, accountType);
    // Add the msg.sender address as an associated address
    addAssociatedAddress(msg.sender);
    // Update the Total Deposited for the User
    userTotalDepositAmount[msg.sender] = userTotalDepositAmount[msg.sender] + totalAmount;
    // Update the Total Deposited for the Account Type
    userTotalDepositAmountForAccountType[msg.sender][accountType] = totalAmount;
    // Update the Monthly Payout Amount for the User
    userMonthlyPayoutAmount[msg.sender] = userMonthlyPayoutAmount[msg.sender] + monthlyAmount;
    // Update the Total Deposited for the Contract
    totalDepositAmount = totalDepositAmount + totalAmount;
    // Update is User
    isUser[msg.sender] = true;
    // Increment Current ID
    currentId++;
  }

  // TODO: Create Update
  // Update Account
  // Store Value of Account
  // @param accountId The ID of the Account to Update
  // @param value The New Monthly Amount of the Account
  // function updateAccount(uint256 accountId, uint256 value) public isOwner {
  //   accounts[msg.sender][accounts[msg.sender][accountId].accountType].monthlyPremium = value;
  // }

  // Create Payout
  // Create a new payout for a user
  // @param value Monthly Amount of the Health Account
  // @param accountType The Type of Account to Create
  // @security - done - Change so we verify the signature. Verify that user who signed is admin.
  function createPayout(
    address user, 
    uint256 accountType, 
    uint256 fundAmount
  )
    public
    isNotBlacklisted
    isAdminUser
    isActiveContract
  {
    // Find the Account being referenced
    Account storage account = accounts[user][accountType];
    require(account.exists, "Account Type must exist");
    require(account.payoutsLeft > 0, "Account must have payouts left");
    // Get Current Payout Index from Block TImestamp
    uint256 currentIndex = DateUtils.getMonth(block.timestamp);
    require(
      currentIndex == account.payIndex,
      "Must be same month as pay index"
    );
    uint256 currentPayIndex = account.payIndex;
    account.payIndex = (account.payIndex + 1) % 13;
    // If Account PayIndex == 0 then set the payIndex to 1 for January
    if (account.payIndex == 0) {
      account.payIndex = 1;
    }
    Payout memory payout = Payout(
      currentId,
      accountType,
      account.monthlyPremium,
      1,
      user,
      block.timestamp,
      currentPayIndex,
      fundAmount
    );
    
		account.paidTotal = account.paidTotal + account.monthlyPremium;
    account.fundedTotal = account.fundedTotal + fundAmount;
    account.payoutsLeft = account.payoutsLeft - 1;
    uint256 paymentMonthsToReceive = tierPaymentsToReceive[account.tier];
		// If the Principal Has not been paid check the amount to see if it has been paid now
		if (account.principalPaid == false) {
			if (account.paidTotal >= account.monthlyPremium * paymentMonthsToReceive) {
				account.principalPaid = true;
			}
		}
    // Create a New Payout and Push it into the User's Payout Array
    userPayouts[user].push(payout);
    // Set the Payouts to the Account Payouts Array
    userAccountTypePayouts[user][accountType].push(payout);
    // Emit Payout Created Event
    emit PayoutCreated(user, account.monthlyPremium, accountType);
    // Update the Total Payout Amount for the User
    userTotalPayedAmount[user] = userTotalPayedAmount[user] + account.monthlyPremium;
    // Update the Total Payout Amount for the Account Type
    userTotalPayedAmountForAccountType[user][accountType] =
      userTotalPayedAmountForAccountType[user][accountType] +
      account.monthlyPremium;
    // Update the Total Payout Amount for the Contract
    totalPayoutAmount = totalPayoutAmount + account.monthlyPremium;
    // Increment Current Id
    currentId++;
  }

  // Is A Current User
  // @dev Checks if the address is a current user
  function isACurrentUser() public view isActiveContract returns (bool) {
    return isUser[msg.sender];
  }

  // Get Account
  // Used to get the account of the user
  // @param accountType The Type of Account to get
  function getAccount(uint256 accountType)
    public
    view
    isNotBlacklisted
    isActiveContract
    returns (Account memory)
  {
    return accounts[msg.sender][accountType];
  }

  // Get User Account
  // Used to get the user account of the user
  // function getUserAccount() public view isNotBlacklisted returns (UserAccount memory) {
  //   return userAccounts[msg.sender];
  // }

  // Get Payouts Method
  // Used to get payouts of the user
  function getUserPayouts()
    public
    view
    isNotBlacklisted
    isActiveContract
    returns (Payout[] memory)
  {
    return userPayouts[msg.sender];
  }

  // Get Payouts for Specific Account Type
  // Used to get payouts of the user for a specific account type
  function getUserAccountPayouts(uint256 accountType)
    public
    view
    isNotBlacklisted
    isActiveContract
    returns (Payout[] memory)
  {
    return userAccountTypePayouts[msg.sender][accountType];
  }

  // Get Deposits Method
  // Used to get deposits of the user
  function getUserDeposits()
    public
    view
    isNotBlacklisted
    isActiveContract
    returns (Deposit[] memory)
  {
    return userDeposits[msg.sender];
  }

  // Get User Total Monthly Payout Amount
  // Used to get the total monthly Payout Amount of the user
  function getUserMonthlyPayoutAmount()
    public
    view
    isNotBlacklisted
    isActiveContract
    returns (uint256)
  {
    return userMonthlyPayoutAmount[msg.sender];
  }

  // Get User Total Deposit Amount
  // Used to get the total deposit amount of the user
  function getUserTotalDepositAmount()
    public
    view
    isNotBlacklisted
    isActiveContract
    returns (uint256)
  {
    return userTotalDepositAmount[msg.sender];
  }

  // Get User Total Payout Amount
  // Used to get the total payout amount of the user
  function getUserTotalPayedAmount()
    public
    view
    isNotBlacklisted
    isActiveContract
    returns (uint256)
  {
    return userTotalPayedAmount[msg.sender];
  }

  // Get User Total Deposit Amount for Account Type
  // Used to get the total deposit amount of the user for a specific account type
  function getUserTotalDepositAmountForAccountType(uint256 accountType)
    public
    view
    isNotBlacklisted
    isActiveContract
    returns (uint256)
  {
    return userTotalDepositAmountForAccountType[msg.sender][accountType];
  }

  // Get User Total Payout Amount for Account Type
  // Used to get the total payout amount of the user for a specific account type
  function getUserTotalPayedAmountForAccountType(uint256 accountType)
    public
    view
    isNotBlacklisted
    isActiveContract
    returns (uint256)
  {
    return userTotalPayedAmountForAccountType[msg.sender][accountType];
  }

	// Verify Signature
	// Used to Verify Signature
	// @param actionType - Action to be tied to Nonce
	// @param signature - Signature to be verified
	function verifySignature(uint256 actionType, bytes memory signature) public view returns (bool) {
		// Get the User Nonce from the User
    uint256 userNonce = getNonce(actionType);
    // Concatenate the message and the nonce
    string
      memory message = "You are signing this message to create an account with the following nonce: ";
    string memory messageWithNonce = string(abi.encodePacked(message, uint2str(userNonce)));
    // Check if the Signature is Valid
    require(
      VerifySignature.verify(msg.sender, messageWithNonce, signature),
      "Signature is not valid"
    );
		return true;
	}

  // Get a Login Nonce
  // Used in the Authentication Flow
  // @security - You must send signature to create your own time nonce. This will write the nonce to the nonce mapping and be used for any future signing and verifying.
  function getNonce(uint256 actionType)
    public
    view
    isNotBlacklisted
    isActiveContract
    returns (uint256)
  {
    return random(randomSeed, actionType);
  }

  // Random
  // Used as a random number generator
  // @param number used to help generate a random number
  // @security - setup to return the same number every time for the same address.
  function random(uint256 number, uint256 actionType)
    private
    view
    isNotBlacklisted
    returns (uint256)
  {
    return (uint256(keccak256(abi.encodePacked(msg.sender))) % (number + actionType));
  }

  ////// Admin Functions //////
  // @security - For all Admin Functions we must sign and and make sure they are an admin.

  // Get Total Deposit Amount
  // Get Total Deposited Amount for the Contract
  function getTotalContractDepositedAmount()
    public
    view
    isAdminUser
    isNotBlacklisted
    isActiveContract
    returns (uint256)
  {
    return totalDepositAmount;
  }

  // Get Total Payed Out Amount
  // Get Total Deposited Amount for the Contract
  function getTotalContractPayedOutAmount()
    public
    view
    isAdminUser
    isNotBlacklisted
    isActiveContract
    returns (uint256)
  {
    return totalPayoutAmount;
  }

  // Get All Associated Addresses for the Contract
  // Retrieve all Associated Addresses for the Contract
  function getAllAssociatedAddressesOfTheContract()
    public
    view
    isAdminUser
    isNotBlacklisted
    isActiveContract
    returns (address[] memory)
  {
    return associatedAddresses;
  }

  // Create Admin
  // Allows an admin to create a new admin
  // @param address New Admin Address
  function createAdmin(address adminAddress) public isAdminUser isNotBlacklisted {
    require(adminAddress != msg.sender, "Cannot make yourself Admin");
    require(adminAddress != address(this), "Cannot make yourself Admin");
    isAdmin[adminAddress] = true;
    addAssociatedAddress(adminAddress);
  }

  // Change Contract Status
  // Allows an admin to update contract status
  // @param status The new status of the contract
  function updateContractStatus(bool status) public isAdminUser isNotBlacklisted {
    contractStatus = status;
  }

  // Blacklist User
  // Allows an admin to blacklist an address
  // @param address New Deposit Address
  function blacklistAddress(address blacklistedAddress) public isAdminUser isNotBlacklisted {
    blacklist[blacklistedAddress] = true;
    emit BlackListedUser(blacklistedAddress);
  }

  // Update USDT Address
  // Allows an admin to update the usdt Address
  // @param address New USDT Address
  function updateUsdtAddress(address usdtAddress) public isAdminUser isNotBlacklisted {
    usdtToken = IERC20(usdtAddress);
  }

  // Update Deposit Address
  // Allows an admin to update the deposit address
  // @param address New Deposit Address
  // @security - Hardcode into contract
  function updateDepositAddress(address adminAddress) public isAdminUser isNotBlacklisted {
    depositAddress = adminAddress;
  }

  // Set the Account Limit Amount
  // Allows an admin to set the account limit amount
  // @param uint256 New Account Limit Amount
  function setAccountLimitAmount(uint256 newAccountLimitAmount)
    public
    isAdminUser
    isNotBlacklisted
  {
    accountLimitAmount = newAccountLimitAmount;
  }
	// Set the Payment Months to Receive
  // Allows an admin to set the number of payment months to receive
  // @param uint256 New Payment Months to Receive
  function setPaymentMonthsToReceive(uint256 newPaymentMonthsToReceive, uint256 tier)
    public
    isAdminUser
    isNotBlacklisted
  {
    tierPaymentsToReceive[tier] = newPaymentMonthsToReceive;
  }

  // Update the Minimum Payment Amount
  // Allows an admin to update the minimum payment amount
  // @param uint256 New Minimum Payment Amount
  function updateMinimumMonthlyPaymentAmount(uint256 newMinimumPaymentAmount)
    public
    isAdminUser
    isNotBlacklisted
  {
    minimumMonthlyPaymentAmount = newMinimumPaymentAmount;
  }

  // Update Pay Index for a particular Account
  // Allows an admin to update the pay index for a particular account
  // @param uint256 New Pay Index
  // @param address Account Address
  function updatePayIndexForAccount(uint256 newPayIndex, address accountAddress, uint256 accountType)
    public
    isAdminUser
    isNotBlacklisted
  {
    Account storage account = accounts[accountAddress][accountType];
    require(account.exists, "Account Type must exist");
    account.payIndex = newPayIndex;
  }

  ////// Tools //////

  // Uint to String
  // Used to convert a uint to a string
  // @param _i uint to convert
  function uint2str(uint256 _i) private pure returns (string memory str) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 length;
    while (j != 0) {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length;
    j = _i;
    while (j != 0) {
      bstr[--k] = bytes1(uint8(48 + (j % 10)));
      j /= 10;
    }
    str = string(bstr);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

library VerifySignature {
  /* 1. Unlock MetaMask account
    ethereum.enable()
    */

  /* 2. Get message hash to sign
    getMessageHash(
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        123,
        "coffee and donuts",
        1
    )

    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
  function getMessageHash(string memory _message) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_message));
  }

  /* 3. Sign message hash
    # using browser
    account = "copy paste account of signer here"
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

    Signature will be different for different accounts
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
  function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
    /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
    return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', _messageHash));
  }

  /* 4. Verify signature
    signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    to = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    amount = 123
    message = "coffee and donuts"
    nonce = 1
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
  function verify(
    address _signer,
    string memory _message,
    bytes memory signature
  ) public pure returns (bool) {
    bytes32 messageHash = getMessageHash(_message);
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

    return recoverSigner(ethSignedMessageHash, signature) == _signer;
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
    public
    pure
    returns (address)
  {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig)
    public
    pure
    returns (
      bytes32 r,
      bytes32 s,
      uint8 v
    )
  {
    require(sig.length == 65, 'invalid signature length');

    assembly {
      /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

      // first 32 bytes, after the length prefix
      r := mload(add(sig, 32))
      // second 32 bytes
      s := mload(add(sig, 64))
      // final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(sig, 96)))
    }

    // implicitly return (r, s, v)
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateUtils {
  uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint256 private constant SECONDS_PER_HOUR = 60 * 60;
  uint256 private constant SECONDS_PER_MINUTE = 60;
  int256 private constant OFFSET19700101 = 2440588;

  uint256 private constant DOW_MON = 1;
  uint256 private constant DOW_TUE = 2;
  uint256 private constant DOW_WED = 3;
  uint256 private constant DOW_THU = 4;
  uint256 private constant DOW_FRI = 5;
  uint256 private constant DOW_SAT = 6;
  uint256 private constant DOW_SUN = 7;

  // ------------------------------------------------------------------------
  // Calculate the number of days from 1970/01/01 to year/month/day using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and subtracting the offset 2440588 so that 1970/01/01 is day 0
  //
  // days = day
  //      - 32075
  //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
  //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
  //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
  //      - offset
  // ------------------------------------------------------------------------
  function _daysFromDate(
      uint256 year,
      uint256 month,
      uint256 day
  ) internal pure returns (uint256 _days) {
      require(year >= 1970, "Year must be >= 1970");
      int256 _year = int256(year);
      int256 _month = int256(month);
      int256 _day = int256(day);

      int256 __days =
          _day -
              32075 +
              (1461 * (_year + 4800 + (_month - 14) / 12)) /
              4 +
              (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
              12 -
              (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
              4 -
              OFFSET19700101;

      _days = uint256(__days);
  }

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(uint256 _days)
      internal
      pure
      returns (
          uint256 year,
          uint256 month,
          uint256 day
      )
  {
      int256 __days = int256(_days);

      int256 L = __days + 68569 + OFFSET19700101;
      int256 N = (4 * L) / 146097;
      L = L - (146097 * N + 3) / 4;
      int256 _year = (4000 * (L + 1)) / 1461001;
      L = L - (1461 * _year) / 4 + 31;
      int256 _month = (80 * L) / 2447;
      int256 _day = L - (2447 * _month) / 80;
      L = _month / 11;
      _month = _month + 2 - 12 * L;
      _year = 100 * (N - 49) + _year + L;

      year = uint256(_year);
      month = uint256(_month);
      day = uint256(_day);
  }

  function timestampFromDate(
      uint256 year,
      uint256 month,
      uint256 day
  ) internal pure returns (uint256 timestamp) {
      timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
  }

  function timestampFromDateTime(
      uint256 year,
      uint256 month,
      uint256 day,
      uint256 hour,
      uint256 minute,
      uint256 second
  ) internal pure returns (uint256 timestamp) {
      timestamp =
          _daysFromDate(year, month, day) *
          SECONDS_PER_DAY +
          hour *
          SECONDS_PER_HOUR +
          minute *
          SECONDS_PER_MINUTE +
          second;
  }

  function timestampToDate(uint256 timestamp)
      internal
      pure
      returns (
          uint256 year,
          uint256 month,
          uint256 day
      )
  {
      (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function timestampToDateTime(uint256 timestamp)
      internal
      pure
      returns (
          uint256 year,
          uint256 month,
          uint256 day,
          uint256 hour,
          uint256 minute,
          uint256 second
      )
  {
      (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
      uint256 secs = timestamp % SECONDS_PER_DAY;
      hour = secs / SECONDS_PER_HOUR;
      secs = secs % SECONDS_PER_HOUR;
      minute = secs / SECONDS_PER_MINUTE;
      second = secs % SECONDS_PER_MINUTE;
  }

  function isValidDate(
      uint256 year,
      uint256 month,
      uint256 day
  ) internal pure returns (bool valid) {
      if (year >= 1970 && month > 0 && month <= 12) {
          uint256 daysInMonth = _getDaysInMonth(year, month);
          if (day > 0 && day <= daysInMonth) {
              valid = true;
          }
      }
  }

  function isValidDateTime(
      uint256 year,
      uint256 month,
      uint256 day,
      uint256 hour,
      uint256 minute,
      uint256 second
  ) internal pure returns (bool valid) {
      if (isValidDate(year, month, day)) {
          if (hour < 24 && minute < 60 && second < 60) {
              valid = true;
          }
      }
  }

  function isLeapYear(uint256 timestamp)
      internal
      pure
      returns (bool leapYear)
  {
      (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
      leapYear = _isLeapYear(year);
  }

  function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
      leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
  }

  function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
      weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
  }

  function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
      weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
  }

  function getDaysInMonth(uint256 timestamp)
      internal
      pure
      returns (uint256 daysInMonth)
  {
      (uint256 year, uint256 month, ) =
          _daysToDate(timestamp / SECONDS_PER_DAY);
      daysInMonth = _getDaysInMonth(year, month);
  }

  function _getDaysInMonth(uint256 year, uint256 month)
      internal
      pure
      returns (uint256 daysInMonth)
  {
      if (
          month == 1 ||
          month == 3 ||
          month == 5 ||
          month == 7 ||
          month == 8 ||
          month == 10 ||
          month == 12
      ) {
          daysInMonth = 31;
      } else if (month != 2) {
          daysInMonth = 30;
      } else {
          daysInMonth = _isLeapYear(year) ? 29 : 28;
      }
  }

  // 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint256 timestamp)
      internal
      pure
      returns (uint256 dayOfWeek)
  {
      uint256 _days = timestamp / SECONDS_PER_DAY;
      dayOfWeek = ((_days + 3) % 7) + 1;
  }

  function getYear(uint256 timestamp) internal pure returns (uint256 year) {
      (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getMonth(uint256 timestamp) public pure returns (uint256 month) {
      (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getDay(uint256 timestamp) internal pure returns (uint256 day) {
      (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
      uint256 secs = timestamp % SECONDS_PER_DAY;
      hour = secs / SECONDS_PER_HOUR;
  }

  function getMinute(uint256 timestamp)
      internal
      pure
      returns (uint256 minute)
  {
      uint256 secs = timestamp % SECONDS_PER_HOUR;
      minute = secs / SECONDS_PER_MINUTE;
  }

  function getSecond(uint256 timestamp)
      internal
      pure
      returns (uint256 second)
  {
      second = timestamp % SECONDS_PER_MINUTE;
  }

  function addYears(uint256 timestamp, uint256 _years)
      internal
      pure
      returns (uint256 newTimestamp)
  {
      (uint256 year, uint256 month, uint256 day) =
          _daysToDate(timestamp / SECONDS_PER_DAY);
      year += _years;
      uint256 daysInMonth = _getDaysInMonth(year, month);
      if (day > daysInMonth) {
          day = daysInMonth;
      }
      newTimestamp =
          _daysFromDate(year, month, day) *
          SECONDS_PER_DAY +
          (timestamp % SECONDS_PER_DAY);
      require(newTimestamp >= timestamp, "new must be >= timestamp");
  }

  function addMonths(uint256 timestamp, uint256 _months)
      public
      pure
      returns (uint256 newTimestamp)
  {
      (uint256 year, uint256 month, uint256 day) =
          _daysToDate(timestamp / SECONDS_PER_DAY);
      month += _months;
      year += (month - 1) / 12;
      month = ((month - 1) % 12) + 1;
      uint256 daysInMonth = _getDaysInMonth(year, month);
      if (day > daysInMonth) {
          day = daysInMonth;
      }
      newTimestamp =
          _daysFromDate(year, month, day) *
          SECONDS_PER_DAY +
          (timestamp % SECONDS_PER_DAY);
      require(newTimestamp >= timestamp, "new must be >= timestamp");
  }

  function addDays(uint256 timestamp, uint256 _days)
      internal
      pure
      returns (uint256 newTimestamp)
  {
      newTimestamp = timestamp + _days * SECONDS_PER_DAY;
      require(newTimestamp >= timestamp, "new must be >= timestamp");
  }

  function addHours(uint256 timestamp, uint256 _hours)
      internal
      pure
      returns (uint256 newTimestamp)
  {
      newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
      require(newTimestamp >= timestamp );
  }

  function addMinutes(uint256 timestamp, uint256 _minutes)
      internal
      pure
      returns (uint256 newTimestamp)
  {
      newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
      require(newTimestamp >= timestamp);
  }

  function addSeconds(uint256 timestamp, uint256 _seconds)
      internal
      pure
      returns (uint256 newTimestamp)
  {
      newTimestamp = timestamp + _seconds;
      require(newTimestamp >= timestamp);
  }

  function subYears(uint256 timestamp, uint256 _years)
      internal
      pure
      returns (uint256 newTimestamp)
  {
      (uint256 year, uint256 month, uint256 day) =
          _daysToDate(timestamp / SECONDS_PER_DAY);
      year -= _years;
      uint256 daysInMonth = _getDaysInMonth(year, month);
      if (day > daysInMonth) {
          day = daysInMonth;
      }
      newTimestamp =
          _daysFromDate(year, month, day) *
          SECONDS_PER_DAY +
          (timestamp % SECONDS_PER_DAY);
      require(newTimestamp <= timestamp);
  }

  function subMonths(uint256 timestamp, uint256 _months)
      internal
      pure
      returns (uint256 newTimestamp)
  {
      (uint256 year, uint256 month, uint256 day) =
          _daysToDate(timestamp / SECONDS_PER_DAY);
      uint256 yearMonth = year * 12 + (month - 1) - _months;
      year = yearMonth / 12;
      month = (yearMonth % 12) + 1;
      uint256 daysInMonth = _getDaysInMonth(year, month);
      if (day > daysInMonth) {
          day = daysInMonth;
      }
      newTimestamp =
          _daysFromDate(year, month, day) *
          SECONDS_PER_DAY +
          (timestamp % SECONDS_PER_DAY);
      require(newTimestamp <= timestamp);
  }

  function subDays(uint256 timestamp, uint256 _days)
      internal
      pure
      returns (uint256 newTimestamp)
  {
      newTimestamp = timestamp - _days * SECONDS_PER_DAY;
      require(newTimestamp <= timestamp);
  }

  function subHours(uint256 timestamp, uint256 _hours)
      internal
      pure
      returns (uint256 newTimestamp)
  {
      newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
      require(newTimestamp <= timestamp);
  }

  function subMinutes(uint256 timestamp, uint256 _minutes)
      internal
      pure
      returns (uint256 newTimestamp)
  {
      newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
      require(newTimestamp <= timestamp);
  }

  function subSeconds(uint256 timestamp, uint256 _seconds)
      internal
      pure
      returns (uint256 newTimestamp)
  {
      newTimestamp = timestamp - _seconds;
      require(newTimestamp <= timestamp);
  }

  function diffYears(uint256 fromTimestamp, uint256 toTimestamp)
      internal
      pure
      returns (uint256 _years)
  {
      require(fromTimestamp <= toTimestamp);
      (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
      (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
      _years = toYear - fromYear;
  }

  function diffMonths(uint256 fromTimestamp, uint256 toTimestamp)
      internal
      pure
      returns (uint256 _months)
  {
      require(fromTimestamp <= toTimestamp);
      (uint256 fromYear, uint256 fromMonth, ) =
          _daysToDate(fromTimestamp / SECONDS_PER_DAY);
      (uint256 toYear, uint256 toMonth, ) =
          _daysToDate(toTimestamp / SECONDS_PER_DAY);
      _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
  }

  function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
      internal
      pure
      returns (uint256 _days)
  {
      require(fromTimestamp <= toTimestamp);
      _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
  }

  function diffHours(uint256 fromTimestamp, uint256 toTimestamp)
      internal
      pure
      returns (uint256 _hours)
  {
      require(fromTimestamp <= toTimestamp);
      _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
  }

  function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp)
      internal
      pure
      returns (uint256 _minutes)
  {
      require(fromTimestamp <= toTimestamp);
      _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
  }

  function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp)
      internal
      pure
      returns (uint256 _seconds)
  {
      require(fromTimestamp <= toTimestamp);
      _seconds = toTimestamp - fromTimestamp;
  }
}