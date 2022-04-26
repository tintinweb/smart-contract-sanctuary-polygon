/**
 *Submitted for verification at polygonscan.com on 2022-04-26
*/

library HashTransaction {
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant CREATE_COLLECTION_TYPEHASH = keccak256("CreateCollection(address creator,string name)");
    bytes32 private constant POST_TYPEHASH = keccak256("Post(address poster,string content,string metadataURI,address parentPostContract,uint256 parentPostId,string[] tags,bytes32 seed)");
    bytes32 private constant DELETE_POST_TYPEHASH = keccak256("DeletePost(uint256 nonce,address poster,uint256 tokenId)");
    bytes32 private constant UPVOTE_TYPEHASH = keccak256("Upvote(bytes32 seed,address upvoter,uint256 tokenId)");
    bytes32 private constant REMOVE_UPVOTE_TYPEHASH = keccak256("RemoveUpvote(bytes32 seed,address upvoter,uint256 tokenId)");
    bytes32 private constant DOWNVOTE_TYPEHASH = keccak256("Downvote(bytes32 seed,address downvoter,uint256 tokenId)");
    bytes32 private constant REMOVE_DOWNVOTE_TYPEHASH = keccak256("RemoveDownvote(bytes32 seed,address downvoter,uint256 tokenId)");
    bytes32 private constant REPOST_TYPEHASH = keccak256("Repost(bytes32 seed,address reposter,uint256 tokenId)");
    bytes32 private constant REMOVE_REPOST_TYPEHASH = keccak256("RemoveRepost(bytes32 seed,address reposter,uint256 tokenId)");
    bytes32 private constant PIN_TYPEHASH = keccak256("PinPost(uint256 nonce,address pinner,uint256 tokenId)");
    bytes32 private constant SET_APPROVAL_TYPEHASH = keccak256("SetApproval(uint256 nonce,address nfpContract,address owner,address operator,bool approved)");
    uint256 constant chainId = 137;

    function getDomainSeperator(address verifyingContract) public pure returns (bytes32) {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("PostPlaza Post Domain")),      // name
                keccak256(bytes("1")),                          // version
                chainId,
                verifyingContract
            ));
        return DOMAIN_SEPARATOR;
    }

    function encodeStringArray(string[] memory strings) public pure returns(bytes memory){
        bytes memory data;
        for(uint i=0; i<strings.length; i++){
            data = abi.encodePacked(data, keccak256(bytes(strings[i])));
        }
        return data;
    }

    function hashCreateCollectionTransaction(address verifyingContract, address _creator, string memory _name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(CREATE_COLLECTION_TYPEHASH, _creator, keccak256(bytes(_name))))));
    }

    function hashMintTransaction(address verifyingContract, address _poster, string memory _content, string memory _metadataURI, address _parentPostContract, uint256 _parentPostId, string[] memory _tags, bytes32 _seed) public pure returns (bytes32) {
        bytes memory encodedTags = encodeStringArray(_tags);
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(POST_TYPEHASH, _poster, keccak256(bytes(_content)), keccak256(bytes(_metadataURI)), _parentPostContract, _parentPostId, keccak256(encodedTags), _seed))));
    }

    function hashDeletePostTransaction(address verifyingContract, uint256 _nonce, address _poster, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(DELETE_POST_TYPEHASH, _nonce, _poster, _tokenId))));
    }

    function hashUpvoteTransaction(address verifyingContract, bytes32 _seed, address _upvoter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(UPVOTE_TYPEHASH, _seed, _upvoter, _tokenId))));
    }

    function hashRemoveUpvoteTransaction(address verifyingContract, bytes32 _seed, address _upvoter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(REMOVE_UPVOTE_TYPEHASH, _seed, _upvoter, _tokenId))));
    }

    function hashDownvoteTransaction(address verifyingContract, bytes32 _seed, address _downvoter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(DOWNVOTE_TYPEHASH, _seed, _downvoter, _tokenId))));
    }

    function hashRemoveDownvoteTransaction(address verifyingContract, bytes32 _seed, address _downvoter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(REMOVE_DOWNVOTE_TYPEHASH, _seed, _downvoter, _tokenId))));
    }

    function hashRepostTransaction(address verifyingContract, bytes32 _seed, address _reposter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(REPOST_TYPEHASH, _seed, _reposter, _tokenId))));
    }

    function hashRemoveRepostTransaction(address verifyingContract, bytes32 _seed, address _reposter, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(REMOVE_REPOST_TYPEHASH, _seed, _reposter, _tokenId))));
    }

    function hashPinPostTransaction(address verifyingContract, uint256 _nonce, address _pinner, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(PIN_TYPEHASH, _nonce, _pinner, _tokenId))));
    }

    function hashSetApprovalTransaction(address verifyingContract, uint256 _nonce, address _nfpContract, address _owner, address _operator, bool _approved) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(SET_APPROVAL_TYPEHASH, _nonce, _nfpContract, _owner, _operator, _approved))));
    }
}