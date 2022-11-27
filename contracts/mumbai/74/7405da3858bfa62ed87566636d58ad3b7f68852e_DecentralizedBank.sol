/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// SPDX-License-Identifier: Unlisenced

/*                                                                                       
                                              __     _____      __  ____                   
    /\                                        \ \    \__  )    / _)|  _ \                  
   /  \   _____   _____ _  _____  ___   __  __ \ \  _  / / ___ \ \ | |_) ) __  ___  ___  __
  / /\ \ / __) \ / / __) |/ (   )/ _ \ /  \/ /  > \| |/ / / __) _ \|  _ ( /  \/ / |/ / |/ /
 / /__\ \> _) \ v /> _)| / / | || |_) | ()  <  / ^ \ | |__> _| (_) ) |_) | ()  <| / /|   < 
/________\___) > < \___)__/   \_)  __/ \__/\_\/_/ \_\_)__ \___)___/|____/ \__/\_\__/ |_|\_\
              / ^ \             | |                      ) )                               
             /_/ \_\            |_|                     (_/                                

                                Contract Coded By: Zain Ul Abideen AKA The Dragon Emperor
*/

pragma solidity 0.8.17;

contract DecentralizedBank {
    string public LatestNotification;
    address public OwnerOfTheContract;
    mapping(address => mapping(uint => uint)) private HolyRecords;
    
    constructor() {
        OwnerOfTheContract = msg.sender;
    }

    function DepositNativeCoin(address WithdrawlAddress, uint SortingID) public payable {
        HolyRecords[WithdrawlAddress][SortingID] += msg.value;
    }

    function PayAnonymously(address payable PayeeAddress, uint PayAmount, uint SortingID) public {
        require(HolyRecords[msg.sender][SortingID] >= PayAmount, "you cannot withdraw what you donot possess.");
        HolyRecords[msg.sender][SortingID] -= PayAmount;
        PayeeAddress.transfer(PayAmount);
    }

    function HolyBalance(address CheckingAddress, uint SortingID) public view returns (uint){
        require(CheckingAddress == msg.sender, "you can check someone else's balance??");
        return HolyRecords[CheckingAddress][SortingID];
    }

    function ChangeOwnershipOfCOntract(address NewOwner) public {
        require(OwnerOfTheContract == msg.sender, "access denied.");
        OwnerOfTheContract = NewOwner;
    }

    function UpdateSlogan(string memory NewNotification) public {
        require(OwnerOfTheContract == msg.sender, "access denied.");
        LatestNotification = NewNotification;
    }

}