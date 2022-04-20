/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface ERC20 {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface ERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external ;
}

interface ERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}



contract MultiTransfer {

    function transfer(
        address payable[] calldata addresses,
        uint256[] calldata etherAmounts,
        address erc20TokenAddress,
        uint256[] calldata erc20Amounts,
        address itemTokenAddress,
        uint256[] calldata itemTokenIds,
        uint256[] calldata itemAmounts
    ) public payable {
        require(etherAmounts.length == addresses.length);
        require((erc20Amounts.length == 0 && erc20TokenAddress == address(0x0)) || (erc20Amounts.length == addresses.length));
        require((itemTokenIds.length == 0 && itemTokenAddress == address(0x0)) || (itemTokenIds.length == addresses.length));
        require(itemAmounts.length == 0 || itemAmounts.length == addresses.length);
        
        for(uint256 i=0; i<addresses.length; i++) {
            if(etherAmounts.length > 0 && etherAmounts[i] > 0) {
                addresses[i].transfer(etherAmounts[i]);
            }
            if(erc20TokenAddress != address(0x0)) {
                require(ERC20(erc20TokenAddress).transferFrom(msg.sender, addresses[i], erc20Amounts[i]), 'ERC20 transfer failed');
            }
            if(itemTokenAddress != address(0x0)) {
                if(itemAmounts.length == 0) {
                    //ERC721
                    ERC721(itemTokenAddress).transferFrom(msg.sender, addresses[i], itemTokenIds[i]);
                } else {
                    ERC1155(itemTokenAddress).safeTransferFrom(msg.sender, addresses[i], itemTokenIds[i], itemAmounts[i], new bytes(0));
                }
            }
        }
    }

}