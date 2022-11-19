/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract KametiContract {
    // ** Kameti (ROSCAs): A rotating savings and credit association is a group of individuals who
    // ** agree to meet for a defined period in order to save and borrow together, a form of
    // ** combined peer-to-peer banking and peer-to-peer lending.

    // * New Kameti Created
    event kametiCreated(
        bytes32 kametiId,
        string kametiDataCID,
        address organizer,
        uint256 monthlyPayment,
        uint256 months,
        address payable[] kametiMembers,
        address payable[] winners,
        uint256 timestamp
    );

    // * New Kameti Payment
    event newKametiPayment(bytes32 kametiId, address payer, uint256 payment);

    // * Monthly Check of Kameti & Choosing Winner for the Saving Pool
    event monthlyCheckPerformed(
        bytes32 kametiId,
        uint256 month,
        address winner
    );

    // * Kameti Ended (with Conflict or Success)
    event kametiEnded(
        bytes32 kametiId,
        uint256 remainingPool, // * sent to the organizer
        bool kametiEndedSuccess,
        bool kametiEndedConflict
    );

    // ** Data Structure
    // ? Kameti Member
    struct kametiMember {
        bytes32 kametiId;
        address payable memberAddress;
        uint256 monthsPaid;
        bool kametiReceived;
    }
    // ? Main data of a Kameti to be used for futher calculations
    struct Kameti {
        bytes32 kametiId; // * Unique id of every kameti
        string kametiDataCID; // * Data Related to Kameti
        uint256 lastCheckTime; // * For tracking Monthly Checks
        address payable kametiOrganizer; // * Gets a little cut for doing due dilligence on group
        address payable[] memberAddresses;
        uint256 monthlyPayment;
        uint256 months;
        uint256 currentMonth;
        uint256 poolSize;
        address payable[] winners; // * Winners will be rewarded from 0 index to onwards
        uint256 totalMembers;
        bool kametiEndedSuccess;
        bool kametiEndedConflict;
    }

    // * keep track of multiple kameti's with their id
    mapping(bytes32 => Kameti) public idToKameti;

    mapping(address => kametiMember) public addressToMember;

    // ** Create Kameti
    // ? Anyone can create a new kameti with the right parameters like a game lobby
    // ? Organizer has no control over the kameti
    function createKameti(
        address payable[] memory _kametiMembers,
        string memory _kametiDataCID,
        uint256 _monthlyPayment
    ) public {
        // * Calculate unique Kameti Id
        bytes32 kametiId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                _monthlyPayment,
                block.number
            )
        );
    
        
        for (uint i = 0; i < _kametiMembers.length; i++) {
            // * Get member's address
            address memberAddress = _kametiMembers[i];

            // * Create a temporary kametiMember(struct)
            kametiMember memory tempKametiMember = kametiMember(
                kametiId,
                payable(memberAddress),
                0,
                false
            );

            // * Push to addressToMember Mapping
            addressToMember[memberAddress] = tempKametiMember;

        }

        uint256 totalMembers = _kametiMembers.length;

        // ! Do the Random kura andazi, and define everyone's Kameti Month at the start

        // ? Doing manually for testing
        address payable[] memory orderOfWinners;
        for (uint i = 0; i < _kametiMembers.length; i++) {
            address payable memberAddress = _kametiMembers[i];

            orderOfWinners[i] = memberAddress;
        }

        // * Create Kameti
        idToKameti[kametiId] = Kameti(
            kametiId,
            _kametiDataCID,
            block.timestamp,
            payable(msg.sender),
            _kametiMembers,
            0.001 ether,
            totalMembers,
            1,
            _monthlyPayment * totalMembers,
            orderOfWinners,
            totalMembers,
            false,
            false
        );

        emit kametiCreated(
            kametiId,
            _kametiDataCID,
            msg.sender,
            _monthlyPayment,
            totalMembers,
            _kametiMembers,
            orderOfWinners,
            block.timestamp
        );
    }

    // ** Generate Random Number
    // ? Chainlink VRF for selecting the next person to access the pool

    // * Make Kameti Payment
    // ? Make a payment to the kameti you are a part of
    function payKameti(bytes32 kametiId) public payable {
        // * Get Kameti
        Kameti storage kameti = idToKameti[kametiId];

        // * Check kameti Prize
        require(msg.value >= kameti.monthlyPayment, "Wrong Payment");

        // * Check Kameti Status
        require(kameti.kametiEndedSuccess == false, "Kameti Ended Success");
        require(kameti.kametiEndedConflict == false, "Kameti Ended Conflict");

        // * Check if Sender is a kameti Member
        // * Check if Current Month Payment Done

        // * Get Current Kameti Member Data from mapping 
        kametiMember memory currentKametiMember = addressToMember[msg.sender];
        
        // * Check if current Member already paid kameti
        // * Check if he is a member of current kameti

        if (kameti.kametiId == currentKametiMember.kametiId && currentKametiMember.memberAddress == msg.sender) {
                require(
                    kameti.currentMonth > currentKametiMember.monthsPaid,
                    "Already Paid"
                );
                // ! Take Organizer's cut
                currentKametiMember.monthsPaid += 1;

                // * Emit New Kameti Payment
                emit newKametiPayment(kametiId, msg.sender, msg.value);
            }
        else {
             revert("Not a Kameti Member");
        }
    }

    // * Check Kameti & Pay the Winner(if no conflict)
    // ? Call with Chainlink Keepers every 10th of a month
    function checkKameti(bytes32 kametiId) public payable {
        // * Get Kameti
        Kameti storage kameti = idToKameti[kametiId];

        // * Time when last Checked
        uint256 lastCheck = kameti.lastCheckTime;

        // * Check if 2 minutes have passed since last check
        require(block.timestamp >= lastCheck + 2 minutes, "Too Early");

        // * Get Current Month for easy Check
        uint256 currentMonth = kameti.currentMonth;
        uint256 lastMonth = kameti.totalMembers;

        // * Last Check Time

        // * Check Kameti Status
        require(kameti.kametiEndedSuccess == false, "Kameti Ended Success");
        require(kameti.kametiEndedConflict == false, "Kameti Ended Conflict");

        // * End the kameti with success
        // ? Everyone received their kameti,
        bool isLastMonth = false;
        if (currentMonth == lastMonth) {
            isLastMonth = true;
        }

        // * Get the Current Winner's address
        address payable currentWinner = kameti.winners[currentMonth - 1]; // * for getting the array index of the winner

        bool noConflict = false;
        // * Check if Everyone have paid their Kameti
        // ? Check Conflict
        for (uint8 i = 0; i < kameti.totalMembers; i++) {
            
            // * Get address of current Member
            address currentMemberAddress = kameti.memberAddresses[i];
            // * Get current Kameti Member
            kametiMember memory currentKametiMember = addressToMember[currentMemberAddress];

            // * Check if someone haven't paid
            // ? Raise Conflict if someone is default
            if (currentKametiMember.monthsPaid != currentMonth) {
                // * Kameti Ended with Conflict
                conflictKameti(kametiId);
                noConflict = false;
                break;
            } else {
                noConflict = true;
            }
        }
        // * If no Conflict, Find & Pay the winner
        if (noConflict) {
            for (uint8 i = 0; i < kameti.totalMembers; i++) {
                // * Get address of current Member
                address currentMemberAddress = kameti.memberAddresses[i];
                // * Get current Kameti Member
                kametiMember memory currentKametiMember = addressToMember[currentMemberAddress];

                // * Haven't already received the kameti
                // * is the winner
                if (
                    currentKametiMember.kametiReceived != true &&
                    currentWinner == currentKametiMember.memberAddress
                ) {
                    // * Update winner's account details
                    // ? kameti Received
                    currentKametiMember.kametiReceived = true;

                    // * Send Kameti to the winner
                    currentWinner.transfer(address(this).balance);

                    // * Update LastCheckTime
                    kameti.lastCheckTime = block.timestamp;

                    // * Emit monthly Kameti Paid
                    emit monthlyCheckPerformed(
                        kametiId,
                        currentMonth,
                        currentWinner
                    );

                    break;
                }
            }
        }

        // * Check if last month, mark Kameti Ended Success
        // ? Send the remaining(if any) balance to the organizer
        if (isLastMonth && noConflict) {
            kameti.kametiEndedSuccess = true;

            uint256 contractBalance = address(this).balance;

            // * Transfer any remaining funds to the organizer
            kameti.kametiOrganizer.transfer(contractBalance);

            // * Emit Kameti Ended Success
            emit kametiEnded(kametiId, contractBalance, true, false);
        }
    }

    // * Conflict Kameti
    // ? If someone's go default in a kameti
    function conflictKameti(bytes32 kametiId) internal {
        // * Get Kameti
        Kameti storage kameti = idToKameti[kametiId];

        // * End the Kameti With Conflict
        kameti.kametiEndedConflict = true;

        uint256 contractBalance = address(this).balance;

        // * Transfer any remaining funds to the organizer
        kameti.kametiOrganizer.transfer(contractBalance);

        // * Emit kameti Ended
        emit kametiEnded(kametiId, contractBalance, false, true);
    }

    // ** ChainLink keepers for Automation
    // ** Check after every month who has paid or not paid
}