// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

/// @notice Price receiver contract to be deployed on Polygon.
contract Yang {
    address public yin;
    uint256 public latestNum;
    uint256 public latestDenom;

    constructor() {
        yin = address(0);
    }

    function setSender(address _yin) external {
        require(yin == address(0), "Sender already set");

        yin = _yin;
    }

    function processMessageFromRoot(uint256, address rootMessageSender, bytes calldata data) external {
        require(msg.sender == address(0), "Child not authorized");
        require(rootMessageSender == yin, "Sender not authorized");

        (uint256 num, uint256 denom) = _convertBytesToPrice(data);

        latestNum = num;
        latestDenom = denom;
    }

    function _convertBytesToPrice(bytes memory data) public pure returns (uint256, uint256) {
        require(data.length == 64, "Invalid data length");

        uint256 num = 0;
        uint256 denom = 0;

        (num, denom) = abi.decode(data, (uint256, uint256));

        return (num, denom);
    }
}