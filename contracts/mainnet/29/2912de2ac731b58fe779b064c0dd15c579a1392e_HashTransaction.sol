/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

library HashTransaction {
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant FOLLOW_TYPEHASH = keccak256("Follow(uint256 nonce,address follower,address addressToFollow)");
    bytes32 private constant UNFOLLOW_TYPEHASH = keccak256("Unfollow(uint256 nonce,address unfollower,address addressToUnfollow)");

    uint256 constant chainId = 137;

    function getDomainSeperator(address verifyingContract) public pure returns (bytes32) {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("PostPlaza Network Domain")),   // name
                keccak256(bytes("1")),                          // version
                chainId,
                verifyingContract
            ));
        return DOMAIN_SEPARATOR;
    }

    function hashFollowTransaction(address verifyingContract, uint256 _nonce, address _follower, address _addressToFollow) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(FOLLOW_TYPEHASH, _nonce, _follower, _addressToFollow ))));
    }

    function hashUnfollowTransaction(address verifyingContract, uint256 _nonce, address _unfollower, address _addressToUnfollow) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(UNFOLLOW_TYPEHASH, _nonce, _unfollower, _addressToUnfollow ))));
    }
}