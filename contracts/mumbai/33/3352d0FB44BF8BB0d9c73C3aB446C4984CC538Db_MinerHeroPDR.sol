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

contract MinerHeroPDR is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    enum Rarity {
        DEFAULT,
        RARE,
        UNIQUE,
        LEGENDARY,
        EXCELLENT
    }

    event EMintMinerHero(
        uint256 indexed tokenId,
        string uri,
        address to,
        Rarity rarity
    );

    event EAddedUserBlackList(address by, address indexed user);
    event ERemovedUserBlackList(address by, address indexed user);

    event EAddedNFTBlackList(address by, uint256 tokenId);
    event ERemovedNFTBlackList(address by, uint256 tokenId);

    event EAddMiner(address by, address miner);
    event ERemovedMiner(address by, address miner);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _rareCounter;
    Counters.Counter private _uniqueCounter;
    Counters.Counter private _legendaryCounter;
    Counters.Counter private _excellentCounter;

    mapping(uint256 => bool) public _blackListTokens;
    mapping(address => bool) public _blackListAccounts;
    mapping(uint256 => Rarity) public _rarityHeros;
    mapping(address => Counters.Counter) public _ownerHeros;

    uint32 constant RARE_HERO = 152950;
    uint16 constant UNIQUE_HERO = 54625;
    uint16 constant LEGENDARY_HERO = 8740;
    uint16 constant EXCELLENT_HERO = 2185;

    constructor(address owner) ERC721("My Miner Hero For Testing", "MMHFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 rarity)  public onlyRole(MINTER_ROLE) {
        Rarity _rarity = toRare(rarity);
        string memory uri = toURIByRare(_rarity);

        uint256 _tokenId = _mint(to, uri);
        _rarityHeros[_tokenId] = _rarity;
        emit EMintMinerHero(_tokenId, uri, to, _rarity);
    }

    function toURIByRare(Rarity rarity) internal pure returns (string memory) {
        if (rarity == Rarity.EXCELLENT) return 'https://ipfs.io/ipfs/bafyreid4trcdxtqcxvxy27avq4annivlemgkdxmnfxc567dsuzkjchzrf4/metadata.json';
        if (rarity == Rarity.LEGENDARY) return 'https://ipfs.io/ipfs/bafyreiawrpk6fprefkppti3ikbtn7yrqv2yz3bt5slabi45psbtpvcdbga/metadata.json';
        if (rarity == Rarity.UNIQUE) return 'https://ipfs.io/ipfs/bafyreias7gij7y4wwrezmrctypuathtwxrju53n2f4y33tpjnyuasxkmqy/metadata.json';
        return 'https://ipfs.io/ipfs/bafyreihxk5ljazsuzwubts4yl2isbvlxct4idfyebbmuhenznijpu4wjqq/metadata.json';
    }

    function toRare(uint256 rand) internal returns (Rarity) {
        uint256 MAX_INT = uint256(
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        ).div(100);
        if (rand <= MAX_INT.mul(60)) {
            if (_rareCounter.current() < RARE_HERO) {
                _rareCounter.increment(); 
                return Rarity.RARE;
            }
            if (_uniqueCounter.current() < UNIQUE_HERO) {
                _uniqueCounter.increment(); 
                return Rarity.UNIQUE;
            }
            if (_legendaryCounter.current() < LEGENDARY_HERO) {
                _legendaryCounter.increment();
                return Rarity.LEGENDARY;
            }
            if (_excellentCounter.current() < EXCELLENT_HERO) {
                _excellentCounter.increment();
                return Rarity.EXCELLENT;
            }
        }
        if (rand <= MAX_INT.mul(90)) {
            if (_uniqueCounter.current() < UNIQUE_HERO) {
                _uniqueCounter.increment(); 
                return Rarity.UNIQUE;
            }
            if (_rareCounter.current() < RARE_HERO)  {
                _rareCounter.increment(); 
                return Rarity.RARE;
            }
            if (_legendaryCounter.current() < LEGENDARY_HERO) {
                _legendaryCounter.increment();
                return Rarity.LEGENDARY;
            }
            if (_excellentCounter.current() < EXCELLENT_HERO) {
                _excellentCounter.increment();
                return Rarity.EXCELLENT;
            }
        }
        if (rand <= MAX_INT.mul(99)) {
            if (_legendaryCounter.current() < LEGENDARY_HERO) {
                _legendaryCounter.increment();
                return Rarity.LEGENDARY;
            }
            if (_uniqueCounter.current() < UNIQUE_HERO) {
                _uniqueCounter.increment(); 
                return Rarity.UNIQUE;
            }
            if (_rareCounter.current() < RARE_HERO) {
                _rareCounter.increment(); 
                return Rarity.RARE;
            }
            if (_excellentCounter.current() < EXCELLENT_HERO) {
                _excellentCounter.increment();
                return Rarity.EXCELLENT;
            }
        }
        if (_excellentCounter.current() < EXCELLENT_HERO) {
            _excellentCounter.increment();
            return Rarity.EXCELLENT;
        }
        if (_legendaryCounter.current() < LEGENDARY_HERO) {
            _legendaryCounter.increment();
            return Rarity.LEGENDARY;
        }
        if (_uniqueCounter.current() < UNIQUE_HERO) {
            _uniqueCounter.increment(); 
            return Rarity.UNIQUE;
        }
        require(_rareCounter.current() < RARE_HERO, "OUT_OF_LAND");
        _rareCounter.increment(); 
        return Rarity.RARE;
    }

    function _mint(address _to, string memory _uri) internal returns (uint256) {
        require(!_blackListAccounts[_to], "ADDRESS_BLACKLIST");
        _tokenIdCounter.increment();
        _ownerHeros[_to].increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        return tokenId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
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

    function countOwnLand(address owner) public view returns(uint256) {
        return _ownerHeros[owner].current();
    }

    function countSaleLandDetail() public view returns(uint256, uint256, uint256, uint256) {
        return (_rareCounter.current(), _uniqueCounter.current(), _legendaryCounter.current(), _excellentCounter.current());
    }

    function rarityOf(uint256 token_id) public view returns(Rarity) {
        return _rarityHeros[token_id];
    }
}