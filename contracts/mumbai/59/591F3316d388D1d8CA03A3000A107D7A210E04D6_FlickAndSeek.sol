/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "./areaspool.sol";


contract FlickAndSeek is Ownable, ReentrancyGuard
{
    using Address for address payable;

    event RoundStarted(uint256 indexed round, uint256 numberOfTasks, uint256 roundFinishTime);
    event RoundFinished(uint256 indexed round, uint256 [] winnerTasks);
    event BetMade(address indexed user, uint256 indexed round, uint256 indexed task, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed round, uint256 amount);

    struct User
    {
        uint256                      total;
        mapping (uint256 => uint256) tasks;
        bool                         withdrawn;
    }

    struct Round
    {
        uint256                      total;
        mapping (address => User)    users;
        mapping (uint256 => uint256) tasks;
        uint256                      numberOfTasks;
        uint256 []                   winnerTasks;
        uint256                      startTime;
        uint256                      finishTime;
    }

    mapping (uint256 => Round) public _rounds;

    uint256   public _roundsCounter;
    uint256   public _currentRound;
    AreasPool public _pool;

    constructor(address payable thewall, address thewallcore)
    {
        _pool = new AreasPool(thewall, thewallcore);
    }

    function bet(uint256 task) payable public
    {
        require(msg.value > 1 ether / 10, "FlickAndSeek: Bet to0 small");
        require(_currentRound != 0, "FlickAndSeek: Round is not started");
        Round storage round = _rounds[_currentRound];
        require(block.timestamp < round.finishTime, "FlickAndSeek: Round is over");
        require(task < round.numberOfTasks, "FlickAndSeek: Unknown task");
        round.total += msg.value;
        round.tasks[task] += msg.value;
        round.users[_msgSender()].total += msg.value;
        round.users[_msgSender()].tasks[task] += msg.value;
        emit BetMade(_msgSender(), _currentRound, task, msg.value);
    }

    function getReward(address user, uint256 round) public view returns(uint256)
    {
        uint256 reward = 0;
        Round storage r = _rounds[round];
        if (r.finishTime != 0 && block.timestamp >= r.finishTime && !r.users[user].withdrawn)
        {
            uint256 total = r.total;
            for(uint256 i = 0; i < r.winnerTasks.length; ++i)
            {
                uint256 currentTotal =
                    (r.winnerTasks.length-1 == i) ? total : total * 9 / 10;
                uint256 task = r.winnerTasks[i];
                reward += currentTotal * r.users[user].tasks[task] / r.tasks[task];
                total -= currentTotal;
            }
        }
        return reward;
    }

    function withdrawReward(uint256 round) public nonReentrant returns(uint256)
    {
        uint256 value = getReward(_msgSender(), round);
        if (value > 0)
        {
            Round storage r = _rounds[round];
            r.users[_msgSender()].withdrawn = true;
            payable(_msgSender()).sendValue(value);
            emit Withdrawn(_msgSender(), round, value);
        }
        return value;
    }

    function startRound(
        uint256 durationSeconds,
        uint256 numberOfTasks,
        uint256 [] memory areas,
        bytes [] memory contents) public onlyOwner returns(uint256)
    {
        require(_currentRound == 0, "FlickAndSeek: Round is in progress");
        require(durationSeconds <= 7 days, "FlickAndSeek: Too long round");
        _pool.setLock(true);
        _pool.setContentMulti(areas, contents);
        _roundsCounter += 1;
        _currentRound = _roundsCounter;
        Round storage r = _rounds[_currentRound];
        r.numberOfTasks = numberOfTasks;
        r.startTime = block.timestamp;
        r.finishTime = block.timestamp + durationSeconds;
        emit RoundStarted(_currentRound, numberOfTasks, r.finishTime);
        return _currentRound;
    }

    function finishRound(uint256 [] memory winnerTasks) public onlyOwner nonReentrant
    {
        require(_currentRound != 0, "FlickAndSeek: Nothing to finish");
        _pool.setLock(false);
        Round storage r = _rounds[_currentRound];
        require(block.timestamp >= r.finishTime, "FlickAndSeek: Round is not finished yet");
        r.winnerTasks = winnerTasks;
        uint256 value = r.total / ((winnerTasks.length == 0) ? 1 : 10);
        if (value != 0)
        {
            payable(_pool).sendValue(value);
            r.total -= value;
        }
        emit RoundFinished(_currentRound, winnerTasks);
        _currentRound = 0;
    }
}