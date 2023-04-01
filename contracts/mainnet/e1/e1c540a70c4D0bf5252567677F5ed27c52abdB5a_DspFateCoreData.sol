/**
 *Submitted for verification at polygonscan.com on 2023-03-31
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

// File: contracts/Admin/data/FateCoreData.sol


pragma solidity ^0.8.18;


contract DspFateCoreData is Ownable {
    event SetFateCoreData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event DeleteFateCoreData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event SetFateCoreName(uint256 indexed id, string indexed name);

    struct FateCoreInfo {
        string name;
        uint256 tier;
        uint256 gachaGrade;
        uint256 classType;
        uint256 nation;
        uint256 element;
        uint256 rootId;
        bool isValid;
    }

    struct FateCoreName {
        uint256 id;
        string name;
    }

    // fate core id => name
    mapping(uint256 => string) private fateCoreName;
    // name => fate core info
    mapping(string => FateCoreInfo) private fateCoreData;
    // tier => gacha grade => name[]
    mapping(uint256 => mapping(uint256 => string[])) private fateCoreInfoTable;

    uint256 private fateCoreCount;

    function getFateCoreInfo(string memory name) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (fateCoreData[name].tier, fateCoreData[name].gachaGrade, fateCoreData[name].classType, fateCoreData[name].nation, fateCoreData[name].element, fateCoreData[name].rootId, fateCoreData[name].isValid);
    }

    function getFateCoreInfoIsValid(string memory name) public view returns(bool) {
        return fateCoreData[name].isValid;
    }

    function getFateCoreName(uint256 id) public view returns (string memory) {
        return fateCoreName[id];
    }

    function setFateCoreName(FateCoreName[] memory _fateCoreName) external onlyOwner {
        for (uint256 i = 0; i < _fateCoreName.length; i++) {
            fateCoreName[_fateCoreName[i].id] = _fateCoreName[i].name;
            emit SetFateCoreName(_fateCoreName[i].id, _fateCoreName[i].name);
        }
    }

    function setFateCoreData(FateCoreInfo[] memory _fateCoreData) external onlyOwner {
        for (uint256 i = 0; i < _fateCoreData.length; i++) {
            require(_fateCoreData[i].isValid, "isValid false use delete");
            if (!fateCoreData[_fateCoreData[i].name].isValid) {
                fateCoreCount++;
            } else if (fateCoreData[_fateCoreData[i].name].tier != _fateCoreData[i].tier) {
                uint256 index;
                uint256 _tier = fateCoreData[_fateCoreData[i].name].tier;
                uint256 _gachaGrade = fateCoreData[_fateCoreData[i].name].gachaGrade;
                for (uint256 j = 0; j < fateCoreInfoTable[_tier][_gachaGrade].length; j++) {
                    if (keccak256(abi.encodePacked(fateCoreInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(_fateCoreData[i].name))) {
                        index = j;
                        break;
                    }
                }
                for (uint256 j = index; j < fateCoreInfoTable[_tier][_gachaGrade].length - 1; j++) {
                    fateCoreInfoTable[_tier][_gachaGrade][j] = fateCoreInfoTable[_tier][_gachaGrade][j + 1];
                }
                fateCoreInfoTable[_tier][_gachaGrade].pop();
            }
            fateCoreInfoTable[_fateCoreData[i].tier][_fateCoreData[i].gachaGrade].push(_fateCoreData[i].name);
            fateCoreData[_fateCoreData[i].name] = _fateCoreData[i];

            emit SetFateCoreData(_fateCoreData[i].name, _fateCoreData[i].tier, _fateCoreData[i].gachaGrade, _fateCoreData[i].classType, _fateCoreData[i].nation, _fateCoreData[i].element, _fateCoreData[i].isValid);
        }
    }

    function deleteFateCoreData(string[] memory names) external onlyOwner {
        for (uint256 i = 0; i < names.length; i++) {
            uint256 _tier = fateCoreData[names[i]].tier;
            uint256 _gachaGrade = fateCoreData[names[i]].gachaGrade;

            uint256 index;
            for (uint256 j = 0; j < fateCoreInfoTable[_tier][_gachaGrade].length; j++) {
                if (keccak256(abi.encodePacked(fateCoreInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(fateCoreData[names[i]].name))) {
                    index = j;
                    break;
                }
            }
            for (uint256 j = index; j < fateCoreInfoTable[_tier][_gachaGrade].length - 1; j++) {
                fateCoreInfoTable[_tier][_gachaGrade][j] = fateCoreInfoTable[_tier][_gachaGrade][j + 1];
            }
            fateCoreInfoTable[_tier][_gachaGrade].pop();
            fateCoreCount--;

            emit DeleteFateCoreData(fateCoreData[names[i]].name, fateCoreData[names[i]].tier, fateCoreData[names[i]].gachaGrade, fateCoreData[names[i]].classType, fateCoreData[names[i]].nation, fateCoreData[names[i]].element, fateCoreData[names[i]].isValid);
            delete fateCoreData[names[i]];
        }
    }

    function getFateCoreCount() public view returns (uint256) {
        return fateCoreCount;
    }

    function getFateCoreCountByTireAndGachaGrade(uint256 _tier, uint256 _gachaGrade) public view returns (uint256) {
        return fateCoreInfoTable[_tier][_gachaGrade].length;
    }

    function getFateCoreInfoByTireAndIndex(uint256 _tier, uint256 _gachaGrade, uint index) public view returns (string memory) {
        return fateCoreInfoTable[_tier][_gachaGrade][index];
    }
}