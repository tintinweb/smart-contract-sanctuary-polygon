// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

interface IMetaProject {
    function getLevelForNFT(address _user) external view returns (uint256);
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

import "../interfaces/IMetaProject.sol";

contract MetaProjectMock is IMetaProject {
    mapping(address => uint256) public getLevelForNFT;

    function setLevelForNFT(address _user, uint256 _level) external {
        getLevelForNFT[_user] = _level;
    }
}