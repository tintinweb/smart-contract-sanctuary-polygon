/**
 *Submitted for verification at polygonscan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT

/*
 * - @dev
 * - とりあえず大まかには完成
 * - 実際にテストとして動かしてみるのにgiveRights functionは邪魔なのでコメントアウトしています
 * - 得た棄権以外の票数が、特定の値以下の場合は順位を10000位とする
 *
 * - <4/12　更新>
 * - 全員が棄権した場合にエラーが出ていたのでその修正
 * - 棄権が多すぎるなどして優勝者が決められない場合はエラーを返すようにしている
 * 
 * - <残りやること>
 * --- uintとintを揃える。型がぐちゃぐちゃ(searchとか特に)
 * --- 様々なパターンでの確認
 */

pragma solidity ^0.8.9;

contract Voting {

    /// @dev オーナーはこのコントラクトをデプロイしたアカウント
    address public owner;

    /// @dev 投票が終わったらfalseに。
    bool public voteEnded = false;

    uint public numOfVoters = 0;

    /// @dev 候補者・投票者それぞれのデータ構造
    struct Candidate {
        string name;
        uint[] score;
    }
    struct Voter {
        bool voted;
        //bool granted;
        uint[] scores;
    }

    /// @dev 候補者の配列、アドレスと投票者を結びつけるマッピング
    Candidate[] internal candidates; ///internalにすれば表示は消える
    mapping(address => Voter) internal voters;

    event Voted(address voter_);
    event VoteEnded();

    constructor(string[] memory candidateNames) {
        owner = msg.sender;
        //Voter storage owner_ = voters[owner];
        //owner_.granted = true;
        /*
         * @dev もし候補者の人数に制限があるなら
         * - require(candidateNames.length == 5, "The number of candidates must be 5.");
         */

        for (uint i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate(candidateNames[i], new uint[](0)));

            /// @dev 候補者の名前に被りがあってはならない
            for(uint j = i + 1; j < candidateNames.length; j++) {
                require(!compareStrings(candidateNames[i], candidateNames[j]), "Each candidate's name must be different");
            }
            
        }
    }

    /// @dev オーナーだけができる、というのを示すmodifier修飾子
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner.");
        _;
    }

/*
    function giveRight(address addr) public onlyOwner {
        Voter storage receiver = voters[addr];
        require(!receiver.granted, "This account has already been granted voting rights.");
        receiver.granted = true;
    }
    */

    /// @dev 配列の中から文字を検索し、それが配列の何番目にあるかを返す
    function searchIndexStr(string[] memory strArr, string memory str) internal pure returns (uint) {
        for (uint i = 0; i < strArr.length; i++) {
            if (keccak256(abi.encodePacked(strArr[i])) == keccak256(abi.encodePacked(str))) {
                return i;
            }
        }

        /// @dev もし検索して出てこなければ配列の長さを返す
        return strArr.length;

    }

    /// @dev 配列の中から数字を検索し、それが配列の何番目にあるかを返す
    function searchIndexUint(uint[] memory uintArr, uint num) internal pure returns (uint) {
        for (uint i = 0; i < uintArr.length; i++) {
            if (uintArr[i] == num) {
                return i;
            }
        }
        return uintArr.length;
    }

    


    /// @dev 2つのstringが同じかどうかを見比べる。単純比較はできないので一旦バイト列に変換
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /* 
     * @dev 
     * - 投票
     * - 一度投票したら二度と投票できない
     * - 候補者の数と同じ数の配列であることを確認
     * - 点数は1-4点
     * - 点数を入れない場合は100点
     */
    
    function vote(uint[] memory _scores) public {
        require(!voteEnded, "This vote has already ended.");
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        require(_scores.length == candidates.length, "Invalid number of scores.");
        for (uint i = 0; i < _scores.length; i++) {
            require((_scores[i] >= 1 && _scores[i] <= 4) || _scores[i] == 100, "The point must be between 1 and 4. If you want to abstain, enter 100.");
            if(candidates[i].score.length == 0){
                candidates[i].score.push(0);
            }
            if(_scores[i] != uint256(100)){
                if (candidates[i].score[candidates[i].score.length - 1] == 0){
                    candidates[i].score[candidates[i].score.length - 1] = _scores[i];
                } else {
                    candidates[i].score.push(_scores[i]);
                }
            }
            sender.scores.push(_scores[i]);
        }
        sender.voted = true;
        numOfVoters += 1;
        emit Voted(msg.sender);
    }


    /// @dev 自分の投票内容を見る
    function getVoterScores() public view returns (uint[] memory) {
        Voter storage sender = voters[msg.sender];
        require(sender.voted, "You have not voted yet.");
        return sender.scores;
    }

    /// @dev オーナーのみ他人の投票内容を確認できる。
    function ForOwnerGetVoterScores(address voterAddress) public view onlyOwner returns (uint[] memory) {
        Voter storage voter = voters[voterAddress];
        require(voter.voted, "This voter has not voted yet.");
        return voter.scores;
    }

    /// @dev 中央値の計算。外部の状態は参照しないし変更もしないのでpure。solidityは小数点を表せないことに注意
    function calculateMedian(uint[] memory _arr) private pure returns (uint) {
        uint len = _arr.length;
        if (len == 0){return 0;}
        uint mid = len / 2;
        uint[] memory arr = _arr;

        for (uint i = 0; i < len; i++) {
            uint min = i;
            for (uint j = i + 1; j < len; j++) {
                if (arr[j] < arr[min]) {
                    min = j;
                }
            }
            uint tmp = arr[min];
            arr[min] = arr[i];
            arr[i] = tmp;
        }

        if (len % 2 == 0) {
            return arr[mid - 1];
        } else {
            return arr[mid] ;
        }
    }


    /// @dev 中央値の値以下の値の総数を返す
    function lessMed(uint[] memory _arr) private pure returns (uint greatNum) {
        uint counter = 0;
        uint median = calculateMedian(_arr);
        for(uint i = 0; i < _arr.length; i++) {
            if (median >= _arr[i]) {
                counter++;
            }
        }
        return counter*100/_arr.length;
    }

    /// @dev 中央値の値以上の値の総数を返す
    function greaterMed(uint[] memory _arr) private pure returns (uint lessNum) {
        uint counter = 0;
        uint median = calculateMedian(_arr);
        for(uint i = 0; i < _arr.length; i++) {
            if (median <= _arr[i]) {
                counter++;
            }
        }
        return counter*100/_arr.length;
    }


    function Greater(uint[] memory Arr) private pure returns (uint){
        uint counter = 0;
        uint median = calculateMedian(Arr);
        for(uint i = 0; i < Arr.length; i++) {
            if (median < Arr[i]) {
                counter++;
            }
        }
        return counter*100/Arr.length;
    }

    function Less(uint[] memory Arr_) private pure returns (uint){
        uint counter = 0;
        uint median = calculateMedian(Arr_);
        for(uint i = 0; i < Arr_.length; i++) {
            if (median > Arr_[i]) {
                counter++;
            }
        }
        return counter*100/Arr_.length;
    }


    /// @dev uint型をstring型に変換
    function uint2str(uint _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (_i != 0) {
            k = k-1;
            uint8 temp = uint8(48 + _i % 10);
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }

    function ArrCalc(uint[] memory Array) public pure returns (uint) {
    uint result = 0;
    if (Array.length % 2 == 0) {
        uint middle = Array.length/2 - 1;
        for(uint i = 0; i < Array.length; i++) {
            if (i <= middle) {
                result += Array[i] * (10 ** ((Array.length - 1) - ((middle - i) * 2)));
            }
            else{
                result += Array[i] * (10 ** ((Array.length - 2) - ((i - middle - 1) * 2)));
            }
        }
    } else {
        uint middle = (Array.length - 1) / 2;
        for(uint i = 0; i < Array.length; i++) {
            if (i < middle) {
                result += Array[i] * (10 ** ((Array.length - 1) - ((middle - i - 1) * 2) - 1 ));
            }
            else{
                result += Array[i] * (10 ** (Array.length - ((i - middle) * 2) - 1 ));
            }
        }
    }
    return result;
}


    /// @dev 全体の結果を見る
    function getResults() public view returns (string[] memory names, uint[] memory medians, uint[] memory ranks) {
        uint[] memory tempMedians = new uint[](candidates.length);
        uint[] memory tempRanks = new uint[](candidates.length);
        names = new string[](candidates.length);
        //uint minScoreLength = numOfVoters * 3 / 10;
        uint minScoreLength = 2;
        

        for (uint i = 0; i < candidates.length; i++) {

            if (candidates[i].score.length < minScoreLength) {
                    tempMedians[i] = 0; // 得点が一定の長さよりも小さい場合、中央値を0に設定
            } else {
                tempMedians[i] = calculateMedian(candidates[i].score);
            }
            names[i] = candidates[i].name;
        }

        for (uint i = 0; i < candidates.length; i++) {
            uint rank = 1;
            for (uint j = 0; j < candidates.length; j++) {
                if (tempMedians[j] > tempMedians[i]) {
                    rank++;
                }
                else if (tempMedians[i] == tempMedians[j]) {
                    if (ArrCalc(candidates[j].score) > ArrCalc(candidates[i].score)) {
                        rank++;
                    }
                }
                
            }
            if (tempMedians[i] == 0){
                rank = 10000;
            }
            tempRanks[i] = rank;
        }
        
        medians = tempMedians;
        ranks = tempRanks;
    }

    /// @dev 優勝者を返す
    function getWinner() public view returns (string memory winnerName) {
        (,, uint[] memory tempRanks) = getResults();
        require(searchIndexUint(tempRanks, 1) != tempRanks.length, "We cannot determine the winner due to too few votes or too many abstentions.");
        uint winner = uint(searchIndexUint(tempRanks, 1));
        return candidates[winner].name;
    }


    /// @dev 候補者名を入れると、その人の中央値と順位が返される
    function getIndividualResults(string memory CandidateName) public view returns (string memory MedianValue, uint Rank, uint[] memory ScoreGet) {
        
        uint[] memory medians = new uint[](candidates.length);
        //uint minScoreLength = numOfVoters * 3 / 10;
        uint minScoreLength = 2;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].score.length < minScoreLength) {
                medians[i] = 0; // 得点が一定の長さよりも小さい場合、中央値を0に設定
            } else {
                medians[i] = calculateMedian(candidates[i].score);
            }
        }

        uint[] memory ranks = new uint[](candidates.length);
        for (uint i = 0; i < candidates.length; i++) {
            uint rank = 1;
            for (uint j = 0; j < candidates.length; j++) {
                if (medians[j] > medians[i]) {
                    rank++;
                }
                
                else if (medians[i] == medians[j]) {
                    if (ArrCalc(candidates[j].score) > ArrCalc(candidates[i].score)) {
                        rank++;
                    }
                }
                
            }
            if (medians[i] == 0){
                rank = 10000;
            }
            ranks[i] = rank;
        }

        string[] memory names = new string[](candidates.length);
        for (uint i = 0; i < candidates.length; i++) {
            names[i] = candidates[i].name;
        }

        uint CandidateNum = searchIndexStr(names, CandidateName);

        MedianValue = uint2str(medians[CandidateNum]);
        Rank = ranks[CandidateNum];
        ScoreGet = candidates[CandidateNum].score;     

        return (MedianValue, Rank, ScoreGet);
    }


    function endVoting() public onlyOwner returns(string memory winner_) {
        voteEnded = true;
        emit VoteEnded();
        
        (,, uint[] memory tempRanks) = getResults();
        uint winner = uint(searchIndexUint(tempRanks, 1));
        return candidates[winner].name;
    }

}