// SPDX-License-Identifier: CC-BY-NC-4.0

pragma solidity 0.8.16;

import "./ERC721Round/ERC721Round.sol";
import "./IEscrowManager.sol";
import "./IEscrow.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
import "./IHallOfFame.sol";
import "./OpenSeaPolygonProxy.sol";

contract Schneeballschlacht is
    ISchneeballschlacht,
    ERC721Round,
    Pausable,
    ContextMixin,
    NativeMetaTransaction,
    AccessControl
{
    using Strings for uint8;
    // ~3 min at 1 Block / 2 secs, block times vary slightly from 2 secs
    uint16 private immutable TIMEOUT_BLOCK_LENGTH; // 43200; // 24h => 43200
    uint8 private immutable COOLDOWN_BLOCK_LENGTH; // 90; // 3 mins => 90
    uint8 private immutable MAX_LEVEL;
    bool private _finished;
    uint256 private constant MINT_FEE = 0.05 ether;
    uint256 private constant TOSS_FEE = 0.01 ether;

    IHallOfFame private immutable _hof;
    IEscrowManager private immutable _escrowManager;
    address private _proxyRegistryAddress;

    string private _baseURI;
    string private _contractURI;
    string private _folderCID;

    // Mapping roundId to tokenId to snowball
    mapping(uint256 => mapping(uint256 => Snowball)) private _snowballs;

    /**
     * @dev Mapping from tokenId to address.
     * Used for keeping track who the last holder of a snowball was.
     * So that events are logged correctly when a snowball is minted a new owner arises in the current round
     */
    mapping(uint256 => address) private _lastHolder;

    // Mapping roundId to totalTosses
    mapping(uint256 => uint256) private _tosses;

    // map holder address to timeout start blocknumber, defaults to 0
    mapping(address => uint256) private _timeoutStart;

    // map holder address to cooldown start blocknumber, defaults to 0
    mapping(address => uint256) private _cooldownStart;

    event Toss(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event LevelUp(uint256 indexed roundId, uint256 indexed tokenId);
    event Timeout(
        address indexed from,
        uint256 indexed tokenId,
        address indexed to
    );

    constructor(
        address hof,
        address escrowManager,
        uint8 maxLevel,
        string memory baseURI,
        string memory __contractURI,
        address proxyRegistryAddress,
        uint16 timeoutLength,
        uint8 coolDownlength
    ) ERC721Round("Schneeballschlacht", "Schneeball") {
        _pause();
        _hof = IHallOfFame(hof);
        _escrowManager = IEscrowManager(escrowManager);
        _finished = false;
        _baseURI = baseURI;
        _contractURI = __contractURI;
        _proxyRegistryAddress = proxyRegistryAddress;
        MAX_LEVEL = maxLevel;
        TIMEOUT_BLOCK_LENGTH = timeoutLength;
        COOLDOWN_BLOCK_LENGTH = coolDownlength;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier whenFinished() {
        require(_finished, "Finished");
        _;
    }

    modifier isTransferable(uint256 tokenId, address to) {
        uint256 roundId = getRoundId();
        uint256[] memory partners = _snowballs[roundId][tokenId].partners;
        for (uint256 index; index < partners.length; index++) {
            require(ownerOf(partners[index]) != to, "No double transfer");
        }
        _;
    }

    modifier senderNotTimeoutedOrOnCooldown() {
        uint256 roundStart = getStartHeight();
        require(
            _timeoutStart[msg.sender] + TIMEOUT_BLOCK_LENGTH <= block.number ||
                _timeoutStart[msg.sender] <= roundStart,
            "Timeout"
        );
        require(
            _cooldownStart[msg.sender] + COOLDOWN_BLOCK_LENGTH <=
                block.number ||
                _cooldownStart[msg.sender] <= roundStart,
            "Cooldown"
        );
        _;
    }

    /**
     * @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Returns level from the current round.
     */
    function getLevel(uint256 tokenId) external view returns (uint8) {
        uint256 roundId = getRoundId();
        return _snowballs[roundId][tokenId].level;
    }

    function getLevel(uint256 roundId, uint256 tokenId)
        external
        view
        returns (uint8)
    {
        return _snowballs[roundId][tokenId].level;
    }

    /**
     * @dev Returns snowball from id in the current round.
     * @param tokenId, utint256
     */
    function getSnowball(uint256 tokenId)
        external
        view
        returns (Snowball memory)
    {
        uint256 roundId = getRoundId();
        return _snowballs[roundId][tokenId];
    }

    function getSnowball(uint256 roundId, uint256 tokenId)
        external
        view
        returns (Snowball memory)
    {
        return _snowballs[roundId][tokenId];
    }

    /**
     * @dev External function to return list of partner tokenIds
     *
     * @param tokenId uint256 ID of the token to be transferred
     */
    function getPartnerTokenIds(uint256 tokenId)
        external
        view
        returns (uint256[] memory)
    {
        uint256 roundId = getRoundId();
        return getPartnerTokenIds(roundId, tokenId);
    }

    function getPartnerTokenIds(uint256 roundId, uint256 tokenId)
        public
        view
        returns (uint256[] memory)
    {
        uint256 amountOfPartners = _snowballs[roundId][tokenId].partners.length;
        uint256[] memory partners = new uint256[](amountOfPartners);
        for (uint256 i; i < amountOfPartners; i++) {
            partners[i] = _snowballs[roundId][tokenId].partners[i];
        }
        return partners;
    }

    /**
     * @dev External function to return list of snowballs owned by addr
     *
     * @param addr address of the owner to view
     */
    function getSnowballsOfAddress(address addr)
        external
        view
        returns (Snowball[] memory)
    {
        return getSnowballsOfAddress(getRoundId(), addr);
    }

    function getSnowballsOfAddress(uint256 round, address addr)
        public
        view
        returns (Snowball[] memory)
    {
        uint256 amount = balanceOf(round, addr);
        Snowball[] memory snowballs = new Snowball[](amount);

        for (uint256 index; index < amount; index++) {
            snowballs[index] = _snowballs[round][
                getTokenOwner(round, addr, index)
            ];
        }

        return snowballs;
    }

    function getTokens(uint256 page, uint256 amount)
        external
        view
        returns (Query[] memory)
    {
        uint256 roundId = getRoundId();
        return getTokens(roundId, page, amount);
    }

    function getTokens(
        uint256 roundId,
        uint256 page,
        uint256 amount
    ) public view returns (Query[] memory) {
        uint256 total = totalSupply(roundId) - 1;
        uint256 from = (amount * page) + 1;
        require(from < total, "Out of bounds");
        uint256 to = from + amount <= total ? from + amount : total;
        uint256 i;
        Query[] memory result = new Query[](to - from + 1);
        for (uint256 tokenId = from; tokenId <= to; tokenId++) {
            uint8 level = _snowballs[roundId][tokenId].level;
            // length is uint256 but we can cast to uint8 because max(length) === MAX_LEVEL
            uint8 partnerCount = uint8(
                _snowballs[roundId][tokenId].partners.length
            );
            bool snowballHasStone = _snowballs[roundId][tokenId].hasStone;
            address player = ownerOf(tokenId);
            Query memory query = Query({
                player: player,
                tokenId: tokenId,
                level: level,
                partnerCount: partnerCount,
                hasStone: snowballHasStone
            });
            result[i++] = query;
        }
        return result;
    }

    modifier whenNotFinished() {
        if (block.number >= getEndHeight()) {
            _end();
        }
        require(!_finished, "Finished");
        _;
    }

    /**
     * @dev Function to mint a snowball
     *
     * @param to address to send the snowball to
     */
    function mint(address to) public payable whenNotFinished whenNotPaused {
        require(msg.value == MINT_FEE, "Insufficient fee");
        _mint(to, 1, 0);
    }

    /**
     * @dev Function to initialize a new round. Reverts when a round is already running.
     * The address calling the function is granted a free snowball.
     */
    function startRound() external override(ISchneeballschlacht) whenPaused {
        _unpause();
        _startRound();
        _mint(msg.sender, 1, 0);
    }

    /**
     * @dev Function to end a round. Reverts when a round is not finished.
     * endRound
     */
    function endRound() external override(ISchneeballschlacht) whenFinished {
        _finished = false;
        uint256 totalPayout;
        uint256 bonusLevels;
        uint256 payoutPerToss;
        (totalPayout, bonusLevels, payoutPerToss) = _processPayout();
        _endRound(totalPayout, bonusLevels, payoutPerToss);
    }

    /**
     * @dev Function to toss a snowball to a different address.
     * Calling conditions:
     *  - The correct amount of fee must be present
     *  - The tokenId must be owned by the sender
     *  - The address to toss to must be different from previous address tossed to
     *
     * If a snowball of level n has been thrown at n + 1 unique addresses,
     * then a random address is chosen to mint an upgraded snowball to.
     * The random address is chosen by the partners including the thrower.
     *
     * If a snowball would be upgrading to max level,
     * then after the sender receives the final snowball the game finishes
     * and the mint, toss and transfer functions are paused.
     *
     *
     * @param to address to toss the snowball to.
     * @param tokenId snowball to toss
     */
    function toss(address to, uint256 tokenId)
        external
        payable
        whenNotFinished
        whenNotPaused
        isTransferable(tokenId, to)
        senderNotTimeoutedOrOnCooldown
    {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(to != msg.sender, "Self Toss");
        require(to != address(0), "zero address");
        uint256 roundId = getRoundId();
        uint8 level = _snowballs[roundId][tokenId].level;
        require(msg.value == TOSS_FEE * level, "Insufficient fee");

        uint256 newTokenId = _mint(to, level, tokenId);
        _snowballs[roundId][tokenId].partners.push(newTokenId);
        _tosses[roundId]++;
        _cooldownStart[msg.sender] = block.number;

        uint256 amountOfPartners = _snowballs[roundId][tokenId].partners.length;
        require(amountOfPartners <= level + 1, "No throws left");

        if (hasStone(level)) {
            _timeoutStart[to] = block.number;
            _snowballs[roundId][tokenId].hasStone = true;
            emit Timeout(msg.sender, tokenId, to);
        }

        // Next level up also mints randomly
        if (level + 1 < MAX_LEVEL && amountOfPartners == level + 1) {
            _levelup(tokenId);
        }
        // Last snowball is minted => game is over
        else if (level < MAX_LEVEL && amountOfPartners == level + 1) {
            // End Game
            _mint(msg.sender, MAX_LEVEL, tokenId);
            _finish();
        }
        emit Toss(msg.sender, to, tokenId);
    }

    /**
     * @dev Each transfer function from ERC721 has been overridden so it will be paused when a round is finished.
     *
     * @param from address
     * @param to address
     * @param tokenId uint256
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Round) whenNotFinished whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Round) whenNotFinished whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721Round) whenNotFinished whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Returns the amount of tosses made in the current round
     */
    function totalTosses() external view returns (uint256) {
        uint256 roundId = getRoundId();
        return _tosses[roundId];
    }

    /**
     * @dev Returns the amount of tosses made in the round
     *
     * @param roundId uint256
     */
    function totalTosses(uint256 roundId) external view returns (uint256) {
        return _tosses[roundId];
    }

    /**
     * @dev Returns the total supply of the current round
     */
    function totalSupply()
        public
        view
        override(ERC721Round, ISchneeballschlacht)
        returns (uint256)
    {
        return ERC721Round.totalSupply();
    }

    /**
     * @dev Returns the total supply of the give roundId
     *
     * @param roundId uint256
     */
    function totalSupply(uint256 roundId)
        public
        view
        override(ERC721Round, ISchneeballschlacht)
        returns (uint256)
    {
        return ERC721Round.totalSupply(roundId);
    }

    /**
     * @dev Returns the URI of the token based of its level
     *
     * @param tokenId uint256
     * @param roundId uint256
     */
    function tokenURI(uint256 roundId, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseURI,
                    "/",
                    _snowballs[roundId][tokenId].level.toString()
                )
            );
    }

    /**
     * @dev Returns the URI of the token based of its level
     *
     * @param tokenId uint256
     */
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        uint256 roundId = getRoundId();
        return
            string(
                abi.encodePacked(
                    _baseURI,
                    "/",
                    _snowballs[roundId][tokenId].level.toString()
                )
            );
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string memory __baseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseURI = __baseURI;
    }

    function setContractCID(string memory __contractURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _contractURI = __contractURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Round, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal function for handling mint
     *
     * @param to address
     */
    function _mint(
        address to,
        uint8 level,
        uint256 parentSnowballId
    ) internal returns (uint256) {
        uint256 roundId = getRoundId();
        uint256 tokenId = _newTokenId();
        _safeMint(to, tokenId);
        _snowballs[roundId][tokenId] = Snowball({
            hasStone: false,
            level: level,
            partners: new uint256[](0),
            parentSnowballId: parentSnowballId
        });
        address lastHolder = _lastHolder[tokenId];
        _lastHolder[tokenId] = to;
        emit Transfer(lastHolder, to, tokenId);
        return tokenId;
    }

    /**
     * @dev Internal function for handling level up
     * Function will level up as long as the next level is not max level,
     * because it has to be garanteed that the address achieving max level gets the max level snowball
     *
     * @param tokenId uint256
     */
    function _levelup(uint256 tokenId) internal {
        uint256 roundId = getRoundId();
        uint256 amountOldPartners = _snowballs[roundId][tokenId]
            .partners
            .length;
        uint256[] memory partners = new uint256[](amountOldPartners + 1);
        for (uint256 i; i < amountOldPartners; i++) {
            partners[i] = _snowballs[roundId][tokenId].partners[i];
        }
        partners[partners.length - 1] = tokenId;

        uint256 randIndex = _randomIndex(partners.length);
        uint256 randToken = partners[randIndex];
        uint8 level = _snowballs[roundId][tokenId].level;
        // toss handles level up to max since it ends the game
        // otherwise level up in here
        if (level + 1 < MAX_LEVEL) {
            uint256 upgradedTokenId = _mint(ownerOf(randToken), level + 1, tokenId);
            emit LevelUp(roundId, upgradedTokenId);
        }
    }

    /**
     * @dev Internal function for handling the end of a round.
     * Winner is minted a reward NFT
     */
    function _finish() internal {
        _end();
        _setWinner(msg.sender);
        _hof.mint(msg.sender);
    }

    function _end() internal {
        _pause();
        _finished = true;
    }

    /**
     * @dev Pseudo-random generator.
     *
     * @param length uint256
     */
    function _randomIndex(uint256 length) internal view returns (uint256) {
        bytes32 hashValue = keccak256(
            abi.encodePacked(
                msg.sender,
                blockhash(block.number - 1),
                block.number,
                block.timestamp,
                block.difficulty
            )
        );
        return uint256(hashValue) % length;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Internal function for handling the payout to each address owning a snowball
     * Payout is based on the tosses made by a snowball
     */
    function _processPayout()
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 round = getRoundId();
        IEscrow escrow = _escrowManager.createEscrow(round, this);
        uint256 total = _tosses[round];
        // 1% of total is bonus for the winner
        uint256 bonusForWinner = max(total / 100, 1);
        total += bonusForWinner;
        // max total wei are leftover each round for the next round
        uint256 payoutPerToss = address(this).balance / total;
        // because there is leftover wei we need to make sure we only transfer to escrow what is needed
        uint256 totalPayout = total * payoutPerToss;
        escrow.deposit{value: totalPayout}();
        return (totalPayout, bonusForWinner, payoutPerToss);
    }

    /**
     * @dev This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function isTimedOut(address addr) external view returns (bool) {
        uint256 roundStart = getStartHeight();
        return
            !(_timeoutStart[addr] + TIMEOUT_BLOCK_LENGTH <= block.number ||
                _timeoutStart[addr] <= roundStart);
    }

    function isOnCooldown(address addr) external view returns (bool) {
        uint256 roundStart = getStartHeight();
        return
            !(_cooldownStart[addr] + COOLDOWN_BLOCK_LENGTH <= block.number ||
                _cooldownStart[addr] <= roundStart);
    }

    function hasStone(uint8 level) internal view virtual returns (bool) {
        // level 1 -> 1 /1000 level 2 -> 2 / 1000 etc
        // randomIndex returns [0...parameter - 1] because it uses modulo internally
        // so len([0...parameter - 1]) == parameter
        return _randomIndex(1000) < level;
    }

    function withdraw(uint256 round, address payable payee) external {
        _escrowManager.withdraw(round, payee);
    }

    function depositsOf(uint256 round, address payee)
        external
        view
        returns (uint256)
    {
        return _escrowManager.depositsOf(round, payee);
    }

    function getEscrow(uint256 round) external view returns (IEscrow) {
        return _escrowManager.getEscrow(round);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Round.sol";
import "./IERC721MetadataRound.sol";
import "./IERC721EnumerableRound.sol";
import "../SnowballStructs.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721Round is
    Context,
    ERC165,
    IERC721Round,
    IERC721MetadataRound,
    IERC721EnumerableRound
{
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    Counters.Counter private _roundIdCounter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from round id to Round struct
    mapping(uint256 => Round) private _rounds;

    // Mapping from round id to mapping from token id to owner address
    mapping(uint256 => mapping(uint256 => address)) private _owners;

    // Mapping owner address to token amount
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping owner address to index to token id
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        private _tokenOwners;

    // Mapping token id to token index in _tokenOwners
    mapping(uint256 => mapping(uint256 => uint256)) private _tokenOwnersIndex;

    // Mapping from round id to owner to operator approvals
    mapping(uint256 => mapping(address => mapping(address => bool)))
        private _operatorApprovals;

    // Mapping from token id to approved address
    mapping(uint256 => mapping(uint256 => address)) private _tokenApprovals;

    event Winner(uint256 indexed roundId, address indexed player);

    modifier roundIsValid(uint256 roundId) {
        uint256 _roundId = getRoundId();
        require(roundId > 0 && roundId <= _roundId , "No Round started yet");
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Round).interfaceId ||
            interfaceId == type(IERC721MetadataRound).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(owner != address(0), "Zero address");
        uint256 roundId = getRoundId();
        require(roundId > 0, "No Round started");
        return _balances[roundId][owner];
    }

    function balanceOf(uint256 roundId, address owner)
        public
        view
        virtual
        roundIsValid(roundId)
        returns (uint256)
    {
        require(owner != address(0), "Zero address");
        return _balances[roundId][owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        uint256 roundId = getRoundId();
        require(roundId > 0, "No Round started");
        address owner = _owners[roundId][tokenId];
        require(owner != address(0), "Invalid token");
        return owner;
    }

    function ownerOf(uint256 roundId, uint256 tokenId)
        external
        view
        roundIsValid(roundId)
        returns (address)
    {
        address owner = _owners[roundId][tokenId];
        require(owner != address(0), "Invalid token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        returns (string memory);

    function tokenURI(uint256, uint256 tokenId)
        external
        view
        virtual
        returns (string memory);

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Round.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        uint256 roundId = getRoundId();
        require(roundId > 0, "No Round started");
        _requireMinted(tokenId);
        return _tokenApprovals[roundId][tokenId];
    }

    function getApproved(uint256 roundId, uint256 tokenId)
        external
        view
        roundIsValid(roundId)
        returns (address)
    {
        _requireMinted(tokenId);
        return _tokenApprovals[roundId][tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[getRoundId()][owner][operator];
    }

    function isApprovedForAll(
        uint256 roundId,
        address owner,
        address operator
    ) external view roundIsValid(roundId) returns (bool) {
        return _operatorApprovals[roundId][owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Unauthorized"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Unauthorized"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[getRoundId()][tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ERC721Round.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        uint256 roundId = getRoundId();
        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[roundId][to] += 1;
        _owners[roundId][tokenId] = to;
        _rounds[roundId].totalSupply++;

        _addTokenOwner(to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Round.ownerOf(tokenId) == from, "Unauthorized");
        require(to != address(0), "Zero address");
        uint256 roundId = getRoundId();
        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _removeOwner(from, tokenId);

        _balances[roundId][from] -= 1;
        _balances[roundId][to] += 1;
        _owners[roundId][tokenId] = to;

        _addTokenOwner(to, tokenId);

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[getRoundId()][tokenId] = to;
        emit Approval(ERC721Round.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        uint256 roundId = getRoundId();
        require(roundId > 0, "No Round started");
        _operatorApprovals[roundId][owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _addTokenOwner(address to, uint256 tokenId) internal {
        // assumes that balanceOf was already increased
        uint256 length = balanceOf(to) - 1;
        uint32 round = uint32(_roundIdCounter.current());
        _tokenOwners[round][to][length] = tokenId;
        _tokenOwnersIndex[round][tokenId] = length;
    }

    // adapted from from _removeTokenFromOwnerEnumeration (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol)
    function _removeOwner(address from, uint256 tokenId) internal {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        // assumes balance was not already decremented
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint32 round = uint32(_roundIdCounter.current());
        uint256 tokenIndex = _tokenOwnersIndex[round][tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _tokenOwners[round][from][lastTokenIndex];

            _tokenOwners[round][from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _tokenOwnersIndex[round][lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _tokenOwnersIndex[round][tokenId];
        delete _tokenOwners[round][from][lastTokenIndex];
    }

    function totalSupply() public view virtual returns (uint256) {
        return getTokenId();
    }

    function totalSupply(uint256 roundId)
        public
        view
        virtual
        returns (uint256)
    {
        require(roundId > 0 && roundId <= getRoundId(), "Invalid id");
        return _rounds[roundId].totalSupply;
    }

    function getRoundId() public view returns (uint256) {
        return _roundIdCounter.current();
    }

    function _newRoundId() internal returns (uint256) {
        _roundIdCounter.increment();
        return _roundIdCounter.current();
    }

    function getTokenId() internal view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _newTokenId() internal returns (uint256) {
        _tokenIdCounter.increment();
        return _tokenIdCounter.current();
    }

    function getStartHeight() public view returns (uint256) {
        uint256 roundId = getRoundId();
        require(roundId > 0, "No Round started");
        return _rounds[roundId].startHeight;
    }

    function getStartHeight(uint256 roundId) external view roundIsValid(roundId) returns (uint256) {
        return _rounds[roundId].startHeight;
    }

    function getEndHeight() public view returns (uint256) {
        uint256 roundId = getRoundId();
        require(roundId > 0, "No Round started");
        return _rounds[roundId].endHeight;
    }

    function getEndHeight(uint256 roundId) external view roundIsValid(roundId) returns (uint256) {
        return _rounds[roundId].endHeight;
    }

    // TODO: this seem like it would always be 0x0 except for the time between rounds
    function getWinner() public view returns (address) {
        uint256 roundId = getRoundId();
        require(roundId > 0, "No Round started");
        return _rounds[roundId].winner;
    }

    function getWinner(uint256 roundId) public view roundIsValid(roundId) returns (address) {
        return _rounds[roundId].winner;
    }

    function getWinnerBonus(uint256 roundId) public view roundIsValid(roundId) returns (uint256) {
        return _rounds[roundId].winnerBonus;
    }

    function _setWinner(address winner) internal {
        require(winner != address(0), "0 Address");
        uint256 roundId = getRoundId();
        _rounds[roundId].winner = winner;
        emit Winner(roundId, winner);
    }

    function getPayoutPerToss(uint256 roundId) external view roundIsValid(roundId) returns (uint256) {
        return _rounds[roundId].payoutPerToss;
    }

    function _startRound() internal {
        uint256 endHeight = block.number + (31 days / 2 seconds);
        uint256 newRound = _newRoundId();
        _rounds[newRound] = Round({
            startHeight: block.number,
            endHeight: endHeight,
            winner: address(0),
            totalSupply: 0,
            payoutPerToss: 0,
            totalPayout: 0,
            winnerBonus: 0
        });
        _tokenIdCounter.reset();
    }

    function _endRound(
        uint256 totalPayout,
        uint256 winnerBonus,
        uint256 payoutPerToss
    ) internal {
        uint256 total = getTokenId();
        uint256 roundId = getRoundId();

        _rounds[roundId].totalPayout = totalPayout;
        _rounds[roundId].totalSupply = total;
        _rounds[roundId].winnerBonus = winnerBonus;
        _rounds[roundId].payoutPerToss = payoutPerToss;
        _rounds[roundId].endHeight = block.number;
    }

    function getTokensOfAddress(uint256 round, address addr)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 amount = balanceOf(round, addr);
        uint256[] memory ret = new uint256[](amount);

        for (uint256 index; index < amount; index++) {
            ret[index] = _tokenOwners[round][addr][index];
        }

        return ret;
    }

    function getTokensOfAddress(address addr)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        return getTokensOfAddress(_roundIdCounter.current(), addr);
    }

    function getTokenOwner(
        uint256 roundId,
        address addr,
        uint256 index
    ) public view virtual roundIsValid(roundId) returns (uint256) {
        return _tokenOwners[roundId][addr][index];
    }

    function getPayout() external view returns (uint256) {
        uint256 roundId = getRoundId();
        require(roundId > 0, "No Round started");
        return _rounds[roundId].totalPayout;
    }

    function getPayout(uint256 roundId) external view roundIsValid(roundId) returns (uint256) {
        return _rounds[roundId].totalPayout;
    }
}

// SPDX-License-Identifier: CC-BY-NC-4.0

pragma solidity ^0.8.0;

import "./IEscrow.sol";
import "./ISchneeballschlacht.sol";

interface IEscrowManager {
    function withdraw(uint256 round, address payable payee) external;
    function depositsOf(uint256 round, address payee)
        external
        view
        returns (uint256);
    function getEscrow(uint256 round) external view returns (IEscrow);
    function createEscrow(uint256 round, ISchneeballschlacht schneeballschlacht) external returns (IEscrow);
}

// SPDX-License-Identifier: CC-BY-NC-4.0

pragma solidity ^0.8.0;

interface IEscrow {
    event Withdraw(address indexed payee, uint256 weiAmount);

    function depositsOf(address payee) external view returns (uint256);
    function deposit() external payable;
    function withdraw(address payable payee) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: CC-BY-NC-4.0

pragma solidity ^0.8.0;

interface IHallOfFame {
    function mint(address to) external;
}

// SPDX-License-Identifier: CC-BY-NC-4.0

pragma solidity ^0.8.0;

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC721RoundData.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Round is IERC165, IERC721RoundData {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the number of tokens in ``owner``'s account. At round
     */
    function balanceOf(uint256 roundId, address owner) external view returns (uint256 balance);


    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 roundId, uint256 tokenId) external view returns (address owner);


    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 roundId, uint256 tokenId) external view returns (address operator);


    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

        /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(uint256 roundId, address owner, address operator) external view returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataRound {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: CC-BY-NC-4.0

pragma solidity ^0.8.0;

import "../SnowballStructs.sol";

interface IERC721EnumerableRound {
    function getTokensOfAddress(address addr)
        external
        view
        returns (uint256[] memory);

    function getTokensOfAddress(uint256 round, address addr)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: CC-BY-NC-4.0

pragma solidity ^0.8.0;

struct Round {
    address winner;
    uint256 totalPayout;
    uint256 payoutPerToss;
    uint256 startHeight;
    uint256 endHeight;
    uint256 totalSupply;
    uint256 winnerBonus;
}

struct Snowball {
    bool hasStone;
    uint8 level;
    uint256[] partners;
    uint256 parentSnowballId;
}

struct Query {
    address player;
    uint8 level;
    uint8 partnerCount;
    bool hasStone;
    uint256 tokenId;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: CC-BY-NC-4.0

pragma solidity ^0.8.0;

interface IERC721RoundData {
    function getRoundId() external view returns (uint256);

    function getStartHeight() external view returns (uint256);

    function getStartHeight(uint256 roundId) external view returns (uint256);

    function getEndHeight() external view returns (uint256);

    function getEndHeight(uint256 roundId) external view returns (uint256);

    function getPayoutPerToss(uint256 roundId) external view returns (uint256);

    function getWinner(uint256 roundId) external view returns (address);

    function getWinnerBonus(uint256 roundId) external view returns (uint256);
}

// SPDX-License-Identifier: CC-BY-NC-4.0

pragma solidity ^0.8.0;

import "./SnowballStructs.sol";
import "./ERC721Round/IERC721RoundData.sol";
import "./ERC721Round/IERC721EnumerableRound.sol";

interface ISchneeballschlacht is IERC721RoundData, IERC721EnumerableRound {
    function startRound() external;

    function endRound() external;

    function toss(address to, uint256 tokenId) external payable;

    function mint(address to) external payable;

    function getLevel(uint256 tokenId) external view returns (uint8);

    function getLevel(uint256 roundId, uint256 tokenId)
        external
        view
        returns (uint8);

    function getPartnerTokenIds(uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    function getPartnerTokenIds(uint256 roundId, uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    function getSnowballsOfAddress(address addr)
        external
        view
        returns (Snowball[] memory);

    function getSnowballsOfAddress(uint256 round, address addr)
        external
        view
        returns (Snowball[] memory);

    function totalSupply() external view returns (uint256);

    function totalSupply(uint256 roundId) external view returns (uint256);

    function totalTosses() external view returns (uint256);

    function totalTosses(uint256 roundId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal onlyInitializing {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}