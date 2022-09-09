// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ILayerZeroEndpoint {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;
}

contract CrossChainGelatoLicker is Ownable {
    address public immutable ops;
    ILayerZeroEndpoint public immutable lzEndpoint;

    mapping(uint16 => mapping(uint256 => uint256)) public lastLicked;

    modifier onlyOps() {
        require(msg.sender == ops, "CrossChainGelatoLicker: Only ops");
        _;
    }

    constructor(address _ops, ILayerZeroEndpoint _lzEndpoint) {
        ops = _ops;
        lzEndpoint = _lzEndpoint;
    }

    receive() external payable {}

    //@dev called by Gelato whenever `checker` returns true
    function initiateCCLick(
        uint16 _lzChainId,
        address _dstLicker,
        uint256 _tokenId
    ) external payable onlyOps {
        bytes memory lickPayload = abi.encode(_tokenId);

        lastLicked[_lzChainId][_tokenId] = block.timestamp;

        lzEndpoint.send{value: address(this).balance}(
            _lzChainId,
            abi.encodePacked(_dstLicker),
            lickPayload,
            payable(this),
            address(0),
            bytes("")
        );
    }

    //@dev called by Gelato check if it is time to call `initiateCCLick`
    function checker(
        uint16 _lzChainId,
        address _dstLicker,
        uint256 _tokenId
    ) external view returns (bool canExec, bytes memory execPayload) {
        if (block.timestamp < lastLicked[_lzChainId][_tokenId] + 600) {
            canExec = false;
            execPayload = bytes(
                "CrossChainGelatoLicker: Not time to cross chain lick"
            );
            return (canExec, execPayload);
        }

        canExec = true;
        execPayload = abi.encodeWithSelector(
            this.initiateCCLick.selector,
            _lzChainId,
            _dstLicker,
            _tokenId
        );

        return (canExec, execPayload);
    }
}