// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract WanderChain {
    // ユーザーの選択を表す構造体
    struct Choice {
        uint256 timestamp;
        int direction; // 0 for up, 1 for right, 2 for down, 3 for left
    }

    // ユーザーの位置を表す構造体
    struct Position {
        int x;
        int y;
    }

    // ユーザーの選択を保存するマッピング
    mapping(address => Choice[]) public choices;

    // ユーザーの位置を保存するマッピング
    mapping(address => Position) public positions;

    // コントラクトの初期化
    constructor() {
        positions[msg.sender] = Position(4, 4);
    }

    // ユーザーが選択を記録する関数
    function recordChoice(int _direction) private {
        choices[msg.sender].push(Choice(block.timestamp, _direction));
    }

    // ユーザーが上に行く選択を記録する関数
    function goUp() public {
        recordChoice(0);
        positions[msg.sender].y += 1;
    }

    // ユーザーが右に行く選択を記録する関数
    function goRight() public {
        recordChoice(1);
        positions[msg.sender].x += 1;
    }

    // ユーザーが下に行く選択を記録する関数
    function goDown() public {
        recordChoice(2);
        positions[msg.sender].y -= 1;
    }

    // ユーザーが左に行く選択を記録する関数
    function goLeft() public {
        recordChoice(3);
        positions[msg.sender].x -= 1;
    }

    // ユーザーの選択の数を取得する関数
    function getChoicesCount() public view returns(uint256) {
        return choices[msg.sender].length;
    }

    // ユーザーの特定の選択を取得する関数
    function getChoice(uint256 _index) public view returns(uint256, int) {
        Choice storage choice = choices[msg.sender][_index];
        return (choice.timestamp, choice.direction);
    }

    // ユーザーの現在位置を取得する関数
    function getPosition() public view returns(int, int) {
        Position storage position = positions[msg.sender];
        return (position.x, position.y);
    }
}