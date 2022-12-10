/**
 *Submitted for verification at polygonscan.com on 2022-12-09
*/

pragma solidity >=0.7.0;

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract MiszaMeme is ERC721, ERC165, ERC721Metadata {
    
    mapping (uint256 => address) memeToOwner;
    string memeURI;

    bytes4 public constant IID_IERC165 = type(ERC165).interfaceId;
    bytes4 public constant IID_IERC721 = type(ERC721).interfaceId;
    bytes4 public constant IID_IERC721Metadata = type(ERC721Metadata).interfaceId;

    constructor (string memory _memeURI, uint256 _tokenHash) {
        memeURI = _memeURI;
        memeToOwner[_tokenHash] = msg.sender;
    }

    function name() external view override returns (string memory _name) {
        return "MiszaMeme";
    }

    function symbol() external view override returns (string memory _symbol) {
        return "MiMe";
    }

    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        return memeURI;
    }

    function balanceOf(address _owner) external view override returns(uint256) {
        return 1;
    }

    function ownerOf(uint256 _tokenId) external view override returns(address) {
        return memeToOwner[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external override payable { /* dummy */ }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override payable { /* dummy */ }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override payable {
        require(memeToOwner[_tokenId] == msg.sender);
        memeToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override payable { /* dummy */ }
    function setApprovalForAll(address _operator, bool _approved) external override { /* dummy */ }
    function getApproved(uint256 _tokenId) external view override returns (address) { /* dummy */ }
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) { /* dummy */ }

    function supportsInterface(bytes4 interfaceID) external view override returns (bool) {
        return ((interfaceID == IID_IERC165) || (interfaceID == IID_IERC721) || (interfaceID == IID_IERC721Metadata));
    }
}