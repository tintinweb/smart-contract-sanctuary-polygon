// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./VRFV2WrapperConsumerBase.sol";

import "./MinerHero.sol";
import "./WarriorHero.sol";

contract BoxHeroPDR is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    AccessControl,
    ERC721Burnable,
    VRFV2WrapperConsumerBase
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    enum HeroType {
        DEFAULT,
        MINER,
        WARRIOR
    }

    event EMintBoxHero(
        uint256 indexed tokenId,
        string uri,
        address to
    );

    event EAddedUserBlackList(address by, address indexed user);
    event ERemovedUserBlackList(address by, address indexed user);

    event EAddedNFTBlackList(address by, uint256 tokenId);
    event ERemovedNFTBlackList(address by, uint256 tokenId);

    event EAddMiner(address by, address miner);
    event ERemovedMiner(address by, address miner);

    struct RandomStatus {
        uint256 fees;
        uint256 randomWord;
        uint256 tokenId;
        address to;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _minerCounter;
    Counters.Counter private _warriorCounter;

    Counters.Counter public _boxSales;
    Counters.Counter public _unboxes;

    mapping(address => Counters.Counter) public _ownerBoxes;

    mapping(uint256 => RandomStatus) public _randStatuses;
    mapping(uint256 => bool) public _blackListTokens;
    mapping(address => bool) public _blackListAccounts;

    uint256 _priceBox;

    uint32 constant MINER_BOX = 218500;
    uint32 constant WARRIOR_BOX = 218500;

    IERC20 _token;
    MinerHeroPDR _minerHero;
    WarriorHeroPDR _warriorHero;
    LinkTokenInterface _ILink;

    constructor(
        address owner,
        address token,
        address minerHero,
        address warriorHero,
        address link,
        address vrtWrapper
    )
        VRFV2WrapperConsumerBase(link, vrtWrapper)
        ERC721("My Box Hero For Testing", "MBHFT")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);

        _token = IERC20(token);
        _minerHero = MinerHeroPDR(minerHero);
        _warriorHero = WarriorHeroPDR(warriorHero);
        _ILink = LinkTokenInterface(link);
        _priceBox = 10 * 10**18; // 10 PDR
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function buyBox() public returns(uint256) {
        require(_boxSales.current() < MINER_BOX + WARRIOR_BOX, "BOX_SALE_OUT");
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

    function openBox(uint256 _tokenId) public returns(uint256) {
        require(!_blackListAccounts[msg.sender], "ADDRESS_BLACKLIST");
        require(_ownerBoxes[msg.sender].current() > 0, "USER_NOT_OWN_ANY_BOX");
        require(this.ownerOf(_tokenId) == msg.sender, "NOT_OWNER_NFT");

        _ownerBoxes[msg.sender].decrement();
        _unboxes.increment();

        uint256 _requestId = requestRandomness(1_000_000, 3, 1);
        _randStatuses[_requestId] = RandomStatus({
            fees: VRF_V2_WRAPPER.calculateRequestPrice(1_000_000),
            randomWord: 0,
            to: msg.sender,
            tokenId: _tokenId
        });
        return _requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(_randStatuses[requestId].fees > 0, "REQUEST_NOT_FOUND");
        _randStatuses[requestId].randomWord = randomWords[0];
        HeroType heroType = toHeroType(randomWords[0]);
        address _to = _randStatuses[requestId].to;
        uint256 _tokenId = _randStatuses[requestId].tokenId;
        
        if (heroType == HeroType.MINER) _minerHero.mint(_to, randomWords[0]);
        else _warriorHero.mint(_to, randomWords[0]);
        super._burn(_tokenId);
    }

    function toHeroType(uint256 rand) internal returns(HeroType) {
        uint256 MAX_INT = uint256(
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        ).div(100);
        if (rand >= MAX_INT.mul(50)) {
            if (_minerCounter.current() < MINER_BOX) {
                _minerCounter.increment();
                return HeroType.MINER;
            }
        }
        require(_warriorCounter.current() < WARRIOR_BOX, "OUT_OF_BOX");
        _warriorCounter.increment();
        return HeroType.WARRIOR;
    }

    function _mint(address _to, string memory _uri) internal returns (uint256) {
        require(!_blackListAccounts[_to], "ADDRESS_BLACKLIST");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        return tokenId;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId, uint256 _batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        require(!_blackListAccounts[_from], "ADDRESS_BLACKLIST");
        require(!_blackListTokens[_tokenId], "TOKEN_NFT_BLACKLIST");
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
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

    /**
     * @dev function add user into backlist
     * @param _user account to add
     */
    function addBlackListAccount(address _user)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _blackListAccounts[_user] = true;
        emit EAddedUserBlackList(msg.sender, _user);
    }

    /**
     * @dev function remove user in blacklist
     * @param _user account to remove
     */
    function removeBlackListAccount(address _user)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _blackListAccounts[_user] = false;
        emit ERemovedUserBlackList(msg.sender, _user);
    }

    /**
     * @dev function add user into backlist
     * @param _tokenId account to add
     */
    function addBlackListToken(uint256 _tokenId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _blackListTokens[_tokenId] = true;
        emit EAddedNFTBlackList(msg.sender, _tokenId);
    }

    /**
     * @dev function remove user in blacklist
     * @param _tokenId account to remove
     */
    function removeBlackListToken(uint256 _tokenId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _blackListTokens[_tokenId] = false;
        emit ERemovedNFTBlackList(msg.sender, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _ILink.transfer(msg.sender, _ILink.balanceOf(address(this))),
            "UNABLE_TO_TRANSFER"
        );
    }
}