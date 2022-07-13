/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// File: contracts/Creativez/utils/Context.sol



pragma solidity >=0.7.0 <0.9.0;

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

// File: contracts/Creativez/access/Ownable.sol



pragma solidity >=0.7.0 <0.9.0;


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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/CreativezVoting.sol

//SPDX-License-Identifier: MIT

pragma solidity  >=0.7.0 <0.9.0;


interface Creativez {
    function balanceOf(address account) external view returns (uint256);
    function getSupp() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract CreativezVoting is Ownable {

    constructor(){
        _status = _NOT_ENTERED;
    }

    //Reentrancy guard modifier
     modifier nonReentrant () {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }    

    // Voting variables //
    uint public totalVotes;
    uint256 public option1VoteCounter;
    uint256 public option2VoteCounter;
    uint256 public option3VoteCounter;
    uint256 public voteLength;
    bool votingStatus = false;
    address public votingOutcomeStakingAddress;
    address public votingOutcomeTokenAddress;
    mapping (address => uint) voted; 
    mapping(uint256 => uint256) public NFTTokenIDs;   
    string public option1;
    address public option1StakingAddress;
    string public option2;
    address public option2StakingAddress;
    string public option3;
    address public option3StakingAddress; 
    uint256 public _status; 
    uint256 public constant _NOT_ENTERED = 1;
    uint256 public constant _ENTERED = 2;
    address CreativezNFTAddrs;                        

    // Voting section //

    event votingBegins (
        address option1,
        address option2,
        address option3,
        string option_1,
        string option_2,
        string option_3,
        uint256 voteLength,
        uint256 voteStartTime
    ); 

    event votingEnded (
        address optionWinner,
        address buttonPusher,
        uint256 totalVoters
    ); 

    event hasVoted (
        address voter,
        address option
    );

    event Vote (
        uint256 time, //compare block.timestamp with start time (needs to be > to included in the UI)
        uint256 count,
        address option,
        uint256 option1Count,
        uint256 option2Count,
        uint256 option3Count
    );

    function initiateAVote(string memory _option1, address _option1StakingAddress, string memory _option2, address _option2StakingAddress, string memory _option3, address _option3StakingAddress) public onlyOwner{
        option1 = _option1;
        option1StakingAddress = _option1StakingAddress;
        option2 = _option2;
        option2StakingAddress = _option2StakingAddress;
        option3 = _option3;
        option3StakingAddress = _option3StakingAddress;
        option1VoteCounter = 0;
        option2VoteCounter = 0;
        option3VoteCounter = 0;
        totalVotes = 0;
        votingStatus = true;
        voteLength = block.timestamp + 604800; //7 days        
        emit votingBegins (
        option1StakingAddress,
        option2StakingAddress,
        option3StakingAddress,
        _option1,
        _option2,
        _option3,
        voteLength,
        block.timestamp);
    }

    function vote(address option) public nonReentrant{
        require(votingStatus == true, "voting closed");
        require(option == option1StakingAddress || option == option2StakingAddress || option == option3StakingAddress, "must vote for one of the options");
        require(voted[msg.sender] < voteLength, "already voted");
        require(Creativez(CreativezNFTAddrs).balanceOf(msg.sender) >= 1, "does not hold a CTZ NFT"); // needs to hold at least 1 NFT to be a part of the DAO voting
        if (block.timestamp < voteLength){
            uint256 count = 0;
            voted [msg.sender] = block.timestamp+votingTimeLeft()+300;
            for (uint256 i = 0; i<Creativez(CreativezNFTAddrs).balanceOf(msg.sender); i++) {
                uint256 tokenID = Creativez(CreativezNFTAddrs).tokenOfOwnerByIndex(msg.sender, i);
                if (NFTTokenIDs[tokenID]<voteLength){
                  count++;
                  NFTTokenIDs[tokenID] = block.timestamp+votingTimeLeft()+300;
                  } 
                NFTTokenIDs[tokenID]= block.timestamp+votingTimeLeft()+300;
                }             
            option == option1StakingAddress ? option1VoteCounter += count : option == option2StakingAddress ? option2VoteCounter += count : option3VoteCounter += count;
            totalVotes += count;
            emit Vote (
                block.timestamp,
                count,
                option,
                option1VoteCounter,
                option2VoteCounter,
                option3VoteCounter
            );            
            }            
        else {
            option1VoteCounter >= option2VoteCounter && option1VoteCounter >= option3VoteCounter ? votingOutcomeStakingAddress = option1StakingAddress : option2VoteCounter >= option3VoteCounter ? votingOutcomeStakingAddress = option2StakingAddress : votingOutcomeStakingAddress = option3StakingAddress;
            emit votingEnded (
            msg.sender,
            votingOutcomeStakingAddress,
            totalVotes); 
            votingStatus = false;     
            }
        emit hasVoted (
        msg.sender,
        option
    );
    }            

    function votingTimeLeft() public view returns (uint){
        if(voteLength > block.timestamp)
            return (voteLength - block.timestamp);
        else {
            return 0;
        } 
    }

    // set Creativez.sol address //
    function setCreativezNFTAddrs(address _CreativezNFTAddrs) public onlyOwner {
      CreativezNFTAddrs = _CreativezNFTAddrs;
    }

    //this is the function that the Creativez contract uses to read which contract to invest in
    function getCreativezVotingOutcome() public view returns (address) {
        return votingOutcomeStakingAddress;
    }
}