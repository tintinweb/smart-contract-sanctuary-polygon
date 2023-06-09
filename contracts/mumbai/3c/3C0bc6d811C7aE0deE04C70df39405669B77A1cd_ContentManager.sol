//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ITokens.sol";

contract ContentManager {
    ITokens private tokens;

    constructor(address _tokens) {
        tokens = ITokens(_tokens);
    }

    event VideoPublished(
        uint videoId,
        uint roomId,
        address owner,
        address creator,
        string URI,
        bool adsEnabled
    );
    event VideoUnpublished(uint videoId, uint roomId, address owner);
    event SocialTokenLaunched(
        uint tokenId,
        address creator,
        uint price,
        uint amount,
        uint videoIds
    );

    function publishVideo(
        uint _id,
        uint _ownerPercentage,
        uint _holdersPercentage,
        bool _adsEnabled
    ) public {
        require(
            tokens.getVideo(_id).Owner == msg.sender,
            "Only the creator can publish a video"
        );
        require(
            tokens.getVideo(_id).Published == false,
            "Video is already published"
        );
        ITokens.Video memory video = tokens.getVideo(_id);
        tokens.updateVideoParameters(
            _id,
            video.Owner,
            video.Price,
            address(0),
            2,
            false,
            true,
            _adsEnabled,
            video.RoomId
        );
        tokens.updateVideoRevenueParameters(
            _id,
            _ownerPercentage,
            _holdersPercentage
        );
        emit VideoPublished(
            _id,
            video.RoomId,
            video.Owner,
            video.Creator,
            video.URI,
            _adsEnabled
        );
    }

    function unpublishVideo(uint _id) public {
        require(
            tokens.getVideo(_id).Owner == msg.sender,
            "Only the creator can unpublish a video"
        );
        require(
            tokens.getVideo(_id).Published == true,
            "Video is already unpublished"
        );
        ITokens.Video memory video = tokens.getVideo(_id);
        tokens.updateVideoParameters(
            _id,
            video.Owner,
            video.Price,
            address(0),
            2,
            false,
            false,
            false,
            video.RoomId
        );
        emit VideoUnpublished(_id, video.RoomId, video.Owner);
    }

    function launchSocialToken(uint _id) public {
        require(
            tokens.getSocialToken(_id).creator == msg.sender,
            "Only the creator can launch a social token"
        );
        require(
            tokens.getSocialToken(_id).launched == false,
            "Social token is already launched"
        );
        ITokens.SocialToken memory socialToken = tokens.getSocialToken(_id);
        tokens.updateSocialTokenParameters(
            _id,
            socialToken.circulatingSupply,
            socialToken.price,
            true,
            socialToken.videoIds
        );
        tokens.updateSocialTokenHolderParameters(
            _id,
            socialToken.totalSupply,
            socialToken.price,
            socialToken.totalSupply,
            msg.sender
        );
        emit SocialTokenLaunched(
            _id,
            socialToken.creator,
            socialToken.price,
            socialToken.totalSupply,
            socialToken.videoIds
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokens {
    struct SocialToken {
        uint ID;
        string URI;
        uint256 totalSupply;
        uint circulatingSupply;
        uint price;
        bool launched;
        address creator;
        uint maxHoldingAmount;
        uint videoIds;
    }

    struct SocialTokenHolder {
        uint Id;
        uint amount;
        uint price;
        uint currentlyListed;
    }

    struct Video {
        uint Id;
        string URI;
        address Owner;
        address Creator;
        uint Price;
        uint SocialTokenId;
        uint OwnerPercentage;
        uint HoldersPercentage;
        address[] Benefeciaries;
        bool Listed;
        bool Published;
        bool AdsEnabled;
        uint RoomId;
    }

    struct Ad {
        uint Id;
        string URI;
        address Advertiser;
        uint[] PublishingRooms;
        bool Active;
        uint TotalSpent;
        uint CurrentBudget;
        uint MaxBudget;
    }

    struct Room {
        uint Id;
        string URI;
        address Creator;
        address Owner;
        uint Price;
        uint DisplayReward;
        uint[] VideoIds;
        uint[] AdIds;
        bool Listed;
    }

    function getSocialToken(
        uint _id
    ) external view returns (SocialToken memory);

    function getAd(uint _adId) external view returns (Ad memory);

    function getVideo(uint _id) external view returns (Video memory);

    function getRoom(uint _id) external view returns (Room memory);

    function getSocialTokenHolder(
        uint _id,
        address _account
    ) external view returns (SocialTokenHolder memory);

    function getBalance(
        address _account,
        uint _id
    ) external view returns (uint256);

    function transferTokens(
        address _from,
        address _to,
        uint _id,
        uint256 _amount
    ) external;

    function transferBatch(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;

    function updateAdParameters(
        uint _id,
        uint _roomId,
        uint roomAdded,
        bool _status,
        uint _totalSpent,
        uint _currentBudget,
        uint _maxBudget
    ) external;

    function updateVideoParameters(
        uint _id,
        address _owner,
        uint _price,
        address _beneficiary,
        uint _action,
        bool _listed,
        bool _published,
        bool _AdsEnabled,
        uint _roomId
    ) external;

    function updateVideoRevenueParameters(
        uint _id,
        uint _ownerPercentage,
        uint _holderPercentage
    ) external;

    function updateRoomParameters(
        uint _id,
        address _owner,
        uint _price,
        uint _displayCharge,
        uint _videoId,
        uint _action,
        uint _adId,
        uint _adAction,
        bool _listed
    ) external;

    function updateSocialTokenParameters(
        uint _id,
        uint _circulatingSupply,
        uint price,
        bool _launched,
        uint videoId
    ) external;

    function updateSocialTokenHolderParameters(
        uint _id,
        uint _amount,
        uint _price,
        uint _currentlyListed,
        address _account
    ) external;
}