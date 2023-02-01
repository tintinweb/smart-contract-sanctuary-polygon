// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./openzeppelin-contracts/contracts/access/Ownable.sol";

interface reyuContracts {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract RGCGRT is Ownable
{
    reyuContracts[] public _contracts = [
    reyuContracts(0x15F3E5A30E45A58b15BBA610F27689FBc7De8c3c),
    reyuContracts(0xB55A820d92809bcFF91d568fC1ef0E451c69f5e8),
    reyuContracts(0x5891eB497D1ddB4e3933981B55B37D5F98BBfBCF),
    reyuContracts(0x16a1DCD0f76947dc3d3bA5158952107eF0321aD9),
    reyuContracts(0x6a570bB15Bc67968868c19b0ec7DCcCdFd8ED089)
    ];

    uint[] public nftIDs = [888000020,888000048,888000061,888000072,888000118,888000155,888000206,888000294,888000295,888000345,888000514,888000672,888000724,888000725,888000772,888000773,888000815,888000853,888000888,888000889,888000934,888000980,888001064,888001111,888001112,888001113,888001149,888001150,888001151,888001152,888001189,888001232,888001269,888001270,888001292,888001311,888001312,888001363,888001364,888001365,888001366,888001462,888001463,888001464,888001510,888001529,888001552,888001553,888001575,888001597,888001642,888001644,888001689,888001690,888001691,888001736,888001737,888001777,888001778,888001816,888001858,888001897,888001898,888001983,888001984,888002025,888002075,888002077,888002109,888002155,888002180,888002208,888002209,888002254,888002293,888002335,888002370,888002431,888400003,888400183,888400203,888400216,888400233,888400255,888400310,888400317,888400367,888400368,888400369,888400387,888400413,888400463,888400496,888400519,888400632,888400657,888400658,888400671,888400686,888400708,888400763,888400804,888400898,888400949,888400950,888400978,888401009,888401010,888401085,888401097,888401124,888401175,888401176,888401213,888401330,888401360,888401381,888401382,888401442,888401465,888401495,888700013,888700045,888700070,888700078,888700095,888700128,888700139,888700140,888700209,888700308,888700319,888800006,888800093,888800118,888800138,888800190,888800195,888888890,888888959];
    
    function updateNFTids(uint256[] memory _IDs) public
    {
        for(uint i=0; i < _IDs.length; i++){
            nftIDs.push(_IDs[i]);
        }
    }

    function getInts() public view returns(uint[] memory) {
        return nftIDs;
    }

    function shuffle() public returns(uint[] memory)
    {

        uint[] memory uintsCopy = nftIDs;

        uint counter = 0;
        uint j = 0;
        bytes32 b32 = keccak256(abi.encodePacked(block.timestamp + counter));
        uint length = uintsCopy.length;

        for (uint256 i = 0; i < uintsCopy.length; i++) {

            if(j > 31) {
                b32 = keccak256(abi.encodePacked(block.timestamp + ++counter));
                j = 0;
            }

            uint8 value = uint8(b32[j++]);

            uint256 n = value % length;

            uint temp = uintsCopy[n];
            uintsCopy[n] = uintsCopy[i];
            uintsCopy[i] = temp;
        }

        nftIDs = uintsCopy;

        return uintsCopy;

    }

    function removeIndex(uint256 index) internal
    {
        if (index >= nftIDs.length) return;

        nftIDs[index] = nftIDs[nftIDs.length - 1];
        nftIDs.pop();
    }

    uint256[] public CharacterBuffer = [
    888000000,
    888400000,
    888700000,
    888800000,
    888888888
    ];

    function tokenRange(uint256 _id) public view
    returns(uint256)
    {
        uint256[] memory buffer = CharacterBuffer;
        string memory err = string(abi.encodePacked(_id, "NFT id is less than buffer value"));
        require(_id >= buffer[0], err);

        uint256 _contract;

        if(_id <= buffer[1]){
            _contract = 0;
        }else if(_id <= buffer[2]){
            _contract = 1;
        }else if(_id <= buffer[3]){
            _contract = 2;
        }else if(_id <= buffer[4]){
            _contract = 3;
        }else{
            _contract = 4;
        }

        return _contract;
    }


    function returnRandomIndex() public view
    returns(uint256)
    {
        uint256 arrayLenght = nftIDs.length;
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender,arrayLenght)))%arrayLenght;

        return rand;
    }

    function transfer(address _vault, address _address)
    public onlyOwner()
    {

        shuffle();

        uint256 randomID = returnRandomIndex();

        uint256 _tokenRange = tokenRange(randomID);

        _contracts[_tokenRange].transferFrom(
            _vault,
            _address,
            nftIDs[randomID]
        );

        removeIndex(randomID);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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