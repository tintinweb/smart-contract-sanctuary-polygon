// SPDX-License-Identifier: NFT

pragma solidity ^0.8.2;

contract ERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _owners;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;

    // @notice : đếm tất cả các Nft của user
    function balanceOf(address owner) external view returns (uint256) {
        // kiểm tra ví được gọi khác ví 0
        require(owner != address(0), "Address is zaro");

        return _balances[owner];
    }

    // tìm chủ sở hữu của Nft
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token ID does not exitst");
        return owner;
    }

    //  set quyền cho operator quản lý Nft
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // kiểm tra xem 1 địa chỉ có là operator của 1 address không
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    // set quyền quản lý cho oprater quản lý 1 Nft
    function approve(address approved, uint256 tokenId) public payable {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "smg.sender is not the owner or the approved opertor"
        );
        _tokenApprovals[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "token ID does not exist");
        return _tokenApprovals[tokenId];
    }

    // chuyến Nft
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        address owner = ownerOf(tokenId);

        require(
            msg.sender == owner ||
                isApprovedForAll(owner, msg.sender) ||
                getApproved(tokenId) == msg.sender,
            "smg.sender is not the owner or the approved opertor"
        );
        require(from == msg.sender, "from address is not the owner");
        require(to != address(0), "address is the zero address");
        require(_owners[tokenId] != address(0), "token ID dose not exist");

        approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = owner;

        emit Transfer(from, to, tokenId);
    }

    // đối tượng nhận Nft là 1 address hoặc 1 smartcontract ,trường hợp là 1 smartcontract thì nó là hàm transfers nhưng thêm kiểm tra xem smart contract có thể nhận Nft không
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable {
        transferFrom(from, to, tokenId);
        require(_checkonERC721Receipt(), "Receipt is not implemented");
    }

    function _checkonERC721Receipt() private pure returns (bool) {
        return true;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {
        safeTransferFrom(from, to, tokenId, "");
    }

    // gọi hàm và truyền vào interfaceID == 0x80ac58cd thì trả về true giúp người gọi biết contract của mình có các hàm như interface miêu tả không
    function supportInterface(bytes4 interfaceID)
        public
        pure
        virtual
        returns (bool)
    {
        return interfaceID == 0x80ac58cd;
    }
}

pragma solidity ^0.8.2;

import "./ERC721.sol";

contract Nft is ERC721 {
  string public name;
  string public symbol;
  mapping(uint256  => string) private _tokenURIs;

  uint public tokenCount;

  constructor (string memory _name, string memory _symbol){
    name = _name;
    name = _symbol;
  }
// tokenURI : trả về đường dẫn URI chỗ mình lưu metadata của NFT, để fon-end lấy đc dữ liệu từ metadata hiện thị lên
  function tokenURI(uint tokenID) public view returns(string memory) {
    require(_owners[tokenID] != address(0), "token ID does not exist");
    return _tokenURIs[tokenID];
  }

  function mint(string memory _tokenURI ) public{
    tokenCount +=1; // tokenID
    _balances[msg.sender] +=1;
    _owners[tokenCount] = msg.sender;
    _tokenURIs[tokenCount] = _tokenURI;
    emit Transfer(address(0), msg.sender, tokenCount);
    
  }

  function supportInterface(bytes4 interfaceID)
        public
        pure
        override
        returns (bool)
    {
        return interfaceID == 0x80ac58cd || interfaceID == 0x5b5e139f;
    }
  
}