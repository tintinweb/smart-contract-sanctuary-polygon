/**
 *Submitted for verification at polygonscan.com on 2022-05-05
*/

library HashTransaction {
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant UPDATE_ALL_TYPEHASH = keccak256("UpdateAll(uint256 nonce,address user,string name,string bio,string website,string ipfsHash)");
    bytes32 private constant VERIFY_TYPEHASH = keccak256("Verify(uint256 nonce,address user,string linkToVerifiedSource)");
    bytes32 private constant VERIFIED_SOURCE_USERNAME_TYPEHASH = keccak256("SetUseVerifiedSourceUsername(uint256 nonce,address user,bool useVerifiedSourceUsername)");
    bytes32 private constant VERIFY_AND_USERNAME_TYPEHASH = keccak256("VerifyAndSetSourceUsername(uint256 nonce,address user,string linkToVerifiedSource,bool useVerifiedSourceUsername)");
    bytes32 private constant NAME_TYPEHASH = keccak256("SetName(address user,string name,uint256 nonce)");
    bytes32 private constant BIO_TYPEHASH = keccak256("SetBio(address user,string bio,uint256 nonce)");
    bytes32 private constant WEBSITE_TYPEHASH = keccak256("SetWebsite(address user,string website,uint256 nonce)");
    bytes32 private constant CONNECT_AVATAR_TYPEHASH = keccak256("ConnectAvatar(address user,uint256 externalNFTChainId,address externalNftContractAddress,uint256 externalTokenId,uint256 nonce)");

    uint256 constant chainId = 137;

    function getDomainSeperator(address verifyingContract) public pure returns (bytes32) {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("PostPlaza Info Domain")),  // name
                keccak256(bytes("1")),                      // version
                chainId,
                verifyingContract
            ));
        return DOMAIN_SEPARATOR;
    }

    function hashUpdateAllTransaction(address verifyingContract, uint256 _nonce, address _user, string memory _name, string memory _bio,
        string memory _website, string memory _ipfsHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(UPDATE_ALL_TYPEHASH,
            _nonce, _user, keccak256(bytes(_name)), keccak256(bytes(_bio)), keccak256(bytes(_website)), keccak256(bytes(_ipfsHash))))));
    }

    function hashVerify(address verifyingContract, uint256 _nonce, address _user, string memory _linkToVerifiedSource) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(VERIFY_TYPEHASH, _nonce, _user, keccak256(bytes(_linkToVerifiedSource))))));
    }

    function hashSetUseVerifiedSourceUsername(address verifyingContract, uint256 _nonce, address _user, bool _useVerifiedSourceUsername) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(VERIFIED_SOURCE_USERNAME_TYPEHASH, _nonce, _user, _useVerifiedSourceUsername))));
    }

    function hashVerifyAndSetSourceUsername(address verifyingContract, uint256 _nonce, address _user, string memory _linkToVerifiedSource, bool _useVerifiedSourceUsername) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(VERIFY_AND_USERNAME_TYPEHASH, _nonce, _user, keccak256(bytes(_linkToVerifiedSource)), _useVerifiedSourceUsername))));
    }

    function hashSetName(address verifyingContract, address _user, string memory _name, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(NAME_TYPEHASH, _user, keccak256(bytes(_name)), _nonce))));
    }

    function hashSetBio(address verifyingContract, address _user, string memory _bio, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(BIO_TYPEHASH, _user, keccak256(bytes(_bio)), _nonce))));
    }

    function hashSetWebsite(address verifyingContract, address _user, string memory _website, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(WEBSITE_TYPEHASH, _user, keccak256(bytes(_website)), _nonce))));
    }

    function hashConnectAvatar(address verifyingContract, address _user, uint256 _externalNFTChainId, address _externalNftContractAddress, uint256 _externalTokenId, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract),
            keccak256(abi.encode(CONNECT_AVATAR_TYPEHASH, _user, _externalNFTChainId, _externalNftContractAddress, _externalTokenId, _nonce))));
    }
}