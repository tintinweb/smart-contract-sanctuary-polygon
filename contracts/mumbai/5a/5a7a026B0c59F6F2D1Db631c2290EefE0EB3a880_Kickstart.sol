/**
 *Submitted for verification at polygonscan.com on 2022-09-28
*/

// File: contracts/crowdfunding/INFTCrowdfunding.sol

pragma solidity >=0.8.0 <0.9.0;

interface INFTCrowdfunding {
    function totalSupply() external view returns (uint256 _totalSupply);
    function totalAmount() external view returns (uint256 _totalAmount);
    function targetAmount() external view returns (uint256 _targetAmount);
    function allowlist(address account) external view returns (bool _status);
    function publicReceipt(address account) external view returns (uint256 _publicReceipt);
    function allowlistReceipt(address account) external view returns (uint256 _allowlistReceipt);
    function publicRefundReceipt(address account) external view returns (uint256 _refundAmount);
    function allowlistRefundReceipt(address account) external view returns (uint256 _refundAmount);

    function getPublicData() external view returns (uint256 _startAt, uint256 _endAt, uint256 _price, uint256 _AcctQty);
    function getAllowlistData() external view returns (uint256 _startAt, uint256 _endAt, uint256 _price, uint256 _AcctQty);

    function getPublicReceiptAccounts() external view returns (address[] memory _accounts);
    function getAllowlistReceiptAccounts() external view returns (address[] memory _accounts);

    function publicBuy(address account, uint256 buyQty) external returns (uint256 _payableAmount);
    function allowlistBuy(address account, uint256 buyQty) external returns (uint256 _payableAmount);
    function publicRefund(address account) external returns (uint256 _refundAmount);
    function allowlistRefund(address account) external returns (uint256 _refundAmount);
    function withdraw() external returns (uint256 _withdrawAmount);
}

// File: contracts/security/v2/AccessControl.sol

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    fallback() external {}
}
// File: contracts/security/v2/Pausable.sol

pragma solidity >=0.8.0 <0.9.0;


contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}
// File: contracts/crowdfunding/Kickstart.sol

pragma solidity >=0.8.0 <0.9.0;



contract Kickstart is Pausable, INFTCrowdfunding {

    uint256 public override totalSupply = 0;
    uint256 public override totalAmount = 0;
    uint256 public override targetAmount = 0;
    uint256 public withdrawAmount = 0;

    uint256 public publicStartAt = 0;
    uint256 public publicEndAt = 0;
    uint256 public publicPrice = 0;
    uint256 public publicAcctQty = 0;
    mapping(address => uint256) public override publicReceipt;
    address[] publicReceiptAccounts;
    uint256 public publicTotalSupply = 0;
    uint256 public publicTotalAmount = 0;
    uint256 public publicRefundSupply = 0;
    uint256 public publicRefundAmount = 0;
    mapping(address => uint256) public override publicRefundReceipt;

    mapping(address => bool) public override allowlist;
    uint256 public allowlistStartAt = 0;
    uint256 public allowlistEndAt = 0;
    uint256 public allowlistPrice = 0;
    uint256 public allowlistAcctQty = 0;
    mapping(address => uint256) public override allowlistReceipt;
    address[] allowlistReceiptAccounts;
    uint256 public allowlistTotalSupply = 0;
    uint256 public allowlistTotalAmount = 0;
    uint256 public allowlistRefundSupply = 0;
    uint256 public allowlistRefundAmount = 0;
    mapping(address => uint256) public override allowlistRefundReceipt;

    address mainContract;

    constructor(address _address, uint256 _targetAmount) {
        mainContract = _address;
        targetAmount = _targetAmount;
    }

    //-------------------//
    // SET               //
    //-------------------//
    /// @dev Set the target amount of the crowdfunding campaign
    /// @param _targetAmount target amount
    function setTargetAmount(uint256 _targetAmount) external onlyAdmin {
        require((publicStartAt > block.timestamp && allowlistStartAt > block.timestamp) || (allowlistStartAt == 0 && publicStartAt == 0), 'The activity has started');
        targetAmount = _targetAmount;
    }

    /// @dev Set the General selling conditions
    /// @param startAt start time
    /// @param endAt end time
    /// @param price price
    /// @param acctQty Quantity that can be purchased
    function setPublicData(uint256 startAt, uint256 endAt, uint256 price, uint256 acctQty) external validSetData(startAt, endAt) onlyAdmin {
        publicAcctQty = acctQty;
        if (publicStartAt == 0 || publicStartAt > block.timestamp) {
            publicStartAt = startAt;
        }
        if (publicEndAt == 0 || publicEndAt > block.timestamp) {
            publicEndAt = endAt;
        }
        if (publicTotalSupply == 0) {
            publicPrice = price;
        }
    }

    /// @dev Set the allowlist selling conditions
    /// @param startAt start time
    /// @param endAt end time
    /// @param price price
    /// @param acctQty Quantity that can be purchased
    function setAllowlistData(uint256 startAt, uint256 endAt, uint256 price, uint256 acctQty) external validSetData(startAt, endAt) onlyAdmin {
        allowlistAcctQty = acctQty;
        if (allowlistStartAt == 0 || allowlistStartAt > block.timestamp) {
            allowlistStartAt = startAt;
        }
        if (allowlistEndAt == 0 || allowlistEndAt > block.timestamp) {
            allowlistEndAt = endAt;
        }
        if (allowlistTotalSupply == 0) {
            allowlistPrice = price;
        }
    }

    /// @dev set allowlist address
    /// @param account input 1-n address
    function setAllowlist(address[] memory account) external onlyAdmin {
        for (uint256 i = 0; i < account.length; i++) {
            if (account[i] != address(0)) {
                allowlist[account[i]] = true;
            }
        }
    }

    //-------------------//
    // GET               //
    //-------------------//

    /// @dev Get the General selling conditions
    /// @return _startAt start time
    /// @return _endAt end time
    /// @return _price price
    /// @return _acctQty Quantity that can be purchased
    function getPublicData() external override view returns (uint256 _startAt, uint256 _endAt, uint256 _price, uint256 _acctQty) {
        _startAt = publicStartAt;
        _endAt = publicEndAt;
        _price = publicPrice;
        _acctQty = publicAcctQty;
    }

    /// @dev Get the allowlist selling conditions.
    /// @return _startAt start time
    /// @return _endAt end time
    /// @return _price price
    /// @return _acctQty Quantity that can be purchased
    function getAllowlistData() external override view returns (uint256 _startAt, uint256 _endAt, uint256 _price, uint256 _acctQty) {
        _startAt = allowlistStartAt;
        _endAt = allowlistEndAt;
        _price = allowlistPrice;
        _acctQty = allowlistAcctQty;
    }

    /// @dev Get General purchased accounts
    /// @return _publicReceiptAccounts 0-N purchase accounts
    function getPublicReceiptAccounts() external override view returns (address[] memory _publicReceiptAccounts) {
        _publicReceiptAccounts = publicReceiptAccounts;
    }

    /// @dev Get allowlist purchased accounts
    /// @return _allowlistReceiptAccounts 0-N purchase accounts
    function getAllowlistReceiptAccounts() external override view returns (address[] memory _allowlistReceiptAccounts) {
        _allowlistReceiptAccounts = allowlistReceiptAccounts;
    }

    //-------------------//
    // FUNCTION          //
    //-------------------//

    /// @dev General purchase function
    /// @param account purchase address
    /// @param buyQty Purchase quantity
    /// @return _payableAmount Amounts payable
    function publicBuy(address account, uint256 buyQty) external whenNotPaused override validBuy(buyQty, publicStartAt, publicEndAt) returns (uint256 _payableAmount) {
        require(publicReceipt[account] + buyQty <= publicAcctQty, "Exceeds the available quantity");

        _payableAmount = buyQty * publicPrice;

        if (publicReceipt[account] == 0) {
            publicReceiptAccounts.push(account);
        }
        publicReceipt[account] += buyQty;
        publicTotalSupply += buyQty;
        publicTotalAmount += _payableAmount;

        totalSupply += buyQty;
        totalAmount += _payableAmount;
    }

    /// @dev allowlist purchase function
    /// @param account purchase address
    /// @param buyQty Purchase quantity
    /// @return _payableAmount Amounts payable
    function allowlistBuy(address account, uint256 buyQty) external whenNotPaused override validBuy(buyQty, allowlistStartAt, allowlistEndAt) returns (uint256 _payableAmount) {
        require(allowlist[account] == true, "Not in the allowlist");
        require(allowlistReceipt[account] + buyQty <= allowlistAcctQty, "Exceeds the available quantity");

        _payableAmount = buyQty * allowlistPrice;

        if (allowlistReceipt[account] == 0) {
            allowlistReceiptAccounts.push(account);
        }
        allowlistReceipt[account] += buyQty;
        allowlistTotalSupply += buyQty;
        allowlistTotalAmount += _payableAmount;

        totalSupply += buyQty;
        totalAmount += _payableAmount;
    }

    /// @dev General purchase refund
    /// @param account purchase address
    /// @return _refundAmount refund amount
    function publicRefund(address account) external whenNotPaused override validRefund(account) returns (uint256 _refundAmount) {
        require(publicReceipt[account] > 0, "No purchase record");
        require(publicRefundReceipt[account] == 0, "There is already a refund record");

        _refundAmount = publicPrice * publicReceipt[account];

        require(publicRefundSupply + publicReceipt[account] <= publicTotalSupply, "Refund Supply cannot exceed public total supply");
        require(publicRefundAmount + _refundAmount <= publicTotalAmount, "Refund Amount cannot exceed public total amount");

        publicRefundSupply += publicReceipt[account];
        publicRefundAmount += _refundAmount;
        publicRefundReceipt[account] = _refundAmount;

        require(allowlistRefundSupply + publicRefundSupply <= totalSupply, "refund supply cannot exceed total supply");
        require(allowlistRefundAmount + publicRefundAmount <= totalAmount, "refund amount cannot exceed total amount");
    }

    /// @dev Allowlist Refund
    /// @param account purchase address
    /// @return _refundAmount refund amount
    function allowlistRefund(address account) external whenNotPaused override validRefund(account) returns (uint256 _refundAmount) {
        require(allowlistReceipt[account] > 0, "No purchase record");
        require(allowlistRefundReceipt[account] == 0, "There is already a refund record");

        _refundAmount = allowlistPrice * allowlistReceipt[account];

        require(allowlistRefundSupply + allowlistReceipt[account] <= allowlistTotalSupply, "Refund Supply cannot exceed allowlist total supply");
        require(allowlistRefundAmount + _refundAmount <= allowlistTotalAmount, "Refund Amount cannot exceed allowlist total amount");

        allowlistRefundSupply += allowlistReceipt[account];
        allowlistRefundAmount += _refundAmount;
        allowlistRefundReceipt[account] = _refundAmount;

        require(allowlistRefundSupply + publicRefundSupply <= totalSupply, "refund supply cannot exceed total supply");
        require(allowlistRefundAmount + publicRefundAmount <= totalAmount, "refund amount cannot exceed total amount");
    }

    /// @dev Withdrawal
    /// @return _withdrawAmount Withdrawable amount
    function withdraw() external override returns (uint256 _withdrawAmount) {
        require(msg.sender == mainContract, NO_PERMISSION);
        require(allowlistEndAt != 0 &&  publicEndAt != 0, 'The activity has not been activated');
        require(block.timestamp > allowlistEndAt, 'The allowlist activity has not ended');
        require(block.timestamp > publicEndAt, 'The activity has not ended');
        require(totalAmount >= targetAmount, 'Target amount not reached');

        _withdrawAmount = totalAmount - (withdrawAmount + publicRefundAmount + allowlistRefundAmount);
        require(_withdrawAmount > 0, "No withdrawable amount");
        withdrawAmount += _withdrawAmount;
    }

    //-------------------//
    // Validation        //
    //-------------------//

    modifier validBuy(uint256 buyQty, uint256 startAt, uint256 endAt) {
        require(msg.sender == mainContract, NO_PERMISSION);
        require(startAt != 0 && endAt != 0, 'The activity has not been activated');
        require(block.timestamp >= startAt, 'The activity has not begun yet');
        require(block.timestamp <= endAt, 'The activity has ended');
        _;
    }

    modifier validRefund(address account) {
        require(msg.sender == mainContract, NO_PERMISSION);
        require(account != address(0), 'Invalid address');
        require(allowlistEndAt != 0 && publicEndAt != 0, 'The activity has not been activated');
        require(block.timestamp > allowlistEndAt, 'The allowlist activity has not ended');
        require(block.timestamp > publicEndAt, 'The activity has not ended');
        require(totalAmount < targetAmount, 'The target amount has been reached');
        _;
    }

    modifier validSetData(uint256 startAt, uint256 endAt) {
        require(startAt != 0, 'Start time cannot be set to 0');
        require(startAt > block.timestamp, 'The start time must be greater than the current time');
        require(endAt > startAt, 'The end time must be greater than the start time');
        _;
    }
}