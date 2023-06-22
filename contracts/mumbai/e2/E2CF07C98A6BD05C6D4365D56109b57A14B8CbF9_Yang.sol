// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

struct Price {
    uint256 num;
    uint256 denom;
}

interface IRateProvider {
    function getRate() external view returns (uint256);
}

/// @notice Price receiver contract to be deployed on Polygon.
contract Yang is IRateProvider {
    address public fxChild; // Mumbai: 0xCf73231F28B7331BBe3124B907840A94851f9f11 | Polygon: 0x8397259c983751DAf40400790063935a11afa28a
    address public yin;
    Price public latestPrice;

    constructor(address _fxChild) {
        fxChild = _fxChild;
        yin = address(0);
    }

    function setSender(address _yin) external {
        require(yin == address(0), "Sender already set");

        yin = _yin;
    }

    function processMessageFromRoot(uint256, address rootMessageSender, bytes calldata data) external {
        require(msg.sender == fxChild, "Sender not authorized");
        require(rootMessageSender == yin, "Root sender not authorized");

        (uint256 num, uint256 denom) = _convertBytesToPrice(data);

        latestPrice = Price(num, denom);
    }

    function getRate() external override view returns (uint256) {
        return latestPrice.num / latestPrice.denom;
    }

    function _convertBytesToPrice(bytes memory data) private pure returns (uint256, uint256) {
        return abi.decode(data, (uint256, uint256));
    }
}