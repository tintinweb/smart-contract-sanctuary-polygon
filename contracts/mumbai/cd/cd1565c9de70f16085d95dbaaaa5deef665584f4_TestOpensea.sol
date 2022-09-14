/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

contract TestOpensea {
    address public constant OPENSEA_CONTRACT_ADDRESS = 0x2953399124F0cBB46d2CbACD8A89cF0599974963;

    function test(address _address, uint256 _tokenId) public returns (bytes4, bool) {
        bytes memory payload = abi.encodeWithSignature("balanceOf(address, uint256)", _address, _tokenId);
        (bool success, bytes memory returnData) = address(OPENSEA_CONTRACT_ADDRESS).call(payload);

        return (bytes4(returnData), success);
    }

    function callTransferFunctionDirectlyTwo(address _address, uint256 _tokenId)
        public
        returns (bytes4, bool)
    {
        (bool success, bytes memory returnData) = OPENSEA_CONTRACT_ADDRESS.call(
            abi.encodeWithSignature("balanceOf(address, uint256)", _address, _tokenId)
        );
        return (bytes4(returnData), success);
    }
}