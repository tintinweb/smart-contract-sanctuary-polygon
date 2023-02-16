/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "contracts/originERC20Token";

interface IERC20 {
    function transfer(address _receiver, uint256 _amount) external;
    function transferFrom(address _from, address _to, uint256 _amount) external;
    function balance(address _address) external view returns (uint256);

}
contract originAirdrop {
    address originalERC20Token;
    mapping(address => bool) whiteListedAddresses;
    //address[] arrayAddresses = 0xD0F0152FB7290Fa8264Ec3F71C6742753E4A1aa6, 0x26Ed8b4d4cEE16b8695dd325129CA931F34e0EEF];
    constructor(address _originERC20Token) {
        originalERC20Token = _originERC20Token;
    }
    /*function airdropTokensWithTransfer(address[] memory arrayAddresses) public {
        for (uint8 i=0; i < arrayAddresses.length; i++) {
            IERC20(originERC20Token).transfer(arrayAddresses[i], 100);
        }
    }*/
    function airdropTokensWithTransfer(address _receiver) public {
            IERC20(originalERC20Token).transfer(_receiver, 100);
    }

    function airdropTokensWithTransferFrom(address _to) public {
        IERC20(originalERC20Token).transferFrom(msg.sender, _to, 100);
    }

    function claimDrop() public { //User himself claims tokens, no gas is paid by user
        require(whiteListedAddresses[msg.sender]);
        IERC20(originalERC20Token).transfer(msg.sender, 100);
    }
}