// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";
import "./RefundableContract.sol";

contract PolyDogeBetting is RefundableContract {
    IERC20 public token;

    constructor(address underlying_token) {
        token = IERC20(underlying_token);
    }

    enum BetState {
        NOT_CREATED,
        CREATED,
        STARTED,
        RESOLVED_INITIATOR_WINS,
        RESOLVED_PARTICIPANT_WINS,
        CANCELED,
        REFUNDED,
        BURNED
    }

    enum BetVote {
        NONE,
        CANCEL,
        ADMIT_DEFEAT,
        BURN
    }

    struct Bet {
        BetState state;
        string name;
        uint bet_amount;

        address initiator;
        address participant;

        bool initiator_paid;
        bool participant_paid;

        BetVote initiator_vote;
        BetVote participant_vote;
    }

    event BetCreated(uint indexed bet_id, address indexed initiator, address indexed target, uint bet_amount);
    event BetUpdated(uint indexed bet_id);

    uint bet_index;
    mapping(uint => Bet) bets;

    modifier IsBetInitiator(uint bet_id) {
        require(msg.sender == bets[bet_id].initiator, "Must be bet initiator.");
        _;
    }

    modifier IsBetTarget(uint bet_id) {
        require(msg.sender == bets[bet_id].participant, "Must be bet target.");
        _;
    }

    modifier IsBetParticipant(uint bet_id) {
        require(msg.sender == bets[bet_id].initiator || msg.sender == bets[bet_id].participant, "Must be part of the bet.");
        _;
    }

    function make_bet(string calldata bet_text, uint bet_amount, address target) external gasRefunded {
        require(bet_amount > 0, "Bet must be at least 1 token");
        require(msg.sender != target, "Can't make a bet with yourself");

        require(token.transferFrom(msg.sender, address(this), bet_amount));

        uint bet_id = bet_index++;
        bets[bet_id] = Bet({
            state : BetState.CREATED,
            name : bet_text,
            bet_amount : bet_amount,
            initiator : msg.sender,
            participant : target,
            initiator_paid : true,
            participant_paid : false,
            initiator_vote : BetVote.NONE,
            participant_vote : BetVote.NONE
        });

        emit BetCreated(bet_id, msg.sender, target, bet_amount);
    }

    function accept_bet(uint bet_id) external IsBetTarget(bet_id) gasRefunded {
        Bet storage bet = bets[bet_id];

        require(bet.state == BetState.CREATED);

        require(token.transferFrom(msg.sender, address(this), bet.bet_amount));
        bet.participant_paid = true;

        assert(bet.participant_paid && bet.initiator_paid);

        bet.state = BetState.STARTED;

        emit BetUpdated(bet_id);
    }

    function refund(uint bet_id) internal {
        Bet storage bet = bets[bet_id];

        require(bet.state != BetState.REFUNDED, "Bet has already been refunded");

        if (bet.initiator_paid) {
            require(token.transfer(bet.initiator, bet.bet_amount), "Initiator refund failed");
        }

        if (bet.participant_paid) {
            require(token.transfer(bet.participant, bet.bet_amount), "Participant refund failed");
        }

        bet.state = BetState.REFUNDED;

        emit BetUpdated(bet_id);
    }

    function reject_bet(uint bet_id) external IsBetParticipant(bet_id) gasRefunded {
        require(bets[bet_id].state == BetState.CREATED);

        refund(bet_id);
    }

    function checkVoteConsensus(uint bet_id, Bet storage bet) internal {
        if (bet.participant_vote == bet.initiator_vote) {
            BetVote consensus = bet.participant_vote;

            if (consensus == BetVote.CANCEL) {
                refund(bet_id);
            } else if (consensus == BetVote.BURN) {
                bet.state = BetState.BURNED;
                emit BetUpdated(bet_id);
            }
        }
    }

    function vote(uint bet_id, BetVote vote_choice) external IsBetParticipant(bet_id) gasRefunded {
        Bet storage bet = bets[bet_id];

        require(bet.state == BetState.CREATED || bet.state == BetState.STARTED);
        require(vote_choice >= BetVote.NONE && vote_choice <= BetVote.BURN);

        // win multiplier can be 1 if a party admits defeat before accepting the bet
        uint win_multiplier = (bet.participant_paid && bet.initiator_paid) ? 2 : 1;
        require(win_multiplier == 2 || bet.state == BetState.CREATED);

        if (msg.sender == bet.initiator) {
            require(bet.initiator_paid);

            bet.initiator_vote = vote_choice;

            if (vote_choice == BetVote.ADMIT_DEFEAT) {
                require(token.transfer(bet.participant, bet.bet_amount * win_multiplier));
                bet.state = BetState.RESOLVED_PARTICIPANT_WINS;
                emit BetUpdated(bet_id);
            } else {
                checkVoteConsensus(bet_id, bet);
            }
        } else {
            require(bet.participant_paid);

            bet.participant_vote = vote_choice;

            if (vote_choice == BetVote.ADMIT_DEFEAT) {
                require(token.transfer(bet.initiator, bet.bet_amount * win_multiplier));
                bet.state = BetState.RESOLVED_INITIATOR_WINS;
                emit BetUpdated(bet_id);
            } else {
                checkVoteConsensus(bet_id, bet);
            }
        }
    }

    function get_bet_details(uint bet_id) external view returns (Bet memory) {
        return bets[bet_id];
    }
}