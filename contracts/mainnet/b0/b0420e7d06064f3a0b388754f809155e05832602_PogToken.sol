// SPDX-License-Identifier: GPL-3.0

/// @title The Pog ERC-721 token

pragma solidity ^0.8.6;

import { Ownable } from './Ownable.sol';
import { Strings } from './Strings.sol';
import { ERC721Enumerable } from './ERC721Enumerable.sol';
import { IPogToken } from './IPogToken.sol';
import { ITokenHooks } from './ITokenHooks.sol';
import { ERC721 } from './ERC721.sol';
import { IERC721 } from './IERC721.sol';
import { IProofOfGoodLedger } from './IProofOfGoodLedger.sol';

contract PogToken is IPogToken, Ownable, ERC721Enumerable {

    using Strings for uint256;

    // PoG Ledger address
    address public pogLedgerAddress;
    // Token Hooks address (for later pre/post token transfer)
    address public iTokenHooksAddress;
    // IPFS url of contract-level metadata
    string private _contractURI = '';
    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;
    // Whether the minter can be updated
    bool public isMintersLocked;

    // An address who has permissions to mint PoG
    mapping(address => bool) public minters;
    //operator -> bool
    mapping(address => bool) public proxyRegistry;
    // subcollection configuration
    mapping(uint32 => SubCollection) public subcollections;
    // seed -> tokenId mapping
    mapping(uint256 => uint256) public seedTokenMap;
    // tokenId -> TokenInfo
    mapping(uint256 => TokenInfo) public tokenInfoMap;
    // The Proof-Of-Good linking records
    mapping(uint256 => IProofOfGoodLedger.Reference[]) public pogLinks;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMintersNotLocked() {
        require(!isMintersLocked, 'Minters is locked');
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(minters[msg.sender], 'Sender is not a minter');
        _;
    }

    constructor(
    ) ERC721('PoG Pack', 'POGP') {
        addMinter(msg.sender);
    }

    /**
     * @notice Set the pogLedger address.
     * @dev Only callable by the owner.
     */
    function setProofOfGoodLedger(address newPogLedgerAddress) external onlyOwner {
        pogLedgerAddress = newPogLedgerAddress;
        emit PogLedgerUpdated(pogLedgerAddress);
    }

    /**
     * @notice Set the token hooks address.
     * @dev Only callable by the owner.
     */
    function setHooksAddress(address newHooksAddress) external onlyOwner {
        iTokenHooksAddress = newHooksAddress;
        emit ITokenHooksUpdated(iTokenHooksAddress);
    }

    /**
     * @notice Set the contractUri.
     * @dev Only callable by the owner.
     */
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_contractURI));
    }

    /**
     * @notice Add a minter.
     */
    function addMinter(address _minter) public override onlyOwner {
        require(_minter != address(0));
        minters[_minter] = true;
        emit MinterAdded(_minter);
    }

    /**
     * @notice Remove a minter.
     */
    function removeMinter(address _minter) public override onlyOwner {
        minters[_minter] = false;
        emit MinterRemoved(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinters() external override onlyOwner whenMintersNotLocked {
        isMintersLocked = true;
        emit MintersLocked();
    }

    /**
     * @notice Adds an approved proxy operator
     */
    function addApprovalProxy(address operator) external override onlyOwner {
        proxyRegistry[operator] = true;
        emit ApprovalProxyAdded(operator);
    }

    /**
     * @notice Removes an approved proxy operator
     */
    function removeApprovalProxy(address operator) external override onlyOwner {
        delete(proxyRegistry[operator]);
        emit ApprovalProxyRemoved(operator);
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's proxy accounts to enable gas-less listings. Allow minters to move contract tokens.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // check if operator is proxy
        if (proxyRegistry[operator]) {
            return true;
        }

        // allow minters to manager tokens owned by this contract
        if (owner == address(this) && minters[operator] == true) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Creates a subcollection, must be called before minting any tokens for a subcollection
     * @dev By default the current token index will *not* be reset for safety reasons, set `forceSetCurrentTokenId`=true to change this behaviour
     */
    function addSubCollection(uint32 subcollectionId, SubCollection memory sc) external override onlyMinter {
        //validate
        require(subcollectionId>0, 'Subcollection id must be at least 1');
        require(!subcollections[subcollectionId].exists, 'Subcollection already exists');
        require(bytes(sc.name).length>0, 'Must include name');
        require(sc.minTokenId>0, 'Min token id must be at least 1');
        require(sc.maxTokenId>=sc.minTokenId, 'Min token id cannot be larger than max token id');

        //all is good, write all fields except pool
        subcollections[subcollectionId].exists = true;
        subcollections[subcollectionId].minTokenId = sc.minTokenId;
        subcollections[subcollectionId].maxTokenId = sc.maxTokenId;
        subcollections[subcollectionId].currentTokenId = sc.minTokenId; //always start at minTokenId
        subcollections[subcollectionId].name = sc.name;
        subcollections[subcollectionId].sType = sc.sType;
        subcollections[subcollectionId].baseURI = sc.baseURI;
    }

    /**
     * @notice Updates subcollection data
     * @dev By default the current token index will *not* be reset for safety reasons, set `forceSetCurrentTokenId`=true to change this behaviour
     */
    function updateSubCollection(uint32 subcollectionId, SubCollection memory sc, bool forceSetCurrentTokenId) external override onlyMinter {
        //validate
        require(subcollectionId>0, 'Subcollection id must be at least 1');
        require(sc.entries.length==0, 'Entries must be empty');
        SubCollection storage currentSc = subcollections[subcollectionId];
        require(currentSc.exists, 'Subcollection does not exist');
        require(bytes(sc.name).length>0, 'Must include name');
        require(sc.minTokenId>0, 'Min token id must be at least 1');
        require(sc.maxTokenId>=sc.minTokenId, 'Min token id cannot be larger than max token id');
        require(sc.sType==currentSc.sType, 'Cannot change subcollection type'); //cannot change type!

        sc.exists = true;

        //leave token id gen alone by default, dangerous!
        if(!forceSetCurrentTokenId) {
            sc.currentTokenId = currentSc.currentTokenId;
        }

        //validate token in range
        require(sc.currentTokenId>=sc.minTokenId && sc.currentTokenId<=sc.maxTokenId, 'Token id out of range');

        //all is good, overwrite all fields except pool
        currentSc.exists = sc.exists;
        currentSc.minTokenId = sc.minTokenId;
        currentSc.maxTokenId = sc.maxTokenId;
        currentSc.currentTokenId = sc.currentTokenId;
        currentSc.name = sc.name;
        currentSc.sType = sc.sType;
        currentSc.baseURI = sc.baseURI;
    }

    /**
     * @notice Mint a batch of tokens to specified address and add to available pool for transfer.
     */
    function mintAndAddToPoolBatch(uint32 subcollectionId, uint256[] memory tokenIds, uint256[] memory seeds) external override onlyOwner whenMintersNotLocked {
        //validate
        require(tokenIds.length == seeds.length, 'Token id and seeds array lengths must be equal');
        SubCollection storage sc = subcollections[subcollectionId];
        require(sc.exists, 'Subcollection does not exist');
        require(sc.sType==SubCollectionType.BATCH, 'Subcollection type must be batch');
        
        for (uint i = 0; i < seeds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 seed = seeds[i];

            //ensure we stay within configured token id space
            require(tokenId>0, 'Token id must be greater than 0');
            require(tokenId>=sc.minTokenId, 'Token id less than min');
            require(tokenId<=sc.maxTokenId, 'Token id greater than max');
            //ensure seed not duplicate (note: added to map in _mintTo())
            require(seedTokenMap[seed]==0, 'Seed already exists');

            //new pool entry
            PogPoolEntry memory e = PogPoolEntry({tokenId: tokenId, seed: seed});

            //add to pool
            sc.entries.push(e);

            _mintTo(address(this), subcollectionId, e.tokenId, e.seed);
            
            emit SeedAdded(subcollectionId, tokenId, seed);
        }
    }

    /**
     * @notice Mint a Pog Pack from `subcollectionId` with `pogId` to the provided `to` address.
     */
    function _mintTo(address to, uint32 subcollectionId, uint256 tokenId, uint256 seed) internal {
        seedTokenMap[seed] = tokenId;

        tokenInfoMap[tokenId] = TokenInfo({
            tokenId: tokenId,
            subcollectionId: subcollectionId,
            seed: seed,
            tokenURI: ''
        });

        _mint(owner(), to, tokenId);

        emit PogCreated(subcollectionId, tokenId, seed);
    }

    /**
     * @notice Remove a token from the pool and transfer to an address
     * @dev Call _mintTo with the to address(es).
     */
    function pullFromPoolAndTransferTo(address to, uint32 subcollectionId) external override onlyMinter returns (uint256) {

        PogPoolEntry memory e = _consumeRandomTokenFromPool(subcollectionId);

        safeTransferFrom(ownerOf(e.tokenId), to, e.tokenId);

        return e.tokenId;
    }

    /**
     * @notice Consume a Random Token/Seed.
     */
    function _consumeRandomTokenFromPool(uint32 subcollectionId) internal returns (PogPoolEntry memory) {
        PogPoolEntry[] storage pool = subcollections[subcollectionId].entries;

        //error if no seeds
        require(pool.length>0, 'No entries in subcollection pool');

        //TODO: should include additional data like sender?
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), subcollectionId))
        );

        //pick a random index
        uint256 pickedIndex = pseudorandomness % pool.length;

        //get the seed
        PogPoolEntry memory randomEntry = pool[pickedIndex];

        //swap and delete last element (EVM cannot delete an arbitrary index)
        pool[pickedIndex] = pool[pool.length-1];
        pool.pop();

        return randomEntry;
    }

     /**
     * @notice Mint a random token starting at RandomTokenFirstId and transfer to `to`. Note that no validation is performed on the subCollectionId
     */
    function mintNewRandomToken(address to, uint32 subcollectionId, IProofOfGoodLedger.Reference[] calldata proofs) external override onlyMinter whenMintersNotLocked returns (uint256) {
        SubCollection storage sc = subcollections[subcollectionId];
        require(sc.exists, 'Subcollection does not exist');
        require(sc.sType==SubCollectionType.RANDOM_SEQUENTIAL, 'Subcollection type must be random sequential');
        require(sc.currentTokenId>=sc.minTokenId, 'Token id less than min');
        require(sc.currentTokenId<=sc.maxTokenId, 'Token id greater than max');

        //new sequential token id
        uint256 tokenId = sc.currentTokenId;

        //increment after assignment
        sc.currentTokenId++;

        //using last blockhash, to address, subcollectionId, tokenId
        uint256 seed = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), to, subcollectionId, tokenId))
        );

        _mintTo(to, subcollectionId, tokenId, seed);

        if(proofs.length>0) {
            _addProofs(tokenId, proofs);
        }

        return tokenId;
    }

    /**
     * @notice Add Proof to a token after the fact.
     */
    function addProof(uint256 tokenId, IProofOfGoodLedger.Reference[] calldata proofs) external override onlyMinter {
        if(proofs.length>0) {
            _addProofs(tokenId, proofs);
        }
    }

    function _addProofs(uint256 tokenId, IProofOfGoodLedger.Reference[] calldata proofs) internal {
        //current EVM spec requires to recreate/copy each struct individually
        for(uint256 i=0; i<proofs.length; i++) {
            pogLinks[tokenId].push(proofs[i]);
        }
    }

    /**
     * @notice Sets the unique uri for token `tokenId` to `uri`. Overrides any Subcollection URI.
     */
    function updateTokenURI(uint256 tokenId, string calldata uri) external onlyMinter {
        TokenInfo storage i = tokenInfoMap[tokenId];
        require(i.seed>0);

        i.tokenURI = uri;
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for an official pog pack.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        TokenInfo memory i = tokenInfoMap[tokenId];

        if(bytes(i.tokenURI).length>0) {
            return string(abi.encodePacked(i.tokenURI));
        } else {
            SubCollection memory sc = subcollections[i.subcollectionId];
            require(sc.exists);

            return string(abi.encodePacked(sc.baseURI, tokenId.toString(), ".json"));
        }
    }

    /**
     * @notice returns all current entries in the NFT pool for `subcollection`
     */
    function getSubcollectionEntries(uint32 _subcollectionId) public view onlyMinter returns (PogPoolEntry[] memory entries) {
        return subcollections[_subcollectionId].entries;
    }

    /**
     * @notice Get available entries count by subcollectionId
     */
    function getPoolEntryCount(uint32 subcollectionId) external view onlyMinter returns (uint256) {
        return subcollections[subcollectionId].entries.length;
    }

    /**
     * @notice Gets the Token metadata associated with `tokenId`
     */
    function getTokenInfo(uint256 tokenId) external view override returns (IPogToken.TokenInfo memory) {
        return tokenInfoMap[tokenId];
    }

    /**
     * @notice Gets the pog references `tokenId`
     */
    function getTokenLedgerReferences(uint256 _tokenId) public view returns (IProofOfGoodLedger.Reference[] memory proofs) {
        return pogLinks[_tokenId];
    }

    /**
     * @dev Get details of a ledger entry list from the ledger
     *
     */
    function getLedgerDetails(uint256 tokenId) external view returns (IProofOfGoodLedger.ProofOfGoodEntryView[] memory pogs) {
        return IProofOfGoodLedger(pogLedgerAddress).getLedgerDetails(pogLinks[tokenId]);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // check if address set
        if (iTokenHooksAddress != address(0)) {
            ITokenHooks(iTokenHooksAddress).beforeTokenTransferHook(from, to, tokenId);
        }
    }

     /**
     * @notice Burn a pog.
     */
    function burn(uint256 tokenId) public override onlyMinter {
        _burn(tokenId);
        emit PogBurned(tokenId);
    }
}