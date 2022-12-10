// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Daigon.sol";

contract StakeInfo {
	DAIgon dg = DAIgon(0x4eEfb25bc035189b91cC5CE7d54E1a4DDcfcfBEe);

	uint32 public constant TIME_STEP = 1 days;
	uint32 public constant STAKE_LENGTH = 30 * TIME_STEP;

	struct User {
		address referrer;
		uint32 lastClaim;
		uint32 startIndex;
		uint128 bonusClaimed;

		uint96 bonus_0;
		uint32 downlines_0;
		uint96 bonus_1;
		uint32 downlines_1;
		uint96 bonus_2;
		uint32 downlines_2;

		uint96 leftOver;
	}

	struct Stake {
		uint96 amount;
		uint32 startDate;
	}

	function get(address addr) external view returns (uint112 totalReturn, uint112 activeStakes, uint112 totalClaimed, uint256 claimable, uint112 cps) {
		bool errored;
        uint256 i;

        (,uint32 user_lastClaim, uint32 user_startIndex,,,,,,,, uint96 user_leftOver) = dg.users(addr);

		uint32 lastClaim;

        while(!errored) {
            try dg.stakes(addr, i) returns (uint96 stake_amount, uint32 stake_startDate) {

                totalReturn += stake_amount;

                lastClaim = stake_startDate > user_lastClaim ? stake_startDate : user_lastClaim;

                if(block.timestamp < stake_startDate + STAKE_LENGTH) {
                    cps += stake_amount / 30 / 24 / 60 / 60;
                    activeStakes += stake_amount;
                }
                if(lastClaim >= stake_startDate + STAKE_LENGTH) {
                    totalClaimed += stake_amount;
                }
                else {
                    totalClaimed += stake_amount * (lastClaim - stake_startDate) / STAKE_LENGTH;
                }

                if(i >= user_startIndex) {
			        if(stake_startDate + STAKE_LENGTH > user_lastClaim) {
                        if(block.timestamp >= stake_startDate + STAKE_LENGTH) {
                            claimable += stake_amount * (stake_startDate + STAKE_LENGTH - lastClaim) / STAKE_LENGTH;
                        }
                        else {
                            claimable += stake_amount * (block.timestamp - lastClaim) / STAKE_LENGTH;
                        }
                    }
                }
                i++;
            }
            catch {
                errored = true;
            }
        }

		claimable += user_leftOver;
		totalClaimed -= user_leftOver;
	}
}