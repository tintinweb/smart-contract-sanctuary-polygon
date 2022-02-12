pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract StaticStorage is Ownable {
    struct DownTown {
        uint256 xPos;
        uint256 yPos;
        uint256 id;
        string name;
        string image;
    }

    struct Emotional {
        uint256 xPos;
        uint256 yPos;
        uint256 id;
        string name;
        string image;
    }

    struct Env {
        uint256 xPos;
        uint256 yPos;
        uint256 id;
        string name;
        string image;
    }

    struct Intellectual {
        uint256 xPos;
        uint256 yPos;
        uint256 id;
        string name;
        string image;
    }


    struct OC {
        uint256 xPos;
        uint256 yPos;
        uint256 id;
        string name;
        string image;
    }


    struct Physical {
        uint256 xPos;
        uint256 yPos;
        uint256 id;
        string name;
        string image;
    }

    struct Spirtual {
        uint256 xPos;
        uint256 yPos;
        uint256 id;
        string name;
        string image;
    }

    struct Social {
        uint256 xPos;
        uint256 yPos;
        uint256 id;
        string name;
        string image;
    }

    event AddPhysical(uint256 _xPos, uint256 _yPos, string _name, string _image);
    event AddSocial(uint256 _xPos, uint256 _yPos, string _name, string _image);
    DownTown[] private downtownInfos;
    Env[] private envInfos;
    Emotional[] private emotionalInfos;
    OC[] private ocInfos;
    Intellectual[] private intellectualInfos;
    Spirtual[] private spirtualInfos;
    Social[] private socialInfos;
    Physical[] private physicalInfos;

    function getAllDowntownInfos() external view returns (DownTown[] memory) {
        return downtownInfos;
    }

    function getAllEmotionalInfos() external view returns (Emotional[] memory) {
        return emotionalInfos;
    }

    function getAllEnvInfos() external view returns (Env[] memory) {
        return envInfos;
    }

    function getAllIntellectualInfos() external view returns (Intellectual[] memory) {
        return intellectualInfos;
    }

    function getAllOCInfos() external view returns (OC[] memory) {
        return ocInfos;
    }

    function getAllPhysicalInfos() external view returns (Physical[] memory) {
        return physicalInfos;
    }


    function getAllSocialInfos() external view returns (Social[] memory) {
        return socialInfos;
    }

    function getAllSpirtualInfos() external view returns (Spirtual[] memory) {
        return spirtualInfos;
    }

    function addPhysicalInfo(uint256 _xPos, uint256 _yPos, uint256 _id, string memory _name, string memory _image) public onlyOwner {
        physicalInfos.push(
            Physical({
                xPos: _xPos,
                yPos: _yPos,
                id: _id,
                name: _name,
                image: _image
            })
        );
        emit AddPhysical(_xPos, _yPos, _name, _image);
    }

    function addSocialInfo(uint256 _xPos, uint256 _yPos, uint256 _id, string memory _name, string memory _image) public onlyOwner {
        socialInfos.push(
            Social({
                xPos: _xPos,
                yPos: _yPos,
                id: _id,
                name: _name,
                image: _image
                })
        );
        emit AddSocial(_xPos, _yPos, _name, _image);
    }

    function addSpirtualInfo(uint256 _xPos, uint256 _yPos, uint256 _id, string memory _name, string memory _image) public onlyOwner {
        spirtualInfos.push(
            Spirtual({
            xPos: _xPos,
            yPos: _yPos,
            id: _id,
            name: _name,
            image: _image
            })
        );
        emit AddSocial(_xPos, _yPos, _name, _image);
    }

    function addDownTownInfo(uint256 _xPos, uint256 _yPos, uint256 _id, string memory _name, string memory _image) public onlyOwner {
        downtownInfos.push(
            DownTown({
                xPos: _xPos,
                yPos: _yPos,
                id: _id,
                name: _name,
                image: _image
            })
        );
        emit AddSocial(_xPos, _yPos, _name, _image);
    }

    function addEmotionalInfo(uint256 _xPos, uint256 _yPos, uint256 _id, string memory _name, string memory _image) public onlyOwner {
        emotionalInfos.push(
            Emotional({
                xPos: _xPos,
                yPos: _yPos,
                id: _id,
                name: _name,
                image: _image
            })
        );
        emit AddSocial(_xPos, _yPos, _name, _image);
    }

    function addEnvInfo(uint256 _xPos, uint256 _yPos, uint256 _id, string memory _name, string memory _image) public onlyOwner {
        envInfos.push(
            Env({
                xPos: _xPos,
                yPos: _yPos,
                id: _id,
                name: _name,
                image: _image
            })
        );
        emit AddSocial(_xPos, _yPos, _name, _image);
    }

    function addIntellectualInfo(uint256 _xPos, uint256 _yPos, uint256 _id, string memory _name, string memory _image) public onlyOwner {
        intellectualInfos.push(
            Intellectual({
                xPos: _xPos,
                yPos: _yPos,
                id: _id,
                name: _name,
                image: _image
            })
        );
        emit AddSocial(_xPos, _yPos, _name, _image);
    }

    function addOCInfos(uint256 _xPos, uint256 _yPos, uint256 _id, string memory _name, string memory _image) public onlyOwner {
        ocInfos.push(
            OC({
                xPos: _xPos,
                yPos: _yPos,
                id: _id,
                name: _name,
                image: _image
            })
        );
        emit AddSocial(_xPos, _yPos, _name, _image);
    }
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