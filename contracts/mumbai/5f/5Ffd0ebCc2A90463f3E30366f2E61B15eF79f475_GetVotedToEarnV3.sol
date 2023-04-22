// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// create a pool of prize?
// create a contest
// create participants by attracting people to join: prize pool
// if one winner allowed only
// find the highest vote to choose a winner 
// send money to highest vote
// else
// find the n highest vote count to get the n winners
// send money by proportion to the n addresses

contract GetVotedToEarnV3 {
    // func list
    // create a contest and fund the contest at the same time
    struct Contest {
        address contestCreator;
        Participant[] participants;
        string contestTitle;
        string contestDescription;
        uint256 contestPrizeAmount;
        uint256 contestWinningVoteOfUniqueValue; // <= 3 && > 0 && int
        uint256 contestDeadline;
        Winner[] winner;
    }

    struct Winner {
        address winner;
        uint256 winedPriceAmount; // for a record
    }

    // func list
    // create a participant if one wants to join the contest
    // create a vote if an user wants to make a vote; if voter is one of the participants, illegal
    struct Participant {
        address workCreator;
        string workTitle;
        string workDescription;
        string workPreviewImage;
        string workWebAddress;
        Vote[] collectedVote;
    }

    struct Vote {
        address voter;
    }

    modifier onlyContestCreator(uint256 _id) {
        Contest storage contest = contests[_id];
        require(msg.sender == contest.contestCreator,"only contest creator can use this func"); // maybe a bug in this method
        _;
    }

    mapping(uint256 => Contest) public contests;
    mapping(uint256 => Participant) public participants;
    mapping(uint256 => Winner) public winners;
    mapping(uint256 => Vote) public votes;
    mapping(address => bool) public creators;
    mapping(address => bool) public isPlayer;

    uint256 public contestAmount = 0;
    uint256 public participantAmount = 0;
    uint256 public winnerAmount = 0;
    uint256 public voteAmount = 0;

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
        require(msg.sender!=contest.contestCreator,"contest creator cannot join the contest he or she or they create");
        Participant storage participant = participants[participantAmount];
        participant.workCreator = msg.sender;
        participant.workTitle = _projectTitle;
        participant.workDescription = _projectDescription;
        participant.workPreviewImage = _projectPreviewImg;
        participant.workWebAddress = _projectWebAddress;
        participantAmount++;
        isPlayer[msg.sender]=true;
        contest.participants.push(participant);
        return participantAmount -1;
    }

    function voteToOneParticipant(uint256 _participantId,uint256 _contestId) public returns (uint256) {
        Contest storage contest = contests[_contestId];
        Participant storage targetParticipant = contest.participants[_participantId];
        address voteFromAddress = msg.sender;
        require(!isPlayer[msg.sender],"voter must not be a participant in the contest");
        targetParticipant.collectedVote.push(Vote({voter:voteFromAddress}));
        voteAmount++;
        return voteAmount - 1;
    }

    function createWinner( // create winner(s) and send prize
        uint256 _contestId
    ) public payable returns (uint256) { // only the contest creator can call;
        Contest storage contest = contests[_contestId];
        require(contest.contestCreator==msg.sender,"only the contest creator address can call this func");
        require(block.timestamp>contest.contestDeadline,"only after the contest deadline");
        require(msg.value==contest.contestPrizeAmount,"prize synced needed");
        uint256 totalPrize = msg.value;
        uint256 countOfUniqueWinningVote = contest.contestWinningVoteOfUniqueValue;
        Participant[] memory allParticipants = new Participant[](participantAmount);
        uint256[] memory indexArr = new uint256[](countOfUniqueWinningVote*100);
        for (uint u=0;u<countOfUniqueWinningVote;u++) {
            indexArr[u]=u; // 0 1 2
        }
        for (uint x=countOfUniqueWinningVote;x<participantAmount;x++) {
            uint256 minValueIloc = 0;
            uint256[] memory finalArr = new uint256[](countOfUniqueWinningVote*10);
            if (indexArr.length > 1) {
                for (uint y=1;y<indexArr.length;y++) {
                    if (allParticipants[indexArr[y]].collectedVote.length < allParticipants[indexArr[minValueIloc]].collectedVote.length) {
                        minValueIloc = y;
                    } 
                }
            } 
            if (allParticipants[x].collectedVote.length>allParticipants[indexArr[minValueIloc]].collectedVote.length) {
                uint256 counter = 0;
                uint256[] memory otherwiseArrIndexList = new uint256[](countOfUniqueWinningVote*10);
                otherwiseArrIndexList[0]=indexArr.length+1; // not possible: have not been added yet
                uint256 otherwiseCounter = 0;
                uint256 prevVoteVal = allParticipants[0].collectedVote.length; // default: first id value 
                uint256 uniqueCounter = 1; // default: one unique value in the array
                uint256 newUniqueValue = 0; // assume no new unique value added in the first place
                for (uint q=0;q<indexArr.length;q++){
                    if (allParticipants[x].collectedVote.length != allParticipants[indexArr[q]].collectedVote.length) {
                        newUniqueValue = 1;
                    } 
                }
                for (uint g=0;g<indexArr.length;g++){
                    if (allParticipants[indexArr[g]].collectedVote.length==allParticipants[indexArr[minValueIloc]].collectedVote.length) {
                        counter++;
                    } else {
                        if (allParticipants[indexArr[g]].collectedVote.length != prevVoteVal) {
                            uniqueCounter++;
                            prevVoteVal = allParticipants[indexArr[g]].collectedVote.length;
                        } 
                        if (otherwiseArrIndexList.length==1) {
                            otherwiseArrIndexList[0]=indexArr[g];
                        } else {
                            otherwiseArrIndexList[otherwiseArrIndexList.length]=indexArr[g];
                        }
                        otherwiseCounter++;
                    }
                }
                if (counter > 1) {
                    if (newUniqueValue + uniqueCounter > countOfUniqueWinningVote) {
                        uint256 leftCount = indexArr.length-counter; 
                        uint256 start = 0;
                        while (start < leftCount) {
                            finalArr[start]=otherwiseArrIndexList[start];
                            start++;
                        }
                    } else {
                        finalArr=indexArr;
                    }
                    if (countOfUniqueWinningVote > 1) {
                        finalArr[finalArr.length]=x;
                    } else {
                        finalArr[0]=x;
                    }
                } else {
                    if (minValueIloc+1 !=x) {
                        uint256 start = 0;
                        uint256 skip = 0;
                        while (start!=indexArr.length) {
                            if (newUniqueValue + uniqueCounter <= countOfUniqueWinningVote) { 
                                finalArr[start]=indexArr[start];
                                start++;
                            } else {
                                if (skip < minValueIloc) {
                                    finalArr[start]=indexArr[start]; 
                                    start++;
                                } else if (skip == minValueIloc) {

                                } else {
                                    finalArr[start]=indexArr[start+counter]; 
                                    start++;
                                }
                                skip++;
                                if (start > indexArr.length-counter*2) { 
                                    break;
                                }
                            }
                        }
                        finalArr[finalArr.length]=x;
                    } else {
                        finalArr=indexArr;
                        finalArr[minValueIloc]=x;
                    }
                }
            }
            else if (allParticipants[x].collectedVote.length==allParticipants[minValueIloc].collectedVote.length) {
                uint256 counterElseIf = 0;
                for (uint n=0;n<indexArr.length;n++){
                    if (allParticipants[indexArr[n]].collectedVote.length==allParticipants[indexArr[minValueIloc]].collectedVote.length) {
                        counterElseIf++;
                    } 
                }
                if (indexArr.length+1>countOfUniqueWinningVote) {
                    if (counterElseIf >= 1) {
                        finalArr=indexArr;
                        finalArr[finalArr.length]=x;
                    }
                } 
            }
            indexArr=finalArr;
        }
        uint256[] memory minVoteValueIndexList = new uint256[](indexArr.length);
        uint256[] memory medVoteValueIndexList = new uint256[](indexArr.length);
        uint256[] memory maxVoteValueIndexList = new uint256[](indexArr.length);
        medVoteValueIndexList[0]=0; // just in case
        if (indexArr.length > 1) {
            uint256 prevMinVal = allParticipants[indexArr[0]].collectedVote.length;
            uint256 prevMedVal = 0;
            prevMedVal=allParticipants[indexArr[0]].collectedVote.length;
            uint256 prevMaxVal = allParticipants[indexArr[indexArr.length-1]].collectedVote.length;
            // distribute into different ranking by an identical value
            for (uint b=1;b<indexArr.length;b++){
                if (allParticipants[indexArr[b]].collectedVote.length<prevMinVal) {
                    prevMinVal=allParticipants[indexArr[b]].collectedVote.length;
                }
            }
            for (uint a=0;a<indexArr.length-1;a++){
                if (allParticipants[indexArr[a]].collectedVote.length>prevMaxVal) {
                    prevMaxVal=allParticipants[indexArr[a]].collectedVote.length;
                }
            }
            for (uint l=0;l<indexArr.length;l++){
                if (allParticipants[indexArr[l]].collectedVote.length!=prevMaxVal) {
                    if (allParticipants[indexArr[l]].collectedVote.length!=prevMinVal) {
                        prevMedVal=allParticipants[indexArr[l]].collectedVote.length;
                    }
                }
            }
            // log into min med max lists
            for (uint ef=0;ef<indexArr.length;ef++){
                if (allParticipants[indexArr[ef]].collectedVote.length==prevMinVal) {
                    if (minVoteValueIndexList.length==0) {
                        minVoteValueIndexList[0]=indexArr[ef];
                    } else {
                        minVoteValueIndexList[minVoteValueIndexList.length]=indexArr[ef];
                    }
                }
            }
            for (uint ac=0;ac<indexArr.length;ac++){
                if (allParticipants[indexArr[ac]].collectedVote.length==prevMaxVal) {
                    if (maxVoteValueIndexList.length==0) {
                        maxVoteValueIndexList[0]=indexArr[ac];
                    } else {
                        maxVoteValueIndexList[maxVoteValueIndexList.length]=indexArr[ac];
                    }
                }
            }
            if (countOfUniqueWinningVote == 3) {
                for (uint hi=0;hi<indexArr.length;hi++){
                    if (allParticipants[indexArr[hi]].collectedVote.length!=prevMaxVal) {
                        if (allParticipants[indexArr[hi]].collectedVote.length!=prevMinVal) {
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
        if (indexArr.length > 1) {
            if (countOfUniqueWinningVote == 1) {
                for (uint ui=0;ui<minVoteValueIndexList.length;ui++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[minVoteValueIndexList[ui]].workCreator;
                    winnerAmount++;
                    uint256 sharedOfPrize = totalPrize/indexArr.length;
                    (bool paid,) = payable(participantWhoWon.winner).call{value:sharedOfPrize}("");
                    if (paid) {
                        participantWhoWon.winedPriceAmount = sharedOfPrize;
                    }
                }
            } else if(countOfUniqueWinningVote == 2) {
                for (uint st=0;st<minVoteValueIndexList.length;st++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[minVoteValueIndexList[st]].workCreator;
                    winnerAmount++;
                    uint256 sharedOfPrize = totalPrize*(indexArr.length-1)/(indexArr.length*countOfUniqueWinningVote);
                    uint256 evenShare = sharedOfPrize/minVoteValueIndexList.length;
                    (bool paid,) = payable(participantWhoWon.winner).call{value:evenShare}("");
                    if (paid) {
                        participantWhoWon.winedPriceAmount = evenShare;
                    }
                }
                for (uint xy=0;xy<maxVoteValueIndexList.length;xy++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[maxVoteValueIndexList[xy]].workCreator;
                    winnerAmount++;
                    uint256 sharedOfPrize = totalPrize*(indexArr.length+1)/(indexArr.length*countOfUniqueWinningVote);
                    uint256 evenShare = sharedOfPrize/maxVoteValueIndexList.length;
                    (bool paid,) = payable(participantWhoWon.winner).call{value:evenShare}("");
                    if (paid) {
                        participantWhoWon.winedPriceAmount = evenShare;
                    }
                }
            } else {
                for (uint jk=0;jk<minVoteValueIndexList.length;jk++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[minVoteValueIndexList[jk]].workCreator;
                    winnerAmount++;
                    uint256 sharedOfPrize = totalPrize*(indexArr.length-1)/(indexArr.length*countOfUniqueWinningVote);
                    uint256 evenShare = sharedOfPrize/minVoteValueIndexList.length;
                    (bool paid,) = payable(participantWhoWon.winner).call{value:evenShare}("");
                    if (paid) {
                        participantWhoWon.winedPriceAmount = evenShare;
                    }
                }
                for (uint pq=0;pq<maxVoteValueIndexList.length;pq++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[maxVoteValueIndexList[pq]].workCreator;
                    winnerAmount++;
                    uint256 sharedOfPrize = totalPrize*(indexArr.length+1)/(indexArr.length*countOfUniqueWinningVote);
                    uint256 evenShare = sharedOfPrize/maxVoteValueIndexList.length;
                    (bool paid,) = payable(participantWhoWon.winner).call{value:evenShare}("");
                    if (paid) {
                        participantWhoWon.winedPriceAmount = evenShare;
                    }
                }
                for (uint cd=0;cd<medVoteValueIndexList.length;cd++) {
                    Winner storage participantWhoWon = winners[winnerAmount];
                    participantWhoWon.winner = allParticipants[medVoteValueIndexList[cd]].workCreator;
                    winnerAmount++;
                    uint256 sharedOfPrize = totalPrize*(indexArr.length)/(indexArr.length*countOfUniqueWinningVote);
                    uint256 evenShare = sharedOfPrize/medVoteValueIndexList.length;
                    (bool paid,) = payable(participantWhoWon.winner).call{value:evenShare}("");
                    if (paid) {
                        participantWhoWon.winedPriceAmount = evenShare;
                    }
                }
            }
        } else {
            Winner storage participantWhoWon = winners[winnerAmount];
            participantWhoWon.winner = allParticipants[indexArr[0]].workCreator;
            winnerAmount++;
            (bool paid,) = payable(participantWhoWon.winner).call{value:totalPrize}("");
            if (paid) {
                participantWhoWon.winedPriceAmount = totalPrize;
            }
        }
        return winnerAmount-indexArr.length;
    }
    
    // begin test non-get

    function sendMOne(address ad) public payable {
        uint256 price = msg.value;
        (bool paid,) = payable(ad).call{value:price/2}("");
        if (paid) {
            
        }
    }

    // end test non-get

    // begin get funcs

    function getAllContests() public view returns (Contest[] memory) {
        Contest[] memory allContests = new Contest[](contestAmount);
        for (uint k=0;k<contestAmount;k++){
            Contest storage individualContest = contests[k];
            allContests[k]=individualContest;
        }
        return allContests;
    }

    function getOneContestCreatorAddress(uint256 _contestId) public view returns (address) { // for testing purpose
        Contest storage contest = contests[_contestId];
        require(tx.origin==msg.sender,"only the contest creator address can call this func");
        return contest.contestCreator;
    }

    function getOneContestCreatorAddressNoRule(uint256 _contestId) public view returns (address,address,address,bool) { // for testing purpose
        Contest storage contest = contests[_contestId];
        return (contest.contestCreator,msg.sender,tx.origin,tx.origin==contest.contestCreator); // test
    }

    function getAllParticipantsDetailForAContest(uint256 _contestId) public view returns (Participant[] memory) {
        return contests[_contestId].participants;
    }

    function getAllWinnersDetailForAContest(uint256 _contestId) view public returns (Winner[] memory) {
        return contests[_contestId].winner;
    }

    function getAllVoteCountForAParticipant(uint256 _participantsId) view public returns (uint256 voteCount) {
        return (participants[_participantsId].collectedVote.length);
    }

    // end get funcs
}