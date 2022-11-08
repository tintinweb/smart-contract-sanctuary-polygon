/**
 *Submitted for verification at polygonscan.com on 2022-11-07
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
    uint256 ticketPrice;
    uint256 maxTickets;

    Pool [] public pools;
    mapping (uint256 => address[]) public poolParticipants;
    uint256 [] public winnerRewards;


    event PoolCreated(address indexed ticketToken, uint256 ticketPrice, uint256 maxTickets);

    constructor () {
        ticketToken = 0xA806DD99274E778f0e0d6115B8d7f7A586637B9C;
        ticketPrice = 1 * 10 ** 18;
        maxTickets = 10;

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
        for (i; i>=0 && winnerNumber < winnerRewards.length; i--){
            uint256 winnerIndex = random(i);
            address winner = poolParticipants[_poolId][winnerIndex];
            IERC20(pool.ticketToken).transfer(winner, ((pool.ticketPrice * pool.maxTickets * winnerRewards[winnerNumber])/100));
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