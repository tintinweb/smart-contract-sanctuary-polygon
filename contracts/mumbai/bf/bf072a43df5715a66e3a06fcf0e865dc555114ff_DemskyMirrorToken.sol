// SPDX-License-Identifier: MIT

/**
       ###    ##    ## #### ##     ##    ###
      ## ##   ###   ##  ##  ###   ###   ## ##
     ##   ##  ####  ##  ##  #### ####  ##   ##
    ##     ## ## ## ##  ##  ## ### ## ##     ##
    ######### ##  ####  ##  ##     ## #########
    ##     ## ##   ###  ##  ##     ## ##     ##
    ##     ## ##    ## #### ##     ## ##     ##
*/

pragma solidity ^0.8.10;
pragma abicoder v2;
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AnimaToken.sol";
import "./AnimaMetadata.sol";
contract DemskyMirrorToken is
    AnimaToken,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable
{
    //
    // GAP
    // !! This can potentially be used in the future to add new base classes !!
    //
    uint256[50] private __gap;

    //
    // EVENTS
    //
    event AnimaMint(address indexed recipient, uint256 indexed tokenId);
    event BridgeMint(address indexed recipient, uint256 indexed tokenId);

    //
    // STRUCTS
    //
    struct MutableData {
        string tokenMetadataBaseURI;
        string openSeaContractURI;
        address payable royaltyReceiver;
        uint256 royaltyPercentage; // out of 1000
    }

    //
    // CONSTANTS
    //
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    string private constant RELEASE_ID = "demsky/mirror";
    uint256 private constant MAX_MINT_ID = 8888;
    uint128 private constant ROYALTY_SCALE = 1000;
    string private constant INVALID_ROYALTY_PERCENTAGE = "INVALID_ROYALTY_PERCENTAGE";
    string private constant BURN_DENIED = "BURN_DENIED";

    //
    // STATE VARIABLES
    // !! When adding new state variables in upgrades, make sure to preserve the existing order and add new variables _last_ !!
    //
    uint256 public nextMintId;
    AnimaMetadata metadataContract;
    mapping(uint256 => bool) animaMintNonces;
    MutableData public mutableData;

    //
    // INITIALIZER FUNCTION
    //

    function initialize(address _metadataContractAddress) public initializer {
        // Note: this is technically not recommended, but the alternative is simply not using multiple inheritance:
        //   https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/README.md
        // Since it seems like this is way better than re-implementing interfaces that already exist,
        //   confirm that all parent contracts are initialized _once_ and in the correct order here
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC721_init_unchained("MIRROR BY DEMSKY", "MN1");
        __ERC721Enumerable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, owner());
        nextMintId = 1;
        metadataContract = AnimaMetadata(_metadataContractAddress);
    }

    //
    // EXTERNAL FUNCTIONS
    //

    receive() external payable {}

    fallback() external {}

    function setPaused(bool _value) external onlyRole(ADMIN_ROLE) {
        if (_value) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setMutableData(MutableData memory _mutableData) public onlyRole(ADMIN_ROLE) {
        require(_mutableData.royaltyPercentage <= ROYALTY_SCALE, INVALID_ROYALTY_PERCENTAGE);

        mutableData = _mutableData;
    }

    // Mint from ANIMA
    function mintAnima(
        string calldata _releaseId,
        uint256 _nonce,
        address _recipient,
        uint256 _count
    ) external override whenNotPaused onlyRole(MINTER_ROLE) {
        require(keccak256(abi.encodePacked(_releaseId)) == keccak256(abi.encodePacked(RELEASE_ID)), "WRONG_RELEASE");
        require(animaMintNonces[_nonce] != true, "DUPLICATE_NONCE");
        require(_count > 0, "INVALID_TOKEN_COUNT");
        // Realistically should be _much_ smaller than this, but seems like a good sanity check
        require(_count <= MAX_MINT_ID, "INVALID_TOKEN_COUNT");
        require(address(metadataContract) != address(0), "NO_METADATA_CONTRACT");
        animaMintNonces[_nonce] = true;

        for (uint256 i = 0; i < _count; i++) {
            uint256 tokenId = nextMintId;
            nextMintId += 1;

            require(tokenId > 0, "NO_MINT_ZERO");
            require(tokenId <= MAX_MINT_ID, "MAX_MINTS");

            _safeMint(_recipient, tokenId);
            metadataContract.tokenMinted(tokenId);
            emit AnimaMint(_recipient, tokenId);
        }
    }

    // Mint from bridge
    function mint(
        address _recipient,
        uint256 _tokenId,
        string calldata
    ) external whenNotPaused onlyRole(BRIDGE_ROLE) {
        _safeMint(_recipient, _tokenId);
        emit BridgeMint(_recipient, _tokenId);
    }

    function burn(uint256 _tokenId) public virtual whenNotPaused {
        require(msg.sender == ownerOf(_tokenId) || hasRole(BRIDGE_ROLE, msg.sender), BURN_DENIED);
        _burn(_tokenId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "royaltyInfo query for nonexistent token");
        return (mutableData.royaltyReceiver, percentage(_salePrice, mutableData.royaltyPercentage, ROYALTY_SCALE));
    }

    function contractURI() external view returns (string memory) {
        return mutableData.openSeaContractURI;
    }

    //
    // PUBLIC FUNCTIONS
    //

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (address(metadataContract) != address(0) && bytes(mutableData.tokenMetadataBaseURI).length == 0) {
            return metadataContract.tokenDataURI(_tokenId);
        } else {
            return string(abi.encodePacked(mutableData.tokenMetadataBaseURI, StringsUpgradeable.toString(_tokenId)));
        }
    }

    function tokensOfOwner(address _owner) external view override returns (uint256[] memory) {
        uint256 balance = ERC721Upgradeable.balanceOf(_owner);
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = ERC721EnumerableUpgradeable.tokenOfOwnerByIndex(_owner, i);
        }
        return tokens;
    }

    function ownerOfOrZeroAddress(uint256 _tokenId) external view override returns (address) {
        if (!ERC721Upgradeable._exists(_tokenId)) {
            return address(0);
        }

        return ERC721Upgradeable.ownerOf(_tokenId);
    }

    //
    // INTERNAL FUNCTIONS
    //

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
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            require(hasRole(MINTER_ROLE, msg.sender) || hasRole(BRIDGE_ROLE, msg.sender), "MINT_DENIED");
        }

        if (to == address(0)) {
            require(msg.sender == from || hasRole(BRIDGE_ROLE, msg.sender), BURN_DENIED);
        }
    }

    // Calculate base * ratio / scale rounding down.
    // https://ethereum.stackexchange.com/a/79736
    // NOTE: As of solidity 0.8, SafeMath is no longer required
    function percentage(
        uint256 base,
        uint256 ratio,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 baseDiv = base / scale;
        uint256 baseMod = base % scale;
        uint256 ratioDiv = ratio / scale;
        uint256 ratioMod = ratio % scale;

        return
            (baseDiv * ratioDiv * scale) + (baseDiv * ratioMod) + (baseMod * ratioDiv) + ((baseMod * ratioMod) / scale);
    }
}