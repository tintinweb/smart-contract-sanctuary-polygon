// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./ERC1155URIStorageSrb.sol";
import "./AdminControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "./JsonBuilder.sol";

import {IPaperPotMetadata} from "./PaperPotMetadata.sol";
import "./PaperPotEnum.sol";


contract PaperPot is AdminControl, ERC1155, ERC1155Supply, ERC1155URIStorageSrb, JsonBuilder {
    IPaperPotMetadata public _metadataGenerator;
    // This is multiple to handle possibility of future seed series
    address[] public SEED_CONTRACT_ADDRESSES;
    uint constant POT_TOKENID = 1;
    uint constant FERTILIZER_TOKENID = 2;
    uint constant WATER_TOKENID = 3;
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint constant POTTED_PLANT_BASE_TOKENID = 10 ** 6;
    uint constant SHRUB_BASE_TOKENID = 2 * 10 ** 6;
    bytes4 constant ERC1155ID = 0xd9b67a26;

    bool public mintingPaused = true;
    bool private freeze = false;
    uint private NFTTicketTokenId;
    address private NFTTicketAddress;

    string private CONTRACT_URI = "ipfs://QmZ7GM5AYS8fZKXhVJ518uHV4Wdx8nAdyquPhDH6TNY4Q5";

    uint private _fertForHappy = 3;
    uint private _fertForName = 5;

    uint public pottedPlantCurrentIndex = 0;
    uint public shrubCurrentIndex = 0;
    uint private waterNonce = 0;

    struct Growth {
        uint16 growthBps;   // 0 to 10000
        uint lastWatering;  // timestamp of the last watering
    }

    using Strings for uint256;

    // Valid seedContractAddresses
    mapping(address => bool) private _seedContractAddresses;

    // True indicates sad seed
    // IMPORTANT: even though it is possible to add new seed contract addresses tokenIds must not be reused
    mapping(uint256 => bool) private _sadSeeds;

    // seed planted in potted plant (tokenId, seedTokenId)
    mapping(uint => uint) private _plantedSeed;

    // seed that shrub is based on (tokenId, seedTokenId)
    mapping(uint => uint) private _shrubBaseSeed;

    // indicates growth state of a potted plant
    mapping(uint => Growth) private _growthState;

    // indicates order number of a potted plant (only increases)
    mapping(uint => uint) private _pottedPlantNumber;

    // indicates number of each class of potted plant
    mapping(NftClass => uint) public pottedPlantsByClass;

    // Royalties.
    bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
    mapping(uint256 => address payable) internal _royaltiesReceivers;
    mapping(uint256 => uint256) internal _royaltiesBps;


    event Grow(uint tokenId, uint16 growthAmount, uint16 growthBps);
    event Plant(uint256 tokenId, uint256 seedTokenId, address account);
    event Happy(uint256 tokenId);
    event Harvest(uint256 pottedPlantTokenId, uint256 shrubTokenId, address account);

// Constructor
    constructor(
        address[] memory seedContractAddresses,
        uint[] memory sadSeeds,
        string[3] memory resourceUris_,
        address metadataGenerator_
    ) ERC1155("") {
        require(seedContractAddresses.length > 0, "Must be at least 1 seedContractAddress");
        require(resourceUris_.length == 3, "must be 3 uris - pot, fertilizer, water");
        // setup the initial admin as the contract deployer
        setAdmin(_msgSender(), true);
        // Set the uri for pot, fertilizer, water
        for (uint i = 0; i < resourceUris_.length; i++) {
            _setURI(i + 1, resourceUris_[i]);
            emit URI(resourceUris_[i], i+1);
        }
        for (uint i = 0; i < seedContractAddresses.length; i++) {
            _seedContractAddresses[seedContractAddresses[i]] = true;
            SEED_CONTRACT_ADDRESSES.push(seedContractAddresses[i]);
        }
        for (uint i = 0; i < sadSeeds.length; i++) {
            _sadSeeds[sadSeeds[i]] = true;
        }
        _metadataGenerator = IPaperPotMetadata(metadataGenerator_);
    }

    // Receive Function


    // Fallback Function

    // External Functions

    function plantAndMakeHappy(address _seedContractAddress, uint _seedTokenId) public {
        // User must burn 3 Fertilizer to make the seed happy (can be configured later)
        _burn(_msgSender(), FERTILIZER_TOKENID, _fertForHappy);
        // Ensure that the seed is sad
        require(_sadSeeds[_seedTokenId] == true, "PaperPot: Seed already happy");
        // Update the sad metadata for _seedTokenId
        _sadSeeds[_seedTokenId] = false;
        // run plant
        uint pottedPlantTokenId = plant(_seedContractAddress, _seedTokenId);
        // emit happy event
        emit Happy(pottedPlantTokenId);
    }

    function _water(uint[] memory _tokenIds, bool fertilizer) internal {
        // Burn the water
        _burn(_msgSender(), WATER_TOKENID, _tokenIds.length);
        if (fertilizer) {
            // Burn the fertilizer
            _burn(_msgSender(), FERTILIZER_TOKENID, _tokenIds.length);
        }
        // Loop through and water each plant
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(_eligibleForWatering(_tokenIds[i]), "PaperPot: provided tokenIds not eligible");
            require(balanceOf(_msgSender(), _tokenIds[i]) > 0, "PaperPot: Potted plant not owned by sender");
            require(_growthState[_tokenIds[i]].growthBps < 10000, "PaperPot: Potted plant is already fully grown");
            waterNonce++;
            uint16 relativeGrowth = fertilizer ? (
                _sadSeeds[_plantedSeed[_tokenIds[i]]] ?
                    getRandomInt(113, 150, waterNonce) : // Case: Sad Potted Plant with Fertilizer (150-263)
                    getRandomInt(225, 300, waterNonce)    // Case: Happy Potted Plant with Fertilizer (300-525)
            ) : (
                _sadSeeds[_plantedSeed[_tokenIds[i]]] ?
                    getRandomInt(75, 100, waterNonce) : // Case: Sad Potted Plant (100-175)
                    getRandomInt(150, 200, waterNonce)    // Case: Happy Potted Plant (200-350)
            );
            _growPlant(_tokenIds[i], relativeGrowth);
            emit URI(uri(_tokenIds[i]),_tokenIds[i]);
        }
    }

    function water(uint[] calldata _tokenIds) external {
        _water(_tokenIds, false);
    }

    function waterWithFertilizer(uint[] calldata _tokenIds) external {
        _water(_tokenIds, true);
    }

    function setShrubName(uint tokenId_, string memory newName_) external {
        // Must be the tokenId of a shrub
        require(tokenId_ > SHRUB_BASE_TOKENID, "PaperPot: Invalid tokenId");
        // Must own SHRUB
        require(balanceOf(_msgSender(), tokenId_) > 0, "PaperPot: Must own Shrub to name");
        // Must pay 5 fertilizer
        _burn(_msgSender(), FERTILIZER_TOKENID, _fertForName);
        // update the name based on the seedTokenId
        _metadataGenerator.setShrubName(_shrubBaseSeed[tokenId_], newName_);
    }

    function harvest(uint _tokenId) external {
        // Ensure that tokenId is eligible for Harvest
        require(_growthState[_tokenId].growthBps == 10000, "PaperPot: Not eligible for harvest");
        // Ensure that tokenId is owned by caller
        require(balanceOf(_msgSender(), _tokenId) > 0, "PaperPot: Potted plant not owned by sender");
        // burn the potted plant
        _burn(_msgSender(), _tokenId, 1);
        // increment shrubCurrentIndex;
        shrubCurrentIndex++;
        uint shrubTokenId = SHRUB_BASE_TOKENID + shrubCurrentIndex;
        // set metadata for shrub
        _shrubBaseSeed[shrubTokenId] = _plantedSeed[_tokenId];
        // mint the shrub to the caller
        _mint(_msgSender(), shrubTokenId, 1, new bytes(0));
        emit Harvest(_tokenId, shrubTokenId, _msgSender());
//        emit URI(uri(shrubTokenId), shrubTokenId);
    }

    // Owner Write Functions
    function setNftTicketInfo(uint NFTTicketTokenId_, address NFTTicketAddress_) external adminOnly {
        NFTTicketTokenId = NFTTicketTokenId_;
        NFTTicketAddress = NFTTicketAddress_;
    }

    function addSeedContractAddress(address _seedContractAddress) external adminOnly {
        require(_seedContractAddresses[_seedContractAddress] == false, "address already on seedContractAddresses");
        require(ERC165Checker.supportsInterface(_seedContractAddress, type(IERC721).interfaceId), "not a valid ERC-721 implementation");
        SEED_CONTRACT_ADDRESSES.push(_seedContractAddress);
        _seedContractAddresses[_seedContractAddress] = true;
    }

    function removeSeedContractAddress(address _seedContractAddress) external adminOnly {
        require(_seedContractAddresses[_seedContractAddress] == true, "address not on seedContractAddresses");
        _seedContractAddresses[_seedContractAddress] = false;
        for (uint i = 0; i < SEED_CONTRACT_ADDRESSES.length; i++) {
            if (SEED_CONTRACT_ADDRESSES[i] == _seedContractAddress) {
                SEED_CONTRACT_ADDRESSES[i] = SEED_CONTRACT_ADDRESSES[SEED_CONTRACT_ADDRESSES.length - 1];
                SEED_CONTRACT_ADDRESSES.pop();
                return;
            }
        }
    }

    function adminMintPot(address _to, uint _amount) external adminOnly {
        _mint(_to, POT_TOKENID, _amount, new bytes(0));
    }

    function unpauseMinting() external adminOnly {
        mintingPaused = false;
    }

    function pauseMinting() external adminOnly {
        mintingPaused = true;
    }

    function mintFromTicket(address _to, uint _amount, uint ticketTokenId) external returns (bool) {
        require(mintingPaused == false, "PaperPot: minting paused");
        require(ticketTokenId == NFTTicketTokenId, "PaperPot: invalid ticket tokenId");
        require(_msgSender() == NFTTicketAddress, "PaperPot: invalid sender");
        _mint(_to, POT_TOKENID, _amount, new bytes(0));
        return true;
    }

    function adminSetFreeze(bool freeze_) external adminOnly {
        freeze = freeze_;
    }

    function adminDistributeWater(address _to, uint _amount) external adminOnly {
        _mint(_to, WATER_TOKENID, _amount, new bytes(0));
    }

    function adminDistributeFertilizer(address _to, uint _amount) external adminOnly {
        _mint(_to, FERTILIZER_TOKENID, _amount, new bytes(0));
    }

    function adminSetSadSeeds(uint[] memory seedTokenIds, bool[] memory isSads) external adminOnly {
        require(seedTokenIds.length == isSads.length, "seedTokenIds and isSads must be equal length");
        for (uint i = 0; i < seedTokenIds.length; i++) {
            _sadSeeds[seedTokenIds[i]] = isSads[i];
        }
    }

    function adminSetFertForHappy(uint fertForHappy_) external adminOnly {
        _fertForHappy = fertForHappy_;
    }

    function adminSetFertForName(uint fertForName_) external adminOnly {
        _fertForName = fertForName_;
    }

    function setURI(uint tokenId_, string calldata tokenURI_) external adminOnly {
        _setURI(tokenId_, tokenURI_);
        emit URI(tokenURI_, tokenId_);
    }

    function setMetadataGenerator(address metadataGenerator_) external adminOnly {
        require(ERC165Checker.supportsInterface(metadataGenerator_, type(IPaperPotMetadata).interfaceId), "PaperPot: not a valid IPaperPotMetadata implementation");
        _metadataGenerator = IPaperPotMetadata(metadataGenerator_);
    }

    function adminEmitUri(uint tokenId_) external adminOnly {
        emit URI(uri(tokenId_), tokenId_);
    }

    function setContractURI(string memory _contractUri) external adminOnly {
        CONTRACT_URI = _contractUri;
    }

    // External View

    function getPlantedSeed(uint _tokenId) external view validPottedPlant(_tokenId) returns (uint seedTokenId) {
        return _plantedSeed[_tokenId];
    }

    function getGrowthLevel(uint _tokenId) external view validPottedPlant(_tokenId) returns (uint) {
        return _growthState[_tokenId].growthBps;
    }

    function getLastWatering(uint _tokenId) external view validPottedPlant(_tokenId) returns (uint) {
        return _growthState[_tokenId].lastWatering;
    }

    function eligibleForWatering(uint[] calldata _tokenIds) external view returns (bool eligible) {
        for (uint i = 0; i < _tokenIds.length; i++) {
            _validPottedPlant(_tokenIds[i]);
            // Check for duplicates
            for (uint j = 0; j < i; j++) {
                require(_tokenIds[j] != _tokenIds[i], "PaperPot: duplicate tokenId");
            }
            if (_eligibleForWatering(_tokenIds[i]) == false) {
                return false;
            }
        }
        return true;
    }

    function isSeedSad(uint seedTokenId_) external view returns (bool) {
        return _sadSeeds[seedTokenId_];
    }

    function contractURI() external view returns (string memory) {
        return CONTRACT_URI;
    }

    // Public Functions

    function plant(address _seedContractAddress, uint _seedTokenId) public returns(uint) {
        // Pot is decremented from msg_sender()
        // Seed with _seedTokenId gets transferred to the Zero address (burned)
        // Mint new potted plant with tokenId POTTED_PLANT_BASE_TOKENID + pottedPlantCurrentIndex
        // Save metadata of potted plant
        // increment pottedPlantCurrentIndex

        // _seedContractAddress must be valid
        require(_seedContractAddresses[_seedContractAddress] == true, "Invalid seedContractAddress");
        // must own a pot
        require(balanceOf(_msgSender(), POT_TOKENID) > 0, "Must own a pot token to plant");
        // must own the specified seed
        require(IERC721(_seedContractAddress).ownerOf(_seedTokenId) == _msgSender(), "Must own seed to plant");
        // Pot is decremented from msg_sender()
        _burn(_msgSender(), POT_TOKENID, 1);
        // Seed with _seedTokenId gets transferred to the Zero address (burned)
        IERC721(_seedContractAddress).transferFrom(_msgSender(), BURN_ADDRESS, _seedTokenId);
        // increment pottedPlantCurrentIndex
        pottedPlantCurrentIndex++;
        NftClass class = getClassFromSeedId(_seedTokenId);
        pottedPlantsByClass[class]++;
        // Mint new potted plant with tokenId POTTED_PLANT_BASE_TOKENID + pottedPlantCurrentIndex
        uint tokenId = POTTED_PLANT_BASE_TOKENID + pottedPlantCurrentIndex;
        _mint(_msgSender(), tokenId, 1, new bytes(0));
        _pottedPlantNumber[tokenId] = pottedPlantsByClass[class];
        // Save metadata of potted plant
        _plantedSeed[tokenId] = _seedTokenId;
        // Set initial growth state of potted plant
        _growthState[tokenId] = Growth({
            growthBps: 0,
            lastWatering: 1             // Initialized to 1 to differentiate from uninitialized
        });
        emit Plant(tokenId, _seedTokenId, _msgSender());
        emit URI(uri(tokenId), tokenId);
        return tokenId;
    }

    function uri(uint _tokenId) public view override(ERC1155, ERC1155URIStorageSrb) returns (string memory) {
        require(exists(_tokenId), "PaperPot: URI query for nonexistent token");
        // use the baseUri for the pots, water, and fertilizer
        string memory storageUri = super.uri(_tokenId);
        if (bytes(storageUri).length > 0) {
            return storageUri;
        }
        if (_tokenId < SHRUB_BASE_TOKENID) {
            return generatePottedPlantMetadata(_tokenId);
        } else {
            return generateShrubMetatdata(_tokenId);
        }
    }

    // Internal Functions

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        if (from != address(0)) {
            // sufficient balance check can be skipped for minting
            for (uint i = 0; i < ids.length; i++) {
                require(balanceOf(from, ids[i]) >= amounts[i], "PaperPot: Insufficient balance");
            }
        }
        require(freeze == false, "Shrub: freeze in effect");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _eligibleForWatering(uint tokenId) internal view returns (bool) {
        Growth memory potGrowth = _growthState[tokenId];
        require(potGrowth.lastWatering != 0, "PaperPot: ineligible tokenId");
        // Check if timestamp is more than 8 hours ago
        if (block.timestamp < potGrowth.lastWatering + 8 hours) {
            return false;
        }
        // Check that timestamp is from previous day
        if (block.timestamp / 1 days == potGrowth.lastWatering / 1 days) {
            return false;
        }
        return true;
    }

    // Private Functions

    function _growPlant(uint _tokenId, uint16 growthAmount) private returns (uint growthBps) {
        if (_growthState[_tokenId].growthBps + growthAmount > 10000) {
            emit Grow(_tokenId, 10000 - _growthState[_tokenId].growthBps, 10000);
            _growthState[_tokenId].growthBps = 10000;
        } else {
            _growthState[_tokenId].growthBps += growthAmount;
            emit Grow(_tokenId, growthAmount, _growthState[_tokenId].growthBps);
        }
        _growthState[_tokenId].lastWatering = block.timestamp;
        return _growthState[_tokenId].growthBps;
    }

    function generatePottedPlantMetadata(uint _tokenId) private view returns (string memory) {
        uint seedTokenId = _plantedSeed[_tokenId];
        return _metadataGenerator.tokenMetadata(
            getPottedPlantName(_tokenId),
            seedTokenId,
            _growthState[_tokenId].growthBps,
            _sadSeeds[seedTokenId]
        );
    }

    function generateShrubMetatdata(uint _tokenId) private view returns (string memory) {
        uint seedTokenId = _shrubBaseSeed[_tokenId];
        return _metadataGenerator.shrubTokenMetadata(_tokenId, seedTokenId, _sadSeeds[seedTokenId]);
    }

    function getPottedPlantName(uint _tokenId) private view returns (string memory) {
        NftClass class = getClassFromSeedId(_plantedSeed[_tokenId]);
        string memory className = class == NftClass.wonder ? "Wonder" :
        class == NftClass.passion ? "Passion" :
        class == NftClass.hope ? "Hope" : "Power";
        return string(abi.encodePacked('Potted Plant of ',className,' #',_pottedPlantNumber[_tokenId].toString()));
    }

    function getRandomInt(uint16 _range, uint16 _min, uint _nonce) private view returns (uint16) {
        return uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _nonce))) % _range) + _min;
    }

    function seedIdInRange(uint256 _seedTokenId) private pure returns (bool) {
        return _seedTokenId > 0 && _seedTokenId < 10001;
    }

    function getClassFromSeedId(uint256 _seedTokenId) private pure returns (NftClass) {
        require(seedIdInRange(_seedTokenId), "seedTokenId not in range");
        if (_seedTokenId > 1110) {
            return NftClass.wonder;
        }
        if (_seedTokenId > 110) {
            return NftClass.passion;
        }
        if (_seedTokenId > 10) {
            return NftClass.hope;
        }
        return NftClass.power;
    }

    function _validPottedPlant(uint tokenId_) private view validPottedPlant(tokenId_) {}

    /**
 * @dev Throws if not a valid tokenId for a pottedplant or does not exist.
     */
    modifier validPottedPlant(uint tokenId_) {
        require(
            tokenId_ > POTTED_PLANT_BASE_TOKENID && tokenId_ < SHRUB_BASE_TOKENID,
            "PaperPot: invalid potted plant tokenId"
        );
        require(exists(tokenId_), "PaperPot: query for nonexistent token");
        _;
    }

//    Payment functions

    function setRoyalties(uint256 tokenId, address payable receiver, uint256 bps) external adminOnly {
        require(bps < 10000, "invalid bps");
        _royaltiesReceivers[tokenId] = receiver;
        _royaltiesBps[tokenId] = bps;
    }

    function royaltyInfo(uint256 tokenId, uint256 value) public view returns (address, uint256) {
        if (_royaltiesReceivers[tokenId] == address(0)) return (address(this), 1000*value/10000);
        return (_royaltiesReceivers[tokenId], _royaltiesBps[tokenId]*value/10000);
    }

    function p(
        address token,
        address recipient,
        uint amount
    ) external adminOnly {
        if (token == address(0)) {
            require(
                amount == 0 || address(this).balance >= amount,
                'invalid amount value'
            );
            (bool success, ) = recipient.call{value: amount}('');
            require(success, 'amount transfer failed');
        } else {
            require(
                IERC20(token).transfer(recipient, amount),
                'amount transfer failed'
            );
        }
    }

    receive() external payable {}


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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory _data
    ) internal virtual {
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

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155URIStorage.sol)
// Modified to not emit events when _setURI is called

pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 * Inspired by the ERC721URIStorage extension
 *
 * _Available since v4.6._
 */
abstract contract ERC1155URIStorageSrb is ERC1155 {
    using Strings for uint256;

    // Optional base URI
    string private _baseURI = "";

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the concatenation of the `_baseURI`
     * and the token-specific uri if the latter is set
     *
     * This enables the following behaviors:
     *
     * - if `_tokenURIs[tokenId]` is set, then the result is the concatenation
     *   of `_baseURI` and `_tokenURIs[tokenId]` (keep in mind that `_baseURI`
     *   is empty per default);
     *
     * - if `_tokenURIs[tokenId]` is NOT set then we fallback to `super.uri()`
     *   which in most cases will contain `ERC1155._uri`;
     *
     * - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
     *   uri value set, then the result is empty.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenURI)) : super.uri(tokenId);
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        _tokenURIs[tokenId] = tokenURI;
        // Remove this emit
//        emit URI(uri(tokenId), tokenId);
    }

    /**
     * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract AdminControl is Context {
    // Contract admins.
    mapping(address => bool) private _admins;

    /**
 * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _admins[_msgSender()] = true;
    }

    function setAdmin(address addr, bool add) public adminOnly {
        if (add) {
            _admins[addr] = true;
        } else {
            delete _admins[addr];
        }
    }

    function isAdmin(address addr) public view returns (bool) {
        return true == _admins[addr];
    }

    modifier adminOnly() {
        require(isAdmin(msg.sender), "AdminControl: caller is not an admin");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
pragma solidity 0.8.9;

contract JsonBuilder {
    function _openJsonObject() internal pure returns (string memory) {
        return string(abi.encodePacked("{"));
    }

    function _closeJsonObject() internal pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function _openJsonArray() internal pure returns (string memory) {
        return string(abi.encodePacked("["));
    }

    function _closeJsonArray() internal pure returns (string memory) {
        return string(abi.encodePacked("]"));
    }

    function _pushJsonPrimitiveStringAttribute(string memory key, string memory value, bool insertComma) internal pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": "', value, '"', insertComma ? ',' : ''));
    }

    function _pushJsonPrimitiveNonStringAttribute(string memory key, string memory value, bool insertComma) internal pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonComplexAttribute(string memory key, string memory value, bool insertComma) internal pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonArrayElement(string memory value, bool insertComma) internal pure returns (string memory) {
        return string(abi.encodePacked(value, insertComma ? ',' : ''));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
// Inspired by merge

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./JsonBuilder.sol";
import "./AdminControl.sol";
import "./PaperPotEnum.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "./basic/baseERC1155.sol";
import "./PaperPotEnum.sol";

interface IPaperPotMetadata {
    function tokenMetadata(
        string memory name,
        uint seedTokenId,
        uint growth,
        bool isSad
    ) external view returns (string memory);

    function shrubTokenMetadata(
        uint tokenId,
        uint seedTokenId,
        bool isSad
    ) external view returns (string memory);

    function setShrubName(uint seedTokenId_, string memory newName_) external;
}

contract PaperPotMetadata is IPaperPotMetadata, JsonBuilder, Ownable, AdminControl, ERC165 {
    uint constant POTTED_PLANT_BASE_TOKENID = 10 ** 6;

    struct ERC1155MetadataStructure {
        bool isImageLinked;
        string name;
        string description;
        string createdBy;
        string image;
        ERC1155MetadataAttribute[] attributes;
    }

    struct ERC1155MetadataAttribute {
        bool includeDisplayType;
        bool includeTraitType;
        bool isValueAString;
        string displayType;
        string traitType;
        string value;
    }
    
    struct CustomMetadata {
        string name;
        string imageUri;
        string bodyType;
        string background;
        string top;
        string hat;
        string expression;
        string leftHand;
        string rightHand;
        string clothes;
        string accessory;
    }

    string private _imageBaseUri;

    // images for the potted plants by class and stage
    mapping(NftClass => mapping(GrowthStages => string)) private _pottedPlantImages;

    // default image uri for shrubs based on class
    mapping(NftClass => string) private _shrubDefaultUris;

    // uri for shrubs based on seedTokenId
    mapping(uint => CustomMetadata) private _shrubSeedUris;

    using Base64 for string;
    using Strings for uint256;

    constructor(
        string memory imageBaseUri_,
        string[4] memory shrubDefaultUris_
) {
        require(shrubDefaultUris_.length == 4, "PaperPotMetadata: must be 4 uris - wonder, passion, hope, power");

        // setup the initial admin as the contract deployer
        setAdmin(_msgSender(), true);

        adminSetDefaultUris(shrubDefaultUris_);
        _imageBaseUri = imageBaseUri_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
        interfaceId == type(IPaperPotMetadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function tokenMetadata(
        string memory name,
        uint seedTokenId,
        uint growth,
        bool isSad
    ) external view returns (string memory) {
        string memory base64json = Base64.encode(bytes(string(abi.encodePacked(_getJson(name, seedTokenId, growth, isSad)))));
        return string(abi.encodePacked('data:application/json;base64,', base64json));
    }

    function shrubTokenMetadata(
        uint tokenId,
        uint seedTokenId,
        bool isSad
    ) external view returns (string memory) {
        string memory base64json = Base64.encode(bytes(string(abi.encodePacked(_getJsonShrub(tokenId, seedTokenId, isSad)))));
        return string(abi.encodePacked('data:application/json;base64,', base64json));
    }

    function _getJson(string memory name, uint _seedTokenId, uint _growth, bool _isSad) private view returns (string memory) {
        ERC1155MetadataStructure memory metadata = ERC1155MetadataStructure({
            isImageLinked: true,
            name: name,
            description: "created by Shrub.finance",
            createdBy: "Shrub.finance",
            image: string(abi.encodePacked(_getImage(_seedTokenId, _growth, _isSad))),
            attributes: _getJsonAttributes(_seedTokenId, _growth, _isSad)
        });
        return _generateERC1155Metadata(metadata);
    }

    function _getJsonShrub(uint _tokenId, uint _seedTokenId, bool _isSad) private view returns (string memory) {
        ERC1155MetadataStructure memory metadata = ERC1155MetadataStructure({
            isImageLinked: true,
            name: _getNameShrub(_tokenId, _seedTokenId),
            description: "created by Shrub.finance",
            createdBy: "Shrub.finance",
            image: string(abi.encodePacked(_getImageShrub(_seedTokenId))),
            attributes: _getJsonAttributesShrub(_tokenId, _seedTokenId, _isSad)
        });
        return _generateERC1155Metadata(metadata);
    }

    function _getImage(uint seedTokenId, uint growth, bool isSad) private view returns (string memory) {
        string[3] memory classRarity = getClassFromSeedId(seedTokenId);
        string memory class = classRarity[0];
        string memory sadString = isSad ? "sad" : "happy";
        uint growthLevel = getGrowthLevel(growth);
        return string(abi.encodePacked(_imageBaseUri, "pottedplant-", class, "-", growthLevel.toString(), "-", sadString, ".svg"));
    }

    function _getImageShrub(uint seedTokenId) private view returns (string memory) {
        // Return the seedTokenId specific image if it exists
        if (seedTokenId != 0) {
            string memory shrubSeedUri = _shrubSeedUris[seedTokenId].imageUri;
            if (bytes(shrubSeedUri).length > 0) {
                return shrubSeedUri;
            }
        }

        // Otherwise return the default based on class
        NftClass class = getNftClassFromSeedId(seedTokenId);
        return _shrubDefaultUris[class];
    }
    
    function _getNameShrub(uint tokenId_, uint seedTokenId_) private view returns (string memory) {
        // Return the seedTokenId specific image if it exists
        if (seedTokenId_ != 0) {
            string memory shrubSeedUriName = _shrubSeedUris[seedTokenId_].name;
            if (bytes(shrubSeedUriName).length > 0) {
                return shrubSeedUriName;
            }
        }
        
        // Otherwise return the default based on tokenId
        return string(abi.encodePacked("Shrub #", (tokenId_ - 2000000).toString()));
    }

    function getGrowthLevel(uint growth) internal pure returns (uint) {
        return growth / 2000;
    }

    function _getJsonAttributes(uint _seedTokenId, uint growth, bool isSad) private pure returns (ERC1155MetadataAttribute[] memory) {
        string[3] memory classRarity = getClassFromSeedId(_seedTokenId);
        ERC1155MetadataAttribute[] memory attributes = new ERC1155MetadataAttribute[](6);
        attributes[0] = _getERC721MetadataAttribute(false, true, true, "", "Class", classRarity[0]);
        attributes[1] = _getERC721MetadataAttribute(false, true, true, "", "Rarity", classRarity[1]);
        attributes[2] = _getERC721MetadataAttribute(false, true, false, "", "DNA", getDnaFromSeedId(_seedTokenId).toString());
        attributes[3] = _getERC721MetadataAttribute(false, true, false, "", "Growth", growth.toString());
        attributes[4] = _getERC721MetadataAttribute(false, true, true, "", "Emotion", isSad ? "Sad" : "Happy");
        attributes[5] = _getERC721MetadataAttribute(false, true, true, "", "Planted Seed", classRarity[2]);
        return attributes;
    }

    function _getJsonAttributesShrub(uint _tokenId, uint _seedTokenId, bool isSad) private view returns (ERC1155MetadataAttribute[] memory) {
        string[3] memory classRarity = getClassFromSeedId(_seedTokenId);
        ERC1155MetadataAttribute[] memory attributes = new ERC1155MetadataAttribute[](14);
        attributes[0] = _getERC721MetadataAttribute(false, true, true, "", "Class", classRarity[0]);
        attributes[1] = _getERC721MetadataAttribute(false, true, false, "", "DNA", getDnaFromSeedId(_seedTokenId).toString());
        attributes[2] = _getERC721MetadataAttribute(false, true, true, "", "Emotion", isSad ? "Sad" : "Happy");
        attributes[3] = _getERC721MetadataAttribute(false, true, true, "", "Planted Seed", classRarity[2]);
        attributes[4] = _getERC721MetadataAttribute(false, true, true, "", "Birth Order", (_tokenId - 2000000).toString());
        if (bytes(_shrubSeedUris[_seedTokenId].bodyType).length == 0) {
            return attributes;
        }
        uint i = 5;
        attributes[i] = _getERC721MetadataAttribute(false, true, true, "", "Body Type", _shrubSeedUris[_seedTokenId].bodyType);
        i++;
        if (bytes(_shrubSeedUris[_seedTokenId].background).length > 0) {
            attributes[i] = _getERC721MetadataAttribute(false, true, true, "", "Background", _shrubSeedUris[_seedTokenId].background);
            i++;
        }
        if (bytes(_shrubSeedUris[_seedTokenId].top).length > 0) {
            attributes[i] = _getERC721MetadataAttribute(false, true, true, "", "Top", _shrubSeedUris[_seedTokenId].top);
            i++;
        }
        if (bytes(_shrubSeedUris[_seedTokenId].hat).length > 0) {
            attributes[i] = _getERC721MetadataAttribute(false, true, true, "", "Hat", _shrubSeedUris[_seedTokenId].hat);
            i++;
        }
        if (bytes(_shrubSeedUris[_seedTokenId].leftHand).length > 0) {
            attributes[i] = _getERC721MetadataAttribute(false, true, true, "", "Left Hand", _shrubSeedUris[_seedTokenId].leftHand);
            i++;
        }
        if (bytes(_shrubSeedUris[_seedTokenId].rightHand).length > 0) {
            attributes[i] = _getERC721MetadataAttribute(false, true, true, "", "Right Hand", _shrubSeedUris[_seedTokenId].rightHand);
            i++;
        }
        if (bytes(_shrubSeedUris[_seedTokenId].clothes).length > 0) {
            attributes[i] = _getERC721MetadataAttribute(false, true, true, "", "Clothes", _shrubSeedUris[_seedTokenId].clothes);
            i++;
        }
        if (bytes(_shrubSeedUris[_seedTokenId].accessory).length > 0) {
            attributes[i] = _getERC721MetadataAttribute(false, true, true, "", "Accessory", _shrubSeedUris[_seedTokenId].accessory);
            i++;
        }
        if (bytes(_shrubSeedUris[_seedTokenId].expression).length > 0) {
            attributes[i] = _getERC721MetadataAttribute(false, true, true, "", "Expression", _shrubSeedUris[_seedTokenId].expression);
        }

        return attributes;
    }

    function _getERC721MetadataAttribute(
        bool includeDisplayType,
        bool includeTraitType,
        bool isValueAString,
        string memory displayType,
        string memory traitType,
        string memory value
    ) private pure returns (ERC1155MetadataAttribute memory) {
        ERC1155MetadataAttribute memory attribute = ERC1155MetadataAttribute({
        includeDisplayType: includeDisplayType,
        includeTraitType: includeTraitType,
        isValueAString: isValueAString,
        displayType: displayType,
        traitType: traitType,
        value: value
        });
        return attribute;
    }

    function _generateERC1155Metadata(ERC1155MetadataStructure memory metadata) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(
            byteString,
            _openJsonObject());

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("name", metadata.name, true));

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("description", metadata.description, true));

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("created_by", metadata.createdBy, true));

        if(metadata.isImageLinked) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image", metadata.image, true));
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image_data", metadata.image, true));
        }

        byteString = abi.encodePacked(
            byteString,
            _pushJsonComplexAttribute("attributes", _getAttributes(metadata.attributes), false));

        byteString = abi.encodePacked(
            byteString,
            _closeJsonObject());

        return string(byteString);
    }

    function _getAttributes(ERC1155MetadataAttribute[] memory attributes) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(
            byteString,
            _openJsonArray());

        for (uint i = 0; i < attributes.length; i++) {
            ERC1155MetadataAttribute memory attribute = attributes[i];
            // Added this to handle the case where there is no value
            if (bytes(attribute.value).length == 0) {
                continue;
            }

            bool insertComma = i < (attributes.length - 1) && !(i == 4 && bytes(attributes[5].value).length == 0);

            byteString = abi.encodePacked(
                byteString,
                _pushJsonArrayElement(_getAttribute(attribute), insertComma));
        }

        byteString = abi.encodePacked(
            byteString,
            _closeJsonArray());

        return string(byteString);
    }

    function _getAttribute(ERC1155MetadataAttribute memory attribute) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(
            byteString,
            _openJsonObject());

        if(attribute.includeDisplayType) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("display_type", attribute.displayType, true));
        }

        if(attribute.includeTraitType) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("trait_type", attribute.traitType, true));
        }

        if(attribute.isValueAString) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("value", attribute.value, false));
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveNonStringAttribute("value", attribute.value, false));
        }

        byteString = abi.encodePacked(
            byteString,
            _closeJsonObject());

        return string(byteString);
    }

    function seedIdInRange(uint256 _seedTokenId) private pure returns (bool) {
        return _seedTokenId > 0 && _seedTokenId < 10001;
    }

    function getClassFromSeedId(uint256 _seedTokenId) private pure returns (string[3] memory) {
        require(seedIdInRange(_seedTokenId), "PaperPotMetadata: seedTokenId not in range");
        if (_seedTokenId > 1110) {
            return ["Wonder", "Common", string(abi.encodePacked("Paper Seed of Wonder #",(_seedTokenId - 1110).toString()))];
        }
        if (_seedTokenId > 110) {
            return ["Passion", "Uncommon", string(abi.encodePacked("Paper Seed of Passion #",(_seedTokenId - 110).toString()))];
        }
        if (_seedTokenId > 10) {
            return ["Hope", "Rare", string(abi.encodePacked("Paper Seed of Hope #",(_seedTokenId - 10).toString()))];
        }
        return ["Power", "Legendary", string(abi.encodePacked("Paper Seed of Power #",_seedTokenId.toString()))];
    }

    function getNftClassFromSeedId(uint256 _seedTokenId) private pure returns (NftClass) {
        require(seedIdInRange(_seedTokenId), "PaperPotMetadata: seedTokenId not in range");
        if (_seedTokenId > 1110) {
            return NftClass.wonder;
        }
        if (_seedTokenId > 110) {
            return NftClass.passion;
        }
        if (_seedTokenId > 10) {
            return NftClass.hope;
        }
        return NftClass.power;
    }

    function getDnaFromSeedId(uint256 _seedTokenId) private pure returns (uint256 dna) {
        require(seedIdInRange(_seedTokenId), "PaperPotMetadata: seedTokenId not in range");
        return _seedTokenId % 100;
    }

    function adminSetDefaultUris(string[4] memory shrubDefaultUris_) public adminOnly {
        // must be 4 uris - wonder, passion, hope, power
        for (uint8 i = 0; i < shrubDefaultUris_.length; i++) {
            _shrubDefaultUris[NftClass(i)] = shrubDefaultUris_[i];
        }
    }

    function setShrubSeedUris(uint[] calldata seedTokenIds_, CustomMetadata[] calldata metadatas_) external adminOnly {
        require(seedTokenIds_.length == metadatas_.length, "PaperPotMetadata: seedTokenIds and uris must be same length");
        for (uint i = 0; i < seedTokenIds_.length; i++) {
            require(seedTokenIds_[i] < POTTED_PLANT_BASE_TOKENID, "PaperPotMetadata: invalid seedTokenId");
            _shrubSeedUris[seedTokenIds_[i]] = metadatas_[i];
        }
    }

    function setShrubName(uint seedTokenId_, string memory newName_) external adminOnly {
        require(bytes(_shrubSeedUris[seedTokenId_].imageUri).length > 0, "PaperPotMetadata: Can only set name for already set Shrub");
        require(bytes(newName_).length < 27, "PaperPotMetadata: Maximum characters in name is 26.");
        require(validateMessage(newName_), "PaperPotMetadata: Invalid Name");
        _shrubSeedUris[seedTokenId_].name = newName_;
    }

    function validateMessage(string memory message_) public pure returns(bool) {
        // a-z,A-Z only
        bytes memory messageBytes = bytes(message_);
        if (messageBytes.length == 0) {
            // Length 0 is allow to revert
            return true;
        }

        // cannot begin or end with a space
        require(messageBytes.length > 0 && messageBytes[0] != 0x20 && messageBytes[messageBytes.length-1] != 0x20, "Invalid characters");

        for (uint i = 0; i < messageBytes.length; i++) {
            bytes1 char = messageBytes[i];
            if (!(char >= 0x41 && char <= 0x5A) && !(char >= 0x61 && char <= 0x7A) && char != 0x20) {
                revert("Invalid character");
            } else if (i >= 1 && char == 0x20 && messageBytes[i-1] == 0x20) {
                revert("Cannot have multiple sequential spaces");
            }
        }
        return true;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
enum NftClass {
    wonder, // 0
    passion, // 1
    hope, // 2
    power    // 3
}

enum GrowthStages {
    none, // 0
    stage1, // 1
    stage2, // 2
    stage3, // 3
    stage4   // 4
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract BaseERC1155 is ERC1155 {
    constructor(string memory _baseUri) ERC1155(_baseUri) {}
}