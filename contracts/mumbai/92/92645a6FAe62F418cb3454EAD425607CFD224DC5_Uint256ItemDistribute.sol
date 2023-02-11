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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
contract CooperatableBase is Ownable 
{
    mapping (address => bool) cooperative_contracts;
    function add_cooperative(address contract_addr) external onlyOwner{
        cooperative_contracts[contract_addr] = true;
    }
    function add_cooperatives(address[] memory contract_addrs) external onlyOwner {
        for(uint256 i = 0; i < contract_addrs.length; i++)
            cooperative_contracts[contract_addrs[i]] = true;
    }

    function remove_cooperative(address contract_addr) external onlyOwner {
        delete cooperative_contracts[contract_addr];
    }
    function remove_cooperatives(address[] memory contract_addrs) external onlyOwner{
        for(uint256 i = 0; i < contract_addrs.length; i++)
           delete cooperative_contracts[contract_addrs[i]];
    }
    function is_cooperative_contract(address _addr) internal view returns (bool){return cooperative_contracts[_addr];}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CooperatableBase.sol";
import "../Interfaces/IRandomnessConsumer.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

//Fixed total supply item distribute use for reveal the unreveal collection to revealed one.
//Example : reveal erc721 pet collection to player.
abstract contract ItemDistributeBaseContract is CooperatableBase {
    
    using ERC165Checker for address;
    

    uint32 total_count = 10000;
    uint32[] private distributed;
    
    address private randomness_address;
    
    constructor(uint32 total_count_,address randomness_address_){
        total_count = total_count_;
        _set_randomness_internal(randomness_address_);
    }

    function set_total_count(uint32 newCount) external onlyOwner {
        if(total_count != newCount){
            total_count = newCount;
            _redistribute_internal();
        }
    }
    function set_randomness(address _addr) external onlyOwner {
        _set_randomness_internal(_addr);
    }
    function redistribute() external onlyOwner {
        _redistribute_internal();
    }
    function get_item_count() internal virtual returns (uint32);
    function is_fallback_item(uint32 index) internal virtual returns (bool);
    function get_item_amount(uint32 index) internal virtual returns (uint32);
    function get_randomness() public view returns(address) {return randomness_address;}
    
    function _set_randomness_internal(address _addr) internal{
        require(_addr != address(0),"ZERO_ADDRESS");
        require(_addr.supportsInterface(type(IRandomnessConsumer).interfaceId),"NOT_RANDOMNESS");
        randomness_address = _addr;
    }
    function _consume_distributed(uint32 rand_value,bool ordered) internal returns (bool,uint32,uint32){
        require(distributed.length > 0,"NO_DISTRIBUTED");
        uint32 chosen_index =  rand_value % (uint32(distributed.length));
        uint32 item_index = distributed[chosen_index];
        if(ordered)
            _remove_distributed_ordered(chosen_index);
        else
            _remove_distributed_unordered(chosen_index);
        return (item_index > 0,item_index - 1,chosen_index);
    }
    function _redistribute_internal() internal {
 
        uint32 item_count = get_item_count();
        uint32 fallback_item_count = 0;
        for(uint32 i = 0; i < item_count; i++){
           if(is_fallback_item(i))
               fallback_item_count++;
        }
        uint32 fallback_counter = 0;
        uint32[] memory fallback_indics = new uint32[](fallback_item_count);
        uint32[] memory list = new uint32[](total_count);
        for(uint32 i = 0; i < item_count; i++){
            if(is_fallback_item(i)){
                fallback_indics[fallback_counter] = i;
                fallback_counter++;
                continue;
            }

            uint32 item_amount = get_item_amount(i);
            uint32 distance = total_count / (item_amount + 1);
            for(uint32 e = 0; e < item_amount; e++){
                uint32 index= distance*(e+1);
                (bool found,uint32 free_index) = find_empty_element(list,index);
                if(found)
                    list[free_index] = i+1;
                else
                    revert("Failed to find index");
            }
        }
        uint32 fallback_nounce = 0;
        if(fallback_indics.length > 0){
            uint32 findex = (fallback_nounce % uint32(fallback_indics.length));
            for(uint32 i = 0; i < list.length; i++){
                if(list[i] == 0)
                    list[i] = fallback_indics[findex] + 1;
            }
        }
        distributed = list;
    }
    function _clear_distribute_internal() internal {
        distributed = new uint32[](0);
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
    function _remove_distributed_unordered(uint32 index) internal{
        distributed[index] = distributed[distributed.length - 1];
        distributed.pop();
    }
    function _remove_distributed_ordered(uint32 index) internal {
        for(uint i = index; i < distributed.length-1; i++)
            distributed[i] = distributed[i+1];      
        distributed.pop();
    }
    function get_distributed_list() public view returns (uint32[] memory){return distributed;}
    function get_total_count() public view returns (uint32){return total_count;}
    function distribute_remain() public view returns (uint32) {return uint32(distributed.length);}
    modifier onlyOwnerOrOperator(){
        bool _as_owner = owner() == msg.sender;
        bool _as_operator = is_cooperative_contract(msg.sender);
        require(_as_owner || _as_operator,"NOT_OWNER_OR_OPERATOR");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/ItemDistributeBaseContract.sol";
import "../Interfaces/IItemDistributeUint256.sol";

//Uint256 as item on distribute.
contract Uint256ItemDistribute is ItemDistributeBaseContract,IItemDistributeUint256 {
    
    struct Item{
        uint256 item;
        uint32 amount;
        bool as_fallback;
    }
    
    Item[] private items;
    
    event OnConsumeDistributed(address indexed addr,uint32 index,uint256 data,uint32 as_item_index);

    constructor(uint32 total_count_,address randomness_address_)
    ItemDistributeBaseContract(total_count_,randomness_address_){

    }

    function set_items(uint256[] memory datas,uint32[] memory amounts) external onlyOwner(){
       require(datas.length == amounts.length,"PARAM_DIM_MISMATCH");
       _clear_items_internal();
       for(uint32 i = 0; i < datas.length; i++)
            _add_item_internal(datas[i],amounts[i]);
        _redistribute_internal();
    }
    function clear_items() external onlyOwner {
        _clear_distribute_internal();
        _clear_items_internal();
    }
    function _do_consume_distributed(address addr,uint32 rand_value,bool ordered) internal returns (uint256){
        (bool found,uint32 item_index,uint32 chosen_value) = _consume_distributed(rand_value,ordered);
        require(found,"FAILED_ON_DISTRIBUTE");
        emit OnConsumeDistributed(addr,chosen_value,items[item_index].item,item_index);
        return items[item_index].item;
    }
    function test_consume_distributed(address addr,uint32 rand_value,bool ordered) external onlyOwner returns (uint256){
        return _do_consume_distributed(addr,rand_value,ordered);
    }
    function consume_distributed(address addr,bool ordered) external onlyOwnerOrOperator returns (uint256){
        require(get_randomness() != address(0),"NO_RANDOMNESS");
        IRandomnessConsumer randomness = IRandomnessConsumer(get_randomness());
        return _do_consume_distributed(addr,uint32(randomness.random(type(uint32).max)),ordered);
    }

    function _add_item_internal(uint256 data,uint32 amount) internal {
        items.push(Item({item : data,amount : amount,as_fallback : (amount == 0)}));
    }
    function _clear_items_internal() internal {
        while(items.length > 0)
            items.pop();
    }
    
    function get_item(uint32 index) public view returns(uint256,uint32,bool) {
        return (items[index].item,items[index].amount,items[index].as_fallback);
    }
    function get_items() public view returns (uint256[] memory,uint32[] memory,bool[] memory){
        uint256[] memory _datas = new uint256[](items.length);
        uint32[] memory _amounts = new uint32[](items.length);
        bool[] memory _fallbacks = new bool[](items.length);
        for(uint32 i = 0; i < items.length; i++){
            _datas[i] = items[i].item;
            _amounts[i] = items[i].amount;
            _fallbacks[i] = items[i].as_fallback;
        }
        return (_datas,_amounts,_fallbacks);
    }

    function get_item_count() internal virtual override returns (uint32){return uint32(items.length);}
    function is_fallback_item(uint32 index) internal virtual override returns (bool){return (items[index].amount == 0);}
    function get_item_amount(uint32 index) internal virtual override returns (uint32){
        return (index < items.length) ? items[index].amount : 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IItemDistributeUint256 {

    function consume_distributed(address addr,bool ordered) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRandomnessConsumer {

   //Random [0-range]
   function random(uint32 range) external returns (uint256);

   //Tell just refresh randomness - both manual or in-contract auto.
   function should_refresh_randomness() external view returns (bool);

   //Current random nounce
   function get_random_nounce() external view returns (uint256);
}