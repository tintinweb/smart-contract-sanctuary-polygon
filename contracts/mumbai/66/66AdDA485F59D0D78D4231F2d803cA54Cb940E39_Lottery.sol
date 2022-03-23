/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Lottery {

    // 1
    uint256[] public grandPrizeList;
    uint internal constant grandPrizeNum = 1;
    // 4
    uint256[] public firstPrizeList;
    uint internal constant firstPrizeNum = 4;
    // 15
    uint256[] public secondPrizeList;
    uint internal constant secondPrizeNum = 15;
    // 200
    uint256[] public thirdPrizeList;
    uint internal constant thirdPrizeNum = 200;
    // 1000
    uint256[] public fourthPrizeList;
    uint internal constant fourthPrizeNum = 1000;

    // 120000
    uint internal constant totalParticipation = 120000;
    uint internal thirdIndex = 0;
    uint internal fourthIndex = 0;
    uint internal thirdTimes = 0;
    uint internal fourthTimes = 0;
    uint256[] internal lists;

    event LuckyListUpdate(
        uint8 prizeType,
        uint times,
        uint loopIndex,
        uint prizeLength,
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

    function random(uint256 number,uint256 i) internal pure returns(uint256) {
        uint256 randomValue;
        if(number==0){
            randomValue=12345;
        }else if(number==1){
            randomValue=56505;
        }else if(number==2){
            randomValue=43467;
        }else if(number==3){
            randomValue=59467;
        }else if(number==4){
            randomValue=32156;
        }
        return uint256(keccak256(abi.encodePacked(abi.encode(number,randomValue,i))));
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
        emit LuckyListUpdate(0,1,loopIndex,grandPrizeList.length,grandPrizeList);
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
        emit LuckyListUpdate(1,1,loopIndex,firstPrizeList.length,firstPrizeList);
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
        emit LuckyListUpdate(2,1,loopIndex,secondPrizeList.length,secondPrizeList);
    }

    function pickWinnerForThird() internal  {
        require(thirdPrizeList.length<thirdPrizeNum,"The award has been drawn out");
        thirdTimes++;
        if(lists.length>0){
            delete(lists);
        }
        uint loopIndex=0;
        for(uint256 i=thirdIndex;i<totalParticipation;i++){
            loopIndex=i;
            thirdIndex=i+1;
            uint256 randomNumber=random(3,i)%totalParticipation;
            if (prizeInfo[randomNumber]==0) {
                prizeInfo[randomNumber]=3;
                thirdPrizeList.push(randomNumber);
                lists.push(randomNumber);
            }
            if (thirdPrizeList.length%100==0){
                break;
            }
        }
        emit LuckyListUpdate(3,thirdTimes,loopIndex,thirdPrizeList.length,lists);
    }

    function pickWinnerForFourth() internal  {
        require(fourthPrizeList.length<fourthPrizeNum,"The award has been drawn out");
        fourthTimes++;
        uint loopIndex=0;
        if(lists.length>0){
            delete(lists);
        }
        for(uint256 i=fourthIndex;i<totalParticipation;i++){
            loopIndex=i;
            fourthIndex=i+1;
            uint256 randomNumber=random(4,i)%totalParticipation;
            if (prizeInfo[randomNumber]==0) {
                prizeInfo[randomNumber]=4;
                fourthPrizeList.push(randomNumber);
                lists.push(randomNumber);
            }
            if (fourthPrizeList.length%100==0){
                break;
            }
        }
        emit LuckyListUpdate(4,fourthTimes,loopIndex,fourthPrizeList.length,lists);
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