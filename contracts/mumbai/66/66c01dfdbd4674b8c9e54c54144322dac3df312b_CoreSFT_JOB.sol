//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interface/ISFTRec.sol";
import "./interface/ISFTjob.sol";
import "./interface/ICoreSFT_JOB.sol";

/**
 * @title CoreSFT - Semi-Fungible Recommendation system.
 * @dev This contract is the core contract for the SFTRec, SFTJob and SFTInsignia usage.
 *         - It provides creation of recommendation discounts based on the previously deployed contracts that sells something.
 *         - It provides a way to create Jobs and only allow dev that matches the requisites to accept.
 *         - It provides a way to test the developer skills on solidity.
 *         - 
 * @author Omnes - <Waiandt.eth>
 */


contract CoreSFT_JOB is ICoreSFT_JOB,Ownable, ERC1155Holder{
/// -----------------------------------------------------------------------
/// ---------------------------EVENTS--------------------------------------
/// -----------------------------------------------------------------------

event MicroJob(address indexed _job, address indexed _paymentToken, uint256 indexed _paymentAmount, address _contractor);
event MicroJobTaken(uint256 indexed _jobIndex, address indexed _taker);
event RemovedMicroJob(uint256 indexed _jobIndex);
event RedeemedMicroJob(uint256 indexed _jobIndex, address indexed _dev);
event DiscountSet(address indexed _material, uint256 indexed _discount);


/// -----------------------------------------------------------------------
/// ---------------------------STORAGE-------------------------------------
/// -----------------------------------------------------------------------

uint256 _jobCounter;
address private _SFTInsignia; //GET AN INTERFACE HERE
ISFTjob private _SFTJob;
mapping(uint256 => microJob) public Job;


/// -----------------------------------------------------------------------
/// -------------------------CONSTRUCTOR-----------------------------------
/// -----------------------------------------------------------------------

constructor() Ownable() ICoreSFT_JOB(){}







/// -----------------------------------------------------------------------
/// -----------------------PARAMETERS FUNCTIONS----------------------------
/// -----------------------------------------------------------------------



/// -----------------------------------------------------------------------
/// ----------------------MICROJOB FUNCTIONS-------------------------------
/// -----------------------------------------------------------------------

    function newMicroJob(microJob memory _newJob) public payable returns(uint256, address, uint256){
        _checkEOA();
        _newJob._contractor = msg.sender;
        require(_newJob._amount / _newJob._amountOfDevs > 0, "Core SFT : New Job, devs cannot have payments of less than 1 unit");
        require(_newJob._amount % _newJob._amountOfDevs == 0, "Core SFT : New Job cannot have payments counting on fractions");

        if(_newJob._token == address(0))
        require(msg.value == _newJob._amount, "Core SFT : New Job, payment is set wrong");
        else
        IERC20(_newJob._token).transferFrom(msg.sender, address(this), _newJob._amount);

        Job[_jobCounter] = microJob({
            _jobAddress : _newJob._jobAddress,
            _token : _newJob._token,
            _amount : _newJob._amount,
            _jobType : _newJob._jobType,
            _contractor : _newJob._contractor,
            _reqLevel : _newJob._reqLevel,
            _amountOfDevs : _newJob._amountOfDevs,
            _jobDone : false
        });

        _SFTJob.newJob(_jobCounter,  _newJob._amountOfDevs);

        emit MicroJob(_newJob._jobAddress, _newJob._token, _newJob._amount, msg.sender);
        return(++_jobCounter,_newJob._token, _newJob._amount);
    }

    function getMicroJob(uint256 _jobIndex) public returns(bool){
        _checkEOA();
        require(_SFTJob.balanceOf(address(this), _jobIndex) > 0, "Core SFT : Job has already been taken");
        require(!Job[_jobIndex]._jobDone, "Core SFT : Sorry, that job has already closed");

        (bool _success, bytes memory _level) = _SFTInsignia.call(abi.encodeWithSignature("userLevel(address)", msg.sender));    
        uint256 _levelUint = bytesToUint(_level);
        
        require(_success && _levelUint >= Job[_jobIndex]._reqLevel, "Core SFT : User level is not high enough");
        require(_SFTJob.balanceOf(msg.sender, _jobIndex) == 0, "Core SFT : Cannot take the job again");

        _SFTJob.safeTransferFrom(address(this), msg.sender, _jobIndex, 1, "");

        emit MicroJobTaken(_jobIndex, msg.sender);
        return true;
    }

    function removeMicroJob(uint256 _jobIndex) public returns(bool){
        _checkEOA();
        microJob memory _aux = Job[_jobIndex];

        require(msg.sender ==_aux._contractor || msg.sender == owner(), "Core SFT : Only owner of the job or owner of the contract can remove");
        require(_SFTJob.balanceOf(address(this), _jobIndex) == _aux._amountOfDevs, "Core SFT : You have already contracted someone");
        
        (bool success) = _SFTJob.deleteJob(_jobIndex, _aux._amountOfDevs);
        require(success, "Core SFT : Not able to remove job");

        success = IERC20(_aux._token).transfer(_aux._contractor, _aux._amount);
        require(success, "Core SFT : Not able to refund job tokens");
        
        emit RemovedMicroJob(_jobIndex);

        return true;
    }

    function redeemJobPayment(uint256 _jobIndex) public returns(bool){
        _checkEOA();
        require(_SFTJob.balanceOf(msg.sender,_jobIndex) == 1,"Core SFT : You have to own one JobSFT token of the _jobIndex");
        microJob memory _aux = Job[_jobIndex];
        
        require(_aux._jobDone, "Core SFT : Sorry, job is still running");
        _SFTJob.safeTransferFrom(msg.sender, address(this), _jobIndex, 1, "");
        _SFTJob.deleteJob(_jobIndex, 1);
        
        IERC20(_aux._token).transfer(msg.sender, _aux._amount/_aux._amountOfDevs);

        emit RedeemedMicroJob(_jobIndex, msg.sender);

        return true;
    }


/// -----------------------------------------------------------------------
/// ---------------------------SET FUNCTIONS-------------------------------
/// -----------------------------------------------------------------------


    function setSFTInsignia(address __SFTInsignia) public onlyOwner {
        _SFTInsignia = __SFTInsignia;
    }
    function setSFTJob(address __SFTJob) public onlyOwner {
        _SFTJob = ISFTjob(__SFTJob);
    }

    function setMicroJobDone(uint256 _jobIndex) public {
        require(msg.sender == Job[_jobIndex]._contractor || msg.sender == owner(), "Core SFT : You do not have access to this function");

        Job[_jobIndex]._jobDone = true;
    }

/// -----------------------------------------------------------------------
/// ---------------------------GET FUNCTIONS-------------------------------
/// -----------------------------------------------------------------------




/// -----------------------------------------------------------------------
/// -------------------------INTERNAL FUNCTIONS----------------------------
/// -----------------------------------------------------------------------

    function _checkEOA() private view{
        require(msg.sender == tx.origin, "Core SFT : No contract calls here");
    }


    function bytesToUint(bytes memory b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }




    ///@dev CREATE SOULBOUND INSIGNIA FOR USER TECNOLOGY AND USER RECOMMENDATION PROGRAM
    ///@dev CREATE A POSSIBILITY FOR SMALL UNIT CHALLENGES TO EARN THE INSIGNIA FROM THE PROTOCOL
    ///@dev CREATE A JOB HUNT PAGE AND A USER MATCH SYSTEM



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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface ISFTRec {
    function currentId() external returns(uint256);
    
    // function price() external returns(uint256);

    // function maxDiscount() external returns(uint256);

    function createDiscount(uint256 _amount, string memory _tokenURI) external returns(uint256);

    function addDiscountTokens(uint256 _amount, uint256 _id) external returns (bool);

    function redeemDiscount(uint256 _id) external returns (bool);

    function redeemBaggedDiscount(uint256 _id) external returns (bool);

    // function mint(address to, uint256 tokenId) external returns (bool); // 721
    
    // function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external returns (bool); // 1155

    function setURI(uint _tokenId, string memory _tokenURI) external;

    function setBaseUri(string memory _baseURI) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface ISFTjob {

    function newJob(uint256 _index, uint256 _amount) external returns(bool);

    function deleteJob(uint256 _index, uint256 _amount) external returns(bool);
    
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;



}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


interface ICoreSFT_JOB{


///@dev This enum is used to delimit the type of job that has to be performed
enum typeofJOB{
    Develop,
    optimize,
    audit
}

///@dev This is the struct used to add a new Job into the protocol
///@param _jobAddress is the address of the contract that needs development
///@param _token is the payment token accepted in that contract
///@param _amount is the amount to be paid
///@param _jobType is the type of job to be performed
///@param _contractor is the EOA that needs developers
///@param _reqLevel is the level that the dev has to have in order to get the job
///@param _amountOfdevs is the amount of devs needed for the job
///@param _jobDone is set by the contractor to release the payment
struct microJob{
    address _jobAddress;
    address _token;
    uint256 _amount;
    typeofJOB _jobType;
    address _contractor;
    uint256 _reqLevel;
    uint256 _amountOfDevs;
    bool _jobDone;

}


/// -----------------------------------------------------------------------
/// ----------------------MICROJOB FUNCTIONS-------------------------------
/// -----------------------------------------------------------------------

///@dev Creates a new Job on the contract
///@notice Only the contractor can create
function newMicroJob(microJob memory _newJob) external payable returns(uint256, address, uint256);

///@dev Gets a new Job on the contract
///@notice Each dev can only get one Job at a time
function getMicroJob(uint256 _jobIndex) external  returns(bool);

///@dev Delist a Job
///@notice Can only delist a job without any takers
function removeMicroJob(uint256 _jobIndex) external  returns(bool);

///@dev Redeem a finished payment
function redeemJobPayment(uint256 _jobIndex) external  returns(bool);

/// -----------------------------------------------------------------------
/// ---------------------------SET FUNCTIONS-------------------------------
/// -----------------------------------------------------------------------

///@dev Sets a Job as finished
///@notice Only the job contractor can set that
///@param _jobIndex is the job identificator in the Job mapping
function setMicroJobDone(uint256 _jobIndex) external;

/// -----------------------------------------------------------------------
/// ---------------------------GET FUNCTIONS-------------------------------
/// -----------------------------------------------------------------------

///@dev Returns the full price of a discount
///@param _tokenId is the discount token id
// function fullPrice(uint256 _tokenId) external view returns (uint256);








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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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