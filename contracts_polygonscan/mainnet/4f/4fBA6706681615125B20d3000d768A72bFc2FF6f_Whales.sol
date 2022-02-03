// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.6;

import "./Weighting.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Whales {
   
    address payable internal _whaleBeneficiary;
    address internal _whaleWeightingContract;
    address internal _whaleHighestBidder;
    uint internal _highestBid;
    uint internal _whaleLastBidTime;
    uint internal _minimumWhaleBid;
    uint internal _whaleIncrement;
    uint internal _whaleReturnFee;
    bool private constant NOT_ENTERED = false;
    bool private constant ENTERED = true;
    Weighting wcon;

    receive() external payable {}
    fallback() external payable {}
   
    mapping(address => uint) internal _pendingReturns;
    mapping(address => bool) internal _userWhaleReentrancy;
    
    modifier whaleMultipleETH(){
       require(msg.value % _whaleIncrement == 0, "Only 1 ETH multiples are accepted"); //1 matic
       _;
    }
   
    modifier beforeWhaleAuction(uint _time) {
        require(block.timestamp < _time, "Whale auction has ended");
        _;
    }
    
    modifier afterWhaleAuction(uint _time) {
        require(block.timestamp >= _time, "Whale auction did not end yet");
        _;
    }
    
    modifier notWhaleOwner() {
        require(msg.sender != _whaleBeneficiary, "Contract owner can not interract here");
        _;
    }
    
    modifier onlyWhaleOwner(address messageSender) {
        require(_whaleBeneficiary == messageSender, "Only the owner can use this function");
        _;
    }
    
    modifier isWhaleWeighting() {
        require(address(_whaleWeightingContract) == msg.sender, "Wrong contract passed. Contract is not Weighting");
        _;
    }
    
    modifier cantBeFutureOwner(address newBeneficiaryW) {
        require(_whaleHighestBidder != newBeneficiaryW, "Can not pass ownership to highest bidder");
        _;
    }
    
    modifier lowestWhaleBidMinimum() {
        require(msg.value >= _minimumWhaleBid/ (1e18 wei), "Minimum bid amount required");
        _;
    }
    
    modifier highestBidRequired() {
        require(msg.value > _highestBid, "Highest bidder amount required");
        _;
    }
    
    modifier sameBidder() {
        require(msg.sender == _whaleHighestBidder, "Only the same bidder can add to amount");
        _;   
    }
    
    modifier nonWhaleReentrant() {
        require(_userWhaleReentrancy[msg.sender] != ENTERED, "ReentrancyGuard: reentrant call");
        _userWhaleReentrancy[msg.sender] = ENTERED;
        _;
        _userWhaleReentrancy[msg.sender] = NOT_ENTERED;
    }

    constructor(
        address payable whaleBeneficiary,
        uint minimumWhaleBid,
        address whaleWeightingContract,
        uint256 whaleIncrement,
        uint256 whaleReturnFee
    )
    {
        _whaleBeneficiary = whaleBeneficiary;
        _minimumWhaleBid = minimumWhaleBid;
        _whaleWeightingContract = whaleWeightingContract;
        wcon = Weighting(payable(_whaleWeightingContract));
        
         _whaleIncrement = whaleIncrement; //1 matic;
        _whaleReturnFee = whaleReturnFee; //0.01 matic;
    }
    
    function whalesBid()
        public
        payable
        beforeWhaleAuction(wcon.getAuctionEndTime())
        notWhaleOwner()
        lowestWhaleBidMinimum()
        highestBidRequired()
        whaleMultipleETH()
        nonWhaleReentrant()
    {
        _whalesBid();
    }
   
    function _whalesBid()
        internal
    {
        if (_highestBid != 0) {
            _pendingReturns[_whaleHighestBidder] = _pendingReturns[_whaleHighestBidder] + _highestBid;
            uint amount = _pendingReturns[_whaleHighestBidder];
            if (amount > 0) {
                _pendingReturns[_whaleHighestBidder] = 0;
                if (!payable(_whaleHighestBidder).send(amount)) {
                    _pendingReturns[_whaleHighestBidder] = amount;
                }
            }
        }
        
        _whaleHighestBidder = msg.sender;
        _highestBid = msg.value;
        
        uint timeLeft = wcon.getAuctionEndTime() - block.timestamp;
        if(timeLeft <= 15 minutes){
            wcon.setAuctionEndTime();
        }
        _whaleLastBidTime = block.timestamp;
    }
    
    function addToWhalesBid()
        public
        payable
        beforeWhaleAuction(wcon.getAuctionEndTime())
        notWhaleOwner()
        sameBidder()
        whaleMultipleETH()
        nonWhaleReentrant()
    {
        _addToBid();
    }
    
    function _addToBid()
        internal
    {
        if(msg.value > 0 && _highestBid > 0){
            _highestBid = _highestBid + msg.value;
            _whaleLastBidTime = block.timestamp;
        }
    }

    function _returnWhaleFunds() 
        external
        payable
        isWhaleWeighting()
        afterWhaleAuction(wcon.getAuctionEndTime())
    {
        if (_highestBid > 0) {
            uint amount =  address(this).balance - _whaleReturnFee;
            payable(_whaleHighestBidder).transfer(amount);
        }
    }
    
    function transferWhaleOwnership(address payable newWhaleBeneficiary)
        public
        onlyWhaleOwner(msg.sender)
        beforeWhaleAuction(wcon.getAuctionEndTime())
        cantBeFutureOwner(newWhaleBeneficiary)
    {
        _transferWhaleOwnership(newWhaleBeneficiary);
    }
   
    function _transferWhaleOwnership(address payable newWhaleBeneficiary)
        internal
    {
        require(newWhaleBeneficiary != address(0));
        _whaleBeneficiary = newWhaleBeneficiary;  
    }
    
        
    function transferWhaleOwnershipToZero()
        public
        onlyWhaleOwner(msg.sender)
        beforeWhaleAuction(wcon.getAuctionEndTime())
    {
        _transferWhaleOwnershipToZero();
    }
   
    function _transferWhaleOwnershipToZero()
        internal
    {
        _whaleBeneficiary = payable(address(0));  
    }
    
    function whalesTransfer(address recipient, uint256 amount)
        public 
        onlyWhaleOwner(msg.sender)
        afterWhaleAuction(wcon.getAuctionEndTime())
        returns (bool) 
    {
        _whalesTransfer(msg.sender, recipient, amount);
        return true;
    }
    
    function _whalesTransfer(address sender, address recipient, uint256 amount) 
        internal
        virtual 
    {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        uint256 senderBalance = address(this).balance;
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        
        if(recipient == _whaleHighestBidder){
            _highestBid = _highestBid - amount;
            if(_highestBid == 0){
                _whaleHighestBidder = address(0);
            }
        }
        payable(recipient).transfer(amount);
    }
    
    function whalesWithdrawERC20ContractTokens(IERC20 tokenAddress, address recipient)
        public
        onlyWhaleOwner(msg.sender)
        returns(bool)
    {
        require(msg.sender != address(0), "Sender is address zero");
        require(recipient != address(0), "Receiver is address zero");
        tokenAddress.approve(address(this), tokenAddress.balanceOf(address(this)));
        if(!tokenAddress.transferFrom(address(this), recipient, tokenAddress.balanceOf(address(this)))){
            return false;
        }
        return true;
    }
    
    function resetWhaleReentrancy(address user) 
        public
        onlyWhaleOwner(msg.sender)
    {
        _userWhaleReentrancy[user] = NOT_ENTERED;
    }
    
    function getPendingReturns(address user) 
        public
        view
        onlyWhaleOwner(msg.sender)
        returns (uint256) 
    {
        return _pendingReturns[user];
    }
    
    function getWhaleReturnFee() 
        public
        view
        returns (uint256) 
    {
        return _whaleReturnFee;
    }
    
    function getWhaleReentrancyStatus(address user) 
        public
        view
        onlyWhaleOwner(msg.sender)
        returns (bool) 
    {
        return _userWhaleReentrancy[user];
    }

    function getWhaleBeneficiary() 
        public
        view
        returns (address) 
    {
        return _whaleBeneficiary;
    }
    
    function getHighestBidder() 
        public
        view
        returns (address) 
    {
        return _whaleHighestBidder;
    }
    
    function getWhaleAuctionEndTime() 
        public
        view
        returns (uint)
    {
        return wcon.getAuctionEndTime();
    }

    function getWhaleWeightingContractAddress() 
        public
        view
        returns (address) 
    {
        return address(wcon);
    }
    
    function getWhaleLastBidTime()
        public
        view
        returns (uint)
    {
        return _whaleLastBidTime;
    }
    
    function getHighestBid() 
        public
        view
        returns (uint) 
    {
        return _highestBid;
    }
    
    function getWhaleIncrement() 
        public
        view
        returns (uint) 
    {
        return _whaleIncrement;
    }
    
    function getMinimumWhaleBid() 
        public
        view
        returns (uint)
    {
        return _minimumWhaleBid;
    }

    function getWhaleContractAddress() 
        public
        view
        returns (address)
    {
        return address(this);
    }
    
    function getWhaleContractBalance() 
        public
        view
        returns (uint) 
    {
        return address(this).balance;
    }
    
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.6;

import "./Whales.sol";
import "./Shrimps.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Weighting {
    
    address payable internal _weightingBeneficiary;
    address internal _highestWhaleBidder;
    address internal _winnerContract;
    address internal _shrimpsContractAddress;
    address internal _whalesContractAddress;
    uint internal _highestWhaleBid;
    uint internal _highestShrimpBid;
    uint internal _whaleBidTime;
    uint internal _shrimpBidTime;
    uint internal _auctionEndTime;  
    uint internal _paintingMinimalPricing;
    uint internal _weightingWinner;
    uint internal _weightingWinnerMidAuction;
    bool internal _whaleWinnerCheck;
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    receive() external payable {}
    fallback() external payable {}

    modifier onlyOwner() {
        require(msg.sender == _weightingBeneficiary, "Only the owner can use this function");
        _;
    }
    
    modifier afterAuction() {
        require(block.timestamp >= _auctionEndTime, "Auction time is incorrect");
        _;
    }
    
    modifier beforeAuction() {
        require(block.timestamp < _auctionEndTime, "Auction time is incorrect");
        _;
    }
    modifier onlyShrimpsOrWhales() {
        require(msg.sender == _whalesContractAddress || msg.sender == _shrimpsContractAddress, "Not shrimps or whales contract calling");
        _;
    }
    
   
    constructor(
        address payable weightingBeneficiary,
        uint paintingMinimalPricing,
        uint auctionEndTime
    )
    {
        _weightingBeneficiary = weightingBeneficiary;
        _paintingMinimalPricing = paintingMinimalPricing;
        _auctionEndTime = auctionEndTime;
        
        _weightingWinner = 0;
        _weightingWinnerMidAuction = 0;
        _whaleWinnerCheck = false;
    }
   
    function returnWhaleFunds(Whales whalesContract) 
        public
        payable
        onlyOwner()
        afterAuction()
    {
        whalesContract._returnWhaleFunds();
    }
    
    function returnShrimpFunds(Shrimps shrimpContract) 
        public
        payable
        onlyOwner()
        afterAuction()
    {
        shrimpContract._returnShrimpFunds();
    }
    
    function determineWinner(Whales whalesContract, Shrimps shrimpContract)
        public
        onlyOwner()
        afterAuction()
        returns(uint)
    {
        _highestWhaleBid = whalesContract.getHighestBid();
        _highestShrimpBid = shrimpContract.getTotalBid();
        
        _whaleBidTime = whalesContract.getWhaleLastBidTime();
        _shrimpBidTime = shrimpContract.getShrimpLastBidTime();
    
        if(_highestShrimpBid < _paintingMinimalPricing && _highestWhaleBid < _paintingMinimalPricing){
            _weightingWinner = 3;
            return(_weightingWinner);
        }else{
            if(_highestWhaleBid > _highestShrimpBid){
                _weightingWinner = 1;
                _winnerContract = address(whalesContract);
            }else if (_highestWhaleBid < _highestShrimpBid){
                _weightingWinner = 2;
                _winnerContract = address(shrimpContract);
            }else{
                if(_whaleBidTime < _shrimpBidTime){
                    _weightingWinner = 1;
                    _winnerContract = address(whalesContract);
                }else{
                    _weightingWinner = 2;
                    _winnerContract = address(shrimpContract);
                }
            }
        }

        return(_weightingWinner);
    }
    
    function determineWinnerMidAuction(Whales whalesContract, Shrimps shrimpContract)
        public
        returns(uint, uint)
    {
        uint _highestWinnerBidMidAuction;
        _highestWhaleBid = whalesContract.getHighestBid();
        _highestShrimpBid = shrimpContract.getTotalBid();
        
        _whaleBidTime = whalesContract.getWhaleLastBidTime();
        _shrimpBidTime = shrimpContract.getShrimpLastBidTime();
        
        if(_highestWhaleBid > _highestShrimpBid){
            _weightingWinnerMidAuction = 1;
            _highestWinnerBidMidAuction = _highestWhaleBid;
        }else if (_highestWhaleBid < _highestShrimpBid){
            _weightingWinnerMidAuction = 2;
            _highestWinnerBidMidAuction = _highestShrimpBid;
        }else{
            if(_whaleBidTime < _shrimpBidTime){
                _weightingWinnerMidAuction = 1;
                _highestWinnerBidMidAuction = _highestWhaleBid;
            }else{
                _weightingWinnerMidAuction = 2;
                _highestWinnerBidMidAuction = _highestShrimpBid;
            }
        }
        return(_weightingWinnerMidAuction, _highestWinnerBidMidAuction);
    }
    
    function weightingTransfer(address recipient, uint256 amount)
        public 
        onlyOwner()
        afterAuction()
        returns (bool) 
    {
        _weightingTransfer(msg.sender, recipient, amount);
        return true;
    }
    
    function _weightingTransfer(address sender, address recipient, uint256 amount) 
        internal
        virtual 
    {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        uint256 senderBalance = address(this).balance;
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        payable(recipient).transfer(amount);
    }
    
    function weightingWithdrawERC20ContractTokens(IERC20 tokenAddress, address recipient)
        public
        onlyOwner()
        returns(bool)
    {
        require(msg.sender != address(0), "Sender is address zero");
        require(recipient != address(0), "Receiver is address zero");
        tokenAddress.approve(address(this), tokenAddress.balanceOf(address(this)));
        if(!tokenAddress.transferFrom(address(this), recipient, tokenAddress.balanceOf(address(this)))){
            return false;
        }
        return true;
    }

    function transferWeightingOwnership(address payable newWeightingBeneficiary)
        public
        onlyOwner()
        beforeAuction()
    {
        _transferWeightingOwnership(newWeightingBeneficiary);
    }
   
    function _transferWeightingOwnership(address payable newWeightingBeneficiary)
        internal
    {
        require(newWeightingBeneficiary != address(0));
        _weightingBeneficiary = newWeightingBeneficiary;  
    }
    
        
    function transferWeightingOwnershipToZero()
        public
        onlyOwner()
        beforeAuction()
    {
        _transferWeightingOwnershipToZero();
    }
   
    function _transferWeightingOwnershipToZero()
        internal
    {
        _weightingBeneficiary = payable(address(0));  
    }
    
    function setAuctionEndTime() 
        external
        onlyShrimpsOrWhales()
    {
        _auctionEndTime = block.timestamp + 15 minutes;
    }
    
    function setPaintingMinimalPricing(uint newPrice) 
        public
        onlyOwner()
    {
        _paintingMinimalPricing = newPrice;
    }
    
    function setAuctionEndTimeManual(uint256 newtime) 
        public
        onlyOwner()
    {
        _auctionEndTime = newtime;
    }

    function confirmWhaleWinner()
        public
        afterAuction()
    {
        require(msg.sender == _highestWhaleBidder, "False winner interaction");
        _whaleWinnerCheck = true;
    }
    
    function setWhalesContract(address whalesContractAddress) 
        public
        onlyOwner()
    {
        _whalesContractAddress = whalesContractAddress;
    }
    
    function setShrimpsContract(address shrimpsContractAddress) 
        public
        onlyOwner()
    {
        _shrimpsContractAddress = shrimpsContractAddress;
    }

    function _passWinner()
        external
        view
        afterAuction()
        returns(uint)
    {
        return (_weightingWinner);
    }
    
    function getWhaleData(Whales whalesContract)
        public
        onlyOwner()
        returns (address, uint)
    {
        _highestWhaleBidder = whalesContract.getHighestBidder();
        _highestWhaleBid = whalesContract.getHighestBid();
        return (_highestWhaleBidder, _highestWhaleBid);
    }
    
    function getShrimpData(Shrimps shrimpContract)
        public
        onlyOwner()
        returns (uint)
    {
        _highestShrimpBid = shrimpContract.getTotalBid();
        return (_highestShrimpBid);
    }
    
    function getBeneficiary() 
        public
        view
        returns (address)
    {
        return _weightingBeneficiary;
    }
    
    function getHighestWhaleBidder() 
        public
        view
        returns (address) 
    {
        return _highestWhaleBidder;
    }
    
    function getWinnerContract() 
        public
        view
        returns (address)
    {
        return _winnerContract;
    }
    
    function getHighestWhaleBid() 
        public
        view
        returns (uint) 
    {
        return _highestWhaleBid;
    }
    
    function getHighestShrimpBid() 
        public
        view
        returns (uint) 
    {
        return _highestShrimpBid;
    }
    
    function getAuctionEndTime() 
        public
        view
        returns (uint) 
    {
        return _auctionEndTime;
    }
    
    function whaleWinnerContractInteraction() 
        public
        afterAuction()
        view
        returns (bool) 
    {
        return _whaleWinnerCheck;
    }
 
    function getWeightingContractAddress() 
        public
        view
        returns (address) 
    {
        return address(this);
    }
    
    function getShrimpsContractAddress() 
        public
        view
        returns (address) 
    {
        return _shrimpsContractAddress;
    }
    
    function getWhalesContractAddress() 
        public
        view
        returns (address) 
    {
        return _whalesContractAddress;
    }
    
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.6;

import "./Weighting.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Shrimps {

    address payable internal _shrimpBeneficiary;
    address internal _shrimpWeightingContract;
    uint internal _totalBid;
    uint internal _maximumShrimpBid;
    uint internal _minimumShrimpBid;
    uint internal _shrimpLastBidTime;
    uint internal _shrimpIncrement;
    uint internal _shrimpReturnFee;
    uint internal _firstDistributionCount;
    uint internal _lastDistributionCount;
    address[] internal shrimpAddresses;   
    bool internal _returnedAllFunds;
    bool private constant NOT_ENTERED = false;
    bool private constant ENTERED = true;
    Weighting scon;
    
    mapping(address => uint) internal _shrimpArray;
    mapping(address => bool) internal _shrimpBid;
    mapping(address => bool) internal _userShrimpReentrancy;
    
    receive() external payable {}
    fallback() external payable {}
    
    modifier shrimpMultipleETH(){
      require(msg.value % _shrimpIncrement * 10**18 == 0, "Only 0,1 ETH multiples are accepted"); //0.1 matic
       _;
    }
   
    modifier beforeShrimpAuction(uint _time) {
        require(block.timestamp < _time, "Shrimp auction has ended");
        _;
    }
    
    modifier afterShrimpAuction(uint _time) {
        require(block.timestamp >= _time, "Shrimp auction did not end yet");
        _;
    }
    
    modifier notShrimpOwner() {
        require(msg.sender != _shrimpBeneficiary, "Contract owner can not interract here");
        _;
    }
    
    modifier onlyShrimpOwner(address messageSender) {
        require(_shrimpBeneficiary == messageSender, "Only the owner can use this function");
        _;
    }
    
    modifier isShrimpWeighting() {
        require(address(_shrimpWeightingContract) == msg.sender, "Wrong contract passed. Contract is not Weighting");
        _;
    }
    
    modifier highestBidMaximum() {
        require(msg.value <= _maximumShrimpBid, "Bid must be less than the set maximum bid");
        require((_shrimpArray[msg.sender] + msg.value) <= _maximumShrimpBid, "Bid must be less than the set maximum bid");
        _;
    }
    
    modifier lowestShrimpBidMinimum() {
        require(msg.value >= _minimumShrimpBid/ (1e18 wei), "Minimum bid amount required");
        _;
    }
    
    modifier returnedAllFunds() {
        require(false == _returnedAllFunds, "Funds have been returned to all users");
        _;
    }
    
    modifier nonShrimpReentrant() {
        require(_userShrimpReentrancy[msg.sender] != ENTERED, "ReentrancyGuard: reentrant call");
        _userShrimpReentrancy[msg.sender] = ENTERED;
        _;
        _userShrimpReentrancy[msg.sender] = NOT_ENTERED;
    }

    constructor(
        address payable shrimpBeneficiary,
        uint maximumShrimpBid,
        uint minimumShrimpBid,
        address shrimpWeightingContract,
        uint256 shrimpIncrement,
        uint256 shrimpReturnFee
    )
    {
        _shrimpBeneficiary = shrimpBeneficiary;
        _maximumShrimpBid = maximumShrimpBid;
        _minimumShrimpBid = minimumShrimpBid;
        _shrimpWeightingContract = shrimpWeightingContract;
        scon = Weighting(payable(_shrimpWeightingContract));
        _shrimpIncrement = shrimpIncrement; //0.1 matic;
        _shrimpReturnFee = shrimpReturnFee; //0.001 matic;
        _firstDistributionCount = 0;
        _lastDistributionCount = 100;
        _returnedAllFunds = false;
    }
    
    function shrimpsBid()
        public
        payable
        beforeShrimpAuction(scon.getAuctionEndTime())
        notShrimpOwner()
        highestBidMaximum()
        lowestShrimpBidMinimum()
        shrimpMultipleETH()
        nonShrimpReentrant()
    {
        _shrimpsBid();
    }
   
    function _shrimpsBid()
        internal
    {
        uint amount = msg.value;
        
        if(amount > 0){
            _shrimpArray[msg.sender] = _shrimpArray[msg.sender] + amount;
            if(_shrimpBid[msg.sender] == false){
                _shrimpBid[msg.sender] = true;
                shrimpAddresses.push(msg.sender);
            }
            _totalBid = _totalBid + amount;
            _shrimpLastBidTime = block.timestamp;
            
            uint timeLeft = scon.getAuctionEndTime() - block.timestamp;
            if(timeLeft <= 15 minutes){
                scon.setAuctionEndTime();
            }
        }
    }

    function _returnShrimpFunds()
        external
        payable
        isShrimpWeighting()
        returnedAllFunds()
        afterShrimpAuction(scon.getAuctionEndTime())
    {
        if (_lastDistributionCount > shrimpAddresses.length) {
            _lastDistributionCount = shrimpAddresses.length;
        }
        for (uint j = _firstDistributionCount; j < _lastDistributionCount; j++) {
            if(_shrimpArray[shrimpAddresses[j]] > 0){
                uint amount = _shrimpArray[shrimpAddresses[j]] - _shrimpReturnFee;
                if(payable(shrimpAddresses[j]).send(amount)){
                    _shrimpArray[shrimpAddresses[j]] = 0;
                }
            }
        }
        _firstDistributionCount = _lastDistributionCount;
        _lastDistributionCount += 100;
        if (_firstDistributionCount >= shrimpAddresses.length) {
            _returnedAllFunds = true;
        }
    }
    
    function transferShrimpOwnership(address payable newShrimpBeneficiary)
        public
        onlyShrimpOwner(msg.sender)
        beforeShrimpAuction(scon.getAuctionEndTime())
    {
        _transferShrimpOwnership(newShrimpBeneficiary);
    }
   
    function _transferShrimpOwnership(address payable newShrimpBeneficiary)
        internal
    {
        require(newShrimpBeneficiary != address(0));
        _shrimpBeneficiary = newShrimpBeneficiary;  
    }
    
    function transferShrimpOwnershipToZero()
        public
        onlyShrimpOwner(msg.sender)
        beforeShrimpAuction(scon.getAuctionEndTime())
    {
        _transferShrimpOwnershipToZero();
    }
   
    function _transferShrimpOwnershipToZero()
        internal
    {
        _shrimpBeneficiary = payable(address(0));  
    }
    
    function shrimpsTransfer(address recipient, uint256 amount)
        public 
        onlyShrimpOwner(msg.sender)
        afterShrimpAuction(scon.getAuctionEndTime())
        returns (bool) 
    {   
        _shrimpsTransfer(msg.sender, recipient, amount);
        return true;
    }
    
    function _shrimpsTransfer(address sender, address recipient, uint256 amount) 
        internal
        virtual 
    {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        uint256 senderBalance = address(this).balance;
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        if(_shrimpBid[recipient] == true){
            _shrimpArray[recipient] = _shrimpArray[recipient] - amount;
            _totalBid = _totalBid - amount;
            if(_shrimpArray[recipient] == 0){
                delete _shrimpArray[recipient];
            }
        }
        payable(recipient).transfer(amount);
    }
    
    function shrimpsWithdrawERC20ContractTokens(IERC20 tokenAddress, address recipient)
        public
        onlyShrimpOwner(msg.sender)
        returns(bool)
    {
        require(msg.sender != address(0), "Sender is address zero");
        require(recipient != address(0), "Receiver is address zero");
        tokenAddress.approve(address(this), tokenAddress.balanceOf(address(this)));
        if(!tokenAddress.transferFrom(address(this), recipient, tokenAddress.balanceOf(address(this)))){
            return false;
        }
        return true;
    }
    
    function resetShrimpReentrancy(address user) 
        public
        onlyShrimpOwner(msg.sender)
    {
        _userShrimpReentrancy[user] = NOT_ENTERED;
    }

    function getShrimpBeneficiary() 
        public
        view
        returns (address)
    {
        return _shrimpBeneficiary;
    }
    
    function getShrimpAuctionEndTime() 
        public
        view
        returns (uint) 
    {
        return scon.getAuctionEndTime();
    }
    
    function getTotalBid() 
        public
        view
        returns (uint)
    {
        return _totalBid;
    }
    
    function getShrimpReturnFee() 
        public
        view
        returns (uint256) 
    {
        return _shrimpReturnFee;
    }
    
    function getMaximumShrimpBid() 
        public
        view
        returns (uint) 
    {
        return _maximumShrimpBid;
    }
    
    function getMinimumShrimpBid() 
        public
        view
        returns (uint) 
    {
        return _minimumShrimpBid;
    }
    
    function checkIfShrimpExists(address shrimp) 
        public
        view
        returns (bool)
    {
        if(_shrimpBid[shrimp] == true){
            return true;
        }
        return false;
    }
    
    function getShrimpBid(address shrimpAddress) 
        public
        view
        returns (uint) 
    {
        return _shrimpArray[shrimpAddress];
    }
    
    function getShrimpReentrancyStatus(address user) 
        public
        view
        onlyShrimpOwner(msg.sender)
        returns (bool) 
    {
        return _userShrimpReentrancy[user];
    }
    
    function getTotalAmountOfShrimps() 
        public
        view
        returns (uint) 
    {
        return shrimpAddresses.length;
    }

    function getShrimpWeightingContractAddress() 
        public
        view
        returns (address) 
    {
        return address(scon);
    }
    
    function getShrimpLastBidTime()
        public
        view
        returns (uint)
    {
        return _shrimpLastBidTime;
    }
    
    function getShrimpIncrement() 
        public
        view
        returns (uint) 
    {
        return _shrimpIncrement;
    }
    
    function getShrimpAddress(uint id) 
        public
        view
        returns (address)
    {
        return shrimpAddresses[id];
    }
    
    function getShrimpContractAddress() 
        public
        view
        returns (address)
    {
        return address(this);
    }
    
    function getShrimpContractBalance() 
        public
        view
        returns (uint) 
    {
        return address(this).balance;
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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