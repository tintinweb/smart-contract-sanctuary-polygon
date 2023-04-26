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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//  Interface for ERC20 stablecoins as USDT, DAI, BUSD etc.
//  In this version i used only USDT for payments. In next versions it will be possible to
//  pay by various tokens.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";






// Start of the smart contract for DAO education platform
// This version supprots only one round of quadraticFounring
contract EducationPlatform is Ownable {

    using Counters for Counters.Counter;
    

    // Here you can see main data strucure of round system
    // enums using for emit events and later using them onback-end
    Counters.Counter private _expertId;
    enum Register { None, Pending, Done }
    enum CourseStatus {Pending, Done, Canceled}
    IERC20 USDT;
    Round public round;
    //address withdrawAddr;

    mapping (uint => Expert) public expertById;
    mapping (address => bool) public isExpertRegistered;
    mapping (address => mapping (uint => DonatingInfo)) public userDonation;
    mapping (address => RegistrationRequest) public registrationRequests;
    mapping (address => bool) public isUserRegistered;
    
    // Data about our experts like ADDRESS, NAME, BALANCE and VOTES for this expert

    struct Expert { //this is Expert
        address expertAddress;
        string expertName;
        uint expertId;
        uint votes;
        uint balance;
        uint rewardPoints;
        CourseStatus status;
    }

    // Donating info using in mapping, to know is user donated for current expert
    // and how much
    struct DonatingInfo{
        bool isDonated;
        uint amountOfDonations;
    }

    // RegistrationRequest also using in mapping and used for register our experts in system
    struct RegistrationRequest { 
        address userAddress;
        string name;
        Register registrationStatus;
    }

    // Info about round
    struct Round{
        uint budget;
        uint startTime;
        uint endTime;
        uint totalVotes;
        bool roundActive;
        mapping(address => mapping (uint => bool)) isUserDonatedToExpertInRound;
    }
    
    
    constructor(address _USDT) {
        USDT = IERC20(_USDT);
    }
    
    function register() external{
        isUserRegistered[_msgSender()] = true;
    }

    // Here function get string "Name of Expert" and scan its addres, then make request to register
    // after some requrements checks 
    function registerAsExpert(string memory _name) external {

        require(!isExpertRegistered[_msgSender()], "You already registered");
        require(registrationRequests[_msgSender()].registrationStatus == Register.None, 'Your request already created');
        address _expertAddr = _msgSender();
        registrationRequests[_expertAddr].name = _name;
        registrationRequests[_expertAddr].userAddress = _expertAddr;
        registrationRequests[_expertAddr].registrationStatus = Register.Pending;
        emit RegistrationRequested(_name, _expertAddr);
    }
    
    // Deployer of smart-contract can approve any of the users request and register him as Expert
    function approveExpert(address _expertAddr) external onlyOwner {
        require(!isExpertRegistered[_expertAddr], "This Expert already registered");
        require(registrationRequests[_expertAddr].registrationStatus != Register.None, "This request not exist");
        
        uint expertId = _expertId.current();
        
        isExpertRegistered[_expertAddr] = true;
        registrationRequests[_expertAddr].registrationStatus = Register.Done;

        expertById[expertId].expertAddress = _expertAddr;
        expertById[expertId].expertId = expertId;
        expertById[expertId].expertName = registrationRequests[_expertAddr].name;
        _expertId.increment();
        emit RegistrationApproved(expertById[expertId].expertName, _expertAddr, expertId);
    }
    
    // After all experts registration, contract Owner should to start round by giving function latency in days
    function startRound(uint _timeInHours, uint _roundRevardsPoints) external onlyOwner {
        require(!round.roundActive, "Round already active");
        uint _hourInMillisecconds = 1000*60*60;
        uint _endTime = block.timestamp + _timeInHours * _hourInMillisecconds;
        
        round.roundActive = true;
        round.endTime = _endTime;
        round.budget = _roundRevardsPoints;
        round.startTime = block.timestamp;
        emit RoundStarted(round.startTime, round.endTime, round.budget);
    }
    
    // Native users allow to donate any existing expert some funds
    // in USDT, then some votes adding for expert in this round if he 
    // not voted for this expert in this round yet
    function donateInUSDT(uint _id, uint _amount) external{
        require(isUserRegistered[_msgSender()], "You not registered");
        require(USDT.balanceOf(_msgSender()) >= _amount, "You havent enougth USDT");
        require(USDT.allowance(_msgSender(), address(this)) >= _amount, "You need to approve mote USDT to donate this");
        require(expertById[_id].expertAddress != address(0), "Expert not exist");
        bool _isVoteAdded;
        USDT.transferFrom(_msgSender(), address(this), _amount);
        if(round.startTime < block.timestamp && block.timestamp < round.endTime && !round.isUserDonatedToExpertInRound[_msgSender()][_id]){
            round.totalVotes++;
            expertById[_id].votes++;
            round.isUserDonatedToExpertInRound[_msgSender()][_id] = true;
            _isVoteAdded = true;
        }
        expertById[_id].balance+= _amount;
        userDonation[_msgSender()][_id].isDonated = true;
        userDonation[_msgSender()][_id].amountOfDonations+= _amount;
        emit Donate(_msgSender(), _id, _amount, _isVoteAdded);
    }
    


    // After round ending and expert produced his course, 
    // contract Owner can approve that and transfer his donation and
    // funding revard to experts wallet
    function transferTokensToExpert(uint _id) external onlyOwner{
        //require(round.endTime < block.timestamp, "Round not finished yet");
        require(round.totalVotes > 0, "Panic! Please add votes");
        require(expertById[_id].expertAddress != address(0), "Expert not exist");
        require(expertById[_id].status == CourseStatus.Pending, "This is already not actual");
        expertById[_id].status = CourseStatus.Done;
        uint balance = expertById[_id].balance;
        uint reward = round.budget * expertById[_id].votes / round.totalVotes;
        expertById[_id].balance = 0;
        USDT.transfer(expertById[_id].expertAddress, balance);
        expertById[_id].rewardPoints+=reward;
        emit TransferDonationsToExpert(_id, balance, reward);
    }
    
    function OnMoneyBack(uint _id) external onlyOwner{
        //require(round.endTime < block.timestamp, "Round not finished yet");
        require(expertById[_id].expertAddress != address(0), "Expert not exist");
        require(expertById[_id].status == CourseStatus.Pending, "This is already not actual");
        expertById[_id].status = CourseStatus.Canceled;
        emit EnableMoneyBack(_id);
    }
    
    function getMoneyBack(uint _id) external {
        //require(round.endTime < block.timestamp, "Round not finished yet");
        require(expertById[_id].expertAddress != address(0), "Expert not exist");
        require(expertById[_id].status == CourseStatus.Canceled, "This course not canceled");
        require(0 < userDonation[_msgSender()][_id].amountOfDonations, "Nothing to withdraw");
        uint donated = userDonation[_msgSender()][_id].amountOfDonations;
        userDonation[_msgSender()][_id].amountOfDonations = 0;
        expertById[_id].balance -= donated;
        USDT.transfer(_msgSender(), donated);
        emit GotMoneyBack(_id, donated, _msgSender());
    }

    event EnableMoneyBack (uint _expertId);
    event GotMoneyBack (uint _expertId, uint _amount, address _user);
    event RegistrationRequested(string _name, address _expertAddress);
    event RoundStarted(uint _startTime, uint _endTime, uint _revardsAmount );
    event RegistrationApproved(string _name, address _expertAddress, uint _id );
    event TransferDonationsToExpert (uint _expertId, uint _transfered, uint _rewardPoints);
    event Donate(address _sender, uint _expertId, uint _revardsAmount, bool _isVoteAdded );
    
}