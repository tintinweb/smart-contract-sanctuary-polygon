// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract NFT is ERC721, AccessControlEnumerable, ERC721Enumerable, Ownable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    event AddedBlackList(address _by, address indexed _user);
    event RemovedBlackList(address _by, address indexed _user);
    event AddedBlackListToken(address _by, uint256 _tokenId);
    event RemoveBlackListToken(address _by, uint256 _tokenId);
    event AddMiner(address _by, address _miner);
    event RemoveMiner(address _by, address _miner);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(address => bool) public blackListAccounts;
    string private baseTokenURI;
    bool private lockUserMint;

    constructor(
        string memory baseURI
    ) ERC721("Astrozone NFT", "AZN") {
        address _owner = msg.sender;

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(PAUSER_ROLE, _owner);
        _grantRole(MINTER_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _owner);

        lockUserMint = false;
        baseTokenURI = baseURI;
    }

    /*
    @dev _baseURI will return the token uri
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /*
    @dev _baseURI will transfer admin
    */
    function transferAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_admin != address(0), "ZERO_ADDRESS");
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Set token URI
     */
    function updateBaseURI(string calldata baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    modifier whenNotLockMinted() {
        require(!lockUserMint, "Lock mint by user.");
        _;
    }

    function mint(address sender, uint256 tokenId) public whenNotLockMinted {
        require(sender != address(0), "Astro NFT: zero address");
        require(!blackListAccounts[sender], "Astro NFT: address in blacklist");
        require(hasRole(MINTER_ROLE, msg.sender), "Astro NFT: is not minter");

        _safeMint(sender, tokenId);
    }

    function batchMint(address sender, uint256[] memory listTokenId) public whenNotLockMinted {
        require(sender != address(0), "Astro NFT: zero address");
        require(!blackListAccounts[sender], "Astro NFT: address in blacklist");
        require(hasRole(MINTER_ROLE, msg.sender), "Astro NFT: is not minter");

        for (uint i=0; i<listTokenId.length; i++) {
            _safeMint(sender, listTokenId[i]);
        }
    }

    function lockMint(bool _isLock) public onlyRole(OPERATOR_ROLE) {
        require(lockUserMint != _isLock, "SAME_LOCK_USER_MINT");
        lockUserMint = _isLock;
    }

    function addMiner(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minter != address(0), "ZERO_ADDRESS");
        _grantRole(MINTER_ROLE, _minter);
        emit AddMiner(msg.sender, _minter);
    }

    function removeMiner(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minter != address(0), "ZERO_ADDRESS");
        _revokeRole(MINTER_ROLE, _minter);
        emit RemoveMiner(msg.sender, _minter);
    }

    function setOperatorRole(address _operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_operator != address(0), "ZERO_ADDRESS");
        _grantRole(OPERATOR_ROLE, _operator);
    }

    function removeOperatorRole(address _operator)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_operator != address(0), "ZERO_ADDRESS");
        _revokeRole(OPERATOR_ROLE, _operator);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable)  {
        require(!blackListAccounts[_from], "ADDRESS_BLACKLIST");
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function _burn(uint256 tokenId)
    internal
    override(ERC721)
    {
        super._burn(tokenId);
    }

    /**
     * @dev function add user into backlist
     * @param _user account to add
     */
    function addBlackListAccount(address _user) public onlyRole(OPERATOR_ROLE) {
        blackListAccounts[_user] = true;
        emit AddedBlackList(msg.sender, _user);
    }

    /**
     * @dev function remove user in blacklist
     * @param _user account to remove
     */
    function removeBlackListAccount(address _user)
    public
    onlyRole(OPERATOR_ROLE)
    {
        blackListAccounts[_user] = false;
        emit AddedBlackList(msg.sender, _user);
    }

    /**
     * @dev check user in black list
     * @param _user account to check
     */
    function isInBlackListAccount(address _user) public view returns (bool) {
        return blackListAccounts[_user];
    }

    function tokenURI(uint256 tokenId)  public view virtual override(ERC721) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControlEnumerable, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}