// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Event {
    uint256 start;
    uint256 end;
    address creator;
    bytes eventId;
}

struct BuyRequest {
    uint256 totalCopies;
    uint256 onSaleQuantity;
    uint256 price;
    uint256 amount;
    uint256 commissionRatio;
    uint256 bdaRatio;
    address buyer;
    address payee;
    address paymentToken;
    address collection;
    address referrer;
    address bda;
    bytes nftId;
    // bytes transactionId;
    bytes eventSignature;
    string uri;
}

struct MintRequest {
    address collection;
    address receiver;
    bytes nftId;
    // bytes transactionId;
    string uri;
}

struct Redemption {
    address redeemer;
    address collection;
    uint256[] tokenIds;
    bytes redemptionId;
}

struct Request {
    bytes signature;
    bytes transactionId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/Structs.sol";
import "./utils/HashUtils.sol";

contract Test {
    using HashUtils for Event;

    function hash(
        uint256 start,
        uint256 end,
        address creator,
        bytes calldata eventId
    ) public pure returns (bytes32 digest) {
        Event memory event_ = Event({
            start: start,
            end: end,
            creator: creator,
            eventId: eventId
        });

        return event_.hash();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../common/Structs.sol";

library HashUtils {
    function hash(Event memory event_) internal pure returns (bytes32 digest) {
        return
            keccak256(
                abi.encodePacked(
                    event_.start,
                    event_.end,
                    event_.creator,
                    event_.eventId
                )
            );
    }

    function hash(BuyRequest memory buyRequest)
        internal
        pure
        returns (bytes32 digest)
    {
        return
            keccak256(
                abi.encodePacked(
                    abi.encodePacked(
                        buyRequest.totalCopies,
                        buyRequest.onSaleQuantity,
                        buyRequest.price,
                        buyRequest.amount,
                        buyRequest.commissionRatio,
                        buyRequest.bdaRatio
                    ),
                    abi.encodePacked(
                        buyRequest.buyer,
                        buyRequest.payee,
                        buyRequest.paymentToken,
                        buyRequest.collection,
                        buyRequest.referrer,
                        buyRequest.bda
                    ),
                    buyRequest.nftId,
                    buyRequest.eventSignature,
                    buyRequest.uri
                )
            );
    }
}