/**
 *Submitted for verification at polygonscan.com on 2022-03-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SoulVoting
 * @dev Implements voting process along with vote delegation
 */
contract SoulVoting {

    struct SoulLinker {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted memory
    }

    struct CoreMemory {
        string name;   // short id to reference core memory sentence
        uint voteCount; // number of accumulated votes
    }

    struct TrainingPipeline {
        uint round;  // current training round starting from 0
        uint timestamp;  // timestamp of training
        string data;  // proof hash of all training data in this round
    }

    address public soulKeeper;

    mapping(address => SoulLinker) public soulLinkers;

    CoreMemory[] public coreMemories;
    TrainingPipeline[] public pipelines;

    constructor() {
        soulKeeper = msg.sender;
    }

    function getCoreMemoriesCount() public view returns(uint count) {
      return coreMemories.length;
    }

    function getPipelineCount() public view returns(uint count) {
      return pipelines.length;
    }

    function addTrainingPipeline(uint round, uint timestamp, string memory data) public {
        pipelines.push(TrainingPipeline(round, timestamp, data));
    }

    function addMemory(string memory coreMemory) public {
      coreMemories.push(CoreMemory({
        name: coreMemory,
        voteCount: 0
      }));
    }

    /**
     * @dev Give 'soulLinker' the right to vote on this ballot. May only be called by 'soulKeeper'.
     *  soulLinker is a holder of SoulFiction NFT(https://opensea.io/collection/soulfiction)
     *  multiple NFT holders may have a higher voting power.
     * @param soulLinker address of soulLinker
     * @param weight voting power (number of NFTs)
     */
    function giveRightToVote(address soulLinker, uint weight) public {
        require(
            msg.sender == soulKeeper,
            "Only soulKeeper can give right to vote."
        );
        require(
            !soulLinkers[soulLinker].voted,
            "The soulLinker already voted."
        );
        require(soulLinkers[soulLinker].weight == 0);
        soulLinkers[soulLinker].weight = weight;
    }

    /**
     * @dev Delegate your vote to the soulLinker 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        SoulLinker storage sender = soulLinkers[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (soulLinkers[to].delegate != address(0)) {
            to = soulLinkers[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        SoulLinker storage delegate_ = soulLinkers[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            coreMemories[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to 'soulLinkers[index].name'.
     * @param index index of memory in the coreMemories array
     */
    function vote(uint index) public {
        SoulLinker storage sender = soulLinkers[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = index;

        // If 'memory' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        coreMemories[index].voteCount += sender.weight;
    }
}