// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract GetVotedToEarnV3 {
    struct Contest {
        uint256 contestId;
        address contestCreator;
        Participant[] participants;
        string contestTitle;
        string contestDescription;
        uint256 contestPrizeAmount;
        uint256 contestWinningVoteOfUniqueValue;
        uint256 contestDeadline;
        Winner[] winner;
    }

    struct Winner {
        uint256 contestId;
        address winner;
        uint256 winedPriceAmount; // for a record
    }

    struct Participant {
        uint256 contestId;
        address workCreator;
        string workTitle;
        string workDescription;
        string workPreviewImage;
        string workWebAddress;
        uint256 voteCount;
    }

    mapping(uint256 => Contest) public contests;
    mapping(uint256 => Participant) public participants;
    mapping(uint256 => Winner) public winners;
    mapping(address => bool) public creators;
    mapping(address => bool) public isPlayer;

    uint256 public contestAmount = 0;
    uint256 public participantAmount = 0;
    uint256 public winnerAmount = 0;

    function createOneContest(
        string memory _contestTitle, 
        string memory _contestDescription,
        uint256 _contestUniqueWinningVoteCount,
        uint256 _contestDeadline,
        uint256 _contestPrizeAmount
    ) public returns (uint256) {
        // require(_contestPrizeAmount >= 100000000000000000,"at least 0.1 eth for the prize"); // use when mainnet
        require(_contestUniqueWinningVoteCount > 0 && _contestUniqueWinningVoteCount < 4,"between 1 and 3");
        require(_contestDeadline > block.timestamp,"Deadline To Be Came");
        Contest storage contest = contests[contestAmount];
        contest.contestId = contestAmount;
        contest.contestCreator = msg.sender;
        contest.contestTitle = _contestTitle;
        contest.contestDescription = _contestDescription;
        contest.contestPrizeAmount = _contestPrizeAmount;
        contest.contestWinningVoteOfUniqueValue = _contestUniqueWinningVoteCount;
        contest.contestDeadline = _contestDeadline;
        creators[msg.sender]=true;
        contestAmount++;
        return contestAmount - 1;
    }

    function createOneParticipant( // join the contest with work detail
        uint256 _contestId,
        string memory _projectTitle,
        string memory _projectDescription,
        string memory _projectPreviewImg,
        string memory _projectWebAddress
    ) public returns (uint256) {
        Contest storage contest = contests[_contestId];
        require(block.timestamp<contest.contestDeadline,"only before the contest deadline");
        require(msg.sender!=contest.contestCreator,"contest creator cannot join the contest he or she or they create");
        require(contestAmount>=1,"at least one contest");
        require(!isPlayer[msg.sender],"one address one participant only");
        Participant storage participant = participants[participantAmount];
        participant.contestId = contest.contestId;
        participant.workCreator = msg.sender;
        participant.workTitle = _projectTitle;
        participant.workDescription = _projectDescription;
        participant.workPreviewImage = _projectPreviewImg;
        participant.workWebAddress = _projectWebAddress;
        participant.voteCount = 0;
        isPlayer[msg.sender]=true;
        contest.participants.push(participant);
        participantAmount++;
        return participantAmount -1;
    }

    function voteToOneParticipant(uint256 _participantId,uint256 _contestId) public {
        Contest storage contest = contests[_contestId];
        require(block.timestamp<contest.contestDeadline,"only before the contest deadline");
        require(participantAmount>=1,"at least one player");
        require(!isPlayer[msg.sender],"voter must not be a participant in the contest");
        Participant storage targetParticipant = contest.participants[_participantId];
        targetParticipant.voteCount++;
    }

    function createWinner( // create winner(s)
        uint256 _contestId
    ) public returns (uint256) {
        Contest storage contest = contests[_contestId];
        require(contest.contestCreator==msg.sender,"only the contest creator address can call this func");
        require(block.timestamp>contest.contestDeadline,"only after the contest deadline");
        require(participantAmount > 0,"at least one player");
        uint256 totalPrize = contest.contestPrizeAmount;
        uint256 countOfUniqueWinningVote = contest.contestWinningVoteOfUniqueValue;
        Participant[] memory allParticipants = new Participant[](participantAmount);
        // if (participantAmount == 1) {
        //     require(allParticipants[0].voteCount > 0,"at least one vote");
        // }
        uint256[] memory indexArr = new uint256[](participantAmount);
        for (uint u=0;u<countOfUniqueWinningVote;u++) {
            indexArr[u]=u; // 0 1 2 at most in init
        } 
        for (uint kk=countOfUniqueWinningVote;kk<participantAmount;kk++){
            indexArr[kk] = 100000000000000000000000000000000000000000000;
        }
        if (indexArr.length-(indexArr.length-countOfUniqueWinningVote) >= 1 && participantAmount > 1) {
            uint256 differenceBetweenParticipantAmountAndNonInfiniteValue = countOfUniqueWinningVote;
            for (uint x=indexArr[indexArr.length-(indexArr.length-differenceBetweenParticipantAmountAndNonInfiniteValue)-1]+1;x<participantAmount;x++) {
                uint256 minValueIloc = 0;
                uint256[] memory finalArr = new uint256[](participantAmount);
                for (uint ff=0;ff<participantAmount;ff++){
                    finalArr[ff] = 100000000000000000000000000000000000000000000;
                }
                uint256 leng = indexArr.length-(indexArr.length-differenceBetweenParticipantAmountAndNonInfiniteValue);
                if (leng > 1) {
                    for (uint y=1;y<leng;y++) {
                        if (allParticipants[indexArr[y]].voteCount < allParticipants[indexArr[minValueIloc]].voteCount) {
                            minValueIloc = y;
                        } 
                    }
                } 
                if (allParticipants[x].voteCount>allParticipants[indexArr[minValueIloc]].voteCount) {
                    uint256 counter = 0;
                    uint256[] memory otherwiseArrIndexList = new uint256[](participantAmount);
                    otherwiseArrIndexList[0]=indexArr.length-(indexArr.length-differenceBetweenParticipantAmountAndNonInfiniteValue)+1; // not possible: have not been added yet
                    uint256 otherwiseCounter = 0;
                    uint256 prevVoteVal = allParticipants[0].voteCount; // default: first id value 
                    uint256 uniqueCounter = 1; // default: one unique value in the array
                    uint256 newUniqueValue = 0; // assume no new unique value added in the first place
                    for (uint q=0;q<leng;q++){
                        if (allParticipants[x].voteCount != allParticipants[indexArr[q]].voteCount) {
                            newUniqueValue = 1;
                        } else {}
                        if (allParticipants[indexArr[q]].voteCount==allParticipants[indexArr[minValueIloc]].voteCount) {
                            counter++;
                        } else {
                            if (allParticipants[indexArr[q]].voteCount != prevVoteVal) {
                                uniqueCounter++;
                                prevVoteVal = allParticipants[indexArr[q]].voteCount;
                            } 
                            if (otherwiseArrIndexList.length==1) {
                                otherwiseArrIndexList[0]=indexArr[q];
                            } else {
                                otherwiseArrIndexList[otherwiseArrIndexList.length]=indexArr[q];
                            }
                            otherwiseCounter++;
                        }
                    }
                    if (counter > 1) {
                        if (newUniqueValue + uniqueCounter > countOfUniqueWinningVote) {
                            uint256 start = 0;
                            while (start < leng-counter) {
                                finalArr[start]=otherwiseArrIndexList[start];
                                start++;
                            }
                        } else {
                            finalArr=indexArr;
                        }
                        if (countOfUniqueWinningVote > 1) {
                            finalArr[finalArr.length-(finalArr.length-differenceBetweenParticipantAmountAndNonInfiniteValue)-counter]=x;
                        } else {
                            finalArr[0]=x;
                        }
                    } else {
                        if (minValueIloc+1 !=x) {
                            uint256 start = 0;
                            uint256 skip = 0;
                            while (start!=leng) {
                                if (newUniqueValue + uniqueCounter <= countOfUniqueWinningVote) { 
                                    finalArr[start]=indexArr[start];
                                    start++;
                                } else {
                                    if (skip < minValueIloc) {
                                        finalArr[start]=indexArr[start]; 
                                        start++;
                                    } else if (skip == minValueIloc) {
                                        // nothing so that skipped
                                    } else {
                                        finalArr[start]=indexArr[start+counter]; 
                                        start++;
                                    }
                                    skip++;
                                    if (start > leng-counter*2) { 
                                        break;
                                    }
                                }
                            }
                            finalArr[finalArr.length-(finalArr.length-differenceBetweenParticipantAmountAndNonInfiniteValue)-1]=x;
                        } else {
                            finalArr=indexArr;
                            finalArr[minValueIloc]=x;
                        }
                    }
                }
                else if (allParticipants[x].voteCount==allParticipants[minValueIloc].voteCount) {
                    uint256 counterElseIf = 0;
                    for (uint n=0;n<leng;n++){
                        if (allParticipants[indexArr[n]].voteCount==allParticipants[indexArr[minValueIloc]].voteCount) {
                            counterElseIf++;
                        } 
                    }
                    if (leng+1>countOfUniqueWinningVote) {
                        if (counterElseIf >= 1) {
                            finalArr=indexArr;
                            finalArr[finalArr.length]=x;
                        }
                    } 
                }
                indexArr=finalArr;
                differenceBetweenParticipantAmountAndNonInfiniteValue = 0;
                for (uint op=0;op<indexArr.length;op++) {
                    if (indexArr[op]!=100000000000000000000000000000000000000000000) {
                        differenceBetweenParticipantAmountAndNonInfiniteValue++;
                    }
                }
            }
        }
        uint256 counterKKK = 0;
        for (uint op=0;op<indexArr.length;op++) {
            if (indexArr[op]!=100000000000000000000000000000000000000000000) {
                counterKKK++;
            }
        }
        uint256 finalLength = indexArr.length-(indexArr.length-counterKKK);
        uint256[] memory minVoteValueIndexList = new uint256[](finalLength);
        uint256[] memory medVoteValueIndexList = new uint256[](finalLength);
        uint256[] memory maxVoteValueIndexList = new uint256[](finalLength);
        medVoteValueIndexList[0]=0; // just in case
        if (finalLength > 1) {
            uint256 prevMinVal = allParticipants[indexArr[0]].voteCount;
            uint256 prevMedVal = 0;
            prevMedVal=allParticipants[indexArr[0]].voteCount;
            uint256 prevMaxVal = allParticipants[indexArr[finalLength-1]].voteCount;
            // distribute into different ranking by an identical value
            for (uint b=1;b<finalLength;b++){
                if (allParticipants[indexArr[b]].voteCount<prevMinVal) {
                    prevMinVal=allParticipants[indexArr[b]].voteCount;
                }
            }
            for (uint a=0;a<finalLength-1;a++){
                if (allParticipants[indexArr[a]].voteCount>prevMaxVal) {
                    prevMaxVal=allParticipants[indexArr[a]].voteCount;
                }
            }
            for (uint l=0;l<finalLength;l++){
                if (allParticipants[indexArr[l]].voteCount!=prevMaxVal) {
                    if (allParticipants[indexArr[l]].voteCount!=prevMinVal) {
                        prevMedVal=allParticipants[indexArr[l]].voteCount;
                    }
                }
            }
            // log into min med max lists
            for (uint ef=0;ef<finalLength;ef++){
                if (allParticipants[indexArr[ef]].voteCount==prevMinVal) {
                    if (minVoteValueIndexList.length==0) {
                        minVoteValueIndexList[0]=indexArr[ef];
                    } else {
                        minVoteValueIndexList[minVoteValueIndexList.length]=indexArr[ef];
                    }
                }
            }
            for (uint ac=0;ac<finalLength;ac++){
                if (allParticipants[indexArr[ac]].voteCount==prevMaxVal) {
                    if (maxVoteValueIndexList.length==0) {
                        maxVoteValueIndexList[0]=indexArr[ac];
                    } else {
                        maxVoteValueIndexList[maxVoteValueIndexList.length]=indexArr[ac];
                    }
                }
            }
            if (countOfUniqueWinningVote == 3) {
                for (uint hi=0;hi<finalLength;hi++){
                    if (allParticipants[indexArr[hi]].voteCount!=prevMaxVal) {
                        if (allParticipants[indexArr[hi]].voteCount!=prevMinVal) {
                            if (medVoteValueIndexList.length==1) {
                                medVoteValueIndexList[0]=indexArr[hi];
                            } else {
                                medVoteValueIndexList[medVoteValueIndexList.length]=indexArr[hi];
                            }
                        }
                    }
                }
            }
        } else {}
        if (finalLength > 1) {
            if (countOfUniqueWinningVote == 1) {
                for (uint ui=0;ui<minVoteValueIndexList.length;ui++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[minVoteValueIndexList[ui]].workCreator;
                    uint256 sharedOfPrize = totalPrize/finalLength;
                    participantWhoWon.winedPriceAmount = sharedOfPrize;
                    participantWhoWon.contestId = contest.contestId;
                    contest.winner.push(participantWhoWon);
                    winnerAmount++;
                }
            } else if(countOfUniqueWinningVote == 2) {
                for (uint st=0;st<minVoteValueIndexList.length;st++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[minVoteValueIndexList[st]].workCreator;
                    participantWhoWon.contestId = contest.contestId;
                    uint256 sharedOfPrize = totalPrize*(finalLength-1)/(finalLength*countOfUniqueWinningVote);
                    uint256 evenShare = sharedOfPrize/minVoteValueIndexList.length;
                    participantWhoWon.winedPriceAmount = evenShare;
                    contest.winner.push(participantWhoWon);
                    winnerAmount++;
                }
                for (uint xy=0;xy<maxVoteValueIndexList.length;xy++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[maxVoteValueIndexList[xy]].workCreator;
                    participantWhoWon.contestId = contest.contestId;
                    uint256 sharedOfPrize = totalPrize*(finalLength+1)/(finalLength*countOfUniqueWinningVote);
                    uint256 evenShare = sharedOfPrize/maxVoteValueIndexList.length;
                    participantWhoWon.winedPriceAmount = evenShare;
                    contest.winner.push(participantWhoWon);
                    winnerAmount++;
                }
            } else {
                for (uint jk=0;jk<minVoteValueIndexList.length;jk++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[minVoteValueIndexList[jk]].workCreator;
                    participantWhoWon.contestId = contest.contestId;
                    uint256 sharedOfPrize = totalPrize*(finalLength-1)/(finalLength*countOfUniqueWinningVote);
                    uint256 evenShare = sharedOfPrize/minVoteValueIndexList.length;
                    participantWhoWon.winedPriceAmount = evenShare;
                    contest.winner.push(participantWhoWon);
                    winnerAmount++;
                }
                for (uint pq=0;pq<maxVoteValueIndexList.length;pq++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[maxVoteValueIndexList[pq]].workCreator;
                    participantWhoWon.contestId = contest.contestId;
                    uint256 sharedOfPrize = totalPrize*(finalLength+1)/(finalLength*countOfUniqueWinningVote);
                    uint256 evenShare = sharedOfPrize/maxVoteValueIndexList.length;
                    participantWhoWon.winedPriceAmount = evenShare;
                    contest.winner.push(participantWhoWon);
                    winnerAmount++;
                }
                for (uint cd=0;cd<medVoteValueIndexList.length;cd++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[medVoteValueIndexList[cd]].workCreator;
                    participantWhoWon.contestId = contest.contestId;
                    uint256 sharedOfPrize = totalPrize*(finalLength)/(finalLength*countOfUniqueWinningVote);
                    uint256 evenShare = sharedOfPrize/medVoteValueIndexList.length;
                    participantWhoWon.winedPriceAmount = evenShare;
                    contest.winner.push(participantWhoWon);
                    winnerAmount++;
                }
            }
        } else {
            Winner storage participantWhoWon = winners[winnerAmount];
            participantWhoWon.winner = allParticipants[indexArr[0]].workCreator;
            participantWhoWon.contestId = contest.contestId;
            participantWhoWon.winedPriceAmount = totalPrize;
            contest.winner.push(participantWhoWon);
            winnerAmount++;
        }
        return winnerAmount-finalLength;
    }

    function sendMoneyToOneWinner(address _winnerAddress) public payable {
        (bool paid,) = payable(_winnerAddress).call{value:msg.value}("");
        if (paid) {
            // can consider to add isPaid bool status to the Winner struct
        }
    }

    function getAllContests() public view returns (Contest[] memory) {
        Contest[] memory allContests = new Contest[](contestAmount);
        for (uint k=0;k<contestAmount;k++){
            Contest storage individualContest = contests[k];
            allContests[k]=individualContest;
        }
        return allContests;
    }

    function getAllParticipantsDetailForAContest(uint256 _contestId) public view returns (Participant[] memory) {
        return contests[_contestId].participants;
    }

    function getAllWinnersDetailForAContest(uint256 _contestId) view public returns (Winner[] memory) {
        return contests[_contestId].winner;
    }

    function getAllVoteCountForAParticipant(uint256 _participantsId) view public returns (uint256) {
        return participants[_participantsId].voteCount;
    }
}