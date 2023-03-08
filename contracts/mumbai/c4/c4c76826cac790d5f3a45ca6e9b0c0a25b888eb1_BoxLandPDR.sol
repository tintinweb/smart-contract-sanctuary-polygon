// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMath.sol";

import "./Land.sol";

contract BoxLandPDR is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMath for uint256;

    event EMintBoxLand(uint256 indexed _tokenId, string _uri, address _to);

    event EAddedUserBlackList(address _by, address indexed _user);
    event ERemovedUserBlackList(address _by, address indexed _user);

    event EAddedNFTBlackList(address _by, uint256 _tokenId);
    event ERemovedNFTBlackList(address _by, uint256 _tokenId);

    uint256 boxPlanSale;
    uint256 priceBox;
    IERC20 token;
    LandPDR land;
    CountersUpgradeable.Counter private boxSales;
    CountersUpgradeable.Counter private unboxes;
    mapping(address => CountersUpgradeable.Counter) public ownerBoxes;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    CountersUpgradeable.Counter private _tokenIdCounter;

    mapping(address => bool) public blackListAccounts;
    mapping(uint256 => bool) public blackListTokens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _owner,
        address _token,
        address _land
    ) public initializer {
        __ERC721_init("My Box Land For Testing", "MBLFT");
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(PAUSER_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _owner);

        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        token = IERC20(_token);
        land = LandPDR(_land);
        boxPlanSale = 10000;
        priceBox = 10 * 10**18; // 5 PDR
    }

    function transferAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_admin != address(0), "ZERO_ADDRESS");
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function buyBox() public returns (uint256) {
        require(boxSales.current() < boxPlanSale, "BOX_SALE_OUT");
        require(!blackListAccounts[msg.sender], "ADDRESS_BLACKLIST");

        token.transferFrom(msg.sender, address(this), priceBox);

        string memory _uri = toURI();
        uint256 _tokenId = _mint(msg.sender, _uri);
        boxSales.increment();
        ownerBoxes[msg.sender].increment();
        emit EMintBoxLand(_tokenId, _uri, msg.sender);
        return _tokenId;
    }

    function toURI() internal pure returns (string memory) {
        return 'https://ipfs.io/ipfs/bafyreic4ebxg3pwyor5uhwp5uge2ozqysi5a5xvbhb6l34hucnbdo22gz4/metadata.json';
    }

    function openBox(uint256 _tokenId) public {
        require(!blackListAccounts[msg.sender], "ADDRESS_BLACKLIST");
        require(ownerBoxes[msg.sender].current() > 0, "USER_NOT_OWN_ANY_BOX");
        require(this.ownerOf(_tokenId) == msg.sender, "NOT_OWNER_NFT");

        ownerBoxes[msg.sender].decrement();
        unboxes.increment();

        // mint nft land
        land.mint(msg.sender);

        // burn nft box
        super._burn(_tokenId);
    }

    function _mint(address _to, string memory _uri) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        return tokenId;
    }

    function setOperatorRole(address _operator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
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

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId, uint256 _batchSize)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        require(!blackListAccounts[_from], "ADDRESS_BLACKLIST");
        require(!blackListTokens[_tokenId], "TOKEN_NFT_BLACKLIST");
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 _tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(_tokenId);
    }

    /**
     * @dev function add user into backlist
     * @param _user account to add
     */
    function addBlackListAccount(address _user) public onlyRole(OPERATOR_ROLE) {
        blackListAccounts[_user] = true;
        emit EAddedUserBlackList(msg.sender, _user);
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
        emit ERemovedUserBlackList(msg.sender, _user);
    }

    /**
     * @dev function add user into backlist
     * @param _tokenId account to add
     */
    function addBlackListToken(uint256 _tokenId)
        public
        onlyRole(OPERATOR_ROLE)
    {
        blackListTokens[_tokenId] = true;
        emit EAddedNFTBlackList(msg.sender, _tokenId);
    }

    /**
     * @dev function remove user in blacklist
     * @param _tokenId account to remove
     */
    function removeBlackListToken(uint256 _tokenId)
        public
        onlyRole(OPERATOR_ROLE)
    {
        blackListTokens[_tokenId] = false;
        emit ERemovedNFTBlackList(msg.sender, _tokenId);
    }

    /**
     * @dev check user in black list
     * @param _user account to check
     */
    function isInBlackListAccount(address _user) public view returns (bool) {
        return blackListAccounts[_user];
    }

    /**
     * @dev check token in black list
     * @param _tokenId account to check
     */
    function isInBlackListToken(uint256 _tokenId) public view returns (bool) {
        return blackListTokens[_tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev function return current verion of smart contract
     */
    function version() public pure returns (string memory) {
        return "v1.0!";
    }
}