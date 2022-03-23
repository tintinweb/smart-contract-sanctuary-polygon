/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Lottery {

    // 1
    uint256[] public grandPrizeList;
    uint public constant grandPrizeNum = 1;
    // 4
    uint256[] public firstPrizeList;
    uint public constant firstPrizeNum = 4;
    // 15
    uint256[] public secondPrizeList;
    uint public constant secondPrizeNum = 15;
    // 200
    uint256[] public thirdPrizeList;
    uint public constant thirdPrizeNum = 200;
    // 1000
    uint256[] public fourthPrizeList;
    uint public constant fourthPrizeNum = 1000;

    // 120000
    uint public constant totalParticipation = 120000;
    uint public index = 0;
    uint public times = 0;
    uint256[] internal lists;

    event LuckyListUpdate(
        uint8 prizeType,
        uint loopIndex,
        uint times,
        uint256[] winners
    );

    mapping(uint256 => uint256) public prizeInfo;

    address public admin;

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor(){
        admin = msg.sender;
    }

    function random(uint256 number,uint256 i) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,abi.encode(number,i))));
    }

    function pickWinner(uint8 number) public onlyAdmin {
        if (number==0){
            pickWinnerForGrand();
        }else if (number==1){
            pickWinnerForFist();
        } else if(number==2){
            pickWinnerForSecond();
        } else if(number==3){
            pickWinnerForThird();
        } else if(number==4){
            pickWinnerForFourth();
        }
    }

    function pickWinnerForGrand() internal  {
        require(grandPrizeList.length<grandPrizeNum,"The award has been drawn out");
        uint loopIndex=0;
        for(uint256 i=0;i<totalParticipation;i++){
            loopIndex=i;
            uint256 randomNumber=random(0,i)%totalParticipation;
            if (prizeInfo[randomNumber]==0) {
                prizeInfo[randomNumber]=5;
                grandPrizeList.push(randomNumber);
            }
            if (grandPrizeList.length==grandPrizeNum){
                break;
            }
        }
        emit LuckyListUpdate(0,loopIndex,1,grandPrizeList);
    }

    function pickWinnerForFist() internal  {
        require(firstPrizeList.length<firstPrizeNum,"The award has been drawn out");
        uint loopIndex=0;
        for(uint256 i=0;i<totalParticipation;i++){
            loopIndex=i;
            uint256 randomNumber=random(1,i)%totalParticipation;
            if (prizeInfo[randomNumber]==0) {
                prizeInfo[randomNumber]=1;
                firstPrizeList.push(randomNumber);
            }
            if (firstPrizeList.length==firstPrizeNum){
                break;
            }
        }
        emit LuckyListUpdate(1,loopIndex,1,firstPrizeList);
    }

    function pickWinnerForSecond() internal  {
        require(secondPrizeList.length<secondPrizeNum,"The award has been drawn out");
        uint loopIndex=0;
        for(uint256 i=0;i<totalParticipation;i++){
            loopIndex=i;
            uint256 randomNumber=random(2,i)%totalParticipation;
            if (prizeInfo[randomNumber]==0) {
                prizeInfo[randomNumber]=2;
                secondPrizeList.push(randomNumber);
            }
            if (secondPrizeList.length==secondPrizeNum){
                break;
            }
        }
        emit LuckyListUpdate(2,loopIndex,1,secondPrizeList);
    }

    function pickWinnerForThird() internal  {
        require(thirdPrizeList.length<thirdPrizeNum,"The award has been drawn out");
        uint loopIndex=0;
        for(uint256 i=0;i<totalParticipation;i++){
            loopIndex=i;
            uint256 randomNumber=random(3,i)%totalParticipation;
            if (prizeInfo[randomNumber]==0) {
                prizeInfo[randomNumber]=3;
                thirdPrizeList.push(randomNumber);
            }
            if (thirdPrizeList.length==thirdPrizeNum){
                break;
            }
        }
        emit LuckyListUpdate(3,loopIndex,1,thirdPrizeList);
    }

    function pickWinnerForFourth() internal  {
        require(fourthPrizeList.length<fourthPrizeNum,"The award has been drawn out");
        times++;
        uint loopIndex=0;
        if(lists.length>0){
            delete(lists);
        }
        for(uint256 i=index;i<totalParticipation;i++){
            loopIndex=i;
            index=i+1;
            uint256 randomNumber=random(4,i)%totalParticipation;
            if (prizeInfo[randomNumber]==0) {
                prizeInfo[randomNumber]=4;
                firstPrizeList.push(randomNumber);
                lists.push(randomNumber);
            }
            if ((fourthPrizeList.length+1)%200==0){
                break;
            }
        }
        emit LuckyListUpdate(4,loopIndex,times,lists);
    }

    function getArr(uint8 number) public view returns (uint256[] memory) {
        if (number==1){
            return firstPrizeList;
        } else if(number==2){
            return secondPrizeList;
        } else if(number==3){
            return thirdPrizeList;
        } else if(number==4){
            return fourthPrizeList;
        } else {
            return grandPrizeList;
        }
    }

}