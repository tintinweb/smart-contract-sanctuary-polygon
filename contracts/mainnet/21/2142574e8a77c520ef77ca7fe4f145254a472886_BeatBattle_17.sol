/**
 *Submitted for verification at polygonscan.com on 2022-11-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract BeatBattle_17 {

//Declare Variables:
    mapping(address=> uint256) VoteTicket1;
    mapping(address=> uint256) VoteTicket2;

    uint256 private RegistrationCounter = 0;
    uint256 private TotalVotes = 0;
    uint256 private MaxVotes = 6;

    struct Contestant {
        bool regestration;
        address _address;
        uint256 number;
        string date;
        string link;
        uint256 votes;
    }

    Contestant[5] public contestants;

    uint256 MaxValue;
    uint256 WinnerIndex;

//Declare Functions
    function GetRegistration() public view returns (bool value) {
        for (uint256 i=0; i<5; i++){
            if (msg.sender == contestants[i]._address){
                i=5;
                return value=true;
            }        
        }
        return value=false;
    }

    function SetRegistrationTrue(string memory ueDate, string memory ueLink) public {
        if(RegistrationCounter < 5)
        {
            for (uint256 i=0; i<5; i++){
                if(contestants[i].regestration == false){
                    contestants[i].regestration = true;
                    contestants[i]._address = msg.sender;
                    contestants[i].number = i+1;
                    contestants[i].date = ueDate;
                    contestants[i].link = ueLink;
                    RegistrationCounter++;
                    break;
                }
            }
        }
    }

    function SetRegistrationFalse() public {
        for (uint256 i = 0; i < 5; i++) {
            if (contestants[i]._address == msg.sender) {
                delete contestants[i];
                RegistrationCounter--;
                break;
            }
        }
    }

    function GetCounter() public view returns (uint256) {
        return RegistrationCounter;
    }

    function GetContestants() public view returns (
        address address1, address address2, address address3, address address4, address address5,
        uint256 votes1, uint256 votes2, uint256 votes3, uint256 votes4, uint256 votes5
        ) {
               
        address1=contestants[0]._address;
        address2=contestants[1]._address;
        address3=contestants[2]._address;
        address4=contestants[3]._address;
        address5=contestants[4]._address;

        votes1=contestants[0].votes;
        votes2=contestants[1].votes;
        votes3=contestants[2].votes;
        votes4=contestants[3].votes;
        votes5=contestants[4].votes;

        return (address1, address2, address3, address4, address5, votes1, votes2, votes3, votes4, votes5);
    }

    function GetDates() public view returns (string memory date1, string memory date2, string memory date3, string memory date4, string memory date5) {

        date1=contestants[0].date;
        date2=contestants[1].date;
        date3=contestants[2].date;
        date4=contestants[3].date;
        date5=contestants[4].date;

        return (date1, date2, date3, date4, date5);
    }

    function GetLinks() public view returns (string memory link1, string memory link2, string memory link3, string memory link4, string memory link5) {

        link1=contestants[0].link;
        link2=contestants[1].link;
        link3=contestants[2].link;
        link4=contestants[3].link;
        link5=contestants[4].link;

        return (link1, link2, link3, link4, link5);
    }

    function Vote (address faddress) public returns (uint votestatus){     
    votestatus = 0;    //0 reset voting status
        if(TotalVotes<200){
            if (VoteTicket1[msg.sender] == 0){          
                for (uint256 i = 0; i < 5; i++) {
                    if (contestants[i]._address == faddress) {
                        VoteTicket1[msg.sender]=contestants[i].number;
                        contestants[i].votes++;
                        votestatus = 1; // means vote1 allowed
                        TotalVotes++;
                        if (TotalVotes>=MaxVotes){GetWinners();}
                        i=5;
                        return votestatus;
                    }
                }
            }
            if (VoteTicket1[msg.sender] != 0){          
                for (uint256 i = 0; i < 5; i++) {
                    if (contestants[i]._address == faddress && VoteTicket1[msg.sender]!=contestants[i].number) {
                        VoteTicket2[msg.sender]=contestants[i].number;
                        contestants[i].votes++;
                        votestatus = 2; // means vote2 allowed
                        TotalVotes++;
                        if (TotalVotes>=MaxVotes){GetWinners();}
                        i=5;
                        return votestatus;
                    }
                }
            }
            votestatus = 3; // means vote not allowed
            return votestatus;
        }
        votestatus = 4; // means vote is maxed out
        return votestatus;    
    }

    function GetVotingTickets () public view returns (uint256 fTicket1, uint256 fTicket2){
        fTicket1=VoteTicket1[msg.sender];
        fTicket2=VoteTicket2[msg.sender];
        return (fTicket1, fTicket2);
    }


    function GetWinners() public
    {
        MaxValue=0;
        for(uint256 i=4; i>=0; i--)
        {
            if (contestants[i].votes > MaxValue)
            {
                MaxValue=contestants[i].votes;
                WinnerIndex=i;
            }
        }
    
        // send contestants[WinnerAIndex]._address (0.9*Balance)
        payable(contestants[WinnerIndex]._address).transfer((address(this).balance)*9/10);
    }

    function payout() public
    {
        if (VoteTicket1[msg.sender] == (WinnerIndex+1) || VoteTicket2[msg.sender] == (WinnerIndex+1))
        {
        // send winning each vote (0.1*Balance)/(contestants[WinnerIndex].votes) // this step is done in unreal
        payable(msg.sender).transfer((address(this).balance)*1/(10*contestants[WinnerIndex].votes));
        }
    }
}