// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.11;

contract WikiTest {
    /// @dev keccak256("SignedPost(address user,uint256 deadline)")
    bytes32 private constant SIGNED_POST_TYPEHASH = 0xf0f72c1511232ff53697c486bd00cd997a330dbff5fe1ee90a777f8f37c6c78d;

    /// @notice the EIP-712 domain separator
    bytes32 private immutable EIP_712_DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("EP")),
                keccak256(bytes("1")),
                _chainID(),
                address(this)
            )
        );

    event Posted(address indexed _from, string _ipfs);

    function postBySig(
        address _user,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                EIP_712_DOMAIN_SEPARATOR,
                keccak256(abi.encode(SIGNED_POST_TYPEHASH, _user, _deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(recoveredAddress != address(0) && recoveredAddress == _user, "invalid signature");
    }

    function _chainID() private view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }
}