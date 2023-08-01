/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

contract WhaleWars {

    address private owner;

    uint private minimumDeposit = 1 ether;

    uint private constant EPOCH_DURATION_IN_BLOCKS = 50;

    uint private settlementDuration = EPOCH_DURATION_IN_BLOCKS * 7;

    uint private ownerTaxBasisPoints = 800;

    struct MatchProposition {
        address proposer;
        int value;
    }

    // Queue of deposits waiting for match making.
    // The queue contains only deposits from one team, since when a deposit for another team is submitted
    // it is immediately matched with tokens waiting in the queue. If the submitted deposit is more than
    // the balance in the queue, the queue flips and then stores the remaining tokens for the other team.
    mapping(uint256 => MatchProposition) private queue;
     // Queue is implemented as a dequeue to allow for efficient dropping from the front.
	uint256 private queueFirst = 0;
	uint256 private queueEnd = 0;

    // Whether the queue is for bulls or bears
    bool private queueIsBulls;

    // A match between two players in an epoch
    struct Match {
        // Address of the player supporting bulls.
        address bull;
        // Address of the player supporting bears.
        address bear;
        // Negative values indicate that the match
        // was already withdrawn by the winner.
        int value;
    }

    // An epoch
    struct Epoch {
        // Matches in the epoch
        Match[] matches;

        // Sum of deposits (bulls - bears = delta) in the given epoch
        // Negative values mean that bears are leading, positive are for bulls.
        int depositsDelta;

        // ID of next epoch that has at least one deposit so that we don't have to
        // iterate over all epochs and possibly run out of gas.
        uint nextEpochWithDeposit;

        // Cached delta result calculation from the settlement period.
        // This is set to 0 by default, indicating that
        // the result is not yet available.
        int cacheFinalDelta;
    }

    mapping (uint => Epoch) private epochs;

    uint private lastEpochWithDeposit;
    uint private ownerBalance;

    // A struct and mapping used for state calculations in case of unlikely problems with block gas limit. 
    struct FallbackPartialCalculation {
        int partialDelta;
        uint lastIncludedEpoch;
    }
    mapping (uint => FallbackPartialCalculation) private fallbackCache;

    constructor() {
		owner = tx.origin;
	}
    
    // Send tokens to this function to support the bull team.
    function stakeBulls() external payable {
        require(msg.value >= minimumDeposit);
        uint epoch = block.number - block.number % EPOCH_DURATION_IN_BLOCKS;
        
        // Update deposits delta for current epoch
        epochs[epoch].depositsDelta += int(msg.value);
        epochs[lastEpochWithDeposit].nextEpochWithDeposit = epoch;
        lastEpochWithDeposit = epoch;

        // create matches, if not possible put tokens in queue
        int valueRemaining = int(msg.value);

        // while we still got tokens
        while (valueRemaining > 0) {
            // If queue is empty or is from our team we just add tokens to it
            if (queueIsBulls || queueIsEmpty()) {
                MatchProposition memory proposition = MatchProposition({proposer: msg.sender, value: valueRemaining});
                enqueue(proposition);
                queueIsBulls = true;
                break;
            }

            // Otherwise we can match our tokens with the tokens from queue
            Match memory newMatch;
            newMatch.bull = msg.sender;
            newMatch.bear = queue[queueFirst].proposer;
            
            if (queue[queueFirst].value > valueRemaining) {
                queue[queueFirst].value -= valueRemaining;
                newMatch.value = valueRemaining;
            } else {
                newMatch.value = queue[queueFirst].value;
                dequeue();
            }

            // Add match and continue until no tokens are left
            valueRemaining -= newMatch.value;
            epochs[epoch].matches.push(newMatch);
        }       
    }

    function stakeBears() external payable {
        require(msg.value >= minimumDeposit);
        uint epoch = block.number - block.number % EPOCH_DURATION_IN_BLOCKS;

        // Update deposits delta for current epoch
        epochs[epoch].depositsDelta -= int(msg.value);
        epochs[lastEpochWithDeposit].nextEpochWithDeposit = epoch;
        lastEpochWithDeposit = epoch;

        // while we still got tokens
        int valueRemaining = int(msg.value);
        while (valueRemaining > 0) {
            // If queue is empty or is from our team we just add tokens
            // to the queue
            if (!queueIsBulls || queueIsEmpty()) {
                MatchProposition memory proposition = MatchProposition({proposer: msg.sender, value: valueRemaining});
                enqueue(proposition);
                queueIsBulls = false;
                break;
            }

            // Otherwise we can match our tokens with the tokens from queue of the opposite team
            Match memory newMatch;
            newMatch.bear = msg.sender;
            newMatch.bull = queue[queueFirst].proposer;
            if (queue[queueFirst].value > valueRemaining) {
                queue[queueFirst].value -= valueRemaining;
                newMatch.value = valueRemaining;
            } else {
                newMatch.value = queue[queueFirst].value;
                dequeue();
            }

            // Add match and continue until no tokens are left
            valueRemaining -= newMatch.value;
            epochs[epoch].matches.push(newMatch);
        }
    }

    // Use this function to withdrawal winnings.
    function withdrawal(uint matchEpoch, uint[] memory matchIndices) public {
       
        uint epoch = matchEpoch - matchEpoch % EPOCH_DURATION_IN_BLOCKS; 

        // Check who won the epoch, the function will revert if epoch is still in progress
        bool bullsWon = getBullsWon(matchEpoch);

        for (uint256 i = 0; i < matchIndices.length; ++i) {
            Match storage m = epochs[epoch].matches[matchIndices[i]];
            require(m.bull == msg.sender || m.bear == msg.sender || msg.sender == owner, "Invalid index");

            // If match value is negative it means that the winnings have been already withdrawn
            require (m.value > 0, "Already withdrawn");

            uint val = uint(m.value);

            // Apply tax to the win
            uint ownerTax = (val * ownerTaxBasisPoints) / 10000;
            ownerBalance += ownerTax;

            // calculate win
            uint win = val + val - ownerTax;

            // negate value to indicate that it has been already withdrawn.
            m.value = -m.value;

            // transfer winnings to the winner
            if (bullsWon) {
                payable(m.bull).transfer(win);
            } else {
                payable(m.bear).transfer(win);
            }
        }
    }


    function withdrawalMultiCall(uint[] memory matchEpochs, uint[][] memory matchIndices) external {
        for (uint i = 0; i < matchEpochs.length; ++i) {
            withdrawal(matchEpochs[i], matchIndices[i]);
        }
    }

    // Returns true if given epoch was won by bulls
    // Returns false when it was won by bears
    // and reverts if the epoch is still in progress
    function getBullsWon(uint256 _epoch) public returns (bool) {
        uint matchEpoch = _epoch - _epoch % EPOCH_DURATION_IN_BLOCKS; 

        // If the state was already calculated use cached value
        if (epochs[matchEpoch].cacheFinalDelta != 0) {
            return epochs[matchEpoch].cacheFinalDelta > 0;
        }

        // calculate delta, will revert if epoch not completed
        int delta = calculateDelta(_epoch);

        // cache result
        epochs[matchEpoch].cacheFinalDelta = delta;

        // Return true if bulls won, false otherwise
        return delta > 0;
    }

    function calculateDelta(uint256 matchEpoch) public view returns (int) {
        uint currentEpoch = block.number - block.number % EPOCH_DURATION_IN_BLOCKS; 

        // Calculate settlement epoch, that is the epoch after which the given epoch is finished
        uint settlementEpoch = matchEpoch + settlementDuration;

        // Sum deposits until we reach the settlement epoch
        // Continue further if the deposits equal to 0 (that is a tie)
        uint epoch = matchEpoch;
        int delta = 0;
        while (true)
        {
   
            uint nextEpoch = epochs[epoch].nextEpochWithDeposit;

            if (nextEpoch == 0 || nextEpoch == epoch || nextEpoch >= currentEpoch) {
                if (delta != 0 && currentEpoch > settlementEpoch) {
                    break;
                }
                revert("Not yet settled");
            }

            epoch = nextEpoch;

            if (epoch > settlementEpoch && delta != 0) {
                break;
            }

            delta += epochs[epoch].depositsDelta;
        }

        return delta;
    }
 
    // This function is here only just in case.
    // A loop can possibly hit the block gas limit, making withdrawals impossible.
    // To avoid this we provide a function which can progress the calculation in multiple transactions
    // and avoid any gas limits.
    function fallbackProgressEpochCalculation(uint _epoch, uint blocks) external {
         uint matchEpoch = _epoch - _epoch % EPOCH_DURATION_IN_BLOCKS; 

        FallbackPartialCalculation storage c = fallbackCache[matchEpoch];
        if (c.lastIncludedEpoch == 0) {
            c.lastIncludedEpoch = matchEpoch;
        }

        require(epochs[matchEpoch].cacheFinalDelta == 0, "Already calculated");

        uint currentEpoch = block.number - block.number % EPOCH_DURATION_IN_BLOCKS; 
        uint settlementEpoch = matchEpoch + settlementDuration;

        uint epoch = fallbackCache[matchEpoch].lastIncludedEpoch;
        uint stopAfterBlock = epoch + blocks;
        require(stopAfterBlock >= epoch, "addition overflow");

        int delta = fallbackCache[matchEpoch].partialDelta;

        while (true)
        {
   
            uint nextEpoch = epochs[epoch].nextEpochWithDeposit;

            if (nextEpoch == 0 || nextEpoch == epoch || nextEpoch >= currentEpoch) {
                if (delta != 0 && currentEpoch > settlementEpoch) {
                    break;
                }
                revert("Not yet settled");
            }

            epoch = nextEpoch;

            if (epoch > settlementEpoch && delta != 0) {
                break;
            }

            delta += epochs[epoch].depositsDelta;

            if (epoch >= stopAfterBlock) {
                fallbackCache[matchEpoch].lastIncludedEpoch = epoch;
                fallbackCache[matchEpoch].partialDelta = delta;
                return;
            }
        }

        fallbackCache[matchEpoch].partialDelta = delta;
        epochs[matchEpoch].cacheFinalDelta = delta;
    }

    // Allows the owner to transfer contract ownership to another contract.
    function ownerChangeOwner(address addr) external {
        require(msg.sender == owner);
        require(addr != address(0));
        owner = addr;
    }

    // In the beginning, we may want to change the game settings
    // such as the epoch duration. However allowing this would allow the owner to
    // manipulate games in progress. To avoid this, changes are done in two steps.
    // First a change is announced and has no immidiate effect.
    // Only after 5 days it can then be applied to the contract.

    uint ownerAnnouncedNewTax = 495;
    uint ownerAnnouncedNewEpochDuration = EPOCH_DURATION_IN_BLOCKS * 8;
    uint ownerAnnouncedMinimumDeposit = 1 ether;
    uint announcementBlock = 0;
  
    // Cache new settings and save current block
    function ownerAnnounceNewSettings(uint duration, uint tax, uint minDeposit) external {
        require(msg.sender == owner);
        // Allow max epoch duration to 1000 epochs.
        require(duration <= 1000);
        require(duration >= 1);

        // Allow max theoretical 15% tax
        require(tax > 0);
        require(tax <= 1500);

        // Allow max minimum deposit of 1000 ether
        require (minimumDeposit < 10000 ether);

        ownerAnnouncedNewEpochDuration = duration;
        ownerAnnouncedNewTax = tax;
        announcementBlock = block.number;
        ownerAnnouncedMinimumDeposit = minDeposit;
    }

    // Apply new settings only if 3 days have passed since the settings were announced.
    function ownerApplySettingsAnnouncement() external {
        require(msg.sender == owner);
        require(block.number > announcementBlock + 129600);
        ownerTaxBasisPoints = ownerAnnouncedNewTax;
        settlementDuration = ownerAnnouncedNewEpochDuration;
        minimumDeposit = ownerAnnouncedMinimumDeposit;
    }

    // Allow owner tax withdrawals
    function ownerWithdrawal(uint amount) external {
        require(msg.sender == owner);
        require(ownerBalance >= amount);
        ownerBalance -= amount;
        payable(owner).transfer(amount);
    }

    function ownerGetBalance() external view returns (uint256) {
        return ownerBalance;
    }

    function enqueue(MatchProposition memory matchProposition) private {
		queue[queueEnd] = matchProposition;
		queueEnd += 1;
	}

	function dequeue() private {
		require(!queueIsEmpty(), "Queue is Empty");
		delete queue[queueFirst];
		queueFirst += 1;
	}

    function queueIsEmpty() private view returns (bool) {
        return queueFirst >= queueEnd;
	}

    function getMatches(uint epoch, uint offset, uint limit) external view returns(Match[] memory) {
        uint lim = limit;
        if (lim == 0) {
            lim = epochs[epoch].matches.length;
        }

        Match[] memory b = new Match[](lim);
        uint j = 0;
        for (uint i = offset; i < lim; ++i) {
            b[j] = epochs[epoch].matches[i];
            j++;
        }
        
        return b;
    }

    function getMatchesCount(uint epoch) external view returns(uint256) {
        return epochs[epoch].matches.length;
    }

    function getDepositsBeforeInclusive(uint epoch, uint limit) external view returns(int[] memory) {
        int[] memory d = new int[](limit);
        for (uint i = 0; i < limit; ++i) {
            d[i] = epochs[epoch].depositsDelta;
            epoch -= EPOCH_DURATION_IN_BLOCKS;
            if (epoch == 0) {
                break;
            }
        }

        return d;
    }

    function getQueue() external view returns(MatchProposition[] memory, bool) {
        MatchProposition[] memory b = new MatchProposition[](queueEnd - queueFirst);
        uint j = 0;
        for (uint i = queueFirst; i < queueEnd; ++i) {
            b[j] = queue[i];
            j++;
        }
        
        return (b, queueIsBulls);
    }

    function getMatchesAndDeposits(uint epoch, uint limit) external view returns(Match[][] memory, int[] memory) {
        Match[][] memory _matchesByEpoch = new Match[][](limit);
        int[] memory deposits = new int[](limit);

        for (uint i = 0; i < limit; ++i) {
            Match[] memory matches = new Match[](epochs[epoch].matches.length);
            uint j = 0;
            for (uint x = 0; x < epochs[epoch].matches.length; ++x) {
                matches[j] = epochs[epoch].matches[x];
                j++;
            }
            _matchesByEpoch[i] = matches;
            deposits[i] = epochs[epoch].depositsDelta;

            epoch -= EPOCH_DURATION_IN_BLOCKS;
            if (epoch == 0) {
                break;
            }
        }

        return (_matchesByEpoch, deposits);
    }

    function getNextDepositEpoch(uint epoch) external view returns(uint) {
        return epochs[epoch].nextEpochWithDeposit;
    }
}