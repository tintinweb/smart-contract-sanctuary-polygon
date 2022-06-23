/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface BC_Interface {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function symbol() external returns (string memory);
}

contract BanaCatBot {
    BC_Interface public BanaCat;
    string public symbol;
    // event safeTransferFrom(address from,address to, uint256 tokenId);

    // 给目标合约赋值
    function setInterfaceContract(BC_Interface _addr) external{
        BanaCat = _addr;
    }

    function bulkTransfer(address[] calldata addrList, uint[] calldata nftlist) external {
        require(addrList.length == nftlist.length, "length doesn't match");
        for (uint i = 0; i < addrList.length; i++){
            BanaCat.safeTransferFrom(msg.sender, addrList[i], nftlist[i]);
            // emit safeTransferFrom(msg.sender, addrList[i], nftlist[i]);
        }
    }
    function showSymbol() external{
        symbol = BanaCat.symbol();
    }

}