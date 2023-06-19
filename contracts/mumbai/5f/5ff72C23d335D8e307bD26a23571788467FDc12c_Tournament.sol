// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./extensions/Playable.sol";

struct Tour {    
    address[] players;
    uint[] scores;
    mapping(address=>bool) playerMap;
    uint entryDeadline;
    uint entryFee;
    uint pot;
    bool closed;    
}

contract Tournament is Playable {

    mapping(uint=>Tour) public tournaments;
    uint public tourCount;    

    event PaymentCannotProcessed(address player, uint amount);
    event EnterTournament(uint tournamentId,address player,uint amount);
    event TournamentCreated(uint tournamentId,uint deadline,uint entryFee);
    event TournamentEnded(uint tournamentId,uint winnersCount,uint pot);

    constructor(address _playerContract, uint _devFee, address _treasuryWallet)
    {
        playerContract = IPlayer(_playerContract);        
        devFee = _devFee;        
        treasuryWallet = ITreasuryWallet(_treasuryWallet);
    }

    function createTour(uint deadline,uint entryFee) public onlyScoreSetter returns(uint){
        Tour storage tour = tournaments[tourCount];
        tour.entryDeadline = deadline;
        tour.entryFee = entryFee;         
        tourCount++;
        emit TournamentCreated(tourCount-1,deadline,entryFee);
        return tourCount-1;
    }

    function enterTournament(uint tournamentId,address ref) public payable returns(uint){
        Tour storage tournament = tournaments[tournamentId];
        require(tournament.entryDeadline>0 && tournament.entryDeadline <= block.timestamp && !tournament.closed,"Enter Tourament: Deadline passed!!");
        require(address(playerContract) !=address(0),"Enter Tourament: Player Contract is not defined!!");

        if(!playerContract.getPlayerExistence(msg.sender)){
            playerContract.registerPlayer(ref,msg.sender);            
        }
        bool playerExtempt = playerContract.getPlayerExemption(msg.sender);        
        if(!playerExtempt || tournament.playerMap[msg.sender]){
            require(msg.value==tournament.entryFee,"Enter Tourament: Amount send is not equal to entry fee!!");
        }

        uint256 amount = msg.value;
        (uint platformFee, ) = _payDevFee(amount, msg.sender,!playerExtempt);
        amount -= platformFee;

        tournament.playerMap[msg.sender] = true;
        tournament.players.push(msg.sender);
        tournament.pot+=amount;
        emit EnterTournament(tournamentId, msg.sender, amount);
        return tournament.players.length;
    }

    function endTournament(uint tournamentId,uint[] calldata scores,address[] memory winners,uint[] calldata winnings) public onlyScoreSetter {
        if(scores.length>0){
            setScores(tournamentId,scores);
        }
        for(uint i=0;i<winners.length;i++ ){
            if(winners[i] != address(0) && tournaments[tournamentId].playerMap[winners[i]]){
                (bool success,) = winners[i].call{value:winnings[i]}("");
               if(!success){
                emit PaymentCannotProcessed(winners[i],winnings[i]);
               }
            }      
        }
        Tour storage tournament = tournaments[tournamentId];
        tournament.closed = true;
        emit TournamentEnded(tournamentId,winners.length,tournament.pot);        
    }

    function setScores(uint id,uint[] calldata scores) internal{
        for(uint i =0 ;i<scores.length;i++){
            tournaments[id].scores.push(scores[i]);
        }        
    }

    function getTournamentDetail(uint tournamentId) public view returns( uint,bool,uint,uint,uint){
        Tour storage tournament = tournaments[tournamentId];
        return (tournament.players.length,tournament.closed,tournament.entryFee,tournament.entryDeadline,tournament.pot);
    }
}

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ITreasuryWallet {
    function addDevWalletBalance(uint) external payable;
}

interface IPlayer {

    function registerPlayer(address, address) external;

    function distributeReferrals(address,uint) external payable returns (uint);

    function getPlayerExistence(address useraddr) external view returns (bool);

    function getPlayerExemption(address useraddr) external view returns (bool);
}


abstract contract Playable is Ownable {

    ITreasuryWallet treasuryWallet;
    IPlayer playerContract;
    uint devFee;

    address public scoreSetter;    

    event Fees(uint256 amount, uint256 refAmount, address player, bool exemption);

    modifier onlyScoreSetter() {
        require(msg.sender==scoreSetter,"Playable: Caller not Playable contract");
        _;
    }

    function setTreasuryWallet(address treasuryWalletAddress) public onlyOwner{
        treasuryWallet=ITreasuryWallet(treasuryWalletAddress);
    }

    function setPlayerWallet(address playerAddress) public onlyOwner{
        playerContract=IPlayer(playerAddress);
    }

    function setScoreSetter(address scoreSetterAddress) public onlyOwner{
        scoreSetter = scoreSetterAddress;
    }


    function _payDevFee(
        uint256 amount,
        address user,
        bool payDevFees
    ) internal returns (uint, uint) {
        require(
            address(treasuryWallet) != address(0),
            "TreasuryWallet not yet assigned!!"
        );
        require(
            address(playerContract) != address(0),
            "Player Contract is not defined!!"
        );
        uint amountFee;
        uint amountAfterRefFee;
        if (payDevFees) {
            amountFee = (amount * (devFee)) / 100;            
            uint refFee = playerContract.distributeReferrals(user,amountFee);                            
            treasuryWallet.addDevWalletBalance{value: amountFee}(refFee);
        }
        emit Fees(
            amountFee,
            amountAfterRefFee,
            msg.sender,
            playerContract.getPlayerExemption(msg.sender)
        );
        return (amountFee, amountAfterRefFee);
    }
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