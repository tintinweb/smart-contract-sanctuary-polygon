// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IVRFConsumer.sol";

/**
 * @title ChanceDrop
 * @author chance.win
 */
contract ChanceDrop is Ownable {

    address VRF_ADDR;
    address public DROP_MINTER;
    
    function setVRF(address _addr) public onlyOwner {
        VRF_ADDR = _addr;
    }

    /**
     * @notice get_rand is used to get random number. 
     * @param start specify the minimum number of random.
     * @param end specify the maximum number of random.
     * @param _seed specify random seed.
     * @return rand result.
     */
    function get_rand(uint256 start, uint256 end, uint256 _seed) private pure returns(uint256) {
        if (end == 1) {
            return 1;
        }
        if (start == 0) {
            return 1 + _seed%(end);
        }
        return start + _seed%(end - start + 1);
    }

    function setDropOwner(address _addr) public onlyOwner {
        DROP_MINTER = _addr;
    }

    /**
     * @notice drop_winner_token_id is used to drop round and get result. 
     * @param round specify which round will be droped.
     * @param end specify the current nft ID.
     * @param lastEnd specify lastEnd.
     * @return winner_id result of nft ID.
     */
    function drop_winner_token_id(uint256 round, uint256 end, uint256 lastEnd) external returns (uint256){
        require(msg.sender == DROP_MINTER, "Permission Denied");
        if (end == lastEnd) {
            return 0;
        }
        uint256 start = round * 100 + 1;
        if (lastEnd <= start) {
            start = lastEnd; 
        }
        require(end > start, "Wrong Drop Condition");

        // get randomseed
        // uint256 _seed = uint256(keccak256(abi.encode(block.difficulty, block.timestamp, round)));
        uint256 _seed = IVRFConsumer(VRF_ADDR).getSeed(round%24);
        require(_seed !=0 , "Seed Not Ready");

        uint256 winner_in_round = get_rand(1, 10, _seed);
        uint256 winner_id;
        if (winner_in_round > 1){
            // drop winner in this round
            winner_id = get_rand(start, end, _seed);
        } else {
            // drop winner in history round
            if (start <= 1){
                winner_id = 1;
            } else {
                winner_id = get_rand(1, start - 1, _seed);
            }
        }
        return winner_id;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVRFConsumer {

  function requestRandomWords() external;

  function getSeed(uint256 _s) external returns(uint256);
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