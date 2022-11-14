/**
 *Submitted for verification at polygonscan.com on 2022-11-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract Lottery is Ownable{

    struct Pool {
        address ticketToken;
        uint256 ticketPrice;
        uint256 maxTickets;
    }

    address ticketToken;
    address public royaltyAddress;
    uint256 ticketPrice;
    uint256 maxTickets;
    uint256 public royaltyPercent;

    Pool [] public pools;
    mapping (uint256 => address[]) public poolParticipants;
    mapping (uint256 => address[]) public poolWinners;
    mapping (address => mapping (uint256 => uint256)) public poolWinnersAmounts;
    mapping (address => mapping (uint256 => uint256)) public userTicketsCount;
    uint256 [] public winnerRewards;


    event PoolCreated(address indexed ticketToken, uint256 ticketPrice, uint256 maxTickets);

    constructor () {
        ticketToken = 0x9aD8b29Ee8afdEE10DB983b50504d51d8609Ae80;
        royaltyAddress = 0x33FAb482631484ce61360e239A6dCd1446D2931d;
        royaltyPercent = 10;
        ticketPrice = 1 * 10 ** 18;
        maxTickets = 10;
        winnerRewards= [30, 20, 10, 5, 5, 5, 5, 5, 5];

        createPool(ticketToken, ticketPrice, maxTickets);
    }

    function createPool(address _ticketToken, uint256 _ticketPrice, uint256 _maxTickets) internal {
        pools.push(Pool(_ticketToken, _ticketPrice, _maxTickets));
        emit PoolCreated(_ticketToken, _ticketPrice, _maxTickets);
    }

    function buyTicket(uint256 _numberOfTickets) public {
        uint256 _poolId = pools.length - 1;
        Pool memory pool = pools[_poolId];
        require(poolParticipants[_poolId].length + _numberOfTickets <= pool.maxTickets, "Number of tickets exceeds max tickets for this pool");
        userTicketsCount[msg.sender][_poolId] += _numberOfTickets;
        IERC20(pool.ticketToken).transferFrom(msg.sender, address(this), (pool.ticketPrice * _numberOfTickets));
        for (uint256 i = 0; i < _numberOfTickets; i++) {
            poolParticipants[_poolId].push(msg.sender);
        }

        if (poolParticipants[_poolId].length == pool.maxTickets){
            drawWinner();
            createPool(ticketToken, ticketPrice, maxTickets);
        }
    }

    function drawWinner() public {
        uint256 _poolId = pools.length - 1;
        Pool memory pool = pools[_poolId];
        require(poolParticipants[_poolId].length == pool.maxTickets, "Pool is not full");
        uint256 i = poolParticipants[_poolId].length;
        uint256 winnerNumber = 0;
        
        // clear winners list
        delete poolWinners[_poolId];

        // give royalty
        uint256 _lotteryAmount = (pool.ticketPrice * pool.maxTickets);
        uint256 royaltyAmount = (_lotteryAmount * royaltyPercent) / 100;
        IERC20(pool.ticketToken).transfer(royaltyAddress, royaltyAmount);

        for (i; i>=0 && winnerNumber < winnerRewards.length; i--){
            uint256 winnerIndex = random(i);
            address winner = poolParticipants[_poolId][winnerIndex];
            poolWinners[_poolId].push(winner);
            poolWinnersAmounts[winner][_poolId] += winnerRewards[winnerNumber];
            IERC20(pool.ticketToken).transfer(winner, ((_lotteryAmount * winnerRewards[winnerNumber])/100));
            winnerNumber +=1;
        }
    }

    function random(uint256 _max) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, msg.sender, _max))) % _max;
    }

    // onlyOwner functions below

    function setTicketToken(address _ticketToken) public onlyOwner {
        ticketToken = _ticketToken;
    }

    function setTicketPrice(uint256 _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice;
    }

    function setMaxTickets(uint256 _maxTickets) public onlyOwner {
        maxTickets = _maxTickets;
    }

    function setWinnerRewards(uint256 [] memory _winnerRewards) public onlyOwner {
        winnerRewards = _winnerRewards;

        uint256 totalRewards = 0;
        for (uint256 i=0; i<_winnerRewards.length; i++){
            require(_winnerRewards[i] > 0, "Winner rewards must be greater than 0");
            totalRewards += _winnerRewards[i];
        }
        require(totalRewards <= 100, "Total rewards must be less than or equal to 100");
    }

    function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setRoyaltyPercent(uint256 _royaltyPercent) public onlyOwner {
        royaltyPercent = _royaltyPercent;
    }

    // Get functions

    function getCurrentPoolSize () view public returns (uint256) {
        uint256 _poolId = pools.length - 1;
        return poolParticipants[_poolId].length;
    }

    function getPoolSize () view public returns (uint256) {
        uint256 _poolId = pools.length - 1;
        return poolParticipants[_poolId].length;
    }

    function getPoolTicketPrice () view public returns (uint256) {
        uint256 _poolId = pools.length - 1;
        return pools[_poolId].ticketPrice;
    }

    function getPoolMaxTickets () view public returns (uint256) {
        uint256 _poolId = pools.length - 1;
        return pools[_poolId].maxTickets;
    }

    function getPoolTicketToken () view public returns (address) {
        uint256 _poolId = pools.length - 1;
        return pools[_poolId].ticketToken;
    }

    function getAnyPoolWinners (uint256 _poolId) view public returns (address[] memory) {
        return poolWinners[_poolId];
    }

    function getPoolWinners () view public returns (address[] memory) {
        uint256 _poolId = pools.length - 1;
        return poolWinners[_poolId];
    }

    function getCurrentPoolIndex () view public returns (uint256) {
        return pools.length - 1;
    }

    function getUserTicketCount (address _user) view public returns (uint256) {
        uint256 _poolId = pools.length - 1;
        return userTicketsCount[_user][_poolId];
    }

    function getPoolWinningAmount (address _user) view public returns (uint256) {
        uint256 _poolId = pools.length - 1;
        return poolWinnersAmounts[_user][_poolId];
    }

    // Emergency functions

    // this function is to withdraw BNB sent to this address by mistake
    function withdrawEth () external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: balance
        }("");
        return success;
    }

    // this function is to withdraw BEP20 tokens sent to this address by mistake
    function withdrawBEP20 (address _tokenAddress) external onlyOwner returns (bool) {
        IERC20 _token = IERC20 (_tokenAddress);
        uint256 balance = _token.balanceOf(address(this));
        bool success = _token.transfer(msg.sender, balance);
        return success;
    }
    
}