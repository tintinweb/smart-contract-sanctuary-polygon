// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../storage/facets/ERC721StorageFacet.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721Receiver.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC2981.sol";

contract NeoFilms721Facet is ERC721StorageFacet, IERC721, IERC2981, IERC721Metadata {
    function initialize() external {
        LibDiamond.enforceIsContractOwner();
        ERC721FacetStorage storage _ds = erc721Storage();
        /* string memory name_, string memory symbol_ */
        _ds._name = "Neo NFTS";
        _ds._symbol = "NEO";
        _ds.maxSupply = 3333;
        _ds.publicMintPrice = 65 ether;
        _ds._idx = 483;
        _ds.totalRemainingFreeMints = 330;
        setBaseURI("https://neogoldpass.mypinata.cloud/ipfs/QmeeaDbEb1Qkz9wyNshtmiH54QjHfbnfBqD4rTNFPsJrFw/");
        _ds.royaltyReceiver = 0x491968b05D95979BA3a52D73D8a39EA96693f011;
        _ds.royaltyFraction = 500;
    }

    function setRoyaltyReceiver(address receiver) external {
        LibDiamond.enforceIsContractOwner();
        ERC721FacetStorage storage _ds = erc721Storage();
        _ds.royaltyReceiver = receiver;
    }

    function setRoyaltyFraction(uint96 fraction) external {
        LibDiamond.enforceIsContractOwner();
        ERC721FacetStorage storage _ds = erc721Storage();
        _ds.royaltyFraction = fraction;
    }

    function getMaxSupply() public view returns (uint256) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds.maxSupply - _ds.totalRemainingFreeMints - _ds.totalBtgoFreeClaimsRemaining;
    }

    function getBlockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    function setPublicMintPrice(uint256 price) external {
        LibDiamond.enforceIsContractOwner();
        ERC721FacetStorage storage _ds = erc721Storage();
        _ds.publicMintPrice = price;
    }

    function getPublicMintPrice() external view returns (uint256) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds.publicMintPrice;
    }

    function isPaused() external view returns (bool) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds.paused;
    }

    function pause() external {
        LibDiamond.enforceIsContractOwner();
        ERC721FacetStorage storage _ds = erc721Storage();
        _ds.paused = true;
    }

    function unpause() external {
        LibDiamond.enforceIsContractOwner();
        ERC721FacetStorage storage _ds = erc721Storage();
        _ds.paused = false;
    }

    function enforceNotPaused() internal view {
        ERC721FacetStorage storage _ds = erc721Storage();
        require(!_ds.paused, "Contract is paused");
    }

    event TipGiven(address indexed by, uint256 amount);

    function publicMintToWithTip(address to, uint256 amount, uint256 tipAmount) payable external {
        enforceNotPaused();
        ERC721FacetStorage storage _ds = erc721Storage();
        require(msg.value >= _ds.publicMintPrice * amount + tipAmount, "Not enough MATIC sent to mint and tip");
        require(totalSupply() + amount <= getMaxSupply(), "Trying to mint more than the max supply");
        for (uint i = 0; i < amount; i++) {
            _mint(to, 0);
        }
        _ds.totalBtgoFreeClaimsRemaining += amount/2;
        _ds.btgoFreeClaimedEarned[to] += amount/2;
        if (tipAmount > 0) {
            emit TipGiven(msg.sender, tipAmount);
        }
    }

    event MintedFromEth(address indexed by, uint256 amount);

    function mintFromEth(uint256 amount, address to) external {
        LibDiamond.enforceIsContractOwner();
        ERC721FacetStorage storage _ds = erc721Storage();
        require(totalSupply() + amount <= getMaxSupply(), "Trying to mint more than the max supply");
        for (uint i = 0; i < amount; i++) {
            _mint(to, 0);
        }
        _ds.totalBtgoFreeClaimsRemaining += amount/2;
        _ds.btgoFreeClaimedEarned[to] += amount/2;
        emit MintedFromEth(to, amount);
    }

    function adminMintTo(address to, uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        require(totalSupply() + amount <= getMaxSupply(), "Trying to mint more than the max supply");
        for (uint i = 0; i < amount; i++) {
            _mint(to, 0);
        }
    }

    function getReservedTokens(address user) external view returns (uint256[] memory) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds.reservedTokens[user];
    }

    function setReservedTokens(LibDiamond.ReservedTokens[] calldata reservedTokens) external {
        LibDiamond.enforceIsContractOwner();
        ERC721FacetStorage storage _ds = erc721Storage();
        for (uint256 i = 0; i < reservedTokens.length; i++) {
            _ds.reservedTokens[reservedTokens[i].recipient] = reservedTokens[i].ids;
        }
    }

    function claimReserved() external {
        ERC721FacetStorage storage _ds = erc721Storage();
        uint256[] memory tokenIds = _ds.reservedTokens[msg.sender];
        require(tokenIds.length > 0, "No reserved tokens for this address");
        mintMultipleSpecificTo(tokenIds.length, msg.sender, tokenIds);
        delete _ds.reservedTokens[msg.sender];
    }

    function setClaimFree(address[] calldata accounts, uint256[] calldata amounts) external {
        require(accounts.length == amounts.length, "Lengths must match");
        LibDiamond.enforceIsContractOwner();
        ERC721FacetStorage storage _ds = erc721Storage();
        for (uint256 i = 0; i < accounts.length; i++) {
            _ds.freeClaimsRemaining[accounts[i]] = amounts[i];
        }
    }

    function claimFree() external {
        ERC721FacetStorage storage _ds = erc721Storage();
        uint256 freeClaimsRemaining = _ds.freeClaimsRemaining[msg.sender];
        require(freeClaimsRemaining > 0, "None left to claim for free");
        for (uint i = 0; i < freeClaimsRemaining; i++) {
            _mint(msg.sender, 0);
            _ds.freeClaimsRemaining[msg.sender] -= 1;
            _ds.totalRemainingFreeMints -= 1;
        }
    }

    function getClaimFreeRemaining(address user) external view returns (uint256) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds.freeClaimsRemaining[user];
    }

    function getTotalBtgoFreeClaimsRemaining() public view returns (uint256) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds.totalBtgoFreeClaimsRemaining;
    }

    function getBtgoFreeClaimsRemaining(address user) public view returns (uint256) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds.btgoFreeClaimedEarned[user] - _ds.btgoFreeClaimed[user];
    }

    function claimBtgoFree() external {
        ERC721FacetStorage storage _ds = erc721Storage();
        uint256 amount = getBtgoFreeClaimsRemaining(msg.sender);
        require(amount > 0, "Trying to claim more than remaining");
        _ds.btgoFreeClaimed[msg.sender] += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender, 0);
        }
    }

    function getBtgoClaimed(address user) public view returns (uint256) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds.btgoFreeClaimed[user];
    }

    function mintMultipleSpecificTo(uint amount, address to, uint256[] memory tokenIds) internal {
        require(tokenIds.length == amount, "TokenIds length does not match amount");
        for (uint i = 0; i < amount; i++) {
            _mint(to, tokenIds[i]);
        }
    }

    function _mint(address to_, uint256 tokenId) private {
        ERC721FacetStorage storage _ds = erc721Storage();
        if(tokenId == 0){
            tokenId = _ds._idx;
            _ds._idx += 1;
        }
        _ds._balances[to_] += 1;
        _ds._owners[tokenId] = to_;
        _ds.totalSupply += 1;
        emit Transfer(address(0), to_, tokenId);
    }

    function getCurrentIndex() public view returns (uint256) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds._idx;
    }

    function setCurrentIndex(uint256 _idx) public {
        ERC721FacetStorage storage _ds = erc721Storage();
        _ds._idx = _idx;
    }

    function setMaxSupply(uint256 amount) public {
        ERC721FacetStorage storage _ds = erc721Storage();
        _ds.maxSupply = amount;
    }

    function totalSupply() public view returns (uint256) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds.totalSupply;
    }

    // ERC721 interface ID is 0x80ac58cd
    bytes4 constant ERC721_INTERFACE_ID = 0x80ac58cd;

    function isERC721Contract(address addr) public view returns (bool) {
        if (!isContract(addr)) {
            return false;
        }

        try IERC721(addr).supportsInterface(ERC721_INTERFACE_ID) returns (bool supportsERC721) {
            return supportsERC721;
        } catch {
            return false;
        }
        return false;
    }

    //return IERC721(0xc7E77C602D549747AB33C2F0137Cbcb42eeF2bB8).balanceOf(account) > 0;

    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

    function adminMintMultipleSpecificTo(uint amount, address to, uint256[] memory tokenIds) external {
        ERC721FacetStorage storage _ds = erc721Storage();
        require(tokenIds.length == amount, "TokenIds length does not match amount");
        require(_ds._idx + amount <= getMaxSupply(), "Trying to mint more than the max supply");
        LibDiamond.enforceIsContractOwner();
        _ds.adminMintedAmount += amount;
        mintMultipleSpecificTo(amount, to, tokenIds);
    }

    function symbol() public view virtual override returns (string memory) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds._symbol;
    }

    function name() public view virtual override returns (string memory) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds._name;
    }

    function baseURI() external view returns (string memory) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds.baseUrl;
    }

    function tokenURI(uint256 tokenID_) public view override returns (string memory) {
        _requireMinted(tokenID_);
        ERC721FacetStorage storage _ds = erc721Storage();
        string memory _base = _ds.baseUrl;
        return string(abi.encodePacked(_base, tokenID_));
    }

    function setBaseURI(string memory baseUri) public {
        ERC721FacetStorage storage _ds = erc721Storage();
        _ds.baseUrl = baseUri;
    }

    function withdrawToken(address _tokenContract, uint256 _amount) public {
        LibDiamond.enforceIsContractOwner();
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }

    function withdrawNft(address _nft, uint256[] memory tokenIds) public {
        LibDiamond.enforceIsContractOwner();
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            IERC721(_nft).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }

    function withdrawEth() public {
        LibDiamond.enforceIsContractOwner();
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
        require(success);
    }

    // ERC721 INTERFACE FUNCTIONS

    function balanceOf(address account_) external override view returns (uint256) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds._balances[account_];
    }

    function ownerOf(uint256 tokenID_) public view virtual override returns (address) {
        _requireMinted(tokenID_);
        return _owner(tokenID_);
    }

    function transfer(address to_, uint256 amount_) external returns (bool) {
        return _transfer(msg.sender, to_, amount_);
    }

    function transferFrom(address from_, address to_, uint256 tokenID_) override external {
        _requireAuth(from_, tokenID_);
        _transfer(from_, to_, tokenID_);
    }

    function approve(address operator_, uint256 tokenID_) override external {
        _approve(msg.sender, operator_, tokenID_);
    }

    function setApprovalForAll(address operator_, bool approved_) external override {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    function getApproved(uint256 tokenId) external override view returns (address operator) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds._tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner_, address operator_) override public view returns (bool) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds._operatorApprovals[owner_][operator_];
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenID_, bytes memory data_) public override {
        _requireAuth(msg.sender, tokenID_);
        _safeTransfer(from_, to_, tokenID_, data_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenID_) external override {
        safeTransferFrom(from_, to_, tokenID_, "");
    }

    // PRIVATE FUNCTIONS

    function _setApprovalForAll(address owner_, address operator_, bool approved_) internal virtual {
        require(owner_ != operator_, "ERC721: approve to caller");

        ERC721FacetStorage storage _ds = erc721Storage();
        _ds._operatorApprovals[owner_][operator_] = approved_;

        emit ApprovalForAll(owner_, operator_, approved_);
    }

    function _approve(address owner_, address operator_, uint256 tokenID_) private returns (bool) {
        require(ownerOf(tokenID_) != operator_, "ERC721: Approval to current owner");
        _requireAuth(owner_, tokenID_);

        ERC721FacetStorage storage _ds = erc721Storage();
        _ds._tokenApprovals[tokenID_] = operator_;

        emit Approval(ownerOf(tokenID_), operator_, tokenID_);
        return true;
    }

    function _transfer(address from_, address to_, uint256 tokenID_) private returns (bool) {
        _requireMinted(tokenID_);
        _requireOwner(from_, tokenID_);
        /* _requireAuth(from_, tokenID_); */

        ERC721FacetStorage storage _ds = erc721Storage();

        delete _ds._tokenApprovals[tokenID_];
        _ds._owners[tokenID_] = to_;
        _ds._balances[msg.sender] -= 1;
        _ds._balances[to_] += 1;

        emit Transfer(msg.sender, to_, tokenID_);
        return true;
    }

    function _safeTransfer(address from_, address to_, uint256 tokenID_, bytes memory data_) internal {
        _transfer(from_, to_, tokenID_);
        _requireReciever(from_, to_, tokenID_, data_);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _requireAuth(address from_, uint256 tokenID_) private view {
        require(_hasAuth(from_, tokenID_), "ERC721: Not token owner or approved");
    }

    function _requireOwner(address from_, uint256 tokenID_) private view {
        require(_owner(tokenID_) == from_, "ERC721: Not token owner");
    }

    function _requireReciever(address from_, address to_, uint256 tokenID_, bytes memory data_) private {
        require(_checkOnERC721Received(from_, to_, tokenID_, data_), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _owner(uint256 tokenID_) internal view returns (address) {
        ERC721FacetStorage storage _ds = erc721Storage();
        return _ds._owners[tokenID_];
    }

    function _hasAuth(address from_, uint256 tokenID_) internal view returns (bool) {
        address owner = _owner(tokenID_);
        return owner == from_ || isApprovedForAll(owner, from_);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owner(tokenId) != address(0);
    }

    function _hasContract(address account_) private view returns (bool) {
        return account_.code.length > 0;
    }

    function _checkOnERC721Received(address from_, address to_, uint256 tokenID_, bytes memory data_) private returns (bool) {
        if (_hasContract(to_)) {
            try IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenID_, data_) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address, uint256) {
        ERC721FacetStorage storage _ds = erc721Storage();
        uint256 royaltyAmount = (salePrice * _ds.royaltyFraction) / 10000;

        return (_ds.royaltyReceiver, royaltyAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    struct ReservedTokens {
        uint256[] ids;
        address recipient;
    }

function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

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
pragma solidity ^0.8.0;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import "../structs/ERC721FacetStorage.sol";

contract ERC721StorageFacet {
  function erc721Storage() internal pure returns (ERC721FacetStorage storage ds) {
      bytes32 position =  keccak256("diamond.erc721.diamond.storage");
      assembly {
          ds.slot := position
      }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ERC721FacetStorage {
  string _name;
  string _symbol;
  uint256 _idx;
  mapping(uint256 => address) _owners;
  mapping(address => uint256) _balances;
  mapping(uint256 => address) _tokenApprovals;
  mapping(address => mapping(address => bool)) _operatorApprovals;
  uint256 publicMintPrice;
  uint256 whitelistPrice;
  string baseUrl;
  string hiddenFullUrl;
  bool revealed;
  mapping(address => bool) whitelisted;
  uint256 totalSupply;
  uint256 startTime;
  uint256 adminMintedAmount;
  uint256 whitelistMintedAmount;
  uint256 publicMintedAmount;
  bool paused;
  uint256 maxSupply;
  mapping(address => uint256) btgoFreeClaimed;
  mapping(address => uint256) btgoFreeClaimedEarned;
  mapping(address => uint256[]) reservedTokens;
  mapping(address => uint256) freeClaimsRemaining;
  uint256 totalRemainingFreeMints;
  uint256 totalBtgoFreeClaimsRemaining;
  address royaltyReceiver;
  uint96 royaltyFraction;
}