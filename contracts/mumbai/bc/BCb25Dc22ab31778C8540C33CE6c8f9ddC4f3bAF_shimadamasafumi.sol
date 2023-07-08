/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

// SPDX-License-Identifier: MIT

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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: contracts/shimadamasafumi.sol

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//               shimadamasafumi ArtWork On-chain Datebase v1                //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                           .    4  .     j                                 //
//                            -dT"""77777"""6a,.]                            //
//                         .J"`                 (4a,                         //
//                       .(=                        (S,                      //
//                     .F                             /h.                    //
//                    .F                                4 ,                  //
//                   #                                    ,b                 //
//                 .%                                      ,L                //
//                 J~                                       (p   `           //
//                 H                                         ?mAj,           //
//                [email protected]                             ..JT""Ya,.   W. .W,         //
//                .F          ..                J"        ?m. .b   W.        //
//              .J4]      .J"!``?"h,           J:   .gMN,   W. d,  ,b        //
//             [email protected] .F     .F  JMMe  ,h.         ([   HMMM#   .\ .b   #        //
//             f  .b     d  ,MMMM`  .\ `d\      ?m,  ?"=   .Y   W   #        //
//             @   H     v,   7^   .Y       ,     (4nJ..Jk"`    J; .]        //
//             W.  J<     ?WJ...JTF         4,     3  t  ?      ,].K         //
//             .h.+,b      ,   $            .b                  ,hB`         //
//              .MB=d,                      .F                  ,]           //
//              [email protected], N                      !                   (:           //
//              .#b?9"b                                         K            //
//             ,h.#   ?x                                      .%            //
//                     T,              .J"G.Y5.              .F              //
//                      v,             .D                  [email protected]                //
//                        ?a.          ?! 7`            .J^                  //
//                           ?h,                     .J"`                    //
//                              "U(,.           ..JT"                        //
//                                   ?7""""""""^`                            //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.0;


contract shimadamasafumi is Ownable {
    struct Work {
        string inventoryNumber;
        string title_en;
        string title_ja;
        string material;
        string edition;
        uint256 year;
        string size;
        string status;
    }

    mapping(uint256 => Work) private works;
    mapping(string => uint256) private workIdByTitle;
    uint256 private workCount;
    string private latestUpdateTitle;

    event WorkUpdated(uint256 indexed workId);

    function addWork(
        string memory _inventoryNumber,
        string memory _title_en,
        string memory _title_ja,
        string memory _material,
        string memory _edition,
        uint256 _year,
        string memory _size,
        string memory _status
    ) external onlyOwner {
        require(workIdByTitle[_inventoryNumber] == 0, "Work already exists");

        workCount++;
        works[workCount] = Work({
            inventoryNumber: string(abi.encodePacked(" ","\u29BF ", _inventoryNumber)),
            title_en: _title_en,
            title_ja: _title_ja,
            material: _material,
            edition: _edition,
            year: _year,
            size: _size,
            status: _status
        });

        workIdByTitle[_inventoryNumber] = workCount;
        latestUpdateTitle = _inventoryNumber;
        emit WorkUpdated(workCount);
    }

    function addNewInformation(string memory _inventoryNumber, string memory _newInformation) external onlyOwner {
        require(workIdByTitle[_inventoryNumber] > 0, "Work does not exist");

        uint256 workId = workIdByTitle[_inventoryNumber];
        string memory currentInformation = works[workId].status;
        string memory updatedInformation = string(abi.encodePacked(currentInformation, " \u2710 ", _newInformation));
        works[workId].status = updatedInformation;
        latestUpdateTitle = _inventoryNumber;
        emit WorkUpdated(workId);
    }

    function deleteStatusByInventoryNumber(string memory _inventoryNumber) external onlyOwner {
        require(workIdByTitle[_inventoryNumber] > 0, "Work does not exist");

        uint256 workId = workIdByTitle[_inventoryNumber];
        works[workId].status = "";
        emit WorkUpdated(workId);
    }

    function removeWorkByInventoryNumber(string memory _inventoryNumber) external onlyOwner {
        require(workIdByTitle[_inventoryNumber] > 0, "Work does not exist");

        uint256 workId = workIdByTitle[_inventoryNumber];
        delete works[workId];
        delete workIdByTitle[_inventoryNumber];
    }

    function getLatestUpdate() external view returns (string memory) {
        return latestUpdateTitle;
    }

    function getAllTitles() external view returns (string memory) {
        string memory titleInventoryNumbers;
        for (uint256 i = 1; i <= workCount; i++) {
            titleInventoryNumbers = string(abi.encodePacked(
                titleInventoryNumbers,
                works[i].inventoryNumber,
                "(",
                works[i].title_en,
                "), "
            ));
        }
        return titleInventoryNumbers;
    }

        function searchWorksByInventoryNumber(string memory _inventoryNumber) external view returns (Work[] memory) {
        uint256 workId = workIdByTitle[_inventoryNumber];
        if (workId == 0) {
            return new Work[](0);
        } else {
            Work[] memory result = new Work[](1);
            result[0] = works[workId];
            return result;
        }
    }

    function searchWorksByTitle(string memory _title_en) external view returns (Work[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= workCount; i++) {
            if (keccak256(bytes(works[i].title_en)) == keccak256(bytes(_title_en))) {
                count++;
            }
        }

        Work[] memory result = new Work[](count);
        count = 0;

        for (uint256 i = 1; i <= workCount; i++) {
            if (keccak256(bytes(works[i].title_en)) == keccak256(bytes(_title_en))) {
                result[count] = works[i];
                count++;
            }
        }

        return result;
    }

    function searchWorksByYear(uint256 _year) external view returns (Work[] memory) {
        Work[] memory result = new Work[](workCount);
        uint256 count = 0;

        for (uint256 i = 1; i <= workCount; i++) {
            if (works[i].year == _year) {
                result[count] = works[i];
                count++;
            }
        }

        assembly {
            mstore(result, count)
        }

        return result;
    }
}