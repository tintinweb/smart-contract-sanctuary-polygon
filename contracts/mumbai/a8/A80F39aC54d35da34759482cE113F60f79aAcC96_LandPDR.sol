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

contract LandPDR is
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

    event EMintLand(
        uint256 indexed _tokenId,
        string _uri,
        address _to,
        uint8 _rarity
    );

    event EAddedUserBlackList(address _by, address indexed _user);
    event ERemovedUserBlackList(address _by, address indexed _user);

    event EAddedNFTBlackList(address _by, uint256 _tokenId);
    event ERemovedNFTBlackList(address _by, uint256 _tokenId);

    event EAddMiner(address _by, address _miner);
    event ERemovedMiner(address _by, address _miner);

    struct RandomStatus {
        uint256 fees;
        uint256 randomWord;
        address to;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private tokenIdCounter;
    Counters.Counter private rare1Counter;
    Counters.Counter private rare2Counter;
    Counters.Counter private rare3Counter;
    Counters.Counter private rare4Counter;

    mapping(uint256 => RandomStatus) public randStatuses;
    mapping(uint256 => bool) public blackListTokens;
    mapping(uint256 => uint8) public rarityLands;
    mapping(address => bool) public blackListAccounts;
    mapping(address => Counters.Counter) public ownerLands;

    uint16 constant maxRare1 = 7500;
    uint16 constant maxRare2 = 2000;
    uint16 constant maxRare3 = 400;
    uint16 constant maxRare4 = 100;

    LinkTokenInterface ILink;

    constructor(
        address _owner,
        address _link,
        address _vrtWrapper
    )
        VRFV2WrapperConsumerBase(_link, _vrtWrapper)
        ERC721("My Land For Testing", "MLFT")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(PAUSER_ROLE, _owner);
        _grantRole(MINTER_ROLE, _owner);

        ILink = LinkTokenInterface(_link);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address _to)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 _requestId = requestRandomness(1_000_000, 3, 1);
        randStatuses[_requestId] = RandomStatus({
            fees: VRF_V2_WRAPPER.calculateRequestPrice(1_000_000),
            randomWord: 0,
            to: _to
        });
        return _requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(randStatuses[_requestId].fees > 0, "Request not found");
        randStatuses[_requestId].randomWord = _randomWords[0];
        uint8 rarity = toRare(_randomWords[0]);
        address to = randStatuses[_requestId].to;
        string memory uri = toURIByRare(rarity);

        uint256 _tokenId = _mint(to, uri);
        rarityLands[_tokenId] = rarity;
        emit EMintLand(_tokenId, uri, to, rarity);
    }

    function toURIByRare(uint8 rarity) internal pure returns (string memory) {
        if (rarity == 4) return 'https://ipfs.io/ipfs/bafyreid4trcdxtqcxvxy27avq4annivlemgkdxmnfxc567dsuzkjchzrf4/metadata.json';
        if (rarity == 3) return 'https://ipfs.io/ipfs/bafyreiawrpk6fprefkppti3ikbtn7yrqv2yz3bt5slabi45psbtpvcdbga/metadata.json';
        if (rarity == 2) return 'https://ipfs.io/ipfs/bafyreias7gij7y4wwrezmrctypuathtwxrju53n2f4y33tpjnyuasxkmqy/metadata.json';
        return 'https://ipfs.io/ipfs/bafyreihxk5ljazsuzwubts4yl2isbvlxct4idfyebbmuhenznijpu4wjqq/metadata.json';
    }

    function toRare(uint256 rand) internal view returns (uint8) {
        uint256 MAX_INT = uint256(
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        ).div(100);
        if (rand <= MAX_INT.mul(60)) {
            if (rare1Counter.current() < maxRare1) return 1;
            if (rare2Counter.current() < maxRare2) return 2;
            if (rare3Counter.current() < maxRare3) return 3;
            if (rare4Counter.current() < maxRare4) return 4;
        }
        if (rand <= MAX_INT.mul(90)) {
            if (rare2Counter.current() < maxRare2) return 2;
            if (rare1Counter.current() < maxRare1) return 1;
            if (rare3Counter.current() < maxRare3) return 3;
            if (rare4Counter.current() < maxRare4) return 4;
        }
        if (rand <= MAX_INT.mul(99)) {
            if (rare3Counter.current() < maxRare3) return 3;
            if (rare2Counter.current() < maxRare2) return 2;
            if (rare1Counter.current() < maxRare1) return 1;
            if (rare4Counter.current() < maxRare4) return 4;
        }
        if (rare4Counter.current() < maxRare4) return 4;
        if (rare3Counter.current() < maxRare3) return 3;
        if (rare2Counter.current() < maxRare2) return 2;
        return 1;
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
        blackListAccounts[_user] = true;
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
        blackListAccounts[_user] = false;
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
        blackListTokens[_tokenId] = true;
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
        blackListTokens[_tokenId] = false;
        emit ERemovedNFTBlackList(msg.sender, _tokenId);
    }

    function _mint(address _to, string memory _uri) internal returns (uint256) {
        require(!blackListAccounts[_to], "ADDRESS_BLACKLIST");
        tokenIdCounter.increment();
        ownerLands[_to].increment();
        uint256 tokenId = tokenIdCounter.current();
        rarityLands[tokenId] = 1;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        return tokenId;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId, uint256 _batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        require(!blackListAccounts[_from], "ADDRESS_BLACKLIST");
        require(!blackListTokens[_tokenId], "TOKEN_NFT_BLACKLIST");
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
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
            ILink.transfer(msg.sender, ILink.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}