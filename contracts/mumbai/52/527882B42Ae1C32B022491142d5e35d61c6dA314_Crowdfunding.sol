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
// File: contracts/crowdfunding/Crowdfunding.sol

pragma solidity >=0.8.0 <0.9.0;



contract Crowdfunding is Pausable {

    /// @dev error message.
    string constant TX_FAIL = "Transfer failed";

    modifier validActivity(string memory activity){
        require(subContracts[activity] != address(0), "Activity not found");
        _;
    }

    mapping(string => address) subContracts;

    //-------------------//
    // SET               //
    //-------------------//

    /// @dev Set the sub-contract name and corresponding address.
    /// @param activity The name of the sub-contract.
    /// @param _address The address of the sub-contract.
    function setSubContracts(string memory activity, address _address) external onlyAdmin {
        subContracts[activity] = _address;
    }

    //-------------------//
    // GET               //
    //-------------------//

    /// @dev Get the subcontract address
    /// @param activity The name of the subcontracts.
    /// @return The address of the subcontract.
    function getSubContracts(string memory activity) external onlyAdmin validActivity(activity) view returns (address) {
        return subContracts[activity];
    }

    /// @dev Get the total number of subcontracts sold.
    /// @param activity The name of the subcontracts.
    /// @return totalSupply The total quantity sold of the subcontracts.
    function getTotalSupply(string memory activity) external view returns (uint256 totalSupply) {
        INFTCrowdfunding subContract = buildSubContract(activity);
        totalSupply = subContract.totalSupply();
    }

    /// @dev Get total amount of the subcontracts sold.
    /// @param activity The name of the subcontracts.
    /// @return totalAmount
    function getTotalAmount(string memory activity) external view returns (uint256 totalAmount) {
        INFTCrowdfunding subContract = buildSubContract(activity);
        totalAmount = subContract.totalAmount();
    }

    /// @dev Get the fundraising target amount
    /// @param activity The name of the subcontracts.
    /// @return targetAmount
    function getTargetAmount(string memory activity) external view returns (uint256 targetAmount) {
        INFTCrowdfunding subContract = buildSubContract(activity);
        targetAmount = subContract.targetAmount();
    }

    /// @dev Whether it is a allowlist
    /// @param activity The name of the subcontracts.
    /// @return status true: is a allowlist, false: not allowlist
    function isAllowlist(string memory activity) external view returns (bool status) {
        INFTCrowdfunding subContract = buildSubContract(activity);
        status = subContract.allowlist(msg.sender);
    }

    /// @dev Get general selling conditions
    /// @param activity The name of the subcontracts.
    /// @return startAt start time
    /// @return endAt end time
    /// @return price unit price
    /// @return acctQty Quantity that can be purchased
        function getPublicData(string memory activity) external view returns (uint256 startAt, uint256 endAt, uint256 price, uint256 acctQty) {
        INFTCrowdfunding subContract = buildSubContract(activity);
        (startAt, endAt, price, acctQty) = subContract.getPublicData();
    }

    /// @dev Get allowlist selling conditions
    /// @param activity The name of the subcontracts
    /// @return startAt Start time
    /// @return endAt End time
    /// @return price Unit price
    /// @return acctQty Quantity that can be purchased
    function getAllowlistData(string memory activity) external view returns (uint256 startAt, uint256 endAt, uint256 price, uint256 acctQty) {
        INFTCrowdfunding subContract = buildSubContract(activity);
        (startAt, endAt, price, acctQty) = subContract.getAllowlistData();
    }

    /// @dev Get the number of purchases of the specified account
    /// @param activity The name of the subcontracts
    /// @param account The account address
    /// @return publicReceipt Quantity purchased
    function getPublicReceipt(string memory activity, address account) external view returns (uint256 publicReceipt) {
        INFTCrowdfunding subContract = buildSubContract(activity);
        publicReceipt = subContract.publicReceipt(account);
    }

    /// @dev Get the number of purchases of the specified account
    /// @param activity The name of the subcontracts
    /// @param account The account address
    /// @return allowlistReceipt Quantity purchased
    function getAllowlistReceipt(string memory activity, address account) external view returns (uint256 allowlistReceipt) {
        INFTCrowdfunding subContract = buildSubContract(activity);
        allowlistReceipt = subContract.allowlistReceipt(account);
    }

    function getpublicRefundReceipt(string memory activity, address account) external view returns (uint256 amount) {
        INFTCrowdfunding subContract = buildSubContract(activity);
        amount = subContract.publicRefundReceipt(account);
    }

    function getAllowlistRefundReceipt(string memory activity, address account) external view returns (uint256 amount) {
        INFTCrowdfunding subContract = buildSubContract(activity);
        amount = subContract.allowlistRefundReceipt(account);
    }
    //-------------------//
    // FUNCTION          //
    //-------------------//

    /// @dev General buy
    /// @param activity The name of the subcontracts.
    /// @param buyQty quantity to buy.
    function publicBuy(string memory activity, uint256 buyQty) whenNotPaused external payable {
        INFTCrowdfunding subContract = buildSubContract(activity);
        require(buyQty > 0, 'The quantity must be above 0');
        uint256 payableAmount = subContract.publicBuy(msg.sender, buyQty);
        require(payableAmount == msg.value, 'The price must be equal to the msg.value');
    }

    /// @dev allowlist buy
    /// @param activity The name of the subcontracts.
    /// @param buyQty quantity to buy.
    function allowlistBuy(string memory activity, uint256 buyQty) whenNotPaused external payable {
        INFTCrowdfunding subContract = buildSubContract(activity);
        require(buyQty > 0, 'The quantity must be above 0');
        uint256 payableAmount = subContract.allowlistBuy(msg.sender, buyQty);
        require(payableAmount == msg.value, 'The price must be equal to the msg.value');
    }

    /// @dev General Refund
    /// @param activity The name of the subcontracts.
    /// @param account purchase address
    function publicRefund(string memory activity, address account) whenNotPaused external {
        INFTCrowdfunding subContract = buildSubContract(activity);
        require(account != address(0), INVALID_ADDRESS);
        uint256 refundAmount = subContract.publicRefund(account);
        (bool success,) = payable(account).call{value : refundAmount}("");
        require(success, TX_FAIL);
    }

    /// @dev Allowlist Refund
    /// @param activity The name of the subcontracts.
    /// @param account purchase address
    function allowlistRefund(string memory activity, address account) whenNotPaused external {
        INFTCrowdfunding subContract = buildSubContract(activity);
        require(account != address(0), INVALID_ADDRESS);
        uint256 refundAmount = subContract.allowlistRefund(account);
        (bool success,) = payable(account).call{value : refundAmount}("");
        require(success, TX_FAIL);
    }

    /// @dev Refund all accounts at once
    /// @param activity The name of the subcontracts.
    function refundAll(string memory activity) whenNotPaused external {
        INFTCrowdfunding subContract = buildSubContract(activity);
        address[] memory publicReceiptAccounts = subContract.getPublicReceiptAccounts();
        for (uint256 i = 0; i < publicReceiptAccounts.length; i++) {
            uint256 refundAmount = subContract.publicRefundReceipt(publicReceiptAccounts[i]);
            if (refundAmount != 0) {
                continue;
            }
            uint256 totalAmount = subContract.publicRefund(publicReceiptAccounts[i]);
            (bool success,) = payable(publicReceiptAccounts[i]).call{value : totalAmount}("");
            require(success, TX_FAIL);
        }

        address[] memory allowlistReceiptAccounts = subContract.getAllowlistReceiptAccounts();
        for (uint256 i = 0; i < allowlistReceiptAccounts.length; i++) {
            uint256 refundAmount = subContract.allowlistRefundReceipt(allowlistReceiptAccounts[i]);
            if (refundAmount != 0) {
                continue;
            }
            uint256 totalAmount = subContract.allowlistRefund(allowlistReceiptAccounts[i]);
            (bool success,) = payable(allowlistReceiptAccounts[i]).call{value : totalAmount}("");
            require(success, TX_FAIL);
        }
    }

    /// @dev Withdrawal
    /// @param activity The name of the subcontracts.
    /// @param receiver Payout address.
    function withdraw(string memory activity, address receiver) external onlySuperAdmin {
        INFTCrowdfunding subContract = buildSubContract(activity);
        require(receiver != address(0), 'Invalid address');
        uint256 _withdrawAmount = subContract.withdraw();
        (bool success,) = payable(receiver).call{value : _withdrawAmount}("");
        require(success, TX_FAIL);
    }

    function buildSubContract(string memory activity) internal view validActivity(activity) returns(INFTCrowdfunding subContract){
        address SubContractAddress = subContracts[activity];
        subContract = INFTCrowdfunding(SubContractAddress);
    }
}