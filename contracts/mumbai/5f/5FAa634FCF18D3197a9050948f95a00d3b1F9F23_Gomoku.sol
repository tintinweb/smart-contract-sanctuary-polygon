// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SGomoku} from "interfaces/SGomoku.sol";

contract Gomoku {

    uint256 nonce;
    mapping(uint256 => SGomoku.GomokuData) public dataGomoku;

    event evChangeOpen(bool status);
    event evMakeGame(address owner);
    event evPlayer1(address player1);
    event evPlayer2(address player2);
    event evWin(address winer);
    event evLose(address winer);
    event evHaiti();
    event evHikiwake();

    function initialize() external{
        dataGomoku[nonce].flgGame = false;
    }

    function makeGomoku() external returns(bool){
        bool bCompletemake = false;
        if(dataGomoku[nonce].flgGame == false)
        {
            for(uint8 i = 0; i < 10; i++)
            {
               for(uint8 j = 0; j < 10; j++)
               {
                   dataGomoku[nonce].Goban[i][j] = 0;
               }
            }
            dataGomoku[nonce].flgGame = true;
            dataGomoku[nonce].OpenStatus = false;
            dataGomoku[nonce].PlayerNum = 0;
            dataGomoku[nonce].OwnerAddr = msg.sender;
            emit evMakeGame(dataGomoku[nonce].OwnerAddr);
            bCompletemake = true;
        }
        else
        {
            revert("Already created");
        }
        return(bCompletemake);
    }

    function ChanegeOpen() external onlyOwner(){
        dataGomoku[nonce].OpenStatus = true;
        emit evChangeOpen(dataGomoku[nonce].OpenStatus);
    }

    function EntryGame() external {
        // 開放状態を確認
        require(dataGomoku[nonce].OpenStatus == true, "Game is CLOSE");
        // 終了状態確認
        require(dataGomoku[nonce].flgEnd == false, "Game is END");

        // 現時点での参加人数０人
        if(dataGomoku[nonce].PlayerNum == 0){
            dataGomoku[nonce].PlayerNum++; // プレイヤー人数をインクリメント
            dataGomoku[nonce].Player1Addr = msg.sender; // プレイヤー1として設定
            emit evPlayer1(dataGomoku[nonce].Player1Addr);
        }
        // 現時点での参加人数1人
        else if(dataGomoku[nonce].PlayerNum == 1){
            require(msg.sender != dataGomoku[nonce].Player1Addr, "Don't Play Same Player");

            dataGomoku[nonce].PlayerNum++; // プレイヤー人数をインクリメント
            dataGomoku[nonce].Player2Addr = msg.sender; // プレイヤー2として設定
            dataGomoku[nonce].OpenStatus = false; // 公開状態をCLOSEに変更
            emit evPlayer2(dataGomoku[nonce].Player2Addr);
            dataGomoku[nonce].turnPlayerAddr = dataGomoku[nonce].Player1Addr; // 手番のアドレスをプレイヤー1に変更
        }
        else{
            revert("Full Player");
        }
    }

    function StoneHaiti(uint8 x, uint8 y) external{
        // ゲームが終了されているか
        require(dataGomoku[nonce].flgEnd == false, "Game is END");
        // 手番じゃなければ無効
        require(dataGomoku[nonce].turnPlayerAddr == msg.sender, "You're not turnPlayer");
        // 値が範囲内かどうかの判定
        require(0 <= x && x < 10 && 0 <= y && y < 10, "Out of range");
        // すでに値が入っている場合は無効
        require(dataGomoku[nonce].Goban[x][y] == 0, "This place not vacant");
        uint8 Player = 0;
        // アドレスに応じて配列内の値を変更
        if(dataGomoku[nonce].turnPlayerAddr == dataGomoku[nonce].Player1Addr)
        {
            Player = 1;
        }
        else if(dataGomoku[nonce].turnPlayerAddr == dataGomoku[nonce].Player2Addr)
        {
            Player = 2;
        }
        dataGomoku[nonce].Goban[x][y] = Player;
        emit evHaiti();

        // 配置後に勝敗判定
        uint8 hanteiCount = Judge(x,y);
        // 打った石の隣り合わせで石が4つある場合
        if(hanteiCount == 4){
            dataGomoku[nonce].winPlayerAddr = msg.sender;
            dataGomoku[nonce].flgEnd = true;
            emit evWin(dataGomoku[nonce].winPlayerAddr);
        }
        // 盤面に空きがある場合
        else if(hanteiCount == 8)
        {
            if(Player == 1){
                dataGomoku[nonce].turnPlayerAddr = dataGomoku[nonce].Player2Addr;
            }
            else if(Player == 2){
                dataGomoku[nonce].turnPlayerAddr = dataGomoku[nonce].Player1Addr;
            }
        }
        // その他(５個並んでいないかつ盤面に空きがない)
        else
        {
            emit evHikiwake();
            dataGomoku[nonce].flgEnd = true;
        }
    }

    function Judge(uint8 x, uint8 y) internal view returns(uint8){
        uint8 countishi_side = 0;
        uint8 countishi_ver = 0;
        uint8 countishi_diag = 0;
        uint8 countishi_gyakudiag = 0;
        uint8 returnCount;
        // 横正方向に複数同じ石が並んでいるか
        for(uint8 i = 1; i < 5; i++){
            if(x+i > 9){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x+i][y]){
                countishi_side++;
            }
            else{
                break;
            }
        }
        // 縦正方向に複数同じ石が並んでいるか
        for(uint8 j = 1; j < 5; j++){
            if(y+j > 9){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x][y+j]){
                countishi_ver++;
            }
            else{
                break;
            }
        }
        // 斜め正方向に複数同じ石が並んでいるか
        for(uint8 k = 1; k < 5; k++){
            if(x+k > 9 || y+k > 9){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x+k][y+k]){
                countishi_diag++;
            }
            else{
                break;
            }
        }
        // 逆斜め正方向に複数同じ石が並んでいるか
        for(uint8 k = 1; k < 5; k++){
            if(x+k > 9 || y+k > 9){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x+k][y+k]){
                countishi_gyakudiag++;
            }
            else{
                break;
            }
        }
        // 横負方向に複数同じ石が並んでいるか
        for(uint8 l = 1; l < 5; l++){
            if(l > x){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x-l][y]){
                countishi_side++;
            }
            else{
                break;
            }
        }
        // 縦負方向に複数同じ石が並んでいるか
        for(uint8 m = 1; m < 5; m++){
            if(m > y){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x][y-m]){
                countishi_ver++;
            }
            else{
                break;
            }
        }
        // 斜め負方向に複数同じ石が並んでいるか
        for(uint8 n = 1; n < 5; n++){
            if(n > x || n > y){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x-n][y-n]){
                countishi_diag++;
            }
            else{
                break;
            }
        }
        // 逆斜め負方向に複数同じ石が並んでいるか
        for(uint8 n = 1; n < 5; n++){
            if(n > x || n > y){
                break;
            }
            if(dataGomoku[nonce].Goban[x][y] == dataGomoku[nonce].Goban[x-n][y-n]){
                countishi_gyakudiag++;
            }
            else{
                break;
            }
        }

        // 打った石の周りで4つ以上が直線で並んでいる場合
        if(countishi_side >= 4 || countishi_ver >= 4 || countishi_diag >= 4)
        {
            returnCount = 4;
        }
        else{
            for(uint8 o = 0; o < 10; o++)
            {
                for(uint8 p = 0; p < 10; p++)
                {
                    // 盤面に空いているマスがあれば継続
                    if(dataGomoku[nonce].Goban[o][p] == 0)
                    {
                        returnCount = 8;
                    }
                }
            }
        }
        return returnCount;
    }

    modifier onlyOwner() {
        require(msg.sender == dataGomoku[nonce].OwnerAddr, "Caller is not GameOwner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface SGomoku{
    struct GomokuData{
        bool flgGame; // 作成済みフラグ
        bool OpenStatus; //公開状態
        bool flgEnd; //ゲーム終了フラグ
        uint8 PlayerNum; //参加人数
        address OwnerAddr; //オーナーアドレス
        address Player1Addr; //プレイヤー1アドレス
        address Player2Addr; //プレイヤー2アドレス
        address turnPlayerAddr; //手番プレイヤーアドレス
        address winPlayerAddr; //勝利プレイヤーアドレス
        uint8 [10][10] Goban;
        uint8 Version;
    }
}