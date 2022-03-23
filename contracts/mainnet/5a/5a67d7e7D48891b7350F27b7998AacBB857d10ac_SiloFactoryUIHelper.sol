// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/ISiloFactory.sol";
import "../../interfaces/ISilo.sol";
import "../../interfaces/IAction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/ISiloManagerFactory.sol";

contract SiloFactoryUIHelper is Ownable{

    address public siloFactory;
    ISiloFactory SiloFactory;

    constructor(address _siloFactory){
        siloFactory = _siloFactory;
        SiloFactory = ISiloFactory(_siloFactory);
    }

    /***************************************external onlyOwner *************************************/
    function updateSiloFactory(address _siloFactory)  external onlyOwner{
        siloFactory = _siloFactory;
        SiloFactory = ISiloFactory(_siloFactory);
    }

    /***************************************external state mutative *************************************/

    /***************************************external view *************************************/
    function getSiloInputAndOutput(uint siloId) external view returns(address[4] memory input, address[4] memory output){
        bytes memory config = ISilo(siloMap(siloId)).getConfig();
        (input, output) = abi.decode(config, (address[4], address[4]));
    }

    function usersSilosFilterCategory(address _user, uint _category, bool _filter) external view returns(uint[] memory, address[] memory, string[] memory){
        uint count;
        ISilo silo;
        if(_filter){
            for(uint i=0; i<SiloFactory.balanceOf(_user); i++){
                silo = ISilo(siloMap(SiloFactory.tokenOfOwnerByIndex(_user, i)));
                if(silo.strategyCategory() == _category){
                    count+=1;
                }
            }
        }
        else{
            count = SiloFactory.balanceOf(_user);
        }
        uint[] memory ids = new uint[](count);
        address[] memory silos = new address[](count);
        string[] memory names = new string[](count);
        count = 0;
        for(uint i=0; i<SiloFactory.balanceOf(_user); i++){
            silo = ISilo(siloMap(SiloFactory.tokenOfOwnerByIndex(_user, i)));
            if(!_filter || silo.strategyCategory() == _category){
                ids[count] = SiloFactory.tokenOfOwnerByIndex(_user, i);
                silos[count] = address(silo);
                names[count] = silo.name();
                count+=1;
            }
        }
        return (ids, silos, names);
    }

    function usersSilosFilterStrategyName(address _user, string memory _name, bool _filter) external view returns(uint[] memory, address[] memory, string[] memory){
        uint count;
        ISilo silo;
        if(_filter){
            for(uint i=0; i<SiloFactory.balanceOf(_user); i++){
                silo = ISilo(siloMap(SiloFactory.tokenOfOwnerByIndex(_user, i)));
                if(compareStrings(silo.strategyName(), _name)){
                    count+=1;
                }
            }
        }
        else{
            count = SiloFactory.balanceOf(_user);
        }
        uint[] memory ids = new uint[](count);
        address[] memory silos = new address[](count);
        string[] memory names = new string[](count);
        count = 0;
        for(uint i=0; i<SiloFactory.balanceOf(_user); i++){
            silo = ISilo(siloMap(SiloFactory.tokenOfOwnerByIndex(_user, i)));
            if(!_filter || compareStrings(silo.strategyName(), _name)){
                ids[count] = SiloFactory.tokenOfOwnerByIndex(_user, i);
                silos[count] = address(silo);
                names[count] = silo.name();
                count+=1;
            }
        }
        return (ids, silos, names);
    }

    function usersSilosFilterStrategyNameAndCategory(address _user, string memory _name, uint _category, bool _filter) external view returns(uint[] memory, address[] memory, string[] memory){
        uint count;
        ISilo silo;
        if(_filter){
            for(uint i=0; i<SiloFactory.balanceOf(_user); i++){
                silo = ISilo(siloMap(SiloFactory.tokenOfOwnerByIndex(_user, i)));
                if(compareStrings(silo.strategyName(), _name) && silo.strategyCategory() == _category){
                    count+=1;
                }
            }
        }
        else{
            count = SiloFactory.balanceOf(_user);
        }
        uint[] memory ids = new uint[](count);
        address[] memory silos = new address[](count);
        string[] memory names = new string[](count);
        count = 0;
        for(uint i=0; i<SiloFactory.balanceOf(_user); i++){
            silo = ISilo(siloMap(SiloFactory.tokenOfOwnerByIndex(_user, i)));
            if(!_filter || (compareStrings(silo.strategyName(), _name) && silo.strategyCategory() == _category)){
                ids[count] = SiloFactory.tokenOfOwnerByIndex(_user, i);
                silos[count] = address(silo);
                names[count] = silo.name();
                count+=1;
            }
        }
        return (ids, silos, names);
    }

    function getSiloDelay(uint siloID) external view returns(uint){
        return ISilo(siloMap(siloID)).siloDelay();
    }

    function getLastTimeMaintained(uint siloID) external view returns(uint){
        return ISilo(siloMap(siloID)).lastTimeMaintained();
    }

    function getTimeToNextMaintain(uint siloID) external view returns(uint time){
        time = block.timestamp - ISilo(siloMap(siloID)).lastTimeMaintained();
        uint delay = ISilo(siloMap(siloID)).siloDelay();
        if(time < delay){
           time = delay - time;
        }
        else{
            time = 0;
        }
    }

    //get the action stack using the strategy name 
    function getActionStackWithName(string memory _strategyName) external view returns(address[4] memory inputs, address[] memory actions, bytes[] memory configurationData){
        uint id = SiloFactory.strategyName(_strategyName);
        inputs = SiloFactory.getStrategyInputs(id);
        actions = SiloFactory.getStrategyActions(id);
        configurationData = SiloFactory.getStrategyConfigurationData(id);
    }

        /**
     * @dev returns an error array
     * if errors = [0,0] no errors were found
     * if errors = [A,A] and A != 0, then there is an erorr with validateConfig locaetd at index A-1 in the _configurationData Array
     * if errors = [A,B] and A != B, then there is an input/output mismatch located between indexes A-1 and B-1 in the _configurationData array
     */
    function validateStrategyWithStack(address[4] memory _inputs, address[] memory _actions, bytes[] memory _configurationData) external view returns(uint[2] memory errors){
        require(_actions.length == _configurationData.length, "Gravity: Actions/Configuration Data Lengths do not match");
        address[4] memory input = _inputs;
        address[4] memory output;
        address[4] memory tmp;
        for(uint i=0; i<_actions.length; i++){
            if(!IAction(_actions[i]).validateConfig(_configurationData[i])){
                errors[0] = i+1;
                errors[1] = i+1;
                break;
            }
            (output,tmp) = abi.decode(_configurationData[i], (address[4],address[4]));
            for(uint j=0; j<4; j++){
                if(input[j] != output[j]){
                    errors[0] = i;
                    errors[1] = i+1;
                    break;
                }
            }
            if(errors[0] != 0 && errors[1] != 0){break;}//break out of for loop if error was found
            input = tmp;
        }
    }

    function viewConfigMakeupForStack(address[] memory actions) external view returns(string[] memory makeups){
        makeups = new string[](actions.length);
        for(uint i=0; i<actions.length; i++){
            makeups[i] = viewConfigMakeupForAction(actions[i]);
        }
    }

    function getFeeInfo(address _action) external view returns(uint fee, address recipient){
        uint tier = getTier(msg.sender);
        if(SiloFactory.useCustom(_action)){
            return (SiloFactory.getFeeList(_action)[tier], SiloFactory.feeRecipient(_action));
        }
        else{
            return (SiloFactory.getDefaultFeeList()[tier], SiloFactory.defaultRecipient());
        }
    }

    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory){
        if(SiloFactory.useCustom(_action)){
            return SiloFactory.getFeeList(_action);
        }
        else{
            return SiloFactory.getDefaultFeeList();
        }
    }

    function getUpkeepBalance(address _user) external view returns(uint96){
        return ISiloManagerFactory(SiloFactory.managerFactory()).getUpkeepBalance(_user);
    }

    function managerApproved(address _user) external view returns(bool){
        return ISiloManagerFactory(SiloFactory.managerFactory()).managerApproved(_user);
    }

    function managerExists(address _user) external view returns(bool){
        address manager = ISiloManagerFactory(SiloFactory.managerFactory()).userToManager(_user);
        return manager != address(0);
    }

    function showActionStackFeeInfo(address[] memory _implementations) external view returns(string[] memory, uint[] memory){
        uint[4] memory actionFees;
        string memory name;
        uint[] memory fees = new uint[](_implementations.length * 4);
        string[] memory names = new string[](_implementations.length);
        for(uint i=0; i<_implementations.length; i++){
            (name, actionFees) = IAction(_implementations[i]).showFee(_implementations[i]);
            names[i] = name;
            for(uint j=0; j<4; j++){
                fees[i*4+j] = actionFees[j];
            }
        }
        return (names, fees);
    }

    /***************************************public state mutative *************************************/

    /***************************************public view *************************************/
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    function siloMap(uint _id) public view returns(address){
        return SiloFactory.siloMap(_id);
    }

    function siloToId(address _silo) public view returns(uint){
        return SiloFactory.siloToId(_silo);
    }

    function getTier(address silo) public view returns(uint){
        return SiloFactory.getTier(silo);
    }

    function getStrategiesByType(uint strategyType) public view returns(string[] memory strategies){
        return SiloFactory.getCatalogue(strategyType);
    }

    function viewConfigMakeupForAction(address action) public view returns(string memory makeup){
        makeup = IAction(action).getMetaData();
    }

    function viewSiloStrategyMetaData(uint siloID) external view returns(string memory, uint, string memory, uint, address[] memory actions, bytes[] memory configData){
        ISilo silo = ISilo(SiloFactory.siloMap(siloID));
        (actions, configData) = silo.viewStrategy();
        return (silo.strategyName(), silo.strategyCategory(), silo.name(), silo.siloDelay(), actions, configData);
    }

    function showStrategyBalances(uint siloId) external view returns(uint[] memory collateral, uint[] memory debt, address[] memory collateralTokens, address[] memory debtTokens){
        ISilo silo = ISilo(SiloFactory.siloMap(siloId));
        IAction action;
        (address[] memory actions, bytes[] memory configData) = silo.viewStrategy();
        collateral = new uint[](actions.length);
        debt = new uint[](actions.length);
        collateralTokens = new address[](actions.length);
        debtTokens = new address[](actions.length);
        for(uint i=0; i< actions.length; i++){
            action = IAction(actions[i]);
            (collateral[i], debt[i], collateralTokens[i], debtTokens[i]) = action.showBalances(address(silo), configData[i]);
        }

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISiloFactory is IERC721Enumerable{
    function tokenMinimum(address _token) external view returns(uint _minimum);
    function balanceOf(address _owner) external view returns(uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function managerFactory() external view returns(address);
    function siloMap(uint _id) external view returns(address);
    function tierManager() external view returns(address);
    function ownerOf(uint _id) external view returns(address);
    function siloToId(address silo) external view returns(uint);
    function CreateSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[4] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    function Withdraw(uint siloID) external;
    function getFeeInfo(address _action) external view returns(uint fee, address recipient);
    function strategyMaxGas() external view returns(uint);
    function strategyName(string memory _name) external view returns(uint);
    function getStrategyInputs(uint _id) external view returns(address[4] memory inputs);
    function getStrategyActions(uint _id) external view returns(address[] memory actions);
    function getStrategyConfigurationData(uint _id) external view returns(bytes[] memory configurationData);
    function useCustom(address _action) external view returns(bool);
    function getFeeList(address _action) external view returns(uint[4] memory);
    function feeRecipient(address _action) external view returns(address);
    function getDefaultFeeList() external view returns(uint[4] memory);
    function defaultRecipient() external view returns(address);
    function getTier(address _silo) external view returns(uint);
    function getCatalogue(uint _type) external view returns(string[] memory);
    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct PriceOracle{
        address oracle;
        uint actionPrice;
    }

interface ISilo{
    function initialize(uint siloID) external;
    function Deposit() external;
    function Withdraw() external;
    function Maintain() external;
    function ExitSilo(address caller) external;
    function adminCall(address target, bytes memory data) external;
    function setStrategy(address[4] memory input, bytes[] memory _configurationData, address[] memory _implementations) external;
    function getConfig() external view returns(bytes memory config);
    function withdrawToken(address token, address recipient) external;
    function adjustSiloDelay(uint _newDelay) external;
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
    function siloDelay() external view returns(uint);
    function name() external view returns(string memory);
    function lastTimeMaintained() external view returns(uint);
    function setName(string memory name) external;
    function inStrategy() external view returns(bool);
    function setStrategyName(string memory _strategyName) external;
    function setStrategyCategory(uint _strategyCategory) external;
    function strategyName() external view returns(string memory);
    function strategyCategory() external view returns(uint);
    function adjustStrategy(uint _index, bytes memory _configurationData, address _implementation) external;
    function viewStrategy() external view returns(address[] memory actions, bytes[] memory configData);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAction{
    function getConfig() external view returns(bytes memory config);
    function checkMaintain(bytes memory configuration) external view returns(bool);
    function validateConfig(bytes memory configData) external view returns(bool); 
    function getMetaData() external view returns(string memory);
    function getFactory() external view returns(address);
    function getDecimals() external view returns(uint);
    function showFee(address _action) external view returns(string memory actionName, uint[4] memory fees);
    function showBalances(address _silo, bytes memory _configurationData) external view returns(uint, uint, address, address);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISiloManagerFactory{
    function isManager(address _manager) external view returns(bool);
    function keeperRegistry() external view returns(address);
    function siloFactory() external view returns(address);
    function ERC20_LINK_ADDRESS() external view returns(address);
    function ERC677_LINK_ADDRESS() external view returns(address);
    function PEGSWAP_ADDRESS() external view returns(address);
    function REGISTRAR_ADDRESS() external view returns(address);
    function getUpkeepBalance(address _user) external view returns(uint96 balance);
    function managerApproved(address _user) external view returns(bool);
    function userToManager(address _user) external view returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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