//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface INFTWarranty {
    function getSellerNFTs(uint256 sellerId)
        external
        view
        returns (uint256[] memory);

    function getSellers() external view returns (uint256[] memory);

    function getExpiry(uint256 sellerId, uint256 tokenId)
        external
        view
        returns (uint256 expiry);

    function getCreation(uint256 sellerId, uint256 tokenId)
        external
        view
        returns (uint256 creation);

    function getStatus(uint256 sellerId, uint256 tokenId)
        external
        view
        returns (uint256 stat);
        function getSellerNFT(uint256 sellerId,uint256 Index)external view returns(uint256);
        function getSellerNFTSize(uint256 sellerId)external view returns(uint256);

    function burn(uint256 tokenId) external;
}

contract NFTResolver {
    function checker(address contract_add)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    // returns(uint256 []  memory arr)
    {
        uint256[] memory ans = INFTWarranty(contract_add).getSellers();
        for (uint256 i = 0; i < ans.length; i++) {

            for (uint256 j = 0; j <  INFTWarranty(contract_add).getSellerNFTSize(ans[i]); j++) {
                //uint256 creationTime =  INFTWarranty(contract_add).getCreation(ans[i],nfts[i]);
                if (
                    (INFTWarranty(contract_add).getExpiry(ans[i],INFTWarranty(contract_add).getSellerNFT(ans[i],j) ) <
                        block.timestamp) &&
                    (INFTWarranty(contract_add).getStatus(ans[i], INFTWarranty(contract_add).getSellerNFT(ans[i],j)) == 2)
                ) {
                    execPayload = abi.encodeWithSelector(
                        INFTWarranty.burn.selector,
                        uint256(INFTWarranty(contract_add).getSellerNFT(ans[i],j))
                    );
                    return (true, execPayload);
                }
                if (
                    INFTWarranty(contract_add).getExpiry(ans[i], INFTWarranty(contract_add).getSellerNFT(ans[i],j)) >
                    block.timestamp ||
                    INFTWarranty(contract_add).getStatus(ans[i], INFTWarranty(contract_add).getSellerNFT(ans[i],j)) ==
                    0 ||
                    INFTWarranty(contract_add).getStatus(ans[i], INFTWarranty(contract_add).getSellerNFT(ans[i],j)) ==
                    1 ||
                    INFTWarranty(contract_add).getStatus(ans[i], INFTWarranty(contract_add).getSellerNFT(ans[i],j)) == 3
                ) {
                    return (false, bytes("Session is ongoing"));
                }
            }
        }
    }
}