// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

import "./Ownable.sol";
import "./IERC20.sol";

contract WildGamesWildFive is Ownable {
    IERC20 paymentToken;
    address public wildGamesVault;
    uint8 public arrayCounter;
    uint8 public amountGamesUntilExtraGame;
    mapping(address => uint256) public payments;
    mapping(uint256 => Game[]) public gameLogs;
    mapping(uint256 => Game[]) public extraGameLogs;
    mapping(address => mapping(uint256 => uint256[])) private addressToGameIndexToGames;

    struct Game {
        uint128 id;
        address[5] players;
        uint8 playersNow;
        uint8 extraGameFundCounter;
        uint256 extraGameFundBalance;
        address[] losers;
        uint256 betValue;
        uint256[5] playerNotes;
    }

    struct WinnerLog{
        address winner;
        uint256 gameId;
        uint256 betValue;
        uint256 winnerPayout;
    }

    Game[] public AllGames;
    WinnerLog[] public AllWinners;

    event UserEnteredGame(address indexed user, uint256 indexed betIndex, uint256 indexed gameIndex, address[5] participants);
    event GameFinished(uint256 indexed betIndex, uint256 indexed gameIndex, address looser, address[5] participants);

    constructor(address _paymentToken, address _vaultAddress) {
        paymentToken = IERC20(_paymentToken); // BSC
        // paymentToken = IERC20(0x7f92a2653c0f0de33e25351ee2a89471f4f18bc0); // POLYGON address's checksum is wrong
        
        wildGamesVault = _vaultAddress;
        amountGamesUntilExtraGame = 100;

        createGame(50000000000000000000); // 50
        createGame(100000000000000000000); // 100
        createGame(500000000000000000000); // 500
        createGame(1000000000000000000000); // 1000
        createGame(5000000000000000000000); // 5000
        createGame(10000000000000000000000); // 10000
        createGame(50000000000000000000000); // 50000
        createGame(100000000000000000000000); // 100000
    }

    function getTokenBalanceContract() external view returns(uint) {
        return paymentToken.balanceOf(address(this));
    }

    function createGame(uint256 _betValue) public onlyOwner {
        address[] memory emptyArr;
        address[5] memory playersArr;
        uint256[5] memory playersNotesArr;

        AllGames.push(Game(0, playersArr, 0, 0 ,0, emptyArr, _betValue, playersNotesArr));
    }

    function getPaymentTokenBalance(address _who) public view returns(uint256) {
        return paymentToken.balanceOf(_who);
    }

    function _DepositIntoContract( uint256 amount) internal  returns (bool) {
        paymentToken.transferFrom(tx.origin,address(this), amount);
        payments[tx.origin] += amount;
        return true;
    }

    function checkAllowanceFrom(address _who) public view returns(uint256) {
        return paymentToken.allowance(_who, address(this));
    }

    function withdrawContract() public onlyOwner {
        paymentToken.transfer( owner(),  paymentToken.balanceOf(address(this)));
    }

    function getLosersByGame(uint _indexGame) public view returns(address[] memory) {
        Game storage currentGame = AllGames[_indexGame];
        return currentGame.losers;
    }

    function isPlayerInGame(address _player, uint _indexGame) public view returns(bool) {
        Game memory currentGame = AllGames[_indexGame];
        for(uint i = 0; i < currentGame.players.length; i++) {
            if(currentGame.players[i] == _player) {
                return true;
            }
        }
        return false;
    }

    function enterinGame (uint _indexGame, uint256 _playerNote) public {
        Game storage currentGame = AllGames[_indexGame];
        require(!isPlayerInGame(msg.sender, _indexGame), "you're already entered");
        require(checkAllowanceFrom(msg.sender) >= currentGame.betValue, "not enough allowance");

        _DepositIntoContract(currentGame.betValue);
        pushPlayerIn(msg.sender, _indexGame, _playerNote);

        addressToGameIndexToGames[msg.sender][_indexGame].push(currentGame.id);

        currentGame.playersNow++;    

        // check occupancy of players array
        if(currentGame.playersNow == 10) {
            drawProcess(_indexGame);
            currentGame.extraGameFundCounter++;
        }

        if(currentGame.extraGameFundCounter % amountGamesUntilExtraGame == 0) {
            extraGameDraw(_indexGame);
        }

        emit UserEnteredGame(msg.sender, _indexGame, currentGame.id, currentGame.players);
    }

    function viewPlayersByGame(uint _indexGame) public view returns(address[5] memory) {
        Game storage currentGame = AllGames[_indexGame];
        return currentGame.players;
    }

    function pushPlayerIn(address _player, uint _index, uint256 _playerNote) internal {
        Game storage currentGame = AllGames[_index];
        for(uint i = 0; i < currentGame.players.length; i++) {
            if(currentGame.players[i] == address(0) ) {
                currentGame.players[i] = _player;
                currentGame.playerNotes[i] = _playerNote ;
                break;
            }
        }
    }

    function cancelBet( uint _indexGame) public  returns (bool) {
        Game storage currentGame = AllGames[_indexGame];
        require(isPlayerInGame(msg.sender, _indexGame), "you're not a player");
        require(payments[msg.sender] >= currentGame.betValue, "not enough allowance for cancelBet");

        currentGame.playersNow--;    
        addressToGameIndexToGames[msg.sender][_indexGame].pop();

        for(uint i = 0; i < currentGame.players.length; i++) {
            if(msg.sender == currentGame.players[i]) {
                delete currentGame.players[i];
                delete currentGame.playerNotes[i];
            }
        }

        payments[msg.sender] -= currentGame.betValue;
        paymentToken.transfer(tx.origin, currentGame.betValue); //msg sender or tx origin?

        return true;        
    }

    function removeGame(uint _indexGame) public onlyOwner{
        delete AllGames[_indexGame];
    }
 
    function getAllGamesData() external view returns(Game[] memory) {
        return AllGames;
    }
    
    function getGameByIndex(uint _indexGame) external view returns(Game memory) {
        return AllGames[_indexGame];
    }

 ////////////////////////////////////////////
    receive() external payable {}
 ////////////////////////////////////////////

    function setAmountUntilExtra(uint8 _amount) public {
        amountGamesUntilExtraGame = _amount;
    }

    function checkBalanceWildGamesVault() public onlyOwner view returns(uint256) {
        return paymentToken.balanceOf(wildGamesVault);
    }

    function drawProcess(uint _indexGame) internal {
        Game storage currentGame = AllGames[_indexGame];
        // gameLogs[_indexGame].push(currentGame);
        uint payoutForWinner = (currentGame.betValue * 120) / 100; //80%
        uint indexLoser =  random(currentGame.players.length, _indexGame); 

        //send loser to losers list
        currentGame.losers.push(currentGame.players[indexLoser]);

        //distribute to winners
        for (uint i = 0; i < currentGame.players.length ; i++) {
            if(i != indexLoser ) {
                paymentToken.transfer( payable(currentGame.players[i]), payoutForWinner);
            }
        }

        // distribute for WildGamesFund
        paymentToken.transfer(wildGamesVault, (currentGame.betValue * 11/100)); //11%

        // distribute to extraGameFund
        currentGame.extraGameFundBalance += (currentGame.betValue * 9) / 100; //9%
        delete currentGame.players;
        delete currentGame.playerNotes;
        currentGame.playersNow = 0;

        gameLogs[_indexGame].push(currentGame);

        emit GameFinished(_indexGame, currentGame.id++, currentGame.players[indexLoser], currentGame.players);
    }

    function setWildGamesFuncReceiver(address _receiver) public onlyOwner {
        wildGamesVault = _receiver;
    }

    function getLastGameLog(uint256 _indexGame) external view returns(Game memory gameLogs_) {
        Game[] memory _gameLogs = gameLogs[_indexGame];
        return _gameLogs[_gameLogs.length - 1];
    }

    function getUserLastGame(address _user, uint256 _indexGame) external view returns (Game memory) {
        uint256[] memory games = addressToGameIndexToGames[_user][_indexGame];
        return gameLogs[_indexGame][games.length - 1];
    }

    function getAllGameIdsUserParticipated(address _user, uint256 _indexGame) external view returns (uint256[] memory) {
        return addressToGameIndexToGames[_user][_indexGame];
    }

    function extraGameDraw(uint _indexGame) internal   {
        Game storage currentGame = AllGames[_indexGame];
        // extraGameLogs[_indexGame].push(currentGame);
        uint winnerIndex = random(currentGame.losers.length, _indexGame);
        paymentToken.transfer(currentGame.losers[winnerIndex], currentGame.extraGameFundBalance);
        AllWinners.push(WinnerLog(currentGame.losers[winnerIndex], currentGame.id, currentGame.betValue, currentGame.extraGameFundBalance));
        extraGameLogs[_indexGame].push(currentGame);
        delete currentGame.losers;
    }
        
    function random(uint _value, uint _indexGame) internal view returns(uint){
        Game memory currentGame = AllGames[_indexGame];
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,blockhash(block.number-1), currentGame.playerNotes, msg.sender))) % _value; //11 + add -1 to block number
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    /**
        @dev emitted when ownership is transfered 
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
        @dev creates a contract instance and sets deployer as its _owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
        @dev returns address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
        @dev checks if caller of the function is _owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "You are not the owner");
        _;
    }

    /**
       @dev transfers the ownership to 0x00 address.
       @notice after renouncing contract ownership functions with onlyOwner modifier will not be accessible.
       @notice can be called only be _owner
    */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
        @dev transfers ownership to newOwner.
        @notice can not be transfered to 0x00 addres.
        @notice can be called only be _owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "zero address can not be owner");
        _transferOwnership(newOwner);
    }

    /**
        @dev internal function to transfer ownership.
        @notice can only be called internally and only by _owner.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title ERC20 interface.
    @author @farruhsydykov.
 */
interface IERC20 {
    /**
        @dev returns the amount of tokens that currently exist.
     */
    function totalSupply() external view returns (uint256);

    /**
        @dev returns the amount of tokens owned by account.
        @param account is the account which's balance is checked
     */
    function balanceOf(address account) external view returns (uint256);

    /**
        @dev sends caller's tokens to the recipient's account.
        @param recipient account that will recieve tokens in case of transfer success
        @param amount amount of tokens being sent
        @return bool representing success of operation.
        @notice if success emits transfer event
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
        @dev returns the remaining amount of tokens that spender is allowed
        to spend on behalf of owner.
        @param owner is the account which's tokens are allowed to be spent by spender.
        @param spender is the account which is allowed to spend owners tokens.
        @return amount of tokens in uint256 that are allowed to spender.
        @notice allowance value changes when aprove or transferFrom functions are called.
        @notice allowance is zero by default.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
        @dev allowes spender to spend a set amount of caller's tokens throught transferFrom.
        @param spender is the account which will be allowed to spend owners tokens.
        @param amount is the amount of caller's tokens allowed to be spent by spender.
        @return bool representing a success or failure of the function call.
        @notice emits and Approval event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
        @dev sends amount of allowed tokens from the sender's account to recipient'saccount.
        amount is then deducted from the caller's allowance.
        @param sender is the account which's tokens are allowed to and sent by the caller.
        @param recipient is the account which will receive tokens from the sender.
        @param amount is the amount of tokens sent from the sender.
        @return bool representing a success or a failure of transaction.
        @notice emits Transfer event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
        @dev emitted when a transfer occures. Notifies about the value sent from which to which account.
        @param from acccount that sent tokens.
        @param to account that received tokens.
        @param value value sent from sender to receiver.
        @notice value may be zero
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
        @dev emitted when an account allowed another account to spend it's tokens on it's behalf.
        @param owner owner of tokens which allowed it's tokens to be spent.
        @param spender account who was allowed to spend tokens on another's account behalf.
        @param value amount of tokens allowed to spend by spender from owner's account.
        @notice value is always the allowed amount. It does not accumulated with calls to approve.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}