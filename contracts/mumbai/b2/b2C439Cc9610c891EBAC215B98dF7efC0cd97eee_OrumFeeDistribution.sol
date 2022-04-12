// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './IERC20.sol';
import './OrumMath.sol';
/*

@title Curve Fee Distribution modified for ve(3,3) emissions
@author Curve Finance, andrecronje
@license MIT

*/
interface VotingEscrow {

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function user_point_epoch(uint tokenId) external view returns (uint);
    function epoch() external view returns (uint);
    function user_point_history(uint tokenId, uint loc) external view returns (Point memory);
    function point_history(uint loc) external view returns (Point memory);
    function checkpoint() external;
    function deposit_for(uint tokenId, uint value) external;
    function token() external view returns (address);
    function tokenOfOwnerByIndex(address _addr, uint _tokenIndex) external view returns (uint);
}


contract OrumFeeDistribution{

    event CheckpointToken(
        uint time,
        uint tokens
    );

    event Claimed(
        uint tokenId,
        uint amount,
        uint claim_epoch,
        uint max_epoch
    );

    event TestingRevenue(string s, uint t,uint since_last,uint to_distribute,uint tokens_per_week,uint this_week,uint next_week);
    event OrumFeeDistributionROSEBalanceUpdated(uint _amount);
    event test_hello(uint _toDistribute, uint _balanceOf, uint _veSupply);
    event TEST_balances(uint _tokBalance, uint _toDistribute, uint _tokenLastBalance);
    event TEST_timestamps(uint _now, uint _nextWeek, uint _thisWeek);

    uint constant WEEK = 7 * 86400;

    uint public start_time;
    uint public time_cursor;
    mapping(uint => uint) public time_cursor_of;
    mapping(uint => uint) public user_epoch_of;

    uint public last_token_time;
    uint[1000000000000000] public tokens_per_week;

    address public voting_escrow;
    address public token;
    uint public token_last_balance;
    uint public TOKEN_CHECKPOINT_DEADLINE = 86400;

    uint[1000000000000000] public ve_supply;

    address public depositor;
    address public owner;
    address public borrowerOpsAddress;
    address public activePoolAddress;
    bool public can_checkpoint_toggle = true;

    constructor(address _voting_escrow) {
        uint _t = block.timestamp / WEEK * WEEK;
        start_time = _t;
        last_token_time = _t;
        time_cursor = _t;
        address _token = VotingEscrow(_voting_escrow).token();
        token = _token;
        voting_escrow = _voting_escrow;
        depositor = msg.sender;
        IERC20(_token).approve(_voting_escrow, type(uint).max);
        owner = msg.sender;
    }

    function setAddresses(address _borrowerOpsAddress, address _activePoolAddress) external {
        require(msg.sender == owner, "Only called by the owner");
        borrowerOpsAddress = _borrowerOpsAddress;
        activePoolAddress = _activePoolAddress;
    }
    function timestamp() external view returns (uint) {
        return block.timestamp / WEEK * WEEK;
    }

    function _checkpoint_token() internal {
        uint token_balance = address(this).balance;
        uint to_distribute = token_balance - token_last_balance;
        emit TEST_balances(token_balance, to_distribute, token_last_balance);
        token_last_balance = token_balance;
        emit TEST_balances(token_balance, to_distribute, token_last_balance);
        uint t = last_token_time;
        uint since_last = block.timestamp - t;
        last_token_time = block.timestamp;
        uint this_week = t / WEEK * WEEK;
        uint next_week = 0;

        for (uint i = 0; i < 20; i++) {
            next_week = this_week + WEEK;
            emit TEST_timestamps(block.timestamp, next_week, this_week);
            if (block.timestamp < next_week) {
                if (since_last == 0 && block.timestamp == t) {
                    tokens_per_week[this_week] = tokens_per_week[this_week] + to_distribute;
                    emit TestingRevenue("-1", t, since_last, to_distribute, tokens_per_week[this_week], this_week, block.timestamp - t);
                } else {
                    tokens_per_week[this_week] = tokens_per_week[this_week] + to_distribute * (block.timestamp - t) / since_last;
                    emit TestingRevenue("0", t, since_last, to_distribute, tokens_per_week[this_week], this_week, block.timestamp - t);
                }
                break;
            } else {
                if (since_last == 0 && next_week == t) {
                    tokens_per_week[this_week] = tokens_per_week[this_week] + to_distribute;
                    emit TestingRevenue("1", t, since_last, to_distribute, tokens_per_week[this_week], this_week, block.timestamp - t);

                } else {
                    tokens_per_week[this_week] = tokens_per_week[this_week] + to_distribute * (next_week - t) / since_last;
                    emit TestingRevenue("2", t, since_last, to_distribute, tokens_per_week[this_week], this_week, block.timestamp - t);

                }
            }
            t = next_week;
            this_week = next_week;
        }
        emit CheckpointToken(block.timestamp, to_distribute);
    }

    function checkpoint_token() external {
        // _requireCallerIsBorrowerOpsOrActivePool();
        _checkpoint_token();
    }

    function _find_timestamp_epoch(address ve, uint _timestamp) internal view returns (uint) {
        uint _min = 0;
        uint _max = VotingEscrow(ve).epoch();
        for (uint i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint _mid = (_min + _max + 2) / 2;
            VotingEscrow.Point memory pt = VotingEscrow(ve).point_history(_mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _find_timestamp_user_epoch(address ve, uint tokenId, uint _timestamp, uint max_user_epoch) internal view returns (uint) {
        uint _min = 0;
        uint _max = max_user_epoch;
        for (uint i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint _mid = (_min + _max + 2) / 2;
            VotingEscrow.Point memory pt = VotingEscrow(ve).user_point_history(tokenId, _mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid -1;
            }
        }
        return _min;
    }

    function ve_for_at(uint _tokenId, uint _timestamp) external view returns (uint) {
        address ve = voting_escrow;
        uint max_user_epoch = VotingEscrow(ve).user_point_epoch(_tokenId);
        uint epoch = _find_timestamp_user_epoch(ve, _tokenId, _timestamp, max_user_epoch);
        VotingEscrow.Point memory pt = VotingEscrow(ve).user_point_history(_tokenId, epoch);
        return OrumMath._max(int256(pt.bias - pt.slope * (int128(int256(_timestamp - pt.ts)))), 0);
    }

    function _checkpoint_total_supply() internal {
        address ve = voting_escrow;
        uint t = time_cursor;
        uint rounded_timestamp = block.timestamp / WEEK * WEEK;
        VotingEscrow(ve).checkpoint();

        for (uint i = 0; i < 20; i++) {
            if (t > rounded_timestamp) {
                break;
            } else {
                uint epoch = _find_timestamp_epoch(ve, t);
                VotingEscrow.Point memory pt = VotingEscrow(ve).point_history(epoch);
                int128 dt = 0;
                if (t > pt.ts) {
                    dt = int128(int256(t - pt.ts));
                }
                ve_supply[t] = OrumMath._max(int256(pt.bias - pt.slope * dt), 0);
            }
            t += WEEK;
        }
        time_cursor = t;
    }

    function checkpoint_total_supply() external {
        _checkpoint_total_supply();
    }

    function _claim(uint _tokenId, address ve, uint _last_token_time) internal returns (uint) {
        uint user_epoch = 0;
        uint to_distribute = 0;

        uint max_user_epoch = VotingEscrow(ve).user_point_epoch(_tokenId);
        uint _start_time = start_time;

        if (max_user_epoch == 0) return 0;

        uint week_cursor = time_cursor_of[_tokenId];
        if (week_cursor == 0) {
            user_epoch = _find_timestamp_user_epoch(ve, _tokenId, _start_time, max_user_epoch);
        } else {
            user_epoch = user_epoch_of[_tokenId];
        }

        if (user_epoch == 0) user_epoch = 1;

        VotingEscrow.Point memory user_point = VotingEscrow(ve).user_point_history(_tokenId, user_epoch);

        if (week_cursor == 0) week_cursor = (user_point.ts + WEEK - 1) / WEEK * WEEK;
        // if (week_cursor == 0) week_cursor = _start_time;
        if (week_cursor >= last_token_time) return 0;
        if (week_cursor < _start_time) week_cursor = _start_time;

        VotingEscrow.Point memory old_user_point;

        for (uint i = 0; i < 50; i++) {
            if (week_cursor >= _last_token_time) break;

            if (week_cursor >= user_point.ts && user_epoch <= max_user_epoch) {
                user_epoch += 1;
                old_user_point = user_point;
                if (user_epoch > max_user_epoch) {
                    user_point = VotingEscrow.Point(0,0,0,0);
                } else {
                    user_point = VotingEscrow(ve).user_point_history(_tokenId, user_epoch);
                }
            } else {
                int128 dt = int128(int256(week_cursor - old_user_point.ts));
                uint balance_of = OrumMath._max(int256(old_user_point.bias - dt * old_user_point.slope), 0);
                // emit test_hello(balance_of, balance_of);
                if (balance_of == 0 && user_epoch > max_user_epoch) break;
                if (balance_of > 0) {
                    to_distribute += balance_of * tokens_per_week[week_cursor] / ve_supply[week_cursor];
                    emit test_hello(to_distribute, balance_of,ve_supply[week_cursor]);

                }
                week_cursor += WEEK;
            }
        }

        user_epoch = OrumMath._min(max_user_epoch, user_epoch - 1);
        user_epoch_of[_tokenId] = user_epoch;
        time_cursor_of[_tokenId] = week_cursor;

        emit Claimed(_tokenId, to_distribute, user_epoch, max_user_epoch);

        return to_distribute;
    }

    function _claimable(uint _tokenId, address ve, uint _last_token_time) internal view returns (uint) {
        uint user_epoch = 0;
        uint to_distribute = 0;

        uint max_user_epoch = VotingEscrow(ve).user_point_epoch(_tokenId);
        uint _start_time = start_time;

        if (max_user_epoch == 0) return 0;

        uint week_cursor = time_cursor_of[_tokenId];
        if (week_cursor == 0) {
            user_epoch = _find_timestamp_user_epoch(ve, _tokenId, _start_time, max_user_epoch);
        } else {
            user_epoch = user_epoch_of[_tokenId];
        }

        if (user_epoch == 0) user_epoch = 1;

        VotingEscrow.Point memory user_point = VotingEscrow(ve).user_point_history(_tokenId, user_epoch);

        if (week_cursor == 0) week_cursor = (user_point.ts + WEEK - 1) / WEEK * WEEK;
        if (week_cursor >= last_token_time) return 0;
        if (week_cursor < _start_time) week_cursor = _start_time;

        VotingEscrow.Point memory old_user_point;

        for (uint i = 0; i < 50; i++) {
            if (week_cursor >= _last_token_time) break;

            if (week_cursor >= user_point.ts && user_epoch <= max_user_epoch) {
                user_epoch += 1;
                old_user_point = user_point;
                if (user_epoch > max_user_epoch) {
                    user_point = VotingEscrow.Point(0,0,0,0);
                } else {
                    user_point = VotingEscrow(ve).user_point_history(_tokenId, user_epoch);
                }
            } else {
                int128 dt = int128(int256(week_cursor - old_user_point.ts));
                uint balance_of = OrumMath._max(int256(old_user_point.bias - dt * old_user_point.slope), 0);
                if (balance_of == 0 && user_epoch > max_user_epoch) break;
                if (balance_of > 0) {
                    to_distribute += balance_of * tokens_per_week[week_cursor] / ve_supply[week_cursor];
                }
                week_cursor += WEEK;
            }
        }

        return to_distribute;
    }

    function claimable(uint _tokenId) external view returns (uint) {
        uint _last_token_time = last_token_time / WEEK * WEEK;
        return _claimable(_tokenId, voting_escrow, _last_token_time);
    }

    function claim(uint _tokenIndex) external returns (uint) {
        if (block.timestamp >= time_cursor) _checkpoint_total_supply();
        address _voting_escrow = voting_escrow;
        uint _tokenId = VotingEscrow(_voting_escrow).tokenOfOwnerByIndex(msg.sender, _tokenIndex);
        uint _last_token_time = last_token_time;

        if(can_checkpoint_toggle && block.timestamp > _last_token_time + TOKEN_CHECKPOINT_DEADLINE){
            _checkpoint_token();
            _last_token_time = block.timestamp;
        }
        _last_token_time = _last_token_time / WEEK * WEEK;
        uint amount = _claim(_tokenId, _voting_escrow, _last_token_time);
        if (amount != 0) {
            payable(msg.sender).transfer(amount);
            token_last_balance -= amount;
        }
        return amount;
    }

    function claim_many(uint[] memory _tokenIdxs) external returns (bool) {
        if (block.timestamp >= time_cursor) _checkpoint_total_supply();
        uint _last_token_time = last_token_time;
        _last_token_time = _last_token_time / WEEK * WEEK;
        address _voting_escrow = voting_escrow;
        uint total = 0;

        for (uint i = 0; i < _tokenIdxs.length; i++) {
            uint _tokenId = VotingEscrow(_voting_escrow).tokenOfOwnerByIndex(msg.sender, _tokenIdxs[i]);
            if (_tokenId == 0) break;
            uint amount = _claim(_tokenId, _voting_escrow, _last_token_time);
            if (amount != 0) {
                VotingEscrow(_voting_escrow).deposit_for(_tokenId, amount);
                total += amount;
            }
        }
        if (total != 0) {
            token_last_balance -= total;
        }

        return true;
    }

    // Once off event on contract initialize
    function setDepositor(address _depositor) external {
        require(msg.sender == depositor);
        depositor = _depositor;
    }

    receive() external payable{
        _requireCallerIsBorrowerOpsOrActivePool();
        _checkpoint_token();
        emit OrumFeeDistributionROSEBalanceUpdated(msg.value);
    }

    function _requireCallerIsBorrowerOpsOrActivePool() internal view {
        require(msg.sender == borrowerOpsAddress || msg.sender == activePoolAddress, "FeeDistribution: caller not BO or ActivePool");
    }
}