// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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


contract DataStorage {
    using SafeMath for uint256;
    address public owner;
    mapping(address => bool) public operators;
    mapping(string => address[]) public admins;


    struct QuizDetail {
        uint256 id;
        string app_id;
        string[] questions;
        uint256 amount;
        int256 group;
        uint botType;
        bool exist;
        bool over;
        uint256 startTime;
        uint256 activeTime;
        string title;
        string photo;
        uint256 participate;
    }

    uint256[] private shouldAwardQuizIds;
    mapping(uint256 => address[]) private inductees;
    mapping(uint256 => QuizDetail) private quizzes;
    mapping(string => uint256[]) public appQuizzes;

    struct Lottery {
        IERC20 token;
        uint256[] amounts;
        uint256[] fixedNum;
        uint256[] proportionNum;
        uint256 totalAmount;
        bool isEth;
        bool over;
        bool exist;
    }

    mapping(address => uint256) private ethBank;
    mapping(address => mapping(IERC20 => uint256)) private erc20Bank;
    mapping(uint256 => mapping(uint256 => address[])) private lotteryResults;
    mapping(uint256 => Lottery) private lotteries;
    mapping(uint256 => address) private lotteryCreator;



    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyOperator(){
        require(operators[msg.sender], "Only Operator");
        _;
    }

    function transferOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
        operators[_newOwner] = true;
    }

    function addOperator(address _newOperator) public onlyOwner {
        operators[_newOperator] = true;
    }

    function addAdmin(string memory _appId, address _admin) public onlyOwner {
        admins[_appId].push(_admin);
    }

    function delAdmin(string memory _appId, address _delAdmin) public onlyOwner {
        for (uint i = 0; i < admins[_appId].length; i++) {
            if (admins[_appId][i] == _delAdmin) {
                admins[_appId][i] = address(0);
                return;
            }
        }
    }

    function checkAdmin(string memory _appId, address _sender) public view returns (bool){
        for (uint i = 0; i < admins[_appId].length; i++) {
            if (admins[_appId][i] == _sender) {
                return true;
            }
        }
        return false;
    }


    function getAppAdmins(string memory _appId) public view returns (address[] memory){
        return admins[_appId];
    }



    constructor() {
        owner = msg.sender;
        operators[msg.sender] = true;
    }


    //Quiz
    function setQuiz(string memory _appId, QuizDetail memory _quiz) public onlyOperator {
        if (!quizzes[_quiz.id].exist) {
            shouldAwardQuizIds.push(_quiz.id);
            appQuizzes[_appId].push(_quiz.id);
        }
        quizzes[_quiz.id] = _quiz;
    }

    function overQuiz(uint256 _quizId) public onlyOperator {
        quizzes[_quizId].over = true;
        _popAwardQuiz(_quizId);
    }

    function getQuiz(uint256 _quizId) public onlyOperator view returns (QuizDetail memory) {
        return quizzes[_quizId];
    }

    function getQuizzes(uint256[] memory _quizIds) public view returns (QuizDetail[] memory) {
        QuizDetail[] memory details = new QuizDetail[](_quizIds.length);
        for (uint i = 0; i < _quizIds.length; i++) {
            details[i] = quizzes[_quizIds[i]];
        }
        return details;
    }

    function addInductees(uint256 _quizId, address[] memory _inductees, uint256 _participate) public onlyOperator {
        quizzes[_quizId].participate = _participate;
        inductees[_quizId] = _inductees;
    }

    function getInductees(uint256 _quizId) public view returns (address[] memory){
        return inductees[_quizId];
    }

    function getShouldAwardQuizIds() public view returns (uint256[] memory){
        return shouldAwardQuizIds;
    }

    function getAppQuizIds(string memory _appId) public view returns (uint256[] memory){
        return appQuizzes[_appId];
    }

    function _popAwardQuiz(uint256 _quizId) internal {
        uint256 lastShouldAwardQuizIdIndex = shouldAwardQuizIds.length - 1;
        uint256 shouldAwardQuizIdIndex = 0;
        for (uint256 i = 0; i < lastShouldAwardQuizIdIndex; i ++) {
            if (shouldAwardQuizIds[i] == _quizId) {
                shouldAwardQuizIdIndex = i;
            }
        }

        // When the question to delete is the last question, the swap operation is unnecessary
        if (lastShouldAwardQuizIdIndex != shouldAwardQuizIdIndex) {
            shouldAwardQuizIds[shouldAwardQuizIdIndex] = shouldAwardQuizIds[lastShouldAwardQuizIdIndex];
        }
        shouldAwardQuizIds.pop();
    }


    //Lottery

    function setLottery(address _creator, uint256 _lotteryId, Lottery memory _lottery) public onlyOperator {
        if (!lotteries[_lotteryId].exist) {
            lotteryCreator[_lotteryId] = _creator;
        }
        lotteries[_lotteryId] = _lottery;
    }

    function overLottery(uint256 _lotteryId) public onlyOperator {
        lotteries[_lotteryId].over = true;
    }

    function getLottery(uint256 _lotteryId) public view returns (Lottery memory) {
        return lotteries[_lotteryId];
    }

    function getLotteries(uint256[] memory _lotteryIds) public view returns (Lottery[] memory){
        Lottery[] memory details = new Lottery[](_lotteryIds.length);
        for (uint i = 0; i < _lotteryIds.length; i++) {
            details[i] = lotteries[_lotteryIds[i]];
        }
        return details;
    }


    function setLotteryResult(uint256 _lotteryId, uint256 _index, address[] memory _winner) public onlyOperator {
        lotteryResults[_lotteryId][_index] = _winner;
    }

    function getLotteryResult(uint256 _lotteryId, uint256 _index) public view returns (address[] memory){
        return lotteryResults[_lotteryId][_index];
    }

    function getLotteryCreator(uint256 _lotteryId) public view returns (address){
        return lotteryCreator[_lotteryId];
    }

    function setEthBank(address _holder, uint256 _amount) public onlyOperator {
        ethBank[_holder] = _amount;
    }

    function getEthBank(address _holder) public view returns (uint256){
        return ethBank[_holder];
    }

    function setErc20Bank(address _holder, IERC20 _token, uint256 _amount) public onlyOperator {
        erc20Bank[_holder][_token] = _amount;
    }

    function getErc20Bank(address _holder, IERC20 _token) public view returns (uint256){
        return erc20Bank[_holder][_token];
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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


contract Permission {
    address public owner;
    mapping(address => bool) public operators;
    modifier onlyOperator(){
        require(operators[msg.sender], "Only Operator");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner");
        _;
    }

    function transferOwner(address _newOwner) public onlyOwner {
        operators[owner] = false;
        owner = _newOwner;
        operators[_newOwner] = true;
    }

    function addOperator(address _newOperator) public onlyOwner {
        operators[_newOperator] = true;
    }

    function delOperator(address _removeOperator) public onlyOwner {
        operators[_removeOperator] = false;
    }

}


contract GameDataStorage is Permission {
    using SafeMath for uint256;

    constructor() {
        owner = msg.sender;
        addOperator(msg.sender);
    }

    //game
    struct GameDetail {
        uint256 id;
        uint256 category;
        string appId;
        int256 groupId;
        uint256 botType;
        string title;
        string introduction;
        string story;

        // v/100
        uint256 eliminateProportion;
        uint256 awardProportion;
        uint256 winNum;
        uint256[] buffIds;
        string buffDesc;
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

    mapping(uint256 => GameDetail) private games;
    mapping(string => uint256[]) private appGames;
    mapping(uint256 => mapping(uint256 => uint256[])) private buffPlayerIndexes;
    mapping(uint256 => mapping(uint256 => address[])) private players;
    mapping(uint256 => mapping(uint256 => uint256)) private ticketsPoll;

    uint256[] private gameIds;

    function setGame(string memory _appId, GameDetail memory _game) public onlyOperator {
        if (!games[_game.id].exist) {
            games[_game.id] = _game;
            appGames[_appId].push(_game.id);
            gameIds.push(_game.id);
        }
    }

    function getGame(uint256 _id) public view returns (GameDetail memory) {
        return games[_id];
    }

    function getGames(uint256[] memory _ids) public view returns (GameDetail[] memory) {
        GameDetail[] memory details = new GameDetail[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            details[i] = games[_ids[i]];
        }
        return details;
    }


    function getAppGames(string memory _appId) public view returns (uint256[] memory){
        return appGames[_appId];
    }

    function getGameIds() public view returns (uint256[] memory){
        return gameIds;
    }

    function getPlayers(uint256 _gameId, uint256 _ground) public view returns (address[] memory){
        return players[_gameId][_ground];
    }

    function setPlayers(uint256 _gameId, uint256 _round, address[] memory _players) public onlyOperator {

        for (uint i = 0; i < _players.length; i++) {
            players[_gameId][_round].push(_players[i]);
            ticketsPoll[_gameId][_round] = ticketsPoll[_gameId][_round].add(games[_gameId].ticketAmount);
        }
        if (players[_gameId][_round].length == 0) {
            players[_gameId][_round] = _players;
        } else {
            for (uint i = 0; i < _players.length; i++) {
                players[_gameId][_round].push(_players[i]);
            }
        }
    }

    function addPlayer(uint256 _gameId, uint256 _round, address _player) public onlyOperator {
        players[_gameId][_round].push(_player);
        ticketsPoll[_gameId][_round] = ticketsPoll[_gameId][_round].add(games[_gameId].ticketAmount);
    }

    function getBuffPlayers(uint256 _gameId, uint256 _round) public view returns (uint256[] memory){
        return buffPlayerIndexes[_gameId][_round];
    }

    function setBuffPlayers(uint256 _gameId, uint256 _round, uint256[] memory _indexes) public onlyOperator {
        if (buffPlayerIndexes[_gameId][_round].length == 0) {
            buffPlayerIndexes[_gameId][_round] = _indexes;
        } else {
            for (uint i = 0; i < _indexes.length; i++) {
                buffPlayerIndexes[_gameId][_round].push(_indexes[i]);
            }
        }
    }

    function addBuffPlayers(uint256 _gameId, uint256 _round, uint _index) public onlyOperator {
        buffPlayerIndexes[_gameId][_round].push(_index);
    }

    function getTicketsPool(uint256 _gameId, uint256 _round) public view returns (uint256){
        return ticketsPoll[_gameId][_round];
    }




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

    mapping(uint256 => GameRound[]) private gameRoundList;


    function initGameRound(uint256 _gameId, address _sponsor, uint256 _launchTime) public onlyOperator {
        if (games[_gameId].exist) {
            GameRound memory gameRound = GameRound(
                _gameId,
                new address[](0),
                0,
                _sponsor,
                _launchTime,
                new int256[](0),
                new int256[](0),
                new int256[](0),
                false,
                true
            );
            gameRoundList[_gameId].push(gameRound);
        }
    }

    function editGameRound(uint256 _gameId, uint256 _round, GameRound memory _gameRound) public onlyOperator {
        gameRoundList[_gameId][_round] = _gameRound;
    }

    function getGameRound(uint256 _gameId, uint256 _round) public view returns (GameRound memory){
        GameRound memory gameRound = GameRound(
            0,
            new address[](0),
            0,
            address(0),
            0,
            new int256[](0),
            new int256[](0),
            new int256[](0),
            false,
            false
        );

        if (gameRoundList[_gameId].length == 0) {
            return gameRound;
        }

        if (gameRoundList[_gameId].length.sub(1) < _round) {
            return gameRound;
        }

        return gameRoundList[_gameId][_round];
    }

    function getGameLatestRoundNum(uint256 _gameId) public view returns (int256){
        if (gameRoundList[_gameId].length > 0) {
            return int256(gameRoundList[_gameId].length.sub(1));
        } else {
            return - 1;
        }

    }

    function getGameRoundList(uint256 _gameId) public view returns (GameRound[] memory){
        return gameRoundList[_gameId];
    }


    function getGameAndRound(uint256 _gameId) public view returns (GameDetail memory detail, GameRound[] memory gameRounds){
        return (games[_gameId], gameRoundList[_gameId]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "subtraction overflow");
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
        string story;

        // v/100
        uint256 eliminateProportion;
        uint256 awardProportion;
        uint256 winNum;
        uint256[] buffIds;
        string buffDesc;
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

    function getGameLatestRoundNum(uint256 _gameId) external view returns (int256);

    function getGameRoundList(uint256 _gameId) external view returns (GameRound[] memory);
}


contract Permission {
    address public owner;
    mapping(address => bool) public operators;
    modifier onlyOperator(){
        require(operators[msg.sender], "Only Operator");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner");
        _;
    }

    function transferOwner(address _newOwner) public onlyOwner {
        operators[owner] = false;
        owner = _newOwner;
        operators[_newOwner] = true;
    }

    function addOperator(address _newOperator) public onlyOwner {
        operators[_newOperator] = true;
    }

    function delOperator(address _removeOperator) public onlyOwner {
        operators[_removeOperator] = false;
    }

}


contract GameLogic is Permission {

    using SafeMath for uint256;

    IGameData public gameData;

    mapping(uint256 => mapping(uint256 => address[])) private winners;
    mapping(uint256 => mapping(uint256 => int256[])) private  eliminatePlayerIndexes;
    mapping(uint256 => mapping(uint256 => int256[])) private buffUsersIndexes;
    mapping(uint256 => mapping(uint256 => int256[])) private eventsIndexes;
    mapping(uint256 => mapping(uint256 => int256[]))private remainPlayers;

    constructor(IGameData _gameData) {
        gameData = _gameData;
        owner = msg.sender;
        operators[msg.sender] = true;
    }

    function addEliminatePlayer(uint256 _gameId, uint256 _round, int256 _index) public onlyOperator {
        eliminatePlayerIndexes[_gameId][_round].push(_index);
    }

    function getEliminatePlayers(uint256 _gameId, uint256 _round) public view returns (int256[] memory){
        return eliminatePlayerIndexes[_gameId][_round];
    }

    function addEvent(uint256 _gameId, uint256 _round, int256 _index) public onlyOperator {
        eventsIndexes[_gameId][_round].push(_index);
    }

    function getEventsIndexes(uint256 _gameId, uint256 _round) public view returns (int256[] memory){
        return eventsIndexes[_gameId][_round];
    }

    function getbuffUsersIndexes(uint256 _gameId, uint256 _round) public view returns (int256[] memory){
        return eventsIndexes[_gameId][_round];
    }

    function addBufferUserIndex(uint256 _gameId, uint256 _round, int256 _index) public onlyOperator {
        buffUsersIndexes[_gameId][_round].push(_index);
    }


    function triggerBuff(uint256 _gameId, uint256 _round, int256 _index) public onlyOperator {
        buffUsersIndexes[_gameId][_round].push(_index);
        (bool hasIndex,uint256 index) = _checkHasIndex(uint256(_index), eliminatePlayerIndexes[_gameId][_round]);
        if (hasIndex) {
            eliminatePlayerIndexes[_gameId][_round][index] = - 1;
            eventsIndexes[_gameId][_round][index] = - 1;
            remainPlayers[_gameId][_round].push(_index);
        }
    }

    function getWinners(uint256 _gameId, uint256 _round) public view returns (address[] memory){
        return winners[_gameId][_round];
    }


    function eliminatePlayer(uint256 _gameId, uint256 _round, int256 _index) public onlyOperator {
        IGameData.GameDetail memory game = gameData.getGame(_gameId);
        if (_randomNumber(100, game.eliminateProportion) > game.eliminateProportion || remainPlayers[_gameId][_round].length < game.winNum) {
            remainPlayers[_gameId][_round].push(_index);
            return;
        }
        eliminatePlayerIndexes[_gameId][_round].push(_index);
        eventsIndexes[_gameId][_round].push(int256(_randomNumber(game.events.length, game.events.length)));
    }


    function calculateResult(uint256 _gameId, uint256 _round) public onlyOperator returns
    (int256[] memory _eliminatePlayerIndexes,
        int256[] memory _buffUserIndexes,
        int256[] memory _eventsIndexes,
        address[] memory _winners){

        IGameData.GameDetail memory game = gameData.getGame(_gameId);
        address[] memory players = gameData.getPlayers(_gameId, _round);

        if (players.length <= game.winNum) {
            winners[_gameId][_round] = players;
        } else {
            while (remainPlayers[_gameId][_round].length > game.winNum) {
                uint256 eliminateNum = remainPlayers[_gameId][_round].length.mul(game.eliminateProportion).div(100);
                if (eliminateNum == 0) {
                    eliminateNum = 1;
                }
                for (uint i = 0; i < eliminateNum; i++) {
                    uint256 eliminateIndex = _randomNumber(remainPlayers[_gameId][_round].length, eliminateNum);
                    _calculateEliminate(_gameId, _round, eliminateIndex, game.events.length);
                }
            }
            _calculateWinner(_gameId, _round, players);
        }

        return (eliminatePlayerIndexes[_gameId][_round], buffUsersIndexes[_gameId][_round], eventsIndexes[_gameId][_round], winners[_gameId][_round]);
    }

    function _calculateEliminate(uint256 _gameId, uint256 _round, uint256 _eliminateIndex, uint256 _eventLength) internal returns (bool)  {
        bool eliminate = false;
        uint256 playerIndex = uint256(remainPlayers[_gameId][_round][_eliminateIndex]);
        (bool hasIndex,) = _checkHasIndex(playerIndex, buffUsersIndexes[_gameId][_round]);
        if (_checkHasBuff(_gameId, _round, playerIndex) && !hasIndex) {
            buffUsersIndexes[_gameId][_round].push(int256(playerIndex));
            eliminatePlayerIndexes[_gameId][_round].push(- 1);
        } else {
            eliminatePlayerIndexes[_gameId][_round].push(int256(playerIndex));
            eventsIndexes[_gameId][_round].push(int256(_randomNumber(_eventLength, _eventLength)));

            (remainPlayers[_gameId][_round][_eliminateIndex], remainPlayers[_gameId][_round][remainPlayers[_gameId][_round].length - 1]) =
            (remainPlayers[_gameId][_round][remainPlayers[_gameId][_round].length - 1], remainPlayers[_gameId][_round][_eliminateIndex]);
            remainPlayers[_gameId][_round].pop();
            eliminate = true;
        }
        return eliminate;
    }

    function _calculateWinner(uint256 _gameId, uint256 _round, address[] memory _players) internal {
        for (uint i = 0; i < remainPlayers[_gameId][_round].length; i++) {
            uint256 index = uint256(remainPlayers[_gameId][_round][i]);
            winners[_gameId][_round].push(_players[index]);
        }
    }


    function _checkHasBuff(uint256 _gameId, uint256 _round, uint256 _index) internal view returns (bool){
        uint256[] memory indexes = gameData.getBuffPlayers(_gameId, _round);
        bool hasBuff = false;
        for (uint i = 0; i < indexes.length; i++) {
            if (indexes[i] == _index) {
                hasBuff = true;
            }
        }
        return hasBuff;
    }

    function _checkHasIndex(uint256 _index, int256[] memory _list) internal pure returns (bool, uint256){
        bool hasIndex = false;
        uint256 index = 0;
        for (uint i = 0; i < _list.length; i++) {
            if (_list[i] == int256(_index)) {
                hasIndex = true;
                index = i;
            }
        }
        return (hasIndex, index);
    }

    function _randomNumber(uint256 _scope, uint256 _salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encode(abi.encodePacked(block.timestamp, block.difficulty), _salt))) % _scope;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "subtraction overflow");
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
        string story;

        // v/100
        uint256 eliminateProportion;
        uint256 awardProportion;
        uint256 winNum;
        uint256[] buffIds;
        string buffDesc;
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

    function getGameLatestRoundNum(uint256 _gameId) external view returns (int256);

    function getGameRoundList(uint256 _gameId) external view returns (GameRound[] memory);
}


interface IGameLogic {
    function eliminatePlayer(uint256 _gameId, uint256 _round, int256 _index) external;

    function getWinners(uint256 _gameId, uint256 _round) external view returns (address[] memory);

    function getbuffUsersIndexes(uint256 _gameId, uint256 _round) external view returns (uint256[] memory);

    function getEventsIndexes(uint256 _gameId, uint256 _round) external view returns (uint256[] memory);

    function getEliminatePlayers(uint256 _gameId, uint256 _round) external view returns (uint256[] memory);

    function triggerBuff(uint256 _gameId, uint256 _round, uint256 _index) external;

    function calculateResult(uint256 _gameId, uint256 _round) external returns
    (int256[] memory _eliminatePlayerIndexes,
        int256[] memory _buffUserIndexes,
        int256[] memory _eventsIndexes,
        address[] memory _winners);
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
    IGameLogic public gameLogic;
    IQuizToken public buffToken;
    uint256 public buffValue;
    IERC20[] public erc20List;
    mapping(IERC20 => bool) public erc20Exist;
    mapping(uint256 => mapping(uint256 => uint256))private newPlayerIndex;

    uint256 public availableSize = 100;

    constructor(address payable _operator, IAdminData _adminData, IGameData _gameData, IGameLogic _gameLogic, IQuizToken _buffToken, uint256 _buffValue) {
        owner = msg.sender;
        operator = _operator;
        adminData = _adminData;
        gameData = _gameData;
        gameLogic = _gameLogic;
        buffToken = _buffToken;
        buffValue = _buffValue;
    }

    function setAvailableSize(uint256 _newSize) public onlyOwner {
        availableSize = _newSize;
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

    function getAvailableGameIds() public view returns (uint256[] memory){
        uint256[] memory availableIds = new uint256[](availableSize);
        uint256 size = 0;
        for (uint i = 0; i < gameData.getGameIds().length; i++) {
            if (size >= 100) {
                break;
            }
            IGameData.GameDetail memory game = gameData.getGame(gameData.getGameIds()[i]);
            if (game.effectEndTime >= block.timestamp) {
                size++;
                availableIds[size] = game.id;
            }
        }
        return availableIds;
    }



    function checkGame(uint256 _gameId) private view {
        require(_gameId != 0, "Invalid id");
        require(gameData.getGame(_gameId).exist, "Not exist game");
    }

    function checkGameRound(uint256 _gameId, uint256 _round) private view {
        require(gameData.getGameRound(_gameId, _round).exist, "Not start round");
    }

    function gameRoundNotOver(uint256 _gameId, uint256 _round) private view {
        require(!gameData.getGameRound(_gameId, _round).over, "Over round");
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
        require(_game.id != 0, "Invalid id");
        IGameData.GameDetail memory game = gameData.getGame(_game.id);
        require(!game.exist, "Exist game");
        game = _game;
        game.exist = true;
        game.creator = msg.sender;
        gameData.setGame(_game.appId, game);
    }

    function buyTicket(uint256 _gameId, uint256 _round) public payable {
        checkGameRound(_gameId, _round);
        gameRoundNotOver(_gameId, _round);
        IGameData.GameDetail memory game = gameData.getGame(_gameId);
        (bool hasPlayer,) = _checkIsJoin(_gameId, _round, msg.sender);
        require(!hasPlayer, "Has tickets");
        if (game.ticketIsEth) {
            require(msg.value >= game.ticketAmount, "Insufficient");
        } else {
            game.ticketsToken.transferFrom(msg.sender, address(this), game.ticketAmount);
        }
        gameData.addPlayer(_gameId, _round, msg.sender);
        gameLogic.eliminatePlayer(_gameId, _round, int256(newPlayerIndex[_gameId][_round]));
        newPlayerIndex[_gameId][_round] += 1;
    }


    function buyBuff(uint256 _gameId, uint256 _round, uint256 _buffId) public {
        gameRoundNotOver(_gameId, _round);
        checkGameRound(_gameId, _round);
        require(_checkBuffExist(_gameId, _buffId), "not buff");
        (bool hasPlayer, uint256 index) = _checkIsJoin(_gameId, _round, msg.sender);
        require(hasPlayer, "Not in round");
        require(!_checkHasBuff(_gameId, _round, index), "Has buff");
        buffToken.burn(msg.sender, buffValue);
        gameData.addBuffPlayers(_gameId, _round, index);
        gameLogic.triggerBuff(_gameId, _round, index);
    }

    function startGame(string memory _appId, uint256 _gameId, uint256 _launchTime) public payable {
        checkGame(_gameId);
        require(msg.value > 0, "Prepay for gas");
        address payable thisOperator = appOperators[_appId];
        if (address(thisOperator) == address(0)) {
            thisOperator = operator;
        }
        thisOperator.transfer(msg.value);
        gameData.initGameRound(_gameId, msg.sender, _launchTime);
    }


    function gameRoundOver(string memory _appId, uint256 _gameId, uint256 _round) public
    {
        require(isOperator(_appId), "Only operator");
        checkGameRound(_gameId, _round);
        gameRoundNotOver(_gameId, _round);
        address[] memory players = gameData.getPlayers(_gameId, _round);
        IGameData.GameRound memory _gameRound = gameData.getGameRound(_gameId, _round);
        (int256[] memory _eliminatePlayerIndexes,
        int256[] memory _buffUserIndexes,
        int256[] memory _eventsIndexes,
        address[] memory _winners) = gameLogic.calculateResult(_gameId, _round);
        _gameRound.winners = _winners;
        _gameRound.participate = players.length;
        _gameRound.eliminatePlayerIndexes = _eliminatePlayerIndexes;
        _gameRound.buffUsersIndexes = _buffUserIndexes;
        _gameRound.eventsIndexes = _eventsIndexes;
        _gameRound.over = true;
        gameData.editGameRound(_gameId, _round, _gameRound);
        _awardWinner(_gameId, _winners, _round);
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
                payable(_winners[i]).transfer(singleAward);
            } else {
                game.ticketsToken.transfer(_winners[i], singleAward);

            }
        }
        _refundTicketPool(game, remainingAmount);
    }

    function _refundTicketPool(IGameData.GameDetail memory _game, uint256 _remainingAmount) internal {
        if (_game.ticketIsEth) {
            payable(_game.creator).transfer(_remainingAmount);
        } else {
            _game.ticketsToken.transfer(_game.creator, _remainingAmount);
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

    function _checkBuffExist(uint256 _gameId, uint256 _buffId) internal view returns (bool){
        uint256[] memory buffIds = gameData.getGame(_gameId).buffIds;
        bool buffExist = false;
        for (uint i = 0; i < buffIds.length; i++) {
            if (buffIds[i] == _buffId) {
                buffExist = true;
                break;
            }
        }
        return buffExist;

    }

    function _checkHasBuff(uint256 _gameId, uint256 _round, uint256 _index) internal view returns (bool){
        uint256[] memory indexes = gameData.getBuffPlayers(_gameId, _round);
        bool hasBuff = false;
        for (uint i = 0; i < indexes.length; i++) {
            if (indexes[i] == _index) {
                hasBuff = true;
            }
        }
        return hasBuff;
    }

}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin contracts with minor modifications:
// - Modified Solidity version
// - Formatted code
// - Shortened revert messages
// - Removed unused methods
// - Convert to `type(*).*` notation
// <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/SafeCast.sol>

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: not positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(
            value <= uint256(type(int256).max),
            "SafeCast: int256 overflow"
        );
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin contracts with minor modifications:
// - Modified Solidity version
// - Formatted code
// - Shortened some revert messages
// - Removed unused methods
// - Added `ceilDiv` method
// <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/math/SafeMath.sol>

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: mul overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by 0");
        return a / b;
    }

    /**
     * @dev Returns the ceiling integer division of two unsigned integers,
     * reverting on division by zero. The result is rounded towards up the
     * nearest integer, instead of truncating the fractional part.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     * - The sum of the dividend and divisor cannot overflow.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: ceiling division by 0");
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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


interface IDataStorage {

    struct Lottery {
        IERC20 token;
        uint256[] amounts;
        uint256[] fixedNum;
        uint256[] proportionNum;
        uint256 totalAmount;
        bool isEth;
        bool over;
        bool exist;
    }

    function checkAdmin(string memory _appId, address _sender) external view returns (bool);

    function getInductees(uint256 _quizId) external view returns (address[] memory);

    function setLottery(address _creator, uint256 _lotteryId, Lottery memory _lottery) external;

    function overLottery(uint256 _lotteryId) external;

    function getLottery(uint256 _lotteryId) external view returns (Lottery memory);

    function getLotteries(uint256[] memory _lotteryIds) external view returns (Lottery[] memory);

    function setLotteryResult(uint256 _lotteryId, uint256 _index, address[] memory _winner) external;

    function getLotteryResult(uint256 _lotteryId, uint256 _index) external view returns (address[] memory);

    function getLotteryCreator(uint256 _lotteryId) external view returns (address);

    function setEthBank(address _holder, uint256 _amount) external;

    function getEthBank(address _holder) external view returns (uint256);

    function setErc20Bank(address _holder, IERC20 _token, uint256 _amount) external;

    function getErc20Bank(address _holder, IERC20 _token) external view returns (uint256);

}

contract LotteryPool {
    using SafeMath for uint256;
    address public owner;
    mapping(address => bool) public operators;
    IDataStorage public dataStorage;
    IERC20[] private erc20List;

    constructor(address _operator, IDataStorage _storage){
        owner = msg.sender;
        dataStorage = _storage;
        operators[msg.sender] = true;
        operators[_operator] = true;
    }

    function transferOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
        operators[_newOwner] = true;
    }

    function addOperator(address _newOperator) public onlyOwner {
        operators[_newOperator] = true;
    }

    function changeStorage(IDataStorage _newStorage) public onlyOwner {
        dataStorage = _newStorage;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyOperator(){
        require(operators[msg.sender], "Only Operator");
        _;
    }

    modifier onlyAdmin(string memory _appId, address _sender){
        bool isAdmin = dataStorage.checkAdmin(_appId, _sender);
        require(isAdmin || operators[msg.sender], "Only Admin");
        _;
    }

    modifier newLottery(uint256 _lotteryId){
        require(!dataStorage.getLottery(_lotteryId).exist, "exist lottery");
        _;
    }

    modifier notOverLottery(uint256 _lotteryId){
        require(dataStorage.getLottery(_lotteryId).exist, "not exist lottery");
        require(!dataStorage.getLottery(_lotteryId).over, "over lottery");
        _;
    }

    mapping(uint256 => address[]) remainLotteryInductees;


    function getErc20List() public view returns (IERC20[] memory){
        return erc20List;
    }


    function _erc20Lottery(IERC20 _token, uint256 _amount, address[] memory _receivers) internal {
        if (_receivers.length == 0) {
            return;
        }
        require(_token.balanceOf(address(this)) >= _amount, "token remain not enough");
        uint256 singleAmount = _amount.div(_receivers.length);
        for (uint i = 0; i < _receivers.length; i++) {
            _token.transfer(_receivers[i], singleAmount);
        }
    }

    function _ethLottery(uint256 _amount, address[] memory _receivers) internal {
        if (_receivers.length == 0) {
            return;
        }
        require(address(this).balance >= _amount, "eth not enough");
        uint256 singleAmount = _amount.div(_receivers.length);
        for (uint i = 0; i < _receivers.length; i++) {
            payable(_receivers[i]).transfer(singleAmount);
        }
    }

    function createLottery(string memory _appId, uint256 _lotteryId, IERC20 _rewardToken, uint256[] memory _fixedNum, uint256[] memory _proportionNum, uint256[] memory _amounts) public newLottery(_lotteryId)
    onlyAdmin(_appId, msg.sender) {
        require(_amounts.length == _fixedNum.length || _amounts.length == _proportionNum.length, "amounts and lottery number not match");
        uint256 _amount = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            _amount = _amount.add(_amounts[i]);
        }
        require(_amount > 0, "total amount should be greater than zero");
        _rewardToken.transferFrom(msg.sender, address(this), _amount);
        erc20List.push(_rewardToken);

        IDataStorage.Lottery memory lottery = dataStorage.getLottery(_lotteryId);
        lottery.exist = true;
        lottery.token = _rewardToken;
        lottery.amounts = _amounts;
        lottery.totalAmount = _amount;
        lottery.fixedNum = _fixedNum;
        lottery.proportionNum = _proportionNum;

        dataStorage.setLottery(msg.sender, _lotteryId, lottery);
        uint256 lastBalance = dataStorage.getErc20Bank(msg.sender, _rewardToken);
        dataStorage.setErc20Bank(msg.sender, _rewardToken, lastBalance.add(_amount));
    }

    function createEthLottery(string memory _appId, uint256 _lotteryId, uint256[] memory _fixedNum, uint256[] memory _proportionNum, uint256[] memory _amounts) public payable newLottery(_lotteryId)
    onlyAdmin(_appId, msg.sender) {
        require(_amounts.length == _fixedNum.length || _amounts.length == _proportionNum.length, "amounts and lottery number not match");
        uint256 _amount = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            _amount = _amount.add(_amounts[i]);
        }
        require(_amount > 0, "total amount should be greater than zero");
        require(msg.value >= _amount, "sent value should be greater amount");
        IDataStorage.Lottery memory lottery = dataStorage.getLottery(_lotteryId);
        lottery.exist = true;
        lottery.isEth = true;
        lottery.amounts = _amounts;
        lottery.totalAmount = _amount;
        lottery.fixedNum = _fixedNum;
        lottery.proportionNum = _proportionNum;

        dataStorage.setLottery(msg.sender, _lotteryId, lottery);
        uint256 lastBalance = dataStorage.getEthBank(msg.sender);
        dataStorage.setEthBank(msg.sender, lastBalance.add(msg.value));
    }


    function drawALottery(uint256 _lotteryId) public onlyOperator {
        IDataStorage.Lottery memory lottery = dataStorage.getLottery(_lotteryId);
        if (!lottery.exist) {
            return;
        }
        require(!lottery.over, "lottery is over");
        dataStorage.overLottery(_lotteryId);
        if (lottery.fixedNum.length > 0) {
            for (uint i = 0; i < lottery.fixedNum.length; i++) {
                _drawALotteryByIndex(lottery, _lotteryId, i, true);
            }
        } else {
            for (uint i = 0; i < lottery.proportionNum.length; i++) {
                _drawALotteryByIndex(lottery, _lotteryId, i, false);
            }
        }
    }

    function _drawALotteryByIndex(IDataStorage.Lottery memory _lottery, uint256 _lotteryId, uint256 _index, bool isFixNum) internal {
        if (_lottery.amounts[_index] == 0) {
            return;
        }

        remainLotteryInductees[_lotteryId] = dataStorage.getInductees(_lotteryId);

        uint256 lotteryNum = 0;
        if (isFixNum) {
            require(_index <= _lottery.fixedNum.length, "lottery index out of bounds");
            lotteryNum = _lottery.fixedNum[_index];
            if (lotteryNum > remainLotteryInductees[_lotteryId].length) {
                lotteryNum = remainLotteryInductees[_lotteryId].length;
            }
        } else {
            require(_index <= _lottery.proportionNum.length, "lottery index out of bounds");
            uint256 proportion = _lottery.proportionNum[_index];
            if (proportion > 0) {
                if (proportion >= 100) {
                    proportion = 100;
                }
                lotteryNum = remainLotteryInductees[_lotteryId].length.mul(proportion).div(100);
                if (lotteryNum == 0) {
                    lotteryNum = 1;
                }
            }
        }

        if (lotteryNum == 0) {
            return;
        }

        address[] memory lotteryResults = new address[](lotteryNum);

        for (uint256 i = 0; i < lotteryNum; i++) {
            uint256 inducteeNum = remainLotteryInductees[_lotteryId].length;
            uint256 latestInducteeIndex = inducteeNum - 1;

            uint256 winnerIndex = _randomNumber(inducteeNum, i);

            lotteryResults[i] = remainLotteryInductees[_lotteryId][winnerIndex];

            if (winnerIndex != latestInducteeIndex) {
                remainLotteryInductees[_lotteryId][winnerIndex] = remainLotteryInductees[_lotteryId][latestInducteeIndex];
            }
            remainLotteryInductees[_lotteryId].pop();
        }

        address creator = dataStorage.getLotteryCreator(_lotteryId);

        if (_lottery.isEth) {
            uint256 lastBalance = dataStorage.getEthBank(creator);
            require(lastBalance >= _lottery.amounts[_index], "creator's eth not enough");
            dataStorage.setEthBank(creator, lastBalance.sub(_lottery.amounts[_index]));
            _ethLottery(_lottery.amounts[_index], lotteryResults);
        } else {
            uint256 lastBalance = dataStorage.getErc20Bank(creator, _lottery.token);
            require(lastBalance >= _lottery.amounts[_index], "creator's token not enough");
            dataStorage.setErc20Bank(creator, _lottery.token, lastBalance.sub(_lottery.amounts[_index]));
            _erc20Lottery(_lottery.token, _lottery.amounts[_index], lotteryResults);
        }
        dataStorage.setLotteryResult(_lotteryId, _index, lotteryResults);

    }

    function getLotteries(uint256[] memory _ids) public view returns (IDataStorage.Lottery[] memory){
        return dataStorage.getLotteries(_ids);
    }

    function getLottery(uint256 _lotteryId) public view returns (IDataStorage.Lottery memory){
        return dataStorage.getLottery(_lotteryId);
    }

    function getLotteryResults(uint256 _lotteryId, uint256 _index) public view returns (address[] memory){
        return dataStorage.getLotteryResult(_lotteryId, _index);
    }

    function _randomNumber(uint256 _scope, uint256 _salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encode(abi.encodePacked(block.timestamp, block.difficulty), _salt))) % _scope;
    }


    function transferAsset(address payable _to) public onlyOperator {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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


interface ILottery {
    function drawALottery(uint256 _lotteryId) external;

    function transferAsset(address payable _to) external;
}

interface IQuizToken {
    function mint(address account, uint256 amount) external;
}

interface IDataStorage {

    struct QuizDetail {
        uint256 id;
        string app_id;
        string[] questions;
        uint256 amount;
        int256 group;
        uint botType;
        bool exist;
        bool over;
        uint256 startTime;
        uint256 activeTime;
        string title;
        string photo;
        uint256 participate;
    }

    function checkAdmin(string memory _appId, address _sender) external view returns (bool);

    function setQuiz(string memory _appId, QuizDetail memory _quiz) external;

    function overQuiz(uint256 _quizId) external;

    function getQuiz(uint256 _quizId) external view returns (QuizDetail memory);

    function getQuizzes(uint256[] memory _quizIds) external view returns (QuizDetail[] memory);

    function addInductees(uint256 _quizId, address[] memory _inductees, uint256 _participate) external;

    function getInductees(uint256 _quizId) external view returns (address[] memory);

    function getShouldAwardQuizIds() external view returns (uint256[] memory);

    function getAppQuizIds(string memory _appId) external view returns (uint256[] memory);

    function getLotteryResult(uint256 _quizId, uint256 _index) external view returns (address[] memory);

}


contract Quiz {

    using SafeMath for uint256;
    address  public owner;
    address payable public operator;
    mapping(string => address payable) appOperators;
    ILottery public lottery;
    IQuizToken public quizToken;
    IDataStorage public dataStorage;


    uint256 public correctRewardAmount;

    constructor(address payable _operator, ILottery _lottery, IQuizToken _quizToken, IDataStorage _storage, uint256 _rewardAmount) {
        owner = msg.sender;
        operator = _operator;
        lottery = _lottery;
        quizToken = _quizToken;
        dataStorage = _storage;
        correctRewardAmount = _rewardAmount;
    }


    modifier checkQuiz(uint256 _quizId){
        require(_quizId != 0, "invalid quizId 0");
        require(dataStorage.getQuiz(_quizId).exist, "nonexistent quiz");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyAdmin(string memory _appId) {
        require(dataStorage.checkAdmin(_appId, msg.sender) || operator == msg.sender
        || address(appOperators[_appId]) == msg.sender || owner == msg.sender, "Only admin");
        _;
    }

    event CreateQuiz(string _appId, uint256 _quizId, int256 _groupId, uint _botType, string[] questions, uint256 _rewardAmount,
        uint256 _startTime, uint256 _activeTime);
    event Awards(bytes32 _quizId);


    function transferOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function changeOperator(address payable _newOperator) public onlyOwner {
        operator = _newOperator;
    }

    function addAppOperator(string memory _appId, address payable _newOperator) public onlyOwner {
        appOperators[_appId] = _newOperator;
    }

    function changeLottery(ILottery _newLottery) public onlyOwner {
        if (address(lottery) != address(0)) {
            address _to = address(_newLottery);
            lottery.transferAsset(payable(_to));
        }
        lottery = _newLottery;
    }

    function changeQuizToken(IQuizToken _newQuizToken) public onlyOwner {
        quizToken = _newQuizToken;
    }

    function changeRewardAmount(uint256 _newAmount) public onlyOwner {
        correctRewardAmount = _newAmount;
    }

    function createQuiz(string memory _appId, uint256 _quizId, int256 _groupId, uint _botType, string[] memory _questions,
        uint256 _rewardAmount, uint256 _startTime, uint256 _activeTime, string memory _title, string memory _photo) payable public onlyAdmin(_appId) {
        require(_quizId != 0, "invalid quizId 0");
        IDataStorage.QuizDetail memory quiz = dataStorage.getQuiz(_quizId);
        require(!quiz.exist, "exist quiz");
        _rewardAmount = correctRewardAmount;

        address payable thisOperator = appOperators[_appId];

        if (address(msg.sender) != address(operator) && address(msg.sender) != owner) {
            require(msg.value > 0, "you should prepay for gas");
            if (address(thisOperator) != address(0)) {
                require(msg.value > 0, "you should prepay for gas");
                thisOperator.transfer(msg.value);
            } else {
                operator.transfer(msg.value);
            }
        }

        quiz.id = _quizId;
        quiz.app_id = _appId;
        quiz.amount = _rewardAmount;
        quiz.questions = _questions;
        quiz.group = _groupId;
        quiz.exist = true;
        quiz.botType = _botType;
        quiz.title = _title;
        quiz.photo = _photo;
        quiz.startTime = _startTime;
        quiz.activeTime = _activeTime;

        dataStorage.setQuiz(_appId, quiz);

        emit CreateQuiz(_appId, _quizId, _groupId, _botType, _questions, _rewardAmount, _startTime, _activeTime);
    }


    function editQuiz(string memory _appId, uint256 _quizId, int256 _groupId, string[] memory _questions, uint256 _startTime, uint256 _activeTime, string memory _title, string memory _photo) public
    onlyAdmin(_appId)
    checkQuiz(_quizId) {
        IDataStorage.QuizDetail memory quiz = dataStorage.getQuiz(_quizId);
        if (_groupId != 0) {
            quiz.group = _groupId;
        }
        if (_questions.length > 0) {
            quiz.questions = _questions;
        }
        if (_startTime > 0) {
            quiz.startTime = _startTime;
        }
        if (_activeTime > 0) {
            quiz.activeTime = _activeTime;
        }
        if (bytes(_title).length > 0) {
            quiz.title = _title;
        }
        if (bytes(_photo).length > 0) {
            quiz.photo = _photo;
        }

        dataStorage.setQuiz(_appId, quiz);
    }


    function getQuiz(uint256 _quizId) public view returns (IDataStorage.QuizDetail memory) {
        return dataStorage.getQuiz(_quizId);
    }

    function getQuizzes(uint256[] memory _ids) public view returns (IDataStorage.QuizDetail[] memory){
        return dataStorage.getQuizzes(_ids);
    }


    function getShouldAwardQuizIds() public view returns (uint256[] memory) {
        return dataStorage.getShouldAwardQuizIds();
    }

    function getAppQuizIds(string memory _appId) public view returns (uint256[] memory){
        return dataStorage.getAppQuizIds(_appId);
    }


    function getInductees(uint256 _quizId) public view returns (address[] memory){
        return dataStorage.getInductees(_quizId);
    }

    function addInductees(string memory _appId, uint256 _quizId, address[] memory _inductees, uint256 _participateNumber) public checkQuiz(_quizId) onlyAdmin(_appId) {
        IDataStorage.QuizDetail memory quiz = dataStorage.getQuiz(_quizId);
        require(!quiz.over, "quiz is over");
        dataStorage.addInductees(_quizId, _inductees, _participateNumber);
    }

    function awards(string memory _appId, uint256 _quizId) public checkQuiz(_quizId) onlyAdmin(_appId) {
        IDataStorage.QuizDetail memory quiz = dataStorage.getQuiz(_quizId);
        require(!quiz.over, "quiz is over");

        address[] memory thisInductees = dataStorage.getInductees(_quizId);
        uint256 i = 0;

        while (i < thisInductees.length) {
            quizToken.mint(thisInductees[i], quiz.amount);
            i += 1;
        }

        quiz.over = true;
        dataStorage.overQuiz(_quizId);
        lottery.drawALottery(_quizId);
    }


    function getLotteryResults(uint256 _quizId, uint256 _index) public view returns (address[] memory){
        return dataStorage.getLotteryResult(_quizId, _index);
    }
}

//SPDX-License-Identifier: MIT

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

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        uint256 nowTotalAmount = _totalSupply.add(amount);
        _totalSupply = nowTotalAmount;
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract UnlimitedToken is ERC20 {

    address public owner;

    mapping(address => bool) public  operators;

    constructor(string memory _name, string memory _symbol)  ERC20(_name, _symbol) {
        owner = msg.sender;
        operators[msg.sender] = true;
        _setupDecimals(18);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyOperator(){
        require(operators[msg.sender], "not allowed");
        _;
    }

    function addOperator(address _operator) public onlyOwner {
        operators[_operator] = true;
    }

    function mint(address account, uint256 amount) public onlyOperator {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOperator {
        _burn(account, amount);
    }
}