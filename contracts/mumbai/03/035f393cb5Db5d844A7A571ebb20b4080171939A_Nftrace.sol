// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Nftrace {

    string private name;
    string private symbol;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    struct Nft{
        uint TokenId;
        address Address;
        string ShipmentName;
        string Owner;
        string CreatedBy;
        uint CreatedDate;
        string ImageURI;
        string Approved;
        string Description;
        string[] Stakeholders;
        Md MetaData;
    }

    struct Md{
        string key1;
        string key2;
    }

    Md public md;
    Nft public nft;    

    mapping(uint => Nft) public nftData;
    mapping(uint => address)private owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;

    mapping(address => uint) private Balance;

    event minted(
    uint TokenId,
    address Address,
    string ShipmentName,
    string Owner,
    string CreatedBy,
    uint CreatedDate,
    string ImageURI,
    string Approved,
    string Description,
    string[] Stakeholders,
    Md MetaData
    );

    event updated(
    uint TokenId,
    string ShipmentName,
    string Owner,
    string CreatedBy,
    string ImageURI,
    string Approved,
    string Description,
    string[] Stakeholders,
    Md MetaData
    );

    event Approval(
    address owner,
    address operator,
    uint tokenId
    );

    event ApprovalForAll(
    address owner,
    address operator,
    bool approved
    );

    event transferred(
        address From,
        address To,
        uint TokenId
    );

    // constructor() ERC721("nftrace", "nftrace") {}

    function NftExists(uint256 tokenId) internal view virtual returns (bool) {
        return OwnerOf(tokenId) != address(0);
    }

    function MintNft(uint _tokenId, string memory _shipmentName, string memory _owner, string memory _createdBy, string memory _imageURI, string memory _approved, string memory _description, string[] memory _stakeholders, string memory _key1, string memory _key2) public {
        require(!NftExists(_tokenId), "ERC721: token already minted");
        owners[_tokenId]=msg.sender;
        uint _createdDate = block.timestamp;
        md.key1 = _key1;
        md.key2 = _key2;
        nftData[_tokenId] =  Nft(_tokenId, msg.sender, _shipmentName, _owner, _createdBy, _createdDate, _imageURI, _approved, _description, _stakeholders, md);
        emit minted(_tokenId, msg.sender, _shipmentName, _owner, _createdBy, _createdDate, _imageURI, _approved, _description, _stakeholders, md);
    }

    function UpdateNft(uint _tokenId, string memory _shipmentName, string memory _owner, string memory _createdBy, string memory _imageURI, string memory _approved, string memory _description, string[] memory _stakeholders, string memory _key1, string memory _key2) public {
        require(NftExists(_tokenId), "TokenId doesn't exist");
        nft.TokenId = _tokenId;
        nft.ShipmentName = _shipmentName;
        nft.Owner = _owner;
        nft.CreatedBy = _createdBy;
        nft.CreatedDate = block.timestamp;
        nft.ImageURI = _imageURI;
        nft.Approved = _approved;
        nft.Description = _description;
        nft.Stakeholders = _stakeholders;
        md.key1 = _key1;
        md.key2 = _key2;
        nft.MetaData = md;
        nftData[_tokenId] = nft;

        emit updated(_tokenId, _shipmentName, _owner, _createdBy, _imageURI, _approved, _description, _stakeholders, md);
    }

    function approve(address _operator,uint _tokenId) public {
    require(_operator != owners[_tokenId], "ERC721: approval to current owner");

        require(
            msg.sender == owners[_tokenId] || isApprovedForAll(owners[_tokenId], msg.sender),
            "ERC721: approve caller is not token owner or approved for all"
        );

        tokenApprovals[_tokenId] = _operator;
        emit Approval(msg.sender, _operator, _tokenId);
    }

    function setApprovalForAll(address _owner, address _operator, bool _approved) public {
        require(_owner != _operator, "ERC721: approve to caller");
        operatorApprovals[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(NftExists(_tokenId), "ERC721: invalid token ID");

        return tokenApprovals[_tokenId];
    }

    function TransferFrom(address _from,address payable _to,uint _tokenId)public payable{
        require(msg.sender == owners[_tokenId]);
        owners[_tokenId] = _to;
        emit transferred(_from, _to, _tokenId);
    }   

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function OwnerOf(uint TokenId) public view returns(address){
        return(owners[TokenId]);
    }

    function BalanceOf(address _owner) public view returns(uint){
        return(Balance[_owner]);
    }

    function GetName() public view returns (string memory) {
        return name;
    }

    function GetSymbol() public view returns (string memory) {
        return symbol;
    }

    function TokenURI(uint _tokenId) public view returns(string memory){
        require(NftExists(_tokenId), "TokenId doesn't exist");
        return string (abi.encodePacked(nft.ShipmentName, _tokenId));
    }

}