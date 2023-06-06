/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


                        //        .__            _____  _____.__                                   .___      
                        //   _____|  |__  __ ___/ ____\/ ____\  |   ____     ____ _____ _______  __| _/______
                        //  /  ___/  |  \|  |  \   __\\   __\|  | _/ __ \  _/ ___\\__  \\_  __ \/ __ |/  ___/
                        //  \___ \|   Y  \  |  /|  |   |  |  |  |_\  ___/  \  \___ / __ \|  | \/ /_/ |\___ \ 
                        // /____  >___|  /____/ |__|   |__|  |____/\___  >  \___  >____  /__|  \____ /____  >
                        //      \/     \/                              \/       \/     \/           \/    \/ 


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IdirectRandom {

    function requestRandomWords() external returns(uint256 );

    function getRequestStatus(uint256 _requestId) external view returns(uint256 , bool , uint256[] memory);

    function lastRequestId() external view returns(uint256);

    function transferOwnership(address newOwner) external ;

    function acceptOwnership() external ;

}

contract shuffleCards is Ownable {

    // cards Number
    uint8[52] private cards = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52];

    address public operator;
    IdirectRandom public directRandom;
    uint256 public lastRandom;
    uint256 public gameCount;
    uint256 public feeForVerifier;
    uint256[] public randomWords;
    
    struct roundDetails{
        uint256 fairnessNumber;
        uint64 startingTime;
        uint8[52] shufflingCards;
    }   
    
    mapping(uint => roundDetails) private gameRoundInfo;

    event RoundEvent(uint indexed RoundID, uint indexed CreationTime);

    constructor(address _operator, address _directRandom) {
        operator = _operator;
        directRandom = IdirectRandom(_directRandom);
    }

    modifier onlyOperator() {
        require(_msgSender() == operator,"operator only call this function");
        _;
    }

    function createRound() external onlyOperator {
        gameCount++;
        roundDetails storage round = gameRoundInfo[gameCount];

        round.startingTime = uint64(block.timestamp);

        getRandomNum();
        uint8[52] memory deck = shuffleCard(lastRandom);
        round.fairnessNumber = lastRandom;
        round.shufflingCards = deck;

        emit RoundEvent(gameCount, block.timestamp);
    }

    function getRandomNum() internal {
        lastRandom = directRandom.requestRandomWords();
        // (,, randomWords) = directRandom.getRequestStatus(lastRandom);
    }

    function shuffleCard(uint random) public view returns(uint8[52] memory){

        uint8[52] memory values = cards;

        for(uint8 i = 0; i < cards.length; i++){
            uint256 n = i + uint256(keccak256(abi.encodePacked(random))) % (cards.length - i);

            uint8 temp = values[n];
            values[n] = values[i];
            values[i] = temp; 
        }

        return values;
    }

    function transferRandomOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0x0), "invalid address");
        directRandom.transferOwnership(_newOwner);
    }

    function updateDirectRandom(address _newRandomGenerator) external onlyOwner{
        require(_newRandomGenerator != address(0x0), "invalid address");
        directRandom = IdirectRandom(_newRandomGenerator);
    }

    function updateOperator(address _newOperator) external onlyOwner{
        require(_newOperator != address(0x0), "invalid address");
        operator = _newOperator;
    }

    function acceptRandomOwnership() external {
        directRandom.acceptOwnership();
    }

    function getRoundDetails(uint _roundID) external view onlyOperator returns(uint8[52] memory Deck,uint randomNumber, uint64 roundStartTime){
        roundDetails storage round = gameRoundInfo[_roundID];
        return (round.shufflingCards, round.fairnessNumber, round.startingTime);
    }

}