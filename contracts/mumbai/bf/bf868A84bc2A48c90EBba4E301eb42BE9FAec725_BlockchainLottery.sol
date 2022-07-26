/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

//SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: BlockchainLottery.sol


pragma solidity ^0.8.0;



contract BlockchainLottery is Ownable{
    address[] participants;
    address public lastWinner;
    uint public fee = 500000;
    uint public lotteryTime;
    uint public lotteryTimeDuration = 3 minutes;
    uint randNonce=2;
    uint public amount = 10e6;
    uint lotteryNumberCounter=0;
    address feeAccount;
    mapping(address=>uint) amountOfParticipants;
    address public USDTAddress = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; //USDT Address on Polygon
    event Winner(address,uint);
    event DepositeAmountEvent(address);
    constructor(){
        lotteryTime=block.timestamp+lotteryTimeDuration;
    }
    function updateUSDTAddress(address _newAddress) public onlyOwner{
        require(_newAddress!=USDTAddress,"NEW ADDRESS CAN NOT BE OLD ONE");
        USDTAddress = _newAddress;
    }
    function getParticipants(uint _id) view public onlyOwner returns(address){
        return participants[_id];
    }
    function updateFee(uint _fee) public onlyOwner{
        require(_fee<amount,"Fee should be less then amount");
        fee = _fee;
    }
    function setDepositeAmount(uint _amount) public onlyOwner{
        amount = _amount;
    }
    function setLotteryTime(uint _timeDuration) public onlyOwner {
        lotteryTimeDuration = _timeDuration;
        lotteryTime=block.timestamp + lotteryTimeDuration;
    }
    function setRandNounce(uint _num) public onlyOwner {
        randNonce=_num;
    }
    function setFeeAccount(address _account) public onlyOwner {
        feeAccount = _account;
    }

    function getAllParticipants() view public returns(address[] memory){
        return participants;
    }
    function depositeUSDT(uint _amount) public {
        require(_amount==amount,"Please enter the specified amount of USDT");
        IERC20(USDTAddress).transferFrom(msg.sender, feeAccount, fee);
        IERC20(USDTAddress).transferFrom(msg.sender, address(this), _amount-fee);
        participants.push(msg.sender);
        amountOfParticipants[msg.sender]+=_amount;
        emit DepositeAmountEvent(msg.sender);
    }
    
    function getLottery() public onlyOwner{
        if(participants.length==1){
            uint balance = IERC20(USDTAddress).balanceOf(address(this));
            IERC20(USDTAddress).transfer(participants[0],balance);  
            emit Winner(participants[0], 0);
            lastWinner=participants[0];
            participants.pop();  
            lotteryTime = block.timestamp + lotteryTimeDuration;
        }else{
            uint winnerId = LotteryWinner();
            uint balance = IERC20(USDTAddress).balanceOf(address(this));
            IERC20(USDTAddress).transfer(participants[winnerId],balance);
            lotteryTime = block.timestamp + lotteryTimeDuration;
            address winner = participants[winnerId];
            lastWinner=winner;
            for(uint i=0;i<=participants.length;i++){
                participants.pop();
            }
            emit Winner(winner,winnerId);
        }
    }

    function LotteryWinner() internal view returns(uint){
        uint _modulus = participants.length;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }

    function times() public view returns(uint){
        return block.timestamp;
    }

    function range(uint _modulus) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }

    function random(uint[] memory _myArray) public view returns(uint[] memory){
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