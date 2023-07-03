/**
 *Submitted for verification at polygonscan.com on 2023-07-03
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/color.sol



pragma solidity ^0.8.17;


contract Color is Ownable {
    string public Color_1 = "F9423A"; //red
    string public Color_2 = "E782A9"; //purple
    string public Color_3 = "00778B"; //blue
    string public Color_4 = "72246C"; //green//dark purple
    string public Color_5 = "FFB81C"; //gold
    string public Color_6 = "B9D9EB"; //silver BBDDE6//light blue B9D9EB
    string public Color_7 = "FFCD00"; //yellow
    string public Color_8 = "FE5000"; //orange

    constructor() {}

    function backgroundColors(
        uint256 index
    ) internal view returns (string memory) {
        string[12] memory bgColors = [
            Color_1, //red
            Color_1, //red
            Color_2, //purple
            Color_3, //blue
            Color_4, //green
            Color_5, //gold
            Color_6, //silver
            Color_7, //yellow
            Color_7, //yellow
            Color_8, //orange
            Color_8, //orange
            Color_7 //yellow
        ];
        return bgColors[index];
    }

    function stopOpacityPicker(
        uint256 index
    ) internal pure returns (string memory) {
        string[10] memory stopOpacity = [
            "0.1",
            "0.2",
            "0.3",
            "0.4",
            "0.5",
            "0.6",
            "0.7",
            "0.8",
            "0.9",
            "1.0"
        ];
        return stopOpacity[index];
    }

    function setColor_1(string memory _Color_1) public onlyOwner {
        Color_1 = _Color_1;
    }

    function setColor_2(string memory _Color_2) public onlyOwner {
        Color_2 = _Color_2;
    }

    function setColor_3(string memory _Color_3) public onlyOwner {
        Color_3 = _Color_3;
    }

    function setColor_4(string memory _Color_4) public onlyOwner {
        Color_4 = _Color_4;
    }

    function setColor_5(string memory _Color_5) public onlyOwner {
        Color_5 = _Color_5;
    }

    function setColor_6(string memory _Color_6) public onlyOwner {
        Color_6 = _Color_6;
    }

    function setColor_7(string memory _Color_7) public onlyOwner {
        Color_7 = _Color_7;
    }

    function setColor_8(string memory _Color_8) public onlyOwner {
        Color_8 = _Color_8;
    }
}