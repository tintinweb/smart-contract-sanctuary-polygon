/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// File: contracts/Admin/data/GachaStruct.sol


pragma solidity ^0.8.18;

    enum GachaType {
        None,
        Character,
        FateCore
    }

    struct InputGachaInfo {
        uint256 tokenId;
        string name;
        uint256[] tierRatio;
        uint256[][] gachaGradeRatio;
        uint256[] gachaFateCoreRatio;
        uint256[] gachaFateCoreList;
        GachaType gachaType;
        bool isValid;
    }

    struct GachaInfo {
        uint256 tokenId;
        string name;
        uint256[] tierRatio;
        uint256[][] gachaGradeRatio;
        bool isValid;
    }

    struct FateCoreGachaInfo {
        uint256 tokenId;
        string name;
        uint256[] gachaFateCoreRatio;
        uint256[] gachaFateCoreList;
        bool isValid;
    }
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

// File: contracts/Admin/data/GachaDataV2.sol


pragma solidity ^0.8.16;



contract DspGachaData is Ownable {
    event SetGachaInfo(uint256 indexed tokenId, string indexed name, uint256[] tierRatio, uint256[][]gachaGradeRatio, bool isValid);
    event SetFateCoreGachaInfo(uint256 indexed tokenId, string indexed name, uint256[] ratio, uint256[]list, bool isValid);
    event RemoveGachaInfo(uint256 indexed tokenId, string indexed name, uint256[] tierRatio, uint256[][]gachaGradeRatio, bool isValid);
    event RemoveFateCoreGachaInfo(uint256 indexed tokenId, string indexed name, uint256[] ratio, uint256[] list, bool isValid);

    uint256 private gachaCount;

    // tokenId => GachaInfo
    mapping(uint256 => GachaInfo) private gachaInfo;

    // tokenId => FateCoreGachaInfo
    mapping(uint256 => FateCoreGachaInfo) private fateCoreGachaInfo;

    // token id => type
    mapping(uint256 => uint256) private gachaTypeByTokenId;

    function getGachaCount() public view returns (uint256) {
        return gachaCount;
    }

    function getGachaInfo(uint256 _tokenId) public view returns (GachaInfo memory) {
        return gachaInfo[_tokenId];
    }

    function getFateCoreGachaInfo(uint256 _tokenId) public view returns (FateCoreGachaInfo memory) {
        return fateCoreGachaInfo[_tokenId];
    }

    function getGachaType(uint256 _tokenId) public view returns (uint256) {
        return uint256(gachaTypeByTokenId[_tokenId]);
    }

    function getGachaTierRatio(uint256 _tokenId) public view returns (uint256[] memory, uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < gachaInfo[_tokenId].tierRatio.length; i++) {
            sum += gachaInfo[_tokenId].tierRatio[i];
        }
        return (gachaInfo[_tokenId].tierRatio, sum);
    }

    function getGachaGachaGradeRatio(uint256 _tokenId) public view returns (uint256[][] memory, uint256[] memory) {
        uint256[] memory sum = new uint256[](gachaInfo[_tokenId].gachaGradeRatio.length);
        for (uint256 i = 0; i < gachaInfo[_tokenId].gachaGradeRatio.length; i++) {
            for (uint256 j = 0; j < gachaInfo[_tokenId].gachaGradeRatio[i].length; j++) {
                sum[i] += gachaInfo[_tokenId].gachaGradeRatio[i][j];
            }
        }
        return (gachaInfo[_tokenId].gachaGradeRatio, sum);
    }

    function getGachaFateCoreRatio(uint256 _tokenId) public view returns (uint256[] memory, uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < fateCoreGachaInfo[_tokenId].gachaFateCoreRatio.length; i++) {
            sum += fateCoreGachaInfo[_tokenId].gachaFateCoreRatio[i];
        }
        return (fateCoreGachaInfo[_tokenId].gachaFateCoreRatio, sum);
    }

    function getFateCoreByIndex(uint256 _tokenId, uint256 index) public view returns (uint256) {
        return fateCoreGachaInfo[_tokenId].gachaFateCoreList[index];
    }

    function setGachaInfo(InputGachaInfo memory _inputGachaInfo) external onlyOwner {
        require(_inputGachaInfo.tokenId != 0, "gacha id not valid");
        if (GachaType.Character == _inputGachaInfo.gachaType) {
            GachaInfo memory _gachaInfo = GachaInfo(_inputGachaInfo.tokenId, _inputGachaInfo.name, _inputGachaInfo.tierRatio, _inputGachaInfo.gachaGradeRatio, _inputGachaInfo.isValid);
            uint256 sumTierRatio = 0;
            for (uint256 i = 0; i < _gachaInfo.tierRatio.length; i++) {
                sumTierRatio += _gachaInfo.tierRatio[i];
            }
            require(sumTierRatio != 0, "gacha ratio sum 0");
            if (!gachaInfo[_gachaInfo.tokenId].isValid) {
                gachaCount++;
            }
            for (uint256 i = 0; i < _gachaInfo.gachaGradeRatio.length; i++) {
                if (_gachaInfo.tierRatio[i] != 0) {
                    uint256 sumGachaGradeRatio = 0;
                    for (uint256 j = 0; j < _gachaInfo.gachaGradeRatio[i].length; j++) {
                        sumGachaGradeRatio += _gachaInfo.gachaGradeRatio[i][j];
                    }
                    require(sumGachaGradeRatio != 0, "gacha gacha grade ratio sum 0");
                }
            }
            gachaTypeByTokenId[_gachaInfo.tokenId] = uint256(GachaType.Character);
            gachaInfo[_gachaInfo.tokenId] = _gachaInfo;
            emit SetGachaInfo(_gachaInfo.tokenId, _gachaInfo.name, _gachaInfo.tierRatio, _gachaInfo.gachaGradeRatio, _gachaInfo.isValid);
        } else if (GachaType.FateCore == _inputGachaInfo.gachaType) {
            FateCoreGachaInfo memory _fateCoreGachaInfo = FateCoreGachaInfo(_inputGachaInfo.tokenId, _inputGachaInfo.name, _inputGachaInfo.gachaFateCoreRatio, _inputGachaInfo.gachaFateCoreList, _inputGachaInfo.isValid);
            uint256 sumRatio = 0;
            for (uint256 i = 0; i < _fateCoreGachaInfo.gachaFateCoreRatio.length; i++) {
                sumRatio += _fateCoreGachaInfo.gachaFateCoreRatio[i];
            }
            require(sumRatio != 0, "gacha ratio sum 0");
            require(_fateCoreGachaInfo.gachaFateCoreRatio.length == _fateCoreGachaInfo.gachaFateCoreList.length, "not same count");
            if (!fateCoreGachaInfo[_fateCoreGachaInfo.tokenId].isValid) {
                gachaCount++;
            }
            gachaTypeByTokenId[_fateCoreGachaInfo.tokenId] = uint256(GachaType.FateCore);
            fateCoreGachaInfo[_fateCoreGachaInfo.tokenId] = _fateCoreGachaInfo;
            emit SetFateCoreGachaInfo(_fateCoreGachaInfo.tokenId, _fateCoreGachaInfo.name, _fateCoreGachaInfo.gachaFateCoreRatio, _fateCoreGachaInfo.gachaFateCoreList, _fateCoreGachaInfo.isValid);
        }
    }

    function setGachaInfos(InputGachaInfo[] memory _inputGachaInfo) external onlyOwner {
        for (uint256 k = 0; k < _inputGachaInfo.length; k++) {
            require(_inputGachaInfo[k].tokenId != 0, "gacha id not valid");
            if (GachaType.Character == _inputGachaInfo[k].gachaType) {
                GachaInfo memory _gachaInfo = GachaInfo(_inputGachaInfo[k].tokenId, _inputGachaInfo[k].name, _inputGachaInfo[k].tierRatio, _inputGachaInfo[k].gachaGradeRatio, _inputGachaInfo[k].isValid);
                uint256 sumTierRatio = 0;
                for (uint256 i = 0; i < _gachaInfo.tierRatio.length; i++) {
                    sumTierRatio += _gachaInfo.tierRatio[i];
                }
                require(sumTierRatio != 0, "gacha ratio sum 0");
                if (!gachaInfo[_gachaInfo.tokenId].isValid) {
                    gachaCount++;
                }
                for (uint256 i = 0; i < _gachaInfo.gachaGradeRatio.length; i++) {
                    if (_gachaInfo.tierRatio[i] != 0) {
                        uint256 sumGachaGradeRatio = 0;
                        for (uint256 j = 0; j < _gachaInfo.gachaGradeRatio[i].length; j++) {
                            sumGachaGradeRatio += _gachaInfo.gachaGradeRatio[i][j];
                        }
                        require(sumGachaGradeRatio != 0, "gacha gacha grade ratio sum 0");
                    }
                }
                gachaTypeByTokenId[_gachaInfo.tokenId] = uint256(GachaType.Character);
                gachaInfo[_gachaInfo.tokenId] = _gachaInfo;
                emit SetGachaInfo(_gachaInfo.tokenId, _gachaInfo.name, _gachaInfo.tierRatio, _gachaInfo.gachaGradeRatio, _gachaInfo.isValid);
            } else if (GachaType.FateCore == _inputGachaInfo[k].gachaType) {
                FateCoreGachaInfo memory _fateCoreGachaInfo = FateCoreGachaInfo(_inputGachaInfo[k].tokenId, _inputGachaInfo[k].name, _inputGachaInfo[k].gachaFateCoreRatio, _inputGachaInfo[k].gachaFateCoreList, _inputGachaInfo[k].isValid);
                uint256 sumRatio = 0;
                for (uint256 i = 0; i < _fateCoreGachaInfo.gachaFateCoreRatio.length; i++) {
                    sumRatio += _fateCoreGachaInfo.gachaFateCoreRatio[i];
                }
                require(sumRatio != 0, "gacha ratio sum 0");
                require(_fateCoreGachaInfo.gachaFateCoreRatio.length == _fateCoreGachaInfo.gachaFateCoreList.length, "not same count");
                if (!fateCoreGachaInfo[_fateCoreGachaInfo.tokenId].isValid) {
                    gachaCount++;
                }
                gachaTypeByTokenId[_fateCoreGachaInfo.tokenId] = uint256(GachaType.FateCore);
                fateCoreGachaInfo[_fateCoreGachaInfo.tokenId] = _fateCoreGachaInfo;
                emit SetFateCoreGachaInfo(_fateCoreGachaInfo.tokenId, _fateCoreGachaInfo.name, _fateCoreGachaInfo.gachaFateCoreRatio, _fateCoreGachaInfo.gachaFateCoreList, _fateCoreGachaInfo.isValid);
            }
        }
    }

    function removeGachaInfo(uint256 _tokenId) external onlyOwner {
        require(_tokenId != 0, "gacha id not valid");
        if (gachaInfo[_tokenId].isValid) {
            gachaCount--;
        }
        emit RemoveGachaInfo(_tokenId, gachaInfo[_tokenId].name, gachaInfo[_tokenId].tierRatio, gachaInfo[_tokenId].gachaGradeRatio, gachaInfo[_tokenId].isValid);
        delete gachaInfo[_tokenId];
    }

    function removeFateCoreGachaInfo(uint256 _tokenId) external onlyOwner {
        require(_tokenId != 0, "gacha id not valid");
        if (fateCoreGachaInfo[_tokenId].isValid) {
            gachaCount--;
        }
        emit RemoveFateCoreGachaInfo(_tokenId, fateCoreGachaInfo[_tokenId].name, fateCoreGachaInfo[_tokenId].gachaFateCoreRatio, fateCoreGachaInfo[_tokenId].gachaFateCoreList, fateCoreGachaInfo[_tokenId].isValid);
        delete fateCoreGachaInfo[_tokenId];
    }
}