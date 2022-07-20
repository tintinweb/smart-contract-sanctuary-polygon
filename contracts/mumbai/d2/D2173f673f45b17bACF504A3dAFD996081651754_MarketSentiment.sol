// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error OwnerTickerError();
error TickerDoesntExist();
error AlreadyVoted();

contract MarketSentiment {
  address public owner;
  string[] public tickersArray;

  constructor() {
    owner = msg.sender;
  }

  struct Ticker {
    bool exists;
    uint256 up;
    uint256 down;
    mapping(address => bool) voters;
  }

  event TickerUpdated(uint256 up, uint256 down, address voter, string ticker);

  mapping(string => Ticker) private tickers;

  function addTicker(string memory _ticker) public {
    if (msg.sender == owner) {
      revert OwnerTickerError();
    }

    Ticker storage newTicker = tickers[_ticker];

    newTicker.exists = true;
    tickersArray.push(_ticker);
  }

  function vote(string memory _ticker, bool _vote) public {
    if (tickers[_ticker].exists == false) {
      revert TickerDoesntExist();
    }

    if (tickers[_ticker].voters[msg.sender] == true) {
      revert AlreadyVoted();
    }

    Ticker storage t = tickers[_ticker];

    t.voters[msg.sender] = true;

    if (_vote) {
      t.up++;
    } else {
      t.down++;
    }

    emit TickerUpdated(t.up, t.down, msg.sender, _ticker);
  }

  function getVotes(string memory _ticker) public view returns (uint256 up, uint256 down) {
    if (tickers[_ticker].exists == false) {
      revert TickerDoesntExist();
    }

    Ticker storage t = tickers[_ticker];

    return (t.up, t.down);
  }
}