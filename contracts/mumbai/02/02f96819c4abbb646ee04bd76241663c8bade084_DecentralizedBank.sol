/**
 *Submitted for verification at polygonscan.com on 2022-11-25
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
    address public OwnerOfTheContract;
    mapping(address => mapping(uint => uint)) HolyRecords;
    
    constructor() {
        OwnerOfTheContract = msg.sender;
    }

    function DepositNativeCoin(uint PrivateID) public payable {
        HolyRecords[msg.sender][PrivateID] += msg.value;
    }

    function PayAnonymously( address payable PayeeAddress, uint PrivateID) public payable {
        require(HolyRecords[msg.sender][PrivateID] >= msg.value, "you cannot withdraw what you donot possess.");
        HolyRecords[msg.sender][PrivateID] -= msg.value;
        PayeeAddress.transfer(msg.value);
    }

}