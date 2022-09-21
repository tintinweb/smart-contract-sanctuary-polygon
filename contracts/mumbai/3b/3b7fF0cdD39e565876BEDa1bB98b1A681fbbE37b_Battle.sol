/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*\
Info:
houseEdge is the percentage the contract burns. (default: 5%, max: 20%)
owner is the owner of contract
operator is the address that will End the battles.
setOwner() sets the owner of contract
setOperator() sets the operator
setToken() sets the token the players will use
renouceOwner() sets owner to 0x0;

lookForGame() is used at battle creation to lock if any other game with same bet is already created.
createGame() creates a new game or joins a game with same bet and returns Gameid, bet, Ifstarted, player1, player2.
This information can be used by operator.
    GameId, player1, player2 is informaion needed to end the game.
    Ifstarted to see if new game is created or game was joined (true = joined, false = created)
    bet to display the bet.

GameStarted() is used by operator to check if a created game is filled. This means if createGame() returns false on Ifstarted the operator uses this function til it returns true, after that the operator can procced to use Endgame().
Endgame() is used by operator to end the game.

Constructor:
_token is the ERC20 token that players should use.
_operator is the address that will End the battles

\*/

interface IERC20 {
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function burn(uint256 amount) external; 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC1155 {
    function balanceOf(address account, uint id) external returns(uint);   
}

interface IERC721 {
    function balanceOf(address account) external view returns (uint256);
}

interface IVault {
    function deposit(address _token, uint _amount) external returns(bool);
}

contract Battle {
    address public owner;
    address public team;
    address public LPstaking;
    uint currentGame = 1;
    IERC1155 erc1155;
    IERC20 mainToken;
    IERC721 erc721;
    mapping(address => uint) inGame;
    mapping(uint => game) public Gamelist;
    mapping(address => bool) isOperator;
    mapping(address => player) stats;
    constructor(address _token, address _operator, address _staking, address _team, address _erc1155, address _erc721){
        mainToken = IERC20(_token);
        owner = msg.sender;
        isOperator[_operator] = true;
        LPstaking = _staking;
        team = _team;
        erc1155 = IERC1155(_erc1155);
        erc721 = IERC721(_erc721);
        mainToken.approve(team, 2**256 - 1);
    }

    event newGame(uint indexed id, address indexed creator, uint indexed bet);
    event joinedGame(uint indexed id, address indexed player, uint indexed bet);
    event endedGame(uint indexed id, address indexed winner, uint indexed bet);


    struct game {
        address operator;
        address player1;
        address player2;
        uint256 stakes;
        address winner;
        uint startedAt;
    }

    struct player {
        uint[] gamesPlayed;
        uint[] gamesWon;
        uint[] gamesLost;
    }

    modifier onlyOwner() {
        require(owner == msg.sender || isOperator[msg.sender]);
        _;
    }

    function setOwner(address _add) public onlyOwner{
        owner = _add;
    }
    
    function setOperator(address _add) public onlyOwner{
        isOperator[_add] = !isOperator[_add];
    }

    function setToken(address _add) public onlyOwner{
        mainToken = IERC20(_add);
    }

    function renouceOwner() public onlyOwner{
        owner = address(0x0);
    }

    function setTeam(address _add) public onlyOwner {
        team = _add;
    }

    function setStaking(address _add) public onlyOwner {
        LPstaking = _add;
    }

    function latestGame() public view returns(uint) {
        return currentGame;
    }

    function playingOn(address _add) public view returns(uint) {
        return inGame[_add];
    }

    function getAllWonOf(address _add) public view returns(uint[] memory) {
        return stats[_add].gamesWon;
    }

    function getAllPlayedOf(address _add) public view returns(uint[] memory) {
        return stats[_add].gamesPlayed;
    }

    function getAllLostOf(address _add) public view returns(uint[] memory) {
        return stats[_add].gamesLost;
    }

    function getAllDrawnOf(address _add) public view returns(uint[] memory) {
        uint[] memory ids = new uint[](getTotalGamesDrawnOf(_add));
        uint count = 0;
        for(uint i; i < getTotalPlayedOf(_add); i++) {
            if(stats[_add].gamesPlayed[i] != stats[_add].gamesWon[i] && stats[_add].gamesPlayed[i] != stats[_add].gamesLost[i]) {
                ids[count] = i;
                count++;
            }
        }
        return ids;
    }

    function getTotalWonOf(address _add) public view returns(uint) {
        return stats[_add].gamesWon.length;
    }

    function getTotalLostOf(address _add) public view returns(uint) {
        return stats[_add].gamesLost.length;
    }

    function getTotalPlayedOf(address _add) public view returns(uint) {
        return stats[_add].gamesPlayed.length;
    }

    function getTotalGamesDrawnOf(address _add) public view returns(uint) {
        return getTotalPlayedOf(_add) - (getTotalWonOf(_add) + getTotalLostOf(_add));
    }

    function getWLOf(address _add) public view returns(uint)  {
        return getTotalWonOf(_add) * 1e18 / getTotalLostOf(_add);
    }  

    function getWinPercentageOf(address _add) public view returns(uint) {
        return 100e18 / getTotalPlayedOf(_add) * getTotalWonOf(_add);
    }

    function getLoosePercentageOf(address _add) public view returns(uint) {
        return 100e18 / getTotalPlayedOf(_add) * getTotalLostOf(_add);
    }

    function getDrawPercentageOf(address _add) public view returns(uint) {
        return 100e18 / getTotalPlayedOf(_add) * getTotalGamesDrawnOf(_add);
    }

    function getGame(uint _id) public view returns(uint, uint, address, address, address) {
        return (getState(_id), Gamelist[_id].stakes, Gamelist[_id].player1, Gamelist[_id].player2, Gamelist[_id].winner);
    }

    function getState(uint _id) public view returns(uint) {
        uint state = 0;
        if(Gamelist[_id].winner != address(0x0))
            state = 3;
        else if(Gamelist[_id].player1 != address(0x0) && Gamelist[_id].player2 == address(0x0))
            state = 1;
        else
            state = 2;
        return state;
    }


    function getAllActive(uint _start) public view returns(uint[] memory, uint[] memory) {
        uint count = 0;
        for(uint i = _start; i < currentGame; i++) {
            if(Gamelist[i].winner == address(0x0))
                count++;
        }
        uint[] memory _id = new uint[](count);
        uint[] memory _times = new uint[](count);
        count = 0;
        for(uint i = _start; i < currentGame; i++) {
            if(Gamelist[i].winner == address(0x0)) {
                _id[count] = i;
                _times[count] = Gamelist[i].startedAt;
                count++;
            }
        }
        return (_id, _times);
    }




   


    function createGame(uint256 _bet) public payable returns(uint256 id, uint256 bet, bool started) {
        require(inGame[msg.sender] == 0, "already joineed a game atm!");
        require(msg.value >= 5e16, "please provide a fee of at least 0.05 MATIC!"); 
        require(_bet > 0, "Bet must be higher than 0!");
        require(bet <= 10000*1e18, "bet too big!");
        require(mainToken.transferFrom(msg.sender, address(this), _bet), "bet transfer  failed!");
        if(bet >= 100 && bet < 1000) {
            require(erc1155.balanceOf(msg.sender, 1) > 0 ||
                    erc1155.balanceOf(msg.sender, 2) > 0 ||
                    erc1155.balanceOf(msg.sender, 3) > 0 ||
                    erc1155.balanceOf(msg.sender, 4) > 0, "Please purchse coin! (erc1155)");
        }
        if(bet >= 1000e18)
            require(erc721.balanceOf(msg.sender) > 0, "please purchase a nft. (erc721)");
        
        inGame[msg.sender] = currentGame;
        game memory Game = game(address(0x0), msg.sender, address(0x0), _bet, address(0x0), block.timestamp);
        stats[msg.sender].gamesPlayed.push(currentGame);
        Gamelist[currentGame] = Game;
        currentGame++;
        emit newGame(currentGame-1, msg.sender, _bet);
        return (currentGame, _bet, false);
    }

    function joinGame(uint _id) public payable returns(bool){
        require(msg.value >= 5e16, "please provide a fee of at least 0.05 MATIC!"); 
        require(inGame[msg.sender] == 0, "already joineed a game atm!");
        require(mainToken.transferFrom(msg.sender, address(this), Gamelist[_id].stakes), "payment failed!");
        require(Gamelist[_id].winner == address(0x0), "game was shut down!");
        require(Gamelist[_id].player2 == address(0x0), "game full!");
        inGame[msg.sender] = _id;
        Gamelist[_id].player2 = msg.sender;
        stats[msg.sender].gamesPlayed.push(_id);
        emit joinedGame(_id, msg.sender, Gamelist[_id].stakes);
        return true;
    }

    function cancel(uint _id) public returns(bool){
        require(Gamelist[_id].player2 == address(0x0));
        require(Gamelist[_id].player1 == msg.sender);
        require(mainToken.transfer(Gamelist[_id].player1, Gamelist[_id].stakes), "transfer failed!");
        payable(Gamelist[_id].player1).transfer(5e16);
        return true;
    }

    function endgame(uint256 id, address winner) public onlyOwner returns(bool){
        require(Gamelist[id].winner == address(0x0));
        require(Gamelist[id].player2 != address(0x0));
        Gamelist[id].operator = msg.sender;
        if(winner == address(0x0)) {
            require(mainToken.transfer(Gamelist[id].player1, Gamelist[id].stakes), "transfer failed, 1!");
            require(mainToken.transfer(Gamelist[id].player2, Gamelist[id].stakes), "transfer failed, 2!");
            Gamelist[id].winner = Gamelist[id].operator;
        } else {
           Gamelist[id].winner = winner;
            uint _burnFee = (Gamelist[id].stakes * 2) * 8 / 100;
            mainToken.burn(_burnFee-1);

            uint _teamFee = (Gamelist[id].stakes * 2) * 1 / 100;
            require(IVault(team).deposit(address(mainToken), _teamFee-1));

            uint _LPStakingFee = (Gamelist[id].stakes * 2) * 1 / 100;
            require(mainToken.transfer(LPstaking, _LPStakingFee-1));

            uint _tFee = _burnFee + _teamFee + _LPStakingFee;
            uint win = (Gamelist[id].stakes * 2) - _tFee;
            require(mainToken.transfer(winner, win), "transfer failed, winner!");
            stats[winner].gamesWon.push(id);
            stats[Gamelist[id].player2].gamesLost.push(id);
        }
        inGame[Gamelist[id].player1] = 0;
        inGame[Gamelist[id].player2] = 0;
        emit endedGame(id, winner, Gamelist[id].stakes);
        payable(Gamelist[id].operator).transfer(1e17);
        return true;
    }

    receive() external payable {

    }
}