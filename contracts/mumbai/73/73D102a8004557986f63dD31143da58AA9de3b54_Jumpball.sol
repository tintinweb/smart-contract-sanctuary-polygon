// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Jumpball {
    address public owner;

    constructor() {
        owner = msg.sender; 
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    enum progressType { open, home, away }
    struct GameInfo {
        string typeAndId;
        string name;
        string home;
        string away;
        uint256 startTime;
        progressType completed;
        uint256 homeSum;
        uint256 awaySum;
        uint256 harvestedSum;
        address validator; 
    }
    struct BetInfo {
        string typeAndId;
        uint256 homeSum;
        uint256 awaySum;
        bool isHarvested;
    }
    mapping(string => GameInfo) gameInfos;
    mapping(address => mapping(string => BetInfo)) betInfos;

    function setGameInfo(string memory _id, uint256 _date, string memory _match, string memory _home, string memory _away) internal {
        gameInfos[_id] = GameInfo(_id, _match, _home, _away, _date, progressType.open, 0, 0, 0, address(0));
    }

    function getGameInfo(string memory _id) public view returns(GameInfo memory){
        return gameInfos[_id];
    }

    function getMyBetInfo(string memory _id) public view returns(uint256, uint256){
        return (betInfos[msg.sender][_id].homeSum, betInfos[msg.sender][_id].awaySum);
    }

    function isEnrollId(string memory _id) internal view returns(bool){
        if(gameInfos[_id].startTime > 0){
            return true;
        }
        return false;
    }

    function betting(string memory _id, uint256 _date, string memory _match, string memory _home, string memory _away, bool _isHome) public payable returns(bool){
        if(!isEnrollId(_id)){
            setGameInfo(_id, _date, _match, _home, _away);
        }
        require(msg.value > 0,"not allowed 0 value");
        require(isEnrollId(_id), "not enrolled id");
        require(gameInfos[_id].startTime > block.timestamp);
        require(gameInfos[_id].completed == progressType.open, 'already validated');

        if(_isHome){
            gameInfos[_id].homeSum += msg.value;
            betInfos[msg.sender][_id].typeAndId = _id;
            betInfos[msg.sender][_id].homeSum += msg.value;
        }else{
            gameInfos[_id].awaySum += msg.value;
            betInfos[msg.sender][_id].typeAndId = _id;
            betInfos[msg.sender][_id].awaySum += msg.value;
        }
        return true;
    }

    function validateGame(string memory _id, bool _win) public onlyOwner {
        require(gameInfos[_id].startTime < block.timestamp);
        require(gameInfos[_id].completed == progressType.open, 'aleady validated');
        if(_win){
            gameInfos[_id].completed = progressType.home;
        }else{
            gameInfos[_id].completed = progressType.away;
        }
        gameInfos[_id].validator = msg.sender;
    }

    function harvest(string memory _id) public returns(uint) {
        require(gameInfos[_id].completed != progressType.open, 'not validated');
        require(!betInfos[msg.sender][_id].isHarvested, 'already harvested');

        bool result = gameInfos[_id].completed == progressType.home ? true : false;
        if(result){
            uint amount = (gameInfos[_id].homeSum + gameInfos[_id].awaySum) * (betInfos[msg.sender][_id].homeSum / gameInfos[_id].homeSum);
            payable(msg.sender).transfer(amount);
            gameInfos[_id].harvestedSum += amount;
            betInfos[msg.sender][_id].isHarvested = true;
            return amount;
        }else{
            uint amount = (gameInfos[_id].homeSum + gameInfos[_id].awaySum) * (betInfos[msg.sender][_id].awaySum / gameInfos[_id].awaySum);
            payable(msg.sender).transfer(amount);
            gameInfos[_id].harvestedSum += amount;
            betInfos[msg.sender][_id].isHarvested = true;
            return amount;
        }
    }
}