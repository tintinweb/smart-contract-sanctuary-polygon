// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title Statuses
 * @author Lucien Akchoté
 *
 * @notice Handles the statuses calculation
 */
library Status {
    function getStatus(uint256 totalTokens) external pure returns (DataTypes.FrenStatus) {
        if (totalTokens >= 34) {
            return DataTypes.FrenStatus.Oracle;
        }
        if (totalTokens >= 21) {
            return DataTypes.FrenStatus.Aggregatoor;
        }
        if (totalTokens >= 13) {
            return DataTypes.FrenStatus.Contributoor;
        }
        if (totalTokens >= 5) {
            return DataTypes.FrenStatus.Pepe;
        }
        if (totalTokens == 1) {
            return DataTypes.FrenStatus.Degen;
        }

        return DataTypes.FrenStatus.Anon;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title DataTypes
 * @author Lucien Akchoté
 *
 * @notice A standard library of data types used throughout AmpliFrens
 */
library DataTypes {
    /// @notice Contain the different statuses depending on tokens earnt
    enum FrenStatus {
        Anon,
        Degen,
        Pepe,
        Contributoor,
        Aggregatoor,
        Oracle
    }

    /// @notice Contain the different contributions categories
    enum ContributionCategory {
        NFT,
        Article,
        DeFi,
        Security,
        Thread,
        GameFi,
        Video,
        Misc
    }

    /**
     *  @notice Contain the basic information of a contribution
     *
     *  @dev Use tight packing to save up on storage cost
     *  4 storage slots used (string takes up 64 bytes or 2 slots in the storage)
     */
    struct Contribution {
        address author; /// @dev 20 bytes
        ContributionCategory category; /// @dev 1 byte
        bool valid; /// @dev 1 byte
        uint64 timestamp; /// @dev 8 bytes
        int16 votes; /// @dev 2 bytes
        bytes32 title; /// @dev 32 bytes
        string url; /// @dev 64 bytes
    }

    /// @notice Contain the basic information of a profile
    struct Profile {
        bytes32 lensHandle;
        bytes32 discordHandle;
        bytes32 twitterHandle;
        bytes32 username;
        bytes32 email;
        string websiteUrl;
        bool valid;
    }

    /// @notice These time-related variables are used in conjunction to determine when minting function can be called
    struct MintingInterval {
        uint256 lastBlockTimestamp;
        uint256 mintInterval;
    }

    /// @notice Contain contributions data
    struct Contributions {
        mapping(uint256 => DataTypes.Contribution) contribution;
        mapping(uint256 => mapping(address => bool)) upvoted;
        mapping(uint256 => mapping(address => bool)) downvoted;
        address[] upvoterAddresses;
        address[] downvoterAddresses;
        uint256[] upvotedIds;
        uint256[] downvotedIds;
        address adminAddress;
    }
}