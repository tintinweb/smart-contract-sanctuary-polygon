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

import "./PHero.sol";

contract PBoxHero is
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

    event EMintBoxHero(uint256 indexed tokenId, string uri, address to);

    event EAddedUserBlackList(address by, address indexed user);
    event ERemovedUserBlackList(address by, address indexed user);

    event EAddedNFTBlackList(address by, uint256 tokenId);
    event ERemovedNFTBlackList(address by, uint256 tokenId);

    uint256 _boxPlanSale;
    uint256 _priceBox;
    IERC20 _token;
    PHero _hero;
    CountersUpgradeable.Counter private _boxSales;
    CountersUpgradeable.Counter private _unboxes;
    mapping(address => CountersUpgradeable.Counter) public _ownerBoxes;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    CountersUpgradeable.Counter private _tokenIdCounter;

    mapping(address => bool) public _blackListAccounts;
    mapping(uint256 => bool) public _blackListTokens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address owner,
        address token,
        address hero
    ) public initializer {
        __ERC721_init("My Box Hero For Testing", "MBLFT");
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(UPGRADER_ROLE, owner);
        _grantRole(OPERATOR_ROLE, owner);

        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        _token = IERC20(token);
        _hero = PHero(hero);
        _boxPlanSale = 349600;
        _priceBox = 10 * 10**18; // 10 PDR
    }

    function transferAdmin(address admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(admin != address(0), "ZERO_ADDRESS");
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function buyBox() public returns (uint256) {
        require(_boxSales.current() < _boxPlanSale, "BOX_SALE_OUT");
        require(!_blackListAccounts[msg.sender], "ADDRESS_BLACKLIST");

        _token.transferFrom(msg.sender, address(this), _priceBox);

        string memory _uri = toURI();
        uint256 _tokenId = _mint(msg.sender, _uri);
        _boxSales.increment();
        _ownerBoxes[msg.sender].increment();
        emit EMintBoxHero(_tokenId, _uri, msg.sender);
        return _tokenId;
    }

    function toURI() internal pure returns (string memory) {
        return 'https://ipfs.io/ipfs/bafyreic4ebxg3pwyor5uhwp5uge2ozqysi5a5xvbhb6l34hucnbdo22gz4/metadata.json';
    }

    function openBox(uint256 tokenId) public {
        require(!_blackListAccounts[msg.sender], "ADDRESS_BLACKLIST");
        require(_ownerBoxes[msg.sender].current() > 0, "USER_NOT_OWN_ANY_BOX");
        require(this.ownerOf(tokenId) == msg.sender, "NOT_OWNER_NFT");

        _ownerBoxes[msg.sender].decrement();
        _unboxes.increment();

        // mint nft hero
        _hero.mint(msg.sender);

        // burn nft box
        super._burn(tokenId);
    }

    function _mint(address to, string memory uri) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 _tokenId = _tokenIdCounter.current();
        _safeMint(to, _tokenId);
        _setTokenURI(_tokenId, uri);
        return _tokenId;
    }

    function setOperatorRole(address operator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(operator != address(0), "ZERO_ADDRESS");
        _grantRole(OPERATOR_ROLE, operator);
    }

    function removeOperatorRole(address operator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(operator != address(0), "ZERO_ADDRESS");
        _revokeRole(OPERATOR_ROLE, operator);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        require(!_blackListAccounts[from], "ADDRESS_BLACKLIST");
        require(!_blackListTokens[tokenId], "TOKEN_NFT_BLACKLIST");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    /**
     * @dev function add user into backlist
     * @param user account to add
     */
    function addBlackListAccount(address user) public onlyRole(OPERATOR_ROLE) {
        _blackListAccounts[user] = true;
        emit EAddedUserBlackList(msg.sender, user);
    }

    /**
     * @dev function remove user in blacklist
     * @param user account to remove
     */
    function removeBlackListAccount(address user)
        public
        onlyRole(OPERATOR_ROLE)
    {
        _blackListAccounts[user] = false;
        emit ERemovedUserBlackList(msg.sender, user);
    }

    /**
     * @dev function add user into backlist
     * @param tokenId account to add
     */
    function addBlackListToken(uint256 tokenId)
        public
        onlyRole(OPERATOR_ROLE)
    {
        _blackListTokens[tokenId] = true;
        emit EAddedNFTBlackList(msg.sender, tokenId);
    }

    /**
     * @dev function remove user in blacklist
     * @param tokenId account to remove
     */
    function removeBlackListToken(uint256 tokenId)
        public
        onlyRole(OPERATOR_ROLE)
    {
        _blackListTokens[tokenId] = false;
        emit ERemovedNFTBlackList(msg.sender, tokenId);
    }

    /**
     * @dev check user in black list
     * @param user account to check
     */
    function isInBlackListAccount(address user) public view returns (bool) {
        return _blackListAccounts[user];
    }

    /**
     * @dev check token in black list
     * @param tokenId account to check
     */
    function isInBlackListToken(uint256 tokenId) public view returns (bool) {
        return _blackListTokens[tokenId];
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

    function countUnbox() public view returns(uint256) {
        return _unboxes.current();
    }

    function countBoxOf(address owner) public view returns(uint256) {
        return _ownerBoxes[owner].current();
    }

    /**
     * @dev function return current verion of smart contract
     */
    function version() public pure returns (string memory) {
        return "v1.0!";
    }

    /**
     * Allow withdraw of PPP tokens from the contract
     */
    function withdrawLink() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _token.transfer(msg.sender, _token.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}