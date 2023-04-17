// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import {IVotingEscrow} from '../interfaces/IVotingEscrow.sol';
import {IBlocklist} from '../interfaces/IBlocklist.sol';

/// @title Blocklist Checker implementation.
/// @notice Checks if an address is blocklisted
/// @dev This is a basic implementation using a mapping for address => bool
contract Blocklist is IBlocklist {
    mapping(address => bool) private _blocklist;
    address public manager;
    address public ve;

    constructor(address _manager, address _ve) {
        manager = _manager;
        ve = _ve;
    }

    /// @notice Add address to blocklist
    /// @dev only callable by owner.
    /// @dev Allows blocklisting only of smart contracts
    /// @param addr The contract address to blocklist
    function blockContract(address addr) external {
        require(msg.sender == manager, 'Only manager');
        require(_isContract(addr), 'Only contracts');
        _blocklist[addr] = true;
        IVotingEscrow(ve).forceUndelegate(addr);
    }

    /// @notice Check an address
    /// @dev This method will be called by the VotingEscrow contract
    /// @param addr The contract address to check
    function isBlocked(address addr) public view returns (bool) {
        return _blocklist[addr];
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Blocklist Checker interface
/// @notice Basic blocklist checker interface for VotingEscrow
interface IBlocklist {
    function isBlocked(address addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    enum LockPeriods {
        oneWeek,
        threeMonths,
        sixMonths,
        oneYear
    }

    /// @notice Creates a new lock
    /// @param _value Total units of token to lock
    /// @param _unlockTime Time at which the lock expires
    function createLock(uint256 _value, uint256 _unlockTime) external;

    /// @notice Creates a new lock based in one of the valid period
    /// @param amount Total units of token to lock
    /// @param period Period of time the tokens will be locked
    /// @dev Possible period options are: 1 week (0), 3 months (1), 6 months (2), 1 year (3)
    function createLockByPeriod(uint256 amount, LockPeriods period) external;

    /// @notice Locks more tokens in an existing lock
    /// @param _value Additional units of `token` to add to the lock
    /// @dev Does not update the lock's expiration.
    /// @dev Does increase the user's voting power, or the delegatee's voting power.
    function increaseAmount(uint256 _value) external;

    /// @notice Extends the expiration of an existing lock
    /// @param _unlockTime New lock expiration time
    /// @dev Does not update the amount of tokens locked.
    /// @dev Does increase the user's voting power, unless lock is delegated.
    function increaseUnlockTime(uint256 _unlockTime) external;

    /// @notice Withdraws all the senders tokens, providing lockup is over
    /// @dev Delegated locks need to be undelegated first.
    function withdraw() external;

    /// @notice Delegate voting power to another address
    /// @param _addr user to which voting power is delegated
    /// @dev Can only undelegate to longer lock duration
    /// @dev Delegator inherits updates of delegatee lock
    function delegate(address _addr) external;

    /// @notice Quit an existing lock by withdrawing all tokens less a penalty
    /// @dev Quitters lock expiration remains in place because it might be delegated to
    function quitLock() external;

    /// @notice Get current user voting power
    /// @param _owner User for which to return the voting power
    /// @return Voting power of user
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Get users voting power at a given blockNumber
    /// @param _owner User for which to return the voting power
    /// @param _blockNumber Block at which to calculate voting power
    /// @return uint256 Voting power of user
    function balanceOfAt(
        address _owner,
        uint256 _blockNumber
    ) external view returns (uint256);

    function balanceOfAtT(
        address _owner,
        uint256 _ts
    ) external view returns (uint256);

    /// @notice Calculate current total supply of voting power
    /// @return Current totalSupply
    function totalSupply() external view returns (uint256);

    /// @notice Calculate total supply of voting power at a given blockNumber
    /// @param _blockNumber Block number at which to calculate total supply
    /// @return totalSupply of voting power at the given blockNumber
    function totalSupplyAt(
        uint256 _blockNumber
    ) external view returns (uint256);

    /// @notice Calculate total supply of voting power at a given time
    /// @param _t Time at which to calculate total supply
    /// @return totalSupply of voting power at the given time
    function totalSupplyAtT(uint256 _t) external view returns (uint256);

    /// @notice Remove delegation for blocked contract.
    /// @param _addr user to which voting power is delegated
    /// @dev Only callable by the blocklist contract
    function forceUndelegate(address _addr) external;

    function userPointEpoch(address user) external view returns (uint256);

    function userPointHistory(
        address user,
        uint256 timestamp
    ) external view returns (Point memory);

    function checkpoint() external;
}