// SPDX-License-Identifier: MIT

// Because every self-respected businessman needs his business card

pragma solidity ^0.8.0;

import "./BusinessCardUtils.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165Storage.sol";
import "./SafeMath.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";

contract ISoulboundCard {

    function burnAllSoulboundCardsOfToken(uint256 tokenId) external { }

} 

/**
 * @title NFT Business Card smart contract
 * @dev compliant with https://eips.ethereum.org/EIPS/eip-721
 */
contract BusinessCard is ERC165Storage, IERC721, IERC721Metadata, IERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Public variables
    uint256 public constant maxSupply = 1111;
    bool public saleStarted;

    // Random nonce for generating genes
    uint256 private randNonce;

    struct Card {
        uint256 genes;
        string name;
    }

    // Mapping from token ID to genes
    mapping (uint256 => Card) private _tokenStats;
    // Mapping for reserved names, reserved names are stored in lowercase
    mapping (string => bool) private _nameReserved;

    // Values sent in the event when minting / updating a card
    // All the metadata attributes that do NOT get stored on chain
    struct CardProperties {
        string position;
        string twitterAccount;
        string telegramAccount;
        string telegramGroup;
        uint256 discordAccount;
        string discordGroup;
        string githubUsername;
        string website;
    }

    // Default URI
    string private _defaultURI;

    // Address of the oracle
    address private oracle;
    // Requests made to the NFT oracle
    mapping(uint256 => bool) public requests;

    // Marketplace address
    address private bCardMarketplace;
    // sCard address - SoulboundCards
    ISoulboundCard private sCard;

    // Token mint price
    uint256 public mintPrice = 0.1 ether;
    // Token URI update / swap price
    uint256 public updatePrice = 0.05 ether;
    // Oracle update transaction gas price
    uint256 public oraclePrice = 0.025 ether;

    // Oracle related events
    event UpdateRequest(uint256 tokenId, uint256 genes, string name, CardProperties cardProperties);
    event SwapRequest(uint256 tokenId1, uint256 tokenId2, uint256 genes1, uint256 genes2);
    event TokenURIUpdated(uint256 tokenId, string tokenURI);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection, and defining base and default URIs.
     */
    constructor (string memory name_, string memory symbol_, string memory defaultURI_, address _oracle) {
        _name = name_;
        _symbol = symbol_;
        _defaultURI = defaultURI_;
        oracle = _oracle;

        // register the supported interfaces to conform to ERC721 via ERC165
        /*
        *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
        *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
        *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
        *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
        *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
        *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
        *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
        *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
        *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
        *
        *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
        *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
        */
        _registerInterface(0x80ac58cd);

        /*
        *     bytes4(keccak256('name()')) == 0x06fdde03
        *     bytes4(keccak256('symbol()')) == 0x95d89b41
        *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
        *
        *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
        */
        _registerInterface(0x5b5e139f);

        /*
        *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
        *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
        *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
        *
        *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
        */
        _registerInterface(0x780e9d63);
    }
    
    /**
     * @dev Sets up a new oracle that handles the dynamic aspect of the NFT
     */
    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    /**
     * @dev Sets up a Marketplace allowing the native trading of Business Cards
     */
    function setMarketplace(address _marketplace) external onlyOwner {
        bCardMarketplace = _marketplace;
    }

    /**
     * @dev Sets up the sCard address for interaction
     */
    function setSoulboundCard(address _soulbound) external onlyOwner {
        sCard = ISoulboundCard(_soulbound);
    }

    /**
     * @dev Changes the update price for the usage of the oracle
     */
    function modifyUpdatePrice(uint256 newUpdatePrice) external onlyOwner {
        require(newUpdatePrice >= oraclePrice); // dev: Update price must always cover the gas costs of running the oracle
        updatePrice = newUpdatePrice;
    }

    /**
     * @dev Calls the oracle to update a certain token URI with the newly defined Card struct
     */
    function _updateTokenURI(uint256 _tokenId, uint256 _genes, string calldata _cardName, CardProperties calldata _cardProperties) internal {
        require(BusinessCardUtils.validateOtherProperties(_cardProperties));  // Other properties are not valid
        require(_exists(_tokenId));
        // Calls for updating the token can only be made if it is not being processed already
        require(requests[_tokenId] == false, "Update being processed");
        requests[_tokenId] = true;
        // Fund the server oracle with enough funds for the updateCallback transaction
        payable(oracle).transfer(oraclePrice);
        // Emit event to be catched by the server oracle running off-chain
        emit UpdateRequest(_tokenId, _genes, _cardName, _cardProperties);
    }

    /**
     * @dev Updates a certain token URI and clears the corresponding update request
     * Only the assigned server oracle is allowed to call this function
     */
     function updateCallback(uint256 _tokenId, string memory _tokenURI) external {
        _callback(_tokenId, _tokenURI);
    }

    /**
     * @dev Updates a certain token URI and clears the corresponding update request
     * Only the assigned server oracle is allowed to call this function
     */
     function swapCallback(uint256 _tokenId1, uint256 _tokenId2, string memory _tokenURI1, string memory _tokenURI2) external {
        _callback(_tokenId1, _tokenURI1);
        _callback(_tokenId2, _tokenURI2);
    }

    /**
     * @dev Updates a certain token URI and clears the corresponding update request
     * Only the assigned server oracle is allowed to call this function
     */
     function _callback(uint256 _tokenId, string memory _tokenURI) internal {
        require(_msgSender() == oracle); // dev: Only the assigned oracle can call this function
        require(requests[_tokenId]); // dev: Request not in pending list
        _tokenURIs[_tokenId] = _tokenURI;
        delete requests[_tokenId];
        emit TokenURIUpdated(_tokenId, _tokenURI);
     }

     /**
     * @dev Mints a new NFT Business Card
     */
    function getCard(string calldata _cardName, CardProperties calldata _cardProperties) public payable {
        require(saleStarted == true);  // dev: sale not started or paused, can be managed on frontend
        require(totalSupply() < maxSupply);  // dev: sale has ended, can be managed on frontend
        require(msg.value >= mintPrice);  // dev: value sent is below the price, can be managed on frontend
        // Minting a new NFT with the name and position provided
        _safeMint(_msgSender(), totalSupply() + 1, _cardName, _cardProperties);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address _to, uint256 _tokenId, string calldata _cardName, CardProperties calldata _cardProperties) internal virtual {
        require(
            BusinessCardUtils.validateName(_cardName) &&
            isNameReserved(_cardName) == false, 
            "Name taken or not valid"
        );
        require(
            BusinessCardUtils.validatePosition(_cardProperties.position), 
            "Position not valid"
        );

        // Generating the random genes, defined by a 26 digit number
        // The server oracle will convert the genes to a string and add leading zeros, as tokenURIs are generated with this constraint
        uint256 genes = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _cardName, randNonce))) % 10**30;
        randNonce++;
        
        // Generating a new card
        toggleReserveName(_cardName, true);
        _tokenStats[_tokenId] = Card(genes, _cardName);
        _safeMint(_to, _tokenId, abi.encodePacked(_cardName, genes));
        _updateTokenURI(_tokenId, genes, _cardName, _cardProperties);
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Changes the name and/or position of a given NFT, must be owned by the caller.
     * Whenever such change is made, it is first immediately reflected in the Card struct, and in the metadata after oracle updates.
     * User can change both name and position, just the name, or just the position (by leaving those inputs empty)
     */
    function updateCard(uint256 tokenId, string calldata newName, CardProperties calldata newCardProperties) public payable {
        require(saleStarted == true);  // dev: updates paused, can be managed on frontend
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        require(
            isNameReserved(newName) == false &&
            (
                bytes(newName).length == 0 
                ||
                BusinessCardUtils.validateName(newName) == true
            )
            , 
            "Name taken or not valid"
        );
        require(
            bytes(newCardProperties.position).length == 0
            ||
            BusinessCardUtils.validatePosition(newCardProperties.position) == true
            , 
            "Position not valid"
        );
        require(
            msg.value >= updatePrice || _msgSender() == bCardMarketplace
        );  // dev: value sent is below the price, can be managed on frontend

        // Only change the name if specified
        if (bytes(newName).length > 0) {
            // De-reserve the old name
            toggleReserveName(_tokenStats[tokenId].name, false);
            // Reserve the new name
            toggleReserveName(newName, true);
            // Changing the token name
            _tokenStats[tokenId].name = newName;
        }

        // Make new tokenURI update request
        _updateTokenURI(tokenId, _tokenStats[tokenId].genes, newName, newCardProperties);
    }

    /**
     * @dev Swaps the name and position between two NFTs, must be owned by the caller.
     * This is to give customers the ability to directly shuffle name and positions of their
     * cards, and prevent possible "name snipers"
     */
    function swapCards(uint256 tokenId1, uint256 tokenId2) public payable {
        require(saleStarted == true);  // dev: updates paused, can be managed on frontend
        require(
            _isApprovedOrOwner(_msgSender(), tokenId1) &&
            _isApprovedOrOwner(_msgSender(), tokenId2), 
            "Caller is not owner nor approved"
        );
        require(msg.value >= updatePrice);  // dev: value sent is below the price, can be managed on frontend
        // Calls for updating the token can only be made if it is not being processed already
        require(requests[tokenId1] == false && requests[tokenId2] == false, "Update being processed");

        // Swapping names between tokens
        string memory name1 = _tokenStats[tokenId1].name;
        _tokenStats[tokenId1].name = _tokenStats[tokenId2].name;
        _tokenStats[tokenId2].name = name1;

        // Requests now pending
        requests[tokenId1] = true;
        requests[tokenId2] = true;

        // Emitting a single swap request to the oracle -- processed differently
        emit SwapRequest(tokenId1, tokenId2, _tokenStats[tokenId1].genes, _tokenStats[tokenId2].genes);

        // Fund the server oracle with enough funds for the swapCallback transaction
        payable(oracle).transfer(oraclePrice);
    }

    /**
     * @dev Updates the tokenURI, intented to be used only when oracle fails to update a tokenURI
     */
    function updateTokenURI(uint256 tokenId, string calldata cardName, CardProperties calldata _cardProperties) external onlyOwner {
        _updateTokenURI(tokenId, _tokenStats[tokenId].genes, cardName, _cardProperties);
    }

    /**
     * @dev Starts the sale, cannot do so until the oracle is defined
     */
    function startSale() external onlyOwner {
        require(oracle != address(0));  // dev: Oracle not defined
        saleStarted = true;
    }

    /**
     * @dev Pauses the sale
     */
    function pauseSale() external onlyOwner {
        saleStarted = false;
    }

    /**
     * @dev Returns the stats of a token
     */
    function tokenStats(uint256 tokenId) public view returns (Card memory) {
        return _tokenStats[tokenId];
    }

    /**
     * @dev Overrides the default tokenURI behaviour to include the default URI
     */
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length == 0) {
            return defaultURI();
        } else {
            return _tokenURI;
        }
    }

    /**
    * @dev Returns the default URI
    */
    function defaultURI() public view virtual returns (string memory) {
        return _defaultURI;
    }

    /**
     * @dev For setting the default URI for all tokenId's. 
     */
    function setDefaultURI(string calldata newDefaultURI) external onlyOwner {
        require(bytes(newDefaultURI).length > 0);  // dev: cannot be set to empty string
        _defaultURI = newDefaultURI;
    }

    /**
     * @dev Returns if the name has been reserved.
     * Name reservation checks are made in lowercase
     */
    function isNameReserved(string calldata nameString) public view returns (bool) {
        return _nameReserved[BusinessCardUtils.toLower(nameString)];
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     * Names are reserved in lowercase, but stored in whatever case the user gave
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[BusinessCardUtils.toLower(str)] = isReserve;
    }

    /**
     * @dev Withdraw balance from this contract (Callable by owner)
    */
    function withdraw() onlyOwner external {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < balanceOf(owner));  // @dev: index out of bounds
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply());  // @dev: index out of bounds
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *
     * If the sCard smart contract was specified, it burns all Soulbound Cards associated 
     * with the Business Card `tokenId` in the process
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId, true);
    }

    /**
     * @dev Works as `transferFrom`, but will not burn the associated Soulbound Cards 
     */
    function transferFromWithoutBurn(address from, address to, uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId, false);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId, true);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(!_exists(_tokenId), "ERC721: token already minted");

        _holderTokens[_to].add(_tokenId);

        _tokenOwners.set(_tokenId, _to);

        emit Transfer(address(0), _to, _tokenId);
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
    function _transfer(address from, address to, uint256 tokenId, bool burn) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        // Burn the associated Soulbound Cards
        if (address(sCard) != address(0) && burn) {
            sCard.burnAllSoulboundCardsOfToken(tokenId);
        }

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == 0x150b7a02);
    }

}