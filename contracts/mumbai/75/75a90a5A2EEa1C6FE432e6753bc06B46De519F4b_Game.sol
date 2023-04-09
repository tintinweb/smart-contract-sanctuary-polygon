// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./VRFv2Consumer.sol";

contract Game is VRFv2Consumer{
    mapping(address => uint) private _balances;

    // playerAddress => bool
    mapping(address => bool) private _isGameRunning;

    // requestId => playerAddress
    mapping(uint => address) private _plays;


    event Deposit(address indexed from, uint value);
    event Withdraw(address indexed to, uint value);
    event GameFulfilled(address indexed player, bool isWin);
    event GameStarted(uint requestId, address player);
    constructor() payable {
        _balances[msg.sender] = 100;
    }

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function startGame() public {
        require(_balances[msg.sender] > 0, "Unsufficient balance");
        require(!_isGameRunning[msg.sender], "Already playing");
        uint requestId = requestRandomWords();
        _plays[requestId] = msg.sender;
        _isGameRunning[msg.sender] = true;
        emit GameStarted(requestId, msg.sender);
    }


    function withdraw(uint amount) public {
        require(amount <= _balances[msg.sender], "Insufficient balance");
        _balances[msg.sender] -= amount;
        (bool s, ) = payable(msg.sender).call{value: amount}("");
        require(s, "Transfer failed");
        emit Withdraw(msg.sender, amount);
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(s_requests[requestId].exists, "request not found");
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWords = randomWords;

        // fulfillGame(requestId, randomWords[0]);

        emit RequestFulfilled(requestId, randomWords);
    }

    function fulfillGame(uint requestId) public onlyOwner {
        uint randomWord = s_requests[requestId].randomWords[0];
        address player = _plays[requestId];
        require(_isGameRunning[player], "Not playing");
        if(randomWord % 10 > 4) {
            _balances[player] *= 2;
            emit GameFulfilled(player, true);
        } else {
            _balances[player] = 0;
            emit GameFulfilled(player, false);
        }
        _isGameRunning[player] = false;
    }
    


}