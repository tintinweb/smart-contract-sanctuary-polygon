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
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Gomoku is Ownable{
    address public gameOwner;
    constructor() {
        gameOwner = owner();
    }

    uint8 [19][19] public board;//[0]〜[18]までの19個 

    bool public initializeStatus;//初期化状態。publish時のチェックにも使うフラグ
    //bool public gamestatus = false;//ゲームの状態　false:stop game, true:newgame
    bool public publicstatus = false;//ゲームの公開状態
    bool public gameOver;
    uint8 public playercount = 0;
    uint16 public turncount = 0;
    address[2] public players;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public playerstonecolor;//false:black, true:white
    uint8 currentturn =0;//0:black, 1:white
    enum gameResult {blckWin, whiteWin, draw}

    function initializeGame() public onlyOwner() returns (bool){
        require(publicstatus == false, "the game is already started");
        //ゲームを初期化
        // 1. Gameのターンを初期化する
        currentturn = 0;

        // 2. Gameのボードを初期化する
        for (uint8 i = 0; i < 19; i++){
            for (uint8 j = 0; j < 19; j++){
                board[i][j] = 0;
            }
        }
        initializeStatus = true;
        return true;
    }

    function publishGame() public onlyOwner returns (bool) {
        require(initializeStatus == true, "initialization need");
        publicstatus = true;//ゲームを公開
        return true;
    }

    function playerAssign() public returns (bool) {
        require(publicstatus == true, "game is not open yet");
        require(msg.sender != gameOwner, "gameOwner can't be player");
        require(playercount < 2, "players restrict to 2 persons");
        require(blacklist[msg.sender] != true, "you have played in the past");//記録はオーナーがゲームを終了させる時

        players[playercount] = msg.sender;//playerの情報を格納する配列にアドレスを保存
        if(playercount == 0){
            playerstonecolor[msg.sender] = false;//最初の人は黒石
        }else{
            playerstonecolor[msg.sender] = true;//次の人は白石
        }
        playercount ++;
        return true;
    }

    modifier onlyPlayer() {
        require(msg.sender == players[0] || msg.sender == players[1], "You are not a player!");
        _;
    }

    modifier turnCheck() {
        if (msg.sender == players[0]) {
            require(currentturn == 0, "Not your turn!");
        } else {
            require(currentturn == 1, "Not your turn!");
        }
        _;
    }

    function putStone(uint8 x, uint8 y) public onlyPlayer turnCheck {
    //function putStone(uint8 x, uint8 y) public onlyPlayer {

        require(publicstatus == true, "game is not open yet");
        require(msg.sender != gameOwner, "gameOwner can't be player");
        require(blacklist[msg.sender] != true, "you have played in the past");
        require(!judgementFullBoard(), "drow game over");

        require(board[x][y] == 0,"you must put stone vacant space");
        require(gameOver != true, "game is over");

            if(currentturn == 0){
                board[x][y] = 1;
                judgementVertical();//勝敗のチェック（縦方向）
                judgementHorizontal();//勝敗のチェック（横方向）
                judgementDiagonalDown();//勝敗のチェック（斜め下方向）
                judgementDiagonalUp();//勝敗のチェック（斜め上方向）
                currentturn = 1;//白石に切り替え
                turncount ++;
            }
            else if(currentturn == 1){
                board[x][y] = 2;
                judgementVertical();//勝敗のチェック（縦方向）
                judgementHorizontal();//勝敗のチェック（横方向）
                judgementDiagonalDown();//勝敗のチェック（斜め下方向）
                judgementDiagonalUp();//勝敗のチェック（斜め上方向）
                currentturn = 0;
                turncount ++;
            }      
    }

    function terminateGame() public onlyOwner(){
    //gamestatus = false;
    publicstatus = false;
    //gameOver = true;//すでにtrueになっている。
    playercount = 0;
    turncount = 0;
    currentturn =0;
    blacklist[players[0]] = true;
    blacklist[players[1]] = true;
    }
//enum gameResult {blckWin, whiteWin, draw}
    function judgementVertical() public returns (gameResult) {//戻り値はenum型
        for(uint8 i = 0; i < 19; i++){
            uint8 blackCount;
            uint8 whiteCount;
            for(uint8 j = 0; j < 19; j++){
                if(board[i][j]==1){// 1は黒石
                    blackCount ++;
                    whiteCount = 0;
                }
                else if(board[i][j]==2){// 2は白石
                    blackCount = 0;
                    whiteCount ++;
                } else{
                    blackCount = 0;
                    whiteCount = 0;
                }
                if(blackCount >= 5){
                    gameOver = true;//黒石が勝利 (引き分けでもtrue）
                    return gameResult.blckWin;
                }
                if(whiteCount >= 5){
                    gameOver = true;//白石勝利 (引き分けでもtrue）
                    return gameResult.whiteWin;
                }
            }
        }
    }

//enum gameResult {blckWin, whiteWin, draw}
    function judgementHorizontal() public returns (gameResult) {//戻り値はenum型
        // i と j を入れ替えた（縦→横）
        for(uint8 j = 0; j < 19; j++){
            uint8 blackCount;
            uint8 whiteCount;
            for(uint8 i = 0; i < 19; i++){
                if(board[i][j]==1){// 1は黒石
                    blackCount ++;
                    whiteCount = 0;
                }
                else if(board[i][j]==2){// 2は白石
                    blackCount = 0;
                    whiteCount ++;
                } else{
                    blackCount = 0;
                    whiteCount = 0;
                }
                if(blackCount >= 5){
                    gameOver = true;//黒石が勝利 (引き分けでもtrue）
                    return gameResult.blckWin;
                }
                if(whiteCount >= 5){
                    gameOver = true;//白石勝利 (引き分けでもtrue）
                    return gameResult.whiteWin;
                }
            }
        }
    }

    function judgementDiagonalDown() public returns (uint8 b, uint8 w) {//戻り値はenum型
        uint8 blackCount;
        uint8 whiteCount;
        for(uint8 i=0; i<=14; i++){
            for(uint8 j=0; j<=14; j++){
                for(uint8 k=0; k<=4; k++){
                    if(board[i+k][j+k] == 1){
                        blackCount ++;
                        whiteCount = 0;

                    }else if(board[i+k][j+k] == 2){
                        blackCount = 0;
                        whiteCount ++;
                    }else{
                        blackCount = 0;
                        whiteCount = 0;
                    }
                    if(blackCount >= 5){
                        gameOver = true;//黒石が勝利 (引き分けでもtrue）
                        //return gameResult.blckWin;
                    }
                    if(whiteCount >= 5){
                        gameOver = true;//白石勝利 (引き分けでもtrue）
                        //return gameResult.whiteWin;
                    }
                    b = blackCount;
                    w = whiteCount;
                }
            }
        }
        return (b,w);
    }

        function judgementDiagonalUp() public returns (uint8 b, uint8 w) {//戻り値はenum型
        uint8 blackCount;
        uint8 whiteCount;
        for(uint8 i=0; i<=14; i++){
            for(uint8 j=4; j<=18; j++){
                for(uint8 k=0; k<=4; k++){
                    if(board[i+k][j-k] == 1){
                        blackCount ++;
                        whiteCount = 0;

                    }else if(board[i+k][j-k] == 2){
                        blackCount = 0;
                        whiteCount ++;
                    }else{
                        blackCount = 0;
                        whiteCount = 0;
                    }
                    if(blackCount >= 5){
                        gameOver = true;//黒石が勝利 (引き分けでもtrue）
                        //return gameResult.blckWin;
                    }
                    if(whiteCount >= 5){
                        gameOver = true;//白石勝利 (引き分けでもtrue）
                        //return gameResult.whiteWin;
                    }
                    b = blackCount;
                    w = whiteCount;
                }
            }
        }
        return (b,w);
    }

    function judgementFullBoard() public view returns (bool) {
        if(turncount == 360){
            return true;
        }
    return false;
    }


}