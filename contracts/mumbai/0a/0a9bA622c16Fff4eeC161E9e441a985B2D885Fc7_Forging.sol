// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ICat.sol";

contract Forging {
    function forgeToken(address _tokenAddress, uint256 _tokenId) external {
        ICat catInterface = ICat(_tokenAddress);

        uint256[] memory requirementTokens = catInterface.getCat(_tokenId).requiresBurning;

        uint256 available;
        uint256[] memory amounts = new uint256[](requirementTokens.length);
        for (uint256 i; i < requirementTokens.length; i++) {
            if (catInterface.adminBalanceOf(msg.sender, requirementTokens[i]) > 0) {
                available += 1;
            }
            amounts[i] = 1;
        }
        require(available == requirementTokens.length, "Required Tokens not minted");

        catInterface.burnBatch(msg.sender, requirementTokens, amounts);
        catInterface.adminMint(msg.sender, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICat {
    struct Cat {
        uint256 id;
        string name;
        bool tradable;
        uint256[] requiresBurning;
        uint256 lastTouched;
    }

    function getCat(uint256 _tokenId) external view returns (Cat memory);

    function adminMint(address _to, uint256 _tokenId) external;

    function burnBatch(
        address _from,
        uint256[] memory _tokenIds,
        uint256[] memory amounts
    ) external;

    function adminBalanceOf(address account, uint256 id) external view returns (uint256);
}