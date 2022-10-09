/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

interface IPreCommitManager {
    struct Project {
        address receiver;
        address asset;
    }
    struct Commit {
        uint256 commitId;
        uint256 projectId;
        address commiter;
        address erc20Token;
        uint256 amount;
        uint256 expiry;
    }

    function lastProjectId() external view returns (uint256);
    function lastCommitId() external view returns (uint256);
    function getProject(uint256) external view returns (Project memory);
    function getCommit(uint256) external view returns (Commit memory);

    function createProject(address projectAcceptedAsset) external;
    function redeem(uint256 projectId, uint256[] memory commitIds) external;
    function commit(
        uint256 projectId,
        uint256 amount,
        uint256 deadline
    ) external;
    function withdrawCommit(uint256 commitId) external;
}

contract CheckExpiration {
    IPreCommitManager public immutable preCommitManager;
    uint256 internal _lastCheckTime;

    event CommitExpired(uint256 commitId);
    event CommitExpiringWarning(uint256 commitId);

    constructor(IPreCommitManager preCommitManager_) {
        preCommitManager = preCommitManager_;
    }

    function everyHour() external {
        if (_lastCheckTime != 0) {
            uint256 _nextCheckTime = _lastCheckTime + 3600;
            require(
                block.timestamp >= _nextCheckTime,
                "CheckExpiration: before next check time"
            );
            _checkExpiration();
            _lastCheckTime = _nextCheckTime;
        } else {
            // execute the first time
            _checkExpiration();
            _lastCheckTime = block.timestamp;
        }
    }

    function _checkExpiration() internal {
        for (uint256 i = 0; i < preCommitManager.lastCommitId() + 1; i++) {
            _checkExpiration(i);
        }
    }

    function _checkExpiration(uint256 commitId) internal {
        uint256 expiry = preCommitManager.getCommit(commitId).expiry;
        if (expiry == 0) {
            // commit already withdrawn
        } else if (
            expiry < block.timestamp + 3600 && expiry > block.timestamp
        ) {
            // expiring in less than 1 hour
            emit CommitExpiringWarning(commitId);
        } else if (expiry < block.timestamp) {
            emit CommitExpired(commitId);
        }
    }
}