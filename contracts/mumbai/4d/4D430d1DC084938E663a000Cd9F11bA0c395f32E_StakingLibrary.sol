// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IKommunitasStaking{
    function getUserStakedTokens(address _of) external view returns (uint256);
    function communityStaked() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IKommunitasStakingV2{
    function getUserStakedTokensBeforeDate(address _of, uint256 _before) external view returns (uint256);
    function staked(uint256) external view returns (uint256,uint256,uint256);
    function lockPeriod(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../interfaces/IKommunitasStaking.sol";
import "../interfaces/IKommunitasStakingV2.sol";

library StakingLibrary {
	IKommunitasStaking public constant stakingV1 = IKommunitasStaking(0x233BA8ab987d1e66702cdbEC914812fBC31D7D47);
	IKommunitasStakingV2 public constant stakingV2 = IKommunitasStakingV2(0xEFB19A429947Bb5D1Ac340C31146d325b4CE90a5);

    /**
     * @dev Get V1 + V2 Staked
     */
    function getTotalStaked() internal view returns(uint128 total){
        uint256 v2;
        for(uint8 i=0; i<3; ++i){
            uint lock = stakingV2.lockPeriod(i);
            (,,uint fetch) = stakingV2.staked(lock);
            v2 += fetch;
        }

        total = uint128(stakingV1.communityStaked()) + uint128(v2);
    }

	/**
     * @dev Get User Total Staked Kom
     * @param _user User address
     */
    function getUserTotalStaked(address _user, uint128 _calculation) internal view returns(uint128){
        uint128 userV1Staked = uint128(stakingV1.getUserStakedTokens(_user));
        uint128 userV2Staked = uint128(stakingV2.getUserStakedTokensBeforeDate(_user, _calculation));
        return userV1Staked + userV2Staked;
    }
}