// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

interface ILidoOracle {
    function getLastCompletedReportDelta()
        external
        view
        returns (
            uint256 postTotalPooledEther,
            uint256 preTotalPooledEther,
            uint256 timeElapsed
        );

    function getCurrentFrame()
        external
        view
        returns (
            uint256 frameEpochId,
            uint256 frameStartTime,
            uint256 frameEndTime
        );

    function getLastCompletedEpochId() external view returns (uint256);

    function getBeaconSpec()
        external
        view
        returns (
            uint64 epochsPerFrame,
            uint64 slotsPerEpoch,
            uint64 secondsPerSlot,
            uint64 genesisTime
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

interface IStETH {
    function getPooledEthByShares(uint256 _sharesAmount)
        external
        view
        returns (uint256);

    /**
     * @notice Returns staking rewards fee rate
     */
    function getFee() external view returns (uint16 feeBasisPoints);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.9;

import "contracts/interfaces/lido/ILidoOracle.sol";
import "contracts/test/MockStEth.sol";

/**
 * @dev Lido Oracle mock - only for testing purposes.
 */
contract MockLidoOracle is ILidoOracle {
    uint256 private sharesMultiplier = 1e27;
    MockStEth public mockStEth;

    constructor(MockStEth _mockStEth) {
        mockStEth = _mockStEth;
    }

    /**
     * @notice Report beacon balance and its change during the last frame
     */
    function getLastCompletedReportDelta()
        external
        view
        override
        returns (
            uint256 postTotalPooledEther,
            uint256 preTotalPooledEther,
            uint256 timeElapsed
        )
    {
        // 101 ether, 100 ether, 1 day
        return (1e20 + 1e18, 1e20, 86400);
    }

    /**
     * @notice Return currently reportable epoch (the first epoch of the current frame) as well as
     * its start and end times in seconds
     */
    function getCurrentFrame()
        external
        view
        override
        returns (
            uint256 frameEpochId,
            uint256 frameStartTime,
            uint256 frameEndTime
        )
    {
        // solhint-disable-next-line not-rely-on-time
        uint256 lastUpdatedTimestamp = mockStEth.getlastUpdatedTimestamp();
        return (0, lastUpdatedTimestamp, lastUpdatedTimestamp + 86400);
    }

    function getLastCompletedEpochId() external view returns (uint256) {
        bool instantUpdates = mockStEth.getInstantUpdates();
        if (instantUpdates) {
            return block.timestamp;
        } else {
            return mockStEth.getlastUpdatedTimestamp();
        }
    }

    function getBeaconSpec()
        external
        view
        returns (
            uint64 epochsPerFrame,
            uint64 slotsPerEpoch,
            uint64 secondsPerSlot,
            uint64 genesisTime
        )
    {
        // By returning 1 seconds per epoch and zero as the genesis, we can simply return the timestamp as the last completed epoch
        return (1, 1, 1, 0);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.9;

import "../interfaces/lido/IStETH.sol";

/**
 * @dev StETH mock - only for testing purposes.
 */
contract MockStEth is IStETH {
    uint256 private _sharesMultiplier = 0;
    uint256 private _lastUpdatedTimestamp;
    bool private _instantUpdates;
    bool private _lastUpdatedTimestampManipulation;

    constructor() public {
        _instantUpdates = true;
        _lastUpdatedTimestampManipulation = false;
    }

    function setLastUpdatedTimestampManipulation(
        bool lastUpdatedTimestampManipulation
    ) public {
        _lastUpdatedTimestampManipulation = lastUpdatedTimestampManipulation;
    }

    function getPooledEthByShares(uint256 sharesAmount)
        public
        view
        returns (uint256)
    {
        return (sharesAmount * _sharesMultiplier) / 1e27;
    }

    function setInstantUpdates(bool instantUpdates) public {
        _instantUpdates = instantUpdates;
    }

    function getInstantUpdates() public view returns (bool) {
        return _instantUpdates;
    }

    function getlastUpdatedTimestamp() public view returns (uint256) {
        return _lastUpdatedTimestamp;
    }

    function setSharesMultiplierInRay(uint256 sharesMultiplier) public {
        _sharesMultiplier = sharesMultiplier;
        _lastUpdatedTimestamp = block.timestamp;
    }

    function setLastUpdatedTimestamp(uint256 lastUpdatedTimestamp) public {
        require(
            _lastUpdatedTimestampManipulation,
            "Enable last updated block manipulation"
        );
        _lastUpdatedTimestamp = lastUpdatedTimestamp;
    }

    /**
     * @notice Returns staking rewards fee rate
     */
    function getFee() external view override returns (uint16 feeBasisPoints) {
        return 1000;
    }
}