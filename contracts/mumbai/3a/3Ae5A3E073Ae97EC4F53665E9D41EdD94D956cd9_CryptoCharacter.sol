// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title CryptoCharacter
/// @author Ng Ju Peng
/// @notice Track ownership of each part of the character
contract CryptoCharacter {
    struct CharacterPartOwnership {
        string styleURI;
        address owner;
        uint256 highestBid;
    }

    struct Character {
        CharacterPartOwnership hair;
        CharacterPartOwnership eye;
        CharacterPartOwnership mouth;
        CharacterPartOwnership cloth;
    }

    // in order to gain the ownership of the part of the character, at least > MIN_BID_AMOUNT + character part.highest bid
    uint256 private constant MIN_BID_AMOUNT = 0.001 ether;

    address private immutable i_owner;

    // the only character in this contract
    Character private s_character;

    // track the style ipfs uri
    string[] internal s_hairStyleURIs;
    string[] internal s_eyeStyleURIs;
    string[] internal s_mouthStyleURIs;
    string[] internal s_clothStyleURIs;

    /********************
        Events
    ********************/
    event UpdateCharacterStyle(
        string indexed part,
        address indexed bidder,
        string uri,
        uint256 amount
    );
    event NewStyleAdded(string uri);

    /********************
        Errors
    ********************/
    error CryptoCharacter__InsufficientBidAmount();
    error CryptoCharacter__NotOwner();
    error CryptoCharacter__StyleExisted();
    error CryptoCharacter__AccessOutOfBound();

    /********************
        Modifiers
    ********************/
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert CryptoCharacter__NotOwner();
        }
        _;
    }
    modifier isEnoughBidAmount(CharacterPartOwnership memory _part) {
        if (msg.value <= _part.highestBid + MIN_BID_AMOUNT) {
            revert CryptoCharacter__InsufficientBidAmount();
        }
        _;
    }
    modifier isValidIndex(uint256 _index, string[] memory _arr) {
        if (_index < 0 || _index >= _arr.length) {
            revert CryptoCharacter__AccessOutOfBound();
        }
        _;
    }

    constructor(
        string[] memory _hairStyleURIs,
        string[] memory _eyeStyleURIs,
        string[] memory _mouthStyleURIs,
        string[] memory _clothStyleURIs
    ) {
        i_owner = msg.sender;
        // initialize the character
        s_character = Character({
            hair: CharacterPartOwnership({
                styleURI: _hairStyleURIs[0],
                owner: msg.sender,
                highestBid: 0.001 ether
            }),
            eye: CharacterPartOwnership({
                styleURI: _eyeStyleURIs[0],
                owner: msg.sender,
                highestBid: 0.001 ether
            }),
            mouth: CharacterPartOwnership({
                styleURI: _mouthStyleURIs[0],
                owner: msg.sender,
                highestBid: 0.001 ether
            }),
            cloth: CharacterPartOwnership({
                styleURI: _clothStyleURIs[0],
                owner: msg.sender,
                highestBid: 0.001 ether
            })
        });
        s_hairStyleURIs = _hairStyleURIs;
        s_eyeStyleURIs = _eyeStyleURIs;
        s_mouthStyleURIs = _mouthStyleURIs;
        s_clothStyleURIs = _clothStyleURIs;
    }

    fallback() external payable {}

    receive() external payable {}

    /********************
        Gain part ownership of the character
    ********************/

    /// @notice gain the ownership of character's hair and use the index in s_hairStyleURIs as hair outfit
    function selectNewHairStyle(uint256 _index)
        external
        payable
        isEnoughBidAmount(s_character.hair)
        isValidIndex(_index, s_hairStyleURIs)
    {
        s_character.hair = CharacterPartOwnership({
            styleURI: s_hairStyleURIs[_index],
            owner: msg.sender,
            highestBid: msg.value
        });
        emit UpdateCharacterStyle(
            "hair",
            msg.sender,
            s_hairStyleURIs[_index],
            msg.value
        );
    }

    /// @notice gain the ownership of character's eye and use the index in s_eyeStyleURIs as eye outfit
    function selectNewEyeStyle(uint256 _index)
        external
        payable
        isEnoughBidAmount(s_character.eye)
        isValidIndex(_index, s_eyeStyleURIs)
    {
        s_character.eye = CharacterPartOwnership({
            styleURI: s_eyeStyleURIs[_index],
            owner: msg.sender,
            highestBid: msg.value
        });
        emit UpdateCharacterStyle(
            "eye",
            msg.sender,
            s_eyeStyleURIs[_index],
            msg.value
        );
    }

    /// @notice gain the ownership of character's mouth and use the index in s_mouthStyleURIs as mouth outfit
    function selectNewMouthStyle(uint256 _index)
        external
        payable
        isEnoughBidAmount(s_character.mouth)
        isValidIndex(_index, s_mouthStyleURIs)
    {
        s_character.mouth = CharacterPartOwnership({
            styleURI: s_mouthStyleURIs[_index],
            owner: msg.sender,
            highestBid: msg.value
        });
        emit UpdateCharacterStyle(
            "mouth",
            msg.sender,
            s_mouthStyleURIs[_index],
            msg.value
        );
    }

    /// @notice gain the ownership of character's cloth and use the index in s_clothStyleURIs as cloth outfit
    function selectNewClothStyle(uint256 _index)
        external
        payable
        isEnoughBidAmount(s_character.cloth)
        isValidIndex(_index, s_clothStyleURIs)
    {
        s_character.cloth = CharacterPartOwnership({
            styleURI: s_clothStyleURIs[_index],
            owner: msg.sender,
            highestBid: msg.value
        });
        emit UpdateCharacterStyle(
            "cloth",
            msg.sender,
            s_clothStyleURIs[_index],
            msg.value
        );
    }

    /********************
        Add new outfit for each part of the character
    ********************/
    function addNewHairStyle(string memory _newHairStyleURI)
        external
        onlyOwner
    {
        if (_isStyleURIExist(_newHairStyleURI, s_hairStyleURIs)) {
            revert CryptoCharacter__StyleExisted();
        }
        s_hairStyleURIs.push(_newHairStyleURI);
        emit NewStyleAdded(_newHairStyleURI);
    }

    function addNewEyeStyle(string memory _newEyeStyleURI) external onlyOwner {
        if (_isStyleURIExist(_newEyeStyleURI, s_eyeStyleURIs)) {
            revert CryptoCharacter__StyleExisted();
        }
        s_eyeStyleURIs.push(_newEyeStyleURI);
        emit NewStyleAdded(_newEyeStyleURI);
    }

    function addNewMouthStyle(string memory _newMouthStyleURI)
        external
        onlyOwner
    {
        if (_isStyleURIExist(_newMouthStyleURI, s_mouthStyleURIs)) {
            revert CryptoCharacter__StyleExisted();
        }
        s_mouthStyleURIs.push(_newMouthStyleURI);
        emit NewStyleAdded(_newMouthStyleURI);
    }

    function addNewClothStyle(string memory _newClothStyleURI)
        external
        onlyOwner
    {
        if (_isStyleURIExist(_newClothStyleURI, s_clothStyleURIs)) {
            revert CryptoCharacter__StyleExisted();
        }
        s_clothStyleURIs.push(_newClothStyleURI);
        emit NewStyleAdded(_newClothStyleURI);
    }

    /********************
        Private functions
    ********************/
    function _isStyleURIExist(string memory uri, string[] memory uris)
        private
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < uris.length; i++) {
            if (
                keccak256(abi.encodePacked(uri)) ==
                keccak256(abi.encodePacked(uris[i]))
            ) {
                return true;
            }
        }
        return false;
    }

    /********************
        Read Only
    ********************/
    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getCharacter() external view returns (Character memory) {
        return s_character;
    }

    function getMinimumBidAmount() external pure returns (uint256) {
        return MIN_BID_AMOUNT;
    }

    function getHairStyleURIs() external view returns (string[] memory) {
        return s_hairStyleURIs;
    }

    function getEyeStyleURIs() external view returns (string[] memory) {
        return s_eyeStyleURIs;
    }

    function getMouthStyleURIs() external view returns (string[] memory) {
        return s_mouthStyleURIs;
    }

    function getClothStyleURIs() external view returns (string[] memory) {
        return s_clothStyleURIs;
    }

    function getHairStyleURI(uint256 _index)
        external
        view
        returns (string memory)
    {
        return s_hairStyleURIs[_index];
    }

    function getEyeStyleURI(uint256 _index)
        external
        view
        returns (string memory)
    {
        return s_eyeStyleURIs[_index];
    }

    function getMouthStyleURI(uint256 _index)
        external
        view
        returns (string memory)
    {
        return s_mouthStyleURIs[_index];
    }

    function getClothStyleURI(uint256 _index)
        external
        view
        returns (string memory)
    {
        return s_clothStyleURIs[_index];
    }
}