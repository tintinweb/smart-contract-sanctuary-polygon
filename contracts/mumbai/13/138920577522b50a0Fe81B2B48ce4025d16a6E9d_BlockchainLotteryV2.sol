/**
 *Submitted for verification at polygonscan.com on 2022-08-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: BlockchainV2.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BlockchainLotteryV2{
    address USDTAddress = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; //USDT ADDRESS POLYGON
    uint randNonce = 0;
    mapping(address=>uint[]) public ownerAndPoolId;
    mapping(uint=>address) public poolidAndOwner;
    mapping(uint=>uint) public poolidAndAmount;
    struct Pool{
        uint fees;
        uint amount;
        address owner;
        address[] participants;
        uint[] tickets;
        mapping(address=>uint) participantAndTicket;
        mapping(uint=>address) ticketAndParticipant;
        bool isOn;
    }
    Pool[] Pools;
    event WinnerEvent(uint PoolId, uint WinnerTicket, address WinnerAddress);
    modifier onlyPoolOwner(uint _poolid){
        require(Pools[_poolid].owner==msg.sender,"You don't own this Pool");
        _;
    }
    function updateUSDTAddress(address _address) public {
        USDTAddress = _address;
    }
    function createPool(uint _fees, uint _amount) public {
        Pool storage p = Pools.push();
        p.isOn = true;
        p.owner = msg.sender;
        p.amount = _amount;
        p.fees = _fees;
        ownerAndPoolId[msg.sender].push(Pools.length-1);
        poolidAndOwner[Pools.length-1] = msg.sender;
    }
    function addUsdt(uint _poolid, uint _amount) public {
        require(Pools[_poolid].isOn,"Deposites is over");
        require(_amount==Pools[_poolid].amount,"Please add specified amount");
        Pools[_poolid].participants.push(msg.sender);
        IERC20(USDTAddress).transferFrom(msg.sender,address(this),_amount);
        poolidAndAmount[_poolid]+=_amount;
    }
    function assignTickets(uint _poolid) public onlyPoolOwner(_poolid){
        require(Pools[_poolid].isOn,"The Tickets are already assigned");
        for(uint i=0;i<Pools[_poolid].participants.length;i++){
            uint _ticket = ticketGenerator();
            Pools[_poolid].tickets.push(_ticket);
            Pools[_poolid].ticketAndParticipant[_ticket]=Pools[_poolid].participants[i];
            Pools[_poolid].participantAndTicket[Pools[_poolid].participants[i]]=_ticket;
            randNonce++;
        }
        Pools[_poolid].isOn = false;
    }

    function openLottery(uint _poolid) public onlyPoolOwner(_poolid){
        require(Pools[_poolid].isOn==false,"Tickets are not assigned");
        uint[] memory shuffledTickets = shuffleTickets(Pools[_poolid].tickets);
        uint winner = winGenerator(shuffledTickets.length);
        address Winner = Pools[_poolid].ticketAndParticipant[shuffledTickets[winner]];
        IERC20(USDTAddress).transfer(Winner,poolidAndAmount[_poolid]);
        emit WinnerEvent(_poolid,shuffledTickets[winner],Winner);
        poolidAndAmount[_poolid]=0;
        while(Pools[_poolid].participants.length>0){
            Pools[_poolid].participants.pop();
        }
        while(Pools[_poolid].tickets.length>0){
            Pools[_poolid].tickets.pop();
        }
        Pools[_poolid].isOn=true;
    }


    function getAllPoolByAddress(address _addr) public view returns(uint[] memory){
        return ownerAndPoolId[_addr];
    }
    function getNumberOfAllPools() public view returns(uint) {
        return Pools.length;
    }
    function getCurrentPricePool() public view returns(uint) {
        return IERC20(USDTAddress).balanceOf(address(this));
    }
    function getPoolFees(uint _poolid) public view returns(uint){
        return Pools[_poolid].fees;
    }
    function getPoolAmount(uint _poolid) public view returns(uint){
        return Pools[_poolid].amount;
    }
    function getPoolOwner(uint _poolid) public view returns(address) {
        return Pools[_poolid].owner;
    }
    function getAllParticipants(uint _poolid) public view returns(address[] memory){
        return Pools[_poolid].participants;
    }
    function getAllTickets(uint _poolid) public view returns(uint[] memory){
        return Pools[_poolid].tickets;
    }


    
    // Randomizers
    function winGenerator(uint _ticketLen) public view returns(uint) {
        uint ticket = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _ticketLen;
        return ticket;
    }
    function ticketGenerator() public view returns(uint) {
        uint _modulus = 10000000000;
        uint ticket = uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
        return ticket;
    }
    function shuffleTickets(uint[] memory _myArray) public view returns(uint[] memory){
        uint a = _myArray.length; 
        uint b = _myArray.length;
        for(uint i = 0; i< b ; i++){
            uint randNumber =(uint(keccak256
            (abi.encodePacked(block.timestamp,_myArray[i]))) % a)+1;
            uint interim = _myArray[randNumber - 1];
            _myArray[randNumber-1]= _myArray[a-1];
            _myArray[a-1] = interim;
            a = a-1;
        }
        uint256[] memory result;
        result = _myArray;       
        return result;        
    }
}