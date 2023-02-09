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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
import "@openzeppelin/contracts/utils/Counters.sol";

//Distribute like Roulette. just for control how hard to random items.
//Main usage is lootbox or reveal one item to another.
abstract contract RouletteDistributeBaseContract is CooperatableBase {

    struct Interval{
        string name;
        uint32 min_value;
        uint32 max_value;
        uint32 distribute_quota;
        uint32 remain_quota;
        bool is_ssr;
        bool include_in_ssr_gurantee;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _interval_ids;

    //In case overlap range we use nounce with modulo.
    uint256 private overlap_nonnce = 0;
    uint32 private total_range = 100000;
    uint32 private ssr_gurantee_nounce = 100;

    mapping(uint256 => Interval) private intervals;
    mapping(uint256 => bool) private defined; 
    mapping(address => uint32) private roulette_nounces;

    constructor(uint32 total_range_,uint32 ssr_gurantee_nounce_){
        total_range = total_range_;
        ssr_gurantee_nounce = ssr_gurantee_nounce_;
    }
    

    function _add_interval(string memory name_,uint32 min_,uint32 max_,uint32 quota_,bool ssr_,bool include_ssr_guarantee_) internal returns (uint256){
        require(max_ > min_,"INVALID_INTERVAL_RANGE");
        _interval_ids.increment();
        uint256 _next_id = _interval_ids.current();
        intervals[_next_id].name = name_;
        intervals[_next_id].min_value = min_;
        intervals[_next_id].max_value = max_;
        intervals[_next_id].distribute_quota = quota_;
        intervals[_next_id].remain_quota = quota_;
        intervals[_next_id].is_ssr = ssr_;
        intervals[_next_id].include_in_ssr_gurantee = include_ssr_guarantee_;
        defined[_next_id] = true;
        return  _next_id;
    }
    function _remove_interval(uint256 _id) internal {
        require(defined[_id],"NO_INTERVAL");
        delete defined[_id];
        delete intervals[_id];
    }
    function _update_interval_range(uint256 id_,uint32 min_,uint32 max_) internal {
        require(defined[id_],"NO_INTERVAL");
        require(max_ > min_,"INVALID_INTERVAL_RANGE");
        intervals[id_].min_value = min_;
        intervals[id_].max_value = max_;
    }
    function _update_interval_quota(uint256 id_,uint32 quota) internal {
        require(defined[id_],"NO_INTERVAL");
        intervals[id_].distribute_quota = quota;
        if(quota < intervals[id_].remain_quota)
            intervals[id_].remain_quota = quota;
    }
    function _update_interval_name(uint256 id_,string memory name) internal {
        require(defined[id_],"NO_INTERVAL");
        intervals[id_].name = name;
    }
    function _update_ssr_metadata(uint256 id_,bool ssr_,bool include_ssr_guarantee_) internal {
        require(defined[id_],"NO_INTERVAL");
        intervals[id_].is_ssr = ssr_; 
        intervals[id_].include_in_ssr_gurantee = include_ssr_guarantee_;
    }

    function set_total_range(uint32 newRange) external onlyOwner {
        require(newRange >= 2,"RANGE_LOWER_THAN_2");
        total_range = newRange;
    }   
    function set_ssr_guarantee_nounce(uint32 nounce) external onlyOwner {
        require(nounce > 1,"RANGE_LOWER_THAN_1");
        ssr_gurantee_nounce = nounce;
    }
    function reset_overlap_nounce() external onlyOwner {
        ssr_gurantee_nounce = 0;
    }

    //Do roulette and return match interval_id.
    function _roulette(address _addr,uint32 rand_value,bool include_none_on_multi_overlap) internal onlyOwnerOrOperator returns (bool,uint256){
        uint256 found_interval_id = 0;
        uint32 chosen_value = (rand_value%total_range);

        uint256 overlap_count = 0;
        uint256 ssr_gurantee_count = 0;

        uint256[] memory overlapped = new uint256[](_interval_ids.current() + 1);
        uint256[] memory ssr_gurantees = new uint256[](_interval_ids.current() + 1);

        for(uint256 tid = 1; tid <= _interval_ids.current(); tid++){
            if(defined[tid]){
                if(is_in_range(tid,chosen_value)){
                    overlapped[overlap_count] = tid;
                    overlap_count++;
                }
                if(is_ssr_gurantee(tid)){
                    ssr_gurantees[ssr_gurantee_count] = tid;
                    ssr_gurantee_count++;
                }
            }
        }
        
        bool got_ssr = false;
        if((ssr_gurantee_count > 0) && (roulette_nounces[_addr] > ssr_gurantee_nounce)){
            found_interval_id = overlapped[overlap_nonnce%overlap_count];
            deduct_quota(found_interval_id);
            overlap_nonnce++;
            got_ssr = true;
        }
        else{
            if(overlap_count >= 1){
                if(overlap_count > 1){
                    if(include_none_on_multi_overlap){
                        overlapped[overlap_count] = 0;
                        overlap_count++;
                    }
                    found_interval_id = overlapped[overlap_nonnce%overlap_count];
                    overlap_nonnce++;
                }
                else
                    found_interval_id = overlapped[0];
                
                if(found_interval_id > 0){
                    deduct_quota(found_interval_id);
                    got_ssr = intervals[found_interval_id].is_ssr;
                }
            }
        }
        if(got_ssr)
            roulette_nounces[_addr] = 0;
        else
            roulette_nounces[_addr]++;

        return (overlap_count >= 1,found_interval_id);
    }
    function is_in_range(uint256 interval_id,uint32 rand_value) internal view returns (bool){
        return (rand_value >= intervals[interval_id].min_value) && (rand_value >= intervals[interval_id].max_value);
    }
    function is_ssr_gurantee(uint256 interval_id) internal view returns (bool){
        return intervals[interval_id].is_ssr && intervals[interval_id].include_in_ssr_gurantee;
    }
    function is_on_quota(uint256 interval_id) internal view returns (bool){
        if(intervals[interval_id].distribute_quota == 0)
            return true;
        return (intervals[interval_id].remain_quota > 0);
    }
    function deduct_quota(uint256 interval_id) internal {
        if(intervals[interval_id].remain_quota > 0)
           intervals[interval_id].remain_quota--;
    } 
    function is_defined(uint256 interval_id) internal view returns (bool){return defined[interval_id];}
    function get_interval(uint256 interval_id) internal view returns (Interval memory){return intervals[interval_id];}
    function get_interval_metadata(uint256 interval_id) external view returns (string memory,uint32,uint32,uint32,uint32,bool,bool){
        Interval memory inv = get_interval(interval_id);
        return (inv.name,inv.min_value,inv.max_value,inv.distribute_quota,inv.remain_quota,inv.is_ssr,inv.include_in_ssr_gurantee);
    }
    function get_total_range() public view returns (uint32){return total_range;}
    function get_last_interval_id() public view returns (uint256) {return _interval_ids.current();}
    function get_roulette_nounce(address _addr) public view returns (uint32) {return roulette_nounces[_addr];}
    modifier onlyOwnerOrOperator(){
        bool _as_owner = owner() == msg.sender;
        bool _as_operator = is_cooperative_contract(msg.sender);
        require(_as_owner || _as_operator,"NOT_OWNER_OR_OPERATOR");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/RouletteDistributeBaseContract.sol";
import "../Interfaces/IERC20TokenContract.sol";
import "../Interfaces/IERC1155TokenContract.sol";
import "../Interfaces/IERC721TokenContract.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

//Use for distribute string item such as token_uri.
contract ItemRouletteDistribute is RouletteDistributeBaseContract {
    
    using ERC165Checker for address;
    enum RewardType{ TOKEN, ERC1155, ERC721 }
    struct Reward{
        RewardType reward_type;
        address contract_address;
        uint256 token_id; 
        uint256 min_amount;
        uint256 max_amount;
    }

    mapping(uint256 => Reward) private rewards;    
    Reward[] default_rewards;
    
    constructor(uint32 total_range_,uint32 ssr_gurantee_nounce_)
    RouletteDistributeBaseContract(total_range_,ssr_gurantee_nounce_){

    }

    function add_token_reward(string memory name_,uint32 min_range,uint32 max_range,uint32 quota,bool ssr,bool include_ssr_guarantee,address token_contract,uint256 min_amount,uint256 max_amount) external onlyOwner{
        uint256 interval_id = _add_interval(name_,min_range,max_range,quota,ssr,include_ssr_guarantee);
        _set_reward_as_token(interval_id,token_contract,min_amount,max_amount);
    }
    function add_multitoken_reward(string memory name_,uint32 min_range,uint32 max_range,uint32 quota,bool ssr,bool include_ssr_guarantee,address token_contract,uint256 token_id,uint256 min_amount,uint256 max_amount) external onlyOwner{
        uint256 interval_id = _add_interval(name_,min_range,max_range,quota,ssr,include_ssr_guarantee);
        _set_reward_as_multitoken(interval_id,token_contract,token_id,min_amount,max_amount);
    
    }
    function add_individual_reward(string memory name_,uint32 min_range,uint32 max_range,uint32 quota,bool ssr,bool include_ssr_guarantee,address token_contract,uint256 min_amount,uint256 max_amount) external onlyOwner{
        uint256 interval_id = _add_interval(name_,min_range,max_range,quota,ssr,include_ssr_guarantee);
        _set_reward_as_individual(interval_id,token_contract,min_amount,max_amount);
    }
    function remove_reward(uint256 interval_id) external onlyOwner {
        _remove_interval(interval_id);
        delete rewards[interval_id];
    }
    function roulette(address _addr,uint32 rand_value,bool include_none_on_multi_overlap) internal onlyOwnerOrOperator returns (RewardType,address,uint256,uint256){
        (bool found,uint256 interval_id) = _roulette(_addr, rand_value, include_none_on_multi_overlap);
        Reward memory _reward = (found && (interval_id > 0)) ? get_reward(interval_id) : sampling_default_reward(_addr);
        uint256 amount = _reward.min_amount;
        if(_reward.min_amount != _reward.max_amount)
            amount = _reward.min_amount + rand_value%(_reward.max_amount - _reward.min_amount);
        return (_reward.reward_type,_reward.contract_address,_reward.token_id,amount);
    }
    function sampling_default_reward(address _addr) internal view returns (Reward memory) {
        uint32 _index = uint32(get_roulette_nounce(_addr)%default_rewards.length);
        return default_rewards[_index];
    }
    
    function get_reward(uint256 interval_id) internal view returns (Reward memory) {return rewards[interval_id];}
    function get_reward_metadata(uint256 interval_id) external view returns (RewardType,address,uint256,uint256,uint256) {
        Reward memory _reward = get_reward(interval_id);
        return (_reward.reward_type,_reward.contract_address,_reward.token_id,_reward.min_amount,_reward.max_amount);
    }
    function get_default_reward(uint32 index) internal view returns (Reward memory) {
        require(index < default_rewards.length,"OUTOF_INDEX");
        return default_rewards[index];
    }
    function get_default_reward_metadata(uint32 index) external view returns (RewardType,address,uint256,uint256,uint256) {
        Reward memory _reward = get_default_reward(index);
        return (_reward.reward_type,_reward.contract_address,_reward.token_id,_reward.min_amount,_reward.max_amount);
    }
    
    function get_default_rewards() public view returns (Reward[] memory){return default_rewards;}
    function get_default_rewards_count() public view returns (uint256){return default_rewards.length;}

    function update_reward_as_token(uint256 interval_id,address token_contract,uint256 min_amount,uint256 max_amount) external onlyOwner{
        _set_reward_as_token(interval_id,token_contract,min_amount,max_amount);
    }
    function update_reward_as_multitoken(uint256 interval_id,address token_contract,uint256 token_id,uint256 min_amount,uint256 max_amount) external onlyOwner{
        _set_reward_as_multitoken(interval_id,token_contract,token_id,min_amount,max_amount);
    }
    function update_reward_as_individual(uint256 interval_id,address token_contract,uint256 min_amount,uint256 max_amount) external onlyOwner{
        _set_reward_as_individual(interval_id,token_contract,min_amount,max_amount);
    }
    function add_default_reward_as_token(address token_contract,uint256 min_amount,uint256 max_amount) external onlyOwner{
        default_rewards.push(_form_token_reward(token_contract,min_amount,max_amount));
    }
    function add_default_reward_as_multitoken(address token_contract,uint256 token_id,uint256 min_amount,uint256 max_amount) external onlyOwner{
        default_rewards.push(_form_erc1155_reward(token_contract,token_id,min_amount,max_amount));
    }
    function add_default_reward_as_individual(address token_contract,uint256 min_amount,uint256 max_amount) external onlyOwner{
        default_rewards.push(_form_erc721_reward(token_contract,min_amount,max_amount));
    }
    function remove_default_reward(uint32 index,bool ordered) external onlyOwner{
        require(index < default_rewards.length,"OUTOF_INDEX");
        if(ordered)
            _remove_default_reward_ordered(index);
        else
            _remove_default_reward_unordered(index);
    }



    function _remove_default_reward_ordered(uint32 index) internal{
         for(uint i = index; i < default_rewards.length-1; i++)
            default_rewards[i] = default_rewards[i+1];      
        default_rewards.pop();
    }
    function _remove_default_reward_unordered(uint32 index) internal{
        default_rewards[index] = default_rewards[default_rewards.length - 1];
        default_rewards.pop();
    }
    

    function _set_reward_as_token(uint256 interval_id,address token_contract,uint256 min_amount,uint256 max_amount) internal{
        rewards[interval_id] = _form_token_reward(token_contract,min_amount,max_amount);
    }
    function _set_reward_as_multitoken(uint256 interval_id,address token_contract,uint256 token_id,uint256 min_amount,uint256 max_amount) internal{
        rewards[interval_id] = _form_erc1155_reward(token_contract,token_id,min_amount,max_amount);
    }
    function _set_reward_as_individual(uint256 interval_id,address token_contract,uint256 min_amount,uint256 max_amount) internal{
        rewards[interval_id] = _form_erc721_reward(token_contract,min_amount,max_amount);
    }
    function _form_token_reward(address token_contract,uint256 min_amount,uint256 max_amount) internal view returns (Reward memory){
        require(token_contract != address(0),"NULL_ADDRESS");
        require(token_contract.supportsInterface(type(IERC20TokenContract).interfaceId),"NOT_ERC20_CONTRACT");
        require(min_amount <= max_amount,"INVALID_RANGE");
        return Reward(RewardType.TOKEN,token_contract,0,min_amount,max_amount);
    }
    function _form_erc1155_reward(address token_contract,uint256 token_id,uint256 min_amount,uint256 max_amount) internal view returns (Reward memory){
        require(token_contract != address(0),"NULL_ADDRESS");
        require(token_contract.supportsInterface(type(IERC1155TokenContract).interfaceId),"NOT_ERC1155_CONTRACT");
        require(min_amount <= max_amount,"INVALID_RANGE");
        require(IERC1155TokenContract(token_contract).is_token_defined(token_id),"TOKEN_UNDEFINED");
        return Reward(RewardType.ERC1155,token_contract,token_id,min_amount,max_amount);
    }
    function _form_erc721_reward(address token_contract,uint256 min_amount,uint256 max_amount)  internal view returns (Reward memory){
        require(token_contract != address(0),"NULL_ADDRESS");
        require(token_contract.supportsInterface(type(IERC721TokenContract).interfaceId),"NOT_ERC1155_CONTRACT");
        require(min_amount <= max_amount,"INVALID_RANGE");
        return Reward(RewardType.ERC721,token_contract,0,min_amount,max_amount);
    }
   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155TokenContract {

     //Get Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() external view returns (string memory);
    
    //Set Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory contractURI_) external;

    function lastTokenIds() external view returns (uint256);
    
    //Return token ids and amount.
    function ownedTokenOf(address _addr) external view returns(uint256[] memory,uint256[] memory);

    function canMintForAmount(uint256 tokenId,uint256 tokmentAmount) external view returns(bool);

    function canMintBulkForAmount(uint256[] memory tokenIds,uint256[] memory tokmentAmounts) external view returns(bool);
    
    function is_token_defined(uint256 token_id) external view returns (bool);

    //Mint nft for some user by contact owner. use for bleeding/crafting or mint NFT from App
    function mintNFTsFor(address _addr,uint256[] memory tokenIds,uint256[] memory amounts) external;

    //Burn nft for some user by contact owner. use for crafting or burn NFT from App
    function burnNFTsFor(address _addr,uint256[] memory tokenIds,uint256[] memory amounts) external;

    //Mint nft for some user by contact owner. use for bleeding/crafting or mint NFT from App
    function mintNFTFor(address _addr,uint256 tokenId,uint256 amount) external;

    //Burn nft for some user by contact owner. use for crafting or burn NFT from App
    function burnNFTFor(address _addr,uint256 tokenId,uint256 amount) external;

    function getTokenIds(uint256 page_index,uint256 per_page) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of erc20 token
 */
interface IERC20TokenContract {
   
    function mintFor(address _addr,uint256 toMintAmount) external;
    function burnFor(address _addr,uint256 toBurnAmount) external;
    function maxSupply() external view returns (uint256);
    function canMintForAmount(uint256 toMintAmount) external view returns(bool);  
    function remainFromMaxSupply() external view returns (uint256);      
    function getMetadata() external view returns (uint256,uint256,uint8,string memory);      
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IERC721TokenContract {
   
    //Get Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() external view returns (string memory);
    
    //Set Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory contractURI_) external;

    //Get all of items for address.
    function ownedTokenOf(address _addr) external view returns (uint256[] memory);

    //Check address is really own item.
    function isOwnedToken(address _addr,uint256 tokenId) external view returns(bool);

    //Update token URI for token Id
    function updateTokenURI(uint256 tokenId,string memory tokenURI) external;

    //Mint nft (unreveal only) for some user by contact owner. use for bleeding or mint NFT from App
    function mintNFTsFor(address addr,uint256 amount) external;

    //Mint nft for some user by contact owner. use for bleeding or mint NFT from App
    function mintNFTFor(address addr,string memory tokenURI) external;

    //Mint nft for some user by contact owner. use for bleeding or mint NFT from App
    function burnNFTFor(address addr,uint256 tokenId) external;

    //Update display name of token when unreveal.
    function getUnrevealName() external view returns (string memory);

    //Update token uri of token when unreveal.
    function getUnrevealTokenUri() external view returns (string memory);

    function getUnrevealMetadata() external view returns (string memory,string memory);    

    function getTokenIds(uint256 page_index,uint256 per_page) external view returns (uint256[] memory);
}