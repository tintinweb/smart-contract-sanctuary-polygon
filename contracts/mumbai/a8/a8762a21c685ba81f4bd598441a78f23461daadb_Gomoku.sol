// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./GomokuMath.sol";

contract Gomoku {

    /* struct */
    struct GameStatusStruct 
    {
        address player1Addr;
        address player2Addr;
        address ownerAddr;
        address nowPlayerTurn;
        address winnerAddr;
        uint8 availableStatus;
        uint8 startFlg;
        uint8 endFlg;
    }

    struct GameOwnerStatus
    {
        uint256 nonce;
    }

    /* mapping */
    mapping(uint256=>GameStatusStruct) wholeGame;
    mapping(address=>GameOwnerStatus) gameOwnerMap;
    mapping(uint256=>mapping(uint256=>address)) public boardInfo;

    /* Event */
    event createGameEvent(uint256 gamekey,uint8 availableStatus);
    GomokuMath gomokuMath;
    event changeStatusEvent(uint256 gamekey,uint8 availableStatus);
    event entryPlayerEvent(uint256 gamekey,address plaeyerAdr);
    event startGameEvent(uint256 gamekey,address playerAddress);
    event standEndEvent(uint256 gamekey,address playerAddress,uint8 columns,uint8 raws);
    event turnEndEvent(uint256 gamekey,address playerAddress);
    event gameEndEvent(uint256 gamekey,uint8 endFlg,address winnerAddr);
    

    //固定数
    uint8 constant maxColumns = 9;
    uint8 constant maxRows = 9;

    constructor()
    {
        gomokuMath = new GomokuMath();
        gomokuMath.setGomoku(address(this),maxColumns,maxRows);
    }

    function createGame(uint8 availableStatus) public returns(uint256)
    {
        //セットされたステータスは正常値か
        require(availableStatus == 1 || availableStatus == 2,"set status error");
        uint256 gameKey;
        //キーの作成
        gameKey = GameKeyHash.createGameHash(gameOwnerMap[msg.sender].nonce, msg.sender);
        //nonce加算
        gameOwnerMap[msg.sender].nonce++;
        //キーが既に存在していないかチェック
        require(wholeGame[gameKey].ownerAddr == address(0x0),"create hash error");
        //ゲームオーナーのアドレスをセット
        wholeGame[gameKey].ownerAddr = msg.sender;
        //ゲームの公開設定をセット
        wholeGame[gameKey].availableStatus = availableStatus;
        //ゲーム作成のイベント送信
        emit createGameEvent(gameKey,availableStatus);
        //作成したキーのreturn
        return gameKey;
    }

    function changeAvaiableStatus(uint256 gamekey, uint8 availableStatus) public {
        //実行者はゲームの作成者か
        require(wholeGame[gamekey].ownerAddr==msg.sender,"you not game owner");
        //セットされたステータスは正常値か
        require(availableStatus == 1 || availableStatus == 2,"set status error");
        //ゲーム開始前かチェック
        require(wholeGame[gamekey].startFlg==0,"this game already start");
        //状態変更
        wholeGame[gamekey].availableStatus = availableStatus;
        //ゲーム状態変更のイベントのemit
        emit changeStatusEvent(gamekey, availableStatus);
    }

    function entryGame(uint256 gamekey) public {
        //ゲームがOPENでなければrevert
        require(wholeGame[gamekey].availableStatus==1,"you can not entry this game");
        //ゲーム開始済みの場合はrevert
        require(wholeGame[gamekey].startFlg==0,"this game already start");
        //プレイヤー1で既に登録されていた場合はリバート
        require(wholeGame[gamekey].player1Addr != msg.sender,"you already entry this game");

        if(wholeGame[gamekey].player1Addr == address(0x0))
        {
            //一人目が未エントリーの場合はプレイヤー１に設定
            wholeGame[gamekey].player1Addr = msg.sender;
            emit entryPlayerEvent(gamekey,msg.sender);
        }
        else if(wholeGame[gamekey].player2Addr == address(0x0))
        {
            //二人目が未エントリーの場合はプレイヤー2に設定
            wholeGame[gamekey].player2Addr = msg.sender;
            emit entryPlayerEvent(gamekey,msg.sender);

            //ゲーム開始処理
            startGame(gamekey);
        }
        else
        {
            //本来は来ない
            revert("game already start Or Error");
        }
        
    }

    function startGame(uint256 gamekey) internal
    {
        //ゲーム開始
        wholeGame[gamekey].startFlg= 1;
        //現在のプレイヤーをプレイヤー１に設定
        wholeGame[gamekey].nowPlayerTurn = wholeGame[gamekey].player1Addr;
        //startEvent呼び出し
        emit startGameEvent(gamekey,wholeGame[gamekey].nowPlayerTurn);
    }

    function stand(uint256 gamekey,uint8 columns, uint8 rows) public returns(uint8) 
    {
        //指定した範囲が異常値
        require(columns <= maxColumns,"you can stand columns under 9");
        require(rows <= maxRows,"you can stand rows under 9");
        //ゲームの開始前ならrevert
        require(wholeGame[gamekey].startFlg == 1,"this game not start");
        //ゲームが終了していたらrevert
        require(wholeGame[gamekey].endFlg == 0,"this game already finish");
        //ターンではないプレイヤーが実行したらrevert
        require(wholeGame[gamekey].nowPlayerTurn == msg.sender,"not your turn");
        //既に石が置かれているとrevert
        require(boardInfo[gamekey][rows * 10 + columns] == address(0x00), "already put here");
        //石を置く
        boardInfo[gamekey][rows * 10 + columns] = msg.sender;
        //石を置いたといったイベントの送信
        emit standEndEvent(gamekey,msg.sender,columns,rows);
        //終了判定
        uint8 endFlg = gomokuMath.isLineJudge(gamekey, msg.sender, columns, rows);
        if(endFlg != 0)
        {
            //終了していた場合は終了処理
            gameEnd(gamekey,endFlg);
        }
        else
        {
            //終了していない場合は引き分けチェック
            if(gomokuMath.isNotDraw(gamekey) == 0)
            {
                //引き分けの場合はb終了処理
                endFlg = 2;
                gameEnd(gamekey,endFlg);
            }
            else
            {
                //プレイヤー交代
                playerChange(gamekey);
            }
        }
        //終了フラグをretrun
        return wholeGame[gamekey].endFlg;
    }

    function playerChange(uint256 gamekey) internal
    {
        if(msg.sender == wholeGame[gamekey].player1Addr)
        {
            //送信者がプレイヤー１の場合はプレイヤー２を現在のターンに設定する
            wholeGame[gamekey].nowPlayerTurn = wholeGame[gamekey].player2Addr;
        }
        else if(msg.sender == wholeGame[gamekey].player2Addr)
        {
            //送信者がプレイヤー2の場合はプレイヤー1を現在のターンに設定する
            wholeGame[gamekey].nowPlayerTurn = wholeGame[gamekey].player1Addr;
        }
        else
        {
            //来ることはないがそれ以外のプレイヤーのアクセスはrevert
            revert("your not game player");
        }
        //ターン終了イベント送信
        emit turnEndEvent(gamekey,wholeGame[gamekey].nowPlayerTurn);
    }

    function gameEnd(uint256 gamekey,uint8 endFlg) internal
    {
        //こないはずだがendFlgが経っていない場合はrevert
        require(endFlg != 0 ,"illegal Processing in gameEnd");
        wholeGame[gamekey].endFlg = endFlg;
        if(wholeGame[gamekey].endFlg == 1)
        {
            //endFlgが1の場合は勝者あり
            wholeGame[gamekey].winnerAddr = msg.sender;
        }
        
       emit gameEndEvent(gamekey,wholeGame[gamekey].endFlg,wholeGame[gamekey].winnerAddr);
    }

    function GetBordInfo(uint256 gamekey)public view returns (string[] memory)
    {
        string[] memory ret = new string[](100);
        for (uint i=0; i<100;i++)
        {
            if(boardInfo[gamekey][i] == wholeGame[gamekey].player1Addr)
            {
                ret[i] = "B";
            }
            else if(boardInfo[gamekey][i] == wholeGame[gamekey].player2Addr)
            {
                ret[i] = "W";
            }
            else
            {
                ret[i] = "-";
            }
        }
        return ret;
    }


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./Gomoku.sol";

library GameKeyHash 
{
    function createGameHash(uint256 nonce,address ownerAddr) public pure returns(uint256 hash)
    {
        return uint256(keccak256(abi.encode(nonce,ownerAddr)));
    }
}

contract GomokuMath 
{

    Gomoku gomoku;

    uint8 maxColumns;
    uint8 maxRows;

    function setGomoku(address addr,uint8 maxC, uint8 maxR) public
    {
        gomoku = Gomoku(addr);
        maxColumns= maxC;
        maxRows= maxR;
    }

    function isLineJudge(uint256 gamekey,address player, uint8 columns,uint8 rows) public view returns(uint8) 
    {
        uint8 result = 0; 
        //横列チェック
        result = columnsJudge(gamekey,player,columns, rows);
        if(result != 0)
        {
            return result;
        }

        //縦列チェック
        result = rowsJudge(gamekey,player,columns, rows);
        if(result != 0)
        {
            return result;
        }

        //斜めチェック１
        result = diagonalLeftJudge(gamekey,player,columns, rows);
        if(result != 0)
        {
            return result;
        }

        //斜めチェック2
        result = diagonalRightJudge(gamekey,player,columns, rows);
        if(result != 0)
        {
            return result;
        }
        return 0;
    }

    function columnsJudge(uint256 gamekey,address player, uint8 columns,uint8 rows) internal view returns (uint8)
    {
        //横ラインチェック
        uint8 checkNum=1;
        uint8 tmpColumns = columns;

        for(;;)
        {
            //左にマスが存在しているかチェック
            if(tmpColumns <= 0)
            {
                //左端のためループを抜ける
                break;
            }
            //チェックするマスを左のマスに移動
            tmpColumns--;

            //チェックするマスにおかれている石はプレイヤーのものかチェック
            if(gomoku.boardInfo(gamekey,uint256(rows*10+tmpColumns)) != player)
            {
                //プレイヤーのものではないためループを抜ける
                break;
            }

            //プレイヤーのものであるためCheck++
            checkNum++;
            if(checkNum>=5)
            {
                //5つ並んだ時点で勝利
                return 1;
            }
        }

        //チェックするマスを原点に戻す
        tmpColumns = columns;

        for(;;)
        {
            //右にマスが存在しているかチェック
            if(tmpColumns >= maxColumns)
            {
                //右端のためループを抜ける
                break;
            }
            //チェックするマスを右のマスに移動
            tmpColumns++;

            //チェックするマスにおかれている石はプレイヤーのものかチェック
            if(gomoku.boardInfo(gamekey,uint256(rows*10+tmpColumns)) != player)
            {
                //プレイヤーのものではないためループを抜ける
                break;
            }

            //プレイヤーのものであるためCheck++
            checkNum++;

            if(checkNum>=5)
            {
                //5つ並んだ時点で勝利
                return 1;
            }
        }
        //勝敗が確定していないため０を返す
        return 0;
    }

    function rowsJudge(uint256 gamekey,address player, uint8 columns,uint8 rows) internal view returns (uint8)
    {
        //縦ラインチェック
        uint8 checkNum=1;
        uint8 tmpRows = rows;

        for(;;)
        {
            //上にマスが存在しているかチェック
            if(tmpRows <= 0)
            {
                break;
            }

            //チェックするマスを上のマスに移動
            tmpRows--;
            
            //チェックするマスにおかれている石はプレイヤーのものかチェック
            if(gomoku.boardInfo(gamekey,uint256(tmpRows*10+columns)) != player)
            {
                //プレイヤーのものではないためループを抜ける
                break;
            }

            //プレイヤーのものであるためCheck++
            checkNum++;
            if(checkNum>=5)
            {
                //5つ並んだ時点で勝利
                return 1;
            }
        }

        //チェックするマスを原点に戻す
        tmpRows = rows;

        for(;;)
        {
            //下にマスが存在しているかチェック
            if(tmpRows >= maxRows)
            {
                break;
            }
            //チェックするマスを下のマスに移動
            tmpRows++;

            //チェックするマスにおかれている石はプレイヤーのものかチェック
            if(gomoku.boardInfo(gamekey,uint256(tmpRows*10+columns)) != player)
            {
                //プレイヤーのものではないためループを抜ける
                break;
            }

            //プレイヤーのものであるためCheck++
            checkNum++;
            if(checkNum>=5)
            {
                //5つ並んだ時点で勝利
                return 1;
            }
        }
        return 0;
    }

    function diagonalRightJudge(uint256 gamekey,address player, uint8 columns,uint8 rows) internal view returns (uint8)
    {
        uint8 checkNum=1;
        uint8 tmpColumns = columns;
        uint8 tmpRows = rows;
        for(;;)
        {
            if(tmpRows <= 0 || tmpColumns <= 0)
            {
                break;
            }
            tmpRows--;
            tmpColumns--;
        
            if(gomoku.boardInfo(gamekey,uint256(tmpRows*10+tmpColumns)) != player)
            {
                break;
            }

            checkNum++;
            if(checkNum>=5)
            {
                return 1;
            }
        }

        tmpRows = rows;
        tmpColumns = columns;

        for(;;)
        {
            if(tmpRows >= maxRows || tmpColumns >= maxColumns)
            {
                break;
            }
            tmpRows++;
            tmpColumns++;

            if(gomoku.boardInfo(gamekey,uint256(tmpRows*10+tmpColumns)) != player)
            {
                break;
            }
            checkNum++;
            if(checkNum>=5)
            {
                return 1;
            }
        }
        return 0;
    }

    function diagonalLeftJudge(uint256 gamekey,address player, uint8 columns,uint8 rows) internal view returns (uint8)
    {
        uint8 checkNum=1;
        uint8 tmpColumns = columns;
        uint8 tmpRows = rows;
        
        for(;;)
        {
            if(tmpRows <= 0 || tmpColumns >= maxColumns)
            {
                break;
            }
            tmpRows--;
            tmpColumns++;

            if(gomoku.boardInfo(gamekey,uint256(tmpRows*10+tmpColumns)) != player)
            {
                break;
            }

            checkNum++;
            if(checkNum>=5)
            {
                return 1;
            }
        }

        tmpRows = rows;
        tmpColumns = columns;

        for(;;)
        {
            if(tmpRows >= maxRows || tmpColumns <= 0)
            {
                break;
            }
            tmpRows++;
            tmpColumns--;

            if(gomoku.boardInfo(gamekey,uint256(tmpRows*10+tmpColumns)) != player)
            {
                break;
            }
            checkNum++;
            if(checkNum>=5)
            {
                return 1;
            }
        }
        return 0;
    }

    function isNotDraw(uint256 gamekey) public view returns(uint8)
    {
        uint8 resultNotDraw;
        for(uint i = 0; i < 10 ; i++)
        {
            for(uint j = 0; j < 10; j++)
            {
                if(gomoku.boardInfo(gamekey,i * 10 + j) == address(0x0))
                {
                    resultNotDraw = 1;
                    break;
                }
            }
        }
        return resultNotDraw;
    }
}