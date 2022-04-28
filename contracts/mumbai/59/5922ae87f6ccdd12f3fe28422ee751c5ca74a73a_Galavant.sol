// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
// import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "./ERC2981Upgradeable.sol";
import "./RoyaltiesV2.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
import "./ITerms.sol";
import "./IMintable.sol";

contract Galavant is Initializable, 
    ERC721Upgradeable, 
    ERC721EnumerableUpgradeable,
    ERC2981Upgradeable,
    PausableUpgradeable, 
    OwnableUpgradeable,
    AccessControlUpgradeable, 
    ITerms,
    RoyaltiesV2,
    IMintable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    string public _baseTokenURI;
    string private _termsAndConditionsURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        string memory termsURI_,
        uint96 royaltyFeeNumerator_
    ) initializer public {
        __ERC721_init(name_, symbol_);
        _baseTokenURI = baseTokenURI_;
        _termsAndConditionsURI = termsURI_;

        __ERC721Enumerable_init();
        __ERC2981_init();
        __Ownable_init();
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _setDefaultRoyalty(payable(msg.sender), royaltyFeeNumerator_);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
    
    function setBaseTokenURI(string memory _uri) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = _uri;
    }

    function setTermsURI(string memory termsURI) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _termsAndConditionsURI = termsURI;
    }

    function termsAndConditionsURI() public view virtual override returns (string memory) {
        return _termsAndConditionsURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function safeMint(address to, uint256 quantity) override public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }
    
    function getRaribleV2Royalties(uint256 id) override external view returns (LibPart.Part[] memory) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[id];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }
        
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = royalty.royaltyFraction;
        _royalties[0].account = royalty.receiver;

        return _royalties;
    }

    function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyRole(DEFAULT_ADMIN_ROLE) {
        
        // ERC2981 royalty
        _setTokenRoyalty(_tokenId, _royaltiesReceipientAddress, _percentageBasisPoints);
        
        // Rarible royalty
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;

        emit RoyaltiesSet(_tokenId, _royalties);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}