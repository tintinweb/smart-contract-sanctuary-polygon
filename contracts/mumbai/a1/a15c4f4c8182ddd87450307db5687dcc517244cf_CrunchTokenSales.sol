/**
 *Submitted for verification at polygonscan.com on 2022-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract CrunchTokenSales {

    struct UserClaim {
        uint256 amountLocked;
        uint256 totalAmountToRecieve;
        uint256 amountClaimed;
        uint256 time;
        uint256 nextClaim;
    }

    mapping(address => UserClaim) public userClaim;

    bool public checkSaleStatus;
    address public crunchToken;
    address public USDT;
    address public USDC;

    // address public owner;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public totalAmountSoldOut;
    uint256 public Price;
    uint256 public maticFee;
    uint256 public fee;
    uint256 public minimumPurchaseAmount;

    event sales(address token, address indexed to, uint256 amountIn, uint256 amountRecieved);
    event rewardClaim(address indexed token, address indexed claimer, uint256 reward, uint256 time);
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        address token;
        uint value;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor( 
        address[] memory _owners,
        address _crunchtoken, 
        address _usdt, 
        address _usdc, 
        uint256 _price, 
        uint256 _fee, 
        uint256 mFee, 
        uint256 _minimumAmount,
        uint256 _numConfirmationsRequired
        ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        // owner =  _msgSender();
        checkSaleStatus = true;
        crunchToken = _crunchtoken;
        USDT = _usdt;
        USDC = _usdc;
        Price = _price;
        fee = _fee;
        maticFee = mFee;
        minimumPurchaseAmount = _minimumAmount;
    }

    function updateMinimumAMount(uint256 _newMinimumAmount) external onlyOwner {
        minimumPurchaseAmount = _newMinimumAmount;
    }

    function buy(uint256 _tokenAmount, address purchaseWith) public {
        require(_tokenAmount ** IERC20(purchaseWith).decimals() > 0, "CRUNCH NETWORK: BUY ATLEAST 1 TOKEN.");
        require(purchaseWith == USDT || purchaseWith == USDC, "Invalid Token Contract");
        uint256 fees = _tokenAmount * 10 ** IERC20(purchaseWith).decimals() - (fee);
        uint256 reward = calculateReward(fees);
        require(checkSaleStatus == true, "CRUNCH NETWORK: SALE HAS ENDED.");
        require(reward >= minimumPurchaseAmount, "Minimum amount require for purchase");
        uint256 addressBalance = IERC20(crunchToken).balanceOf(address(this));
        require(addressBalance >= reward, "CRUNCH NETWORK: Contract Balance too low for amount provided");
        require(IERC20(purchaseWith).transferFrom(_msgSender(), address(this), _tokenAmount * 10 ** IERC20(purchaseWith).decimals() ), "CRUNCH NETWORK: TRANSFERFROM FAILED!");
        
        UserClaim storage claim = userClaim[msg.sender];
        claim.amountLocked += fees;
        claim.totalAmountToRecieve += reward;
        claim.time = block.timestamp;
        claim.nextClaim = block.timestamp + 5200086; // 60 days 4 hours
        uint256 getTenPercent = (reward * 10 ** IERC20(crunchToken).decimals()) / 100 ** IERC20(crunchToken).decimals();
        totalAmountSoldOut += getTenPercent;
        claim.amountClaimed += getTenPercent;
        IERC20(crunchToken).transfer(_msgSender(), getTenPercent);
        emit sales(purchaseWith, _msgSender(), _tokenAmount, reward);
    }

    function buyWithMatic() external payable{
        uint256 p = Price;
        uint256 value = msg.value;
        uint256 reward = value/ p;
        require(reward >= minimumPurchaseAmount, "Minimum amount require for purchase");
        uint256 addressBalance = IERC20(crunchToken).balanceOf(address(this));
        require(addressBalance >= reward, "CRUNCH NETWORK: Contract Balance too low for amount provided");
        require(checkSaleStatus == true, "CRUNCH NETWORK: SALE HAS ENDED.");
        uint256 debitFee = value - maticFee;
        UserClaim storage claim = userClaim[msg.sender];
        claim.amountLocked += (debitFee);
        claim.totalAmountToRecieve += reward;
        claim.time = block.timestamp;
        claim.nextClaim = block.timestamp + 5200086; // 60 days 4 hours
        uint256 getTenPercent = (debitFee * 10 ** IERC20(crunchToken).decimals()) / 100 ** IERC20(crunchToken).decimals();
        totalAmountSoldOut += getTenPercent;
        claim.amountClaimed += getTenPercent;
        IERC20(crunchToken).transfer(_msgSender(), getTenPercent);
        emit sales(address(crunchToken), _msgSender(), msg.value, reward);
    }

    // function buy

    function claimReward() external {
        UserClaim storage claim = userClaim[msg.sender];
        uint256 _claim = claim.nextClaim;
        uint256 amountClaimed = claim.totalAmountToRecieve;
        require(block.timestamp > _claim, "Chruch: Kindly exercise patience for claim time");
        require(amountClaimed != claim.amountClaimed, "Chruch: No more reward");
        claim.time = block.timestamp;
        claim.nextClaim = block.timestamp + 5200086; // 60 days 4 hours
        uint256 fiftenPercent = (claim.amountLocked * 15 ** IERC20(crunchToken).decimals()) / 100 ** IERC20(crunchToken).decimals();
        claim.amountClaimed += fiftenPercent;
        IERC20(crunchToken).transfer(_msgSender(), fiftenPercent);
        emit rewardClaim(address(crunchToken), _msgSender(), fiftenPercent, block.timestamp);
    }

    function setFee(uint256 _newFeeToken, uint256 mFee) external onlyOwner {
        fee = _newFeeToken;
        maticFee = mFee;
    }

    function calculateReward(uint256 amount) public view returns(uint256) {
        uint256 p = Price;
        uint256 reward = (
            (amount * 10 ** IERC20(crunchToken).decimals()) * 
            1 ** IERC20(crunchToken).decimals()/
            p) * 10 ** IERC20(crunchToken).decimals()
        ;
        return reward ;
    }

    function resetPrice(uint256 newPrice) external onlyOwner {
        Price = newPrice;
    }
    
    // To enable the sale, send RGP tokens to this contract
    function enableSale(bool status) external onlyOwner{

        // Enable the sale
        checkSaleStatus = status;
    }

    function submitTransaction(
        address _token,
        address _to,
        uint _value
    ) public onlyOwner {
        uint txIndex = transactions.length;
        require(IERC20(_token).balanceOf(address(this)) > _value, "Kindly ensure there is enough fee.");
        transactions.push(
            Transaction({
                to: _to,
                token: _token,
                value: _value,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;
        require(IERC20(transaction.token).transfer(transaction.to, transaction.value), "transfer failed.");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function executeMaticTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address token,
            address to,
            uint value,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.token,
            transaction.to,
            transaction.value,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}