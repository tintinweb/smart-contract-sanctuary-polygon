//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MarketSentiment {
    address public owner;
    string[] public coinList;

    constructor() {
        owner = msg.sender;
    }

    struct coinVoting {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event votingUpdated (
        uint256 up,
        uint256 down,
        address voter,
        string coin
    );

    mapping(string => coinVoting) private CoinVotings;

    function addCoin(string memory _coin) public {
        require(msg.sender == owner, "Only owner can create tickers");

        coinVoting storage newCoin = CoinVotings[_coin];
        newCoin.exists = true;

        coinList.push(_coin);
    }

    function vote(string memory _coin, bool _vote) public {
        require(CoinVotings[_coin].exists, "Can't vote on this coin");
        require(!CoinVotings[_coin].Voters[msg.sender], "You have already voted for this coin");

        coinVoting storage cv = CoinVotings[_coin];
        cv.Voters[msg.sender] = true;

        if (_vote) {
            cv.up++;
        } else {
            cv.down++;
        }

        emit votingUpdated(cv.up, cv.down, msg.sender, _coin);
    }

    function getVotes(string memory _coin) public view returns (
        uint256 up,
        uint256 down
    ) {
        require(CoinVotings[_coin].exists, "No such coin listed");

        coinVoting storage cv = CoinVotings[_coin];

        return (cv.up, cv.down);
    }
}