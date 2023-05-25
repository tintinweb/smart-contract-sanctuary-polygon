// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./extensions/Playable.sol";

struct Game {
    address playerOne;
    address playerTwo;
    uint256 playerOneScore;
    uint256 playerTwoScore;
    uint256 betAmount;
    address winner;
    uint pot;
    bool closed;
    uint gameId;
}

contract OneVSOne is Playable {

    mapping(uint256 => Game) public games;
    uint256 public gamesCount; 
    
    event GameCreated(uint256 id);
    event ScoreSetted(uint256 id, address player, uint256 amount);
    event BetSet(uint256 id, address player, uint256 amount); 
    event DistributeWinning(uint gameId,address player,uint256 amount);

    constructor(address _playerContract, uint256 _devFee, address _treasuryWallet)
    {
        playerContract = IPlayer(_playerContract);        
        devFee = _devFee;        
        treasuryWallet = ITreasuryWallet(_treasuryWallet);
    }

    function createOrJoinGame(
        uint256 gameId,
        address ref        
    ) external payable {
        require(msg.value > 0, "value can not be less than 0");
        require(address(playerContract) !=address(0),"Player Contract is not defined!!");

        if(!playerContract.getPlayerExistence(msg.sender)){
            playerContract.registerPlayer(ref,msg.sender);            
        }

        uint256 amount = msg.value;
        (uint platformFee, ) = _payDevFee(amount, msg.sender,!playerContract.getPlayerExemption(msg.sender));
        amount -= platformFee;
        
        Game storage game = games[gameId];
        require(!game.closed, "Game is already finished!!");
        

        if (game.playerOne != address(0)) {
            require(msg.value == game.betAmount,"The amount should be equal for both players");
            game.playerTwo = msg.sender;            
        } else {
            game = games[gameId];
            game.playerOne = msg.sender;
            game.betAmount = msg.value;                         
            emit GameCreated(gamesCount);
            gamesCount++;
        }
        game.pot += amount;                        
        emit BetSet(gameId, msg.sender, amount);
    }

    function setScore(uint gameId,uint score1,uint score2) public onlyScoreSetter {
        require(score1>0 && score2>0,"InvalidScore!!");
        Game storage game = games[gameId];
        require(!game.closed,"Game is already finished!!");
        require(game.playerOne!=address(0) && game.playerTwo!=address(0),"Score submitted without players.!!");
        game.playerOneScore=score1;
        game.playerTwoScore=score2;
        bool success = false;
        if(score1<score2){
            game.winner = game.playerTwo;
            (success,)=game.playerTwo.call{value: games[gameId].pot}("");            
        }else if(score1>score2){
            game.winner = game.playerOne;
            (success,)=game.playerOne.call{value: game.pot}("");            
        } else {
            game.winner = address(this);
            uint halfpot = game.pot /2;
            (success,)=game.playerOne.call{value:halfpot}("");
            (success,)=game.playerTwo.call{value:game.pot-halfpot}("");            
        }
        require(success,"Error while transferring winnings!!");
        emit DistributeWinning(gameId,game.winner,game.pot);
        game.closed=true;
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