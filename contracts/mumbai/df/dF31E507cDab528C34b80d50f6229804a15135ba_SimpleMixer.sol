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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleMixer is Ownable {
    address treasuryWallet;

    uint256 RING_PARTICIPANT = 2;

    uint256[4] allowedAmounts;
    uint256[4] allowedFees;
    uint256[4] ringIndexes = [1, 2, 3, 4];
    uint256 denominator = 1000;

    struct Ring {
        uint256 amountDeposited;
        uint256 fee;
        uint256 ringIndex;
    }

    mapping(uint256 => Ring) public rings;

    event RingTrigger(uint256 amountDeposited, uint256 fee, uint256 ringIndex);

    constructor() {
        treasuryWallet = 0xAc8A130aF6B1AA186Bc08a3EddC7dc725e0db072;
    }

    function depositEth() public payable {
        uint256 fee = getFeeForAmount(amountCheck(msg.value));
        uint256 amount = amountCheck(msg.value) - fee;
        uint256 ringIndex = getRingIndex(msg.value);

        payable(treasuryWallet).transfer(fee);

        rings[ringIndex].amountDeposited += amount;
        rings[ringIndex].fee = fee;
        rings[ringIndex].ringIndex = ringIndex;

        if (rings[ringIndex].amountDeposited >= amount * RING_PARTICIPANT) {
            emit RingTrigger(rings[ringIndex].amountDeposited, rings[ringIndex].fee, rings[ringIndex].ringIndex);
        }
    }

    function withdrawEth(address[] memory addresses, uint256 _ringIndex) external onlyOwner {
        require(address(this).balance >= rings[_ringIndex].amountDeposited, "Pool Balance exceed");
        require(rings[_ringIndex].amountDeposited > 0, "RING_EMPTY");
        require(addresses.length == RING_PARTICIPANT, "INVALID_RING_PARTICIPANT");
        uint256 withdrawableETH = allowedAmounts[_ringIndex - 1] - rings[_ringIndex].fee;
        for (uint256 i = 0; i < addresses.length; i++) {
            payable(addresses[i]).transfer(withdrawableETH);
        }
        rings[_ringIndex].amountDeposited = 0;
    }

    function getFeeForAmount(uint256 amount) public view returns (uint256){
        uint256 allowedFee;
        uint256 feeAmount;
        for (uint256 i = 0; i < allowedAmounts.length; i++) {
            if (allowedAmounts[i] == amount) {
                allowedFee = allowedFees[i];
            }
        }
        feeAmount = amount * allowedFee / denominator;
        return feeAmount;
    }

    function getRingIndex(uint256 amount) public view returns (uint256){
        uint256 ringIndex;
        for (uint256 i = 0; i < allowedAmounts.length; i++) {
            if (allowedAmounts[i] == amount) {
                ringIndex = ringIndexes[i];
            }
        }
        return ringIndex;
    }

    function getAllowedAmounts() external view returns (uint256[4] memory) {
        return allowedAmounts;
    }

    function amountCheck(uint256 _amount) internal view returns (uint256)
    {
        bool allowed = false;
        uint256 _length = allowedAmounts.length;

        for (uint256 i = 0; i < _length;) {
            if (allowedAmounts[i] == _amount) {
                allowed = true;
            }
            if (allowed) {
                break;
            }

        unchecked {
            i++;
        }
        }

        // Revert if token sent isn't in the allowed fixed amounts
        require(allowed, "AMOUNT_NOT_ALLOWED");
        return _amount;
    }

    // configure settings //////////////////////////////////////////
    function setTreasuryWallet(address _treasuryWallet) public onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    function setAllowedAmounts(uint256[4] memory _wei_amounts) public onlyOwner {
        require(allowedAmounts.length == _wei_amounts.length, "ARRAY_LENGTH_MISMATCH");

        for (uint256 i = 0; i < allowedAmounts.length;) {
            allowedAmounts[i] = _wei_amounts[i];
        unchecked {
            i++;
        }
        }
    }

    function setRingParticipate(uint256 _ring_participant) public onlyOwner {
        RING_PARTICIPANT = _ring_participant;
    }

    function setAllowedFees(uint256[4] memory _fees) public onlyOwner {
        require(allowedFees.length == _fees.length, "ARRAY_LENGTH_MISMATCH");

        for (uint256 i = 0; i < allowedFees.length;) {
            allowedFees[i] = _fees[i];
        unchecked {
            i++;
        }
        }
    }
}