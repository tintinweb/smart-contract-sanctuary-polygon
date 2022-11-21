// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBlindBox.sol";


contract BlindBox is Ownable, IBlindBox {
    
    uint8 private constant SUBSET_START = 0;
    uint8 private constant SUBSET_END = 1;
    
    address public governance;
    uint16[][] private _tokenIdsToDraw;
    uint16 private _subsetSize = 100;
    uint256 private _blindboxCount;

    event GovernanceUpdated(address _governance);
    event BlindBoxDraw(address _to, uint16[] _tokenIds);

    modifier canDraw(uint256 drawAmount) {
        require(_tokenIdsToDraw.length > 0, "No blindbox to draw");
        require(drawAmount <= _blindboxCount, "Not enough blindbox to draw");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance");
        _;
    }

    function setGovernance(address _governance) external onlyOwner {
        require(_governance != address(0), "Zero address");
        governance = _governance;
        emit GovernanceUpdated(_governance);
    }

    function setSubsetSize(uint16 _size) external onlyOwner {
        require(_size != 0, "Zero size");
        _subsetSize = _size;
    }

    function setTokenIds(uint16[] memory subsets) public onlyOwner {
        require(subsets.length > 0, "Zero length");
        uint16 lastSetEnd = 0;
        for (uint16 i = 0; i < subsets.length; i++) {
            uint16 subsetStart = subsets[i];
            uint16 subsetEnd = subsetStart + _subsetSize - 1;
            
            require(subsetStart > lastSetEnd, "Invalid subset");
            
            // subnet start ID and end ID
            uint16[2] memory subsetRange = [subsetStart, subsetEnd];
            _tokenIdsToDraw.push(subsetRange);
            _blindboxCount += _subsetSize;
            lastSetEnd = subsetEnd;
        }
    }

    function getSubsetSize() external view onlyOwner returns (uint256) {
        return _subsetSize;
    }

    function getBlindboxCount() external view onlyOwner returns (uint256) {
        return _blindboxCount;
    }

    function getSubsetLength() external view onlyOwner returns (uint256) {
        return _tokenIdsToDraw.length;
    }
 
    function getTokenIds(uint16 subnetIndex) external view onlyOwner returns (uint16[] memory) {
        return _tokenIdsToDraw[subnetIndex];
    }

    function draw(uint256 drawAmount) 
        external
        override
        onlyGovernance
        canDraw(drawAmount)
        returns (uint16[] memory)
    {
        uint16[] memory drawnIds = new uint16[](drawAmount);
        for (uint256 i = 0; i < drawAmount; i ++) {
            uint256 randInt = uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.coinbase,
                        block.difficulty,
                        block.gaslimit,
                        block.timestamp + i + 1
                    )
                )
            );

            uint256 subsetIndex = randInt % _tokenIdsToDraw.length;
            uint256 fromStart = randInt % 2;

            uint16 start = _tokenIdsToDraw[subsetIndex][SUBSET_START];
            uint16 end = _tokenIdsToDraw[subsetIndex][SUBSET_END];

            drawnIds[i] = fromStart == SUBSET_START ? start : end;
            _blindboxCount -= 1;

            if (start == end) {
                _popSubset(subsetIndex);
            } else {
                if (fromStart == SUBSET_START) {
                    _tokenIdsToDraw[subsetIndex] = [start + 1, end];
                } else {
                    _tokenIdsToDraw[subsetIndex] = [start, end - 1];
                }
            }
        }

        emit BlindBoxDraw(msg.sender, drawnIds);
        return drawnIds;
    }

    function _popSubset(uint256 subsetIndex) internal {
        _tokenIdsToDraw[subsetIndex] = _tokenIdsToDraw[_tokenIdsToDraw.length - 1];
        _tokenIdsToDraw.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBlindBox {
    
    function draw(uint256 drawAmount) external returns (uint16[] memory);

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