// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "../Ownable.sol";

interface IStateReceiver {
	function onStateReceive(uint256 stateId, bytes calldata data) external;
}

contract StateReceiverCaller is 
    Ownable
{
    
    IStateReceiver public stateReceiver;

    constructor() {}
    
    function setStateReceiver(address _stateReceiver) public onlyOwner {
        stateReceiver = IStateReceiver(_stateReceiver);
    }

    function callOnStateReceive(address collection, uint256 tokenId, address newOwner) public onlyOwner {
        require(address(stateReceiver) != address(0x0), "state receiver not set ");
        bytes memory syncData = abi.encode(collection, tokenId, newOwner);
        stateReceiver.onStateReceive(1, abi.encode(syncData));
    }
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed oldOwner_,
        address indexed newOwner_
    );

    constructor() {
        owner = msg.sender;
    }

    function _onlyOwner() internal view {
      require(owner == msg.sender, "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);
    }

    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(
            newOwner_ != address(0x0),
            "Ownable: new owner is the zero address!"
        );
        _transferOwnership(newOwner_);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}