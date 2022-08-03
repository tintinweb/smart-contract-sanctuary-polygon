// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../interfaces/IExecutionStrategy.sol";
import "../libraries/OrderTypes.sol";

contract FixedPrice is IExecutionStrategy{

    uint256 public protocolFee;
    constructor(uint256 _fee) {
        protocolFee = _fee;
    }

    function viewProtocolFee() external override view returns (uint256) {
        return protocolFee;
    }

    function canExecuteTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        ) 
    {
        return (makerBid.price == takerAsk.price && makerBid.startTime <= block.timestamp && makerBid.endTime >= block.timestamp && makerBid.id == takerAsk.id, makerBid.id, takerAsk.sid);
    }

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (makerAsk.price == takerBid.price && makerAsk.startTime <= block.timestamp && makerAsk.endTime >= block.timestamp && makerAsk.id == takerBid.id, makerAsk.id, makerAsk.sid);
    }

    function getStrategyType() external override pure returns(uint256){
        return 0; // transfer
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IExecutionStrategy {
    function canExecuteTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function viewProtocolFee() external view returns (uint256);
    function getStrategyType() external pure returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the LooksRare exchange.
 */
library OrderTypes {
    bytes32 internal constant MAKER_ORDER_HASH = 0x0c580f839e714c65f79de49a3eb3a85b0d4f8b049970c2e31fb64e38c0b32dfc;

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        uint256 price; // price (used as )
        uint id;
        uint256 sid; // id of the token
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 id;
        uint256 sid;
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.signer,
                    makerOrder.price,
                    makerOrder.id,
                    makerOrder.sid,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk
                )
            );
    }
}