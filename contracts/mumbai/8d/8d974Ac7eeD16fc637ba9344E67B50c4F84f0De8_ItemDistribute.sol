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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ItemDistribute is Ownable {
    
    uint32 total_count = 10000;
    struct Item{
        string item;
        uint32 amount;
        bytes32 item_hash;
    }

    Item[] private items;
    mapping(bytes32 => bool) item_added; 

    uint32[] private distributed;

    constructor(){}

    function add_item(string memory name,uint32 amount) external onlyOwner{add_item_internal(name,amount);}
    function add_items(string[] memory names,uint32[] memory amounts) external onlyOwner{
        require(names.length == amounts.length,"PARAM_DIM_MISMATCH");
        for(uint32 i = 0; i < names.length; i++)
            add_item_internal(names[i],amounts[i]);
    }
    function remove_item(string memory name,bool ordered) external onlyOwner{remove_item_internal(name,ordered);}
    function remove_items(string[] memory names,bool ordered) external onlyOwner {
        for(uint32 i = 0; i < names.length; i++)
            remove_item_internal(names[i],ordered);
    }
    function set_total_count(uint32 newCount) external onlyOwner {
        total_count = newCount;
    }
    function add_item_internal(string memory name,uint32 amount) internal {
        bytes32 item_hash = keccak256(abi.encodePacked(name));
        if(item_added[item_hash]){
            items.push(Item({item : name,amount : amount,item_hash:item_hash}));
            item_added[item_hash] = true;
        }
    }
    function remove_item_internal(string memory name,bool ordered) internal{
        (bool found,uint32 index,bytes32 item_hash) = find_item_index(name);
        if(found){
            if(ordered)
                remove_ordered(index);
            else
               remove_unordered(index);
            delete item_added[item_hash];
        }
    }

    function evenly_distribute() external onlyOwner {
        uint32[] memory list = new uint32[](total_count);
        for(uint32 i = 0; i < items.length; i++){
            uint32 distance = total_count / (items[i].amount + 1);
            for(uint32 e = 0; e < items[i].amount; e++){
                uint32 index= distance*(e+1);
                (bool found,uint32 free_index) = find_empty_element(list,index);
                if(found)
                    list[free_index] = i+1;
                else
                    revert("Failed to find index");
            }
        }
        distributed = list;
    }
    function find_empty_element(uint32[] memory list_,uint32 center_index_) internal pure returns(bool,uint32){
        if(list_[center_index_] == 0)
            return (true,center_index_);
        
        uint32 MAX_VALUE = type(uint32).max;
        uint32 _left_index = MAX_VALUE;
        if(center_index_ > 0){
            _left_index = center_index_ - 1;
            while((_left_index > 0) && (list_[_left_index] > 0)){
                _left_index--;
            }
            _left_index = (list_[_left_index] == 0) ? _left_index : MAX_VALUE;
        }

        uint32 _right_index = MAX_VALUE;
        if(center_index_ < list_.length){
            _right_index = center_index_ + 1;
            while((_right_index < list_.length) && (list_[_right_index] > 0)){
                _right_index++;
            }
            _right_index = (list_[_right_index] == 0) ? _right_index : MAX_VALUE;
        }
        if(_right_index == MAX_VALUE || _left_index == MAX_VALUE){
            if(_right_index < MAX_VALUE)
                return (true,_right_index);
            else if(_left_index < MAX_VALUE)
                return (true,_left_index);
        }
        else{
            uint32 left_distance = center_index_ - _left_index;
            uint32 right_distance = _right_index - center_index_;
            if(left_distance < right_distance)
                return (true,_left_index);
            else 
                return (true,_right_index);
        }
        return (false,0);
    }
    function find_item_index(string memory name) internal view returns (bool,uint32,bytes32){
        bytes32 search_bytes = keccak256(abi.encodePacked(name));
        for(uint32 i = 0; i < items.length; i++){
            if(items[i].item_hash == search_bytes)
                return (true,i,items[i].item_hash);
        }
        return (false,0,0);
    }
    function remove_unordered(uint32 index) internal{
        items[index] = items[items.length - 1];
        items.pop();
    }
    function remove_ordered(uint32 index) internal {
        for(uint i = index; i < items.length-1; i++)
            items[i] = items[i+1];      
        items.pop();
    }
    function get_distributed_list() public view returns (uint32[] memory){return distributed;}
    function get_total_count() public view returns (uint32){return total_count;}
}