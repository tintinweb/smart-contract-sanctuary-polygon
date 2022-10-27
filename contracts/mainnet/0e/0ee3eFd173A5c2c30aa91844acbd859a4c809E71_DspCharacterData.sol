/**
 *Submitted for verification at polygonscan.com on 2022-10-26
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Admin/data/ValueChipData.sol


pragma solidity ^0.8.16;


contract DspValueChipData is Ownable {
    enum ValueChipsType { None, Hero, Class, Nation, Element }
    uint256 private valueChipCount;

    struct InputValueChipInfo {
        uint256 tokenId;
        string name;
        ValueChipsType valueChipsType;
        string characterName;
        uint256 gameEnumByValueChipsType;
        bool isValid;
    }

    struct ValueChipInfo {
        string name;
        ValueChipsType valueChipsType;
        string characterName;
        uint256 gameEnumByValueChipsType;
        bool isValid;
    }

    // tokenId => ValueChipInfo
    mapping(uint256 => ValueChipInfo) private valueChipInfo;
    uint256[] private valueChipTokenIdList;

    function getValueChipCount() public view returns (uint256) {
        return valueChipCount;
    }

    function getValueChipInfo(uint256 _tokenId) public view returns (string memory, uint32, string memory, uint256, bool) {
        return (
        valueChipInfo[_tokenId].name,
        uint32(valueChipInfo[_tokenId].valueChipsType),
        valueChipInfo[_tokenId].characterName,
        valueChipInfo[_tokenId].gameEnumByValueChipsType,
        valueChipInfo[_tokenId].isValid
        );
    }

    function getValueChipsIsValid(uint256 _tokenId) public view returns (bool) {
        return valueChipInfo[_tokenId].isValid;
    }

    function getValueChipValueChipsType(uint256 _tokenId) public view returns (uint32) {
        return uint32(valueChipInfo[_tokenId].valueChipsType);
    }

    function getValueChipTokenIdList() public view returns (uint256[] memory) {
        return valueChipTokenIdList;
    }

    function setValueChipInfo(InputValueChipInfo memory _valueChipInfo) external onlyOwner {
        require(_valueChipInfo.tokenId != 0, "value chip id not valid");
        require(_valueChipInfo.isValid, "value chip not valid");
        if (!valueChipInfo[_valueChipInfo.tokenId].isValid) {
            valueChipCount++;
        }
        valueChipInfo[_valueChipInfo.tokenId] =
        ValueChipInfo(
            _valueChipInfo.name,
            _valueChipInfo.valueChipsType,
            _valueChipInfo.characterName,
            _valueChipInfo.gameEnumByValueChipsType,
            _valueChipInfo.isValid
        );
    }

    function setValueChipInfos(InputValueChipInfo[] memory _valueChipInfos) external onlyOwner {
        for (uint256 i = 0; i < _valueChipInfos.length; i++) {
            require(_valueChipInfos[i].tokenId != 0, "value chip id not valid");
            require(_valueChipInfos[i].isValid, "value chip not valid");
            if (!valueChipInfo[_valueChipInfos[i].tokenId].isValid) {
                valueChipCount++;
                valueChipTokenIdList.push(_valueChipInfos[i].tokenId);
            }
            valueChipInfo[_valueChipInfos[i].tokenId] =
            ValueChipInfo(
                _valueChipInfos[i].name,
                _valueChipInfos[i].valueChipsType,
                _valueChipInfos[i].characterName,
                _valueChipInfos[i].gameEnumByValueChipsType,
                _valueChipInfos[i].isValid
            );
        }
    }

    function removeValueChipInfo(uint256 _tokenId) external onlyOwner {
        require(_tokenId != 0, "gacha ticket id not valid");
        if (valueChipInfo[_tokenId].isValid) {
            valueChipCount--;
            uint256 index;
            for (uint256 i = 0; i < valueChipTokenIdList.length; i++) {
                if (valueChipTokenIdList[i] == _tokenId) {
                    index = i;
                }
            }
            for (uint256 i = index; i < valueChipTokenIdList.length - 1; i++) {
                valueChipTokenIdList[i] = valueChipTokenIdList[i + 1];
            }
            valueChipTokenIdList.pop();
        }
        delete valueChipInfo[_tokenId];
    }
}
// File: contracts/Admin/data/CharacterData.sol


pragma solidity ^0.8.16;



contract DspCharacterData is Ownable {

    event SetCharacterData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event DeleteCharacterData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event SetCharacterName(uint256 indexed id, string indexed name);

    struct CharacterInfo {
        string name;
        uint256 tier;
        uint256 gachaGrade;
        uint256 classType;
        uint256 nation;
        uint256 element;
        uint256 rootId;
        bool isValid;
    }

    struct CharacterName {
        uint256 id;
        string name;
    }

    struct MatchValueChip {
        string name;
        uint256 valueChipId;
    }

    constructor(address _valueChipAddress) {
        valueChipAddress = _valueChipAddress;
    }

    address private valueChipAddress;

    // character id => name
    mapping(uint256 => string) private characterName;
    // name => character info
    mapping(string => CharacterInfo) private characterData;
    // tier => gacha grade => name[]
    mapping(uint256 => mapping(uint256 => string[])) private characterInfoTable;
    // name => value chip
    mapping(string => uint256) private matchValueChip;

    uint256 private characterCount;

    function getCharacterInfo(string memory name) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (characterData[name].tier, characterData[name].gachaGrade, characterData[name].classType, characterData[name].nation, characterData[name].element, characterData[name].rootId, characterData[name].isValid);
    }

    function getCharacterInfoIsValid(string memory name) public view returns(bool) {
        return characterData[name].isValid;
    }

    function getCharacterName(uint256 id) public view returns (string memory) {
        return characterName[id];
    }

    function setMatchValueChip(MatchValueChip[] memory _matchValueChips) external onlyOwner {
        for (uint256 i = 0; i < _matchValueChips.length; i++) {
            ( , uint32 _valueChipsType, string memory _characterName, , bool _isValid) = DspValueChipData(valueChipAddress).getValueChipInfo(_matchValueChips[i].valueChipId);
            if (
                _isValid &&
                _valueChipsType == uint32(DspValueChipData.ValueChipsType.Hero) &&
                uint(keccak256(abi.encodePacked(_characterName))) == uint(keccak256(abi.encodePacked(_matchValueChips[i].name)))
            ) {
                matchValueChip[_matchValueChips[i].name] = _matchValueChips[i].valueChipId;
            }
        }
    }

    function setCharacterName(CharacterName[] memory _characterName) external onlyOwner {
        for (uint256 i = 0; i < _characterName.length; i++) {
            characterName[_characterName[i].id] = _characterName[i].name;
            emit SetCharacterName(_characterName[i].id, _characterName[i].name);
        }
    }

    function setCharacterData(CharacterInfo[] memory _characterData) external onlyOwner {
        for (uint256 i = 0; i < _characterData.length; i++) {
            require(_characterData[i].isValid, "isValid false use delete");
            if (!characterData[_characterData[i].name].isValid) {
                characterCount++;
            } else if (characterData[_characterData[i].name].tier != _characterData[i].tier) {
                uint256 index;
                uint256 _tier = characterData[_characterData[i].name].tier;
                uint256 _gachaGrade = characterData[_characterData[i].name].gachaGrade;
                for (uint256 j = 0; j < characterInfoTable[_tier][_gachaGrade].length; j++) {
                    if (keccak256(abi.encodePacked(characterInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(_characterData[i].name))) {
                        index = j;
                        break;
                    }
                }
                for (uint256 j = index; j < characterInfoTable[_tier][_gachaGrade].length - 1; j++) {
                    characterInfoTable[_tier][_gachaGrade][j] = characterInfoTable[_tier][_gachaGrade][j + 1];
                }
                characterInfoTable[_tier][_gachaGrade].pop();
            }
            characterInfoTable[_characterData[i].tier][_characterData[i].gachaGrade].push(_characterData[i].name);
            characterData[_characterData[i].name] = _characterData[i];

            emit SetCharacterData(_characterData[i].name, _characterData[i].tier, _characterData[i].gachaGrade, _characterData[i].classType, _characterData[i].nation, _characterData[i].element, _characterData[i].isValid);
        }
    }

    function deleteCharacterData(string[] memory names) external onlyOwner {
        for (uint256 i = 0; i < names.length; i++) {
            uint256 _tier = characterData[names[i]].tier;
            uint256 _gachaGrade = characterData[names[i]].gachaGrade;

            uint256 index;
            for (uint256 j = 0; j < characterInfoTable[_tier][_gachaGrade].length; j++) {
                if (keccak256(abi.encodePacked(characterInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(characterData[names[i]].name))) {
                    index = j;
                    break;
                }
            }
            for (uint256 j = index; j < characterInfoTable[_tier][_gachaGrade].length - 1; j++) {
                characterInfoTable[_tier][_gachaGrade][j] = characterInfoTable[_tier][_gachaGrade][j + 1];
            }
            characterInfoTable[_tier][_gachaGrade].pop();
            characterCount--;

            emit DeleteCharacterData(characterData[names[i]].name, characterData[names[i]].tier, characterData[names[i]].gachaGrade, characterData[names[i]].classType, characterData[names[i]].nation, characterData[names[i]].element, characterData[names[i]].isValid);
            delete characterData[names[i]];
        }
    }

    function getMatchValueChip(string memory _name) public view returns (uint256) {
        return matchValueChip[_name];
    }

    function getValueChipAddress() public view returns (address) {
        return valueChipAddress;
    }

    function setValueChipAddress(address _valueChipAddress) external onlyOwner {
        valueChipAddress = _valueChipAddress;
    }

    function getCharacterCount() public view returns (uint256) {
        return characterCount;
    }

    function getCharacterCountByTireAndGachaGrade(uint256 _tier, uint256 _gachaGrade) public view returns (uint256) {
        return characterInfoTable[_tier][_gachaGrade].length;
    }

    function getCharacterInfoByTireAndIndex(uint256 _tier, uint256 _gachaGrade, uint index) public view returns (string memory) {
        return characterInfoTable[_tier][_gachaGrade][index];
    }
}