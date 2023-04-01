/**
 *Submitted for verification at polygonscan.com on 2023-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {

            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface automation {
    function addFunds(uint256 id, uint96 amount) external;
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IERC20 {
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
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
    using SafeMath for uint;
    address public owner; // owner of contract
    address public team; // address of team
    address public LPstaking; // address of LP staking contract
    address dead = 0x000000000000000000000000000000000000dEaD; // dead address
    uint currentGame = 1; // current  game  id
    IERC1155 erc1155; // address of erc155 tken
    IERC20 mainToken; // main tkens address
    IERC721 erc721; // nft tokens cntract
    mapping(address => uint) inGame; // mapping to check which gamme the player is currently on
    mapping(uint => game) public Gamelist; // mapping form gammeId to gamme
    mapping(address => bool) isOperator; // mapping to check if player is operator (cheaper than arrays)
    mapping(address => player) stats; // mapping  from player to playerStats
    IUniswapV2Router router = IUniswapV2Router(0x8954AfA98594b838bda56FE4C12a09D7739D179b);
    automation registry = automation(0x02777053d6764996e594c3E88AF1D58D5363a2e6);
    IERC20 link = IERC20(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    address weth = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    uint id = 36505841710297596905327621152638315757066783081865792723756990402822851841027;
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

    /*\
    event for newGame
    \*/
    event newGame(uint indexed id, address indexed creator, uint indexed bet);
    
    /*\
    event for joining game
    \*/
    event joinedGame(uint indexed id, address indexed player, uint indexed bet);
    
    /*\
    event for ending games
    \*/
    event endedGame(uint indexed id, address indexed winner, uint indexed bet);

    /*\
    saves all values of each gamme
    \*/
    struct game {
        address operator;
        address player1;
        address player2;
        uint256 stakes;
        address winner;
        uint startedAt;
    }

    /*\
    saves stats of each wallet
    \*/
    struct player {
        uint[] gamesPlayed;
        uint[] gamesWon;
        uint[] gamesLost;
    }

    /*\
    functions with this modifier can only be called by the owner or operator
    \*/
    modifier onlyOwner() {
        require(owner == msg.sender || isOperator[msg.sender]);
        _;
    }

    /*\
    transfers owner
    \*/
    function setOwner(address _add) public onlyOwner{
        owner = _add;
    }
    
    /*\
    toggles operator
    \*/
    function setOperator(address _add) public onlyOwner{
        isOperator[_add] = !isOperator[_add];
    }

    /*\
    sets main token
    \*/
    function setToken(address _add) public onlyOwner{
        mainToken = IERC20(_add);
    }

    /*\
    renounce owner
    \*/
    function renouceOwner() public onlyOwner{
        owner = address(0x0);
    }

    /*\
    set team address
    \*/
    function setTeam(address _add) public onlyOwner {
        team = _add;
    }

    /*\
    set staking contract
    \*/
    function setStaking(address _add) public onlyOwner {
        LPstaking = _add;
    }

    /*\
    returns latest game id
    \*/
    function latestGame() public view returns(uint) {
        return currentGame;
    }

    /*\
    return what address is currently playing on
    \*/
    function playingOn(address _add) public view returns(uint) {
        return inGame[_add];
    }

    /*\
    returns all ids of won games of address
    \*/
    function getAllWonOf(address _add) public view returns(uint[] memory) {
        return stats[_add].gamesWon;
    }

    /*\
    returns all ids of games played of address
    \*/
    function getAllPlayedOf(address _add) public view returns(uint[] memory) {
        return stats[_add].gamesPlayed;
    }

    /*\
    returns all ids of lost games of address
    \*/
    function getAllLostOf(address _add) public view returns(uint[] memory) {
        return stats[_add].gamesLost;
    }

    /*\
    returns all ids of draw games of address 
    \*/
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

    /*\
    returns total games won of address
    \*/
    function getTotalWonOf(address _add) public view returns(uint) {
        return stats[_add].gamesWon.length;
    }

    /*\
    returns total lost games of address
    \*/
    function getTotalLostOf(address _add) public view returns(uint) {
        return stats[_add].gamesLost.length;
    }

    /*\
    returns total played games of address
    \*/
    function getTotalPlayedOf(address _add) public view returns(uint) {
        return stats[_add].gamesPlayed.length;
    }

    /*\
    returns total games drawn of address
    \*/
    function getTotalGamesDrawnOf(address _add) public view returns(uint) {
        return getTotalPlayedOf(_add) - (getTotalWonOf(_add) + getTotalLostOf(_add));
    }

    /*\
    returns W/L rate of player
    \*/
    function getWLOf(address _add) public view returns(uint)  {
        return getTotalWonOf(_add) * 1e18 / getTotalLostOf(_add);
    }  

    /*\
    returns win percentage of player
    \*/
    function getWinPercentageOf(address _add) public view returns(uint) {
        return 100e18 / getTotalPlayedOf(_add) * getTotalWonOf(_add);
    }

    /*\
    returns loose percentage of player
    \*/
    function getLoosePercentageOf(address _add) public view returns(uint) {
        return 100e18 / getTotalPlayedOf(_add) * getTotalLostOf(_add);
    }

    /*\
    returns draw percentage of player
    \*/
    function getDrawPercentageOf(address _add) public view returns(uint) {
        return 100e18 / getTotalPlayedOf(_add) * getTotalGamesDrawnOf(_add);
    }

    /*\
    returns information of game id
    \*/
    function getGame(uint _id) public view returns(uint, uint, address, address, address) {
        return (getState(_id), Gamelist[_id].stakes, Gamelist[_id].player1, Gamelist[_id].player2, Gamelist[_id].winner);
    }

    /*\
    returns current state of game id
    \*/
    function getState(uint _id) public view returns(uint) {
        uint state = 0;
        if(Gamelist[_id].winner != address(0x0))
            state = 3;
        else if(Gamelist[_id].player1 != address(0x0) && Gamelist[_id].player2 == address(0x0))
            state = 1;
        else if(Gamelist[_id].player1 != address(0x0) && Gamelist[_id].player2 != address(0x0))
            state = 2;
        return state;
    }

    /*\
    returns all current active games
    \*/
    function getAllActive(uint _start) public view returns(uint[] memory, uint[] memory, uint[] memory, uint) {
        uint count = 0;
        for(uint i = _start; i < currentGame; i++) {
            if(Gamelist[i].winner == address(0x0))
                count++;
        }
        uint[] memory _id = new uint[](count);
        uint[] memory _times = new uint[](count);
        uint[] memory _state = new uint[](count);
        count = 0;
        for(uint i = _start; i < currentGame; i++) {
            if(Gamelist[i].winner == address(0x0)) {
                _id[count] = i;
                _times[count] = Gamelist[i].startedAt;
                _state[count] = getState(i);
                count++;
            }
        }
        return (_id, _times, _state, block.timestamp);
    }

    /*\
    create a new game
    \*/
    function createGame(uint256 _bet) public payable returns(uint256 _id, uint256 bet, bool started) {
        require(inGame[msg.sender] == 0, "already joineed a game atm!");
        require(msg.value >= 1e16, "please provide a fee of at least 0.01 MATIC!"); 
        require(_bet >= 10e18, "Bet must be higher than 10!");
        require(_bet <= 10000e18, "bet too big!");
        require(mainToken.transferFrom(msg.sender, address(this), _bet), "bet transfer  failed!");
        if(_bet >= 100e18 && _bet < 1000e18) {
            require(erc1155.balanceOf(msg.sender, 1) > 0 ||
                    erc1155.balanceOf(msg.sender, 2) > 0 ||
                    erc1155.balanceOf(msg.sender, 3) > 0 ||
                    erc1155.balanceOf(msg.sender, 4) > 0 ||
                    erc1155.balanceOf(msg.sender, 5) > 0, "Please purchse coin! (erc1155)");
        }
        if(_bet >= 1000e18)
            require(erc721.balanceOf(msg.sender) > 0, "please purchase a nft. (erc721)");
        
        inGame[msg.sender] = currentGame;
        game memory Game = game(address(0x0), msg.sender, address(0x0), _bet, address(0x0), block.timestamp);
        stats[msg.sender].gamesPlayed.push(currentGame);
        Gamelist[currentGame] = Game;
        currentGame++;
        emit newGame(currentGame-1, msg.sender, _bet);
        return (currentGame, _bet, false);
    }

    /*\
    join a game
    \*/
    function joinGame(uint _id) public payable returns(bool){
        require(msg.value >= 1e16, "please provide a fee of at least 0.01 MATIC!"); 
        require(inGame[msg.sender] == 0, "already joineed a game atm!");
        require(mainToken.transferFrom(msg.sender, address(this), Gamelist[_id].stakes), "payment failed!");
        require(Gamelist[_id].winner == address(0x0), "game was shut down!");
        require(Gamelist[_id].player1 != address(0x0), "invalid id!");
        require(Gamelist[_id].player2 == address(0x0), "game full!");
        inGame[msg.sender] = _id;
        Gamelist[_id].player2 = msg.sender;
        stats[msg.sender].gamesPlayed.push(_id);
        emit joinedGame(_id, msg.sender, Gamelist[_id].stakes);
        return true;
    }

    /*\
    allows player to resign
    \*/
    function resign(uint _id) public returns(bool) {
        require(Gamelist[_id].player2 != address(0x0));
        require(Gamelist[_id].player1 != address(0x0));
        require(Gamelist[_id].player1 == msg.sender || Gamelist[_id].player2 == msg.sender);
        address winner;
        if(Gamelist[_id].player1 == msg.sender) {
            winner = Gamelist[_id].player2;
        } else {
            winner = Gamelist[_id].player1;
        }

        address loser;
        if(winner == Gamelist[_id].player1) {
            loser = Gamelist[_id].player2;
        } else {
            loser = Gamelist[_id].player1;
        }

        uint _burnFee = (Gamelist[_id].stakes.mul(2)).mul(6).div(100);
        mainToken.transfer(dead, _burnFee);

        uint _teamFee = (Gamelist[_id].stakes.mul(2)).div(100);
        require(IVault(team).deposit(address(mainToken), _teamFee));

        uint _LPStakingFee = (Gamelist[_id].stakes.mul(2)).mul(3).div(100);
        require(mainToken.transfer(LPstaking, _LPStakingFee));

        uint _tFee = _burnFee.add(_teamFee).add(_LPStakingFee);
        uint win = (Gamelist[_id].stakes.mul(2)).sub(_tFee);
        require(mainToken.transfer(winner, win), "transfer failed, winner!");

        stats[winner].gamesWon.push(_id);
        stats[loser].gamesLost.push(_id);
        Gamelist[_id].winner = winner;
        inGame[Gamelist[_id].player1] = 0;
        inGame[Gamelist[_id].player2] = 0;
        require(_fundAutoamtion(), "automation funding failed!");
        return true;
    }

    /*\
    cancels game if no other player joins
    \*/
    function cancel(uint _id) public returns(bool){
        require(Gamelist[_id].player2 == address(0x0));
        require(Gamelist[_id].player1 == msg.sender || isOperator[msg.sender]);
        require(mainToken.transfer(Gamelist[_id].player1, Gamelist[_id].stakes), "transfer failed!");
        inGame[Gamelist[_id].player1] = 0;
        Gamelist[_id].player2 = Gamelist[_id].player1;
        Gamelist[_id].winner = Gamelist[_id].player1;
        payable(Gamelist[_id].player1).transfer(1e16);
        return true;
    }

    /*\
    operator ends game and sets winner
    \*/
    function endGame(uint256 _id, address winner) public onlyOwner returns(bool){
        require(Gamelist[_id].winner == address(0x0));
        require(Gamelist[_id].player2 != address(0x0));
        Gamelist[_id].operator = msg.sender;

        if(winner == address(0x0)) {
            require(mainToken.transfer(Gamelist[_id].player1, Gamelist[_id].stakes), "transfer failed, 1!");
            require(mainToken.transfer(Gamelist[_id].player2, Gamelist[_id].stakes), "transfer failed, 2!");
            Gamelist[_id].winner = Gamelist[_id].operator;
        } else {
            address loser;
            if(winner == Gamelist[_id].player1) {
                loser = Gamelist[_id].player2;
            } else {
                loser = Gamelist[_id].player1;
            }
            Gamelist[_id].winner = winner;
            uint _burnFee = (Gamelist[_id].stakes.mul(2)).mul(6).div(100);
            mainToken.transfer(dead, _burnFee);

            uint _teamFee = (Gamelist[_id].stakes.mul(2)).div(100);
            require(IVault(team).deposit(address(mainToken), _teamFee));

            uint _LPStakingFee = (Gamelist[_id].stakes.mul(2)).mul(3).div(100);
            require(mainToken.transfer(LPstaking, _LPStakingFee));

            uint _tFee = _burnFee.add(_teamFee).add(_LPStakingFee);
            uint win = (Gamelist[_id].stakes.mul(2)).sub(_tFee);
            require(mainToken.transfer(winner, win), "transfer failed, winner!");
            stats[winner].gamesWon.push(_id);
            stats[loser].gamesLost.push(_id);
        }
        inGame[Gamelist[_id].player1] = 0;
        inGame[Gamelist[_id].player2] = 0;
        emit endedGame(_id, winner, Gamelist[_id].stakes);
        payable(Gamelist[_id].operator).transfer(1e16);
        require(_fundAutoamtion(), "automation funding failed!");

        return true;
    }

    function _fundAutoamtion() private returns(bool) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(link);
        router.swapExactETHForTokens {value: 1e16}(
            0,
            path,
            address(this),
            block.timestamp
        );
        link.approve(address(registry), link.balanceOf(address(this)));
        registry.addFunds(id, uint96(link.balanceOf(address(this))));
        return true;
    }


    receive() external payable {

    }
}

/*\
Created by SolidityX for Decision Game
Telegram: @solidityX
\*/