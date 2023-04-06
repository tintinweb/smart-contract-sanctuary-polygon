// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
contract FakeVoterVeDistMinter {

    uint256 activePeriod;

    constructor () {
        activePeriod = 1680717764;
    }
    function vote(uint256 _tokenId, address[] memory poolVotes, uint256[] memory weights) external {}
    function setActivePeriod(uint256 _period) external {
        if (activePeriod > 0) {
            activePeriod += 1 hours;
        } else activePeriod = _period;
    }

    function active_period() external view returns (uint256) {
        return activePeriod;
    }

    function claim(uint256 _tokenId) external {}
}