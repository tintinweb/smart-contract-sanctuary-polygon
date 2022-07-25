/**
 *Submitted for verification at polygonscan.com on 2022-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Guard {
    uint256 revealSpan = 600;
    uint256 stakeSpan = 7200;
    uint256 fee = 1 ether;
    uint256 contractBalance;

    enum Stage {
        Initial,
        Staked,
        Unstaked,
        KeyCommit,
        KeyReveal,
        Distribute
    }

    struct Operation {
        Stage stage;
        address Attacker;
        address User;
        uint256 stakeAmount;
        uint256 stakeTimeStamp;
        string cid;
        string PrivateKey; //cid of privatekey file
        bytes32 Commitment;
        uint256 CommitmentTimestamp;
    }

    event Commited(address attacker);
    event Revealed(
        address attacker,
        string privateKey,
        string cid,
        uint256 counter
    );
    event Staked(
        address user,
        uint256 amount,
        uint256 operationCount,
        string cid
    );
    event Distributed(address attacker, address user, uint256 amount);
    event KeyVerified(uint256 counter, string keyCID);
    mapping(uint256 => Operation) operations;
    uint256 public counter = 0;

    address public checker;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Operation not allowed");
        _;
    }

    modifier onlyChecker() {
        require(msg.sender == checker, "Operation not allowed");
        _;
    }

    constructor() {
        checker = msg.sender;
        owner = msg.sender;
    }

    function Stake(string calldata cid) external payable {
        require(msg.value > fee);
        operations[counter].User = msg.sender;
        operations[counter].stakeAmount = msg.value;
        operations[counter].stakeTimeStamp = block.timestamp;
        operations[counter].stage = Stage.Staked;

        counter++;
        emit Staked(msg.sender, msg.value, counter - 1, cid);
    }

    function unStake(uint256 _counter) external {
        require(operations[_counter].User == msg.sender);
        require(
            operations[_counter].stakeTimeStamp + stakeSpan < block.timestamp
        );
        require(operations[_counter].stage == Stage.Staked);
        operations[_counter].stage == Stage.Unstaked;
        (bool sent, bytes memory data) = msg.sender.call{
            value: operations[_counter].stakeAmount
        }("");
        require(sent, "Failed to send Ether");
    }

    function Commit(uint256 _counter, bytes32 _Commitment) external {
        require(
            operations[_counter].User != address(0),
            "This operation doesn't exist"
        );
        require(
            operations[_counter].stage == Stage.Staked ||
                (operations[_counter].stage == Stage.KeyCommit &&
                    operations[_counter].CommitmentTimestamp + revealSpan <
                    block.timestamp),
            "Not allowed to commit"
        );

        operations[_counter].Attacker = msg.sender;
        operations[_counter].Commitment = _Commitment;
        operations[_counter].stage = Stage.KeyCommit;
        operations[_counter].CommitmentTimestamp = block.timestamp;

        emit Commited(msg.sender);
    }

    function Reveal(
        uint256 _counter,
        string calldata keyCID,
        string calldata blindingFactor
    ) external {
        require(
            operations[_counter].User != address(0),
            "This operation doesn't exist"
        );
        require(
            operations[_counter].Attacker == msg.sender,
            "You are not allowed to reveal, you didn't commit"
        );
        require(
            operations[_counter].stage == Stage.KeyCommit &&
                operations[_counter].CommitmentTimestamp + revealSpan >
                block.timestamp,
            "Reveal period passed"
        );
        require(
            keccak256(abi.encodePacked(msg.sender, keyCID, blindingFactor)) ==
                operations[_counter].Commitment,
            "invalid hash"
        );

        operations[_counter].stage = Stage.KeyReveal;
        operations[_counter].PrivateKey = keyCID;

        emit Revealed(
            operations[_counter].Attacker,
            keyCID,
            operations[_counter].cid,
            _counter
        );
    }

    function check(uint256 _counter, bool integrity) external onlyChecker {
        require(
            operations[_counter].stage == Stage.KeyReveal,
            "Stage is not KeyReveal"
        );

        if (integrity) {
            operations[_counter].stage = Stage.Distribute;
            (bool sent, bytes memory data) = operations[_counter].Attacker.call{
                value: operations[_counter].stakeAmount - fee
            }("");
            require(sent, "kkk");
            contractBalance += fee;
            emit Distributed(
                operations[_counter].Attacker,
                operations[_counter].User,
                operations[_counter].stakeAmount
            );
            emit KeyVerified(_counter, operations[_counter].PrivateKey);
        } else {
            operations[_counter].stage = Stage.Staked;
            operations[_counter].Attacker = address(0);
        }
    }

    function withdraw() external onlyOwner {
        (bool sent, bytes memory data) = msg.sender.call{
            value: contractBalance
        }("");
        require(sent);
    }
}