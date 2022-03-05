/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

pragma solidity ^0.8.0;

interface ISablier {
    function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);
    function withdrawFromStream(uint256 streamId, uint256 amount) external returns (bool);
}

interface IERC20 {
    function transfer(address recipient, uint amount) external;
    function balanceOf(address recipient) external returns (uint);
}


contract SablierClaimer {

    address public owner;

    function setOwner(address _owner) public {
        require(owner == address(0), "owner already set");
        owner = _owner;
    }

    function claimAndSendToOwner(ISablier sablier, uint streamId, address streamToken) public {
        // If the stream is closed, sablier removes the stream.
        try sablier.balanceOf(streamId, address(this)) returns (uint balance) {
            sablier.withdrawFromStream(streamId, balance);
        } catch {}

        sweep(streamToken);
    }

    function sweep(address tokenAddress) public {
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "nothing to claim");
        IERC20(tokenAddress).transfer(owner, balance);
    }

    // Failsafe Incase the sablier API changes
    // allow owner to execute any arbitary contract call.
    function execTransaction(address to, bytes memory data) external returns (bool success) {
        require(msg.sender == owner, "must be owner");
        success = tryAssemblyCall(to, data);
    }

    function tryAssemblyCall(address to, bytes memory data) internal returns (bool success) {
        assembly {
            success := call(gas(), to, 0, add(data, 0x20), mload(data), 0, 0)
            switch iszero(success)
            case 1 {
                let size := returndatasize()
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }
}