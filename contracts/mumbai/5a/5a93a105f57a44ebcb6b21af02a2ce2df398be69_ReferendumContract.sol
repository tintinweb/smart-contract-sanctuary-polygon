/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// SPDX-License-Identifier: Unlisenced

/*

 ██▀███  ▓█████   █████▒▓█████  ██▀███  ▓█████  ███▄    █ ▓█████▄  █    ██  ███▄ ▄███▓ ▐██▌ 
▓██ ▒ ██▒▓█   ▀ ▓██   ▒ ▓█   ▀ ▓██ ▒ ██▒▓█   ▀  ██ ▀█   █ ▒██▀ ██▌ ██  ▓██▒▓██▒▀█▀ ██▒ ▐██▌ 
▓██ ░▄█ ▒▒███   ▒████ ░ ▒███   ▓██ ░▄█ ▒▒███   ▓██  ▀█ ██▒░██   █▌▓██  ▒██░▓██    ▓██░ ▐██▌ 
▒██▀▀█▄  ▒▓█  ▄ ░▓█▒  ░ ▒▓█  ▄ ▒██▀▀█▄  ▒▓█  ▄ ▓██▒  ▐▌██▒░▓█▄   ▌▓▓█  ░██░▒██    ▒██  ▓██▒ 
░██▓ ▒██▒░▒████▒░▒█░    ░▒████▒░██▓ ▒██▒░▒████▒▒██░   ▓██░░▒████▓ ▒▒█████▓ ▒██▒   ░██▒ ▒▄▄  
░ ▒▓ ░▒▓░░░ ▒░ ░ ▒ ░    ░░ ▒░ ░░ ▒▓ ░▒▓░░░ ▒░ ░░ ▒░   ▒ ▒  ▒▒▓  ▒ ░▒▓▒ ▒ ▒ ░ ▒░   ░  ░ ░▀▀▒ 
  ░▒ ░ ▒░ ░ ░  ░ ░       ░ ░  ░  ░▒ ░ ▒░ ░ ░  ░░ ░░   ░ ▒░ ░ ▒  ▒ ░░▒░ ░ ░ ░  ░      ░ ░  ░ 
  ░░   ░    ░    ░ ░       ░     ░░   ░    ░      ░   ░ ░  ░ ░  ░  ░░░ ░ ░ ░      ░       ░ 
   ░        ░  ░           ░  ░   ░        ░  ░         ░    ░       ░            ░    ░    
                                 Contract Coded by: Zain Ul Abideen AKA The Dragon Emperor. 
*/

pragma solidity 0.8.16;

contract ReferendumContract {
    address public OwnerOfTheContract;
    bool public IsReferendumActive = false;
    string public ShowFirstSlogan = "Not Set";
    uint public ShowVotesForFirstSlogan = 0;
    string public ShowSecondSlogan = "Not Set";
    uint public ShowVotesForSecondSlogan = 0;
    address[] public ShowVotersByIndex;

    // sets the deployer of the contract as owner.
    constructor() {
        OwnerOfTheContract = msg.sender;
    }

    modifier RequireRootAccess() {
        if (msg.sender == OwnerOfTheContract) {
            _;
        }
    }

    // some setters for owner only.
    function SetFirstSloganForOwnerOnly(string memory _slogan) RequireRootAccess public {
        ShowFirstSlogan = _slogan;
    }

    function SetSecondSloganForOwnerOnly(string memory _slogan) RequireRootAccess public {
        ShowSecondSlogan = _slogan;
    }

    function SetReferendumActiveForOwnerOnly() RequireRootAccess public {
        IsReferendumActive = true;
    }

    // making sure an address cannot vote more than once.
    function NotAlreadyVoted() internal view returns (bool) {
        for (uint i = 0; i < ShowVotersByIndex.length; i++) {
            if (ShowVotersByIndex[i] == msg.sender) {
                return false;
            }
        }

        return true;
    }

    // to be used by public to vote.
    function VoteForFirstSlogan() public {
        require(NotAlreadyVoted(), "Vote already placed");
        require(IsReferendumActive, "Referendum closed");
        ShowVotersByIndex.push(msg.sender);
        ShowVotesForFirstSlogan += 1;
    }

    function VoteForSecondSlogan() public {
        require(NotAlreadyVoted(), "Vote already placed");
        require(IsReferendumActive, "Referendum closed");
        ShowVotersByIndex.push(msg.sender);
        ShowVotesForSecondSlogan += 1;
    }

    function ShowTotalNumberOfVoters() public view returns (uint) {
        return ShowVotersByIndex.length;
    }

    // resets everything to default values.
    function ResetReferendumForOwnerOnly() RequireRootAccess public {
        ShowFirstSlogan = "Not Set";
        ShowSecondSlogan = "Not Set";
        ShowVotesForFirstSlogan = 0;
        ShowVotesForSecondSlogan = 0;
        ShowVotersByIndex = new address[](0);
    }

    // closes voting for referendum.
    function CloseVotesForOwnerOnly() RequireRootAccess public {
        IsReferendumActive = false;
    }
}