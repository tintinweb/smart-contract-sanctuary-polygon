// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./VRFV2WrapperConsumerBase.sol";

import "./HeroDetails.sol";

contract PHero is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    AccessControl,
    ERC721Burnable,
    VRFV2WrapperConsumerBase
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using PHeroDetails for PHeroDetails.Details;

    event EAddedUserBlackList(address by, address indexed user);
    event ERemovedUserBlackList(address by, address indexed user);

    event EAddedNFTBlackList(address by, uint256 tokenId);
    event ERemovedNFTBlackList(address by, uint256 tokenId);

    event EAddMiner(address by, address miner);
    event ERemovedMiner(address by, address miner);

    event EMintHero(
        uint256 indexed _tokenId,
        string _uri,
        address _to,
        uint256 _detail
    );

    struct RandomStatus {
        uint256 fees;
        uint256 randomWord;
        address to;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdCounter;
    PHeroDetails.Counter private _counter;

    mapping(uint256 => RandomStatus) public _randResp;
    mapping(uint256 => bool) public _blackListTokens;
    mapping(address => bool) public _blackListAccounts;
    mapping(address => Counters.Counter) public _ownerHeros;
    // key: tokenId, value: encoded attributes
    mapping(uint256 => uint256) public _heroDetails;

    LinkTokenInterface _ILink;

    constructor(
        address owner,
        address link,
        address vrtWrapper
    )
        VRFV2WrapperConsumerBase(link, vrtWrapper)
        ERC721("My Hero For Testing", "MHFT")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);

        _ILink = LinkTokenInterface(link);
        _counter = PHeroDetails.intCounter();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 requestId = requestRandomness(1_000_000, 3, 1);
        _randResp[requestId] = RandomStatus({
            fees: VRF_V2_WRAPPER.calculateRequestPrice(1_000_000),
            randomWord: 0,
            to: to
        });
        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(_randResp[requestId].fees > 0, "REQUEST_NOT_FOUND");
        uint256 seed = randomWords[0];
        _randResp[requestId].randomWord = seed;
        address to = _randResp[requestId].to;
        _mint(to, "", seed);
    }

    function _mint(address to, string memory uri, uint256 seed) internal returns (uint256) {
        require(!_blackListAccounts[to], "ADDRESS_BLACKLIST");
        _tokenIdCounter.increment();
        _ownerHeros[to].increment();
        uint256 tokenId = _tokenIdCounter.current();

        // set hero's attributes from seed
        PHeroDetails.Details memory detail = PHeroDetails.decode(seed);
        detail = PHeroDetails.formatHero(detail, _counter);
        _counter = PHeroDetails.increaseCounter(_counter, detail.opposition, detail.rarity);
        uint256 enc = PHeroDetails.encode(detail, tokenId);
        _heroDetails[tokenId] = enc;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit EMintHero(tokenId, uri, to, enc);
        return tokenId;
    }

    function addMiner(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(minter != address(0), "ZERO_ADDRESS");
        _grantRole(MINTER_ROLE, minter);
        emit EAddMiner(msg.sender, minter);
    }

    function removeMiner(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(minter != address(0), "ZERO_ADDRESS");
        _revokeRole(MINTER_ROLE, minter);
        emit ERemovedMiner(msg.sender, minter);
    }

    /**
     * @dev function add user into backlist
     * @param user account to add
     */
    function addBlackListAccount(address user)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _blackListAccounts[user] = true;
        emit EAddedUserBlackList(msg.sender, user);
    }

    /**
     * @dev function remove user in blacklist
     * @param user account to remove
     */
    function removeBlackListAccount(address user)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
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
        onlyRole(DEFAULT_ADMIN_ROLE)
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
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _blackListTokens[tokenId] = false;
        emit ERemovedNFTBlackList(msg.sender, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        require(!_blackListAccounts[from], "ADDRESS_BLACKLIST");
        require(!_blackListTokens[tokenId], "TOKEN_NFT_BLACKLIST");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

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
            "Unable to transfer"
        );
    }
}