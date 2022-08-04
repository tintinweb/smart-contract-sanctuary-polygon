/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


interface IAdminData {
    function checkAdmin(string memory _appId, address _sender) external view returns (bool);
}

interface IQuizToken {
    function burn(address account, uint256 amount) external;
}

interface IGameData {

    //game
    struct GameDetail {
        uint256 id;
        uint256 category;
        string appId;
        int256 groupId;
        uint256 botType;
        string title;
        string introduction;
        string endContent;

        // v/100
        uint256 eliminateProportion;
        uint256 awardProportion;
        uint256 winNum;
        uint256[] buffIds;
        string[] events;
        //ticket
        bool ticketIsEth;
        IERC20 ticketsToken;
        uint256 ticketAmount;
        //option
        uint256 effectStartTime;
        uint256 effectEndTime;
        //option auto start
        bool daily;
        //24H
        uint256 startH;
        uint256 startM;
        bool exist;
        address creator;
    }


    function setGame(string memory _appId, GameDetail memory _game) external;

    function getGame(uint256 _id) external view returns (GameDetail memory);

    function getGames(uint256[] memory _ids) external view returns (GameDetail[] memory);

    function getAppGames(string memory _appId) external view returns (uint256[] memory);

    function getGameIds() external view returns (uint256[] memory);

    function getPlayers(uint256 _gameId, uint256 _ground) external view returns (address[] memory);

    function setPlayers(uint256 _gameId, uint256 _round, address[] memory _players) external;

    function addPlayer(uint256 _gameId, uint256 _round, address _player) external;

    function getBuffPlayers(uint256 _gameId, uint256 _round) external view returns (uint256[] memory);

    function setBuffPlayers(uint256 _gameId, uint256 _round, uint256[] memory _indexes) external;

    function addBuffPlayers(uint256 _gameId, uint256 _round, uint _index) external;

    function getTicketsPool(uint256 _gameId, uint256 _round) external view returns (uint256);

    function getGameTicket(uint256 _id) external view returns (bool isEth, IERC20 token, uint256 amount);

    //game result
    struct GameRound {
        uint256 gameId;
        address[] winners;
        uint256 participate;
        address sponsor;
        uint256 launchTime;
        int256[] eliminatePlayerIndexes;
        int256[] buffUsersIndexes;
        int256[] eventsIndexes;
        bool over;
        bool exist;
    }

    function initGameRound(uint256 _gameId, address _sponsor, uint256 _launchTime) external;

    function editGameRound(uint256 _gameId, uint256 _round, GameRound memory _gameRound) external;

    function getGameRound(uint256 _gameId, uint256 _round) external view returns (GameRound memory);

    function getGameLatestRoundNum(uint256 _gameId) external view returns (uint256);

    function getGameRoundList(uint256 _gameId) external view returns (GameRound[] memory);
}


contract Permission {
    address public owner;
    address payable public operator;
    mapping(string => address payable) appOperators;

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner");
        _;
    }

    function transferOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function isOperator(string memory _appId) public view returns (bool){
        return (operator == msg.sender || address(appOperators[_appId]) == msg.sender);
    }

    function changeOperator(address payable _newOperator) public onlyOwner {
        operator = _newOperator;
    }

    function addAppOperator(string memory _appId, address payable _newOperator) public onlyOwner {
        appOperators[_appId] = _newOperator;
    }

    function delAppOperator(string memory _appId) public onlyOwner {
        appOperators[_appId] = payable(0);
    }
}


contract Game is Permission {

    using SafeMath for uint256;

    IAdminData public adminData;
    IGameData public gameData;
    IQuizToken public buffToken;
    uint256 public buffValue;
    IERC20[] private erc20List;
    mapping(IERC20 => bool) public erc20Exist;




    constructor(address payable _operator, IAdminData _adminData, IGameData _gameData, IQuizToken _buffToken, uint256 _buffValue) {
        owner = msg.sender;
        operator = _operator;
        adminData = _adminData;
        gameData = _gameData;
        buffToken = _buffToken;
        buffValue = _buffValue;
    }


    function changeAdminData(IAdminData _newData) public onlyOwner {
        adminData = _newData;
    }

    function changeGameData(IGameData _newData) public onlyOwner {
        gameData = _newData;
    }

    function changeBuffToken(IQuizToken _newToken) public onlyOwner {
        buffToken = _newToken;
    }

    function changeBuffValue(uint256 _newValue) public onlyOwner {
        buffValue = _newValue;
    }

    function transferAsset(address payable _to) public onlyOwner {
        if (address(this).balance > 0) {
            _to.transfer(address(this).balance);
        }
        for (uint i = 0; i < erc20List.length; i++) {
            uint256 balance = erc20List[i].balanceOf(address(this));
            if (balance > 0) {
                erc20List[i].transfer(_to, balance);
            }
        }
    }


    function checkGame(uint256 _gameId) private view {
        require(_gameId != 0, "invalid quizId 0");
        require(gameData.getGame(_gameId).exist, "not exist game");
    }

    function checkGameRound(uint256 _gameId, uint256 _round) private view {
        require(gameData.getGameRound(_gameId, _round).exist, "not start game round");
    }

    function gameRoundNotOver(uint256 _gameId, uint256 _round) private view {
        require(!gameData.getGameRound(_gameId, _round).over, "over game round");
    }

    modifier onlyAdmin(string memory _appId) {
        require(adminData.checkAdmin(_appId, msg.sender) || isOperator(_appId), "Only admin");
        _;
    }


    function _addErc20(IERC20 _token) internal {
        if (!erc20Exist[_token]) {
            erc20List.push(_token);
            erc20Exist[_token] = true;
        }
    }

    function createGame(IGameData.GameDetail memory _game) public onlyAdmin(_game.appId) {
        require(_game.id != 0, "invalid gameId 0");
        IGameData.GameDetail memory game = gameData.getGame(_game.id);
        require(!game.exist, "exist game");
        game = _game;
        game.exist = true;
        game.creator = msg.sender;
        gameData.setGame(_game.appId, game);
    }

    function buyErc20Ticket(uint256 _gameId, uint256 _round) public {
        checkGameRound(_gameId, _round);
        gameRoundNotOver(_gameId, _round);
        IGameData.GameDetail memory game = gameData.getGame(_gameId);
        require(!game.ticketIsEth, "not erc20 ticket");
        (bool hasPlayer,) = _checkIsJoin(_gameId, _round, msg.sender);
        require(!hasPlayer, "already buy tickets");
        game.ticketsToken.transferFrom(msg.sender, address(this), game.ticketAmount);
        gameData.addPlayer(_gameId, _round, msg.sender);
        _addErc20(game.ticketsToken);
    }


    function buyEthTicket(uint256 _gameId, uint256 _round) public payable {
        checkGameRound(_gameId, _round);
        gameRoundNotOver(_gameId, _round);
        IGameData.GameDetail memory game = gameData.getGame(_gameId);
        require(game.ticketIsEth, "not eth ticket");
        (bool hasPlayer,) = _checkIsJoin(_gameId, _round, msg.sender);
        require(!hasPlayer, "already buy");
        require(msg.value >= game.ticketAmount, "insufficient");
        gameData.addPlayer(_gameId, _round, msg.sender);
    }

    function buyBuff(uint256 _gameId, uint256 _round, uint256 _buffId) public {
        gameRoundNotOver(_gameId, _round);
        checkGameRound(_gameId, _round);
        uint256[] memory buffIds = gameData.getGame(_gameId).buffIds;
        bool buffExist = false;
        for (uint i = 0; i < buffIds.length; i++) {
            if (buffIds[i] == _buffId) {
                buffExist = true;
                break;
            }
        }
        require(buffExist, "invalid buff");

        (bool hasPlayer, uint256 index) = _checkIsJoin(_gameId, _round, msg.sender);
        require(hasPlayer, "not in game");

        buffToken.burn(msg.sender, buffValue);
        gameData.addBuffPlayers(_gameId, _round, index);
    }

    function startGame(string memory _appId, uint256 _gameId, uint256 _launchTime) public payable {
        checkGame(_gameId);
        require(msg.value > 0, "you should prepay for gas");
        address payable thisOperator = appOperators[_appId];
        if (address(thisOperator) == address(0)) {
            thisOperator = operator;
        }
        thisOperator.transfer(msg.value);
        gameData.initGameRound(_gameId, msg.sender, _launchTime);
    }


    function gameRoundOver(string memory _appId, uint256 _gameId, uint256 _round, address[] memory _winners,
        int256[] memory _eliminatePlayerIndexes, int256[] memory _buffUsersIndexes, int256[] memory _eventsIndexes) public
    {
        require(isOperator(_appId), "only operator");
        checkGameRound(_gameId, _round);
        gameRoundNotOver(_gameId, _round);
        IGameData.GameRound memory _gameRound = gameData.getGameRound(_gameId, _round);
        _gameRound.winners = _winners;
        _gameRound.participate = gameData.getPlayers(_gameId, _round).length;
        _gameRound.eliminatePlayerIndexes = _eliminatePlayerIndexes;
        _gameRound.buffUsersIndexes = _buffUsersIndexes;
        _gameRound.eventsIndexes = _eventsIndexes;
        _gameRound.over = true;
        gameData.editGameRound(_gameId, _round, _gameRound);
        _awardWinner(_gameId, _winners, _round);
    }


    function getErc20List() public view returns (IERC20[] memory){
        return erc20List;
    }

    function getGameIds() public view returns (uint256[] memory){
        uint256[] memory ids = gameData.getGameIds();
        uint256[] memory availableIds = new uint256[](100);
        uint256 size = 0;
        for (uint i = 0; i < ids.length; i++) {
            if (size >= 100) {
                break;
            }
            IGameData.GameDetail memory game = gameData.getGame(ids[i]);
            if (game.effectEndTime >= block.timestamp) {
                size++;
                availableIds[size] = ids[i];
            }
        }

        return availableIds;
    }

    function _awardWinner(uint256 _gameId, address[] memory _winners, uint256 _round) internal {
        if (_winners.length == 0) {
            return;
        }
        IGameData.GameDetail memory game = gameData.getGame(_gameId);
        uint256 ticketPoolAmount = gameData.getTicketsPool(_gameId, _round);
        uint256 awardAmount = ticketPoolAmount.div(100).mul(game.awardProportion);
        uint256 remainingAmount = ticketPoolAmount.sub(awardAmount);
        uint256 singleAward = awardAmount.div(_winners.length);

        for (uint i = 0; i < _winners.length; i++) {
            if (game.ticketIsEth) {
                game.ticketsToken.transfer(_winners[i], singleAward);
            } else {
                payable(_winners[i]).transfer(singleAward);
            }
        }
        _refundTicketPool(game, remainingAmount);
    }

    function _refundTicketPool(IGameData.GameDetail memory _game, uint256 _remainingAmount) internal {
        if (_game.ticketIsEth) {
            _game.ticketsToken.transfer(_game.creator, _remainingAmount);
        } else {
            payable(_game.creator).transfer(_remainingAmount);
        }
    }

    function _checkIsJoin(uint256 _gameId, uint256 _round, address _player) internal view returns (bool hasPlayer, uint256 index){
        address[] memory players = gameData.getPlayers(_gameId, _round);
        for (uint i = 0; i < players.length; i++) {
            if (players[i] == _player) {
                hasPlayer = true;
                index = i;
                break;
            }
        }
        return (hasPlayer, index);
    }
}