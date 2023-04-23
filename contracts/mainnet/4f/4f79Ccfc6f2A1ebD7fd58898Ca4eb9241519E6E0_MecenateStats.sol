pragma solidity 0.8.19;

import "./interfaces/IMecenateUsers.sol";
import "./interfaces/IMecenateFeedFactory.sol";
import "./interfaces/IMecenateBay.sol";
import "./interfaces/IMecenateIdentity.sol";
import "./interfaces/IMecenateTreasury.sol";

contract MecenateStats {
    struct Stats {
        uint256 totalUsers;
        uint256 totalIdentities;
        uint256 totalBayRequests;
        uint256 totalFeeds;
        uint256 globalFee;
        uint256 fixedFee;
        uint256 treasuryBalance;
    }

    IMecenateUsers public mecenateUsers;
    IMecenateFeedFactory public mecenateFeedFactory;
    IMecenateBay public mecenateBay;
    IMecenateIdentity public mecenateIdentity;
    IMecenateTreasury public mecenateTreasury;

    constructor(
        address _mecenateUsers,
        address _mecenateFeedFactory,
        address _mecenateBay,
        address _mecenateIdentity,
        address _mecenateTreasury
    ) {
        mecenateUsers = IMecenateUsers(_mecenateUsers);
        mecenateFeedFactory = IMecenateFeedFactory(_mecenateFeedFactory);

        mecenateBay = IMecenateBay(_mecenateBay);
        mecenateIdentity = IMecenateIdentity(_mecenateIdentity);
        mecenateTreasury = IMecenateTreasury(_mecenateTreasury);
    }

    function getStats() public view returns (Stats memory) {
        // sanitizé reverted

        uint256 totalBayRequests = mecenateBay.contractCounter();
        uint256 totalFeeds = mecenateFeedFactory.contractCounter();

        return
            Stats(
                mecenateUsers.getUserCount(),
                mecenateIdentity.getTotalIdentities(),
                totalBayRequests,
                totalFeeds,
                mecenateTreasury.globalFee(),
                mecenateTreasury.fixedFee(),
                address(mecenateTreasury).balance
            );
    }
}

pragma solidity 0.8.19;
import "../library/Structures.sol";

interface IMecenateBay {
    function allRequests()
        external
        view
        returns (Structures.BayRequest[] memory);

    function contractCounter() external view returns (uint256);
}

pragma solidity 0.8.19;

interface IMecenateFeedFactory {
    function owner() external view returns (address payable);

    function treasuryContract() external view returns (address payable);

    function identityContract() external view returns (address);

    function feeds() external view returns (address[] memory);

    function contractCounter() external view returns (uint256);
}

pragma solidity 0.8.19;

interface IMecenateIdentity {
    function identityByAddress(address user) external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function getTotalIdentities() external view returns (uint256);

    function getOwnerById(uint256 tokenId) external view returns (address);
}

pragma solidity 0.8.19;

interface IMecenateTreasury {
    function globalFee() external view returns (uint256);

    function fixedFee() external view returns (uint256);
}

pragma solidity 0.8.19;
import "../library/Structures.sol";

interface IMecenateUsers {
    function checkifUserExist(address user) external view returns (bool);

    function getUserData(
        address user
    ) external view returns (Structures.User memory);

    function getUserCount() external view returns (uint256);
}

pragma solidity 0.8.19;

library Structures {
    enum PostStatus {
        Waiting,
        Proposed,
        Accepted,
        Submitted,
        Finalized,
        Punished,
        Revealed,
        Renounced
    }

    enum PostType {
        Text,
        Image,
        Video,
        Audio,
        File
    }

    enum PostDuration {
        OneDay,
        ThreeDays,
        OneWeek,
        TwoWeeks,
        OneMonth
    }

    struct Post {
        User creator;
        PostData postdata;
    }

    struct PostData {
        PostSettings settings;
        PostEscrow escrow;
        PostEncryptedData data;
    }

    struct PostEncryptedData {
        bytes encryptedData;
        bytes encryptedKey;
        bytes decryptedData;
    }

    struct PostSettings {
        PostStatus status;
        PostType postType;
        address buyer;
        bytes buyerPubKey;
        address seller;
        uint256 creationTimeStamp;
        uint256 endTimeStamp;
        uint256 duration;
    }

    struct PostEscrow {
        uint256 stake;
        uint256 payment;
        uint256 punishment;
        uint256 buyerPunishment;
    }

    struct User {
        uint256 mecenateID;
        address wallet;
        bytes publicKey;
    }

    struct UserCentral {
        uint256 mecenateID;
        address wallet;
        bytes publicKey;
        bytes secretKey;
    }

    struct Feed {
        address contractAddress;
        address operator;
        address buyer;
        address seller;
        uint256 sellerStake;
        uint256 buyerStake;
        uint256 totalStake;
        uint256 postCount;
        uint256 buyerPayment;
    }

    struct BayRequest {
        bytes32 request;
        address buyer;
        address seller;
        uint256 payment;
        uint256 stake;
        address postAddress;
        bool accepted;
        uint256 postCount;
    }
}