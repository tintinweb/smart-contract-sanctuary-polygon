// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./SafeMath.sol";

contract Hero is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMath for uint256;

    event EMintHero(
        uint256 indexed _tokenId,
        address _by,
        string _uri,
        address _to
    );
    event EMintsHero(uint16 _batchMint, string _uri);

    event EAddedUserBlackList(address _by, address indexed _user);
    event ERemovedUserBlackList(address _by, address indexed _user);

    event EAddedNFTBlackList(address _by, uint256 _tokenId);
    event ERemovedNFTBlackList(address _by, uint256 _tokenId);

    event EAddMiner(address _by, address _miner);
    event ERemovedMiner(address _by, address _miner);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    CountersUpgradeable.Counter private _tokenIdCounter;

    mapping(address => bool) public blackListAccounts;
    mapping(uint256 => bool) public blackListTokens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _owner) public initializer {
        __ERC721_init("My Hero For Testing", "MHFT");
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(PAUSER_ROLE, _owner);
        _grantRole(MINTER_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _owner);

        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
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

    function mint(address to, string memory uri)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 _tokenId = _mint(to, uri);
        emit EMintHero(_tokenId, msg.sender, uri, to);
        return _tokenId;
    }

    function mints(uint16 batchMint, string memory uri)
        public
        onlyRole(MINTER_ROLE)
    {
        require(batchMint > 0, "ZERO_NUMBER_OF_MINT_AMOUNT");
        for (uint16 i = 0; i < batchMint; i++) {
            _mint(msg.sender, uri);
        }
        emit EMintsHero(batchMint, uri);
    }

    function _mint(address _to, string memory _uri) internal returns (uint256) {
        require(!blackListAccounts[_to], "ADDRESS_BLACKLIST");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        return tokenId;
    }

    function addMiner(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minter != address(0), "ZERO_ADDRESS");
        _grantRole(MINTER_ROLE, _minter);
        emit EAddMiner(msg.sender, _minter);
    }

    function removeMiner(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minter != address(0), "ZERO_ADDRESS");
        _revokeRole(MINTER_ROLE, _minter);
        emit ERemovedMiner(msg.sender, _minter);
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

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override whenNotPaused {
        require(!blackListAccounts[_from], "ADDRESS_BLACKLIST");
        require(!blackListTokens[_tokenId], "TOKEN_NFT_BLACKLIST");
        super._beforeTokenTransfer(_from, _to, _tokenId);
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
        override(ERC721Upgradeable, AccessControlUpgradeable)
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