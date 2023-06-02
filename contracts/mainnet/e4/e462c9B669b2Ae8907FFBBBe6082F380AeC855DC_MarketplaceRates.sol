// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

interface IMarketplaceRates {
    function getOilWellSalePrice(uint256 bars) external view returns (uint256);

    function getArtifactSalePrice(uint256 mod) external view returns (uint256);

    function getBarPrice() external view returns (uint256);

    function getWosPrice() external view returns (uint256);

    function getBarAverage() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "../Security2/Interfaces/IECDSASignature2.sol";
import "../Security2/libs/ECDSALib.sol";
import "./interfaces/IMarketplaceRates.sol";

contract MarketplaceRates is IMarketplaceRates {
    using ECDSALib for bytes;

    IECDSASignature2 private signature;

    uint256 constant _decimals = 6;
    uint256 private barPrice;
    uint256 private wosPrice;
    uint256 private barAverage;

    event ChangedBarPrice(uint256 newPrice);
    event ChangedWosPrice(uint256 newPrice);
    event ChangedBarAverage(uint256 newAverage);

    constructor(IECDSASignature2 _signature) {
        signature = _signature;
        barPrice = _pow(1) / 10;
        wosPrice = _pow(1);
        barAverage = 2099;
    }

    function getOilWellSalePrice(uint256 bars) external view returns (uint256) {
        return _getPrice(bars);
    }

    function getArtifactSalePrice(uint256 mod) external view returns (uint256) {
        return (_getPrice(barAverage) * mod) / 100;
    }

    function getBarPrice() external view returns (uint256) {
        return barPrice;
    }

    function getWosPrice() external view returns (uint256) {
        return wosPrice;
    }

    function getBarAverage() external view returns (uint256) {
        return barAverage;
    }

    function changeBarPrice(
        uint256 price,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        require(price > 0, "The price must be greater than 0");
        signature.verifyMessage(
            abi.encodePacked(msg.sender, price).hash(),
            nonce,
            timestamp,
            signatures
        );
        barPrice = price;
        emit ChangedBarPrice(price);
    }

    function changeWosPrice(
        uint256 price,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        require(price > 0, "The price must be greater than 0");
        signature.verifyMessage(
            abi.encodePacked(msg.sender, price).hash(),
            nonce,
            timestamp,
            signatures
        );
        wosPrice = price;
        emit ChangedWosPrice(price);
    }

    function changeBarAverage(
        uint256 average,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        require(average > 0, "The average must be greater than 0");
        signature.verifyMessage(
            abi.encodePacked(msg.sender, average).hash(),
            nonce,
            timestamp,
            signatures
        );
        barAverage = average;
        emit ChangedBarAverage(average);
    }

    function _pow(uint256 n) private pure returns (uint256) {
        return n * 10 ** _decimals;
    }

    function _getPrice(uint256 bars) private view returns (uint256) {
        return (bars * barPrice) / 2;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

interface IECDSASignature2 {
    function verifyMessage(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external;
    function signatureStatus(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external view returns(uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

library ECDSALib {
    function hash(bytes memory encodePackedMsg) internal pure returns (bytes32) {
        return keccak256(encodePackedMsg);
    }
}