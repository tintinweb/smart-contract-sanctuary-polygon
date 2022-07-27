/**
 *Submitted for verification at polygonscan.com on 2022-07-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

library EnumerableSet {

    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }


    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

contract EcoWattClaim is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public immutable token;
    bool public claimPaused = false;

    EnumerableSet.AddressSet private walletsOutstanding;
    mapping(address => uint256) public amountClaimable;
    
    event AllocatedTokens(address indexed wallet, uint256 amount);
    event ResetAllocation(address indexed wallet);
    event ClaimedTokens(address indexed wallet,  uint256 amount);

    constructor(address tokenAddress){
        token = IERC20(tokenAddress);
    }

    modifier notPaused {
        require(!claimPaused, "Claim is paused");
        _;
    }

    function setClaimPaused(bool paused) external onlyOwner {
        claimPaused = paused;
    }
   
    function allocateTokens(address[] calldata wallets, uint256[] calldata amountsWithDecimals) external onlyOwner {
        require(wallets.length == amountsWithDecimals.length, "array lengths must match");
        address wallet;
        uint256 amount;
        for(uint256 i = 0; i < wallets.length; i++){
            wallet = wallets[i];
            amount = amountsWithDecimals[i];
            amountClaimable[wallet] += amount;
            emit AllocatedTokens(wallet, amount);
            if(!walletsOutstanding.contains(wallet)){
                walletsOutstanding.add(wallet);
            }
        }
    }

    // for resetting allocation in the event of a mistake
    function resetAllocation(address[] calldata wallets) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            amountClaimable[wallets[i]] = 0;
            emit ResetAllocation(wallets[i]);
        }
    }

    function claimTokens() external notPaused {
        uint256 amountToClaim = amountClaimable[msg.sender];
        require(amountToClaim > 0, "Cannot claim 0");
        require(walletsOutstanding.contains(msg.sender), "Wallet cannot claim");
        require(token.balanceOf(address(this)) >= amountToClaim, "Not enough tokens on contract to claim");
        amountClaimable[msg.sender] = 0; // prevent reentrancy
        token.transfer(msg.sender, amountToClaim);
        emit ClaimedTokens(msg.sender, amountToClaim);
        walletsOutstanding.remove(msg.sender);
    }

    function canWalletClaim(address account) external view returns (bool){
        return walletsOutstanding.contains(account);
    }

    function getWalletsOutstanding() external view returns (address[] memory){
        return walletsOutstanding.values();
    }
}