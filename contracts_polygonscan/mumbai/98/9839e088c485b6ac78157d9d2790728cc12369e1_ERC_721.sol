/**
 *Submitted for verification at polygonscan.com on 2021-10-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
library SafeMath{
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }
    function sub(uint256 a,uint256 b) internal pure returns (uint256)
    {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }
}

interface ERC721 {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

contract ERC_721 is ERC721 {
    using SafeMath for uint256;
    struct Nfts{
        uint256 _tokenId;
        string _name;
        string _tokenIPFSHash;
    }
    mapping(uint256 => address) public ownerAddress;      // Mapping from tokenId to ownerAddress
    mapping(address => uint256) public balance;          // Mapping from ownerAddress to token count
    mapping(uint256 => address) public approvedAddress; // Mapping from tokenId to approved address
    mapping(address => mapping(address => bool)) public tokenApprovals; // owner sets or unsets approval for address
    
    mapping(uint256 => address payable) private tokenIdToCreator;
    mapping(address => mapping(string => bool)) private creatorToIPFSHashToMinted;
    mapping(uint256 => string) internal _tokenURIs;
    
    constructor() public {
        _initializeNFT721Mint();
    }
    
    event TokenCreatorUpdated(address indexed fromCreator, address indexed toCreator, uint256 indexed tokenId);
    event Minted(address indexed creator,uint256 indexed tokenId,string indexed indexedTokenIPFSPath,string tokenIPFSPath);
    
    uint256 private nextTokenId;

    
    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual {}
    
    function _updateTokenCreator(uint256 tokenId, address payable creator) internal {
    emit TokenCreatorUpdated(tokenIdToCreator[tokenId], creator, tokenId);
    ownerAddress[tokenId]=creator;
    tokenIdToCreator[tokenId] = creator;
  }


    function balanceOf(address _owner) public override view returns(uint256) {
        require(_owner!=address(0),"Invalid Address");
        return balance[_owner];
    }
    function ownerOf(uint256 _tokenId) public override view returns (address) {
        address owner = ownerAddress[_tokenId];
        require(owner!=address(0),"TokenId does not exists");
        return owner;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
    
  }
    
    function approve(address _approved, uint256 _tokenId) public override payable {
        address owner = ownerOf(_tokenId);
        require(owner!=_approved,"Approval for self");
        require(msg.sender==owner,"Calling address is not the owner of given tokenId");
        approvedAddress[_tokenId]=_approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }
    function getApproved(uint256 _tokenId) public override view returns(address) {
        address owner = ownerOf(_tokenId);
        require(owner!=address(0),"TokenId does not exists");
        return approvedAddress[_tokenId];
    }
    function setApprovalForAll(address _operator, bool _approved) public override {
        require(msg.sender!=_operator,"Approval for current address");
        tokenApprovals[msg.sender][_operator]=_approved;
         emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    function isApprovedForAll(address _owner, address _operator) public override view returns(bool) {
        return tokenApprovals[_owner][_operator];
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public override payable {
        address owner = ownerAddress[_tokenId];
        require(owner!=address(0),"TokenId does not exists");
        //checking whether msg.sender has approval for sending given TokenId
        require(msg.sender==owner || getApproved(_tokenId)==msg.sender || isApprovedForAll(owner,msg.sender),"Calling address is not approved");
        require(_from==owner,"From address is not the owner of given address");
        require(_to!=address(0),"Receiver address must not be zeo address");
        balance[_from]=balance[_from].sub(1);
        balance[_to]=balance[_to].add(1);
        ownerAddress[_tokenId]=_to;
        emit Transfer(_from, _to, _tokenId);
    }
    
    function _setTokenIPFSHash(uint256 tokenId, string memory _tokenIPFSHash) internal {
    // 46 is the minimum length for an IPFS content hash, it may be longer if paths are used
    require(bytes(_tokenIPFSHash).length >= 46, "NFT721Metadata: Invalid IPFS path");
    require(!creatorToIPFSHashToMinted[msg.sender][_tokenIPFSHash], "NFT721Metadata: NFT was already minted");

    creatorToIPFSHashToMinted[msg.sender][_tokenIPFSHash] = true;
    _setTokenURI(tokenId, _tokenIPFSHash);
  }
  

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ownerAddress[tokenId] != address(0);
    }
    
    
    function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);

    emit Transfer(address(0), to, tokenId);
  }
    
      /**
   * @notice Gets the tokenId of the next NFT minted.
   */
  function getNextTokenId() public view returns (uint256) {
    return nextTokenId;
  }

  /**
   * @dev Called once after the initial deployment to set the initial tokenId.
   */
  function _initializeNFT721Mint() internal  {
    // Use ID 1 for the first NFT tokenId
    nextTokenId = 1;
  }

  Nfts[] public alreadyMinted;
  function mint(string memory tokenIPFSHash, string memory name) public  returns (uint256 tokenId) {
    require(keccak256(abi.encodePacked((name))) != keccak256(abi.encodePacked((""))),"Name cannot be null");
    tokenId = nextTokenId++;
    
    balance[msg.sender]=balance[msg.sender].add(1);
    _mint(msg.sender, tokenId);
    _updateTokenCreator(tokenId, msg.sender);
    _setTokenIPFSHash(tokenId, tokenIPFSHash);

    alreadyMinted.push(Nfts(tokenId,name,tokenIPFSHash));
    emit Minted(msg.sender, tokenId, tokenIPFSHash, tokenIPFSHash);
  }
   
  
  function NftDetails() public view returns(Nfts[] memory) {
     return alreadyMinted;
  }
 
  function burn(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);
    balance[owner] =balance[owner].sub(1);
    delete ownerAddress[tokenId];
    emit Transfer(owner, address(0), tokenId);
}
}