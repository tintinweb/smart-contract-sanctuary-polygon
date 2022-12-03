// SPDX-License-Identifier:  MIT
pragma solidity 0.8.17;

interface IMetaProject {
    function getLevelForNFT(uint256 _idUser) external view returns (uint256);
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.17;

import "../interfaces/IMetaProject.sol";

contract MetaProjectMock is IMetaProject {
    mapping(uint256 => uint256) public getLevelForNFT;

    function setLevelForNFT(uint256 _user, uint256 _level) external {
        getLevelForNFT[_user] = _level;
    }
}