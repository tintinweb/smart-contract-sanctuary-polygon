// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

contract Bridge {
    address private authority;

    constructor(address _auth) payable {
        authority = _auth;
    }

    event BridgeToken(address, uint256, string);
    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function bridgeNative(string calldata signature) public payable {
        emit BridgeToken(msg.sender, msg.value, signature);
    }

    function authorityTransfer(address _payee, uint256 amount) public {
        require(
            msg.sender == authority,
            "Sender doesn't have authorty to make transaction"
        );
        payable(_payee).transfer(amount);
    }

    function updateAuthority(address newAuthority) external {
        require(
            msg.sender == authority,
            "Caller doesn't have authority to transfer funds"
        );
        authority = newAuthority;
    }
}