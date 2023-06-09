// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokens.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MarketPlace is ERC1155Holder {
    ITokens private token;

    event VideoListed(uint _id, uint _price);
    event VideoUnlisted(uint _id);
    event VideoPurchased(
        uint _id,
        address _buyer,
        address _seller,
        uint _price,
        uint _roomId
    );
    event RoomListed(uint _id, uint _price);
    event RoomUnlisted(uint _id);
    event RoomPurchased(uint _id, address _buyer, address _seller, uint _price);
    event SocialTokenListed(
        uint _id,
        uint _price,
        address _seller,
        uint _amount
    );
    event SocialTokenUnlisted(uint _id, uint _amount, address _seller);
    event SocialTokenPurchased(
        uint _id,
        address _buyer,
        address _seller,
        uint _price,
        uint _amount
    );

    constructor(address _token) {
        token = ITokens(_token);
    }

    function getVideo(uint _id) external view returns (ITokens.Video memory) {
        return token.getVideo(_id);
    }

    function getRoom(uint _id) external view returns (ITokens.Room memory) {
        return token.getRoom(_id);
    }

    function getSocialToken(
        uint _id
    ) external view returns (ITokens.SocialToken memory) {
        return token.getSocialToken(_id);
    }

    function listVideo(uint _id, uint _price) public {
        ITokens.Video memory video = token.getVideo(_id);
        require(
            video.Owner == msg.sender,
            "You are not the owner of this video"
        );
        require(video.Listed == false, "Video is already listed");
        token.updateVideoParameters(
            _id,
            msg.sender,
            _price,
            address(0),
            2,
            true,
            video.Published,
            video.AdsEnabled,
            video.RoomId
        );
        token.transferTokens(msg.sender, address(this), _id, 1);
        emit VideoListed(_id, _price);
    }

    function unlistVideo(uint _id) public {
        ITokens.Video memory video = token.getVideo(_id);
        require(
            video.Owner == msg.sender,
            "You are not the owner of this video"
        );
        require(video.Listed == true, "Video is not listed");
        token.updateVideoParameters(
            _id,
            msg.sender,
            0,
            address(0),
            2,
            false,
            video.Published,
            video.AdsEnabled,
            video.RoomId
        );
        token.transferTokens(address(this), msg.sender, _id, 1);
        emit VideoUnlisted(_id);
    }

    function buyVideo(uint _id, uint _roomId) public {
        ITokens.Video memory video = token.getVideo(_id);
        address currentOwner = video.Owner;
        require(video.Listed == true, "Video is not listed");
        require(
            token.getRoom(_roomId).Owner == msg.sender,
            "You are not the owner of this room"
        );
        token.transferTokens(address(this), msg.sender, _id, 1);
        token.transferTokens(msg.sender, address(this), 0, video.Price);
        token.updateVideoParameters(
            _id,
            msg.sender,
            0,
            currentOwner,
            0,
            false,
            video.Published,
            video.AdsEnabled,
            _roomId
        );
        token.updateVideoParameters(
            _id,
            msg.sender,
            0,
            msg.sender,
            1,
            false,
            video.Published,
            video.AdsEnabled,
            video.RoomId
        );
        emit VideoPurchased(
            _id,
            msg.sender,
            currentOwner,
            video.Price,
            _roomId
        );
    }

    function listRoom(uint _id, uint _price) public {
        ITokens.Room memory room = token.getRoom(_id);
        require(room.Owner == msg.sender, "You are not the owner of this room");
        require(room.Listed == false, "Room is already listed");
        token.updateRoomParameters(
            _id,
            msg.sender,
            _price,
            room.DisplayReward,
            0,
            2,
            0,
            2,
            true
        );
        token.transferTokens(msg.sender, address(this), _id, 1);
        uint[] memory amounts = new uint[](room.VideoIds.length);
        for (uint i = 0; i < room.VideoIds.length; i++) {
            amounts[i] = 1;
        }
        token.transferBatch(msg.sender, address(this), room.VideoIds, amounts);
        emit RoomListed(_id, _price);
    }

    function unListRoom(uint _id) public {
        ITokens.Room memory room = token.getRoom(_id);
        require(room.Owner == msg.sender, "You are not the owner of this room");
        require(room.Listed == true, "Room is not listed");
        token.updateRoomParameters(
            _id,
            msg.sender,
            0,
            room.DisplayReward,
            0,
            2,
            0,
            2,
            false
        );
        token.transferTokens(address(this), msg.sender, _id, 1);
        uint[] memory amounts = new uint[](room.VideoIds.length);
        for (uint i = 0; i < room.VideoIds.length; i++) {
            amounts[i] = 1;
        }
        token.transferBatch(address(this), msg.sender, room.VideoIds, amounts);
        emit RoomUnlisted(_id);
    }

    function buyRoom(uint _id) public {
        ITokens.Room memory room = token.getRoom(_id);
        require(
            token.getBalance(msg.sender, 0) >= room.Price,
            "Insufficient balance"
        );
        require(room.Listed == true, "Room is not listed");
        token.transferTokens(address(this), msg.sender, _id, 1);
        token.transferTokens(msg.sender, address(this), 0, room.Price);
        uint[] memory amounts = new uint[](room.VideoIds.length);
        for (uint i = 0; i < room.VideoIds.length; i++) {
            amounts[i] = 1;
        }
        token.transferBatch(address(this), msg.sender, room.VideoIds, amounts);
        token.updateRoomParameters(
            _id,
            msg.sender,
            0,
            room.DisplayReward,
            0,
            2,
            0,
            2,
            false
        );
        for (uint i = 0; i < room.VideoIds.length; i++) {
            ITokens.Video memory video = token.getVideo(room.VideoIds[i]);
            token.updateVideoParameters(
                room.VideoIds[i],
                msg.sender,
                0,
                address(0),
                2,
                false,
                false,
                false,
                video.RoomId
            );
        }
        emit RoomPurchased(_id, msg.sender, room.Owner, room.Price);
    }

    function listSocialToken(uint _id, uint _amount, uint _price) public {
        require(
            token.getBalance(msg.sender, _id) >= _amount,
            "Insufficient balance"
        );
        ITokens.SocialTokenHolder memory holder = token.getSocialTokenHolder(
            _id,
            msg.sender
        );
        require(holder.amount >= _amount, "Insufficient balance");
        token.updateSocialTokenHolderParameters(
            _id,
            holder.amount - _amount,
            _price,
            holder.currentlyListed + _amount,
            msg.sender
        );
        token.updateSocialTokenParameters(
            _id,
            token.getSocialToken(_id).circulatingSupply + _amount,
            token.getSocialToken(_id).price,
            true,
            token.getSocialToken(_id).videoIds
        );
        token.transferTokens(msg.sender, address(this), _id, _amount);
        emit SocialTokenListed(_id, _price, msg.sender, _amount);
    }

    function unListSocialToken(uint _id, uint _amount) public {
        ITokens.SocialTokenHolder memory holder = token.getSocialTokenHolder(
            _id,
            msg.sender
        );
        require(
            holder.currentlyListed >= _amount,
            "You currently ;isted less than the amount you want to unlist"
        );
        token.updateSocialTokenHolderParameters(
            _id,
            holder.amount + _amount,
            holder.price,
            holder.currentlyListed - _amount,
            msg.sender
        );
        token.updateSocialTokenParameters(
            _id,
            token.getSocialToken(_id).circulatingSupply - _amount,
            token.getSocialToken(_id).price,
            true,
            token.getSocialToken(_id).videoIds
        );
        token.transferTokens(address(this), msg.sender, _id, _amount);
        emit SocialTokenUnlisted(_id, _amount, msg.sender);
    }

    function buySocialToken(uint _id, uint _amount, address _seller) public {
        ITokens.SocialTokenHolder memory buyer = token.getSocialTokenHolder(
            _id,
            msg.sender
        );
        ITokens.SocialTokenHolder memory seller = token.getSocialTokenHolder(
            _id,
            _seller
        );
        require(
            seller.currentlyListed >= _amount,
            "Seller does not have enough tokens listed"
        );
        require(
            token.getSocialToken(_id).maxHoldingAmount >=
                buyer.amount + _amount,
            "You can not buy more than the max holding amount"
        );
        require(
            token.getBalance(msg.sender, 0) >= seller.price * _amount,
            "Insufficient balance"
        );
        token.transferTokens(msg.sender, _seller, 0, seller.price * _amount);
        token.transferTokens(address(this), msg.sender, _id, _amount);
        token.updateSocialTokenHolderParameters(
            _id,
            buyer.amount + _amount,
            seller.price,
            buyer.currentlyListed,
            msg.sender
        );
        token.updateSocialTokenHolderParameters(
            _id,
            seller.amount,
            seller.price,
            seller.currentlyListed,
            _seller
        );
        uint videoId = token.getSocialToken(_id).videoIds;
        token.updateVideoParameters(
            videoId,
            token.getVideo(videoId).Owner,
            token.getVideo(videoId).Price,
            _seller,
            0,
            token.getVideo(videoId).Listed,
            token.getVideo(videoId).Published,
            token.getVideo(videoId).AdsEnabled,
            token.getVideo(videoId).RoomId
        );
        token.updateVideoParameters(
            videoId,
            token.getVideo(videoId).Owner,
            token.getVideo(videoId).Price,
            msg.sender,
            1,
            token.getVideo(videoId).Listed,
            token.getVideo(videoId).Published,
            token.getVideo(videoId).AdsEnabled,
            token.getVideo(videoId).RoomId
        );
        emit SocialTokenPurchased(
            _id,
            msg.sender,
            _seller,
            seller.price * _amount,
            _amount
        );
    }
}