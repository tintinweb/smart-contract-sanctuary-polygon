/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

pragma solidity ^0.8.0;

interface ISablier {
    function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);
    function withdrawFromStream(uint256 streamId, uint256 amount) external returns (bool);
    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        );
}

interface IERC20 {
    function safeTransfer(address recipient, uint amount) external;
}


contract SablierClaimer {

    address public owner;

    function setOwner(address _owner) public {
        require(owner == address(0), "owner already set");
        owner = _owner;
    }

    function claimAndSendToOwner(ISablier sablier, uint streamId) public {
        (,,,address tokenAddress,,,,) = sablier.getStream(streamId);
        uint balance = sablier.balanceOf(streamId, address(this));
        require(balance > 0, "nothing to claim");
        // Withdraw to the contract
        sablier.withdrawFromStream(streamId, balance);
        // Transfer from contract to owner.
        IERC20(tokenAddress).safeTransfer(owner, balance);
    }

    // Incase the sablier API changes, we allow the contract owner
    // to execute any arbitary contract call.
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