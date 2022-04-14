/**
 *Submitted for verification at polygonscan.com on 2022-04-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IERC721 /* is ERC165 */ {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


contract ERC721 is IERC721 {
    string private _name;
    string private _symbol;
    uint256 tokenCount;
    uint256[] userTokens;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    mapping (address => uint256) _balances;
    mapping (uint256 => address) _owners;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256[]) myTokens;
    
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    // Returns a URL that points to the metadata
    function tokenURI(uint256 tokenId) public view returns (string memory) { // ERC721Metadata
        require(_owners[tokenId] != address(0), "TokenId does not exist");
        return _tokenURIs[tokenId];
    }
    // Creates a new NFT inside our collection

    function mint(string memory _tokenURI) public {

        tokenCount += 1; // tokenId
        _balances[msg.sender] += 1;
        _owners[tokenCount] = msg.sender;
        _tokenURIs[tokenCount] = _tokenURI; 
        myTokens[msg.sender].push(tokenCount);

        emit Transfer(address(0), msg.sender, tokenCount);
    }
    function balanceOf(address _owner) public view override returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balances[_owner];
    }   

    //View my tokens
    function viewMyTokens() public view returns(uint256[] memory){
        return myTokens[msg.sender];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address){
        address owner = _owners[_tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function setApprovalForAll(address _operator, bool _approved) public override {
        require(msg.sender != _operator, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }    

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function getApproved(uint256 _tokenId) public view override returns (address) {
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool){
        return _operatorApprovals[_owner][_operator];
    }
    function approve(address _approved, uint256 _tokenId) public  payable override {
        address owner = _owners[_tokenId];
        require(_approved != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is neither owner nor approved for all"
        );
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);

    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable override {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        require(ERC721.ownerOf(_tokenId) == _from, "ERC721: transfer from incorrect owner");
        require(_to != address(0), "ERC721: transfer to the zero address");
        // Clear approvals from the previous owner
        approve(address(0), _tokenId);
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        myTokens[_to].push(_tokenId);
        emit Transfer(_from, _to, _tokenId);

    }
 // Oversimplified
    function _checkOnERC721Received() private pure returns(bool) {
        return true;
    }

    // EIP165 : Query if a contract implements another interface
    function supportsInterface(bytes4 interfaceId) public pure virtual returns(bool) {
        return interfaceId == 0x80ac58cd;
    }
}