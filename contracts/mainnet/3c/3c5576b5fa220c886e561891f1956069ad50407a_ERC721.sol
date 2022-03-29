// NFTitties Polygon
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Strings.sol";
import "ERC165.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "Counters.sol";
import "IERC20.sol";

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable {
    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct Auction {
        uint256 id;
        uint256 endTime;
        uint256 tokenId;
    }

    struct Rate {
        uint256 id;
        uint256 cost;
        address owner;
    }

    event TokenCreated(uint256 indexed tokenId, address indexed owner);

    event MultipleTokenCreated(uint256[] tokenIds, address indexed owner);

    event CreateAuction(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 indexed price
    );

    event ResetAuction(
        uint256 indexed tokenId
    );

    event PlaceBid(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 indexed price
    );

    event CompleteAuction(
        uint256 indexed tokenId,
        address indexed toAddress,
        uint256 indexed price
    );

    //Creator fee
    uint256 public creatorPercent = 89;
    //Platform + charity fee
    uint256 public systemPercent = 11;
    //Duration for each auction
    uint256 public timeInterval = 24 hours;
    //Time extension if a new bid appears near the end
    uint256 public timeExtension = 15 minutes;
    //Percentage by which new bid should be greater than old
    uint256 public rateStep = 10;
    //Min bid amount WEI
    uint256 public minBid = 0.0005 ether;
    //Is preminting or postminting
    bool public isPreMinting;
    //Enable approveAuctionWithCreator function
    bool public canApproveWithCreator;

    //Auction of tokenId
    mapping(uint256 => Auction) public auctionOfToken;
    //Rate of auctionId
    mapping(uint256 => Rate) public rateOfAuctionId;
    //Creator of tokenId
    mapping(uint256 => address) public tokenCreator;
    //Creator addresses
    mapping(uint256 => address) public creatorAddresses;
    //Admin addresses
    mapping(address => bool) public adminPool;
    //Approved auctions
    mapping(uint256 => bool) public claimableAuctions;

    //System address
    address payable public systemAddress = payable(address(0xd613c3878CbC435feAf066D3d510165D7DE9AcC1));

    uint256 public auctionCount = 1;
    uint256 public rateCount = 1;
    uint256 private tokensCounter = 0;

    modifier onlyAdmin() {
        require(adminPool[_msgSender()], "Caller is not the admin");
        _;
    }

    function setCreatorFeePercent(uint256 percent) external onlyOwner {
        creatorPercent = percent;
    }

    function setSystemFeePercent(uint256 percent) external onlyOwner {
        systemPercent = percent;
    }

    function setMinBidAmount(uint256 _minBid) external onlyOwner {
        minBid = _minBid;
    }

    function setRateStep(uint256 _newValue) external onlyOwner {
        require(_newValue <= 100, "Rate step too high");
        rateStep = _newValue;
    }

    function setTimeExtension(uint256 _newValue) external onlyOwner {
        require(_newValue <= 24 hours, "Too much extension");
        timeExtension = _newValue;
    }

    function setSystemAddress(address payable _address) external onlyOwner {
        systemAddress = _address;
    }

    function setTimeInterval(uint256 newTime) external onlyOwner {
        timeInterval = newTime;
    }

    function setAdminPool(address _address, bool value) external onlyOwner {
        adminPool[_address] = value;
    }

    function setMintType(bool value) external onlyOwner {
        isPreMinting = value;
    }

    function setApproveWithCreator(bool value) external onlyOwner {
        canApproveWithCreator = value;
    }

    function approveAuction(uint256 tokenId, uint256 serverBidPrice) external onlyAdmin {
        Auction memory auction = auctionOfToken[tokenId];

        require(auction.id != 0, "Auction does not exist");
        require(auction.endTime <= block.timestamp, "Auction has not ended yet");

        Rate memory maxRate = rateOfAuctionId[auction.id];

        if (maxRate.cost >= serverBidPrice) {
            claimableAuctions[tokenId] = true;
        } else {
            returnRateToUser(tokenId);

            delete auctionOfToken[tokenId];
            delete rateOfAuctionId[auction.id];
        }
    }

    function approveAuctionWithCreator(uint256 tokenId, uint256 serverBidPrice, address creator) external onlyAdmin {
        require(canApproveWithCreator, "Approving with creator disabled");
    
        Auction memory auction = auctionOfToken[tokenId];

        require(auction.id != 0, "Auction does not exist");
        require(auction.endTime <= block.timestamp, "Auction has not ended yet");

        Rate memory maxRate = rateOfAuctionId[auction.id];

        if (maxRate.cost >= serverBidPrice) {
            claimableAuctions[tokenId] = true;
            creatorAddresses[tokenId] = creator;
        } else {
            returnRateToUser(tokenId);

            delete auctionOfToken[tokenId];
            delete rateOfAuctionId[auction.id];
        }
    }

    function emergencyCancelAuction(uint256 tokenId) external onlyOwner {
        Auction memory auction = auctionOfToken[tokenId];
        require(auction.id != 0, "Auction not exist");

        returnRateToUser(tokenId);

        delete auctionOfToken[tokenId];
        delete rateOfAuctionId[auction.id];

        emit ResetAuction(tokenId);
    }

    function startAuction(uint256 tokenId) external payable {
        require(auctionOfToken[tokenId].id == 0, "Auction already exists");
        require(!isPreMinting, "Pre-minting is active");
        require(_owners[tokenId] == address(0), "Token already owned");
        require(msg.value >= minBid, "ETH amount too low");

        _setAuctionToMap(tokenId);
        _setRateToAuction(auctionOfToken[tokenId].id, _msgSender(), msg.value);

        emit CreateAuction(tokenId, _msgSender(), msg.value);
    }

    function returnRateToUser(uint256 tokenId) private {
        Auction memory auction = auctionOfToken[tokenId];
        Rate memory oldRate = rateOfAuctionId[auction.id];

        require(oldRate.id != 0, "Bid does not exist");

        address payable owner = payable(oldRate.owner);

        owner.transfer(oldRate.cost);
    }

    function placeBid(uint256 tokenId) external payable {
        require(auctionOfToken[tokenId].id != 0, "Auction does not exist");

        Auction memory auction = auctionOfToken[tokenId];
        Rate memory maxRate = rateOfAuctionId[auction.id];

        require(msg.value >= (maxRate.cost).mul(rateStep + 100).div(100),
            "Bid must be greater than current bid"
        );

        if (block.timestamp > auction.endTime.sub(timeExtension))
            auctionOfToken[tokenId].endTime = block.timestamp + timeExtension;

        _setRateToAuction(auction.id, _msgSender(), msg.value);

        emit PlaceBid(tokenId, _msgSender(), msg.value);
    }

    function claimToken(uint256 tokenId) external {
        require(_owners[tokenId] == address(0), "Token already claimed");

        Auction memory auction = auctionOfToken[tokenId];

        require(auction.endTime <= block.timestamp, "Auction has not ended yet");

        Rate memory maxRate = rateOfAuctionId[auction.id];

        require(maxRate.owner != address(0), "No address for previous bidder");
        require(claimableAuctions[tokenId], "Auction has not been approved yet");

        _safeMint(maxRate.owner, tokenId);

        if(creatorAddresses[tokenId] != address(0)) {
            address payable _creatorAddress = payable(creatorAddresses[tokenId]);

            _creatorAddress.transfer(getQuantityByTotalAndPercent(maxRate.cost, creatorPercent));
            systemAddress.transfer(getQuantityByTotalAndPercent(maxRate.cost, systemPercent));
        } else {
            systemAddress.transfer(maxRate.cost);
        }

        delete auctionOfToken[tokenId];
        delete rateOfAuctionId[auction.id];
        delete claimableAuctions[tokenId];
    
        emit CompleteAuction(tokenId, maxRate.owner, maxRate.cost);
    }

    function _setRateToAuction(uint256 auctionId, address rateOwnAddress, uint256 cost) private {
        Rate memory oldRate = rateOfAuctionId[auctionId];

        Rate memory rate;
        rate.cost = cost;
        rate.owner = rateOwnAddress;
        rate.id = rateCount;

        rateCount = rateCount + 1;
        rateOfAuctionId[auctionId] = rate;

        if (oldRate.id != 0) {
            address payable owner = payable(oldRate.owner);

            owner.transfer(oldRate.cost);
        }
    }

    function getHighestBidFromAuction(uint256 tokenId) public view returns (uint256) {
        require(auctionOfToken[tokenId].id != 0, "Auction does not exist");
        Auction memory auction = auctionOfToken[tokenId];
        Rate memory maxRate = rateOfAuctionId[auction.id];

        require(maxRate.id != 0, "Bid does not exist");

        return maxRate.cost;
    }

    function isAuctionOver(uint256 tokenId) public view returns (bool) {
        Auction memory auction = auctionOfToken[tokenId];

        if(auctionOfToken[tokenId].id == 0)
            return false;

        return block.timestamp > auction.endTime;
    }

    function _setAuctionToMap(uint256 _tokenId) private {
        Auction memory auction;

        auction.tokenId = _tokenId;
        auction.id = auctionCount;
        auction.endTime = block.timestamp + timeInterval;

        auctionOfToken[_tokenId] = auction;

        auctionCount++;
    }

    // Create tokens
    function createToken() public returns (uint256) {
        require(isPreMinting, "Post-minting is active");

        uint256 tokenId = totalSupply();
        while (ownerOf(tokenId) != address(0)) {
            tokenId++;
        }
        _safeMint(_msgSender(), tokenId);
        tokensCounter++;

        emit TokenCreated(tokenId, _msgSender());
        return tokenId;
    }

    function createMultipleTokens(uint256 count) public returns (uint256[] memory) {
        require(count <= 50, "Max limit is 50 tokens");
        require(isPreMinting, "Post-minting is active");

        uint256[] memory tokensArray = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = totalSupply();
            while (ownerOf(tokenId) != address(0)) {
                tokenId++;
            }
            _safeMint(_msgSender(), tokenId);
            tokensCounter++;
            tokensArray[i] = tokenId;
        }
        emit MultipleTokenCreated(tokensArray, _msgSender());
        return tokensArray;
    }

    function getQuantityByTotalAndPercent(uint256 totalCount, uint256 percent) public pure returns (uint256) {
        if (percent == 0) return 0;

        return totalCount.mul(percent).div(100);
    }

    function changeTokensOwner(address newAddress) public {
        uint256[] memory tokens = tokensOfOwner(_msgSender());

        for (uint256 i = 0; i < tokens.length; i++) {
            _safeTransfer(_msgSender(), newAddress, tokens[i], "");
            tokenCreator[tokens[i]] = newAddress;
        }
    }

    function withdraw(address _address) public onlyOwner {
        address payable owner = payable(address(uint160(_msgSender())));

        if (_address == address(0)) {
            owner.transfer(address(this).balance);
        } else {
            require(
                IERC20(_address).transfer(
                    _msgSender(),
                    IERC20(_address).balanceOf(address(this))
                ),
                "Error while transferring token"
            );
        }
    }

    // Token name
    string private _name = "NFTitties";
    // Token symbol
    string private _symbol = "TITS";

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "https://www.nftitties.app/token/";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
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
        return _owners[tokenId] != address(0);
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;
    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;
    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        _ownedTokens[from].pop();
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.pop();
        _allTokensIndex[tokenId] = 0;
    }
}