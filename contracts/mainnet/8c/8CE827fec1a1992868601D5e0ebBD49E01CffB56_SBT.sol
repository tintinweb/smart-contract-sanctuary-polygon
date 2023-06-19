pragma solidity ^0.8.0;

contract SBT {

    string public name;

    string public symbol;

    uint256 public totalSupply;

    //owner token count
    mapping(address => uint256) public ownerTokensCount;

    //token owner
    mapping(uint256 => address) public ownerOf;

    mapping(address => bool) public owners;

    string public contractURI;

    mapping(uint256 => string) private uri;

    bool private locked = false;

    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri);

    modifier noLock() {
        require(!locked, "The lock is locked.");
        locked = true;
        _;
        locked = false;
    }

    modifier checkAdmin() {
        require(owners[msg.sender], "invalid owner");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _contractURI){
        name = _name;
        symbol = _symbol;
        contractURI = _contractURI;
        owners[msg.sender] = true;
    }

    function balanceOf(address _owner) view public returns(uint256 balance){
        balance = ownerTokensCount[_owner];
    }

    function setOwner(address _address, bool admin) external checkAdmin{
        require(msg.sender != _address, "invalid address");
        owners[_address] = admin;
    }

    function setContractURI(string memory _contractURI) external checkAdmin{
        contractURI = _contractURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _uri) external checkAdmin{
        uri[_tokenId] = _uri;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return uri[_tokenId];
    }

    function mintTo(address _to, uint256 _tokenId, string memory _uri) external noLock checkAdmin{
        _mint(_to, _tokenId, _uri);
    }

    function _mint(address _to, uint256 _tokenId, string memory _uri)  internal virtual {
        require(!_isExistTokenId(_tokenId), "token existed");
        //token owner
        ownerOf[_tokenId] = _to;
        //owner token amount++
        ownerTokensCount[_to] = add(ownerTokensCount[_to],1);
        uri[_tokenId] = _uri;
        totalSupply = totalSupply + 1;

        emit TokensMinted(_to, _tokenId, _uri);
    }

    function _isExistTokenId(uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf[_tokenId];
        if (address(0) != owner) {
            return true;
        }
        return false;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

}