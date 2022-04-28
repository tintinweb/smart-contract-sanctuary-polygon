/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract TaxTerminator {
    address public theSpace = 0xA69b77089b1d2b01212128593146125f28f0A7FD;
    address public token = 0xEb6814043DC2184B0B321F6De995bF11bdbCc5B8;

    function ownerOf(uint256 _tokenId) public view returns (address) {
        (bool success, bytes memory data) = theSpace.staticcall(abi.encodeWithSignature("getOwner(uint256)", _tokenId));
        
        require(success, "call failed");
        return abi.decode(data, (address));
    }

    function judge(uint256 _tokenId, address _owner, uint256 threshhold) public view returns(bool) {
        (bool success, bytes memory data) = theSpace.staticcall(abi.encodeWithSignature("getTax(uint256)", _tokenId));
        (bool success2, bytes memory data2) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", _owner));

        require(success && success2, "judge failed");
        
        uint256 tax = abi.decode(data, (uint256));
        uint256 balance = abi.decode(data2, (uint256));
        return tax > threshhold || tax >= balance;
    }

    function terminate(uint256 _x, uint256 _y) external {
        uint256 tokenId = 200 * (_y - 1) + _x;
        bytes memory payload = abi.encodeWithSignature("settleTax(uint256)", tokenId);
        (bool success,) = theSpace.call(payload);

        require(success, "terminate fail");
    }

    function terminator_1000(uint16 _from, uint256 _threshold) external {
        unchecked {
            for (uint16 i=_from; i < _from + 1000; ++i) {
                // Check if the pixel has an owner
                address owner = ownerOf(i);
                if (owner == address(0)) {continue;}
                
                // We are a busy terminator, time is gas
                if ( !judge(i, owner, _threshold)) {continue;}

                bytes memory payload = abi.encodeWithSignature("settleTax(uint256)", i);
                (bool success,) = theSpace.call(payload);
                require(success, "Over my dead body");
            }
        }
    }
    
    receive() external payable {}
}