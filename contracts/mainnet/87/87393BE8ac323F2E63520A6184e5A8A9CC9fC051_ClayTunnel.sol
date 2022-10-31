/**
 *Submitted for verification at polygonscan.com on 2022-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IClayTunnel {
    function getFunds() external view returns (uint256, uint256);

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

contract ClayTunnel is IClayTunnel {
    // fx child
    address public immutable fxChild;

    // fx root tunnel aka ClayMatic
    address public immutable fxRootTunnel;

    uint256 public latestStateId;
    uint256 public totalCsToken;
    uint256 public currentDeposits;

    constructor(address _fxChild, address _fxRootTunnel) {
        fxChild = _fxChild;
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        require(rootMessageSender == fxRootTunnel, "FxBaseChildTunnel: INVALID_ROOT_SENDER");
        if (latestStateId < stateId) {
            latestStateId = stateId;
            (totalCsToken, currentDeposits) = abi.decode(data, (uint256, uint256));
        }
    }

    /**
     * @dev Decodes and returns csMATIC supply and Current Deposits
     */
    function getFunds() public view returns (uint256, uint256) {
        return (totalCsToken, currentDeposits);
    }

    /**
     * @dev Returns the current exchange rate accounting for any slashing or donations.
     */
    function getRate() external view returns (uint256) {
        (uint256 totalCsToken_, uint256 currentDeposits_) = getFunds();
        if (totalCsToken_ != currentDeposits_ && totalCsToken_ != 0 && currentDeposits_ != 0) {
            return (1 ether * currentDeposits_) / totalCsToken_;
        } else {
            return 1 ether;
        }
    }
}