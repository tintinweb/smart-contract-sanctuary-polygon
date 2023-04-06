// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
contract ParentChainRewardDistributorInterface {
    event KickFailed(uint256 time);
    event KickedEmissions(
        uint256 indexed chainId,
        uint256 indexed activePeriod,
        uint256 amount
    );
    event NewKickMin(uint256 amount);

    function accruedEmissions(uint256) external view returns (uint256) {}

    function base() external view returns (address) {}

    function callproxy() external view returns (address) {}

    function childChainDistributor(uint256)
        external
        view
        returns (string memory) {}

    function initialize(
        address _base,
        address _minter,
        address _voter,
        address _nftBridge,
        address _callproxy,
        uint256 _kickMin
    ) external {}


    function kick(uint256 _chainId) external {}

    function kickMin() external view returns (uint256) {}

    function kickMultiple(uint256[] memory _chainIds) external {}

    function killGovernance() external {}

    function logicAddress() external view returns (address _logicAddress) {}

    function minter() external view returns (address) {}

    function nftBridge() external view returns (address) {}

    function notifyRewardAmount(address _token, uint256 _amount) external {}

    function periodEmissions(uint256) external view returns (uint256) {}

    function setKickMin(uint256 _minAmount) external {}

    function thisAddress() external view returns (string memory) {}

    function voter() external view returns (address) {}
}